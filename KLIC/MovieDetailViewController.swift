//
//  MovieDetailViewController.swift
//  DemosPenthera
//
//  Created by José Alberto González Gordillo on 23/02/22.
//

import UIKit
import DownloadButton

class MovieDetailViewController: UIViewController {

    @IBOutlet private weak var containerStackView: UIStackView!

    var purchasedMovieDetailView: PurchasedMovieDetailView!

    var movie: Movie!
    var userInfo: NSDictionary!
    var assetId: String = ""
    var isCanDownload: Bool = false
    var starDownload: Bool = true
    var sessionID = String.random(length: 10)

    override func viewDidLoad() {
        super.viewDidLoad()
        if let userInfo = UserDefaults.standard.object(forKey: Utils.share.USERINFO) as? NSDictionary {
            self.userInfo = userInfo
            configMovieDetailView()
        }
        self.addObserverNotification()
        // Do any additional setup after loading the view.
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if !self.isMovingToParent {
            checkDownload()
        }
    }

    // Config viewController
    func configMovieDetailView() {

        self.purchasedMovieDetailView = Bundle.main.loadNibNamed("PurchasedMovieDetailView",
                                                                owner: nil,
                                                                options: nil)?.first
        as? PurchasedMovieDetailView

        self.purchasedMovieDetailView.delegate = self
        self.purchasedMovieDetailView.configView(movieModel: self.movie)
        containerStackView.addArrangedSubview(self.purchasedMovieDetailView)
        self.isCanDownload = true
        self.purchasedMovieDetailView.isHiddenDownloadButton(isHidden: false)
        self.checkStateDownload()
    }

    // Add notification from Penthera manager.
    func addObserverNotification() {

        NotificationCenter.default.addObserver(self, selector: #selector(stateNotificationSizeMovie(_:)),
                                               name: NSNotification.Name(rawValue: "stateNotificationSizeMovie"),
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(downloadNetwork(_:)),
                                               name: NSNotification.Name(rawValue:
                                                Utils.share.Download_Notifier_Network),
                                               object: nil)

        /*
         *  Called whenever the Engine reports progress for a VirtuosoAsset object
         */
        NotificationCenter.default.addObserver(forName: NSNotification.Name.downloadEngineProgressUpdatedForAsset,
                                               object: nil,
                                               queue: nil) { [weak self] (note) in
        if let asset: VirtuosoAsset = note.userInfo?[kDownloadEngineNotificationAssetKey]
            as? VirtuosoAsset {
            self?.downloadProgressHLS(asset: asset)
                             }
        }

        /*
         *  Called when an asset is being processed after background transfer
         */
        NotificationCenter.default.addObserver(forName:
            NSNotification.Name.downloadEngineProgressUpdatedForAssetProcessing,
                                               object: nil,
                                               queue: nil) { [weak self] (note) in
        if let asset: VirtuosoAsset = note.userInfo?[kDownloadEngineNotificationAssetKey]
        as? VirtuosoAsset {
            self?.downloadProgressHLS(asset: asset)
                         }
        }

        /*
         *  Called whenever the Engine reports a VirtuosoAsset as complete
         */
        NotificationCenter.default.addObserver(forName: NSNotification.Name.downloadEngineDidFinishDownloadingAsset,
                                               object: nil,
                                               queue: nil) { [weak self] (note) in
        if let asset: VirtuosoAsset = note.userInfo?[kDownloadEngineNotificationAssetKey]
            as? VirtuosoAsset {
            print("-* Descarga completa MovieController *-")
            self?.downloadCompleteHLS(asset: asset)
                               }
        }

        /*
         *  Called whenever the Engine encounters an error that it cannot recover from.
         This type of error will cause the engine to retry download of the file.  If too many
         *  errors are encountered, the Engine will move on to the next item in the queue.
         */

        NotificationCenter.default.addObserver(forName: NSNotification.Name.downloadEngineDidEncounterError,
                                               object: nil,
                                               queue: nil) { [weak self] (note) in
    if let asset: VirtuosoAsset = note.userInfo?[kDownloadEngineNotificationAssetKey]
             as? VirtuosoAsset {
       print("-* Erron on Download---- *-")
            self?.downloadError(asset: asset)
                    }
            }
    }
}

