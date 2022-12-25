//
//  ViewController.swift
//  EmojiPop-Storyboard
//
//  Created by Zaid Neurothrone on 2022-12-25.
//

import UIKit
import SpriteKit
import ARKit

class ViewController: UIViewController {
  
  @IBOutlet var sceneView: ARSKView!
  @IBOutlet weak var hudLabel: UILabel!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // Set the view's delegate
    sceneView.delegate = self
    
    // Show statistics such as fps and node count
    sceneView.showsFPS = true
    sceneView.showsNodeCount = true
    
    // Load the SKScene from 'Scene.sks'
    if let scene = SKScene(fileNamed: "Scene") {
      sceneView.presentScene(scene)
    }
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    // Create a session configuration
    let configuration = ARWorldTrackingConfiguration()
    
    // Run the view's session
    sceneView.session.run(configuration)
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    
    // Pause the view's session
    sceneView.session.pause()
  }
  
  //MARK: - Custom methods
  func showAlert(_ title: String, _ message: String) {
    let alert = UIAlertController(
      title: title,
      message: message,
      preferredStyle: .alert
    )
    
    alert.addAction(
      UIAlertAction(
        title: "OK",
        style: UIAlertAction.Style.default,
        handler: nil
      )
    )
    
    self.present(alert, animated: true, completion: nil)
  }
}

// MARK: - ARSKViewDelegate conformance
extension ViewController: ARSKViewDelegate {
  func view(_ view: ARSKView, nodeFor anchor: ARAnchor) -> SKNode? {
    // After the app creates the AR anchor, you’ll use the delegate to provide a SKNode for the new anchor. This SpriteKit node acts as the Spawn Point for the game.
    
    // This creates an empty SpriteKit node and sets its name to SpawnPoint
    let spawnNode = SKNode()
    spawnNode.name = "SpawnPoint"
    
    // To give the player a visual indicator of where the spawn point is in the real world, this creates a little SOS box and adds it as a child of the spawn point node
    let boxNode = SKLabelNode(text: "🆘")
    boxNode.verticalAlignmentMode = .center
    boxNode.horizontalAlignmentMode = .center
    boxNode.zPosition = 100
    boxNode.setScale(0)
    spawnNode.addChild(boxNode)
    
    // Animate SOS up scale: This creates and runs an action sequence consisting of a sound effect and a scale effect on the created box node. It slowly scales the box to 1.5 while playing a nice sound effect.
    let startSoundAction = SKAction.playSoundFileNamed(
      "SoundEffects/GameStart.wav",
      waitForCompletion: false
    )
    let scaleInAction = SKAction.scale(to: 1.5, duration: 0.8)
    
    boxNode.run(
      SKAction.sequence([
        startSoundAction,
        scaleInAction
      ])
    )
    
    // Finally, the spawnNode is provided as the SKNode for the newly-added AR anchor. This also links the spawn node to the AR anchor. Any changes to the AR anchor will be synced to the spawn node.
    return spawnNode

    
//    // Create and configure a node for the anchor added to the view's session.
//    let labelNode = SKLabelNode(text: "👾")
//    labelNode.horizontalAlignmentMode = .center
//    labelNode.verticalAlignmentMode = .center
//    return labelNode;
  }
  
  //MARK: - Handling AR Session Failures: Typically occur when the AR session has stopped due to some kind of failure
  func session(_ session: ARSession, didFailWithError error: Error) {
    showAlert("Session Failure", error.localizedDescription)
  }
  
  //MARK: - Handling AR Session Interruptions: This issue happens when the session has temporarily stopped processing frames and device position tracking — typically because the player took a phone call or switched to a different app
  func sessionWasInterrupted(_ session: ARSession) {
    // Inform the user that the session has been interrupted, for example, by presenting an overlay
    showAlert("AR Session", "Session was interrupted!")
  }
  
  func sessionInterruptionEnded(_ session: ARSession) {
    // Reset tracking and/or remove existing anchors if consistent tracking is required
    let scene = sceneView.scene as! Scene
    scene.startGame()
  }
  
  //MARK: - Handling Camera Tracking Issues: These occur when the quality of ARKit’s position tracking has degraded for some reason
  func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
    // You can access the current tracking state through the provided camera. Th switch statement then handles all possible cases. If there’s a problem, you then notify the player with an alert message.
    switch camera.trackingState {
    case .normal: break
    case .notAvailable:
      showAlert("Tracking Limited", "AR not available")
      break
      // When tracking is limited, you can dig deeper to find out exactly why. Again, you have a few cases to deal with. You’ll then send the player an alert message with the result.
    case .limited(let reason):
      switch reason {
      case .initializing, .relocalizing: break
      case .excessiveMotion:
        showAlert("Tracking Limited", "Excessive motion!")
        break
      case .insufficientFeatures:
        showAlert("Tracking Limited", "Insufficient features!")
        break
      default: break
      }
    }
  }
}

/*
 ARSKViewDelegate functions:
 
 func view(_:nodeFor:) -> SKNode: Call this when the app adds a new AR anchor. Note that it returns a SKNode, so this is a good place to create and link a SpriteKit node to the newly-added AR anchor.

 func view(_:didAdd:for:): Informs the delegate that a SpriteKit node related to a new AR anchor has been added to the scene.

 func view(_:willUpdate:for:): Informs the delegate that a SpriteKit node will be updated based on changes to the related AR anchor.

 func view(_:didUpdate:for:): Informs the delegate that a SpriteKit node has been updated to match changes on the related AR anchor.

 func view(_:didRemove:for:): Informs the delegate that the SpriteKit node has been removed from the scene on the related AR anchor.
 */
