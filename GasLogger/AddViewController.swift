//
//  AddViewController.swift
//  GasLogger
//
//  Created by Jacob Pitkin on 12/3/18.
//  Copyright © 2018 Jacob Pitkin. All rights reserved.
//

import UIKit

protocol AddEntryProtocol {
    func addEntry(date: Double, miles: Int, price: Double, gallons: Double, image: UIImage?)
}

class AddViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    @IBOutlet weak var milesField: UITextField!
    @IBOutlet weak var priceField: UITextField!
    @IBOutlet weak var gallonsField: UITextField!
    var delegate: AddEntryProtocol?
    var previousMileage: Int?
    var image: UIImage?
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var addButton: UIButton!
    @IBOutlet weak var editButton: UIButton!
    let imagePicker = UIImagePickerController()
    
    @IBAction func loadImage(_ sender: Any) {
        imagePicker.allowsEditing = false
        imagePicker.sourceType = .photoLibrary
        
        present(imagePicker, animated: true, completion: nil)
    }
    
    @IBAction func editImage(_ sender: Any) {
        imagePicker.allowsEditing = false
        imagePicker.sourceType = .photoLibrary
        
        present(imagePicker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let pickedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            print("image selected")
            imageView.contentMode = .scaleToFill
            imageView.image = pickedImage
            image = pickedImage
            addButton.isHidden = true
            editButton.isHidden = false
        } else {
            print("problem selecting image")
        }
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        let save = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(saveItem))
        self.navigationItem.rightBarButtonItem = save
        
        imagePicker.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        print("previous: \(previousMileage!)")
    }
    
    @objc func saveItem() {
        if milesField.text?.isEmpty == true || priceField.text?.isEmpty == true || gallonsField.text?.isEmpty == true {
            return
        }
        
        if Int(milesField.text!)! < previousMileage! {
            let alert = UIAlertController(title: "Mileage Error", message: "Miles must be larger than last entry: \(previousMileage!)", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true)
            return
        }
        
        delegate!.addEntry(date: Date().timeIntervalSince1970, miles: Int(milesField.text!)!, price: Double(priceField.text!)!, gallons: Double(gallonsField.text!)!, image: image)
        
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
