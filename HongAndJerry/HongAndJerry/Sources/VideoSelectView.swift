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
  }
  
  func imageList() -> some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack {
        ForEach(viewModel.attachments) { attachment in
          ImageAttachmentView(imageAttachment: attachment)
//          attachment.thumbnail
        }
      }

    }
  }
}

struct ImageAttachmentView: View {
    
    /// An image that a person selects in the Photos picker.
  @ObservedObject var imageAttachment: VideoAttachment
    
    /// A container view for the row.
    var body: some View {
        HStack {
            
          
            // Display the image that the text describes.
          switch imageAttachment.videoStatus {
            case .loading:
              Image("progress.indicator")
            case .finished(let image):
                image.resizable().aspectRatio(contentMode: .fit).frame(height: 100)
            case .failed:
                Image(systemName: "exclamationmark.triangle.fill")
            default:
                ProgressView()
            }
        }.task {
            // Asynchronously display the photo.
          await imageAttachment.loadThumbnail()
        }
    }
}




#Preview {
  VideoSelectView()
}
