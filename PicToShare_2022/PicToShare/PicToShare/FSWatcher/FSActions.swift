//
//  FSActions.swift
//  TestApp
//
//  Created by Liana on 20/03/2022.
//

import Foundation


import FileProvider

//FSActionHandler : gere le traitement a effectuer lors de la détection d'un nouveau fichier sur iCloud
class FSActionHandler : ActionHandler {
    let scriptName = "pictoshare.loopScript.sh"
    
    let fm = FileManager.default

    let appContainerURL: URL
    let workingDirURL: URL

    //expression reguliere permettant d'extraire les informations de contexte (definie dans le constructeur)
    let fileNameMatchRegex: NSRegularExpression
    let scriptCommand: String
    
    let importationManager: ImportationManager
    let configurationManager: ConfigurationManager
    let calendarsResource: CalendarsResource

    //detecte et extrait les informations de contexte depuis un nom de fichier
    func matchFileName(fileName item:String) -> (name:String, docType:String, eventType:String, calendarList: [String])? {
        //match du nom de fichier avec la regex
        let trymatch = fileNameMatchRegex.firstMatch(
                in: item,
                options: [],
                range:NSRange(location:0, length:item.utf16.count)
            )
    
        //s'il y a un match, on extrait les informations, sinon la fonction renvoit nil
        guard let match = trymatch else {
            return nil
        }
    
        let name: String = String(item[Range(match.range(at:4), in:item)!])
        let docType: String = String(item[Range(match.range(at:1), in:item)!])
        let eventType: String = String(item[Range(match.range(at:2), in:item)!])
        let calendarList: [String] = String(item[Range(match.range(at:3), in:item)!]).components(separatedBy: [","])

        
        return (name, docType, eventType, calendarList)
    }
    
    //fonction appelee lors du callback d'evenement du File System (requis dans le protocole). Elle definit le traitement effectue lorsqu'un nouveau fichier est ajoute sur iCloud
    func handleFSEvent() -> Void {
        do {
            //exectution du script de traitement (defini dans le constructeur)
            let res = try safeShell(scriptCommand, env: appContainerURL)
            print("script result : \n\(res)")
            
            print("beginning importations")
            let filesToImport = try fm.contentsOfDirectory(atPath: workingDirURL.appendingPathComponent("pending").path)
            
            //traitement des documents ajoutes un a un
            for file in filesToImport {
                print()
                print("importing \(file)")
                
                //si le document ne respecte pas la convention de nommage (define par l'expression reguliere), il est deplace vers pictoshare.workingdir/failed
                guard let (name, documentType, eventType, calendarList) = matchFileName(fileName: file) else {
                    print("unsupported naming format : \(file)")
                    do {
                        try fm.moveItem(at: workingDirURL.appendingPathComponent("pending/\(file)"), to: workingDirURL.appendingPathComponent("failed/\(file)"))
                    } catch {
                        print("WARNING : couldn't move failed file to pictoshare.workingdir/failed")
                    }
                    continue
                }
                
                //si le document respecte la convention de nommage, on trouve les configurations correspondant aux informations de contexte
                let docTypeConfig = configurationManager.types.first(where: { (available: DocumentTypeMetadata) -> Bool in
                    available.description == documentType
                })
                
                let eventTypeConfig = configurationManager.contexts.first(where: { (available: UserContextMetadata) -> Bool in
                    available.description == eventType
                })
                
                print("Additional calendars :")
                print(calendarList)
                
                for calendarName in calendarList {
                    guard let addedCalendar =
                            calendarsResource.calendars.first(where: {cal in
                        cal.description == calendarName
                    }) else {
                        print("unrecognised calendar \(calendarName)")
                        continue
                    }
                    eventTypeConfig?.calendars.update(with: addedCalendar)
                }
                //let calendarConfig = PartialImportationConfiguration()
                
                //le fichier a traiter est renomme (pour enlever les informations de contexte du nom) et deplace vers pictoshare.workingdir/done
                let fileUrl = workingDirURL.appendingPathComponent("pending/\(file)", isDirectory: false)
                let renamedUrl = workingDirURL.appendingPathComponent("done/\(name)", isDirectory: false)
                let failedUrl = workingDirURL.appendingPathComponent("failed/\(name)", isDirectory: false)

                var workingFileName : URL
                do {
                    try fm.moveItem(at: fileUrl, to: renamedUrl)
                    workingFileName = renamedUrl
                } catch {
                    workingFileName = fileUrl
                }
                
                var willProceed = true
                
                //prints dans la console pour debugger les configurations, l'utilisateur ne le voit pas
                if let docConfig = docTypeConfig {
                    print("recognised \"\(documentType)\" as a valid configuration : \n")
                    debugConfigurationPrint(docConfig)
                } else {
                    print("unknown document type \"\(documentType)\"\n")
                    willProceed = false
                    do {
                        try fm.moveItem(at: fileUrl, to: failedUrl)
                    } catch {
                        print("WARNING : couldn't move failed file to pictoshare.workingdir/failed")
                    }
                }
                
                if willProceed, let eventConfig = eventTypeConfig {
                    print("recognised \"\(eventType)\" as a valid configuration : \n")
                    debugConfigurationPrint(eventConfig)
                } else {
                    print("unknown event type \"\(eventType)\"\n")
                    willProceed = false
                    do {
                        try fm.moveItem(at: fileUrl, to: failedUrl)
                    } catch {
                        print("WARNING : couldn't move failed file to pictoshare.workingdir/failed")
                    }
                }

                //application de la chaine de traitement, en utilisant les configurations detectees
                if willProceed {
                    importationManager.importDocument(workingFileName, with: docTypeConfig, eventTypeConfig)
                }

            }
        } catch {
            
            print("file event handling failed : \(error)\n")
        }
    }
    
