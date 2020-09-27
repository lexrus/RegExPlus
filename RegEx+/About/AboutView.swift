//
//  AboutView.swift
//  RegEx+
//
//  Created by Lex on 2020/5/24.
//  Copyright © 2020 Lex.sh. All rights reserved.
//

import SwiftUI
import StoreKit


private let kAppStoreReviewUrl = "https://apps.apple.com/app/regex/id1511763524?action=write-review"
private let kGitHubUrl = "https://github.com/lexrus/RegExPlus"


struct AboutView: View {
    @State private var showingAppStore = false
    @State private var showingGitHub = false
    @State private var showingAcknowledgements = false
    
    private var rateButton: some View {
        Button(action: {
            #if targetEnvironment(macCatalyst)
            SKStoreReviewController.requestReview()
            #else
            
            if #available(iOS 14.0, *) {
                guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
                    return
                }
                SKStoreReviewController.requestReview(in: scene)
            } else {
                SKStoreReviewController.requestReview()
            }
            #endif
        }) {
            Text("Rate RegEx+")
        }
    }
    
    private var appStoreButton: some View {
        Button(action: {
            self.showingAppStore.toggle()
        }) {
            Text("Write a review")
        }
        .sheet(isPresented: $showingAppStore) {
             SafariView(url: URL(string: kAppStoreReviewUrl)!)
        }
    }
    
    private var gitHubButton: some View {
        Button(action: {
            self.showingGitHub.toggle()
        }) {
            Text(kGitHubUrl)
        }
        .sheet(isPresented: $showingGitHub) {
            SafariView(url: URL(string: kGitHubUrl)!)
        }
    }
    
    private var acknowledgementsSection: some View {
        Section(header: Text("Acknowledgements")) {
            Button(action: {
                self.showingAcknowledgements.toggle()
            }) {
                Text("KeyboardObserving")
            }
            .sheet(isPresented: $showingAcknowledgements) {
                SafariView(url: URL(string: "https://github.com/nickffox/KeyboardObserving")!)
            }
        }
    }
    
    var body: some View {
        List {
            Section(header: Text("\(Bundle.main.releaseVersionNumber ?? "")")) {
                rateButton
                appStoreButton
                gitHubButton
            }
            acknowledgementsSection
        }
        .listStyle(GroupedListStyle())
        .navigationTitle("RegEx+")
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

struct AboutView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            AboutView()
        }
    }
}
