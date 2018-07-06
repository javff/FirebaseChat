//
//  ViewController.swift
//  chatApp
//
//  Created by Juan  Vasquez on 22/6/18.
//  Copyright © 2018 JavffCompany. All rights reserved.
//

import UIKit
import MessageKit
import FirebaseDatabase
import Firebase
import FirebaseStorage
import AVFoundation
import Photos



class ViewController: MessagesViewController {
    
    var recordingSession: AVAudioSession!
    var audioRecorder: AVAudioRecorder!
    var audioFileName: URL!

    private let imageURLNotSetKey = "NOTSET"

    
    //MARK: - Firebase Vars //
    var channelRef: DatabaseReference?
    
    var myUid = "javff@gmailcom"
    
    var channel: PreviewModel!
    
    private lazy var messageRef: DatabaseReference = Database.database().reference().child("messages/issues/\(channel.issueId)/messages")
    
    private lazy var personalRef: DatabaseReference = Database.database().reference().child("personal/\(myUid)/issues/\(channel.issueId)")
    
    private lazy var previewRef: DatabaseReference = Database.database().reference().child("preview/issues/\(channel.issueId)")

    fileprivate lazy var storageRef: StorageReference = Storage.storage().reference(forURL: "gs://sultanes-927b4.appspot.com")
    
    private var newMessageRefHandle: DatabaseHandle?
    private var updatedMessageRefHandle: DatabaseHandle?
    
    private var activityIndicator: UIActivityIndicatorView = UIActivityIndicatorView(frame: CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: 60, height: 60)))
    
    
    var mockMessages:[MessageModel] = []
     var photoMessageMap = [String: MessageModel]()

    
    let sender =  Sender(id: "javff@gmailcom", displayName: "juan")
    var issue = UUID().uuidString
    
    lazy var formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // set options //
        
        //NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow), name: .UIKeyboardWillShow, object: nil)
        
        
        // set delegates //
        
        
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messageInputBar.delegate = self
        
        
        self.messagesCollectionView.backgroundColor = .white
        
        self.messageInputBar.inputTextView.autocorrectionType = .no
       
        self.title = "Sultanes chat app"
        self.navigationItem.rightBarButtonItem?.customView = self.activityIndicator
        
        self.observeMessages()
        
        
    }
    
    //MARK: - funcs
    
    @objc func keyboardWillShow(){
        
        self.messagesCollectionView.scrollToBottom()
        
    }
    
    
    deinit{
        NotificationCenter.default.removeObserver(self)
    }
    
    //MARK: - firebase methods
    
    // MARK: Firebase related methods
    
    private func observeMessages() {

        let messageQuery = messageRef.queryLimited(toLast:100)
        
        // We can use the observe method to listen for new
        // messages being written to the Firebase DB
        
        
        newMessageRefHandle = messageQuery.observe(.childAdded, with: { (snapshot) -> Void in
            
            let message = snapshot.value as! Dictionary<String, Any>
            
            
            guard let type = message["type"] as? String else{
                return
            }
            
            if type == "image"{
                
                guard let link = message["link"] as? String else{
                    return
                }
                
                
                if link == self.imageURLNotSetKey{
                    return
                }
                
                let placeholderImage = UIImage.gifWithURL("https://cdn-images-1.medium.com/max/1600/1*9EBHIOzhE1XfMYoKz1JcsQ.gif")!
                let mediaItem = MessageModel(data: .photo(placeholderImage), sender: self.sender, messageId: UUID.init().uuidString, date: Date())
                self.addPhotoMessage(mediaItem: mediaItem)
                
                
                if link.hasPrefix("gs://") {
                    self.fetchImageDataAtURL(link, forMediaItem: mediaItem, clearsPhotoMessageMapOnSuccessForKey: nil)
                }
                
                
            }
            
            
            if type == "text"{
                
                let messageText = message["message"] as! String
                // let rol = messages["rol"] as! String
                // let statusReaded = messages["statusReaded"] as! String
                let timestamp = message["timestamp"] as! TimeInterval
                let uid = message["uid"] as! String
                let username = message["username"] as! String
                
                let messageData = MessageData.text(messageText)
                let sender = Sender(id: uid, displayName: username)
                let date = Date(timeIntervalSince1970: timestamp / 1000)
                let mockMessage = MessageModel(data: messageData, sender: sender, messageId: "key", date: date)
                
                self.mockMessages.append(mockMessage)
                self.messagesCollectionView.insertSections([self.mockMessages.count - 1])
                self.messagesCollectionView.scrollToBottom()
            }


            

    })

        
        updatedMessageRefHandle = messageRef.observe(.childChanged, with: { (snapshot) in
            let key = snapshot.key
            let messageData = snapshot.value as! Dictionary<String, Any>

            if let photoURL = messageData["link"] as? String {
                // The photo has been updated.
                if let mediaItem = self.photoMessageMap[key] {
                    self.fetchImageDataAtURL(photoURL, forMediaItem: mediaItem, clearsPhotoMessageMapOnSuccessForKey: key)
                }
            }
        })
    }
    
    
     func fetchImageDataAtURL(_ photoURL: String  , forMediaItem mediaItem: MessageModel, clearsPhotoMessageMapOnSuccessForKey key: String?) {
        let storageRef = Storage.storage().reference(forURL: photoURL)
        
        
        DispatchQueue.global().async {
            
            storageRef.downloadURL { (url, error) in
                
                if error != nil{
                    return
                }
                
                let data = try! Data.init(contentsOf: url!)
                let image = UIImage.init(data: data)!
                
                let index = self.mockMessages.index(where: { (message) -> Bool in
                    return mediaItem.messageId == message.messageId
                })!
                
                DispatchQueue.main.async {
                    self.mockMessages[index].data = MessageData.photo(image)
                    
                    let indexSet = IndexSet.init(integer: index)
                    self.messagesCollectionView.reloadSections(indexSet)
                }
                
                if key != nil{
                    self.photoMessageMap.removeValue(forKey: key!)
                }
            }
            
        }
        
    }
    
     func addPhotoMessage(mediaItem: MessageModel) {
        
        self.mockMessages.append(mediaItem)
        self.messagesCollectionView.insertSections([self.mockMessages.count - 1])
        self.messagesCollectionView.scrollToBottom()
    }
    
    
    func setImageURL(_ url: String, forPhotoMessageWithKey key: String) {
        let itemRef = messageRef.child(key)
        itemRef.updateChildValues(["link": url])
    }


    func sendPhotoMessage() -> String? {
       
        let itemRef = messageRef.childByAutoId()
        
        let messageItem:[String:Any] = [
            "link": self.imageURLNotSetKey,
            "uid":self.sender.id,
            "type":"image",
            "rol": "client",
            "timestamp":Date().timeIntervalSince1970 * 1000
        ]
        
        itemRef.setValue(messageItem)
        return itemRef.key
    }

    
}


