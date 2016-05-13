//
//  utility.swift
//  idolrss
//
//  Created by eddy on 2016/05/13.
//  Copyright © 2016年 eddy. All rights reserved.
//

import Foundation

func print(message: String, filename: String = #file, line: Int = #line, function: String = #function) {
    Swift.print("\((filename as NSString).lastPathComponent):\(line) \(function):\r\(message)")
}