import MetalKit

class Node {
    private var _name: String = "Node"
    private var _id: String!
    
    private var _position: float3 = float3()
    private var _scale: float3 = float3(1,1,1)
    private var _rotation: float3 = float3()
    private var _velocity: float3 = float3()
    private var _acceleration: float3 = float3(0,0,0)
    private var _mass = Float(5.974e15)

    var parentModelMatrix = matrix_identity_float4x4
    
    var modelMatrix: matrix_float4x4{
        var modelMatrix = matrix_identity_float4x4
        modelMatrix.translate(direction: _position)
        modelMatrix.rotate(angle: _rotation.x, axis: X_AXIS)
        modelMatrix.rotate(angle: _rotation.y, axis: Y_AXIS)
        modelMatrix.rotate(angle: _rotation.z, axis: Z_AXIS)
        modelMatrix.scale(axis: _scale)
        return matrix_multiply(parentModelMatrix, modelMatrix)
    }
    
    var children: [Node] = []
    
    init(name: String){
        self._name = name
        self._id = UUID().uuidString
    }
    
    func addChild(_ child: Node){
        children.append(child)
    }
    
    /// Override this function instead of the update function
    func doUpdate() { }
    
    func update(){
        doUpdate()
        for child in children{
            child.parentModelMatrix = self.modelMatrix
            child.update()
        }
    }
    
    func render(renderCommandEncoder: MTLRenderCommandEncoder){
        renderCommandEncoder.pushDebugGroup("Rendering \(_name)")
        if let renderable = self as? Renderable {
            renderable.doRender(renderCommandEncoder)
        }
        
        for child in children{
            child.render(renderCommandEncoder: renderCommandEncoder)
        }
        renderCommandEncoder.popDebugGroup()
    }
}

extension Node {
    //Naming
    func setName(_ name: String){ self._name = name }
    func getName()->String{ return _name }
    func getID()->String { return _id }
    
    //Positioning and Movement
    func setPosition(_ position: float3){ self._position = position }
    func setPosition(_ r: Float,_ g: Float,_ b: Float) { setPosition(float3(r,g,b)) }
    func setPositionX(_ xPosition: Float) { self._position.x = xPosition }
    func setPositionY(_ yPosition: Float) { self._position.y = yPosition }
    func setPositionZ(_ zPosition: Float) { self._position.z = zPosition }
    func getPosition()->float3 { return self._position }
    func getPositionX()->Float { return self._position.x }
    func getPositionY()->Float { return self._position.y }
    func getPositionZ()->Float { return self._position.z }
    func move(_ x: Float, _ y: Float, _ z: Float){ self._position += float3(x,y,z) }
    func moveX(_ delta: Float){ self._position.x += delta }
    func moveY(_ delta: Float){ self._position.y += delta }
    func moveZ(_ delta: Float){ self._position.z += delta }
    
    //Rotating
    func setRotation(_ rotation: float3) { self._rotation = rotation }
    func setRotation(_ r: Float,_ g: Float,_ b: Float) { setRotation(float3(r,g,b)) }
    func setRotationX(_ xRotation: Float) { self._rotation.x = xRotation }
    func setRotationY(_ yRotation: Float) { self._rotation.y = yRotation }
    func setRotationZ(_ zRotation: Float) { self._rotation.z = zRotation }
    func getRotation()->float3 { return self._rotation }
    func getRotationX()->Float { return self._rotation.x }
    func getRotationY()->Float { return self._rotation.y }
    func getRotationZ()->Float { return self._rotation.z }
    func rotate(_ x: Float, _ y: Float, _ z: Float){ self._rotation += float3(x,y,z) }
    func rotateX(_ delta: Float){ self._rotation.x += delta }
    func rotateY(_ delta: Float){ self._rotation.y += delta }
    func rotateZ(_ delta: Float){ self._rotation.z += delta }
    
    //Scaling
    func setScale(_ scale: float3){ self._scale = scale }
    func setScale(_ r: Float,_ g: Float,_ b: Float) { setScale(float3(r,g,b)) }
    func setScale(_ scale: Float){setScale(float3(scale, scale, scale))}
    func setScaleX(_ scaleX: Float){ self._scale.x = scaleX }
    func setScaleY(_ scaleY: Float){ self._scale.y = scaleY }
    func setScaleZ(_ scaleZ: Float){ self._scale.z = scaleZ }
    func getScale()->float3 { return self._scale }
    func getScaleX()->Float { return self._scale.x }
    func getScaleY()->Float { return self._scale.y }
    func getScaleZ()->Float { return self._scale.z }
    func scaleX(_ delta: Float){ self._scale.x += delta }
    func scaleY(_ delta: Float){ self._scale.y += delta }
    func scaleZ(_ delta: Float){ self._scale.z += delta }
    
    //Body related
    func setMass(_ mass: Float){ self._mass = mass}
    func getMass()->Float { return self._mass }
    
    func setVelocity(_ velocity: float3){ self._velocity = velocity }
    func setVelocity(_ r: Float,_ g: Float,_ b: Float) { setVelocity(float3(r,g,b)) }
    func setVelocityX(_ xVelocity: Float) { self._velocity.x = xVelocity }
    func setVelocityY(_ yVelocity: Float) { self._velocity.y = yVelocity }
    func setVelocityZ(_ zVelocity: Float) { self._velocity.z = zVelocity }
    func getVelocity()->float3 { return self._velocity }
    func getVelocityX()->Float { return self._velocity.x }
    func getVelocityY()->Float { return self._velocity.y }
    func getVelocityZ()->Float { return self._velocity.z }

    func setAcceleration(_ acceleration: float3){ self._acceleration = acceleration }
    func setAcceleration(_ r: Float,_ g: Float,_ b: Float) { setAcceleration(float3(r,g,b)) }
    func setAccelerationX(_ xAcceleration: Float) { self._acceleration.x = xAcceleration }
    func setAccelerationY(_ yAcceleration: Float) { self._acceleration.y = yAcceleration }
    func setAccelerationZ(_ zAcceleration: Float) { self._acceleration.z = zAcceleration }
    func getAcceleration()->float3 { return self._acceleration }
    func getAccelerationX()->Float { return self._acceleration.x }
    func getAccelerationY()->Float { return self._acceleration.y }
    func getAccelerationZ()->Float { return self._acceleration.z }

}
