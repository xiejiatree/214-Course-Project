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
    var person : SKSpriteNode! //NEW GameObject, -Erica
    
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
        person = childNode(withName: "right-wp-frame1")as?SKSpriteNode
        
        initialPumpPos = pumpkin.position
        restingArc()
        
        self.lastUpdateTime = 0
        
        
        // Get label node from scene and store it for use later
        self.label = self.childNode(withName: "//helloLabel") as? SKLabelNode
        if let label = self.label {
            label.alpha = 0.0
            label.run(SKAction.fadeIn(withDuration: 2.0))
        }
        createPerson() //Make a person
        //        while(true){
        //            createPerson()
        //        }
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
    
    //NEW createPerson function -Erica
    func createPerson() {//Creates an animated person. Would be nice if this could happen randomly on either side, and I don't know how to get it to happen multiple times in once game cycle.
        //Sprite animation tutorial: https://www.youtube.com/watch?v=cI9aH1_a2J0&ab_channel=MathienVision //It's a little old but it will do.
        let r_frame1 = SKTexture(imageNamed: "right-wp-frame1")
        let r_frame2 = SKTexture(imageNamed: "right-wp-frame2")
        let r_frame3 = SKTexture(imageNamed: "right-wp-frame3")
        let r_frame4 = SKTexture(imageNamed: "right-wp-frame4")
        let rightTextures = [r_frame1, r_frame2, r_frame3, r_frame4]
        
        let l_frame1 = SKTexture(imageNamed: "left-wp-frame1")
        let l_frame2 = SKTexture(imageNamed: "left-wp-frame2")
        let l_frame3 = SKTexture(imageNamed: "left-wp-frame3")
        let l_frame4 = SKTexture(imageNamed: "left-wp-frame4")
        let leftTextures = [l_frame1, l_frame2, l_frame3, l_frame4]
        
        let right_animation = SKAction.animate(with: rightTextures, timePerFrame: 0.25) //iterates through the four frames in one second.
        let left_animation = SKAction.animate(with: leftTextures, timePerFrame: 0.25)
        
        let spawnSide = Bool.random() //True = LEFT, False = RIGHT
        let xPosition: CGFloat = spawnSide ? -100 : frame.width + 100
        let yPosition: CGFloat = frame.minY + frame.height * 0.25
        let direction: CGFloat = spawnSide ? 1 : -1
        
        let person = SKSpriteNode(texture: spawnSide ? rightTextures[0] : leftTextures[0])
        person.position = CGPoint(x: xPosition, y: yPosition)
        person.xScale = 0.25 //Original sprite is 1024px, scaling it down
        person.yScale = 0.25
        addChild(person)
        
        let animation = spawnSide ? right_animation : left_animation
        let animationAction = SKAction.repeatForever(animation)
        person.run(animationAction, withKey: "animation")
        
        let moveToCenter = SKAction.move(to: CGPoint(x: frame.midX, y: yPosition), duration: 4.0)
        let changeDirection = SKAction.run { [weak person] in
            guard let person = person else { return }
            let newDirection = Bool.random() ? 1 : -1
            let newTextures = newDirection == 1 ? rightTextures : leftTextures
            person.texture = newTextures.first
            let newAnimation = SKAction.animate(with: newTextures, timePerFrame: 0.25)
            person.run(SKAction.repeatForever(newAnimation), withKey: "animation")
        }
        
        let sequence = SKAction.sequence([moveToCenter, changeDirection]) //I need to read up on SKAction sequence. Ideally the person will first walk to the center of the screen and then randomly change direction after that.
        let repeatSequence = SKAction.repeatForever(sequence)
        person.run(repeatSequence)
    }
    
}
