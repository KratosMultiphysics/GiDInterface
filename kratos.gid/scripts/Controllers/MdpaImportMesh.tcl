proc Kratos::ReadPreW { } {
    set filename [Browser-ramR file read .gid [_ "Kratos - Read Mdpa file"] {} {{{Model part} {.mdpa }}} ]
    if {$filename == ""} {
        return
    }
    GidUtils::EvalAndEnterInBatch Kratos::ReadPre $filename
}


#to drag and drop a file
proc Kratos::ReadPreSingleFile { filename } {
    GidUtils::EvalAndEnterInBatch Kratos::ReadPre $filename
}

#create could be GEOMETRY or MESH
proc Kratos::ReadPre { filename } {
    if { ![file exists $filename] } { 
        WarnWin [_ "file '%s' not exists" $filename]
        return 1
    }   
    set fp [open $filename r]
    if { $fp == "" } {
        WarnWin [_ "Cannot open file '%s'" $filename]
        return 1
    }
    #offset_nodes to be added to the number if a previous model exists
    set offset_nodes [GiD_Info Mesh MaxNumNodes]
    set offset_elements [GiD_Info Mesh MaxNumElements]
    set conditions_dict [dict create]
    set layer Layer0
    set fail 0
    set state 0
    ::GidUtils::WaitState
    while { ![eof $fp] } {
        # take next line
        gets $fp line

        if {$line eq "Begin Nodes"} {
            while { ![eof $fp] } {
                gets $fp line
                if {$line ne "End Nodes"} {
                    lassign [regsub -all {\s+}  $line " "] id x y z
                    GiD_Mesh create node [expr $offset_nodes + $id] [list $x $y $z]
                } else {
                    break
                }
            }
        }
        if {[string match "Begin Elements*" $line]} {
            set element_type [Kratos::GuessElementTypeFromMDPA $line]
            while { ![eof $fp] } {
                gets $fp line
                if {$line ne "End Elements"} {
                    # lo del elemento
                    set raw [regsub -all {\s+}  $line " "]
                    set id [lindex $raw 0]
                    set nodes [lrange $raw 2 end]
                    set nodes_new [list ]
                    foreach node $nodes {lappend nodes_new [expr $node + $offset_nodes]}
                    GiD_Mesh create element [expr $offset_elements + $id] $element_type [llength $nodes_new] $nodes_new
                } else {
                    break
                }
            }
        }
        if {[string match "Begin Conditions*" $line]} {
            set element_type [Kratos::GuessElementTypeFromMDPA $line]
            while { ![eof $fp] } {
                gets $fp line
                if {$line ne "End Conditions"} {
                    # lo del elemento
                    set raw [regsub -all {\s+}  $line " "]
                    set id [lindex $raw 0]
                    if {$id in [dict exists $conditions_dict $id]} {next}
                    set nodes [lrange $raw 2 end]
                    set nodes_new [list ]
                    foreach node $nodes {lappend nodes_new [expr $node + $offset_nodes]}
                    set new_id [GiD_Mesh create element append $element_type [llength $nodes_new] $nodes_new]
                    dict set conditions_dict $id $new_id
                } else {
                    break
                }
            }
        }
        if {[string match "Begin SubModelPart*" $line]} {
            set group_name [lindex [split [lindex $line 2] "//"] 0]
            set group_name_orig $group_name
            set i 0
            while {[GiD_Groups exists $group_name]} {set group_name [string cat "Imported_" $group_name_orig "_" [incr i]]}
            GiD_Groups create $group_name
            while { ![eof $fp] } {
                gets $fp line
                if {[string trim $line] ne "End SubModelPart"} {
                    if {[string trim $line] eq "Begin SubModelPartNodes"} {
                        while { ![eof $fp] } {
                            gets $fp line
                            if {[string trim $line] ne "End SubModelPartNodes"} {
                                GiD_EntitiesGroups assign $group_name nodes [expr $offset_nodes + [string trim $line]]
                            } else {
                                break
                            }
                        }
                    }
                    if {[string trim $line] eq "Begin SubModelPartElements"} {
                        while { ![eof $fp] } {
                            gets $fp line
                            if {[string trim $line] ne "End SubModelPartElements"} {
                                GiD_EntitiesGroups assign $group_name elements [expr $offset_elements + [string trim $line]]
                            } else {
                                break
                            }
                        }
                    }
                    if {[string trim $line] eq "Begin SubModelPartConditions"} {
                        while { ![eof $fp] } {
                            gets $fp line
                            if {[string trim $line] ne "End SubModelPartConditions"} {
                                GiD_EntitiesGroups assign $group_name elements [dict get $conditions_dict [string trim $line]]
                            } else {
                                break
                            }
                        }
                    }
                } else {
                    break
                }
            }
        }
    }
    close $fp

    ::GidUtils::EndWaitState
    ::GidUtils::SetWarnLine [_ "File read"]

    if { [GiD_Info project ViewMode] != "MESHUSE" } {
        GiD_Process MEscape Meshing MeshView
    }

    #GiD_Redraw
    GiD_Process Mescape View Zoom Frame escape
    if { [info commands GiD_Groups] != "" } {
        Groups::FillInfo
    }
    
    #RaiseEvent_GenericProc ::AfterOpenFile $filename UNV_FORMAT 0
    return 0
}

proc Kratos::GuessElementTypeFromMDPA {line} {
    set element_type "unknown"
    set element_name [lindex $line 2]
    set element_name [lindex [split $element_name "//"] 0]
    
    if {$element_name eq "Sphere3D"} {
        set element_type "Sphere"
    } else {
        set dim [string index $element_name end-3]
        set nnodes [string index $element_name end-1]
        switch $nnodes {
            2 {
                set element_type "Line"
            }
            3 {
                set element_type "Triangle"
            }
            4 {
                if {$dim eq 2} {
                    set element_type "Quadrilateral"
                } else {
                    set element_type "Tetraedra"
                }
            }
            5 {
                set element_type "Pyramid"
            }
            6 { 
                if {$dim eq 2} {
                    set element_type "Triangle"
                } else {
                    set element_type "Prism"
                }
            }
            8 { 
                if {$dim eq 2} {
                    set element_type "Quadrilateral"
                } else {
                    set element_type "Hexaedra"
                }
            }
            9 {
                set element_type "Quadrilateral"
            }
            10 {
                set element_type "Tetraedra"
            }
            13 {
                set element_type "Pyramid"
            }
            15 {
                set element_type "Prism"
            }
            18 {
                set element_type "Prism"
            }
            20 {
                set element_type "Hexaedra"
            }
            27 {
                set element_type "Hexaedra"
            }
        }
    }
    return $element_type
}

#register the proc to be automatically called when dropping a file
GiD_RegisterExtensionProc ".mdpa" PRE Kratos::ReadPreSingleFile