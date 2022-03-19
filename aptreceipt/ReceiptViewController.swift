//
//  ReceiptViewController.swift
//  aptreceipt
//
//  Created by Berk Babadoğan on 18.03.2022.
//

import Cocoa

class ReceiptViewController: NSViewController {

    var recevier:String = ""
    var issuer:String = ""
    var notes:String = ""
    var monthYear:String = ""
    var aptNumber:Int=0
    var price:Double=0.0
    var seqNumber:Int=0
    var currentDate:String=""
    
    @IBOutlet weak var ReceiptView: NSView!
    
    @IBOutlet weak var Receipt_IssuerLabel: NSTextField!
    @IBOutlet weak var Total_MesaageLabel: NSTextField!
    @IBOutlet weak var Notes_Print: NSTextField!
    @IBOutlet weak var MonthYear_Label: NSTextField!
    @IBOutlet weak var AptNumber_Label: NSTextField!
    @IBOutlet weak var Date_Label: NSTextField!
    @IBOutlet weak var Price_Label: NSTextField!
    @IBOutlet weak var Seq_Label: NSTextField!
    @IBOutlet weak var CurrentDate_Label: NSTextField!
    @IBOutlet weak var Receipt: NSBox!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        Total_MesaageLabel.stringValue = "\(localizedString(forKey: "totalMessage")) \(recevier)"
        Receipt_IssuerLabel.stringValue=issuer
        Notes_Print.stringValue=notes
        MonthYear_Label.stringValue=monthYear
        AptNumber_Label.stringValue=String(aptNumber)
        let locale = Locale.current
        let currencySymbol = locale.currencySymbol!
        if locale.languageCode!.contains("tr") {
            Price_Label.stringValue="\(String(price)) \(currencySymbol)"
        }
        else
        {
            Price_Label.stringValue=" \(currencySymbol) \(String(price))"
        }
        
        Price_Label.stringValue="\(String(price)) \(currencySymbol)"
        Seq_Label.stringValue=String(seqNumber)
        CurrentDate_Label.stringValue=currentDate
    }
    /// Cancel click function
    @IBAction func Cancel_Click(_ sender: Any) {
        
        if let controller=self.storyboard?.instantiateController(withIdentifier: "HomeView") as? ViewController{self.view.window?.contentViewController=controller}
    }
    
    /// Save click function
    @IBAction func Save_Click(_ sender: Any) {
        
        let image=Receipt.asImage();
   
        let savePanel = NSSavePanel()
            savePanel.canCreateDirectories = true
            savePanel.showsTagField = false
        savePanel.nameFieldStringValue = "\(recevier.lowercased())_\(monthYear.lowercased()).jpg"
        savePanel.allowedFileTypes = ["jpg"]
        savePanel.title=localizedString(forKey: "saveImagetitle")
        if (savePanel.runModal() == NSApplication.ModalResponse.OK) {
                    let result = savePanel.url

                   if (result != nil) {

                       image.writeJPEG(toURL: result!)
                       print("saved at \(result!)")
                   }
               } else {
                   print("Cancel")
                   return // User clicked cancel
               }
    
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
extension NSBox {

    // Using a function since `var image` might conflict with an existing variable
    // (like on `UIImageView`)
    func asImage() -> NSImage {
        let viewToCapture = self
        let rep = viewToCapture.bitmapImageRepForCachingDisplay(in: viewToCapture.bounds)!
        viewToCapture.cacheDisplay(in: viewToCapture.bounds, to: rep)

        let img = NSImage(size: viewToCapture.bounds.size)
        img.addRepresentation(rep)
        return img
        }
    
    }

extension NSImage {
   public func writeJPEG(toURL url: URL) {

       guard let data = tiffRepresentation,
           let rep = NSBitmapImageRep(data: data),
             let imgData = rep.representation(using: .jpeg, properties: [.compressionFactor : NSNumber(floatLiteral: 1.0)]) else {

               print("\(self.self) Error Function '\(#function)' Line: \(#line) No tiff rep found for image writing to \(url)")
               return
       }

       do {
           try imgData.write(to: url)
       }catch let error {
           print("\(self.self) Error Function '\(#function)' Line: \(#line) \(error.localizedDescription)")
       }
   }
}
