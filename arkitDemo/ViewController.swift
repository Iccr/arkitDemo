//
//  ViewController.swift
//  arkitDemo
//
//  Created by shishir sapkota on 11/1/17.
//  Copyright © 2017 shishir sapkota. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!

    let nodeRadius: CGFloat = 0.01
    
    var points: [SCNVector3] = [] {
        didSet {
            if points.count >= 2 {
                self.tap?.isEnabled = false
                self.buttonActivate.setTitle("passive", for: .normal)
                self.createPlane()
            }
        }
        
    }
    var tap: UITapGestureRecognizer?
    @IBOutlet weak var buttonActivate: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
    
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        sceneView.session.run(configuration)
        self.sceneView.debugOptions  = [.showConstraints, .showLightExtents, ARSCNDebugOptions.showFeaturePoints, ARSCNDebugOptions.showWorldOrigin]

        self.sceneView.showsStatistics = true
        self.sceneView.automaticallyUpdatesLighting = true

        tap = UITapGestureRecognizer(target: self, action: #selector(tapped(sender:)))
        self.view.addGestureRecognizer(tap!)
        
    }
    
    
    @IBAction func buttonActivate(_ sender: UIButton) {
            self.tap?.isEnabled = true
            self.buttonActivate.setTitle("active", for: .normal)
    }

    
    @objc
    func tapped(sender: UITapGestureRecognizer) {
        let currentFame = sceneView.session.currentFrame
//        addSnapshot(at: currentFame)
        let point = sender.location(in: self.sceneView)
         guard let currentframe = currentFame else {return}
        
        if let position = doHitTestingOnExistingPlane(point) {
            self.points.append(position)
            addNode(at: position)
        }
        
    }
    
    func createPlane() {
        let distance = getDistance()
        
        let plane = SCNPlane.init(width: CGFloat(distance), height: CGFloat(distance))
        plane.firstMaterial?.diffuse.contents = UIColor.red
        let planeNode = SCNNode(geometry: plane)
        
        guard let node1 = self.points.first, let node2 = self.points.last else { return }
        
        
        let mid1X = (node1.x)
        
        let mid1y = (node1.y)
        
        let mid1z: Float = 0.001
        
        let planePosition = SCNVector3Make(mid1X, mid1y, mid1z)
        
        planeNode.position = planePosition
        
        self.sceneView.scene.rootNode.addChildNode(planeNode)
        
    }
    
    
    func getDistance()  -> Float {
        print(points)
        print(points.first)
        print(points.last)
        let node1Pos = points.first!
        let node2Pos = points.last!
        let distance = SCNVector3(
            node2Pos.x - node1Pos.x,
            node2Pos.y - node1Pos.y,
            node2Pos.z - node1Pos.z
        )
        let length: Float = sqrtf(distance.x * distance.x + distance.y * distance.y + distance.z * distance.z)
        return length
    }
    
    func addNode(at position: SCNVector3) {
        let node = nodeWithPosition(position)
        print(node)
        sceneView.scene.rootNode.addChildNode(node)
    }

    
    func doHitTestingOnExistingPlane(_ point: CGPoint) -> SCNVector3? {
        let results = sceneView.hitTest(point, types: ARHitTestResult.ResultType.estimatedHorizontalPlane)
       // print(results)
        
        if let result = results.first {
           return createNodeAtPositionOf(result: result)
            
        }
        return nil
    }
    
    
    func createNodeAtPositionOf(result: ARHitTestResult) -> SCNVector3 {
        let position = positionFromTransfrom(result.worldTransform)
        let node = nodeWithPosition(position)
        print(position)
        self.sceneView.scene.rootNode.addChildNode(node)
        return position
    }
    
    func positionFromTransfrom(_ transform: matrix_float4x4) -> SCNVector3 {
        let position = SCNVector3Make(transform.columns.3.x, transform.columns.3.y, transform.columns.3.z)
        
        return position
    }
    

    func nodeWithPosition(_ position: SCNVector3) -> SCNNode {
        let sphere = SCNSphere(radius: nodeRadius)
        print(drand48() * 100)
        sphere.firstMaterial?.diffuse.contents = UIColor.init(red: CGFloat(drand48() * 100), green: CGFloat(arc4random_uniform(10) * 10), blue: 333, alpha: 1)
        sphere.firstMaterial?.lightingModel = .constant
        sphere.firstMaterial?.isDoubleSided = true
        let node = SCNNode(geometry: sphere)
        node.position = position
        return node
    }
    
    func addSnapshot(at currentFrame: ARFrame?) {
        guard let currentframe =  currentFrame else {return}
        
        let imagePlane = SCNPlane(width: self.sceneView.bounds.width/6000, height: self.sceneView.bounds.height/6000)
        imagePlane.firstMaterial?.diffuse.contents = sceneView.snapshot()
        imagePlane.firstMaterial?.lightingModel = .blinn
        
        let planeNode = SCNNode(geometry: imagePlane)
        sceneView.scene.rootNode.addChildNode(planeNode)
        
        var translation = matrix_identity_float4x4
        translation.columns.3.z = -0.5
        planeNode.simdTransform = matrix_multiply(translation, currentframe.camera.transform)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    
    }
    
    
    @IBAction func createPlane(_ sender: UIButton) {
        self.createPlane()
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

    // MARK: - ARSCNViewDelegate
    
/*
    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
     
        return node
    }
*/
    
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





func normalizeVector(_ iv: SCNVector3) -> SCNVector3 {
    let length = sqrt(iv.x * iv.x + iv.y * iv.y + iv.z * iv.z)
    if length == 0 {
        return SCNVector3(0.0, 0.0, 0.0)
    }
    
    return SCNVector3( iv.x / length, iv.y / length, iv.z / length)
    
}

extension SCNNode {
    
    func buildLineInTwoPointsWithRotation(from startPoint: SCNVector3,
                                          to endPoint: SCNVector3,
                                          radius: CGFloat,
                                          color: UIColor) -> SCNNode {
        let w = SCNVector3(x: endPoint.x-startPoint.x,
                           y: endPoint.y-startPoint.y,
                           z: endPoint.z-startPoint.z)
        let l = CGFloat(sqrt(w.x * w.x + w.y * w.y + w.z * w.z))
        
        if l == 0.0 {
            // two points together.
            let sphere = SCNSphere(radius: radius)
            sphere.firstMaterial?.diffuse.contents = color
            self.geometry = sphere
            self.position = startPoint
            return self
            
        }
        
        let cyl = SCNCylinder(radius: radius, height: l)
        cyl.firstMaterial?.diffuse.contents = color
        
        self.geometry = cyl
        
        //original vector of cylinder above 0,0,0
        let ov = SCNVector3(0, l/2.0,0)
        //target vector, in new coordination
        let nv = SCNVector3((endPoint.x - startPoint.x)/2.0, (endPoint.y - startPoint.y)/2.0,
                            (endPoint.z-startPoint.z)/2.0)
        
        // axis between two vector
        let av = SCNVector3( (ov.x + nv.x)/2.0, (ov.y+nv.y)/2.0, (ov.z+nv.z)/2.0)
        
        //normalized axis vector
        let av_normalized = normalizeVector(av)
        let q0 = Float(0.0) //cos(angel/2), angle is always 180 or M_PI
        let q1 = Float(av_normalized.x) // x' * sin(angle/2)
        let q2 = Float(av_normalized.y) // y' * sin(angle/2)
        let q3 = Float(av_normalized.z) // z' * sin(angle/2)
        
        let r_m11 = q0 * q0 + q1 * q1 - q2 * q2 - q3 * q3
        let r_m12 = 2 * q1 * q2 + 2 * q0 * q3
        let r_m13 = 2 * q1 * q3 - 2 * q0 * q2
        let r_m21 = 2 * q1 * q2 - 2 * q0 * q3
        let r_m22 = q0 * q0 - q1 * q1 + q2 * q2 - q3 * q3
        let r_m23 = 2 * q2 * q3 + 2 * q0 * q1
        let r_m31 = 2 * q1 * q3 + 2 * q0 * q2
        let r_m32 = 2 * q2 * q3 - 2 * q0 * q1
        let r_m33 = q0 * q0 - q1 * q1 - q2 * q2 + q3 * q3
        
        self.transform.m11 = r_m11
        self.transform.m12 = r_m12
        self.transform.m13 = r_m13
        self.transform.m14 = 0.0
        
        self.transform.m21 = r_m21
        self.transform.m22 = r_m22
        self.transform.m23 = r_m23
        self.transform.m24 = 0.0
        
        self.transform.m31 = r_m31
        self.transform.m32 = r_m32
        self.transform.m33 = r_m33
        self.transform.m34 = 0.0
        
        self.transform.m41 = (startPoint.x + endPoint.x) / 2.0
        self.transform.m42 = (startPoint.y + endPoint.y) / 2.0
        self.transform.m43 = (startPoint.z + endPoint.z) / 2.0
        self.transform.m44 = 1.0
        return self
    }
}
