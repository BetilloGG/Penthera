//
//  DownloadsController.swift
//  cinepolis
//
//  Created by Victor Manuel Aguado Alvarez on 11/05/17.
//  Copyright © 2017 Firecode. All rights reserved.
//

import Foundation
import SwipeCellKit
import KVNProgress
import UIKit
import DownloadButton


class DownloadsController: UIViewController, SwipeTableViewCellDelegate, DownloadCellDelegate {

    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var etiqueta1: UILabel!
    @IBOutlet private weak var etiqueta2: UILabel!
    @IBOutlet private weak var emptySate: UIImageView!

    var pendingAssets: [VirtuosoAsset] = []
    var completedAssets: [VirtuosoAsset] = []
    var player: UIViewController = UIViewController()
    var starNewDownlader: Bool = false
    var movieIdStar = ""
    var idStar = ""

    override func viewDidLoad() {
        super.viewDidLoad()


        if !isiPad() {
            let value = UIInterfaceOrientation.portrait.rawValue
            UIDevice.current.setValue(value, forKey: "orientation")
        }
        self.hiddenLabels(ishidden: true)

        if self.connected() {
            KVNProgress.show()
        }


        self.navigationController?.navigationBar.isTranslucent = false
        self.navigationController?.navigationBar.titleTextAttributes =
            [NSAttributedString.Key.foregroundColor: UIColor.yellowColors]
        let label = UIBarButtonItem(title: "My downloads",
                                    style: .plain,
                                    target: nil, action: nil)
        let backMenu = UIBarButtonItem(image:
                                        UIImage(named: "iconLeft")?.imageWithSize(size: CGSize(width: 25, height: 25)),
                                       style: UIBarButtonItem.Style.plain,
                                       target: self, action: #selector(backAction(_:)))
        self.navigationItem.leftBarButtonItems = [backMenu, label]
        NotificationCenter.default.addObserver(self, selector: #selector(self.reachabilityChanged),
                                               name: ReachabilityChangedNotification,
                                               object: self.appDelegate()?.reachability)
        self.refreshData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setNeedsStatusBarAppearanceUpdate()
        // rotation exit
        if !isiPad() {
            let value = UIInterfaceOrientation.portrait.rawValue
            UIDevice.current.setValue(value, forKey: "orientation")
          //  self.appDelegate()?.interfaceOrientation = false
        }
    }

    override var prefersStatusBarHidden: Bool {
        return false
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        .lightContent
    }

    deinit {
        print("-* deinit DownloadsController ---- *-")
        NotificationCenter.default.removeObserver(self)
        if KVNProgress.isVisible() {
            KVNProgress.dismiss()
        }
    }

     func getInfo(_ completion:@escaping(Bool) -> Void) {
        var userid = ""
        if let user = UserDefaults.standard.object(forKey: Utils.share.USERINFO) as? NSDictionary,
            let userId = user.object(forKey: "userId") {
            userid = "\(userId)"
        }

        pendingAssets = []
        completedAssets = []

        var pending: [VirtuosoAsset] = []
        var completed: [VirtuosoAsset] = []

        // Return the number of rows in the section.
       // let intance = VirtuosoDownloadEngine.instance()
        DispatchQueue.main.async {
           // if intance.started {
                if let newPending = VirtuosoAsset.pendingAssets(withAvailabilityFilter: false) as? [VirtuosoAsset] {
                    pending = newPending
                }
                if let newCompleted = VirtuosoAsset.completedAssets(withAvailabilityFilter: false) as? [VirtuosoAsset] {
                    completed = newCompleted
             //   }
            }

            DispatchQueue.main.async {
                for movie in pending where movie.userInfo?["userId"] as? String == userid {
                    self.pendingAssets.append(movie)
                }
                for movie in completed where movie.userInfo?["userId"] as? String == userid {
                    self.completedAssets.append(movie)
                }
                completion(true)
            }
        }
    }

    @objc func reachabilityChanged(note: NSNotification) {
        if  DownloadPentheraManager.share.checkMovieInProgress() {
            VirtuosoDownloadEngine.instance().enabled = false
            DispatchQueue.main.async {
                self.refreshData()
            }
        }
    }

    func refreshData() {
        DispatchQueue.main.async {
            self.getInfo { (succes) in
                if succes {
                    if self.pendingAssets == [] && self.completedAssets == [] {
                        self.hiddenLabels(ishidden: false)
                    } else {
                        self.hiddenLabels(ishidden: true)
                    }
                    self.tableView.reloadData()
                    KVNProgress.dismiss()
                }
            }
        }
    }

    @IBAction func backAction(_ sender: AnyObject) {
        self.navigationController?.popViewController(animated: true)
    }
}

// MARK: - Player View
extension DownloadsController {
    func playVide(asset: VirtuosoAsset) {

        if asset.isPlayable {

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
    }

    func showAlertMessage(message: String) {
        self.showAlert(message: message)
    }
}

// MARK: - Alert view
extension DownloadsController {

