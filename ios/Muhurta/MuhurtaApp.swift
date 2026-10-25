//
//  MuhurtaApp.swift
//  Muhurta
//
//  Created by Shinde on 24/10/26.
//

import SwiftUI
import FirebaseCore
import FirebaseAuth

@objc(AppDelegate)
final class AppDelegate: NSObject, UIApplicationDelegate {
    @objc func application(_ application: UIApplication,
                           didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        return true
    }
}

@main
struct MuhurtaApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    _ = Auth.auth().canHandle(url)
                }
        }
    }
}
