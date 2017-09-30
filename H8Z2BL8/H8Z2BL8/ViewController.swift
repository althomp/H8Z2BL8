//
//  ViewController.swift
//  H8Z2BL8
//
//  Created by Abby Thompson on 9/29/17.
//  Copyright © 2017 althomp. All rights reserved.
//

import Foundation
import UIKit
import SwiftyJSON

class ViewController: UIViewController {
    @IBOutlet var table: UITableView!
    
    var tableData: [Train] = []
    var refreshControl: UIRefreshControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        table.delegate = self
        table.dataSource = self
        
        testFetch()
        refreshControl = UIRefreshControl()
        refreshControl.attributedTitle = NSAttributedString(string: "Refreshing")
        refreshControl.addTarget(self, action: #selector(ViewController.testFetch), for: UIControlEvents.valueChanged)
        table.addSubview(refreshControl)
    }
    
    @objc func testFetch() {
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
                let destinationName = jsonTrain["DestinationName"].string!
                let line = jsonTrain["Line"].string!
                let min = jsonTrain["Min"].string!
                tableData.append(Train(destinationName: destinationName, line: line, minToArrival: min))
            }
        }
        DispatchQueue.main.async(execute: {
            self.table.reloadData()
            if self.refreshControl.isRefreshing {
                self.refreshControl.endRefreshing()
            }
        })
    }

}

extension ViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let label1 = cell.viewWithTag(1) as! UILabel
        let label2 = cell.viewWithTag(2) as! UILabel
        let label3 = cell.viewWithTag(3) as! UILabel
        
        let train = tableData[indexPath.item]
        label1.text = train.minToArrival
        label2.text = train.line
        label3.text = train.destinationName
    
        return cell
    }
    

}
