//
//  UnitTests.swift
//  UnitTests
//
//  Created by Petr Budík on 03/07/2019.
//  Copyright © 2019 Petr Budík. All rights reserved.
//

import XCTest
import RealmSwift
@testable import IOSSemestralWork
@testable import Data
@testable import Common

class RSSFeedEditVMTest: XCTestCase {
    private var dependencies: TestDependency!
    
    private var viewModel: IRSSFeedEditVM!
    
    override func setUp() {
        super.setUp()
        
        dependencies = TestDependency()
        
        initRealmDb()
        
        viewModel = RSSFeedEditVM(dependencies: dependencies)
        viewModel.feedName.value = "Custom title"
        viewModel.link.value = "google.com"
        viewModel.selectedFolder.value = dependencies.repository.rootFolder
    }
    
    /**
     Operations which are done only when the app is launched for the first time.
     */
    private func initRealmDb() {
        let defaults = dependencies.userDefaults
        
        // Set important values in UserDefaults
        defaults.set(NSDate(), forKey: UserDefaults.Keys.lastUpdate.rawValue)
        
        dependencies.repository.realmEdit(errorCode: nil) { realm in
            dependencies.repository.rootFolder.folders.append(Folder(withTitle: "Idnes"))
            dependencies.repository.rootFolder.feeds.append(MyRSSFeed(title: "Zpravodaj", link: "https://servis.idnes.cz/rss.aspx?c=zpravodaj"))
        }
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testCreateOk() {
        let expectation = XCTestExpectation(description: "Valid viewModel data returns no error")
        
        let rssFeedsCount = self.dependencies.repository.feeds.count
        
        viewModel.saveBtnAction.completed.observeValues {
            let rssFeedRes = self.dependencies.repository.feeds.filter("title CONTAINS[cd] %@", self.viewModel.feedName.value)
            
            XCTAssertTrue(rssFeedRes.count == 1)
            XCTAssertNotNil(rssFeedRes.first)
            XCTAssertEqual(rssFeedsCount + 1, self.dependencies.repository.feeds.count)
            
            let rssFeed: MyRSSFeed = rssFeedRes.first!
            
            XCTAssertNotNil(rssFeed.folder)
            XCTAssertTrue(rssFeed.link.contains(self.viewModel.link.value))
            XCTAssertTrue(rssFeed.link.starts(with: "http://"))
            
            expectation.fulfill()
        }
        
        viewModel.saveBtnAction.apply().start()
        
        wait(for: [expectation], timeout: 10)
    }
    
    func testCreateOk_hasHttp() {
        let oldLink = viewModel.link.value
        viewModel.link.value = "http://\(oldLink)"
        
        testCreateOk()
    }
    
    func testCreateError() {
        let expectation = XCTestExpectation(description: "Valid viewModel data returns error")

        dependencies.repository.realmEdit(errorCode: nil) { realm in
            viewModel.selectedFolder.value.feeds.append(MyRSSFeed(title: viewModel.feedName.value, link: viewModel.link.value))
        }

        let rssFeedsCount = self.dependencies.repository.feeds.count

        viewModel.saveBtnAction.errors.observeValues { error in
            let rssFeedRes = self.dependencies.repository.feeds.filter("title CONTAINS[cd] %@", self.viewModel.feedName.value)

            XCTAssertEqual(rssFeedRes.count, 1)
            XCTAssertNotNil(rssFeedRes.first)
            XCTAssertEqual(rssFeedsCount, self.dependencies.repository.feeds.count)

            let rssFeed: MyRSSFeed = rssFeedRes.first!

            XCTAssertNotNil(rssFeed.folder)
            XCTAssertTrue(rssFeed.link.contains(self.viewModel.link.value))

            //TODO: Check for error
//            switch error {
//            case .exists:
//                XCTAssertEqual(rssFeed.itemId, existingFeed.itemId)
//            }

            expectation.fulfill()
        }
        viewModel.saveBtnAction.apply().start()

        wait(for: [expectation], timeout: 10)
    }

    func testCreateError_hasHttp() {
        let oldLink = viewModel.link.value
        viewModel.link.value = "http://\(oldLink)"

        testCreateError()
    }
    
    func testUpdateOK() {
        let expectation = XCTestExpectation(description: "Valid viewModel data returns no error")
        
        let oldFolder = Folder(withTitle: "TestFolder")
        let feedForUpdate = MyRSSFeed(title: viewModel.feedName.value, link: viewModel.link.value)
        dependencies.repository.realmEdit(errorCode: nil) { realm in
            dependencies.repository.rootFolder.folders.append(oldFolder)
            oldFolder.feeds.append(feedForUpdate)
        }
        
        viewModel = RSSFeedEditVM(dependencies: dependencies, feedForUpdate: feedForUpdate)
        
        XCTAssertNotNil(viewModel.feedForUpdate.value)
        XCTAssertEqual(viewModel.feedForUpdate.value, feedForUpdate)
        XCTAssertEqual(viewModel.feedName.value, feedForUpdate.title)
        XCTAssertEqual(viewModel.link.value, feedForUpdate.link)
        
        // Data of the newly updated feed
        viewModel.feedName.value = "Updated title"
        viewModel.link.value = "seznam.cz"
        viewModel.selectedFolder.value = dependencies.repository.rootFolder
        
        let rssFeedsCount = dependencies.repository.feeds.count
        
        viewModel.saveBtnAction.completed.observeValues {
            let rssFeedRes = self.dependencies.repository.feeds.filter("title CONTAINS[cd] %@", self.viewModel.feedName.value)
            
            XCTAssertTrue(rssFeedRes.count == 1)
            XCTAssertNotNil(rssFeedRes.first)
            XCTAssertEqual(rssFeedsCount, self.dependencies.repository.feeds.count)
            XCTAssertEqual(oldFolder.feeds.filter("itemId == %@", feedForUpdate.itemId).count, 0)
            
            let rssFeed: MyRSSFeed = rssFeedRes.first!
            
            XCTAssertEqual(feedForUpdate.itemId, rssFeed.itemId)
            XCTAssertNotNil(rssFeed.folder)
            XCTAssertEqual(rssFeed.folder.first?.feeds.filter("itemId == %@", rssFeed.itemId).count, 1)
            XCTAssertTrue(rssFeed.link.contains(self.viewModel.link.value))
            XCTAssertTrue(rssFeed.link.starts(with: "http://"))
            
            expectation.fulfill()
        }
        
        viewModel.saveBtnAction.apply().start()
        
        wait(for: [expectation], timeout: 10)
    }
}
