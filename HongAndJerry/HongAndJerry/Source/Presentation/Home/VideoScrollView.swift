//
//  VideoScrollView.swift
//  HongAndJerry
//
//  Created by Hong on 7/21/25.
//

import SwiftUI
import Photos

struct VideoScrollView {
    @Binding var viewModel: AlbumVideoViewModel
    let columns = Array(repeating: GridItem(.flexible()), count: 3)
    @Binding var selectedAsset: PHAsset?
    @Binding var showPlayer: Bool
}

extension VideoScrollView: View {
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns) {
                ForEach(viewModel.videos) { video in
                    VStack(alignment: .leading) {
                        Image(uiImage: video.thumbnail)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                        Text(video.durationValue)
                            .font(.SUITBodyTitle)
                            .foregroundStyle(.font)
                        Text(video.creationDateValue)
                            .font(.SUITTimer)
                            .foregroundStyle(.inactive)
                        Text(video.creationTimeValue)
                            .font(.SUITTimer)
                            .foregroundStyle(.inactive)
                    }
                    .onTapGesture {
                        selectedAsset = video.asset
//                        showPlayer = true
                    }
                }
            } 
            .padding()
        }
    }
}
