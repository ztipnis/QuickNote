//
//  ViewController.swift
//  QuickNote
//
//  Created by Zachary A. Tipnis on 3/10/17.
//  Copyright © 2017 zachal. All rights reserved.
//

import UIKit
import SVGKit

class ViewController: UIViewController {

    @IBOutlet var photoButton: UIButton!
    @IBOutlet var noteButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let url = Bundle.main.url(forResource: "photo-camera", withExtension: "svg")
        let image = SVGKImage.init(contentsOf: url)
        photoButton.setImage(image?.uiImage, for: .normal)
        
        let url2 = Bundle.main.url(forResource: "quill", withExtension: "svg")
        let image2 = SVGKImage.init(contentsOf: url2)
        noteButton.setImage(image2?.uiImage, for: .normal)
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

