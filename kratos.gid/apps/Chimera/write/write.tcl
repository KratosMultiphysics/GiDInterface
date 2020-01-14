namespace eval Chimera::write {
    variable writeAttributes
    
    variable patches
    variable inner_boundaries
    variable ConditionMap
}

proc Chimera::write::Init { } {
    # Namespace variables inicialization
    variable writeAttributes
    set writeAttributes [Fluid::write::GetAttributes]
    
    SetAttribute chim_parts_un ChimParts
    SetAttribute writeCoordinatesByGroups 1
    SetAttribute validApps [list "Fluid" "Chimera"]
}

# Events
proc Chimera::write::writeModelPartEvent { } {
    # Write the background mesh as the fluid
    Fluid::write::writeModelPartEvent
    write::CloseFile

    
    InitConditionsMap
    
    # Write the patches as independent mdpa
    Chimera::write::writePatches
    
    # Clean
    unset Chimera::write::ConditionMap
}

proc Chimera::write::writePatches { } {
    set iter $Fluid::write::last_condition_iterator
    set condid ChimeraInternalBoundary${Model::SpatialDimension}
    set ConditionMap [objarray new intarray [expr [GiD_Info Mesh MaxNumElements] +1] 0]
    foreach patch [Chimera::write::GetPatchParts] {
        set group_id [get_domnode_attribute $patch n]
        set patch_name [write::GetWriteGroupName $group_id]
        # New file for each patch
        write::OpenFile ${patch_name}.mdpa
        # Nodes
        write::writeNodalCoordinatesOnGroups [list $group_id]
        # Elements 
        write::writeGroupElementConnectivities $patch ChimeraPatch$Model::SpatialDimension
        # Internal patch boundary Conditions 
        set internal_boundaries_list [Chimera::write::GetInternalBoundaries $patch_name]
        foreach internal_boundary_group $internal_boundaries_list {
            set iter [write::writeGroupNodeConditionByUniqueId $internal_boundary_group $condid $iter $Chimera::write::ConditionMap]
        }
        # Patch Submodelpart
        ::write::writeGroupSubModelPartByUniqueId "Patch" $group_id "" "Elements"
        # Internal patch boundary Submodelparts
        foreach internal_boundary_group $internal_boundaries_list {
            ::write::writeGroupSubModelPartByUniqueId $condid [$internal_boundary_group @n] $Chimera::write::ConditionMap "Conditions"
        }
        # End file
        write::CloseFile
    }
}

proc Chimera::write::GetPatchParts { {what "xml"} } {
    set root [customlib::GetBaseRoot]
    set xp "[spdAux::getRoute [GetAttribute chim_parts_un]]/group"
    set xml_nodes [$root selectNodes $xp]
    if {$what eq "xml"} {
        return $xml_nodes
    } else {
        set names [list ]
        foreach patch $nodes {
            lappend names [get_domnode_attribute $patch name]
        }
        return $names
    }
}

proc Chimera::write::GetInternalBoundaries { {patch_group_id ""} {what "xml"}  } {
    # Empty means all
    set all 0
    if {$patch_group_id eq ""} {
        set all 1
    }
    set name ChimeraInternalBoundary${Model::SpatialDimension}
    set un [GetAttribute conditions_un]
    set xp "[spdAux::getRoute $un]/condition\[@n = '$name'\]/group" 
    
    set internal_boundaries_list [list ]
    set root [customlib::GetBaseRoot]
    foreach cnd_group [$root selectNodes $xp] {
        set cnd_group_name [get_domnode_attribute $cnd_group n]
        
        if {$what eq "xml"} {
            set gr $cnd_group
        } else {
            set gr [write::GetWriteGroupName $cnd_group_name]
        }

        if {$all} {
            lappend internal_boundaries_list $gr
        } else {
            set first_node [objarray get [GiD_EntitiesGroups get $cnd_group_name node] 0]
            set affected_groups [GiD_EntitiesGroups entity_groups nodes $first_node]
            if {$patch_group_id in $affected_groups} {
                lappend internal_boundaries_list $gr
            }
            # set part_names [Fluid::write::GetFluidPartGroups]
            # set patch_names [Chimera::write::GetPatchParts names]
            # foreach group $affected_groups {
            #     if {$group ni $part_names} {
            #         if {$group ni $patch_names} {
            #             if 
            #         }
            #     }
            # }
        }
    }
    return $internal_boundaries_list
}

proc Chimera::write::writeCustomFilesEvent { } {
    write::CopyFileIntoModel "python/KratosFluid.py"
    write::RenameFileInModel "KratosFluid.py" "MainKratos.py"
}

proc Chimera::write::InitConditionsMap { {map "" } } {

    variable ConditionMap
    if {$map eq ""} {
        set ConditionMap [objarray new intarray [expr [GiD_Info Mesh MaxNumElements] +1] 0]
    } {
        set ConditionMap $map
    }
}
proc Chimera::write::FreeConditionsMap { } {

    variable ConditionMap
    unset ConditionMap
}


# Mandatory - Attribute handler
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
