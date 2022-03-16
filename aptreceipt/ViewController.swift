//
//  ViewController.swift
//  aptreceipt
//
//  Created by Berk Babadoğan on 16.03.2022.
//

import Cocoa

class ViewController: NSViewController {

 
    @IBOutlet weak var HomeHumber_Selector: NSPopUpButton!
    @IBOutlet weak var DatePicker_Receipt: NSDatePicker!
    @IBOutlet weak var SupplierName_textControl: NSTextField!
    @IBOutlet weak var OwnerName_textControl: NSTextField!
    @IBOutlet weak var SeqNumber_textControl: NSTextField!
    @IBOutlet weak var Total_TextControl: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    @IBAction func Clear_Click(_ sender: NSButton) {
        HomeHumber_Selector.selectItem(at: 0)
        DatePicker_Receipt.dateValue=Date()
        Total_TextControl.stringValue=""
        SeqNumber_textControl.stringValue=""
        SupplierName_textControl.stringValue="Mustafa Cem Babadoğan"
        OwnerName_textControl.stringValue=""
     
        
    }
    
    @IBAction func Create_Click(_ sender: NSButton) {
    }
}

