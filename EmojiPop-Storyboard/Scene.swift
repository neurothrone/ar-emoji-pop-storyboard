//
//  Scene.swift
//  EmojiPop-Storyboard
//
//  Created by Zaid Neurothrone on 2022-12-25.
//

import ARKit
import SpriteKit

public enum GameState {
  case Init
  case TapToStart
  case Playing
  case GameOver
}

var gameState = GameState.Init
var anchor: ARAnchor?
var emojis = "😁😂😛😝😋😜🤪😎🤓🤖🎃💀🤡"
var spawnTime : TimeInterval = 0
var score : Int = 0
var lives : Int = 10


class Scene: SKScene {
  
  func updateHUD(_ message: String) {
    guard let sceneView = view as? ARSKView else { return }
    
    let viewController = sceneView.delegate as! ViewController
    viewController.hudLabel.text = message
  }
  
  public func startGame() {
    gameState = .TapToStart
    updateHUD("- TAP TO START -")
    
    removeAnchor()
  }
  
  public func playGame() {
    gameState = .Playing
    score = 0
    lives = 10
    spawnTime = 0
    
    addAnchor()
  }
  
  public func stopGame() {
    gameState = .GameOver
    updateHUD("GAME OVER! SCORE: " + String(score))
  }
  
  func addAnchor() {
    // This casts the view as an ARSKSView so you can access the current AR session.
    guard let sceneView = self.view as? ARSKView else { return }
    
    // This gets the current active frame from the AR session, which contains the camera. You’ll use the cameras transform information to create an AR anchor in front of the camera view.
    if let currentFrame = sceneView.session.currentFrame {
      // This calculates a new transform located 50cm in front of the camera’s view.
      var translation = matrix_identity_float4x4
      translation.columns.3.z = -0.5
      let transform = simd_mul(currentFrame.camera.transform, translation)
      
      // Finally, this creates an AR anchor with the new transform information and adds it to the AR session.
      anchor = ARAnchor(transform: transform)
      sceneView.session.add(anchor: anchor!)
    }
  }
  
  func removeAnchor() {
    guard let sceneView = self.view as? ARSKView else { return }
    
    if anchor != nil {
      sceneView.session.remove(anchor: anchor!)
    }
  }
  
  func spawnEmoji() {
    // Creates a new SKLabelNode using a random emoji character from the string of emojis available in emojis. The node is named Emoji and it’s centered vertically and horizontally.
    let emojiNode = SKLabelNode(
      text: String(emojis.randomElement()!)
    )
    
    emojiNode.name = "Emoji"
    emojiNode.horizontalAlignmentMode = .center
    emojiNode.verticalAlignmentMode = .center
    
    // Interrogates the available node in scene, looking for the node named SpawnPoint. It then adds the newly-created emoji as a child of spawnNode. This places the emoji into the scene.
    guard let sceneView = self.view as? ARSKView else { return }
    
    let spawnNode = sceneView.scene?.childNode(withName: "SpawnPoint")
    spawnNode?.addChild(emojiNode)
    
    // Enable Physics
    // This creates a new, circular-shaped physics body that you’ll attach to the emoji node’s physicsBody. The physical mass of the body is set to 10 grams.
    emojiNode.physicsBody = SKPhysicsBody(circleOfRadius: 15)
    emojiNode.physicsBody?.mass = 0.01
    
    // Add Impulse
    emojiNode.physicsBody?.applyImpulse(
      CGVector(
        dx: -5 + 10 * randomCGFloat(),
        dy: 10
      )
    )
    
    // Add Torque
    // Positive -> Spins to the right
    // Negative <- Spins to the left
    emojiNode.physicsBody?.applyTorque(-0.2 + 0.4 * randomCGFloat())
    
    // Sound Effects & Actions
    // Creates a few basic actions that you’ll use in just a moment. They’re fairly self-explanatory based on their names and action types.
    let spawnSoundAction = SKAction.playSoundFileNamed(
          "SoundEffects/Spawn.wav", waitForCompletion: false)
    let dieSoundAction = SKAction.playSoundFileNamed(
          "SoundEffects/Die.wav", waitForCompletion: false)
    let waitAction = SKAction.wait(forDuration: 3)
    let removeAction = SKAction.removeFromParent()
    
    // Creates a custom code block action that decreases the lives by one. When all the lives are depleted, the game stops.
    let runAction = SKAction.run {
      lives -= 1
      if lives <= .zero {
        self.stopGame()
      }
    }

    // Creates a single action sequence that consists of all the previously-created actions. You then run the sequence action against the freshly-spawned emojis. The resulting action sequence will play out as follows, as soon as an emoji is spawned: Play spawn sound ▸ Wait for three seconds ▸ Play die sound ▸ Decrease lives / stop game ▸ Remove emojis from scene.
    let sequenceAction = SKAction.sequence([
      spawnSoundAction,
      waitAction,
      dieSoundAction,
      runAction,
        removeAction
    ])
    
    emojiNode.run(sequenceAction)
  }
  
  func randomCGFloat() -> CGFloat {
    CGFloat(Float(arc4random()) / Float(UINT32_MAX))
  }
  
  func checkTouches(_ touches: Set<UITouch>) {
    // This takes the first available touch from a provided list of touches. It then uses the touched screen location to do a quick raycast into the scene, determining whether the player hit any of the available SKNodes
    guard let touch = touches.first else { return }
    
    let touchLocation = touch.location(in: self)
    let touchedNode = self.atPoint(touchLocation)
    
    // If the player touched a node, and it’s indeed an emoji node, the score increases by 1
    if touchedNode.name != "Emoji" { return }
    score += 1
    
    // Finally, you create and run an action sequence consisting of a sound effect and an action that will remove the emoji node from its parent node — ultimately destroying the touched emoji by removing it from the scene
    let collectSoundAction = SKAction.playSoundFileNamed(
      "SoundEffects/Collect.wav",
      waitForCompletion: false
    )
    let removeAction = SKAction.removeFromParent()
    
    let sequenceAction = SKAction.sequence([
      collectSoundAction,
      removeAction
    ])
    
    touchedNode.run(sequenceAction)
  }


  
  //MARK: - SKScene
  override func didMove(to view: SKView) {
    // Setup your scene here
    startGame()
  }
  
  override func update(_ currentTime: TimeInterval) {
    // Called before each frame is rendered
    
    // You only want to update the game while it’s in the Playing state.
    if gameState != .Playing { return }
    
    // If spawnTime is 0, the game just started so you give the player a few seconds to prepare for the onslaught of emojis that are about to spawn. This creates a slight delay of 3 seconds before the first emoji spawns.
    if spawnTime == 0 { spawnTime = currentTime + 3 }
    
    // Once spawnTime is less than currentTime, it’s time to spawn a new emoji. Once spawned, you reset spawnTime to wait for another half a second before spawning the next emoji.
    if spawnTime < currentTime {
      spawnEmoji()
      spawnTime = currentTime + 0.5;
    }
    
    // Finally, you update the HUD with the current score and available lives.
    updateHUD("SCORE: " + String(score) + " | LIVES: " + String(lives))
  }
  
  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    switch (gameState) {
    case .Init:
      break
      
    case .TapToStart:
      playGame()
      break
      
    case .Playing:
      checkTouches(touches)
      break
      
    case .GameOver:
      startGame()
      break
    }
  }
}
