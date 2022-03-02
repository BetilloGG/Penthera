//
//  MovieInfoCellTableViewCell.swift
//  cinepolis
//
//  Created by José Ramón Arsuaga Sotres on 21/02/18.
//  Copyright © 2018 IA Interactive. All rights reserved.
//

import UIKit

class MovieInfoCellTableViewCell: UITableViewCell {

    @IBOutlet weak var movieNameLabel: UILabel!
    @IBOutlet weak var movieDescription: UILabel!
    @IBOutlet weak var imageMovie: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    func configTableViewCell(movie: Movie) {
        self.movieNameLabel.text = movie.movieTitle
        self.imageMovie.image = #imageLiteral(resourceName: movie.poster)
        self.movieDescription.text = movie.movieDescrition
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }
}
