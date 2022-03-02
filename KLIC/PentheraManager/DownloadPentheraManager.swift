//
//  DownloadPentheraManager.swift
//  cinepolis
//
//  Created by José Alberto González Gordillo on 20/11/18.
//  Copyright © 2018 IA Interactive. All rights reserved.
//

import VirtuosoClientDownloadEngine
import UserNotifications

class DownloadPentheraManager: NSObject {

    // MARK: - Instance
    static let share = DownloadPentheraManager()
    var pendingAssets: NSMutableArray = []
    var completedAssets: NSMutableArray = []

    private var downloadEngineNotifications: VirtuosoDownloadEngineNotificationManager!
    private let backplaneUrl = "https://cinepolis.penthera.com"
    private let publicKey = "76a4a9b54e3e72b481c5aae0f8783c1ed9416b3915446d912cd069cdf23e7471"
    private let privateKey = "119e51baa9a83f0f23f732dfdaed6bcabdb367c1f82b73d67242bcab94a16345"

    private var certificateUrl: String? = "https://lic.drmtoday.com/license-server-fairplay/cert/cinepolis"
    private var licenseUrl: String? = "https://lic.drmtoday.com/license-server-fairplay/"

    private var sampleAssetType = kVDE_AssetType.vde_AssetTypeHLS   // This must match the asset type for

    func appDelegate() -> AppDelegate? {
        return UIApplication.shared.delegate as? AppDelegate
    }

