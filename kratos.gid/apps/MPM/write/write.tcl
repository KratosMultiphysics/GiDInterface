namespace eval MPM::write {
    variable writeAttributes
    variable ConditionsDictGroupIterators
    variable RegisteredCustomBlock
}

proc MPM::write::Init { } {
    # Namespace variables inicialization
    variable ConditionsDictGroupIterators
    variable RegisteredCustomBlock
    set  RegisteredCustomBlock [list ]
    set ConditionsDictGroupIterators [dict create]
    SetAttribute writeCoordinatesByGroups 0
    SetAttribute parts_un MPMParts
    SetAttribute current_app "MPM"
    SetAttribute nodal_conditions_un MPMNodalConditions
    SetAttribute conditions_un MPMLoads
    SetAttribute properties_location json 
    SetAttribute results_un MPMResults
    SetAttribute conditions_un MPMLoads
    SetAttribute time_parameters_un MPMTimeParameters
    SetAttribute main_script_file "KratosParticle.py"
    SetAttribute materials_file "ParticleMaterials.json"
    SetAttribute model_part_name ""
    SetAttribute solution_type_un MPMSoluType
    SetAttribute solution_strategy_un MPMSolStrat
    SetAttribute analysis_type_un MPMAnalysisType
    SetAttribute scheme_un MPMScheme
    SetAttribute solution_strategy_parameters_un MPMStratParams
    SetAttribute mpm_grid_elements [list GRID2D GRID3D]
    # Reserved for interfaces
    SetAttribute mpm_grid_extra_conditions [list ]
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

    MPM::write::writeGridNodalCoordinates

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

    writeCustomBlock

    write::CloseFile
}

proc MPM::write::writeGridNodalCoordinates { } {
    set xp1 "[spdAux::getRoute [GetAttribute parts_un]]/group"
    set body_groups [list ]
    foreach gNode [[customlib::GetBaseRoot] selectNodes $xp1] {
        set elem [write::getValueByNode [$gNode selectNodes ".//value\[@n='Element'\]"] ]
        if {$elem in [GetAttribute mpm_grid_elements]} {
            lappend body_groups [$gNode @n]
        }
    }
    set xp1 "[spdAux::getRoute [GetAttribute conditions_un]]"
    set body_groups [list ]
    foreach condition [GetAttribute mpm_grid_extra_conditions] {
        foreach gNode [[customlib::GetBaseRoot] selectNodes "$xp1/condition\[@n='$condition'\]/group"] {
            lappend body_groups [$gNode @n]
        }
    }
    write::writeNodalCoordinatesOnGroups $body_groups
}

proc MPM::write::writeBodyNodalCoordinates { } {
    set xp1 "[spdAux::getRoute [GetAttribute parts_un]]/group"
    set body_groups [list ]
    foreach gNode [[customlib::GetBaseRoot] selectNodes $xp1] {
        set elem [write::getValueByNode [$gNode selectNodes ".//value\[@n='Element'\]"] ]
        if {$elem ni [GetAttribute mpm_grid_elements]} {
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
        if {$elem ni [GetAttribute mpm_grid_elements]} {
            write::writeGroupElementConnectivities $gNode $elem
        }
    }
}

proc MPM::write::writeGridConnectivities { } {
    set xp1 "[spdAux::getRoute [GetAttribute parts_un]]/group"
    foreach gNode [[customlib::GetBaseRoot] selectNodes $xp1] {
        set elem [write::getValueByNode [$gNode selectNodes ".//value\[@n='Element'\]"] ]
        if {$elem in [GetAttribute mpm_grid_elements]} {
            write::writeGroupElementConnectivities $gNode $elem
        }
    }
}

proc MPM::write::writeConditions { } {
    variable ConditionsDictGroupIterators
    set ConditionsDictGroupIterators [write::writeConditions [GetAttribute conditions_un] ]
}

proc MPM::write::writeSubmodelparts { type } {

    set grid_elements [GetAttribute mpm_grid_elements]

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

proc MPM::write::writeCustomBlock { } {
    variable RegisteredCustomBlock

    foreach method $RegisteredCustomBlock {
        catch {
            $method
        }
    }
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

proc MPM::write::GetLastConditionId { } {
    
    variable ConditionsDictGroupIterators
    set max 0
    foreach interval [dict values $ConditionsDictGroupIterators] {
        set candidate [lindex $interval end]
        if {$candidate > $max} {set max $candidate}
    }
    return $max
}

proc MPM::write::RegisterCustomBlockMethod { method } {
    variable RegisteredCustomBlock
    lappend RegisteredCustomBlock $method
}

MPM::write::Init
