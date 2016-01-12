//
//  RecordSoundsViewController.swift
//  Pitch Perfect
//
//  Created by Jovit Royeca on 1/4/16.
//  Copyright © 2016 Jovito Royeca. All rights reserved.
//

import UIKit
import AVFoundation

class RecordSoundsViewController: UIViewController, AVAudioRecorderDelegate {

    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var stopButton: UIButton!
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var pauseButton: UIButton!
    
    var audioRecorder:AVAudioRecorder!
    var recordedAudio:RecordedAudio!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
    }

    override func viewWillAppear(animated: Bool) {
        recordButton.hidden = false
        statusLabel.text = "Tap Mic to Record"
        stopButton.hidden = true
        pauseButton.hidden = true
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func recordAudio(sender: UIButton) {
        recordButton.hidden = true
        statusLabel.text = "Recording..."
        stopButton.hidden = false
        pauseButton.hidden = false
        
        let dirPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as String
        
        let recordingName = "my_audio.wav"
        let pathArray = [dirPath, recordingName]
        let filePath = NSURL.fileURLWithPathComponents(pathArray)
        print(filePath!)
        
        let session = AVAudioSession.sharedInstance()
        try! session.setCategory(AVAudioSessionCategoryPlayAndRecord)
        
        try! audioRecorder = AVAudioRecorder(URL: filePath!, settings: [:])
        audioRecorder.delegate = self
        audioRecorder.meteringEnabled = true
        audioRecorder.prepareToRecord()
        audioRecorder.record()
    }

    
    @IBAction func stopRecording(sender: UIButton) {
        pauseButton.hidden = true
        recordButton.hidden = false
        audioRecorder.stop()
        let audioSession = AVAudioSession.sharedInstance()
        try! audioSession.setActive(false)
    }
    
    @IBAction func pauseRecording(sender: UIButton) {
        if (audioRecorder.recording) {
            audioRecorder.pause()
            pauseButton.hidden = true
            recordButton.hidden = false
            statusLabel.text = "Paused. Tap Mic to Continue"
        } else {
            audioRecorder.record()
            recordButton.hidden = true
            statusLabel.text = "Recording..."
            stopButton.hidden = false
            pauseButton.hidden = false
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (segue.identifier == "stopRecording") {
            let playSoundsVC:PlaySoundsViewController = segue.destinationViewController as! PlaySoundsViewController
            let data = sender as! RecordedAudio
            playSoundsVC.receivedAudio = data
            playSoundsVC.navigationItem.title = "Play"
        }
    }
    
    func audioRecorderDidFinishRecording(recorder: AVAudioRecorder, successfully flag: Bool) {
        if (flag) {
            let filePathUrl = recorder.url
            let title = recorder.url.lastPathComponent!
            recordedAudio = RecordedAudio(filePathUrl: filePathUrl, title:title)
            
            //Move to the next scene / peform the segue
            self.performSegueWithIdentifier("stopRecording", sender: recordedAudio)
        }
        
    }
    
//    func concatenateRecordings() {
//        let dirPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as String
//        let newRecordingName = "new_audio.wav"
//        let newFilePath = NSURL.fileURLWithPathComponents([dirPath, newRecordingName])
//        
//        let oldRecordingName = "old_audio.wav"
//        let oldFilePath = NSURL.fileURLWithPathComponents([dirPath, oldRecordingName])
//        
//        
//    }
}

