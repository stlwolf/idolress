//
//  DetailViewController.swift
//  idolrss
//
//  Created by eda on 2016/03/18.
//  Copyright © 2016年 eddy. All rights reserved.
//

import Foundation
import UIKit
import TOWebViewController
import SwiftyJSON
import SVProgressHUD

class DetailViewController : TOWebViewController {
    
    let webview = UIWebView()
    var entry = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // webViewの基本設定
        self.webview.frame = self.view.bounds
        self.webview.delegate = self
        
        self.view.addSubview(self.webview)
        
        let url = NSURL(string: self.entry)
        let request = NSURLRequest(URL: url!)

        // 真ん中のくるくる消す
        SVProgressHUD.dismiss()
        
        self.webview.loadRequest(request)
    }
    
    override func webViewDidStartLoad(webView: UIWebView) {
        // ネットワークアクセス中にiphone上部に出るぐるぐるを動かす設定をON
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
    }
    
    override func webViewDidFinishLoad(webView: UIWebView) {
        // 上記ぐるぐるをOFF
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
    }

}
