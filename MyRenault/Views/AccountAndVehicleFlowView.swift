//
//  AccountAndVehicleFlowView.swift
//  MyRenault
//
//  Created by Costantino Pistagna on 10/11/25.
//


import SwiftUI

struct AccountAndVehicleFlowView: View {
    @Environment(MyRenaultOpenAPIViewModel.self) private var apiViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var path = NavigationPath()
    
    var body: some View {
        NavigationStack(path: $path) {
            AccountSelectionView()
                .navigationTitle("Select Account")
                .navigationBarTitleDisplayMode(.inline)
                .onChange(of: apiViewModel.selectedAccountId) { _, newValue in
                    if newValue != nil {
                        path.append("VehicleSelection")
                    }
                }
                .onChange(of: apiViewModel.selectedVehicle) { _, newValue in
                    if newValue != nil, apiViewModel.selectedAccountId != nil {
                        dismiss()
                    }
                }
                .navigationDestination(for: String.self) { destination in
                    if destination == "VehicleSelection" {
                        VehicleSelectionView()
                            .navigationTitle("Select Vehicle")
                            .navigationBarTitleDisplayMode(.inline)
                            .onChange(of: apiViewModel.selectedVehicle) { _, newValue in
                                if newValue != nil {
                                    path.append("SelectionCompleted")
                                }
                            }
                    }
                }
        }
        .presentationDetents([.large])
    }
}

struct AccountSelectionView: View {
    @Environment(MyRenaultOpenAPIViewModel.self) private var apiViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            if let accounts = apiViewModel.accountIds, !accounts.isEmpty {
                List(accounts, id: \.accountId) { account in
                    Button(action: {
                        apiViewModel.selectedAccountId = account
                    }) {
                        VStack(alignment: .leading) {
                            Text(account.accountId)
                                .font(.body)
                            Text(account.accountType)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            } else {
                if apiViewModel.isLoading {
                    ProgressView()
                } else {
                    Text("No accounts available")
                        .foregroundStyle(.secondary)
                }
               
            }
        }
        .task {
            if apiViewModel.accountIds == nil || apiViewModel.accountIds?.isEmpty == true {
                await apiViewModel.fetchAccounts()
            }
        }
    }
}
struct VehicleSelectionView: View {
    @Environment(MyRenaultOpenAPIViewModel.self) private var apiViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 16) {
            if let vehicles = apiViewModel.vehicles?.vehicleLinks, !vehicles.isEmpty {
                List(vehicles, id: \.vin) { vehicle in
                    Button(action: {
                        apiViewModel.selectedVehicle = vehicle
                    }) {
                        VStack(alignment: .leading) {
                            Text(vehicle.brand + " " + (vehicle.vehicleDetails?.model?.label ?? ""))
                                .font(.body)
                            Text(vehicle.vin)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            } else {
                if apiViewModel.isLoading {
                    ProgressView()
                } else {
                    Text("No vehicles available")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .task {
            if apiViewModel.vehicles == nil || apiViewModel.vehicles?.vehicleLinks.isEmpty == true {
                if let accountId = apiViewModel.selectedAccountId?.accountId {
                    await apiViewModel.fetchVehicles(for: accountId)
                }
            }
        }
    }
}