    // hidden alert
    func hiddenAlertAreOpen() {
        DispatchQueue.main.async {
            if let window = self.appDelegate()?.window {
                let presentedViewController = window.rootViewController?.presentedViewController
                if presentedViewController != nil,
                   (presentedViewController is UIActivityViewController) ||
                    (presentedViewController is UIAlertController) {
                    presentedViewController?.dismiss(animated: true, completion: nil)
                }
            }
        }
    }

    // i send button for show actionSheet ob buttton.
    func showOptions(reanudar: Bool = false, anyError: Bool = false,
                     asset: VirtuosoAsset?, button: PKStopDownloadButton) {

        let optionMenu = UIAlertController(title: nil,
                                           message: "Download options",
                                           preferredStyle: .actionSheet)
        let cancelAction = UIAlertAction(title: "Cancel download",
                                         style: .default, handler: {(_: UIAlertAction!) -> Void in
            DispatchQueue.main.async {
                KVNProgress.show()
                let deadlineTime = DispatchTime.now() + 0.4
                DispatchQueue.main.asyncAfter(deadline: deadlineTime) {
                    UserDefaults().set(false, forKey: "pauseByUser")
                    UserDefaults().set("0.0", forKey: "progrees")
                    asset?.delete(onComplete: {
                        print("off Now")
                        // new state
                        DownloadPentheraManager.share.checkContaninMovies()
                        UIApplication.shared.isIdleTimerDisabled = false
                        self.refreshData()
                    })
                }
            }
        })

        let reanudarAction = UIAlertAction(title: "Resume download",
                                           style: .default, handler: {(_: UIAlertAction!) -> Void in

            let engines = VirtuosoDownloadEngine.instance()
            let status: kVDE_DownloadEngineStatus = engines.status

            if self.isWifi() {
                engines.enabled = true
                UserDefaults().set(false, forKey: "pauseByUser")
                if status == .vde_Blocked {
                    if !engines.diskStatusOK {
                        self.showAlertMessage(message: "We have detected that you do not have enough space to download this content.")
                    }
                }

                DispatchQueue.main.async {
                    UIApplication.shared.isIdleTimerDisabled = false
                    print("off Now")
                    self.refreshData()
                }

            } else {

                let isConexion: Bool = self.appDelegate()?.reachability?.isReachable ?? false
                if isConexion {

                    if !Utils.share.isWifiDownload() {

                        engines.enabled = true
                        UserDefaults().set(false, forKey: "pauseByUser")

                        if status == .vde_Blocked {
                            if !engines.diskStatusOK {
                                self.showAlertMessage(message: "We have detected that you do not have enough space to download this content.")
                            }
                        }

                        DispatchQueue.main.async {
                            UIApplication.shared.isIdleTimerDisabled = true
                            print("off Now")
                            self.refreshData()
                        }
                    } else {
                        self.showAlertMessage(message: "You have configured the download to only by Wifi.")
                    }
                } else {
                    self.showAlertMessage(message: "You do not have an Internet connection.")
                }
            }

        })

        let pauseAction = UIAlertAction(title: "pause download",
                                        style: .default, handler: {(_: UIAlertAction!) -> Void in

            VirtuosoDownloadEngine.instance().enabled = false
            DispatchQueue.main.asyncAfter(deadline: .now(), execute: {
                UserDefaults.standard.set(true, forKey: "pauseByUser")
                UIApplication.shared.isIdleTimerDisabled = false
                print("off Now")
                self.refreshData()
            })
        })

        let exitAction = UIAlertAction(title: "Cancel",
                                       style: .cancel, handler: {(_: UIAlertAction!) -> Void in
            print("Cancelled")
        })

        if reanudar {
            if !anyError {
                optionMenu.addAction(reanudarAction)
            }
            optionMenu.addAction(cancelAction)
            optionMenu.addAction(exitAction)
        } else {
            optionMenu.addAction(pauseAction)
            optionMenu.addAction(cancelAction)
            optionMenu.addAction(exitAction)
        }

        if isiPad() {
            if let currentPopoverpresentioncontroller = optionMenu.popoverPresentationController {
                currentPopoverpresentioncontroller.sourceView = button
                currentPopoverpresentioncontroller.sourceRect = button.bounds
                currentPopoverpresentioncontroller.permittedArrowDirections = UIPopoverArrowDirection.up
                self.present(optionMenu, animated: true, completion: nil)
            }
        } else {
            self.present(optionMenu, animated: true, completion: nil)
        }
    }

