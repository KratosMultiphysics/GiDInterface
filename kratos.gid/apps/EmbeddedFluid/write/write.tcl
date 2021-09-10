namespace eval EmbeddedFluid::write {
    variable writeAttributes
}

proc EmbeddedFluid::write::Init { } {
    # Namespace variables inicialization        
    variable writeAttributes
    set writeAttributes [::Fluid::write::GetAttributes]
}

# Events
proc EmbeddedFluid::write::writeModelPartEvent { } {
    Fluid::write::writeModelPartEvent
}

# Overwrite this function to print something at the end of the mdpa
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
    write::SetConfigurationAttribute main_launch_file [GetAttribute main_launch_file]
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
