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
import Alamofire
import Fuzi

class ViewController: UIViewController, CAPSPageMenuDelegate {

    let topUrl = "http://www.keyakizaka46.com"
    var pageMenu: CAPSPageMenu?
    
    func blogRequest(url: String, complete: (String -> Void)) {
        
        Alamofire.request(.GET, url).responseString { response in
            guard let html = response.result.value else {
                return
            }
            
            complete(html)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        self.title = "IDOL Reeder"
        
        // ブログTOPアクセス
        blogRequest(topUrl, complete: { topHtml in
            
            if let doc = try? Fuzi.HTMLDocument(string: topHtml) {
                // ブログへのリンク
                if let blogUrl = doc.firstChild(xpath: "//li[@class=\"blog\"]/a") {
                    let blogTop = self.topUrl + blogUrl["href"]!
                    
                    // ブログ新着ページ
                    self.blogRequest(blogTop, complete: { entryHtml in
                        
                        if let doc = try? Fuzi.HTMLDocument(string: entryHtml) {
                            
                            if let blogMain = doc.firstChild(xpath: "//p[@class=\"btn\"]/a")?["href"] {
                                
                                var controllerArray = [UIViewController]()
                                let feedViewController = FeedTableViewController()
                                
                                // 記事情報
                                feedViewController.link = self.topUrl + blogMain
                                feedViewController.title = "ブログ"
                                    
                                // 親controllerはこいつ自身
                                feedViewController.parent = self
                                    
                                // PageMenu用にviewController配列に突っ込む
                                controllerArray.append(feedViewController)
                                
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
                                self.pageMenu = CAPSPageMenu(viewControllers: controllerArray, frame: CGRectMake(0.0, yPosition, self.view.frame.width, self.view.frame.height - yPosition), pageMenuOptions: parameters)
                                
                                self.view.addSubview(self.pageMenu!.view)
                            }
                        }
                    })
                }
            }
        })
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}