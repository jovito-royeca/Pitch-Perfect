//
//  PlaySoundsViewController.swift
//  Pitch Perfect
//
//  Created by Jovit Royeca on 1/5/16.
//  Copyright © 2016 Jovito Royeca. All rights reserved.
//

import UIKit
import AVFoundation

class PlaySoundsViewController: UIViewController, AVAudioPlayerDelegate {
//MARK: variables
    
    // constant values for effects
    let SlowRate        = Float(0.5)
    let FastRate        = Float(1.5)
    let ChipmunkPitch   = Float(1000)
    let DarthVaderPitch = Float(-1000)
    let EchoDelay       = NSTimeInterval(0.1) //100ms
    let EchoVolume      = Float(0.8)
    let ReverbPreset    = AVAudioUnitReverbPreset.LargeChamber // large Chamber is a suitable reverb effect
    let ReverbWetDryMix = Float(50.0)
    
    // tracks the playback of audio
    var audioUpdater:CADisplayLink!
    
    var audioPlayer:AVAudioPlayer!
    var echoPlayer:AVAudioPlayer!
    var audioPlayerNode:AVAudioPlayerNode!
    var audioEngine:AVAudioEngine!
    var audioFile:AVAudioFile!
    
    // the passed-in model class
    var receivedAudio:RecordedAudio!
    
    // the actively playing button
    var activeButton:UIButton?
    
    // if the audio is currently playing
    var playing = false
    
    // cache the button images
    var pauseButtonImage: UIImage!
    var resumeButtonImage: UIImage!

    // audio playback properties
    var currentTime:NSTimeInterval = 0.0
    var duration:NSTimeInterval = 0.0
    
//MARK: UI elements
    @IBOutlet weak var slowButton: UIButton!
    @IBOutlet weak var fastButton: UIButton!
    @IBOutlet weak var chipmunkButton: UIButton!
    @IBOutlet weak var darthVaderButton: UIButton!
    @IBOutlet weak var echoButton: UIButton!
    @IBOutlet weak var reverbButton: UIButton!
    @IBOutlet weak var timelineSlider: UISlider!
    @IBOutlet weak var startLabel: UILabel!
    @IBOutlet weak var endLabel: UILabel!

//MARK: overridden inherited methods
    override func viewDidLoad() {
        super.viewDidLoad()

        try! audioPlayer = AVAudioPlayer(contentsOfURL: receivedAudio.filePathUrl)
        audioPlayer.delegate = self
        
        try! echoPlayer = AVAudioPlayer(contentsOfURL: receivedAudio.filePathUrl)
        echoPlayer.delegate = self
        
        audioEngine = AVAudioEngine()
        try! audioFile = AVAudioFile(forReading: receivedAudio.filePathUrl)
        
        pauseButtonImage = UIImage(named: "pauseButtonBig")
        resumeButtonImage = UIImage(named: "resumeButtonBig")
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        computeDurationAndCurrentTime()
        resetPlaybackControls()
    }
    
