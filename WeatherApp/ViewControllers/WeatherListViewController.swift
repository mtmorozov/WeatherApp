//
//  ViewController.swift
//  WeatherApp
//
//  Created by Dmitrii Morozov on 25/01/2018.
//  Copyright © 2018 Dmitrii Morozov. All rights reserved.
//

import UIKit

final class WeatherListViewController: UIViewController {
    /// Outlets
    @IBOutlet weak var tableView: UITableView!
    var editBarButtonItem: UIBarButtonItem!
    
    /// Data
    var cityCurrentWeatherItems: [CityCurrentWeather] = []
}

extension WeatherListViewController {
    func loadDataFromDatabase() {
        cityCurrentWeatherItems = getCurrentWeathersFromDatabase()
    }
}

// MARK: - Constants
extension WeatherListViewController {
    fileprivate struct Constants {
        static let numberOfSections = 1
    }
}

// MARK: - Lifecycle
extension WeatherListViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadDataFromDatabase()
        setupNavigationBar()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        getCurrentWeatherItemsOnline(onComplete: updateCityCurrentWeatherItems)
        NotificationCenter.default.addObserver(self, selector: #selector(reachabilityChanged), name: NSNotification.Name(rawValue: Notifications.offlineNotification), object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: Notifications.offlineNotification), object: nil)
    }
    
    @objc func reachabilityChanged(note: Notification) {
        if ConnectionController.shared.isOnline {
            title = "Weather"
            
            getCurrentWeatherItemsOnline(onComplete: updateCityCurrentWeatherItems)
        }
        else {
            title = "Weather(offline)"
        }
    }
    
    private func updateCityCurrentWeatherItems(_ newCityCurrentWeatherItems: [CityCurrentWeather]) {
        if newCityCurrentWeatherItems.count > 0 {
            self.cityCurrentWeatherItems = newCityCurrentWeatherItems
            self.tableView.reloadData()
        }
    }
    
    func getCurrentWeathersFromDatabase() -> [CityCurrentWeather] {
        var resultArray: [CityCurrentWeather] = []
        
        if let cities = LocalStorage.sharedInstance.getCities() {
            
            for city in cities {
                if let currentWeather = LocalStorage.sharedInstance.getCityCurrentWeather(cityId: city.id!) {
                    let cityCurrentWeather = CityCurrentWeather(title: city.title!,
                                                                cityId: city.id!,
                                                                wind: Int(currentWeather.wind),
                                                                humidity: Int(currentWeather.humidity),
                                                                pressure: Int(currentWeather.pressure),
                                                                temperature: Int(currentWeather.temperature),
                                                                weatherDescription: currentWeather.weatherDescription!)
                    
                    resultArray.append(cityCurrentWeather)
                }
            }
        }
        
        return resultArray
    }
}

// MARK: - Setup
extension WeatherListViewController {
    fileprivate func setupNavigationBar() {
        editBarButtonItem = UIBarButtonItem(title: "Edit", style: .done, target: self, action: #selector(changeTableEditingStyle))
        navigationItem.leftBarButtonItem = editBarButtonItem
    }
}

// MARK: - UI Handlers
extension WeatherListViewController {
    @IBAction func onAddBarButtonItem(_ sender: Any) {
        if ConnectionController.shared.isOnline {
            alertWithTextInput(title: "New city", message: "Enter the name") { self.addNewCity(city: $0, onComplete: self.addNewCityCurrentWeather) }
        }
        else {
            alert(title: "Error", message: "You can't add cities in offline")
        }
    }
    
    func getCurrentWeatherItemsOnline(onComplete: @escaping ([CityCurrentWeather]) -> Void) {
        if let cities = LocalStorage.sharedInstance.getCities() {
            WeatherService.sharedInstance.getCurrentWeathers(cityIds: cities.map{ $0.id! }) {
                cityCurrentWeatherItems in
                
                LocalStorage.sharedInstance.createOrUpdateCityCurrentWeatherItems(items: cityCurrentWeatherItems)
                onComplete(cityCurrentWeatherItems)
            }
        }
        else {
            onComplete([])
        }
    }
    
    private func addNewCityCurrentWeather(_ newCityCurrentWeather: CityCurrentWeather?, addCityResult: AddCityResult) {
        switch addCityResult
        {
        case .error:
            alert(title: "Error", message: "Could not add city. Check the name and try again")
            
        case .exist:
            alert(title: "Error", message: "The city is already on the list")
            
        case .success:
            cityCurrentWeatherItems.append(newCityCurrentWeather!)
            self.tableView.insertRows(at: [IndexPath(row: cityCurrentWeatherItems.count - 1, section: 0)], with: .top)
        }
    }
    
    func addNewCity(city: String, onComplete: @escaping (CityCurrentWeather?, AddCityResult) -> Void) {
        WeatherService.sharedInstance.getCurrentWeather(city: city) {
            cityCurrentWeather in
            
            if let cityCurrentWeather = cityCurrentWeather {
                if let _ = LocalStorage.sharedInstance.getCity(id: cityCurrentWeather.cityId) {
                    onComplete(nil, .exist)
                }
                else {
                    LocalStorage.sharedInstance.createOrUpdateCityCurrentWeather(cityCurrentWeather)
                    onComplete(cityCurrentWeather, .success)
                }
            }
            else {
                onComplete(nil, .error)
            }
        }
    }
    
    func deleteCity(cityId: String) {
        LocalStorage.sharedInstance.deleteCity(id: cityId)
    }
}

// MARK: - Navigation
extension WeatherListViewController {
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let detailViewController = segue.destination as? WeatherDetailViewController {
            detailViewController.setup(cityCurrentWeatherItems[(tableView.indexPathForSelectedRow?.row)!])
            tableView.deselectRow(at: tableView.indexPathForSelectedRow!, animated: true)
        }
    }
}

// MARK: - Table
extension WeatherListViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return Constants.numberOfSections
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cityCurrentWeatherItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CityWeatherCell.identifier, for: indexPath) as! CityWeatherCell
        cell.setup(currentWeather: cityCurrentWeatherItems[indexPath.row])
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if cityCurrentWeatherItems[indexPath.row].cityId != GlobalConstants.EmbeddedCityIds.moscowId && cityCurrentWeatherItems[indexPath.row].cityId != GlobalConstants.EmbeddedCityIds.spbId {
            deleteCity(cityId: cityCurrentWeatherItems[indexPath.row].cityId)
            cityCurrentWeatherItems.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
        else {
            alert(title: "Error", message: "You can't delete embedded cities")
        }
    }
    
    @objc func changeTableEditingStyle() {
        tableView.setEditing(!tableView.isEditing, animated: true)
        editBarButtonItem.title = tableView.isEditing ? "Done" : "Edit"
    }
}

enum AddCityResult {
    case success
    case exist
    case error
}

// MARK: - Cell
class CityWeatherCell: UITableViewCell {
    /// Outlets
    @IBOutlet weak var cityTitleLabel:   UILabel!
    @IBOutlet weak var temperatureLabel: UILabel!
    
    /// Identifier
    static let identifier = "CityWeatherCell"
    
    // MARK: - Setup
    func setup(currentWeather: CityCurrentWeather) {
        cityTitleLabel.text   = currentWeather.title.capitalized
        temperatureLabel.text = currentWeather.temperature.description + "°"
    }
}
