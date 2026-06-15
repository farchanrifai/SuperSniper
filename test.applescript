tell application "Finder"
    set theSelection to selection
    set fileList to ""
    repeat with theItem in theSelection
        set fileList to fileList & POSIX path of (theItem as alias) & linefeed
    end repeat
    return fileList
end tell
