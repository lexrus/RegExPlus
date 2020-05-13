//
//  TabView.swift
//  RegEx+
//
//  Created by Lex on 2020/4/21.
//  Copyright © 2020 Lex.sh. All rights reserved.
//

import SwiftUI

struct HomeView: View {
    @Environment(\.managedObjectContext) var managedObjectContext
    @State private var selection = 0
    
    var body: some View {
        NavigationView {
            LibraryView()
                .tabItem {
                    VStack {
                        Image(systemName: "list.bullet")
                        Text("Library")
                    }
            }
            .environment(\.managedObjectContext, managedObjectContext)
        }
        .navigationViewStyle(DoubleColumnNavigationViewStyle())
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
