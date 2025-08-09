//
//  AboutView.swift
//  RegEx+
//
//  Created by Lex on 2020/5/24.
//  Copyright © 2020 Lex.sh. All rights reserved.
//

import SwiftUI
import StoreKit
import AppAboutView

struct AboutView: View {
    var body: some View {
        AppAboutView.fromMainBundle(
          appIcon: Image(.appIconForAboutView),
          feedbackEmail: "lexrus@gmail.com",
          appStoreID: "1511763524",
          privacyPolicy: URL(string: "https://lex.sh/regexplus/privacypolicy")!,
          copyrightText: "©2025 lex.sh"
        )
        .background(Color.init(white: 0.5, opacity: 0.1))
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarTitle("RegEx+")
    }
}

#Preview {
    AboutView()
}
