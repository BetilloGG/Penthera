//
//  ViewController.swift
//  Example8.2
//
//  Created by Penthera on 2/6/20.
//  Copyright © 2020 Penthera. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    // <-- change these to your settings in production
    let backplaneUrl = "https://cinepolis.penthera.com"
    let publicKey = "76a4a9b54e3e72b481c5aae0f8783c1ed9416b3915446d912cd069cdf23e7471"
    let privateKey = "119e51baa9a83f0f23f732dfdaed6bcabdb367c1f82b73d67242bcab94a16345"

    // IMPORTANT:
    // DRM Setup requires these parameters
    private var sampleAssetManifestUrl: String? = "https://hlscf.cinepolisklic.com/usp-s3-storage/clear/coleccion-venom-venom-carnage-liberado/coleccion-venom-venom-carnage-liberado_fp.ism/.m3u8?filter=(type==%22audio%22)%7C%7C(type==%22textstream%22)%7C%7C(type==%22video%22%26%26MaxHeight%3C=480)"               // <-- replace this with a proper value
    private var sampleAssetType = kVDE_AssetType.vde_AssetTypeHLS   // This must match the asset type for sampleAssetManifestUrl

    private var certificateUrl: String? = "https://lic.drmtoday.com/license-server-fairplay/cert/cinepolis"       // <-- replace this with a proper value
    private var licenseUrl: String? = "https://lic.drmtoday.com/license-server-fairplay/"           // <-- replace this with a proper value
    private var authenticationXml: String? = "nil"    // <-- replace this with a proper value
    private var userID: String? = "11514946"               // <-- replace this with a proper value
    private var customerName: String? = "cinepolis"         // <-- replace this with a proper value
    private var sessionID: String? = String.random(length: 10)            // <-- replace this with a proper value

    //
    // MARK: Instance data
    //
    var exampleAsset: VirtuosoAsset?
    var downloadEngineNotifications: VirtuosoDownloadEngineNotificationManager!
    var hasDownloaded = false
    var error: Error?
   // var drmSetup: CastDrmSetup!

    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var playBtn: UIButton!
    @IBOutlet weak var downloadBtn: UIButton!
    @IBOutlet weak var deleteBtn: UIButton!
    @IBOutlet weak var statusProgressBar: UIProgressView!

    override func viewDidLoad()
    {
        super.viewDidLoad()
        // download engine update listener
        downloadEngineNotifications = VirtuosoDownloadEngineNotificationManager.init(delegate: self)
    }



    func startup() {

        // Backplane permissions require a unique user-id for the full range of captabilities support to work
        // Production code that needs this will need a unique customer ID.
        // For demonstation purposes only, we use the device name
        let userName = UIDevice.current.name

        //
        // Create the engine confuration
        guard let config = VirtuosoEngineConfig(user: userName,
                                                backplaneUrl: self.backplaneUrl,
                                                publicKey: self.publicKey,
                                                privateKey: self.privateKey)
        else
        {
            DispatchQueue.main.async {
                let alert = UIAlertController(title: "Setup Required", message: "Please contact support@penthera.com to setup the backplaneUrl, publicKey, and privateKey", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
                    exit(0)
                }))
                self.present(alert, animated: true, completion: nil)
            }
            return
        }

        //
        // Start the Engine
        // This method will execute async, the callback will happen on the main-thread.
        VirtuosoDownloadEngine.instance().startup(config) { (status) in
            if status != .vde_EngineStartupSuccess {
                let alert = UIAlertController(title: "Startup Failed", message: "Startup completed with status: \(status.rawValue)", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
                }))
                self.present(alert, animated: true, completion: nil)
            }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    func displayAsset(asset: VirtuosoAsset) {
        let fractionComplete = asset.fractionComplete
        let status = asset.status
        var errorAdd = ""
        if( asset.downloadRetryCount > 0 ) {
            errorAdd = String(format: " (Errors: %i)", asset.downloadRetryCount)
        }
        if status != .vde_DownloadComplete && status != .vde_DownloadProcessing {
            let optionalStatus = (asset.status == .vde_DownloadInitializing) ? NSLocalizedString("Initializing: ", comment: "") : ""
            statusLabel.text = String(format: "%@ %@%0.02f%% (%qi MB)%@", asset, optionalStatus, fractionComplete*100.0, asset.currentSize/1024/1024, errorAdd)
            statusProgressBar.progress = Float(fractionComplete)
            downloadBtn.isEnabled = false
        }
        else if status == .vde_DownloadComplete {
            statusLabel.text = String(format: "%@ %0.02f%% (%qi MB)", asset, fractionComplete*100.0, asset.currentSize/1024/1024)
            statusProgressBar.progress = Float(fractionComplete)
        }
    }

    private func loadEngineData() {
        self.error = nil

        DispatchQueue.global().async {
            if VirtuosoDownloadEngine.instance().started {
                let downloadComplete = VirtuosoAsset.completedAssets(withAvailabilityFilter: false)
                let downloadPending = VirtuosoAsset.pendingAssets(withAvailabilityFilter: false)
                DispatchQueue.main.async {
                    if downloadComplete.count > 0 {
                        self.exampleAsset = downloadComplete.first as? VirtuosoAsset
                    }
                    else if downloadPending.count > 0 {
                        self.exampleAsset = downloadPending.first as? VirtuosoAsset
                    }
                    else {
                        self.exampleAsset = nil
                    }
                    self.refreshView()
                }
            }
            else {
                DispatchQueue.main.async {
                    self.loadEngineData()
                }
            }
        }
    }

    private func refreshView() {
        guard let asset = self.exampleAsset else {
            self.statusLabel.text = "Ready to download"
            self.downloadBtn.backgroundColor = UIColor.black
            self.playBtn.backgroundColor = UIColor.lightGray
            self.downloadBtn.isEnabled = true
            self.playBtn.isEnabled = false

            if nil != self.error {
                deleteBtn.isEnabled = true
                deleteBtn.backgroundColor = UIColor.black
            } else {
                deleteBtn.isEnabled = false
                deleteBtn.backgroundColor = UIColor.lightGray
            }

            self.statusProgressBar.progress = 0
            return
        }

        if asset.fractionComplete < 1.0 {
            statusLabel.text = "Downloading..."
        } else {
            statusLabel.text = "Ready to play"
        }

        deleteBtn.isEnabled = true
        deleteBtn.backgroundColor = UIColor.black
        downloadBtn.isEnabled = false
        downloadBtn.backgroundColor = UIColor.lightGray

        statusProgressBar.progress = Float(asset.fractionComplete)

        VirtuosoAsset.isPlayable(asset) { (playable) in
            if playable {
                self.playBtn.isEnabled = true
                self.playBtn.backgroundColor = UIColor.black
            } else {
                self.playBtn.isEnabled = false
                self.playBtn.backgroundColor = UIColor.lightGray
            }
        }
    }

    @IBAction func deleteBtnClicked(_ sender: UIButton) {
        sender.isEnabled = false   // Block reentry

        guard let asset = self.exampleAsset else { return }
        asset.delete {
            self.statusLabel.text = ""
            self.statusProgressBar.progress = 0
            // Give next smartdownload time to get started
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: {
                self.loadEngineData()
            })
        }
    }

    @IBAction func playBtnClicked(_ sender: UIButton) {
        guard let asset = self.exampleAsset else {
            print("asset not playable yet")
            return
        }

        VirtuosoAsset.isPlayable(asset) { (playable) in
            if !playable { return }

            switch(asset.type) {
            case .vde_AssetTypeHLS, .vde_AssetTypeDASH, .vde_AssetTypeNonSegmented:
                let demoPlayer = DemoPlayerViewController()

                asset.play(using: .vde_AssetPlaybackTypeLocal, andPlayer: demoPlayer as VirtuosoPlayer, onSuccess: {
                    self.present(demoPlayer, animated: true, completion: nil)

                }) {
                    self.exampleAsset = nil
                    self.error = nil
                    print("Video is unplayble.")
                }
                break

            case .vde_AssetTypeHSS:
                print("Playback of HSS supported in another Tutorial")
                break

            @unknown default:
                break;
            }
        }
    }

    @IBAction func downloadBtnClicked(_ sender: UIButton) {

        startup()

        sender.isEnabled = false // block reentrancy while we create the asset

       /* if .vde_ReachableViaWiFi != VirtuosoDownloadEngine.instance().currentNetworkStatus() {
            let alertView = UIAlertController(title: "Network Unreachable", message: "Demo requires WiFi", preferredStyle: .alert)
            alertView.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: { (action) in
                sender.isEnabled = true
            }))
            self.present(alertView, animated: true, completion: nil)
            return
        }*/

        guard let manifestUrl = self.sampleAssetManifestUrl else {
            let alert = UIAlertController(title: "Invalid Manifest", message: "Please enter required value for sampleAssetManifestUrl. App will now exit.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
                exit(0)
            }))
            self.present(alert, animated: true, completion: nil)
            return
        }

        // Create the Asset on a background thread
        DispatchQueue.global(qos: .background).async {
            // Create asset configuration object
            guard let config = VirtuosoAssetConfig(url: manifestUrl,
                                                   assetID: "coleccion-venom-venom-carnage-liberado",
                                                   description: "Colección: Venom + Venom: Carnage Liberado",
                                                   type: self.sampleAssetType) else {
                                                    print("create config failed")
                                                    sender.isEnabled = true
                                                    return
            }
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
                sender.isEnabled = true
                self.hasDownloaded = true
                self.refreshView()
            }
        }
    }
}

