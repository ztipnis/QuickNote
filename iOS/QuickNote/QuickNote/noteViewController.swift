//
//  NoteViewViewController.swift
//  QuickNote
//
//  Created by Zachary A. Tipnis on 3/13/17.
//  Copyright © 2017 zachal. All rights reserved.
//

import UIKit
import slideOutMenu
import YapDatabase
import FontAwesome

class noteViewController: UIViewController {

    var VC2 = lrSlideMenu()
    var dim = UIView()
    var selectedIndex:Int?
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    var inConstraint = NSLayoutConstraint()
    var outConstraint = NSLayoutConstraint()
    let navigationEditTitle = UITextField()
    @IBAction func leftSwipe(_ sender: UISwipeGestureRecognizer) {

        if(VC2.inView){
            self.view.removeConstraint(inConstraint)
            self.view.addConstraint(outConstraint)
            view.setNeedsUpdateConstraints()
            VC2.slide(time: 0.175, delay: 0, options: .curveEaseOut, completion: nil)
            UIView.animate(withDuration: 0.175, animations: {self.dim.alpha = 0
            self.view.layoutIfNeeded()}, completion: {complete in
                self.dim.isHidden = true})

        }

    }

    @IBAction func rightSwipe(_ sender: UISwipeGestureRecognizer) {
        if(!VC2.inView){
            self.view.removeConstraint(outConstraint)
            self.view.addConstraint(inConstraint)
            navigationEditTitle.endEditing(true)
            mainEditor.endEditing(true)
            view.setNeedsUpdateConstraints()
            VC2.slide(time: 0.175, delay: 0, options: .curveEaseOut, completion: nil)
            dim.alpha = 0
            dim.isHidden = false
            UIView.animate(withDuration: 0.175, animations: {
                self.view.layoutIfNeeded()
                self.dim.alpha = 0.40})

        }

    }
    @IBOutlet weak var mainEditor: richTextEditor!

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        VC2.resetViewToZ()
    }

    func rotated(){
        print(UIDevice.current.orientation)
        VC2.resetViewToZ()
        self.view.layoutIfNeeded()
    }

    func titleDidChange(){
        self.title = navigationEditTitle.text
        if(self.VC2.selected() != nil){
            appDelegate.notes[self.VC2.selected()?.item ?? -1].setTitle(to: navigationEditTitle.text!)
        }
        VC2.reloadTable()
    }


    override func viewDidLoad() {
        super.viewDidLoad()
        navigationEditTitle.translatesAutoresizingMaskIntoConstraints = false
        navigationEditTitle.textAlignment = .center
        NotificationCenter.default.addObserver(self, selector: #selector(noteViewController.rotated), name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
        dim = UIView(frame: view.frame)
        dim.translatesAutoresizingMaskIntoConstraints = false
        let top = NSLayoutConstraint(item: dim, attribute: .top, relatedBy: .equal, toItem: view, attribute: .top, multiplier: 1.0, constant: 0.0)
        let trailing = NSLayoutConstraint(item: dim, attribute: .trailing, relatedBy: .equal, toItem: view, attribute: .trailing, multiplier: 1.0, constant: 0.0)
        let bottom = NSLayoutConstraint(item: dim, attribute: .bottom, relatedBy: .equal, toItem: view, attribute: .bottom, multiplier: 1.0, constant: 0.0)
        dim.backgroundColor = UIColor.black
        dim.alpha = 0.40
        view.addSubview(dim)
        dim.isHidden = true
        VC2 = lrSlideMenu(frame: CGRect(x: 0, y: view.frame.minY, width: view.bounds.width/2, height: view.bounds.height))
        let slidewidth = NSLayoutConstraint(item: VC2, attribute: .width, relatedBy: .equal, toItem: dim, attribute: .width, multiplier: 1.0, constant: 0.0)
        let slidewidth2 = NSLayoutConstraint(item: VC2, attribute: .width, relatedBy: .equal, toItem: view, attribute: .width, multiplier: 0.5, constant: 0.0)
        let slidetop = NSLayoutConstraint(item: VC2, attribute: .top, relatedBy: .equal, toItem: view, attribute: .top, multiplier: 1.0, constant: 0.0)
        let slidebottom = NSLayoutConstraint(item: VC2, attribute: .bottom, relatedBy: .equal, toItem: view, attribute: .bottom, multiplier: 1.0, constant: 0.0)
        //VC2.autoresizingMask = UIViewAutoresizing.flexibleWidth
        VC2.inView = true
        VC2.dataSource = self
        VC2.reloadTable()
        VC2.setTitle(to: "Notes:")
        self.title = "New Note"
        let button = UIBarButtonItem(title: String.fontAwesomeIcon(name: .plusCircle), style: .plain, target: nil, action: #selector(noteViewController.newNote))
        let attributes = [NSFontAttributeName: UIFont.fontAwesome(ofSize: 20)] as [String: UIFont]
        button.setTitleTextAttributes(attributes, for: .normal)
        VC2.toolbar().items = [button]
        view.addSubview(VC2)
        VC2.translatesAutoresizingMaskIntoConstraints = false
        VC2.slide(time: 0, delay: 0, options: .curveEaseOut, completion: nil)
        appDelegate.database?.getConnection(type: .main).read({transRead in
            print(transRead)
            for key in transRead.allKeys(inCollection: "Notes") {
                if self.appDelegate.notes.contains(transRead.object(forKey: key, inCollection: "Notes") as! QNNote) {
                    print("duplicate")
                }else{
                    self.appDelegate.notes.append(transRead.object(forKey: key, inCollection: "Notes") as! QNNote)
                }
            }
        })
        self.VC2.reloadTable()
        view.addConstraints([top, trailing, bottom, slidewidth, slidetop, slidebottom, slidewidth2])
        let leading = NSLayoutConstraint(item: dim, attribute: .leading, relatedBy: .equal, toItem: VC2, attribute: .trailing, multiplier: 1.0, constant: 0.0)
        view.addConstraint(leading)
        inConstraint = NSLayoutConstraint(item: VC2, attribute: .leading, relatedBy: .equal, toItem: view, attribute: .leading, multiplier: 1.0, constant: 0.0)
        outConstraint = NSLayoutConstraint(item: VC2, attribute: .trailing, relatedBy: .equal, toItem: view, attribute: .leading, multiplier: 1.0, constant: 0.0)
        view.addConstraint(outConstraint)

        NotificationCenter.default.addObserver(self, selector: #selector(noteViewController.titleDidChange), name: NSNotification.Name.UITextFieldTextDidEndEditing, object: navigationEditTitle)
        appDelegate.noteVC = self
        CKMgr().setup(completion: {
            print("Loaded")
            self.VC2.reloadTable()
        })
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        //self.navigationController?.setNavigationBarHidden(true, animated: false)
        self.navigationItem.titleView = navigationEditTitle
        navigationEditTitle.text = self.title
        VC2.resetViewToZ()
        let tfConst1 = NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[navigationEditTitle]-0-|", options: .alignAllCenterX, metrics: nil, views: ["navigationEditTitle": navigationEditTitle])
        let tfConst2 = NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[navigationEditTitle]-0-|", options: .alignAllCenterY, metrics: nil, views: ["navigationEditTitle": navigationEditTitle])
        NSLayoutConstraint.activate(tfConst1)
        NSLayoutConstraint.activate(tfConst2)
    }

    func saveNote(note: Int){
        appDelegate.saveNote(note: note)
    }


    func loadNote(note: Int){
        self.selectedIndex = note
        //self.mainEditor
        do {
            let attribString = try NSAttributedString(data: appDelegate.notes[note].getRawValues().data, options: [NSDocumentTypeDocumentAttribute:NSRTFDTextDocumentType], documentAttributes: nil)
            self.title = appDelegate.notes[note].getRawValues().title
            self.navigationEditTitle.text = appDelegate.notes[note].getRawValues().title
            self.mainEditor.attributedText = attribString
            self.mainEditor.resizeImagesToFit()
        }catch{
            //print("hi")
        }
    }

    func newNote() {
        self.navigationEditTitle.endEditing(true)
        self.VC2.deselectAll()
        if selectedIndex != nil {
            self.mainEditor.text = ""
            do {
                let attributes = [NSDocumentTypeDocumentAttribute:NSRTFDTextDocumentType]
                let rtfData = try self.mainEditor.attributedText.data(from: NSRange(location: 0, length: self.mainEditor.attributedText.length), documentAttributes: attributes)
                let newNote = QNNote(title: "New Note", description: "", with: rtfData)
                appDelegate.notes.insert(newNote, at: 0)
                selectedIndex = 0
                let at = IndexPath(row: 0, section: 1)
                self.VC2.reloadTable()
                self.VC2.selectRow(at: at)
                self.loadNote(note: at.item)

            }catch let error{
                print(error)
            }
        }else{
            let attributes = [NSDocumentTypeDocumentAttribute:NSRTFDTextDocumentType]
            do {
                let rtfData = try mainEditor.attributedText.data(from: NSRange(location: 0, length: mainEditor.attributedText.length), documentAttributes: attributes)
                let newNote = QNNote(title: self.title ?? "New Note", description: mainEditor.textStorage.string, with: rtfData)
                appDelegate.notes.insert(newNote, at: 0)
                selectedIndex = 0
                let at = IndexPath(row: 0, section: 1)
                self.VC2.reloadTable()
                self.VC2.selectRow(at: at)
                self.loadNote(note: at.item)
            }catch {
                //print("hi: \(error)")
            }

        }
        VC2.slide(time: 0.1, delay: 0.25, options: .curveEaseInOut, completion: nil)

        UIView.animate(withDuration: 0.35, animations: {self.dim.alpha = 0}, completion: {complete in
            self.dim.isHidden = true})
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
       //e self.navigationController?.setNavigationBarHidden(false, animated: true)
        //self.VC2.deselectAll()
        self.navigationItem.titleView = nil
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        //VC2.deselectAll()
    }

    

}

extension noteViewController:UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        let minX = VC2.frame.maxX - 15
        let maxX = VC2.frame.maxX + 15
        if (minX <= touch.location(in: self.view).x && maxX >= touch.location(in: self.view).x){
            return true
        }
        return false
    }
}

