//
//  PlaySoundsViewController.swift
//  Pitch Perfect
//
//  Created by Jovit Royeca on 1/5/16.
//  Copyright © 2016 Jovito Royeca. All rights reserved.
//

import UIKit
import AVFoundation

class PlaySoundsViewController: UIViewController/*, AVAudioPlayerDelegate*/ {
    var audioPlayer:AVAudioPlayer!
    var echoPlayer:AVAudioPlayer!
    var reverbPlayers:[AVAudioPlayer] = []
    var audioEngine:AVAudioEngine!
    var audioFile:AVAudioFile!
    var receivedAudio:RecordedAudio!
    let N:Int = 10 // number of reverb players
    
    @IBOutlet weak var slowButton: UIButton!
    @IBOutlet weak var fastButton: UIButton!
    @IBOutlet weak var chipmunkButton: UIButton!
    @IBOutlet weak var darthVaderButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        try! audioPlayer = AVAudioPlayer(contentsOfURL: receivedAudio.filePathUrl)
        try! echoPlayer = AVAudioPlayer(contentsOfURL: receivedAudio.filePathUrl)
        for _ in 0...N {
            var temp:AVAudioPlayer
            try! temp = AVAudioPlayer(contentsOfURL: receivedAudio.filePathUrl)
            reverbPlayers.append(temp)
        }
//        audioPlayer.delegate = self
        
        audioEngine = AVAudioEngine()
        try! audioFile = AVAudioFile(forReading: receivedAudio.filePathUrl)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    @IBAction func playSlowAudio(sender: UIButton) {
        playAudio(0.5)
    }
    
    @IBAction func playFastAudio(sender: UIButton) {
        playAudio(1.5)
    }
    
    @IBAction func playChipmunk(sender: UIButton) {
        playAudioWithVariablePitch(1000)
    }
    
    @IBAction func playDarthVader(sender: UIButton) {
        playAudioWithVariablePitch(-1000)
    }
    
    @IBAction func playEcho(sender: UIButton) {
        playEcho()
    }
    
    @IBAction func playReverb(sender: UIButton) {
        playReverb()
    }
    
    @IBAction func playStop(sender: UIButton) {
        playbackStop()
    }
    
    func playbackStop() {
        audioPlayer.stop()
        audioPlayer.currentTime = 0.0
        
        echoPlayer.stop()
        echoPlayer.currentTime = 0.0
        
        for i in 0...N {
            let player:AVAudioPlayer = reverbPlayers[i]
            player.stop()
            player.currentTime = 0.0
        }
        
        audioEngine.stop()
        audioEngine.reset()
    }
    
    func playAudio(rate: Float) {
        playbackStop()
        
        audioPlayer.rate = rate
        audioPlayer.play()
    }
    
    func playAudioWithVariablePitch(pitch: Float) {
        playbackStop()
        
        let audioPlayerNode = AVAudioPlayerNode()
        audioEngine.attachNode(audioPlayerNode)
        
        let changePitchEffect = AVAudioUnitTimePitch()
        changePitchEffect.pitch = pitch
        audioEngine.attachNode(changePitchEffect)
        
        audioEngine.connect(audioPlayerNode, to: changePitchEffect, format: nil)
        audioEngine.connect(changePitchEffect, to: audioEngine.outputNode, format: nil)
        
        audioPlayerNode.scheduleFile(audioFile, atTime: nil, completionHandler: nil)
        
        try! audioEngine.start()
        
        audioPlayerNode.play()
    }
    
    func playEcho() {
        playbackStop()
        
        audioPlayer.play()
        
        let delay:NSTimeInterval = 0.1//100ms
        var playtime:NSTimeInterval
        playtime = echoPlayer.deviceCurrentTime + delay
        echoPlayer.volume = 0.8;
        echoPlayer.playAtTime(playtime)
    }
    
    func playReverb() {
        playbackStop()
        
//        20ms produces detectable delays
        let delay:NSTimeInterval = 0.02
        for i in 0...N {
            let curDelay:NSTimeInterval = delay*NSTimeInterval(i)
            let player:AVAudioPlayer = reverbPlayers[i]
            //M_E is e=2.718...
            //dividing N by 2 made it sound ok for the case N=10
            let exponent:Double = -Double(i)/Double(N/2)
            let volume = Float(pow(Double(M_E), exponent))
            player.volume = volume
            player.playAtTime(player.deviceCurrentTime + curDelay)
        }
    }
    
    /*
    func audioPlayerDidFinishPlaying(player: AVAudioPlayer, successfully flag: Bool) {
        playStop()
    }
    
    func completionHandler() -> Void {
        playStop()
    }*/
}
