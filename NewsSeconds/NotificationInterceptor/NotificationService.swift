//
//  NotificationService.swift
//  NotificationInterceptor
//
//  Created by Anantha Krishnan K G on 03/03/17.
//  Copyright © 2017 Ananth. All rights reserved.
//

#if swift(>=3.0)

    import UserNotifications
    class NotificationService:UNNotificationServiceExtension {
        
        
        var contentHandler: ((UNNotificationContent) -> Void)?
        var bestAttemptContent: UNMutableNotificationContent?
        
        override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
            
            var bestAttemptContent: UNMutableNotificationContent?
            bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
            
            let urlString = request.content.userInfo["attachment-url"] as? String
            if let fileUrl = URL(string: urlString! ) {
                // Download the attachment
                URLSession.shared.downloadTask(with: fileUrl) { (location, response, error) in
                    if let location = location {
                        // Move temporary file to remove .tmp extension
                        let tmpDirectory = NSTemporaryDirectory()
                        let tmpFile = "file://".appending(tmpDirectory).appending(fileUrl.lastPathComponent)
                        let tmpUrl = URL(string: tmpFile)!
                        try! FileManager.default.moveItem(at: location, to: tmpUrl)
                        
                        // Add the attachment to the notification content
                        if let attachment = try? UNNotificationAttachment(identifier: "video", url: tmpUrl, options:nil) {
                            bestAttemptContent?.attachments = [attachment]
                        }
                    }
                    // Serve the notification content
                    contentHandler(bestAttemptContent!)
                    }.resume()
            }
        }
        
        override func serviceExtensionTimeWillExpire() {
            // Called just before the extension will be terminated by the system.
            // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
            if let contentHandler = contentHandler, let bestAttemptContent =  bestAttemptContent {
                contentHandler(bestAttemptContent)
            }
        }
        
    }
#endif
