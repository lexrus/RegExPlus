//
//  SettingsView.swift
//  RegEx+
//
//  Created by Lex on 2020/4/21.
//  Copyright © 2020 Lex.sh. All rights reserved.
//

import SwiftUI

struct SettingsView: View {
    var body: some View {
        VStack(alignment: .center, spacing: 10) {
            Text("RegEx+")
                .font(.title)
            Text("Version \(Bundle.main.releaseVersionNumber!)")
                .font(.subheadline)
            Text("Build \(Bundle.main.buildVersionNumber!)")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}

extension Bundle {
    
    var releaseVersionNumber: String? {
        return infoDictionary?["CFBundleShortVersionString"] as? String
    }
    
    var buildVersionNumber: String? {
        return infoDictionary?["CFBundleVersion"] as? String
    }
    
}