// MARK: - NotificationCenter
extension MovieDetailViewController {
    // NotificationCenter  size movie whit the movieDownloading
    @objc func stateNotificationSizeMovie(_ aNotification: NSNotification) {
        self.stateNotificationSizeMovie()
    }

    // NotificationCenter  CLMovieDownloadSet Delegate
    @objc func downloadNetwork(_ aNotification: NSNotification) {
        if let networkObj = aNotification.object as? String {
            if networkObj == "CEL" {
                if Utils.share.isWifiDownload() {
                    self.downloadNetwork(network: "CEL")
                }
            }
            if networkObj == "NO" {
                 self.downloadNetwork(network: "NO")
            }
        }
    }

    // NotificationCenter PKDownloadButton Penthera
    func downloadProgressHLS(asset: VirtuosoAsset?) {
        self.downloadProgress(asset: asset)
    }

    // NotificationCenter Complete Download
    func downloadCompleteHLS(asset: VirtuosoAsset?) {
        self.downloadComplete(asset: asset)
    }

    // NotificationCenter DownloadError
    func downloadError(asset: VirtuosoAsset?) {
        if self.purchasedMovieDetailView != nil {
            DispatchQueue.main.async {
                self.purchasedMovieDetailView.pauseDownload()
            }
        }
    }
}

// MARK: - NotificationCenter action
extension MovieDetailViewController {

    // NotificationCenter PKDownloadButton Penthera
    func downloadProgress(asset: VirtuosoAsset?) {
        guard let asset = asset else { return }
        if self.assetId == asset.assetID {
            if asset.fractionComplete < 1.0 {
                DispatchQueue.main.async {
                    UserDefaults().set(asset.fractionComplete, forKey: "progrees")
                    let progress = ((asset.fractionComplete * 100) / 5)
                    let cantidaProgress = Int(progress.rounded(.down) * 5 )

                    let attrs1 = [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 6.5),
                                  NSAttributedString.Key.foregroundColor: UIColor.yellowColors]
                    let attrs2 = [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 5.5),
                                  NSAttributedString.Key.foregroundColor: UIColor.yellowColors]
                    let attributedString1 = NSMutableAttributedString(string: "\(cantidaProgress)",
                                                                      attributes: attrs1)
                    let attributedString2 = NSMutableAttributedString(string: "%",
                                                                      attributes: attrs2)
                    attributedString1.append(attributedString2)

                    if self.purchasedMovieDetailView != nil {
                        let engine = VirtuosoDownloadEngine.instance()
                        if engine.enabled {
                            self.purchasedMovieDetailView.downloadingButton(asset: asset, progress: attributedString1)
                        }
                    }
                }
            }
        }
    }

    func downloadComplete(asset: VirtuosoAsset?) {
        self.starDownload = true
        UserDefaults().set("0.0", forKey: "progrees")
        // hidden alert
        //presenter?.hiddenAlertAreOpen()
        guard let asset = asset else { return }
        if self.assetId == asset.assetID {
            if self.purchasedMovieDetailView != nil {
                DispatchQueue.main.async {
                    self.purchasedMovieDetailView.downloadCompleteHLS()
                }
            }
        }
    }

    func stateNotificationSizeMovie() {
        VirtuosoDownloadEngine.instance().enabled = false

            if self.purchasedMovieDetailView != nil {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    UIApplication.shared.isIdleTimerDisabled = false
                    print("off Now")
                    if DownloadPentheraManager.share.checkMovieInProgress() {
                        self.purchasedMovieDetailView.pauseDownload()
                    } else {
                        self.purchasedMovieDetailView.cancelDownload()
                    }
                }
            }
        self.showAlert(message: "We have detected that you do not have enough space")
    }

    func downloadNetwork(network: String) {

        if network == "CEL" {
            if self.purchasedMovieDetailView != nil {
                if self.purchasedMovieDetailView.buttonStateDownloading() {
                    VirtuosoDownloadEngine.instance().enabled = false
                    DispatchQueue.main.async {
                        UIApplication.shared.isIdleTimerDisabled = false
                        print("off Now")
                        self.purchasedMovieDetailView.pauseDownload()
                    }
                }
            }

            if DownloadPentheraManager.share.checkMovieInProgress() {
                DispatchQueue.main.async {
                    self.showAlert(message: "It is canceled due to change to Cellular Data.")
                }
            }
        }
        if network == "NO" {

            if self.purchasedMovieDetailView != nil {
                if self.purchasedMovieDetailView.buttonStateDownloading() {
                    if DownloadPentheraManager.share.checkMovieInProgress() {
                        VirtuosoDownloadEngine.instance().enabled = false
                        DispatchQueue.main.async {
                            UIApplication.shared.isIdleTimerDisabled = false
                            print("off Now")
                            self.purchasedMovieDetailView.pauseDownload()
                        }
                    }
                }
            }

            if DownloadPentheraManager.share.checkMovieInProgress() {
                DispatchQueue.main.async {
                    if DownloadPentheraManager.share.checkDowloadingMovie(movies: self.assetId) {
                        self.showAlert(message: "You do not have an Internet connection. Please check and try again.")
                    }
                }
            }
        }
    }
}

