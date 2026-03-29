import AppKit
import Metal
import MetalKit
import simd

/// GPU-based generative art renderer with multiple algorithmic presets.
final class GenerativeArtRenderer: NSObject, WallpaperRenderer, MTKViewDelegate {
    
    let targetView: NSView
    private let configuration: Configuration
    
    private var metalView: MTKView?
    private var device: MTLDevice?
    private var commandQueue: MTLCommandQueue?
    private var pipelineState: MTLRenderPipelineState?
    private var uniformBuffer: MTLBuffer?
    private var startTime: CFTimeInterval = 0
    private var audioSpectrum = AudioSpectrum()
    
    struct GenUniforms {
        var time: Float
        var resolution: SIMD2<Float>
        var audioLevel: Float
        var audioBass: Float
        var audioMid: Float
        var audioTreble: Float
        var seed: Float
        var speed: Float
    }
    
    init(targetView: NSView, configuration: Configuration) {
        self.targetView = targetView
        self.configuration = configuration
        super.init()
    }
    
    func load(url: URL) {
        setupMetal()
    }
    
    func start() {
        startTime = CACurrentMediaTime()
        metalView?.isPaused = false
    }
    
    func pause() { metalView?.isPaused = true }
    func resume() { metalView?.isPaused = false }
    
    func stop() {
        metalView?.isPaused = true
        metalView?.removeFromSuperview()
        metalView = nil
    }
    
    func setTargetFPS(_ fps: Int) {
        metalView?.preferredFramesPerSecond = fps
    }
    
    func receiveAudioSpectrum(_ spectrum: AudioSpectrum) {
        self.audioSpectrum = spectrum
    }
    
    private func setupMetal() {
        guard let device = MTLCreateSystemDefaultDevice() else { return }
        self.device = device
        self.commandQueue = device.makeCommandQueue()
        
        let view = MTKView(frame: targetView.bounds, device: device)
        view.autoresizingMask = [.width, .height]
        view.colorPixelFormat = .bgra8Unorm
        view.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)
        view.delegate = self
        view.preferredFramesPerSecond = configuration.targetFPS
        view.isPaused = true
        
        targetView.subviews.forEach { $0.removeFromSuperview() }
        targetView.addSubview(view)
        self.metalView = view
        
        buildPipeline(device: device)
        
