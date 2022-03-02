//
//  DownloadCell.swift
//  cinepolis
//
//  Created by Victor Manuel Aguado Alvarez on 11/05/17.
//  Copyright © 2017 Firecode. All rights reserved.
//

import Foundation
import UIKit
import SwipeCellKit
import DownloadButton

public enum PKDownloadMovieState: UInt {
    case startDownload
    case pending
    case downloading
    case downloaded
    case paused
}

@objc protocol DownloadCellDelegate {
        func showOptions(reanudar: Bool, anyError: Bool, asset: VirtuosoAsset?, button: PKStopDownloadButton)
        func showAlertMessage(message: String)
        func hiddenAlertAreOpen()
        func refreshData()
        func playVide(asset: VirtuosoAsset)
}

class DownloadCell: SwipeTableViewCell {

     weak var delegateCell: DownloadCellDelegate?

    @IBOutlet private weak var imageMovie: UIImageView!
    @IBOutlet private weak var playAction: UIButton!
    @IBOutlet private weak var labelTitleMovie: UILabel!
    @IBOutlet private weak var labelQuality: UILabel!
    @IBOutlet private weak var labelSize: UILabel!
    @IBOutlet private weak var downloadBtn: PKDownloadButton!
    @IBOutlet private weak var downloadWieghtConstraint: NSLayoutConstraint!
    @IBOutlet private weak var downloadHeigthConstraint: NSLayoutConstraint!
    @IBOutlet private weak var etiquetaStatusDownload: UILabel!

    var asset: VirtuosoAsset?
    var downloading: Bool = false
    var downloadStoping: Bool = false
    var stateDownload: PKDownloadMovieState = PKDownloadMovieState.pending

    override func awakeFromNib() {
        super.awakeFromNib()
        stylize()
        addObserverNotification()
    }

