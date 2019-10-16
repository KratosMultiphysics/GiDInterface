# utility for advanced meshing features in DEM
proc DEM::write::Elements_Substitution {} {

    set root [customlib::GetBaseRoot]
    set xp1 "[spdAux::getRoute DEMParts]/group"
    package require math::statistics
    set seed [expr srand(0)]
    set fail 0
    set final_list_of_isolated_nodes [list]

    foreach group [$root selectNodes $xp1] {
        set groupid [$group @n]
        set advanced_meshing_features [write::getValueByNode [$group selectNodes "./value\[@n='AdvancedMeshingFeatures'\]"]]
        if {[write::isBooleanTrue $advanced_meshing_features]} {

            set AdvancedMeshingFeaturesAlgorithmType [write::getValueByNode [$group selectNodes "./value\[@n='AdvancedMeshingFeaturesAlgorithmType'\]"]]
            set FEMtoDEM [write::getValueByNode [$group selectNodes "./value\[@n='FEMtoDEM'\]"]]
            set Diameter [write::getValueByNode [$group selectNodes "./value\[@n='Diameter'\]"]]
            set ProbabilityDistribution [write::getValueByNode [$group selectNodes "./value\[@n='ProbabilityDistribution'\]"]]
            set StandardDeviation [write::getValueByNode [$group selectNodes "./value\[@n='StandardDeviation'\]"]]

            if {$AdvancedMeshingFeaturesAlgorithmType eq "FEMtoDEM"} {
                set element_radius [expr {0.5*$Diameter}]
                set standard_deviation $StandardDeviation
                set probldistr $ProbabilityDistribution
                set min_radius [expr {0.5*$element_radius}]
                set max_radius [expr {1.5*$element_radius}]
                if {$FEMtoDEM == "AttheCentroid"} {
                    set nodes_to_delete [list]
                    set element_ids [GiD_EntitiesGroups get $groupid elements] ;               # get ids of all elements in cgroupid
                    array set is_external_element [DEM::write::Compute_External_Elements 3 $groupid $element_ids]

                    foreach element_id $element_ids { ;                                         # loop on each of the elements by id
                        set element_nodes [lrange [GiD_Mesh get element $element_id] 3 end] ;   # get the nodes of the element
                        lappend nodes_to_delete {*}$element_nodes ;                             # add those nodes to the nodes_to_delete list
                        if {$probldistr == "NormalDistribution"} {
                            set final_elem_radius [DEM::write::NormalDistribution $element_radius $standard_deviation $min_radius $max_radius]
                        } else {
                            set final_elem_radius [DEM::write::LognormalDistribution $element_radius $standard_deviation $min_radius $max_radius]
                        }
                        set node_id [GiD_Mesh create node append [DEM::write::GetElementCenter $element_id]]
                        # create a new node starting from the center of the given element
                        set new_element_id [GiD_Mesh create element append sphere 1 $node_id $final_elem_radius]
                        # create a new sphere element starting from the previous node and obtain its id

                        # lappend list_of_elements_to_add_to_skin_sphere_group {*}$new_element_id
                        # if {($is_external_element($element_id)==1) && ([lsearch $cohesive_groups_list $groupid] != -1)} {
                            #     GiD_EntitiesGroups assign SKIN_SPHERE_DO_NOT_DELETE elements $new_element_id
                            # }

                        foreach container_group [GiD_EntitiesGroups entity_groups elements $element_id] {
                            # get the list of groups to which the element with id $element_id belongs
                            GiD_EntitiesGroups assign $container_group elements $new_element_id
                            # assign the element with id $new_element_id to each of the groups in the loop
                        }
                    }

                    # if {[lsearch $cohesive_groups_list $groupid] == -1} {
                        #     GiD_EntitiesGroups assign SKIN_SPHERE_DO_NOT_DELETE elements $list_of_elements_to_add_to_skin_sphere_group
                        # }

                    GiD_Mesh delete element [GiD_EntitiesGroups get $groupid elements -element_type hexahedra]
                    GiD_Mesh delete element [GiD_EntitiesGroups get $groupid elements -element_type tetrahedra]
                    GiD_Mesh delete element [GiD_EntitiesGroups get $groupid elements -element_type triangle]
                    set nodes_to_delete [lsort -integer -unique $nodes_to_delete]
                    # reorder the list and remove repeated nodes
                    foreach node_id $nodes_to_delete {
                        set gid_info [GiD_Info list_entities nodes $node_id]
                        if {![DEM::write::GetNodeHigherentities $node_id]} {
                            # if this node does not have higher entities
                            GiD_Mesh delete node $node_id
                            # delete the nodes of the element as long as it does not have higher entities
                        }
                    }
                    set point_node_ids [GiD_EntitiesGroups get $groupid nodes]
                    # This list exists only for groups made up of isolated points
                    foreach node_id $point_node_ids {
                        if {![DEM::write::GetNodeHigherentities $node_id]} {
                            if {$probldistr == "NormalDistribution"} {
                                set final_elem_radius [DEM::write::NormalDistribution $element_radius $standard_deviation $min_radius $max_radius]
                            } else {
                                set final_elem_radius [DEM::write::LognormalDistribution $element_radius $standard_deviation $min_radius $max_radius]
                            }

                            set new_element_id [GiD_Mesh create element append sphere 1 $node_id $final_elem_radius]
                            # create a new sphere element starting from the previous node and obtain its id

                            set list_of_groups_containing_this_elem [GiD_EntitiesGroups entity_groups nodes $node_id]
                            foreach container_group $list_of_groups_containing_this_elem {
                                GiD_EntitiesGroups assign $container_group elements $new_element_id
                            }
                        }
                    }
                    set extra_nodes [GiD_EntitiesGroups get $groupid nodes]
                    foreach node_id $extra_nodes {
                        if {![DEM::write::GetNodeHigherentities $node_id]} {
                            GiD_Mesh delete node $node_id
                        }
                    }
                } elseif {$FEMtoDEM == "AttheNodes"} {
                    # We first delete the elements (lines, triangles, quadrilaterals, tetrahedra or hexahedra) of this group,
                    # but not their nodes, which will be used for creating the new sheres
                    if {[GiD_EntitiesGroups get $groupid elements -count] >0} {GiD_Mesh delete element [GiD_EntitiesGroups get $groupid elements]}
                    foreach node_id [GiD_EntitiesGroups get $groupid nodes] {
                        if {$probldistr == "NormalDistribution"} {
                            set final_elem_radius [DEM::write::NormalDistribution $element_radius $standard_deviation $min_radius $max_radius]
                        } else {
                            set final_elem_radius [DEM::write::LognormalDistribution $element_radius $standard_deviation $min_radius $max_radius]
                        }
                        set new_element_id [GiD_Mesh create element append sphere 1 $node_id $final_elem_radius]
                        # create a new sphere element starting from the previous node and obtain its id
                        lappend list_of_elements_to_add_to_skin_sphere_group {*}$new_element_id

                        set list_of_groups_containing_this_elem [GiD_EntitiesGroups entity_groups nodes $node_id]
                        foreach container_group $list_of_groups_containing_this_elem {
                            GiD_EntitiesGroups assign $container_group elements $new_element_id
                        }
                    }

                    # if {[lsearch $cohesive_groups_list $groupid] == -1} {
                        #     GiD_EntitiesGroups assign SKIN_SPHERE_DO_NOT_DELETE elements $list_of_elements_to_add_to_skin_sphere_group
                        # }

                } elseif {$FEMtoDEM == "AtBothNodesAndCentroids"} {
                    set nodes_to_delete [list]
                    set element_ids [GiD_EntitiesGroups get $groupid elements]
                    # get the ids of all the elements in groupid

                    foreach element_id $element_ids {
                        # loop on each of the elements by id

                        set element_nodes [lrange [GiD_Mesh get element $element_id] 3 end]
                        # get the nodes of the element

                        lappend nodes_to_delete {*}$element_nodes
                        # add those nodes to the nodes_to_delete list
                        if {$probldistr == "NormalDistribution"} {
                            set final_elem_radius [DEM::write::NormalDistribution $element_radius $standard_deviation $min_radius $max_radius]
                        } else {
                            set final_elem_radius [DEM::write::LognormalDistribution $element_radius $standard_deviation $min_radius $max_radius]
                        }
                        set node_id [GiD_Mesh create node append [DEM::write::GetElementCenter $element_id]]
                        # create a new node starting from the center of the given element

                        set new_element_id [GiD_Mesh create element append sphere 1 $node_id $final_elem_radius]
                        # create a new sphere element starting from the previous node and obtain its id
                        lappend list_of_elements_to_add_to_skin_sphere_group {*}$new_element_id

                        foreach container_group [GiD_EntitiesGroups entity_groups elements $element_id] {
                            # get the list of groups to which the element with id $element_id belongs
                            GiD_EntitiesGroups assign $container_group elements $new_element_id
                            # assign the element with id $new_element_id to each of the groups in the loop
                        }
                    }

                    GiD_Mesh delete element [GiD_EntitiesGroups get $groupid elements -element_type hexahedra]
                    GiD_Mesh delete element [GiD_EntitiesGroups get $groupid elements -element_type tetrahedra]
                    GiD_Mesh delete element [GiD_EntitiesGroups get $groupid elements -element_type triangle]

                    foreach node_id [GiD_EntitiesGroups get $groupid nodes] {
                        if {$probldistr == "NormalDistribution"} {
                            set final_elem_radius [DEM::write::NormalDistribution $element_radius $standard_deviation $min_radius $max_radius]
                        } else {
                            set final_elem_radius [DEM::write::LognormalDistribution $element_radius $standard_deviation $min_radius $max_radius]
                        }

                        set new_element_id [GiD_Mesh create element append sphere 1 $node_id $final_elem_radius]
                        # create a new sphere element starting from the previous node and obtain its id
                        lappend list_of_elements_to_add_to_skin_sphere_group {*}$new_element_id

                        set list_of_groups_containing_this_elem [GiD_EntitiesGroups entity_groups nodes $node_id]
                        foreach container_group $list_of_groups_containing_this_elem {
                            GiD_EntitiesGroups assign $container_group elements $new_element_id
                        }
                    }

                    # if {[lsearch $cohesive_groups_list $groupid] == -1} {
                        #     GiD_EntitiesGroups assign SKIN_SPHERE_DO_NOT_DELETE elements $list_of_elements_to_add_to_skin_sphere_group
                        # }

                }
            } else {
                # 2D to 3D algorithm instead of FEM2DEM
                lassign [lindex [GiD_Info Mesh elements Circle -array] 0] type element_ids element_nodes element_materials element_radii
                foreach element_id $element_ids element_node [lindex $element_nodes 0] element_radius $element_radii {
                    set element_info($element_id) [list $element_node $element_radius]
                }
                set element_list [GiD_EntitiesGroups get $groupid elements]
                foreach element_id $element_list {
                    lassign $element_info($element_id) element_node element_radius
                    lappend group_nodes($groupid) $element_node
                    lappend group_radius($groupid) $element_radius
                }

                GiD_Mesh delete element [GiD_EntitiesGroups get $groupid elements]
                foreach node_id $group_nodes($groupid) radius $group_radius($groupid) {
                    set final_elem_radius $radius
                    set new_element_id [GiD_Mesh create element append sphere 1 $node_id $final_elem_radius]
                    # create a new sphere element starting from the previous node and obtain its id
                    lappend list_of_elements_to_add_to_skin_sphere_group {*}$new_element_id
                    set list_of_groups_containing_this_elem [GiD_EntitiesGroups entity_groups nodes $node_id]
                    foreach container_group $list_of_groups_containing_this_elem {
                        GiD_EntitiesGroups assign $container_group elements $new_element_id
                    }
                }

                # if {[lsearch $cohesive_groups_list $groupid] == -1} {
                    #     GiD_EntitiesGroups assign SKIN_SPHERE_DO_NOT_DELETE elements $list_of_elements_to_add_to_skin_sphere_group
                    # }
            }

        }

        lappend final_list_of_isolated_nodes {*}[lindex [GiD_EntitiesGroups get $groupid all_mesh] 0]
        DEM::write::Delete_Unnecessary_Elements_From_Mesh $groupid
    }

    DEM::write::Cleaning_Up_Skin_And_Removing_Isolated_Nodes $final_list_of_isolated_nodes
    # DEM::write::Destroy_Skin_Sphere_Group $KPriv(what_dempack_package)
    # Getting rid of the SKIN_SPHERE_DO_NOT_DELETE group when in discontinuum or swimming

    return $fail
}

