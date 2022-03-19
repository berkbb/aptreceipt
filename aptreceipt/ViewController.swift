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
    @IBOutlet weak var Info_TextControl: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
       

       

        // Do any additional setup after loading the view.
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    /// Clear button click  event.
    @IBAction func Clear_Click(_ sender: NSButton) {
        HomeHumber_Selector.selectItem(at: 0)
        DatePicker_Receipt.dateValue=Date()
        Total_TextControl.stringValue=""
        SeqNumber_textControl.stringValue=""
        SupplierName_textControl.stringValue="Mustafa Cem Babadoğan"
        OwnerName_textControl.stringValue=""
        Info_TextControl.stringValue="";
        
     
        
    }
   
    /// Create button click  event.
    @IBAction func Create_Click(_ sender: NSButton) {
        
        
        
        let selectedApartment=HomeHumber_Selector.selectedItem?.title
        print("Apartment number: \(selectedApartment!)")
        let issueDate=getDatewithMonthDate(sentDate: DatePicker_Receipt.dateValue)
        if !issueDate.isEmpty {
            print("Issue Date: \(issueDate)")
        }
  
        let seqNumber=SeqNumber_textControl.stringValue
        if !seqNumber.isEmpty {
            print("Sequence Number \(seqNumber)")
        }
    
      
        let supplierName=SupplierName_textControl.stringValue.localizedCapitalized
        if !supplierName.isEmpty {
            print("Supplier Name: \(supplierName)")
        }
       
        let ownerName=OwnerName_textControl.stringValue.localizedCapitalized
        if !ownerName.isEmpty {
            print("Owner Name: \(ownerName)")
        }
        let total=Total_TextControl.stringValue
         if !total.isEmpty {
             print("Total: \(total)")
         }
       
     
        var info=Info_TextControl.stringValue;
        if !info.isEmpty {
            print("Info: \(info)")
        }
        else
        {
            info=" "
        }
        
        let doubleTotal = Double(total)
        
        let intSequence = Int(seqNumber)
        
        if( !selectedApartment!.isEmpty  && !seqNumber.isEmpty && !total.isEmpty && !supplierName.isEmpty && !ownerName.isEmpty && !issueDate.isEmpty && !info.isEmpty && doubleTotal != nil && intSequence != nil )
        {
            print("OK")
       
        
           let vc = self.storyboard?.instantiateController(withIdentifier: "ReceiptView") as? ReceiptViewController
           
            vc?.issuer=supplierName
            vc?.recevier=ownerName
            vc?.notes=info
            vc?.monthYear=issueDate
            vc?.aptNumber=Int(selectedApartment!)!
            vc?.price=Double(total)!
            vc?.seqNumber=Int(seqNumber)!
            vc?.currentDate=getDatewithDayMonthYear(sentDate: Date())
            
          if let controller = vc {self.view.window?.contentViewController=controller}
            
            
        }
        else
        {
            print("Error - Check areas!")
            
            let answer = showDialog(title: localizedString(forKey: "errorTitle"), text: localizedString(forKey: "errorMessage"), buttonName: localizedString(forKey: "okText"), alertType: .warning)
            
            print(answer)
        }
       
    }
    
    /// Get month and year from Date from given 'sentDate'
    ///
    /// - Warning: The returned string is  localized.
    /// - Parameter subject: The subject  is Date object.
    /// - Returns: A date string to the `sentDate` like XXXX YYYY.
    func getDatewithMonthDate(sentDate:Date) -> String
    {
        let dateFormatter1 = DateFormatter()
        dateFormatter1.dateFormat = "yyyy"
        let yearString = dateFormatter1.string(from: sentDate)
        let dateFormatter2 = DateFormatter()
        dateFormatter2.dateFormat = "MMMM"
        let monthString = dateFormatter2.string(from: sentDate)
        let returnValue = "\(monthString) \(yearString)"
        
      
        return returnValue
    }
    
    // Get day, month and year from Date from given 'sentDate'
    ///
    /// - Warning: The returned string is  localized.
    /// - Parameter subject: The subject  is Date object.
    /// - Returns: A date string to the `sentDate` like XXXX YYYY.
    func getDatewithDayMonthYear(sentDate:Date) -> String
    {
        let dateFormatter1 = DateFormatter()
        dateFormatter1.dateFormat = "yyyy"
        let yearString = dateFormatter1.string(from: sentDate)
        let dateFormatter2 = DateFormatter()
        dateFormatter2.dateFormat = "MMMM"
        let monthString = dateFormatter2.string(from: sentDate)
        
        let dateFormatter3 = DateFormatter()
        dateFormatter3.dateFormat = "dd"
        let dayString = dateFormatter3.string(from: sentDate)
      
        var returnValue=""
        let locale =  Locale.current.languageCode
        if locale!.contains("tr") {
             returnValue = "\(dayString) \(monthString) \(yearString)"
        }
        else
        {
             returnValue = "\(monthString) \(dayString), \(yearString)"
        }
      
        return returnValue
    }
    
    
    /// Prints OK Cancel Dialog
    ///
    /// - Warning: The returned alert is  localized.
    /// - Parameter title: The title  is String object.
    /// - Parameter text: The text  is String object.
    /// - Parameter alertType: The text  is NSAlert.Style object.
    /// - Parameter buttonName: The text  is String object.
    /// - Returns: boolean.
    
    func showDialog(title: String, text: String, buttonName:String, alertType: NSAlert.Style ) -> Bool {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = text
        alert.alertStyle = alertType
        alert.addButton(withTitle: buttonName)
     
        return alert.runModal() == .alertFirstButtonReturn
    }
    
    
    /// Retuns value of translated key.
    ///
    /// - Warning: The returned String is  localized.
    /// - Parameter forKey: The forKey  is String object.
    /// - Returns: bStringoolean.
    
    
    func localizedString(forKey key: String) -> String {
        var result = Bundle.main.localizedString(forKey: key, value: nil, table: nil)

        if result == key {
            result = Bundle.main.localizedString(forKey: key, value: nil, table: "File")
        }

        return result
    }
}


