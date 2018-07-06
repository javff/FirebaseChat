//
//  ChannelVC.swift
//  chatApp
//
//  Created by Juan  Vasquez on 23/6/18.
//  Copyright © 2018 JavffCompany. All rights reserved.
//

import UIKit
import FirebaseDatabase

class ChannelVC: UIViewController {
    
    //MARK: - var definitions
    
    var myUid = "javff@gmailcom"

    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var tableView: UITableView!
    private lazy var channelRef = Database.database().reference().child("personal/\(myUid)/issues")
    private var channelRefHandle: DatabaseHandle?
    

    var data: [PreviewModel] = []
    
    //MARK: - life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupView()
        self.observeChannels()

        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        self.tableView.tableFooterView = UIView()

    }
    
    //MARK: - setups

    private func setupView(){
        
        self.title = "Asistencias"
    }
    
    //MARK: - firebase observers

    private func observeChannels() {

        self.activityIndicator.startAnimating()
        
        channelRef.observe(.childAdded, with: { (snapshot) in
            
            self.activityIndicator.alpha = 0
            self.activityIndicator.stopAnimating()
            
            let issue = snapshot.value as! Dictionary<String, AnyObject>
            let issueKey = snapshot.key
            
                let lastMessageInformation = issue["lastMessage"] as! Dictionary<String, AnyObject>
                let userName = lastMessageInformation["username"] as! String
                let status = lastMessageInformation["statusReaded"] as! Bool
                let count = issue["count"] as! Int
                let lastMessage = lastMessageInformation["message"] as! String
            
                let previewChat = PreviewModel(issueName: "leccion Sillabus Swing", userName: userName, status: status, count: count, lastMessage: lastMessage,issueId:issueKey)
                    
                self.data.append(previewChat)
                    
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            
        }) { (error) in
            print(error)
        }
    }
}

//MARK: - implement tableView
extension ChannelVC: UITableViewDelegate, UITableViewDataSource{
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
       return self.data.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "ChatCell")! as! ChatCellVC
        
        cell.channelTitle.text = "\(self.data[indexPath.row].issueName) "
        
        cell.previewLabel.text = "\(self.data[indexPath.row].lastMessage)"
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let selectedPreview = self.data[indexPath.row]
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let conversationVC = storyboard.instantiateViewController(withIdentifier: "conversationVC") as! ViewController
        
        let backItem = UIBarButtonItem()
        backItem.tintColor = .white
        self.navigationItem.backBarButtonItem = backItem
        
        conversationVC.channel = selectedPreview
        self.navigationController?.pushViewController(conversationVC, animated: true)
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
    
    
}
