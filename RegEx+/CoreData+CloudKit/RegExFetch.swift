//
//  RegExFetch.swift
//  RegEx+
//
//  Created by Lex on 2020/5/3.
//  Copyright © 2020 Lex.sh. All rights reserved.
//

import CoreData


extension RegEx {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<RegEx> {
        NSFetchRequest<RegEx>(entityName: "RegEx")
    }

    @nonobjc public class func fetchAllRegEx() -> NSFetchRequest<RegEx> {
        let req: NSFetchRequest<RegEx> = RegEx.fetchRequest()
        req.sortDescriptors = [
            NSSortDescriptor(key: "createdAt", ascending: false),
            NSSortDescriptor(key: "updatedAt", ascending: false)
        ]
        return req
    }

    @nonobjc public class func fetch(byID ID: NSManagedObjectID) -> NSFetchRequest<RegEx> {
        let req: NSFetchRequest<RegEx> = RegEx.fetchRequest()
        req.predicate = NSPredicate(format: "self.objectID IN %@", ID)
        return req
    }

}
