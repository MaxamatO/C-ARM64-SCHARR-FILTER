//
//  ContentView.swift
//  ScharrFilter
//
//  Created by Maksymilian Pierchała on 14/10/2025.
//

import SwiftUI
import AppKit
internal import UniformTypeIdentifiers

class CImageFields{
    var data: UnsafeMutablePointer<UInt8>?
    var width: Int32?
    var height: Int32?
    var bitsPerComponent: Int32?
    var bytesPerRow: Int32?
    var colorSpace = 0
    var bitmapInfo = 0
}

struct ContentView: View {
    @State private var inputImage: NSImage? = nil
    @State private var processedImage: NSImage? = nil
    
    var body: some View {
        VStack {
            Text("Scharr Filter Preview")
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.top)
            HStack{
                VStack{
                    Button("Run C filtering") {
                        filterImageC()
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.bottom)                }
                VStack{
                    Button("Run ASM filtering") {
                        Void()
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.bottom)
                }
            }

            HStack {
                VStack {
                    Text("Oryginalny obraz")
                        .font(.headline)

                    if let image = inputImage {
                        Image(nsImage: image)
                            .resizable()
                            .scaledToFit()
                            .border(Color.gray.opacity(0.4), width: 1)
                            .padding()
                    } else {
                        Rectangle()
                            .fill(Color.gray.opacity(0.1))
                            .overlay(
                                Text("Brak obrazu")
                                    .foregroundColor(.secondary)
                            )
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .border(Color.gray.opacity(0.4), width: 1)
                            .padding()
                    }
                }

                Divider()

                VStack {
                    Text("Przefiltrowany obraz (puste)")
                        .font(.headline)
                        .foregroundColor(.gray)
                    if let image = processedImage {
                        Image(nsImage: image)
                            .resizable()
                            .scaledToFit()
                            .border(Color.gray.opacity(0.4), width: 1)
                            .padding()
                    } else {
                        Rectangle()
                            .fill(Color.gray.opacity(0.1))
                            .overlay(Text("Brak danych").foregroundColor(.secondary))
                            .padding()
                    }
                }
            }
            .padding()
            .frame(maxHeight: .infinity)

            HStack {
                Button("Wybierz obraz z Findera") {
                    openImageWithFinder()
                }
                .buttonStyle(.borderedProminent)
                .padding(.bottom)
            }
        }
        .padding()
        .frame(minWidth: 800, minHeight: 500)
    }

    // MARK: - Finder image picker
    func openImageWithFinder() {
        let panel = NSOpenPanel()
        panel.title = "Wybierz obraz do filtracji"
        panel.allowedContentTypes = [.png, .jpeg, .tiff, .bmp]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false

        if panel.runModal() == .OK, let url = panel.url {
            if let image = NSImage(contentsOf: url) {
                self.inputImage = image
            }
        }
    }
    // MARK: - C function filtering
    func filterImageC() -> Void?{
        guard let cgImage = inputImage?.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return nil
        }
        
        let width = cgImage.width
        let height = cgImage.height
        let bitsPerComponent = 8
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        
        var pixelData = [UInt8](repeating: 0, count: height * bytesPerRow)
        
        guard let context = CGContext(
                data: &pixelData,
                width: width,
                height: height,
                bitsPerComponent: bitsPerComponent,
                bytesPerRow: bytesPerRow,
                space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
            ) else {
                print("Nie udało się stworzyć kontekstu źródłowego")
                return nil
            }

            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        pixelData.withUnsafeMutableBytes { rawBufferPtr in
            let pixelsPtr = rawBufferPtr.bindMemory(to: UInt8.self).baseAddress!
            
            let returnedCImage = processImage(pixelsPtr, Int32(width), Int32(height), Int32(bytesPerRow))

            guard let newContext = CGContext(
                data: returnedCImage.data,
                width: Int(returnedCImage.width),
                height: Int(returnedCImage.height),
                bitsPerComponent: Int(returnedCImage.bitsPerComponent),
                bytesPerRow: Int(returnedCImage.bytesPerRow),
                space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
            ),
            let newCGImage = newContext.makeImage() else {
                print("Nie udało się stworzyć nowego CGImage")
                return
            }

            let nsImage = NSImage(cgImage: newCGImage, size: NSSize(width: width, height: height))
            self.processedImage = nsImage;
            free(returnedCImage.data!)
        }
        
        return nil;
    }
}

#Preview {
    ContentView()
}
