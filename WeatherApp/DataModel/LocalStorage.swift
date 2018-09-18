//
//  LocalStorage.swift
//  WeatherApp
//
//  Created by Dmitrii Morozov on 25/01/2018.
//  Copyright © 2018 Dmitrii Morozov. All rights reserved.
//

import CoreData

class LocalStorage {
    /// Init
    init() {
        createCity(title: "Moscow", cityId: "524901")
        createCity(title: "Saint Petersburg", cityId: "498817")
        
        queue.maxConcurrentOperationCount = 1
    }
    
    /// Singleton
    static let sharedInstance = LocalStorage()
    
    /// Queue
    fileprivate let queue = OperationQueue()
    
    lazy var persistentContainer: NSPersistentContainer = {
        if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil {
            return mockPersistantContainer
        }
        else {
            return regularPersistentContainer
        }
    }()
    
    private lazy var regularPersistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "WeatherApp")
        container.loadPersistentStores(completionHandler: {
            (storeDescription, error) in
            
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
        
        return container
    }()
    
    private lazy var mockPersistantContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "WeatherApp")
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        description.shouldAddStoreAsynchronously = false
        
        container.persistentStoreDescriptions = [description]
        container.loadPersistentStores { (description, error) in
            precondition( description.type == NSInMemoryStoreType )

            if let error = error {
                fatalError("Create an in-mem coordinator failed \(error)")
            }
        }
        return container
    }()
}

// MARK: - Common
extension LocalStorage {
    private func enqueuBlock(_ block:@escaping (NSManagedObjectContext) -> ()) {
        self.queue.addOperation { [unowned self] in
            let context = self.persistentContainer.newBackgroundContext()
            context.performAndWait {
                block(context)
            }
        }
    }
    
    private func save(context: NSManagedObjectContext? = nil) {
        let context = context ?? persistentContainer.viewContext
        
        do {
            try context.save()
        }
        catch {
            print(error)
        }
    }
    
    func clear(onComplete:@escaping ()->()) {
        enqueuBlock { context in
            let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "CurrentWeather")
            if let weatherRecords = try? context.fetch(fetchRequest) as! [CurrentWeather] {
                for weatherRecord in weatherRecords {
                    context.delete(weatherRecord)
                }
            }
            let fetchRequestForecast = NSFetchRequest<NSManagedObject>(entityName: "ForecastRecord")
            if let forecasts = try? context.fetch(fetchRequestForecast) as! [ForecastRecord] {
                for forecast in forecasts {
                    context.delete(forecast)
                }
            }
            let fetchRequestCity = NSFetchRequest<NSManagedObject>(entityName: "City")
            if let cities = try? context.fetch(fetchRequestCity) as! [City] {
                for city in cities {
                    context.delete(city)
                }
            }
            self.save(context: context)
            onComplete()
        }
    }
}

// MARK: - CurrentWeather
extension LocalStorage {
    func createOrUpdateCityCurrentWeatherItems(items: [CityCurrentWeather]) {
        for cityCurrentWeatherItem in items {
            createOrUpdateCityCurrentWeather(cityCurrentWeatherItem)
        }
    }
    
    func createOrUpdateCityCurrentWeather(_ cityCurrentWeather: CityCurrentWeather, onComplete: (()->())? = nil) {
        enqueuBlock { context in
            if self.getCity(id: cityCurrentWeather.cityId, context: context) == nil {
                let city = NSEntityDescription.insertNewObject(forEntityName: "City", into: context) as! City
                city.title = cityCurrentWeather.title
                city.id    = cityCurrentWeather.cityId
            }
            let currentWeatherRecord = self.getCityCurrentWeather(cityId: cityCurrentWeather.cityId, context: context) ?? NSEntityDescription.insertNewObject(forEntityName: "CurrentWeather", into: context) as! CurrentWeather
            
            currentWeatherRecord.city               = self.getCity(id: cityCurrentWeather.cityId, context: context)
            currentWeatherRecord.wind               = Int32(cityCurrentWeather.wind)
            currentWeatherRecord.humidity           = Int32(cityCurrentWeather.humidity)
            currentWeatherRecord.pressure           = Int32(cityCurrentWeather.pressure)
            currentWeatherRecord.temperature        = Int32(cityCurrentWeather.temperature)
            currentWeatherRecord.weatherDescription = cityCurrentWeather.weatherDescription
            
            self.save(context: context)
        }
    }
    
