//
//  ContentView.swift
//  ImageGenie
//
//  Created by Petra Cackov on 22. 5. 24.
//

import SwiftUI

enum OutputType: String, CaseIterable {
    case png
    case pdf
    case jpeg
    case tiff
    case onePdf
    
    var bitmap: NSBitmapImageRep.FileType? {
        switch self {
        case .png: .png
        case .jpeg: .jpeg
        case .tiff: .tiff
        case .pdf: nil
        case .onePdf: nil
        }
    }
    
    var suffix: String {
        switch self {
        case .jpeg, .pdf, .png, .tiff: self.rawValue
        case .onePdf: OutputType.pdf.rawValue
        }
    }
}

struct ContentView: View {
    
    @StateObject private var viewModel = ViewModel()
    
    @State private var selectedOutputType: OutputType = .png
    @State private var showFileImporter: Bool = false
    @State private var fileExporterIsPresented: Bool = false
    
    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text(viewModel.error ?? "")
                    .foregroundStyle(.red)
                Spacer()
                
            }
            Group {
                if viewModel.images.isEmpty {
                    emptyView()
                } else {
                    imagesView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.secondary.opacity(0.2))
            .cornerRadius(5)
            
            bottomActionRow()
        }
        .padding(30)
        .fileImporter(isPresented: $showFileImporter,
                      allowedContentTypes: [.png, .pdf, .jpeg, .tiff],
                      allowsMultipleSelection: true) { result in
            switch result {
            case .success(let urls):
                viewModel.selectImages(urls: urls)
            case .failure(let error):
                viewModel.error = error.localizedDescription
            }
        }
    }
    
    
}

private extension ContentView {
    
    func emptyView() -> some View {
        VStack(spacing: 20) {
            Button {
                showFileImporter = true
            } label: {
                Text("Select images")
            }
            
            Image(systemName: "plus")
                .resizable()
                .scaledToFit()
                .frame(height: 20)
        }
    }
    
    func imagesView() -> some View {
        ScrollView {
            VStack(spacing: 40) {
                ForEach(viewModel.images, id: \.self) { image in
                    Image(nsImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 500, maxHeight: 500)
                    
                }
                
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    
    func outputFormatPicker() -> some View {
        VStack(alignment: .leading) {
            Text("Output type:")
            Picker("", selection: $selectedOutputType) {
                ForEach(OutputType.allCases, id: \.self) {
                    Text($0.rawValue)
                }
            }
            .pickerStyle(.inline)
        }
    }
    
    func bottomActionRow() -> some View {
        HStack(alignment: .bottom) {
            outputFormatPicker()
            Spacer()
            
            Button("Clear") {
                viewModel.clearImages()
            }
            .disabled(viewModel.noImagesSelected)
            
            Button("Convert") {
                viewModel.convertImages(selectedFormat: selectedOutputType)
            }
            .disabled(viewModel.noImagesSelected)
        }
    }
}

#Preview {
    ContentView()
}
