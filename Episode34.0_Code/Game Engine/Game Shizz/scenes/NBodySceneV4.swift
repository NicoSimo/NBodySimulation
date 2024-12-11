import simd
import MetalKit

class NBodySceneV4: Scene{
    var debugCamera = DebugCamera()
    var bodies: [GameObject] = []
    
    let epsilon: Float = 0.5
    let minDistance: Float = 20
    let maxDistance: Float = 54
    let GRAVITY: Float = 6.67E-11 / 1E10
    let SUN_MASS: Float = 1.9890e30 / 1E10
    let EARTH_MASS: Float = 5.974e22
    let COLLISION_TH: Float = 1.0e6
    
    let SCALE_FACTOR: Float = 1E6
    let maxForce: Float = 1E8
    
    let dt: Float = 10

    let NBODY: Int = 5000

    
    override func buildScene() {
        debugCamera.setPosition(0,0,600)
        debugCamera.setRotationX(Float(10).toRadians)
        addCamera(debugCamera)
        
        let sunColor = float4(0.7, 0.5, 0, 1.0)
        var sunMaterial = Material()
        sunMaterial.isLit = false
        sunMaterial.color = sunColor
        
        let light = LightObject(name: "Light")
        light.setLightBrightness(0.5)
        addLight(light)
        
        let sun = LightObject(name: "Sun", meshType: .Sphere)
        sun.setScale(5)
        sun.useMaterial(sunMaterial)
        addLight(sun)
        
        let sunBody = GameObject(name: "Sun", meshType: .Sphere)
        sunBody.setPosition(float3(0,0,0))
        sunBody.setVelocity(float3(0,0,0))
        sunBody.setAcceleration(float3(0,0,0))
        sunBody.setMass(SUN_MASS)
        bodies.append(sunBody)
        
        // Bodies
        let body_count: Int = NBODY
        
        for i in 0..<body_count {
            let body = GameObject(name: "Body", meshType: .Sphere)
            body.setScale(1)
            
            let angle = 2 * Float.pi * Float.random(in: 0...1)
            let zAngle = Float.pi * Float.random(in: 0...1)
            let radius = (maxDistance - minDistance) * (Float.random(in: 0...1)) + 30
            
            let x = radius * cos(angle)
            let y = radius * sin(angle)
            let z = radius * sin(zAngle)
            
            let position = float3(x, y, z)
            let distance = simd_distance(position, float3(0,0,0))
            let r = position - float3(0,0,0)
            let a = r / distance
            
            let esc = sqrt((GRAVITY * SUN_MASS) / distance)
            bodies[i].setVelocity((-a.y * esc),( a.x * esc), (a.z * esc))
            body.setPosition(position)
            
            addChild(body)
            bodies.append(body)
        }
    }
    
    override func doUpdate() {
        updateAccelerationGPU()
        updateVelocityGPU()
        updatePositionGPU() 
    }
    
    func updateAccelerationGPU() {
        guard let device = MTLCreateSystemDefaultDevice(),
              let commandQueue = device.makeCommandQueue(),
              let computePipeline = try? device.makeComputePipelineState(function: Engine.DefaultLibrary.makeFunction(name: "update_acceleration")!) else {
            fatalError("Failed to create Metal setup")
        }
        
        // Flatten positions and masses into arrays
        var positions = bodies.map { $0.getPosition() }
        var masses = bodies.map { $0.getMass() }
        var accelerations = Array(repeating: float3(0, 0, 0), count: bodies.count)
        
        // Constants
        var gravity = GRAVITY
        var epsilon: Float = self.epsilon
        var body_count = NBODY
        
        // Create Metal buffers
        let posBuffer = device.makeBuffer(bytes: &positions,
                                          length: positions.count * MemoryLayout<float3>.stride,
                                          options: .storageModeShared)!
        let massBuffer = device.makeBuffer(bytes: &masses,
                                           length: masses.count * MemoryLayout<Float>.stride,
                                           options: .storageModeShared)!
        let accBuffer = device.makeBuffer(bytes: &accelerations,
                                           length: accelerations.count * MemoryLayout<float3>.stride,
                                           options: .storageModeShared)!
        let gravityBuffer = device.makeBuffer(bytes: &gravity,
                                              length: MemoryLayout<Float>.stride,
                                              options: .storageModeShared)!
        let epsilonBuffer = device.makeBuffer(bytes: &epsilon,
                                              length: MemoryLayout<Float>.stride,
                                              options: .storageModeShared)!
        
        let bodyCountBuffer = device.makeBuffer(bytes: &body_count,
                                                length: MemoryLayout<UInt32>.stride,
                                                options: .storageModeShared)!
        
        // Create command buffer and encoder
        guard let commandBuffer = commandQueue.makeCommandBuffer(),
              let computeEncoder = commandBuffer.makeComputeCommandEncoder() else {
            fatalError("Failed to create command buffer or encoder")
        }
        
        computeEncoder.setComputePipelineState(computePipeline)
        computeEncoder.setBuffer(posBuffer, offset: 0, index: 0)
        computeEncoder.setBuffer(massBuffer, offset: 0, index: 1)
        computeEncoder.setBuffer(accBuffer, offset: 0, index: 2)
        computeEncoder.setBuffer(gravityBuffer, offset: 0, index: 3)
        computeEncoder.setBuffer(epsilonBuffer, offset: 0, index: 4)
        computeEncoder.setBuffer(bodyCountBuffer, offset: 0, index: 5)

        
        // Determine thread execution configuration
        let threadsPerGrid = MTLSize(width: bodies.count, height: 1, depth: 1)
        let threadsPerThreadgroup = MTLSize(width: min(computePipeline.maxTotalThreadsPerThreadgroup, bodies.count), height: 1, depth: 1)
        computeEncoder.dispatchThreads(threadsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)
        
        computeEncoder.endEncoding()
        commandBuffer.commit()
        
        // Retrieve updated accelerations from the GPU
        let updatedAccelerations = accBuffer.contents().bindMemory(to: float3.self, capacity: bodies.count)
        for i in 0..<bodies.count {
            bodies[i].setAcceleration(updatedAccelerations[i])
        }
    }

