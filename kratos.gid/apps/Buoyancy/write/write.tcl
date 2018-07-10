namespace eval Buoyancy::write {
    variable BuoyancyConditions
    variable writeAttributes
}

proc Buoyancy::write::Init { } {    
    Fluid::write::Init
    variable BuoyancyConditions
    set BuoyancyConditions(temp) 0
    unset BuoyancyConditions(temp)
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

    Buoyancy::write::writeConditions
    
    # SubmodelParts
    Fluid::write::writeMeshes
    Buoyancy::write::writeSubModelParts
    
    # Custom SubmodelParts
    #write::writeBasicSubmodelParts [Fluid::write::getLastConditionId]

    
}
proc Buoyancy::write::writeCustomFilesEvent { } {
    # Materials
    WriteMaterialsFile

    # Main python script
    set orig_name [Fluid::write::GetAttribute main_script_file]
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

proc Buoyancy::write::writeConditions {  } {
    variable BuoyancyConditions
    set BCUN "CNVDFFBC"

    # Write the conditions
    set dict_group_intervals [write::writeConditions $BCUN [Fluid::write::getLastConditionId]]

    set root [customlib::GetBaseRoot]
    set xp1 "[spdAux::getRoute $BCUN]/condition/group"
    foreach group [$root selectNodes $xp1] {
        set groupid [get_domnode_attribute $group n]
        set groupid [write::GetWriteGroupName $groupid]
        lassign [dict get $dict_group_intervals $groupid] ini fin
        set BuoyancyConditions($groupid,initial) $ini
        set BuoyancyConditions($groupid,final) $fin
        
    }
}


proc Buoyancy::write::writeSubModelParts { } {
    variable BuoyancyConditions
    set BCUN "CNVDFFBC"
    
    set root [customlib::GetBaseRoot]
    set xp1 "[spdAux::getRoute $BCUN]/condition/group"
    set grouped_conditions [list ]
    #W "Conditions $xp1 [$root selectNodes $xp1]"
    foreach group [$root selectNodes $xp1] {
        set groupid [$group @n]
        set groupid [write::GetWriteGroupName $groupid]
        set condid [[$group parent] @n]

        set ini $BuoyancyConditions($groupid,initial)
        set end $BuoyancyConditions($groupid,final)
        W "$condid $groupid $ini $end"
        if {$ini == -1} {
            ::write::writeGroupSubModelPart $condid $groupid "Nodes"
        } else {
            ::write::writeGroupSubModelPart $condid $groupid "Conditions" [list $ini $end]
        }
    }
}

Buoyancy::write::Init
