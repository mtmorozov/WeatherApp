//
//  Date+ToString.swift
//  WeatherApp
//
//  Created by Dmitrii Morozov on 27/01/2018.
//  Copyright © 2018 Dmitrii Morozov. All rights reserved.
//

import Foundation

extension Date {
    func toString(dateFormat: String) -> String {
        let dateFormatter: DateFormatter = DateFormatter()
        dateFormatter.dateFormat = dateFormat
        
        return dateFormatter.string(from: self)
    }
}