    fileprivate override init() {
        super.init()

        // download engine update listener
        downloadEngineNotifications = VirtuosoDownloadEngineNotificationManager.init(delegate: self)

        /*
         *  Called whenever the Engine status changes
         */
        NotificationCenter.default.addObserver(forName: NSNotification.Name.downloadEngineStatusDidChange,
                                               object: nil,
                                               queue: nil) { (_) in
            self.updateStatusLabel()
        }

        /*
         *  Called whenever the Engine reports a VirtuosoAsset as complete
         */
        NotificationCenter.default.addObserver(forName:
                                                NSNotification.Name.downloadEngineDidFinishDownloadingAsset,
                                               object: nil,
                                               queue: nil) { (_) in
            UserDefaults().set("0.0", forKey: "progrees")
            DispatchQueue.main.async {
                UIApplication.shared.isIdleTimerDisabled = false
                print("off Now")
            }
        }

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.reachabilityChanged),
                                               name: ReachabilityChangedNotification,
                                               object: self.appDelegate()?.reachability)
    }

    @objc func reachabilityChanged(note: NSNotification) {
        if let reachObj: Reachability = note.object as? Reachability {
            if reachObj.isReachable {
                if !reachObj.isReachableViaWiFi {
                    NotificationCenter.default.post(name:
                        NSNotification.Name(rawValue: "DOWNLOAD_NOTIFIER_NETWORK"),
                                                    object: "CEL")
                } else {
                    NotificationCenter.default.post(name:
                        NSNotification.Name(rawValue:
                            "DOWNLOAD_NOTIFIER_NETWORK"),
                                                    object: "WIFI")
                }
            } else {
                // self.pauseAll()
                NotificationCenter.default.post(name:
                    NSNotification.Name(rawValue: "DOWNLOAD_NOTIFIER_NETWORK"),
                                                object: "NO")
            }
        }
    }

    // check status Dowload
    func updateStatusLabel() {
        let engine = VirtuosoDownloadEngine.instance()
        let status: kVDE_DownloadEngineStatus = engine.status

        switch status {
        case .vde_Blocked:
            print("Blocked")
            if !engine.diskStatusOK {
                let pendingAssets = NSMutableArray(array: VirtuosoAsset.pendingAssets(withAvailabilityFilter: false))
                    if pendingAssets.firstObject != nil {
                        if let asset = pendingAssets[0] as? VirtuosoAsset {
                        NotificationCenter.default.post(name:
                                                       NSNotification.Name(rawValue: "stateNotificationSizeMovie"),
                                                        object: asset.assetID)
                        }
                }
               /* if pendingAssets.count > 0 {
                    if let asset = pendingAssets[0] as? VirtuosoAsset {
                            NotificationCenter.default.post(name:
                                NSNotification.Name(rawValue: "stateNotificationSizeMovie"),
                                                            object: asset)
                    }
                }*/
            }
        case .vde_Idle:
            print("Idle")
        case .vde_Errors:
            print("Halted For Download Errors")
        case .vde_Disabled:
            print("Disabled")
        case .vde_Downloading:
            print("Downloading")
        default:
            print("")
        }
    }

    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }

    // check all movies completes
    func checkMovieAll(movies: String) -> Bool {
        let  movie = VirtuosoAsset.completedAssets(withAvailabilityFilter: false)
        return  movie.contains { (objet) -> Bool in
            if let asset = objet as? VirtuosoAsset {
                return asset.assetID.elementsEqual(movies)
            }
            return false
        }
    }

    func checkMovieAll(movies: String, userID: String) -> Bool {
        let  movie = VirtuosoAsset.completedAssets(withAvailabilityFilter: false)
        return  movie.contains { (objet) -> Bool in
            if let asset = objet as? VirtuosoAsset {
                if let userId = asset.userInfo?["userId"] as? String, userId == userID {
                     return asset.assetID.elementsEqual(movies)
                }
            }
            return false
        }
    }

     // check if the movie is in progress
    func checkDowloadingMovie(movies: String) -> Bool {
        let  movie = VirtuosoAsset.pendingAssets(withAvailabilityFilter: false)
        return  movie.contains { (objet) -> Bool in
            if let asset = objet as? VirtuosoAsset {
                return asset.assetID.elementsEqual(movies)
            }
            return false
        }
    }

    // check if the movie is in progress
   func getProgressMovie() -> VirtuosoAsset {
       let movies = VirtuosoAsset.pendingAssets(withAvailabilityFilter: false)
       if let movie = movies as? [VirtuosoAsset],
          let asset = movie.first {
           return asset
       }
       return VirtuosoAsset()
   }

    // check if existe a movie in progress
    func checkMovieInProgress() -> Bool {
        if !VirtuosoAsset.pendingAssets(withAvailabilityFilter: false).isEmpty {
            return true
        }
        return false
    }

    // check if existe a movie complete
    func checkMovieInCompleted() -> Bool {
        if !VirtuosoAsset.completedAssets(withAvailabilityFilter: false).isEmpty {
            return true
        }
        return false
    }

    func checkContaninMovies() {
        if checkMovieInProgress() || checkMovieInCompleted() {
            setState(status: true)
        } else {
            setState(status: false)
        }
    }

    // get movie complete
    func getCompleteMovie(movie: String?) -> VirtuosoAsset? {
        var completed: NSMutableArray = []
        guard let assedMovie = movie  else { return nil }
        //let intance = VirtuosoDownloadEngine.instance()
       // if intance.started {
            completed = NSMutableArray(array: VirtuosoAsset.completedAssets(withAvailabilityFilter: false))

            for elemt in completed {
                if let asset = elemt as? VirtuosoAsset {
                    if asset.assetID == "\(assedMovie)" {
                       return asset
                    }
                } else {
                    return nil
                }
            }
       // }
        return nil
    }

    // get movie on progress and complete
    func getInfoMovies() {
        var pending: NSMutableArray = []
        var completed: NSMutableArray = []

        // Return the number of rows in the section.
        let intance = VirtuosoDownloadEngine.instance()

        DispatchQueue.main.async {
            if intance.started {

                pending = NSMutableArray(array: VirtuosoAsset.pendingAssets(withAvailabilityFilter: false))
                completed = NSMutableArray(array: VirtuosoAsset.completedAssets(withAvailabilityFilter: false))

            }
            DispatchQueue.main.async {
                self.pendingAssets = pending
                self.completedAssets = completed
            }
        }
    }

    // Error on player
    func showErrorForAsset(asset: VirtuosoAsset) -> String {
        if asset.isExpired {
            return "La película ha caducado."
        } else {
            return "Error en la descarga \n\n Hubo un detalle, te invitamos a descargar nuevamente el contenido."
        }
    }

    func setState(status: Bool) {
        // save status download.
        guard let user = UserDefaults.standard.object(forKey: Utils.share.USERINFO) as? NSDictionary,
            let userId = user.object(forKey: "email") as? String else { return }
        UserDefaults().set(status, forKey: userId)
    }

    // set a new movie
    func fetchDownloadSet(url: String, properties: NSMutableDictionary) {
        let assetID = properties.object(forKey: "assetId") as? String ?? ""
        let descriptionMovie = properties.object(forKey: "descrition") as? String ?? ""

        virtuosoStartup()

        // Create the Asset on a background thread
        DispatchQueue.global(qos: .background).async {
            // Create asset configuration object
            guard let config = VirtuosoAssetConfig(url: url,
                                                   assetID: assetID,
                                                   description: descriptionMovie,
                                                   type: self.sampleAssetType) else {
                                                    print("create config failed")
                                                    return
            }
            config.userInfo = properties as? [AnyHashable: Any]
            config.includeEncryption = false
            config.protectionType = kVDE_AssetProtectionType.vde_AssetProtectionTypeFairPlay

            // Create asset and commence downloading.
            let _ = VirtuosoAsset.init(config: config)

            //
            // Alternatively, you can create a Playlist directly using the following:
            // VirtuosoPlaylistManager.instance().create(withItems: playlists)

            //
            // Playlists can be appended to as well
            // VirtuosoPlaylistManager.instance().appendItems(playlists)

            DispatchQueue.main.async {
                UIApplication.shared.isIdleTimerDisabled = true
                print("not off")
            }
        }
    }
}

