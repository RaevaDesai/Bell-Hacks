//
//  ContentView.swift
//  glowify
//
//  Created by Raeva Desai on 2/3/24.
//

import SwiftUI
import UIKit
import CoreML
import Vision

class SkinEvaluationViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var evaluateButton: UIButton!
    @IBOutlet weak var resultLabel: UILabel!
    
    var model: YourSkinEvaluationModelClass = YourSkinEvaluationModelClass() // Replace with your actual model class
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Additional setup code, if any
    }
    
    // MARK: - Image Capture and Processing
    
    @IBAction func takePhotoButtonPressed(_ sender: UIButton) {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .camera
        imagePicker.delegate = self
        present(imagePicker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let pickedImage = info[.originalImage] as? UIImage {
            imageView.image = pickedImage
        }
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Skin Evaluation
    
    @IBAction func evaluateButtonPressed(_ sender: UIButton) {
        guard let image = imageView.image else {
            // Handle case where no image is selected
            return
        }
        
        // Resize image if needed
        let resizedImage = resizeImage(image: image, targetSize: CGSize(width: 224, height: 224))
        
        // Convert UIImage to CVPixelBuffer
        guard let pixelBuffer = resizedImage.toCVPixelBuffer() else {
            // Handle conversion failure
            return
        }
        
        // Make a prediction with the Core ML model
        do {
            let prediction = try model.prediction(image: pixelBuffer)
            
            // Extract predicted scores for oiliness, dryness, and acne
            let oilinessScore = prediction.oiliness
            let drynessScore = prediction.dryness
            let acneScore = prediction.acne
            
            // Calculate an overall ranking (you may adjust this based on your model output)
            let overallRanking = (oilinessScore + drynessScore + acneScore) / 3.0
            
            // Display the result to the user
            resultLabel.text = "Skin Ranking: \(overallRanking)"
            
            // Provide skincare recommendations based on the ranking (implement this part)
            provideSkincareRecommendations(overallRanking: overallRanking)
            
        } catch {
            // Handle prediction error
            print("Error making prediction: \(error.localizedDescription)")
        }
    }
    
    // Function to resize UIImage
    func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage {
        let size = image.size
        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height
        let newSize = widthRatio > heightRatio ? CGSize(width: size.width * heightRatio, height: size.height * heightRatio) : CGSize(width: size.width * widthRatio, height: size.height * widthRatio)
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage ?? UIImage()
    }
}

// Extension to convert UIImage to CVPixelBuffer
extension UIImage {
    func toCVPixelBuffer() -> CVPixelBuffer? {
        let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue, kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(kCFAllocatorDefault, Int(size.width), Int(size.height), kCVPixelFormatType_32ARGB, attrs, &pixelBuffer)
        
        guard status == kCVReturnSuccess, let buffer = pixelBuffer else {
            return nil
        }
        
        CVPixelBufferLockBaseAddress(buffer, CVPixelBufferLockFlags(rawValue: 0))
        let context = CGContext(data: CVPixelBufferGetBaseAddress(buffer), width: Int(size.width), height: Int(size.height), bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(buffer), space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)
        
        guard let cgImage = self.cgImage, let cgContext = context else {
            return nil
        }
        
        cgContext.draw(cgImage, in: CGRect(origin: .zero, size: size))
        CVPixelBufferUnlockBaseAddress(buffer, CVPixelBufferLockFlags(rawValue: 0))
        
        return buffer
    }
}

