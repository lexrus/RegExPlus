//
//  LibraryView+Data.swift
//  RegEx+
//
//  Created by Lex on 2020/5/3.
//  Copyright © 2020 Lex.sh. All rights reserved.
//

import CoreData


extension LibraryView {
    
    func deleteRegEx(indexSet: IndexSet) {
        let source = indexSet.first!
        let regEx = regExItems[source]
        managedObjectContext.delete(regEx)
        
        save()
    }
    
    func addRegEx() {
        let regEx = RegEx(context: managedObjectContext)
        regEx.raw = #"(\$[\d]+)\.?(\d{2})?"#
        regEx.allowCommentsAndWhitespace = true
        
        save()
    }
    
    private func save() {
        DataManager.shared.saveContext()
    }
    
}
