//
//  ConnectionHandler.swift
//  KeyTalk client
//
//  Created by Rinshi Rastogi
//  Copyright © 2018 KeyTalk. All rights reserved.
//

import Foundation

class ConnectionHandler {
    
    //MARK:- Variables
    var lSeriveName = ""
    var lUsername = ""
    var lServerUrl = ""
    var lPassword = ""
    var lChallengeResponseArr : String? = nil
    var bgKeytalkCookie = ""
    
    //MARK:- Public Methods
    init (servicename: String,username:String,password: String,server:String,challengeResponse:String?){
        self.lSeriveName = servicename
        self.lUsername = username
        self.lPassword = password
        self.lServerUrl = server
        self.lChallengeResponseArr = challengeResponse
    }
    
    /**
     This method is used to request server for response.
     - Parameter forURLType: the URL value containing the URLs used to request the KeyTalk server.
     - Parameter serverCookie: the string value containing the server Cookie.
     - Parameter success: the Bool value determining whether the communication was successful or not.
     - Parameter message: the string value containing the message received in response.
     - Parameter responseData: the Data value containing the response data.
     - Parameter ktCookie: the string value containing the server Cookie received after communication.
     */
    func request(forURLType:URLs, serverCookie:String, completionHandler: @escaping (_ success: Bool, _ message: String?,_ responseData: Data?,_ ktCookie:String?) -> ()) {
        //makes request to the server
        Connection.makeRequest(request: getRequest(urlType: forURLType,ktCookie: serverCookie), isUserInitiated: false) { (success, message,responseData,cookie) in
            if success {
                if let _responseData = responseData {
                    do {
                        //parse the json data and store in dictionary
                        let data = try JSONSerialization.jsonObject(with: _responseData, options: .mutableContainers) as? [String : Any]
                        if let data = data {
                            let status = data["status"] as! String
                            if status == "eoc" {
                                completionHandler(false, "end_of_communication_string".localizedNotify(UserDefaults.standard.value(forKey: "LanguageChangeSelected") as! String),nil,cookie)
                            }
                            else {
                                completionHandler(true, nil,_responseData,cookie)
                            }
                        }
                        else {
                            completionHandler(false, "something_went_wrong_try_string".localizedNotify(UserDefaults.standard.value(forKey: "LanguageChangeSelected") as! String),nil,cookie)
                        }
                    }
                    catch let error {
                        print(error.localizedDescription)
                        completionHandler(false, "something_went_wrong_try_string".localizedNotify(UserDefaults.standard.value(forKey: "LanguageChangeSelected") as! String),nil,cookie)
                    }
                } else {
                    completionHandler(false, "something_went_wrong_try_string".localizedNotify(UserDefaults.standard.value(forKey: "LanguageChangeSelected") as! String),nil,cookie)
                }
            }
            else {
                completionHandler(false, message,nil,cookie)
            }
        }
    }
    
    /**
     This method is used to download the file.
     - Parameter url: the URL value containing the URLs used to download file.
     - Parameter fileurl: the URL value containing the URL of the file path where the file needs to be saved after download.
     - Parameter message: the string value containing the message received in response.
     */
    func downloadFile(url: URL, completionHandler: @escaping (_ fileurl: URL?, _ message: String?) -> ()) {
        let request = URLRequest.init(url: url)
        Connection.downloadFile(request: request) { (fileUrl, message) in
            if let message = message {
                completionHandler(nil, message)
            }
            else {
                completionHandler(fileUrl, nil)
            }
        }
    }
    
    /**
     This method is used to get request URL.
     - Parameter urlType: the URL value containing the URL Types needed to request the KeyTalk server.
     - Parameter ktCookie: the string value containing the server Cookie received after communication.
     - Returns: A URLRequest containing the Request URL.
     */
    func getRequest(urlType: URLs,ktCookie:String) -> URLRequest {
        let server = Server(servicename: lSeriveName, username: lUsername, password: lPassword, server: lServerUrl, challengeResponse: lChallengeResponseArr)
        let url = server.getUrl(type: urlType)
        print("Url::::::: \(url)")
        var request = URLRequest.init(url: url)
        request.timeoutInterval = 60
        request.httpMethod = "GET"
        if !ktCookie.isEmpty {
            request.addValue(ktCookie, forHTTPHeaderField: "Cookie")
            request.addValue("identity", forHTTPHeaderField: "Accept-Encoding")
        }
        return request
    }
    
}



