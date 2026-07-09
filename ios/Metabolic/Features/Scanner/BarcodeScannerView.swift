import SwiftUI
import VisionKit

/// Live barcode scanner backed by VisionKit's `DataScannerViewController`. Fires `onScan`
/// once per newly-recognized payload, suppressing repeats of the same code within 2 seconds.
struct BarcodeScannerView: UIViewControllerRepresentable {
    var onScan: (String) -> Void

    init(onScan: @escaping (String) -> Void) {
        self.onScan = onScan
    }

    static var isSupported: Bool {
        DataScannerViewController.isSupported && DataScannerViewController.isAvailable
    }

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let controller = DataScannerViewController(
            recognizedDataTypes: [.barcode(symbologies: [.ean13, .ean8, .upce, .code128])],
            qualityLevel: .fast,
            recognizesMultipleItems: false,
            isHighFrameRateTrackingEnabled: false,
            isPinchToZoomEnabled: true,
            isGuidanceEnabled: false,
            isHighlightingEnabled: true
        )
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ controller: DataScannerViewController, context: Context) {
        if !controller.isScanning {
            try? controller.startScanning()
        }
    }

    static func dismantleUIViewController(_ controller: DataScannerViewController, coordinator: Coordinator) {
        controller.stopScanning()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onScan: onScan)
    }

    final class Coordinator: NSObject, DataScannerViewControllerDelegate {
        private let onScan: (String) -> Void
        private var lastPayload: String?
        private var lastFireDate: Date = .distantPast

        init(onScan: @escaping (String) -> Void) {
            self.onScan = onScan
        }

        func dataScanner(_ dataScanner: DataScannerViewController, didAdd addedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            for item in addedItems {
                handle(item)
            }
        }

        func dataScanner(_ dataScanner: DataScannerViewController, didTapOn item: RecognizedItem) {
            handle(item)
        }

        private func handle(_ item: RecognizedItem) {
            guard case .barcode(let barcode) = item, let payload = barcode.payloadStringValue else { return }
            let now = Date()
            if payload == lastPayload, now.timeIntervalSince(lastFireDate) < 2 {
                return
            }
            lastPayload = payload
            lastFireDate = now
            onScan(payload)
        }
    }
}

#Preview {
    Group {
        if BarcodeScannerView.isSupported {
            BarcodeScannerView(onScan: { _ in })
        } else {
            MTEmptyState(
                symbol: "barcode.viewfinder",
                title: "Scanner Unavailable",
                message: "Live barcode scanning isn't supported in this environment."
            )
        }
    }
}
