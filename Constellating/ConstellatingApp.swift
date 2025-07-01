//
//  ConstellatingApp.swift
//  Constellating
//
//  Created by kris aziabor on 7/1/25.
//

import SwiftUI

@main
struct ConstellatingApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
