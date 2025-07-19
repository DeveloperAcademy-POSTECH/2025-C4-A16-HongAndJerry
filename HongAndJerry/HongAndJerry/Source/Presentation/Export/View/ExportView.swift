//
//  ViewExample.swift
//  HongAndJerry
//
//  Created by Rama on 7/16/25.
//

import Photos
import SwiftUI

struct ExportView {
    @State private var viewModel = ExportViewModel()
    @State private var showAlert = false
    let video: AVAsset
}

extension ExportView: View {
    var body: some View {
        Button {
            viewModel.saveVideo(video)
            showAlert = true
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
                    goToSettings()
                }
            )
        }
    }
}

private extension ExportView {
    func goToSettings() {
        if viewModel.alertModel.buttonTitle == ExportNameSpace.AlertRejectMessage.buttonTitle {
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        }
    }
}

