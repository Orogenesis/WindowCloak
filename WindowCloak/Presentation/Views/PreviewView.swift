//
//  PreviewView.swift
//  WindowCloak
//
//  Created on 2025-10-07.
//

import SwiftUI
import AppKit

// MARK: - PreviewView

struct PreviewView: View {
    let currentFrame: CGImage?

    var body: some View {
        GeometryReader { geometry in
            if let frame = currentFrame {
                Image(decorative: frame, scale: 1.0)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: geometry.size.width, height: geometry.size.height)
            } else {
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.5)

                    Text("Initializing capture...")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Color.black)
    }
}

// MARK: - Image+DecorativeInit

extension Image {
    init(decorative cgImage: CGImage, scale: CGFloat) {
        let nsImage = NSImage(cgImage: cgImage, size: .zero)
        self.init(nsImage: nsImage)
    }
}