// MARK: - MovieDetailDelegate
extension MovieDetailViewController: MovieDetailDelegate {

    func downloadTapped() {
        print("downloadTapped")
    }

    func seeNowDisconnectedTapped() {
        guard let assetMovie = DownloadPentheraManager.share.getCompleteMovie(movie: self.assetId) else {
            showAlert(message: "The movie cannot be played.")
            return
        }
        self.playVideoPenthera(asset: assetMovie)
    }

    func seeNowConnected() {
        print("seeNowConnected")
    }

    func showMessage(message: String) {
        print("showMessage")
    }

    func downloadButtonTapped(_ downloadButton: PKDownloadButton!, currentState state: PKDownloadButtonState) {

        switch state {
        case .startDownload:
            let isWifi: Bool = self.appDelegate()?.reachability?.isReachableViaWiFi ?? false

            if isWifi {
                // star download
                self.downloadWhitChangeConection(downloadButton: downloadButton)

            } else {
                // 3G
                // star download with 3G
                let isConexion: Bool = self.appDelegate()?.reachability?.isReachable ?? false
                if isConexion {
                    if !Utils.share.isWifiDownload() {

                        self.downloadWhitChangeConection(downloadButton: downloadButton)

                    } else {
                        self.showAlert(message: "You have configured the download to only by Wifi")
                    }
                } else {
                    self.showAlert(message: "You do not have an Internet connection. Please check and try again.")
                }
            }
        case .downloaded:
          // Downloaded movie
            guard let assetMovie = DownloadPentheraManager.share.getCompleteMovie(movie: self.assetId) else {
                    self.showAlert(message: "La película no se puede reproducir.")
                     return
                 }
            self.playVideoPenthera(asset: assetMovie)
        case .downloading:
            // options for when the movie is downloading
            self.showOptionDownloading(status: .downloading,
                                       downloadButton: downloadButton,
                                       callBackAction: { (optionSheet) in
                switch optionSheet {
                case .cancelDownload:
                    self.actionSheetCancelDownload()
                case .pauseDownloads:
                    self.actionSheetPauseDownload()
                case .seeDownloads:
                    self.openDownloadViewController()
                default:
                    print("")
                }
            })
        default:
            print(state.rawValue)
        }
    }
}

// MARK: - Downloads
extension MovieDetailViewController {

