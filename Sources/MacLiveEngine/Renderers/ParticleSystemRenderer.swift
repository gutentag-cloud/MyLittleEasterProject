import AppKit
import Metal
import MetalKit
import simd

/// GPU-accelerated particle system renderer.
final class ParticleSystemRenderer: NSObject, WallpaperRenderer, MTKViewDelegate {
    
    let targetView: NSView
    private let configuration: Configuration
    
    private var metalView: MTKView?
    private var device: MTLDevice?
    private var commandQueue: MTLCommandQueue?
    private var computePipeline: MTLComputePipelineState?
    private var renderPipeline: MTLRenderPipelineState?
    private var particleBuffer: MTLBuffer?
    
    private var startTime: CFTimeInterval = 0
    private var lastTime: CFTimeInterval = 0
    private var particleCount: Int = 0
    private var audioSpectrum = AudioSpectrum()
    
    struct Particle {
        var position: SIMD2<Float>
        var velocity: SIMD2<Float>
        var color: SIMD4<Float>
        var size: Float
        var life: Float
        var maxLife: Float
        var padding: Float
    }
    
    init(targetView: NSView, configuration: Configuration) {
        self.targetView = targetView
        self.configuration = configuration
        super.init()
    }
    
    func load(url: URL) {
        // URL could point to a particle preset JSON
        setupMetal()
    }
    
    func start() {
        startTime = CACurrentMediaTime()
        lastTime = startTime
        metalView?.isPaused = false
        Logger.shared.info("Particle system started (\(particleCount) particles)")
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
    
    // MARK: - Metal Setup
    
    private func setupMetal() {
        guard let device = MTLCreateSystemDefaultDevice() else { return }
        self.device = device
        self.commandQueue = device.makeCommandQueue()
        
        particleCount = configuration.particleCount
        
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
        
        // Initialize particles
        initializeParticles(device: device)
        buildPipelines(device: device)
    }
    
    private func initializeParticles(device: MTLDevice) {
        var particles = [Particle]()
        particles.reserveCapacity(particleCount)
        
        let preset = configuration.particlePreset
        
        for _ in 0..<particleCount {
            var p = Particle(
                position: SIMD2<Float>(Float.random(in: -1...1), Float.random(in: -1...1)),
                velocity: SIMD2<Float>(0, 0),
                color: SIMD4<Float>(1, 1, 1, 1),
                size: 2.0,
                life: Float.random(in: 0...1),
                maxLife: 1.0,
                padding: 0
            )
            
            switch preset {
            case "starfield":
                p.velocity = SIMD2<Float>(Float.random(in: -0.01...0.01), Float.random(in: -0.01...0.01))
                p.size = Float.random(in: 1...4)
                let brightness = Float.random(in: 0.3...1.0)
                p.color = SIMD4<Float>(brightness, brightness, brightness * 1.1, 1)
                p.maxLife = Float.random(in: 2...8)
                
            case "fireflies":
                p.velocity = SIMD2<Float>(Float.random(in: -0.005...0.005), Float.random(in: 0.001...0.01))
                p.size = Float.random(in: 2...6)
                p.color = SIMD4<Float>(1.0, 0.9, 0.3, Float.random(in: 0.3...0.8))
                p.maxLife = Float.random(in: 3...10)
                
            case "snow":
                p.position.y = Float.random(in: 0...2)
                p.velocity = SIMD2<Float>(Float.random(in: -0.002...0.002), Float.random(in: -0.01 ... -0.003))
                p.size = Float.random(in: 2...5)
                p.color = SIMD4<Float>(1, 1, 1, Float.random(in: 0.5...1))
                p.maxLife = Float.random(in: 5...15)
                
            case "rain":
                p.position.y = Float.random(in: 0...2)
                p.velocity = SIMD2<Float>(Float.random(in: -0.001...0.001), Float.random(in: -0.05 ... -0.02))
                p.size = Float.random(in: 1...2)
                p.color = SIMD4<Float>(0.6, 0.7, 0.9, 0.5)
                p.maxLife = Float.random(in: 1...3)
                
            default: // galaxy
                let angle = Float.random(in: 0...(2 * .pi))
                let radius = Float.random(in: 0...0.8)
                p.position = SIMD2<Float>(cos(angle) * radius, sin(angle) * radius)
                let speed: Float = 0.01 / max(radius, 0.1)
                p.velocity = SIMD2<Float>(-sin(angle) * speed, cos(angle) * speed)
                p.size = Float.random(in: 1...3)
                let hue = angle / (2 * .pi)
                p.color = SIMD4<Float>(
                    0.5 + 0.5 * cos(hue * 6.28),
                    0.3 + 0.3 * cos(hue * 6.28 + 2.09),
                    0.8 + 0.2 * cos(hue * 6.28 + 4.19),
                    1
                )
                p.maxLife = Float.random(in: 5...20)
            }
            
            particles.append(p)
        }
        
        particleBuffer = device.makeBuffer(
            bytes: &particles,
            length: MemoryLayout<Particle>.stride * particleCount,
            options: .storageModeShared
        )
    }
    
    private func buildPipelines(device: MTLDevice) {
        do {
            let library = try device.makeLibrary(source: Self.particleShaderSource, options: nil)
            
            // Compute pipeline
            if let computeFunc = library.makeFunction(name: "updateParticles") {
                computePipeline = try device.makeComputePipelineState(function: computeFunc)
            }
            
            // Render pipeline
            let renderDesc = MTLRenderPipelineDescriptor()
            renderDesc.vertexFunction = library.makeFunction(name: "particleVertex")
            renderDesc.fragmentFunction = library.makeFunction(name: "particleFragment")
            renderDesc.colorAttachments[0].pixelFormat = .bgra8Unorm
            renderDesc.colorAttachments[0].isBlendingEnabled = true
            renderDesc.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
            renderDesc.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
            renderDesc.colorAttachments[0].sourceAlphaBlendFactor = .one
            renderDesc.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
            
            renderPipeline = try device.makeRenderPipelineState(descriptor: renderDesc)
        } catch {
            Logger.shared.error("Particle pipeline error: \(error)")
        }
    }
    
    // MARK: - MTKViewDelegate
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
    
    func draw(in view: MTKView) {
        let now = CACurrentMediaTime()
        let deltaTime = Float(now - lastTime)
        lastTime = now
        
        guard let commandBuffer = commandQueue?.makeCommandBuffer(),
              let particleBuffer = particleBuffer else { return }
        
        // Compute pass — update particles
        if let computePipeline = computePipeline,
           let computeEncoder = commandBuffer.makeComputeCommandEncoder() {
            
            var params = SIMD4<Float>(
                deltaTime,
                audioSpectrum.overallLevel,
                audioSpectrum.bass,
                Float(particleCount)
            )
            
            computeEncoder.setComputePipelineState(computePipeline)
            computeEncoder.setBuffer(particleBuffer, offset: 0, index: 0)
            computeEncoder.setBytes(&params, length: MemoryLayout<SIMD4<Float>>.size, index: 1)
            
            let threadGroupSize = min(256, computePipeline.maxTotalThreadsPerThreadgroup)
            let threadGroups = (particleCount + threadGroupSize - 1) / threadGroupSize
            computeEncoder.dispatchThreadgroups(
                MTLSize(width: threadGroups, height: 1, depth: 1),
                threadsPerThreadgroup: MTLSize(width: threadGroupSize, height: 1, depth: 1)
            )
            computeEncoder.endEncoding()
        }
        
        // Render pass — draw particles
        guard let drawable = view.currentDrawable,
              let descriptor = view.currentRenderPassDescriptor,
              let renderPipeline = renderPipeline,
              let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor)
        else {
            commandBuffer.commit()
            return
        }
        
        var resolution = SIMD2<Float>(Float(view.drawableSize.width), Float(view.drawableSize.height))
        
        renderEncoder.setRenderPipelineState(renderPipeline)
        renderEncoder.setVertexBuffer(particleBuffer, offset: 0, index: 0)
        renderEncoder.setVertexBytes(&resolution, length: MemoryLayout<SIMD2<Float>>.size, index: 1)
        renderEncoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: particleCount)
        renderEncoder.endEncoding()
        
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
    
