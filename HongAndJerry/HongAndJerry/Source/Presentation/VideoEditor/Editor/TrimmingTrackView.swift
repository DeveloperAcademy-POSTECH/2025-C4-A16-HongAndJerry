//
//  TrimmingTrackView.swift
//  HongAndJerry
//
//  Created by Rama on 12/20/25.
//

import AVFoundation
import SwiftUI
import UIKit

import SnapKit
import Then


enum TrimmingConstants {
    static let confirmButtonWidth: CGFloat = 45
    static let trackHeight: CGFloat = 60
    static let handleWidth: CGFloat = 20
    static let borderWidth: CGFloat = 4
    static let cornerRadius: CGFloat = 8
    static let minTrimDuration: Double = 0.5
    static let snapThreshold: Double = 0.5
    static let handleColor = UIColor.accent
}

final class TrimmingTrackView: UIView {
    var onTrimStarted: ((HandlesView.HandleType) -> Void)?
    var onTrimChanged: ((Double, Double, HandlesView.HandleType) -> Void)?
    var onTrimEnded: (() -> Void)?
    var onTrimConfirmed: (() -> Void)?
    private var segment: VideoSegment?
    private var totalDuration: Double = 1.0
    private var snapEndTimes: [Double] = []
    private var lastSnappedTime: Double?
    private let hapticFeedback = UIImpactFeedbackGenerator(style: .medium)
    private var trimStartRatio: CGFloat = 0.0
    private var trimEndRatio: CGFloat = 1.0
    private var dragStartRatio: CGFloat = 0.0
    private var dragStartX: CGFloat = 0.0
    private let confirmButton = UIButton(type: .system)
    private let thumbnailContainerView = UIView()
    private let containerBackgroundView = UIView()
    private let thumbnailStackView = UIStackView()
    private let leftMaskView = UIView()
    private let rightMaskView = UIView()
    private let trimFrameView = UIView()
    private let leftHandleView = HandlesView(type: .left)
    private let rightHandleView = HandlesView(type: .right)
    private let topBorderView = UIView()
    private let bottomBorderView = UIView()
    private var minTrimRatio: CGFloat {
        CGFloat(TrimmingConstants.minTrimDuration / totalDuration)
    }
    override init(frame: CGRect) {
        super.init(frame: frame)

        setStyle()
        setUI()
        setLayout()
        setGestures()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)

        setStyle()
        setUI()
        setLayout()
        setGestures()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateTrimFrame()
    }
    private func setStyle() {
        confirmButton.do {
            $0.setImage(UIImage(systemName: "checkmark"), for: .normal)
            $0.tintColor = .white
            $0.addTarget(self, action: #selector(confirmTapped), for: .touchUpInside)
        }

        thumbnailContainerView.do {
            $0.clipsToBounds = true
        }
        containerBackgroundView.do {
            $0.backgroundColor = .inactive
            $0.clipsToBounds = true
            $0.layer.cornerRadius = 8.0
        }

        thumbnailStackView.do {
            $0.axis = .horizontal
            $0.distribution = .fillEqually
            $0.spacing = 0
        }
        trimFrameView.do {
            $0.backgroundColor = .clear
        }

        leftMaskView.do {
            $0.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        }

        rightMaskView.do {
            $0.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        }

        topBorderView.do {
            $0.backgroundColor = TrimmingConstants.handleColor
        }

        bottomBorderView.do {
            $0.backgroundColor = TrimmingConstants.handleColor
        }
    }
    private func setUI() {
        addSubview(confirmButton)
        addSubview(containerBackgroundView)
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
    private func setLayout() {
        confirmButton.snp.makeConstraints {
            $0.leading.top.bottom.equalToSuperview()
            $0.width.equalTo(TrimmingConstants.confirmButtonWidth)
        }
        containerBackgroundView.snp.makeConstraints {
            $0.leading.equalTo(confirmButton.snp.trailing)
            $0.trailing.equalToSuperview()
            $0.top.bottom.equalToSuperview()
        }

        thumbnailContainerView.snp.makeConstraints {
            $0.leading.equalTo(confirmButton.snp.trailing).offset(TrimmingConstants.handleWidth)
            $0.trailing.equalToSuperview().offset(-TrimmingConstants.handleWidth)
            $0.top.equalToSuperview().offset(TrimmingConstants.borderWidth)
            $0.bottom.equalToSuperview().offset(-TrimmingConstants.borderWidth)
        }

        thumbnailStackView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        updateTrimFrame()
    }
    private func setGestures() {
        let leftDrag = UIPanGestureRecognizer(
            target: self,
            action: #selector(handleLeftDrag(_:))
        )
        leftHandleView.addGestureRecognizer(leftDrag)

        let rightDrag = UIPanGestureRecognizer(
            target: self,
            action: #selector(handleRightDrag(_:))
        )
        rightHandleView.addGestureRecognizer(rightDrag)
    }
    private func updateTrimFrame() {
        let containerWidth = thumbnailContainerView.bounds.width
        let startX = TrimmingConstants.confirmButtonWidth + trimStartRatio * containerWidth
        let endX = TrimmingConstants.confirmButtonWidth + trimEndRatio * containerWidth + TrimmingConstants.handleWidth * 2
        let frameWidth = endX - startX

        trimFrameView.snp.remakeConstraints {
            $0.leading.equalToSuperview().offset(startX)
            $0.width.equalTo(frameWidth)
            $0.top.bottom.equalToSuperview()
        }

        leftHandleView.snp.remakeConstraints {
            $0.leading.top.bottom.equalToSuperview()
            $0.width.equalTo(TrimmingConstants.handleWidth)
        }

        rightHandleView.snp.remakeConstraints {
            $0.trailing.top.bottom.equalToSuperview()
            $0.width.equalTo(TrimmingConstants.handleWidth)
        }


        topBorderView.snp.remakeConstraints {
            $0.leading.equalTo(leftHandleView.snp.trailing)
            $0.trailing.equalTo(rightHandleView.snp.leading)
            $0.top.equalToSuperview()
            $0.height.equalTo(TrimmingConstants.borderWidth)
        }

        bottomBorderView.snp.remakeConstraints {
            $0.leading.equalTo(leftHandleView.snp.trailing)
            $0.trailing.equalTo(rightHandleView.snp.leading)
            $0.bottom.equalToSuperview()
            $0.height.equalTo(TrimmingConstants.borderWidth)
        }

        leftMaskView.snp.remakeConstraints {
            $0.leading.top.bottom.equalToSuperview()
            $0.width.equalTo(trimStartRatio * containerWidth)
        }

        rightMaskView.snp.remakeConstraints {
            $0.trailing.top.bottom.equalToSuperview()
            $0.width.equalTo((1.0 - trimEndRatio) * containerWidth)
        }

        layoutIfNeeded()
    }
}

extension TrimmingTrackView {
    @objc private func handleLeftDrag(_ gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .began:
            onTrimStarted?(.left)
            dragStartRatio = trimStartRatio
            dragStartX = gesture.location(in: self).x

        case .changed:
            let currentX = gesture.location(in: self).x
            let deltaX = currentX - dragStartX
            let containerWidth = thumbnailContainerView.bounds.width
            let deltaRatio = deltaX / containerWidth * 0.9

            var newRatio = dragStartRatio + deltaRatio
            newRatio = max(0, min(newRatio, trimEndRatio - minTrimRatio))

            trimStartRatio = newRatio
            updateTrimFrame()

            let startTime = Double(trimStartRatio) * totalDuration
            let endTime = Double(trimEndRatio) * totalDuration
            onTrimChanged?(startTime, endTime, .left)

        case .ended, .cancelled:
            lastSnappedTime = nil
            onTrimEnded?()

        default:
            break
        }
    }

    @objc private func handleRightDrag(_ gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .began:
            onTrimStarted?(.right)
            dragStartRatio = trimEndRatio
            dragStartX = gesture.location(in: self).x

        case .changed:
            let currentX = gesture.location(in: self).x
            let deltaX = currentX - dragStartX
            let containerWidth = thumbnailContainerView.bounds.width
            let deltaRatio = deltaX / containerWidth * 0.9

            var newRatio = dragStartRatio + deltaRatio
            newRatio = max(trimStartRatio + minTrimRatio, min(newRatio, 1.0))

            let startTime = Double(trimStartRatio) * totalDuration
            let endTime = Double(newRatio) * totalDuration
            let trimmedDuration = endTime - startTime
            let snappedTrimmedDuration = applySnap(to: trimmedDuration)
            let snappedEndTime = startTime + snappedTrimmedDuration

            trimEndRatio = CGFloat(snappedEndTime / totalDuration)
            updateTrimFrame()

            onTrimChanged?(startTime, snappedEndTime, .right)

        case .ended, .cancelled:
            lastSnappedTime = nil
            onTrimEnded?()

        default:
            break
        }
    }
    @objc private func confirmTapped() {
        onTrimConfirmed?()
    }
}

