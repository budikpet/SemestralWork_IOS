//
//  AppDelegate.swift
//  IOSSemestralWork
//
//  Created by Petr Budík on 28/12/2018.
//  Copyright © 2018 Petr Budík. All rights reserved.
//

import UIKit
import RealmSwift
import Toast_Swift

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    weak var navigationController: UINavigationController!
    
    /**
     Returns true when the scheme is set to production. Otherwise false.
     */
    public static let isProduction : Bool = {
        #if DEBUG
            print("DEBUG")
            let dic = ProcessInfo.processInfo.environment
            if let forceProduction = dic["forceProduction"] , forceProduction == "true" {
                return true
            }
            return false
        
        #else
            print("PRODUCTION")
            return true
        #endif
    }()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        print("Realm DB location: \(Realm.Configuration.defaultConfiguration.fileURL!)")
        
        // Initialize realm for the first time. That should be the only time an exception is thrown.
        let realm = AppDependency.shared.realm
        
        if realm.isEmpty {
            firstTimeInit(AppDependency.shared.dbHandler)
        }

        // Set background fetch intervals
        UIApplication.shared.setMinimumBackgroundFetchInterval(UIApplication.backgroundFetchIntervalMinimum)
        
        // Set default Toast values
        ToastManager.shared.duration = 4.0
        ToastManager.shared.position = .center
        ToastManager.shared.style.backgroundColor = UIColor.black.withAlphaComponent(0.71)
        
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.makeKeyAndVisible()
        
        //TODO: Create Flow Coordinators
        // Set up Flow Coordinator
        let navigationController = UINavigationController()
        window?.rootViewController = navigationController
        self.navigationController = navigationController
        
        let vm = RSSFeedEditVM(dependencies: AppDependency.shared)
        let vc = RSSFeedEditVC(vm)
        navigationController.setViewControllers([vc], animated: true)
        
        return true
    }
    
    /**
     Operations which are done only when the app is launched for the first time.
     */
    private func firstTimeInit(_ dbHandler: DBHandler) {
        AppDependency.shared.userDefaults.set(NSDate(), forKey: UserDefaults.Keys.lastUpdate.rawValue)
        
        if !AppDelegate.isProduction {
            let rootFolder = AppDependency.shared.rootFolder
            let folderIdnes = Folder(withTitle: "Idnes", in: rootFolder)
            let folderImages = Folder(withTitle: "WithImages", in: rootFolder)
            
            dbHandler.create(folderIdnes)
            dbHandler.create(folderImages)
            
            dbHandler.create(MyRSSFeed(title: "Zpravodaj", link: "https://servis.idnes.cz/rss.aspx?c=zpravodaj", in: folderIdnes))
            dbHandler.create(MyRSSFeed(title: "Sport", link: "https://servis.idnes.cz/rss.aspx?c=sport", in: folderIdnes))
            dbHandler.create(MyRSSFeed(title: "Wired", link: "http://wired.com/feed/rss", in: folderImages))
            dbHandler.create(MyRSSFeed(title: "Lifehacker", link: "https://lifehacker.com/rss", in: folderImages))
            dbHandler.create(MyRSSFeed(title: "FOX", link: "http://feeds.foxnews.com/foxnews/latest", in: rootFolder))
        }
    }
    
    // MARK: Background fetch
    
    /**
     Background fetch.
     */
    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        print("Started Background fetch")
//        let dbHandler = DBHandler()
//
//        // Updates RSS feeds, calls completionHandler approprietly
//        dbHandler.updateAll { (status) in
//            switch status {
//            case .OK:
//                self.updateUI()
//                AppDependency.shared.userDefaults.set(NSDate(), forKey: UserDefaults.Keys.lastUpdate.rawValue)
//                completionHandler(.newData)
//            case .NotOK:
//                completionHandler(.failed)
//            case .Unreachable:
//                // No internet connection. Tells Ios that it should run backgroundFetch again sooner
//                completionHandler(.noData)
//            }
//        }
    }
    
    /**
     Update UI after Background fetch.
     */
    private func updateUI() {
//        if let navController = window?.rootViewController as? UINavigationController {
//            if let mainVc = navController.topViewController as? ItemTableVC {
//                mainVc.tableView.reloadData()
//            }
//        }
    }
    
    // MARK: Other methods
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

