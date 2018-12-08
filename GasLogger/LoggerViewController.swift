//
//  LoggerViewController.swift
//  GasLogger
//
//  Created by Jacob Pitkin on 12/3/18.
//  Copyright © 2018 Jacob Pitkin. All rights reserved.
//

import UIKit
import SQLite3

class LoggerViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, AddEntryProtocol, EditEntryProtocol, SetDashboardImage {
    
    struct Entry {
        var date: Double
        var miles: Int
        var price: Double
        var gallons: Double
        var spent: Double
    }
    
    var entries: [Entry] = []
    var db: OpaquePointer?
    var entryBeingEdited: Int!
    @IBOutlet var tableView: UITableView!
    var dashboardImage: UIImage?
    
    func addEntry(date: Double, miles: Int, price: Double, gallons: Double, image: UIImage?) {
        entries.append(Entry(date: date, miles: miles, price: price, gallons: gallons, spent: price * gallons))
        
        if let i = image {
            let result = saveImage(image: i, path: "\(date)")
            
            if result {
                print("saved added image")
            } else {
                print("didn't save added image")
            }
        }
        
        self.tableView.reloadData()
    }
    
    func editEntry(miles: Int, price: Double, gallons: Double, image: UIImage?) {
        entries[entryBeingEdited].miles = miles
        entries[entryBeingEdited].price = price
        entries[entryBeingEdited].gallons = gallons
        entries[entryBeingEdited].spent = price * gallons
        
        if let i = image {
            let result = saveImage(image: i, path: "\(entries[entryBeingEdited].date)")
            
            if result {
                print("image saved from edit")
            } else {
                print("image not saved from edit")
            }
        }
        
        self.tableView.reloadData()
    }
    
