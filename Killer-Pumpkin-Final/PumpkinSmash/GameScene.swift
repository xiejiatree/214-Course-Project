//
//  GameScene.swift
//  PS
//
//  Created by Zheng, Jenny on 11/17/24.
//
// All the art was made in-house.
// Sound scream sound

import SpriteKit
import GameplayKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    // Game state variables
    var isDraggablePumpkin = true // Set to true at the start of each round
    var isShifting = false // Tracks when objects shift (for animation)
    var roundCounter = 1
    var score = 0 {
        didSet {
            scoreLabel.text = "Score: \(score)"
        }
    }
    
    // Initialize variables
    var goreSound: SKAction!
    var slingshotBase: SKSpriteNode!
    var slingshotBand: SKShapeNode!
    var pumpkin: SKSpriteNode!
    var ground: SKSpriteNode!
    var street_effect: SKSpriteNode!
    
    var buildings: [SKSpriteNode] = []
    var buildings2: [SKSpriteNode] = []
    // Specifications for building nodes
    let buildingXRange: ClosedRange<CGFloat> = 100...3000
    let buildingYPosition: CGFloat = 320
    let totalBuildings = 10
    var lastXPosition: CGFloat = 0
    var people: [SKSpriteNode] = []
    var owls: [SKSpriteNode] = [] // Added owls array
    
    private var scoreboardLabel: SKLabelNode!
    private var scoreboardEntries: [Int] = [] // Initialize scoreboard
    
    // Define attachment points between slingshot band and base
    let slingshotLeftOffset: CGPoint = CGPoint(x: -70, y: 100)
    let slingshotRightOffset: CGPoint = CGPoint(x: 20, y: 130)
    
    // Max range of pumpkin-slingshot interaction
    let maxRange: CGFloat = 300
    
    // Scrolling speed
    let scrollSpeed: CGFloat = 300.0 // pixels per second
    
    var scoreLabel: SKLabelNode!
    var roundsLeftLabel: SKLabelNode!
    
    private var lastUpdateTime: TimeInterval = 0
    let yThreshold: CGFloat = -399.25 // Adjust this value as needed
    
    // Physics categories
    struct PhysicsCategory {
        static let none: UInt32 = 0
        static let pumpkin: UInt32 = 0b1       // 1
        static let wall: UInt32 = 0b10         // 2
        static let person: UInt32 = 0b100      // 4
        static let owl: UInt32 = 0b1000        // 8
    }
    
    override func sceneDidLoad() {
        // Load nodes
        slingshotBase = childNode(withName: "slingshotBase") as? SKSpriteNode
        pumpkin = childNode(withName: "pumpkin") as? SKSpriteNode
        ground = childNode(withName: "ground") as? SKSpriteNode
        street_effect = childNode(withName: "street_effect") as? SKSpriteNode
        loadSounds()
        
        let band = SKShapeNode()
        band.strokeColor = .clear
        band.lineWidth = 5
        band.fillColor = .clear
        band.zPosition = 1
        
        // Pumpkin physics properties
        pumpkin.physicsBody?.categoryBitMask = PhysicsCategory.pumpkin
        pumpkin.physicsBody?.collisionBitMask = PhysicsCategory.wall
        pumpkin.physicsBody?.contactTestBitMask = PhysicsCategory.wall | PhysicsCategory.person | PhysicsCategory.owl
        pumpkin.physicsBody?.isDynamic = true
        pumpkin.physicsBody?.affectedByGravity = false
        pumpkin.physicsBody?.allowsRotation = true
        
        // Set the physics contact delegate
        self.physicsWorld.contactDelegate = self
        
        self.slingshotBand = band
        addChild(band)
        
        // Initialize labels safely
        if let scoreLabelNode = childNode(withName: "ScoreLabel") as? SKLabelNode {
            scoreLabel = scoreLabelNode
            scoreLabel.text = "Score: \(score)"
        } else {
            print("ScoreLabel node not found")
        }
        
        if let roundsLeftLabelNode = childNode(withName: "RoundsLeftLabel") as? SKLabelNode {
            roundsLeftLabel = roundsLeftLabelNode
            roundsLeftLabel.text = "Round: \(roundCounter) / 3"
        } else {
            print("RoundsLeftLabel node not found")
        }
        
        createBuildings()
        createBuildings2()
        restingArc(point: slingshotBase.position)
        startRandomPersonSpawning()
        startRandomOwlSpawning()
        
        self.lastUpdateTime = 0
    }
    
    func loadSounds() {
        goreSound = SKAction.playSoundFileNamed("goreSound.mp3", waitForCompletion: false)
    }
    
    func playGoreSound(){
        run(goreSound)
    }
    
    func createBuildings() {
        for _ in 0..<totalBuildings {
            let building = SKSpriteNode()
            building.texture = SKTexture(imageNamed: "foreground-short")
            building.size = CGSize(width: 500, height: 500)
            building.zPosition = -1
            
            // Randomly set the X position within the range
            let addRandomX = CGFloat.random(in: buildingXRange)
            building.position = CGPoint(x: lastXPosition + addRandomX, y: buildingYPosition)
            lastXPosition = building.position.x
            
            // Add the building to the scene and to the buildings array
            buildings.append(building)
            addChild(building)
        }
    }
    
    func createBuildings2() {
        for _ in 0..<totalBuildings {
            let building = SKSpriteNode()
            building.texture = SKTexture(imageNamed: "background-tall")
            building.size = CGSize(width: 500, height: 500)
            building.zPosition = -1
            
            // Randomly set the X position within the range
            let addRandomX = CGFloat.random(in: buildingXRange)
            building.position = CGPoint(x: lastXPosition + addRandomX, y: buildingYPosition + 50)
            lastXPosition = building.position.x
            
            // Add the building to the scene and to the buildings array
            buildings2.append(building)
            addChild(building)
        }
    }
    
    func restingArc(point: CGPoint) {
        let basePosition = point
        // Calculate the left and right anchor points relative to the slingshotBase
        let slingshotLeft = CGPoint(
            x: basePosition.x + slingshotLeftOffset.x,
            y: basePosition.y + slingshotLeftOffset.y
        )
        let slingshotRight = CGPoint(
            x: basePosition.x + slingshotRightOffset.x,
            y: basePosition.y + slingshotRightOffset.y
        )
        
        // Calculate the control point as the midpoint of the left and right, with an offset
        let controlPoint = CGPoint(
            x: ((slingshotLeft.x + slingshotRight.x) / 2) - 30,
            y: slingshotLeft.y - 200
        )
        
        // Create the path for the slingshot band
        let path = CGMutablePath()
        path.move(to: slingshotLeft)
        path.addQuadCurve(to: slingshotRight, control: controlPoint)
        
        // Assign path to the slingshotBand
        slingshotBand.path = path
        slingshotBand.lineWidth = 5
        slingshotBand.strokeColor = .clear
        slingshotBand.fillColor = .clear
    }
    
    func updateArc(point: CGPoint){
        let distance = hypot(slingshotBase.position.x - pumpkin.position.x, slingshotBase.position.y - pumpkin.position.y)
        
        if distance >= maxRange {
            restingArc(point: slingshotBase.position)
        } else {
            let basePosition = slingshotBase.position
            // Calculate the left and right anchor points relative to the slingshotBase
            let slingshotLeft = CGPoint(
                x: basePosition.x + slingshotLeftOffset.x,
                y: basePosition.y + slingshotLeftOffset.y
            )
            let slingshotRight = CGPoint(
                x: basePosition.x + slingshotRightOffset.x,
                y: basePosition.y + slingshotRightOffset.y
            )
            
            let controlPoint = CGPoint(
                x: (1.1 * point.x),
                y: (1.1 * point.y)
            )
            
            let path = CGMutablePath()
            path.move(to: slingshotLeft)
            path.addQuadCurve(to: slingshotRight, control: controlPoint)
            
            slingshotBand.path = path
            slingshotBand.lineWidth = 5
            slingshotBand.strokeColor = .clear
            slingshotBand.fillColor = .clear
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            
            let touchLocation = touch.location(in: self)
            // Check if the user is currently touching the pumpkin
            if pumpkin.contains(touchLocation) && isDraggablePumpkin {
                // Stop the pumpkin's movement
                pumpkin.physicsBody?.velocity = .zero
                pumpkin.physicsBody?.angularVelocity = 0
                pumpkin.physicsBody?.affectedByGravity = false
            }
            
            let node = self.atPoint(touchLocation)
            
            if node.name == "RestartButton" {
                // Reset the game
                resetGame()
                // Restore element opacity and remove scoreboard/restart button
                for child in self.children {
                    child.alpha = 1.0
                }
                scoreboardLabel.removeFromParent()
                node.removeFromParent() // Remove Restart button
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let touchLocation = touch.location(in: self)
            
            if pumpkin.contains(touchLocation) && isDraggablePumpkin {
                // Ensure that the pumpkin never overlays the ground
                if pumpkin.position.y < (ground.position.y + (ground.size.height / 2) + (pumpkin.size.height / 2)) {
                    pumpkin.position.y = ground.position.y + (ground.size.height / 2) + (pumpkin.size.height / 2) + 2
                } else {
                    pumpkin.position = touchLocation
                }
                updateArc(point: pumpkin.position)
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if isDraggablePumpkin {
            let launchVector = CGVector(
                dx: (slingshotBase.position.x - pumpkin.position.x) * 1,
                dy: (slingshotBase.position.y - pumpkin.position.y) * 8
            )
            pumpkin.physicsBody?.affectedByGravity = true
            pumpkin.physicsBody?.applyImpulse(launchVector)
            // Reset slingshot band after launch
            restingArc(point: slingshotBase.position)
            
            // Let the pumpkin launch without interference for two seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.isDraggablePumpkin = false
            }
            
            isShifting = true
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
        
        // Initialize lastUpdateTime if it has not already been
        if self.lastUpdateTime == 0 {
            self.lastUpdateTime = currentTime
        }
        
        // Calculate time since last update
        let dt = currentTime - self.lastUpdateTime
        
        if isShifting {
            let shiftAmount = -scrollSpeed * CGFloat(dt)
            shiftElements(shiftAmount: shiftAmount)
            
            // Check if pumpkin is grounded or off-screen
            if pumpkin.position.x <= 50 || pumpkin.position.y < yThreshold {
                isShifting = false // Stop shifting when pumpkin hits ground or goes off-screen
                pumpkin.physicsBody?.velocity = .zero
                pumpkin.physicsBody?.angularVelocity = 0
                pumpkin.physicsBody?.affectedByGravity = false
                pumpkin.position = CGPoint(x: 470, y: 250)
                newRound()
            }
        }
        
        // Adjust collisions based on pumpkin's position
        if pumpkin.position.y < yThreshold {
            // Disable collisions with walls
            pumpkin.physicsBody?.collisionBitMask &= ~PhysicsCategory.wall
            pumpkin.physicsBody?.contactTestBitMask &= ~PhysicsCategory.wall
        } else {
            // Enable collisions with walls
            pumpkin.physicsBody?.collisionBitMask |= PhysicsCategory.wall
            pumpkin.physicsBody?.contactTestBitMask |= PhysicsCategory.wall
        }
        
        self.lastUpdateTime = currentTime
    }
    
    func newRound() {
        if roundCounter >= 3 {
            // Show restart menu after the third round
            afterGame()
            return
        }
        
        roundCounter += 1
        roundsLeftLabel.text = "Round: \(roundCounter) / 3"
        
        isShifting = false
        isDraggablePumpkin = true
        
        pumpkin.physicsBody?.affectedByGravity = true
        pumpkin.physicsBody?.isDynamic = true
        pumpkin.physicsBody?.velocity = .zero
        pumpkin.physicsBody?.angularVelocity = 0
        
        slingshotBase.position = CGPoint(x: 790, y: 240)
        slingshotBand.position = CGPoint.zero // Reset slingshotBand position
        pumpkin.position = CGPoint(x: 470, y: 250)
        
        restingArc(point: slingshotBase.position)
    }
    
    func afterGame() {
        isDraggablePumpkin = false
        
        // Dim all game elements
        for child in self.children {
            child.alpha = 0.5
        }
        // Ensure scoreboard is visible on top
        setupScoreboard()
        loadScores()
        updateScoreboard(with: score)
        updateScoreboardDisplay(withAnimation: true)
        scoreboardLabel.zPosition = 100
        
        setupRestartButton()
    }
    
    func setupRestartButton() {
        // Create the Restart button
        let restartButton = SKSpriteNode(color: .blue, size: CGSize(width: 150, height: 60))
        restartButton.position = CGPoint(x: self.frame.midX - 100 , y: self.frame.midY - 250)
        restartButton.name = "RestartButton" // Set an identifier
        let buttonLabel = SKLabelNode(text: "Play Again")
        buttonLabel.fontName = "Impact"
        buttonLabel.fontSize = 24
        buttonLabel.fontColor = .white
        buttonLabel.verticalAlignmentMode = .center
        buttonLabel.position = CGPoint(x: 0, y: 0)
        restartButton.addChild(buttonLabel)
        restartButton.zPosition = 110
        addChild(restartButton)
    }
    
    func resetGame() {
        roundCounter = 0 // Reset to 0 so that it becomes 1 after first `newRound` call
        score = 0
        isDraggablePumpkin = true
        // Update labels
        roundsLeftLabel.text = "Round: \(roundCounter) / 3"
        scoreLabel.text = "Score: \(score)"
        
        // Remove existing people and owls
        for child in self.children {
            if child.name == "person" || child.name == "owl" {
                child.removeFromParent()
            }
        }
        people.removeAll()
        owls.removeAll()
        
        // Reset pumpkin position
        pumpkin.position = CGPoint(x: 470, y: 250)
        pumpkin.physicsBody?.affectedByGravity = true
        pumpkin.physicsBody?.isDynamic = true
        pumpkin.physicsBody?.velocity = .zero
        pumpkin.physicsBody?.angularVelocity = 0
        
        // Restart spawning
        startRandomPersonSpawning()
        startRandomOwlSpawning()
        
        // Start new round
        newRound()
    }
    
    func shiftElements(shiftAmount: CGFloat) {
        // Shift pumpkin and slingshot
        slingshotBase.position.x += shiftAmount
        slingshotBand.position.x += shiftAmount
        pumpkin.position.x += shiftAmount
        
        // Shift buildings
        for building in buildings {
            building.position.x += shiftAmount
            
            // Assign new locations to offscreen buildings
            if building.position.x < -50 {
                building.position.x = CGFloat.random(in: 3000...4000)
            }
        }
        
        // Shift people
        for (index, person) in people.enumerated().reversed() {
            person.position.x += shiftAmount
            
            // Remove offscreen people
            if person.position.x < -50 {
                person.removeFromParent()
                people.remove(at: index)
            }
        }
        
        // Shift owls
        for (index, owl) in owls.enumerated().reversed() {
            owl.position.x += shiftAmount
            
            // Remove offscreen owls
            if owl.position.x < -50 {
                owl.removeFromParent()
                owls.remove(at: index)
            }
        }
    }
    
    func setupScoreboard() {
        // Create the scoreboard label in the center
        scoreboardLabel = SKLabelNode(fontNamed: "Impact")
        scoreboardLabel.fontSize = 40
        scoreboardLabel.fontColor = .systemBlue
        scoreboardLabel.numberOfLines = 6
        scoreboardLabel.horizontalAlignmentMode = .center
        scoreboardLabel.verticalAlignmentMode = .center
        scoreboardLabel.position = CGPoint(x: self.frame.midX - 100, y: self.frame.midY)
        addChild(scoreboardLabel)
    }
    
    func updateScoreboardDisplay(withAnimation animated: Bool) {
        // Update the scoreboard with current entries
        scoreboardLabel.text = "Top Scores:\n" + scoreboardEntries.map { "\($0)" }.joined(separator: "\n")
        
        if animated {
            let scaleUp = SKAction.scale(to: 1.2, duration: 0.2)
            let scaleDown = SKAction.scale(to: 1.0, duration: 0.2)
            let sequence = SKAction.sequence([scaleUp, scaleDown])
            scoreboardLabel.run(sequence)
        }
    }
    
    func updateScoreboard(with newScore: Int) {
        // Add the new score to the scoreboard
        if scoreboardEntries.count < 5 {
            scoreboardEntries.append(newScore)
        } else if let minScore = scoreboardEntries.min(), newScore > minScore {
            // Replace the smallest score if the new score is greater
            if let index = scoreboardEntries.firstIndex(of: minScore) {
                scoreboardEntries[index] = newScore
            }
        }
        // Sort scores in descending order
        scoreboardEntries.sort(by: >)
        saveScores() // Save scores to UserDefaults
    }
    
    func saveScores() {
        // Save the scores to UserDefaults
        UserDefaults.standard.set(scoreboardEntries, forKey: "TopScores")
    }
    
    func loadScores() {
        // Load the scores from UserDefaults
        if let savedScores = UserDefaults.standard.array(forKey: "TopScores") as? [Int] {
            scoreboardEntries = savedScores
        } else {
            scoreboardEntries = [0, 0, 0, 0, 0] // Default scores
        }
    }
    
    func startRandomPersonSpawning() {
        let spawnAction = SKAction.run { [weak self] in
            self?.createPerson()
            print("createPerson Called!")
        }
        let waitAction = SKAction.wait(forDuration: TimeInterval.random(in: 1.0...2.0))
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
        let girlRightTextures = [
            SKTexture(imageNamed: "right-girl-frame1"),
            SKTexture(imageNamed: "right-girl-frame2"),
            SKTexture(imageNamed: "right-girl-frame3"),
            SKTexture(imageNamed: "right-girl-frame4")
        ]
        let girlLeftTextures = [
            SKTexture(imageNamed: "left-girl-frame1"),
            SKTexture(imageNamed: "left-girl-frame2"),
            SKTexture(imageNamed: "left-girl-frame3"),
            SKTexture(imageNamed: "left-girl-frame4")
        ]
        
        // Random spawn side and type
        let spawnSide = Bool.random() // True = LEFT, False = RIGHT
        let boyOrGirl = Bool.random() // True = GIRL, False = BOY
        
        let xPosition: CGFloat = spawnSide ? frame.minX - 100 : frame.width + 100
        let yPosition: CGFloat = frame.minY + frame.height * 0.25 - 150
        let destinationX: CGFloat = spawnSide ? frame.width + 100 : frame.minX - 100
        
        // Create person sprite
        var person: SKSpriteNode
        
        // Assign the appropriate texture and initialize the SKSpriteNode
        if spawnSide && boyOrGirl {
            person = SKSpriteNode(texture: girlRightTextures[0])
        } else if spawnSide && !boyOrGirl {
            person = SKSpriteNode(texture: rightTextures[0])
        } else if !spawnSide && boyOrGirl {
            person = SKSpriteNode(texture: girlLeftTextures[0])
        } else {
            person = SKSpriteNode(texture: leftTextures[0])
        }
        
        // Set properties for the person
        person.name = "person"
        person.position = CGPoint(x: xPosition, y: yPosition)
        person.size = CGSize(width: 150, height: 150)
        person.zPosition = 1
        
        // Assign physics body to the person
        person.physicsBody = SKPhysicsBody(rectangleOf: person.size)
        person.physicsBody?.isDynamic = false  // People are static in terms of physics simulation
        person.physicsBody?.categoryBitMask = PhysicsCategory.person
        person.physicsBody?.collisionBitMask = PhysicsCategory.none
        person.physicsBody?.contactTestBitMask = PhysicsCategory.pumpkin
        
        addChild(person)
        people.append(person) // Add to people array
        print("A person was created, spawnSide = \(spawnSide), boyOrGirl = \(boyOrGirl)")
        
        // Animation based on spawn side and gender
        var textures: [SKTexture]
        if spawnSide && boyOrGirl {
            textures = girlRightTextures
        } else if spawnSide && !boyOrGirl {
            textures = rightTextures
        } else if !spawnSide && boyOrGirl {
            textures = girlLeftTextures
        } else {
            textures = leftTextures
        }
        let animation = SKAction.animate(with: textures, timePerFrame: 0.25)
        let animationAction = SKAction.repeatForever(animation)
        person.run(animationAction, withKey: "animation")
        
        // Move across the screen
        let moveDistance = abs(destinationX - xPosition)
        let moveDuration = TimeInterval(moveDistance / 100.0) // Adjust speed by changing the divisor
        let moveAction = SKAction.moveTo(x: destinationX, duration: moveDuration)
        let removeAction = SKAction.run { [weak self] in
            person.removeFromParent()
            if let index = self?.people.firstIndex(of: person) {
                self?.people.remove(at: index)
            }
        }
        let sequence = SKAction.sequence([moveAction, removeAction])
        person.run(sequence, withKey: "movement")
    }
    
    func startRandomOwlSpawning() {
        let spawnAction = SKAction.run { [weak self] in
            self?.createOwl()
            print("createOwl Called!")
        }
        let waitAction = SKAction.wait(forDuration: TimeInterval.random(in: 5.0...10.0))
        let sequence = SKAction.sequence([spawnAction, waitAction])
        let repeatAction = SKAction.repeatForever(sequence)
        run(repeatAction, withKey: "spawnOwls")
    }
    
    func createOwl() {
        // Define textures
        let owlRightTextures = [
            SKTexture(imageNamed: "owl-right-frame1"),
            SKTexture(imageNamed: "owl-right-frame2"),
            SKTexture(imageNamed: "owl-right-frame3"),
            SKTexture(imageNamed: "owl-right-frame4")
        ]
        let owlLeftTextures = [
            SKTexture(imageNamed: "owl-left-frame1"),
            SKTexture(imageNamed: "owl-left-frame2"),
            SKTexture(imageNamed: "owl-left-frame3"),
            SKTexture(imageNamed: "owl-left-frame4")
        ]
        
        // Random spawn side
        let spawnSide = Bool.random() // True = LEFT, False = RIGHT
        let xPosition: CGFloat = spawnSide ? frame.minX - 100 : frame.width + 100
        let yPosition: CGFloat = frame.minY + frame.height * CGFloat.random(in: 0.50...0.85)
        let destinationX: CGFloat = spawnSide ? frame.width + 100 : frame.minX - 100
        
        // Create owl sprite
        let owlTexture = spawnSide ? owlRightTextures[0] : owlLeftTextures[0]
        let owl = SKSpriteNode(texture: owlTexture)
        
        // Set properties for the owl
        owl.name = "owl"
        owl.position = CGPoint(x: xPosition, y: yPosition)
        owl.xScale = 0.15
        owl.yScale = 0.15
        
        owl.physicsBody = SKPhysicsBody(rectangleOf: owl.size)
        owl.physicsBody?.isDynamic = false
        owl.physicsBody?.categoryBitMask = PhysicsCategory.owl
        owl.physicsBody?.collisionBitMask = PhysicsCategory.none
        owl.physicsBody?.contactTestBitMask = PhysicsCategory.pumpkin
        
        addChild(owl)
        owls.append(owl) // Add to owls array
        print("An owl was created.")
        
        // Animation based on spawn side
        let textures = spawnSide ? owlRightTextures : owlLeftTextures
        let animation = SKAction.animate(with: textures, timePerFrame: 0.25)
        let animationAction = SKAction.repeatForever(animation)
        owl.run(animationAction, withKey: "animation")
        
        // Move across the screen
        let moveDistance = abs(destinationX - xPosition)
        let moveDuration = TimeInterval(moveDistance / 150.0)
        let moveAction = SKAction.moveTo(x: destinationX, duration: moveDuration)
        let removeAction = SKAction.run { [weak self] in
            owl.removeFromParent()
            if let index = self?.owls.firstIndex(of: owl) {
                self?.owls.remove(at: index)
            }
        }
        let sequence = SKAction.sequence([moveAction, removeAction])
        owl.run(sequence, withKey: "movement")
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        var firstBody: SKPhysicsBody
        var secondBody: SKPhysicsBody
        
        // Sort the bodies so the one with the lower category bit mask is first
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
            firstBody = contact.bodyA
            secondBody = contact.bodyB
        } else {
            firstBody = contact.bodyB
            secondBody = contact.bodyA
        }
        
        // Check if the pumpkin has contacted a person or an owl
        if firstBody.categoryBitMask == PhysicsCategory.pumpkin &&
            (secondBody.categoryBitMask == PhysicsCategory.person || secondBody.categoryBitMask == PhysicsCategory.owl) {
            
            if let hitNode = secondBody.node as? SKSpriteNode {
                playHitAnimation(on: hitNode)
                run(goreSound)
                print("Pumpkin hit a \(hitNode.name ?? "unknown")! Node removed after animation.")
                score += 1
            }
        }
    }
    
    func playHitAnimation(on node: SKSpriteNode) {
        // Ensure the node is either a person or an owl
        guard let nodeName = node.name, nodeName == "person" || nodeName == "owl" else {
            return
        }
        
        // Remove existing actions
        node.removeAllActions()
        
        // Remove physics body to prevent further collisions
        node.physicsBody = nil
        
        // Prepare the hit animation textures
        let hitTextures = [
            SKTexture(imageNamed: "gore-frame1"),
            SKTexture(imageNamed: "gore-frame2"),
            SKTexture(imageNamed: "gore-frame3"),
            SKTexture(imageNamed: "gore-frame4")
        ]
        
        // Create the animation action
        let hitAnimation = SKAction.animate(with: hitTextures, timePerFrame: 0.1)
        
        let scaleUpAction = SKAction.scale(to: 2.0, duration: 0.4)
        
        let playGoreSoundAction = SKAction.run { [weak self] in
            self?.playGoreSound()
        }
        
        // After the animation completes, remove the node and update arrays
        let removeAction = SKAction.run { [weak self] in
            node.removeFromParent()
            if nodeName == "person" {
                if let index = self?.people.firstIndex(of: node) {
                    self?.people.remove(at: index)
                }
            } else if nodeName == "owl" {
                if let index = self?.owls.firstIndex(of: node) {
                    self?.owls.remove(at: index)
                }
            }
        }
        
        // Create a sequence of the animation and the removal
        let sequence = SKAction.sequence([playGoreSoundAction, hitAnimation, removeAction])
        
        // Run the sequence on the node
        node.run(SKAction.group([sequence, scaleUpAction]))
    }
}

