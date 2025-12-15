//
//  AppIconGenerator.swift
//  HeadsUp
//
//  Generates beautiful app icons at various sizes
//

import SwiftUI
import AppKit

// MARK: - App Icon Generator
struct AppIconGenerator {

    // MARK: - Icon Sizes
    static let iconSizes: [CGFloat] = [
        16, 32, 64, 128, 256, 512, 1024
    ]

    // MARK: - Generate Icons
    static func generateAllIcons(outputDirectory: URL) {
        for size in iconSizes {
            let image = generateIcon(size: size)
            saveIcon(image: image, size: size, directory: outputDirectory)
        }
    }

    static func generateIcon(size: CGFloat) -> NSImage {
        let view = AppIconView()
        let hostingView = NSHostingView(rootView: view)
        hostingView.frame = CGRect(x: 0, y: 0, width: size, height: size)

        // Render the view to an image
        let image = NSImage(size: NSSize(width: size, height: size))
        image.lockFocus()

        if let context = NSGraphicsContext.current?.cgContext {
            hostingView.layer?.render(in: context)
        }

        image.unlockFocus()
        return image
    }

    static func saveIcon(image: NSImage, size: CGFloat, directory: URL) {
        guard let tiffData = image.tiffRepresentation,
              let bitmapImage = NSBitmapImageRep(data: tiffData),
              let pngData = bitmapImage.representation(using: .png, properties: [:]) else {
            return
        }

        let filename = "icon_\(Int(size))x\(Int(size)).png"
        let fileURL = directory.appendingPathComponent(filename)

        try? pngData.write(to: fileURL)
        print("✓ Generated icon: \(filename)")
    }
}

// MARK: - App Icon View
struct AppIconView: View {
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(red: 0.0, green: 0.48, blue: 1.0),     // Blue
                    Color(red: 0.35, green: 0.34, blue: 0.84)    // Purple
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Icon content
            GeometryReader { geometry in
                let size = geometry.size.width

                ZStack {
                    // Calendar base
                    RoundedRectangle(cornerRadius: size * 0.12)
                        .fill(Color.white.opacity(0.95))
                        .frame(width: size * 0.65, height: size * 0.65)
                        .shadow(color: .black.opacity(0.2), radius: size * 0.03, y: size * 0.02)

                    VStack(spacing: size * 0.02) {
                        // Calendar header
                        RoundedRectangle(cornerRadius: size * 0.05)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 1.0, green: 0.27, blue: 0.23),  // Red
                                        Color(red: 1.0, green: 0.35, blue: 0.33)   // Light red
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: size * 0.65, height: size * 0.12)
                            .offset(y: size * 0.005)

                        // Calendar date grid
                        VStack(spacing: size * 0.03) {
                            ForEach(0..<3) { row in
                                HStack(spacing: size * 0.03) {
                                    ForEach(0..<4) { col in
                                        RoundedRectangle(cornerRadius: size * 0.015)
                                            .fill(
                                                (row == 1 && col == 1) ?
                                                Color(red: 0.0, green: 0.48, blue: 1.0) :
                                                Color.gray.opacity(0.3)
                                            )
                                            .frame(width: size * 0.08, height: size * 0.06)
                                    }
                                }
                            }
                        }
                        .offset(y: size * 0.04)
                    }

                    // Alert bell overlay
                    ZStack {
                        // Bell shadow
                        Circle()
                            .fill(Color.black.opacity(0.2))
                            .frame(width: size * 0.38, height: size * 0.38)
                            .blur(radius: size * 0.02)
                            .offset(x: size * 0.22, y: size * 0.24)

                        // Bell background
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 1.0, green: 0.58, blue: 0.0),   // Orange
                                        Color(red: 1.0, green: 0.45, blue: 0.0)    // Dark orange
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: size * 0.35, height: size * 0.35)
                            .shadow(color: .black.opacity(0.3), radius: size * 0.02)
                            .offset(x: size * 0.22, y: size * 0.22)

                        // Bell icon
                        Image(systemName: "bell.fill")
                            .font(.system(size: size * 0.18, weight: .semibold))
                            .foregroundColor(.white)
                            .offset(x: size * 0.22, y: size * 0.21)

                        // Notification badge
                        Circle()
                            .fill(Color.red)
                            .frame(width: size * 0.08, height: size * 0.08)
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: size * 0.008)
                            )
                            .offset(x: size * 0.32, y: size * 0.12)
                    }
                }
                .frame(width: size, height: size)
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

// MARK: - Icon Preview
struct AppIconPreview: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("HeadsUp App Icon")
                .font(.title)
                .fontWeight(.bold)

            HStack(spacing: 20) {
                ForEach([128.0, 256.0, 512.0], id: \.self) { size in
                    VStack {
                        AppIconView()
                            .frame(width: size * 0.3, height: size * 0.3)
                            .cornerRadius(size * 0.05)

                        Text("\(Int(size))×\(Int(size))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Button("Generate Icons") {
                generateIcons()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(40)
    }

    func generateIcons() {
        // Get desktop directory
        let desktopURL = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first!
        let iconsFolder = desktopURL.appendingPathComponent("HeadsUpIcons")

        // Create folder if it doesn't exist
        try? FileManager.default.createDirectory(at: iconsFolder, withIntermediateDirectories: true)

        // Generate all icons
        AppIconGenerator.generateAllIcons(outputDirectory: iconsFolder)

        // Open the folder
        NSWorkspace.shared.open(iconsFolder)

        print("✅ Icons generated successfully at: \(iconsFolder.path)")
    }
}

// MARK: - Preview
#Preview {
    AppIconPreview()
        .frame(width: 800, height: 600)
}
