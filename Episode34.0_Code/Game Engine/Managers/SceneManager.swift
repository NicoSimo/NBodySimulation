import MetalKit

enum SceneTypes{
    case Nbody2
    case Nbody3
    case Nbody4
}

class SceneManager{
    private static var _currentScene: Scene!
    
    public static func Initialize(_ sceneType: SceneTypes){
        SetScene(sceneType)
    }
    
    public static func SetScene(_ sceneType: SceneTypes){
        switch sceneType {
        case .Nbody2:
            _currentScene = NBodySceneV2(name: "Nbody2")
            
        case .Nbody3:
            _currentScene = NBodySceneV3(name: "Nbody3")
        
        case .Nbody4:
            _currentScene = NBodySceneV3(name: "Nbody4")
        
        }
    
    }
    
    public static func TickScene(renderCommandEncoder: MTLRenderCommandEncoder, deltaTime: Float){
        GameTime.UpdateTime(deltaTime)
        
        _currentScene.updateCameras()
        
        _currentScene.update()
        
        _currentScene.render(renderCommandEncoder: renderCommandEncoder)
    }
}
