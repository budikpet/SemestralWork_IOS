//
//  TestDependency.swift
//  IOSSemestralWork
//
//  Created by Petr Budík on 04/07/2019.
//  Copyright © 2019 Petr Budík. All rights reserved.
//

import Foundation
import RealmSwift
@testable import Resources

/**
 Mock of [AppDependency](x-source-tag://appDependency) singleton. This class is used at its place for Dependency Injection.
 
 TestDependency is not a singleton because all test cases need their own Realm DB and UserDefaults.
 */
final class TestDependency: AllDependencies{
    public static var shared: AllDependencies = TestDependency()
    
    lazy var realm: Realm = getRealm()
    lazy var userDefaults: UserDefaults = TestDependency.getUserDefaults()
    
    lazy var repository: IRepository = TestRepository(dependencies: self)
    
    public lazy var titleValidator: TitleValidator = TitleValidator()
    public lazy var itemCreateableValidator: ItemCreateableValidator = ItemCreateableValidator(dependencies: self)
    public lazy var rssFeedResponseValidator: RSSFeedResponseValidator = RSSFeedResponseValidator()

    // MARK: HasUserDefaults
    private static func getUserDefaults() -> UserDefaults {
        let name = UUID().uuidString
        guard let userDefaults = UserDefaults(suiteName: name) else {
            fatalError("UserDefaults object should have been created.")
        }
        userDefaults.removePersistentDomain(forName: name)
        
        return userDefaults
    }

    // MARK: HasRealm
    
    /**
     Provides Realm DB object. Automatically creates in-memory Realm DB object when testing.
     */
    private func getRealm() -> Realm {
        do {
            let realmConfig: Realm.Configuration = Realm.Configuration(inMemoryIdentifier: UUID().uuidString, encryptionKey: nil, readOnly: false, schemaVersion: 0, migrationBlock: nil, objectTypes: nil)
            let realm = try Realm(configuration: realmConfig)
            
            try! realm.write { () -> Void in
                realm.deleteAll()
            }
            
            return realm
        } catch {
            fatalError("Error initializing new Realm for the first time: \(error)")
        }
    }
}
