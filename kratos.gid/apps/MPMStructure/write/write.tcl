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
    write::writeAppMDPA MPM
    
    Structural::write::Init
    Structural::write::SetCoordinatesByGroups 1
    Structural::write::RegisterCustomBlockMethod MPMStructure::write::CustomBlock
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
    W "test"
    write::WriteString test
}


MPMStructure::write::Init
