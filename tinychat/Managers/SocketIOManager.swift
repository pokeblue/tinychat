//
//  SocketManager.swift
//  tinychat
//
//  Created by yongkeun oh on 2017-12-10.
//  Copyright © 2017 opengarden. All rights reserved.
//

import UIKit
import ReachabilitySwift
import CoreData

typealias CompletionHandler = () -> Void

public let NewMessageArrivedNotification = Notification.Name("NewMessageArrivedNotification")

class SocketIOManager: NSObject {
    static let sharedInstance = SocketIOManager()

    let reachability = Reachability()
    var socket: SimpleSocket?
    
    override init() {
        super.init()
        
        NotificationCenter.default.addObserver(self, selector: #selector(reachabilityChanged(_:)), name: ReachabilityChangedNotification, object: nil)
        do {
            try reachability?.startNotifier()
        } catch {
            
        }
        
        initSocket()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func initSocket() {
        if socket == nil {
            socket = SimpleSocket()
            socket?.delegate = self
        }
    }
    
    // MARK: socket
    
    func establishConnection() {
        socket?.open()
    }
    
    func closeConnection() {
        socket?.close()
    }
    
    private func becomeOnLine() {
        initSocket()
        establishConnection()
        sendStoredMessages()
    }
    
    private func becomeOffLine() {
        socket?.terminate()
        socket = nil
    }
    
    func sendMessage(msg: String, date: Date? = nil, data: NSManagedObject? = nil) {
        let currentDate = date ?? Date()
        
        guard let reachability = reachability, reachability.isReachable else {
            if data == nil {
                CoreDataManager.sharedInstance.storeMessage(msg: msg, date: currentDate)
            }
            return
        }
        
        let message = Message(
            msg: msg,
            command: nil,
            since: nil,
            client_time: timeIntervalFromDate(currentDate),
            server_time: nil
        )
        
        if let _ = socket?.sendMessage(message: message) {
            if let data = data {
                CoreDataManager.sharedInstance.removeMessage(data)
            }
        } else {
            if data == nil {
                CoreDataManager.sharedInstance.storeMessage(msg: msg, date: currentDate)
            }
        }
    }

    private func sendStoredMessages() {
        guard let reachability = reachability, reachability.isReachable else {
            return
        }
        
        DispatchQueue.global(qos: .background).async { [weak self] in
            self?.storedMessage()
        }
    }
    
    private func storedMessage() {
        if let results = CoreDataManager.sharedInstance.fetchStoredMessage() {
            for data in results {
                if let msg = data.value(forKey: "msg") as? String, let date = data.value(forKey: "client_time") as? Date {
                    sendMessage(msg: msg, date: date, data: data)
                }
            }
        }
    }
    
    func getChatMessages() {
        let syncDate = timeIntervalFromDate(lastSyncDate(isSet: false))
        
        let message = Message(
            msg: nil,
            command: "history",
            since: syncDate,
            client_time: timeIntervalFromDate(Date()),
            server_time: nil
        )
        
        _ = socket?.sendMessage(message: message)
        _ = lastSyncDate(isSet: true)
    }
    
    private func lastSyncDate(isSet: Bool) -> Date {
        let defaults = UserDefaults.standard
        
        if isSet {
            let date = Date()
            defaults.set(date, forKey: "lastSyncDate")
            return date
        } else {
            return defaults.object(forKey: "lastSyncDate") as? Date ?? Date()
        }
    }
    
    private func timeIntervalFromDate(_ date: Date) -> Double {
        return date.timeIntervalSince1970 * 1000
    }
    
    // MARK: Notification
    
    @objc func reachabilityChanged(_ note: Notification) {
        if let reachability = note.object as? Reachability {
            DispatchQueue.main.async { [weak self] in
                if reachability.isReachable {
                    self?.becomeOnLine()
                } else {
                    self?.becomeOffLine()
                }
            }
        }
    }
}

// MARK: SimpleSocketDelegate

extension SocketIOManager: SimpleSocketDelegate {
    func receivedMessage(message: Message) {
        _ = lastSyncDate(isSet: true)
        NotificationCenter.default.post(name: NewMessageArrivedNotification,
                                        object: nil,
                                        userInfo: ["message": message]
        )
    }
}
