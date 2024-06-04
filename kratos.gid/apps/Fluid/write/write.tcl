namespace eval ::Fluid::write {
    namespace path ::Fluid
    Kratos::AddNamespace [namespace current]
    
    # Namespace variables declaration
    variable writeCoordinatesByGroups
    variable writeAttributes
    variable FluidConditionMap
    # after regular conditions are written, we need this number in order to print the custom submodelpart conditions
    # only if are applied over things that are not in the skin
    variable last_condition_iterator
}

proc ::Fluid::write::Init { } {
    # Namespace variables inicialization
    SetAttribute parts_un [::Fluid::GetUniqueName parts]
    SetAttribute nodal_conditions_un [::Fluid:::GetUniqueName nodal_conditions]
    SetAttribute conditions_un [::Fluid::GetUniqueName conditions]
    SetAttribute materials_un [::Fluid::GetUniqueName materials]
    SetAttribute results_un [::Fluid::GetUniqueName results]
    SetAttribute drag_un [::Fluid::GetUniqueName drag]
    SetAttribute time_parameters_un [::Fluid::GetUniqueName time_parameters]
    
    SetAttribute writeCoordinatesByGroups [::Fluid::GetWriteProperty coordinates]
    SetAttribute validApps [list "Fluid"]
    SetAttribute main_launch_file [::Fluid::GetAttribute main_launch_file]
    SetAttribute materials_file [::Fluid::GetWriteProperty materials_file]
    SetAttribute properties_location [::Fluid::GetWriteProperty properties_location]
    SetAttribute model_part_name [::Fluid::GetWriteProperty model_part_name]
    SetAttribute output_model_part_name [::Fluid::GetWriteProperty output_model_part_name]
    SetAttribute write_mdpa_mode [::Fluid::GetWriteProperty write_mdpa_mode]
    # Only write as geometries if the app says it AND the user allows it
    # Note: Fluid will enable it but most of the apps that derive from Fluid are not ready for it
    # Also user can disable it by setting the variable experimental_write_geometries to 0 in the preferences window
    set write_geometries_enabled 0
    if {[info exists Kratos::kratos_private(experimental_write_geometries)] && $Kratos::kratos_private(experimental_write_geometries)>0} {set write_geometries_enabled 1}
    if {[GetAttribute write_mdpa_mode] eq "geometries" && $write_geometries_enabled ne 1} {
        SetAttribute write_mdpa_mode "entities"
    }
    
    variable last_condition_iterator
    set last_condition_iterator 0
}

# MDPA write event
proc ::Fluid::write::writeModelPartEvent { } {
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
    if {[GetAttribute writeCoordinatesByGroups] ne "all"} {write::writeNodalCoordinatesOnParts} {write::writeNodalCoordinates}

    if {[GetAttribute write_mdpa_mode] eq "geometries"} {
        # Write geometries
        # Get the list of groups in the spd
        set lista [::Fluid::xml::GetListOfSubModelParts]
        
        # Write the geometries
        set ret [::write::writeGeometryConnectivities $lista]
        
        # Write the submodelparts
        set grouped_conditions [dict create]
        foreach group $lista {
            # Some conditions should be grouped in the same submodelpart
            # Get condition 
            set condition_node [$group parent]
            # W "Condition node: $condition_node"
            set condition_name [$condition_node @n]
            # W "Condition name: $condition_name"
            set condition [Model::getCondition $condition_name]
            if {$condition ne "" && [$condition getGroupBy] eq "Condition"} {
                dict lappend grouped_conditions $condition [$group @n]
            } else {
                write::writeGroupSubModelPartAsGeometry [$group @n]
            }
        }

        # Write the grouped conditions
        foreach condition [dict keys $grouped_conditions] {
            set condition_name [$condition getName]
            set new_group_name "_HIDDEN_$condition_name"
            set groups [dict get $grouped_conditions $condition]
            set new_group [spdAux::MergeGroups $new_group_name $groups]
            write::writeGroupSubModelPartAsGeometry $new_group_name 
            GiD_Groups delete $new_group_name
        }

    } else {
        # Element connectivities (Groups on FLParts)
        write::writeElementConnectivities
        
        # Nodal conditions and conditions
        writeConditions
        
        # Custom SubmodelParts
        variable last_condition_iterator
        write::writeBasicSubmodelPartsByUniqueId $Fluid::write::FluidConditionMap $last_condition_iterator
        # SubmodelParts
        writeMeshes
        
        # Write custom blocks at the end of the file
        writeCustomBlocks
    }
    
    # Clean
    unset ::Fluid::write::FluidConditionMap
}

proc ::Fluid::write::writeCustomFilesEvent { } {
    # Write the fluid materials json file
    ::Fluid::write::WriteMaterialsFile
    write::SetConfigurationAttribute main_launch_file [GetAttribute main_launch_file]
}

