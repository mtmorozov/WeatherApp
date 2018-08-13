//
//  WeatherService.swift
//  WeatherApp
//
//  Created by Dmitrii Morozov on 26/01/2018.
//  Copyright © 2018 Dmitrii Morozov. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

class WeatherService {
    /// Singleton
    static let sharedInstance = WeatherService()
}

// MARK: - URL
extension WeatherService {
    static let baseUrl = "http://api.openweathermap.org/data/2.5/"
    
    static let apiKey = "c4ba4d3920f534bf01e045fd302a9b1e"

    static func currentWeatherUrl(city: String) -> String {
        return "\(baseUrl)weather?q=\(city.presentationForUrl)&units=metric&lang=en&appid=\(apiKey)"
    }
    
    static func currentWeathersUrl(cityIds: [String]) -> String {
        return "\(baseUrl)group?id=\(cityIds.joined(separator: ","))&units=metric&lang=en&appid=\(apiKey)"
    }
    
    static func forecastUrl(cityId: String) -> String {
        return "\(baseUrl)forecast/daily?id=\(cityId)&units=metric&lang=en&cnt=8&appid=\(apiKey)"
    }
}

// MARK: - Getting data
extension WeatherService {
    func getCurrentWeather(city: String, onComplete: @escaping (CityCurrentWeather?) -> Void) {
        Alamofire.request(WeatherService.currentWeatherUrl(city: city)).responseJSON {
            response in
            
            switch response.result {
            case .failure(let error):
                print(error)
                onComplete(nil)
                
            case .success(let data):
                let json = JSON(data)
                let result = self.parseCurrentWeather(json)
                onComplete(result)
            }
        }
    }
    
    func getCurrentWeathers(cityIds: [String], onComplete: @escaping ([CityCurrentWeather]) -> Void) {
        Alamofire.request(WeatherService.currentWeathersUrl(cityIds: cityIds)).responseJSON {
                response in
                
                switch response.result {
                case .failure(let error):
                    print(error)
                    onComplete([])
                    
                case .success(let data):
                    let json = JSON(data)
                    let result = self.parseCurrentWeathers(json)
                    onComplete(result)
                }
        }
    }
    
    func getForecast(cityId: String, onComplete: @escaping ([Forecast]) -> Void) {
        Alamofire.request(WeatherService.forecastUrl(cityId: cityId)).responseJSON {
                response in
                
                switch response.result {
                case .failure(let error):
                    print(error)
                    onComplete([])
                    
                case .success(let data):
                    let json = JSON(data)
                    let result = self.parseForecast(json)
                    onComplete(result)
                }
        }
    }
}
