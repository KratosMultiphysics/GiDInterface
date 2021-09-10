namespace eval ::FSI::write {
    namespace path ::FSI
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
    Fluid::write::InitConditionsMap
    Fluid::write::SetCoordinatesByGroups 1
    write::writeAppMDPA Fluid
    dict set mdpa_names Fluid "${filename}_Fluid"
    write::RenameFileInModel "$filename.mdpa" "[dict get $mdpa_names Fluid].mdpa"
    
    Structural::write::Init
    Structural::write::SetCoordinatesByGroups 1
    write::writeAppMDPA Structural
    dict set mdpa_names Structural "${filename}_Structural"
    write::RenameFileInModel "$filename.mdpa" "[dict get $mdpa_names Structural].mdpa"
}

proc ::FSI::write::writeCustomFilesEvent { } {
    Fluid::write::WriteMaterialsFile
    Structural::write::WriteMaterialsFile
    write::SetConfigurationAttribute main_launch_file [GetAttribute main_launch_file]
}
