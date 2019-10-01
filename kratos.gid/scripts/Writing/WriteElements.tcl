
proc write::writeElementConnectivities { } {
    set parts [GetConfigurationAttribute parts_un]
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
    W "writeGroupElementConnectivities1"
    if {[GetConfigurationAttribute properties_location] ne ""} {set write_properties_in [GetConfigurationAttribute properties_location]}
    set group [get_domnode_attribute $gNode n]
    W "writeGroupElementConnectivities2"
    if { [dict exists $mat_dict $group] && $write_properties_in eq "mdpa"} {
        set mid [dict get $mat_dict $group MID]
    } else {
        set mid 0
    }
    W "writeGroupElementConnectivities3"
    if {[$gNode hasAttribute ov]} {set ov [get_domnode_attribute $gNode ov] } {set ov [get_domnode_attribute [$gNode parent] ov] }
    lassign [getEtype $ov $group] etype nnodes
    if {$nnodes ne ""} {
        W "writeGroupElementConnectivities4"
        if {$etype ne "none"} {
            set elem [::Model::getElement $kelemtype]
            set top [$elem getTopologyFeature $etype $nnodes]
            if {$top ne ""} {
                set kratosElemName [$top getKratosName]
                set s [mdpaIndent]
                WriteString "${s}Begin Elements $kratosElemName// GUI group identifier: $group"
                W "writeGroupElementConnectivities5"
                incr ::write::current_mdpa_indent_level
                set formats [GetFormatDict $group $mid $nnodes]
                GiD_WriteCalculationFile connectivities $formats
                incr ::write::current_mdpa_indent_level -1
                WriteString "${s}End Elements"
                WriteString ""
            } else {
                W "writeGroupElementConnectivities6"
                error [= "Element $kelemtype $etype ($nnodes nodes) not available for $ov entities on group $group"]
            }
        } else {
            error [= "You have not assigned a proper entity to group $group"]
        }
    } else {
        error [= "You have not assigned a proper entity to group $group"]
    }
}
