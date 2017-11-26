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
    
    private let entityName = "MetroStation"
    private let uniqueIdentifier = "code"
    
    let apiKey = (UIApplication.shared.delegate as! AppDelegate).wmataApiKey
    private let urlString = "https://api.wmata.com/Rail.svc/json/jStations"
    
    private let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.newBackgroundContext()
    
    private var codes = Set<String>()
    
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
        
        guard var urlComponents = URLComponents(string: urlString) else { return }
        urlComponents.query = "api_key=\(apiKey)"

        guard let url = urlComponents.url else { return }
        
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config)
        
        let task = session.dataTask(with: url) { (data, response, error) in
            if let httpRes = response as? HTTPURLResponse {
                if let data = data , httpRes.statusCode == 200 {
                    let json = JSON(data: data)
                    self.parseMetroStations(json)
                    CoreDataHelper.removeOldObjects(for: self.entityName, with: self.uniqueIdentifier, newObjects: self.codes, context: self.context)
                    do {
                        try self.context.save()
                    } catch {}
                } else {
                    if !CoreDataHelper.coreDataContains(self.entityName, context: self.context), let vc = self.viewController {
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
                    if let result = CoreDataHelper.checkCoreData(for: code, entityName: entityName, with: uniqueIdentifier, context: context) {
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

}

