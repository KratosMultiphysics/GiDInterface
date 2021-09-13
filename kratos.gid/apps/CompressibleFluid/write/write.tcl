namespace eval CompressibleFluid::write {
    # Namespace variables declaration
    variable writeCoordinatesByGroups
    variable writeAttributes
    variable FluidConditionMap
    # after regular conditions are written, we need this number in order to print the custom submodelpart conditions
    # only if are applied over things that are not in the skin
    variable last_condition_iterator
}

proc CompressibleFluid::write::Init { } {
    # Namespace variables inicialization

    SetAttribute parts_un CF_Parts
    SetAttribute nodal_conditions_un CF_NodalConditions
    SetAttribute conditions_un CF_BC
    SetAttribute materials_un CF_Materials
    SetAttribute results_un CF_Results
    SetAttribute drag_un CF_Drags
    SetAttribute time_parameters_un CF_TimeParameters
    SetAttribute writeCoordinatesByGroups 0
    SetAttribute validApps [list "Fluid"]
    SetAttribute main_script_file "KratosFluid.py"
    SetAttribute materials_file "FluidMaterials.json"
    SetAttribute properties_location json
    SetAttribute model_part_name "FluidModelPart"
    SetAttribute output_model_part_name "fluid_computational_model_part"
    variable last_condition_iterator
    set last_condition_iterator 0
}

# MDPA write event
proc CompressibleFluid::write::writeModelPartEvent { } {
    # Validation
    set err [Validate]
    if {$err ne ""} {error $err}

    InitConditionsMap

    # Init data
    write::initWriteConfiguration [GetAttributes]

    # Headers
    write::writeModelPartData
    writeProperties

    # Nodal coordinates (1: Print only Fluid nodes <inefficient> | 0: the whole mesh <efficient>)
    if {[GetAttribute writeCoordinatesByGroups]} {write::writeNodalCoordinatesOnParts} {write::writeNodalCoordinates}

    # Element connectivities (Groups on CF_Parts)
    write::writeElementConnectivities

    # Nodal conditions and conditions
    writeConditions

    # Custom SubmodelParts
    variable last_condition_iterator
    write::writeBasicSubmodelPartsByUniqueId  $CompressibleFluid::write::FluidConditionMap $last_condition_iterator
    
    # SubmodelParts
    writeMeshes

    # Clean
    unset CompressibleFluid::write::FluidConditionMap
}
proc CompressibleFluid::write::writeCustomFilesEvent { } {
    # Write the fluid materials json file
    CompressibleFluid::write::WriteMaterialsFile

    # Main python script
    set orig_name [GetAttribute main_script_file]
    write::CopyFileIntoModel [file join "python" $orig_name ]
    write::RenameFileInModel $orig_name "MainKratos.py"
}

# Custom files
proc CompressibleFluid::write::WriteMaterialsFile { {write_const_law True} {include_modelpart_name True} } {
    set model_part_name ""
    if {[write::isBooleanTrue $include_modelpart_name]} {set model_part_name [GetAttribute model_part_name]}
    write::writePropertiesJsonFile [GetAttribute parts_un] [GetAttribute materials_file] $write_const_law $model_part_name
}

proc CompressibleFluid::write::Validate {} {
    set err ""
    set root [customlib::GetBaseRoot]

    # Check only 1 part in Parts
    set xp1 "[spdAux::getRoute [GetAttribute parts_un]]/group"
    if {[llength [$root selectNodes $xp1]] ne 1} {
        set err "You must set one part in Parts.\n"
    }

    # Check closed volume
    #if {[CheckClosedVolume] ne 1} {
    #    append err "Check boundary conditions."
    #}
    return $err
}

# MDPA Blocks
proc CompressibleFluid::write::writeProperties { } {
    # Begin Properties
    write::WriteString "Begin Properties 0"
    write::WriteString "End Properties"
    write::WriteString ""
}

proc CompressibleFluid::write::writeConditions { } {
    writeBoundaryConditions
    writeDrags
}

proc CompressibleFluid::write::getFluidModelPartFilename { } {
    return [Kratos::GetModelName]
}

