//
//  TrimmingTrackView.swift
//  HongAndJerry
//
//  Created by Rama on 12/20/25.
//

//
//  TrimmingTrackView.swift
//  HongAndJerry
//

import AVFoundation
import SwiftUI
import UIKit

// MARK: - Constants
enum TrimmingConstants {
    static let confirmButtonWidth: CGFloat = 40
    static let trackHeight: CGFloat = 60
    static let handleWidth: CGFloat = 20
    static let borderWidth: CGFloat = 4
    static let cornerRadius: CGFloat = 8
    static let minTrimDuration: Double = 0.5
    static let handleColor = UIColor(red: 1.0, green: 0.8, blue: 0.2, alpha: 1.0)
}

// MARK: - TrimmingTrackView
final class TrimmingTrackView: UIView {
    
    // MARK: - Callbacks
    var onTrimChanged: ((Double, Double) -> Void)?
    var onTrimConfirmed: (() -> Void)?
    
    // MARK: - Data
    private var segment: VideoSegment?
    private var totalDuration: Double = 1.0
    
    // MARK: - State
    private var trimStartRatio: CGFloat = 0.0
    private var trimEndRatio: CGFloat = 1.0
    
    // MARK: - Drag State
    private var dragStartRatio: CGFloat = 0.0
    private var dragStartX: CGFloat = 0.0
    
    // MARK: - UI Components
    private let confirmButton = UIButton(type: .system)
    private let thumbnailContainerView = UIView()
    private let thumbnailStackView = UIStackView()
    private let leftMaskView = UIView()
    private let rightMaskView = UIView()
    private let trimFrameView = UIView()
    private let leftHandleView = HandleView(type: .left)
    private let rightHandleView = HandleView(type: .right)
    private let topBorderView = UIView()
    private let bottomBorderView = UIView()
    
    // MARK: - Computed Properties
    private var thumbnailWidth: CGFloat {
        bounds.width - TrimmingConstants.confirmButtonWidth - TrimmingConstants.handleWidth * 2
    }
    
