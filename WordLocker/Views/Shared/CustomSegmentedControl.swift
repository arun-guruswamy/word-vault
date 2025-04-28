import SwiftUI
import UIKit // Required for UIViewRepresentable and UIImage

// Custom Segmented Control for consistent styling
struct CustomSegmentedControl: UIViewRepresentable {
    @Binding var selection: Int
    let items: [String]
    
    func makeUIView(context: Context) -> UISegmentedControl {
        let control = UISegmentedControl(items: items)
        control.selectedSegmentIndex = selection
        control.addTarget(context.coordinator, action: #selector(Coordinator.valueChanged(_:)), for: .valueChanged)
        
        // Customize appearance to match HomeView/StatsView
        control.backgroundColor = .clear
        control.setTitleTextAttributes([
            .font: UIFont(name: "Marker Felt", size: 16) ?? .systemFont(ofSize: 16),
            .foregroundColor: UIColor.black
        ], for: .normal)
        
        control.setTitleTextAttributes([
            .font: UIFont(name: "Marker Felt", size: 16) ?? .systemFont(ofSize: 16),
            .foregroundColor: UIColor.black
        ], for: .selected)
        
        // Remove dividers and set clear background for normal state if desired
        // control.setBackgroundImage(UIImage(color: .clear), for: .normal, barMetrics: .default)
        // control.setDividerImage(UIImage(), forLeftSegmentState: .normal, rightSegmentState: .normal, barMetrics: .default)

        return control
    }
    
    func updateUIView(_ uiView: UISegmentedControl, context: Context) {
        uiView.selectedSegmentIndex = selection
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject {
        var parent: CustomSegmentedControl
        
        init(_ parent: CustomSegmentedControl) {
            self.parent = parent
        }
        
        @objc func valueChanged(_ sender: UISegmentedControl) {
            parent.selection = sender.selectedSegmentIndex
        }
    }
}

// Helper extension to create UIImage from Color (if needed elsewhere or for segment background)
// Keep it here for now as it was part of the original implementation context
extension UIImage {
    convenience init?(color: UIColor, size: CGSize = CGSize(width: 1, height: 1)) {
        let rect = CGRect(origin: .zero, size: size)
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0.0)
        color.setFill()
        UIRectFill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        guard let cgImage = image?.cgImage else { return nil }
        self.init(cgImage: cgImage)
    }
}
