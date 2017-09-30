//
//  BikeStation.swift
//  H8Z2BL8
//
//  Created by Abby Thompson on 9/30/17.
//  Copyright © 2017 althomp. All rights reserved.
//

class BikeStation {
    var stationId: Int
    var stationName: String
    var bikesAvaliable: String
    var docksAvaliable: String
    
    init(stationId: Int, stationName: String, bikesAvaliable: String, docksAvaliable: String) {
        self.stationId = stationId
        self.stationName = stationName
        self.bikesAvaliable = bikesAvaliable
        self.docksAvaliable = docksAvaliable
    }
}
