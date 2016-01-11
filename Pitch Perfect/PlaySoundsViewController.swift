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
    var audioPlayer:AVAudioPlayer!
    var audioUpdater:CADisplayLink!
    
    var echoPlayer:AVAudioPlayer!
    var audioEngine:AVAudioEngine!
    var audioFile:AVAudioFile!
    var receivedAudio:RecordedAudio!
    var activeButton:UIButton?
    
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
    
    override func viewDidLoad() {
        super.viewDidLoad()

        try! audioPlayer = AVAudioPlayer(contentsOfURL: receivedAudio.filePathUrl)
        audioPlayer.delegate = self
        
        try! echoPlayer = AVAudioPlayer(contentsOfURL: receivedAudio.filePathUrl)
        echoPlayer.delegate = self
        
        audioEngine = AVAudioEngine()
        try! audioFile = AVAudioFile(forReading: receivedAudio.filePathUrl)
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        resetPlaybackControls(audioPlayer.duration)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

//MARK: button actions
    @IBAction func playSlowAudio(sender: UIButton) {
        playAudioWithRate(0.5)
    }
    
    @IBAction func playFastAudio(sender: UIButton) {
        playAudioWithRate(1.5)
    }
    
    @IBAction func playChipmunk(sender: UIButton) {
        playAudioWithVariablePitch(1000)
    }
    
    @IBAction func playDarthVader(sender: UIButton) {
        playAudioWithVariablePitch(-1000)
    }
    
    @IBAction func playEcho(sender: UIButton) {
        playAudioWithEcho()
    }
    
    @IBAction func playReverb(sender: UIButton) {
        let alert = UIAlertController(title: "Reverb Presets", message: nil, preferredStyle: .ActionSheet)

        // add actions
        alert.addAction(UIAlertAction(title: "Small Room",
            style: UIAlertActionStyle.Default,
            handler: {(alert: UIAlertAction!) in
                self.playAudioWithReverbPreset(.SmallRoom)
        }))
        alert.addAction(UIAlertAction(title: "Medium Room",
            style: UIAlertActionStyle.Default,
            handler: {(alert: UIAlertAction!) in
                self.playAudioWithReverbPreset(.MediumRoom)
        }))
        alert.addAction(UIAlertAction(title: "Large Room",
            style: UIAlertActionStyle.Default,
            handler: {(alert: UIAlertAction!) in
                self.playAudioWithReverbPreset(.LargeRoom)
        }))
        alert.addAction(UIAlertAction(title: "Large Room 2",
            style: UIAlertActionStyle.Default,
            handler: {(alert: UIAlertAction!) in
                self.playAudioWithReverbPreset(.LargeRoom2)
        }))
        alert.addAction(UIAlertAction(title: "Medium Hall",
            style: UIAlertActionStyle.Default,
            handler: {(alert: UIAlertAction!) in
                self.playAudioWithReverbPreset(.MediumHall)
        }))
        alert.addAction(UIAlertAction(title: "Medium Hall 2",
            style: UIAlertActionStyle.Default,
            handler: {(alert: UIAlertAction!) in
                self.playAudioWithReverbPreset(.MediumHall2)
        }))
        alert.addAction(UIAlertAction(title: "Medium Hall 3",
            style: UIAlertActionStyle.Default,
            handler: {(alert: UIAlertAction!) in
                self.playAudioWithReverbPreset(.MediumHall3)
        }))
        alert.addAction(UIAlertAction(title: "Large Hall",
            style: UIAlertActionStyle.Default,
            handler: {(alert: UIAlertAction!) in
                self.playAudioWithReverbPreset(.LargeHall)
        }))
        alert.addAction(UIAlertAction(title: "Large Hall 2",
            style: UIAlertActionStyle.Default,
            handler: {(alert: UIAlertAction!) in
                self.playAudioWithReverbPreset(.LargeHall2)
        }))
        alert.addAction(UIAlertAction(title: "Plate",
            style: UIAlertActionStyle.Default,
            handler: {(alert: UIAlertAction!) in
                self.playAudioWithReverbPreset(.Plate)
        }))
        alert.addAction(UIAlertAction(title: "Medium Chamber",
            style: UIAlertActionStyle.Default,
            handler: {(alert: UIAlertAction!) in
                self.playAudioWithReverbPreset(.MediumChamber)
        }))
        alert.addAction(UIAlertAction(title: "Large Chamber",
            style: UIAlertActionStyle.Default,
            handler: {(alert: UIAlertAction!) in
                self.playAudioWithReverbPreset(.LargeChamber)
        }))
        alert.addAction(UIAlertAction(title: "Cathedral",
            style: UIAlertActionStyle.Default,
            handler: {(alert: UIAlertAction!) in
                self.playAudioWithReverbPreset(.Cathedral)
        }))
        
        //Present the AlertController
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    @IBAction func playStop(sender: UIButton) {
        playbackStop(true)
    }
    
//MARK: time slider
    @IBAction func timeSliderChanged(sender: UISlider) {
        if (audioPlayer.playing) {
            audioPlayer.pause()
        }
        
        let currentTime = (Double(timelineSlider.value) * audioPlayer.duration) / 100
        audioPlayer.currentTime = currentTime
        trackAudio()
    }
    
    func playAudioWithRate(rate: Float) {
        playbackStop(false)
        
        audioUpdater = CADisplayLink(target: self, selector: Selector("trackAudio"))
        audioUpdater.frameInterval = 1
        audioUpdater.addToRunLoop(NSRunLoop.currentRunLoop(), forMode: NSRunLoopCommonModes)
        
        audioPlayer.rate = rate
        audioPlayer.play()
    }
    
    func playAudioWithVariablePitch(pitch: Float) {
        playbackStop(false)
        
        let audioPlayerNode = AVAudioPlayerNode()
        audioEngine.attachNode(audioPlayerNode)
        
        let changePitchEffect = AVAudioUnitTimePitch()
        changePitchEffect.pitch = pitch
        audioEngine.attachNode(changePitchEffect)
        
        audioEngine.connect(audioPlayerNode, to: changePitchEffect, format: nil)
        audioEngine.connect(changePitchEffect, to: audioEngine.outputNode, format: nil)
        
        audioPlayerNode.scheduleFile(audioFile, atTime: nil, completionHandler: completionHandler)
        
        try! audioEngine.start()
        
        audioPlayerNode.play()
    }
    
    /*
     * Code taken from http://sandmemory.blogspot.com/2014/12/how-would-you-add-reverbecho-to-audio.html
     */
    func playAudioWithEcho() {
        playbackStop(false)
        
        audioUpdater = CADisplayLink(target: self, selector: Selector("trackAudio"))
        audioUpdater.frameInterval = 1
        audioUpdater.addToRunLoop(NSRunLoop.currentRunLoop(), forMode: NSRunLoopCommonModes)
        
        audioPlayer.play()
        
        let delay:NSTimeInterval = 0.1//100ms
        var playtime:NSTimeInterval
        playtime = echoPlayer.deviceCurrentTime + delay
        echoPlayer.volume = 0.8;
        echoPlayer.playAtTime(playtime)
    }
    
    func playAudioWithReverbPreset(preset: AVAudioUnitReverbPreset) {
        playbackStop(false)
        
        let audioPlayerNode = AVAudioPlayerNode()
        audioEngine.attachNode(audioPlayerNode)
        
        let unitReverb = AVAudioUnitReverb()
        unitReverb.loadFactoryPreset(preset)
        unitReverb.wetDryMix = 50.0
        audioEngine.attachNode(unitReverb)
        
        audioEngine.connect(audioPlayerNode, to: unitReverb, format: nil)
        audioEngine.connect(unitReverb, to: audioEngine.outputNode, format: nil)
        
        audioPlayerNode.scheduleFile(audioFile, atTime: nil, completionHandler: completionHandler)
        
        try! audioEngine.start()
        
        audioPlayerNode.play()
    }
    
    func playbackStop(reset: Bool) {
        audioPlayer.stop()
        if (reset) {
            audioPlayer.currentTime = 0.0
        }
        
        if (audioUpdater != nil) {
            audioUpdater.invalidate()
        }
        
        echoPlayer.stop()
        if (reset) {
            echoPlayer.currentTime = 0.0
        }
        
        audioEngine.stop()
        audioEngine.reset()
        
        resetPlaybackControls(audioPlayer.duration)
    }
    
//MARK: AVAudioPlayerDelegate
    func audioPlayerDidFinishPlaying(player: AVAudioPlayer, successfully flag: Bool) {
        playbackStop(true)
    }

//MARK: AudioPlayerNode completion handler
    func completionHandler() -> Void {
        playbackStop(true)
    }

//MARK: player controls
    func resetPlaybackControls(duration: NSTimeInterval) {
        timelineSlider.value = 0.0
        startLabel.text = stringFromTimeInterval(0.0)
        endLabel.text = stringFromTimeInterval(duration)
    }
    
    func trackAudio() {
        let normalizedTime = Float(audioPlayer.currentTime * 100.0 / audioPlayer.duration)
        let startText = stringFromTimeInterval(audioPlayer.currentTime)
        let endText = stringFromTimeInterval(audioPlayer.duration-audioPlayer.currentTime)
        
        self.timelineSlider.value = normalizedTime
        self.startLabel.text = startText
        self.endLabel.text = endText
    }

//MARK: Utility methods
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
}
