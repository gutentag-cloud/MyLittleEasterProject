import AppKit
import Metal
import MetalKit
import simd

/// Renders custom Metal shaders as wallpapers (Shadertoy-style).
final class MetalShaderRenderer: NSObject, WallpaperRenderer, MTKViewDelegate {
    
    let targetView: NSView
    private let configuration: Configuration
    
    private var metalView: MTKView?
    private var device: MTLDevice?
    private var commandQueue: MTLCommandQueue?
    private var pipelineState: MTLRenderPipelineState?
    private var uniformBuffer: MTLBuffer?
    
    private var startTime: CFTimeInterval = 0
    private var audioSpectrum = AudioSpectrum()
    
    /// Uniforms passed to every shader.
    struct ShaderUniforms {
        var time: Float
        var resolution: SIMD2<Float>
        var mouse: SIMD2<Float>
        var audioLevel: Float
        var audioBass: Float
        var audioMid: Float
        var audioTreble: Float
        var speed: Float
        var param0: Float
        var param1: Float
        var param2: Float
        var param3: Float
    }
    
    init(targetView: NSView, configuration: Configuration) {
        self.targetView = targetView
        self.configuration = configuration
        super.init()
    }
    
    func load(url: URL) {
        setupMetal(shaderURL: url)
    }
    
    func start() {
        startTime = CACurrentMediaTime()
        metalView?.isPaused = false
        Logger.shared.info("Metal shader renderer started")
    }
    
    func pause() {
        metalView?.isPaused = true
    }
    
    func resume() {
        metalView?.isPaused = false
    }
    
    func stop() {
        metalView?.isPaused = true
        metalView?.removeFromSuperview()
        metalView = nil
        Logger.shared.info("Metal shader renderer stopped")
    }
    
    func setTargetFPS(_ fps: Int) {
        metalView?.preferredFramesPerSecond = fps
    }
    
    func receiveAudioSpectrum(_ spectrum: AudioSpectrum) {
        self.audioSpectrum = spectrum
    }
    
    // MARK: - Metal Setup
    
    private func setupMetal(shaderURL: URL? = nil) {
        guard let device = MTLCreateSystemDefaultDevice() else {
            Logger.shared.error("Metal is not supported on this device")
            return
        }
        self.device = device
        self.commandQueue = device.makeCommandQueue()
        
        // Create MTKView
        let metalView = MTKView(frame: targetView.bounds, device: device)
        metalView.autoresizingMask = [.width, .height]
        metalView.colorPixelFormat = .bgra8Unorm
        metalView.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)
        metalView.delegate = self
        metalView.preferredFramesPerSecond = configuration.targetFPS
        metalView.isPaused = true
        
        targetView.subviews.forEach { $0.removeFromSuperview() }
        targetView.addSubview(metalView)
        self.metalView = metalView
        
        // Build the shader pipeline
        buildPipeline(device: device, shaderURL: shaderURL)
        
