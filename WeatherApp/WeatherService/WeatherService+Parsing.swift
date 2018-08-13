//
//  WeatherService+Parsing.swift
//  WeatherApp
//
//  Created by Dmitrii Morozov on 28/01/2018.
//  Copyright © 2018 Dmitrii Morozov. All rights reserved.
//

import SwiftyJSON

extension WeatherService {
    func parseCurrentWeathers(_ json: JSON) -> [CityCurrentWeather] {
        let jsonWeathersList = json["list"].arrayValue
        
        var resultWeathersList = [CityCurrentWeather]()
        
        for jsonWeatherItem in jsonWeathersList {
            if let currentWeatherItem = parseCurrentWeather(jsonWeatherItem) {
                resultWeathersList.append(currentWeatherItem)
            }
        }
        
        return resultWeathersList
    }
    
    func parseCurrentWeather(_ json: JSON) -> CityCurrentWeather? {
        let main = json["main"]
        let cityId = json["id"].stringValue
        let humidity = main["humidity"].int
        let pressure = main["pressure"].int
        let wind = json["wind"]["speed"].int
        let title = json["name"].stringValue
        let weatherDescription = json["weather"].array?.first?["description"].stringValue
        
        let temperature = main["temp"].int
        
        if !someIsNil(temperature, wind, humidity, pressure, weatherDescription) {
            return CityCurrentWeather(title:              title,
                                      cityId:             cityId,
                                      wind:               wind!,
                                      humidity:           humidity!,
                                      pressure:           pressure!,
                                      temperature:        temperature!,
                                      weatherDescription: weatherDescription!)
        }
        else {
            return nil
        }
    }
    
    func parseForecastItem(_ json: JSON) -> Forecast? {
        let date = parseUnixDate(json["dt"])
        let temperature = json["temp"]["day"].int
        
        if !someIsNil(date, temperature) {
            return Forecast(date: date!, temperature: temperature!)
        }
        
        return nil
    }
    
    func parseForecast(_ json: JSON) -> [Forecast] {
        let jsonForecastList = json["list"].arrayValue
        
        var resultForecastList = [Forecast]()
        
        for jsonForecastItem in jsonForecastList {
            if let forecastItem = parseForecastItem(jsonForecastItem) {
                resultForecastList.append(forecastItem)
            }
        }
        
        resultForecastList.removeFirst()
        
        return resultForecastList
    }
    
    private func parseUnixDate(_ json: JSON) -> Date? {
        if let timeMilliseconds = json.double {
            return Date(timeIntervalSince1970: timeMilliseconds)
        }
        
        return nil
    }
    
    private func someIsNil(_ optionals: Optional<Any> ...) -> Bool {
        return optionals.contains { $0 == nil }
    }
}
