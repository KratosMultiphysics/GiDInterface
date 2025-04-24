namespace eval ::ConjugateHeatTransfer::write {
    namespace path ::ConjugateHeatTransfer
    Kratos::AddNamespace [namespace current]
    # Namespace variables declaration
    variable ConjugateHeatTransferConditions
    variable writeCoordinatesByGroups
    variable writeAttributes
    variable fluid_domain_solver_settings
    variable solid_domain_solver_settings

    variable mdpa_files
}

proc ::ConjugateHeatTransfer::write::Init { } {
    # Namespace variables initialization
    variable ConjugateHeatTransferConditions
    set ConjugateHeatTransferConditions(temp) 0
    unset ConjugateHeatTransferConditions(temp)

    SetAttribute main_launch_file [::ConjugateHeatTransfer::GetAttribute main_launch_file]
    SetAttribute properties_location [::ConjugateHeatTransfer::GetWriteProperty properties_location]
    SetAttribute model_part_name [::ConjugateHeatTransfer::GetWriteProperty model_part_name]

    SetAttribute coordinates [::ConjugateHeatTransfer::GetWriteProperty coordinates]
    SetAttribute write_mdpa_mode [::ConvectionDiffusion::GetWriteProperty write_mdpa_mode]

    SetAttribute fluid_mdpa_suffix Fluid
    SetAttribute solid_mdpa_suffix Solid

    variable fluid_domain_solver_settings
    variable solid_domain_solver_settings
    set fluid_domain_solver_settings [dict create]
    set solid_domain_solver_settings [dict create]

    variable mdpa_files
    set mdpa_files []
}

# Events
proc ::ConjugateHeatTransfer::write::writeModelPartEvent { } {
    variable mdpa_files
    # Validation
    set err [Validate]
    if {$err ne ""} {error $err}
    
    set filename [Kratos::GetModelName]

    # Buoyancy mdpa
    ::ConjugateHeatTransfer::write::PrepareBuoyancy
    write::writeAppMDPA Buoyancy
    set buoyancy_mdpa "${filename}_[GetAttribute fluid_mdpa_suffix]"
    write::RenameFileInModel "$filename.mdpa" ${buoyancy_mdpa}.mdpa
    lappend mdpa_files $buoyancy_mdpa
    
    # Convection diffusion mdpa
    ConvectionDiffusion::write::Init
    ConvectionDiffusion::write::SetAttribute writeCoordinatesByGroups [GetAttribute coordinates]
        
    set base_root_xpath [spdAux::getRoute CHTCNVDFF]
    set base_root [[customlib::GetBaseRoot] selectNodes $base_root_xpath]
    set ::ConvectionDiffusion::write::base_root $base_root

    write::writeAppMDPA ConvectionDiffusion
    set convdif_mdpa "${filename}_[GetAttribute solid_mdpa_suffix]"
    write::RenameFileInModel "$filename.mdpa" ${convdif_mdpa}.mdpa
    lappend mdpa_files $convdif_mdpa
}

proc ::ConjugateHeatTransfer::write::writeCustomFilesEvent { } {
    # Materials
    WriteMaterialsFile
    write::SetConfigurationAttribute main_launch_file [GetAttribute main_launch_file]
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
    Fluid::write::SetCoordinatesByGroups [GetAttribute coordinates]
}

proc ::ConjugateHeatTransfer::write::WriteMaterialsFile { {write_const_law True} {include_modelpart_name True}  } {
    ConjugateHeatTransfer::write::WriteBuoyancyMaterialsFile $write_const_law $include_modelpart_name
    ConvectionDiffusion::write::WriteMaterialsFile False $include_modelpart_name
}

proc ::ConjugateHeatTransfer::write::WriteBuoyancyMaterialsFile { {write_const_law True} {include_modelpart_name True}  } {
    ## Write fluid material file
    set model_part_name ""
    if {[write::isBooleanTrue $include_modelpart_name]} {set model_part_name [GetAttribute model_part_name]}
    set fluid_materials [Fluid::write::GetMaterialsFile $write_const_law $include_modelpart_name]
    write::writePropertiesJsonFileDone [::Fluid::write::GetAttribute materials_file] $fluid_materials

    # Write Buoyancy materials file
    set buoyancy_material [::Buoyancy::write::GetBuoyancyMaterialsFile]
    write::writePropertiesJsonFileDone "BuoyancyMaterials.json" $buoyancy_material
}

proc ::ConjugateHeatTransfer::write::GetAttribute {att} {
    variable writeAttributes
    if {![dict exists $writeAttributes $att]} {
        return ""
    }
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