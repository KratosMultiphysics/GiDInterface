namespace eval Chimera::write {
    variable writeAttributes
}

proc Chimera::write::Init { } {
    # Namespace variables inicialization
    SetAttribute parts_un FLParts
    SetAttribute nodal_conditions_un FLNodalConditions
    SetAttribute conditions_un FLBC
    SetAttribute materials_un EMBFLMaterials
    SetAttribute results_un FLResults
    SetAttribute time_parameters_un FLTimeParameters
    SetAttribute writeCoordinatesByGroups 0
    SetAttribute validApps [list "Fluid" "Chimera"]
    SetAttribute main_script_file "KratosFluid.py"
    SetAttribute model_part_name "FluidModelPart"
    SetAttribute materials_file "FluidMaterials.json"
}

# Events
proc Chimera::write::writeModelPartEvent { } {
    # Fluid::write::AddValidApps "Chimera"
    set err [Fluid::write::Validate]
    if {$err ne ""} {error $err}

    Fluid::write::InitConditionsMap
    write::initWriteConfiguration [GetAttributes]
    write::writeModelPartData
    Fluid::write::writeProperties
    write::writeMaterials [GetAttribute validApps]
    write::writeNodalCoordinatesOnParts
    write::writeElementConnectivities
    Fluid::write::writeConditions
    Fluid::write::writeMeshes
    writeDistances
    Fluid::write::FreeConditionsMap
}
proc Chimera::write::writeCustomFilesEvent { } {
    write::CopyFileIntoModel "python/KratosFluid.py"
    write::RenameFileInModel "KratosFluid.py" "MainKratos.py"
}

proc Chimera::write::writeDistances { } {
    set must_write [write::getValue EMBFLDistanceSettings ReadingMode]
    if {$must_write eq "from_mdpa"} {
        set data [GiD_Info Mesh EmbeddedDistances] 
        lassign $data nodes_list distances_list
        set length [objarray length $nodes_list]
        if {$length eq "0"} {W "Warning: No distances detected! Check Preferences > Mesh type > Embedded"}
        write::WriteString "Begin NodalData DISTANCE"
        incr write::current_mdpa_indent_level
        set s [write::mdpaIndent]
        for {set i 0} {$i < $length} {incr i } {
            set node_id [objarray get $nodes_list $i]
            set distance [objarray get $distances_list $i]
            write::WriteString "$s$node_id 0 $distance"
        }
        incr write::current_mdpa_indent_level -1
        write::WriteString "End NodalData"
    }
}

proc Chimera::write::GetAttribute {att} {
    variable writeAttributes
    return [dict get $writeAttributes $att]
}

proc Chimera::write::GetAttributes {} {
    variable writeAttributes
    return $writeAttributes
}

proc Chimera::write::SetAttribute {att val} {
    variable writeAttributes
    dict set writeAttributes $att $val
}

Chimera::write::Init