    override func viewWillDisappear(animated: Bool) {
        // user may return to Record scene before playback is finished,
        // so we must stop the playback
        playbackStop()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

//MARK: button actions
    @IBAction func playSlowAudio(sender: UIButton) {
        let fx = {(params: Array<AnyObject>?) in
            self.playAudioWithRate(self.SlowRate)
        }
        
        playbackEffects(button: sender, effects: fx, fxParams: nil)
    }
    
    @IBAction func playFastAudio(sender: UIButton) {
        let fx = {(params: Array<AnyObject>?) in
            self.playAudioWithRate(self.FastRate)
        }
        
        playbackEffects(button: sender, effects: fx, fxParams: nil)
        
    }
    
    @IBAction func playChipmunk(sender: UIButton) {
        let fx = {(params: Array<AnyObject>?) in
            let pitchEffect = AVAudioUnitTimePitch()
            pitchEffect.pitch = self.ChipmunkPitch
            
            self.playAudioUsingAudioEngineWithNode(pitchEffect, reset: (params?.first?.boolValue)!)
        }
        let fxParams = [activeButton != sender]
        
        playbackEffects(button: sender, effects: fx, fxParams: fxParams)
    }
    
    @IBAction func playDarthVader(sender: UIButton) {
        let fx = {(params: Array<AnyObject>?) in
            let pitchEffect = AVAudioUnitTimePitch()
            pitchEffect.pitch = self.DarthVaderPitch
            
            self.playAudioUsingAudioEngineWithNode(pitchEffect, reset: (params?.first?.boolValue)!)
        }
        let fxParams = [activeButton != sender]
        
        playbackEffects(button: sender, effects: fx, fxParams: fxParams)
    }
    
    @IBAction func playEcho(sender: UIButton) {
        let fx = {(params: Array<AnyObject>?) in
            self.playAudioWithEcho()
        }
        
        playbackEffects(button: sender, effects: fx, fxParams: nil)
    }
    
    /*
     * Our teacher Kunal Chawla suggested to implement the reverb effect via
     * https://developer.apple.com/library/prerelease/ios/documentation/AVFoundation/Reference/AVAudioUnitReverb_Class/index.html
     * instead of via http://sandmemory.blogspot.com/2014/12/how-would-you-add-reverbecho-to-audio.html
     */
    @IBAction func playReverb(sender: UIButton) {
        let fx = {(params: Array<AnyObject>?) in
            let reverbEffect = AVAudioUnitReverb()
            reverbEffect.loadFactoryPreset(self.ReverbPreset)
            reverbEffect.wetDryMix = self.ReverbWetDryMix
            
            self.playAudioUsingAudioEngineWithNode(reverbEffect, reset: (params?.first?.boolValue)!)
        }
        let fxParams = [activeButton != sender]
        
        playbackEffects(button: sender, effects: fx, fxParams: fxParams)
    }
    
    @IBAction func playStop(sender: UIButton) {
        playbackStop()
    }
    
//MARK: action implementations
    func playAudioWithRate(rate: Float) {
        setupAudioTracker()
        
        audioPlayer.rate = rate
        audioPlayer.play()
        updateActiveButtonWithImage(pauseButtonImage)
    }
    
    /**
     * Echo sound effect.
     * Code taken from http://sandmemory.blogspot.com/2014/12/how-would-you-add-reverbecho-to-audio.html
     */
    func playAudioWithEcho() {
        setupAudioTracker()
        
        audioPlayer.play()
        
        let playtime = echoPlayer.deviceCurrentTime + EchoDelay
        echoPlayer.volume = EchoVolume
        echoPlayer.playAtTime(playtime)
        
        updateActiveButtonWithImage(pauseButtonImage)
    }
    
    /**
     * Sound effects using AVAudioEngine
     * -parameter node: the `AVAudioNode` sound effect
     */
    func playAudioUsingAudioEngineWithNode(node: AVAudioNode, reset: Bool) {
        if (reset) {
            audioPlayerNode = AVAudioPlayerNode()
            audioEngine.attachNode(audioPlayerNode)
            
            audioEngine.attachNode(node)
            
            audioEngine.connect(audioPlayerNode, to: node, format: nil)
            audioEngine.connect(node, to: audioEngine.outputNode, format: nil)
            
            audioPlayerNode.scheduleFile(audioFile, atTime: nil, completionHandler: completionHandler)
            
            setupAudioTracker()
        }
        
        try! audioEngine.start()
        audioPlayerNode.play()
        updateActiveButtonWithImage(pauseButtonImage)
    }

//MARK: playback actions
    func playbackPause() {
        audioPlayer.pause()
        echoPlayer.pause()
        audioEngine.pause()
        if let node = audioPlayerNode {
            node.pause()
        }
        updateActiveButtonWithImage(resumeButtonImage)
    }
    
    func playbackStop() {
        resetPlaybackControls()
        revertButtonImage()
        activeButton = nil
        playing = false
        
        if (audioPlayer.playing) {
            audioPlayer.stop()
        }
        audioPlayer.currentTime = 0.0
        
        if let updater = audioUpdater {
            updater.invalidate()
        }
        
        if (echoPlayer.playing) {
            echoPlayer.stop()
        }
        echoPlayer.currentTime = 0.0
        
        if (audioEngine.running) {
            audioEngine.stop()
            audioEngine.reset()
        }
    }
    
    /**
     * Plays sound `effect`s with the appropriate `button`.
     * -parameter button: the sound effect button
     * -parameter effects: a block that plays the desired sound effect. Can have an optional `params` parameter
     * -parameter fxParams: An optional array of parameters for the `effects` block
     */
    func playbackEffects(button button: UIButton, effects:(Array<AnyObject>?) -> Void, fxParams: Array<AnyObject>?)  {
        // lets check if the button is the activeButton
        // if it is currently playing, pause it. else play the sound effect
        if (activeButton == button) {
            if (playing) {
                playbackPause()
                playing = false
            } else {
                playing = true
                effects(fxParams)
            }
        
        // if not the activeButton, stop the current playback and set the button as the activeButton
        // then play the audio with the sound effects
        } else {
            playbackStop()
            activeButton = button
            playing = true
            effects(fxParams)
        }
    }
    
//MARK: AVAudioPlayerDelegate
    func audioPlayerDidFinishPlaying(player: AVAudioPlayer, successfully flag: Bool) {
        playbackStop()
    }

//MARK: AudioPlayerNode completion handler
    func completionHandler() -> Void {
        playbackStop()
    }

//MARK: player controls
    func resetPlaybackControls() {
        // UI updates must be in main thread because audioPlayerNode and audioEngine are being run in backgraound thread
        dispatch_async(dispatch_get_main_queue()) {
            self.timelineSlider.value = 0.0
            self.startLabel.text = self.stringFromTimeInterval(0.0)
            self.endLabel.text = self.stringFromTimeInterval(self.duration)
        }
    }
    
    func setupAudioTracker() {
        audioUpdater = CADisplayLink(target: self, selector: Selector("trackAudio"))
        audioUpdater.frameInterval = 1
        audioUpdater.addToRunLoop(NSRunLoop.currentRunLoop(), forMode: NSRunLoopCommonModes)
    }
    
    func trackAudio() {
        computeDurationAndCurrentTime()
        
        let normalizedTime = Float(currentTime * 100.0 / duration)
        let startText = stringFromTimeInterval(currentTime)
        let endText = stringFromTimeInterval(duration-currentTime)

        // UI updates must be in main thread because audioPlayerNode and audioEngine are being run in backgraound thread
        dispatch_async(dispatch_get_main_queue()) {
            self.timelineSlider.value = normalizedTime
            self.startLabel.text = startText
            self.endLabel.text = endText
        }
    }

//MARK: Utility methods
    func computeDurationAndCurrentTime() {
        if (activeButton == nil ||
            activeButton == slowButton ||
            activeButton == fastButton ||
            activeButton == echoButton) {
                currentTime = audioPlayer.currentTime
                duration = audioPlayer.duration
        } else if (activeButton == chipmunkButton ||
            activeButton == darthVaderButton ||
            activeButton == reverbButton) {
                if let nodeTime = audioPlayerNode.lastRenderTime {
                    if let playerTime = audioPlayerNode.playerTimeForNodeTime(nodeTime) {
                        let seconds = Double(playerTime.sampleTime) / Double(playerTime.sampleRate);
                        currentTime = seconds
                    }
                }
                duration = Double(audioFile.length) / audioFile.fileFormat.sampleRate
        }
    }
    
    /**
     * Converts NSTimeInterval to human readable format
     * -parameter interval: the time interval
     * -returns: String representation of time in human readable format HH:mm:ss
     */
    func stringFromTimeInterval(interval:NSTimeInterval) -> String {
        let ti = NSInteger(interval)
        let seconds = ti % 60
        let minutes = (ti / 60) % 60
        let hours   = (ti / 3600)
        
        if (hours > 1) {
            return String(format: "%0.2d:%0.2d:%0.2d",hours,minutes,seconds)
        } else {
            return String(format: "%0.2d:%0.2d",minutes,seconds)
        }
    }
    
    func revertButtonImage() {
        if let button = activeButton {
            // UI updates must be in main thread because audioPlayerNode and audioEngine are being run in backgraound thread
            dispatch_async(dispatch_get_main_queue()) {
                if (button == self.slowButton) {
                    button.setImage(UIImage(named: "slowButton"), forState: UIControlState.Normal)
                } else if (button == self.fastButton) {
                    button.setImage(UIImage(named: "fastButton"), forState: UIControlState.Normal)
                } else if (button == self.chipmunkButton) {
                    button.setImage(UIImage(named: "chipmunkButton"), forState: UIControlState.Normal)
                } else if (button == self.darthVaderButton) {
                    button.setImage(UIImage(named: "darthVaderButton"), forState: UIControlState.Normal)
                } else if (button == self.echoButton) {
                    button.setImage(UIImage(named: "echoButton"), forState: UIControlState.Normal)
                } else if (button == self.reverbButton) {
                    button.setImage(UIImage(named: "reverbButton"), forState: UIControlState.Normal)
                }
            }
        }
    }
    
    func updateActiveButtonWithImage(image: UIImage) {
        if let button = activeButton {
            // UI updates must be in main thread because audioPlayerNode and audioEngine are being run in backgraound thread
            dispatch_async(dispatch_get_main_queue()) {
                button.setImage(image, forState: UIControlState.Normal)
            }
        }
    }
}
