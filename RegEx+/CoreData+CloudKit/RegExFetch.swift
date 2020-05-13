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
        return NSFetchRequest<RegEx>(entityName: "RegEx")
    }

    @nonobjc public class func fetchAllRegEx() -> NSFetchRequest<RegEx> {
        let req: NSFetchRequest<RegEx> = RegEx.fetchRequest()
        req.sortDescriptors = [
            NSSortDescriptor(key: "updatedAt", ascending: false),
            NSSortDescriptor(key: "createdAt", ascending: false)
        ]
        return req
    }

}
