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
    var audioPlayerNode:AVAudioPlayerNode!
    var audioEngine:AVAudioEngine!
    var audioFile:AVAudioFile!
    var receivedAudio:RecordedAudio!
    var activeButton:UIButton?
    var pauseButtonImage: UIImage!
    var resumeButtonImage: UIImage!
    
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
        
        pauseButtonImage = UIImage(named: "pauseButton")
        resumeButtonImage = UIImage(named: "resumeButton")
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        resetPlaybackControls(audioPlayer.duration)
    }
    
    override func viewWillDisappear(animated: Bool) {
        playbackStop()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

//MARK: button actions
    @IBAction func playSlowAudio(sender: UIButton) {
        if (activeButton == sender) {
            if (audioPlayer.playing) {
                playbackPause()
            } else {
                playAudioWithRate(0.5)
            }
            
        } else {
            playbackStop()
            activeButton = sender
            playAudioWithRate(0.5)
        }
    }
    
    @IBAction func playFastAudio(sender: UIButton) {
        if (activeButton == sender) {
            if (audioPlayer.playing) {
                playbackPause()
            } else {
                playAudioWithRate(1.5)
            }
        } else {
            playbackStop()
            activeButton = sender
            playAudioWithRate(1.5)
        }
    }
    
    @IBAction func playChipmunk(sender: UIButton) {
        if (activeButton == sender) {
            if (audioPlayerNode.playing) {
                playbackPause()
            } else {
                playAudioWithVariablePitch(1000, reset: false)
            }
        } else {
            playbackStop()
            activeButton = sender
            playAudioWithVariablePitch(1000, reset: true)
        }
    }
    
    @IBAction func playDarthVader(sender: UIButton) {
        if (activeButton == sender) {
            if (audioPlayerNode.playing) {
                playbackPause()
            } else {
                playAudioWithVariablePitch(-1000, reset: false)
            }
        } else {
            playbackStop()
            activeButton = sender
            playAudioWithVariablePitch(-1000, reset: true)
        }
    }
    
    @IBAction func playEcho(sender: UIButton) {
        if (activeButton == sender) {
            if (audioPlayer.playing) {
                playbackPause()
            } else {
                playAudioWithEcho()
            }
        } else {
            playbackStop()
            activeButton = sender
            playAudioWithEcho()
        }
    }
    
    @IBAction func playReverb(sender: UIButton) {
        if (activeButton == sender) {
            if (audioPlayerNode.playing) {
                playbackPause()
            } else {
                playAudioWithReverb(false)
            }
        } else {
            playbackStop()
            activeButton = sender
            playAudioWithReverb(true)
        }
    }
    
    @IBAction func playStop(sender: UIButton) {
        playbackStop()
    }
    
//MARK: time slider action
    @IBAction func timeSliderChanged(sender: UISlider) {
        if (audioPlayer.playing) {
            audioPlayer.pause()
        }
        
        let currentTime = (Double(timelineSlider.value) * audioPlayer.duration) / 100
        audioPlayer.currentTime = currentTime
        echoPlayer.currentTime = currentTime
        trackAudio()
    }

//MARK: action implementations
    func playAudioWithRate(rate: Float) {
        audioUpdater = CADisplayLink(target: self, selector: Selector("trackAudio"))
        audioUpdater.frameInterval = 1
        audioUpdater.addToRunLoop(NSRunLoop.currentRunLoop(), forMode: NSRunLoopCommonModes)
        
        audioPlayer.rate = rate
        audioPlayer.play()
        
        activeButton?.setImage(pauseButtonImage, forState: UIControlState.Normal)
    }
    
    func playAudioWithVariablePitch(pitch: Float, reset: Bool) {
        if (reset) {
            audioPlayerNode = AVAudioPlayerNode()
            audioEngine.attachNode(audioPlayerNode)
            
            let changePitchEffect = AVAudioUnitTimePitch()
            changePitchEffect.pitch = pitch
            audioEngine.attachNode(changePitchEffect)
            
            audioEngine.connect(audioPlayerNode, to: changePitchEffect, format: nil)
            audioEngine.connect(changePitchEffect, to: audioEngine.outputNode, format: nil)
            
            audioPlayerNode.scheduleFile(audioFile, atTime: nil, completionHandler: completionHandler)
            
            audioUpdater = CADisplayLink(target: self, selector: Selector("trackAudio"))
            audioUpdater.frameInterval = 1
            audioUpdater.addToRunLoop(NSRunLoop.currentRunLoop(), forMode: NSRunLoopCommonModes)
        }
        
        try! audioEngine.start()
        audioPlayerNode.play()
        activeButton?.setImage(pauseButtonImage, forState: UIControlState.Normal)
    }
    
    /*
     * Code taken from http://sandmemory.blogspot.com/2014/12/how-would-you-add-reverbecho-to-audio.html
     */
    func playAudioWithEcho() {
        audioUpdater = CADisplayLink(target: self, selector: Selector("trackAudio"))
        audioUpdater.frameInterval = 1
        audioUpdater.addToRunLoop(NSRunLoop.currentRunLoop(), forMode: NSRunLoopCommonModes)
        
        audioPlayer.play()
        
        let delay:NSTimeInterval = 0.1//100ms
        let playtime = echoPlayer.deviceCurrentTime + delay
        echoPlayer.volume = 0.8;
        echoPlayer.playAtTime(playtime)
        
        activeButton?.setImage(pauseButtonImage, forState: UIControlState.Normal)
    }
    
    /*
     * Our teacher Kunal Chawla suggested to implement reverb via
     * https://developer.apple.com/library/prerelease/ios/documentation/AVFoundation/Reference/AVAudioUnitReverb_Class/index.html
     * instead of via http://sandmemory.blogspot.com/2014/12/how-would-you-add-reverbecho-to-audio.html
     */
    func playAudioWithReverb(reset: Bool) {
        if (reset) {
            audioPlayerNode = AVAudioPlayerNode()
            audioEngine.attachNode(audioPlayerNode)
            
            let unitReverb = AVAudioUnitReverb()
            unitReverb.loadFactoryPreset(.LargeChamber)
            unitReverb.wetDryMix = 50.0
            audioEngine.attachNode(unitReverb)
            
            audioEngine.connect(audioPlayerNode, to: unitReverb, format: nil)
            audioEngine.connect(unitReverb, to: audioEngine.outputNode, format: nil)
            
            audioPlayerNode.scheduleFile(audioFile, atTime: nil, completionHandler: completionHandler)
            
            audioUpdater = CADisplayLink(target: self, selector: Selector("trackAudio"))
            audioUpdater.frameInterval = 1
            audioUpdater.addToRunLoop(NSRunLoop.currentRunLoop(), forMode: NSRunLoopCommonModes)
        }
        
        try! audioEngine.start()
        audioPlayerNode.play()
        activeButton?.setImage(pauseButtonImage, forState: UIControlState.Normal)
    }
    
    func playbackPause() {
        audioPlayer.pause()
        echoPlayer.pause()
        audioEngine.pause()
        audioPlayerNode.pause()
        activeButton?.setImage(resumeButtonImage, forState: UIControlState.Normal)
    }
    
    func playbackStop() {
        audioPlayer.stop()
        audioPlayer.currentTime = 0.0
        revertButtonImage()
        activeButton = nil
        
        if (audioUpdater != nil) {
            audioUpdater.invalidate()
        }
        
        echoPlayer.stop()
        echoPlayer.currentTime = 0.0
        
        audioEngine.stop()
        audioEngine.reset()
        
        resetPlaybackControls(audioPlayer.duration)
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
    func resetPlaybackControls(duration: NSTimeInterval) {
        dispatch_async(dispatch_get_main_queue()) {
            self.timelineSlider.value = 0.0
            self.startLabel.text = self.stringFromTimeInterval(0.0)
            self.endLabel.text = self.stringFromTimeInterval(duration)
        }
    }
    
    func trackAudio() {
        var currentTime:NSTimeInterval = 0
        var duration:NSTimeInterval = 0
        
        if (activeButton == slowButton ||
            activeButton == fastButton ||
            activeButton == echoButton) {
            currentTime = audioPlayer.currentTime
            duration = audioPlayer.duration
        } else if (activeButton == chipmunkButton ||
            activeButton == darthVaderButton ||
            activeButton == reverbButton) {
                let nodeTime = audioPlayerNode.lastRenderTime;
                let playerTime = audioPlayerNode.playerTimeForNodeTime(nodeTime!)
                let seconds = Double(playerTime!.sampleTime) / Double(playerTime!.sampleRate);
                currentTime = seconds
                duration = audioPlayer.duration
        }
        
        let normalizedTime = Float(currentTime * 100.0 / duration)
        let startText = stringFromTimeInterval(currentTime)
        let endText = stringFromTimeInterval(duration-currentTime)

        dispatch_async(dispatch_get_main_queue()) {
            self.timelineSlider.value = normalizedTime
            self.startLabel.text = startText
            self.endLabel.text = endText
        }
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
    
    func revertButtonImage() {
        if let button = activeButton {
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
}