    func setDashboardImage(image: UIImage) {
        dashboardImage = image
        let result = saveImage(image: image, path: "dashboard")
        
        if result {
            print("saved")
        } else {
            print("not saved")
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return entries.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        
//        cell.textLabel?.text = String(indexPath.row)
//        cell.detailTextLabel?.text = "Details"
        
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        formatter.dateStyle = .medium
        
        let date = formatter.string(from: Date(timeIntervalSince1970: TimeInterval(entries[indexPath.row].date)))
        
        cell.textLabel?.text = date
        
        if indexPath.row > 0 {
            let mpg = Double(Double(entries[indexPath.row].miles - entries[indexPath.row - 1].miles) / entries[indexPath.row].gallons)
            
            cell.detailTextLabel?.text = "Miles: \(entries[indexPath.row].miles)\tMPG: \(String(format: "%.2f", mpg))\tSpent: $\(String(format: "%.2f", entries[indexPath.row].spent))";
        } else {
            cell.detailTextLabel?.text = "Miles: \(entries[indexPath.row].miles)\tSpent: \(String(format: "%.2f", entries[indexPath.row].spent))"
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") {(action: UIContextualAction, sourceView: UIView, actionPerformed:@escaping (Bool) -> Void) in
            let dialogMessage = UIAlertController(title: "Confirm", message: "Are you sure you want to delete this?", preferredStyle: .alert)
            
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                if self.removeImage(named: "\(self.entries[indexPath.row].date)") {
                    print("returned true")
                }
                self.entries.remove(at: indexPath.row)
                tableView.reloadData()
                actionPerformed(true)
            })
            
            let cancel = UIAlertAction(title: "Cancel", style: .cancel) { (action) -> Void in
                print("Cancel button tapped")
                actionPerformed(false)
            }
            
            dialogMessage.addAction(ok)
            dialogMessage.addAction(cancel)
            
            self.present(dialogMessage, animated: true, completion: nil)
        }
        
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "addSegue"  {
            let view = segue.destination as! AddViewController
            view.delegate = self
            
            if entries.count == 0 {
                view.previousMileage = 0
            } else {
                view.previousMileage = entries[entries.count-1].miles
            }
        } else if segue.identifier == "editSegue" {
            let view = segue.destination as! EditViewController
            view.delegate = self
            entryBeingEdited = tableView.indexPathForSelectedRow?.row
            
            view.miles = entries[entryBeingEdited].miles
            view.price = entries[entryBeingEdited].price
            view.gallons = entries[entryBeingEdited].gallons
            
            if entryBeingEdited == 0 {
                view.previousMileage = 0
                
                if entries.count > 1 {
                    view.nextMileage = entries[entryBeingEdited+1].miles
                } else {
                    view.nextMileage = Int.max
                }
            } else {
                view.previousMileage = entries[entryBeingEdited-1].miles
                
                if entryBeingEdited < entries.count - 1 {
                    view.nextMileage = entries[entryBeingEdited+1].miles
                } else {
                    view.nextMileage = Int.max
                }
            }
            
            if let i = getSavedImage(named: "\(entries[entryBeingEdited].date)") {
                view.image = i
            }
        } else if segue.identifier == "dashboardSegue" {
            let view = segue.destination as! DashboardController
            view.delegate = self
            
            if let i = getSavedImage(named: "dashboard") {
                view.image = i
            }
        }
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(saveToDatabase(_:)), name: UIApplication.willResignActiveNotification, object: nil)
        
        let fileURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("GasLogger.sqlite")
        
        
        if sqlite3_open(fileURL.path, &db) != SQLITE_OK {
            print("error opening database")
        }
        
        if sqlite3_exec(db, "CREATE TABLE IF NOT EXISTS Entries (id INTEGER PRIMARY KEY AUTOINCREMENT, date DOUBLE, miles INTEGER, price DOUBLE, gallons DOUBLE, spent DOUBLE)", nil, nil, nil) != SQLITE_OK {
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            print("error creating table: \(errmsg)")
        }
        
        if sqlite3_exec(db, "CREATE TABLE IF NOT EXISTS DashboardImage (path TEXT)", nil, nil, nil) != SQLITE_OK {
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            print("error creating dashboard table: \(errmsg)")
        }
        
        readValues()
    }
    
    func readValues() {
        entries.removeAll()
        
        let queryString = "SELECT * FROM Entries"
        var stmt: OpaquePointer?
        
        if sqlite3_prepare(db, queryString, -1, &stmt, nil) != SQLITE_OK {
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            print("error preparing selection: \(errmsg)")
            return
        }
        
        while sqlite3_step(stmt) == SQLITE_ROW {
            let date = Double(sqlite3_column_double(stmt, 1))
            let miles = Int(sqlite3_column_int(stmt, 2))
            let price = Double(sqlite3_column_double(stmt, 3))
            let gallons = Double(sqlite3_column_double(stmt, 4))
            let spent = Double(sqlite3_column_double(stmt, 5))
            
            entries.append(Entry(date: date, miles: miles, price: price, gallons: gallons, spent: spent))
        }
        
        self.tableView.reloadData()
    }
    
    @objc func saveToDatabase(_ notification: Notification) {
        let queryString = "INSERT INTO Entries (date, miles, price, gallons, spent) values (?, ?, ?, ?, ?)"
        let deleteString = "DELETE FROM Entries"
        var stmt: OpaquePointer?
        
        if sqlite3_prepare(db, deleteString, -1, &stmt, nil) != SQLITE_OK {
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            print("error preparing delete: \(errmsg)")
            return
        }
        
        if sqlite3_step(stmt) != SQLITE_DONE {
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            print("failure deleting entries from entries table: \(errmsg)")
            return
        }
        
        for entry in entries {
            if sqlite3_prepare(db, queryString, -1, &stmt, nil) != SQLITE_OK {
                let errmsg = String(cString: sqlite3_errmsg(db)!)
                print("error preparing insert: \(errmsg)")
                return
            }
            
            if sqlite3_bind_double(stmt, 1, entry.date) != SQLITE_OK {
                let errmsg = String(cString: sqlite3_errmsg(db)!)
                print("error binding date: \(errmsg)")
                return
            }
            
            if sqlite3_bind_int(stmt, 2, Int32(entry.miles)) != SQLITE_OK {
                let errmsg = String(cString: sqlite3_errmsg(db)!)
                print("error binding miles: \(errmsg)")
                return
            }
            
            if sqlite3_bind_double(stmt, 3, entry.price) != SQLITE_OK {
                let errmsg = String(cString: sqlite3_errmsg(db)!)
                print("error binding price: \(errmsg)")
                return
            }
            
            if sqlite3_bind_double(stmt, 4, entry.gallons) != SQLITE_OK {
                let errmsg = String(cString: sqlite3_errmsg(db)!)
                print("error binding gallons: \(errmsg)")
                return
            }
            
            if sqlite3_bind_double(stmt, 5, entry.spent) != SQLITE_OK {
                let errmsg = String(cString: sqlite3_errmsg(db)!)
                print("error binding spent: \(errmsg)")
                return
            }
            
            if sqlite3_step(stmt) != SQLITE_DONE {
                let errmsg = String(cString: sqlite3_errmsg(db)!)
                print("failure inserting entry: \(errmsg)")
                return
            }
        }
        
        sqlite3_close(db)
    }
    
    func saveImage(image: UIImage, path: String) -> Bool {
        guard let data = image.pngData() else {
            return false
        }
        guard let directory = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false) as NSURL else {
            return false
        }
        do {
            try data.write(to: directory.appendingPathComponent("\(path).png")!)
            return true
        } catch {
            print(error.localizedDescription)
            return false
        }
    }
    
    func getSavedImage(named: String) -> UIImage? {
        if let dir = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false) {
            return UIImage(contentsOfFile: URL(fileURLWithPath: dir.absoluteString).appendingPathComponent("\(named).png").path)
        }
        return nil
    }
    
    func removeImage(named: String) -> Bool {
        do {
            if FileManager.default.fileExists(atPath: "\(named).png") {
                try FileManager.default.removeItem(atPath: "\(named).png")
                print("removed file")
                return true
            }
        } catch {
            print(error.localizedDescription)
            return false
        }
        
        print("nothing to remove")
        return false
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
