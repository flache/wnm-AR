//
//  ViewController.swift
//  DVFoodhack-artest
//
//  Created by Felix Lachenmaier on 07.09.19.
//  Copyright © 2019 Felix Lachenmaier. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    var sceneController = HoverScene()
    
    var didInitializeScene: Bool = false
    var planes = [ARPlaneAnchor: Plane]()
    let feedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
    var visibleGrid: Bool = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints, ARSCNDebugOptions.showWorldOrigin]
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        // Create a new scene
        if let scene = sceneController.scene {
            // Set the scene to the view
            sceneView.scene = scene
        }
        
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(ViewController.didTapScreen))
        tapRecognizer.numberOfTapsRequired = 1
        tapRecognizer.numberOfTouchesRequired = 1
        self.view.addGestureRecognizer(tapRecognizer)
        
        let doubleTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(ViewController.didDoubleTapScreen))
        doubleTapRecognizer.numberOfTapsRequired = 2
        doubleTapRecognizer.numberOfTouchesRequired = 1
        self.view.addGestureRecognizer(doubleTapRecognizer)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        
        guard let referenceObjects = ARReferenceObject.referenceObjects(inGroupNamed: "AR Resources", bundle: nil) else {
            fatalError("Missing expected asset catalog resources.")
        }
        configuration.detectionObjects = referenceObjects
        configuration.planeDetection = [.horizontal]


        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }

    // MARK: - ARSCNViewDelegate
    

    /*
     // Override to create and configure nodes for anchors added to the view's session.
     func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
     let node = SCNNode()
     
     return node
     }
     */
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        DispatchQueue.main.async {
            if let planeAnchor = anchor as? ARPlaneAnchor {
                
                let plane = self.addPlane(node: node, anchor: planeAnchor)
                
                if let planeParent = plane.parent {
                   // self.sceneController.addBucket(parent: planeParent)
                }
                self.feedbackGenerator.impactOccurred()
            }
            
            if let milkAnchor = anchor as? ARObjectAnchor {

                
                let textPos = SCNVector3Make(
                milkAnchor.transform.columns.3.x,
                milkAnchor.transform.columns.3.y + 0.2,
                milkAnchor.transform.columns.3.z
                )
//                if let attachTextNode = node.parent {
                    self.sceneController.addText(string: "Milk | 10 Days", parent: node, position: textPos)
//                }
                
            }
        }
    }
    
    @objc func didDoubleTapScreen(recognizer: UITapGestureRecognizer) {
        if didInitializeScene {
            self.visibleGrid = !self.visibleGrid
            planes.forEach({ (_, plane) in
                plane.setPlaneVisibility(self.visibleGrid)
            })
        }
    }
    
    @objc func didTapScreen(recognizer: UITapGestureRecognizer) {
        print("1")
        if didInitializeScene {
            print("2")
            if let camera = sceneView.session.currentFrame?.camera {
                print("3")
                let tapLocation = recognizer.location(in: sceneView)
                let hitTestResults = sceneView.hitTest(tapLocation)
                if let node = hitTestResults.first?.node, let scene = sceneController.scene {
                    print("4")
                    if let plane = node.parent as? Plane, let planeParent = plane.parent, let hitResult = hitTestResults.first {
                        print("5")
                        
                        sceneController.addBucket(parent: planeParent)
                    }
                }
            }
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        DispatchQueue.main.async {
            if let planeAnchor = anchor as? ARPlaneAnchor {
                self.updatePlane(anchor: planeAnchor)
            }
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        
    }
    
    
    func addPlane(node: SCNNode, anchor: ARPlaneAnchor) -> Plane {
        let plane = Plane(anchor)
        planes[anchor] = plane
        plane.setPlaneVisibility(self.visibleGrid)
        
        node.addChildNode(plane)
        print("Added plane: \(plane)")
        return plane
    }
    
    func updatePlane(anchor: ARPlaneAnchor) {
        if let plane = planes[anchor] {
            plane.update(anchor)
        }
    }
    
    func removePlane(anchor: ARPlaneAnchor) {
        if let plane = planes.removeValue(forKey: anchor) {
            plane.removeFromParentNode()
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        if let camera = sceneView.session.currentFrame?.camera {
            didInitializeScene = true
            
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
