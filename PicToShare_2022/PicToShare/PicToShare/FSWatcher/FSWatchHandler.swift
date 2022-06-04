//
//  WatcherLogic.swift
//  PicToShare
//
//  Created by Avellaneda Tom on 05/05/2022.
//

import Foundation

//definition de types : WatchPathType definit les differentes manieres de definir le dossier surveille (chemin absolu, container de l'application etc...)
enum WatchPathType {
    case absolutePath(path: String)
    case containerPath(path: String?)
    case homedirPath(path: String?)
}

//protocole (interface) WatchHandler : gere la surveillance du dossier (ici iCloud), via l'abonnement a un evenement du File System
protocol WatchHandler {
    func eventCallback(_ : [FileEvent]) -> Void
    init(actionHandler: ActionHandler, pathType: WatchPathType)
}

//protocole ActionHandler : gere le traitement a effectuer lors de la detection d'un fichier
protocol ActionHandler {
    var appContainerURL : URL { get }
    var scriptName : String { get }
    var fileNameMatchRegex : NSRegularExpression { get }

    func handleFSEvent() -> Void
    init(_ config : ConfigurationManager,_ importation: ImportationManager, _ calendarsResource: CalendarsResource)
}

//FSWatchHandler : gere la surveillance du dossier iCloud
class FSWatchHandler : WatchHandler {
    let fsWatcher = SwiftFSWatcher()
    let actionHandler : ActionHandler
    let fm = FileManager.default
    
    let sourceURL : URL
    let appContainerURL : URL

    //fonction appelee lors de la detection d'un changement dans le dossier surveille
    func eventCallback(_ changeEvents: [FileEvent]) -> Void {
        print("\n > Change detected ! \ncallback paths :")
        for ev in changeEvents {
            print(ev.eventPath ?? "no path")
        }
        
        //appel du ActionHandler, en ayant mis en pause la surveillance pour eviter des duplications d'appels
        self.fsWatcher.pause()
        self.actionHandler.handleFSEvent()
        self.fsWatcher.resume()
    }
    
    //constructeur (handler et pathType sont definis au lancement de l'application)
    required init(actionHandler handler : ActionHandler, pathType: WatchPathType) {
        actionHandler = handler
        appContainerURL = handler.appContainerURL
        
        switch (pathType) {
        case .absolutePath(let path):
            sourceURL = URL(string: path)!
            break
        case .containerPath(let path):
            sourceURL = (path != nil) ?
                URL(string: path!, relativeTo: appContainerURL)! :
                appContainerURL
        case .homedirPath(let path):
            sourceURL = (path != nil) ?
                URL(string: path!, relativeTo: fm.homeDirectoryForCurrentUser)! :
                fm.homeDirectoryForCurrentUser
            break
        }
        print("source path : " + sourceURL.path)
        
        if (!fm.fileExists(atPath: sourceURL.path)) {
            print("source directory unknown")
            do {
                try fm.createDirectory(at: sourceURL, withIntermediateDirectories: false)
                print("created source directory")
            } catch {
                print("unable to create directory : \(error)")
            }
        }
            
        fsWatcher.watchingPaths = [sourceURL.path]
        
        fsWatcher.watch (eventCallback)
    }
}
