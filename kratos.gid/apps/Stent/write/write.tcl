namespace eval Stent::write {
}

proc Stent::write::Init { } {
    #Structural::write::Init
}

# MDPA Blocks
proc Stent::write::writeModelPartEvent { } {
    Structural::write::writeModelPartEvent
}

# Custom files
proc Stent::write::WriteMaterialsFile { } {
     Structural::write::WriteMaterialsFile
}

proc Stent::write::writeCustomFilesEvent { } {
    Structural::write::writeCustomFilesEvent
}

Stent::write::Init
