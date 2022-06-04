mkdir ~/Desktop/FichierPourPhotos
cd ~/Library/Mobile\ Documents/iCloud~pictosave/Documents/
for dir in */ ; do
    if [ -d "$dir" ]
    then
        mkdir ~/Desktop/FichierPourPhotos/"$dir"
        echo "$dir"
        cd "$dir"
        for f in * ; do
            echo "$dir$f"
            cp $f ~/Desktop/FichierPourPhotos/"$dir"
            rm $f
        done
        cd ..
    fi
done

