
proc write::writeGeometryConnectivities { group_list} {
    # Foreach group in the list
    foreach gNode $group_list {

        # With the ov field, we know what is selected in the tree (point, line, surface, volume)
        if {[$gNode hasAttribute ov]} {set ov [get_domnode_attribute $gNode ov] } {set ov [get_domnode_attribute [$gNode parent] ov] }
        
        # Get the group name
        set group [get_domnode_attribute $gNode n]

        # Get the number of nodes and the geometry type
        lassign [getEtype $ov $group] etype nnodes
        
        # Print into the mdpa file
        write::printGeometryConnectivities $group $etype $nnodes
    }
}

proc write::printGeometryConnectivities {group etype nnodes} {
    # Prepare the indent
    set s [mdpaIndent]
    # Write header
    WriteString "${s}Begin Geometries ${etype}${nnodes}N// GUI group identifier: $group"
    # increase indent (allows folding in text editor)
    incr ::write::current_mdpa_indent_level
    # Prepare the formats dict
    set formats [GetFormatDict $group 0 $nnodes]
    # Write the connectivities
    GiD_WriteCalculationFile connectivities $formats
    # decrease indent
    incr ::write::current_mdpa_indent_level -1
    # Write footer
    WriteString "${s}End Geometries"
    WriteString ""
}