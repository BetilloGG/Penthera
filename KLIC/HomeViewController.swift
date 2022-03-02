//
//  HomeViewController.swift
//  DemosPenthera
//
//  Created by José Alberto González Gordillo on 23/02/22.
//

import UIKit

class HomeViewController: UITableViewController {

    let reachability = Reachability()
    var Movies: [Movie] = [] {
        didSet {
            tableView.reloadData()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Movies"


        // Check if there are movies in process to pause them
        // If I have a download, I check if the engine is initialized, if it is not I initialize it and later I pause the download.
        DispatchQueue.main.async {
            let engine = VirtuosoDownloadEngine.instance()
            if let userInfo = UserDefaults.standard.object(forKey: Utils.share.USERINFO) as? NSDictionary,
               let userId = userInfo.object(forKey: "userId") {
                print("\(userId)")
                if DownloadPentheraManager.share.checkMovieInProgress() {
                    if !engine.started {
                        // Start the Engine and pause Dowload
                        DownloadPentheraManager.share.virtuosoStartup(true)
                    } else {
                        engine.enabled = true
                    }
                } else {
                    engine.enabled = true
                }
            }
        }


        validateDownloading()
        self.tableView.register(UINib(nibName: "MovieInfoCellTableViewCell", bundle: nil),
                                forCellReuseIdentifier: "MovieInfoCellTableViewCell")
    }


    // Open Catalog or Mis Descargas
   func validateDownloading() {
       let isWifi: Bool = reachability?.isReachable ?? false
       if isWifi {
           self.setMovieInfo()
       } else {
           if UserDefaults.standard.object(forKey: Utils.share.USERINFO ) as? NSDictionary != nil {
               self.performSegue(withIdentifier: "showDownloadsController", sender: nil)
           } else {
             // alert view
           }
       }
   }

    //add any movies
    func setMovieInfo() {
        // movie 1
        Movies.append(Movie(movie: [ "id": 1, "icon": "nemo", "title": "casual-episodio-4",
                                    "description": "casual-episodio-4-temporada-2",
                                    "assetId": "casual-episodio-4-temporada-2",
                                     "url": "https://hlscf.cinepolisklic.com/usp-s3-storage/clear/casual-episodio-4-temporada-2/casual-episodio-4-temporada-2_fp.ism/.m3u8?filter=(type==%22audio%22)%7C%7C(type==%22textstream%22)%7C%7C(type==%22video%22%26%26MaxHeight%3C=480)"]))

        // movie 2
        Movies.append(Movie(movie: [ "id": 2, "icon": "lego", "title": "coleccion-venom-venom-carnage-liberado",
                                    "description": "Colección: Venom + Venom: Carnage Liberado",
                                    "assetId": "coleccion-venom-venom-carnage-liberado",
                                     "url": "https://hlscf.cinepolisklic.com/usp-s3-storage/clear/coleccion-venom-venom-carnage-liberado/coleccion-venom-venom-carnage-liberado_fp.ism/.m3u8?filter=(type==%22audio%22)%7C%7C(type==%22textstream%22)%7C%7C(type==%22video%22%26%26MaxHeight%3C=480)"]))

        // movie 3
        Movies.append(Movie(movie: ["id": 3, "icon": "frozen", "title": "Frozen: La aventura de Olaf",
                                    "description": "Frozen: La aventura de Olaf",
                                    "assetId": "frozen-la-aventura-de-olaf",
                                    "url": "https://hlscf.cinepolisklic.com/usp-s3-storage/clear/frozen-la-aventura-de-olaf/frozen-la-aventura-de-olaf_fp.ism/.m3u8?filter=(type==%22audio%22)%7C%7C(type==%22textstream%22)%7C%7C(type==%22video%22%26%26MaxHeight%3C=480)"]))

        // movie 4
        Movies.append(Movie(movie: ["id": 4, "icon": "robot", "title": "mr-robot-t1-episodio-2",
                                    "description": "mr-robot-t1-episodio-2",
                                    "assetId": "mr-robot-t1-episodio-2",
                                    "url": "https://hlscf.cinepolisklic.com/usp-s3-storage/clear/mr-robot-t1-episodio-2/mr-robot-t1-episodio-2_fp.ism/.m3u8?filter=(type==%22audio%22)%7C%7C(type==%22textstream%22)%7C%7C(type==%22video%22%26%26MaxHeight%3C=480)"]))
    }


    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Movies.count
    }


    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "MovieInfoCellTableViewCell")
            as? MovieInfoCellTableViewCell else { return UITableViewCell() }

        cell.configTableViewCell(movie: Movies[indexPath.row])
        return cell
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 108
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let movie = Movies[indexPath.row]
        self.performSegue(withIdentifier: "showMovie", sender: movie)
    }


    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let destination = segue.destination as? MovieDetailViewController else { return }
        if let movie = sender as? Movie {
            destination.movie = movie
        }
    }
}
