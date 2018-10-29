namespace eval Buoyancy::write {
    variable writeAttributes
}

proc Buoyancy::write::Init { } {    
    Fluid::write::Init
}

# Events
proc Buoyancy::write::writeModelPartEvent { } {
    # Validation
    set err [Validate]
    if {$err ne ""} {error $err}

    Fluid::write::Init
    Fluid::write::InitConditionsMap

    # Init data
    write::initWriteConfiguration [Fluid::write::GetAttributes]

    # Headers
    write::writeModelPartData
    Fluid::write::writeProperties

    # Materials
    write::writeMaterials [Fluid::write::GetAttribute validApps]

    # Nodal coordinates (1: Print only Fluid nodes <inefficient> | 0: the whole mesh <efficient>)
    if {[Fluid::write::GetAttribute writeCoordinatesByGroups]} {write::writeNodalCoordinatesOnParts} {write::writeNodalCoordinates}

    # Element connectivities (Groups on FLParts)
    write::writeElementConnectivities
    
    # Nodal conditions and conditions
    Fluid::write::writeConditions
    
    # SubmodelParts
    Fluid::write::writeMeshes
    write::writeNodalConditions [ConvectionDiffusion::write::GetAttribute nodal_conditions_un]
    Buoyancy::write::writeSubModelParts

    # Boussinesq nodes
    Buoyancy::write::writeBoussinesqSubModelPart
    
    # Custom SubmodelParts
    #write::writeBasicSubmodelParts [Fluid::write::getLastConditionId]
}
proc Buoyancy::write::writeCustomFilesEvent { } {
    # Materials
    WriteMaterialsFile

    # Main python script
    set orig_name "MainKratos.py"
    write::CopyFileIntoModel [file join "python" $orig_name ]
}

proc Buoyancy::write::Validate {} {
    set err ""
    
    return $err
}

proc Buoyancy::write::WriteMaterialsFile { } {
    write::writePropertiesJsonFile [GetAttribute parts_un] "BuoyancyMaterials.json" "False"
}

proc Buoyancy::write::writeSubModelParts { } {
    set BCUN "CNVDFFBC"
    
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

proc Buoyancy::write::writeBoussinesqSubModelPart { } {
    set groupid "_Boussinesq_hidden_"
    GiD_Groups create $groupid
    GiD_EntitiesGroups assign $groupid nodes [GiD_Mesh list node]
    ::write::writeGroupSubModelPart Boussinesq $groupid "Nodes"
    GiD_Groups delete $groupid
}


proc Buoyancy::write::GetAttribute {att} {
    return [Fluid::write::GetAttribute $att]
}

proc Buoyancy::write::GetAttributes {} {
    return [Fluid::write::GetAttributes]
}

proc Buoyancy::write::AddAttributes {configuration} {
    variable writeAttributes
    set writeAttributes [dict merge $writeAttributes $configuration]
}

proc Buoyancy::write::AddValidApps {appid} {
    AddAttribute validApps $appid
}

Buoyancy::write::Init