// MARK: - String
extension String {
    static func random(length: Int = 20) -> String {
        let base = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        var randomString: String = ""

        for _ in 0..<length {
            let randomValue = arc4random_uniform(UInt32(base.count))
            randomString += "\(base[base.index(base.startIndex, offsetBy: Int(randomValue))])"
        }
        return randomString
    }
}

extension ViewController: VirtuosoDownloadEngineNotificationsDelegate {

    //
    // MARK: VirtuosoDownloadEngineNotificationsDelegate - required methods ONLY
    //

    // --------------------------------------------------------------
    //  Called whenever the Engine starts downloading a VirtuosoAsset object.
    // --------------------------------------------------------------
    func downloadEngineDidStartDownloadingAsset(_ asset: VirtuosoAsset)
    {
        displayAsset(asset: asset)
    }

    // --------------------------------------------------------------
    // Called whenever the Engine reports progress for a VirtuosoAsset object
    // --------------------------------------------------------------
    func downloadEngineProgressUpdated(for asset: VirtuosoAsset)
    {
        DispatchQueue.global(qos: .background).async {
            VirtuosoAsset.isPlayable(asset) { (playable) in
                if playable {
                    self.exampleAsset = asset;
                    self.refreshView()
                }
                self.displayAsset(asset: asset)
            }
        }
    }

