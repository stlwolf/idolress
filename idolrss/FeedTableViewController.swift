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

class FeedTableViewController: UITableViewController {

    // MARK: - MoreLoad
    internal var sourceObjects = [AnyObject]() // コンテンツ内容
    internal var fetchSourceObjects: ( completion: (sourceObjects: [AnyObject]) -> () ) -> () = { _ in }
    
    private enum SectionType {
        case Main
        case Footer
    }
    private let sectionTypes: [SectionType] = [.Main, .Footer]
    
    private var isRequesting = false // リクエストフラグ
    private var pendingProcess: (() -> ())?
    // スクロールフラグ(スクロールされたか？)
    private var isScrolling = false {
        // 値が変更された"後に"呼ばれる
        didSet {
            // スクロールしてなくなってかつ終わった後に実行したい関数があるなら
            if !isScrolling && pendingProcess != nil {
                pendingProcess?()
                pendingProcess = nil
            }
        }
    }
    private var cellHeights = [NSIndexPath: CGFloat]()
    
    var link = ""
    var nextlink = ""
    var data = [Dictionary<String, AnyObject>]()
    var parent: ViewController = ViewController()
    var entries: [JSON] = []
    
    // リクエスト送信
    private func getHTML(complete: ((String) -> Void)) {
        
        var url = self.link
        if !self.nextlink.isEmpty {
            url = self.nextlink
        }
        
        Alamofire.request(.GET, url).responseString { response in
            guard let html = response.result.value else {
                return
            }
            
            complete(html)
        }
    }
    
    private func loadHTML(html: String) -> [AnyObject] {
        
        var result = [AnyObject]()
        
        if let doc = try? Fuzi.HTMLDocument(string: html) {
            
            // pager
            for (index, li) in doc.xpath("//div[@class=\"pager\"]/ul/li").enumerate() {
 
                if li.firstChild(xpath: "./span[@class=\"active\"]") != nil {
                    nextlink = parent.topUrl + doc.xpath("//div[@class=\"pager\"]/ul/li")[index + 1]!.children[0]["href"]!
                }
            }
            
            // 個々のブログデータ
            for article in doc.xpath("//div[@class=\"box-main\"]/article") {

                let title = article.children[0].firstChild(xpath: "./div[2]/h3")!.stringValue
                let entry = self.parent.topUrl + article.children[0].firstChild(xpath: "./div[2]/h3/a")!["href"]!
                let name = article.children[0].firstChild(xpath: "./div[2]/p")!.stringValue
                var imageSrc = ""

                // FIXME: これじゃうまくとれない
                for main in article.children[0].xpath("../div[2]/div[1]") {
                    for child in main.children {
                        if let src = child.firstChild(xpath: "./img")?["src"] {
                            imageSrc = self.parent.topUrl + src
                            break
                        }
                    }
                }
                
                if imageSrc == "" {
                    for main in article.children[0].xpath("../div[2]/div[1]/div[2]") {
                        for child in main.children {
                            if let src = child.firstChild(xpath: "./img")?["src"] {
                                imageSrc = self.parent.topUrl + src
                                break
                            }
                        }
                    }
                }
                
                result.append(["title": title.stringByTrimmingCharactersInSet(.whitespaceAndNewlineCharacterSet()), "name": name.stringByTrimmingCharactersInSet(.whitespaceAndNewlineCharacterSet()), "entry": entry, "image": imageSrc])
            }
        }
        
        return result
    }
    
    // テーブルデータ更新
    private func updateTable(reload: Bool) {
        self.dispatch_async_main {
            UIView.setAnimationsEnabled(false)
            
            if let mainSection = self.sectionTypes.indexOf(.Main) {
            
                // 追加データ
                let newDataCount = self.sourceObjects.count
                // テーブル内データ。セクションID以外から取れるのか？
                let currentDataCount = self.tableView.numberOfRowsInSection(mainSection)
                
                if currentDataCount < newDataCount {
                    self.tableView.insertRowsAtIndexPaths(
                        Array(currentDataCount..<newDataCount).map { NSIndexPath(forRow: $0, inSection: mainSection) },
                        withRowAnimation: .None
                    )
                }
                else {
                    self.tableView.deleteRowsAtIndexPaths(
                        Array(newDataCount..<currentDataCount).map { NSIndexPath(forRow: $0, inSection: mainSection) },
                        withRowAnimation: .None
                    )
                }
                
                if reload {
                    self.tableView.reloadRowsAtIndexPaths(
                        Array(0..<newDataCount).map { NSIndexPath(forRow: $0, inSection: mainSection) },
                        withRowAnimation: .None
                    )
                }
            }
            
            UIView.setAnimationsEnabled(true)
            
            self.tableView.reloadData()
        }
    }
    
