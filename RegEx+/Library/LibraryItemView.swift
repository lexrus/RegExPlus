//
//  LibraryItemView.swift
//  RegEx+
//
//  Created by Lex on 2020/5/3.
//  Copyright © 2020 Lex.sh. All rights reserved.
//

import SwiftUI
import CoreData


struct LibraryItemView: View, Equatable {

    @ObservedObject var regEx: RegEx

    var body: some View {
        NavigationLink {
            EditorView(regEx: regEx).equatable()
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                Text(regEx.name)
                    .font(.headline)

                if !regEx.raw.isEmpty {
                    Text(regEx.raw)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            .frame(minHeight: 50, maxHeight: 200)
            .paddingVertical()
        }
        .isDetailLink(true)
    }

    static func == (lhs: LibraryItemView, rhs: LibraryItemView) -> Bool {
        lhs.regEx.objectID == rhs.regEx.objectID
            && lhs.regEx.name == rhs.regEx.name
            && lhs.regEx.raw == rhs.regEx.raw
    }
}

private extension View {

    func paddingVertical() -> AnyView {
        #if targetEnvironment(macCatalyst)
        AnyView(padding(.vertical))
        #else
        AnyView(self)
        #endif
    }

}

struct LibraryItemView_Previews: PreviewProvider {
    private static var regEx: RegEx = {
        var r: RegEx = RegEx(context: DataManager.shared.persistentContainer.viewContext)
        r.name = "Dollars"
        r.raw = #"\$?((\d+)\.?(\d\d)?)"#
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
        .navigationTitle(Text(verbatim: "Test"))
        .navigationViewStyle(StackNavigationViewStyle())
    }
}