        uniformBuffer = device.makeBuffer(
            length: MemoryLayout<GenUniforms>.stride,
            options: .storageModeShared
        )
    }
    
    private func buildPipeline(device: MTLDevice) {
        let source = shaderSource(for: configuration.generativePreset)
        do {
            let library = try device.makeLibrary(source: source, options: nil)
            let desc = MTLRenderPipelineDescriptor()
            desc.vertexFunction = library.makeFunction(name: "genVertexShader")
            desc.fragmentFunction = library.makeFunction(name: "genFragmentShader")
            desc.colorAttachments[0].pixelFormat = .bgra8Unorm
            pipelineState = try device.makeRenderPipelineState(descriptor: desc)
        } catch {
            Logger.shared.error("Generative art pipeline error: \(error)")
        }
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
    
    func draw(in view: MTKView) {
        guard let drawable = view.currentDrawable,
              let desc = view.currentRenderPassDescriptor,
              let pipeline = pipelineState,
              let buf = commandQueue?.makeCommandBuffer(),
              let enc = buf.makeRenderCommandEncoder(descriptor: desc),
              let ub = uniformBuffer
        else { return }
        
        var u = GenUniforms(
            time: Float(CACurrentMediaTime() - startTime) * configuration.shaderSpeed,
            resolution: SIMD2<Float>(Float(view.drawableSize.width), Float(view.drawableSize.height)),
            audioLevel: audioSpectrum.overallLevel,
            audioBass: audioSpectrum.bass,
            audioMid: audioSpectrum.mid,
            audioTreble: audioSpectrum.treble,
            seed: Float(configuration.generativeSeed),
            speed: configuration.shaderSpeed
        )
        memcpy(ub.contents(), &u, MemoryLayout<GenUniforms>.stride)
        
        enc.setRenderPipelineState(pipeline)
        enc.setFragmentBuffer(ub, offset: 0, index: 0)
        enc.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        enc.endEncoding()
        buf.present(drawable)
        buf.commit()
    }
    
    private func shaderSource(for preset: String) -> String {
        let header = """
        #include <metal_stdlib>
        using namespace metal;
        
        struct GenUniforms {
            float time;
            float2 resolution;
            float audioLevel;
            float audioBass;
            float audioMid;
            float audioTreble;
            float seed;
            float speed;
        };
        
        struct VertexOut {
            float4 position [[position]];
            float2 uv;
        };
        
        vertex VertexOut genVertexShader(uint vid [[vertex_id]]) {
            float2 pos[4] = { float2(-1,-1), float2(1,-1), float2(-1,1), float2(1,1) };
            float2 uv[4]  = { float2(0,1),   float2(1,1),  float2(0,0),  float2(1,0) };
            VertexOut out;
            out.position = float4(pos[vid], 0, 1);
            out.uv = uv[vid];
            return out;
        }
        
        float hash(float2 p) {
            return fract(sin(dot(p, float2(127.1, 311.7))) * 43758.5453);
        }
        
        float noise(float2 p) {
            float2 i = floor(p);
            float2 f = fract(p);
            f = f * f * (3.0 - 2.0 * f);
            return mix(
                mix(hash(i), hash(i + float2(1,0)), f.x),
                mix(hash(i + float2(0,1)), hash(i + float2(1,1)), f.x),
                f.y
            );
        }
        
        float fbm(float2 p) {
            float v = 0.0, a = 0.5;
            for (int i = 0; i < 6; i++) {
                v += a * noise(p);
                p = p * 2.0 + float2(1.7, 9.2);
                a *= 0.5;
            }
            return v;
        }
        """
        
        switch preset {
        case "flow_field":
            return header + """
            fragment float4 genFragmentShader(VertexOut in [[stage_in]],
                                               constant GenUniforms &u [[buffer(0)]]) {
                float2 uv = in.uv * 2.0 - 1.0;
                uv.x *= u.resolution.x / u.resolution.y;
                
                float t = u.time * 0.3;
                float audio = 1.0 + u.audioLevel;
                
                float2 p = uv * 3.0;
                float f1 = fbm(p + float2(t * 0.5, t * 0.3) + fbm(p + t) * audio);
                float f2 = fbm(p + float2(t * 0.3, t * 0.5) + fbm(p - t * 0.5) * audio);
                
                float3 col = float3(
                    0.5 + 0.5 * sin(f1 * 6.0 + 0.0),
                    0.5 + 0.5 * sin(f1 * 6.0 + 2.1),
                    0.5 + 0.5 * sin(f2 * 6.0 + 4.2)
                );
                
                col *= 0.8 + 0.2 * fbm(uv * 5.0 + t);
                return float4(col, 1.0);
            }
            """
            
        case "voronoi":
            return header + """
            fragment float4 genFragmentShader(VertexOut in [[stage_in]],
                                               constant GenUniforms &u [[buffer(0)]]) {
                float2 uv = in.uv * 8.0;
                float t = u.time * 0.5;
                
                float2 i = floor(uv);
                float2 f = fract(uv);
                float minDist = 1.0;
                float secondMin = 1.0;
                
                for (int y = -1; y <= 1; y++) {
                    for (int x = -1; x <= 1; x++) {
                        float2 neighbor = float2(x, y);
                        float2 point = float2(hash(i + neighbor), hash(i + neighbor + 31.0));
                        point = 0.5 + 0.5 * sin(t + 6.28 * point);
                        float d = length(f - neighbor - point);
                        if (d < minDist) { secondMin = minDist; minDist = d; }
                        else if (d < secondMin) { secondMin = d; }
                    }
                }
                
                float edge = secondMin - minDist;
                float audio = 1.0 + u.audioLevel * 2.0;
                
                float3 col = float3(
                    0.2 + 0.8 * smoothstep(0.0, 0.05, edge),
                    0.1 + 0.5 * minDist * audio,
                    0.3 + 0.7 * (1.0 - minDist)
                );
                return float4(col, 1.0);
            }
            """
            
        default: // fractal
            return header + """
            fragment float4 genFragmentShader(VertexOut in [[stage_in]],
                                               constant GenUniforms &u [[buffer(0)]]) {
                float2 uv = in.uv * 2.0 - 1.0;
                uv.x *= u.resolution.x / u.resolution.y;
                
                float t = u.time * 0.2;
                float2 c = float2(-0.8 + 0.2 * sin(t), 0.156 + 0.1 * cos(t * 0.7));
                float2 z = uv * 1.5;
                
                int maxIter = 128;
                int iter = 0;
                for (int i = 0; i < maxIter; i++) {
                    z = float2(z.x * z.x - z.y * z.y, 2.0 * z.x * z.y) + c;
                    if (dot(z, z) > 4.0) break;
                    iter = i;
                }
                
                float f = float(iter) / float(maxIter);
                float audio = 1.0 + u.audioLevel;
                
                float3 col = 0.5 + 0.5 * cos(float3(3.0, 4.0, 5.0) * f * 6.28 * audio + float3(0.0, 0.6, 1.0));
                if (iter == maxIter - 1) col = float3(0);
                
                return float4(col, 1.0);
            }
            """
        }
    }
}
