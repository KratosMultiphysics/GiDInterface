namespace eval MPM::write {
    variable writeAttributes
    variable ConditionsDictGroupIterators
}

proc MPM::write::Init { } {
    # Namespace variables inicialization
    variable ConditionsDictGroupIterators
    set ConditionsDictGroupIterators [dict create]
    SetAttribute parts_un MPMParts
    SetAttribute nodal_conditions_un MPMNodalConditions
    SetAttribute conditions_un MPMLoads
    SetAttribute properties_location json 
    # SetAttribute conditions_un FLBC
    # SetAttribute materials_un EMBFLMaterials
    # SetAttribute writeCoordinatesByGroups 0
    # SetAttribute validApps [list "MPM"]
    SetAttribute main_script_file "KratosParticle.py"
    SetAttribute materials_file "ParticleMaterials.json"
}

# Events
proc MPM::write::writeModelPartEvent { } {
    write::initWriteConfiguration [Structural::write::GetAttributes]
    write::initWriteConfiguration [GetAttributes]

    MPM::write::UpdateMaterials
    
    set filename [Kratos::GetModelName]
    
    ## Grid MPDA ##
    # Headers
    write::writeModelPartData
    write::WriteString "Begin Properties 0"
    write::WriteString "End Properties"

    # Nodal coordinates 
    write::writeNodalCoordinates

    # Grid element connectivities
    writeGridConnectivities
    
    # Write conditions
    writeConditions

    # Write Submodelparts
    writeSubmodelparts grid

    write::CloseFile
    write::RenameFileInModel "$filename.mdpa" "${filename}_Grid.mdpa"

    ## Body MDPA ##
    write::OpenFile "${filename}_Body.mdpa"

    # Headers
    write::writeModelPartData
    write::WriteString "Begin Properties 0"
    write::WriteString "End Properties"

    # Nodal coordinates
    writeBodyNodalCoordinates

    # Body element connectivities
    writeBodyElementConnectivities

    # Write Submodelparts
    writeSubmodelparts particles

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

proc MPM::write::writeConditions { } {

    variable ConditionsDictGroupIterators
    set ConditionsDictGroupIterators [write::writeConditions [GetAttribute conditions_un] ]
}
proc MPM::write::writeSubmodelparts { type } {

    set grid_elements [list GRID2D GRID3D]

    set xp1 "[spdAux::getRoute [GetAttribute parts_un]]/group"
    set body_groups [list ]
    foreach gNode [[customlib::GetBaseRoot] selectNodes $xp1] {
        set elem [write::getValueByNode [$gNode selectNodes ".//value\[@n='Element'\]"] ]
        if {$type eq "grid"} {
            if {$elem in $grid_elements} {
                write::writeGroupSubModelPart Parts [get_domnode_attribute $gNode n] "Elements"
            }
        } else {
            if {$elem ni $grid_elements} {
                write::writeGroupSubModelPart Parts [get_domnode_attribute $gNode n] "Elements"
            }
        }
    }
    
    if {$type eq "grid"} {
        # Write the boundary conditions submodelpart
        write::writeNodalConditions [GetAttribute nodal_conditions_un]
        
        # A Condition y a meshes-> salvo lo que no tenga topologia
        writeLoads
    }
}
proc MPM::write::writeLoads { } {
    variable ConditionsDictGroupIterators
    set root [customlib::GetBaseRoot]
    set xp1 "[spdAux::getRoute [GetAttribute conditions_un]]/condition/group"
    foreach group [$root selectNodes $xp1] {
        set groupid [$group @n]
        set groupid [write::GetWriteGroupName $groupid]
        #W "Writing mesh of Load $groupid"
        if {$groupid in [dict keys $ConditionsDictGroupIterators]} {
            ::write::writeGroupSubModelPart [[$group parent] @n] $groupid "Conditions" [dict get $ConditionsDictGroupIterators $groupid]
        } else {
            ::write::writeGroupSubModelPart [[$group parent] @n] $groupid "nodal"
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
