//
//  LoadingVIew.swift
//  HongAndJerry
//
//  Created by Hong on 7/30/25.
//

import SwiftUI
import AVFoundation

struct LoadingView {
    @State var viewModel: ExportViewModel
    @EnvironmentObject var router: Router
    @State private var isFinished: Bool = false
}

extension LoadingView: View {
    var body: some View {
        VStack {
            LottieView(fileName: "Loading50lottie1", loopMode: .loop)
                .onAppear {
                    viewModel.saveVideo {
                        router.popToRoot()
                    }
                }
        }        
    }
}
