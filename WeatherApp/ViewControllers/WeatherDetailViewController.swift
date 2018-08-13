//
//  DetailViewController.swift
//  WeatherApp
//
//  Created by Dmitrii Morozov on 27/01/2018.
//  Copyright © 2018 Dmitrii Morozov. All rights reserved.
//

import UIKit

final class WeatherDetailViewController: UIViewController {
    /// Outlets
    @IBOutlet weak var humidityLabel:           UILabel!
    @IBOutlet weak var pressureLabel:           UILabel!
    @IBOutlet weak var cityTitleLabel:          UILabel!
    @IBOutlet weak var windSpeedLabel:          UILabel!
    @IBOutlet weak var descriptionTitleLabel:   UILabel!
    @IBOutlet weak var currentTemperatureLabel: UILabel!
    
    @IBOutlet weak var tableView: UITableView!
    
    /// Data
    var cityCurrentWeather: CityCurrentWeather!
    var forecastItems: [Forecast] = [Forecast]()
}

// MARK: - Constants
extension WeatherDetailViewController {
    fileprivate struct Constants {
        static let numberOfSections = 1
        static let rowHeight: CGFloat = 50.0
    }
}

// MARK: - Lifecycle
extension WeatherDetailViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = cityCurrentWeather.title
        
        humidityLabel.text           = cityCurrentWeather.humidity.description + " %"
        pressureLabel.text           = cityCurrentWeather.pressure.description + " hPa"
        windSpeedLabel.text          = cityCurrentWeather.wind.description + " mps"
        descriptionTitleLabel.text   = cityCurrentWeather.weatherDescription.capitalized
        currentTemperatureLabel.text = cityCurrentWeather.temperature.description + "°"
        
        loadDataFromDatabase()
    }
    
    private func loadDataFromDatabase() {
        forecastItems = getForecastFromDatabase(cityId: cityCurrentWeather.cityId)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        getForecast(cityId: cityCurrentWeather.cityId, onComplete: refreshForecast)
        NotificationCenter.default.addObserver(self, selector: #selector(reachabilityChanged), name: NSNotification.Name(rawValue: Notifications.offlineNotification), object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: Notifications.offlineNotification), object: nil)
    }
    
    @objc func reachabilityChanged(note: Notification) {
        if ConnectionController.shared.isOnline {
            getForecast(cityId: cityCurrentWeather.cityId, onComplete: refreshForecast)
        }
    }
    
    private func refreshForecast(forecastItems: [Forecast]) {
        if forecastItems.count > 0 {
            self.forecastItems = forecastItems
            self.tableView.reloadData()
        }
    }
}

// MARK: - Setup
extension WeatherDetailViewController {
    func setup(_ currentWeather: CityCurrentWeather) {
        cityCurrentWeather = currentWeather
    }
}

// MARK: - Table
extension WeatherDetailViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return Constants.numberOfSections
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return forecastItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ForecastCell.identifier, for: indexPath) as! ForecastCell
        
        cell.setup(forecast: forecastItems[indexPath.row])
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return Constants.rowHeight;
    }
}

// MARK: - Getting forecast
extension WeatherDetailViewController {
    func getForecast(cityId: String, onComplete: @escaping ([Forecast]) -> Void) {
        WeatherService.sharedInstance.getForecast(cityId: cityId) {
            forecast in
            LocalStorage.sharedInstance.createOrUpdateForecastRecord(forecastItems: forecast, cityId: cityId)
            onComplete(forecast)
        }
    }
    
    func getForecastFromDatabase(cityId: String) -> [Forecast] {
        var resultArray = [Forecast]()
        if let forecastRecord = LocalStorage.sharedInstance.getCityForecast(cityId: cityId) {
            for i in 0..<forecastRecord.count {
                let index = Int(i)
                let temperature = forecastRecord.temperature![index]
                let date = Calendar.current.date(byAdding: .day, value: index, to: forecastRecord.startDate!)!
                
                resultArray.append(Forecast(date: date, temperature: temperature))
            }
        }
        
        return resultArray
    }
}

// MARK: - Cell
class ForecastCell: UITableViewCell {
    /// Outlets
    @IBOutlet weak var dateLabel:   UILabel!
    @IBOutlet weak var temperatureLabel: UILabel!
    
    /// Identifier
    static let identifier = "ForecastCell"
    
    // MARK: - Setup
    func setup(forecast: Forecast) {
        dateLabel.text        = forecast.date.toString(dateFormat: "dd.MM.yyyy")
        temperatureLabel.text = forecast.temperature.description + "°"
    }
}
