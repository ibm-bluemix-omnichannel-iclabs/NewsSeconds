//
//  AppDelegate.swift
//  NewsSeconds
//
//  Created by Anantha Krishnan K G on 02/03/17.
//  Copyright © 2017 Ananth. All rights reserved.
//

import UIKit
import BMSPush
import BMSCore
import SwiftMessages
import AVFoundation
import RestKit
import TextToSpeechV1
import UserNotifications
import UserNotificationsUI

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate,AVAudioPlayerDelegate {
    
    
    //OpenWhisk Credentials
    var whiskAccessKey:String = ""
    var whiskAccessToken:String = ""
    var whiskActionName:String = "GetLatestNewsAPI" // Your action name
    var whiskNameSpace:String = "IMF_Push_kgspace"  // OpenWhisk work space

     //Push Service Credentials
    var pushAppGUID:String = ""
    var pushAppClientSecret:String = ""
    var pushAppRegion:String = ""
    
    //Watson Text-to-speech credentials
    var watsonTextToSpeachUsername:String = ""
    var watsonTextToSpeachPassword:String = ""
    
    //News API key - From https://newsapi.org/
    var newsAPIKey:String = ""

    
    weak var gameTimer: Timer?
    var soundPlayer: AVAudioPlayer?
    var audioPlayer = AVAudioPlayer() // see note below
    var window: UIWindow?
    
    var urlToOpen:String = UserDefaults.standard.value(forKey: "urlToOpen") != nil ?  UserDefaults.standard.value(forKey: "urlToOpen") as! String : ""

    var sourceDescription:String = UserDefaults.standard.value(forKey: "sourceDescription") != nil ?  UserDefaults.standard.value(forKey: "sourceDescription") as! String : "ABC News"

    var source:String = UserDefaults.standard.value(forKey: "sourceValue") != nil ?  UserDefaults.standard.value(forKey: "sourceValue") as! String : "abc-news-au"
    var sourceID:Int = UserDefaults.standard.value(forKey: "sourceValueID") != nil ?  UserDefaults.standard.integer(forKey:"sourceValueID")  : 0
    var oldSource:String = UserDefaults.standard.value(forKey: "oldSourceValue") != nil ?  UserDefaults.standard.value(forKey: "oldSourceValue") as! String :"abc-news-au"
    var valueChanged:Bool = false
    var doIt = false

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
         doIt = false

        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UserDefaults.standard.set("", forKey: "newsURL")
        UserDefaults.standard.synchronize()
        urlToOpen = ""
        UIApplication.shared.applicationIconBadgeNumber = 0;
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()


        if (UserDefaults.standard.bool(forKey: "isPushEnabled")){
            registerForPush()
        }
        
        gameTimer?.invalidate()
        let ff = Date()
        
        let dateComponentsFormatter = DateComponentsFormatter()
        dateComponentsFormatter.allowedUnits = [.year,.month,.weekOfYear,.day,.hour,.minute,.second]
        dateComponentsFormatter.maximumUnitCount = 1
        dateComponentsFormatter.unitsStyle = .full
        dateComponentsFormatter.string(from: Date(), to: ff)
        
        return true
    }
    
    func registerForPush () {
        
        let myBMSClient = BMSClient.sharedInstance
        myBMSClient.initialize(bluemixRegion: pushAppRegion)
        let push =  BMSPushClient.sharedInstance
        push.initializeWithAppGUID(appGUID: pushAppGUID, clientSecret:pushAppClientSecret)
        
    }
    func unRegisterPush () {
        
        // MARK:  RETRIEVING AVAILABLE SUBSCRIPTIONS
        
        let push =  BMSPushClient.sharedInstance
        
        push.unregisterDevice(completionHandler: { (response, statusCode, error) -> Void in
            
            if error.isEmpty {
                print( "Response during unregistering device : \(response)")
                print( "status code during unregistering device : \(statusCode)")
                UIApplication.shared.unregisterForRemoteNotifications()
            }
            else{
                print( "Error during unregistering device \(error) ")
            }
        })
        
    }
    
    func registerForTag(){
        
        if (UserDefaults.standard.bool(forKey:"isPushEnabled")){
            
            let push =  BMSPushClient.sharedInstance
            
            push.unsubscribeFromTags(tagsArray: [self.oldSource]) { (response, status, error) in
                
                if error.isEmpty {
                    
                    print( "Response during device Unsubscribing : \(response)")
                    
                    print( "status code during device Unsubscribing : \(status)")
                    
                    push.subscribeToTags(tagsArray: [self.source]) { (response, status, error) in
                        
                        if error.isEmpty {
                            print( "Response during device subscription : \(response)")
                            print( "status code during device subscription : \(status)")
                           
                        }
                        else{
                            print( "Error during device subscription \(error) ")
                            
                        }
                    }
                }
                else{
                    print( "Error during Unsubscribing \(error) ")
                    
                }
            }
        }else{
            self.showAlert(title: "Error !!!", message: "Enable Push Service",theme: .error)
        }
    }
    
    func application (_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data){
        
        let push =  BMSPushClient.sharedInstance
        
        push.registerWithDeviceToken(deviceToken: deviceToken) { (response, statusCode, error) -> Void in
            
            if error.isEmpty {
                
                print( "Response during device registration : \(response)")
                
                print( "status code during device registration : \(statusCode)")
                
                push.subscribeToTags(tagsArray: [self.source]) { (response, status, error) in
                    
                    if error.isEmpty {
                        
                        print( "Response during device subscription : \(response)")
                        
                        print( "status code during device subscription : \(status)")
                    }
                    else{
                        print( "Error during device subscription \(error) ")
                    }
                }
            }
            else{
                print( "Error during device registration \(error) ")
            }
        }
    }
    
    //Called if unable to register for APNS.
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        
        let message:String = "Error registering for push notifications: \(error.localizedDescription)" as String
        
        self.showAlert(title: "Registering for notifications", message: message, theme: .warning)
        
    }
    
    func showTimer(date:Date) -> Bool {
        
        while(Date().minutes(from:date) < 1){
            print(Date().minutes(from:date))
        }
        return true
    }
   
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
        let payLoad = ((((userInfo as NSDictionary).value(forKey: "aps") as! NSDictionary).value(forKey: "alert") as! NSDictionary).value(forKey: "body") as! String)
        
        self.showAlert(title: "Recieved Push notifications", message: payLoad, theme: .info)
        
        
        if(UIApplication.shared.applicationState == .active){
            
            print("Will not play the sound")
           
        }else if(UserDefaults.standard.bool(forKey: "isWatsonEnabled")) {
            doIt = true
            
            
         // if(showTimer(date: Date()) && doIt){
            //Timer.scheduledTimer(withTimeInterval: 10, repeats: false){_ in
            let payLoadAlert = (((userInfo as NSDictionary).value(forKey: "aps") as! NSDictionary).value(forKey: "alert") as! NSDictionary)
            
            let respJson = (userInfo as NSDictionary).value(forKey: "payload") as! String
            let data = respJson.data(using: String.Encoding.utf8)
            
            let jsonResponse:NSDictionary = try! JSONSerialization.jsonObject(with: data! , options: JSONSerialization.ReadingOptions.allowFragments) as! NSDictionary
        
            let messageValue:String = jsonResponse.value(forKey: "data") as! String
            let newsURL:String = jsonResponse.value(forKey: "newsURL") as! String
            
            UserDefaults.standard.set(newsURL, forKey: "newsURL")
            UserDefaults.standard.synchronize()
            self.urlToOpen = newsURL
        
        let title = "Latest News From \(self.sourceDescription)"
        let subtitle = payLoadAlert.value(forKey: "body") as! String;
        let alert = messageValue
            
            
            let watsonMessage = "\(title), \(subtitle), \(alert)"
                do {
                    try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback, with: .duckOthers)
                    try AVAudioSession.sharedInstance().setActive(true)
                    UIApplication.shared.beginReceivingRemoteControlEvents()
                    let textToSpeech = TextToSpeech(username:watsonTextToSpeachUsername, password: watsonTextToSpeachPassword)
                    
                    textToSpeech.synthesize(watsonMessage as String, success: { data in
                        
                        self.audioPlayer = try! AVAudioPlayer(data: data)
                        self.audioPlayer.prepareToPlay()
                        //self.audioPlayer.play()
                        
                        if #available(iOS 10.0, *) {
                            let content = UNMutableNotificationContent()
                            
                            content.title = title
                            content.subtitle = subtitle
                            content.body = alert
                            
                            // Deliver the notification in five seconds.
                            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
                            let request = UNNotificationRequest(identifier: "watsonPush", content: content, trigger: trigger)
                            
                            // Schedule the notification.
                            let center = UNUserNotificationCenter.current()
                            center.delegate = self
                            center.removeAllPendingNotificationRequests()
                            center.removeAllDeliveredNotifications()
                            // self.audioPlayer.play()
                            completionHandler(UIBackgroundFetchResult.newData)
                            center.add(request) { (error) in
                                print("Success")
                                self.audioPlayer.play()
                            }
                        } else {
                            // Fallback on earlier versions
                        }
                        print("should have been added")
                    })
                }
                catch {}
         // }
        }
    }
    
    func showAlert (title:String , message:String, theme:Theme){
        
        // create the alert
       
        
        
        let view = MessageView.viewFromNib(layout: .CardView)
        
        // Theme message elements with the warning style.
        view.configureTheme(theme)
        var iconText = "😊"
        
        switch theme {
        case .error:
            iconText = "😱"
            break;
            
        case .success:
            iconText = "👏"
            break;
            
        case .warning:
            iconText = "🙄"
            break;
            
        case .info:
            iconText = "😊"
            break;
        }
        // Add a drop shadow.
        view.configureDropShadow()
        // Set message title, body, and icon. Here, we're overriding the default warning
        // image with an emoji character.
        view.configureContent(title: title, body: message, iconText: iconText)
        view.button?.isHidden = true
        // Show the message.
        SwiftMessages.show(view: view)

    }
    func applicationDidBecomeActive(_ application: UIApplication) {
        doIt = false
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
        if(urlToOpen.isEmpty) == false{
            UIApplication.shared.open(URL(string: urlToOpen)!, options: [:], completionHandler: nil)
            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
            UserDefaults.standard.set("", forKey: "newsURL")
            UserDefaults.standard.synchronize()
            urlToOpen = ""
            doIt = false
            audioPlayer.stop()
            UIApplication.shared.applicationIconBadgeNumber = 0;
            UIApplication.shared.cancelAllLocalNotifications()
        }
    }
    func applicationDidEnterBackground(_ application: UIApplication) {
        UIApplication.shared.beginBackgroundTask(expirationHandler: nil)
        UIApplication.shared.beginReceivingRemoteControlEvents()
    }
}

extension Date {
    
    /// Returns the amount of minutes from another date
    func minutes(from date: Date) -> Int {
        return Calendar.current.dateComponents([.minute], from: date, to: self).minute ?? 0
    }
    func seconds(from date: Date) -> Int {
        return Calendar.current.dateComponents([.second], from: date, to: self).second ?? 0
    }
    
    /// Returns the a custom time interval description from another date
    func offset(from date: Date) -> String {
        
        if minutes(from: date) >= 0 { return "\(minutes(from: date))" }
        if seconds(from: date) >= 0 { return "\(seconds(from: date))" }
        return ""
    }
}

