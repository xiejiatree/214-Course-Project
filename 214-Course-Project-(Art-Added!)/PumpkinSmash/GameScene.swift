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
        startRandomPersonSpawning()
        //startRandomGirlSpawning()
        startRandomOwlSpawning()
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
    
    func startRandomPersonSpawning() { //Start Random Spawning People.
        let spawnAction = SKAction.run { [weak self] in
            self?.createPerson()
            print("createPerson Called!")
        }
        
        let waitAction = SKAction.wait(forDuration: TimeInterval.random(in: 3.0...5.0)) // Random interval between 1-5 seconds
        let sequence = SKAction.sequence([spawnAction, waitAction])
        let repeatAction = SKAction.repeatForever(sequence)
        
        run(repeatAction, withKey: "spawnPersons")
    }

    func createPerson() {
        // Define textures
        let rightTextures = [
            SKTexture(imageNamed: "right-wp-frame1"),
            SKTexture(imageNamed: "right-wp-frame2"),
            SKTexture(imageNamed: "right-wp-frame3"),
            SKTexture(imageNamed: "right-wp-frame4")
        ]
        
        let leftTextures = [
            SKTexture(imageNamed: "left-wp-frame1"),
            SKTexture(imageNamed: "left-wp-frame2"),
            SKTexture(imageNamed: "left-wp-frame3"),
            SKTexture(imageNamed: "left-wp-frame4")
        ]
        
        let girl_rightTextures = [
            SKTexture(imageNamed: "right-girl-frame1"),
              SKTexture(imageNamed: "right-girl-frame2"),
              SKTexture(imageNamed: "right-girl-frame3"),
              SKTexture(imageNamed: "right-girl-frame4")
        ]
        
        let girl_leftTextures = [
            SKTexture(imageNamed: "left-girl-frame1"),
            SKTexture(imageNamed: "left-girl-frame2"),
            SKTexture(imageNamed: "left-girl-frame3"),
            SKTexture(imageNamed: "left-girl-frame4")
        ]
        
        // Random spawn side
        let spawnSide = Bool.random() // True = LEFT, False = RIGHT
        let boyOrGirl = Bool.random() //True = GIRL, False = BOY
        let xPosition: CGFloat = spawnSide ? frame.minX-100 : frame.width + 100
        let yPosition: CGFloat = frame.minY + frame.height * 0.25
        let destinationX: CGFloat = spawnSide ? frame.width + 100 : frame.minX-100
        
        // Create person sprite
//        let person = SKSpriteNode(texture: spawnSide ? rightTextures[0] : leftTextures[0])
        var person: SKSpriteNode

        // Assign the appropriate texture and initialize the SKSpriteNode
        if spawnSide && boyOrGirl {
            person = SKSpriteNode(texture: girl_rightTextures[0])
        } 
        else if spawnSide && !boyOrGirl {
            person = SKSpriteNode(texture: rightTextures[0])
        } 
        else if !spawnSide && boyOrGirl {
            person = SKSpriteNode(texture: girl_leftTextures[0])
        } 
        else {
            person = SKSpriteNode(texture: leftTextures[0])
        }

        // Set properties for the person
        person.name = "person"
        person.position = CGPoint(x: xPosition, y: yPosition)
        person.xScale = 0.25
        person.yScale = 0.25
        addChild(person)
        print("A person was created, spawnSide = \(spawnSide), boyOrGirl = \(boyOrGirl)")

        
        var textures : [SKTexture]
        // Animation based on spawn side
        if(spawnSide && boyOrGirl){
            textures = girl_rightTextures
        }
        
        else if(spawnSide && !boyOrGirl){
            textures = rightTextures
        }
        
        else if(!spawnSide && boyOrGirl){
            textures = girl_leftTextures
        }
        else {
            textures = leftTextures
        }
        
//        let textures = spawnSide ? rightTextures : leftTextures
        let animation = SKAction.animate(with: textures, timePerFrame: 0.25)
        let animationAction = SKAction.repeatForever(animation)
        person.run(animationAction, withKey: "animation")
        
        // Move across the screen
        let moveDistance = abs(destinationX - xPosition)
        let moveDuration = TimeInterval(moveDistance / 100.0) // Adjust speed by changing the divisor
        let moveAction = SKAction.moveTo(x: destinationX, duration: moveDuration)
        
        // Remove person after movement
        let removeAction = SKAction.removeFromParent()
        
        let sequence = SKAction.sequence([moveAction, removeAction])
        person.run(sequence, withKey: "movement")
    }
    
    func startRandomOwlSpawning() { //Start Random Spawning People.
        let spawnAction = SKAction.run { [weak self] in
            self?.createOwl()
            print("createOwl Called!")
        }
        
        let waitAction = SKAction.wait(forDuration: TimeInterval.random(in: 5.0...10.0)) // Random interval between 1-5 seconds
        let sequence = SKAction.sequence([spawnAction, waitAction])
        let repeatAction = SKAction.repeatForever(sequence)
        
        run(repeatAction, withKey: "spawnOwls")
    }
    
    
    func createOwl(){
        // Define textures
         let owl_rightTextures = [
             SKTexture(imageNamed: "owl-right-frame1"),
             SKTexture(imageNamed: "owl-right-frame2"),
             SKTexture(imageNamed: "owl-right-frame3"),
             SKTexture(imageNamed: "owl-right-frame4")
         ]
         
         let owl_leftTextures = [
             SKTexture(imageNamed: "owl-left-frame1"),
             SKTexture(imageNamed: "owl-left-frame2"),
             SKTexture(imageNamed: "owl-left-frame3"),
             SKTexture(imageNamed: "owl-left-frame4")
         ]

         // Random spawn side
         let spawnSide = Bool.random() // True = LEFT, False = RIGHT
         let xPosition: CGFloat = spawnSide ? frame.minX-100 : frame.width + 100
         let yPosition: CGFloat = frame.minY + frame.height * CGFloat.random(in: 0.50...0.85)
         let destinationX: CGFloat = spawnSide ? frame.width + 100 : frame.minX-100
         
         // Create person sprite
 //        let person = SKSpriteNode(texture: spawnSide ? rightTextures[0] : leftTextures[0])
         var owl: SKSpriteNode

         // Assign the appropriate texture and initialize the SKSpriteNode
         if spawnSide{
             owl = SKSpriteNode(texture: owl_rightTextures[0])
         }
         else {
             owl = SKSpriteNode(texture: owl_rightTextures[0])
         }

         // Set properties for the person
         owl.name = "owl"
         owl.position = CGPoint(x: xPosition, y: yPosition)
         owl.xScale = 0.25
         owl.yScale = 0.25
         addChild(owl)
         print("An owl was created.")

         
         var textures : [SKTexture]
         if(spawnSide){
             textures = owl_rightTextures
         }
         else{
             textures = owl_leftTextures
         }
         // Animation based on spawn side
         
 //        let textures = spawnSide ? rightTextures : leftTextures
         let animation = SKAction.animate(with: textures, timePerFrame: 0.25)
         let animationAction = SKAction.repeatForever(animation)
         owl.run(animationAction, withKey: "animation")
         
         // Move across the screen
         let moveDistance = abs(destinationX - xPosition)
         let moveDuration = TimeInterval(moveDistance / 150.0) // Adjust speed by changing the divisor
         let moveAction = SKAction.moveTo(x: destinationX, duration: moveDuration)
         
         // Remove person after movement
         let removeAction = SKAction.removeFromParent()
         
         let sequence = SKAction.sequence([moveAction, removeAction])
         owl.run(sequence, withKey: "movement")
    }
    


    
}

