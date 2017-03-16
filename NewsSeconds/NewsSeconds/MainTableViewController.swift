//
//  ViewController.swift
//  NewsSeconds
//
//  Created by Anantha Krishnan K G on 02/03/17.
//  Copyright © 2017 Ananth. All rights reserved.
//

import UIKit
import OpenWhisk
import UserNotifications

class MainTableViewController: UITableViewController {
    
    let kCloseCellHeight: CGFloat = 179
    let kOpenCellHeight: CGFloat = 488
    
    let kRowsCount = 10
    var tableValue:NSArray = [];
    var cellHeights = [CGFloat]()
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    var indicator = UIActivityIndicatorView()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        activityIndicator()
       self.tableView.contentInset = UIEdgeInsetsMake(20, 0, 0, 0)
        createCellHeightsArray()
        loadData()
        

        //self.tableView.backgroundColor = UIColor(patternImage: UIImage(named: "background")!)
    }
    
    func activityIndicator() {
        indicator = UIActivityIndicatorView(frame: CGRect(x: self.view.center.x - 10, y: 0, width: 40, height: 40))
        indicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.whiteLarge
        indicator.color = UIColor.green
        self.view.addSubview(indicator)
        indicator.startAnimating()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if appDelegate.valueChanged {
            self.tableValue = []
            self.tableView.reloadData()
            indicator.startAnimating()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if appDelegate.valueChanged {
            loadData()
            appDelegate.valueChanged = false
        }
     }
    
    func loadData(){
        
        let credentialsConfiguration = WhiskCredentials(accessKey:appDelegate.whiskAccessKey, accessToken: appDelegate.whiskAccessToken)
        
        let whisk = Whisk(credentials: credentialsConfiguration)
        whisk.verboseReplies = true

        var params = Dictionary<String, String>()
        params["source"] = appDelegate.source
        params["apiKey"] = appDelegate.newsAPIKey
        do {
            try whisk.invokeAction(name: appDelegate.whiskActionName, package: "", namespace: appDelegate.whiskNameSpace, parameters: params as AnyObject?, hasResult: true, callback: {(reply, error) -> Void in
                
                if let error = error {
                    //do something
                    print("Error invoking action \(error.localizedDescription)")
                    
                } else {
                    var result = reply?["response"]?["result"] as? [String: AnyObject]
                    print("Got result \(result?["articles"] as! NSArray)")
                    self.tableValue = (result?["articles"] as? NSArray)!
                    self.tableView.reloadData()
                    self.indicator.stopAnimating()
                    self.indicator.hidesWhenStopped = true
                }
                
            })
        } catch {
            print("Error \(error)")
        }
        
    }
    // MARK: configure
    func createCellHeightsArray() {
        for _ in 0...kRowsCount {
            cellHeights.append(kCloseCellHeight)
        }
    }
    
    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableValue.count
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        
        guard case let cell as ActionCell = cell else {
            return
        }
        
        cell.backgroundColor = UIColor.clear
        
        if cellHeights[(indexPath as NSIndexPath).row] == kCloseCellHeight {
            cell.selectedAnimation(false, animated: false, completion:nil)
        } else {
            cell.selectedAnimation(true, animated: false, completion: nil)
        }
        
        cell.setValues = tableValue[indexPath.row] as! [String : AnyObject]
        cell.number = indexPath.row
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FoldingCell", for: indexPath)
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return cellHeights[(indexPath as NSIndexPath).row]
    }
    
    // MARK: Table vie delegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let cell = tableView.cellForRow(at: indexPath) as! FoldingCell
        if cell.isAnimating() {
            return
        }
        var duration = 0.0
        if cellHeights[(indexPath as NSIndexPath).row] == kCloseCellHeight { // open cell
            cellHeights[(indexPath as NSIndexPath).row] = kOpenCellHeight
            cell.selectedAnimation(true, animated: true, completion: nil)
            duration = 0.5
        } else {// close cell
            cellHeights[(indexPath as NSIndexPath).row] = kCloseCellHeight
            cell.selectedAnimation(false, animated: true, completion: nil)
            duration = 0.8
        }
        UIView.animate(withDuration: duration, delay: 0, options: .curveEaseOut, animations: { () -> Void in
            tableView.beginUpdates()
            tableView.endUpdates()
        }, completion: nil)
    }
    
    @IBAction func refreshData(_ sender: UIBarButtonItem) {
        self.tableValue = []
        self.tableView.reloadData()
        indicator.startAnimating()
        loadData()
        
    }
}

