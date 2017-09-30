//
//  TrainTableViewController.swift
//  H8Z2BL8
//
//  Created by Abby Thompson on 9/30/17.
//  Copyright © 2017 althomp. All rights reserved.
//

import UIKit
import SwiftyJSON

class TrainTableViewController: UITableViewController {
    
    var tableData: [Train] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        trainFetch()
        self.refreshControl = UIRefreshControl()
        self.refreshControl?.attributedTitle = NSAttributedString(string: "Refreshing")
        self.refreshControl?.addTarget(self, action: #selector(TrainTableViewController.trainFetch), for: UIControlEvents.valueChanged)
    }
    
    @objc func trainFetch() {
        if var urlComponents = URLComponents(string: "https://api.wmata.com/StationPrediction.svc/json/GetPrediction/K01") {
            urlComponents.query = "api_key=e1eee2b5677f408da40af8480a5fd5a8"
            
            if let url = urlComponents.url {
                let defaultSession = URLSession(configuration: .default)
                let dataTask = defaultSession.dataTask(with: url) { data, response, error in
                    if let error = error {
                        print("Error: " + error.localizedDescription + "\n")
                    } else if let data = data,
                        let response = response as? HTTPURLResponse,
                        response.statusCode == 200 {
                        self.parseMetroArrivals(JSON(data: data))
                    }
                }
                dataTask.resume()
            }
        }
    }
    
    func parseMetroArrivals(_ json: JSON) {
        tableData.removeAll()
        if let jsonTrainsArray = json["Trains"].array {
            for jsonTrain in jsonTrainsArray {
                if let line = jsonTrain["Line"].string, line != "--" {
                    let destinationName = jsonTrain["DestinationName"].string!
                    let min = jsonTrain["Min"].string!
                    tableData.append(Train(destinationName: destinationName, line: line, minToArrival: min))
                }
            }
        }
        DispatchQueue.main.async(execute: {
            self.tableView.reloadData()
            if let refreshControl = self.refreshControl, refreshControl.isRefreshing {
                refreshControl.endRefreshing()
            }
        })
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableData.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let arrivalLabel = cell.viewWithTag(1) as! UILabel
        let lineLabel = cell.viewWithTag(2) as! UILabel
        let destinationLabel = cell.viewWithTag(3) as! UILabel
        let colorBar = cell.viewWithTag(4)
        
        let train = tableData[indexPath.item]
        
        arrivalLabel.text = train.getArrivalStatus()
        lineLabel.text = "\(train.line) line"
        destinationLabel.text = "Headed towards \(train.destinationName)"
        
        if let colorBar = colorBar {
            colorBar.backgroundColor = train.color
        }
        
        return cell
    }
    
}