    private var minTrimRatio: CGFloat {
        CGFloat(TrimmingConstants.minTrimDuration / totalDuration)
    }
    
    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setStyle()
        setUI()
        setGestures()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        setStyle()
        setUI()
        setGestures()
    }
    
    // MARK: - Layout
    override func layoutSubviews() {
        super.layoutSubviews()
        setLayout()
    }
    
    // MARK: - Setup Style
    private func setStyle() {
        backgroundColor = .black
        
        confirmButton.setImage(UIImage(systemName: "checkmark"), for: .normal)
        confirmButton.tintColor = .white
        confirmButton.addTarget(self, action: #selector(confirmTapped), for: .touchUpInside)
        
        thumbnailContainerView.clipsToBounds = true
        
        thumbnailStackView.axis = .horizontal
        thumbnailStackView.distribution = .fillEqually
        thumbnailStackView.spacing = 0
        
        leftMaskView.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        rightMaskView.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        
        trimFrameView.backgroundColor = .clear
        
        topBorderView.backgroundColor = TrimmingConstants.handleColor
        bottomBorderView.backgroundColor = TrimmingConstants.handleColor
    }
    
    // MARK: - Setup UI
    private func setUI() {
        addSubview(confirmButton)
        addSubview(thumbnailContainerView)
        addSubview(trimFrameView)
        
        thumbnailContainerView.addSubview(thumbnailStackView)
        thumbnailContainerView.addSubview(leftMaskView)
        thumbnailContainerView.addSubview(rightMaskView)
        
        trimFrameView.addSubview(leftHandleView)
        trimFrameView.addSubview(rightHandleView)
        trimFrameView.addSubview(topBorderView)
        trimFrameView.addSubview(bottomBorderView)
    }
    
    // MARK: - Setup Layout
    private func setLayout() {
        let height = bounds.height
        
        // Confirm Button
        confirmButton.frame = CGRect(
            x: 0,
            y: 0,
            width: TrimmingConstants.confirmButtonWidth,
            height: height
        )
        
        // Thumbnail Container
        thumbnailContainerView.frame = CGRect(
            x: TrimmingConstants.confirmButtonWidth + TrimmingConstants.handleWidth,
            y: TrimmingConstants.borderWidth,
            width: thumbnailWidth,
            height: height - TrimmingConstants.borderWidth * 2
        )
        
        // Thumbnail Stack
        thumbnailStackView.frame = thumbnailContainerView.bounds
        
        // Trim Frame
        updateTrimFrame()
    }
    
    // MARK: - Setup Gestures
    private func setGestures() {
        let leftPan = UIPanGestureRecognizer(
            target: self,
            action: #selector(handleLeftPan(_:))
        )
        leftHandleView.addGestureRecognizer(leftPan)
        
        let rightPan = UIPanGestureRecognizer(
            target: self,
            action: #selector(handleRightPan(_:))
        )
        rightHandleView.addGestureRecognizer(rightPan)
    }
    
    // MARK: - Update Trim Frame
    private func updateTrimFrame() {
        let startX = TrimmingConstants.confirmButtonWidth + trimStartRatio * thumbnailWidth
        let endX = TrimmingConstants.confirmButtonWidth + trimEndRatio * thumbnailWidth + TrimmingConstants.handleWidth * 2
        let frameWidth = endX - startX
        let height = bounds.height
        
        // Trim Frame
        trimFrameView.frame = CGRect(
            x: startX,
            y: 0,
            width: frameWidth,
            height: height
        )
        
        // Left Handle
        leftHandleView.frame = CGRect(
            x: 0,
            y: 0,
            width: TrimmingConstants.handleWidth,
            height: height
        )
        
        // Right Handle
        rightHandleView.frame = CGRect(
            x: frameWidth - TrimmingConstants.handleWidth,
            y: 0,
            width: TrimmingConstants.handleWidth,
            height: height
        )
        
        // Borders
        let borderX = TrimmingConstants.handleWidth
        let innerWidth = frameWidth - TrimmingConstants.handleWidth * 2
        
        topBorderView.frame = CGRect(
            x: borderX,
            y: 0,
            width: innerWidth,
            height: TrimmingConstants.borderWidth
        )
        
        bottomBorderView.frame = CGRect(
            x: borderX,
            y: height - TrimmingConstants.borderWidth,
            width: innerWidth,
            height: TrimmingConstants.borderWidth
        )
        
        // Masks
        let maskHeight = thumbnailContainerView.bounds.height
        
        leftMaskView.frame = CGRect(
            x: 0,
            y: 0,
            width: trimStartRatio * thumbnailWidth,
            height: maskHeight
        )
        
        rightMaskView.frame = CGRect(
            x: trimEndRatio * thumbnailWidth,
            y: 0,
            width: (1.0 - trimEndRatio) * thumbnailWidth,
            height: maskHeight
        )
    }
}

// MARK: - Gesture Handlers
extension TrimmingTrackView {
    
    @objc private func handleLeftPan(_ gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .began:
            dragStartRatio = trimStartRatio
            dragStartX = gesture.location(in: self).x
            
        case .changed:
            let currentX = gesture.location(in: self).x
            let deltaX = currentX - dragStartX
            let deltaRatio = deltaX / thumbnailWidth
            
            var newRatio = dragStartRatio + deltaRatio
            newRatio = max(0, min(newRatio, trimEndRatio - minTrimRatio))
            
            trimStartRatio = newRatio
            updateTrimFrame()
            
            let startTime = Double(trimStartRatio) * totalDuration
            let endTime = Double(trimEndRatio) * totalDuration
            onTrimChanged?(startTime, endTime)
            
        case .ended, .cancelled:
            break
            
        default:
            break
        }
    }
    
    @objc private func handleRightPan(_ gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .began:
            dragStartRatio = trimEndRatio
            dragStartX = gesture.location(in: self).x
            
        case .changed:
            let currentX = gesture.location(in: self).x
            let deltaX = currentX - dragStartX
            let deltaRatio = deltaX / thumbnailWidth
            
            var newRatio = dragStartRatio + deltaRatio
            newRatio = max(trimStartRatio + minTrimRatio, min(newRatio, 1.0))
            
            trimEndRatio = newRatio
            updateTrimFrame()
            
            let startTime = Double(trimStartRatio) * totalDuration
            let endTime = Double(trimEndRatio) * totalDuration
            onTrimChanged?(startTime, endTime)
            
        case .ended, .cancelled:
            break
            
        default:
            break
        }
    }
    
    @objc private func confirmTapped() {
        onTrimConfirmed?()
    }
}

