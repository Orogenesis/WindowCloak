//
//  PreviewWindowView.swift
//  WindowCloak
//
//  Created on 2025-10-07.
//

import SwiftUI

// MARK: - PreviewWindowView

struct PreviewWindowView: View {
    let currentFrame: CGImage?

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black
                    .ignoresSafeArea()

                if let frame = currentFrame {
                    Image(decorative: frame, scale: 1.0)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(2)
                            .tint(.white)

                        Text("Initializing filtered capture...")
                            .font(.title2)
                            .foregroundColor(.white)

                        Text("Share THIS window in Google Meet/Zoom")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }
}
