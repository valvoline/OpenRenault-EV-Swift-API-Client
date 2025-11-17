//
//  VehicleLink+Views.swift
//  MyRenault
//
//  Created by Costantino Pistagna on 10/11/25.
//

import SwiftUI

extension VehicleLink {
    @ViewBuilder func brandImage() -> some View {
        if let mybrandAsset = vehicleDetails?.assets?.first(where: { $0.viewPointInLowerCase == "mybrand_2" }),
           let renderURL = mybrandAsset.renditions?.first(where: { $0.resolutionType?.contains("LARGE") ?? false })?.url,
            let url = URL(string: renderURL)
        {
            AsyncImage(url: url) { image in
                image
                    .resizable()
                    .scaledToFit()
            } placeholder: {
                ProgressView()
            }
        } else {
            Image(systemName: "photo.badge.exclamationmark.fill")
        }
    }
    @ViewBuilder func dashboardImage() -> some View {
        if let mybrandAsset = vehicleDetails?.assets?.first(where: { $0.viewPointInLowerCase == "myb_car_page_dashboard" }),
           let renderURL = mybrandAsset.renditions?.first(where: { $0.resolutionType?.contains("LARGE") ?? false })?.url,
           let url = URL(string: renderURL)
        {
            AsyncImage(url: url) { image in
                image
                    .resizable()
                    .scaledToFit()
            } placeholder: {
                ProgressView()
            }
        } else {
            Image(systemName: "photo.badge.exclamationmark.fill")
        }
    }
    @ViewBuilder func chargePercentageImage(percentage: Double) -> some View {
        if let mybrandAsset = vehicleDetails?.assets?.first(where: { $0.viewPointInLowerCase == "myb_car_page_dashboard" }),
           let renderURL = mybrandAsset.renditions?.first(where: { $0.resolutionType?.contains("LARGE") ?? false })?.url,
           let url = URL(string: renderURL)
        {
            AsyncImage(url: url) { image in
                PercentageFillImageView(image: image, fillPercentage: percentage)
            } placeholder: {
                ProgressView()
            }
        } else {
            Image(systemName: "photo.badge.exclamationmark.fill")
        }
    }
}
