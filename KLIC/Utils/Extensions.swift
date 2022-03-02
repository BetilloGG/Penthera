//
//  Extensions.swift
//  DemosPenthera
//
//  Created by José Alberto González Gordillo on 24/02/22.
//

import Foundation
import UIKit
import DownloadButton

// MARK: - UIViewController
extension UIViewController {

    func appDelegate() -> AppDelegate? {
        return UIApplication.shared.delegate as? AppDelegate
    }

    func isWifi() -> Bool {
        guard let reachability = self.appDelegate()?.reachability else { return false }
        return reachability.isReachableViaWiFi
    }

    func isiPad() -> Bool {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return false
        }

        return true
    }

    func connected() -> Bool {
        guard let reachability = self.appDelegate()?.reachability else { return false }
        return reachability.isReachable
    }

    func showAlert(message: String) {
       let alert = UIAlertController(title: "Alert",
                                     message: message,
                                     preferredStyle: .alert)

        alert.addAction(UIAlertAction(title: "OK",
                                      style: .default,
                                      handler: nil))
        self.present(alert, animated: true, completion: nil)
    }

    func actionSheetDownloads(status: StatusDownloads, downloadButton: PKDownloadButton,
                              callBackAction: ((_ optionActionSheet: OptionActionSheet) -> Void)?) {

      let optionMenu = UIAlertController(title: nil, message: "Download options",
                                         preferredStyle: .actionSheet)

      let cancelAction = UIAlertAction(title: "Cancel download",
                                       style: .default,
                                       handler: { ( _: UIAlertAction!) -> Void in
                                          if let callback = callBackAction {
                                              callback(.cancelDownload)
                                          }
      })

      let pauseAction = UIAlertAction(title: "Pause download",
                                      style: .default,
                                      handler: { ( _: UIAlertAction!) -> Void in
                                          if let callback = callBackAction {
                                              callback(.pauseDownloads)
                                          }
      })

      let resumenAction = UIAlertAction(title: "Resume download",
                                        style: .default,
                                        handler: { ( _: UIAlertAction!) -> Void in
                                          if let callback = callBackAction {
                                              callback(.resumenDownload)
                                          }
      })

      let verAction = UIAlertAction(title: "See my downloads",
                                    style: .default,
                                    handler: { ( _: UIAlertAction!) -> Void in
                                      if let callback = callBackAction {
                                          callback(.seeDownloads)
                                      }
      })

      let exitAction = UIAlertAction(title: "Cancel",
                                     style: .cancel,
                                     handler: { ( _: UIAlertAction!) -> Void in
                                      print("Cancelled")
      })

      switch status {
      case .downloading:
          optionMenu.addAction(pauseAction)
          optionMenu.addAction(cancelAction)
      case .resumen:
          optionMenu.addAction(resumenAction)
          optionMenu.addAction(cancelAction)
      case .errorDownload:
          optionMenu.addAction(cancelAction)
      }
      optionMenu.addAction(verAction)
      optionMenu.addAction(exitAction)

      if UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiom.pad {
          if let currentPopoverpresentioncontroller = optionMenu.popoverPresentationController {
              currentPopoverpresentioncontroller.sourceView = downloadButton
              currentPopoverpresentioncontroller.sourceRect = downloadButton.bounds
              currentPopoverpresentioncontroller.permittedArrowDirections = .up
              self.present(optionMenu, animated: true, completion: nil)
          }
      } else {
          self.present(optionMenu, animated: true, completion: nil)
      }
    }
}

extension UIImage {

    func imageWithSize(size: CGSize) -> UIImage {
        var scaledImageRect = CGRect.zero

        let aspectWidth: CGFloat = size.width / self.size.width
        let aspectHeight: CGFloat = size.height / self.size.height
        let aspectRatio: CGFloat = min(aspectWidth, aspectHeight)

        scaledImageRect.size.width = self.size.width * aspectRatio
        scaledImageRect.size.height = self.size.height * aspectRatio
        scaledImageRect.origin.x = (size.width - scaledImageRect.size.width) / 2.0
        scaledImageRect.origin.y = (size.height - scaledImageRect.size.height) / 2.0

        UIGraphicsBeginImageContextWithOptions(size, false, 0)

        self.draw(in: scaledImageRect)

        guard let scaledImage = UIGraphicsGetImageFromCurrentImageContext() else { return UIImage() }
        UIGraphicsEndImageContext()

        return scaledImage
    }

}
