//
//  ChargesHistoryView.swift
//  MyRenault
//
//  Created by Costantino Pistagna on 17/11/25.
//

import SwiftUI

struct ChargesHistoryView: View {
    let charges: [KamereonChargesResponse.ChargeAttributes.Charge]
    @AppStorage(ChargeCostSettingsKey.energyCostPerKW) private var energyCostPerKW: Double = ChargeCostSettingsDefault.energyCostPerKW
    @State private var showSettings = false
    private let isoDateFormatter = ISO8601DateFormatter()
    private static let displayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, HH:mm"
        return formatter
    }()
    
    var body: some View {
        List(sortedCharges, id: \.identifier) { item in
            VStack(alignment: .leading) {
                HStack {
                    VStack(alignment: .trailing) {
                        HStack {
                            Text("Start:")
                                .font(.system(size: 13, weight: .medium, design: .default))
                            Text("\(formattedDate(item.charge.chargeStartDate))")
                                .font(.system(size: 12, weight: .regular, design: .default))
                        }
                        HStack {
                            Text("End:")
                                .font(.system(size: 13, weight: .medium, design: .default))
                            Text("\(formattedDate(item.charge.chargeEndDate))")
                                .font(.system(size: 12, weight: .regular, design: .default))
                        }
                    }
                    Spacer()
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Duration:")
                                .font(.system(size: 13, weight: .medium, design: .default))
                            Text("\(formattedDuration(item.charge.chargeDuration))")
                                .font(.system(size: 12, weight: .regular, design: .default))
                        }
                        HStack {
                            Text("Total kW:")
                                .font(.system(size: 13, weight: .medium, design: .default))
                            Text("\(String(format: "%.1f", item.charge.chargeEnergyRecovered))")
                                .font(.system(size: 12, weight: .regular, design: .default))
                        }
                    }
                }
                Divider().padding(.leading, 200)
                HStack {
                    Spacer()
                    Text("Estimated cost:")
                        .font(.system(size: 13, weight: .medium, design: .default))
                    Text("\(String(format: "%.1f", item.charge.chargeEnergyRecovered * energyCostPerKW)) €")
                        .font(.system(size: 15, weight: .bold, design: .default))
                }
            }
            .padding(4)
        }
        .navigationTitle("Charges history")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showSettings = true
                } label: {
                    Image(systemName: "gearshape")
                }
            }
        }
        .sheet(isPresented: $showSettings) {
            ChargeCostSettingsView()
        }
    }
    
    private var sortedCharges: [ChargeHistoryItem] {
        charges.compactMap { charge in
            ChargeHistoryItem(charge: charge)
        }
        .sorted { $0.startDate > $1.startDate }
    }
    
    private func formattedDate(_ dateString: String) -> String {
        guard let date = isoDateFormatter.date(from: dateString) else {
            return dateString
        }
        return Self.displayFormatter.string(from: date)
    }
    
    private func formattedDuration(_ minutes: Int) -> String {
        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        return String(format: "%02d:%02d", hours, remainingMinutes)
    }
    
    private struct ChargeHistoryItem {
        let charge: KamereonChargesResponse.ChargeAttributes.Charge
        let startDate: Date
        let identifier: String
        
        init?(charge: KamereonChargesResponse.ChargeAttributes.Charge) {
            guard let startDate = ISO8601DateFormatter().date(from: charge.chargeStartDate) else { return nil }
            self.charge = charge
            self.startDate = startDate
            self.identifier = charge.chargeStartDate + charge.chargeEndDate
        }
    }
}

private struct ChargeCostSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage(ChargeCostSettingsKey.energyCostPerKW) private var energyCostPerKW: Double = ChargeCostSettingsDefault.energyCostPerKW
    @AppStorage(ChargeCostSettingsKey.gasolineCostPerLiter) private var gasolineCostPerLiter: Double = ChargeCostSettingsDefault.gasolineCostPerLiter
    @AppStorage(ChargeCostSettingsKey.averageKmPerLiter) private var averageKmPerLiter: Double = ChargeCostSettingsDefault.averageKmPerLiter
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Electric") {
                    HStack {
                        Text("Energy cost €/kWh")
                        Spacer()
                        TextField("0.00", value: $energyCostPerKW, format: .number.precision(.fractionLength(3)))
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.decimalPad)
                    }
                }
                Section("Endothermic") {
                    HStack {
                        Text("Gasoline cost €/L")
                        Spacer()
                        TextField("0.00", value: $gasolineCostPerLiter, format: .number.precision(.fractionLength(3)))
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.decimalPad)
                    }
                    HStack {
                        Text("Avg km per L")
                        Spacer()
                        TextField("0.0", value: $averageKmPerLiter, format: .number.precision(.fractionLength(1)))
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.decimalPad)
                    }
                }
            }
            .navigationTitle("Cost settings")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
