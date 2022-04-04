//
//  PreferencesViewController.swift
//  aptreceipt
//
//  Created by berkbb on 20.03.2022.
//

import Cocoa


class PreferencesViewController: NSViewController {

   
    @IBOutlet weak var AptName_TextControl: NSTextField!

    @IBOutlet weak var DefaultPay_TextControl: NSTextField!
    
    @IBOutlet weak var House_Selector: NSPopUpButton!
    @IBOutlet weak var FlatCount_TextControl: NSTextField!
    @IBOutlet weak var HouseOwner_TextControl: NSTextField!
    @IBOutlet weak var SignImage: NSImageView!
    @IBOutlet weak var Issuer_TextControl: NSTextField!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        if let imageData = UserDefaults.standard.value(forKey: "usersign") as? Data{
                if let imageFromData = NSImage(data: imageData){
                    SignImage.image=imageFromData
                }
            }
  
        else
        {
            print("No sign imported.")
        }
        
        let defpay = UserDefaults.standard.string(forKey: "defaultpay")
        if(defpay != nil)
        {
            DefaultPay_TextControl.stringValue=defpay!
        }
        
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
            for i in 1..<Int(flatCount!)!+1 // For 8 apartment home.
            {
                House_Selector.addItem(withTitle: String(i))
                
            }
        }
        else
        {
            FlatCount_TextControl.stringValue="1"
            House_Selector.addItem(withTitle: "1")
            
        }
        House_Selector.selectItem(at: 0)
        let homeOwner = UserDefaults.standard.string(forKey: "homeowner_1")
        
       
            if(homeOwner != nil)
            {
                
                HouseOwner_TextControl.stringValue=homeOwner!.localizedCapitalized
            }
      
       
        
    }
    
    /// Save person button clciked event.
    @IBAction func SavePersonButton_Clicked(_ sender: Any) {
        
        let selected=Int(House_Selector.selectedItem!.title)
        
        let person=HouseOwner_TextControl.stringValue
        if(!person.isEmpty)
        {
            UserDefaults.standard.set(person, forKey: "homeowner_\(selected!)")
        }
      
       
    }
    
    /// House number changed devent.
    @IBAction func HouseNumberChanged(_ sender: Any) {
        HouseOwner_TextControl.stringValue="";
        let selected=Int(House_Selector.selectedItem!.title)
        print("Selected apartment number: \(selected!)")
        let homeOwner = UserDefaults.standard.string(forKey: "homeowner_\(selected!)")
        
       
            if(homeOwner != nil)
            {
                
                HouseOwner_TextControl.stringValue=homeOwner!.localizedCapitalized
            }
      
      
       
        
    }
    
 
    @IBAction func ImportSignButton_Click(_ sender: Any) {
        //Load NSImage.
        let openPanel = NSOpenPanel()
        openPanel.canCreateDirectories = false
        openPanel.allowsMultipleSelection=false
        openPanel.canChooseFiles=true
        openPanel.canChooseDirectories=false
        openPanel.showsTagField = false
        openPanel.allowedFileTypes = ["png"]
        openPanel.title=localizedString(forKey: "openImageTitle")
        if (openPanel.runModal() == NSApplication.ModalResponse.OK) {
            let result = openPanel.url

                   if (result != nil) {
                       do
                       {
                           SignImage.image=NSImage(data: try Data(contentsOf: result!))
                       }
                       catch
                       {
                           SignImage.image =  NSImage(named: NSImage.Name("sgn"))
                           UserDefaults.standard.removeObject(forKey: "usersign")
                       }
                      
                   
                       print("sign imported: \(result!)")
                   }
               } else {
                   print("Cancel")
                   return // User clicked cancel
               }
    }
    
    @IBAction func ClearSignButton_Click(_ sender: Any) {
        SignImage.image =  NSImage(named: NSImage.Name("sgn"))
        UserDefaults.standard.removeObject(forKey: "usersign")
    }
    
    /// Save info button cliick event.
    @IBAction func SaveButton_Click(_ sender: Any) {
        
        let flat=FlatCount_TextControl.stringValue
        let name=AptName_TextControl.stringValue
        let issuer = Issuer_TextControl.stringValue.localizedCapitalized
        let pay=DefaultPay_TextControl.stringValue
        
       
    
     
        let flats = Int(flat)
        let pays=Double(pay)
        print(flat)
        print(pay)
        print(issuer)
        print(name)
        
        if(!AptName_TextControl.stringValue.isEmpty && !FlatCount_TextControl.stringValue.isEmpty && !Issuer_TextControl.stringValue.isEmpty && flats != nil && pays != nil)
        {
            print("OK")
            UserDefaults.standard.set(name, forKey: "aptname")
            
            UserDefaults.standard.set(issuer, forKey: "issuer")
            
            UserDefaults.standard.set(flat, forKey: "flatcount")
            
            UserDefaults.standard.set(pay, forKey: "defaultpay")
            
            if(SignImage.image !=  NSImage(named: NSImage.Name("sgn")))
            {
           
                let imageData = NSImagePNGRepresentation(image: SignImage.image!)
                UserDefaults.standard.set(imageData,forKey: "usersign")
                
  
            }
            
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
    /// Retuns value of translated key.
    ///
    /// - Warning: The returned String is  localized.
    /// - Parameter forKey: The forKey  is String object.
    /// - Returns: String.
    
    
    func localizedString(forKey key: String) -> String {
        var result = Bundle.main.localizedString(forKey: key, value: nil, table: nil)

        if result == key {
            result = Bundle.main.localizedString(forKey: key, value: nil, table: "File")
        }

        return result
    }
    

}


#if os(macOS)

func NSImagePNGRepresentation(image:NSImage) -> Data? {
    guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil)
        else { return nil }
    let imageRep = NSBitmapImageRep(cgImage: cgImage)
    imageRep.size = image.size // display size in points
    return imageRep.representation(using: .png, properties: [:])
}

#endif

