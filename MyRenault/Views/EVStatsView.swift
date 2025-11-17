//
//  EVStatsView.swift
//  MyRenault
//
//  Created by Costantino Pistagna on 17/11/25.
//

import SwiftUI

struct EVStatsView: View {
    @Environment(MyRenaultOpenAPIViewModel.self) private var apiViewModel
    let charges: [KamereonChargesResponse.ChargeAttributes.Charge]
    @AppStorage(ChargeCostSettingsKey.energyCostPerKW) private var energyCostPerKW: Double = ChargeCostSettingsDefault.energyCostPerKW
    @AppStorage(ChargeCostSettingsKey.gasolineCostPerLiter) private var gasolineCostPerLiter: Double = ChargeCostSettingsDefault.gasolineCostPerLiter
    @AppStorage(ChargeCostSettingsKey.averageKmPerLiter) private var gasolineKmPerLiter: Double = ChargeCostSettingsDefault.averageKmPerLiter
    private let isoDateFormatter = ISO8601DateFormatter()
    private static let displayDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            let totalEnergy = apiViewModel.totalRecoveredEnergy()
            HStack {
                Text("Total energy consumption")
                    .font(.system(size: 14, weight: .regular, design: .default))
                Spacer()
                VStack(alignment: .trailing) {
                    Text("\(String(format: "%.1f", totalEnergy)) kW")
                        .font(.system(size: 14, weight: .bold, design: .default))
                    Text("\(String(format: "%.2f", totalEnergy * energyCostPerKW)) €")
                        .font(.system(size: 13, weight: .bold, design: .default))
                }
            }
            .padding(.bottom, 4)
            Divider()
            if let largestCharge = charges.max(by: { $0.chargeEnergyRecovered < $1.chargeEnergyRecovered }) {
                VStack(alignment: .leading) {
                    HStack {
                        Text("Largest charge")
                            .font(.system(size: 14, weight: .regular, design: .default))
                        Spacer()
                        Text("\(String(format: "%.1f", largestCharge.chargeEnergyRecovered)) kW")
                            .font(.system(size: 14, weight: .bold, design: .default))
                    }
                    HStack {
                        Text("on \(formattedDate(largestCharge.chargeStartDate))")
                            .font(.system(size: 12, weight: .regular, design: .default))
                        Spacer()
                        Text("\(formattedDuration(largestCharge.chargeDuration))")
                            .font(.system(size: 12, weight: .regular, design: .default))
                    }
                }
                .padding(.vertical, 4)
                Divider()
            }
            if let smallestCharge = charges.min(by: { $0.chargeEnergyRecovered < $1.chargeEnergyRecovered }) {
                VStack(alignment: .leading) {
                    HStack {
                        Text("Smallest charge")
                            .font(.system(size: 14, weight: .regular, design: .default))
                        Spacer()
                        Text("\(String(format: "%.1f", smallestCharge.chargeEnergyRecovered)) kW")
                            .font(.system(size: 14, weight: .bold, design: .default))
                    }
                    HStack {
                        Text("on \(formattedDate(smallestCharge.chargeStartDate))")
                            .font(.system(size: 12, weight: .regular, design: .default))
                        Spacer()
                        Text("\(formattedDuration(smallestCharge.chargeDuration))")
                            .font(.system(size: 12, weight: .regular, design: .default))
                    }
                }
                .padding(.vertical, 4)
                Divider()
            }
            if let totalKm = apiViewModel.cockpit?.data?.attributes?.totalMileage, totalKm > 0 {
                let energyPer100km = (totalEnergy / totalKm) * 100
                let evCostPer100km = energyPer100km * energyCostPerKW
                HStack {
                    Text("Energy / 100km")
                        .font(.system(size: 14, weight: .regular, design: .default))
                    Spacer()
                    Text("\(String(format: "%.1f", energyPer100km)) kW")
                        .font(.system(size: 14, weight: .bold, design: .default))
                }
                .padding(.vertical, 4)
                Divider()
                
                HStack {
                    Text("Price € / 100km @ \(String(format: "%.2f", energyCostPerKW)) €/kW")
                        .font(.system(size: 14, weight: .regular, design: .default))
                    Spacer()
                    Text("\(String(format: "%.2f", evCostPer100km)) €")
                        .font(.system(size: 14, weight: .bold, design: .default))
                }
                .padding(.vertical, 4)
                Divider()
                let remainingRange = apiViewModel.batteryStatus?.data?.attributes?.batteryAutonomy ?? 0
                let combinedDistance = totalKm + remainingRange
                if combinedDistance > 0 {
                    let energyPer100kmWithRange = (totalEnergy / combinedDistance) * 100
                    let evCostPer100kmWithRange = energyPer100kmWithRange * energyCostPerKW
                    HStack {
                        Text("Energy / 100km (incl range)")
                            .font(.system(size: 14, weight: .regular, design: .default))
                        Spacer()
                        Text("\(String(format: "%.1f", energyPer100kmWithRange)) kW")
                            .font(.system(size: 14, weight: .bold, design: .default))
                    }
                    .padding(.vertical, 4)
                    Divider()
                    HStack {
                        Text("Price € / 100km (incl range)")
                            .font(.system(size: 14, weight: .regular, design: .default))
                        Spacer()
                        Text("\(String(format: "%.2f", evCostPer100kmWithRange)) €")
                            .font(.system(size: 14, weight: .bold, design: .default))
                    }
                    .padding(.vertical, 4)
                    Divider()
                }
                let gasolineCostPer100km = (100.0 / gasolineKmPerLiter) * gasolineCostPerLiter

                HStack {
                    VStack(alignment: .leading) {
                        Text("Endothermic comparison")
                            .font(.system(size: 14, weight: .regular, design: .default))
                        Text("\(String(format: "%.2f", gasolineCostPerLiter)) €/lt. (\(String(format: "%.1f", gasolineKmPerLiter)) km/lt.)")
                            .font(.system(size: 13, weight: .regular, design: .default))
                    }
                    Spacer()
                    Text("\(String(format: "%.2f", gasolineCostPer100km)) €")
                        .font(.system(size: 14, weight: .bold, design: .default))
                }
                .padding(.vertical, 4)
                Divider()
            } else {
                Text("Energy per 100 km: --")
                Text("Cost per 100 km @ \(String(format: "%.2f", energyCostPerKW)) EUR/kW: --")
                Text("Gasoline @ \(String(format: "%.2f", gasolineCostPerLiter)) EUR/L vs EV: --")
                Text("Energy per 100 km (incl range): --")
                Text("Cost per 100 km (incl range) @ \(String(format: "%.2f", energyCostPerKW)) EUR/kW: --")
                Text("Gasoline vs EV (incl range): --")
            }
        }
    }
    
    private func formattedDate(_ dateString: String) -> String {
        if let date = isoDateFormatter.date(from: dateString) {
            return Self.displayDateFormatter.string(from: date)
        }
        return dateString
    }
    
    private func formattedDuration(_ minutes: Int) -> String {
        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        return String(format: "%02dh : %02dm", hours, remainingMinutes)
    }
}
