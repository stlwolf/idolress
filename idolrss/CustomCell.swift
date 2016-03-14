//
//  CustomCell.swift
//  idolrss
//
//  Created by eddy on 2016/03/15.
//  Copyright © 2016年 eddy. All rights reserved.
//

import UIKit

class CustomCell: UITableViewCell {

    @IBOutlet weak var thumbImage: UIImageView!
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var contents: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
