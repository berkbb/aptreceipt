//
//  PreferencesViewController.swift
//  aptreceipt
//
//  Created by Berk Babadoğan on 20.03.2022.
//

import Cocoa

class PreferencesViewController: NSViewController {

   
    @IBOutlet weak var AptName_TextControl: NSTextField!

  
    @IBOutlet weak var FlatCount_TextControl: NSTextField!
    
    @IBOutlet weak var Issuer_TextControl: NSTextField!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        let aptName = UserDefaults.standard.string(forKey: "aptname")
        if(aptName != nil)
        {
            AptName_TextControl.stringValue=aptName!
        }
        let issuerName = UserDefaults.standard.string(forKey: "issuer")
        if(issuerName != nil)
        {
            Issuer_TextControl.stringValue=issuerName!.localizedCapitalized
        }
        
        
        let flatCount = UserDefaults.standard.string(forKey: "flatcount")
        if(flatCount != nil)
        {
            FlatCount_TextControl.stringValue=flatCount!
        }
    }
    
    @IBAction func SaveButton_Click(_ sender: Any) {
        
        let flat=FlatCount_TextControl.stringValue
        let name=AptName_TextControl.stringValue
        let issuer = Issuer_TextControl.stringValue.localizedCapitalized
        
       
        print(issuer)
        
        print(name)
        let flats = Int(flat)
        print(flat)
        
        if(!AptName_TextControl.stringValue.isEmpty && !FlatCount_TextControl.stringValue.isEmpty && !Issuer_TextControl.stringValue.isEmpty && flats != nil)
        {
            print("OK")
            UserDefaults.standard.set(name, forKey: "aptname")
            
            UserDefaults.standard.set(issuer, forKey: "issuer")
            
            UserDefaults.standard.set(flat, forKey: "flatcount")
            let answer = showDialog(title: localizedString(forKey: "infoTitle"), text: localizedString(forKey: "restartMessage"), buttonName: localizedString(forKey: "okText"), alertType: .informational)
            
            print(answer)
            self.view.window?.close()
        }
       else
       
       {
           print("Error - Check areas!")
           
           let answer = showDialog(title: localizedString(forKey: "errorTitle"), text: localizedString(forKey: "errorMessage"), buttonName: localizedString(forKey: "okText"), alertType: .warning)
           
           print(answer)
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
}
