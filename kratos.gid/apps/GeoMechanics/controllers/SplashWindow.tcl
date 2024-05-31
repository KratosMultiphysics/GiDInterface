# Create the main window
set mainWindow .gid.maingui
toplevel $mainWindow
wm title $mainWindow "Two Sections Window"
wm geometry $mainWindow 400x200

# Create the first section with two big square buttons
frame $mainWindow.section1 -background white
button $mainWindow.section1.button1 -text "Button 1" -width 10 -height 10
button $mainWindow.section1.button2 -text "Button 2" -width 10 -height 10
grid $mainWindow.section1.button1 -row 0 -column 0 -padx 20 -pady 20
grid $mainWindow.section1.button2 -row 0 -column 1 -padx 20 -pady 20

# Create the second section with text and a small button
frame $mainWindow.section2 -background white
text $mainWindow.section2.text -width 30 -height 5
button $mainWindow.section2.button -text "Small Button" -width 10
grid $mainWindow.section2.text -row 0 -column 0 -padx 20 -pady 20
grid $mainWindow.section2.button -row 1 -column 0 -padx 20 -pady 10

# Place the sections in the main window
grid $mainWindow.section1 -row 0 -column 0 -sticky news
grid $mainWindow.section2 -row 0 -column 1 -sticky news

# Start the event loop
tkwait window $mainWindow