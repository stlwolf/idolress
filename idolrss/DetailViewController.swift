//
//  DetailViewController.swift
//  idolrss
//
//  Created by eda on 2016/03/18.
//  Copyright © 2016年 eddy. All rights reserved.
//

import Foundation
import UIKit
import SwiftyJSON
import SVProgressHUD
import WebKit

class DetailViewController : UIViewController, WKNavigationDelegate {
    
    let webview = WKWebView()
    var entry = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // webViewの基本設定
        self.webview.frame = self.view.bounds
        self.webview.navigationDelegate = self
        self.webview.translatesAutoresizingMaskIntoConstraints = false
        
        self.view.addSubview(self.webview)
        
        let url = NSURL(string: self.entry)
        let request = NSURLRequest(URL: url!)

        // 真ん中のくるくる消す
        SVProgressHUD.dismiss()
        
        self.webview.loadRequest(request)
    }
    
    func webView(webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true // インジゲーターON
    }
    
    func webView(webView: WKWebView, didFinishNavigation navigation: WKNavigation!) {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false // インジゲーターOFF
    }
}
