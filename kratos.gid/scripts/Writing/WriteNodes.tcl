
proc write::writeNodalCoordinatesOnGroups { groups } {
    # Write the nodal coordinates block for a list of groups
    # Nodes block format
    # Begin Nodes
    # // id          X        Y        Z
    # End Nodes
    if {[llength $groups] >0} {
        variable formats_dict
        set id_f [dict get $formats_dict ID]
        set coord_f [dict get $formats_dict COORDINATE]
        set formats [dict create]
        set s [mdpaIndent]

        WriteString "${s}Begin Nodes"
        incr ::write::current_mdpa_indent_level
        foreach group $groups {
            dict set formats $group "${s}$id_f $coord_f $coord_f $coord_f\n"
        }
        GiD_WriteCalculationFile nodes $formats
        incr ::write::current_mdpa_indent_level -1
        WriteString "${s}End Nodes"
        WriteString "\n"
    }
}

proc write::writeNodalCoordinatesOnParts { } {
    writeNodalCoordinatesOnGroups [getPartsGroupsId]
}

proc write::writeNodalCoordinates { } {
    # Write the nodal coordinates block
    # Nodes block format
    # Begin Nodes
    # // id          X        Y        Z
    # End Nodes
    variable formats_dict
    set id_f [dict get $formats_dict ID]
    set coord_f [dict get $formats_dict COORDINATE]
    set s [mdpaIndent]
    WriteString "${s}Begin Nodes"
    incr ::write::current_mdpa_indent_level
    customlib::WriteCoordinates "${s}$id_f $coord_f $coord_f $coord_f\n"
    incr ::write::current_mdpa_indent_level -1
    WriteString "${s}End Nodes"
    WriteString "\n"
}

