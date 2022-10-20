//
//  ViewController.swift
//  aptreceipt
//
//  Created by berkbb on 16.03.2022.
//

import Cocoa

class ViewController: NSViewController {

    //Outlets
 
    @IBOutlet weak var HomeHumber_Selector: NSPopUpButton!
    @IBOutlet weak var DatePicker_Receipt: NSDatePicker!
    @IBOutlet weak var SupplierName_textControl: NSTextField!
    @IBOutlet weak var OwnerName_textControl: NSTextField!
    @IBOutlet weak var SeqNumber_textControl: NSTextField!
    @IBOutlet weak var Total_TextControl: NSTextField!
    @IBOutlet weak var Info_TextControl: NSTextField!
    
    @IBOutlet weak var AptONOFFSwitch: NSSwitch!
    @IBOutlet weak var AptONOFFLabel: NSTextField!
    @IBOutlet weak var Income_Check: NSButton!
    
    @IBOutlet weak var Outcome_Check: NSButton!
    //
    
    private(set) var popUpInitiallySelectedItem: NSMenuItem?
    
    // /Load function
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Load settings from User Defaults
        
        let seqNumber = UserDefaults.standard.string(forKey: "seqNumber")
         if(seqNumber != nil)
        {
             SeqNumber_textControl.stringValue=seqNumber!
         }
        else
        {
            SeqNumber_textControl.stringValue="1"
        }
        
        let flatCount = UserDefaults.standard.string(forKey: "flatcount")
        if(flatCount != nil)
        {
            for i in 1..<Int(flatCount!)!+1 // For 8 apartment home.
            {
                HomeHumber_Selector.addItem(withTitle: String(i))
                
             
                
                
            }
        }
        
        else
        {
            HomeHumber_Selector.addItem(withTitle: "1")
        }
        
        HomeHumber_Selector.selectItem(at: 0)
        let homeOwner = UserDefaults.standard.string(forKey: "homeowner_1")
        
       
            if(homeOwner != nil)
            {
                
                OwnerName_textControl.stringValue=homeOwner!.localizedCapitalized
            }
      
       
        
     
        let defpay = UserDefaults.standard.string(forKey: "defaultpay")
        if(defpay != nil)
        {
            Total_TextControl.stringValue=defpay!
        }
        
       
        
      
       
        let issuerName = UserDefaults.standard.string(forKey: "issuer")
        if(issuerName != nil)
        {
            SupplierName_textControl.stringValue=issuerName!
        }
     
