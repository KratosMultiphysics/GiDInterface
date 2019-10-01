
proc write::writeNodalCoordinatesOnGroups { groups } {
    set formats [dict create]
    set s [mdpaIndent]
    WriteString "${s}Begin Nodes"
    incr ::write::current_mdpa_indent_level
    foreach group $groups {
        dict set formats $group "${s}%5d %14.5f %14.5f %14.5f\n"
    }
    GiD_WriteCalculationFile nodes $formats
    incr ::write::current_mdpa_indent_level -1
    WriteString "${s}End Nodes"
    WriteString "\n"
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
    set s [mdpaIndent]
    WriteString "${s}Begin Nodes"
    incr ::write::current_mdpa_indent_level
    customlib::WriteCoordinates "${s}%5d %14.10f %14.10f %14.10f\n"
    incr ::write::current_mdpa_indent_level -1
    WriteString "${s}End Nodes"
    WriteString "\n"
}

