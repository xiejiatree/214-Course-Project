//
//  GameScene.swift
//  PS
//
//  Created by Zheng, Jenny on 11/17/24.
//

import SpriteKit
import GameplayKit
    
class GameScene: SKScene {
    
    var entities = [GKEntity]()
    var graphs = [String : GKGraph]()
    
    private var lastUpdateTime : TimeInterval = 0
    private var label : SKLabelNode?
    private var spinnyNode : SKShapeNode?
    
    var slingshotBase: SKSpriteNode!
    var slingshotBand: SKShapeNode!
    var pumpkin: SKSpriteNode!
    var initialPumpPos: CGPoint!
    
    // Define attachment points between slingshot band and base
    let slingshotLeft: CGPoint = CGPoint(x: -20, y: 0)
    let slingshotRight: CGPoint = CGPoint(x: 40, y: 27)
    
    let ssDefaultControl: CGPoint = CGPoint(x: -45, y: -150)
    
    // Max range of pumpkin-slingshot interaction
    let maxRange: CGFloat = 400
    
    override func sceneDidLoad() {
        
        // Load nodes
        slingshotBase = childNode(withName: "slingshot") as? SKSpriteNode
        slingshotBand = childNode(withName: "slingshotBand") as? SKShapeNode
        pumpkin = childNode(withName: "pumpkin") as? SKSpriteNode
        
        initialPumpPos = pumpkin.position
        
        restingArc()
        
        self.lastUpdateTime = 0
        
        // Get label node from scene and store it for use later
        self.label = self.childNode(withName: "//helloLabel") as? SKLabelNode
        if let label = self.label {
            label.alpha = 0.0
            label.run(SKAction.fadeIn(withDuration: 2.0))
        }
            
    }
    
    func restingArc(){
        let path = CGMutablePath()
        
        path.move(to: slingshotLeft)
        
        path.addQuadCurve(to: slingshotRight, control: ssDefaultControl)
        
        slingshotBand.path = path
        
        slingshotBand.lineWidth = 2
        slingshotBand.strokeColor = .black
        slingshotBand.fillColor = .clear

    }
    
    func updateArc(point: CGPoint){
        
        let distance = hypot(slingshotBase.position.x - pumpkin.position.x, slingshotBase.position.y - pumpkin.position.y)
        var controlPoint: CGPoint
        //if distance <= maxRange {
            //controlPoint = point
        //} else {
            //controlPoint = ssDefaultControl
        //}
        
        controlPoint = point
        
        let path = CGMutablePath()
        
        path.move(to: slingshotLeft)
        
        path.addQuadCurve(to: slingshotRight, control: controlPoint)
        
        slingshotBand.path = path
        
        slingshotBand.lineWidth = 2
        slingshotBand.strokeColor = .black
        slingshotBand.fillColor = .clear
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let touchLocation = touch.location(in: self)
            
            if pumpkin.contains(touchLocation) {
                pumpkin.physicsBody?.isDynamic = false
                pumpkin.physicsBody?.affectedByGravity = false
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let touchLocation = touch.location(in: self)
            
            pumpkin.position = touchLocation
            pumpkin.physicsBody?.isDynamic = false
            pumpkin.physicsBody?.affectedByGravity = false
            updateArc(point: pumpkin.position)
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let touchLocation = touch.location(in: self)
            
            pumpkin.position = touchLocation
            let launchVector = CGVector(dx: (slingshotBase.position.x - pumpkin.position.x) * 0.8, dy: (slingshotBase.position.y - pumpkin.position.y) * 2)
            
            pumpkin.physicsBody?.isDynamic = true
            pumpkin.physicsBody?.affectedByGravity = true
            pumpkin.physicsBody?.applyImpulse(launchVector)
            
            // Reset slingshot band after launch
            restingArc()
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
        
        // Initialize _lastUpdateTime if it has not already been
        if (self.lastUpdateTime == 0) {
            self.lastUpdateTime = currentTime
        }
        
        // Calculate time since last update
        let dt = currentTime - self.lastUpdateTime
        
        // Update entities
        for entity in self.entities {
            entity.update(deltaTime: dt)
        }
        
        self.lastUpdateTime = currentTime
    }
}
