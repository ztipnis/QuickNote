//
//  photoCollectionItem.swift
//  QuickNote
//
//  Created by Zachary A. Tipnis on 3/12/17.
//  Copyright © 2017 zachal. All rights reserved.
//

import Cocoa

class photoCollectionItem: NSCollectionViewItem {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    var imageFile: ImageFile? {
        didSet{
            guard isViewLoaded else { return }
            if let imageFile = imageFile {
                imageView?.image = imageFile.thumbnail
            } else {
                imageView?.image = nil
            }
        }
    }
    override var isSelected: Bool {
        didSet{
            if(isSelected){
                imageView?.wantsLayer = true
                imageView?.layer?.borderColor = NSColor.blue.cgColor
                imageView?.layer?.borderWidth = 1.0
                imageView?.layer?.masksToBounds = true
            }else{
                imageView?.layer?.borderWidth = 0
            }
        }
    }
}
