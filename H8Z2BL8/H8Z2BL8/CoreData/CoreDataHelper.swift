//
//  CoreDataHelper.swift
//  H8Z2BL8
//
//  Created by Abby Thompson on 10/7/17.
//  Copyright © 2017 althomp. All rights reserved.
//

import CoreData

class CoreDataHelper {
    static func checkCoreData(for code: String, entityName: String, with uniqueIdentifier: String, context: NSManagedObjectContext) -> Any? {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        fetchRequest.predicate = NSPredicate(format: "\(uniqueIdentifier) == %@", code)
        fetchRequest.fetchBatchSize = 1
        do {
            let results = try context.fetch(fetchRequest)
            if results.count > 0 {
                return results[0]
            }
        } catch { print("checkCoreDataFor error \(error)") }
        return nil
    }
    
    static func coreDataContains(_ entityName: String, context: NSManagedObjectContext) -> Bool {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        fetchRequest.fetchBatchSize = 1
        do {
            let results = try context.fetch(fetchRequest)
            if results.count > 0 {
                return true
            }
        } catch { print("coreDataContains error \(error)") }
        return false
    }
    
    static func removeOldObjects(for entityName: String, with uniqueIdentifier: String, newObjects ids: Set<String>, context: NSManagedObjectContext) {
        if ids.count > 0 {
            let ooFetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
            ooFetchRequest.predicate = NSPredicate(format: "NOT \(uniqueIdentifier) IN %@", ids)
            do {
                let outdatedObjects = try context.fetch(ooFetchRequest)
                for obj in outdatedObjects {
                    context.delete(obj as! NSManagedObject)
                }
            } catch { print("removeOldObjects error \(error)")  }
        }
        
    }
}
