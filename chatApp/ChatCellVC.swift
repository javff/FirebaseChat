//
//  ChatCellVC.swift
//  chatApp
//
//  Created by Juan  Vasquez on 27/6/18.
//  Copyright © 2018 JavffCompany. All rights reserved.
//

import UIKit

class ChatCellVC: UITableViewCell {

    @IBOutlet weak var channelTitle: UILabel!
    @IBOutlet weak var previewLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.selectionStyle = .none
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
