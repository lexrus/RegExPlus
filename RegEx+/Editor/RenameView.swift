//
//  RenameView.swift
//  RegEx+
//
//  Created by Lex on 2020/5/4.
//  Copyright © 2020 Lex.sh. All rights reserved.
//

import SwiftUI

struct RenameView: View {
    @ObservedObject var viewModel: EditorViewModel
    
    var body: some View {
        List {
            Section(header: Text("New name")) {
                TextField("Name", text: $viewModel.regEx.name)
                    .font(.title)
            }
        }
        .listStyle(GroupedListStyle())
        .navigationBarTitle(viewModel.regEx.raw)
    }

}

struct RenameView_Previews: PreviewProvider {
    static var viewModel: EditorViewModel {
        let r = RegEx(context: DataManager.shared.persistentContainer.viewContext)
        r.name = "Untitled"
        let vm = EditorViewModel(regEx: r)
        return vm
    }
    
    static var previews: some View {
        NavigationView {
            RenameView(viewModel: viewModel)
                .navigationBarTitle(viewModel.regEx.name)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}
