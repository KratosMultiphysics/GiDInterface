namespace eval MPM::write {
    variable writeAttributes
}

proc MPM::write::Init { } {
    # Namespace variables inicialization
    # SetAttribute parts_un FLParts
    # SetAttribute nodal_conditions_un FLNodalConditions
    # SetAttribute conditions_un FLBC
    # SetAttribute materials_un EMBFLMaterials
    # SetAttribute writeCoordinatesByGroups 0
    # SetAttribute validApps [list "MPM"]
    # SetAttribute main_script_file "KratosFluid.py"
    # SetAttribute materials_file "FluidMaterials.json"
}

# Events
proc MPM::write::writeModelPartEvent { } {
   
}
proc MPM::write::writeCustomFilesEvent { } {
    write::CopyFileIntoModel "python/KratosFluid.py"
    write::RenameFileInModel "KratosFluid.py" "MainKratos.py"
}

proc MPM::write::GetAttribute {att} {
    variable writeAttributes
    return [dict get $writeAttributes $att]
}

proc MPM::write::GetAttributes {} {
    variable writeAttributes
    return $writeAttributes
}

proc MPM::write::SetAttribute {att val} {
    variable writeAttributes
    dict set writeAttributes $att $val
}

MPM::write::Init
