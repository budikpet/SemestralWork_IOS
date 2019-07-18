//
//  Repository.swift
//  IOSSemestralWork
//
//  Created by Petr Budík on 02/07/2019.
//  Copyright © 2019 Petr Budík. All rights reserved.
//

import Foundation
import RealmSwift
import Common
import ReactiveSwift

public protocol HasRepository {
    var repository: IRepository { get }
}

public protocol IRepository {
    /** Currently selected folder, RSS feed or RSS item */
    var selectedItem: MutableProperty<Item> { get }
    
    func create(rssFeed feed: MyRSSFeed, parentFolder: Folder) -> SignalProducer<MyRSSFeed, MyRSSFeedError>
    func update(selectedFeed oldFeed: MyRSSFeed, with newFeed: MyRSSFeed, parentFolder: Folder) -> SignalProducer<MyRSSFeed, MyRSSFeedError>
    func getAllRssItems(of folder: Folder, predicate: NSCompoundPredicate?) -> Results<MyRSSItem>
}

public final class Repository: IRepository {
    public typealias Dependencies = HasDBHandler & HasRealm & HasRootFolder
    private let dependencies: Dependencies
    
    public let selectedItem: MutableProperty<Item>
    
    public init(dependencies: Dependencies) {
        self.dependencies = dependencies
        self.selectedItem = MutableProperty<Item>(dependencies.rootFolder)
    }
    
    public func create(rssFeed feed: MyRSSFeed, parentFolder: Folder) -> SignalProducer<MyRSSFeed, MyRSSFeedError> {
        // Check for duplicates
        let cleanLink = feed.link.replacingOccurrences(of: "http://", with: "")
        if let duplicateFeed = dependencies.realm.objects(MyRSSFeed.self).filter("link CONTAINS[cd] %@", cleanLink).first {
            return SignalProducer(error: .exists)
        }
        
        // Save the new feed
        dependencies.dbHandler.realmEdit(errorMsg: "Could not create a feed.") {
            parentFolder.feeds.append(feed)
        }
        return SignalProducer(value: feed)
    }
    
    public func update(selectedFeed oldFeed: MyRSSFeed, with newFeed: MyRSSFeed, parentFolder: Folder) -> SignalProducer<MyRSSFeed, MyRSSFeedError> {
        //TODO: Error handling – change errorMsg to a closure
        dependencies.dbHandler.realmEdit(errorMsg: "Error occured when updating the RSSFeed") {
            let oldFolder = oldFeed.folder.first
            let oldIndex = oldFolder?.feeds.index(matching: "link == %@", oldFeed.link)

            // Update properties
            oldFeed.title = newFeed.title
            oldFeed.link = newFeed.link

            // Change folders
            if oldFolder?.itemId != parentFolder.itemId {
                oldFolder?.feeds.remove(at: oldIndex!)
                parentFolder.feeds.append(oldFeed)
            }
        }
        return SignalProducer(value: oldFeed)
    }
    
    public func getAllRssItems(of folder: Folder, predicate: NSCompoundPredicate? = nil) -> Results<MyRSSItem> {
        let rssItems = dependencies.realm.objects(MyRSSItem.self)
        let folderNames: [String] = getAllFolderNames(from: folder)
        let foldersPredicate = NSPredicate(format: "ANY rssFeed.folder.title IN %@", folderNames)
                
        if let predicate = predicate {
            return rssItems
                .filter(predicate)
                .filter(foldersPredicate)
        } else {
            return rssItems.filter(foldersPredicate)
        }
    }
    
    private func getAllFolderNames(from folder: Folder) -> [String] {
        var folderNames: [String] = [folder.title]
        
        for subfolder in folder.folders {
            folderNames.append(contentsOf: getAllFolderNames(from: subfolder))
        }
        
        return folderNames
    }
}