    // MARK: - Shader Source
    
    static let particleShaderSource = """
    #include <metal_stdlib>
    using namespace metal;
    
    struct Particle {
        float2 position;
        float2 velocity;
        float4 color;
        float size;
        float life;
        float maxLife;
        float padding;
    };
    
    kernel void updateParticles(device Particle *particles [[buffer(0)]],
                                 constant float4 &params [[buffer(1)]],
                                 uint id [[thread_position_in_grid]]) {
        if (id >= uint(params.w)) return;
        
        float dt = params.x;
        float audioLevel = params.y;
        
        Particle p = particles[id];
        
        p.life += dt;
        if (p.life > p.maxLife) {
            p.life = 0;
            p.position = float2(fract(sin(float(id) * 43758.5453) * 2.0) - 1.0,
                                fract(sin(float(id) * 93481.3271) * 2.0) - 1.0);
        }
        
        float audioForce = 1.0 + audioLevel * 3.0;
        p.position += p.velocity * dt * 60.0 * audioForce;
        
        // Wrap around
        if (p.position.x > 1.2) p.position.x = -1.2;
        if (p.position.x < -1.2) p.position.x = 1.2;
        if (p.position.y > 1.2) p.position.y = -1.2;
        if (p.position.y < -1.2) p.position.y = 1.2;
        
        particles[id] = p;
    }
    
    struct ParticleVertexOut {
        float4 position [[position]];
        float4 color;
        float pointSize [[point_size]];
    };
    
    vertex ParticleVertexOut particleVertex(const device Particle *particles [[buffer(0)]],
                                             constant float2 &resolution [[buffer(1)]],
                                             uint vid [[vertex_id]]) {
        Particle p = particles[vid];
        ParticleVertexOut out;
        out.position = float4(p.position, 0, 1);
        float lifeFraction = p.life / p.maxLife;
        float alpha = 1.0 - lifeFraction;
        out.color = float4(p.color.rgb, p.color.a * alpha);
        out.pointSize = p.size * (resolution.y / 1080.0);
        return out;
    }
    
    fragment float4 particleFragment(ParticleVertexOut in [[stage_in]],
                                      float2 pointCoord [[point_coord]]) {
        float dist = length(pointCoord - float2(0.5));
        if (dist > 0.5) discard_fragment();
        float alpha = smoothstep(0.5, 0.0, dist);
        return float4(in.color.rgb, in.color.a * alpha);
    }
    """
}