extension noteViewController:ADsource {
    func saveAll(){

        VC2.deselectAll()
        mainEditor.text = ""
    }
    func loadAll(){
        appDelegate.database?.getConnection(type: .main).read({transRead in
            print(transRead)
            for key in transRead.allKeys(inCollection: "Notes") {
                if self.appDelegate.notes.contains(transRead.object(forKey: key, inCollection: "Notes") as! QNNote) {
                    print("duplicate")
                }else{
                    self.appDelegate.notes.append(transRead.object(forKey: key, inCollection: "Notes") as! QNNote)
                }
            }
        })
    }
    func reload() {
        VC2.reloadTable()
    }
}

extension noteViewController:slideOutMenuDataSource {

    func menuItems() -> [[menuItem]] {

        var noteList = [menuItem]()

        for note in appDelegate.notes {
            let item = menuItem(title: note.getRawValues().title, selection: { (indexPath: IndexPath) in
                self.loadNote(note: indexPath.item)
                self.VC2.slide(time: 0.1, delay: 0, options: .curveEaseInOut, completion: nil)
                UIView.animate(withDuration: 0.1, animations: {self.dim.alpha = 0}, completion: {complete in
                    self.dim.isHidden = true})
                //self.VC2.deselectAll()
            }, deselection: { (indexPath: IndexPath) in
                //print(indexPath)
                do {
                    let attributes = [NSDocumentTypeDocumentAttribute:NSRTFDTextDocumentType]
                    let rtfData = try self.mainEditor.attributedText.data(from: NSRange(location: 0, length: self.mainEditor.attributedText.length), documentAttributes: attributes)
                    //print("deselect")
                    self.appDelegate.notes[indexPath.item].setContent(to: rtfData)
                    self.appDelegate.notes[indexPath.item].setTitle(to: self.title ?? "")
                    self.appDelegate.notes[indexPath.item].setDescription(to: self.mainEditor.text)
                    self.saveNote(note: indexPath.item)
                    self.mainEditor.text = ""
                }catch let error{
                    print(error)
                }

            }, deletion: { (indexPath: IndexPath) in
                self.appDelegate.database?.getConnection(type: .main).readWrite({ transaction in
                    transaction.removeObject(forKey: self.appDelegate.notes[indexPath.item].uuid.uuidString, inCollection: "Notes")
                })
                    self.appDelegate.notes.remove(at: indexPath.item)
                    self.VC2.deselectAll()
            })
            noteList.append(item)
        }
        return [[menuItem(title: "Send Photo to Mac", selection: { _ in
            DispatchQueue.main.async {
                self.performSegue(withIdentifier: "sendPhoto", sender: self)
            }
        }, deselection: { (indexPath: IndexPath) in})], noteList]
    }
}
