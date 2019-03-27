namespace eval ConvectionDiffusion::write {
    # Namespace variables declaration
    variable ConvectionDiffusionConditions
    variable writeCoordinatesByGroups
    variable writeAttributes
}

proc ConvectionDiffusion::write::Init { } {
    # Namespace variables inicialization
    variable ConvectionDiffusionConditions
    set ConvectionDiffusionConditions(temp) 0
    unset ConvectionDiffusionConditions(temp)

    SetAttribute parts_un CNVDFFParts
    SetAttribute nodal_conditions_un CNVDFFNodalConditions
    SetAttribute conditions_un CNVDFFBC
    SetAttribute materials_un FLMaterials
    SetAttribute writeCoordinatesByGroups 0
    SetAttribute validApps [list "ConvectionDiffusion"]
    SetAttribute main_script_file "KratosConvectionDiffusion.py"
    SetAttribute materials_file "ConvectionDiffusionMaterials.json"
    SetAttribute properties_location json
    SetAttribute model_part_name ThermalModelPart
    SetAttribute output_model_part_name "thermal_computing_domain"
}

# Events
proc ConvectionDiffusion::write::writeModelPartEvent { } {
    # Validation
    set err [Validate]
    if {$err ne ""} {error $err}

    # Init data
    write::initWriteConfiguration [GetAttributes]

    # Headers
    write::writeModelPartData
    writeProperties

    # Materials (write materials in *.mdpa)
    # write::writeMaterials [GetAttribute validApps]

    # Nodal coordinates (1: Print only Fluid nodes <inefficient> | 0: the whole mesh <efficient>)
    if {[GetAttribute writeCoordinatesByGroups]} {write::writeNodalCoordinatesOnParts} {write::writeNodalCoordinates}

    # Element connectivities (Groups on CNVDFFParts)
    write::writeElementConnectivities
    
    # Nodal conditions and conditions
    writeConditions
    
    # SubmodelParts
    writeMeshes
    
    # Custom SubmodelParts
    write::writeBasicSubmodelParts [getLastConditionId]
}
proc ConvectionDiffusion::write::writeCustomFilesEvent { } {
    # Materials
    WriteMaterialsFile

    # Main python script
    set orig_name [GetAttribute main_script_file]
    write::CopyFileIntoModel [file join "python" $orig_name ]
    write::RenameFileInModel $orig_name "MainKratos.py"
}

proc ConvectionDiffusion::write::Validate {} {
    set err ""    
    set root [customlib::GetBaseRoot]

    return $err
}

proc ConvectionDiffusion::write::getLastConditionId { } { 
    variable ConvectionDiffusionConditions
    set top 1
    # Kratos::PrintArray ConvectionDiffusionConditions
    if {[array size ConvectionDiffusionConditions]} {
        foreach name [array names ConvectionDiffusionConditions] {
            set top [expr max($top,$ConvectionDiffusionConditions($name))]
        }
    }
    return $top
}

proc ConvectionDiffusion::write::WriteMaterialsFile { } {
    write::writePropertiesJsonFile [GetAttribute parts_un] [GetAttribute materials_file] "False"
}

# MDPA Blocks
proc ConvectionDiffusion::write::writeProperties { } {
    # Begin Properties
    write::WriteString "Begin Properties 0"
    write::WriteString "End Properties"
    write::WriteString ""
}

proc ConvectionDiffusion::write::writeConditions { } {
    writeBoundaryConditions
}

proc ConvectionDiffusion::write::writeBoundaryConditions { } {
    variable ConvectionDiffusionConditions
    set BCUN [GetAttribute conditions_un]

    # Write the conditions
    set dict_group_intervals [write::writeConditions $BCUN]

    set root [customlib::GetBaseRoot]
    set xp1 "[spdAux::getRoute $BCUN]/condition/group"
    set iter 1
    foreach group [$root selectNodes $xp1] {
        set condid [[$group parent] @n]
        set groupid [get_domnode_attribute $group n]
        set groupid [write::GetWriteGroupName $groupid]
        set cond [::Model::getCondition $condid]
        if {[$cond getAttribute SkinConditions]} {
            lassign [dict get $dict_group_intervals $groupid] ini fin
            set ConvectionDiffusionConditions($groupid,initial) $ini
            set ConvectionDiffusionConditions($groupid,final) $fin
            set ConvectionDiffusionConditions($groupid,SkinCondition) 1
            #W "ARRAY [array get ConvectionDiffusionConditions]"
        } else {
            set ConvectionDiffusionConditions($groupid,initial) -1
            set ConvectionDiffusionConditions($groupid,final) -1
            set ConvectionDiffusionConditions($groupid,SkinCondition) 0
        }
    }
}

proc ConvectionDiffusion::write::writeMeshes { } {
    write::writePartSubModelPart
    write::writeNodalConditions [GetAttribute nodal_conditions_un]
    writeConditionsMesh
}

proc ConvectionDiffusion::write::writeConditionsMesh { } {
    variable ConvectionDiffusionConditions
    
    set root [customlib::GetBaseRoot]
    set xp1 "[spdAux::getRoute [GetAttribute conditions_un]]/condition/group"
    set grouped_conditions [list ]
    #W "Conditions $xp1 [$root selectNodes $xp1]"
    foreach group [$root selectNodes $xp1] {
        set groupid [$group @n]
        set groupid [write::GetWriteGroupName $groupid]
        set condid [[$group parent] @n]
        if {[[::Model::getCondition $condid] getGroupBy] eq "Condition"} {
            # Grouped conditions will be written later
            if {$condid ni $grouped_conditions} {
                lappend grouped_conditions $condid
            }
        } else {
            set ini $ConvectionDiffusionConditions($groupid,initial)
            set end $ConvectionDiffusionConditions($groupid,final)
            #W "$groupid $ini $end"
            if {$ini == -1} {
                ::write::writeGroupSubModelPart $condid $groupid "Nodes"
            } else {
                ::write::writeGroupSubModelPart $condid $groupid "Conditions" [list $ini $end]
            }
        }
    }

    foreach condid $grouped_conditions {
        set xp "[spdAux::getRoute [GetAttribute conditions_un]]/condition\[@n='$condid'\]/group"
        set groups_dict [dict create ]
        foreach group [$root selectNodes $xp] {
            set groupid [get_domnode_attribute $group n]
            set ini $ConvectionDiffusionConditions($groupid,initial)
            set end $ConvectionDiffusionConditions($groupid,final)
            dict set groups_dict $groupid what "Conditions"
            dict set groups_dict $groupid iniend [list $ini $end]
        } 
        write::writeConditionGroupedSubmodelParts $condid $groups_dict
    }
}

proc ConvectionDiffusion::write::GetAttribute {att} {
    variable writeAttributes
    return [dict get $writeAttributes $att]
}

proc ConvectionDiffusion::write::GetAttributes {} {
    variable writeAttributes
    return $writeAttributes
}

proc ConvectionDiffusion::write::SetAttribute {att val} {
    variable writeAttributes
    dict set writeAttributes $att $val
}

proc ConvectionDiffusion::write::AddAttribute {att val} {
    variable writeAttributes
    dict lappend writeAttributes $att $val
}

proc ConvectionDiffusion::write::AddAttributes {configuration} {
    variable writeAttributes
    set writeAttributes [dict merge $writeAttributes $configuration]
}

proc ConvectionDiffusion::write::AddValidApps {appid} {
    AddAttribute validApps $appid
}

proc ConvectionDiffusion::write::SetCoordinatesByGroups {value} {
    SetAttribute writeCoordinatesByGroups $value
}

ConvectionDiffusion::write::Init
