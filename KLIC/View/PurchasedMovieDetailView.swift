//
//  PurchasedMovieDetailView.swift
//  cinepolis
//
//  Created by José Alberto González on 09/02/18.
//  Copyright © 2018 IA Interactive. All rights reserved.
//

import UIKit
import DownloadButton

@objc protocol MovieDetailDelegate {

    @objc func downloadTapped()
    @objc func seeNowDisconnectedTapped()
    @objc func seeNowConnected()
    @objc func showMessage(message: String)

    func downloadButtonTapped(_ downloadButton: PKDownloadButton!,
                              currentState state: PKDownloadButtonState)
}

class PurchasedMovieDetailView: UIView {

    @IBOutlet private weak var downloadBtn: PKDownloadButton!
    @IBOutlet private weak var movieTitleLabel: UILabel!
    @IBOutlet private weak var comodinView1: UIView?
    @IBOutlet private weak var comodinView2: UIView?

    // MARK: Outlets Stackviews and Views
    @IBOutlet private weak var seeNowConnectedStackView: UIStackView!
    @IBOutlet private weak var poster: UIImageView!

    // MARK: Outlets NSLayoutConstraint
    @IBOutlet private weak var constraintsHeight: NSLayoutConstraint!
    @IBOutlet private weak var constraintsBotton: NSLayoutConstraint!
    @IBOutlet private weak var downloadWieghtConstraint: NSLayoutConstraint!

    // MARK: Delegate
    weak var delegate: MovieDetailDelegate?

    var movie: Movie?

    // starDownload
    @IBOutlet private weak var downloadStackView: UIStackView!
    // progressDownloading
    @IBOutlet private weak var progressDownloadStackView: UIStackView!
    // finalice download
    @IBOutlet private weak var seeNowDisconnectedStackView: UIStackView!
    // state download label
    @IBOutlet private weak var downloadStateTitleLabel: UILabel!
    // state download Contend
    @IBOutlet private weak var downloadStateTitleConted: UIStackView!

     override var intrinsicContentSize: CGSize {

           switch UIScreen.main.nativeBounds.height {
           case 1136:
               constraintsHeight.constant = -37
               constraintsBotton.constant = -37
           case 1334, 2436:
               constraintsHeight.constant = -23
               constraintsBotton.constant = -23
           case 2688:
               constraintsHeight.constant = -11
               constraintsBotton.constant = -11
           default:
               print("")
           }

           if UIScreen.main.nativeBounds.height <= 1136.0 {
               return CGSize(width: UIScreen.main.bounds.width, height: 250.0)
           }
        return CGSize(width: UIScreen.main.bounds.width, height: 268.0)
       }

    func configView(movieModel: Movie) {

        self.movie = movieModel

        // config DownloadButton
        self.downloadBtn.startDownloadButton.cleanDefaultAppearance()
        self.downloadBtn.startDownloadButton.setBackgroundImage(UIImage.buttonBackground(with:
            UIColor.yellowColors), for: UIControl.State.normal)
        self.downloadBtn.startDownloadButton.setBackgroundImage(UIImage.highlitedButtonBackground(with:
            UIColor.yellowColors), for: UIControl.State.highlighted)
        self.downloadBtn.startDownloadButton.setTitle("DESCARGAR", for: .normal)
        self.downloadWieghtConstraint.constant = 100
        self.downloadBtn.startDownloadButton.titleLabel?.font = UIFont.systemFont(ofSize: 12)
        self.downloadBtn.startDownloadButton.setTitleColor(UIColor.yellowColors, for: .normal)
        self.downloadBtn.startDownloadButton.setTitleColor(UIColor.yellowColors, for: .highlighted)
        self.downloadBtn.delegate = self

        self.movieTitleLabel?.text = movieModel.movieTitle
        self.poster.image = #imageLiteral(resourceName: movieModel.poster)
    }


    @IBAction func downloadTapped(_ sender: Any) {
         self.delegate?.downloadButtonTapped(self.downloadBtn, currentState: .startDownload)
    }

    @IBAction func seeNowDisconnectedTapped(_ sender: Any) {
        self.delegate?.seeNowDisconnectedTapped()
    }

    @IBAction func seeNowConnected(_ sender: Any) {
        self.delegate?.seeNowConnected()
    }
}

extension PurchasedMovieDetailView: PKDownloadButtonDelegate {
    func downloadButtonTapped(_ downloadButton: PKDownloadButton!,
                              currentState state: PKDownloadButtonState) {
        self.delegate?.downloadButtonTapped(downloadButton, currentState: state)
    }
}

// MARK: - Config View
extension PurchasedMovieDetailView {


    func downloadStackView(isHidden: Bool) {
        DispatchQueue.main.async {
            self.downloadStackView.isHidden = isHidden
        }
    }

    func progressDownloadStackView(isHidden: Bool) {
        DispatchQueue.main.async {
            self.progressDownloadStackView.isHidden = isHidden
        }
    }

    func seeNowDisconnectedStackView(isHidden: Bool) {
        DispatchQueue.main.async {
            self.seeNowDisconnectedStackView.isHidden = isHidden
        }
    }

    func configDownloadButton(isHidden: Bool) {
        DispatchQueue.main.async {
            self.downloadBtn.isHidden = isHidden
        }
    }

    func downloadButtonState(state: PKDownloadButtonState) {
        self.downloadBtn.state = state
    }

}

// MARK: - Downloads
extension PurchasedMovieDetailView {

        func buttonStateDownloading() -> Bool {
            if self.downloadBtn.state == PKDownloadButtonState.downloading ||
            self.downloadBtn.state == PKDownloadButtonState.pending {
              return true
            }
            return false
        }

