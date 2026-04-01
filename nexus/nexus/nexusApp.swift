//
//  nexusApp.swift
//  nexus
//
//  Created by Anton on 3/14/26
//

import SwiftUI
#if canImport(FirebaseCore)
import FirebaseCore
#endif

@main
struct nexusApp: App {
    init() {
        #if canImport(FirebaseCore)
        FirebaseApp.configure()
        #endif
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
