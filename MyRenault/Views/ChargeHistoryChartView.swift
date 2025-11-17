//
//  ChargeHistoryChartView.swift
//  MyRenault
//
//  Created by Costantino Pistagna on 17/11/25.
//

import SwiftUI
import Charts

struct ChargeHistoryChartView: View {
    let charges: [KamereonChargesResponse.ChargeAttributes.Charge]
    private let isoDateFormatter = ISO8601DateFormatter()
    private let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }()
    
    var body: some View {
        let points = charges.compactMap { charge -> ChargeEnergyPoint? in
            guard let date = isoDateFormatter.date(from: charge.chargeStartDate) else { return nil }
            return ChargeEnergyPoint(date: date,
                                     energy: charge.chargeEnergyRecovered,
                                     dayLabel: dayFormatter.string(from: date))
        }
        
        if points.isEmpty {
            Text("No charge data to plot")
                .font(.footnote)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            VStack(alignment: .leading, spacing: 4) {
                Text("Energy (kW)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Chart(points) { point in
                    BarMark(
                        x: .value("Day", point.dayLabel),
                        y: .value("Energy", point.energy)
                    )
                    .foregroundStyle(.blue.gradient)
                }
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .chartXAxis {
                    AxisMarks(values: points.map { $0.dayLabel }) { value in
                        if let day = value.as(String.self) {
                            AxisGridLine()
                            AxisValueLabel(day)
                        }
                    }
                }
                .chartYScale(domain: .automatic(includesZero: true))
            }
        }
    }
}

private struct ChargeEnergyPoint: Identifiable {
    let date: Date
    let energy: Double
    let dayLabel: String
    var id: Date { date }
}
