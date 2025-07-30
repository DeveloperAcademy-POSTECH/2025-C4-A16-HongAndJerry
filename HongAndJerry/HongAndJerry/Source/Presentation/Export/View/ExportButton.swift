//
//  ExportButton.swift
//  HongAndJerry
//
//  Created by Rama on 7/16/25.
//

import Photos
import SwiftUI

struct ExportButton {
    let video: AVAsset?
    let composition: AVVideoComposition?
    @EnvironmentObject var router: Router
}

extension ExportButton: View {
    var body: some View {
        Button {
            router.push(screen: .exportView(video, composition))
        } label: {
            Text(ExportNameSpace.ExportView.export)
                .font(.SUITHeader)
                .foregroundStyle(.accent)
        }
    }
}

//private extension ExportButton {
//    func goToSettings() {
//        if viewModel.alertModel.buttonTitle == ExportNameSpace.AlertRejectMessage.buttonTitle {
//            if let url = URL(string: UIApplication.openSettingsURLString) {
//                UIApplication.shared.open(url)
//            }
//        }
//    }
//}

