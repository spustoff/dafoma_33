//
//  CameraService.swift
//  TaskVantage Road
//
//  Created by Developer on 1/9/25.
//

import Foundation
import SwiftUI
import AVFoundation
import Vision
import VisionKit

class CameraService: NSObject, ObservableObject {
    @Published var isShowingCamera = false
    @Published var isShowingDocumentScanner = false
    @Published var capturedImage: UIImage?
    @Published var extractedText: String = ""
    @Published var isProcessing = false
    @Published var errorMessage: String?
    
    override init() {
        super.init()
        checkCameraPermission()
    }
    
    // MARK: - Camera Permission
    private func checkCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            break
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { _ in }
        case .denied, .restricted:
            errorMessage = "Camera access is required to scan documents and capture images"
        @unknown default:
            break
        }
    }
    
    // MARK: - Document Scanning
    func startDocumentScanning() {
        guard VNDocumentCameraViewController.isSupported else {
            errorMessage = "Document scanning is not supported on this device"
            return
        }
        isShowingDocumentScanner = true
    }
    
    func processScannedDocument(_ image: UIImage) {
        capturedImage = image
        extractTextFromImage(image)
    }
    
    // MARK: - Text Extraction
    private func extractTextFromImage(_ image: UIImage) {
        guard let cgImage = image.cgImage else {
            errorMessage = "Failed to process image"
            return
        }
        
        isProcessing = true
        
        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        let request = VNRecognizeTextRequest { [weak self] request, error in
            DispatchQueue.main.async {
                self?.isProcessing = false
                
                if let error = error {
                    self?.errorMessage = "Text recognition failed: \(error.localizedDescription)"
                    return
                }
                
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    self?.errorMessage = "No text found in image"
                    return
                }
                
                let recognizedText = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }.joined(separator: "\n")
                
                self?.extractedText = recognizedText
                self?.processExtractedText(recognizedText)
            }
        }
        
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        
        do {
            try requestHandler.perform([request])
        } catch {
            DispatchQueue.main.async {
                self.isProcessing = false
                self.errorMessage = "Failed to perform text recognition: \(error.localizedDescription)"
            }
        }
    }
    
    // MARK: - Text Processing and Task Generation
    private func processExtractedText(_ text: String) {
        let tasks = generateTasksFromText(text)
        
        // Notify about generated tasks
        NotificationCenter.default.post(
            name: .tasksGeneratedFromText,
            object: nil,
            userInfo: ["tasks": tasks, "originalText": text]
        )
    }
    
    private func generateTasksFromText(_ text: String) -> [TaskModel] {
        var generatedTasks: [TaskModel] = []
        
        // Split text into lines and process each line
        let lines = text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        for line in lines {
            if let task = parseLineAsTask(line) {
                generatedTasks.append(task)
            }
        }
        
        // If no specific tasks found, create a general task with the full text
        if generatedTasks.isEmpty && !text.isEmpty {
            let generalTask = TaskModel(
                title: "Review Scanned Document",
                description: text.prefix(200).appending(text.count > 200 ? "..." : ""),
                priority: .medium
            )
            generatedTasks.append(generalTask)
        }
        
        return generatedTasks
    }
    
    private func parseLineAsTask(_ line: String) -> TaskModel? {
        // Look for common task indicators
        let taskIndicators = ["TODO:", "Task:", "Action:", "•", "-", "1.", "2.", "3.", "4.", "5."]
        let priorityKeywords = ["urgent", "critical", "important", "asap", "high priority"]
        let dateKeywords = ["due", "deadline", "by", "before"]
        
        var cleanedLine = line
        var priority: TaskPriority = .medium
        
        // Check for priority keywords
        for keyword in priorityKeywords {
            if line.localizedCaseInsensitiveContains(keyword) {
                priority = .high
                break
            }
        }
        
        // Remove task indicators
        for indicator in taskIndicators {
            if cleanedLine.hasPrefix(indicator) {
                cleanedLine = String(cleanedLine.dropFirst(indicator.count))
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                break
            }
        }
        
        // Skip very short or long lines
        guard cleanedLine.count > 5 && cleanedLine.count < 100 else { return nil }
        
        // Create task
        var task = TaskModel(
            title: cleanedLine,
            description: "Generated from scanned document",
            priority: priority
        )
        
        // Try to extract due date
        task.dueDate = extractDateFromText(line)
        
        return task
    }
    
    private func extractDateFromText(_ text: String) -> Date? {
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue)
        let matches = detector?.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count))
        
        return matches?.first?.date
    }
    
    // MARK: - Image Capture
    func captureImage(_ image: UIImage) {
        capturedImage = image
        extractTextFromImage(image)
    }
    
    // MARK: - Utility Methods
    func clearCapturedData() {
        capturedImage = nil
        extractedText = ""
        errorMessage = nil
    }
    
    func saveImageToDocuments(_ image: UIImage, withName name: String) -> String? {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        
        let fileName = "\(name)_\(Date().timeIntervalSince1970).jpg"
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            return nil
        }
        
        do {
            try imageData.write(to: fileURL)
            return fileURL.path
        } catch {
            errorMessage = "Failed to save image: \(error.localizedDescription)"
            return nil
        }
    }
}

// MARK: - VNDocumentCameraViewControllerDelegate
extension CameraService: VNDocumentCameraViewControllerDelegate {
    func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
        guard scan.pageCount > 0 else {
            controller.dismiss(animated: true)
            return
        }
        
        // Process the first scanned page
        let image = scan.imageOfPage(at: 0)
        processScannedDocument(image)
        
        controller.dismiss(animated: true)
    }
    
    func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
        controller.dismiss(animated: true)
    }
    
    func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
        errorMessage = "Document scanning failed: \(error.localizedDescription)"
        controller.dismiss(animated: true)
    }
}

// MARK: - Notifications
extension Notification.Name {
    static let tasksGeneratedFromText = Notification.Name("tasksGeneratedFromText")
}

// MARK: - Document Scanner View
struct DocumentScannerView: UIViewControllerRepresentable {
    @ObservedObject var cameraService: CameraService
    
    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let scanner = VNDocumentCameraViewController()
        scanner.delegate = cameraService
        return scanner
    }
    
    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {
        // No updates needed
    }
}

// MARK: - Camera View
struct CameraView: UIViewControllerRepresentable {
    @ObservedObject var cameraService: CameraService
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
        // No updates needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView
        
        init(_ parent: CameraView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.cameraService.captureImage(image)
            }
            picker.dismiss(animated: true)
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}

