//
//  FUploadTaskManager.swift
//  AudioRecordingDemo
//
//  Created by Mindbowser on 04/02/19.
//  Copyright © 2019 Mindbowser. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase

class FUploadTaskManager: NSObject {
    static let sharedInstance = FUploadTaskManager()
    let fdbRef:DatabaseReference = Database.database().reference()
    let storageRef:StorageReference! = Storage.storage().reference()
    typealias CompletionHandler = (_ success:Bool,_ metadata:StorageMetadata?, _ downloadUrl:URL?) -> Void
    private override init() {
        
    }
    
    // Save messages to Firebase
    func saveMessage(message:String) -> Void {
        let ref = fdbRef.child("messages")
        let childRef = ref.childByAutoId()
        childRef.setValue(["content": message])
    }
    
    // Saving image-url (in String format) to Firebase
    func saveImageUrl(urlString:String) {
        let ref = fdbRef.child("AllImageUrls")
        let childRef = ref.childByAutoId()
        childRef.setValue(["imageurl": urlString])
    }
    
    // Uploading an UIImage/Image Data to Firebase - (Google cloud storage bucket)
    func uploadImageWithData(imageData:Data, fileName:String, completionHandler: @escaping CompletionHandler) {
        let imageFolderRef = storageRef.child("images")
        let imageRef = imageFolderRef.child(fileName)
        
        let imgMetadata = StorageMetadata()
        imgMetadata.contentType = "image/jpeg"
        
        let uploadTask = imageRef.putData(imageData, metadata: imgMetadata) { (metadata, error) in
            guard let metadata = metadata else {
                return completionHandler(false, nil, nil)
            }
            let size = metadata.size
            print("Size of uploaded image data is: \(size)")
            imageRef.downloadURL { (url, error) in
                guard let downloadURL = url else {
                    return completionHandler(false, nil, nil)
                }
                print("Downloaded Url for uploaded imade data is: \(downloadURL)")
                completionHandler(true, metadata, downloadURL)
            }
        }
    }
    
    // Uploading an audio file to Firebase - (Google cloud storage bucket)
    func uploadAudioWithUrl(fileUrl:URL, fileName:String, completionHandler: @escaping CompletionHandler) {
        let audiosRef = storageRef.child("audios")
        let fileRef = audiosRef.child(fileName)
        
        let audioMetadata = StorageMetadata()
        audioMetadata.contentType = "audio/m4a"
        
        let uploadTask = fileRef.putFile(from: fileUrl, metadata: nil) { metadata, error in
            guard let metadata = metadata else {
                return completionHandler(false, nil, nil)
            }
            let size = metadata.size
            print("Size of uploaded audio file is: \(size)")
            fileRef.downloadURL { (url, error) in
                guard let downloadURL = url else {
                    return completionHandler(false, nil, nil)
                }
                print("Downloaded Url for uploaded audio is: \(downloadURL)")
                completionHandler(true, metadata, downloadURL)
            }
        }
    }
}
