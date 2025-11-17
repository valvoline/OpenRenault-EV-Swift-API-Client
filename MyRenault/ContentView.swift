//
//  ContentView.swift
//  MyRenault
//
//  Created by Costantino Pistagna on 09/11/25.
//

import SwiftUI
import Charts

struct ContentView: View {
    @Environment(MyRenaultOpenAPIViewModel.self) private var apiViewModel
    @Binding var showLoginSheet: Bool
    @State private var showAccountVehicleFlow = false
    @State private var selectedRange: ChargeHistoryRange = .currentMonth
    @State private var customStartDate: Date = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: Date())) ?? Date()
    @State private var customEndDate: Date = Date()
    @State private var pendingCustomStartDate: Date = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: Date())) ?? Date()
    @State private var pendingCustomEndDate: Date = Date()
    @State private var showingCustomRangeSheet = false
    @State private var showVehicleSwitcher = false
    @State private var dashboardRefreshID = UUID()

    var body: some View {
        Group {
            if apiViewModel.loginNeeded {
                placeholderView(
                    title: "Welcome back",
                    message: "Please login to access your vehicle.",
                    actionTitle: "Login",
                    action: { showLoginSheet = true }
                )
            } else if !hasConfiguredVehicle {
                placeholderView(
                    title: "No vehicle configured",
                    message: "Add a vehicle to start tracking stats and charges.",
                    actionTitle: "Configure Vehicle",
                    action: { showAccountVehicleFlow = true } 
                )
            } else {
                mainNavigationContent
            }
        }
        .sheet(isPresented: $showAccountVehicleFlow) {
            AccountAndVehicleFlowView()
                .environment(apiViewModel)
        }
        .onChange(of: apiViewModel.selectedVehicle?.vin) {
            selectedRange = .currentMonth
            customStartDate = startOfCurrentMonth ?? Date()
            pendingCustomStartDate = customStartDate
            customEndDate = Date()
            pendingCustomEndDate = customEndDate
        }
        .onChange(of: apiViewModel.loginNeeded) { _, newValue in
            if newValue == false {
                presentVehicleFlowIfNeeded()
            }
        }
        .onChange(of: showLoginSheet) { _, newValue in
            if newValue == false {
                presentVehicleFlowIfNeeded()
            }
        }
        .task {
            presentVehicleFlowIfNeeded()
        }
        .onChange(of: selectedRange) {
            Task { await refreshChargeHistory() }
        }
        .task(id: refreshTaskIdentifier) {
            await refreshChargeHistory()
        }
        .sheet(isPresented: $showingCustomRangeSheet) {
            NavigationStack {
                VStack(spacing: 16) {
                    Form {
                        DatePicker(
                            "Start date",
                            selection: $pendingCustomStartDate,
                            in: minimumCustomStartDate...pendingCustomEndDate,
                            displayedComponents: .date
                        )
                        DatePicker(
                            "End date",
                            selection: $pendingCustomEndDate,
                            in: pendingCustomStartDate...Date(),
                            displayedComponents: .date
                        )
                    }
                    .frame(maxHeight: 220)
                    
                    Spacer()
                    
                    VStack(spacing: 12) {
                        Button("Continue") {
                            applyCustomDates()
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(pendingCustomStartDate > pendingCustomEndDate)
                        
                        Button("Cancel") {
                            showingCustomRangeSheet = false
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                }
                .navigationTitle("Custom range")
                .navigationBarTitleDisplayMode(.inline)
            }
            .presentationDetents([.medium])
            .onChange(of: pendingCustomStartDate) { _, newValue in
                if newValue > pendingCustomEndDate {
                    pendingCustomEndDate = newValue
                }
            }
            .onChange(of: pendingCustomEndDate) { _, newValue in
                if newValue < pendingCustomStartDate {
                    pendingCustomStartDate = newValue
                }
            }
        }
        .sheet(isPresented: $showVehicleSwitcher) {
            VehicleSwitcherView {
                Task { await refreshAllData() }
            }
            .environment(apiViewModel)
        }
    }

    //MARK: internal view builders for such of clarity
    
    @ViewBuilder
    private var mainNavigationContent: some View {
        NavigationStack {
            ZStack {
                Color.clear.ignoresSafeArea()
                List {
                    Section {
                        Picker(
                            "Charge range",
                            selection: Binding(
                                get: { selectedRange },
                                set: { handleRangeSelection($0) }
                            )
                        ) {
                            ForEach(ChargeHistoryRange.allCases) { range in
                                Text(range.title).tag(range)
                            }
                        }
                        .pickerStyle(.segmented)
                        .listSectionSeparator(.hidden)
                    }
                    if let charges = apiViewModel.chargeHistory?.data.attributes.charges,
                       !charges.isEmpty {
                        Section {
                            NavigationLink {
                                ChargesHistoryView(charges: charges)
                            } label: {
                                HStack {
                                    Text(selectedRangeTitle)
                                        .font(.system(size: 17, weight: .bold))
                                    Spacer()
                                    Text("total charges:")
                                        .font(.system(size: 14, weight: .regular))
                                    Text("\(charges.count)")
                                        .font(.system(size: 17, weight: .bold))
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }
                    if let charges = apiViewModel.chargeHistory?.data.attributes.charges {
                        Section {
                            EVStatsView(charges: charges)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.vertical, 4)
                        }
                    }
                    
                    if let charges = apiViewModel.chargeHistory?.data.attributes.charges, !charges.isEmpty {
                        Section {
                            ChargeHistoryChartView(charges: charges)
                                .frame(height: 220)
                        }
                    }
                }
                .listStyle(.plain)
                .refreshable {
                    await refreshAllData()
                }
                .scrollContentBackground(.hidden)
                .contentMargins(.top, 180, for: .scrollContent)
                .contentMargins(.top, 180, for: .scrollIndicators)
                .overlay(alignment: .top) {
                    DashboardCardView(frameHeight: 290)
                        .id(dashboardRefreshID)
                        .ignoresSafeArea()
                }
                
                if apiViewModel.isLoading {
                    ProgressView("Refreshing...")
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        .transition(.opacity)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        apiViewModel.logout()
                    } label: {
                        Image(systemName: "rectangle.portrait.and.arrow.forward")
                            .environment(\.layoutDirection, .rightToLeft)
                            .padding(.vertical)
                            .padding(.horizontal, 6)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showVehicleSwitcher = true
                    } label: {
                        Image(systemName: "car.side")
                            .padding(.vertical)
                            .padding(.horizontal, 0)
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func placeholderView(title: String, message: String, actionTitle: String, action: @escaping () -> Void) -> some View {
        VStack(spacing: 16) {
            Spacer()
            Text(title)
                .font(.title3)
                .fontWeight(.semibold)
            Text(message)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Button(actionTitle, action: action)
                .buttonStyle(.borderedProminent)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    //MARK: internal getters and methods to deal with BL
    
    private var hasConfiguredVehicle: Bool {
        apiViewModel.selectedAccountId != nil && apiViewModel.selectedVehicle != nil
    }

    private var currentMonthName: String {
        Self.monthFormatter.string(from: Date())
    }
    
    private var selectedRangeTitle: String {
        switch selectedRange {
        case .currentMonth:
            return currentMonthName
        case .lifetime:
            return "Lifetime"
        case .custom:
            let formatter = Self.customDisplayFormatter
            return "\(formatter.string(from: customStartDate)) - \(formatter.string(from: customEndDate))"
        }
    }

    private var startOfCurrentMonth: Date? {
        let calendar = Calendar.current
        return calendar.date(from: calendar.dateComponents([.year, .month], from: Date()))
    }
    
    private var ownershipStartDate: Date? {
        guard let rawDate = apiViewModel.selectedVehicle?.ownershipStartDate else { return nil }
        if let isoDate = ISO8601DateFormatter().date(from: rawDate) {
            return isoDate
        }
        return Self.simpleOwnershipDateFormatter.date(from: rawDate)
    }
    
    private func startDate(for range: ChargeHistoryRange) -> Date? {
        switch range {
        case .currentMonth:
            return startOfCurrentMonth
        case .lifetime:
            return ownershipStartDate ?? startOfCurrentMonth
        case .custom:
            return customStartDate
        }
    }
    
    private func endDate(for range: ChargeHistoryRange) -> Date? {
        switch range {
        case .currentMonth, .lifetime:
            return Date()
        case .custom:
            return customEndDate
        }
    }
    
    private func refreshChargeHistory() async {
        guard hasConfiguredVehicle else { return }
        await apiViewModel.refreshChargeHistoryForVehicle(
            startDate: startDate(for: selectedRange),
            endDate: endDate(for: selectedRange)
        )
    }

    private func refreshAllData() async {
        guard hasConfiguredVehicle else { return }
        let start = startDate(for: selectedRange)
        let end = endDate(for: selectedRange)
        async let history: Void = apiViewModel.refreshChargeHistoryForVehicle(startDate: start, endDate: end)
        async let fullRefresh: Void = apiViewModel.refreshAllVehicleData(startDate: start, endDate: end)
        _ = await (history, fullRefresh)
        await MainActor.run {
            dashboardRefreshID = UUID()
        }
    }
    
    private var refreshTaskIdentifier: String {
        var identifier = "\(selectedRange.id)-\(apiViewModel.selectedVehicle?.vin ?? "none")"
        if selectedRange == .custom {
            identifier += "-\(customStartDate.timeIntervalSince1970)-\(customEndDate.timeIntervalSince1970)"
        }
        return identifier
    }
    
    private static let simpleOwnershipDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()
    
    private static let customDisplayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM yyyy"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
    
    private static let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "LLLL"
        return formatter
    }()

    private var minimumCustomStartDate: Date {
        ownershipStartDate ?? startOfCurrentMonth ?? Date()
    }
    
    private func handleRangeSelection(_ newValue: ChargeHistoryRange) {
        if newValue == .custom {
            pendingCustomStartDate = customStartDate
            pendingCustomEndDate = customEndDate
            showingCustomRangeSheet = true
        } else {
            selectedRange = newValue
        }
    }
    
    private func applyCustomDates() {
        customStartDate = pendingCustomStartDate
        customEndDate = pendingCustomEndDate
        selectedRange = .custom
        showingCustomRangeSheet = false
        Task { await refreshChargeHistory() }
    }
    
    private func presentVehicleFlowIfNeeded() {
        if !apiViewModel.loginNeeded && !hasConfiguredVehicle {
            showAccountVehicleFlow = true
        }
    }
    
    private enum ChargeHistoryRange: String, CaseIterable, Identifiable {
        case lifetime
        case currentMonth
        case custom
        
        static var allCases: [ChargeHistoryRange] {
            [.lifetime, .currentMonth, .custom]
        }
        
        var id: String { rawValue }
        
        var title: String {
            switch self {
            case .lifetime:
                return "Lifetime"
            case .currentMonth:
                return "Current month"
            case .custom:
                return "Custom"
            }
        }
    }
    
}