        func cancelDownload() {
            if #available(iOS 10.0, *) {
                // download
                comodinView1?.isHidden = true
                comodinView2?.isHidden = true
                self.downloadStackView.isHidden = false
            } else {
                // not download
                comodinView1?.isHidden = false
                comodinView2?.isHidden = false
                self.downloadStackView.isHidden = true
            }

            self.progressDownloadStackView.isHidden = true
            self.seeNowDisconnectedStackView.isHidden = true
            self.downloadWieghtConstraint.constant = 31
            self.downloadBtn.state = PKDownloadButtonState.pending
            self.downloadBtn.startDownloadButton.setTitle("", for: .normal)
        }

        func pauseDownload() {

            self.downloadStackView.isHidden = true
            self.progressDownloadStackView.isHidden = false
            self.seeNowDisconnectedStackView.isHidden = true
            self.downloadStateTitleConted?.isHidden = true
            self.downloadWieghtConstraint.constant = 80

            self.downloadBtn.state = PKDownloadButtonState.startDownload
            self.downloadBtn.startDownloadButton.setTitle("REANUDAR", for: .normal)
        }

        func setPendingState() {
            DispatchQueue.main.async {
                self.downloadBtn.state = PKDownloadButtonState.pending
                self.downloadWieghtConstraint.constant = 31
                self.downloadStackView.isHidden = true
                self.downloadStateTitleConted?.isHidden = false
                self.progressDownloadStackView.isHidden = false
            }
        }

        func pendingDownload() {

             DispatchQueue.main.async {
                self.downloadStackView.isHidden = true
                self.progressDownloadStackView.isHidden = false
                self.seeNowDisconnectedStackView.isHidden = true
                self.downloadStateTitleConted?.isHidden = false

                self.downloadWieghtConstraint.constant = 31
                self.downloadStateTitleConted.isHidden = false
                self.downloadStateTitleLabel.text = "DESCARGANDO"
            }
        }

        func setProgresDowloading() {
            let progress = UserDefaults().double(forKey: "progrees")
            let progresFloat = Float(progress)

            if progress != 0.0 && progress < 1.0 {

            DispatchQueue.main.async {

                let progress = ((progress * 100) / 5)
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

                self.downloadBtn.tintAdjustmentMode = .normal
                self.downloadBtn.state = PKDownloadButtonState.downloading

                self.downloadBtn.stopDownloadButton.stopButton.setImage(nil, for: .normal)
                self.downloadBtn.stopDownloadButton.stopButton.setNeedsDisplay()
                self.downloadBtn.stopDownloadButton.stopButton.setAttributedTitle(attributedString1, for: .normal)
                self.downloadBtn.state = PKDownloadButtonState.downloading
                self.downloadWieghtConstraint.constant = 31

                self.downloadBtn.setNeedsLayout()
                self.downloadBtn.setNeedsDisplay()
                self.downloadBtn.layoutIfNeeded()
                self.downloadBtn.stopDownloadButton.progress = CGFloat(progresFloat)
            }
        }
    }

        func initDownloadButton() {

            downloadWieghtConstraint.constant = 31
            downloadBtn.tintAdjustmentMode = .normal
            downloadBtn.state = PKDownloadButtonState.downloading

            let attrs1 = [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 6.5),
                          NSAttributedString.Key.foregroundColor: UIColor.yellowColors]
            let attrs2 = [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 5.5),
                          NSAttributedString.Key.foregroundColor: UIColor.yellowColors]
            let attributedString1 = NSMutableAttributedString(string: "0", attributes: attrs1)
            let attributedString2 = NSMutableAttributedString(string: "%", attributes: attrs2)
                attributedString1.append(attributedString2)

            downloadBtn.stopDownloadButton.stopButton.setImage(nil, for: .normal)
            downloadBtn.stopDownloadButton.stopButton.setNeedsDisplay()
            downloadBtn.stopDownloadButton.stopButton.setAttributedTitle(attributedString1, for: .normal)
            downloadBtn.setNeedsLayout()
            downloadBtn.setNeedsDisplay()
            downloadBtn.layoutIfNeeded()
        }

        func isHiddenDownloadButton(isHidden: Bool) {
          comodinView1?.isHidden = !isHidden
          comodinView2?.isHidden = !isHidden
          downloadStackView.isHidden = isHidden
        }
}

// MARK: - Downloads
extension PurchasedMovieDetailView {

    func downloadingButton(asset: VirtuosoAsset, progress: NSAttributedString) {
        self.downloadBtn.tintAdjustmentMode = .normal
        self.downloadBtn.state = PKDownloadButtonState.downloading
        self.downloadBtn.stopDownloadButton.stopButton.setImage(nil, for: .normal)
        self.downloadBtn.stopDownloadButton.stopButton.setNeedsDisplay()
        self.downloadBtn.stopDownloadButton.stopButton.setAttributedTitle(progress, for: .normal)

        self.downloadBtn.state = PKDownloadButtonState.downloading
        self.downloadWieghtConstraint.constant = 31
        self.downloadBtn.stopDownloadButton.progress = CGFloat(asset.fractionComplete)
        self.downloadBtn.setNeedsLayout()
        self.downloadBtn.setNeedsDisplay()
        self.downloadBtn.layoutIfNeeded()
    }

    func downloadCompleteHLS() {
        if  self.downloadBtn.state != PKDownloadButtonState.downloaded {
            self.downloadStackView.isHidden = true
            self.progressDownloadStackView.isHidden = true
            self.seeNowDisconnectedStackView.isHidden = false
            self.downloadBtn.state = PKDownloadButtonState.downloaded
        }
    }
}
