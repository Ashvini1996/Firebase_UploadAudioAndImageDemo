//
//  ViewController.swift
//  AudioRecordingDemo
//
//  Created by Mindbowser on 17/12/18.
//  Copyright © 2018 Mindbowser. All rights reserved.
//

import UIKit
import AVFoundation
import Firebase
import FirebaseDatabase

class ViewController: UIViewController, AVAudioRecorderDelegate, AVAudioPlayerDelegate {    
    @IBOutlet weak var recordBtn: UIButton!
    @IBOutlet weak var playBtn: UIButton!
    
    var fDBRef:DatabaseReference!
    var uploadAudioTask: StorageUploadTask!
    var storageRef:StorageReference!
    var soundRecorder: AVAudioRecorder!
    var soundPlayer:AVAudioPlayer!
    let fileName = "/myaudio.m4a"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        fDBRef = Database.database().reference()
        self.storageRef = Storage.storage().reference()
        self.setupAudioRecorder()
        self.readMessagesFromFDB()
    }

    // Writing messages to Firebase - Realtime Database
    func saveMessageToFirebase() {
        let textMsg:String = "India is a very good country."
        FUploadTaskManager.sharedInstance.saveMessage(message: textMsg)
    }
    
    // Saving image urls to Firebase - Realtime Database
    func saveImageUrlToFDB() {
        let imgurlStr = "https://pixabay.com/en/flower-branch-twig-autumn-color-3876195/"
        FUploadTaskManager.sharedInstance.saveImageUrl(urlString: imgurlStr)
    }
    
    // Read data from Firebase - Realtime Database
    func readMessagesFromFDB() {
        fDBRef.child("messages").observeSingleEvent(of: .value, with: { (snapshot) in
            let value = snapshot.value as? NSDictionary
            let allKeys = value!.allKeys as! NSArray
            for key in allKeys {
                let element = value![key as! String] as! NSDictionary
                let text:String = element["content"] as! String
                print("text msg for \(key): \(text)")
            }
        }) { (error) in
            print(error.localizedDescription)
        }
    }
    
    // Upload local audio to Firebase - Cloud storage bucket
    @IBAction func uploadAudioToFirebase(_ sender: Any) {
        FUploadTaskManager.sharedInstance.uploadAudioWithUrl(fileUrl: self.getFileURL(), fileName: "liveaudio.mp4") { (success, metadata, downloadUrl) in
            if success {
                print("Audio file successfully uploaded to Firebase.")
                print("Download url for uploaded audio is: \(String(describing: downloadUrl))")
            } else {
                print("Failed to upload an audio file to Firebase.")
            }
        }
    }
   
    // Upload an image data to Firebase - Cloud storage bucket
    @IBAction func uploadImageToFirebase(_ sender: Any) {
        let flowerimg:UIImage! = UIImage(named: "flower")!
        let imageData:Data = flowerimg.pngData()!
        
        FUploadTaskManager.sharedInstance.uploadImageWithData(imageData: imageData, fileName: "currentimg.png") { (success, metadata, downloadUrl) in
            if success {
                print("Image Data is uploaded to Firebase.")
                print("Download url for uploaded image data is: \(String(describing: downloadUrl!))")
            } else {
                print("Failed to upload an image data to Firebase.")
            }
        }
    }
    
    @IBAction func recordAudioClicked(_ sender: Any) {
        if (recordBtn.titleLabel?.text == "Record Audio"){
            soundRecorder.record()
            recordBtn.setTitle("Stop Audio", for: .normal)
            playBtn.isEnabled = false
        } else {
            soundRecorder.stop()
            recordBtn.setTitle("Record Audio", for: .normal)
        }
    }
    
    @IBAction func playAudioClicked(_ sender: Any) {
        if (playBtn.titleLabel?.text == "Play Audio"){
            recordBtn.isEnabled = false
            playBtn.setTitle("Stop Audio", for: .normal)
            preparePlayer()
            soundPlayer.play()
        } else {
            soundPlayer.stop()            
            playBtn.setTitle("Play Audio", for: .normal)
        }
    }
    
    func setupAudioRecorder() {
        do {
         let session = AVAudioSession.sharedInstance()
         try session.setCategory(.playAndRecord, mode: .default, options: .defaultToSpeaker)
         try session.setActive(true)
         let recordSettings = [AVFormatIDKey: Int(kAudioFormatMPEG4AAC),AVSampleRateKey: 44100,AVNumberOfChannelsKey: 2,AVEncoderAudioQualityKey:AVAudioQuality.high.rawValue]
         soundRecorder = try AVAudioRecorder(url: getFileURL(), settings: recordSettings)
         soundRecorder.delegate = self
         soundRecorder.prepareToRecord()
        }  catch let error {
            print("AVAudioRecorder error: \(error.localizedDescription)")
        }
    }
    
    func getFileURL() -> URL {
        let documents: AnyObject = NSSearchPathForDirectoriesInDomains( FileManager.SearchPathDirectory.documentDirectory,  FileManager.SearchPathDomainMask.userDomainMask, true)[0] as AnyObject
        let strng = (documents as! NSString).appending(fileName)
        let fileurl:URL = NSURL.fileURL(withPath: strng as String)
        return fileurl
    }
    
    func preparePlayer() {
        do {
             soundPlayer = try AVAudioPlayer(contentsOf: getFileURL())
             soundPlayer.delegate = self
             soundPlayer.prepareToPlay()
             soundPlayer.volume = 1.0
        }  catch let error {
            print("AVAudioPlayer error: \(error.localizedDescription)")
        }
    }

    // AVAudioRecorderDelegate
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        playBtn.isEnabled = true
        recordBtn.setTitle("Record Audio", for: .normal)
    }
    
    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        print("Error while recording audio \(String(describing: error?.localizedDescription))")
    }
    
   // AVAudioPlayerDelegate
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        recordBtn.isEnabled = true
        playBtn.setTitle("Play Audio", for: .normal)
    }
    
    private func audioPlayerDecodeErrorDidOccur(player: AVAudioPlayer!, error: NSError!) {
        print("Error while playing audio \(error.localizedDescription)")
    }
    
}

