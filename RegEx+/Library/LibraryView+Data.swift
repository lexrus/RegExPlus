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
    
    func addRegEx(withSample: Bool) {
        let regEx = RegEx(context: managedObjectContext)

        if withSample, let randomItem = sampleData().randomElement() {
            regEx.name = randomItem.name
            regEx.raw = randomItem.raw
            regEx.sample = randomItem.sample
            regEx.allowCommentsAndWhitespace = randomItem.allowComments
            regEx.createdAt = Date()
        } else {
            regEx.name = NSLocalizedString("Untitled", comment: "Default item name")
            regEx.raw = ""
            regEx.createdAt = Date()
        }

        save()
        editMode = .inactive
    }
    
    private func save() {
        DataManager.shared.saveContext()
    }
    
    private func sampleData() -> [SampleItem] {
        return [
            SampleItem("Dollars", raw: #"(\$[\d]+)\.?(\d{2})?"#),
            SampleItem("Hex", raw: #"#?([a-f0-9]{6}|[a-f0-9]{3})"#, sample: "#336699\n#F2A\nFF9933"),
            SampleItem("Allow Comments", raw: #"(\$[\d]+) # Dollars symbol and digits"#, allowComments: true),
            SampleItem("Roman Numeral", raw: #"M{0,4}(CM|CD|D?C{0,3})(XC|XL|L?X{0,3})(IX|IV|V?I{0,3})"#),
            SampleItem("Email", raw: #"([a-z0-9_\.-]+)@([\da-z\.-]+)\.([a-z\.]{2,6})"#, sample: "ive@apple.com"),
            SampleItem("HTML <li> tag", raw: #"<li>(.*?)</li>"#, sample: "<li>iPhone</li>\n<li>iPad</li>"),
        ]
    }
    
}

private struct SampleItem {
    let name: String
    let raw: String
    let sample: String
    let allowComments: Bool
    
    init(_ name: String, raw: String, sample: String = "", allowComments: Bool = false) {
        self.name = name
        self.raw = raw
        self.sample = sample
        self.allowComments = allowComments
    }
}
