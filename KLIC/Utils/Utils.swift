//
//  Utils.swift
//  DemosPenthera
//
//  Created by José Alberto González Gordillo on 24/02/22.
//

import Foundation

public enum MovieFormat: String {
    case SD = "SD"
    case HD = "HD"

    var type: String {
        switch self {
        case .HD:
            return "HD"
        case .SD:
            return "SD"
        }
    }
}

public enum OptionActionSheet: String {
    case resumenDownload
    case cancelDownload
    case seeDownloads
    case pauseDownloads
}

public enum StatusDownloads: Int {
    case downloading = 1
    case resumen = 2
    case errorDownload = 3
}

class Utils: NSObject {

    static let share = Utils()

    let USERINFO        = "USERINFO"
    let DOWNLOAD_MOVIES = "downloadMovies"
    let Download_Notifier_Network   = "DOWNLOAD_NOTIFIER_NETWORK"

    var digitNumber: String {
        var result = ""
        repeat {
            result = String(format:"%05d", arc4random_uniform(10000) )
        } while Set<Character>(result).count < 5
        return result
    }

    func getFreeSize() -> Float? {
        let free_str = DiskStatus.freeDiskSpace

        //170 --- is space in disk no avalible on iphone
        let formatMemory = free_str.components(separatedBy: " ")[1]
        let sizeMovie = "\(free_str.components(separatedBy: " ")[0])"
        let newSizeMovie = sizeMovie.replacingOccurrences(of: ",", with: "")

        let size = Float(newSizeMovie)
        if formatMemory == "GB" {
            return (size! * 1000) - 170
        } else {
            return size! - 170
        }
    }

    func isWifiDownload() -> Bool {
        if let userInfo = UserDefaults.standard.object(forKey: Utils.share.USERINFO) as? NSDictionary {
            if let isWifi: Bool = userInfo.object(forKey: "isWifiDownload") as? Bool {
                return isWifi
            } else {
                return true
            }
        } else {
            return true
        }
    }
}
