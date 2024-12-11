import MetalKit

enum Physics {
    case Acceleration
    case Velocity
    case Position
}

class PhysicsLibrary: Library<Physics, MTLFunction> {
    private var _library: [Physics : Body] = [:]
    
    override func fillLibrary() {
        
        // Acceleration shader
        _library.updateValue(Body(functionName: "update_acceleration"), forKey: .Acceleration)
        
        // Velocity shader
        _library.updateValue(Body(functionName: "update_velocity"), forKey: .Velocity)
        
        // Position shader
        _library.updateValue(Body(functionName: "update_position"), forKey: .Position)
    }
    
    override subscript(_ type: Physics)->MTLFunction {
        return (_library[type]?.function)!
    }
}

class Body {
    var function: MTLFunction!
    init(functionName: String) {
        self.function = Engine.DefaultLibrary.makeFunction(name: functionName)
        self.function.label = functionName
    }
}

