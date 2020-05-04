//
//  ViewController.swift
//  Udacity Project
//
//  Created by Kian Maroofi on 11/2/17.
//  Copyright © 2017 Kian Maroofi. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    
    var alreadyPlacedHat:Bool = false
    var balls: [SCNNode] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        //sceneView.showsStatistics = true
        //sceneView.debugOptions = [.showPhysicsShapes]
        
        // Set the scene to the view
        sceneView.scene = SCNScene()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        // Run the view's session
        sceneView?.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView?.session.pause()
    }
    
    
    // plane detection
    private var planeNode: SCNNode?
    
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        guard let _ = anchor as? ARPlaneAnchor else {
            return nil
        }
        planeNode = SCNNode()
        
        return planeNode
    }
    
    private func putHatOnPlane(anchor: ARPlaneAnchor, node: SCNNode) {
        guard let url = Bundle.main.url(forResource: "art.scnassets/magic", withExtension: "scn") else {
            NSLog("Could not find magic hat show scene")
            return
        }
        guard let hatNode = SCNReferenceNode(url: url) else { return }
        
        hatNode.load()
        //hatNode.position = SCNVector3Make(node.position.x, node.position.y, node.position.z)
        hatNode.position = SCNVector3Make(anchor.center.x, anchor.center.y , anchor.center.z)
        node.addChildNode(hatNode)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else {
            return
        }
        let plane = SCNPlane(width: CGFloat(planeAnchor.extent.x + 4.0), height: CGFloat(planeAnchor.extent.z + 4.0))
        
        let planeMaterial = SCNMaterial()
        planeMaterial.diffuse.contents = UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 0
        )
        plane.materials = [planeMaterial]
        
        let planeNode = SCNNode(geometry: plane)
        planeNode.position = SCNVector3Make(planeAnchor.center.x, 0, planeAnchor.center.z)
        let physicsType = SCNPhysicsBody(type: .kinematic, shape: SCNPhysicsShape(geometry: plane))
        physicsType.collisionBitMask = -3
        physicsType.categoryBitMask = 2
        physicsType.contactTestBitMask = 0
        planeNode.physicsBody = physicsType
        planeNode.transform = SCNMatrix4MakeRotation(-Float.pi / 2, 1, 0, 0)
        node.addChildNode(planeNode)
        // after detecting an ARPlane calling a method to put a hat on the detected plane
        if (!alreadyPlacedHat) {
            putHatOnPlane(anchor: planeAnchor, node: node)
            alreadyPlacedHat = true
        } else {
            NSLog("already placed the hat")
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }
    
    
    // Throw balls into the hat
    @IBAction func throwBall(_ sender: Any) {
        NSLog("throw ball")
        let ball = SCNSphere(radius: 0.025)
        let ballNode = SCNNode(geometry: ball)
        let camera = sceneView.session.currentFrame!.camera
        let cameraTransform = camera.transform
        // Changed forceDirection and computing the rotation of device in order to always throw the ball in a perpendicular situation to the phones surface
        let forceDirection = simd_make_float4(0, 0, -36, 0)
        let forceRotated = simd_mul(cameraTransform, forceDirection)
        let forceVector = SCNVector3Make(forceRotated.x, forceRotated.y, forceRotated.z)
        let physicsBody = SCNPhysicsBody(type: .dynamic, shape: SCNPhysicsShape(geometry: ball, options: nil))
        ballNode.simdTransform = cameraTransform
        ballNode.name = "ball"
        physicsBody.isAffectedByGravity = true
        physicsBody.allowsResting = true
        physicsBody.mass = 0.4
        physicsBody.restitution = 1
        physicsBody.friction = 0.5
        physicsBody.collisionBitMask = -1
        physicsBody.categoryBitMask = 1
        physicsBody.contactTestBitMask = 1
        physicsBody.applyForce(forceVector, asImpulse: false)
        ballNode.physicsBody = physicsBody
        ballNode.scale = SCNVector3Make(1, 1, 1)
        balls.append(ballNode)
        sceneView.scene.rootNode.addChildNode(ballNode)
        
    }
    
    //toggle visibility of the balls (magic)
    @IBAction func showMagic(_ sender: Any) {
        NSLog("show magic hat")
        guard let hatTube = sceneView.scene.rootNode.childNode(withName: "tube1", recursively: true) else {return}
        let hatWorldPosition = hatTube.worldPosition
        let (tubeMin, tubeMax): (SCNVector3, SCNVector3) = hatTube.boundingBox
        let minX = hatWorldPosition.x + tubeMin.x
        let minY = hatWorldPosition.y + tubeMin.y
        let minZ = hatWorldPosition.z + tubeMin.z
        
        let maxX = hatWorldPosition.x + tubeMax.x
        let maxY = hatWorldPosition.y + tubeMax.y
        let maxZ = hatWorldPosition.z + tubeMax.z
        for ball in balls {
            let pos = ball.presentation.worldPosition
            let condition = pos.x < maxX && pos.y < maxY && pos.z < maxZ && pos.x >= minX && pos.y >= minY && pos.z >= minZ
            if (condition) {
                ball.isHidden = !ball.isHidden
            }
        }
    }
    
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
}
