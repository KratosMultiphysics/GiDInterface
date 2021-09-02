namespace eval ::ConjugateHeatTransfer::write {
    # Namespace variables declaration
    variable ConjugateHeatTransferConditions
    variable writeCoordinatesByGroups
    variable writeAttributes
    variable fluid_domain_solver_settings
    variable solid_domain_solver_settings
}

proc ::ConjugateHeatTransfer::write::Init { } {
    # Namespace variables initialization
    variable ConjugateHeatTransferConditions
    set ConjugateHeatTransferConditions(temp) 0
    unset ConjugateHeatTransferConditions(temp)

    SetAttribute main_script_file "KratosConjugateHeatTransfer.py"
    #SetAttribute materials_file "ConjugateHeatTransferMaterials.json"
    SetAttribute properties_location json
    SetAttribute model_part_name ThermalModelPart

    SetAttribute fluid_mdpa_suffix Fluid
    SetAttribute solid_mdpa_suffix Solid

    variable fluid_domain_solver_settings
    variable solid_domain_solver_settings
    set fluid_domain_solver_settings [dict create]
    set solid_domain_solver_settings [dict create]
}

# Events
proc ::ConjugateHeatTransfer::write::writeModelPartEvent { } {
    # Validation
    set err [Validate]
    if {$err ne ""} {error $err}
    
    set filename [Kratos::GetModelName]

    # Buoyancy mdpa
    Fluid::write::SetAttribute thermal_initial_cnd_un "Buoyancy_CNVDFFNodalConditions"
    Fluid::write::SetAttribute thermal_bc_un "Buoyancy_CNVDFFBC"
    write::writeAppMDPA Buoyancy
    write::RenameFileInModel "$filename.mdpa" "${filename}_[GetAttribute fluid_mdpa_suffix].mdpa"
    
    # Convection diffusion mdpa
    ConvectionDiffusion::write::Init
    ConvectionDiffusion::write::SetAttribute writeCoordinatesByGroups 1
    write::writeAppMDPA ConvectionDiffusion
    write::RenameFileInModel "$filename.mdpa" "${filename}_[GetAttribute solid_mdpa_suffix].mdpa"
}

proc ::ConjugateHeatTransfer::write::writeCustomFilesEvent { } {
    # Materials
    WriteMaterialsFile

    # Main python script
    set orig_name [GetAttribute main_script_file]
    write::CopyFileIntoModel [file join "python" $orig_name ]
    write::RenameFileInModel $orig_name "MainKratos.py"
}

proc ::ConjugateHeatTransfer::write::Validate {} {
    set err ""    
    set root [customlib::GetBaseRoot]

    return $err
}


proc ::ConjugateHeatTransfer::write::PrepareBuoyancy { } {
    Buoyancy::write::Init
    Fluid::write::SetAttribute thermal_bc_un Buoyancy_CNVDFFBC
    Fluid::write::SetAttribute thermal_initial_cnd_un Buoyancy_CNVDFFNodalConditions
    Fluid::write::SetCoordinatesByGroups 1
}

proc ::ConjugateHeatTransfer::write::WriteMaterialsFile { {write_const_law True} {include_modelpart_name True}  } {
    Buoyancy::write::WriteMaterialsFile $write_const_law $include_modelpart_name
    # ConvectionDiffusion::write::WriteMaterialsFile $write_const_law $include_modelpart_name
    ConvectionDiffusion::write::WriteMaterialsFile False $include_modelpart_name
}

# proc ::Buoyancy::write::GetModelPartName { } {
#     return FluidThermalModelPart
# }

proc ::ConjugateHeatTransfer::write::GetAttribute {att} {
    variable writeAttributes
    return [dict get $writeAttributes $att]
}

proc ::ConjugateHeatTransfer::write::GetAttributes {} {
    variable writeAttributes
    return $writeAttributes
}

proc ::ConjugateHeatTransfer::write::SetAttribute {att val} {
    variable writeAttributes
    dict set writeAttributes $att $val
}

proc ::ConjugateHeatTransfer::write::AddAttribute {att val} {
    variable writeAttributes
    dict lappend writeAttributes $att $val
}

proc ::ConjugateHeatTransfer::write::AddAttributes {configuration} {
    variable writeAttributes
    set writeAttributes [dict merge $writeAttributes $configuration]
}

proc ::ConjugateHeatTransfer::write::AddValidApps {appid} {
    AddAttribute validApps $appid
}

proc ::ConjugateHeatTransfer::write::SetCoordinatesByGroups {value} {
    SetAttribute writeCoordinatesByGroups $value
}