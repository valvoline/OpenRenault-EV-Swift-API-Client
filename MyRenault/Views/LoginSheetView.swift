//
//  LoginSheetView.swift
//  MyRenault
//
//  Created by Costantino Pistagna on 16/11/25.
//

import SwiftUI

struct LoginSheetView: View {
    @Binding var showLoginSheet: Bool
    @Environment(MyRenaultOpenAPIViewModel.self) private var viewModel
    @State private var username: String = ""
    @State private var password: String = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Sign in")
                .font(.headline)
                .padding(.top)
            TextField("Email", text: $username)
                .textFieldStyle(.roundedBorder)
                .autocapitalization(.none)
                .textContentType(.username)
                .padding(.horizontal)
            SecureField("Password", text: $password)
                .textFieldStyle(.roundedBorder)
                .textContentType(.password)
                .padding(.horizontal)
            if let message = viewModel.errorMessage, !message.isEmpty {
                Text(message)
                    .font(.footnote)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            HStack {
                Button("Cancel", role: .cancel) {
                    showLoginSheet = false
                }
                .buttonStyle(.bordered)
                Button("OK") {
                    Task {
                        let success = await viewModel.login(username: username, password: password)
                        if success {
                            showLoginSheet = false
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.bottom)
        }
    }
}