        // Do any additional setup after loading the view.
        
        
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
        
        
    }
    /// Apartment ON / OFF Switch changed event.
    @IBAction func AptONFOFFSwitchChanged(_ sender: Any) {
        
        if(AptONOFFSwitch.state==NSControl.StateValue.on)
        {
            print("on")
            let value = localizedString(forKey: "switchON")
       
                AptONOFFLabel.stringValue=value
            
         
            
        }
        
        else
        {
            print("off")
            let value = localizedString(forKey: "switchOFF")
          
                AptONOFFLabel.stringValue=value
            
            
        }
    }
    /// Apartment number popup button selection changed event.
    @IBAction func NumberSelectorChanged(_ sender: Any) {
        
        let selected=Int(HomeHumber_Selector.selectedItem!.title)
        print("Selected apartment number: \(selected!)")
        let homeOwner = UserDefaults.standard.string(forKey: "homeowner_\(selected!)")
        
            if(homeOwner != nil)
            {
                
                OwnerName_textControl.stringValue=homeOwner!.localizedCapitalized
            }
      
       
    }
    
    /// Income button checked event.
    @IBAction func IncomeSelected(_ sender: Any) {
        if(Outcome_Check.state == NSControl.StateValue.on)
        {
            Outcome_Check.state=NSControl.StateValue.off
        }
    }
    /// Outcome button checked event.
    @IBAction func OutComeSelected(_ sender: Any) {
        
        if(Income_Check.state == NSControl.StateValue.on)
        {
            Income_Check.state=NSControl.StateValue.off
        }
    }
    /// Clear button click  event.
    @IBAction func Clear_Click(_ sender: NSButton) {
        let seqNumber = UserDefaults.standard.string(forKey: "seqNumber")
         if(seqNumber != nil)
        {
             SeqNumber_textControl.stringValue=seqNumber!
         }
        else
        {
            SeqNumber_textControl.stringValue="1"
        }
        
        HomeHumber_Selector.selectItem(at: 0)
        let homeOwner = UserDefaults.standard.string(forKey: "homeowner_1")
        
       
            if(homeOwner != nil)
            {
                
                OwnerName_textControl.stringValue=homeOwner!.localizedCapitalized
            }
      
        DatePicker_Receipt.dateValue=Date()
        let issuerName = UserDefaults.standard.string(forKey: "issuer")
        if(issuerName != nil)
        {
            SupplierName_textControl.stringValue=issuerName!
        }
        
        Info_TextControl.stringValue=""
        AptONOFFSwitch.state=NSControl.StateValue.on
        let value = localizedString(forKey: "switchON")
   
            AptONOFFLabel.stringValue=value
        Outcome_Check.state=NSControl.StateValue.off
        Income_Check.state=NSControl.StateValue.on
        
           let defpay = UserDefaults.standard.string(forKey: "defaultpay")
           if(defpay != nil)
           {
               Total_TextControl.stringValue=defpay!
           }
     
        
    }
   
    /// Create button click  event.
    @IBAction func Create_Click(_ sender: NSButton) {
        
        
        
        let selectedApartment=HomeHumber_Selector.selectedItem?.title
        print("Apartment number: \(selectedApartment!)")
        let issueDate=DatePicker_Receipt.dateValue.getDatewithMonthandYear()
        if !issueDate.isEmpty {
            print("Issue Date: \(issueDate)")
        }
        
        
  
        let seqNumber=SeqNumber_textControl.stringValue
        if !seqNumber.isEmpty {
            print("Sequence Number: \(seqNumber)")
            let seqNumber2 = UserDefaults.standard.string(forKey: "seqNumber")
             if(seqNumber2 != nil)
            {
                 let y = Int(seqNumber2!)!+1
                 let t = String(y)
                UserDefaults.standard.set(t, forKey: "seqNumber")
             }
            else
            {
               
                UserDefaults.standard.set(2, forKey: "seqNumber")
            }
        }
    
        
      
        let issuerName=SupplierName_textControl.stringValue.localizedCapitalized
        if !issuerName.isEmpty {
            print("Issuer Name: \(issuerName)")
        }
       
        let ownerName=OwnerName_textControl.stringValue.localizedCapitalized
        if !ownerName.isEmpty {
            print("Owner Name: \(ownerName)")
        }
        let total=Total_TextControl.stringValue
         if !total.isEmpty {
             print("Total: \(total)")
         }
       
     
        var info=Info_TextControl.stringValue
        if !info.isEmpty {
            print("Info: \(info)")
        }
        else
        {
            info=" "
        }
        
        let doubleTotal = Double(total)
        
        let intSequence = Int(seqNumber)
        
        if( !selectedApartment!.isEmpty  && !seqNumber.isEmpty && !total.isEmpty && !issuerName.isEmpty && !ownerName.isEmpty && !issueDate.isEmpty && !info.isEmpty && doubleTotal != nil && intSequence != nil )
        {
            print("OK")
       
        // Create receipt.
           let vc = self.storyboard?.instantiateController(withIdentifier: "ReceiptView") as? ReceiptViewController
           
            vc?.issuer=issuerName
            vc?.recevier=ownerName
            vc?.notes=info
            vc?.monthYear=issueDate
            vc?.aptNumber=Int(selectedApartment!)!
            vc?.price=Double(total)!
            vc?.seqNumber=Int(seqNumber)!
            vc?.currentDate=Date().getDatewithDayMonthandYear()
            vc?.printAptNumber = AptONOFFSwitch.state == NSControl.StateValue.on ? true : false
            vc?.recType = Income_Check.state == NSControl.StateValue.on ? receiptType.income : receiptType.outcome
            
          if let controller = vc {self.view.window?.contentViewController=controller}
            
            
        }
        else
        {
            print("Error - Check areas!")
            
            let answer = showDialog(title: localizedString(forKey: "errorTitle"), text: localizedString(forKey: "errorMessage"), buttonName: localizedString(forKey: "okText"), alertType: .warning)
            
            print(answer)
        }
       
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
extension Date
{
    // Get month and year from Date from given 'sentDate'
    ///
    /// - Warning: The returned string is  localized.
    
    /// - Returns: A date string to the `sentDate` like XXXX YYYY.
    func getDatewithMonthandYear() -> String
    {
        let dateFormatter1 = DateFormatter()
        dateFormatter1.dateFormat = "yyyy"
        let yearString = dateFormatter1.string(from: self)
        let dateFormatter2 = DateFormatter()
        dateFormatter2.dateFormat = "MMMM"
        let monthString = dateFormatter2.string(from: self)
        let returnValue = "\(monthString) \(yearString)"
        
      
        return returnValue
    }
    
    // Get day, month and year from Date from given 'sentDate'
    ///
    /// - Warning: The returned string is  localized.
   
    /// - Returns: A date string to the `sentDate` like XXXX YYYY.
    func getDatewithDayMonthandYear() -> String
    {
        let dateFormatter1 = DateFormatter()
        dateFormatter1.dateFormat = "yyyy"
        let yearString = dateFormatter1.string(from: self)
        let dateFormatter2 = DateFormatter()
        dateFormatter2.dateFormat = "MMMM"
        let monthString = dateFormatter2.string(from: self)
        
        let dateFormatter3 = DateFormatter()
        dateFormatter3.dateFormat = "dd"
        let dayString = dateFormatter3.string(from: self)
      
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
    
    
}
