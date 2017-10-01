//
//  TrainTableViewController.swift
//  H8Z2BL8
//
//  Created by Abby Thompson on 9/30/17.
//  Copyright © 2017 althomp. All rights reserved.
//

import UIKit
import SwiftyJSON
import CoreLocation
import CoreData

class TrainTableViewController: UITableViewController {
    
    var tableData: [Train] = []
    var locationManager: CLLocationManager!
    
    var context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    var _fetchedResultsController: NSFetchedResultsController<MetroStation>? = nil
    var fetchedResultsController: NSFetchedResultsController<MetroStation> {
        if let _ = _fetchedResultsController {
            return _fetchedResultsController!
        }
        
        let fetchRequest: NSFetchRequest<MetroStation> = MetroStation.fetchRequest()
        
        let aFetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
        aFetchedResultsController.delegate = self
        _fetchedResultsController = aFetchedResultsController
        
        do {
            try _fetchedResultsController!.performFetch()
        } catch {
            print("Error fetching metro stations in TrainTableViewController: \(error)")
        }
        
        return _fetchedResultsController!
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let operation = FetchMetroStationsOperation(viewController: self)
        OperationQueue.main.addOperation(operation)
        
        self.navigationItem.title = "Train"
        
        trainFetch()
        self.refreshControl = UIRefreshControl()
        self.refreshControl?.attributedTitle = NSAttributedString(string: "Refreshing")
        self.refreshControl?.addTarget(self, action: #selector(TrainTableViewController.trainFetch), for: UIControlEvents.valueChanged)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        getUserLocation()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        locationManager.stopUpdatingLocation()
    }
    
    func getUserLocation() {
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.startUpdatingLocation()
        }
    }
    
    @objc func trainFetch() {
        if var urlComponents = URLComponents(string: "https://api.wmata.com/StationPrediction.svc/json/GetPrediction/All") {
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
                if displayable(jsonTrain) {
                    let destinationName = jsonTrain["DestinationName"].string!
                    let min = jsonTrain["Min"].string!
                    let line = jsonTrain["Line"].string!
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
    
    func displayable(_ jsonTrain: JSON) -> Bool {
        if let line = jsonTrain["Line"].string, line != "--", line != "No" {
            if let min = jsonTrain["Min"].string, !min.isEmpty, min != "--" {
                return true
            }
        }
        return false
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

extension TrainTableViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let userLocation:CLLocation = locations[0] as CLLocation
        
        print("user latitude = \(userLocation.coordinate.latitude)")
        print("user longitude = \(userLocation.coordinate.longitude)")
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error)
    {
        print("Error \(error)")
    }
}

extension TrainTableViewController: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        // TODO check user location to figure out what station to display and display it
        print("Metro Station data has been updated")
    }
}

