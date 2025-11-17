//
//  WrappedPreviewViewModel.swift
//  MyRenault
//
//  Created by Costantino Pistagna on 17/11/25.
//

import SwiftUI

#Preview {
    WrappedPreviewViewModel()
}

struct WrappedPreviewViewModel: View {
    @State private var viewModel = MyRenaultOpenAPIViewModel(api: MyRenaultOpenAPI(config: .init(
        gigyaRootURL: URL(string: "<INSERT_GIGYA_ROOT_URL>")!,
        gigyaApiKey: "<INSERT_GIGYA_API_KEY>",
        kamereonRootURL: URL(string: "INSERT_KAMEREON_ROOT_URL")!,
        kamereonApiKey: "<INSERT_KAMEREON_API_KEY>",
        country: "<INSERT_COUNTRY>"
    )))
    @State private var showErrorAlert = false
    @State private var showLoginSheet = false
    
    var body: some View {
        ContentView(showLoginSheet: $showLoginSheet)
            .onChange(of: viewModel.errorMessage) {
                if let apiError = viewModel.apiError, case RenaultAPIError.missingCredentials = apiError {
                    showLoginSheet = true
                } else if viewModel.errorMessage != nil {
                    showErrorAlert = true
                }
            }
            .alert("Error", isPresented: $showErrorAlert, actions: {
                Button("OK", role: .cancel) {
                    viewModel.errorMessage = nil
                }
            }, message: {
                Text(viewModel.errorMessage ?? "")
            })
            .sheet(isPresented: $showLoginSheet) {
                LoginSheetView(showLoginSheet: $showLoginSheet)
                    .presentationDetents([.fraction(0.35)])
            }
            .environment(viewModel)
            .onAppear {
                if viewModel.loginNeeded {
                    showLoginSheet.toggle()
                }
            }
    }
}