    deinit {
         print("-* deinit DownloadCell ---- *-")
         NotificationCenter.default.removeObserver(self)
     }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }

    func stylize() {

        self.downloadBtn.startDownloadButton.cleanDefaultAppearance()
        self.downloadBtn.startDownloadButton.setBackgroundImage(UIImage.buttonBackground(with:
            UIColor.yellowColors),
                                                                  for: UIControl.State.normal)
        self.downloadBtn.startDownloadButton.setBackgroundImage(UIImage.highlitedButtonBackground(with:
            UIColor.yellowColors),
                                                                  for: UIControl.State.highlighted)
        self.downloadBtn.startDownloadButton.setTitle("REANUDAR",
                                                        for: .normal)
        self.downloadBtn.startDownloadButton.titleLabel?.font = UIFont.systemFont(ofSize: 12)
        self.downloadBtn.startDownloadButton.setTitleColor(UIColor.yellowColors,
                                                             for: .normal)
        self.downloadBtn.startDownloadButton.setTitleColor(UIColor.yellowColors,
                                                             for: .highlighted)
        self.downloadBtn.tintAdjustmentMode = .normal

        let attrs1 = [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 8.5),
                      NSAttributedString.Key.foregroundColor: UIColor.yellowColors]
        let attrs2 = [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 7.5),
                      NSAttributedString.Key.foregroundColor: UIColor.yellowColors]
        let attributedString1 = NSMutableAttributedString(string: "0",
                                                          attributes: attrs1)
        let attributedString2 = NSMutableAttributedString(string: "%",
                                                          attributes: attrs2)
        attributedString1.append(attributedString2)

        self.downloadBtn.stopDownloadButton.radius = 15
        self.downloadBtn.stopDownloadButton.stopButton.setImage(nil, for: .normal)
        self.downloadBtn.stopDownloadButton.stopButton.setNeedsDisplay()
        self.downloadBtn.stopDownloadButton.stopButton.setAttributedTitle(attributedString1, for: .normal)
        self.downloadBtn.pendingView.tintColor = UIColor.yellowColors
    }

    // Add notification from Penthera manager.
    func addObserverNotification() {
        /*
         *  Called whenever the Engine reports progress for a VirtuosoAsset object
         */
        NotificationCenter.default.addObserver(forName: NSNotification.Name.downloadEngineProgressUpdatedForAsset,
                                               object: nil,
                                               queue: nil) { [weak self] (note) in
                                                if let asset: VirtuosoAsset =
                                                    note.userInfo?[kDownloadEngineNotificationAssetKey]
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
                                                if let asset: VirtuosoAsset =
                                                    note.userInfo?[kDownloadEngineNotificationAssetKey]
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
                                                if let asset: VirtuosoAsset =
                                                    note.userInfo?[kDownloadEngineNotificationAssetKey]
                                                    as? VirtuosoAsset {
                                                    UserDefaults().set("0.0", forKey: "progrees")
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
                                                if let asset: VirtuosoAsset =
                                                    note.userInfo?[kDownloadEngineNotificationAssetKey]
                                                    as? VirtuosoAsset {
                                                    print("-* Erron on Download---- *-")
                                                    self?.downloadError(asset: asset)
                                                }
        }

        /*
         *  Called whenever the Engine status changes
         */
        NotificationCenter.default.addObserver(forName: NSNotification.Name.downloadEngineStatusDidChange,
                                               object: nil,
                                               queue: nil) { [weak self] (_) in
                                                self?.updateStatusLabel()
        }

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(downloadNetwork(_:)),
                                               name: NSNotification.Name(rawValue:
                                                Utils.share.Download_Notifier_Network),
                                               object: nil)
    }

    func configView(pendingAssets: [VirtuosoAsset], completedAssets: [VirtuosoAsset], indexPath: IndexPath) {
        var urlImg: String = ""
        var title: String = ""
        var quality: String = ""
        var moviesSize: String = ""

        // Go and get the asset.
        var asset: VirtuosoAsset?
        if !pendingAssets.isEmpty && indexPath.section == 0 {
            asset = pendingAssets[indexPath.row]
            if let asset = asset {
                self.asset = asset
                playAction.isHidden = true
                downloadBtn.isHidden = false
                // get info from Movie
                let infoMovie = asset.userInfo as NSDictionary?
                let downloadStatus = VirtuosoDownloadEngine.instance()

                var sizeMovie = Float(asset.estimatedSize) / 1000000
                if sizeMovie >= 1000 {
                    sizeMovie /= 1000
                    let format = NSString(format: "%.01f", sizeMovie)
                    moviesSize = "\(format) GB"
                } else {
                    let format = NSString(format: "%.01f", sizeMovie)
                    moviesSize = "\(format) MB"
                }

                urlImg = infoMovie?.object(forKey: "image") as? String ?? ""
                title = infoMovie?.object(forKey: "title") as? String ?? ""
                quality = infoMovie?.object(forKey: "format") as? String ?? ""

                labelQuality.text = "Quality" + ": \(quality)"
                labelSize.text = moviesSize

                switch downloadStatus.status {
                case .vde_Disabled, .vde_Blocked:
                    // pausada
                    downloadWieghtConstraint.constant = 85
                    downloadHeigthConstraint.constant = 30
                    etiquetaStatusDownload.text = "Download paused"
                    downloadBtn.state = PKDownloadButtonState.startDownload
                    downloadBtn.startDownloadButton.setTitle("REANUDAR", for: .normal)

                case .vde_Errors:
                    labelQuality.text = ""
                    labelSize.text = ""
                    etiquetaStatusDownload.text = "Unsuccessful download"

                case .vde_AuthenticationFailure:
                    labelQuality.text = ""
                    labelSize.text = ""
                    etiquetaStatusDownload.text = "Falló la licencia del SDK"
                case .vde_Idle:
                        pauseDownload()
                        etiquetaStatusDownload.text = "Downloading is enabled, but queue is empty"
                case .vde_Downloading:
                    // descargado
                    setProgresDowloading()
                    downloadBtn.state = PKDownloadButtonState.downloading
                    etiquetaStatusDownload.text = "Downloading"

                default:
                    print("error")
                }
            }
        } else {
            asset = completedAssets[indexPath.row]
            if let asset = asset {
                playAction.isHidden = false
                downloadBtn.isHidden = true
                self.asset = asset
                // get info from Movie
                let infoMovie = asset.userInfo as NSDictionary?
                var moviesSize: String = ""

                var sizeMovie = Float(asset.estimatedSize) / 1000000
                if sizeMovie >= 1000 {
                    sizeMovie /= 1000
                    let format = NSString(format: "%.01f", sizeMovie)
                    moviesSize = "\(format) GB"

                } else {
                    // print("-----MB-\(sizeMovie)")
                    let format = NSString(format: "%.01f", sizeMovie)
                    moviesSize = "\(format) MB"
                }


                urlImg = infoMovie?.object(forKey: "image") as? String ?? ""
                title = infoMovie?.object(forKey: "title") as? String ?? ""
                quality = infoMovie?.object(forKey: "format") as? String ?? ""

                /*downloadBtn.state = PKDownloadButtonState.downloaded
                downloadWieghtConstraint.constant = 35
                downloadHeigthConstraint.constant = 30

                downloadBtn.downloadedButton.cleanDefaultAppearance()
                downloadBtn.downloadedButton.setBackgroundImage(UIImage.buttonBackground(with: UIColor.clear),
                                                                  for: .normal)
                downloadBtn.downloadedButton.setBackgroundImage(UIImage.highlitedButtonBackground(with:
                    UIColor.clear),
                                                                  for: .highlighted)
                downloadBtn.downloadedButton.setTitle("", for: .normal)
                downloadBtn.downloadedButton.setImage(#imageLiteral(resourceName: "icoDescargar2"), for: .normal)
                downloadBtn.downloadedButton.setTitleColor(UIColor.clear, for: .normal)
                downloadBtn.downloadedButton.setTitleColor(UIColor.clear, for: .highlighted)
                downloadBtn.downloadedButton.tintColor = UIColor.clear
                downloadBtn.pendingView.tintColor = UIColor.clear*/

                labelQuality.text = "Quality" + ": \(quality)"
                labelSize.text = moviesSize
                etiquetaStatusDownload.text = "Downloaded movie"
            }
        }

        imageMovie.image = #imageLiteral(resourceName: urlImg)
        labelTitleMovie.text = title
    }
}