proc DEM::write::Compute_External_Elements {ndime cgroupid element_ids} {

    set mesh_elements [GiD_EntitiesGroups get $cgroupid all_mesh]
    set real_mesh_elements [lindex $mesh_elements 1]
    set list_of_faces [list]
    foreach mesh_element_id $real_mesh_elements {
        set line($mesh_element_id) [GiD_Mesh get element $mesh_element_id]
        set partial_list_of_faces [lrange [GiD_Mesh get element $mesh_element_id] 3 end]
        lappend list_of_faces {*}$partial_list_of_faces
    }
    set unrepeated_list [lsort -integer -unique $list_of_faces]
    set elements_in_common 6 ; #TODO: Check this constant

    foreach list_elem $unrepeated_list {
        set result($list_elem) [lsearch -all $list_of_faces $list_elem]
        set length($list_elem) [llength $result($list_elem)]
        if {$length($list_elem)>$elements_in_common} {
            set todelete($list_elem) 1
        } else {
            set todelete($list_elem) 0
        }
    }
    foreach list_elem $unrepeated_list {
        if {$todelete($list_elem)==1} {
            set list_of_faces [lsearch -all -inline -not -exact $list_of_faces $list_elem]
        }
    }
    set unrepeated_list_exterior_nodes [lsort -integer -unique $list_of_faces]

    foreach element_id $element_ids { ; # Here we loop on each of the elements by id
        set element_nodes [lrange [GiD_Mesh get element $element_id] 3 end] ; # We get the nodes of the element

        set is_external_element($element_id) 0
        foreach element_node $element_nodes {
            if {[lsearch $unrepeated_list_exterior_nodes $element_node] != -1} {
                set is_external_element($element_id) 1
                break
            }
        }
    }
    return [array get is_external_element]
}

