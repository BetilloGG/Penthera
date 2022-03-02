//
//  Movie.swift
//  DemosPenthera
//
//  Created by José Alberto González Gordillo on 23/02/22.
//

import Foundation
import UIKit

struct Movie {

    var movieTitle: String?
    var movieDescrition: String?
    var mediaID: Int?
    var poster: String!
    var assetId: String?
    var url: String!


    init() { }

    init(movie: NSDictionary) {

        if let title = movie.object(forKey: "title") as? String {
            self.movieTitle = title
        }

        if let assetId = movie.object(forKey: "assetId") as? String {
            self.assetId = assetId
        }

        if let description = movie.object(forKey: "description") as? String {
            self.movieDescrition = description
        }

        if let url = movie.object(forKey: "url") as? String {
            self.url = url
        }

        if let poster = movie.object(forKey: "icon") as? String {
            self.poster = poster
        }

        if let mediaID = movie.object(forKey: "id") as? Int {
            self.mediaID = mediaID
        }
    }
}
