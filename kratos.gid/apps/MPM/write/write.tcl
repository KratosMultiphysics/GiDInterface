namespace eval MPM::write {
    variable writeAttributes
}

proc MPM::write::Init { } {
    # Namespace variables inicialization
    SetAttribute parts_un MPMParts
    SetAttribute nodal_conditions_un MPMNodalConditions
    # SetAttribute conditions_un FLBC
    # SetAttribute materials_un EMBFLMaterials
    # SetAttribute writeCoordinatesByGroups 0
    # SetAttribute validApps [list "MPM"]
    SetAttribute main_script_file "MainKratos.py"
    SetAttribute materials_file "ParticleMaterials.json"
}

# Events
proc MPM::write::writeModelPartEvent { } {
    write::initWriteConfiguration [GetAttributes]
    set filename "[file tail [GiD_Info project ModelName]]"
    
    write::processMaterials
    #MPM::write::UpdateMaterials

    ## Grid MPDA ##
    # Headers
    write::writeModelPartData
    write::WriteString "Begin Properties 0"
    write::WriteString "End Properties"
    
    # Materials
    write::writeMaterials

    # Nodal coordinates 
    write::writeNodalCoordinates

    writeGridConnectivities
    
    writeNodalDisplacement
    write::CloseFile
    write::RenameFileInModel "$filename.mdpa" "${filename}_Grid.mdpa"

    ## Body MDPA ##
    write::OpenFile "${filename}_Body.mdpa"

    # Headers
    write::writeModelPartData
    write::WriteString "Begin Properties 0"
    write::WriteString "End Properties"

    # Materials
    write::writeMaterials

    # Nodal coordinates
    writeBodyNodalCoordinates

    # Body element connectivities
    writeBodyElementConnectivities

    write::CloseFile
}

proc MPM::write::writeBodyNodalCoordinates { } {
    set xp1 "[spdAux::getRoute [GetAttribute parts_un]]/group"
    set body_groups [list ]
    foreach gNode [[customlib::GetBaseRoot] selectNodes $xp1] {
        set elem [write::getValueByNode [$gNode selectNodes ".//value\[@n='Element'\]"] ]
        if {$elem ni [list GRID2D GRID3D]} {
            lappend body_groups [$gNode @n]
        }
    }
    write::writeNodalCoordinatesOnGroups $body_groups
}

proc MPM::write::writeBodyElementConnectivities { } {
    set xp1 "[spdAux::getRoute [GetAttribute parts_un]]/group"
    set body_groups [list ]
    foreach gNode [[customlib::GetBaseRoot] selectNodes $xp1] {
        set elem [write::getValueByNode [$gNode selectNodes ".//value\[@n='Element'\]"] ]
        if {$elem ni [list GRID2D GRID3D]} {
            write::writeGroupElementConnectivities $gNode $elem
        }
    }
}

proc MPM::write::writeGridConnectivities { } {
    set xp1 "[spdAux::getRoute [GetAttribute parts_un]]/group"
    foreach gNode [[customlib::GetBaseRoot] selectNodes $xp1] {
        set elem [write::getValueByNode [$gNode selectNodes ".//value\[@n='Element'\]"] ]
        if {$elem in [list GRID2D GRID3D]} {
            write::writeGroupElementConnectivities $gNode $elem
        }
    }
}

proc MPM::write::writeNodalDisplacement { } {
    set xp1 "[spdAux::getRoute [GetAttribute nodal_conditions_un]]/condition\[@n='DISPLACEMENT'\]/group"
    foreach gNode [[customlib::GetBaseRoot] selectNodes $xp1] {
        set groupid [GiD_Groups get parent [$gNode @n] ]
        foreach dim [list X Y Z] {
            set enabled [write::getValueByNode [$gNode selectNodes ".//value\[@n='Enabled_$dim'\]"]]
            if {[write::isBooleanTrue $enabled]} {
                set disp [write::getValueByNode [$gNode selectNodes ".//value\[@n='Displacement$dim'\]"]]
                write::WriteString "Begin NodalData DISPLACEMENT_$dim"
                GiD_WriteCalculationFile nodes [dict create $groupid  "%5d 1 $disp \n"]
                write::WriteString "End NodalData"
                write::WriteString ""
            }
        }
    }
}

proc MPM::write::writeCustomFilesEvent { } {
    # write::RenameFileInModel "ProjectParameters.json" "ProjectParameters.py"

    # Materials file
    write::writePropertiesJsonFile [GetAttribute parts_un] [GetAttribute materials_file]
    
    # Main python script
    set orig_name [GetAttribute main_script_file]
    write::CopyFileIntoModel [file join "python" $orig_name ]
    write::RenameFileInModel $orig_name "MainKratos.py"
}


proc MPM::write::UpdateMaterials { } {
    set matdict [write::getMatDict]
    foreach {mat props} $matdict {
        # Modificar la ley constitutiva
        dict set matdict $mat THICKNESS  1.0000E+00
        
        set xp1 "[spdAux::getRoute [GetAttribute parts_un]]/group\[@n='$mat'\]/value\[@n='THICKNESS'\]"
        set vNode [[customlib::GetBaseRoot] selectNodes $xp1] 
        if {$vNode ne ""} {
            dict set matdict $mat THICKNESS [write::getValueByNode $vNode]
        }
           
    }
    write::setMatDict $matdict
}

proc MPM::write::GetAttribute {att} {
    variable writeAttributes
    return [dict get $writeAttributes $att]
}

proc MPM::write::GetAttributes {} {
    variable writeAttributes
    return $writeAttributes
}

proc MPM::write::SetAttribute {att val} {
    variable writeAttributes
    dict set writeAttributes $att $val
}

MPM::write::Init