proc DEM::write::Delete_Unnecessary_Elements_From_Mesh {cgroupid} {
    set elem_types [list line triangle quadrilateral tetrahedra hexahedra]
    foreach elem_type $elem_types {
        if {[GiD_EntitiesGroups get $cgroupid elements -count -element_type $elem_type] > 0} {
            GiD_Mesh delete element [GiD_EntitiesGroups get $cgroupid elements -element_type $elem_type]
        }
    }
}

proc DEM::write::Cleaning_Up_Skin_And_Removing_Isolated_Nodes {final_list_of_isolated_nodes} {

    # GiD_EntitiesGroups unassign SKIN_SPHERE_DO_NOT_DELETE nodes
    # # GiD_Mesh delete element [GiD_EntitiesGroups get SKIN_SPHERE_DO_NOT_DELETE elements -element_type triangle]
    # GiD_Mesh delete element [GiD_EntitiesGroups get SKIN_SPHERE_DO_NOT_DELETE elements -element_type quadrilateral]
    # GiD_EntitiesGroups unassign SKIN_SPHERE_DO_NOT_DELETE elements [GiD_EntitiesGroups get SKIN_SPHERE_DO_NOT_DELETE elements -element_type linear]
    # GiD_EntitiesGroups unassign SKIN_SPHERE_DO_NOT_DELETE elements [GiD_EntitiesGroups get SKIN_SPHERE_DO_NOT_DELETE elements -element_type triangle]
    # GiD_EntitiesGroups unassign SKIN_SPHERE_DO_NOT_DELETE elements [GiD_EntitiesGroups get SKIN_SPHERE_DO_NOT_DELETE elements -element_type quadrilateral]

    foreach node_id [lsort -integer -unique $final_list_of_isolated_nodes] {
        if {![DEM::write::GetNodeHigherentities $node_id]} {
            GiD_Mesh delete node $node_id
        }
    }
}

