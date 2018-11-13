namespace eval FSI::write {
    variable fluid_project_parameters
    variable structure_project_parameters
}

proc FSI::write::Init { } {
    variable fluid_project_parameters
    variable structure_project_parameters
    set fluid_project_parameters [dict create ]
    set structure_project_parameters [dict create ]
}

# Events
proc FSI::write::writeModelPartEvent { } {
    set filename [Kratos::GetModelName]
    
    Fluid::write::Init
    Fluid::write::InitConditionsMap
    Fluid::write::SetCoordinatesByGroups 1
    write::writeAppMDPA Fluid
    write::RenameFileInModel "$filename.mdpa" "${filename}_Fluid.mdpa"
    
    Structural::write::Init
    Structural::write::SetCoordinatesByGroups 1
    write::writeAppMDPA Structural
    write::RenameFileInModel "$filename.mdpa" "${filename}_Structural.mdpa"
}

proc FSI::write::writeCustomFilesEvent { } {
    Structural::write::WriteMaterialsFile
    
    write::CopyFileIntoModel "python/KratosFSI.py"
    write::RenameFileInModel "KratosFSI.py" "MainKratos.py"
}


FSI::write::Init
