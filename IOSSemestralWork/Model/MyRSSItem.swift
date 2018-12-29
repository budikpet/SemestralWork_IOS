//
//  MyRSSItem.swift
//  IOSSemestralWork
//
//  Created by Petr Budík on 29/12/2018.
//  Copyright © 2018 Petr Budík. All rights reserved.
//

import Foundation
import AlamofireRSSParser

class MyRSSItem: Item {
    var link: String = ""
    var itemDescription: String = ""
    var author: String = ""
    
    init(with rssItem: RSSItem) {
        super.init(with: rssItem.title ?? "Unknown", type: .myRssItem)
        
        self.link = rssItem.link ?? "Unknown"
        self.author = rssItem.author ?? "Unknown"
        self.itemDescription = rssItem.itemDescription ?? "Unknown"
    }
}
