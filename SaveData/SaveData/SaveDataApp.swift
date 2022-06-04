//
//  SaveDataApp.swift
//  SaveData
//
//  Created by Tino on 21/03/2022.
//

import SwiftUI

// Main de l'application
@main
struct SaveDataApp: App {
    @StateObject var vm = ImageManager()
    @StateObject var cal = CalendarsResource()
    var body: some Scene {
        // Fenetre Principale affichée au démarrage
        WindowGroup {
            ContentView(sc: ScanView(), calendars: $cal.selectedCalendars)
                .environmentObject(vm)
                .environmentObject(cal)
        }
    }
}

