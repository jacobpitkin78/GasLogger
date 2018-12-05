//
//  EditViewController.swift
//  GasLogger
//
//  Created by Jacob Pitkin on 12/3/18.
//  Copyright © 2018 Jacob Pitkin. All rights reserved.
//

import UIKit

protocol EditEntryProtocol {
    func editEntry(miles: Int, price: Double, gallons: Double)
}

class EditViewController: UIViewController {
    @IBOutlet weak var milesField: UITextField!
    @IBOutlet weak var priceField: UITextField!
    @IBOutlet weak var gallonsField: UITextField!
    var delegate: EditEntryProtocol?
    var miles: Int?
    var price: Double?
    var gallons: Double?
    var previousMileage: Int?
    var nextMileage: Int?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        let save = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(saveItem))
        self.navigationItem.rightBarButtonItem = save
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        milesField.text = String(miles!)
        priceField.text = String(price!)
        gallonsField.text = String(gallons!)
    }
    
    @objc func saveItem() {
        if milesField.text?.isEmpty == true || priceField.text?.isEmpty == true || gallonsField.text?.isEmpty == true {
            return
        }
        
        if Int(milesField.text!)! < previousMileage! {
            let alert = UIAlertController(title: "Mileage Error", message: "Mileage must be larger than last entry: \(previousMileage!)", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true)
            return
        } else if Int(milesField.text!)! > nextMileage! {
            let alert = UIAlertController(title: "Mileage Error", message: "Mileage must be less than next entry: \(nextMileage!)", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true)
            return
        }
        
        delegate!.editEntry(miles: Int(milesField.text!)!, price: Double(priceField.text!)!, gallons: Double(gallonsField.text!)!)
        
        self.navigationController?.popViewController(animated: true)
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
