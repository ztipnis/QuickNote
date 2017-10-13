//
//  openFileModal.swift
//  QuickNote
//
//  Created by Zachary A. Tipnis on 3/12/17.
//  Copyright © 2017 zachal. All rights reserved.
//

import Cocoa

protocol openFileModalDelegate {
    func onFileClose(image: NSImage)
}

class openFileModal: NSViewController {
    @IBOutlet weak var photoCollection: NSCollectionView!
    @IBOutlet weak var downloadCollection: NSCollectionView!
    @IBOutlet weak var fileText: NSTextField!
    var delegate: openFileModalDelegate?
    var imageFile = NSImage()
    var imageDirectoryLoader = ImageDirectoryLoader.init()
    var initialFolderUrl = URL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.picturesDirectory, .userDomainMask, true)[0], isDirectory: true).resolvingSymlinksInPath()
    var imageDirectoryLoader2 = ImageDirectoryLoader.init()
    var initialFolderUrl2 = URL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.downloadsDirectory, .userDomainMask, true)[0], isDirectory: true).resolvingSymlinksInPath()
    @IBAction func openButtonPress(_ sender: Any) {
        
        let dialog = NSOpenPanel()
        dialog.title = "Choose a Photo"
        dialog.showsResizeIndicator = true
        dialog.showsHiddenFiles = false
        dialog.canChooseDirectories = false
        dialog.canCreateDirectories = true
        dialog.canChooseFiles = true
        dialog.resolvesAliases = true
        dialog.allowsMultipleSelection = false
        dialog.allowedFileTypes = ["jpg", "JPG", "JPEG", "jpeg", "Jpg", "Jpeg", "png", "PNG", "Png", "gif", "GIF", "Gif", "bmp", "BMP", "Bmp"]
        
        if(dialog.runModal() == NSModalResponseOK){
            let result = dialog.url
            fileText.stringValue = result!.path
            imageFile = NSImage(contentsOf: result!)!
        }
        
    }
    @IBAction func okAction(_ sender: Any) {
        delegate?.onFileClose(image: imageFile)
        self.dismiss(nil)
    }
    @IBAction func cancelAction(_ sender: Any) {
        self.dismiss(nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        fileText.isEditable = false
        let flowlayout = photoCollection.collectionViewLayout as! NSCollectionViewFlowLayout
        flowlayout.itemSize = NSSize(width: 150, height: 150)
        photoCollection.collectionViewLayout = flowlayout
        photoCollection.register(photoCollectionItem.self, forItemWithIdentifier: "PicturesViewItem")
        photoCollection.register(NSNib(nibNamed: "photoCollectionItem", bundle: Bundle.main), forItemWithIdentifier: "PicturesViewItem")
        downloadCollection.collectionViewLayout = flowlayout
        downloadCollection.register(photoCollectionItem.self, forItemWithIdentifier: "DownloadsViewItem")
        downloadCollection.register(NSNib(nibNamed: "photoCollectionItem", bundle: Bundle.main), forItemWithIdentifier: "DownloadsViewItem")
        imageDirectoryLoader.loadDataForFolderWithUrl(initialFolderUrl)
        imageDirectoryLoader2.loadDataForFolderWithUrl(initialFolderUrl2)
    }
    
}

extension openFileModal: NSCollectionViewDataSource{
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        
        switch collectionView {
            case photoCollection:
                return imageDirectoryLoader.numberOfItemsInSection(section)
            case downloadCollection:
                return imageDirectoryLoader2.numberOfItemsInSection(section)
            default:
                return 1
        }
    }
    func numberOfSections(in collectionView: NSCollectionView) -> Int {
        return 1
    }
    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        switch collectionView {
            case photoCollection:
                let item = collectionView.makeItem(withIdentifier: "PicturesViewItem", for: indexPath)
                guard let collectionViewItem = item as? photoCollectionItem else {return item}
                let imageFile = imageDirectoryLoader.imageFileForIndexPath(indexPath)
                collectionViewItem.imageFile = imageFile
                return collectionViewItem
            case downloadCollection:
                let item = collectionView.makeItem(withIdentifier: "DownloadsViewItem", for: indexPath)
                guard let collectionViewItem = item as? photoCollectionItem else {return item}
                let imageFile = imageDirectoryLoader2.imageFileForIndexPath(indexPath)
                collectionViewItem.imageFile = imageFile
                return collectionViewItem
            default:
                return NSCollectionViewItem()
        }
    }
}

extension openFileModal: NSCollectionViewDelegate {
    
    func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {
        //NSLog("Selected")
        for indexPath in indexPaths {
            switch collectionView {
            case photoCollection:
                let image = imageDirectoryLoader.imageFileForIndexPath(indexPath)
                fileText.stringValue = image.fileName.path
                imageFile = NSImage(contentsOf: image.fileName)!
            case downloadCollection:
                let image = imageDirectoryLoader2.imageFileForIndexPath(indexPath)
                fileText.stringValue = image.fileName.path
                imageFile = NSImage(contentsOf: image.fileName)!
                
            default:
                break
            }

        }
        collectionView.deselectAll(collectionView)
    }
}
extension openFileModal: NSTextFieldDelegate {
    override func controlTextDidChange(_ obj: Notification) {
        photoCollection.deselectAll(nil)
        downloadCollection.deselectAll(nil)
    }
}
    
