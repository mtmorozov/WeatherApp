//
//  UIViewController+Alert.swift
//  WeatherApp
//
//  Created by Dmitrii Morozov on 27/01/2018.
//  Copyright © 2018 Dmitrii Morozov. All rights reserved.
//

import UIKit

extension UIViewController {
    func alert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
        
        present(alert, animated: true, completion: nil)
    }
    
    func alertWithTextInput(title: String, message: String, handler: @escaping (String) -> Void) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        alert.addTextField { $0.text = "" }
        
        alert.addAction(UIAlertAction(title: "OK", style: .default) {
            [weak alert] (_) in
            
            let text = alert?.textFields![0].text
            
            handler(text!)
        })
        
        present(alert, animated: true, completion: nil)
    }
}
