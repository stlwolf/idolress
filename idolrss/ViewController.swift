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
        let feedArray: [Dictionary<String, String!>] =
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
        
        // 記事取得
        for feed in feedArray {
            
            let feedViewController = FeedTableViewController()
            
            // 記事情報
            feedViewController.link = feed["link"]!
            feedViewController.title = feed["title"]!
            
            // 親controllerはこいつ自身
            feedViewController.parent = self
            
            // PageMenu用にviewController配列に突っ込む
            controllerArray.append(feedViewController)
        }
        
        // PageMenu設定
        let parameters: [CAPSPageMenuOption] = [
            .MenuItemSeparatorWidth(4.3),
            .UseMenuLikeSegmentedControl(true),
            .MenuItemSeparatorPercentageHeight(0.1),
            .SelectionIndicatorColor(UIColor.blueColor()),
        ]
        
        let statusBarHeight: CGFloat = UIApplication.sharedApplication().statusBarFrame.height
        let naviHeight: CGFloat = self.navigationController!.navigationBar.frame.size.height
        let yPosition = naviHeight + statusBarHeight
        
        // 上部に作成するページメニューライブラリの作成
        pageMenu = CAPSPageMenu(viewControllers: controllerArray, frame: CGRectMake(0.0, yPosition, self.view.frame.width, self.view.frame.height - yPosition), pageMenuOptions: parameters)
        self.view.addSubview(pageMenu!.view)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

