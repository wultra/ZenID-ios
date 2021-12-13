//
//  FaceLivenessVerifier.swift
//  RecogLib-iOS
//
//  Created by Jiri Sacha on 19/05/2020.
//  Copyright © 2020 Marek Stana. All rights reserved.
//

import Foundation
import CoreMedia

public class FaceLivenessVerifier {
    private var cppObject: UnsafeRawPointer?

    public var language: SupportedLanguages
    private let settings: FaceLivenessVerifierSettings?
    
    public var showDebugInfo: Bool = false {
        didSet {
            setFaceLivenessDebugInfo(cppObject, showDebugInfo)
        }
    }
        
    public init(language: SupportedLanguages, settings: FaceLivenessVerifierSettings? = nil) {
        self.language = language
        self.settings = settings
    }
    
    public func loadModels(_ loader: FaceVerifierModels) {
        loader.loadPointer { pointer, data in
            var verifierSettings = createVerifierSettings(settings: settings)
            cppObject = RecogLib_iOS.getFaceLivenessVerifier(loader.url.path.toUnsafeMutablePointer()!, &verifierSettings)
        }
    }
    
    public func verify(buffer: CMSampleBuffer, orientation: UIInterfaceOrientation = .portrait) -> FaceLivenessResult? {
        do {
            var face = createFaceLivenessInfo(orientation: orientation)
            RecogLib_iOS.verifyFaceLiveness(cppObject, buffer, &face)
            return FaceLivenessResult(faceLivenessState: face.state, signature: face.signature)
        } catch {
            ApplicationLogger.shared.Error(error.localizedDescription)
        }
    }
    
    public func verifyImage(imageBuffer: CVPixelBuffer, orientation: UIInterfaceOrientation = .portrait) -> FaceLivenessResult? {
        do {
            var face = createFaceLivenessInfo(orientation: orientation)
            RecogLib_iOS.verifyFaceLivenessImage(cppObject, imageBuffer, &face)
            return FaceLivenessResult(faceLivenessState: face.state, signature: face.signature)
        } catch {
            ApplicationLogger.shared.Error(error.localizedDescription)
        }
    }
    
    /*public func getAuxiliaryInfo() -> FaceLivenessAuxiliaryInfo? {
        do {
            let cInfo = RecogLib_iOS.getAuxiliaryInfo(cppObject)
            let info = createFaceLivenessAuxiliaryInfo(info: cInfo)
            if info.images.isEmpty || info.metadata.isEmpty {
                return nil
            }
            return info
        } catch {
            ApplicationLogger.shared.Error(error.localizedDescription)
        }
        return nil
    }*/
    
    public func reset() {
        RecogLib_iOS.faceLivenessVerifierReset(cppObject)
    }
    
    public func getRenderCommands(canvasWidth: Int, canvasHeight: Int, orientation: UIInterfaceOrientation = .portrait) -> String? {
        var face = createFaceLivenessInfo(orientation: orientation)
        let cString = RecogLib_iOS.getFaceLivenessRenderCommands(cppObject, Int32(canvasWidth), Int32(canvasHeight), &face)
        defer { free(cString) }
        
        var result: String?
        if let unwrappedCString = cString {
            result = String(cString: unwrappedCString)
        }
        
        return result
    }
    
    private func createFaceLivenessInfo(orientation: UIInterfaceOrientation) -> CFaceLivenessInfo {
        return CFaceLivenessInfo(
            state: -1,
            orientation: Int32(orientation.rawValue),
            language: Int32(language.rawValue),
            signature: .init()
        )
    }
    
    private func createVerifierSettings(settings: FaceLivenessVerifierSettings?) -> CFaceLivenessVerifierSettings {
        return CFaceLivenessVerifierSettings(
            enableLegacyMode: settings?.isLegacyModeEnabled ?? false,
            maxAuxiliaryImageSize: Int32(settings?.maxAuxiliaryImageSize ?? 300)
        )
    }
    
    private func createFaceLivenessAuxiliaryInfo(info: CFaceLivenessAuxiliaryInfo) -> FaceLivenessAuxiliaryInfo {
        var images = [Data]()
        var metadata = [FaceLivenessAuxiliaryMetadata]()
        if let cImages = info.images, let cMetadata = info.metadata {
            let imagesBuffer = UnsafeBufferPointer(start: cImages, count: Int(info.imagesSize))
            for image in Array(imagesBuffer) {
                images.append(Data(bytes: image.image, count: Int(image.imageSize)))
            }
            
            let metadataString = String(cString: UnsafePointer<CChar>(cMetadata))
            let metadataData = metadataString.data(using: .utf8) ?? Data()
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .secondsSince1970
            if let decodedMetadata = try? decoder.decode([FaceLivenessAuxiliaryMetadata].self, from: metadataData) {
                metadata.append(contentsOf: decodedMetadata)
            }
        }
        return .init(
            images: images,
            metadata: metadata
        )
    }
}
