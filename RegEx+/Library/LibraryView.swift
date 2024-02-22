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
                    ForEach(regExItems.filter(filterByTerm), id: \.objectID) {
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

    private func filterByTerm(_ item: FetchedResults<RegEx>.Element) -> Bool {
        if searchTerm.isEmpty {
            return true
        }

        return item.name.lowercased().contains(searchTerm.lowercased())
            || item.raw.lowercased().contains(searchTerm.lowercased())
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
    func currentDeviceListStyle() -> AnyView {
#if targetEnvironment(macCatalyst)
        return AnyView(listStyle(PlainListStyle()).padding(.horizontal))
#else
        if #available(iOS 14.0, *) {
            return AnyView(listStyle(InsetGroupedListStyle()))
        } else {
            return AnyView(listStyle(GroupedListStyle()))
        }
#endif
    }
}

private extension View {
    func setNavigationItems(libraryView: LibraryView) -> AnyView {
        #if targetEnvironment(macCatalyst)
        AnyView(toolbar {
            ToolbarItem(placement: .topBarLeading) {
                libraryView.editButton
            }
            ToolbarItem(placement: .topBarTrailing) {
                HStack {
                    libraryView.aboutButton
                    libraryView.addButton
                }
            }
        })
        #else
        AnyView(toolbar {
            ToolbarItem(placement: .topBarLeading) {
                libraryView.editButton
            }
            ToolbarItem(placement: .topBarTrailing) {
                libraryView.aboutButton
            }
            ToolbarItem(placement: .topBarTrailing) {
                libraryView.addButton.padding(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 0))
            }
        })
        #endif
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
