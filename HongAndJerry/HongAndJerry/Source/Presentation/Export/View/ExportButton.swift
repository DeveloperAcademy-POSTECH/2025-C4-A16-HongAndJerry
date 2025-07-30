//
//  ExportButton.swift
//  HongAndJerry
//
//  Created by Rama on 7/16/25.
//

import Photos
import SwiftUI

struct ExportButton {
    @State private var viewModel = ExportViewModel()
    @State private var showAlert = false
    let video: AVAsset?
    let composition: AVVideoComposition?
    @EnvironmentObject var router: Router
}

extension ExportButton: View {
    var body: some View {
        Button {
            if let video = video {
                viewModel.saveVideo(video, videoComposition: composition)
                showAlert = true
            } else {
                /// TODO: video 아직 로드 안되었을 때 로직 추가해야 함.
            }
        } label: {
            Text(ExportNameSpace.ExportView.export)
                .font(.SUITHeader)
                .foregroundStyle(.accent)
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text(viewModel.alertModel.title),
                message: Text(viewModel.alertModel.message),
                dismissButton: .default(Text(viewModel.alertModel.buttonTitle)) {
                    if viewModel.alertModel.buttonTitle == ExportNameSpace.AlertSuccessMessage.buttonTitle {
                        router.popToRoot()
                    }
                    goToSettings()
                }
            )
        }
    }
}

private extension ExportButton {
    func goToSettings() {
        if viewModel.alertModel.buttonTitle == ExportNameSpace.AlertRejectMessage.buttonTitle {
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        }
    }
}

