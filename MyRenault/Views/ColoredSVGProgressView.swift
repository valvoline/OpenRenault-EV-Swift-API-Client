//
//  ColoredSVGProgressView.swift
//  MyRenault
//
//  Created by Costantino Pistagna on 10/11/25.
//

import SwiftUI

struct ColoredSVGProgressView: View {
    var svgImageName: String
    var progress: CGFloat // da 0.0 a 1.0
    var color: Color
    
    var body: some View {
        ZStack(alignment: .top) {
            // Immagine di base in bianco e nero
            Image(svgImageName)
                .resizable()
                .scaledToFit()
                .foregroundStyle(.gray.opacity(0.3))
            
            // Livello colorato sopra
            Image(svgImageName)
                .resizable()
                .scaledToFit()
                .foregroundStyle(color)
                .mask(
                    GeometryReader { geo in
                        Rectangle()
                            .frame(height: geo.size.height * progress)
                            .frame(maxHeight: .infinity, alignment: .bottom)
                    }
                )
            //                .animation(.easeInOut(duration: 0.3), value: progress)
        }
    }
}
