//
//  String+presentationForUrl.swift
//  WeatherApp
//
//  Created by Dmitrii Morozov on 27/01/2018.
//  Copyright © 2018 Dmitrii Morozov. All rights reserved.
//

import Foundation

extension String {
    var presentationForUrl: String {
        return replacingOccurrences(of: " ", with: "+").addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed) ?? ""
    }
}