proc DEM::write::NormalDistribution {mean standard_deviation min_rad max_rad} {
    if {$standard_deviation} {
        set max_iterations 1000 ; #set a maximun number of iterations to avoid an infinite loop
        for {set i 0} {$i < $max_iterations} {incr i} {
            set u1 [::tcl::mathfunc::rand]
            set u2 [::tcl::mathfunc::rand]
            #set distribution [expr {$mean + $standard_deviation * sqrt(-2.0 * log($u1)) * cos(6.28318530717958647692 * $u2)}]
            set distribution [math::statistics::random-normal $mean $standard_deviation 1] ; # We use the math::statistics library instead
            if {$distribution > $min_rad && $distribution < $max_rad} {
                return $distribution
            }
        }
        error "NormalDistribution failed after $max_iterations iterations. mean=$mean std_dev=$standard_deviation min_rad=$min_rad max_rad=$max_rad"
    }
    return $mean
}

proc DEM::write::LognormalDistribution {mean standard_deviation min_rad max_rad} {
    if {$standard_deviation} {
        set log_min [expr log($min_rad)]
        set log_max [expr log($max_rad)]
        set NormalMean [expr {log($mean * $mean / sqrt($standard_deviation * $standard_deviation + $mean * $mean))}]
        set NormalStdDev [expr sqrt(log(1.0 + $standard_deviation * $standard_deviation / ($mean * $mean)))]
        return [expr exp([DEM::write::NormalDistribution $NormalMean $NormalStdDev $log_min $log_max])]
    }
    return $mean
}

proc DEM::write::Destroy_Skin_Sphere_Group {what_dempack_package} {
    if {$what_dempack_package eq "G-DEMPack"} {
        if [GiD_Groups exists SKIN_SPHERE_DO_NOT_DELETE] {
            GiD_Groups delete SKIN_SPHERE_DO_NOT_DELETE
            GidUtils::EnableGraphics
            GidUtils::UpdateWindow GROUPS
            GidUtils::DisableGraphics
        }
    }
}

proc DEM::write::GetNodeHigherentities {node_id} {
    set node_data [GiD_Info list_entities nodes $node_id]
    if {![regexp {HigherEntity: ([0-9]+)} $node_data dummy higherentity]} {
        set higherentity 9999; #the node does not exist, return > 0 to not delete it
    }
    return $higherentity
}

