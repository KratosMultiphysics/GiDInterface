
proc write::writeGeometryConnectivitiesByElementType { group_list} {
    

    set list_of_element_types_used [list ]
    
    foreach gNode $group_list {
        set elem_node [$gNode selectNodes ".//value\[@n='Element']"]
        if {$elem_node eq "" } {set kelemtype "GENERIC_ELEMENT"} else {set kelemtype [write::getValueByNode $elem_node]}
        
        if {$kelemtype eq ""} {set kelemtype "GENERIC_ELEMENT"}
        if {[$gNode hasAttribute ov]} {set ov [get_domnode_attribute $gNode ov] } {set ov [get_domnode_attribute [$gNode parent] ov] }
        set group [get_domnode_attribute $gNode n]
        lassign [getEtype $ov $group] etype nnodes

        set elem [::Model::getElement $kelemtype]
        set topology [$elem getTopologyFeature $etype $nnodes]
        if {$topology ne ""} {
            set kratos_element_type [$topology getKratosName]
            set s [mdpaIndent]
            WriteString "${s}Begin Geometries $kratos_element_type// GUI group identifier: $group"
            incr ::write::current_mdpa_indent_level
            set formats [GetFormatDict $group 0 $nnodes]
            GiD_WriteCalculationFile connectivities $formats
            incr ::write::current_mdpa_indent_level -1
            WriteString "${s}End Geometries"
            WriteString ""
        } else {
            error [= "Element $kelemtype $etype ($nnodes nodes) not available for $ov entities on group $group"]
        }
    }
    
}