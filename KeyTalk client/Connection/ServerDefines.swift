//
//  ServerDefines.swift
//  KeyTalk client
//
//  Created by Rinshi Rastogi
//  Copyright © 2018 KeyTalk. All rights reserved.
//

import Foundation

//MARK:- Enums
public enum URLs: Int {
    case hello
    case handshake
    case authReq
    case authentication
    case challenge
    case certificate
    case addressBook
    case lastMessage
}

public enum AuthResult: String {
    case ok = "OK"
    case delayed = "DELAY"
    case locked = "LOCKED"
    case expired = "EXPIRED"
    case challenge = "CHALLENGE"
}

//Enum for the names of the challenges
public enum ChallengeResult :String {
    case PassWordChallenge = "Password challenge"
}

//Enum for the values of the challenges.
public enum ChallengeType : String {
    case nextToken = "Please Enter the Next Code from Your Token:"
    case otp = "otp"
    case newUserDefinedPin = "Enter your new PIN of 4 to 8 digits,or <Ctrl-D> to cancel the New PIN procedure:"
    case reenterNewPin = "Please re-enter new PIN:"
    case newPinandPasscode = "Wait for the code on your card to change, then enter new PIN and TokenCode\r\n\r\nEnter PASSCODE:"
    case newSystemPushedPin = "Are you prepared to accept a new system-generated PIN [y/n]?"
}

//https://192.168.129.122
var serverUrl = ""
var dataCert = Data()
var bgDataCert = Data()
let rcdpProtocol = "/rcdp/2.4.1"
let port = ":4443"

let HELLO_URL = "/hello"
let HANDSHAKE_URL = "/handshake"
let AUTH_REQUIREMENTS_URL = "/auth-requirements"
let AUTHENTICATION_URL = "/authentication"
let CERTIFICATE_URL = "/cert?format=P12&include-chain=False&out-of-band=True"//PEM&include-chain=True"
let HTTP_METHOD_POST = "POST"
let ADDRESSBOOKURL = "/public/1.0.0/address-book-list?service="
let LASTMESSAGE_URL = "/last-messages"

let DELAY = "DELAY"
let LOCKED = "LOCKED"
let EXPIRED = "EXPIRED"

class Server {
    
    //MARK:- Variables
    var lSeriveName = ""
    var lUsername = ""
    var lPassword = ""
    var lServerUrl = ""
    var lChallengeResponseJSONStr : String? = nil
    
    init (servicename: String,username:String,password: String,server:String,challengeResponse: String?) {
        self.lSeriveName = servicename
        self.lUsername = username
        self.lPassword = password
        self.lServerUrl = server
        self.lChallengeResponseJSONStr = challengeResponse
    }
    //MARK:- Public Methods

    /**
     This method is used to get URL for server communication.
     - Parameter type: URL of different types which when appended generate a valid URL for server communication.
     - Returns: A url with appended urls of different types to generate a valid URL.
     */
     func getUrl(type: URLs) -> URL {
        var urlStr = ""
        switch type {
        case .hello:
            urlStr = lServerUrl + port + rcdpProtocol + HELLO_URL
            break
        case .handshake:
            urlStr = lServerUrl + port + rcdpProtocol + HANDSHAKE_URL + "?caller-utc=\(getISO8601DateFormat())"
            break
        case .authReq:
            urlStr = lServerUrl + port + rcdpProtocol + AUTH_REQUIREMENTS_URL+"?service=\(lSeriveName)"
            break
        case .authentication:
            urlStr = lServerUrl + port + rcdpProtocol + AUTHENTICATION_URL + authentication()
            break
        case .challenge:
            if self.lChallengeResponseJSONStr == nil {
                if let challengeJSONStr = gChallengeModelStr {
                    urlStr = lServerUrl + port + rcdpProtocol + AUTHENTICATION_URL + challengeAuthenticationURL(challenge: challengeJSONStr)
                }
            } else {
                urlStr = lServerUrl + port + rcdpProtocol + AUTHENTICATION_URL + challengeAuthenticationURL(challenge: lChallengeResponseJSONStr!)
            }
            break
        case .certificate:
            urlStr = lServerUrl + port + rcdpProtocol + CERTIFICATE_URL
            break
        case .addressBook:
            urlStr = lServerUrl + port + ADDRESSBOOKURL + lSeriveName
            break
        case .lastMessage:
            urlStr = lServerUrl + port + rcdpProtocol + LASTMESSAGE_URL
            break
        }
        return URL.init(string: urlStr)!
    }
    //MARK:- Private Methods
    /**
     This method is used to get URL to authenticate the device with KeyTalk Server.
     - Returns: A String containing the URL needed for device Authentication.
     */
    private func authentication() -> String {
        let encodedHwsig = Utilities.sha256(securityString: HWSIGCalc.calcHwSignature())
        let hwsig = "CS-" + encodedHwsig
        let modelName = Host.current().name! + Host.current().localizedName!
        let tempStr = "?service=\(lSeriveName)&caller-hw-description=\(modelName)&USERID=\(lUsername)&PASSWD=\(lPassword)&HWSIG=\(hwsig.uppercased())"
        
        let urlStr = tempStr.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        return urlStr
    }
    
    /**
     This method is used to generate the response URL for the challenge Authentication with the challenge name and their corresponding user response. All the information is appended in the base URL and is send to the server to complete the challenge.
     - Parameter aArrDictionary: This is an array of dictionary containing the name of challenge and their reponse in the key value pair format.
     - Returns: A url with appended response from the user.
     */
    private func challengeAuthenticationURL(challenge response:String) -> String {
        //challenge aArrDictionary:[[String:Any]]) -> String {
        let challengeData = response.data(using: .utf8)
        let challengeUserResponse = try! JSONDecoder().decode(ChallengeUserResponse.self, from: challengeData!)
        
        var arrResponse = [[String:Any]]()
        //sets the challeneg name and its corresponding value in the key value pair format.
        var dict : [String:Any] = [String:Any]()
        
        let challengesArr = challengeUserResponse.challenges!
        for challenge in challengesArr {
            dict[challenge.message] = challenge.response
            //appending in the response array.
            arrResponse.append(dict)
        }
        
        //retrieving the array.
        let arr = arrResponse
        
        //encoding the hardware signature required by the server.
        let encodedHwsig = Utilities.sha256(securityString: HWSIGCalc.calcHwSignature())
        
        //adding the prefix.
        let hwsig = "CS-" + encodedHwsig
        
        var passStr = ""
        for dict in arr {
            
            for (_,value) in dict {
                passStr = value as! String//.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        
        //createa a completed string with all the necessary informations.
        let modelName = Host.current().name! + Host.current().localizedName!
        let tempStr = "?service=\(lSeriveName)&caller-hw-description=\(modelName)&USERID=\(lUsername)&PASSWD=\(passStr)&HWSIG=\(hwsig.uppercased())"
        
        //converting it into a valid url format.
        let urlStr = tempStr.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        return urlStr
    }
    
    /**
     This method is used to get date format in ISO 8601 format.
     - Returns: A String date of ISO 8601 format.
     */
    private func getISO8601DateFormat() -> String {
        let dateFormatter = DateFormatter()
        let timeZone = TimeZone.init(identifier: "GMT")
        dateFormatter.timeZone = timeZone
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSS'Z'"
        
        let iso8601String = dateFormatter.string(from: Date())
        print("FormatISO8601String::\(iso8601String)")
        return iso8601String.replacingOccurrences(of: ":", with: "%3A")
    }
}
