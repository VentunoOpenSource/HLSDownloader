//
//  AppDelegate.swift
//  demoOfflineVideo
//
//  Created by Ventuno Technologies on 15/11/19.
//  Copyright © 2019 Ventuno Technologies. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, URLSessionDownloadDelegate{
    


    var window: UIWindow? = UIWindow(frame: UIScreen.main.bounds)
    
    
    
     func application(application: UIApplication, willFinishLaunchingWithOptions launchOptions: [NSObject : AnyObject]?) -> Bool {
        window?.rootViewController = UIViewController() //just template to make compile possible
        window?.makeKeyAndVisible()
        
        return true
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        print("location \(location)")
    }
    
    
    func applicationWillTerminate(_ application: UIApplication) {
          // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
          // Saves changes in the application's managed object context before the application terminates.

    }
    
    func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void) {
        print("handleEventsForBackgroundURLSession")       
    }
    
}

