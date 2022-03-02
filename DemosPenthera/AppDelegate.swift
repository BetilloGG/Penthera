//
//  AppDelegate.swift
//  Example8.2
//
//  Created by Penthera on 2/6/20.
//  Copyright © 2020 Penthera. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    private var certificateUrl: String? = "https://lic.drmtoday.com/license-server-fairplay/cert/cinepolis"       // <-- replace this with a proper value
    private var licenseUrl: String? = "https://lic.drmtoday.com/license-server-fairplay/"           // <-- replace this with a proper value
    private var authenticationXml: String? = "nil"    // <-- replace this with a proper value
    private var userID: String? = "11514946"               // <-- replace this with a proper value
    private var customerName: String? = "cinepolis"         // <-- replace this with a proper value
    private var sessionID: String? = String.random(length: 10)


    var window: UIWindow?
    let reachability = Reachability()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        do {
            guard let reachability = reachability else { return true }
            try reachability.startNotifier()
        } catch {
            print("Unable to start notifier")
        }

        setLogin()
        

        UserDefaults.standard.set(true, forKey: "Virtuoso.SkipBitmovinDetection")
        UserDefaults.standard.setValue(true, forKey: "Virtuoso.SkipBitmovinDetection")


        VirtuosoLogger.setLogLevel(.vl_LogVerbose)          // Verbose might be overkill for Production.
        VirtuosoLogger.enableLogs(toFile: false)            // Setting to true will save Virtuoso logs to disk

        castDrmSetup()
        return true
    }


    func setLogin() {
        let reponse = [
            "domainId": "6355554",
            "loginStatus": "1",
            "email": "cinepolisklic@ia.com.mx",
            "lastname": "IA VIP",
            "userId": "11514946",
            "name": "Desarrollo"
            ] as [String: AnyObject]

        UserDefaults.standard.set(reponse, forKey: Utils.share.USERINFO)
    }
}

extension AppDelegate {

    func castDrmSetup() {

        // download engine update listener
       // downloadEngineNotifications = VirtuosoDownloadEngineNotificationManager.init(delegate: self)
        let sessionID = String.random(length: 10)

        guard let drmSetup = CastDrmSetup(certificateUrl: certificateUrl,
                                licenseUrl: licenseUrl,
                                authXml: "nil",
                                userID: userID,
                                customerName: customerName,
                                          sessionID: sessionID) else {
            print("DRM Setup Required")
            print("Please enter required parameters. App will now exit.")
            return
        }

        if !drmSetup.configure() {
            print("Configure Incomplete")
            print("Please setup the VirtuosoLicenseConfiguration parameters as ")
            print("shown in the configure method. App will now exit.")
        }
        if drmSetup.configure() {
            print("Configure Complete")
            // After the complete configuration in the following view "HomeViewController" it will check if there are pending downloads or in process to pause them
            //VirtuosoDownloadEngine.instance().enabled = true
        }
    }
}

