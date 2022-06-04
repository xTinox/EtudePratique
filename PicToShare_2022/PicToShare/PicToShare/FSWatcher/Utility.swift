//
//  loopScript.swift
//  PicToShare
//
//  Created by Avellaneda Tom on 05/05/2022.
//

import Foundation

//fonctions auxiliaires utiles aux classes FSActionHandler et FSWatchHandler 

//execution d'une commande via le shell
func safeShell(_ command: String, env: URL) throws -> String {
    let task = Process()
    let pipe = Pipe()
    
    task.standardOutput = pipe
    task.standardError = pipe
    task.arguments = ["-c", command]
    task.currentDirectoryURL = env
    task.executableURL = URL(fileURLWithPath: "/bin/bash")

    try task.run()
    
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    let output = String(data: data, encoding: .utf8)!
    
    return output
}

//transforme les espaces en "\ "
func shFriendly(_ raw: String) -> String {
    return raw.replacingOccurrences(of: " ", with: "\\ ")
}

func shFriendly(_ raw: URL) -> String {
    return raw.path.replacingOccurrences(of: " ", with: "\\ ")
}

//export du script de traitement vers le bon fichier
func exportScript(to directory: URL, withname name: String, using fm: FileManager, forcing alwaysOverrideScriptFile: Bool) -> Void {
    let url = directory.appendingPathComponent(name)
    if fm.fileExists(atPath: url.path) && !alwaysOverrideScriptFile {
        print("script already active")
        return
    }
    
    let scriptContent = #"""
    
    #mkdir ~/Desktop/FichierPourPhotos
    mkdir ~/Documents/safe
    cd ~/Documents/safe
    
    source_dir="$HOME/Library/Mobile Documents/iCloud~pictosave/Documents"
    #source_dir=$HOME/Library/Application\ Support/pictoshare.watched
    echo "source_dir: $source_dir"
    
    cd "$source_dir"
    echo "working root (if 'safe', something is wrong, check if the iCloud directory is correctly setup) : "$(pwd)
    
    #cp_dir="~/Desktop/FichierPourPhotos/"
    cp_dir=$HOME/Library/Application\ Support/pictoshare.workingdir/pending
    
    find . | while read dir; do
        if [ -d "$dir" ] && [ ! "$dir" = "." ]
        then
            mkdir "$dir"
            echo "$dir"
            cd "$cp_dir"/"$dir"
            for f in * ; do
                echo "$dir$f"
                cp $f "$cp_dir"/"$dir"
                rm $f
            done
            cd ..
        elif [ -f "$dir" ] ; then
            echo "$dir"
            cp "$dir" "$cp_dir"
            rm "$dir"
        fi
    done
    
    """#
    
    do {
        try scriptContent.write(to: url, atomically: false, encoding: .ascii)
        try fm.setAttributes([.posixPermissions: 493 /*rwxr-xr-x*/], ofItemAtPath: url.path)
        print("script exported at : \(url.path)")
    } catch {
        print("error while exporting script : \(error)")
    }
}

//creation du dossier pictoshare.workingdir
func createSynchronisationDirectories(at workingDirUrl: URL, using fm: FileManager, forcing alwaysCreateDirectories: Bool) -> Void {
    if fm.fileExists(atPath: workingDirUrl.path) && !alwaysCreateDirectories {
        print("sync directories already active")
        return
    }

    do {
        try fm.createDirectory(at: workingDirUrl, withIntermediateDirectories: false)
        try fm.setAttributes([.posixPermissions: 493 /*rwxr-xr-x*/], ofItemAtPath: workingDirUrl.path)
        try fm.createDirectory(at: workingDirUrl.appendingPathComponent("pending"), withIntermediateDirectories: false)
        try fm.createDirectory(at: workingDirUrl.appendingPathComponent("done"), withIntermediateDirectories: false)
        try fm.createDirectory(at: workingDirUrl.appendingPathComponent("failed"), withIntermediateDirectories: false)

        print("synchronisation directories created at \(workingDirUrl.path)")
    } catch {
        print("error while creating sync directories : \(error)")
    }
}
