namespace eval ::Buoyancy::write {
    namespace path ::Buoyancy::write
    Kratos::AddNamespace [namespace current]

    variable writeAttributes
}

proc ::Buoyancy::write::Init { } {
    # Start Fluid write variables
    # Add thermal unique names to Fluid write variables
    Fluid::write::SetAttribute thermal_bc_un [ConvectionDiffusion::write::GetAttribute conditions_un]
    Fluid::write::SetAttribute thermal_initial_cnd_un [ConvectionDiffusion::write::GetAttribute nodal_conditions_un]

}

# Events
proc ::Buoyancy::write::writeModelPartEvent { } {
    # Validation
    set err [Validate]
    if {$err ne ""} {error $err}

    ::Fluid::write::Init
    
    ::Fluid::write::writeModelPartEvent

    # Write Boussinesq submodel part as nodals
    ::Buoyancy::write::writeBoussinesqSubModelPart

}

proc ::Buoyancy::write::writeCustomFilesEvent { } {
    # Materials
    Buoyancy::write::WriteMaterialsFile True
    write::SetConfigurationAttribute main_launch_file [ConvectionDiffusion::write::GetAttribute main_launch_file]
}

proc ::Buoyancy::write::Validate {} {
    set err ""
    return $err
}

proc ::Buoyancy::write::WriteMaterialsFile {{write_const_law True} {include_modelpart_name True} } {
    # Note: This will generate 2 quasi identical files for materials. The difference is the model_part_name

    # Write fluid material file
    Fluid::write::WriteMaterialsFile $write_const_law $include_modelpart_name

    # Write Buoyancy materials file
    set model_part_name ""
    if {[write::isBooleanTrue $include_modelpart_name]} {set model_part_name [GetModelPartName]}
    
    set mats [write::getPropertiesJson [GetAttribute parts_un] $write_const_law $model_part_name]
    # keep only first entry
    set clear_mat [dict get $mats properties]
    set clear_mat [lindex $clear_mat 0]
    dict set clear_mat model_part_name ThermalModelPart
    set clear_mat [dict create properties [list $clear_mat]]
    write::writePropertiesJsonFileDone "BuoyancyMaterials.json" $clear_mat
}

proc ::Buoyancy::write::writeSubModelParts { } {
    set BCUN [GetAttribute thermal_bc_un]

    set root [customlib::GetBaseRoot]
    set xp1 "[spdAux::getRoute $BCUN]/condition/group"
    foreach group [$root selectNodes $xp1] {
        set groupid [$group @n]
        set groupid [write::GetWriteGroupName $groupid]
        set condid [[$group parent] @n]
        set cond [::Model::getCondition $condid]

        if {![$cond hasTopologyFeatures]} {
            ::write::writeGroupSubModelPart $condid $groupid "Nodes"
        } else {
            ::write::writeGroupSubModelPartByUniqueId $condid $groupid $Fluid::write::FluidConditionMap "Conditions"
            #::write::writeGroupSubModelPart $condid $groupid "Conditions" [list $ini $end]
        }
    }
}

proc ::Buoyancy::write::writeBoussinesqSubModelPart { } {
    set groupid "_Boussinesq_hidden_"
    GiD_Groups create $groupid
    GiD_EntitiesGroups assign $groupid nodes [GiD_Mesh list node]
    ::write::writeGroupSubModelPartAsGeometry $groupid
    GiD_Groups delete $groupid
}

proc ::Buoyancy::write::GetModelPartName { } {
    return [Fluid::GetWriteProperty model_part_name]
}

proc ::Buoyancy::write::GetAttribute {att} {
    return [Fluid::write::GetAttribute $att]
}

proc ::Buoyancy::write::GetAttributes {} {
    return [Fluid::write::GetAttributes]
}

proc ::Buoyancy::write::AddAttributes {configuration} {
    variable writeAttributes
    set writeAttributes [dict merge $writeAttributes $configuration]
}

proc ::Buoyancy::write::AddValidApps {appid} {
    AddAttribute validApps $appid
}
