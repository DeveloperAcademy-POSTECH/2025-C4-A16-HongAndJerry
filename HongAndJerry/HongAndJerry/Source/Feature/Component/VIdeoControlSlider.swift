import SwiftUI
import UIKit

struct VideoControlSlider: UIViewRepresentable {
  @Binding var value: Double
  let range: ClosedRange<Double>
  let onEditingChanged: (Bool) -> Void

  func makeUIView(context: Context) -> UISlider {
    let slider = UISlider()
    
    slider.minimumValue = Float(range.lowerBound)
    slider.maximumValue = Float(range.upperBound)
    slider.value = Float(value)

    slider.addTarget(
      context.coordinator,
      action: #selector(Coordinator.valueChanged(_:)),
      for: .valueChanged
    )
    slider.addTarget(
      context.coordinator,
      action: #selector(Coordinator.touchDown(_:)),
      for: .touchDown
    )
    slider.addTarget(
      context.coordinator,
      action: #selector(Coordinator.touchUpInside(_:)),
      for: .touchUpInside
    )
    slider.addTarget(
      context.coordinator,
      action: #selector(Coordinator.touchUpOutside(_:)),
      for: .touchUpOutside
    )
    slider.addTarget(
      context.coordinator,
      action: #selector(Coordinator.touchCancel(_:)),
      for: .touchCancel
    )

    return slider
  }

  func updateUIView(_ uiView: UISlider, context: Context) {
    uiView.minimumValue = Float(range.lowerBound)
    uiView.maximumValue = Float(range.upperBound)

    if !context.coordinator.isDragging {
      uiView.value = Float(value)
    }
  }

  func makeCoordinator() -> Coordinator {
    Coordinator(value: $value, onEditingChanged: onEditingChanged)
  }

  class Coordinator: NSObject {
    var value: Binding<Double>
    let onEditingChanged: (Bool) -> Void
    var isDragging = false

    init(value: Binding<Double>, onEditingChanged: @escaping (Bool) -> Void) {
      self.value = value
      self.onEditingChanged = onEditingChanged
    }

    @objc func touchDown(_ sender: UISlider) {
      isDragging = true
      onEditingChanged(true)
    }

    @objc func valueChanged(_ sender: UISlider) {
      value.wrappedValue = Double(sender.value)
    }

    @objc func touchUpInside(_ sender: UISlider) {
      isDragging = false
      onEditingChanged(false)
    }

    @objc func touchUpOutside(_ sender: UISlider) {
      isDragging = false
      onEditingChanged(false)
    }

    @objc func touchCancel(_ sender: UISlider) {
      isDragging = false
      onEditingChanged(false)
    }
  }
}
