//
//  VehicleSwitcherView.swift
//  MyRenault
//
//  Created by Costantino Pistagna on 18/11/25.
//

import SwiftUI

/// Sheet that lets the user pick another vehicle without running the full onboarding flow.
struct VehicleSwitcherView: View {
    @Environment(MyRenaultOpenAPIViewModel.self) private var apiViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var isLoading = false
    var onVehicleChanged: (() -> Void)?
    
    var body: some View {
        NavigationStack {
            Group {
                if let vehicles = apiViewModel.vehicles?.vehicleLinks, !vehicles.isEmpty {
                    List(vehicles, id: \.vin) { vehicle in
                        Button {
                            select(vehicle)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(vehicle.brand + " " + (vehicle.vehicleDetails?.model?.label ?? ""))
                                    .font(.body)
                                Text(vehicle.vin)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .listStyle(.plain)
                } else if isLoading || apiViewModel.isLoading {
                    ProgressView("Loading vehicles…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                } else {
                    Text("No vehicles available")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                }
            }
            .navigationTitle("Switch Vehicle")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await ensureVehiclesLoaded()
            }
            .refreshable {
                await reloadVehicles()
            }
        }
    }
    
    private func select(_ vehicle: VehicleLink) {
        apiViewModel.selectedVehicle = vehicle
        dismiss()
        onVehicleChanged?()
    }
    
    private func ensureVehiclesLoaded() async {
        guard apiViewModel.vehicles?.vehicleLinks.isEmpty != false,
              let accountId = apiViewModel.selectedAccountId?.accountId else { return }
        await reloadVehicles(accountId: accountId)
    }
    
    private func reloadVehicles(accountId: String? = nil) async {
        guard let accountId = accountId ?? apiViewModel.selectedAccountId?.accountId else { return }
        isLoading = true
        await apiViewModel.fetchVehicles(for: accountId)
        isLoading = false
    }
}
