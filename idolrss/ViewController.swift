//
//  ViewController.swift
//  idolrss
//
//  Created by eddy on 2016/03/14.
//  Copyright © 2016年 eddy. All rights reserved.
//

import UIKit
// import test
import TOWebViewController
import PageMenu
import PullToRefreshSwift
import SwiftyJSON

class ViewController: UIViewController, CAPSPageMenuDelegate {

    var pageMenu: CAPSPageMenu?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        self.title = "IDOL Reeder"
        var controllerArray = [UIViewController]()
        var feedArray: [Dictionary<String, String!>] =
        [
            [
                "link" : "http://ajax.googleapis.com/ajax/services/feed/load?v=1.0&q=http://rss.dailynews.yahoo.co.jp/fc/computer/rss.xml&num=10" ,
                "title" : "コンピュータ"
            ],
            [
                "link" : "http://ajax.googleapis.com/ajax/services/feed/load?v=1.0&q=http://rss.dailynews.yahoo.co.jp/fc/world/rss.xml&num=10" ,
                "title" : "海外"
            ],
            [
                "link" : "http://ajax.googleapis.com/ajax/services/feed/load?v=1.0&q=http://rss.dailynews.yahoo.co.jp/fc/local/rss.xml&num=10" ,
                "title" : "地域"
            ]
        ]
        
        for feed in feedArray {
            
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

