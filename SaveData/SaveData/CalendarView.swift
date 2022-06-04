//
//  CalendarView.swift
//  SaveData
//
//  Created by Devos Emma on 23/05/2022.
//


import SwiftUI
import Foundation
import UIKit
import PDFKit
import EventKitUI
import EventKit

struct CalendarView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var cal: CalendarsResource
    @Binding var selected: Set<EKEvent>
    @Binding var calendars: Set<EKCalendar>


    var body: some View {
        GroupBox(label: Text("pts.resources.calendars")) {
            HStack {
                VStack(alignment: .leading) {
                    SetOptionsView(
                        options: $cal.calendars,
                        selected: $calendars
                    ).padding(.bottom, 5)

                    HStack {
                        Button(action: cal.refreshCalendars) {
                            Image(systemName: "arrow.clockwise")
                        }
                        Text("refresh")
                    }
                }
                Spacer()
            }
        }
        
        
         
        //Text(cal.eventsCal)
        
    }
}



