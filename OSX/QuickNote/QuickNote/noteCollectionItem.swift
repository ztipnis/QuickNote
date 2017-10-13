//
//  noteCollectionItem.swift
//  QuickNote
//
//  Created by Zachary A. Tipnis on 3/11/17.
//  Copyright © 2017 zachal. All rights reserved.
//

import Cocoa

class noteCollectionItem: NSCollectionViewItem {

    @IBOutlet weak var descriptionField: NSTextField!
    @IBOutlet weak var titleField: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.wantsLayer = true
        //view.layer?.backgroundColor = NSColor.white.cgColor
        view.layer?.backgroundColor = NSColor.init(white: 1, alpha: 0.6).cgColor
        view.layer?.borderColor = NSColor.black.cgColor
        view.layer?.borderWidth = 1
        view.layer?.cornerRadius = 3
        titleField.layer?.backgroundColor = NSColor.clear.cgColor
        titleField.isBordered = false
        titleField.focusRingType = .none
        titleField.bezelStyle = .squareBezel
        titleField.isBezeled = false
        titleField.drawsBackground = false
        titleField.backgroundColor = NSColor.clear
        // Do view setup here.
    }
    override var isSelected: Bool {
        didSet{
            //NSLog("Selection changed")
            titleField.isEnabled = isSelected
            
            if (isSelected){
                view.layer?.backgroundColor = NSColor.lightGray.withAlphaComponent(0.6).cgColor
            }else{
                view.layer?.backgroundColor = NSColor.init(white: 1, alpha: 0.6).cgColor
            }
        }
    }
    
}