proc DEM::write::GetElementCenter {element_id} {
    set element_data [GiD_Mesh get element $element_id]
    set num_nodes [lindex $element_data 2]
    set node_ids [lrange $element_data 3 2+$num_nodes]
    set sum {0 0 0}
    foreach node_id $node_ids {
        set coordinates [lrange [GiD_Mesh get node $node_id] 1 end]
        set sum [MathUtils::VectorSum $coordinates $sum]
    }
    return [MathUtils::ScalarByVectorProd [expr {1.0/$num_nodes}] $sum]
}

proc DEM::write::BeforeMeshGenerationUtils {elementsize} {

    # Align the normal
    DEM::write::AlignSurfNormals Outwards

    # Reset Automatic Conditions from previous executions
    set entitytype "surface"

    # Automatic Kratos Group for Boundary Condition
    set groupid "-AKGSkinMesh3D"
    DEM::write::CleanAutomaticConditionGroupGiD $entitytype $groupid

    # Find boundaries
    set bsurfacelist [DEM::write::FindBoundariesOfNonSphericElements $entitytype]
    set allsurfacelist [DEM::write::FindAllSurfacesOfNonSphericElements $entitytype]
    DEM::write::AssignGeometricalEntitiesToSkinSphere3D
    DEM::write::AssignGeometricalEntitiesToSkinSphere2D

    if {$::Model::SpatialDimension eq "2D"} {DEM::write::AssignGeometricalEntitiesToSkinSphere2D
    } else {DEM::write::AssignGeometricalEntitiesToSkinSphere3D}

    # Get the surface type list
    lassign [DEM::write::GetSurfaceTypeList $bsurfacelist] tetrasurf hexasurf

    # Triangle
    if {[llength $tetrasurf]} {
        # Assign the triangle element type
        GiD_Process Mescape Meshing ElemType Triangle $tetrasurf escape
        # Automatically meshing all the boundary surfaces
        GiD_Process Mescape Meshing MeshCriteria Mesh Surfaces {*}$tetrasurf escape
    }

    # Quadrilateral
    if {[llength $hexasurf]} {
        # Assign the quadrilateral element type
        GiD_Process Mescape Meshing ElemType Quadrilateral $hexasurf escape
        # Automatically meshing all the boundary surfaces
        GiD_Process Mescape Meshing MeshCriteria Mesh Surfaces {*}$hexasurf escape
    }
    DEM::write::AssignConditionToGroupGID $entitytype $bsurfacelist $groupid

    # Special case of DEM
    DEM::write::AssignSpecialBoundaries $allsurfacelist
    DEM::write::ForceTheMeshingOfDEMFEMWallGroups
    DEM::write::ForceTheMeshingOfDEMInletGroups

}

proc DEM::write::AlignSurfNormals {direction} {
    # ABSTRACT: Makes all of boundary surfaces' normals point inwards or outwards
    # Arguments
    # direction => Direction option ["Inwards"|"Outwards"]
    # Note: This procedure in the same used in the fluid_only problem type

    switch $direction {
        Inwards {
            set wrong_way "DIFF1ST"
        }
        Outwards {
            set wrong_way "SAME1ST"
        }
        default {puts "Unknown Direction, surface normals not aligned"}
    }
    set volumelist [GiD_Geometry list volume 1:]
    set surfacelist [list]

    # For each volume, we look for face surfaces with oriented in the wrong direction
    foreach volume $volumelist {
        set volumeinfo [GiD_Info list_entities volumes $volume]
        set numpos [lsearch $volumeinfo "NumSurfaces:"]
        set numsurf [lindex $volumeinfo [expr {$numpos +1 }]]
        for {set i 0} {$i < $numsurf} {incr i} {
            set orient [lindex $volumeinfo [expr {$numpos+5+4*$i}]]
            if {[string compare $orient $wrong_way]==0} {
                # If the normal is pointing in the wrong direction,
                # Check if it's a contour surface
                set surfnum [lindex $volumeinfo [expr {$numpos+3+4*$i}]]
                set surfinfo [GiD_Info list_entities surfaces $surfnum]
                set higherentities [lindex $surfinfo 4]
                if {$higherentities==1} {
                    lappend surfacelist $surfnum
                }
            }
        }
    }

    if {[llength $surfacelist]} {
        # If its in the contour, switch its normal
        eval GiD_Process Mescape Utilities SwapNormals Surfaces Select $surfacelist
    }
}

proc DEM::write::CleanAutomaticConditionGroupGiD {args {fieldvalue ""}} {
    if {![GiD_Groups exists $fieldvalue]} {
        GiD_Groups create $fieldvalue
    }
    GiD_Groups edit state $fieldvalue hidden
    # W [GiD_Groups get state $fieldvalue]
    # W "$fieldvalue [GiD_EntitiesGroups get $fieldvalue elements]"
    foreach entity $args {
        GiD_EntitiesGroups unassign $fieldvalue $entity
    }
    GidUtils::UpdateWindow GROUPS
}

