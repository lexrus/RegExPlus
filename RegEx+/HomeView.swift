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
        return NavigationView { LibraryView()
            .tabItem {
                VStack {
                    Image(systemName: "list.bullet")
                    Text("Library")
                }
            }
            .environment(\.managedObjectContext, managedObjectContext)
        }
        .currentDeviceNavigationViewStyle()
    }
}

private extension View {
    func currentDeviceNavigationViewStyle() -> AnyView {
#if targetEnvironment(macCatalyst)

        if #available(macCatalyst 16.0, *) {
            return AnyView(
                navigationViewStyle(DoubleColumnNavigationViewStyle())
//                    .navigationSplitViewStyle(ProminentDetailNavigationSplitViewStyle())
            )
        } else {
            return AnyView(
                navigationViewStyle(DoubleColumnNavigationViewStyle())
            )
        }
#else
            
            if UIDevice.current.userInterfaceIdiom == .pad {
                return AnyView(navigationViewStyle(DoubleColumnNavigationViewStyle()))
            } else {
                return AnyView(navigationViewStyle(DefaultNavigationViewStyle()))
            }
            
#endif
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
