//
//  ViewModel.swift
//  ImageGenie
//
//  Created by Petra Cackov on 23. 5. 24.
//

import AppKit
import Quartz

class ViewModel: ObservableObject {
    
    @Published var images: [NSImage] = []
    @Published var error: String?
    var noImagesSelected: Bool { images.isEmpty }
    
    func selectImages(urls: [URL]) {
        let images: [NSImage] = urls.compactMap { url in
            guard url.startAccessingSecurityScopedResource() else {
                error = "Access denied"
                return nil
            }
            
            if let imageData = try? Data(contentsOf: url), let image = NSImage(data: imageData) {
                url.stopAccessingSecurityScopedResource()
                return image
            } else {
                error = "Can't get data"
                url.stopAccessingSecurityScopedResource()
                return nil
            }
            
        }
        self.images = images
        self.error = nil
    }

    func clearImages() {
        images = []
        error = nil
    }
    
    func convertImages(selectedFormat: OutputType) {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Select Folder"
        
        panel.begin { [weak self] response in
            guard let images = self?.images else {
                self?.error = "No images selected"
                return
            }
            if response == .OK, let directoryURL = panel.url {
                self?.saveImages(images, to: directoryURL, format: selectedFormat)
            } else {
                self?.error = "Folder selection was cancelled."
            }
        }
    }
    
    private func saveImages(_ images: [NSImage], to url: URL, format: OutputType) {
        switch format {
        case .png, .jpeg, .tiff:
            images.enumerated().forEach { index, image in
                guard let fileType = format.bitmap else {
                    error = "Not supported type"
                    return
                }
                let fileURL = appendFileName(to: url, forIndex: index, format: format)
                saveAsFileType(image, fileType: fileType, to: fileURL)
            }
        case .pdf: 
            images.enumerated().forEach { index, image in
                let fileURL = appendFileName(to: url, forIndex: index, format: format)
                saveImagesAsPDF([image], to: fileURL)
            }
        case .onePdf:
            let fileURL = appendFileName(to: url, forIndex: 0, format: format)
            saveImagesAsPDF(images, to: fileURL)
        }
    }
    
    private func appendFileName(to url: URL, forIndex index: Int, format: OutputType) -> URL {
        let fileName = "Image\(index).\(format.suffix)"
        return url.appendingPathComponent(fileName)
    }
    
    private func saveAsFileType(_ image: NSImage, fileType: NSBitmapImageRep.FileType, to url: URL) {
        guard let tiffRepresentation = image.tiffRepresentation, let imageRep = NSBitmapImageRep(data: tiffRepresentation) else {
            error = "Failed to convert image to bitmap representation"
            return
        }
        
        guard let data = imageRep.representation(using: fileType, properties: [:]) else {
            error = "Failed to convert image to \(fileType.rawValue)"
            return
        }
        
        do {
            try data.write(to: url)
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    private func saveImagesAsPDF(_ images: [NSImage], to url: URL) {
        // Create a PDF document
        let pdfDocument = PDFDocument()
        
        images.enumerated().forEach { index, image in
            // Create a PDF page with the image
            let pdfPage = PDFPage(image: image)
            pdfDocument.insert(pdfPage!, at: index)
        }
        
        // Write the PDF document to the specified URL
        let success = pdfDocument.write(to: url)
        if !success {
            error = "Could not write to pdf"
        }
    }
}

