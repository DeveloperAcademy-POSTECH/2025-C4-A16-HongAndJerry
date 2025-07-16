//
//  RetryVideoSelectView.swift
//  HongAndJerry
//
//  Created by Soop on 7/16/25.
//

import SwiftUI
import PhotosUI

struct RetryVideoSelectView: View {
  @StateObject var viewModel = RetryVideoSelectViewModel()
  
  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      
      // 선택된 비디오 썸네일 리스트
      ScrollView(.horizontal, showsIndicators: false) {
        HStack {
          ForEach(viewModel.selectedVideos) { video in
            Image(uiImage: video.thumbnail)
              .resizable()
              .frame(width: 100, height: 100)
              .clipShape(RoundedRectangle(cornerRadius: 8))
              .overlay(
                RoundedRectangle(cornerRadius: 8)
                  .stroke(Color.blue, lineWidth: 2)
              )
          }
        }
        .padding(.horizontal)
      }
    
      
      // 비디오 피커
      PhotosPicker(

        selection: Binding(
          get: { nil },
          set: { item in
            if let item { viewModel.handleNewItem(item)
              print("지원되는 타입: \(item.supportedContentTypes)")}
          }
        ),
      
        
        
        matching: .videos
      
        
        
      ) {
        Text("비디오 선택하기")
          .padding()
          .background(Color.blue)
          .foregroundColor(.white)
          .cornerRadius(8)
      }
      .photosPickerStyle(.inline)
      .photosPickerAccessoryVisibility(.hidden)
      
      Spacer()
    }
  }
}

#Preview {
  RetryVideoSelectView()
}



