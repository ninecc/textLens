import CoreGraphics
import Vision

final class OCRService {
    enum Error: LocalizedError {
        case invalidImage

        var errorDescription: String? {
            "Screenshot could not be read."
        }
    }

    func recognizeText(in image: CGImage) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                let text = (request.results as? [VNRecognizedTextObservation])?
                    .compactMap { $0.topCandidates(1).first?.string }
                    .joined(separator: "\n") ?? ""
                continuation.resume(returning: text.trimmingCharacters(in: .whitespacesAndNewlines))
            }
            request.recognitionLevel = .fast
            request.usesLanguageCorrection = false

            do {
                try VNImageRequestHandler(cgImage: image).perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
}
