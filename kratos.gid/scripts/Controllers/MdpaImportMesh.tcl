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

    set num_nodes_before [GiD_Info Mesh NumNodes]
    set num_elements_before [GiD_Info Mesh NumElements]

    #offset_nodes to be added to the number if a previous model exists
    set offset_nodes [GiD_Info Mesh MaxNumNodes]
    set offset_elements [GiD_Info Mesh MaxNumElements]
    set conditions_dict [dict create]
    set layer Layer0
    set fail 0
    set state 0
    set spheres_dict [dict create]
    set space " "
    ::GidUtils::WaitState
    while { ![eof $fp] } {
        # take next line
        gets $fp line

        if {$line eq "Begin Nodes"} {
            while { ![eof $fp] } {
                gets $fp line
                if {$line ne "End Nodes"} {
                    lassign [regsub -all {\s+} $line $space] id x y z
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
                    set raw [regsub -all {\s+} $line $space]
                    set id [lindex $raw 0]
                    set nodes [lrange $raw 2 end]
                    if {[llength $nodes] > 1} {
                        set nodes_new [list ]
                        foreach node $nodes {lappend nodes_new [expr $node + $offset_nodes]}
                        GiD_Mesh create element [expr $offset_elements + $id] $element_type [llength $nodes_new] $nodes_new
                    } else {
                        dict set spheres_dict $nodes element_type $element_type
                        dict set spheres_dict $nodes element $id
                    }
                } else {
                    break
                }
            }
        }
        
        if {[string match "Begin Geometries*" $line]} {
            set element_type [Kratos::GuessElementTypeFromMDPA $line]
            while { ![eof $fp] } {
                gets $fp line
                if {$line ne "End Geometries"} {
                    # lo del elemento
                    set raw [regsub -all {\s+} $line $space]
                    set id [lindex $raw 0]
                    set nodes [lrange $raw 1 end]
                    if {[llength $nodes] > 1} {
                        set nodes_new [list ]
                        foreach node $nodes {lappend nodes_new [expr $node + $offset_nodes]}
                        GiD_Mesh create element [expr $offset_elements + $id] $element_type [llength $nodes_new] $nodes_new
                    } else {
                        dict set spheres_dict $nodes element_type $element_type
                        dict set spheres_dict $nodes element $id
                    }
                } else {
                    break
                }
            }
        }
        if {[string match "Begin NodalData RADIUS*" $line]} {
            while { ![eof $fp] } {
                gets $fp line
                if {$line ne "End NodalData"} {
                    set raw [regsub -all {\s+} $line $space]
                    set id [lindex $raw 0]
                    set element [dict get $spheres_dict $id element]
                    set rad [lindex $raw 2]
                    set element_type [dict get $spheres_dict $id element_type]
                    if {$element_type eq "Circle"} {
                        GiD_Mesh create element [expr $offset_elements + $element] $element_type 1 [expr $id + $offset_nodes] $rad 0 0 1
                    } else {
                        GiD_Mesh create element [expr $offset_elements + $element] $element_type 1 [expr $id + $offset_nodes] $rad
                    }
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
                    set raw [regsub -all {\s+} $line $space]
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
                    if {[string trim $line] eq "Begin SubModelPartGeometries"} {
                        while { ![eof $fp] } {
                            gets $fp line
                            if {[string trim $line] ne "End SubModelPartGeometries"} {
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
    
    set num_nodes [GiD_Info Mesh NumNodes]
    set num_elements [GiD_Info Mesh NumElements]
    if { $num_nodes != $num_nodes_before || $num_elements != $num_elements_before } {
        GiD_RaiseEvent GiD_Event_AfterChangeMesh $num_nodes $num_elements
    }
    GiD_RaiseEvent GiD_Event_AfterOpenFile $filename MESHIO_FORMAT 0

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
    set entity [lindex $line 1]
    set element_name1 [lindex $line 2]
    set element_name [lindex [split $element_name1 "//"] 0]

    if {$element_name eq "Sphere3D"} {
        set element_type "Sphere"
    } elseif {$element_name in {"SphericContinuumParticle3D" "SphericParticle3D"}} {
        set element_type "Sphere"
    } elseif {$element_name in {"CylinderContinuumParticle2D" "CylinderParticle2D"}} {
        set element_type "Circle"
    } else {
        if {$entity eq "Geometries"} {
            set dim [string index $element_name end-2]
            set nnodes [string index $element_name end]
        } else {
            set dim [string index $element_name end-3]
            set nnodes [string index $element_name end-1]
        }
        # 0: linear, 1: quadratic, 2: biquadratic
        set detected_mesh_quad [Kratos::GuessQuadMesh $element_name $dim $nnodes]
        set is_quadratic [GiD_Set Model(QuadraticType)]
        if { $detected_mesh_quad eq "0" } {
            if {$is_quadratic ne "0"} {W "We have changed the mesh mode to linear. Check Mesh menu to change it back."}
            GiD_Set Model(QuadraticType) 0
        } 
        if {$detected_mesh_quad eq "1"} {
            if {$is_quadratic ne "1"} {W "We have changed the mesh mode to quadratic. Check Mesh menu to change it back."}
            GiD_Set Model(QuadraticType) 1
        }
        
        switch $nnodes {
            2 {
                set element_type "Line"
            }
            3 {
                if {$is_quadratic eq "0"} {
                    set element_type "Triangle"
                } else {
                    set element_type "Line"
                }
            }
            4 {
                if {$dim eq 2} {
                    set element_type "Quadrilateral"
                } else {
                    set element_type "Tetrahedra"
                }
            }
            5 {
                set element_type "Pyramid"
            }
            6 { 
                if {$is_quadratic eq "0"} {
                    if {$dim eq 2} {
                        set element_type "Triangle"
                    } 
                } else {
                    if {$dim eq 2} {
                        set element_type "Triangle"
                    } 
                }
            }
            8 { 
                if {$dim eq 2} {
                    set element_type "Quadrilateral"
                } else {
                    set element_type "Hexahedra"
                }
            }
            9 {
                set element_type "Quadrilateral"
            }
            10 {
                set element_type "Tetrahedra"
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
                set element_type "Hexahedra"
            }
            27 {
                set element_type "Hexahedra"
            }
        }
    }
    return $element_type
}

proc Kratos::GuessQuadMesh {element_name dim nnodes} {
    if {$nnodes eq 6 && $dim eq 2} {return 1}
    if {$nnodes eq 4 && $dim eq 2} {return 0}
    if {$nnodes eq 4 && $dim eq 3} {return 0}
    if {$nnodes eq 8 && $dim eq 2} {return 1}
    if {$nnodes eq 8 && $dim eq 3} {return 0}
    if {$nnodes eq 2 }  {return 0}
    if {$nnodes eq 9 }  {return 2}
    if {$nnodes eq 20 } {return 1}
    if {$nnodes eq 27 } {return 2}
    if {$nnodes eq 15 } {return 1}
    if {$nnodes eq 18 } {return 2}
    if {$nnodes eq 5 }  {return 0}
    if {$nnodes eq 13 } {return 1}
    return -1
}

#register the proc to be automatically called when dropping a file
GiD_RegisterExtensionProc ".mdpa" PRE Kratos::ReadPreSingleFile