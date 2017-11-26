//
//  FetchBikeStationOperation.swift
//  H8Z2BL8
//
//  Created by Abby Thompson on 10/7/17.
//  Copyright © 2017 althomp. All rights reserved.
//

import Foundation
import UIKit
import SwiftyJSON
import MBProgressHUD
import CoreData

class FetchBikeStationsInfoOperation: Operation {
    
    private var view : UIView?
    private var viewController: UIViewController?
    
    private let entityName = "BikeStation"
    private let uniqueIdentifier = "stationId"
    
    private let urlString = "https://gbfs.capitalbikeshare.com/gbfs/en/station_information.json"
    
    private let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.newBackgroundContext()
    
    private var ids = Set<String>()
    
    init(viewController: UIViewController) {
        self.view = viewController.view
        self.viewController = viewController
    }
    
    override func main () {
        if let view = self.view, !CoreDataHelper.coreDataContains(entityName, context: context) {
            let hud = MBProgressHUD.showAdded(to: view, animated: true)
            let loadingString = NSLocalizedString("Loading", comment: "loading message while waiting for data to load")
            hud.label.text = loadingString
            UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, loadingString)
        }
        
        let url = URL(string: urlString)!
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config)
        
        let task = session.dataTask(with: url) { (data, response, error) in
            if let httpRes = response as? HTTPURLResponse {
                if let data = data , httpRes.statusCode == 200 {
                    let json = JSON(data: data)
                    self.parseBikeStations(json)
                    CoreDataHelper.removeOldObjects(for: self.entityName, with: self.uniqueIdentifier, newObjects: self.ids, context: self.context)
                    do {
                        try self.context.save()
                    } catch {}
                } else {
                    if !CoreDataHelper.coreDataContains(self.entityName, context: self.context), let vc = self.viewController {
                        // Show error message
                        let alertController: UIAlertController = UIAlertController(title: NSLocalizedString("Can't display bike station information", comment: "title for failed BikeStationInfo fetch"), message: NSLocalizedString("Bike station information is not avaliable at this time.", comment: "message for failed BikeStationInfo fetch"), preferredStyle: .alert)
                        alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "OK action"), style: .default, handler: nil))
                        vc.present(alertController, animated: true, completion: nil)
                    }
                }
            }
            DispatchQueue.main.async(execute: {
                if let view = self.view {
                    MBProgressHUD.hide(for: view, animated: true)
                }
            })
        }
        task.resume()
    }
    
    func parseBikeStations(_ json: JSON) {
        if let jsonBikeStationsArray = json["data"]["stations"].array {
            for jsonBikeStation in jsonBikeStationsArray {
                if let isInstalled = jsonBikeStation["is_installed"].int, isInstalled == 1 {
                    if let stationId = jsonBikeStation["station_id"].string, !stationId.isEmpty {
                        ids.insert(stationId)
                        
                        var bikeStation: BikeStation
                        if let result = CoreDataHelper.checkCoreData(for: stationId, entityName: entityName, with: uniqueIdentifier, context: context) {
                            bikeStation = result as! BikeStation
                        } else {
                            bikeStation = BikeStation(context: context)
                        }
                        
                        bikeStation.stationId = stationId
                        bikeStation.lat = jsonBikeStation["lat"].double ?? 0
                        bikeStation.lon = jsonBikeStation["lon"].double ?? 0
                        bikeStation.name = jsonBikeStation["name"].string ?? ""
                    }
                }
            }
        }
    }

}

class FetchBikeStationsStatusOperation: Operation {
    
    private var view : UIView?
    private var viewController: UIViewController?
    
    private let entityName = "BikeStation"
    private let uniqueIdentifier = "stationId"
    
    private let urlString = "https://gbfs.capitalbikeshare.com/gbfs/en/station_status.json"
    
    private let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.newBackgroundContext()
    
    override func main () {
        let url = URL(string: urlString)!
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config)
        
        let task = session.dataTask(with: url) { (data, response, error) in
            if let httpRes = response as? HTTPURLResponse {
                if let data = data , httpRes.statusCode == 200 {
                    let json = JSON(data: data)
                    self.parseBikeStations(json)
                    do {
                        try self.context.save()
                    } catch {}
                }
            }
        }
        task.resume()
    }
    
    func parseBikeStations(_ json: JSON) {
        if let jsonBikeStationsArray = json["data"]["stations"].array {
            for jsonBikeStation in jsonBikeStationsArray {
                if let stationId = jsonBikeStation["station_id"].string, !stationId.isEmpty {
                    
                    if let result = CoreDataHelper.checkCoreData(for: stationId, entityName: entityName, with: uniqueIdentifier, context: context) {
                        let bikeStation = result as! BikeStation
                        bikeStation.numBikesAvailable = jsonBikeStation["num_bikes_available"].int16 ?? -1
                        bikeStation.numDocksAvailable = jsonBikeStation["num_docks_available"].int16 ?? -1
                    }
                }
            }
        }
    }
    
}