    func getCityCurrentWeather(cityId: String, context: NSManagedObjectContext? = nil) -> CurrentWeather? {
        let context = context ?? persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "CurrentWeather")
        fetchRequest.predicate = NSPredicate(format: "city.id == %@", cityId)
        do {
            let currentWeatherRecords = try context.fetch(fetchRequest) as? [CurrentWeather]
            
            return currentWeatherRecords?.first
        }
        catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
            
            return nil
        }
    }
}

// MARK: - City
extension LocalStorage {
    func deleteCity(id: String) {
        enqueuBlock { context in
            if let city = self.getCity(id: id, context: context) {
                context.delete(city)
                
                self.save(context: context)
            }
        }
    }
    
    func createCity(title: String, cityId: String) {
        if getCity(id: cityId) == nil {
            enqueuBlock { context in
                let city = NSEntityDescription.insertNewObject(forEntityName: "City", into: context) as! City
                
                city.title = title
                city.id    = cityId
                
                self.save(context: context)
            }
        }
    }
    
    func getCity(id: String, context: NSManagedObjectContext) -> City? {
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "City")
        fetchRequest.predicate = NSPredicate(format: "id == %@", id)
        do {
            let cities = try context.fetch(fetchRequest) as? [City]
            
            return cities?.first
        }
        catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
            
            return nil
        }
    }
    
    func getCity(id: String) -> City? {
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "City")
        fetchRequest.predicate = NSPredicate(format: "id == %@", id)
        do {
            let cities = try persistentContainer.viewContext.fetch(fetchRequest) as? [City]
            
            return cities?.first
        }
        catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
            
            return nil
        }
    }
    
    func getCities() -> [City]? {
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "City")
        do {
            return try persistentContainer.viewContext.fetch(fetchRequest) as? [City]
        }
        catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
            
            return nil
        }
    }
}

// MARK: - ForecastRecord
extension LocalStorage {
    func createOrUpdateForecastRecord(forecastItems: [Forecast], cityId: String) {
        enqueuBlock { context in
            if forecastItems.count > 0 {
                let forecastRecord = self.getCityForecast(cityId: cityId, context: context) ??  NSEntityDescription.insertNewObject(forEntityName: "ForecastRecord", into: context) as! ForecastRecord
                
                forecastRecord.city        = self.getCity(id: cityId, context: context)
                forecastRecord.count       = Int16(forecastItems.count)
                forecastRecord.startDate   = forecastItems.first!.date
                forecastRecord.temperature = forecastItems.map{ $0.temperature }
                
                self.save(context: context)
            }
        }
    }
    
    func getCityForecast(cityId: String) -> ForecastRecord? {
        let context = persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "ForecastRecord")
        fetchRequest.predicate = NSPredicate(format: "city.id == %@", cityId)
        do {
            let cityForecasts = try context.fetch(fetchRequest) as? [ForecastRecord]
            
            return cityForecasts?.first
        }
        catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
            
            return nil
        }
    }
    
    func getCityForecast(cityId: String, context: NSManagedObjectContext) -> ForecastRecord? {
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "ForecastRecord")
        fetchRequest.predicate = NSPredicate(format: "city.id == %@", cityId)
        do {
            let cityForecasts = try context.fetch(fetchRequest) as? [ForecastRecord]
            
            return cityForecasts?.first
        }
        catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        
            return nil
        }
    }
}