extension ViewController: MessagesDataSource{
    
   
    func currentSender() -> Sender {
        return self.sender
    }
    
    func numberOfMessages(in messagesCollectionView: MessagesCollectionView) -> Int {
        return mockMessages.count
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return mockMessages[indexPath.section]
    }
    
    func cellBottomLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        
        let dateString = formatter.string(from: message.sentDate)
        return NSAttributedString(string: dateString, attributes: [NSAttributedStringKey.font: UIFont.preferredFont(forTextStyle: .caption2)])
    }
    
    func cellTopLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        
        
        switch message.data {
        case .audio(let asset):
            
            let seconds = Int(asset.duration.seconds)
            let (_,m,s) = (seconds / 3600, (seconds % 3600) / 60, (seconds % 3600) % 60)
            let unit = m > 0 ? "Minutos" : "Segundos"
            let result = "Duración: \(m):\(s) \(unit)"
            
           return NSAttributedString(string: result, attributes: [NSAttributedStringKey.font: UIFont.preferredFont(forTextStyle: .caption2)])
            
        default:
            break
        }
        
        return nil
    }
   
}

extension ViewController: MessagesLayoutDelegate {
    
    func heightForLocation(message: MessageType, at indexPath: IndexPath, with maxWidth: CGFloat, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        
        return UIScreen.main.bounds.width
    }
    
    
    func heightForMedia(message: MessageType, at indexPath: IndexPath, with maxWidth: CGFloat, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        return UIScreen.main.bounds.width / 3
    }
    
    
    func widthForMedia(message: MessageType, at indexPath: IndexPath, with maxWidth: CGFloat, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        
        return UIScreen.main.bounds.width / 3
    }
  
    
    func messageBottomLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        return 16
    }
    
    
    func avatarSize(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGSize {
        
        return .zero
    }

   

}

extension ViewController: MessagesDisplayDelegate{

    func messageStyle(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageStyle {
        
        if message.sender.id == self.sender.id{
            
            return MessageStyle.bubbleTail(.bottomRight, .curved)

        }
        
        return  MessageStyle.bubbleTail(.bottomLeft, .curved)
    }
}


extension ViewController: AudioMessageLayoutDelegate {
    
    func heightForAudio(message: MessageType, at indexPath: IndexPath, with maxWidth: CGFloat, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        return 50
    }
    
}

// MARK: - MediaMessageLayoutDelegate

extension ViewController: MediaMessageLayoutDelegate {}

extension ViewController: MessageInputBarDelegate{
    
