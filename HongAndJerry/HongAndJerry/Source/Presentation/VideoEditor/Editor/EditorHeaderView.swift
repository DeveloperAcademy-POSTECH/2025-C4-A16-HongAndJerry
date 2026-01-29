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
    @Environment(VideoViewModel.self) private var viewModel

    @State private var showExportConfirmAlert = false
    @State private var showResultAlert = false

    var body: some View {
        HStack {
            backButton()
            
            Spacer()
            
            exportButton()
        }
        .alert(
            ExportNameSpace.AlertConfirmMessage.title,
            isPresented: $showExportConfirmAlert
        ) {
            Button(ExportNameSpace.AlertConfirmMessage.cancelButton, role: .cancel) { }
            Button(ExportNameSpace.AlertConfirmMessage.confirmButton) {
                handleExport()
            }
        } message: {
            Text(ExportNameSpace.AlertConfirmMessage.message)
        }
        .alert(
            viewModel.exportController.alertModel.title,
            isPresented: $showResultAlert
        ) {
            Button(viewModel.exportController.alertModel.buttonTitle) {
                showResultAlert = false
                handleAlertDismiss()
            }
        } message: {
            Text(viewModel.exportController.alertModel.message)
        }
        .overlay {
            if viewModel.exportController.isLoading {
                ZStack {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                    
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                    
                }
            }
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
    
    private func exportButton() -> some View {
        Button {
            showExportConfirmAlert = true
        } label: {
            Text(ExportNameSpace.ExportView.export)
                .font(.SUITHeader)
                .foregroundStyle(.accent)
        }
    }

    private func handleExport() {
        guard let video = viewModel.getFinalVideoAsset() else { return }
        let composition = viewModel.getFinalVideoComposition()

        viewModel.exportController.saveVideo(
            video: video,
            videoComposition: composition
        ) {
            showResultAlert = true
        }
    }

    private func handleAlertDismiss() {
        if viewModel.exportController.alertModel.title == ExportNameSpace.AlertSuccessMessage.title {
            router.popToRoot()
        }
    }
}

