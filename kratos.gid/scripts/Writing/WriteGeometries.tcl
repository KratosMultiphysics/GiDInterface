
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
    
    set inittime [clock seconds]
    # Prepare the indent
    set s [mdpaIndent]
    set nDim $::Model::SpatialDimension
    set geometry_name ${etype}${nDim}${nnodes}
    # Write header
    WriteString "${s}Begin Geometries $geometry_name // GUI group identifier: $group"
    # increase indent (allows folding in text editor)
    incr ::write::current_mdpa_indent_level
    # Prepare the formats dict
    set formats [GetFormatDict $group "" $nnodes]
    # Write the connectivities
    GiD_WriteCalculationFile connectivities $formats
    # decrease indent
    incr ::write::current_mdpa_indent_level -1
    # Write footer
    WriteString "${s}End Geometries"
    WriteString ""

    # Write the radius if it is a sphere or a circle
    if {$etype == "Sphere" || $etype == "Circle"} {
        write::writeSphereRadiusOnGroup $group
    }
    if {[GetConfigurationAttribute time_monitor]} {set endtime [clock seconds]; set ttime [expr {$endtime-$inittime}]; W "printGeometryConnectivities $geometry_name time: [Kratos::Duration $ttime]"}
}

proc write::writeSphereRadiusOnGroup { groupid } {
    set print_groupid [write::GetWriteGroupName $groupid]
    write::WriteString "Begin NodalData RADIUS // GUI group identifier: $print_groupid"
    GiD_WriteCalculationFile connectivities [dict create $groupid "%.0s %10d 0 %10g\n"]
    write::WriteString "End NodalData"
    write::WriteString ""
}