    func messageInputBar(_ inputBar: MessageInputBar, didPressSendButtonWith text: String) {
        
        Database.database()
        
        let message: [String:Any] = [
            "link" : "",
            "message" : "\(text)",
            "statusReaded" : false,
            "rol" : "client",
            "status" : true,
            "timestamp" : Date().timeIntervalSince1970 * 1000,
            "type" : "text",
            "username" : self.sender.displayName,
            "uid": self.sender.id
        ]
        
        let previewPayload: [String:Any] = [
            
            "count" : 0,
            "lastMessage": message,
            "name" : "testing name",
            "status": true,
            "uid": "javff@gmailcom",
            "username": self.sender.displayName
        ]
        
        let personalPayload:[String:Any] = [
            "lastMessage": message
        ]
        
        let itemRef = messageRef.childByAutoId()
        itemRef.setValue(message)
        
        previewRef.updateChildValues(previewPayload)
        personalRef.updateChildValues(personalPayload)
        
        inputBar.inputTextView.text = ""
        
    }
    
    
    func messageInputBar(didPressSendMediaButton inputBar: MessageInputBar) {
        
        let picker = UIImagePickerController()
        picker.delegate = self
        self.present(picker, animated: true)
        
        
    }
    
    func messageInputBar(didSelectAudioMediaButton inputBar: MessageInputBar) {
        
        print("testing")

        recordingSession = AVAudioSession.sharedInstance()
        
        
        do {
            try recordingSession.setCategory(AVAudioSessionCategoryPlayAndRecord)
            try recordingSession.setActive(true)
            recordingSession.requestRecordPermission() { [unowned self] allowed in
                DispatchQueue.main.async {
                    if allowed {
                        
                        print("allowed")
                        self.startRecording()

                    } else {
                        // failed to record!
                    }
                }
            }
        } catch {
            // failed to record!
            print("fail")
        }
        
    }
    
    func messageInputBar(didUnselectedAudioMediaButton inputBar: MessageInputBar, audioDuration: Int) {
        
        let validate = audioDuration > 3
        self.finishRecording(success: validate)
    }
    
    
    //MARK: - audio helpers
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    func startRecording() {
        
        self.audioFileName = getDocumentsDirectory().appendingPathComponent("recording.m4a")
        
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: self.audioFileName, settings: settings)
            audioRecorder.delegate = self
            audioRecorder.record()
            
        } catch {
            finishRecording(success: false)
        }
    }
    
}

extension ViewController: AVAudioRecorderDelegate{
    
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            finishRecording(success: false)
        }
    }
    
    func finishRecording(success: Bool) {
        
        defer{
            audioRecorder = nil
        }
        audioRecorder.stop()
        
        if success {
            
            let asset = AVAsset(url: self.audioFileName)
            let random = UUID.init().uuidString
            let data = MessageData.audio(asset)
            let newMessage = MessageModel(data: data, sender: self.sender, messageId: random, date: Date())
            self.mockMessages.append(newMessage)
            self.messagesCollectionView.insertSections([mockMessages.count - 1])
            self.messagesCollectionView.scrollToBottom(animated: true)
        }
    }
}

extension ViewController:  UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        
        self.messageInputBar.isHidden = false
        dismiss(animated: true, completion: nil)
    }
    

    
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        
        self.messageInputBar.isHidden = true
        navigationController.navigationBar.tintColor = .blue
        navigationController.navigationBar.backgroundColor = .red
        navigationController.navigationBar.isTranslucent = false

    }
    
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        self.messageInputBar.isHidden = false
        
        dismiss(animated: true, completion: nil)

        if let imageUrl = info[UIImagePickerControllerImageURL] as? URL {
            // Handle picking a Photo from the Photo Library

            if let key = sendPhotoMessage() {
                
                    let image = info[UIImagePickerControllerOriginalImage] as! UIImage
                    let id =  UUID.init().uuidString
                    let mediaItem = MessageModel(data: .photo(image), sender: self.sender, messageId:id, date: Date())
                
                    photoMessageMap[key] = mediaItem
                
                    self.addPhotoMessage(mediaItem: mediaItem)
                
                    let path = "\(imageUrl.lastPathComponent)"
                    
                self.storageRef.child(path).putFile(from: imageUrl, metadata: nil) { (metadata, error) in
                        if let error = error {
                            print("Error uploading photo: \(error.localizedDescription)")
                            return
                        }
                    
                    self.setImageURL(self.storageRef.child((metadata?.path)!).description, forPhotoMessageWithKey: key)
                    }
            }
        } else {
            // Handle picking a Photo from the Camera - TODO
        }
        
    }
}