// MARK: - events
extension DownloadCell {

    func updateStatusLabel() {
        let engine = VirtuosoDownloadEngine.instance()
        let status: kVDE_DownloadEngineStatus = engine.status
        switch status {
        case .vde_Blocked, .vde_Disabled :
            print("Blocked")
           // if !engine.diskStatusOK {
               pauseDownload()
           // }
        default:
            print("")
        }
    }

    func setProgresDowloading() {

        let progress = UserDefaults().double(forKey: "progrees")
        let progresFloat = Float(progress)

        if progress != 0.0 && progress < 1.0 {

            DispatchQueue.main.async {
                let progress = ((progress * 100) / 5)
                let cantidaProgress = Int(progress.rounded(.down) * 5 )
                let attrs1 = [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 8.5),
                              NSAttributedString.Key.foregroundColor: UIColor.yellowColors]
                let attrs2 = [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 7.5),
                              NSAttributedString.Key.foregroundColor: UIColor.yellowColors]

                let attributedString1 = NSMutableAttributedString(string: "\(cantidaProgress)",
                    attributes: attrs1)
                let attributedString2 = NSMutableAttributedString(string: "%",
                                                                  attributes: attrs2)
                attributedString1.append(attributedString2)

                self.stateDownload = PKDownloadMovieState.downloading
                self.downloadBtn.stopDownloadButton.stopButton.setImage(nil, for: .normal)
                self.downloadBtn.stopDownloadButton.stopButton.setNeedsDisplay()
                self.downloadBtn.stopDownloadButton.stopButton.setAttributedTitle(attributedString1, for: .normal)
                self.downloadBtn.state = PKDownloadButtonState.downloading
                self.downloadWieghtConstraint.constant = 35
                self.downloadHeigthConstraint.constant = 30
                self.downloadBtn.setNeedsLayout()
                self.downloadBtn.setNeedsDisplay()
                self.downloadBtn.layoutIfNeeded()
                self.downloadBtn.stopDownloadButton.progress = CGFloat(progresFloat)

            }
        }
    }

    func downloadProgressHLS(asset: VirtuosoAsset?) {
        if let asset = asset {
            if self.asset?.assetID == asset.assetID {
                if !downloadStoping {
                    DispatchQueue.main.async {

                        UserDefaults().set(asset.fractionComplete, forKey: "progrees")
                        let progress = ((asset.fractionComplete * 100) / 5)
                        let cantidaProgress = Int(progress.rounded(.down) * 5 )

                        let attrs1 = [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 8.5),
                                      NSAttributedString.Key.foregroundColor: UIColor.yellowColors]
                        let attrs2 = [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 7.5),
                                      NSAttributedString.Key.foregroundColor: UIColor.yellowColors]

                        let attributedString1 = NSMutableAttributedString(string: "\(cantidaProgress)",
                            attributes: attrs1)
                        let attributedString2 = NSMutableAttributedString(string: "%",
                                                                          attributes: attrs2)
                        attributedString1.append(attributedString2)

                        self.stateDownload = PKDownloadMovieState.downloading
                        self.downloadBtn.stopDownloadButton.stopButton.setImage(nil,
                                                                                  for: .normal)
                        self.downloadBtn.stopDownloadButton.stopButton.setNeedsDisplay()
                        self.downloadBtn.stopDownloadButton.stopButton.setAttributedTitle(attributedString1,
                                                                                            for: .normal)
                        self.downloadBtn.state = PKDownloadButtonState.downloading
                        self.downloadWieghtConstraint.constant = 35
                        self.downloadHeigthConstraint.constant = 30
                        self.downloadBtn.stopDownloadButton.progress = CGFloat(asset.fractionComplete)
                        self.downloadBtn.setNeedsLayout()
                        self.downloadBtn.setNeedsDisplay()
                        self.downloadBtn.layoutIfNeeded()
                    }
                } else {
                   downloadStoping = true
                }
            }
        }
    }

    func downloadCompleteHLS(asset: VirtuosoAsset?) {
        if let asset = asset {
            if self.asset?.assetID == asset.assetID {
                DispatchQueue.main.async {
                    UserDefaults().set(false, forKey: "pauseByUser")
                    self.delegateCell?.hiddenAlertAreOpen()
                    self.delegateCell?.refreshData()
                }
            }
        }
    }

    func downloadError(asset: VirtuosoAsset?) {
        if let asset = asset {
            if self.asset?.assetID == asset.assetID {
                VirtuosoDownloadEngine.instance().enabled = false
                downloadStoping = true

                DispatchQueue.main.async {
                    self.stateDownload = PKDownloadMovieState.paused
                    self.downloadWieghtConstraint.constant = 85
                    self.downloadHeigthConstraint.constant = 30
                    self.downloadBtn.state = PKDownloadButtonState.startDownload
                    self.downloadBtn.startDownloadButton.setTitle("REANUDAR", for: .normal)
                    self.delegateCell?.showAlertMessage(message: "Download error, to retry tap on resume.")
                }
            }
        }
    }

    func pauseDownload() {

        if DownloadPentheraManager.share.checkMovieInProgress() {
            VirtuosoDownloadEngine.instance().enabled = false
            UserDefaults.standard.set(true, forKey: "pauseByUser")
            self.stateDownload = PKDownloadMovieState.paused
            self.downloadWieghtConstraint.constant = 85
            self.downloadHeigthConstraint.constant = 30
            self.downloadBtn.state = PKDownloadButtonState.startDownload
            self.downloadBtn.startDownloadButton.setTitle("REANUDAR", for: .normal)
        }
    }
}

