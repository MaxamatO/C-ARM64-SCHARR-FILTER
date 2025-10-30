//
//  ContentView.swift
//  ScharrFilter
//
//  Created by Maksymilian Pierchała on 14/10/2025.
//

import SwiftUI
import AppKit
internal import UniformTypeIdentifiers
import Darwin
import Foundation



struct ContentView: View {
    @State private var inputImage: NSImage? = nil
    @State private var processedImage: NSImage? = nil
    @State private var threadCount: Int = 1
    struct CProcessedData{
        var data: UnsafeMutablePointer<UInt8>?
        var height: Int32 = 1
        var width: Int32 = 1
        var bytesPerRow: Int32 = 4
        var bitsPerComponent: Int32 = 8
    }

    typealias ProcessImageFunctionC = @convention(c) (
        UnsafeMutablePointer<UInt8>,
        Int32,
        Int32,
        Int32,
        Int32,
        UnsafeMutableRawPointer
    ) -> Void

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
            VStack(alignment: .leading) {
                            Text("Liczba wątków: \(threadCount)")
                                .font(.headline)
                Slider(value: $threadCount.double, in: 1...64, step: 1) {
                                Text("Liczba wątków")
                            } minimumValueLabel: {
                                Text("1")
                            } maximumValueLabel: {
                                Text("64")
                            }
                            .padding(.horizontal)
                        }
                        .padding(.bottom, 10)

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
    
    private struct IntDoubleBinding: View {
            @Binding var value: Int
            var body: some View {
                Slider(value: Binding(get: { Double(value) }, set: { value = Int($0) }), in: 1...64, step: 1)
            }
        }

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
    
    func filterImageC() -> Void? {
        runDynamicFilter(symbolName: "processImage")
    }

    func filterImageASM() -> Void? {
        return nil
    }
    
    func runDynamicFilter(symbolName: String) -> Void? {
        guard let cgImage = inputImage?.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return nil }
        
        let width = cgImage.width
        let height = cgImage.height
        let bitsPerComponent = 8
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        var pixelData = [UInt8](repeating: 0, count: height * bytesPerRow)
        
        guard let frameworksPath = Bundle.main.privateFrameworksPath else {
            print("Nie znaleziono sciezki do frameworka")
            return nil
        }
        
        let dylibPath = frameworksPath + "/ScharrCore.framework/ScharrCore"
        
        let handle = dlopen(dylibPath, RTLD_NOW)
        guard handle != nil else {
            let error = String(cString: dlerror())
            print("Błąd ładowania biblioteki (\(dylibPath)): \(error)")
            return nil
        }

        
        let symbol = dlsym(handle, symbolName)
        guard symbol != nil else {
            print("Błąd: Nie znaleziono symbolu \(symbolName).")
            dlclose(handle)
            return nil
        }

        let processImagePtr = unsafeBitCast(symbol, to: ProcessImageFunctionC.self)
        
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
            dlclose(handle)
            return nil
        }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        let finalThreadCount = threadCount

        var result = CProcessedData()
    
        pixelData.withUnsafeMutableBytes { rawBufferPtr in
            let pixelsPtr = rawBufferPtr.bindMemory(to: UInt8.self).baseAddress!

            withUnsafeMutablePointer(to: &result){
                $0.withMemoryRebound(to: CProcessedData.self, capacity: 1) { resultPtr in
                    processImagePtr(
                        pixelsPtr,
                        Int32(width),
                        Int32(height),
                        Int32(bytesPerRow),
                        Int32(finalThreadCount),
                        UnsafeMutableRawPointer(resultPtr)
                    )
                }
            }
        }
        defer{dlclose(handle)}
        guard let dataPtr = result.data else {
            print("brak danych w struktrze")
            return nil
        }
        guard let newContext = CGContext(
                    data: dataPtr,
                    width: Int(result.width),
                    height: Int(result.height),
                    bitsPerComponent: Int(result.bitsPerComponent),
                    bytesPerRow: Int(result.bytesPerRow),
                    space: colorSpace,
                    bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
                ), let newCGImage = newContext.makeImage() else {
                    print("Nie udało się stworzyć nowego CGImage")
                    return nil
                }

                let nsImage = NSImage(cgImage: newCGImage, size: NSSize(width: width, height: height))
                self.processedImage = nsImage
        
        return nil
    }
}
extension Binding where Value == Int {
    var double: Binding<Double> {
        return Binding<Double>(get: {
            Double(self.wrappedValue)
        }, set: {
            self.wrappedValue = Int($0)
        })
    }
}

#Preview {
    ContentView()
}
