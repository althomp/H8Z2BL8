//
//  ViewController.swift
//  H8Z2BL8
//
//  Created by Abby Thompson on 9/29/17.
//  Copyright © 2017 althomp. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    @IBOutlet var table: UITableView!
    
    let tableData: [String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        table.delegate = self
        table.dataSource = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

}

extension ViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let label = cell.viewWithTag(1) as! UILabel
        label.text = tableData[indexPath.item]
    
        return cell
    }
    

}
