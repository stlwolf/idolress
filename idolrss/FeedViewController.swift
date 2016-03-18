//
//  FeedViewController.swift
//  idolrss
//
//  Created by eddy on 2016/03/18.
//  Copyright © 2016年 eddy. All rights reserved.
//

import UIKit
import SwiftyJSON
import Alamofire
import HTMLReader
import SVProgressHUD
import PullToRefreshSwift

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
        
        // HTMLを抽出
        let ogTags = html.nodesMatchingSelector("meta[property=\"og:description\"]")
        if ogTags.isEmpty {
            for tag in ogTags {
                content = (tag.attributes?["content"] as? String)!
            }
        }
        
        // 画像を抽出
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

class FeedTableViewController: UITableViewController {

    var link = ""
    var entries: [JSON] = []
    var parent: UIViewController = UIViewController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        SVProgressHUD.show()
        
        // カスタムcellを設定
        let nib: UINib = UINib(nibName: "CustomCell", bundle: nil)
        self.tableView.registerNib(nib, forCellReuseIdentifier: "Cell")
        
        // linkからRSS作って、JSONにparseする？
        parse(self.link, completion: { data in
            
            self.entries = data!
            self.tableView.reloadData()
            SVProgressHUD.dismiss()
        })
        
        self.tableView.addPullToRefresh({ [weak self] in
            
            self?.tableView.reloadData()
            self?.tableView.stopPullToRefresh()
        })
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.entries.count
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 140
    }
    
    func dispatch_async_main(block: ()->()) {
        dispatch_async(dispatch_get_main_queue(), block)
    }
    
    func dispatch_async_global(block: ()->()) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), block)
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell: CustomCell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as! CustomCell
        
        var contents = ""
        var image = ""
        
        // Cell初期化
        cell.contents.text = ""
        cell.thumbImage.image = UIImage(named: "noPhoto")
        
        getContents(self.entries[indexPath.row]["link"].string!, completion: { data in
            
            contents = data["content"] as! String
            cell.contents.text = contents
            
            image = data["image"] as! String
            
            if (image != "") {
        
                self.dispatch_async_global {
                    
                    let url = NSURL(string: image)
                    
                    // TODO:try-catchは後でちゃんと調べておく
                    do {
                        let imageData = try NSData(contentsOfURL: url!, options: NSDataReadingOptions.DataReadingMappedIfSafe)
                    
                        self.dispatch_async_main {
                            cell.thumbImage.image = UIImage(data: imageData)!
                            cell.layoutSubviews()
                        }
                    } catch {
                    }
                }
            }
            else {
                cell.thumbImage.image = UIImage(named: "noPhoto")!
            }
        })
        
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    }
}