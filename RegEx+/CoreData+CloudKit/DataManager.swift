//
//  DataManager.swift
//  RegEx+
//
//  Created by Lex on 2020/5/3.
//  Copyright © 2020 Lex.sh. All rights reserved.
//

import CoreData
import CloudKit


class DataManager {
    
    static let shared = DataManager()
    
    lazy var persistentContainer: NSPersistentCloudKitContainer = {
        
        let container = NSPersistentCloudKitContainer(name: "RegEx")
        
        guard let description = container.persistentStoreDescriptions.first else {
            fatalError("No Descriptions found")
        }
        description.setOption(true as NSObject, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergePolicy.mergeByPropertyStoreTrump
        
        container.loadPersistentStores(completionHandler: { (_, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        
//        NotificationCenter.default.addObserver(self, selector: #selector(self.processUpdate), name: .NSPersistentStoreRemoteChange, object: nil)
        
        return container
    }()
    
    // MARK: - Initialize CloudKit schema
    
    func initializeCloudKitSchema() {
        do {
            try persistentContainer.initializeCloudKitSchema(options: NSPersistentCloudKitContainerSchemaInitializationOptions.printSchema)
        } catch {
            print(error.localizedDescription)
        }
    }
    
    // MARK: - Core Data Saving support

    func saveContext() {
        let context = self.persistentContainer.viewContext
        guard context.hasChanges else {
            return
        }
        do {
            try context.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nserror = error as NSError
            fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
        }
    }
    
    @objc
    func processUpdate(notification: NSNotification) {
        operationQueue.addOperation {
            let context = self.persistentContainer.newBackgroundContext()
            context.performAndWait {
                let items: [RegEx]
                do {
                    try items = context.fetch(RegEx.fetchAllRegEx())
                } catch {
                    let nserror = error as NSError
                    fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
                }

                items.forEach {
                    print("NAME: \($0.name) !!!!")
                }
                
                if context.hasChanges {
                    do {
                        try context.save()
                    } catch {
                        let nserror = error as NSError
                        fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
                    }
                }
            }
            
        }
    }
    
    private lazy var operationQueue: OperationQueue = {
       var queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        return queue
    }()
    
}
