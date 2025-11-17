//
//  DashboardCardView.swift
//  MyRenault
//
//  Created by Costantino Pistagna on 11/11/25.
//

import SwiftUI

struct DashboardCardView: View {
    var frameHeight: CGFloat = 240
    @Environment(MyRenaultOpenAPIViewModel.self) private var apiViewModel
    
    var body: some View {
        ZStack {
            LinearGradient(colors: [.blue, .purple], startPoint: .top, endPoint: .bottom)
                .frame(height: frameHeight)
            Group {
                if apiViewModel.batteryStatus?.data?.attributes?.chargingStatus == .inCharge {
                    apiViewModel.selectedVehicle?.chargePercentageImage(percentage: (apiViewModel.batteryStatus?.data?.attributes?.batteryLevel ?? 0.0) / 100.0)
                } else {
                    apiViewModel.selectedVehicle?.dashboardImage()
                }
            }
            .offset(y: frameHeight*10/100)

            VStack {
                if apiViewModel.batteryStatus?.data?.attributes?.chargingStatus == .inCharge {
                    HStack(alignment: .center) {
                        apiViewModel.batteryStatus?.data?.attributes?.batteryIcon
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 20)
                        Text("\(Int(apiViewModel.batteryStatus?.data?.attributes?.batteryLevel ?? 0.0))%")
                            .font(.system(size: 21)).fontWeight(.bold)
                    }
                    .padding(.top, frameHeight*25/100)
                }
                Spacer()
                HStack {
                    VStack(alignment: .leading) {
                        if apiViewModel.batteryStatus?.data?.attributes?.chargingStatus == .inCharge {
                            Text("To full charge")
                                .font(.footnote).fontWeight(.regular)
                            Text("\(apiViewModel.batteryStatus?.data?.attributes?.chargingRemainingTime ?? 0)" + " min")
                                .font(.default).fontWeight(.bold)
                        } else {
                            Text("Battery level")
                                .font(.footnote).fontWeight(.regular)
                            Text("\(Int(apiViewModel.batteryStatus?.data?.attributes?.batteryLevel ?? 0.0))%")
                                .font(.default).fontWeight(.bold)
                        }
                    }
                    Spacer()
                    VStack(alignment: .leading) {
                        Text("Range")
                            .font(.footnote).fontWeight(.regular)
                        Text(apiViewModel.batteryStatus?.data?.attributes?.batteryAutonomyInKm ?? "")
                            .font(.default).fontWeight(.bold)
                    }
                    Spacer()
                    VStack(alignment: .leading) {
                        Text("Total km")
                            .font(.footnote).fontWeight(.regular)
                        Text(apiViewModel.cockpit?.data?.attributes?.totalKmSoFar ?? "")
                            .font(.default).fontWeight(.bold)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
            .frame(height: frameHeight)
        }
        .onAppear {
            Task {
                do {
                    await apiViewModel.refreshAllVehicleData()
                }
            }
        }
    }
}
