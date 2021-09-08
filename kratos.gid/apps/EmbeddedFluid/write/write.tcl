namespace eval EmbeddedFluid::write {
    variable writeAttributes
}

proc EmbeddedFluid::write::Init { } {
    # Namespace variables inicialization        
    SetAttribute parts_un [::Fluid::GetUniqueName parts]
    SetAttribute nodal_conditions_un [::Fluid:::GetUniqueName nodal_conditions]
    SetAttribute conditions_un [::Fluid::GetUniqueName conditions]
    SetAttribute materials_un [::EmbeddedFluid::GetUniqueName materials]
    SetAttribute results_un [::Fluid::GetUniqueName results]
    SetAttribute drag_un [::Fluid::GetUniqueName drag]
    SetAttribute time_parameters_un [::Fluid::GetUniqueName time_parameters]

    SetAttribute writeCoordinatesByGroups [::Fluid::GetWriteProperty coordinates]
    SetAttribute validApps [list "Fluid" "EmbeddedFluid"]
    SetAttribute main_script_file [::Fluid::GetAttribute main_launch_file]
    SetAttribute materials_file [::Fluid::GetWriteProperty materials_file]
    SetAttribute properties_location [::Fluid::GetWriteProperty properties_location]
    SetAttribute model_part_name [::Fluid::GetWriteProperty model_part_name]
    SetAttribute output_model_part_name [::Fluid::GetWriteProperty output_model_part_name]
}

# Events
proc EmbeddedFluid::write::writeModelPartEvent { } {
    Fluid::write::writeModelPartEvent
}

# Overwrite this function to print something at the end of the mdpa
namespace eval ::Fluid::write:: {}
proc ::Fluid::write::writeCustomBlocks { } {
    EmbeddedFluid::write::writeDistances
}

proc EmbeddedFluid::write::writeDistances { } {
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

proc EmbeddedFluid::write::writeCustomFilesEvent { } {
    Fluid::write::writeCustomFilesEvent
}

proc EmbeddedFluid::write::GetAttribute {att} {
    variable writeAttributes
    return [dict get $writeAttributes $att]
}

proc EmbeddedFluid::write::GetAttributes {} {
    variable writeAttributes
    return $writeAttributes
}

proc EmbeddedFluid::write::SetAttribute {att val} {
    variable writeAttributes
    dict set writeAttributes $att $val
}
