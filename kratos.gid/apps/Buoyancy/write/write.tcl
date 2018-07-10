namespace eval Buoyancy::write {
    variable writeAttributes
}

proc Buoyancy::write::Init { } {    
    Fluid::write::Init
}

proc Buoyancy::write::GetAttribute {att} {
    return [Fluid::write::GetAttribute $att]
}

proc Buoyancy::write::GetAttributes {} {
    return [Fluid::write::GetAttributes]
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

    # Init data
    write::initWriteConfiguration [Fluid::write::GetAttributes]

    # Headers
    write::writeModelPartData
    Fluid::write::writeProperties

    # Materials
    write::writeMaterials [Fluid::write::GetAttribute validApps]

    # Nodal coordinates (1: Print only Fluid nodes <inefficient> | 0: the whole mesh <efficient>)
    if {[Fluid::write::GetAttribute writeCoordinatesByGroups]} {write::writeNodalCoordinatesOnParts} {write::writeNodalCoordinates}

    # Element connectivities (Groups on FLParts)
    write::writeElementConnectivities
    
    # Nodal conditions and conditions
    Fluid::write::writeConditions
    
    # SubmodelParts
    Fluid::write::writeMeshes
    
    # Custom SubmodelParts
    write::writeBasicSubmodelParts [Fluid::write::getLastConditionId]

    
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
