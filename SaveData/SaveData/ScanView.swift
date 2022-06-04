//
//  ScanView.swift
//  SaveData
//
//  Created by Tino on 09/05/2022.
//

import SwiftUI
import UIKit
import Foundation
import VisionKit

// Classe de l'API VisionKit

final class ScanView: NSObject, ObservableObject {
    
    @Published var errorMessage: String?
    @Published var imageArray: [UIImage] = []
    
    func getDocumentCameraViewController() -> VNDocumentCameraViewController {
        let vc = VNDocumentCameraViewController()
        vc.delegate = self
        return vc
    }
    
    func removeImage(image: UIImage) {
        imageArray.removeAll{$0 == image}
    }
}


extension ScanView: VNDocumentCameraViewControllerDelegate {
    
    func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
        controller.dismiss(animated: true, completion: nil)
    }
      
    func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
        errorMessage = error.localizedDescription
    }
      
    func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
      print("Did Finish With Scan.")
        for i in 0..<scan.pageCount {
            self.imageArray.append(scan.imageOfPage(at:i))
        }
        controller.dismiss(animated: true, completion: nil)
    }
}
