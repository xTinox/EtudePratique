//
//  ContentView.swift
//  SaveData
//
//  Created by Tino on 21/03/2022.
//

// Bibliothèques importées
import SwiftUI
import Foundation
import UIKit
import PDFKit
import EventKit
import EventKitUI

// Structure de l'interface principale de l'application
struct ContentView: View{
    
    let PTScontainer:String = "iCloud~pictosave" //Conteneur iCloud
    
    @EnvironmentObject var vm: ImageManager // Objet (non instancié) de classe ImageManager
    @ObservedObject var sc: ScanView // Objet (non instancié) de classe ScanView
    @EnvironmentObject var cal: CalendarsResource
    
    @State var openFile: Bool = false // Booléen pour afficher l'explorateur de fichiers
    
    @State var images: [UIImage] = [] //Liste d'UIImage(s) qui compose le document
    
    @State var pickerType: [String] = ["Document numérique","Tableau blanc","Feuille papier","Carte de visite", "Page de livre","Journal", "Autre"] //Liste initiale des Types de document
    @State var newType: String = "" //Variable String correspondant au champ texte de l'a
    
    @State var pickerEvent: [String] = ["Travail", "Réunion", "Projet", "Étude", "Personnel", "Loisirs"]
    @State var newEvent: String = ""
    
    @State var selectionType = 0 // Indice sur la liste des Types
    @State var selectionEvent = 0 // Indice sur la liste des Évenements
    
    @State private var showAlert = false // Booléen sur l'affichage d'une Alerte (suppression des images)
    @State private var selectedTab = 1 //Choix de la vue (Première vue)

    @State var pickerCal: [String] = []
    @Binding var calendars: Set<EKCalendar>
    @State var rafraichir : Bool = false
    @State private var showCal = false

    //Une VStack permet de mettre plusieurs éléments sur une même colonne (vertical)
    //Une HStack permet de mettre plusieurs éléments sur une même ligne (horizontal)