extension TrimmingTrackView {
    func configure(with segment: VideoSegment, updateRatios: Bool = true) {
        self.segment = segment
        self.totalDuration = segment.source.duration.seconds

        if updateRatios {
            trimStartRatio = CGFloat(segment.startTime.seconds / totalDuration)
            trimEndRatio = CGFloat(segment.endTime.seconds / totalDuration)
        }

        updateThumbnails(segment.thumbnails)
        setNeedsLayout()
    }

    func shakeConfirmButton() {
        let animation = CAKeyframeAnimation(keyPath: "transform.translation.y")
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        animation.duration = 0.4
        animation.values = [0, -12, 0]
        animation.keyTimes = [0, 0.5, 1.0]

        confirmButton.layer.add(animation, forKey: "bounce")
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

    func updateSnapEndTimes(_ times: [Double]) {
        self.snapEndTimes = times
    }

    private func applySnap(to endTime: Double) -> Double {
        for snapTime in snapEndTimes {
            if abs(endTime - snapTime) <= TrimmingConstants.snapThreshold {
                if lastSnappedTime != snapTime {
                    lastSnappedTime = snapTime
                    hapticFeedback.impactOccurred()
                }
                return snapTime
            }
        }
        lastSnappedTime = nil
        return endTime
    }
}

struct TrimmingTrackViewRepresentable: UIViewRepresentable {
    let segment: VideoSegment?
    let snapEndTimes: [Double]
    let shouldShake: Bool
    let isTrimming: Bool
    let onTrimStarted: (HandlesView.HandleType) -> Void
    let onTrimChanged: (Double, Double, HandlesView.HandleType) -> Void
    let onTrimEnded: () -> Void
    let onTrimConfirmed: () -> Void

    func makeUIView(context: Context) -> TrimmingTrackView {
        let view = TrimmingTrackView()
        view.onTrimStarted = onTrimStarted
        view.onTrimChanged = onTrimChanged
        view.onTrimEnded = onTrimEnded
        view.onTrimConfirmed = onTrimConfirmed
        return view
    }

    func updateUIView(_ uiView: TrimmingTrackView, context: Context) {
        uiView.updateSnapEndTimes(snapEndTimes)
        if let segment = segment {
            uiView.configure(with: segment, updateRatios: !isTrimming)
        }

        if shouldShake {
            uiView.shakeConfirmButton()
        }
    }
}
