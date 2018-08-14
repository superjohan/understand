//
//  ViewController.swift
//  demo
//
//  Created by Johan Halin on 12/03/2018.
//  Copyright © 2018 Dekadence. All rights reserved.
//

import UIKit
import AVFoundation
import SceneKit
import Foundation

class UnderstandViewController: UIViewController, SCNSceneRendererDelegate {
    let audioPlayer: AVAudioPlayer
    let sceneView = SCNView()
    let camera = SCNNode()
    let startButton: UIButton
    let qtFoolingBgView: UIView = UIView.init(frame: .zero)
    let understandLabel: UILabel = UILabel(frame: .zero)
    let allFontNames: [String]
    
    var previousFontName: String? = nil
    
    // MARK: - UIViewController
    
    init() {
        if let trackUrl = Bundle.main.url(forResource: "audio", withExtension: "m4a") {
            guard let audioPlayer = try? AVAudioPlayer(contentsOf: trackUrl) else {
                abort()
            }
            
            self.audioPlayer = audioPlayer
        } else {
            abort()
        }
        
        let camera = SCNCamera()
        camera.zFar = 600
//        camera.vignettingIntensity = 1
//        camera.vignettingPower = 1
//        camera.colorFringeStrength = 3
//        camera.bloomIntensity = 1
//        camera.bloomBlurRadius = 40
        self.camera.camera = camera // lol
        
        let startButtonText =
            "\"understand\"\n" +
                "by jumalauta\n" +
                "\n" +
                "programming and music by ylvaes\n" +
                "modeling by tohtori kannabispiikki\n" +
                "\n" +
                "presented at jumalauta 18 years (2018)\n" +
                "\n" +
        "tap anywhere to start"
        self.startButton = UIButton.init(type: UIButtonType.custom)
        self.startButton.setTitle(startButtonText, for: UIControlState.normal)
        self.startButton.titleLabel?.numberOfLines = 0
        self.startButton.titleLabel?.lineBreakMode = NSLineBreakMode.byWordWrapping
        self.startButton.backgroundColor = UIColor.black

        var fontNames: [String] = []
        let ignoredFamilies: [String] = ["Arial", "Arial Hebrew", "Arial Rounded MT Bold", "Bodoni Ornaments", "Bradley Hand", "Chalkboard SE", "Chalkduster", "Marker Felt", "Papyrus", "Party LET", "Rockwell"]
        for familyName in UIFont.familyNames {
            if ignoredFamilies.contains(familyName) {
                continue
            }
            
            for fontName in UIFont.fontNames(forFamilyName: familyName) {
                if fontName.lowercased().contains("bold") && fontName.lowercased().contains("italic") {
                    fontNames.append(fontName)
                }
            }
        }
        
        self.allFontNames = fontNames
            
        super.init(nibName: nil, bundle: nil)
        
        self.startButton.addTarget(self, action: #selector(startButtonTouched), for: UIControlEvents.touchUpInside)
        
        self.view.backgroundColor = .green // FIXME
        self.sceneView.backgroundColor = .black
        self.sceneView.delegate = self
        
        self.qtFoolingBgView.backgroundColor = UIColor(white: 0.1, alpha: 1.0)
        
        // barely visible tiny view for fooling Quicktime player. completely black images are ignored by QT
        self.view.addSubview(self.qtFoolingBgView)
        
        self.view.addSubview(self.sceneView)

        self.view.addSubview(self.understandLabel)
        
        self.view.addSubview(self.startButton)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prefersHomeIndicatorAutoHidden() -> Bool {
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.audioPlayer.prepareToPlay()
        
        self.sceneView.scene = createScene()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.qtFoolingBgView.frame = CGRect(
            x: (self.view.bounds.size.width / 2) - 1,
            y: (self.view.bounds.size.height / 2) - 1,
            width: 2,
            height: 2
        )

        self.sceneView.frame = CGRect(x: 0, y: 0, width: self.view.bounds.size.width, height: self.view.bounds.size.height)
        self.sceneView.isPlaying = true
        self.sceneView.isHidden = true

        self.understandLabel.text = "UNDERSTAND"
        self.understandLabel.frame = self.view.bounds
        self.understandLabel.adjustsFontSizeToFitWidth = true
        self.understandLabel.font = UIFont.systemFont(ofSize: 400)
        self.understandLabel.textAlignment = .center
        self.understandLabel.textColor = .white
        self.understandLabel.baselineAdjustment = .alignCenters
        self.understandLabel.isHidden = true
        self.understandLabel.shadowColor = .black
        self.understandLabel.shadowOffset = CGSize(width: 5, height: 5)
        
        self.startButton.frame = CGRect(x: 0, y: 0, width: self.view.bounds.size.width, height: self.view.bounds.size.height)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        self.audioPlayer.stop()
    }
    
    // MARK: - SCNSceneRendererDelegate

    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        // this function is run in a background thread.
//        DispatchQueue.main.async {
//        }
    }
    
    // MARK: - Private
    
    @objc
    fileprivate func startButtonTouched(button: UIButton) {
        self.startButton.isUserInteractionEnabled = false
        
        // long fadeout to ensure that the home indicator is gone
        UIView.animate(withDuration: 4, animations: {
            self.startButton.alpha = 0
        }, completion: { _ in
            self.start()
        })
    }
    
    fileprivate func start() {
//        self.sceneView.isHidden = false
        
        scheduleEvents()
        
        self.audioPlayer.play()
    }
    
    private func scheduleEvents() {
        let fontStartTime = 1.5
        
        for i in 0..<40 {
            perform(#selector(updateFont), with: nil, afterDelay: (Double(i) * 2) + fontStartTime)
        }
    }
    
    @objc
    private func updateFont() {
        var fontName: String
        repeat {
            let index = Int(arc4random_uniform(UInt32(self.allFontNames.count)))
            fontName = self.allFontNames[index]
        } while fontName == self.previousFontName
        
        self.previousFontName = fontName
        
        guard let font = UIFont(name: fontName, size: 400) else { return }
        self.understandLabel.font = font
        self.understandLabel.isHidden = false
    }
    
    fileprivate func createScene() -> SCNScene {
        let scene = SCNScene()
        scene.background.contents = UIColor.black
        
        self.camera.position = SCNVector3Make(0, 0, 58)
        
        scene.rootNode.addChildNode(self.camera)
        
        configureLight(scene)
        
        return scene
    }
    
    fileprivate func configureLight(_ scene: SCNScene) {
        let omniLightNode = SCNNode()
        omniLightNode.light = SCNLight()
        omniLightNode.light?.type = SCNLight.LightType.omni
        omniLightNode.light?.color = UIColor(white: 1.0, alpha: 1.0)
        omniLightNode.position = SCNVector3Make(0, 0, 60)
        scene.rootNode.addChildNode(omniLightNode)
    }
}
