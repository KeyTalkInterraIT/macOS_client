//
//  Defines.swift
//  KeyTalk client
//
//  Created by Rinshi Rastogi
//  Copyright © 2018 KeyTalk. All rights reserved.
//

import Foundation

var bgkeytalkCookie = ""
var keytalkCookie = ""
var username = ""
var password = ""
var serviceName = ""
var hwsigRequired = false

var isBackgroundTaskRunning = false

var keyCertValidity = "cert_validity"
var keyCertData = "cert_data"

//variable for challenge response
var challengeName = ""
var gChallengeModelStr : String? = nil

let SERVER_FAIL_MSG = "error_connection_string".localizedNotify(UserDefaults.standard.value(forKey: "LanguageChangeSelected") as! String)
let EMAIL_REPORT_HTML = "email_report_html_string".localizedNotify(UserDefaults.standard.value(forKey: "LanguageChangeSelected") as! String);
// Email subject
let EMAIL_REPORT_SUBJECT = "email_report_subject_string".localizedNotify(UserDefaults.standard.value(forKey: "LanguageChangeSelected") as! String);

var gDownloadedCertificateModel : DownloadedCertificate? = nil
var gBGDownloadedCertificateModel : DownloadedCertificate? = nil
var gTempUserModel : UserModel? = nil
var gParsedModelArray = [UserModel]()
var gRCCDData = [String]()
var gRCCDImageData = [Data]()
var gLanguageSelected = "en"

let KEY_KEYTALK_CERTIFICATE = "KEYTALK_CERTIFICATE"
let KEY_FINGERPRINT = "FINGERPRINT"
let KEY_EXPIRY_DATE = "EXPIRYDATE"
let KEY_COMMON_NAME = "COMMONNAME"
let KEY_SERIAL_NUMBER = "SERIALNUMBER"
let KEY_EXTENDED_KEY_USAGE = "EXTENDEDKEYUSAGE"
let KEY_CERTIFICATE_DATA = "CERTIFICATEDATA"
let KEY_SUBJECT_ALTERNATE_NAME = "SUBJECTALTERNATENAME"
let KEY_CRL_URL = "CRLURL"

let CRL_KEY_DB = "CRLKEY"
let LOGIN_KEY_DB = "STARTATLOGIN"
let PERMISSION_KEY_DB = "PERMISSION"
let LANGUAGE_KEY_DB = "LANGUAGESELECTEDS"
