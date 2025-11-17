//
//  PercentageFillImageView.swift
//  MyRenault
//
//  Created by Costantino Pistagna on 11/11/25.
//

import SwiftUI

struct PercentageFillImageView: View {
    let image: Image
    let fillPercentage: Double // 0.0 ... 1.0
    
    var body: some View {
        ZStack(alignment: .leading) {
            // 1️⃣ Immagine base in scala di grigi
            image
                .resizable()
                .scaledToFit()
                .saturation(0)
            
            // 2️⃣ Immagine tinta di blu con maschera statica
            image
                .resizable()
                .scaledToFit()
                .saturation(0)
                .colorMultiply(.blue)
                .mask(
                    GeometryReader { geometry in
                        Rectangle()
                            .frame(width: geometry.size.width * CGFloat(fillPercentage))
                    }
                )
            
            // 3️⃣ Immagine con gradiente trasparente → bianco animato
            image
                .resizable()
                .scaledToFit()
                .saturation(0)
                .mask(
                    TimelineView(.animation) { timeline in
                        let time = timeline.date.timeIntervalSinceReferenceDate
                        // Extend the cycle so the highlight exits the view before restarting,
                        // removing the visible "pop" when the animation loops.
                        let cycleDuration: TimeInterval = 2.8
                        let progress = (time.truncatingRemainder(dividingBy: cycleDuration)) / cycleDuration
                        // Move the highlight center from -0.3 (off-screen left) to 1.3 (off-screen right)
                        // so the reset happens out of view.
                        let center = progress * 1.6 - 0.3
                        let highlightCore: Double = 0.08
                        let highlightFalloff: Double = 0.22
                        GeometryReader { geometry in
                            LinearGradient(
                                gradient: Gradient(stops: [
                                    .init(color: .clear, location: max(0, center - highlightFalloff)),
                                    .init(color: .white.opacity(0.45), location: max(0, center - highlightCore)),
                                    .init(color: .white, location: min(max(0, center), 1)),
                                    .init(color: .white.opacity(0.45), location: min(center + highlightCore, 1)),
                                    .init(color: .clear, location: min(center + highlightFalloff, 1))
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                            .offset(x: -geometry.size.width * CGFloat(fillPercentage * 0.5))
                            .frame(width: geometry.size.width * CGFloat(fillPercentage * 1.7))
                        }
                    }
                )
                .opacity(0.3)
        }
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(radius: 4)
        .padding()
    }
}
