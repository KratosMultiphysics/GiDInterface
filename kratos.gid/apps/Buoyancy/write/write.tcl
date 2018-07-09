namespace eval Buoyancy::write {
    variable writeAttributes
}

proc Buoyancy::write::Init { } {
}

proc Buoyancy::write::GetAttribute {att} {
    variable writeAttributes
    return [dict get $writeAttributes $att]
}

proc Buoyancy::write::GetAttributes {} {
    variable writeAttributes
    return $writeAttributes
}

proc Buoyancy::write::SetAttribute {att val} {
    variable writeAttributes
    dict set writeAttributes $att $val
}

proc Buoyancy::write::AddAttribute {att val} {
    variable writeAttributes
    dict lappend writeAttributes $att $val
}

proc Buoyancy::write::AddAttributes {configuration} {
    variable writeAttributes
    set writeAttributes [dict merge $writeAttributes $configuration]
}

proc Buoyancy::write::AddValidApps {appid} {
    AddAttribute validApps $appid
}

# Events
proc Buoyancy::write::writeModelPartEvent { } {
    # Validation
    set err [Validate]
    if {$err ne ""} {error $err}

    
}
proc Buoyancy::write::writeCustomFilesEvent { } {
    # Materials
    WriteMaterialsFile

    # Main python script
    set orig_name [GetAttribute main_script_file]
    write::CopyFileIntoModel [file join "python" $orig_name ]
    write::RenameFileInModel $orig_name "MainKratos.py"
}

proc Buoyancy::write::Validate {} {
    set err ""    
    set root [customlib::GetBaseRoot]

    return $err
}

proc Buoyancy::write::WriteMaterialsFile { } {
    write::writePropertiesJsonFile [GetAttribute parts_un] [GetAttribute materials_file] "False"
}


proc Buoyancy::write::UpdateUniqueNames { appid } {
    set unList [list "Results"]
    foreach un $unList {
         set current_un [apps::getAppUniqueName $appid $un]
         spdAux::setRoute $un [spdAux::getRoute $current_un]
    }
}

Buoyancy::write::Init
