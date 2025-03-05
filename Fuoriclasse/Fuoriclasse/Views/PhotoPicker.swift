//
//  PhotoPicker.swift
//  Fuoriclasse
//
//  Created by Louis Almairac on 03/03/2025.
//

import PhotosUI
import SwiftUI

struct PhotoPicker: UIViewControllerRepresentable {
    @Binding var photoData: Data?
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {
        // Pas de mise à jour continue nécessaire
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PhotoPicker
        
        init(_ parent: PhotoPicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            guard let provider = results.first?.itemProvider,
                  provider.canLoadObject(ofClass: UIImage.self) else {
                return
            }
            provider.loadObject(ofClass: UIImage.self) { [weak self] image, error in
                guard let self = self,
                      let uiImage = image as? UIImage else { return }
                DispatchQueue.main.async {
                    self.parent.photoData = uiImage.jpegData(compressionQuality: 0.8)
                }
            }
        }
    }
}
