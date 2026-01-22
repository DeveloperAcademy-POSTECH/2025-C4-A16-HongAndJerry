//
//  EditorHeaderView.swift
//  HongAndJerry
//
//  Created by Gemini on 7/21/25.
//

import SwiftUI
import AVFoundation

struct EditorHeaderView: View {
    @EnvironmentObject var router: Router
    
    var videoAsset: AVAsset?
    var videoComposition: AVVideoComposition?
    
    var body: some View {
        HStack {
            backButton()
            
            Spacer()
            
            exportButton(
                video: videoAsset,
                composition: videoComposition
            )
        }
    }
    
    private func backButton() -> some View {
        Button {
            router.pop()
        } label: {
            Image(systemName: "chevron.left")
                .font(.system(size: 22, weight: .medium))
                .foregroundColor(.white)
        }
    }
    
    private func exportButton(
        video: AVAsset?,
        composition: AVVideoComposition?
    ) -> some View {
        Button {
            MediaPermissionUtils.requestPermission { permission in
                if permission == false {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
            }
            
            router.push(screen: .exportView(video, composition))
        } label: {
            Text(ExportNameSpace.ExportView.export)
                .font(.SUITHeader)
                .foregroundStyle(.accent)
        }
    }
}