//
// MARK: VirtuosoDownload Startup
//

extension DownloadPentheraManager {

    func virtuosoStartup(_ checkDownloadProgres: Bool = false) {

        VirtuosoSettings.instance().minimumBackplaneSyncInterval = kDownloadEngineSyncIntervalMinimum
        VirtuosoSettings.instance().overrideHeadroom(500)

        // Backplane permissions require a unique user-id for the full range of captabilities support to work
        // Production code that needs this will need a unique customer ID.
        // For demonstation purposes only, we use the device name
        var userPentehera = "KLIC"
        guard let user = UserDefaults.standard.object(forKey: Utils.share.USERINFO) as? NSDictionary,
            let userEmail = user.object(forKey: "email") as? String else { return }
                userPentehera = userEmail

        //
        // Create the engine confuration
        guard let config = VirtuosoEngineConfig(user: userPentehera,
                                                backplaneUrl: self.backplaneUrl,
                                                publicKey: self.publicKey,
                                                privateKey: self.privateKey)
        else {
            DispatchQueue.main.async {
                print("Setup Required")
                print("Please contact support@penthera.com to setup the backplaneUrl, publicKey, and privateKey")
            }
            return
        }

        //
        // Start the Engine
        // This method will execute async, the callback will happen on the main-thread.
        VirtuosoDownloadEngine.instance().startup(config) { (status) in
            if status != .vde_EngineStartupSuccess {
                print("Startup Failed")
                print("Startup completed with status: \(status.rawValue)")
            }
            if status == .vde_EngineStartupSuccess {
                print("Startup OK")
            }
        }

        VirtuosoSettings.instance().overrideDownloadOverCellular(true)

        if checkDownloadProgres {
            VirtuosoDownloadEngine.instance().enabled = false
        } else {
            VirtuosoDownloadEngine.instance().enabled = true
        }
    }
}

//
// MARK: VirtuosoDownloadEngineNotificationsDelegate - required methods ONLY
//

extension DownloadPentheraManager: VirtuosoDownloadEngineNotificationsDelegate {

    // --------------------------------------------------------------
    //  Called whenever the Engine starts downloading a VirtuosoAsset object.
    // --------------------------------------------------------------
    func downloadEngineDidStartDownloadingAsset(_ asset: VirtuosoAsset) {
       // displayAsset(asset: asset)
    }

    // --------------------------------------------------------------
    // Called whenever the Engine reports progress for a VirtuosoAsset object
    // --------------------------------------------------------------
    func downloadEngineProgressUpdated(for asset: VirtuosoAsset) {
       /* DispatchQueue.global(qos: .background).async {
            VirtuosoAsset.isPlayable(asset) { (playable) in
                if playable {
                    self.exampleAsset = asset;
                    self.refreshView()
                }
                self.displayAsset(asset: asset)
            }
        }*/
    }

    // --------------------------------------------------------------
    // Called when an asset is being processed after background transfer
    // --------------------------------------------------------------
    func downloadEngineProgressUpdatedProcessing(for asset: VirtuosoAsset) {
        //displayAsset(asset: asset)
    }

    // --------------------------------------------------------------
    // Called whenever the Engine reports a VirtuosoAsset as complete
    // --------------------------------------------------------------
    func downloadEngineDidFinishDownloadingAsset(_ asset: VirtuosoAsset) {
        // Download is complete
       /* UserDefaults().set("0.0", forKey: "progrees")
        DispatchQueue.main.async {
            UIApplication.shared.isIdleTimerDisabled = false
            print("off Now")
        }*/
    }

    // --------------------------------------------------------------
    // Called whenever an Engine encounters error downloading asset
    // --------------------------------------------------------------
    func downloadEngineDidEncounterError(for asset: VirtuosoAsset,
                                         error: Error?,
                                         task: URLSessionTask?,
                                         data: Data?,
                                         statusCode: NSNumber?) {
       // self.error = error
       // displayAsset(asset: asset)
       // refreshView()
       // loadEngineData()
    }

    // --------------------------------------------------------------
    // Called whenever an asset is added to the Engine
    // --------------------------------------------------------------
    func downloadEngineInternalQueueUpdate() {
        //loadEngineData()
    }

    // --------------------------------------------------------------
    // Called whenever Engine start completes
    // --------------------------------------------------------------
    func downloadEngineStartupComplete(_ succeeded: Bool) {
       // loadEngineData()
    }

    func downloadEngineStatusChange(_ status: kVDE_DownloadEngineStatus, statusInfo: VirtuosoEngineStatusInfo) {
        // self.updateStatusLabel()
    }
}
