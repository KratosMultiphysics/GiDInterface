
proc write::writeElementConnectivities { {default_parts_un "" } } {
    if {$default_parts_un eq ""} {
        set parts [GetConfigurationAttribute parts_un]
    } else {
        set parts $default_parts_un
    }
    set root [customlib::GetBaseRoot]

    set xp1 "[spdAux::getRoute $parts]/group"
    if {[llength [$root selectNodes $xp1]] < 1} {
        set xp1 "[spdAux::getRoute $parts]/condition/group"
    }
    foreach gNode [$root selectNodes $xp1] {
        set elem [write::getValueByNode [$gNode selectNodes ".//value\[@n='Element']"] ]
        write::writeGroupElementConnectivities $gNode $elem
    }
}

# gNode must be a tree group, have a value n = Element
proc write::writeGroupElementConnectivities { gNode kelemtype} {
    variable mat_dict
    set formats ""
    set write_properties_in mdpa
    if {[GetConfigurationAttribute properties_location] ne ""} {set write_properties_in [GetConfigurationAttribute properties_location]}
    set group [get_domnode_attribute $gNode n]
    set submodelpart [write::GetSubModelPartName Parts $group]
    if { [dict exists $mat_dict $submodelpart] && $write_properties_in eq "mdpa"} {
        set mid [dict get $mat_dict $submodelpart MID]
    } else {
        set mid 0
    }
    if {[$gNode hasAttribute ov]} {set ov [get_domnode_attribute $gNode ov] } {set ov [get_domnode_attribute [$gNode parent] ov] }
    lassign [getEtype $ov $group] etype nnodes
    if {$nnodes ne ""} {
        if {$etype ne "none"} {
            set elem [::Model::getElement $kelemtype]
            set topology [$elem getTopologyFeature $etype $nnodes]
            if {$topology ne ""} {
                set kratos_element_type [$topology getKratosName]
                write::writeGroupElementConnectivitiesFor $kratos_element_type $nnodes $group $mid
            } else {
                error [= "Element $kelemtype $etype ($nnodes nodes) not available for $ov entities on group $group"]
            }
        } else {
            error [= "You have not assigned a proper entity to group $group"]
        }
    } else {
        error [= "You have not assigned a proper entity to group $group"]
    }
}
proc write::writeGroupElementConnectivitiesFor { kratos_element_type nnodes group mid } {
    set s [mdpaIndent]
    WriteString "${s}Begin Elements $kratos_element_type// GUI group identifier: $group"
    incr ::write::current_mdpa_indent_level
    set formats [GetFormatDict $group $mid $nnodes]
    GiD_WriteCalculationFile connectivities $formats
    incr ::write::current_mdpa_indent_level -1
    WriteString "${s}End Elements"
    WriteString ""
}