        // Create uniform buffer
        uniformBuffer = device.makeBuffer(
            length: MemoryLayout<ShaderUniforms>.stride,
            options: .storageModeShared
        )
    }
    
    private func buildPipeline(device: MTLDevice, shaderURL: URL?) {
        do {
            let library: MTLLibrary
            
            if let url = shaderURL, url.pathExtension == "metal",
               let source = try? String(contentsOf: url) {
                library = try device.makeLibrary(source: source, options: nil)
            } else {
                // Use built-in default shader
                library = try device.makeLibrary(source: Self.defaultShaderSource, options: nil)
            }
            
            let descriptor = MTLRenderPipelineDescriptor()
            descriptor.vertexFunction = library.makeFunction(name: "vertexShader")
            descriptor.fragmentFunction = library.makeFunction(name: "fragmentShader")
            descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
            
            pipelineState = try device.makeRenderPipelineState(descriptor: descriptor)
        } catch {
            Logger.shared.error("Failed to create Metal pipeline: \(error)")
        }
    }
    
    // MARK: - MTKViewDelegate
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
    
    func draw(in view: MTKView) {
        guard let drawable = view.currentDrawable,
              let descriptor = view.currentRenderPassDescriptor,
              let pipeline = pipelineState,
              let commandBuffer = commandQueue?.makeCommandBuffer(),
              let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor),
              let uniformBuffer = uniformBuffer
        else { return }
        
        // Update uniforms
        let time = Float(CACurrentMediaTime() - startTime)
        var uniforms = ShaderUniforms(
            time: time * configuration.shaderSpeed,
            resolution: SIMD2<Float>(Float(view.drawableSize.width), Float(view.drawableSize.height)),
            mouse: SIMD2<Float>(0, 0),
            audioLevel: audioSpectrum.overallLevel,
            audioBass: audioSpectrum.bass,
            audioMid: audioSpectrum.mid,
            audioTreble: audioSpectrum.treble,
            speed: configuration.shaderSpeed,
            param0: configuration.shaderParameters["param0"] ?? 0,
            param1: configuration.shaderParameters["param1"] ?? 0,
            param2: configuration.shaderParameters["param2"] ?? 0,
            param3: configuration.shaderParameters["param3"] ?? 0
        )
        memcpy(uniformBuffer.contents(), &uniforms, MemoryLayout<ShaderUniforms>.stride)
        
        encoder.setRenderPipelineState(pipeline)
        encoder.setFragmentBuffer(uniformBuffer, offset: 0, index: 0)
        encoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        encoder.endEncoding()
        
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
    
    // MARK: - Built-in Shaders
    
    static let defaultShaderSource = """
    #include <metal_stdlib>
    using namespace metal;
    
    struct ShaderUniforms {
        float time;
        float2 resolution;
        float2 mouse;
        float audioLevel;
        float audioBass;
        float audioMid;
        float audioTreble;
        float speed;
        float param0;
        float param1;
        float param2;
        float param3;
    };
    
    struct VertexOut {
        float4 position [[position]];
        float2 uv;
    };
    
    vertex VertexOut vertexShader(uint vid [[vertex_id]]) {
        float2 positions[4] = {
            float2(-1, -1), float2(1, -1), float2(-1, 1), float2(1, 1)
        };
        float2 uvs[4] = {
            float2(0, 1), float2(1, 1), float2(0, 0), float2(1, 0)
        };
        VertexOut out;
        out.position = float4(positions[vid], 0, 1);
        out.uv = uvs[vid];
        return out;
    }
    
    // Plasma shader — a classic
    fragment float4 fragmentShader(VertexOut in [[stage_in]],
                                    constant ShaderUniforms &u [[buffer(0)]]) {
        float2 uv = in.uv * 2.0 - 1.0;
        uv.x *= u.resolution.x / u.resolution.y;
        
        float t = u.time;
        float audioBoost = 1.0 + u.audioLevel * 2.0;
        
        float v = 0.0;
        v += sin((uv.x * 10.0 + t));
        v += sin((uv.y * 10.0 + t) / 2.0);
        v += sin((uv.x * 10.0 + uv.y * 10.0 + t) / 2.0);
        
        float cx = uv.x + 0.5 * sin(t / 5.0);
        float cy = uv.y + 0.5 * cos(t / 3.0);
        v += sin(sqrt(100.0 * (cx * cx + cy * cy) + 1.0) + t);
        v = v / 2.0;
        
        float3 col;
        col.r = sin(v * 3.14159) * audioBoost;
        col.g = sin(v * 3.14159 + 2.0 * 3.14159 / 3.0) * audioBoost;
        col.b = sin(v * 3.14159 + 4.0 * 3.14159 / 3.0) * audioBoost;
        col = col * 0.5 + 0.5;
        
        return float4(col, 1.0);
    }
    """
}
