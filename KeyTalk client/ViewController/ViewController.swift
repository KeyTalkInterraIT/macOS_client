//
//  ViewController.swift
//  KeyTalk client
//
//  Created by Rinshi Rastogi
//  Copyright © 2018 KeyTalk. All rights reserved.
//

// URL to download RCCD file = "https://downloads.keytalk.com/corp.rccd"

import Cocoa
import SSZipArchive
import CoreData
import IOKit
import ServiceManagement

class ViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource, NSTextFieldDelegate {
    
    //MARK:- Variables
    //RCCD
    var mRccdImageArray = [Data]()
    var mParsedUserModel = [UserModel]()
    var rccdData:[String] = [String]()
    var sUser_iniArray = [RCCD]()
    var rccdModel = [rccd]()
    var selectedRCCDModel : rccd? {
        didSet {
            self.selectedModel(rccd: selectedRCCDModel)
        }
    }
    
    //selected RCCD check variable
    var selectedRowIndex = -1
    
    //Certificate
    var certificateDict = [String: [String]]()
    var certificateArray = [String]()
    
    //User Defaults
    let defaults = UserDefaults.standard
    
    //DirectoryPath
    let mHomeDirectory = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true)[0] + "/KeyTalk client"
    
    //MARK:- IBOutlets
    @IBOutlet weak var mTableView: NSTableView!
    @IBOutlet weak var mURLButton: NSButton!
    @IBOutlet weak var RccdfileHead: NSTableColumn!
    
    //@IBOutlet var RccdFileHead: NSTextField!
    
    //MARK:- OverrideMethod
    
    /**
     Method is an override method, called after the view controller’s view has been loaded into memory.
     */
    override func viewDidLoad() {
        super.viewDidLoad()
        LocalizerOfApp.LocalizeStoryboard()
    }
    
    /**
     Method is an override method, called after the view controller’s view has been loaded into memory is about to be added to the view hierarchy in the window.
     */
    override func viewWillAppear() {
        //update view
        updateView()
    }
    
    /**
     Method is an override method, called when the view controller’s view is fully transitioned onto the screen.
     */
    override func viewDidAppear() {
        //TableView Delegate and Data Source
        mTableView.delegate = self
        mTableView.dataSource = self
        mTableView.reloadData()
        RccdfileHead.title = "RCCD_Files".localized(LanguagePrefrenceDBHandler.getLanguageSelected()!)

        //update view from database
        updateViewWithLastUsedRCCDInfo()
    }
    
    /**
     Method is an override method, returns the number of rows to be made in a TableView.
     */
    override var representedObject: Any? {
        didSet {
        }
    }
    
    //MARK:- NSTableViewDataSourceMethod
    
    /**
     Method is an override method, returns the number of rows to be made in a TableView.
     */
    func numberOfRows(in tableView: NSTableView) -> Int {
        return rccdModel.count
    }
    
    //MARK:- NSTableViewDelegateMethod
    
    /**
     Method is an override method, used to give TableView cell view.
     */
    func tableView(_ tableView: NSTableView, viewFor viewForTableColumn: NSTableColumn?, row: Int) -> NSView?
    {
        let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "RCCDCell"), owner: self) as! NSTableCellView
        cell.textField?.stringValue = rccdModel[row].name
        if let imgData = rccdModel[row].imageData as? Data
        {
            cell.imageView?.image = NSImage(data: imgData)
        } else {
            cell.imageView?.image = #imageLiteral(resourceName: "logo")
        }
        return cell
    }
    
    /**
     Method is an override method, used to give height to TableView cell.
     */
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return 40
    }
    
    /**
     Method is an override method, called everytime a cell is selected in a TableView .
     */
    func tableViewSelectionDidChange(_ notification: Notification) {
        
        //gets the instance of the present TableView
        if let myTable = notification.object as? NSTableView {
            
            // we create an [Int] array from the index set
            let selectedCell = myTable.selectedRowIndexes.map { Int($0) }
            let splitView = self.parent as? NSSplitViewController
            let servicesVC = splitView?.children[1] as! ServicesViewController
            if selectedCell.count != 0 {
                let selectedRCCDModel = self.rccdModel[selectedCell[0]]//.users[0]
                servicesVC.selectedRCCD = selectedRCCDModel
                //sets the seleted model into the global variable for database handling.
                selectedRowIndex = selectedCell[0]
                
            } else {
                return
            }
        }
    }
    
    //MARK:- IBAction
    /**
     ActionButton used to imports the RCCD file from Finder.
     */
    @IBAction func importFromFilesActionButton(_ sender: Any) {
        
        let lFilePicker : NSOpenPanel = NSOpenPanel()
        lFilePicker.allowsMultipleSelection = false
        lFilePicker.canChooseFiles = true
        lFilePicker.canChooseDirectories = false
        lFilePicker.allowedFileTypes = ["rccd"]
        if (lFilePicker.runModal() == NSApplication.ModalResponse.OK){
            let lChosenFile = lFilePicker.url
            if (lChosenFile != nil){
                
                //chosen RCCD file is unzipped to show its content files
                Utilities.unZipFile(aPath: (lChosenFile?.path)!)
                //updating the current view, after the importing rccd file.
                updateView()
                updateViewWithImportedRCCDInfo()
                mTableView.reloadData()
            }
        }
        else {return}
    }
    
    /**
     ActionButton used to imports the RCCD file from URL.
     */
    @IBAction func importRCCDFromURLActionButton(_ sender: Any) {
        let stringFromTextField =  Utilities.showAlert(aMessageText: "enter_url_to_download_string".localized(UserDefaults.standard.value(forKey: "LanguageChangeSelected") as! String), tag: 0)
        if stringFromTextField != nil {
            //used to download RCCD file from server
            importFromURL(stringValue: stringFromTextField!)
        }
    }
    
    /**
     ActionButton used to remove the RCCD file from TableView.
     */
    @IBAction func removeRCCDFromList(_ sender: Any) {
        if rccdModel.count > 0 {
            if selectedRowIndex >= 0 {
                //selected RCCD file to be deleted
                let rccdTobeDeleted = rccdModel[selectedRowIndex]
                DownloadedCertificateHandler.deleteItem(rccdInfo: rccdTobeDeleted)
                DBHandler.removeRCCDFromDB(rccd: rccdTobeDeleted)
                UserDetailsHandler.deleteValueIfPresent(rccdname: rccdTobeDeleted.name)
                updateView()
                
                let splitView = self.parent as? NSSplitViewController
                let servicesVC = splitView?.children[1] as! ServicesViewController
                servicesVC.selectedRCCD = nil
                servicesVC.resetAll(aServicesArray: true, username: nil)
                
                let fromRange = IndexSet(0..<rccdModel.count)
                mTableView.removeRows(at: fromRange, withAnimation: NSTableView.AnimationOptions.effectFade)
                
                let deletedRCCDIndex = selectedRowIndex
                selectedRowIndex = -1
                mTableView.reloadData()
                updateViewWithDeletedRCCDInfo(index: deletedRCCDIndex)
            } else {
                let _ = Utilities.showAlert(aMessageText: "select_rccd_to_delete_string".localized(UserDefaults.standard.value(forKey: "LanguageChangeSelected") as! String), tag: 1)
            }
        } else {
            return
        }
    }
    
    //MARK:- Public Methods
    /**
     This method is used to set the selected RCCD.
     - Parameter rccd: rccd model of the selected RCCD.
     */
    func selectedModel(rccd : rccd?) {
        print("rccd recieved")
    }
    
    /**
     This method is used to update view with the details of the last used RCCD.
     */
    func updateViewWithLastUsedRCCDInfo () {
        //get the last used RCCD name
        let lastUsedRCCDName  = UserDetailsHandler.getLastSavedEntry()
        if let _lastusedUserName = lastUsedRCCDName {
            for i in 0..<rccdModel.count {
                let tempRCCD = rccdModel[i]
                //get the last used username
                if tempRCCD.name == _lastusedUserName.rccdname {
                    mTableView.selectRowIndexes(IndexSet([i]), byExtendingSelection: true)
                    break
                }
            }
        } else {
            DispatchQueue.main.async {
                self.mTableView.selectRowIndexes(IndexSet([0]), byExtendingSelection: true)
            }
        }
        
    }
    
    /**
     This method is used to update the View with imported RCCD.
     */
    func updateViewWithImportedRCCDInfo () {
        DispatchQueue.main.async {
            self.mTableView.selectRowIndexes(IndexSet([self.rccdModel.count - 1]), byExtendingSelection: true)
        }
    }
    /**
     This method is used to update the table view after the removal of the rccd file from the list.
     - Parameter index: the index from which the rccd file is removed or deleted.
     */
    func updateViewWithDeletedRCCDInfo (index : Int) {
        //if the rccd file was not at the initial index of the list.
        if index > 0 {
            DispatchQueue.main.async {
                self.mTableView.selectRowIndexes(IndexSet([index - 1]), byExtendingSelection: true)
            }
        } else {
            //if the removed rccd file was at the initial index of the list.
            if rccdModel.count > 0 {
                //if rccd list still contains elements, then the one at the initial index will be seleceted or highlighted.
                DispatchQueue.main.async {
                    self.mTableView.selectRowIndexes(IndexSet([0]), byExtendingSelection: true)
                }
            }
        }
    }
    
    /**
     This method is used to download the RCCD file hosted on KeyTalk server.
     - Parameter Filename: The filename with which RCCD file is kept on the Server.
     */
    func importFromURL(stringValue: String) {
        do {
            //maximimum characters for URL
            let lMaxCharactersforTextField = 100
            //URL textField contains some value and its length is less than maximum characters
            if (!stringValue.isEmpty && stringValue.count < lMaxCharactersforTextField) {
                let lTrimmedString = stringValue.components(separatedBy: .whitespacesAndNewlines).joined()
                let lTrimmedURL = URL(string: lTrimmedString)
                var lURLString = lTrimmedURL?.absoluteString
                //making URL valid
                //check wheather the string contains prefix, if not then append the prefix.
                if !(lURLString?.lowercased().hasPrefix("http://"))! && !(lURLString?.lowercased().hasPrefix("https://"))! {
                    lURLString = "https://" + lURLString!
                }
                if lURLString?.range(of: ".rccd") == nil {
                    lURLString = lURLString! + ".rccd"
                }
                
                let lURL = URL(string: lURLString!)
                Utilities.init().logger.write("URL to import RCCD: \(lURL)")
                //store RCCD file using this filename
                let lFileName = lURL!.lastPathComponent
                //destination path to download the RCCD file
                let lDestinationFilePath = mHomeDirectory + "/DownloadedRCCDs"
                let lFileManager = FileManager.default
                try lFileManager.createDirectory(atPath: lDestinationFilePath, withIntermediateDirectories: true, attributes: nil)
                let lFilePath = lDestinationFilePath + "/\(lFileName)"
                //download the RCCD file
                let lSessionConfiguration = URLSessionConfiguration.default
                let lSession = URLSession(configuration: lSessionConfiguration)
                let lRequest = try! URLRequest(url: lURL!)
                let lTask = lSession.downloadTask(with: lRequest) { (tempLocalUrl, response, error) in
                    if let lTempLocalUrl = tempLocalUrl, error == nil {
                        if let statusCode = (response as? HTTPURLResponse)?.statusCode {
                            print("Success: \(statusCode)")
                            //RCCD file downloaded successfully
                            do {
                                //check if file already exists
                                if lFileManager.fileExists(atPath: lFilePath){
                                    //remove item from path
                                    try lFileManager.removeItem(atPath: lFilePath)
                                }
                                //copy downloaded file to the path
                                try lFileManager.copyItem(atPath: lTempLocalUrl.path, toPath: lFilePath)
                                if  lFilePath.hasSuffix("rccd")
                                {
                                    DispatchQueue.main.async {
                                        //unzip the RCCD file downloaded from URL
                                        Utilities.unZipFile(aPath: lFilePath)
                                        self.updateView()
                                        self.updateViewWithImportedRCCDInfo()
                                        self.mTableView.reloadData()
                                    }
                                }
                            }catch{
                                DispatchQueue.main.async {
                                    NotificationManager.sharedManager().showNotification(informativeText: "rccd_already_installed_string".localized(UserDefaults.standard.value(forKey: "LanguageChangeSelected") as! String))
                                }
                            }
                        }
                    } else {
                        print("Failure: %@", error?.localizedDescription as Any)
                        Utilities.init().logger.write((error?.localizedDescription)!)
                        DispatchQueue.main.async {
                            _ =  Utilities.showAlert(aMessageText: "enter_valid_url_string".localized(UserDefaults.standard.value(forKey: "LanguageChangeSelected") as! String), tag: 1)
                        }
                    }
                }
                lTask.resume()
            }
            else {
            }
        } catch {
            _ = Utilities.showAlert(aMessageText: "enter_valid_url_string".localized(UserDefaults.standard.value(forKey: "LanguageChangeSelected") as! String), tag: 1)
        }
    }
    
    /**
     This method is used to update the TableView from database.
     */
    private func updateView() {
        let tempRCCDArr = DBHandler.getRCCDData()
        if let _rccdModel = tempRCCDArr {
            rccdModel = _rccdModel
        }
    }
    
    /**
     This method is used to remove all the RCCD from the Table View, it is called when Remove Configuration menu item is clicked.
     */
    func removeAllRCCDFiles() {
        DBHandler.deleteAllData()
        DownloadedCertificateHandler.deleteAllData()
        UserDetailsHandler.deleteAllData()
        updateView()
    }
    
    
   
    //MARK:- OBJC methods
    /**
     This method is used to remove all the RCCD from the Table View, it is called when Remove Configuration menu item is clicked.
     */
    @objc func removeAllConfigurations(_ sender: AnyObject) {
        //delete all data from database
        DBHandler.deleteAllData()
        //update view after deleting
        updateView()
        let splitView = self.parent as? NSSplitViewController
        let servicesVC = splitView?.children[1] as! ServicesViewController
        servicesVC.selectedRCCD = nil
        DispatchQueue.main.async {
            self.mTableView.reloadData()
        }
    }
}
