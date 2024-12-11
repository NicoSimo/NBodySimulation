import simd

class NBodySceneV2: Scene{
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
    
    let dt: Float = 100
    
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
        let body_count: Int = 10
        
        for i in 0..<body_count {
            let body = GameObject(name: "Body", meshType: .Sphere)
            body.setScale(1)

            let angle = 2 * Float.pi * Float.random(in: 0...1)
            let zAngle = Float.pi * Float.random(in: 0...1)
            let radius = (maxDistance - minDistance) * (Float.random(in: 0...5))

            let x = radius * cos(angle)
            let y = radius * sin(angle)
            let z = radius * sin(zAngle)

            let position = float3(x, y, z)
            let distance = simd_distance(position, float3(0,0,0))
            let r = position - float3(0,0,0)
            let a = r / distance

            let esc = sqrt((GRAVITY * SUN_MASS) / distance)
            
            bodies.append(body)

            bodies[i].setVelocity((-a.y * esc),( a.x * esc), (a.z * esc))
            body.setPosition(position)
            
            addChild(body)
        }
    }
    
    override func doUpdate() {
        
        updateAcceleration()
        updateVelocity()
        updatePosition()
    }
    
    
    }
    
    func updateVelocity(){
        
        for i in 1..<bodies.count {
            let vel = bodies[i].getVelocity()
            let newVel = vel + bodies[i].getAcceleration() * dt
            bodies[i].setVelocity(newVel)
        }
    }

    func updatePosition(){
        for i in 1..<bodies.count {
            let pos = bodies[i].getPosition()
            let newPos = pos + bodies[i].getVelocity() * dt
            bodies[i].setPosition(newPos)
        }
    }
}
