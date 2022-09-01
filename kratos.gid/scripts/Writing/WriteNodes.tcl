
proc write::writeNodalCoordinatesOnGroups { groups } {
    # Write the nodal coordinates block for a list of groups
    # Nodes block format
    # Begin Nodes
    # // id          X        Y        Z
    # End Nodes
    # TODO: check gid version
    set is_coordinates_scaling_fixed 0
    if {[llength $groups] >0} {
        set mesh_unit [gid_groups_conds::give_mesh_unit]
        set mesh_factor [lindex [gid_groups_conds::give_unit_factor L $mesh_unit] 0]

        variable formats_dict
        set id_f [dict get $formats_dict ID]
        set coord_f [dict get $formats_dict COORDINATE]
        set formats [dict create]
        set s [mdpaIndent]

        WriteString "${s}Begin Nodes"
        incr ::write::current_mdpa_indent_level
        set s [mdpaIndent]
        if {$is_coordinates_scaling_fixed} {
            foreach group $groups {
                dict set formats $group "${s}$id_f $coord_f $coord_f $coord_f\n"
            }
            # TODO: Add factor
            GiD_WriteCalculationFile nodes $formats
        } else {
            foreach group $groups {
                set nodes [GiD_EntitiesGroups get $group node]
                foreach node $nodes {
                    lassign [GiD_Mesh get node $node coordinates] x y z
                    WriteString "${s}$node [expr $mesh_factor*$x] [expr $mesh_factor*$y] [expr $mesh_factor*$z]"
                }
            }
        }
        
        incr ::write::current_mdpa_indent_level -1
        set s [mdpaIndent]
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