    // Star Downloads
    func  downloadWhitChangeConection(downloadButton: PKDownloadButton!) {

        if DownloadPentheraManager.share.checkMovieInProgress() {
            if DownloadPentheraManager.share.checkDowloadingMovie(movies: self.assetId) {
                let engine = VirtuosoDownloadEngine.instance()
                let status: kVDE_DownloadEngineStatus = engine.status
                switch status {
                case .vde_AuthenticationFailure:
                    self.showOptionDownloading(status: .resumen,
                                               downloadButton: downloadButton,
                                               callBackAction: { (optionSheet) in
                        switch optionSheet {
                        case .cancelDownload:
                            self.actionSheetCancelDownload()
                        case .seeDownloads:
                            self.openDownloadViewController()
                        default:
                            print("")
                        }
                    })

                case .vde_Disabled, .vde_Downloading:
                    self.showOptionDownloading(status: .resumen,
                                               downloadButton: downloadButton,
                                               callBackAction: { (optionSheet) in
                        switch optionSheet {
                        case .resumenDownload:
                            downloadButton.state = PKDownloadButtonState.pending
                            UserDefaults().set(false, forKey: "pauseByUser")
                            VirtuosoDownloadEngine.instance().enabled = true
                            DispatchQueue.main.async {
                                UIApplication.shared.isIdleTimerDisabled = true
                                print("not off")
                                self.purchasedMovieDetailView.pendingDownload()
                            }
                        case .cancelDownload:
                            self.actionSheetCancelDownload()
                        case .seeDownloads:
                           self.openDownloadViewController()
                        default:
                            print("")
                        }
                    })
                default:
                    print("")
                }
            } else {
                showAlert(message: "Content is currently being downloaded.")
            }

        } else {
            self.startDownload(clContentId: self.assetId)
        }
    }

    // Check if exist a download on progress
    func checkStateDownload() {
        if let assetId = self.movie.assetId,
            let userId = userInfo.object(forKey: "userId") as? String {
            self.assetId = "\(assetId)"

            if DownloadPentheraManager.share.checkMovieInProgress() {
                       if DownloadPentheraManager.share.checkDowloadingMovie(movies: self.assetId) {
                           self.purchasedMovieDetailView.downloadStackView(isHidden: true)
                           self.purchasedMovieDetailView.progressDownloadStackView(isHidden: false)
                           if self.purchasedMovieDetailView != nil {
                            self.purchasedMovieDetailView.downloadButtonState(state: .pending)
                            self.purchasedMovieDetailView.pendingDownload()
                               starDownloader()
                           }
                       }
                   }

            if DownloadPentheraManager.share.checkMovieAll(movies: self.assetId, userID: "\(userId)") {
                self.purchasedMovieDetailView.downloadStackView(isHidden: true)
                self.purchasedMovieDetailView.progressDownloadStackView(isHidden: true)
                self.purchasedMovieDetailView.seeNowDisconnectedStackView(isHidden: false)
            }
        }
    }

    // Star download Movie
    func startDownload(clContentId: String) {
        self.purchasedMovieDetailView.setPendingState()
        self.downloadMovie(format: MovieFormat.SD, sesion: self.sessionID)
    }

    // Cancel Download
    func cancelDownload() {
        self.purchasedMovieDetailView.cancelDownload()
    }

