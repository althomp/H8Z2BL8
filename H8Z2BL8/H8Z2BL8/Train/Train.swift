//
//  Train.swift
//  H8Z2BL8
//
//  Created by Abby Thompson on 9/30/17.
//  Copyright © 2017 althomp. All rights reserved.
//

import UIKit

class Train {
    var destinationName: String
    var line: String
    var minToArrival: String
    var color = UIColor.clear
    
    init(destinationName: String, line: String, minToArrival: String) {
        self.destinationName = destinationName
        self.line = line
        self.minToArrival = minToArrival
        self.color = setColor(for: line)
    }
    
    func setColor(for line: String) -> UIColor {
        switch line {
        case "RD":
            return UIColor.red
        case "OR":
            return UIColor.orange
        case "YL":
            return UIColor.yellow
        case "GR":
            return UIColor.green
        case "BL":
            return UIColor.blue
        case "SV":
            return UIColor.gray
        default:
            return UIColor.clear
        }
    }
    
    func getArrivalStatus() -> String {
        var arrivalStatus = ""
        switch self.minToArrival {
        case "ARR":
            arrivalStatus = "Arriving"
        case "BRD":
            arrivalStatus = "Boarding"
        case "1":
            arrivalStatus = "1 minute to arrival"
        default:
            arrivalStatus = "\(self.minToArrival) minutes to arrival"
        }
        return arrivalStatus
    }
}
