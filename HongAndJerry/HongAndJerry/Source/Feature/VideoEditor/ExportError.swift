import Foundation

enum ExportError: Error {
  case exportSessionCreationFailed
  case exportFailed(Error?)
  case exportCancelled
  case unknown
}
