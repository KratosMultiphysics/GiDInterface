namespace eval ::Buoyancy::write {
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

    # Start Fluid write variables
    Fluid::write::Init
    # Start Fluid write conditions map from scratch
    Fluid::write::InitConditionsMap

    # Init data
    write::initWriteConfiguration [Fluid::write::GetAttributes]

    # Headers
    write::writeModelPartData
    Fluid::write::writeProperties

    # Nodal coordinates (1: Print only Fluid nodes <inefficient> | 0: the whole mesh <efficient>)
    if {[Fluid::write::GetAttribute writeCoordinatesByGroups] ne "all"} {write::writeNodalCoordinatesOnParts} {write::writeNodalCoordinates}

    # Element connectivities (Groups on FLParts)
    write::writeElementConnectivities

    # Nodal conditions and conditions
    Fluid::write::writeConditions

    # SubmodelParts
    Fluid::write::writeMeshes
    write::writeNodalConditions [GetAttribute thermal_initial_cnd_un]
    Buoyancy::write::writeSubModelParts

    # Boussinesq nodes
    Buoyancy::write::writeBoussinesqSubModelPart

    # Custom SubmodelParts
    #write::writeBasicSubmodelParts [Fluid::write::getLastConditionId]
}

proc ::Buoyancy::write::writeCustomFilesEvent { } {
    # Materials
    Buoyancy::write::WriteMaterialsFile True

    # Main python script
    write::CopyFileIntoModel [file join "python" "MainKratos.py" ]
}

proc ::Buoyancy::write::Validate {} {
    set err ""

    return $err
}

proc ::Buoyancy::write::WriteMaterialsFile {{write_const_law True} {include_modelpart_name True} } {
    # Write fluid material file 
    Fluid::write::WriteMaterialsFile $write_const_law $include_modelpart_name

    # Write Buoyancy materials file
    set model_part_name ""
    if {[write::isBooleanTrue $include_modelpart_name]} {set model_part_name [GetModelPartName]}
    write::writePropertiesJsonFile [GetAttribute parts_un] "BuoyancyMaterials.json" $write_const_law $model_part_name
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
    ::write::writeGroupSubModelPart Boussinesq $groupid "Nodes"
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
