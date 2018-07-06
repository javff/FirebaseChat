//
//  MockMessages.swift
//  chatApp
//
//  Created by Juan  Vasquez on 22/6/18.
//  Copyright © 2018 JavffCompany. All rights reserved.
//


import Foundation
import CoreLocation
import MessageKit


internal struct MessageModel: MessageType {
   
    var data: MessageData
    var messageId: String
    var sender: Sender
    var sentDate: Date
    
     init(data: MessageData, sender: Sender, messageId: String, date: Date) {
        self.sender = sender
        self.messageId = messageId
        self.sentDate = date
        self.data = data
    }
    
    

}
