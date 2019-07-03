//
//  ServicesViewController.swift
//  KeyTalk client
//
//  Created by Rinshi Rastogi 
//  Copyright © 2018 KeyTalk. All rights reserved.
//

import Cocoa
import AppKit

class ServicesViewController: NSViewController, NSTextFieldDelegate {
    
    //MARK:- Variables
    let mHomeDirectory = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true)[0] + "/KeyTalk client"//FileManager.default.homeDirectoryForCurrentUser
    
    // Models
    let vcmodel = VCModel()
    
    //Selected Service Variable
    //sets whent the rccd file is selected in the TableView.
    var selectedRCCD : rccd? {
        didSet {
            self.handleMenuModel(selectedRCCD)
        }
    }
    
    //sets the selected service value from the drop down menu
    var selectedService : String? {
        didSet {
            self.handleServiceSelection(service: selectedService)
        }
    }
    // Timer instances, to handle the delay encountered.
    var timer = Timer()
    var isTimerRunning = false
    var delayTimeInSeconds : Int = 0
    
    // Selected Service
    var currentSelectedService :String = String()
    var lastSelectedService :String = String()
    
    //Challenge Variable, to encounter the challenges faces by the user.
    var challengeMessage = String()
    var serverResponseCookie :String? = nil
    
   //LDAP Arrays
    var serverURLArray = [String]()
    var searchBaseArray = [String]()
    
    //loader view
    var mLoaderView : NSView?
    
    //MARK:- IBOutlet
    @IBOutlet weak var showRCCDServices: NSPopUpButton!
    @IBOutlet weak var lUserNameTextField: NSTextField!
    @IBOutlet weak var lPasswordTextField: NSSecureTextField!
    @IBOutlet weak var lImageView: NSImageView!
    @IBOutlet weak var lLoginButton: NSButtonCell!
    @IBOutlet weak var lVersionTextField: NSTextField!
    @IBOutlet weak var lLoginButtonOutlet: NSButton!
    @IBOutlet weak var lBox: NSBox!
    
    //MARK:- Lifecycle Methods.
    /**
     Method is an override method, called after the view controller’s view has been loaded into memory.
     */
    override func viewDidLoad() {
        //sets the loader view
        var currentLocaleLang = Locale.current.languageCode
        let valueInUserDefaults = UserDefaults.standard.value(forKey: "LanguageChangeSelected")
        if valueInUserDefaults == nil {
            if let valueExistsInEnum = LanguageEnum(rawValue: currentLocaleLang!) {//LanguageEnum.init(rawValue: currentLocaleLang!)  {
            UserDefaults.standard.set(valueExistsInEnum, forKey: "LanguageChangeSelected")
        } else {
                UserDefaults.standard.set("en", forKey: "LanguageChangeSelected")
        }
        }else {
            UserDefaults.standard.set(valueInUserDefaults, forKey: "LanguageChangeSelected")
        }
        let setLang = UserDefaults.standard.value(forKey: "LanguageChangeSelected")
        LanguagePrefrenceDBHandler.saveLanguagePreferencetoDatabase(languageSelected: setLang as! String)
      
          setUpLoaderView()
       
        //modify login button
        lLoginButtonOutlet.layer?.cornerRadius = 0
        lLoginButtonOutlet.bezelStyle = .texturedSquare
        //sets the app version number on the UI.
        lVersionTextField.stringValue = "\("version".localized(UserDefaults.standard.value(forKey: "LanguageChangeSelected") as! String)) \(Bundle.main.releaseVersionNumber!).\(Bundle.main.buildVersionNumber!)"
    }
    
    /**
     Method is an override method, called when the view controller’s view is fully transitioned onto the screen.
     */
    override func viewDidAppear() {
        //sets up the model class
        setUpModel()
        //sets the default image icon.
        lImageView.image = #imageLiteral(resourceName: "logo")
    }
    
    /**
     This method is used to set the loader on the View.
     */
    func setUpLoaderView() {
        
        //sets the loader view with the frame of the base view.
        mLoaderView = NSView.init(frame: self.view.frame)
        
        //creating a central view containing the progreea indicator and a text field.,
        let loaderView = NSView.init(frame: .init(x: self.view.frame.width/2-100, y: self.view.frame.height/2-100, width: 200 , height: 200))
        loaderView.alphaValue = 1
        //sets the layer of the view.
        loaderView.wantsLayer = true
        loaderView.layer?.borderColor = NSColor.black.cgColor
        loaderView.layer?.backgroundColor = NSColor.init(red: 255, green: 255, blue: 255, alpha: 0.0).cgColor
        
        //initiates the progress indicator on the view.
        let acticityIndicator = NSProgressIndicator.init(frame: .init(x: 80, y: 80, width: 40, height: 40))
        //sets the style to the progess indicator and background view
        acticityIndicator.style = .spinning
        acticityIndicator.controlTint = NSControlTint.graphiteControlTint
        acticityIndicator.wantsLayer = true
        acticityIndicator.layer?.backgroundColor = NSColor.clear.cgColor
        acticityIndicator.startAnimation(self)
        loaderView.addSubview(acticityIndicator)
        
        let pleaseWaitTxtFld = NSTextField.init(frame: NSRect.init(x: 30, y: 50, width: 140, height: 30))
        pleaseWaitTxtFld.alignment = .center
        pleaseWaitTxtFld.textColor =  .black
        pleaseWaitTxtFld.backgroundColor = .clear
        pleaseWaitTxtFld.isBezeled = false
        pleaseWaitTxtFld.isEditable = false
        pleaseWaitTxtFld.stringValue = "please_wait_string".localized(UserDefaults.standard.value(forKey: "LanguageChangeSelected") as! String)
        pleaseWaitTxtFld.font = NSFont.init(descriptor: .init(), size: 15)
        loaderView.addSubview(pleaseWaitTxtFld)
        
        //adding the central view on the main loader view.
        mLoaderView?.addSubview(loaderView)
    }
    
    //MARK:- NSTextFielsDelegateMethod
    /**
     Method is an NSTextField delegate method, returns the controll to the private method on clicking enter.
     */
    func control(_ control: NSControl, textShouldEndEditing fieldEditor: NSText) -> Bool {
        loginButtonTapped(self)
        return true
    }
    
    //MARK:- IBAction
    /**
     ActionButton is used to show the services of the selected RCCD.
     */
    @IBAction func showRCCDServicesActionButton(_ sender: NSPopUpButton){
        self.selectedService = sender.titleOfSelectedItem
    }
    
    /**
     ActionButton is used to login using the credentials entered.
     */
    
    
    @IBAction func loginButtonTapped(_ sender: Any) {
        
//        let storyboard = NSStoryboard.init(name: "Main", bundle: nil)
//        let identifier = NSStoryboard.SceneIdentifier("LDAPGuideViewController")
//        guard let viewcontroller = storyboard.instantiateController(withIdentifier: identifier) as? LDAPGuideViewController else {
//            fatalError("Why cant i find LDAPGuideViewController? - Check Main.storyboard")
//        }
//        let sViewController = ViewController()
//        sViewController.presentAsModalWindow(viewcontroller)
        
        //Utilities.showLDAPGuide()
        //validates the username , password and service name , before sending the server request.

        guard let usernme = lUserNameTextField.stringValue as? String , usernme.count > 0 else {
            let _ = Utilities.showAlert(aMessageText: "username_cannot_blank_string".localized(UserDefaults.standard.value(forKey: "LanguageChangeSelected") as! String), tag: 1)
            return
        }
        guard let passwrd = lPasswordTextField.stringValue as? String , passwrd.count > 0 else {
            let _ = Utilities.showAlert(aMessageText: "password_blank_string".localized(UserDefaults.standard.value(forKey: "LanguageChangeSelected") as! String), tag: 1)
            return
        }
        guard let servicess = showRCCDServices.titleOfSelectedItem , servicess.count > 0 else {
            let _ = Utilities.showAlert(aMessageText: "select_service_string".localized(UserDefaults.standard.value(forKey: "LanguageChangeSelected") as! String), tag: 1)
            return
        }
        
        //gets the model associated with the RCCD file selected by the user.
        let model = selectedRCCD?.users[0].Providers[0]
        
        //sets the seleted model into the global variable for database handling.
        gDownloadedCertificateModel = DownloadedCertificate(rccdName: selectedRCCD?.name, user: [(selectedRCCD?.users[0])!] , cert: nil)
        
        if let user = lUserNameTextField.objectValue, let pass = lPasswordTextField.objectValue, let _ = showRCCDServices.titleOfSelectedItem {
            username = user as! String
            password = pass as! String
            
            // valid url for API hit
            let serviceURL = Utilities.returnValidServerUrl(urlStr: (model?.Server)!)
            serverUrl = serviceURL
            
            //name of the selected service
            serviceName = showRCCDServices.titleOfSelectedItem!
            
            vcmodel.apiService = ConnectionHandler(servicename: serviceName, username: username, password: password, server: serviceURL, challengeResponse: nil)
            //request for API request with hello URL
            self.vcmodel.requestForApiService(urlType: .hello)
            
            

            
            
        }
        Utilities.init().logger.write("hit the server for hello request")
    }
    
    
    //MARK:- PrivateMethods
    
    /**
     This method is used to download the certificate after the authentication is completed.
     */
    private func downloadCertificate(aCookie:String) {
        do {
            Utilities.init().logger.write("server hit for certificate download initiated")
            
            //json model of the selected service,gets the server url associated with the selected rccd file.
            let model = selectedRCCD?.users[0].Providers[0].Server
            
            //json-serialization of the model
            let dict = try JSONSerialization.jsonObject(with: dataCert, options: []) as? [String:Any]
            
            //gets the status of the response.
            if let status = dict!["status"] as? String {
                
                //if auth status is cert.
                if status == "cert" {
                    
                    //gets the url from which the certificate needs to be downloaded.
                    guard let certUrlStr = dict!["cert-url-templ"] as? String,certUrlStr.count > 0 else{
                        DispatchQueue.main.async {
                            self.resetAll(aServicesArray: false, username: nil)
                            let _ = Utilities.showAlert(aMessageText: "error_communication_string".localized(UserDefaults.standard.value(forKey: "LanguageChangeSelected") as! String), tag: 1)
                        }
                        return
                    }
                    
                    //password of the p12 certificate, retrieves it from the cookie recieved from hello hit.
                    //spliting the cookie to get the certificate password.
                    let passcode = aCookie.components(separatedBy: "=")[1]
                    let index = passcode.index((passcode.startIndex), offsetBy: 30)
                    let subString = passcode[..<index]
                    
                    //sets the server url for the certificate downloading.
                    let serverString = model
                    
                    if certUrlStr.count > 0 {
                        
                        //creating a valid url withe service host url and the certificate url.
                        let tempURLString = certUrlStr.replacingOccurrences(of: "$(KEYTALK_SVR_HOST)", with: serverString!)
                        let certURL = URL(string: tempURLString)
                        
                        //filename of the certificate
                        let fileName = (certURL?.lastPathComponent)! + ".p12"
                        
                        //destination path to store the downloaded certificate
                        let destinationPath = mHomeDirectory + "/DownloadedCertificates"//mHomeDirectory.appendingPathComponent("DownloadedCertificates", isDirectory: true)
                        
                        //create directory for downloaded certificates
                        try FileManager.default.createDirectory(atPath: destinationPath, withIntermediateDirectories: true, attributes: nil)
                        let filePath = destinationPath + "/\(fileName)"//destinationPath.appendingPathComponent(fileName, isDirectory: false)
                        
                        //download the certificate
                        let sessionConfig = URLSessionConfiguration.default
                        let session = URLSession(configuration: sessionConfig)
                        let request = try! URLRequest(url: certURL!)
                        let task = session.downloadTask(with: request) { (tempLocalUrl, response, error) in
                            if let tempLocalUrl = tempLocalUrl, error == nil {
                                Utilities.init().logger.write("certificate downloaded successfully")
                                
                                //Certificate downloaded successfully
                                if let statusCode = (response as? HTTPURLResponse)?.statusCode {
                                    print("Success: \(statusCode)")
                                    do {
                                        //check if file already exists
                                        if FileManager.default.fileExists(atPath: filePath){
                                            //remove item from path
                                            try FileManager.default.removeItem(atPath: filePath)
                                        }
                                        //copy downloaded file to the path
                                        try FileManager.default.copyItem(atPath: tempLocalUrl.path, toPath: filePath)
                                        
                                        //resets all the varibles
                                        self.resetAll(aServicesArray: true, username: username)
                                        
                                        //saves the downloaded certificate into the database and keychain.
                                        let lCertificateLoader = CertificateLoader()
                                        let certiModel = DownloadedCertificate(rccdName: self.selectedRCCD?.name, user: (self.selectedRCCD?.users)!, cert: nil)
                                        
                                        Utilities.init().logger.write("downloaded certificate is sent to be loaded in the keychain and also to be saved in the database")
                                        UserDetailsHandler.saveUsernameAndServices(rccdname: (self.selectedRCCD?.name)!, username: username, services: serviceName)
                                        //get downloaded certificates from database
                                        let downloadedCerts = DownloadedCertificateHandler.getTrustedCertificateData()
                                        if (downloadedCerts?.count)! > 0 {
                                            for downloadedCertificates in downloadedCerts! {
                                                let serviceName = downloadedCertificates.downloadedCert?.cert?.associatedServiceName
                                                let usenameforService = downloadedCertificates.downloadedCert?.cert?.username
                                                let textFieldUsername = self.lUserNameTextField.stringValue
                                                let service = self.showRCCDServices.titleOfSelectedItem
                                                if ( textFieldUsername == usenameforService && service == serviceName){
                                                    //check if the currently downloaded certificate is SMIME
                                                    if downloadedCertificates.downloadedCert?.cert?.isSMIME == false {
                                                        //if not SMIME, delete the previous expired certificate from keychain
                                                        let fingerPrint = downloadedCertificates.downloadedCert?.cert?.fingerPrint
                                                        CertificateHandler.deleteCertificates(fingerprint: (fingerPrint)!)
                                                    } else {
                                                        //if SMIME, certificate is not deleted from Keychain
                                                        print("SMIME Certificate found: installing new one")
                                                    }
                                                    self.setUpModel()
                                                }
                                            }
                                        }
                                         //load p12 certificate and store it in Keychain
                                        lCertificateLoader.loadPKCSCertificate(path: filePath, p12Password: String(subString), isUserInitiated: true, certificateModel: certiModel, aServiceUsername: username, aServiceName: serviceName, completion: { (success) in
                                            if success {
                                                self.vcmodel.requestForApiService(urlType: .lastMessage)
                                            } else {
                                                Utilities.init().logger.write("could not load certificate.")
                                            }
                                        })
                                        
                                    } catch {
                                        Utilities.init().logger.write("could not download certificate.")
                                    }
                                }
                            } else {
                                Utilities.init().logger.write("could not download certificate due to:  \(String(describing: error?.localizedDescription))")
                            }
                        }
                        task.resume()
                    }
                }
                else {
                    DispatchQueue.main.async {
                        self.resetAll(aServicesArray: false, username: nil)
                        Utilities.init().logger.write("could not initiate certificate downloading, resetting every parameter")
                    }
                }
            }
        }
        catch {
            Utilities.init().logger.write("could not initiate certificate downloading, certificate download failed  \(String(describing: error.localizedDescription))")
        } }
    
    
    /**
     This method is used to handle the api request to the server according to the URL.
     The URL type is used to notify that the server communication is successful for that URL and to call the next sequential server request.
     
     - Parameter typeUrl: Type of URL for server communication.
     */
    private func handleAPIs(typeUrl: URLs) {
        switch typeUrl {
        case .hello:
            vcmodel.requestForApiService(urlType: .handshake)
        case .handshake:
            vcmodel.requestForApiService(urlType: .authReq)
        case .authReq:
            vcmodel.requestForApiService(urlType: .authentication)
        case .authentication:
            vcmodel.requestForApiService(urlType: .addressBook)
        case .addressBook:
            vcmodel.requestForApiService(urlType: .certificate)
        case .challenge:
            vcmodel.requestForApiService(urlType: .certificate)
        case .certificate:
            //cookie is been used to fetch the password for the certificate to be downloaded.
            self.downloadCertificate(aCookie: self.serverResponseCookie!)
        case .lastMessage:
            print("last message recieved.")
            //vcmodel.requestForApiService(urlType: .lastMessage)
        
        }
    }
    
    /**
     This method is used to handle the last message retrieved from the server.
     This message is retrieved when communication is successful i.e. certificate is successfully returned from the server.
     
     - Parameter messageArr: Dictionary of last messages.
     */
    private func handleRetrievedLastMesage (messageArr : [Dictionary<String,String>]?) {
        
        if let lastMessageArr = messageArr {
            if !lastMessageArr.isEmpty {
                for messages in lastMessageArr {
                    let text = messages["text"]
                    let utc = messages["utc"]
                    if let _text = text {
                        if let _utcTimeStamp = utc {
                            if Utilities.checkTimeStampValidity(with: _utcTimeStamp) {
                                Utilities.showAlertWithCallBack(aMessageText: _text) {
                                    return
                                }
                            }
                        }
                    }
                }
            } else {
                //got empty message as the last message from the server.
            }
        }
        redirectingToHOTURL()
    }
    
    private func handleAddressBook (messageArr : [Dictionary<String,String>]?) {
        
        if let AddressBook = messageArr {
            if !AddressBook.isEmpty {
                
                for addresses in AddressBook {
                    let serverURL = addresses["ldap_svr_url"]
                    let searchBase = addresses["search_base"]
                    if let _serverURL = serverURL {
                        if let _searchBase = searchBase {
                            if AddressBook.count >= 1 {
                                serverURLArray.append(_serverURL)
                                searchBaseArray.append(_searchBase)
                            } else {
                            }
                        }
                    }
                }
                Utilities.editConfigPlist(searchBase: searchBaseArray, serverURL: serverURLArray)
            } else {
                //got empty message as the last message from the server.
            }
        }
        //redirectingToHOTURL()
    }
    
    /**
     This method is used to handle Menu model of the selected RCCD file.
     The UserModel contains all the information of the selected RCCD file, parse it to show corresponding services.
     
     - Parameter UserModel: Stores information of the selected RCCD file.
     */
    private func handleMenuModel(_ rccdModel:rccd?) {
        
        let userModel = rccdModel?.users[0]
        resetAll(aServicesArray: true, username: nil)
        var serviceArr = [String]()
        
        guard let _ = userModel else {
            showRCCDServices.removeAllItems()
            return
        }
        
        //parse UserModel to retrieve services in it
        if let provider = userModel?.Providers[0] {
            for i in 0..<provider.Services.count  {
                let services = provider.Services[i].Name
                serviceArr.append(services)
            }
            //parse UserModel to get RCCD logo
            guard let imageLogo = userModel?.Providers[0].imageLogo
                else {
                    showRCCDServices.removeAllItems()
                    lImageView.image = #imageLiteral(resourceName: "logo")
                    showRCCDServices.addItems(withTitles: serviceArr)
                    return
            }
            
            showRCCDServices.removeAllItems()
            if let imageData = NSImage(data: imageLogo) {
                //show image logo to the corresponding selected RCCD on the UI
                lImageView.image = imageData
            } else {
                lImageView.image = #imageLiteral(resourceName: "logo")
            }
            
            //shuffles the service array
            serviceArr = swapLastSelectedService(serviceArr)
            
            //gets the username for the associated service from the database.
            if let lastEnteredUsername = UserDetailsHandler.getUsername(from: (rccdModel?.name)!, for: serviceArr[0]) {
                DispatchQueue.main.async {
                    //if username is stored in the database, sets it in the username textfield.
                    self.lUserNameTextField.stringValue = lastEnteredUsername
                }
            }
            
            //show services to the corresponding selected RCCD on the UI
            showRCCDServices.addItems(withTitles: serviceArr)
        }
    }
    
    /**
     This function is used to handle the selected service of the drop down menu or the PopUpButton.
     In this method, the last saved username for the selected service is taken from the database and is value is populated in the Username textfield.
     - Parameter service: the service name for which the username is required.
     - Returns: the username associated with the service, if present in the database, otherise an empty value is returned.
     */
    private func handleServiceSelection(service : String?) {
        //variable to store the username value, if present , otherwise set to empty.
        var usernameSavedWithService = ""
        if let _service = service {
            //gets the username associated with the given service, if present in the database
            let lastSavedUsername = UserDetailsHandler.getUsername(from: (selectedRCCD?.name)!, for: _service)
            if let _username = lastSavedUsername {
                //if username exits, stores it in a variable
                usernameSavedWithService = _username
            } 
        }
        DispatchQueue.main.async {
            self.lUserNameTextField.stringValue = usernameSavedWithService
            self.lPasswordTextField.stringValue = ""
        }
    }
    
    /**
     This method is used to shuffle the services array present in the selected rccd file.
     In this , the services array elements are shuffled and the first element of this array is replaced with the last service used by the user.
     - Parameter rccdServices: An array of services present in the selected rccd file, which needs to be shuffled.
     - Returns: An array , with the last used service at the initial index.
     */
    private func swapLastSelectedService(_ rccdServices: [String]?) -> [String] {
        //gets the last used service name in the given rccd file.
        let lastEntry = UserDetailsHandler.getLastSavedEntry()
        
        if var arrServices = rccdServices {
            //iterating through the service array.
            for i in 0..<arrServices.count {
                //if any element matches the last used service
                if arrServices[i] == lastEntry?.service {
                    //swapping the required element with the zero index element of the array.
                    let temp = arrServices[i]
                    arrServices[i] = arrServices[0]
                    arrServices[0] = temp
                    //returns the shuffled array.
                    return arrServices
                }
            }
        } else {
            return rccdServices!
        }
        return rccdServices!
    }
    
    /**
     This method is used to set up the VCModel instances for the callbacks, So that when the variables will set then the appropriate actions can be taken.
     */
    private func setUpModel() {
        //set up the alert message closure with an alert.
        vcmodel.showAlertClosure = { [weak self] () in
            DispatchQueue.main.async {
                if let message = self?.vcmodel.alertMessage {
                    //shows alert with the encountered message.
                    let _ = Utilities.showAlert(aMessageText: message, tag: 1)
                }
            }
        }
        
        //set up the delay closure, when the delay is encountered
        vcmodel.delayTimeClosure = { [weak self] () in
            DispatchQueue.main.async {
                if let delayTime = self?.vcmodel.delayTime {
                    print("delayTime is :::::::\(delayTime)")
                    //starts the Timer with the encountered delay time.
                    self?.setTimerWithDelay(delay: delayTime)
                }
            }
        }
        
        //set up the challenge closure, when the challenge is encountered.
        vcmodel.showChallengeClosure = {[weak self] (challengeType,challengeValue) in
            DispatchQueue.main.async {
                //calls to handle the challenge.
                self?.handleChallenges(challengeType: challengeType, challengeValue: challengeValue)
            }
        }
        
        vcmodel.updateLoadingStatus = { [weak self] () in
            DispatchQueue.main.async {
                if let loading = self?.vcmodel.isLoading {
                    if loading {
                        self?.startLoader()
                    }
                    else {
                        self?.stopLoader()
                    }
                }
            }
        }
        
        vcmodel.successFullResponse = { [weak self] (urlType) in
            DispatchQueue.main.async {
                self?.handleAPIs(typeUrl: urlType)
            }
        }
        
        vcmodel.setCookie = { [weak self] () in
            DispatchQueue.main.async {
                if let cookie = self?.vcmodel.serverCookie {
                    //sets the server cookie into the local variable to be used further into the app.
                    self?.handleCookie(response: cookie)
                }
            }
        }
        
        vcmodel.setCertifcateData = { [weak self] () in
            DispatchQueue.main.async {
                if let _dataCert = self?.vcmodel.certificateData {
                    //sets the server cookie into the local variable to be used further into the app.
                    dataCert = _dataCert
                }
            }
        }
        
        vcmodel.retrieveLastMessage = { [weak self] (lastmessage) in
            DispatchQueue.main.async {
                self?.handleRetrievedLastMesage(messageArr: lastmessage)
            }
        }
        
        vcmodel.retrieveAddressBook = { [weak self] (addressBook) in
            DispatchQueue.main.async {
                self?.handleAddressBook(messageArr: addressBook)
            }
        }
    }
    
    /**
     This method is used to start the activity indicator on the UI to inform the user about the sysytem activity and also to restrict them to perform any other activity other than the one which is already executing
     */
    private func startLoader() {
        self.view.addSubview(mLoaderView!)
        self.lLoginButton.isEnabled = false
    }
    
    /**
     This method is used to remove or stop the activity indicatior after the system perform any activity.
     */
    private func stopLoader() {
        mLoaderView?.removeFromSuperview()
        self.lLoginButton.isEnabled = true
    }
    
    /**
     This method is used to retrieve the cookie , send by the server inrder to utilize it, further into the application.
     - Parameter cookie: The cookie value recieved from the server
     */
    private func handleCookie(response cookie:String?) {
        guard let _cookie = cookie , !_cookie.isEmpty else {
            return
        }
        
        //if cookie contains any value, then it will be stored into a local variable.
        serverResponseCookie = _cookie
        Utilities.init().logger.write("cookie retrived by the hello hit")
    }
    
    
    /**
     This method is used to handle the challenge when the user encounters it.
     
     - Parameter challengeType: Type of challenge encountered.
     - Parameter challengeValue: The Challenge message encountered.
     */
    private func handleChallenges(challengeType:ChallengeResult,challengeValue:String) {
        
        Utilities.init().logger.write("challenge encountered by the user")
        
        //sets the name of challenge in a variable
        challengeMessage = challengeValue
        challengeName = ChallengeResult.PassWordChallenge.rawValue
        
        //calls to display the challenge view to the user, to register their response.
        showChallengeView(challengeValue,false)
    }
    
    /**
     This method is used to display the challenge view with the encountered challenge message.
     
     - Parameter message: The challenge message encountered.
     - Parameter toHide: A bool value to indicate the visibility of the challenge View.
     */
    private func showChallengeView(_ message:String,_ toHide:Bool) {
        //makes the challenge view visible to the user.
        //self.view.viewWithTag(222)?.isHidden = toHide
        
        //sets the challenge message on the view.
        guard let response = Utilities.showChallengeAlert(aMessageText: message) else {
            let _ = Utilities.showPopupAlert(aMessageText: "response_empty_terminating_string".localized(UserDefaults.standard.value(forKey: "LanguageChangeSelected") as! String))
            return
        }
        challengePopUpOkClicked(response)
    }
    
    /**
     This method is used to redirect to hotURL.
     in this after successful communication i.e. when certificate has been received, redirection happens at hotURL .
     */
    private func redirectingToHOTURL () {
        guard let services = selectedRCCD?.users[0].Providers[0].Services else {
            return
        }
        let lastDownloadedCert = DownloadedCertificateHandler.getCertificateInformation(rccd: (selectedRCCD?.name)!, for: showRCCDServices.titleOfSelectedItem!)
        for service in services {
            if service.Name == showRCCDServices.titleOfSelectedItem! {
                if !service.Uri.isEmpty && !(lastDownloadedCert?.downloadedCert?.cert?.isSMIME ?? false) {
                    if let hotURl = URL.init(string: service.Uri) {
                        NSWorkspace.shared.open(hotURl)
                    }
                }
            }
        }
    }
    //MARK:- Timer or Delay handling
    
    /**
     This method is used to handle the view when the delay is encountered.
     in this the timer will be updated and the view will be updated accordingly.
     */
    private func handleAfterDelay(_ isTimerStarted:Bool) {
        //if timer is  already started.
        if isTimerStarted {
            if delayTimeInSeconds > 0 {
                //This will decrement(count down)the seconds.
                delayTimeInSeconds -= 1
                //disable the authentication button.
                setLoginBtn(true)
            } else {
                //stops the timer.
                timer.invalidate()
                timer = Timer()
                isTimerRunning = false
                self.delayTimeInSeconds = 0
                
                //enables the authentication button.
                setLoginBtn(false)
            }
        } else {
            setLoginBtn(false)
        }
        
    }
    
    /**
     This will enable the authentication button, according to the working of the timer.
     - Parameter isWaiting: A bool value, indication the running of the timer.
     */
    private func setLoginBtn(_ isWaiting:Bool) {
        if isWaiting {
            //if the timer is running, then the button will be disabled, and updated with the delay time left.
            lLoginButton?.isEnabled = false
            let waitString = "wait_string".localized(UserDefaults.standard.value(forKey: "LanguageChangeSelected") as! String)
            lLoginButton?.title? = "\(waitString)- \(delayTimeInSeconds)s"
        } else {
            //if timer is stopped or invalidate, then the button will be enabled.
            lLoginButton?.isEnabled = true
            lLoginButton?.title? = "login_button_string".localized(UserDefaults.standard.value(forKey: "LanguageChangeSelected") as! String)
        }
    }
    
    /**
     This method is used to schedule the Timer with time duration equal to the delay time encountered.
     - Parameter delay: The time duration for which the timer needs to be scheduled.
     */
    private func runTimer(delay : Int) {
        //global value is set.
        self.delayTimeInSeconds = delay
        
        //checks , wheather timer is running or not.
        if isTimerRunning == false {
            isTimerRunning = true
            DispatchQueue.main.async {
                self.timer.invalidate()
                //schedules the timer with the delay time duration.
                self.timer = Timer.scheduledTimer(timeInterval: 1, target: self,   selector: (#selector(self.updateTimer)), userInfo: nil, repeats: true)
            }
        }
    }
    
    /**
     This method check , wheather the timer should be continued or not.
     In this when a user encounters a delay for a particular service, then the timer will be scheduled, but they can still use other services other than the one which got delay as a response. So  for other services, timer should not be continued.
     */
    private func shouldTimerContinue() {
        //checks, if the previous selected and current selected service matches.
        if currentSelectedService == lastSelectedService {
            //if matches, then timer should continue.
            setLoginBtn(isTimerRunning)
        } else {
            //if not, then timer is stopped.
            if isTimerRunning {
                isTimerRunning = false
                setLoginBtn(isTimerRunning)
            }
        }
    }
    
    /**
     Sets the Timer, with the delay encountered by the user.
     - Parameter delay: the time the timer needs to be scheduler for a delay.
     */
    private func setTimerWithDelay(delay : Int) {
        Utilities.init().logger.write("delay encountered by the user")
        //executes when the timer is in invalidate state or not running.
        if !isTimerRunning {
            //starts the timer.
            runTimer(delay: delay)
        }
    }
    
    
    //MARK:- OBJC Methods
    /**
     Action/Target method to be called, to Update the timer with the updated delay time.
     */
    @objc func updateTimer() {
        handleAfterDelay(isTimerRunning)
    }
    
    
    //MARK:- Public Methods
    /**
     This method is used to reset the view to its default or initial state.
     With all the variables being initialized to its default value.
     
     - Parameter aServicesArray: A bool value, indicating wheather to delete or reset all the services or not.
     - Parameter username : The username value needed to be displayed on the username textfield
     */
    func resetAll(aServicesArray: Bool,username: String?) {
        DispatchQueue.main.async {
            self.lPasswordTextField.stringValue = ""
            self.lUserNameTextField.stringValue = username ?? ""
        }
    }
    
    /**
     This method is used to retrive the user reponse , according to the challenge encountered.
     - Parameter userResponse:The response of the user corresponding to the challenge faced.
     */
    func challengePopUpOkClicked(_ userResponse: String) {
        //creating the response array.
        let challengeModelArr = [ChallengeModel.init(message: challengeMessage, response: userResponse)]
        let challengeUserModel = ChallengeUserResponse.init(challenges: challengeModelArr)
        
        let jsonData = try! JSONEncoder().encode(challengeUserModel)
        let jsonChallengeStr = String.init(data: jsonData, encoding: .utf8)
        gChallengeModelStr = jsonChallengeStr
        
        //calls for challenge authentication.
        vcmodel.requestForApiService(urlType: .challenge)
    }
    
    
    
}



