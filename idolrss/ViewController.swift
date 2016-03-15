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
import SVProgressHUD
import Alamofire
import PageMenu
import HTMLReader
import PullToRefreshSwift
import SwiftyJSON

// RSSのJSONをパースする
func parse(url: String, completion: (([JSON]?) -> Void)) {
    
    let url = NSURL(string: url)
    
    // リクエスト送信
    Alamofire.request(.GET, url!, parameters: nil, encoding: .JSON).responseJSON { response in
        guard let object = response.result.value else {
            return
        }
        
        // entryの取り出し
        let json = JSON(object)
        let entries = json["responseData"]["feed"]["entries"].array
        
        completion(entries)
    }
}

// 指定URLのHTMLと画像を取得
func getContents(url: String, completion: ((AnyObject) -> Void)) {
    
    let url = NSURL(string: url)
    var result = [String: String!]()
    
    Alamofire.request(.GET, url!, parameters: nil).responseString { response in
        guard let object = response.result.value else {
            return
        }
        
        var content = ""
        let html = HTMLDocument(string: object)
        
        let ogTags = html.nodesMatchingSelector("meta[property=\"og:description\"]")
        if ogTags.isEmpty {
            for tag in ogTags {
                content = (tag.attributes?["content"] as? String)!
            }
        }
        
        var image = ""
        let imgTags = html.nodesMatchingSelector("img")
        if imgTags.isEmpty {
            for tag in imgTags {
                if let data = tag.attributes?["data-src"] {
                    image = data as! String
                }
            }
        }
        
        result = ["content": content, "image": image]
        completion(result)
    }
}

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
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

