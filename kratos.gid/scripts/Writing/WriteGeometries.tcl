
proc write::writeGeometryConnectivities { group_list } {
    # Avoid duplicates (groups used twice and intervals!)
    set processed_list_names [list ]
    set processed_list [list ]
    foreach gNode $group_list {
        set group [get_domnode_attribute $gNode n]
        set group_name [write::GetWriteGroupName $group]
        
        # If the group is not in the list, add it
        if {[lsearch $processed_list_names $group_name] == -1} {
            lappend processed_list_names $group_name
            lappend processed_list $gNode
        }
    }
    
    # Foreach group in the list
    foreach gNode $processed_list {

        # With the ov field, we know what is selected in the tree (point, line, surface, volume)
        if {[$gNode hasAttribute ov]} {set ov [get_domnode_attribute $gNode ov] } {set ov [get_domnode_attribute [$gNode parent] ov] }
        
        # Get the group name
        set group [get_domnode_attribute $gNode n]
        set group_name [write::GetWriteGroupName $group]

        # Get the number of nodes and the geometry type
        lassign [getEtype $ov $group_name] etype nnodes
        
        # Print into the mdpa file
        write::printGeometryConnectivities $group_name $etype $nnodes
    }
}

proc write::printGeometryConnectivities {group etype nnodes} {
    # W "printGeometryConnectivities $group $etype $nnodes"
    
    if {$nnodes eq "" || $nnodes < 1} {return}
    set inittime [clock seconds]
    # Prepare the indent
    set s [mdpaIndent]
    set nDim $::Model::SpatialDimension
    set geometry_name ${etype}${nDim}${nnodes}

    # Prepare the formats dict
    set formats [GetFormatDict $group "" $nnodes]
    set num_elems [GiD_WriteCalculationFile connectivities -count $formats]
    if {$num_elems > 0} {

        # Write header
        WriteString "${s}Begin Geometries $geometry_name // GUI group identifier: $group"
        # increase indent (allows folding in text editor)
        incr ::write::current_mdpa_indent_level
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
    } else {
        # Trick: GiD < 17.3.x return 0 if elements are of type Point
        set elems [GiD_EntitiesGroups get $group elements -element_type point]
        set num_elems [objarray length $elems]
        if {$num_elems > 0} {
            # Write header
            set geometry_name ${etype}${nDim}
            WriteString "${s}Begin Geometries $geometry_name // GUI group identifier: $group"
            # increase indent (allows folding in text editor)
            incr ::write::current_mdpa_indent_level
            # Write the connectivities
            set s1 [mdpaIndent]
            objarray foreach elem $elems {
                set node_id [GiD_Mesh get element $elem connectivities]
                GiD_WriteCalculationFile puts "${s1}$elem $node_id"
            }
            # decrease indent
            incr ::write::current_mdpa_indent_level -1
            # Write footer
            WriteString "${s}End Geometries"
            WriteString ""

            # Write the radius if it is a sphere or a circle
            if {$etype == "Sphere" || $etype == "Circle"} {
                write::writeSphereRadiusOnGroup $group
            }
        }
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