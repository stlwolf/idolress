//
//  FeedViewController.swift
//  idolrss
//
//  Created by eddy on 2016/03/18.
//  Copyright © 2016年 eddy. All rights reserved.
//

import Foundation
import UIKit
import SwiftyJSON
import Alamofire
import HTMLReader
import SVProgressHUD
import PullToRefreshSwift
import Fuzi

// test
// リクエスト送信
func getHtml(url: String, completion: ((String) -> Void)) {
    
    Alamofire.request(.GET, url).responseString { response in
        guard let html = response.result.value else {
            return
        }
        
        completion(html)
    }
}

// RSSのJSONをパースする
func parseJson(url: String, completion: (([JSON]?) -> Void)) {
    
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
        let html = HTMLReader.HTMLDocument(string: object)
        
        // HTMLを抽出
        let ogTags = html.nodesMatchingSelector("meta[property=\"og:description\"]")
        if !(ogTags.isEmpty) {
            for tag in ogTags {
                content = (tag.attributes?["content"] as? String)!
            }
        }
        
        // 画像を抽出
        var image = ""
        let imgTags = html.nodesMatchingSelector("img")
        if !(imgTags.isEmpty) {
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
    var data = [Dictionary<String, String>]()
    var entries: [JSON] = []
    var parent: ViewController = ViewController()
    var xml = ""
    
    func loadHTML(html: String) {
        
        if let doc = try? Fuzi.HTMLDocument(string: html) {
            
            // 個々のブログデータ
            for article in doc.xpath("//div[@class=\"box-main\"]/article") {

                let title = article.children[0].firstChild(xpath: "./div[2]/h3")!.stringValue
                let entry = self.parent.topUrl + article.children[0].firstChild(xpath: "./div[2]/h3/a")!["href"]!
                let name = article.children[0].firstChild(xpath: "./div[2]/p")!.stringValue
                
                self.data.append(["title": title.stringByTrimmingCharactersInSet(.whitespaceAndNewlineCharacterSet()), "name": name.stringByTrimmingCharactersInSet(.whitespaceAndNewlineCharacterSet()), "entry": entry])
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        SVProgressHUD.show()
        
        // カスタムcellを設定
        let nib: UINib = UINib(nibName: "CustomCell", bundle: nil)
        self.tableView.registerNib(nib, forCellReuseIdentifier: "Cell")
        
        // ブログ見に行く
        getHtml(self.link, completion: { data in
            self.loadHTML(data)
            self.tableView.reloadData()
            SVProgressHUD.dismiss()
        })
        
        // linkからRSS作って、JSONにparseする？
//        parseJson(self.link, completion: { data in
//            
//            self.entries = data!
//            self.tableView.reloadData()
//            SVProgressHUD.dismiss()
//        })
        
        // pullして更新のライブラリ
        self.tableView.addPullToRefresh({ [weak self] in
            
            self?.tableView.reloadData()
            self?.tableView.stopPullToRefresh()
        })
    }
    
    // セルの数返す(必須)
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.data.count
    }
    
    // セルの高さ返す(必須)
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 140
    }
    
    func dispatch_async_main(block: ()->()) {
        dispatch_async(dispatch_get_main_queue(), block)
    }
    
    func dispatch_async_global(block: ()->()) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), block)
    }
    
    // セルの中身返す(必須)
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell: CustomCell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as! CustomCell
        
        // Cell初期化
        cell.title.text = self.data[indexPath.row]["name"]
        cell.contents.text = self.data[indexPath.row]["title"]
        cell.thumbImage.image = UIImage(named: "noPhoto")
        
        //var contents = ""
        //var image = ""
        
//        getContents(self.entries[indexPath.row]["link"].string!, completion: { data in
//            
//            contents = data["content"] as! String
//            cell.contents.text = contents
//            
//            image = data["image"] as! String
//            
//            if (image != "") {
//        
//                self.dispatch_async_global {
//                    
//                    let url = NSURL(string: image)
//                    
//                    // TODO:try-catchは後でちゃんと調べておく
//                    do {
//                        let imageData = try NSData(contentsOfURL: url!, options: NSDataReadingOptions.DataReadingMappedIfSafe)
//                    
//                        self.dispatch_async_main {
//                            cell.thumbImage.image = UIImage(data: imageData)!
//                            cell.layoutSubviews()
//                        }
//                    } catch {
//                    }
//                }
//            }
//            else {
//                cell.thumbImage.image = UIImage(named: "noPhoto")!
//            }
//        })
        
        return cell
    }
    
    // Cellがタップされた時に呼ばれるdelegate
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        // 記事内容を詳細viewControllerに突っ込む
        let detailViewController = DetailViewController()
        detailViewController.entry = self.data[indexPath.row]["entry"]!
        
        // ナビゲーションコントローラに追加
        parent.navigationController!.pushViewController(detailViewController, animated: true)
    }
}