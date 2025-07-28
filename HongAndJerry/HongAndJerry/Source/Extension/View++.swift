//
//  View++.swift
//  HongAndJerry
//
//  Created by Rama on 7/28/25.
//

import SwiftUI

extension View {
    func hjNavigationBar(title: String) -> some View {
            self.modifier(HJNavigationBar(title: title))
        }
}
