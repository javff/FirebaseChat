//
//  PreviewModel.swift
//  chatApp
//
//  Created by Juan  Vasquez on 27/6/18.
//  Copyright © 2018 JavffCompany. All rights reserved.
//

import Foundation

class PreviewModel{
    
    var issueId = ""
    var issueName = ""
    var userName = ""
    var status = false
    var count = 0
    var lastMessage = ""
    
    init(issueName:String, userName:String, status: Bool, count: Int, lastMessage:String, issueId: String){
        
        self.issueName = issueName
        self.userName = userName
        self.status = status
        self.count = count
        self.lastMessage = lastMessage
        self.issueId = issueId
    }
    
}
