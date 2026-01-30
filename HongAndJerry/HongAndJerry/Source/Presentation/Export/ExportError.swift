//
//  ExportError.swift
//  HongAndJerry
//
//  Created by Rama on 1/29/26.
//

import Foundation

// TODO: edit
enum ExportError: Error {
  case exportSessionCreationFailed
  case exportFailed(Error?)
  case exportCancelled
  case unknown
}
