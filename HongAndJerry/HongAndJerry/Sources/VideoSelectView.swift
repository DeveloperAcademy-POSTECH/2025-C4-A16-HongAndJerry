//
//  VideoSelectView.swift
//  HongAndJerry
//
//  Created by Soop on 7/10/25.
//

import SwiftUI
import PhotosUI

struct VideoSelectView: View {
  
  @StateObject var viewModel : VideoSelectViewModel = VideoSelectViewModel()
var body: some View {
    VStack {
      
      imageList()
      
      PhotosPicker(
        selection: $viewModel.selection,
        maxSelectionCount: 3,
        selectionBehavior: .continuous,
        matching: .videos
      ) {
        Text("Select Video")
      }
      .photosPickerStyle(.inline)
      .photosPickerAccessoryVisibility(.hidden)
    }
    .onAppear {
      NotificationCenter.default.addObserver(forName: .didGenerateThumbnail, object: nil, queue: .main) { notification in
        guard
          let id = notification.userInfo?["id"] as? String,
          let image = notification.userInfo?["image"] as? UIImage
        else { return }
        viewModel.cacheThumbnail(image, for: id)
      }
    }
  }
  
  func imageList() -> some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack {
        ForEach(viewModel.attachments) { attachment in
          ImageAttachmentView(videoAttachment: attachment)
//          attachment.thumbnail
        }
      }

    }
  }
}

struct ImageAttachmentView: View {
    
    /// An image that a person selects in the Photos picker.
  @ObservedObject var videoAttachment: VideoAttachment
    
    /// A container view for the row.
    var body: some View {
        HStack {
            
          
            // Display the image that the text describes.
          switch videoAttachment.videoStatus {
            case .loading:
              Image("progress.indicator")
            case .finished(let image):
            Image(uiImage: image)
              .resizable().aspectRatio(contentMode: .fit).frame(height: 100)
            case .failed:
                Image(systemName: "exclamationmark.triangle.fill")
            default:
                ProgressView()
            }
        }.task {
            // Asynchronously display the photo.
          
          // 이미 썸네일이 있거나 로딩 중이면 실행하지 않음
            if videoAttachment.videoStatus == nil {
                await videoAttachment.loadThumbnail()
            }
        }
    }
}




#Preview {
  VideoSelectView()
}