    // PKDownloadButton Delegate
    func downloadMovie(format: MovieFormat, sesion: String) {

        UserDefaults().set(false, forKey: "pauseByUser")

        let sesionTmp = sesion.isEmpty ? self.sessionID : sesion
        let idMovie = Utils.share.digitNumber
        let properties: NSMutableDictionary = NSMutableDictionary()
        if  let userId = self.userInfo.object(forKey: "userId") {

            properties.setValue(movie.assetId, forKey: "assetId")
            properties.setValue("\(userId)", forKey: "userId")
            properties.setValue(sesionTmp, forKey: "sessionId")
            properties.setValue(format.rawValue, forKey: "format")
            properties.setValue(movie.url, forKey: "url")
            properties.setValue(movie.movieTitle, forKey: "title")
            properties.setValue(movie.movieDescrition, forKey: "descrition")
            properties.setValue("", forKey: "localUrl")
            properties.setValue(movie.poster, forKey: "image")
            properties.setValue(movie.mediaID, forKey: "mediaID")
            properties.setValue("\(idMovie)", forKey: "id")
            properties.setValue("", forKey: "progresSize")
            properties.setValue("movie", forKey: "movieType")

            if let sizeFreeDisk = Utils.share.getFreeSize() {
                if sizeFreeDisk >= 900.0 {
                    DownloadPentheraManager.share.setState(status: true)
                    DownloadPentheraManager.share.fetchDownloadSet(url: movie.url, properties: properties)
                } else {
                    NotificationCenter.default.post(name:
                                                        NSNotification.Name(rawValue: "stateNotificationSizeMovie"),
                                                    object: movie.assetId)
                }
            }
        }
    }

