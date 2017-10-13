//
//  PhotoViewController.swift
//  QuickNote
//
//  Created by Zachary A. Tipnis on 3/10/17.
//  Copyright © 2017 zachal. All rights reserved.
//

import UIKit

class PhotoViewController: UIViewController {

    var appDelegate:AppDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.titleView = nil
        //self.view.translatesAutoresizingMaskIntoConstraints = false
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        appDelegate = UIApplication.shared.delegate as? AppDelegate
        appDelegate?.conn?.setupPeerIDAndSession(with: UIDevice.current.name)
        appDelegate?.conn?.advertiseSelf(shouldAdvertise: true)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        appDelegate?.conn?.advertiseSelf(shouldAdvertise: false)
    }



}
