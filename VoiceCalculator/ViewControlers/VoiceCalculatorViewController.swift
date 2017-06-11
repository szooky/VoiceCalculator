//
//  VoiceCalculatorViewController.swift
//  VoiceCalculator
//
//  Created by Filip Szukala on 10/06/2017.
//  Copyright © 2017 Filip Szukala. All rights reserved.
//

import UIKit
import Speech
import AVFoundation

class VoiceCalculatorViewController: UIViewController {

    @IBOutlet weak var listenButton: UIButton!
    @IBOutlet weak var recognizedSpeechLabel: UILabel!
    
    fileprivate let audioEngine = AVAudioEngine()
    fileprivate let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))!
    fileprivate var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    fileprivate var recognitionTask: SFSpeechRecognitionTask?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setApperance()
        listenButton.isEnabled = false
        
        self.read(self.recognizedSpeechLabel.text!)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        speechRecognizer.delegate = self
        checkForSpeechRecognitionPermissions()
    }
    
    private func setApperance() {
        listenButton.layer.cornerRadius = listenButton.frame.width / 2
    }
    
    @IBAction func listenButtonClicked(_ sender: UIButton) {
        if audioEngine.isRunning {
            audioEngine.stop()
            recognitionRequest?.endAudio()
            listenButton.isEnabled = false
            listenButton.setTitle("Stopping", for: .disabled)
        } else {
            try! startRecording()
            listenButton.setTitle("Stop", for: [])
        }
    }
    
}

extension VoiceCalculatorViewController: SFSpeechRecognizerDelegate {
    
    fileprivate func checkForSpeechRecognitionPermissions() {
        SFSpeechRecognizer.requestAuthorization { authorizationStatus in
            OperationQueue.main.addOperation {
                switch authorizationStatus {
                case .authorized:
                    self.listenButton.isEnabled = true
                    
                case .denied:
                    self.listenButton.isEnabled = false
                    self.recognizedSpeechLabel.text = "You disabled access to speech recognition."
                    
                case .notDetermined:
                    self.listenButton.isEnabled = false
                    self.recognizedSpeechLabel.text = "Speech recognition is not authorized."

                    
                case .restricted:
                    self.listenButton.isEnabled = false
                    self.recognizedSpeechLabel.text = "Speech recognition is restricted"

                }
            }
        }
    }
    
    fileprivate func startRecording() throws {
        if let recognitionTask = recognitionTask {
            recognitionTask.cancel()
            self.recognitionTask = nil
        }
        
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(AVAudioSessionCategoryRecord)
        try audioSession.setMode(AVAudioSessionModeMeasurement)
        try audioSession.setActive(true, with: .notifyOthersOnDeactivation)
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        guard let inputNode = audioEngine.inputNode else { fatalError("Audio engine has no input node") }
        guard let recognitionRequest = recognitionRequest else { fatalError("Unable to created a SFSpeechAudioBufferRecognitionRequest object") }
        
        recognitionRequest.shouldReportPartialResults = true
        recognitionRequest.taskHint = .search
        
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { result, error in
            var isFinal = false
            
            if let result = result {
                self.recognizedSpeechLabel.text = result.bestTranscription.formattedString
                isFinal = result.isFinal
            }
            
            if error != nil || isFinal {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                
                self.recognitionRequest = nil
                self.recognitionTask = nil
                
                self.listenButton.isEnabled = true
                self.listenButton.setTitle("Listen", for: [])
                
                let queue = DispatchQueue(label: "com.VoiceCalculator.MathParserQueue", qos: DispatchQoS.background)
                queue.async {
                    let result = MathExpressionCalculator.parse(expression: self.recognizedSpeechLabel.text!)
                    self.read("\(result)")
                }
                
                print(self.recognizedSpeechLabel.text!)
            }
        }
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        try audioEngine.start()
        
        recognizedSpeechLabel.text = "listening..."
    }
    
    public func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if available {
            listenButton.isEnabled = true
            listenButton.setTitle("Listen", for: [])
        } else {
            listenButton.isEnabled = false
            listenButton.setTitle("Recognition not available", for: .disabled)
        }
    }

}

extension VoiceCalculatorViewController {
    
    fileprivate func read(_ textToRead: String) {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSessionCategoryPlayback)
            try audioSession.setMode(AVAudioSessionModeDefault)
            
        } catch {
            print("audioSession properties weren't set because of an error.")
        }
        
        let speechSynthesizer = AVSpeechSynthesizer()
        let speechUtterance = AVSpeechUtterance(string: textToRead)
        speechSynthesizer.speak(speechUtterance)
        
    }
    
}