proc DEM::write::FindBoundariesOfNonSphericElements {entity} {
    # ABSTRACT: Return a list containing all boundaries entities
    # Arguments
    # entity => Entity to be processed
    #  * entity=line for models made of surfaces
    #  * entity=surface for models made of volumes
    # Note: This procedure in the same used in the fluid_only problem type

    set root [customlib::GetBaseRoot]
    set xp1 "[spdAux::getRoute DEMParts]/group"
    set groups_to_spherize_list [list ]
    foreach group [$root selectNodes $xp1] {
        set groupid [$group @n]
        lappend groups_to_spherize_list $groupid
    }

    # set groups_to_spherize_list [::xmlutils::setXmlContainerIds {DEM//c.DEM-Elements//c.DEM-Element}]
    foreach volume_id [GiD_Geometry list volume 1:end] {
        set volume_info [GiD_Info list_entities volume $volume_id]
        set is_spheric [regexp {Elemtype=9} $volume_info]

        foreach group_that_includes_this_volume [GiD_EntitiesGroups entity_groups volumes $volume_id] {
            #next we search $group_that_includes_this_volume among $groups_to_spherize_list:
            if {[lsearch $groups_to_spherize_list $group_that_includes_this_volume] >= 0} {
                set is_spheric 1
            }
        }

        if {$is_spheric==0} {
            foreach item [lrange [GiD_Geometry get volume $volume_id] 2 end] {
                set surface_id [lindex $item 0]
                incr surfaces_higher_entities_list($surface_id)
            }
        }
    }

    set boundarylist [list]
    foreach surface_id [lsort -integer [array names surfaces_higher_entities_list]] {
        if {$surfaces_higher_entities_list($surface_id) == 1} {
            lappend boundarylist $surface_id
        }
    }
    return $boundarylist
}

proc DEM::write::FindAllSurfacesOfNonSphericElements {entity} {
    # ABSTRACT: Return a list containing all boundaries entities
    # Arguments
    # entity => surface

    set surf_high_entities [list]
    set surf_no_high_entities [list]
    set boundarylist [list]

    # Boundary surfaces of all the volumes in the domain
    foreach volume_id [GiD_Geometry list volume 1:end] {
        set volume_info [GiD_Info list_entities volume $volume_id]
        set is_spheric [regexp {Elemtype=9} $volume_info]

        # Sphere volumes are excluded
        if {$is_spheric==0} {
            foreach item [lrange [GiD_Geometry get volume $volume_id] 2 end] {
                lappend surf_high_entities [lindex $item 0]
            }
        }
    }

    # Surfaces with no higher entities (not belonging to a volume)
    set layers [GiD_Info layers]
    foreach layer $layers {
        lappend surf_no_high_entities [GiD_Info layers -entities surfaces -higherentity 0 $layer]
    }
    set boundarylist [concat {*}$surf_high_entities {*}$surf_no_high_entities]
    return $boundarylist
}

proc DEM::write::AssignGeometricalEntitiesToSkinSphere2D {} {

    set list_of_points [GiD_Geometry list point 1:end]
    set list_of_lines [GiD_Geometry list line 1:end]
    if {![GiD_Groups exists SKIN_SPHERE_DO_NOT_DELETE]} {
	GiD_Groups create SKIN_SPHERE_DO_NOT_DELETE
    }

    set points_to_add_to_skin_circles [list]
    set lines_to_add_to_skin_circles [list]
    set boundary_circle_line_list [DEM::write::FindBoundariesOfCircularElements line]

    set total_skin_line_circle_list [concat $lines_to_add_to_skin_circles $boundary_circle_line_list]
    set total_skin_circle_list [list $points_to_add_to_skin_circles $total_skin_line_circle_list {} {}]
    GiD_EntitiesGroups assign SKIN_SPHERE_DO_NOT_DELETE all_geometry $total_skin_circle_list
}


