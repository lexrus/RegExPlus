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

    var body: some View {
        if #available(iOS 16.0, macOS 13.0, *) {
            NavigationSplitView {
                LibraryView()
            } detail: {
                Text(verbatim: "RegEx+")
                    .font(.largeTitle)
            }
        } else {
            NavigationView {
                LibraryView()
                Text(verbatim: "RegEx+")
                    .font(.largeTitle)
            }
            .currentDeviceNavigationViewStyle()
        }
    }
}

private extension View {
    func currentDeviceNavigationViewStyle() -> AnyView {
#if targetEnvironment(macCatalyst)

        return AnyView(
            navigationViewStyle(DoubleColumnNavigationViewStyle())
        )

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
