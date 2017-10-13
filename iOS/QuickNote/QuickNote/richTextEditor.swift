//
//  richTextEditor.swift
//  QuickNote
//
//  Created by Zachary A. Tipnis on 3/16/17.
//  Copyright © 2017 zachal. All rights reserved.
//

import UIKit
import FontAwesome

class richTextEditor: UITextView {

    var fontNames = UIFont.familyNames
    var sections:[[String]] = [[]]
    var currentFont:(font: String, size: Int) = ("System", 9)
    let toolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 50))
    let picker = UIPickerView()
    let imagePicker = UIImagePickerController()
    let colorChanger = CPViewController(nibName: "CPViewController", bundle: Bundle.main)
    var intersectheight:CGFloat = 1.0
    public func resizeImagesToFit(){
        let mutableString = NSMutableAttributedString(attributedString: self.attributedText)
        let attributedString = mutableString
        let range = NSMakeRange(0, attributedString.length)
        attributedString.enumerateAttributes(in: range, options: NSAttributedString.EnumerationOptions(rawValue: 0)) { (object, range, stop) in

            if object.keys.contains(NSAttachmentAttributeName) {
                if let attachment = object[NSAttachmentAttributeName] as? NSTextAttachment {
                    if let image = attachment.image {
                        let oldWidth = image.size.width
                        let scaleFactor = oldWidth / (self.frame.width - 15)
                        attachment.image = UIImage(cgImage: image.cgImage!, scale: scaleFactor, orientation: UIImageOrientation.up)
                        let aString = NSAttributedString(attachment: attachment)
                        mutableString.replaceCharacters(in: range, with: aString)
                    }else if let image = attachment.image(forBounds: attachment.bounds, textContainer: nil, characterIndex: range.location) {
                        let oldWidth = image.size.width
                        let scaleFactor = oldWidth / (self.frame.width - 15)
                        attachment.image = UIImage(cgImage: image.cgImage!, scale: scaleFactor, orientation: UIImageOrientation.up)
                        let aString = NSAttributedString(attachment: attachment)
                        mutableString.replaceCharacters(in: range, with: aString)
                    }
                }
            }
        }
        self.attributedText = mutableString
    }

    func editBegin(){
        print("hi")
        self.dataDetectorTypes = UIDataDetectorTypes.init(rawValue: 0)
        self.isEditable = true
        self.becomeFirstResponder()
    }
    func editOver(){
        self.isEditable = false
        self.dataDetectorTypes = .all
    }

    func setup(){
        let tap = UITapGestureRecognizer(target: self, action: #selector(richTextEditor.editBegin))
        self.addGestureRecognizer(tap)
        NotificationCenter.default.addObserver(self, selector: #selector(richTextEditor.editOver), name: NSNotification.Name.UITextViewTextDidEndEditing, object: self)
        let menuController = UIMenuController.shared
        let fontItem = UIMenuItem(title: "Font", action: #selector(richTextEditor.changeFont))
        let colorItem = UIMenuItem(title: "Color", action: #selector(richTextEditor.changeColor))
        let photoItem = UIMenuItem(title: "Photo", action: #selector(richTextEditor.insertPhoto))
        let cameraItem = UIMenuItem(title: "Camera", action: #selector(richTextEditor.insertCamera))
        
        imagePicker.delegate = self
        if UIImagePickerController.isSourceTypeAvailable(.camera) {menuController.menuItems = [fontItem, colorItem, photoItem, cameraItem]}else{menuController.menuItems = [fontItem, colorItem, photoItem]}
        self.allowsEditingTextAttributes = true
        fontNames.insert("Default", at: 0)
        sections.append(fontNames)
        var numStrArray:[String] = []
        let numArr = [9,10,11,12,13,14,18,24,36,48]
        for i in numArr {
            numStrArray.append(String(i))
        }
        sections.append(numStrArray)
        toolbar.barStyle = .default
        self.inputAccessoryView = toolbar
        toolbar.sizeToFit()

    }


    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        setup()
    }

    required  init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    func insertPhoto() {
        imagePicker.allowsEditing = false
        imagePicker.sourceType = .photoLibrary
        imagePicker.mediaTypes = UIImagePickerController.availableMediaTypes(for: .photoLibrary)!
        imagePicker.modalPresentationStyle = .popover
        imagePicker.setEditing(true, animated: true)
        //imagePicker.showsCameraControls = true
        imagePicker.preferredContentSize = CGSize(width: 200, height: 150)
        //imagePicker.cameraCaptureMode = .photo

        let ctrlr = self.superview?.next as! UIViewController
        ctrlr.present(imagePicker, animated: true, completion: nil)
    }

    func insertCamera() {
        imagePicker.allowsEditing = false
        imagePicker.sourceType = .camera
        imagePicker.mediaTypes = UIImagePickerController.availableMediaTypes(for: .camera)!
        imagePicker.modalPresentationStyle = .popover
        imagePicker.setEditing(true, animated: true)
        //imagePicker.showsCameraControls = true
        imagePicker.preferredContentSize = CGSize(width: 200, height: 150)
        //imagePicker.cameraCaptureMode = .photo

        let ctrlr = self.superview?.next as! UIViewController
        ctrlr.present(imagePicker, animated: true, completion: nil)

    }

    func changeColor() {
        let item1 = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(richTextEditor.setColor))
        self.inputView = colorChanger.view
        toolbar.setItems([item1], animated: true)
        self.reloadInputViews()
    }

    func setColor() {
        self.inputView = nil
        undoManager?.registerUndo(withTarget: self, selector: #selector(richTextEditor.setColor), object: self.textColor)
        undoManager?.registerUndo(withTarget: self, selector: #selector(richTextEditor.setColor), object: self.attributedText)
        undoManager?.setActionName("Change Color")
        let range = self.selectedRange
        let newTextColor = colorChanger.uiColorFromHex(rgbValue: colorChanger.colorArray[Int(colorChanger.slider.value)])
        if range.length > 0 {
            let stringVal = NSMutableAttributedString(attributedString: self.attributedText)
            let attributes = [NSForegroundColorAttributeName: newTextColor]
            stringVal.addAttributes(attributes, range: range)
            self.attributedText = stringVal
            self.selectedRange = range
        }else{
            self.textColor = newTextColor
        }
        toolbar.setItems([], animated: true)
        self.reloadInputViews()

    }

    func changeFont() {
            let item1 = UIBarButtonItem(title: "Font", style: .plain, target: self, action: #selector(richTextEditor.setFont))
            picker.delegate = self
            picker.dataSource = self
            self.inputView = picker
            self.reloadInputViews()
            item1.title = "Done"
            toolbar.setItems([item1], animated: true)
    }

    func setFont(){
        self.inputView = nil
        //print(currentFont)
        //self.font = UIFont(name: currentFont.font, size: CGFloat(currentFont.size))
        var toFont:UIFont?
        print(currentFont.font)
        if currentFont.font == "System" {
            toFont = UIFont.systemFont(ofSize: CGFloat(currentFont.size))
        }else{
            toFont = UIFont(name: currentFont.font, size: CGFloat(currentFont.size))
        }
        let range = self.selectedRange
        if range.length > 0 {
            let stringVal = NSMutableAttributedString(attributedString: self.attributedText)
            let attributes:[String:Any] = [NSFontAttributeName: (toFont as Any)]
            stringVal.addAttributes(attributes, range: range)
            self.attributedText = stringVal
            self.selectedRange = range
        }else{
            self.font = toFont
        }
        toolbar.setItems([], animated: true)
        self.reloadInputViews()
    }

}
class CPViewController: UIViewController {

    // RRGGBB hex colors in the same order as the image
    let colorArray = [ 0x000000, 0x262626, 0x4d4d4d, 0x666666, 0x808080, 0x990000, 0xcc0000, 0xfe0000, 0xff5757, 0xffabab, 0xffabab, 0xffa757, 0xff7900, 0xcc6100, 0x994900, 0x996f00, 0xcc9400, 0xffb900, 0xffd157, 0xffe8ab, 0xfff4ab, 0xffe957, 0xffde00, 0xccb200, 0x998500, 0x979900, 0xcacc00, 0xfcff00, 0xfdff57, 0xfeffab, 0xf0ffab, 0xe1ff57, 0xd2ff00, 0xa8cc00, 0x7e9900, 0x038001, 0x04a101, 0x05c001, 0x44bf41, 0x81bf80, 0x81c0b8, 0x41c0af, 0x00c0a7, 0x00a18c, 0x00806f, 0x040099, 0x0500cc, 0x0600ff, 0x5b57ff, 0xadabff, 0xd8abff, 0xb157ff, 0x6700bf, 0x5700a1, 0x450080, 0x630080, 0x7d00a1, 0x9500c0, 0xa341bf, 0xb180bf, 0xbf80b2, 0xbf41a6, 0xbf0199, 0xa10181, 0x800166, 0x999999, 0xb3b3b3, 0xcccccc, 0xe6e6e6, 0xffffff]

    @IBOutlet weak var selectedColorView: UIView!
    @IBOutlet weak var slider: UISlider!
    @IBAction func sliderChanged(sender: AnyObject) {
        selectedColorView.backgroundColor = uiColorFromHex(rgbValue: colorArray[Int(slider.value)])
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        print(colorArray.count)
        slider.maximumValue = 69.5
    }
    func uiColorFromHex(rgbValue: Int) -> UIColor {
        let red =   CGFloat((rgbValue & 0xFF0000) >> 16) / 0xFF
        let green = CGFloat((rgbValue & 0x00FF00) >> 8) / 0xFF
        let blue =  CGFloat(rgbValue & 0x0000FF) / 0xFF
        let alpha = CGFloat(1.0)

        return UIColor(red: red, green: green, blue: blue, alpha: alpha)
    }
}

extension richTextEditor:UIPickerViewDelegate {

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return sections[component][row]
    }
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        //print(component)
        switch component {
        case 1:
            print(row)
            switch row{
            case 0:
                currentFont.font = "System"
            default:
                currentFont.font = sections[component][row]
            }

        case 2:
            currentFont.size = Int(sections[component][row]) ?? 12
        default:
            break
        }
    }
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        let pickerLabel = UILabel()
        let title = sections[component][row]
        pickerLabel.text = title
        return pickerLabel
    }

}

extension richTextEditor:UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return sections.count
    }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return sections[component].count
    }
}

extension richTextEditor:UIImagePickerControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        let image = (info[UIImagePickerControllerOriginalImage] as! UIImage)
        let oldWidth = image.size.width
        let scaleFactor = oldWidth / (self.frame.width - 15)
        let attachment = NSTextAttachment()
        attachment.image = UIImage(cgImage: image.cgImage!, scale: scaleFactor, orientation: UIImageOrientation.up)
        let aString = NSAttributedString(attachment: attachment)
        let mstring = NSMutableAttributedString(attributedString: self.attributedText)
        mstring.replaceCharacters(in: self.selectedRange, with: aString)
        self.attributedText = mstring
        picker.dismiss(animated: true, completion: nil)
    }
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}

extension richTextEditor:UINavigationControllerDelegate {

}
