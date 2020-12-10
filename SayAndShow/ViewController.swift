//
//  ViewController.swift
//  SayAndShow
//
//  Created by u_chan on 2020/12/06.
//

import UIKit
import Speech

class ViewController: UIViewController, SFSpeechRecognizerDelegate {

    @IBOutlet weak var sayButton: UIButton!
    @IBOutlet weak var showTextView: UITextView!
    @IBOutlet weak var onAirImageView: UIImageView!
    
    // どの言語を認識するか
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: "ja-JP"))
    
    // 音声認識リクエスト
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    // 音声認識リクエストの結果を返す
    private var recognitionTask: SFSpeechRecognitionTask?
    // 音を認識するオーディオエンジン
    private let audioEngine = AVAudioEngine()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        speechRecognizer?.delegate = self
        showTextView.text = "ボタンを押してみて〜\n👇"
    }
    
    @IBAction func speechToText(_ sender: Any) {
        // 音声認識が実行されている場合
        if audioEngine.isRunning {
            // オーディオ入力を中止
            audioEngine.stop()
            // 音声認識も中止
            recognitionRequest?.endAudio()
            sayButton.isEnabled = false
            sayButton.setImage(UIImage(named: "player_button10_rokuon"), for: .normal)
            
            switch showTextView.text {
            case "メリークリスマス", "メリクリ":
                onAirImageView.image = UIImage(named: "merry_christmas_girl")
            case "あけおめ", "あけましておめでとう", "あけましておめでとうございます":
                onAirImageView.image = UIImage(named: "osyougatsu_akemashite_omedetou")
            case "ハッピーニューイヤー":
                onAirImageView.image = UIImage(named: "happynewyear_1")
            default:
                onAirImageView.image = UIImage(named: "text_tv_onair_off")
                showTextView.text = "もう一回？\n👇"
            }
        } else {
            startRecording()
            onAirImageView.image = UIImage(named: "text_tv_onair_on")
            sayButton.setImage(UIImage(named: "player_button04_teishi"), for: .normal)
        }
    }

    func startRecording() {
        // 音声認識が実行中かどうか確認する
        // この場合はタスクと認識を中止
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        
        // 録音するためのセッションを用意する
        // これで「音」が認識できるようになる
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSession.Category.record)
            try audioSession.setMode(AVAudioSession.Mode.measurement)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("audioSession properties weren't set because of an error.")
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        let inputNode: AVAudioInputNode = audioEngine.inputNode
        
        guard let recognitionRequest = recognitionRequest else {
            fatalError("Unable to create an SFSpeechAudioBufferRecognitionRequest object")
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest, resultHandler:
        { (result, error) in
                    
            var isFinal = false
            
            if result != nil {
                
                self.showTextView.text = result?.bestTranscription.formattedString
                isFinal = (result?.isFinal)!
            }
            
            if error != nil || isFinal {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                
                self.recognitionRequest = nil
                self.recognitionTask = nil
                
                self.sayButton.isEnabled = true
            }
        })
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
        } catch {
            print("audioEngine couldn't start because of an error.")
        }
        
        showTextView.text = "聞いてるよ〜！👂"
    }
    
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if available {
            sayButton.isEnabled = true
        } else {
            sayButton.isEnabled = false
        }
    }
    
}
