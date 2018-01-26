//
//  CoreDataManager.swift
//  tinychat
//
//  Created by yongkeun oh on 2017-12-11.
//  Copyright © 2017 opengarden. All rights reserved.
//

import UIKit
import CoreData

class CoreDataManager: NSObject {
    static let sharedInstance = CoreDataManager()
    
    override init() {
        super.init()

     }
    
    // MARK: - Core Data stack
    
    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
         */
        let container = NSPersistentContainer(name: "tinychat")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    
    lazy var context: NSManagedObjectContext = {
        return persistentContainer.viewContext
    }()
    
    // MARK: - Core Data Saving support
    
    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
    // MARK: data inserting and fetching
    
    func storeMessage(msg: String, date: Date) {
        guard let entity = NSEntityDescription.entity(forEntityName: "PendingMessage", in: context) else {
            return
        }
        
        let pendingMessage = NSManagedObject(entity: entity, insertInto: context)
        pendingMessage.setValue(msg, forKey: "msg")
        pendingMessage.setValue(date, forKey: "client_time")
        
        do {
            try context.save()
        } catch {

        }
    }
    
    func removeMessage(_ msgObject: NSManagedObject) {
        context.delete(msgObject)
        
        do {
            try context.save()
        } catch {
            
        }
    }
    
    func fetchStoredMessage() -> [NSManagedObject]? {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "PendingMessage")
        //request.returnsObjectsAsFaults = false
        
        do {
            return try context.fetch(request) as? [NSManagedObject]
        } catch {

        }
        return nil
    }
}