// MARK: - NSNotification
extension DownloadCell {

    @objc func downloadNetwork(_ aNotification: NSNotification) {
        if let networkObj = aNotification.object as? String {
            if networkObj == "CEL" {
                if Utils.share.isWifiDownload() {
                     pauseDownload()
                }
            }
            if networkObj == "NO" {
                pauseDownload()
            }
        }
    }
}

// MARK: - PKDownloadButtonDelegate
extension DownloadCell: PKDownloadButtonDelegate {

    func downloadButtonTapped(_ downloadButton: PKDownloadButton!, currentState state: PKDownloadButtonState) {
        switch state {
        case .startDownload:
            let downloadStatus = VirtuosoDownloadEngine.instance()
            downloadStoping = false
            switch downloadStatus.status {
            case .vde_AuthenticationFailure, .vde_Errors:
                if let asset = self.asset {
                    delegateCell?.showOptions(reanudar: true, anyError: true,
                                              asset: asset, button: downloadBtn.stopDownloadButton)
                }
            default:
                if let asset = self.asset {
                    delegateCell?.showOptions(reanudar: true, anyError: false,
                                              asset: asset, button: downloadBtn.stopDownloadButton)
                }
            }
        case .downloaded:
            if let asset = self.asset {
                delegateCell?.playVide(asset: asset)
            }
        case .downloading, .pending:
            if let asset = self.asset {
                delegateCell?.showOptions(reanudar: false, anyError: false,
                                          asset: asset, button: downloadBtn.stopDownloadButton)
            }
        default:
            print("")
        }
     }

    @IBAction func playConten(_ sender: AnyObject) {
        if let asset = self.asset {
            delegateCell?.playVide(asset: asset)
        }
    }
}
