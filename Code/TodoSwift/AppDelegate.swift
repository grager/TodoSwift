//
//  AppDelegate.swift
//  TodoSwift
//
//  Created by Cyril Chandelier on 31/10/15.
//  Copyright © 2015 Cyril Chandelier. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate
{
    var window: UIWindow?

    private func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool
    {
        // Customize UI
        UIApplication.shared.statusBarStyle = UIStatusBarStyle.lightContent
        UINavigationBar.appearance().barTintColor = UIColor(red: 80.0/255.0, green: 70.0/255.0, blue: 60.0/255.0, alpha: 1.0)
        UINavigationBar.appearance().barStyle = UIBarStyle.black
        UINavigationBar.appearance().tintColor = UIColor.white
        
        return true
    }

    private func applicationWillTerminate(application: UIApplication)
    {
        CoreDataController.sharedInstance.saveContext()
    }
}

