//
//  RSSItemVM.swift
//  IOSSemestralWork
//
//  Created by Petr Budík on 14/07/2019.
//  Copyright © 2019 Petr Budík. All rights reserved.
//

import Foundation
import ReactiveSwift
import RealmSwift
import Data
import Resources

protocol IRSSItemVM {
    var selectedItem: MutableProperty<MyRSSItem> { get }
    var canGoUp: MutableProperty<Bool> { get }
    var canGoDown: MutableProperty<Bool> { get }
    
    func set(isRead: Bool)
    func set(isStarred: Bool)
    func goUp()
    func goDown()
    
    func getScriptCode() -> String
}

/**
 VM for displaying one `MyRSSItem`.
*/
final class RSSItemVM: BaseViewModel, IRSSItemVM {
    typealias Dependencies = HasRepository & HasUserDefaults
    private let dependencies: Dependencies!
    
    private let otherRssItems: Array<MyRSSItem>
    let selectedItem: MutableProperty<MyRSSItem>
    let canGoUp = MutableProperty<Bool>(false)
    let canGoDown = MutableProperty<Bool>(false)
    
    private var currentIndex: Int
    
    init(dependencies: Dependencies, otherRssItems: Results<MyRSSItem>) {
        self.dependencies = dependencies
        self.otherRssItems = Array(otherRssItems)
        
        guard let selectedItem = dependencies.repository.selectedItem.value as? MyRSSItem else {
            fatalError("Selected item must be a RSSItem")
        }
        
        self.selectedItem = MutableProperty<MyRSSItem>(selectedItem)
        
        guard let index = self.otherRssItems.firstIndex(of: selectedItem) else {
            fatalError("Selected item must exist in Realm DB")
        }
        self.currentIndex = index
        
        super.init()
        
        self.selectedItem.producer.startWithValues { [weak self] selectedItem in
            self?.canGoUp.value = selectedItem.itemId != self?.otherRssItems.first!.itemId
            self?.canGoDown.value = selectedItem.itemId != self?.otherRssItems.last!.itemId

            if !selectedItem.isRead {
                self?.set(isRead: true)
            }
        }
    }
    
    func set(isRead: Bool) {
        dependencies.repository.realmEdit(errorCode: nil) { realm in
            selectedItem.value.isRead = isRead
        }
    }
    
    func set(isStarred: Bool) {
        dependencies.repository.realmEdit(errorCode: nil) { realm in
            selectedItem.value.isStarred = isStarred
        }
    }
    
    func goUp() {
        currentIndex -= 1
        selectedItem.value = otherRssItems[currentIndex]
    }
    
    func goDown() {
        currentIndex += 1
        selectedItem.value = otherRssItems[currentIndex]
    }
    
    /**
     Create Javascript code which passes data to the webView.
          
     - returns: The String value of the Javascript code used to pass data into the WKWebView.
     */
    func getScriptCode() -> String {
        // Time
        let formatter = DateFormatter()
        
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "en_GB")  // "cs_CZ"
        var timeString = L10n.RssItemVM.timeString(formatter.string(from: selectedItem.value.date!))
        
        if let author = selectedItem.value.author {
            timeString = "\(timeString) \(L10n.RssItemVM.authorPart(author))"
        }
        
        // Init RSSItem webView
        var code = String(format: "init(`%@`, `%@`, `%@`);", selectedItem.value.title, timeString, selectedItem.value.itemDescription)
        
        if let imageLink = selectedItem.value.image {
            code += String(format: "showImage(`%@`);", imageLink)
        }
        
        return code
    }
}
