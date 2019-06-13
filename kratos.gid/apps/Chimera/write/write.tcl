namespace eval Chimera::write {
    variable writeAttributes
}

proc Chimera::write::Init { } {
    # Namespace variables inicialization
    variable writeAttributes
    set writeAttributes [Fluid::write::GetAttributes]

    SetAttribute writeCoordinatesByGroups 1
    SetAttribute validApps [list "Fluid" "Chimera"]
}

# Events
proc Chimera::write::writeModelPartEvent { } {

    Fluid::write::writeModelPartEvent
}
proc Chimera::write::writeCustomFilesEvent { } {
    write::CopyFileIntoModel "python/KratosFluid.py"
    write::RenameFileInModel "KratosFluid.py" "MainKratos.py"
}

proc Chimera::write::GetAttribute {att} {
    variable writeAttributes
    return [dict get $writeAttributes $att]
}

proc Chimera::write::GetAttributes {} {
    variable writeAttributes
    return $writeAttributes
}

proc Chimera::write::SetAttribute {att val} {
    variable writeAttributes
    dict set writeAttributes $att $val
}

Chimera::write::Init
