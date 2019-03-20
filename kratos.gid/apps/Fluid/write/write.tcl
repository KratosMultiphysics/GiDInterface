namespace eval Fluid::write {
    # Namespace variables declaration
    variable writeCoordinatesByGroups
    variable writeAttributes
    variable FluidConditionMap
}

proc Fluid::write::Init { } {
    # Namespace variables inicialization

    SetAttribute parts_un FLParts
    SetAttribute nodal_conditions_un FLNodalConditions
    SetAttribute conditions_un FLBC
    SetAttribute materials_un FLMaterials
    SetAttribute results_un FLResults
    SetAttribute drag_un FLDrags
    SetAttribute time_parameters_un FLTimeParameters
    SetAttribute writeCoordinatesByGroups 0
    SetAttribute validApps [list "Fluid"]
    SetAttribute main_script_file "KratosFluid.py"
    SetAttribute materials_file "FluidMaterials.json"
    SetAttribute properties_location "mdpa"
    SetAttribute model_part_name "FluidModelPart"
    SetAttribute output_model_part_name "fluid_computational_model_part"
}

# Events
proc Fluid::write::writeModelPartEvent { } {
    # Validation
    set err [Validate]
    if {$err ne ""} {error $err}
    
    InitConditionsMap

    # Init data
    write::initWriteConfiguration [GetAttributes]

    # Headers
    write::writeModelPartData
    writeProperties

    # Materials
    write::writeMaterials [GetAttribute validApps]

    # Nodal coordinates (1: Print only Fluid nodes <inefficient> | 0: the whole mesh <efficient>)
    if {[GetAttribute writeCoordinatesByGroups]} {write::writeNodalCoordinatesOnParts} {write::writeNodalCoordinates}

    # Element connectivities (Groups on FLParts)
    write::writeElementConnectivities
    
    # Nodal conditions and conditions
    writeConditions
    
    # SubmodelParts
    writeMeshes
    
    # Custom SubmodelParts
    #write::writeBasicSubmodelParts
    unset Fluid::write::FluidConditionMap
}
proc Fluid::write::writeCustomFilesEvent { } {
    # Materials file TODO -> Python script must read from here
    #write::writePropertiesJsonFile [GetAttribute parts_un] [GetAttribute materials_file]

    # Main python script
    set orig_name [GetAttribute main_script_file]
    write::CopyFileIntoModel [file join "python" $orig_name ]
    write::RenameFileInModel $orig_name "MainKratos.py"
}

