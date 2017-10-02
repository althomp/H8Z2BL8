//
//  FetchMetroStationsOperation.swift
//  H8Z2BL8
//
//  Created by Abby Thompson on 10/1/17.
//  Copyright © 2017 althomp. All rights reserved.
//

import Foundation
import UIKit
import SwiftyJSON
import MBProgressHUD
import CoreData

class FetchMetroStationsOperation: Operation {
    
    private var view : UIView?
    private var viewController: UIViewController?
    
    let urlString = "https://api.wmata.com/Rail.svc/json/jStations?api_key=e1eee2b5677f408da40af8480a5fd5a8"
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.newBackgroundContext()
    
    private var codes = Set<String>()
    
    init(viewController: UIViewController) {
        self.view = viewController.view
        self.viewController = viewController
    }
    
    override func main () {
        if let view = self.view, !coreDataContainsMetroStations() {
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
                    self.parseMetroStations(json)
                    self.removeOldObjects()
                    do {
                        try self.context.save()
                    } catch {}
                } else {
                    if !self.coreDataContainsMetroStations(), let vc = self.viewController {
                        // Show error message
                        let alertController: UIAlertController = UIAlertController(title: NSLocalizedString("Can't display metro stations", comment: "title for failed metroStation fetch"), message: NSLocalizedString("Metro station data is not avaliable at this time.", comment: "message for failed metroStation fetch"), preferredStyle: .alert)
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
    
    func parseMetroStations(_ json: JSON) {
        if let jsonMetroStationsArray = json["Stations"].array {
            for jsonMetroStation in jsonMetroStationsArray {
                if let code = jsonMetroStation["Code"].string, !code.isEmpty {
                    codes.insert(code)
                    
                    var metroStation: MetroStation
                    if let result = checkCoreDataFor(code, entityName: "MetroStation") {
                        metroStation = result as! MetroStation
                    } else {
                        metroStation = MetroStation(context: context)
                    }
                    
                    metroStation.code = code
                    metroStation.lat = jsonMetroStation["Lat"].double ?? 0
                    metroStation.long = jsonMetroStation["Lon"].double ?? 0
                    metroStation.name = jsonMetroStation["Name"].string ?? ""
                }
            }
        }
    }
    
    func checkCoreDataFor(_ code: String, entityName: String) -> Any? {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        fetchRequest.predicate = NSPredicate(format: "code == %@", code)
        fetchRequest.fetchBatchSize = 1
        do {
            let results = try context.fetch(fetchRequest)
            if results.count > 0 {
                return results[0]
            }
        } catch { print("FetchMetroStationsOperation checkCoreDataFor error \(error)") }
        return nil
    }
    
    func coreDataContainsMetroStations() -> Bool {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "MetroStation")
        fetchRequest.fetchBatchSize = 1
        do {
            let results = try context.fetch(fetchRequest)
            if results.count > 0 {
                return true
            }
        } catch { print("FetchMetroStationsOperation coreDataContainsMetroStations error \(error)") }
        return false
    }
    
    func removeOldObjects() {
        if codes.count > 0 {
            let ooFetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "MetroStation")
            ooFetchRequest.predicate = NSPredicate(format: "NOT code IN %@", codes)
            do {
                let outdatedObjects = try context.fetch(ooFetchRequest)
                for obj in outdatedObjects {
                    context.delete(obj as! MetroStation)
                }
            } catch { print("FetchMetroStationsOperation removeOldObjects error \(error)")  }
        }
        
    }
    
}

