//
//  LibraryItemView.swift
//  RegEx+
//
//  Created by Lex on 2020/5/3.
//  Copyright © 2020 Lex.sh. All rights reserved.
//

import SwiftUI


struct LibraryItemView: View {
    @ObservedObject var regEx: RegEx
    
    private var rawBinding: Binding<String> {
        Binding<String>(get: { self.regEx.raw }, set: { self.regEx.raw = $0 })
    }
    
    @State var isEditable: Bool = false
    
    var body: some View {
        NavigationLink(destination: EditorView(regEx: regEx)) {
            VStack(alignment: .leading, spacing: 4) {
                Text(regEx.name)
                    .font(.headline)
                RegExTextView(text: rawBinding)
                    .disabled(true)
            }
            .frame(minHeight: 60, maxHeight: 200)
        }
    }
}

struct LibraryItemView_Previews: PreviewProvider {
    private static var regEx: RegEx = {
        var r: RegEx = RegEx(context: DataManager.shared.persistentContainer.viewContext)
        r.name = "Dollars"
        r.raw = "\\$?((\\d+)\\.?(\\d\\d)?)"
        r.sample = "$100.00 12.50 $10"
        r.substitution = "$3"
        return r
    }()
    
    static var previews: some View {
        NavigationView {
            List {
                LibraryItemView(regEx: regEx)
                LibraryItemView(regEx: regEx)
                LibraryItemView(regEx: regEx)
            }
        }
        .navigationBarTitle("LibraryItemView")
        .navigationViewStyle(StackNavigationViewStyle())
    }
}