proc DEM::write::AssignGeometricalEntitiesToSkinSphere3D {} {

    set list_of_points [GiD_Geometry list point 1:end]
    set list_of_lines [GiD_Geometry list line 1:end]
    set list_of_surfaces [GiD_Geometry list surface 1:end]
    if {![GiD_Groups exists SKIN_SPHERE_DO_NOT_DELETE]} {
        GiD_Groups create SKIN_SPHERE_DO_NOT_DELETE
    }

    set points_to_add_to_skin_spheres [list]
    set lines_to_add_to_skin_spheres [list]
    set surfaces_to_add_to_skin_spheres [list]
    set bound_sphere_surface_list [DEM::write::FindBoundariesOfSphericElements surface]

    foreach point_id $list_of_points line_id $list_of_lines surface_id $list_of_surfaces {
        set point_info [GiD_Info list_entities point $point_id]
        set line_info [GiD_Info list_entities line $line_id]
        set surface_info [GiD_Info list_entities surface $surface_id]
        set point_has_no_higher_entities [regexp {HigherEntity: 0} $point_info]
        set line_has_no_higher_entities [regexp {HigherEntity: 0} $line_info]
        set surface_has_no_higher_entities [regexp {HigherEntity: 0} $surface_info]
        if {$point_has_no_higher_entities == 1} {
            lappend points_to_add_to_skin_spheres $point_id
        }
        if {$line_has_no_higher_entities == 1} {
            lappend lines_to_add_to_skin_spheres $line_id
        }
        if {$surface_has_no_higher_entities == 1} {
            # lappend surfaces_to_add_to_skin_spheres $surface_id; # esta linea es la que asigna skin a las placas. en el wcfk va bien
        }
    }
    set total_skin_surface_sphere_list [concat $surfaces_to_add_to_skin_spheres $bound_sphere_surface_list]
    set total_skin_sphere_list [list $points_to_add_to_skin_spheres $lines_to_add_to_skin_spheres $total_skin_surface_sphere_list {}]
    GiD_EntitiesGroups assign SKIN_SPHERE_DO_NOT_DELETE all_geometry $total_skin_sphere_list
}

proc DEM::write::GetSurfaceTypeList {surfacelist} {

    set tetrasurf [list]
    set hexasurf [list]
    foreach surfid $surfacelist {
        # Check for higher entity
        set cprop [GiD_Info list_entities -More surfaces $surfid]
        set isve 0
        regexp -nocase {higherentity: ([0-9]+)} $cprop none ivhe
        if {$ivhe} {
            set he [regexp -nocase {Higher entities volumes: (.)*} $cprop vol]
            if {$he && $vol !=""} {
                set voltype ""
                set vlist [lindex [lrange $vol 3 end-2] 0]
                set cvprop [GiD_Info list_entities volumes $vlist]
                regexp -nocase {Elemtype=([0-9]*)} $cvprop none voltype
                if {($voltype == 4) || ($voltype == 0) || ($voltype=="")} {
                    lappend tetrasurf $surfid
                } elseif {$voltype == 5} {
                    lappend hexasurf $surfid
                } else {
                    lappend tetrasurf $surfid
                }
            }
        }
    }
    return [list $tetrasurf $hexasurf]
}

proc DEM::write::AssignConditionToGroupGID {entity elist groupid} {
    # Need New GiD_group adaptation
    if {![GiD_Groups exists $groupid]} {
        GiD_Groups create $groupid
    }
    GiD_Groups edit state $groupid hidden
    GiD_EntitiesGroups assign $groupid $entity $elist
    GidUtils::UpdateWindow GROUPS
}

proc DEM::write::AssignSpecialBoundaries {entitylist} {
    #set DEMApplication "No"
    #catch {set DEMApplication [::xmlutils::setXml {GeneralApplicationData//c.ApplicationTypes//i.DEM} dv]}
    #if {$DEMApplication eq "Yes"} {

        # Automatic Kratos Group for all DEM boundary lines
        set groupid "-AKGDEMSkinMesh3D"
        set entitytype "line"
        DEM::write::CleanAutomaticConditionGroupGiD $entitytype $groupid

        # Get all end line list from the boundary surfaces
        set endlinelist [list]
        foreach surfid $entitylist {
            set surfprop [GiD_Geometry get surface $surfid]
            set surfacetype [lindex $surfprop 0]
            set nline [lindex $surfprop 2]
            set lineprop [list]
            if {$surfacetype eq "nurbssurface"} {
                set lineprop [lrange $surfprop 9 [expr {9+$nline-1}]]
            } else {
                set lineprop [lrange $surfprop 3 [expr {3+$nline-1}]]
            }
            foreach lprop $lineprop {
                lassign $lprop lineid orientation
                lappend endlinelist $lineid
            }
        }
        set endlinelist [lsort -integer -unique $endlinelist]

        # Assign the boundary condition
        DEM::write::AssignConditionToGroupGID $entitytype $endlinelist $groupid

        #}
}

proc DEM::write::ForceTheMeshingOfDEMFEMWallGroups {} {

    set root [customlib::GetBaseRoot]
    #set xp1 "[spdAux::getRoute DEMConditions]/group"DEM-FEM-Wall
    set xp1 "[spdAux::getRoute DEMConditions]/group"
    foreach group [$root selectNodes $xp1] {
        set groupid [$group @n]
        GiD_Process Mescape Meshing MeshCriteria Mesh Surfaces {*}[lindex [GiD_EntitiesGroups get $group_id all_geometry] 2] escape
    }

    # foreach group_id [::xmlutils::setXmlContainerIds "DEM//c.DEM-Conditions//c.DEM-FEM-Wall"] {
        #         GiD_Process Mescape Meshing MeshCriteria Mesh Surfaces {*}[lindex [GiD_EntitiesGroups get $group_id all_geometry] 2] escape
        # }
}

