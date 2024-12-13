namespace eval ::FSI::write {
    namespace path ::FSI
    Kratos::AddNamespace [namespace current]
    
    variable fluid_project_parameters
    variable structure_project_parameters
    variable mdpa_names
}

proc ::FSI::write::Init { } {
    variable fluid_project_parameters
    variable structure_project_parameters
    set fluid_project_parameters [dict create ]
    set structure_project_parameters [dict create ]
    
    variable mdpa_names
    set mdpa_names [dict create ]
}

# Events
proc ::FSI::write::writeModelPartEvent { } {
    variable mdpa_names
    set filename [Kratos::GetModelName]
    
    Fluid::write::Init
    # Fluid has implemented the geometry mode, but we do not use it yet in inherited apps
    ::Fluid::write::SetAttribute write_mdpa_mode [::FSI::GetWriteProperty write_mdpa_mode]
    Fluid::write::InitConditionsMap
    Fluid::write::SetCoordinatesByGroups 1
    set base_root_xpath [spdAux::getRoute FSIFluid]
    set base_root [[customlib::GetBaseRoot] selectNodes $base_root_xpath]
    set ::Fluid::write::base_root $base_root
    write::writeAppMDPA Fluid
    dict set mdpa_names Fluid "${filename}_Fluid"
    write::RenameFileInModel "$filename.mdpa" "[dict get $mdpa_names Fluid].mdpa"
    
    Structural::write::Init
    Structural::write::SetCoordinatesByGroups 1
    set base_root_xpath [spdAux::getRoute FSIStructural]
    set base_root [[customlib::GetBaseRoot] selectNodes $base_root_xpath]
    set ::Structural::write::base_root $base_root
    write::writeAppMDPA Structural
    dict set mdpa_names Structural "${filename}_Structural"
    write::RenameFileInModel "$filename.mdpa" "[dict get $mdpa_names Structural].mdpa"
}

proc ::FSI::write::writeCustomFilesEvent { } {
    Fluid::write::WriteMaterialsFile
    Structural::write::WriteMaterialsFile
    write::SetConfigurationAttribute main_launch_file [GetAttribute main_launch_file]
}
