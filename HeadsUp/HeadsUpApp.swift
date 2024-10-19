//
//  HeadsUpApp.swift
//  HeadsUp
//
//  Created by Konstantin Merenkov on 16.10.2024.
//

import SwiftUI

@main
struct HeadsUpApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}