    var body: some View{
        VStack(spacing: 10){
            Spacer()
            VStack{
                HStack(spacing: 100.0){
                    VStack{
                        Label("Type",systemImage: "doc")
                        // Liste déroulante choix du type
                        Picker("Choisir un type", selection: $selectionType){
                            ForEach(0 ..< pickerType.count){
                                Text(self.pickerType[$0]).tag($0)
                            }
                            .id(self.pickerType)
                        }.padding(10)
                            .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color.gray,lineWidth: 3))
                    }
                    VStack{
                        Label("Évènement", systemImage: "rectangle.on.rectangle.square")
                        // Liste choix de l'évènement
                        Picker("Choisir un événement", selection: $selectionEvent){
                            ForEach(0 ..< pickerEvent.count){
                                Text(self.pickerEvent[$0]).tag($0)
                            }
                            .id(self.pickerEvent)
                        }.padding(10)
                            .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color.gray,lineWidth: 3))
                    }
                    VStack {
                    Label("Lier un calendrier", systemImage: "calendar")
                        Button(
                            action: {
                                cal.refreshCalendars()
                                selectedTab = 3
                            }, label: {
                                Label("Choisir", systemImage: "calendar.badge.plus")
                            }).padding(15)
                            .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color.gray,lineWidth: 3))
                            .sheet(isPresented: $rafraichir) {
                                GroupBox(label: Text("Ressources Calendriers")) {
                                    HStack {
                                        VStack(alignment: .leading) {
                                            SetOptionsView(
                                                options: $cal.calendars,
                                                selected: $calendars
                                            ).padding(.bottom, 5)
                                            
                                            Button("Retour") {
                                                print(calendars)
                                                showCal.toggle()
                                            }
                                        }
                                        Spacer()
                                    }
                                }
                                //CalendarView(selected: calendars, calendars: cal.calendars).environmentObject(cal)
                            }
                    }
                }
            }
            //Structure permettant d'afficher les différentes photos prises à la suite horizontalement et de pouvoir scroller pour les voir
            ScrollView(.horizontal){
                HStack {
                    // Affichage de la liste des UIImages sur l'écran
                    if (!sc.imageArray.isEmpty){
                        ForEach(sc.imageArray, id: \.self) { image in
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 200, height: 280)
                        }
                    }
                }
            }
            // Si la liste d'UIImages est composée d'au moins 1 image, alors les boutons "Supprimer" et "Sauvegarder" apparaissent
            if !(sc.imageArray.isEmpty){
                HStack{
                    Spacer()
                    Button(action:{
                        showAlert = true
                    }, label :{
                        Text("Supprimer")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(Color.red)
                        Image(systemName: "trash")
                    })
                    .foregroundColor(Color.red)
                    .padding(.all,10)
                    .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color.red,lineWidth: 3))
                    .disabled(sc.imageArray.isEmpty)
                    //Warning qui s'affiche lorsqu'on appuie sur le bouton
                    .alert("Voulez-vous vraiment supprimer l'intégralité des photos prises/affichées ci-dessus",isPresented: $showAlert){
                        Button("Oui"){sc.imageArray.removeAll()}
                        Button("Non"){}
                    }
                    Spacer()
                    // Bouton de sauvegarde
                    Button(action: {
                        if !(sc.imageArray.isEmpty){
                            vm.saveAsPDF(images: sc.imageArray, nomEvent: self.pickerEvent[selectionEvent], folderName: self.pickerType[selectionType], calendars: calendars)
                        }
                        else{
                            print("Aucune photo")
                        }
                    }, label: {Text("Sauvegarder")})
                        .font(.title)
                        .padding(20.0)
                        .foregroundColor(Color.green)
                        .frame(width: 200.0, height: 50.0)
                        .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color.green,lineWidth: 4))
                    Spacer()
                }
            }
            
            // Différentes vues controlées par la barre d'onglets
            TabView(selection: $selectedTab) {
                VStack(spacing: 20.0){
                    // Bouton pour accéder à l'API de Scan (VisionKit)
                    Button(action:{
                        UIApplication.shared.windows.filter({$0.isKeyWindow}).first?.rootViewController?.present(sc.getDocumentCameraViewController(), animated: true, completion: nil)
                        openFile = false
                    }, label:{
                        Text("Prendre des photos")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(Color.blue)
                            
                        Image(systemName: "camera")
                            .resizable(resizingMode: .tile)
                            .aspectRatio(contentMode: .fit)
                            .foregroundColor(Color.blue)
                            .frame(width: /*@START_MENU_TOKEN@*/50.0/*@END_MENU_TOKEN@*/, height: /*@START_MENU_TOKEN@*/50.0/*@END_MENU_TOKEN@*/)
                        
                    })
                    .padding(/*@START_MENU_TOKEN@*/.all/*@END_MENU_TOKEN@*/)
                    .frame(width: 300.0, height: 100.0)
                    .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color.blue,lineWidth: 3))
                    
                    // Bouton pour importer un document
                    Button(action:{
                        openFile.toggle()
                    },label:{
                        Text("Choisir un document")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(Color.green)
                        Image(systemName: "doc.badge.plus")
                            .resizable(resizingMode: .tile)
                            .aspectRatio(contentMode: .fit)
                            .foregroundColor(Color.green)
                            .frame(width: /*@START_MENU_TOKEN@*/50.0/*@END_MENU_TOKEN@*/, height: /*@START_MENU_TOKEN@*/50.0/*@END_MENU_TOKEN@*/)
                    })
                    .padding(10)
                    .frame(width: 300.0, height: 100.0)
                    .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color.green,lineWidth: 3))
                    // Fenêtre de l'importation d'un fichier (explorateur de fichiers)
                    .fileImporter(isPresented: $openFile, allowedContentTypes: [.pdf,.jpeg]) { (res) in
                    do{
                        let fileURL = try res.get()
                        // Fichiers JPG et PDF autorisés
                        if FileManager.default.fileExists(atPath: fileURL.path){
                            let urlPDF_JPG = URL(string: fileURL.absoluteString)
                            if (fileURL.pathExtension=="pdf" || fileURL.pathExtension=="PDF"){
                                sc.imageArray += vm.pdfToImages(url: urlPDF_JPG!)!
                            }
                            else if (fileURL.pathExtension=="jpg" || fileURL.pathExtension=="JPG"){
                                let data = try Data(contentsOf: urlPDF_JPG!)
                                let imUI = UIImage(data: data)!
                                sc.imageArray.append(imUI)
                            }
                            else{
                                print(fileURL.pathExtension)
                            }
                            
                        }
                        // Expressions régulières pour récupérer le Type et l'Évènement associé au fichier importé
                        var exprReg = ".*\\/(.*?)\\/(.*?)\\/.*?$"
                        let matches1 = vm.matches(for: exprReg, in: fileURL.absoluteString, groupe: 1).removingPercentEncoding!
                        let matches2 = vm.matches(for: exprReg, in: fileURL.absoluteString, groupe: 2).removingPercentEncoding!
                        
                        print(matches1)
                        print(matches2)
                        
                        if (matches1==self.PTScontainer || matches2==vm.recentsFiles){
                            exprReg = ".*\\/(.*?)-(.*?)!.*?\\_.*$"
                        }
                        else{
                            exprReg = ".*\\/(.*?)\\/(.*?)!.*?\\_.*$"
                        }
                        
                        let matchedType = vm.matches(for: exprReg, in: fileURL.absoluteString, groupe: 1).removingPercentEncoding!
                        let matchedEvent = vm.matches(for: exprReg, in: fileURL.absoluteString, groupe: 2).removingPercentEncoding!
                        
                        if !pickerType.contains(String(matchedType)){
                            pickerType.append(matchedType)
                        }
                        if !pickerEvent.contains(String(matchedEvent)){
                            pickerEvent.append(matchedEvent)
                        }
                        
                        selectionType = pickerType.firstIndex(of: String(matchedType))!
                        selectionEvent = pickerEvent.firstIndex(of: String(matchedEvent))!
                        
                        print(matchedType)
                        print(matchedEvent)
                        
                    } catch {
                        print("erreur.")
                    }
                }
                }.tabItem { Image(systemName: "camera.on.rectangle");Text("Capture") }.tag(1)
                
                // Vue pour Ajouter ou Supprimer un Type ou un Évènement
                VStack(spacing : 30){
                    Label{
                        Text("Ajouter ou Supprimer").font(.title).fontWeight(.bold).underline()
                    } icon:{}
                    HStack{
                        Text("Type :")
                            .font(.title3)
                            .padding(.horizontal, 10)
                        TextField("Type à Ajouter ou Supprimer" , text: $newType)
                            .modifier(TextFieldClearButton(text: $newType))
                            .multilineTextAlignment(.leading)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding(.trailing, 20)
                            .padding(.top, 10)
                        if (!newType.isEmpty) && !pickerType.contains(newType){
                            Button(action:{
                                pickerType.append(newType)
                                selectionType = pickerType.firstIndex(of: newType)!
                            }, label: {
                                Text("Ajouter")
                                Image(systemName: "plus")
                            }).padding(10)
                                .foregroundColor(Color.blue)
                                .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color.blue,lineWidth: 3))
                                .padding(.trailing,10)
                        }
                        if (pickerType.contains(newType)){
                            Button(action:{
                                if selectionType == pickerType.firstIndex(of: newType)!{
                                    selectionType = 0
                                }
                                pickerType.remove(at: pickerType.firstIndex(of: newType)!)
                            }, label: {
                                Text("Supprimer")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(Color.red)
                                Image(systemName:"trash")
                            }).padding(10)
                                .foregroundColor(Color.red)
                                .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color.red,lineWidth: 3))
                                .padding(.trailing,10)
                        }
                    }
                    HStack{
                        Text("Évènement :")
                            .font(.title3)
                            .padding(.horizontal, 10)
                        TextField("Évènement à Ajouter ou Supprimer" , text: $newEvent)
                            .modifier(TextFieldClearButton(text: $newEvent))
                            .multilineTextAlignment(.leading)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding(.trailing, 20)
                        if (!newEvent.isEmpty && !pickerEvent.contains(newEvent)){
                            Button(action:{
                                if !pickerEvent.contains(newEvent){
                                    if !newEvent.isEmpty {
                                        pickerEvent.append(newEvent)
                                        selectionEvent = pickerEvent.firstIndex(of: newEvent)!
                                    }
                                }
                            }, label: {
                                Text("Ajouter")
                                Image(systemName: "plus")
                            }).padding(10)
                                .foregroundColor(Color.blue)
                                .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color.blue,lineWidth: 3))
                                .padding(.trailing,10)
                        }
                        if(pickerEvent.contains(newEvent)){
                            Button(action:{
                                if pickerEvent.contains(newEvent){
                                    if selectionEvent == pickerEvent.firstIndex(of: newEvent)!{
                                        selectionEvent = 0
                                    }
                                    pickerEvent.remove(at: pickerEvent.firstIndex(of: newEvent)!)
                                }
                            }, label: {
                                Text("Supprimer")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(Color.red)
                                Image(systemName:"trash")
                            }).padding(10)
                                .foregroundColor(Color.red)
                                .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color.red,lineWidth: 3))
                                .padding(.trailing,10)
                        }
                    }
                }.tabItem { Image(systemName: "slider.horizontal.3")
                    Text("Type / Évènement")
                }.tag(2)
                
                
                HStack {
                    VStack(alignment: .leading) {
                        SetOptionsView(
                            options: $cal.calendars,
                            selected: $calendars
                        ).padding(.bottom, 5)
                        
                        Button("Retour") {
                            print(calendars)
                            showCal.toggle()
                        }
                    }
                    Spacer()
                }.tabItem {
                    
                    Image(systemName: "calendar")
                    Text("Calendriers")
                }.tag(3)
                
                VStack(alignment: .leading){
                    Text("'Prendre des photos' permet d'utiliser l'appareil photo pour effectuer un scan d'un document\n")
                    Text("'Choisir un document' permet d'importer un document (JPG ou PDF)\n")
                    Text("Choisir le Type et l'Évènement associé au document\n")
                    Text("Sauvegarder et votre document se retrouvera dans les fichiers de l'appareil mais aussi sur PicToShare\n")
                    
                    }.tabItem { Image(systemName: "info.circle")
                        Text("Informations")
                }.tag(4)
            }
        }
    }
}

// Structure permettant de supprimer un champ de texte
struct TextFieldClearButton : ViewModifier {
    @Binding var text: String
    
    func body(content: Content) -> some View {
        HStack {
            content
            if(!text.isEmpty){
                Button(action: {text = ""}, label: {
                    Image(systemName: "delete.left")
                        .foregroundColor(Color(UIColor.opaqueSeparator))
                })
            }
        }
    }
}



// Aperçu de l'application dans XCode
/*
struct Content_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(sc: ScanView())
            
    }
}
 */

struct ContentViewWrapper : View {
    @State var cals = Set<EKCalendar>()
    var body : some View{
        ContentView(sc: ScanView(), calendars:  $cals)
    }
}

struct ContentViewPreview: PreviewProvider {
    static var previews: some View {
        ContentViewWrapper()
    }
}
