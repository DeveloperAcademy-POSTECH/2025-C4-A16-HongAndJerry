//
//  CropBox.swift
//  HongAndJerry
//
//  Created by Soop on 7/21/25.
//

import SwiftUI

struct CropBox: View {
    @Binding public var rect: CGRect    // 부모에게 크롭할 영역의 좌표와 영역 알림
    public let minSize: CGSize          // CropBox의 최소 사이즈 설정
    //    public let maxSize: CGSize
    //    public let initialPosition: CGPoint // CropBox의 시작 지점
    
    @State private var initialRect: CGRect? = nil
    @State private var frameSize: CGSize = .init(width: 1, height: 1)
    @State private var draggedCorner: UIRectCorner? = nil
    
    public init(
        rect: Binding<CGRect>,
        minSize: CGSize = .init(width: 10, height: 10)
    ) {
        self._rect = rect
        self.minSize = minSize
    }
    
    private var rectDrag: some Gesture {
        DragGesture()
            .onChanged { gesture in
                if initialRect == nil {
                    initialRect = rect
                }

                self.rect = drag(
                    initialRect: initialRect!,
                    frameSize: frameSize,
                    translation: gesture.translation
                )
            }
            .onEnded { gesture in
                initialRect = nil
            }
    }
    
    public var body: some View {
        ZStack(alignment: .topLeading) {
            blur
            box
        }
        .background {
            GeometryReader { geometry in
                Color.clear
                    .onAppear { self.frameSize = geometry.size }
                    .onChange(of: geometry.size) { self.frameSize = $0 }
            }
        }
    }
    
    private var blur: some View {
        Color.black.opacity(0.5)
            .overlay(alignment: .topLeading) {
                Color.white
                    .frame(width: rect.width - 1, height: rect.height - 1)
                    .offset(x: rect.origin.x, y: rect.origin.y)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .drawingGroup()
            .blendMode(.multiply)
    }
    
    private var box: some View {
        ZStack {
            grid
        }
        .border(Color.accent, width: 1)
        .background(Color.white.opacity(0.001))
        .frame(width: rect.width, height: rect.height)
        .offset(x: rect.origin.x, y: rect.origin.y)
        .gesture(rectDrag)
    }
    
    private var pins: some View {
        VStack {
            HStack {
                pin(corner: .topLeft)
                Spacer()
                pin(corner: .topRight)
            }
            Spacer()
            HStack {
                pin(corner: .bottomLeft)
                Spacer()
                pin(corner: .bottomRight)
            }
        }
    }
    
    private func pin(corner: UIRectCorner) -> some View {
        var offX = 1.0
        var offY = 1.0

        switch corner {
        case .topLeft:      offX = -1;  offY = -1
        case .topRight:                 offY = -1
        case .bottomLeft:   offX = -1
        case .bottomRight: break
        default: break
        }

        return Circle()
            .fill(Color.accent)
            .frame(width: 16, height: 16)
            .offset(x: offX * 8, y: offY * 8)
    }
    
    private var grid: some View {
        ZStack {
            HStack {
                Spacer()
                Rectangle()
                    .frame(width: 1)
                    .frame(maxHeight: .infinity)
                Spacer()
                Rectangle()
                    .frame(width: 1)
                    .frame(maxHeight: .infinity)
                Spacer()
            }
            VStack {
                Spacer()
                Rectangle()
                    .frame(height: 1)
                    .frame(maxWidth: .infinity)
                Spacer()
                Rectangle()
                    .frame(height: 1)
                    .frame(maxWidth: .infinity)
                Spacer()
            }
        }
        .foregroundColor(.gray)
    }
    
    /// 터치한 영역이 어떤 모서리인지 판단
    /// distance를 조절하여 모서리 터치 영역 조절 가능
    private func closestCorner(point: CGPoint, rect: CGRect, distance: CGFloat = 16) -> UIRectCorner? {
        let ldX = abs(rect.minX.distance(to: point.x)) < distance
        let rdX = abs(rect.maxX.distance(to: point.x)) < distance
        let tdY = abs(rect.minY.distance(to: point.y)) < distance
        let bdY = abs(rect.maxY.distance(to: point.y)) < distance
        
        guard (ldX || rdX) && (tdY || bdY) else { return nil }
        
        return if ldX && tdY { .topLeft }
        else if rdX && tdY { .topRight }
        else if ldX && bdY { .bottomLeft }
        else if rdX && bdY { .bottomRight }
        else { nil }
    }
    
    /// 사이즈 조절
    private func dragResize(initialRect: CGRect, draggedCorner: UIRectCorner, frameSize: CGSize, translation: CGSize) -> CGRect {
        var offX = 1.0
        var offY = 1.0
        
        switch draggedCorner {
        case .topLeft:      offX = -1;  offY = -1
        case .topRight:                 offY = -1
        case .bottomLeft:   offX = -1
        case .bottomRight: break
        default: break
        }
        
        let idealWidth = initialRect.size.width + offX * translation.width
        var newWidth = max(idealWidth, minSize.width)
        
        let maxHeight = frameSize.height - initialRect.minY
        let idealHeight = initialRect.size.height + offY * translation.height
        var newHeight = max(idealHeight, minSize.height)
        
        var newX = initialRect.minX
        var newY = initialRect.minY
        
        if offX < 0 {
            let widthChange = newWidth - initialRect.width
            newX = max(newX - widthChange, 0)
            newWidth = min(newWidth, initialRect.maxX)
        } else {
            newWidth = min(newWidth, frameSize.width - initialRect.minX)
        }
        
        if offY < 0 {
            let heightChange = newHeight - initialRect.height
            newY = max(newY - heightChange, 0)
            newHeight = min(initialRect.maxY, newHeight)
        } else {
            newHeight = min(newHeight, maxHeight)
        }
        
        return .init(origin: .init(x: newX, y: newY), size: .init(width: newWidth, height: newHeight))
    }
    
    private func drag(initialRect: CGRect, frameSize: CGSize, translation: CGSize) -> CGRect {
        let maxX = frameSize.width - initialRect.width
        let newX = min(max(initialRect.origin.x + translation.width, 0), maxX)
        let maxY = frameSize.height - initialRect.height
        let newY = min(max(initialRect.origin.y + translation.height, 0), maxY)
        
        return .init(origin: .init(x: newX, y: newY), size: initialRect.size)
    }
}
//
//#Preview {
//    CropBox()
//}
