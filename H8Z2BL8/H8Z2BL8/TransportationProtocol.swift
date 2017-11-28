//
//  TransportationProtocol.swift
//  H8Z2BL8
//
//  Created by Abby Thompson on 11/27/17.
//  Copyright © 2017 althomp. All rights reserved.
//

import Foundation
import CoreLocation
import CoreData
import UIKit

protocol TransportationProtocol {
    associatedtype Transport
    var urlString: String { get }
    var apiKey: String { get }
    var tableData: [Transport] { get set }
    var locationManager: CLLocationManager! { get set }
    var context: NSManagedObjectContext { get }
    func getUserLocation() 
}
