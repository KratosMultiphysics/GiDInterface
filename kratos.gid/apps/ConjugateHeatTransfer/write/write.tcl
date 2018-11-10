namespace eval ConjugateHeatTransfer::write {
    # Namespace variables declaration
    variable ConjugateHeatTransferConditions
    variable writeCoordinatesByGroups
    variable writeAttributes
}

proc ConjugateHeatTransfer::write::Init { } {
    # Namespace variables inicialization
    variable ConjugateHeatTransferConditions
    set ConjugateHeatTransferConditions(temp) 0
    unset ConjugateHeatTransferConditions(temp)

    SetAttribute main_script_file "KratosConjugateHeatTransfer.py"
    SetAttribute materials_file "ConjugateHeatTransferMaterials.json"
    SetAttribute properties_location json
    SetAttribute model_part_name ThermalModelPart
}

# Events
proc ConjugateHeatTransfer::write::writeModelPartEvent { } {
    # Validation
    set err [Validate]
    if {$err ne ""} {error $err}
    
    set filename "[file tail [GiD_Info project ModelName]]"

    # Buoyancy mdpa
    Buoyancy::write::Init
    Fluid::write::SetAttribute thermal_bc_un Buoyancy_CNVDFFBC
    Fluid::write::SetAttribute thermal_initial_cnd_un Buoyancy_CNVDFFNodalConditions
    Fluid::write::SetCoordinatesByGroups 1
    write::writeAppMDPA Buoyancy
    write::RenameFileInModel "$filename.mdpa" "${filename}_Buoyancy.mdpa"
    
    # Convection diffusion mdpa
    ConvectionDiffusion::write::Init
    ConvectionDiffusion::write::SetCoordinatesByGroups 1
    write::writeAppMDPA ConvectionDiffusion
    write::RenameFileInModel "$filename.mdpa" "${filename}_ConvectionDiffusion.mdpa"
}
proc ConjugateHeatTransfer::write::writeCustomFilesEvent { } {
    # Materials
    WriteMaterialsFile

    # Main python script
    set orig_name [GetAttribute main_script_file]
    write::CopyFileIntoModel [file join "python" $orig_name ]
    write::RenameFileInModel $orig_name "MainKratos.py"
}

proc ConjugateHeatTransfer::write::Validate {} {
    set err ""    
    set root [customlib::GetBaseRoot]

    return $err
}


proc ConjugateHeatTransfer::write::WriteMaterialsFile { } {
    write::writePropertiesJsonFile [GetAttribute parts_un] [GetAttribute materials_file] "False"
}


proc ConjugateHeatTransfer::write::GetAttribute {att} {
    variable writeAttributes
    return [dict get $writeAttributes $att]
}

proc ConjugateHeatTransfer::write::GetAttributes {} {
    variable writeAttributes
    return $writeAttributes
}

proc ConjugateHeatTransfer::write::SetAttribute {att val} {
    variable writeAttributes
    dict set writeAttributes $att $val
}

proc ConjugateHeatTransfer::write::AddAttribute {att val} {
    variable writeAttributes
    dict lappend writeAttributes $att $val
}

proc ConjugateHeatTransfer::write::AddAttributes {configuration} {
    variable writeAttributes
    set writeAttributes [dict merge $writeAttributes $configuration]
}

proc ConjugateHeatTransfer::write::AddValidApps {appid} {
    AddAttribute validApps $appid
}

proc ConjugateHeatTransfer::write::SetCoordinatesByGroups {value} {
    SetAttribute writeCoordinatesByGroups $value
}

ConjugateHeatTransfer::write::Init
