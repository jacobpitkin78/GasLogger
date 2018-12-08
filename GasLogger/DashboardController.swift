//
//  ViewController.swift
//  GasLogger
//
//  Created by Jacob Pitkin on 12/3/18.
//  Copyright © 2018 Jacob Pitkin. All rights reserved.
//

import UIKit

protocol SetDashboardImage {
    func setDashboardImage(image: UIImage)
}

class DashboardController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    @IBOutlet weak var imageView: UIImageView!
    let imagePicker = UIImagePickerController()
    @IBOutlet weak var chooseButton: UIButton!
    var image: UIImage?
    var delegate: SetDashboardImage?
    @IBOutlet weak var editButton: UIButton!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var milesLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var gallonsLabel: UILabel!
    @IBOutlet weak var fillupsLabel: UILabel!
    @IBOutlet weak var mpgLabel: UILabel!
    @IBOutlet weak var totalMilesLabel: UILabel!
    @IBOutlet weak var totalSpentLabel: UILabel!
    var lastFillup: String?
    var lastMiles: String?
    var lastPrice: String?
    var lastGallons: String?
    var totalFillups: String?
    var avgMpg: String?
    var totalMiles: String?
    var totalSpent: String?
    
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        imagePicker.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if let i = image {
            imageView.contentMode = .scaleToFill
            imageView.image = i
            chooseButton.isHidden = true
            editButton.isHidden = false
        }
        
        dateLabel.text = lastFillup
        milesLabel.text = lastMiles
        priceLabel.text = lastPrice
        gallonsLabel.text = lastGallons
        fillupsLabel.text = totalFillups
        mpgLabel.text = avgMpg
        totalMilesLabel.text = totalMiles
        totalSpentLabel.text = totalSpent
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let pickedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            imageView.contentMode = .scaleToFill
            imageView.image = pickedImage
            image = pickedImage
            delegate!.setDashboardImage(image: pickedImage)
            chooseButton.isHidden = true
            editButton.isHidden = false
        }
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }


}