    // Star download a movie
    func starDownloader() {
        if DownloadPentheraManager.share.checkDowloadingMovie(movies: self.assetId) {
             let downloadStatus = VirtuosoDownloadEngine.instance()
            switch downloadStatus.status {
            case .vde_Disabled:
                // Paused
                DispatchQueue.main.async {
                self.purchasedMovieDetailView.pauseDownload()
                }
            case .vde_Blocked:
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    VirtuosoDownloadEngine.instance().enabled = false
                    self.purchasedMovieDetailView.pauseDownload()
                    self.showAlert(message: "We have detected that you do not have enough space")
                }
            case .vde_Errors:
                print("vde_Errors")
            case .vde_AuthenticationFailure:
                print("vde_AuthenticationFailure")
                DispatchQueue.main.async {
                   VirtuosoDownloadEngine.instance().enabled = false
                   self.purchasedMovieDetailView.pauseDownload()
                }
                self.showAlert(message: "SDK license failed")
            case .vde_Idle:
                DispatchQueue.main.async {
                    VirtuosoDownloadEngine.instance().enabled = false
                    self.purchasedMovieDetailView.pauseDownload()
                    self.showAlert(message: "Downloading is enabled, but queue is empty")
                }
            case .vde_Downloading:
                // Downloading
                if self.purchasedMovieDetailView != nil {
                    self.purchasedMovieDetailView.setProgresDowloading()
                }
                self.purchasedMovieDetailView.initDownloadButton()
            default:
                 print("")
            }
            self.purchasedMovieDetailView.configDownloadButton(isHidden: false)
        } else {
            self.purchasedMovieDetailView.cancelDownload()
        }
    }

   // check the status of the movie
    func checkDownload() {
        // download pending
         if DownloadPentheraManager.share.checkDowloadingMovie(movies: self.assetId) {
              let downloadStatus = VirtuosoDownloadEngine.instance()
             switch downloadStatus.status {
             case .vde_Disabled:
                 // Paused
                 DispatchQueue.main.async {
                 self.purchasedMovieDetailView.pauseDownload()
                 }
             case .vde_Blocked:
                 DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                     VirtuosoDownloadEngine.instance().enabled = false
                     self.purchasedMovieDetailView.pauseDownload()
                 }
             case .vde_Errors:
                 print("vde_Errors")
             case .vde_AuthenticationFailure:
                 print("vde_AuthenticationFailure")
                 DispatchQueue.main.async {
                     VirtuosoDownloadEngine.instance().enabled = false
                    self.purchasedMovieDetailView.pauseDownload()
                 }
             case .vde_Downloading, .vde_Idle:
                   // Downloading
                 if self.purchasedMovieDetailView != nil {
                     DispatchQueue.main.asyncAfter(deadline: .now()) {
                         self.purchasedMovieDetailView.pendingDownload()
                         self.purchasedMovieDetailView.setProgresDowloading()
                     }
                 }
             default:
                  print("")
             }
            self.purchasedMovieDetailView.configDownloadButton(isHidden: false)
         } else {
            var userIds = ""
            if let user = UserDefaults.standard.object(forKey: Utils.share.USERINFO) as? NSDictionary,
                let userId: String = user.object(forKey: "userId") as? String {
                userIds = userId
            }
            if DownloadPentheraManager.share.checkMovieAll(movies: self.assetId, userID: "\(userIds)") {
                self.purchasedMovieDetailView.downloadStackView(isHidden: true)
                self.purchasedMovieDetailView.progressDownloadStackView(isHidden: true)
                self.purchasedMovieDetailView.seeNowDisconnectedStackView(isHidden: false)
            } else {
                if self.purchasedMovieDetailView != nil && self.isCanDownload {
                    self.purchasedMovieDetailView.cancelDownload()
                }
            }
        }
     }

    // Play Content Downloaded
    func playVideoPenthera(asset: VirtuosoAsset) {

        VirtuosoAsset.isPlayable(asset) { (playable) in
            if !playable { return }

            switch(asset.type) {
            case .vde_AssetTypeHLS, .vde_AssetTypeDASH, .vde_AssetTypeNonSegmented:
                let demoPlayer = DemoPlayerViewController()

                asset.play(using: .vde_AssetPlaybackTypeLocal, andPlayer: demoPlayer as VirtuosoPlayer, onSuccess: {
                    self.present(demoPlayer, animated: true, completion: nil)

                }) {
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

    // Play Button action
    func playWithoutConexion() {
        guard let assetMovie = DownloadPentheraManager.share.getCompleteMovie(movie: self.assetId) else {
            showAlert(message: "The movie cannot be played.")
            return
        }
         self.playVideoPenthera(asset: assetMovie)
    }
}

// MARK: - ActionSheet
extension MovieDetailViewController {

    func showOptionDownloading(status: StatusDownloads,
                               downloadButton: PKDownloadButton,
                               callBackAction: ((OptionActionSheet) -> Void)?) {
        DispatchQueue.main.async {
            self.actionSheetDownloads(status: status, downloadButton: downloadButton,
                                      callBackAction: callBackAction)
        }
    }
}

// MARK: - Option Action Sheet
extension MovieDetailViewController {

    func actionSheetCancelDownload() {
        self.starDownload = true
        UserDefaults().set("0.0", forKey: "progrees")
        UserDefaults.standard.set(false, forKey: "pauseByUser")

        let pendingAssets = NSMutableArray(array: VirtuosoAsset.pendingAssets(withAvailabilityFilter: false))
        if let asset = pendingAssets[0] as? VirtuosoAsset {

            asset.delete(onComplete: {

                DispatchQueue.main.async {
                    UIApplication.shared.isIdleTimerDisabled = false
                    print("off Now")
                    // new state
                    DownloadPentheraManager.share.checkContaninMovies()
                    self.purchasedMovieDetailView.cancelDownload()
                }
            })
        }
    }

    func actionSheetPauseDownload() {
        UserDefaults.standard.set(true, forKey: "pauseByUser")
        VirtuosoDownloadEngine.instance().enabled = false
        DispatchQueue.main.async {
            UIApplication.shared.isIdleTimerDisabled = false
            print("off Now")
            self.starDownload = true
            self.purchasedMovieDetailView.pauseDownload()
        }
    }
}


// MARK: - Downloads
extension MovieDetailViewController {

    func openDownloadViewController() {

        let storyboard = UIStoryboard(name: "MisDescargas",
                                      bundle: nil)
        if let viewDownloads = storyboard.instantiateViewController(withIdentifier:
                                                                        "DownloadsController") as? DownloadsController {
            self.navigationController?.pushViewController(viewDownloads, animated: true)
        }
    }
}