// MARK: - Public Methods
extension TrimmingTrackView {
    
    func configure(with segment: VideoSegment) {
        self.segment = segment
        self.totalDuration = segment.source.duration.seconds
        
        trimStartRatio = CGFloat(segment.startTime.seconds / totalDuration)
        trimEndRatio = CGFloat(segment.endTime.seconds / totalDuration)
        
        updateThumbnails(segment.thumbnails)
        setNeedsLayout()
    }
    
    private func updateThumbnails(_ thumbnails: [UIImage]) {
        thumbnailStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        for image in thumbnails {
            let imageView = UIImageView(image: image)
            imageView.contentMode = .scaleAspectFill
            imageView.clipsToBounds = true
            thumbnailStackView.addArrangedSubview(imageView)
        }
    }
}

// MARK: - HandleView
final class HandleView: UIView {
    
    // MARK: - Types
    enum HandleType {
        case left
        case right
    }
    
    // MARK: - Properties
    private let type: HandleType
    private let chevronImageView = UIImageView()
    
    // MARK: - Init
    init(type: HandleType) {
        self.type = type
        super.init(frame: .zero)
        
        setStyle()
        setUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Layout
    override func layoutSubviews() {
        super.layoutSubviews()
        setLayout()
    }
    
    // MARK: - Setup Style
    private func setStyle() {
        backgroundColor = TrimmingConstants.handleColor
        isUserInteractionEnabled = true
        
        layer.maskedCorners = type == .left
            ? [.layerMinXMinYCorner, .layerMinXMaxYCorner]
            : [.layerMaxXMinYCorner, .layerMaxXMaxYCorner]
        layer.cornerRadius = TrimmingConstants.cornerRadius
        
        let imageName = type == .left ? "chevron.left" : "chevron.right"
        chevronImageView.image = UIImage(systemName: imageName)?
            .withConfiguration(UIImage.SymbolConfiguration(weight: .black))
        chevronImageView.tintColor = .black
        chevronImageView.contentMode = .scaleAspectFit
    }
    
    // MARK: - Setup UI
    private func setUI() {
        addSubview(chevronImageView)
    }
    
    // MARK: - Setup Layout
    private func setLayout() {
        let chevronSize: CGFloat = 12
        chevronImageView.frame = CGRect(
            x: (bounds.width - chevronSize) / 2,
            y: (bounds.height - chevronSize) / 2,
            width: chevronSize,
            height: chevronSize
        )
    }
}

// MARK: - UIViewRepresentable Wrapper
struct TrimmingTrackViewRepresentable: UIViewRepresentable {
    
    let segment: VideoSegment?
    let onTrimChanged: (Double, Double) -> Void
    let onTrimConfirmed: () -> Void
    
    func makeUIView(context: Context) -> TrimmingTrackView {
        let view = TrimmingTrackView()
        view.onTrimChanged = onTrimChanged
        view.onTrimConfirmed = onTrimConfirmed
        return view
    }
    
    func updateUIView(_ uiView: TrimmingTrackView, context: Context) {
        if let segment = segment {
            uiView.configure(with: segment)
        }
    }
}
