//
//  ViewController.swift
//  tinychat
//
//  Created by yongkeun oh on 2017-12-10.
//  Copyright © 2017 opengarden. All rights reserved.
//

import UIKit
import ReachabilitySwift

class ViewController: UIViewController,UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate {

    @IBOutlet weak var tableView: UITableView?
    @IBOutlet weak var textField: UITextField?
    @IBOutlet weak var messageInputViewConstraint: NSLayoutConstraint?
    
    var chatMessages = [Message]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        initNotifications()
        
        tableView?.register(UINib(nibName: "ChatTableViewCell", bundle: nil), forCellReuseIdentifier: "ChatTableViewCellId")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        fetchMessages()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: IBAction Methods
    
    @IBAction func sendMessage(sender: AnyObject) {
        if let text = textField?.text, text.count > 0 {
            SocketIOManager.sharedInstance.sendMessage(msg: text)

            textField?.text = ""
            textField?.resignFirstResponder()
        }
    }
    
    // MARK: Notifications
    
    func initNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardDidShowNotification(_:)), name: Notification.Name("UIKeyboardDidShowNotification"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardDidHideNotification(_:)), name: Notification.Name("UIKeyboardDidHideNotification"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(reachabilityChanged(_:)), name: ReachabilityChangedNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(newMessageArrived(_:)), name: NewMessageArrivedNotification, object: nil)
    }
    
    @objc func reachabilityChanged(_ note: Notification) {
        if let reachability = note.object as? Reachability, reachability.isReachable {
            fetchMessages()
        }
    }
    
    @objc func handleKeyboardDidShowNotification(_ note: Notification) {
        if let userInfo = note.userInfo {
            if let keyboardFrame = (userInfo[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
                messageInputViewConstraint?.constant = -keyboardFrame.size.height
                view.layoutIfNeeded()
            }
        }
    }
    
    @objc func handleKeyboardDidHideNotification(_ note: Notification) {
        messageInputViewConstraint?.constant = 0
        view.layoutIfNeeded()
    }
    
    @objc func newMessageArrived(_ note: Notification) {
        if let userInfo = note.userInfo, let message = userInfo["message"] as? Message {
            chatMessages.append(message)
            tableView?.reloadData()
            tableView?.scrollToRow(at: IndexPath(row:chatMessages.count-1,section:0), at: .bottom, animated: true)
        }
    }
    
    // MARK: UITextField Delegate
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    // MARK: fetch
    
    func fetchMessages() {
        // Wait for stream is open
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            SocketIOManager.sharedInstance.getChatMessages()
        }
    }
    
    func timeStampToString(_ interval: Double?) -> String {
        if let interval = interval {
            let date = Date(timeIntervalSince1970: interval/1000.0)
            let format = DateFormatter()
            format.dateFormat = "dd MMM, YYYY"
            return format.string(from: date)
        }
        return ""
    }
    
    // MARK: UITableView Delegate and Datasource Methods

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return chatMessages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ChatTableViewCellId", for: indexPath) as! ChatTableViewCell
    
        let chatMessage = chatMessages[indexPath.row]
        
        cell.messageLabel?.text = chatMessage.msg
        cell.dateLabel?.text = timeStampToString(chatMessage.client_time)
        
        return cell
    }
}