proc Fluid::write::Validate {} {
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
proc Fluid::write::writeProperties { } {
    # Begin Properties
    write::WriteString "Begin Properties 0"
    write::WriteString "End Properties"
    write::WriteString ""
}

proc Fluid::write::writeConditions { } {
    writeBoundaryConditions
    writeDrags
}

proc Fluid::write::writeBoundaryConditions { } {
    variable FluidConditionMap

    # Prepare the groups to print
    set BCUN [GetAttribute conditions_un]
    set root [customlib::GetBaseRoot]
    set xp1 "[spdAux::getRoute $BCUN]/condition/group"
    set grouped_conditions [list ]
    set groups [list ]
    foreach group [$root selectNodes $xp1] {
        set group_id [$group @n]
        if {[[Model::getCondition [[$group parent] @n]] getAttribute "Interval"] ne "False"} {
            set group_id [GiD_Groups get parent $group_id]
        }
        lappend groups $group_id
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
    write::writeGroupConditionByUniqueId $skin_group_name $kname $nnodes 0 $Fluid::write::FluidConditionMap
    
    # Clean
    GiD_Groups delete $skin_group_name
}

proc Fluid::write::writeDrags { } {
    lappend ::Model::NodalConditions [::Model::NodalCondition new Drag]
    write::writeNodalConditions [GetAttribute drag_un]
    Model::ForgetNodalCondition Drag
}

proc Fluid::write::writeMeshes { } {
    write::writePartSubModelPart
    write::writeNodalConditions [GetAttribute nodal_conditions_un]
    writeConditionsMesh
    #writeSkinMesh
}

proc Fluid::write::writeConditionsMesh { } {
    
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

# proc Fluid::write::writeSkinMesh { } {
#     variable FluidConditions
    
#     set root [customlib::GetBaseRoot]
#     set xp1 "[spdAux::getRoute [GetAttribute conditions_un]]/condition/group"
#     #W "Conditions $xp1 [$root selectNodes $xp1]"
#     set listiniend [list ]
#     set listgroups [list ]
#     foreach group [$root selectNodes $xp1] {
#         set groupid [$group @n]
#         set groupid [write::GetWriteGroupName $groupid]
#         set ini $FluidConditions($groupid,initial)
#         set end $FluidConditions($groupid,final)
#         lappend listiniend $ini $end
#         lappend listgroups $groupid
#     }
#     set skinconfgroup "SKINCONDITIONS"
#     if {[GiD_Groups exist $skinconfgroup]} {GiD_Groups delete $skinconfgroup}
#     GiD_Groups create $skinconfgroup
#     GiD_Groups edit state $skinconfgroup hidden
#     foreach group $listgroups {
#         GiD_EntitiesGroups assign $skinconfgroup nodes [GiD_EntitiesGroups get $group nodes]
#     }
#     ::write::writeGroupSubModelPart EXTRA $skinconfgroup "Conditions" $listiniend
#  }

# proc Fluid::write::CheckClosedVolume {} {
#     variable BCUN
#     set isclosed 1

#     set root [customlib::GetBaseRoot]
#     set xp1 "[spdAux::getRoute [GetAttribute conditions_un]]/condition/group"

#     set listgroups [list ]
#     foreach group [$root selectNodes $xp1] {
#         set groupid [$group @n]
#         set conditionName [[$group parent] @n]
#         set cond [::Model::getCondition $conditionName]
#         if {[$cond getAttribute "SkinConditions"] eq "True"} {
#             set surfaces [GiD_EntitiesGroups get $groupid surfaces]
#             foreach surf $surfaces {
#                 set linesraw [GiD_Geometry get surface $surf]
#                 set nlines [lindex $linesraw 2]
#                 set linespairs [lrange $linesraw 9 [expr 8 + $nlines]]
#                 foreach pair $linespairs {
#                     set lid [lindex $pair 0]
#                     incr usedsurfaceslines($lid)
#                 }
#             }
#         }
#     }
#     foreach lid [array names usedsurfaceslines] {
#         if {$usedsurfaceslines($lid) ne "2"} {set isclosed 0;}
#     }
#     return $isclosed
# }



proc Fluid::write::InitConditionsMap { {map "" } } {
    
    variable FluidConditionMap
    if {$map eq ""} {
        set FluidConditionMap [objarray new intarray [expr [GiD_Info Mesh MaxNumElements] +1] 0]
    } {
        set FluidConditionMap $map
    }
}
proc Fluid::write::FreeConditionsMap { } {
    
    variable FluidConditionMap
    unset FluidConditionMap
}

proc Fluid::write::GetAttribute {att} {
    variable writeAttributes
    return [dict get $writeAttributes $att]
}

proc Fluid::write::GetAttributes {} {
    variable writeAttributes
    return $writeAttributes
}

proc Fluid::write::SetAttribute {att val} {
    variable writeAttributes
    dict set writeAttributes $att $val
}

proc Fluid::write::AddAttribute {att val} {
    variable writeAttributes
    dict lappend writeAttributes $att $val
}

proc Fluid::write::AddAttributes {configuration} {
    variable writeAttributes
    set writeAttributes [dict merge $writeAttributes $configuration]
}

proc Fluid::write::AddValidApps {appid} {
    AddAttribute validApps $appid
}

proc Fluid::write::SetCoordinatesByGroups {value} {
    SetAttribute writeCoordinatesByGroups $value
}

Fluid::write::Init