    // --------------------------------------------------------------
    // Called when an asset is being processed after background transfer
    // --------------------------------------------------------------
    func downloadEngineProgressUpdatedProcessing(for asset: VirtuosoAsset)
    {
        displayAsset(asset: asset)
    }

    // --------------------------------------------------------------
    // Called whenever the Engine reports a VirtuosoAsset as complete
    // --------------------------------------------------------------
    func downloadEngineDidFinishDownloadingAsset(_ asset: VirtuosoAsset)
    {
        // Download is complete
        displayAsset(asset: asset)
        refreshView()
        loadEngineData()
    }

    // --------------------------------------------------------------
    // Called whenever an Engine encounters error downloading asset
    // --------------------------------------------------------------
    func downloadEngineDidEncounterError(for asset: VirtuosoAsset, error: Error?, task: URLSessionTask?, data: Data?, statusCode: NSNumber?) {
        self.error = error
        displayAsset(asset: asset)
        refreshView()
        loadEngineData()
    }

    // --------------------------------------------------------------
    // Called whenever an asset is added to the Engine
    // --------------------------------------------------------------
    func downloadEngineInternalQueueUpdate() {
        loadEngineData()
    }

    // --------------------------------------------------------------
    // Called whenever Engine start completes
    // --------------------------------------------------------------
    func downloadEngineStartupComplete(_ succeeded: Bool) {
        loadEngineData()
    }

    func downloadEngineNetworkReachabilityChange(_ previousNetworkReachability: kVL_BearerType,
                                                 currentNetworkReachability: kVL_BearerType) {
        switch currentNetworkReachability {
        case .vl_BearerWifi:
            print("vl_BearerWifi")
            //VirtuosoDownloadEngine.instance().enabled = false
        case .vl_BearerNone:
            print("vl_BearerNone")
            //VirtuosoDownloadEngine.instance().enabled = false
        case .vl_BearerCellular:
            print("vl_BearerCellular")
          //  VirtuosoDownloadEngine.instance().enabled = false
        default:
            print("vl_BearerCellular...---")
            //VirtuosoDownloadEngine.instance().enabled = false
        }
    }
}