proc DEM::write::ForceTheMeshingOfDEMInletGroups {} {
    set root [customlib::GetBaseRoot]
    #set xp1 "[spdAux::getRoute DEMConditions]/group" Inlet
    set xp1 "[spdAux::getRoute DEMConditions]/group"
    foreach group [$root selectNodes $xp1] {
        set groupid [$group @n]
        GiD_Process Mescape Meshing MeshCriteria Mesh Surfaces {*}[lindex [GiD_EntitiesGroups get $group_id all_geometry] 2] escape
    }

    # foreach group_id [::xmlutils::setXmlContainerIds "DEM//c.DEM-Conditions//c.DEM-Inlet"] {
        #         GiD_Process Mescape Meshing MeshCriteria Mesh Surfaces {*}[lindex [GiD_EntitiesGroups get $group_id all_geometry] 2] escape
        # }
}

proc DEM::write::FindBoundariesOfCircularElements {entity} {


    set root [customlib::GetBaseRoot]
    set xp1 "[spdAux::getRoute DEMParts]/group"
    set groups_to_circularize_list [list ]
    foreach group [$root selectNodes $xp1] {
        set groupid [$group @n]
        lappend groups_to_circularize_list $groupid
    }

    # ld wckf:dem  code
    # set groups_to_circularize_list [::xmlutils::setXmlContainerIds {DEM//c.DEM-Elements//c.DEM-Element}]
    # foreach surface_id [GiD_Geometry list surface 1:end] {} ; #list of surface identifiers in the whole range
	# set surface_info [GiD_Info list_entities surface $surface_id] ; #info about those surfaces
	# set is_circular [regexp {Elemtype=10} $surface_info] ; #finding out if the element type is circular

    foreach surface_id [GiD_Geometry list surface 1:end] {
        set surface_info [GiD_Info list_entities surface $surface_id]
        set is_circular [regexp {Elemtype=10} $surface_info]

        foreach group_that_includes_this_surface [GiD_EntitiesGroups entity_groups surfaces $surface_id] {
        #next we search $group_that_includes_this_surface among $groups_to_circularize_list:
            if {[lsearch $groups_to_circularize_list $group_that_includes_this_surface] >= 0} {
                set is_circular 1
            }
        }

        set number_of_lines_in_the_surface [lindex [GiD_Geometry get surface $surface_id] 2]

        if {$is_circular==1} {
            foreach item [lrange [GiD_Geometry get surface $surface_id] 9 [expr {8 + $number_of_lines_in_the_surface}]] {
                set line_id [lindex $item 0]
                incr lines_higher_entities_list($line_id)
            }
        }
    }

    set boundarylist [list]
    foreach line_id [lsort -integer [array names lines_higher_entities_list]] {
        if {$lines_higher_entities_list($line_id) == 1} {
            lappend boundarylist $line_id
        }
    }
    return $boundarylist
}



proc DEM::write::FindBoundariesOfSphericElements {entity} {

    set root [customlib::GetBaseRoot]
    set xp1 "[spdAux::getRoute DEMParts]/group"
    set groups_to_spherize_list [list ]
    foreach group [$root selectNodes $xp1] {
            set groupid [$group @n]
            lappend groups_to_spherize_list $groupid
    }

    # set groups_to_spherize_list [::xmlutils::setXmlContainerIds {DEM//c.DEM-Elements//c.DEM-Element}]
    foreach volume_id [GiD_Geometry list volume 1:end] {
        set volume_info [GiD_Info list_entities volume $volume_id]
        set is_spheric [regexp {Elemtype=9} $volume_info]

        foreach group_that_includes_this_volume [GiD_EntitiesGroups entity_groups volumes $volume_id] {
            #next we search $group_that_includes_this_volume among $groups_to_spherize_list:
            if {[lsearch $groups_to_spherize_list $group_that_includes_this_volume] >= 0} {
                set is_spheric 1
            }
        }

        if {$is_spheric==1} {
            foreach item [lrange [GiD_Geometry get volume $volume_id] 2 end] {
                set surface_id [lindex $item 0]
                incr surfaces_higher_entities_list($surface_id)
            }
        }
    }

    set boundarylist [list]
    foreach surface_id [lsort -integer [array names surfaces_higher_entities_list]] {
        if {$surfaces_higher_entities_list($surface_id) == 1} {
            lappend boundarylist $surface_id
        }
    }
    return $boundarylist
}