    func updateVelocityGPU() {
        guard let device = MTLCreateSystemDefaultDevice(),
              let commandQueue = device.makeCommandQueue(),
              let computePipeline = try? device.makeComputePipelineState(function: Engine.DefaultLibrary.makeFunction(name: "update_velocity")!) else {
            fatalError("Failed to create Metal setup")
        }
        
        // Flatten velocities and accelerations into arrays
        var velocities = bodies.map { $0.getVelocity() }
        var accelerations = bodies.map { $0.getAcceleration() }
        
        // Create Metal buffers
        let velBuffer = device.makeBuffer(bytes: &velocities,
                                          length: velocities.count * MemoryLayout<float3>.stride,
                                          options: .storageModeShared)!
        let accBuffer = device.makeBuffer(bytes: &accelerations,
                                          length: accelerations.count * MemoryLayout<float3>.stride,
                                          options: .storageModeShared)!
        var dtScalar = dt
        let dtBuffer = device.makeBuffer(bytes: &dtScalar,
                                         length: MemoryLayout<Float>.stride,
                                         options: .storageModeShared)!
        
        // Create command buffer and encoder
        guard let commandBuffer = commandQueue.makeCommandBuffer(),
              let computeEncoder = commandBuffer.makeComputeCommandEncoder() else {
            fatalError("Failed to create command buffer or encoder")
        }
        
        computeEncoder.setComputePipelineState(computePipeline)
        computeEncoder.setBuffer(velBuffer, offset: 0, index: 0)
        computeEncoder.setBuffer(accBuffer, offset: 0, index: 1)
        computeEncoder.setBuffer(dtBuffer, offset: 0, index: 2)
        
        // Determine thread execution configuration
        let threadsPerGrid = MTLSize(width: bodies.count, height: 1, depth: 1)
        let threadsPerThreadgroup = MTLSize(width: min(computePipeline.maxTotalThreadsPerThreadgroup, bodies.count), height: 1, depth: 1)
        computeEncoder.dispatchThreads(threadsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)
        
        computeEncoder.endEncoding()
        commandBuffer.commit()
        
        // Retrieve updated velocities from the GPU
        let updatedVelocities = velBuffer.contents().bindMemory(to: float3.self, capacity: bodies.count)
        for i in 0..<bodies.count {
            bodies[i].setVelocity(updatedVelocities[i])
        }
    }


    func updatePositionGPU() {
        guard let device = MTLCreateSystemDefaultDevice(),
              let commandQueue = device.makeCommandQueue(),
              let computePipeline = try? device.makeComputePipelineState(function: Engine.DefaultLibrary.makeFunction(name: "update_position")!) else {
            fatalError("Failed to create Metal setup")
        }
        
        // Flatten positions and velocities into arrays
        var positions = bodies.map { $0.getPosition() }
        var velocities = bodies.map { $0.getVelocity() }
        
        // Create Metal buffers
        let posBuffer = device.makeBuffer(bytes: &positions,
                                          length: positions.count * MemoryLayout<float3>.stride,
                                          options: .storageModeShared)!
        let velBuffer = device.makeBuffer(bytes: &velocities,
                                          length: velocities.count * MemoryLayout<float3>.stride,
                                          options: .storageModeShared)!
        var dtScalar = dt
        let dtBuffer = device.makeBuffer(bytes: &dtScalar,
                                         length: MemoryLayout<Float>.stride,
                                         options: .storageModeShared)!
        
        // Create command buffer and encoder
        guard let commandBuffer = commandQueue.makeCommandBuffer(),
              let computeEncoder = commandBuffer.makeComputeCommandEncoder() else {
            fatalError("Failed to create command buffer or encoder")
        }
        
        computeEncoder.setComputePipelineState(computePipeline)
        computeEncoder.setBuffer(posBuffer, offset: 0, index: 0)
        computeEncoder.setBuffer(velBuffer, offset: 0, index: 1)
        computeEncoder.setBuffer(dtBuffer, offset: 0, index: 2)
        
        // Determine thread execution configuration
        let threadsPerGrid = MTLSize(width: bodies.count, height: 1, depth: 1)
        let threadsPerThreadgroup = MTLSize(width: min(computePipeline.maxTotalThreadsPerThreadgroup, bodies.count), height: 1, depth: 1)
        computeEncoder.dispatchThreads(threadsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)
        
        computeEncoder.endEncoding()
        commandBuffer.commit()
        
        // Retrieve updated positions from the GPU
        let updatedPositions = posBuffer.contents().bindMemory(to: float3.self, capacity: bodies.count)
        for i in 0..<bodies.count {
            bodies[i].setPosition(updatedPositions[i])
        }
    }

}
