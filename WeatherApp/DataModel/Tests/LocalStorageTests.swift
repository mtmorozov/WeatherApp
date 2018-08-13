//
//  LocalStorageTests.swift
//  WeatherAppTests
//
//  Created by Dmitrii Morozov on 13/08/2018.
//  Copyright © 2018 Dmitrii Morozov. All rights reserved.
//

import XCTest
@testable import WeatherApp

class LocalStorageTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        let expectation = self.expectation(description: "Setup")
        LocalStorage.sharedInstance.clear {
            expectation.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
        
        let cities = LocalStorage.sharedInstance.getCities()
        XCTAssert(cities?.count == 0)
    }
    
    override func tearDown() {
        super.tearDown()
        
        let expectation = self.expectation(description: "Teardown")

        LocalStorage.sharedInstance.clear {
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5, handler: nil)
    }
}
