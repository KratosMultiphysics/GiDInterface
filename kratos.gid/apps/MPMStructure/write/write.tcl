namespace eval MPMStructure::write {
    variable mpm_project_parameters
    variable structure_project_parameters
}

proc MPMStructure::write::Init { } {
    variable mpm_project_parameters
    variable structure_project_parameters
    set mpm_project_parameters [dict create ]
    set structure_project_parameters [dict create ]
    
}

# Events
proc MPMStructure::write::writeModelPartEvent { } {
    variable mdpa_names
    set filename [Kratos::GetModelName]
    
    MPM::write::Init
    MPM::write::SetAttribute writeCoordinatesByGroups 1
    MPM::write::SetAttribute mpm_grid_extra_conditions [list LineMPMInterface2D LineMPMInterface2Da SurfaceMPMInterface3D]
    MPM::write::RegisterCustomBlockMethod MPMStructure::write::CustomBlock
    write::writeAppMDPA MPM
    set last_mpm_condition [MPM::write::GetLastConditionId]
    
    Structural::write::Init
    Structural::write::SetCoordinatesByGroups 1
    Structural::write::SetAttribute last_condition $last_mpm_condition
    write::writeAppMDPA Structural
    dict set mdpa_names Structural "${filename}_Structural"
    write::RenameFileInModel "$filename.mdpa" "[dict get $mdpa_names Structural].mdpa"
}

proc MPMStructure::write::writeCustomFilesEvent { } {
    Structural::write::WriteMaterialsFile
    
    write::CopyFileIntoModel "python/KratosMPMStructure.py"
    write::RenameFileInModel "KratosMPMStructure.py" "MainKratos.py"
}

proc MPMStructure::write::CustomBlock { } {
    # Time to write the interface properly
}


MPMStructure::write::Init
