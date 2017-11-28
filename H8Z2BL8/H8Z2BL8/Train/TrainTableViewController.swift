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

class TrainTableViewController: UITableViewController, TransportationProtocol {
    typealias Transport = Train
    
    let urlString = "https://api.wmata.com/StationPrediction.svc/json/GetPrediction/"
    let apiKey = (UIApplication.shared.delegate as! AppDelegate).wmataApiKey
    var tableData: [Train] = []
    var locationManager: CLLocationManager!
    private var closestStationCode = ""
    private var closestStationName = ""
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    private var _fetchedResultsController: NSFetchedResultsController<MetroStation>? = nil
    private var fetchedResultsController: NSFetchedResultsController<MetroStation> {
        if let _ = _fetchedResultsController {
            return _fetchedResultsController!
        }
        
        let fetchRequest: NSFetchRequest<MetroStation> = MetroStation.fetchRequest()
        
        let sortDescriptor = NSSortDescriptor(key: "lat", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
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
        guard !closestStationCode.isEmpty else { return }
        
        guard var urlComponents = URLComponents(string: urlString + closestStationCode) else { return }
        urlComponents.query = "api_key=\(apiKey)"
        
        guard let url = urlComponents.url else { return }
        
        let defaultSession = URLSession(configuration: .default)
        let dataTask = defaultSession.dataTask(with: url) { data, response, error in
            if let data = data, let response = response as? HTTPURLResponse, response.statusCode == 200 {
                    self.parseMetroArrivals(JSON(data: data))
            } else {
                if let error = error {
                    print("Error: " + error.localizedDescription + "\n")
                }
                
                DispatchQueue.main.async(execute: {
                    self.tableData.removeAll()
                    self.tableView.reloadData()
                    if let refreshControl = self.refreshControl, refreshControl.isRefreshing {
                        refreshControl.endRefreshing()
                    }
                    
                    // Show error message
                    let alertController: UIAlertController = UIAlertController(title: NSLocalizedString("Can't display arrival times", comment: "title for failed train fetch"), message: NSLocalizedString("Train data is not avaliable at this time.", comment: "message for failed train fetch"), preferredStyle: .alert)
                    alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "OK action"), style: .default, handler: nil))
                    self.present(alertController, animated: true, completion: nil)
                })
            }
        }
        dataTask.resume()
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
            self.navigationItem.title = "\(self.closestStationName) Station"
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
        let userLocation = locations[0] as CLLocation
        getClosestStation(to: userLocation)
        trainFetch()
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error)
    {
        print("Error \(error)")
    }
    
    func getClosestStation(to location: CLLocation) {
        var closestDistance: Double?
        
        if let results = fetchedResultsController.fetchedObjects {
            for station in results {
                let stationCoords = CLLocation(latitude: station.lat, longitude: station.long)
                
                let distanceInMeters = stationCoords.distance(from: location)
                if let _ = closestDistance {
                    if distanceInMeters < closestDistance! {
                        closestDistance = distanceInMeters
                        closestStationCode = station.code ?? ""
                        closestStationName = station.name ?? ""
                    }
                } else {
                    closestDistance = distanceInMeters
                    closestStationName = station.name ?? ""
                }
            }
        }
    }
}

extension TrainTableViewController: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        // TODO check user location to figure out what station to display and display it
    }
}