# Custom files
proc ::Fluid::write::WriteMaterialsFile { {write_const_law True} {include_modelpart_name True} } {
    
    set model_part_name ""
    if {[write::isBooleanTrue $include_modelpart_name]} {set model_part_name [GetAttribute model_part_name]}
    write::writePropertiesJsonFileDone [GetAttribute materials_file] [Fluid::write::GetMaterialsFile $write_const_law $include_modelpart_name]
}
proc Fluid::write::GetMaterialsFile { {write_const_law True} {include_modelpart_name True} } {
    set model_part_name ""
    if {[write::isBooleanTrue $include_modelpart_name]} {set model_part_name [GetAttribute model_part_name]}
    set parts [write::getPropertiesJson [GetAttribute parts_un] $write_const_law $model_part_name]
    set base [dict create model_part_name [GetAttribute model_part_name] properties_id 0 Material null]
    set old_list [dict get $parts properties]
    set new_list [concat [list $base] $old_list]
    set result [dict create properties $new_list]
    return $result
}

proc ::Fluid::write::Validate {} {
    set err ""
    set root [customlib::GetBaseRoot]
    
    # Check only 1 part in Parts
    set xp1 "[spdAux::getRoute [GetAttribute parts_un]]/group"
    if {[llength [$root selectNodes $xp1]] ne 1} {
        set err "You must set one part in Parts.\n"
    }

    # if the user has selected MPI, check that the write is set to entities
    if {[write::getValue ParallelType] eq "MPI"} {
        if {[GetAttribute write_mdpa_mode] ne "entities"} {
            set err "You must set the write mode to entities when using MPI.\nCheck the Preferences window.\n"
        }
    }
    
    # Check closed volume
    #if {[CheckClosedVolume] ne 1} {
        #    append err "Check boundary conditions."
        #}
    return $err
}

# MDPA Blocks
proc ::Fluid::write::writeProperties { } {
    # Begin Properties
    write::WriteString "Begin Properties 0"
    write::WriteString "End Properties"
    write::WriteString ""
}

proc ::Fluid::write::writeConditions { } {
    writeBoundaryConditions
    writeDrags
}

proc ::Fluid::write::getFluidModelPartFilename { } {
    return [Kratos::GetModelName]
}

proc ::Fluid::write::writeBoundaryConditions { } {
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
    lassign [write::_getConditionDefaultName] kname nnodes
    set last_condition_iterator [write::writeGroupConditionByUniqueId $skin_group_name $kname $nnodes 0 $::Fluid::write::FluidConditionMap]
    
    # Clean
    GiD_Groups delete $skin_group_name
}

proc ::Fluid::write::_getConditionDefaultName { } {
    set is_quadratic [write::isquadratic]
    if {$::Model::SpatialDimension eq "3D"} {

        set nnodes 3
        if {$is_quadratic} {set nnodes 6}
        
        set kname SurfaceCondition3D${nnodes}N
    } {
        set nnodes 2
        if {$is_quadratic} {set nnodes 3}
        set kname LineCondition2D${nnodes}N
    }

    return [list $kname $nnodes]
}

proc ::Fluid::write::writeDrags { } {
    lappend ::Model::NodalConditions [::Model::NodalCondition new Drag]
    write::writeNodalConditions [GetAttribute drag_un]
    Model::ForgetNodalCondition Drag
}

proc ::Fluid::write::writeMeshes { } {
    write::writePartSubModelPart
    write::writeNodalConditions [GetAttribute nodal_conditions_un]
    writeConditionsMesh
    #writeSkinMesh
}

proc ::Fluid::write::writeConditionsMesh { } {
    
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
                ::write::writeGroupSubModelPartByUniqueId $condid $groupid $Fluid::write::FluidConditionMap "Conditions"
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
        write::writeConditionGroupedSubmodelPartsByUniqueId $condid $groups_dict $Fluid::write::FluidConditionMap
    }
}

# Overwrite this function to print something at the end of the mdpa
proc ::Fluid::write::writeCustomBlocks { } {
    
}

proc ::Fluid::write::InitConditionsMap { {map "" } } {
    
    variable FluidConditionMap
    if {$map eq ""} {
        set FluidConditionMap [objarray new intarray [expr [GiD_Info Mesh MaxNumElements] +1] 0]
    } {
        set FluidConditionMap $map
    }
}
proc ::Fluid::write::FreeConditionsMap { } {
    
    variable FluidConditionMap
    unset FluidConditionMap
}

proc ::Fluid::write::GetAttribute {att} {
    variable writeAttributes
    return [dict get $writeAttributes $att]
}

proc ::Fluid::write::GetAttributes {} {
    variable writeAttributes
    return $writeAttributes
}

proc ::Fluid::write::SetAttribute {att val} {
    variable writeAttributes
    dict set writeAttributes $att $val
}

proc ::Fluid::write::AddAttribute {att val} {
    variable writeAttributes
    dict lappend writeAttributes $att $val
}

proc ::Fluid::write::AddAttributes {configuration} {
    variable writeAttributes
    set writeAttributes [dict merge $writeAttributes $configuration]
}

proc ::Fluid::write::AddValidApps {appid} {
    AddAttribute validApps $appid
}

proc ::Fluid::write::SetCoordinatesByGroups {value} {
    SetAttribute writeCoordinatesByGroups $value
}


