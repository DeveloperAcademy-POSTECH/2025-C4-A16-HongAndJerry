import SwiftUI
import AVFoundation

struct EditorHeaderView: View {
  @EnvironmentObject var router: Router
  @Environment(EditorViewModel.self) private var viewModel
  
  var body: some View {
    HStack {
      backButton()
      Spacer()
      exportButton()
    }
    .alert(
      ExportNameSpace.AlertConfirmMessage.title,
      isPresented: Binding(
        get: { viewModel.showExportConfirmAlert },
        set: { viewModel.showExportConfirmAlert = $0 }
      )
    ) {
      Button(ExportNameSpace.AlertConfirmMessage.cancelButton, role: .cancel) { }
      Button(ExportNameSpace.AlertConfirmMessage.confirmButton) {
        viewModel.handleExport(router: router)
      }
    } message: {
      Text(ExportNameSpace.AlertConfirmMessage.message)
    }
    .alert(
      viewModel.exportAlert.title,
      isPresented: Binding(
        get: { viewModel.showResultAlert },
        set: { viewModel.showResultAlert = $0 }
      )
    ) {
      Button(viewModel.exportAlert.buttonTitle) {
        viewModel.showResultAlert = false
        viewModel.handleAlertDismiss(router: router)
      }
    } message: {
      Text(viewModel.exportAlert.message)
    }
    .overlay {
      if viewModel.exportIsLoading {
        loadingOverlay()
      }
    }
  }
  
  @ViewBuilder
  private func backButton() -> some View {
    Button {
      router.pop()
    } label: {
      Image(systemName: "chevron.left")
        .font(.system(size: 22, weight: .medium))
        .foregroundColor(.white)
    }
  }
  
  @ViewBuilder
  private func exportButton() -> some View {
    Button {
      viewModel.requestExport()
    } label: {
      Text(ExportNameSpace.ExportView.export)
        .font(.SUITHeader)
        .foregroundStyle(.accent)
    }
  }
  
  @ViewBuilder
  private func loadingOverlay() -> some View {
    ZStack {
      Color.black.opacity(0.4)
        .ignoresSafeArea()
      ProgressView()
        .progressViewStyle(CircularProgressViewStyle(tint: .white))
        .scaleEffect(1.5)
    }
  }
}
