//
//  ContentView.swift
//  Instafilter
//
//  Created by Onur Ay on 14.09.26.
//
import CoreImage
import CoreImage.CIFilterBuiltins
import PhotosUI
import StoreKit
import SwiftUI

struct ContentView: View {
    @State private var processedImage: Image?
    @State private var filterIntensity = 0.5
    @State private var selectedItem: PhotosPickerItem?
    @State private var showingFilters = false
    
    @AppStorage("filterCount") var filterCount = 0
    @Environment(\.requestReview) var requestReview
    
    @State private var currentFilter : CIFilter = CIFilter.sepiaTone()
    let context = CIContext()
    @State private var inputKeys : [String]? = []
    @State private var inputValues: [Double] = []
    
    var body: some View {
        NavigationStack {
        VStack {
            Spacer()
            
            PhotosPicker(selection: $selectedItem) {
                
                if let processedImage {
                    processedImage
                        .resizable()
                        .scaledToFit()
                } else {
                    ContentUnavailableView("No Picture", systemImage: "photo.badge.plus", description: Text("Tap to import photo"))
                }
            }
            .buttonStyle(.plain)
            .onChange(of: selectedItem, loadImage)
            
            
            
            Spacer()
            
            HStack {
                
               
                
                VStack {
                    
                    ForEach(0..<inputKeys!.count, id: \.self) { key in
                        
                        HStack {
                            
                            Text("\(inputKeys![key])")
                            
                            Slider(value: $filterIntensity)
                                .disabled(processedImage == nil)
                                .onChange(of: filterIntensity, applyProcessing)
                            
                        }
                    }
                }
                   
                }
                
            
            HStack {
                Button("Change Filter", action: changeFilter)
                    .disabled(processedImage == nil)
                Spacer()
                
                if let processedImage {
                    ShareLink(item: processedImage, preview: SharePreview("Instafilter image", image: processedImage))
                }
            }
        }
        .padding([.horizontal, .bottom])
        .navigationTitle("InstaFilter")
        .confirmationDialog("Select a filter", isPresented: $showingFilters) {
            Button("Crystalize") {  setFilter(CIFilter.crystallize()) }
            Button("Edges") {  setFilter(CIFilter.edges()) }
            Button("Guassian Blur") {  setFilter(CIFilter.gaussianBlur()) }
            Button("Pixellate") {  setFilter(CIFilter.pixellate()) }
            Button("Sepia Tone") {  setFilter(CIFilter.sepiaTone()) }
            Button("Unsharp Mask") {  setFilter(CIFilter.unsharpMask()) }
            Button("Vignette") {  setFilter(CIFilter.vignette()) }
            Button("Alpha-Histogramm") {
                let filter = CIFilter.areaAlphaWeightedHistogram()
                filter.extent = CGRect(x: 0, y: 0, width: 300, height: 300)
                setFilter(filter)
                 }
            Button("Area Bounds Red") {
                let filter = CIFilter.areaBoundsRed()
                filter.extent = CGRect(x: 0, y: 0, width: 300, height: 300)
                setFilter(filter)
            }
            Button("Area Average") {
                let filter = CIFilter.areaAverage()
                filter.extent = CGRect(x: 0, y: 0, width: 300, height: 300)
                setFilter(filter)
            }
            Button("Cancel", role: .cancel) {}

        }
        }
        .onAppear(perform: createValues)
                
    }
    
    func changeFilter() {
         showingFilters = true
    }
    
    func loadImage() {
        Task { // i added the do catch because i wanted to get rid of the throws warning
            do {
                guard let imageData = try await selectedItem?.loadTransferable(type: Data.self) else { return }
                guard let inputImage = UIImage(data: imageData) else { return }
                
                let beginImage = CIImage(image: inputImage)
                currentFilter.setValue(beginImage, forKey: kCIInputImageKey)
                applyProcessing()
            } catch {
                
            }
        }
    }
    
    func applyProcessing() {
        
        let inputKeys = currentFilter.inputKeys
        
        if inputKeys.contains(kCIInputIntensityKey) {
            currentFilter.setValue(filterIntensity, forKey: kCIInputIntensityKey)
        }
        if inputKeys.contains(kCIInputRadiusKey) {
            currentFilter.setValue(filterIntensity * 200, forKey: kCIInputRadiusKey)
        }
        if inputKeys.contains(kCIInputScaleKey) {
            currentFilter.setValue(filterIntensity * 10, forKey: kCIInputScaleKey)
        }
        
        guard let outputImage = currentFilter.outputImage else { return }
        guard let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else { return }
        
        let uiImage = UIImage(cgImage: cgImage)
        processedImage = Image(uiImage: uiImage)
        
    }
    
    @MainActor
    func setFilter(_ filter: CIFilter) {
        currentFilter = filter
        loadImage()
        
        filterCount += 1
        
        if filterCount >= 20 {
            requestReview()
        }
    }
    
    func createValues() {
        
        inputKeys = currentFilter.inputKeys
        
        
        for _ in inputKeys! {
            inputValues.append(0.5)
        }
        
    }
}

#Preview {
    ContentView()
}