    //affiche lecontenu d'une configuration (pour le debug)
    func debugConfigurationPrint(_ config: PartialImportationConfiguration) {
        print("script : \(config.documentProcessorScript?.path ?? "nil")")
        print("folder : \(config.bookmarkFolder?.path ?? "nil")")
        print("integrators : \(config.documentIntegrators.description)")
        print("annotators : \(config.documentAnnotators.description)")
        print("additional annotations : \(config.additionalDocumentAnnotations)")
        print("copy/delete : \(String(describing: config.copyBeforeProcessing)) / \(String(describing: config.removeOriginalOnProcessingByproduct))")
        print("associated calendars : \(config.calendars)")

    }
    
    //constructeur (config et importation sont definis au lancement de l'application)
    required init(_ config : ConfigurationManager,_ importation: ImportationManager, _ calendars: CalendarsResource) {
        //definition du format de nommage "type-evenement_nomFichier.pdf"
        fileNameMatchRegex = try! NSRegularExpression(pattern: "^(.*?)\\-(.*?):(.*?)\\_(.*)")
        
        //URL du container de l'application. Le dossier utilisé pour trauter les fichiers venat d'iCloud est pictoshare.workingdir, situe dans ce container pour des raisons de droits d'acces. Il contient 3 sous-dossiers : pending (fichiers en attente), done (fichiers traites), et failed (fichiers non traites)
        appContainerURL = fm.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        )[0]
        
        workingDirURL = appContainerURL.appendingPathComponent("pictoshare.workingdir")

        //definition de la commande executee lors de la detection d'un nouveau fichier
        scriptCommand = shFriendly(appContainerURL) + "/" + scriptName
        print("script command : " + scriptCommand)
        
        //creation des fichiers et dossiers necessaires (s'ils n'existent pas deja)
        exportScript(to: appContainerURL, withname: scriptName, using: fm, forcing: true)
        createSynchronisationDirectories(at: workingDirURL, using: fm, forcing: false)
        
        configurationManager = config
        importationManager = importation
        calendarsResource = calendars
    }
}