proc CompressibleFluid::write::writeBoundaryConditions { } {
    variable FluidConditionMap
    variable last_condition_iterator

    # Prepare the groups to print
    set BCUN [GetAttribute conditions_un]
    set root [customlib::GetBaseRoot]
    set xp1 "[spdAux::getRoute $BCUN]/condition/group"
    set grouped_conditions [list ]
    set groups [list ]
    foreach group [$root selectNodes $xp1] {
        set group_id [$group @n]
        set condition [Model::getCondition [[$group parent] @n]]
        if {[write::isBooleanTrue [$condition getAttribute SkinConditions]]} {
            if {[$condition getAttribute "Interval"] ne "False"} {
                set group_id [GiD_Groups get parent $group_id]
            }
            lappend groups $group_id
        }
    }
    set skin_group_name "_HIDDEN__SKIN_"
    if {[GiD_Groups exists $skin_group_name]} {GiD_Groups delete $skin_group_name}
    spdAux::MergeGroups $skin_group_name $groups

    # Write the conditions
    if {$::Model::SpatialDimension eq "3D"} {
        set kname SurfaceCondition3D3N
        set nnodes 3
    } {
        set kname LineCondition2D2N
        set nnodes 2
    }
    set last_condition_iterator [write::writeGroupConditionByUniqueId $skin_group_name $kname $nnodes 0 $CompressibleFluid::write::FluidConditionMap]

    # Clean
    GiD_Groups delete $skin_group_name
}

proc CompressibleFluid::write::writeDrags { } {
    lappend ::Model::NodalConditions [::Model::NodalCondition new Drag]
    write::writeNodalConditions [GetAttribute drag_un]
    Model::ForgetNodalCondition Drag
}

proc CompressibleFluid::write::writeMeshes { } {
    write::writePartSubModelPart
    write::writeNodalConditions [GetAttribute nodal_conditions_un]
    writeConditionsMesh
    #writeSkinMesh
}

proc CompressibleFluid::write::writeConditionsMesh { } {

    set root [customlib::GetBaseRoot]
    set xp1 "[spdAux::getRoute [GetAttribute conditions_un]]/condition/group"
    set grouped_conditions [list ]
    #W "Conditions $xp1 [$root selectNodes $xp1]"
    foreach group [$root selectNodes $xp1] {
        set groupid [$group @n]
        set groupid [write::GetWriteGroupName $groupid]
        set condid [[$group parent] @n]
        set cond [::Model::getCondition $condid]
        if {[$cond getGroupBy] eq "Condition"} {
            # Grouped conditions will be written later
            if {$condid ni $grouped_conditions} {
                lappend grouped_conditions $condid
            }
        } else {
            #W "$groupid $ini $end"
            if {![$cond hasTopologyFeatures]} {
                ::write::writeGroupSubModelPart $condid $groupid "Nodes"
            } else {
                ::write::writeGroupSubModelPartByUniqueId $condid $groupid $CompressibleFluid::write::FluidConditionMap "Conditions"
            }
        }
    }

    foreach condid $grouped_conditions {
        set xp "[spdAux::getRoute [GetAttribute conditions_un]]/condition\[@n='$condid'\]/group"
        set groups_dict [dict create ]
        foreach group [$root selectNodes $xp] {
            set groupid [get_domnode_attribute $group n]
            dict set groups_dict $groupid what "Conditions"
        }
        write::writeConditionGroupedSubmodelPartsByUniqueId $condid $groups_dict $CompressibleFluid::write::FluidConditionMap
    }
}

proc CompressibleFluid::write::InitConditionsMap { {map "" } } {

    variable FluidConditionMap
    if {$map eq ""} {
        set FluidConditionMap [objarray new intarray [expr [GiD_Info Mesh MaxNumElements] +1] 0]
    } {
        set FluidConditionMap $map
    }
}
proc CompressibleFluid::write::FreeConditionsMap { } {

    variable FluidConditionMap
    unset FluidConditionMap
}

proc CompressibleFluid::write::GetAttribute {att} {
    variable writeAttributes
    return [dict get $writeAttributes $att]
}

proc CompressibleFluid::write::GetAttributes {} {
    variable writeAttributes
    return $writeAttributes
}

proc CompressibleFluid::write::SetAttribute {att val} {
    variable writeAttributes
    dict set writeAttributes $att $val
}

proc CompressibleFluid::write::AddAttribute {att val} {
    variable writeAttributes
    dict lappend writeAttributes $att $val
}

proc CompressibleFluid::write::AddAttributes {configuration} {
    variable writeAttributes
    set writeAttributes [dict merge $writeAttributes $configuration]
}

proc CompressibleFluid::write::AddValidApps {appid} {
    AddAttribute validApps $appid
}

proc CompressibleFluid::write::SetCoordinatesByGroups {value} {
    SetAttribute writeCoordinatesByGroups $value
}

CompressibleFluid::write::Init
