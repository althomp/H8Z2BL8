//
//  Train.swift
//  H8Z2BL8
//
//  Created by Abby Thompson on 9/30/17.
//  Copyright © 2017 althomp. All rights reserved.
//

class Train {
    var destinationName: String
    var line: String
    var minToArrival: String
    
    init(destinationName: String, line: String, minToArrival: String) {
        self.destinationName = destinationName
        self.line = line
        self.minToArrival = minToArrival
    }
}
