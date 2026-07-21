import Foundation
import UIKit
import MetabolicCore

/// Errors surfaced by `ClaudeVisionClient` while analyzing a meal photo.
enum MealVisionError: Error {
    case noAPIKey
    case badResponse
    case decodingFailed
}

/// Sends a downscaled meal photo to Claude's vision API and parses the response into a
/// structured `MealPhotoAnalysis`. When no API key is stored, throws `.noAPIKey` — callers
/// in demo mode fall back to `DemoMealAnalysis.sample`.
final class ClaudeVisionClient {
    private let session: URLSession
    private let endpoint = URL(string: "https://api.anthropic.com/v1/messages")!

    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60
        config.timeoutIntervalForResource = 60
        session = URLSession(configuration: config)
    }

    func analyzeMeal(imageData: Data) async throws -> MealPhotoAnalysis {
        guard let apiKey = APIKeyStore.load(), !apiKey.isEmpty else {
            throw MealVisionError.noAPIKey
        }

        let jpegData = Self.downscaledJPEG(from: imageData)
        let base64Image = jpegData.base64EncodedString()

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "content-type")

        let body: [String: Any] = [
            "model": "claude-sonnet-5",
            "max_tokens": 1500,
            "messages": [
                [
                    "role": "user",
                    "content": [
                        [
                            "type": "image",
                            "source": [
                                "type": "base64",
                                "media_type": "image/jpeg",
                                "data": base64Image,
                            ],
                        ],
                        [
                            "type": "text",
                            "text": Self.prompt,
                        ],
                    ],
                ]
            ],
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw MealVisionError.badResponse
        }

        guard
            let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let content = root["content"] as? [[String: Any]],
            let firstText = content.first(where: { ($0["type"] as? String) == "text" })?["text"] as? String
        else {
            throw MealVisionError.decodingFailed
        }

        guard let jsonData = Self.stripJSONFence(firstText).data(using: .utf8) else {
            throw MealVisionError.decodingFailed
        }

        do {
            return try JSONDecoder().decode(MealPhotoAnalysis.self, from: jsonData)
        } catch {
            throw MealVisionError.decodingFailed
        }
    }

    // MARK: - Prompt

    private static let prompt = """
    You are a nutrition estimation assistant. Look at this photo of a meal and identify each \
    distinct food item visible. For each item, estimate the portion size in grams, a short \
    human-readable portion description, total calories, protein in grams, carbs in grams, fat \
    in grams, and your confidence in the estimate from 0 to 1.

    Respond with ONLY strict JSON in exactly this shape, no markdown fences, no commentary:
    {"items":[{"name":"","portionDescription":"","estimatedGrams":0,"calories":0,"proteinG":0,"carbsG":0,"fatG":0,"confidence":0}],"notes":null}
    """

    // MARK: - Response parsing helpers

    private static func stripJSONFence(_ text: String) -> String {
        var trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.hasPrefix("```") else { return trimmed }
        if let firstNewline = trimmed.firstIndex(of: "\n") {
            trimmed = String(trimmed[trimmed.index(after: firstNewline)...])
        }
        if trimmed.hasSuffix("```") {
            trimmed = String(trimmed.dropLast(3))
        }
        return trimmed.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func downscaledJPEG(from data: Data) -> Data {
        guard let image = UIImage(data: data) else { return data }
        let maxDimension: CGFloat = 1400
        let longestSide = max(image.size.width, image.size.height)
        guard longestSide > maxDimension else {
            return image.jpegData(compressionQuality: 0.6) ?? data
        }
        let scale = maxDimension / longestSide
        let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        let resized = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
        return resized.jpegData(compressionQuality: 0.6) ?? data
    }
}
