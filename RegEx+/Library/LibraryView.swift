//
//  LibraryView.swift
//  RegEx+
//
//  Created by Lex on 2020/4/21.
//  Copyright © 2020 Lex.sh. All rights reserved.
//

import SwiftUI
import CoreData


struct LibraryView: View, Equatable {

    static func == (lhs: LibraryView, rhs: LibraryView) -> Bool {
        lhs.regExItems.map(\.objectID).hashValue == rhs.regExItems.map(\.objectID).hashValue
    }

    @Environment(\.managedObjectContext) var managedObjectContext
    @FetchRequest(fetchRequest: RegEx.fetchAllRegEx()) var regExItems: FetchedResults<RegEx>

    @State private var searchTerm = ""
    @State var editMode = EditMode.inactive
    
    private var filteredItems: [RegEx] {
        if searchTerm.isEmpty {
            return Array(regExItems)
        }
        return regExItems.filter { item in
            item.name.localizedCaseInsensitiveContains(searchTerm) ||
            item.raw.localizedCaseInsensitiveContains(searchTerm)
        }
    }

    var body: some View {
        VStack(alignment: .leading) {
            SearchView(text: $searchTerm)
                .padding(.horizontal)

            if regExItems.isEmpty {
                VStack(alignment: .center) {
                    Text("Your RegEx+ library is empty")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Button {
                        addRegEx(withSample: true)
                    } label: {
                        Text("Create a sample")
                    }
                    .buttonStyle(.bordered)
                }
                .frame(maxWidth: .greatestFiniteMagnitude, maxHeight: .greatestFiniteMagnitude)
            } else {
                List {
                    ForEach(filteredItems, id: \.objectID) {
                        LibraryItemView(regEx: $0).equatable()
                    }
                    .onDelete(perform: deleteRegEx)
                }
                .currentDeviceListStyle()
                .environment(\.editMode, $editMode)
            }
        }
        .navigationTitle("RegEx+")
        .setNavigationItems(libraryView: self)
    }


    var editButton: some View {
        Button(action: {
            editMode = editMode.isEditing ? .inactive : .active
        }, label: {
            Text(editMode.isEditing ? "Done" : "Edit")
        })
    }
    
    var aboutButton: some View {
        NavigationLink(destination: AboutView()) {
            Image(systemName: "info.circle")
                .imageScale(.large)
        }
    }
    
    var addButton: some View {
        Button {
            addRegEx(withSample: false)
        } label: {
            Image(systemName: "plus.circle.fill")
                .imageScale(.large)
        }
    }
}

private extension View {
    @ViewBuilder
    func currentDeviceListStyle() -> some View {
#if targetEnvironment(macCatalyst)
        self.listStyle(.plain)
            .padding(.horizontal)
#else
        if #available(iOS 14.0, *) {
            self.listStyle(.insetGrouped)
        } else {
            self.listStyle(.grouped)
        }
#endif
    }
}

private extension View {
    @ViewBuilder
    func setNavigationItems(libraryView: LibraryView) -> some View {
        self.toolbar {
            ToolbarItem(placement: .topBarLeading) {
                libraryView.editButton
            }
#if targetEnvironment(macCatalyst)
            ToolbarItem(placement: .topBarTrailing) {
                HStack {
                    libraryView.aboutButton
                    libraryView.addButton
                }
            }
#else
            ToolbarItem(placement: .topBarTrailing) {
                libraryView.aboutButton
            }
            ToolbarItem(placement: .topBarTrailing) {
                libraryView.addButton
                    .padding(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 0))
            }
#endif
        }
    }
}

#if DEBUG
struct LibraryView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            LibraryView()
                .environment(\.managedObjectContext, DataManager.shared.persistentContainer.viewContext)
        }
    }
}
#endif
