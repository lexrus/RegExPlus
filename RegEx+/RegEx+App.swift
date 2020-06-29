//
//  RegEx+App.swift
//  RegEx+
//
//  Created by Lex on 2020/6/25.
//  Copyright © 2020 Lex.sh. All rights reserved.
//

import SwiftUI

@main
struct RegExPlusApp: App {
    let viewContext = DataManager.shared.persistentContainer.viewContext

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environment(\.managedObjectContext, viewContext)
                .onAppear {
                    // DataManager.shared.initializeCloudKitSchema()
                }
        }
    }
}