    // データロード
    func loadMore(reload reload: Bool = false) {
        guard !isRequesting else {
            return
        }
        isRequesting = true
        
        let oldDataCount = sourceObjects.count
        
        self.dispatch_async_global {
            
            self.fetchSourceObjects() { [weak self] sourceObjects in
                
                if oldDataCount == self?.sourceObjects.count {
                    self?.sourceObjects += sourceObjects
                }
                
                // スクロール中
                if self?.isScrolling == true {
                    if self?.pendingProcess == nil {
                        self?.pendingProcess = {
                            self?.updateTable(reload)
                        }
                    }
                }
                else {
                    self?.updateTable(reload)
                }
                
                self?.isRequesting = false
            }
        }
    }
    
    // MARK: - viewFunc
    override func viewDidLoad() {
        super.viewDidLoad()
        SVProgressHUD.show()
        
        // カスタムcellを設定
        let nib: UINib = UINib(nibName: "CustomCell", bundle: nil)
        self.tableView.registerNib(nib, forCellReuseIdentifier: "Cell")
        
        fetchSourceObjects = { [weak self] completion in
            
            // 非同期データ取得
            self!.getHTML({ data in
                
                // HTML解析データ
                let contents = self!.loadHTML(data)
                completion(sourceObjects: contents)
                
                SVProgressHUD.dismiss()
            })
        }
        
        // ブログ見に行く
//        getHtml(self.link, complete: { data in
//            self.loadHTML(data)
//            self.tableView.reloadData()
//            SVProgressHUD.dismiss()
//        })
        
        // pullして更新のライブラリ
        self.tableView.addPullToRefresh({ [weak self] in
            
            self?.tableView.reloadData()
            self?.tableView.stopPullToRefresh()
        })
    }
    
    // viewが表示される直前に呼ばれるらしい
    internal override func viewWillAppear(animated: Bool) {
        
        super.viewWillAppear(animated)
        
        // ページ遷移時にセレクトされてる行が残ってれば解除しておく
        if let indexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRowAtIndexPath(indexPath, animated: animated)
        }
    }

    // MARK: - Scroll
    
    // スクロール開始時イベント
    internal override func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        isScrolling = true
    }
    
    // スクロールしてる指が離れた時イベント
    internal override func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        // まだスクロール慣性が残ってるところではtrue
        // false!=true完全に止まった
        if !decelerate {
            isScrolling = false
        }
    }
    
    // スクロール移動が完全に止まったら呼ばれるイベント
    internal override func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        isScrolling = false
    }
    
    // MARK: - cell
    
    // セクション数
    internal override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return sectionTypes.count
    }
    
    // セルの数返す(必須)
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionType = sectionTypes[section]
        
        switch sectionType {
        case .Main:
            return self.sourceObjects.count
        case .Footer:
            return 1
        }
    }
    
    // セルの高さ返す(必須)
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    // セルの高さ仮計算？
    override func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if let cacheHeight = cellHeights[indexPath] {
            return cacheHeight
        }
        else {
            return 140
        }
    }

    // セルが描画領域内に入ると呼ばれる
    internal override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        cellHeights[indexPath] = cell.frame.height
        
        if sectionTypes[indexPath.section] == .Footer {
            loadMore()
        }
    }
    
    // セルの中身返す(必須)
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell: CustomCell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as! CustomCell
        
        if sectionTypes[indexPath.section] == .Main {
        
        // Cell初期化
        cell.title.text = self.sourceObjects[indexPath.row]["name"] as? String
        cell.contents.text = self.sourceObjects[indexPath.row]["title"] as? String
        let imagesSrc = self.sourceObjects[indexPath.row]["image"] as? String
        
        if (imagesSrc != "") {
            
            self.dispatch_async_global {
                
                let url = NSURL(string: imagesSrc!)
                
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
            cell.thumbImage.image = UIImage(named: "noPhoto")
        }
        }
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
        detailViewController.entry = self.sourceObjects[indexPath.row]["entry"] as! String
        
        // ナビゲーションコントローラに追加
        parent.navigationController!.pushViewController(detailViewController, animated: true)
    }
    
    // MARK: - async
    private func dispatch_async_main(block: ()->()) {
        dispatch_async(dispatch_get_main_queue(), block)
    }
    
    private func dispatch_async_global(block: ()->()) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), block)
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