    func hiddenLabels(ishidden: Bool) {
        etiqueta1.isHidden = ishidden
        etiqueta2.isHidden = ishidden
        emptySate.isHidden = ishidden
    }
}

// MARK: - UITableViewDataSource
extension DownloadsController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        if !pendingAssets.isEmpty {
            return 2
        } else {
            return 1
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            if !pendingAssets.isEmpty {
                return 1
            } else {
                return completedAssets.count
            }
        } else {
            return completedAssets.count
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell: DownloadCell =
            tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
                as? DownloadCell else { return UITableViewCell() }
        cell.delegate = self
        cell.delegateCell = self
        cell.configView(pendingAssets: pendingAssets, completedAssets: completedAssets, indexPath: indexPath)
        return cell
    }
}

// MARK: - UITableViewDelegate
extension DownloadsController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return isiPad() ? 180 : 135
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView: UIView = UIView(frame: CGRect(x: 0, y: 0, width: 150, height: 50))
        headerView.backgroundColor = UIColor.clear

        let header: UILabel = UILabel(frame: CGRect(x: 20, y: 20, width: 150, height: 25))
        header.text = ""
        header.textColor = UIColor.white
        header.backgroundColor = UIColor.clear
        headerView.addSubview(header)
        return headerView
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 15
    }

    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath,
                   for orientation: SwipeActionsOrientation) -> [SwipeAction]? {

        guard orientation == .right else { return nil }
        let deleteAction = SwipeAction(style: .destructive,
                                       title: "Delete") { _, indexPath in
            DispatchQueue.main.async {
                KVNProgress.show()
                let deadlineTime = DispatchTime.now() + 0.4
                DispatchQueue.main.asyncAfter(deadline: deadlineTime) {
                    if indexPath.section == 0 && !self.pendingAssets.isEmpty {
                        print("")
                    } else {
                        var asset: VirtuosoAsset?
                        asset = self.completedAssets[indexPath.row]
                        let infoMovie = asset?.userInfo as NSDictionary?

                        self.movieIdStar = infoMovie?.object(forKey: "mediaID") as? String ?? ""
                        self.idStar = infoMovie?.object(forKey: "id") as? String ?? ""

                        asset?.delete(onComplete: {
                            UIApplication.shared.isIdleTimerDisabled = false
                            print("off Now")
                            // new state
                            DownloadPentheraManager.share.checkContaninMovies()
                            UserDefaults().set(false, forKey: "pauseByUser")
                            self.refreshData()
                        })
                    }
                }
            }
        }

        deleteAction.image = UIImage(named: "delete")
        if indexPath.section == 0 && !self.pendingAssets.isEmpty {
            return nil
        } else {
            return [deleteAction]
        }
    }
}
