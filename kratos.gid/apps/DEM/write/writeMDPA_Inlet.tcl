proc DEM::write::WriteMDPAInlet { } {
    # Headers
    write::writeModelPartData
    
    # process materials
    processInletMaterials
    
    # Properties section
    writeMaterialsInlet
    
    # Nodal coordinates (only for DEM Parts <inefficient> )
    write::writeNodalCoordinatesOnGroups [GetInletGroups]
    
    # SubmodelParts
    
    writeInletMeshes
    
    #Copy cluster files (.clu)
    copyClusterFiles
}

proc DEM::write::GetInletConditionName { } {
    set condition_name Inlet
    if {$::Model::SpatialDimension eq "2D"} {
        set condition_name Inlet2D
    }
    return $condition_name
}

proc DEM::write::GetInletConditionXpath { } {
    set condition_name [GetInletConditionName]
    set xp1 "[spdAux::getRoute [GetAttribute conditions_un]]/condition\[@n = '$condition_name'\]"
    return $xp1
}

# That can be all or active / All by default
proc DEM::write::GetInletGroups { {that all}} {
    set groups [list ]
    
    foreach group [[customlib::GetBaseRoot] selectNodes [DEM::write::GetInletConditionXpath]/group] {
        set groupid [$group @n]
        if {$that eq "active"} {
            set active_inlet [write::getValueByNodeChild $group SetActive]
            if {[write::isBooleanFalse $active_inlet]} {continue}
        }
        lappend groups [write::GetWriteGroupName $groupid]
    }
    return $groups
}


proc DEM::write::copyClusterFiles { } {
    
    set dir [write::GetConfigurationAttribute dir]
    set src_dir $::Kratos::kratos_private(Path)
    set cluster_dir [file join $src_dir exec Kratos applications DEMApplication custom_elements custom_clusters]
    
    set two_lists_of_clusters [GetUsedClusters ]
    set pre_built_clusters_list [lindex $two_lists_of_clusters 0]
    set custom_clusters_list [lindex $two_lists_of_clusters 1]
    foreach cluster $pre_built_clusters_list {
        set cluster_dem [lindex [DEM::write::GetClusterFileNameAndReplaceInletElementType $cluster] 1]
        set totalpath [file join $cluster_dir $cluster_dem]
        file copy -force $totalpath $dir
    }
    foreach totalpath $custom_clusters_list {
        set only_name [file tail $totalpath]
        set target_final_total_path [file join $dir $only_name]
        set suffix "temporary"
        #this is to avoid copying a file onto itself (giving problems in Windows)
        set target_temp_total_path $target_final_total_path$suffix
        file copy -force $totalpath $target_temp_total_path
        file copy -force $target_temp_total_path $target_final_total_path
        file delete -force $target_temp_total_path
    }
}

proc DEM::write::GetUsedClusters { } {
    variable inletProperties
    set clusters_list [list ]
    set custom_clusters_list [list]
    set condition_name [DEM::write::GetInletConditionName]

    foreach groupid [DEM::write::GetInletGroups] {
        if {[write::getSubModelPartId $condition_name $groupid] ne 0} {
            set mid [write::AddSubmodelpart $condition_name $groupid]
            set props [DEM::write::FindPropertiesBySubmodelpart $inletProperties $mid]
            if {[dict get $props Material Variables InletElementType] in [list "Cluster2D" "Cluster3D"]} {
                set inlet_element_type [dict get $props Material Variables ClusterType]
                if { $inlet_element_type == "FromFile" } {
                    set cluster_full_path [dict get $props Material Variables ClusterFilename]
                    lappend custom_clusters_list $cluster_full_path
                } else {
                    lappend clusters_list $inlet_element_type
                }
            }
        }
    }
    return [list $clusters_list $custom_clusters_list]
}

proc DEM::write::DefineInletConditions {inletProperties mid contains_clusters} {
    set inlet_element_type [DEM::write::GetInletElementType]
    if {[dict get $inletProperties Material Variables InletElementType] eq "Cluster3D"} {
        set contains_clusters 1
        if {[dict get $inletProperties Material Variables ClusterType] eq "FromFile"} {
            set custom_file_name [dict get $inletProperties Material Variables ClusterFilename]
            set only_name [file tail $custom_file_name]
            write::WriteString "        CLUSTER_FILE_NAME $only_name"
            
        } else {
            set cluster_file_name [dict get $inletProperties Material Variables ClusterType]
            lassign [GetClusterFileNameAndReplaceInletElementType $cluster_file_name] inlet_element_type cluster_file_name
            write::WriteString "        CLUSTER_FILE_NAME $cluster_file_name"
        }
    }
    
    write::WriteString "        IDENTIFIER $mid"
    write::WriteString "        INJECTOR_ELEMENT_TYPE [DEM::write::GetInjectorElementType]"
    write::WriteString "        ELEMENT_TYPE $inlet_element_type"
    write::WriteString "        CONTAINS_CLUSTERS $contains_clusters"
}

proc DEM::write::GetInletElementType {} {
    return SphericParticle3D
}
proc DEM::write::GetInjectorElementType {} {
    return SphericParticle3D
}

proc DEM::write::writeInletMeshes { } {
    variable inletProperties
    
    set condition_name [DEM::write::GetInletConditionName]
    
    foreach groupid [DEM::write::GetInletGroups] {
        set what nodal
        if {[write::getSubModelPartId $condition_name $groupid] eq 0} {
            set mid [write::AddSubmodelpart $condition_name $groupid]
            set props [DEM::write::FindPropertiesBySubmodelpart $inletProperties $mid]
            if {$props eq ""} {W "Error printing inlet $groupid"}
            set is_active [dict get $props Material Variables SetActive]
            if {[write::isBooleanFalse $is_active]} {
                continue
            }

            set group_real_name [write::GetWriteGroupName $groupid]
            set gdict [dict create]
            set f "%10i\n"
            set f [subst $f]
            dict set gdict $group_real_name $f
            write::WriteString "Begin SubModelPart $mid // Group $groupid // Subtree Inlet"
            write::WriteString "    Begin SubModelPartData"
            
            
            if {[write::isBooleanTrue $is_active]} {
                set motion_type [dict get $props Material Variables InletMotionType]
                set TableNumber 0
                set TableVelocityComponent 0
                if {$motion_type == "FromATable"} {
                    set TableNumber $mid
                    set TableVelocityComponent [dict get $props Material Variables TableVelocityComponent]
                }
                if {$motion_type=="LinearPeriodic"} {
                    
                    # Linear velocity
                    set velocity [dict get $props Material Variables VelocityModulus]
                    lassign [dict get $props Material Variables DirectionVector] velocity_X velocity_Y velocity_Z
                    if {$velocity_Z eq ""} {set velocity_Z 0.0}
                    lassign [MathUtils::VectorNormalized [list [string trim $velocity_X] [string trim $velocity_Y] [string trim $velocity_Z]]] velocity_X velocity_Y velocity_Z
                    lassign [MathUtils::ScalarByVectorProd $velocity [list $velocity_X $velocity_Y $velocity_Z] ] vx vy vz
                    write::WriteString "        LINEAR_VELOCITY \[3\] ($vx, $vy, $vz)"
                    if {$::Model::SpatialDimension eq "2D"} {
                        if {$vz ne "0.0"} {
                            error "Invalid value for LINEAR_VELOCITY Z : $vz"
                        }
                    }
                    
                    # Period
                    set periodic  [dict get $props Material Variables LinearPeriodic]
                    if {[write::isBooleanTrue $periodic]} {
                        set period  [dict get $props Material Variables LinearPeriod]
                    } else {
                        set period 0.0
                    }
                    write::WriteString "        VELOCITY_PERIOD $period"
                    
                    # Angular velocity
                    set avelocity [dict get $props Material Variables AngularVelocityModulus]
                    set wX 0.0; set wY 0.0; set wZ $avelocity
                    if {$::Model::SpatialDimension ne "2D"} {
                        lassign [dict get $inletProperties $groupid Variables AngularDirectionVector] velocity_X velocity_Y velocity_Z
                        lassign [MathUtils::VectorNormalized [list $velocity_X $velocity_Y $velocity_Z]] velocity_X velocity_Y velocity_Z
                        lassign [MathUtils::ScalarByVectorProd $avelocity [list $velocity_X $velocity_Y $velocity_Z] ] wX wY wZ
                    }
                    write::WriteString "        ANGULAR_VELOCITY \[3\] ($wX,$wY,$wZ)"
                    
                    # Angular center of rotation
                    lassign [dict get $props Material Variables CenterOfRotation] oX oY oZ
                    if {$oZ eq ""} {set oZ 0.0}
                    write::WriteString "        ROTATION_CENTER \[3\] ($oX,$oY,$oZ)"
                    
                    # Angular Period
                    set angular_periodic [dict get $props Material Variables AngularPeriodic]
                    if {[write::isBooleanTrue $angular_periodic]} {
                        set angular_period [dict get $props Material Variables AngularPeriod]
                    } else {
                        set angular_period 0.0
                    }
                    write::WriteString "        ANGULAR_VELOCITY_PERIOD $angular_period"
                    
                    set LinearStartTime [dict get $props Material Variables LinearStartTime]
                    set LinearEndTime  [dict get $props Material Variables LinearEndTime]
                    set AngularStartTime [dict get $props Material Variables AngularStartTime]
                    set AngularEndTime  [dict get $props Material Variables AngularEndTime]
                    set rigid_body_motion 1
                    write::WriteString "        VELOCITY_START_TIME $LinearStartTime"
                    write::WriteString "        VELOCITY_STOP_TIME $LinearEndTime"
                    write::WriteString "        ANGULAR_VELOCITY_START_TIME $AngularStartTime"
                    write::WriteString "        ANGULAR_VELOCITY_STOP_TIME $AngularEndTime"
                    write::WriteString "        RIGID_BODY_MOTION $rigid_body_motion"
                } else {
                    set rigid_body_motion 0
                    write::WriteString "        RIGID_BODY_MOTION $rigid_body_motion"
                    write::WriteString "        //TABLE_VELOCITY_COMPONENT $TableVelocityComponent"
                }
                
                set contains_clusters 0
                set random_orientation 0
                
                DefineInletConditions $props $mid $contains_clusters
                              
                set velocity_modulus [dict get $props Material Variables InVelocityModulus]
                lassign [dict get $props Material Variables InDirectionVector] velocity_X velocity_Y velocity_Z
                if {$velocity_Z eq ""} {set velocity_Z 0.0}
                lassign [MathUtils::VectorNormalized [list $velocity_X $velocity_Y $velocity_Z]] velocity_X velocity_Y velocity_Z
                lassign [MathUtils::ScalarByVectorProd $velocity_modulus [list $velocity_X $velocity_Y $velocity_Z] ] vx vy vz
                write::WriteString "        VELOCITY \[3\] ($vx, $vy, $vz)"
                
                set max_deviation_angle [dict get $props Material Variables VelocityDeviation]
                write::WriteString "        MAX_RAND_DEVIATION_ANGLE $max_deviation_angle"
                
                set type_of_measurement [dict get $props Material Variables TypeOfFlowMeasurement]
                if {$type_of_measurement eq "Kilograms"} {
                    set mass_flow_option 1
                } else {
                    set mass_flow_option 0
                }
                
                if {$mass_flow_option == 0} {
                    set inlet_number_of_particles [dict get $props Material Variables NumberOfParticles]
                    write::WriteString "        INLET_NUMBER_OF_PARTICLES $inlet_number_of_particles"
                }
                
                write::WriteString "        IMPOSED_MASS_FLOW_OPTION $mass_flow_option"
                
                # search for tem id="InletLimitedVelocity" related to dense inlet in spreaddem
                if {$mass_flow_option == 1} {
                    set inlet_mass_flow [dict get $props Material Variables InletMassFlow]
                    write::WriteString "        MASS_FLOW $inlet_mass_flow"
                }

                set inlet_start_time [dict get $props Material Variables InletStartTime]
                write::WriteString "        INLET_START_TIME $inlet_start_time"
                set inlet_stop_time [dict get $props Material Variables InletStopTime]
                write::WriteString "        INLET_STOP_TIME $inlet_stop_time"
                set particle_diameter [dict get $props Material Variables ParticleDiameter]
                write::WriteString "        RADIUS [expr {0.5 * $particle_diameter}]"
                set probability_distribution [dict get $props Material Variables ProbabilityDistribution]
                write::WriteString "        PROBABILITY_DISTRIBUTION $probability_distribution"
                set standard_deviation [dict get $props Material Variables StandardDeviation]
                write::WriteString "        STANDARD_DEVIATION $standard_deviation"
                
                if {[dict get $props Material Variables InletElementType] eq "Cluster3D"} {
                    if {[dict get $props Material Variables ClusterType] eq "SingleSphereCluster3D"} {
                        write::WriteString "        EXCENTRICITY [dict get $props Material Variables Excentricity]"
                        write::WriteString "        EXCENTRICITY_PROBABILITY_DISTRIBUTION [dict get $props Material Variables ProbabilityDistributionOfExcentricity]"
                        write::WriteString "        EXCENTRICITY_STANDARD_DEVIATION [dict get $props Material Variables StandardDeviationOfExcentricity]"
                    }
                }
                
                if {[dict get $props Material Variables InletElementType] eq "Cluster3D"} {
                    if {[dict get $props Material Variables RandomOrientation] == "Yes"} {
                        set random_orientation 1
                    } else {
                        set random_orientation 0
                        set orientation_x [dict get $props Material Variables OrientationX]
                        set orientation_y [dict get $props Material Variables OrientationY]
                        set orientation_z [dict get $props Material Variables OrientationZ]
                        set orientation_w [dict get $props Material Variables OrientationW]
                        write::WriteString "        ORIENTATION \[4\] ($orientation_x, $orientation_y, $orientation_z, $orientation_w)"
                    }
                    write::WriteString "        RANDOM_ORIENTATION $random_orientation"
                }
                
                write::WriteString "    End SubModelPartData"
                # Write nodes
                write::WriteString "    Begin SubModelPartNodes"
                GiD_WriteCalculationFile nodes -sorted $gdict
                write::WriteString "    End SubModelPartNodes"
                write::WriteString "  End SubModelPart"
                write::WriteString "    "
                
            }
        }
        
        if {$motion_type=="NotReady-FromATable"} {
            set properties_path "${basexpath}//c.[list ${cgroupid}]//c.MainProperties"
            set filename [::xmlutils::setXml "${properties_path}//i.VelocitiesFilename" dv]
            GiD_File fprintf $deminletchannel "Begin Table $TableNumber TIME VELOCITY"
            set file_open [open [file native [file join [::KUtils::GetPaths "PDir"] $filename]] r]
            set file_data [read $file_open]
            close $file_open
            GiD_File fprintf -nonewline $deminletchannel $file_data
            GiD_File fprintf $deminletchannel "End Table"
            GiD_File fprintf $deminletchannel ""
        }
        
        write::WriteString "  Begin Table 0 TIME VELOCITY"
        write::WriteString "  0.0  0.0"
        write::WriteString "  1.0  0.0"
        write::WriteString "  End Table"
        write::WriteString "  "
    }
}

proc DEM::write::GetClusterFileNameAndReplaceInletElementType {inlet_element_type} {
    if {$inlet_element_type eq "LineCluster3D"} {
        set inlet_element_type "Cluster3D"
        set cluster_file_name "linecluster3D.clu"
    } elseif {$inlet_element_type eq "RingCluster3D"} {
        set inlet_element_type "Cluster3D"
        set cluster_file_name "ringcluster3D.clu"
    } elseif {$inlet_element_type eq "Wheat5Cluster3D"} {
        set inlet_element_type "Cluster3D"
        set cluster_file_name "wheat5cluster3D.clu"
    } elseif {$inlet_element_type eq "SoyBeanCluster3D"} {
        set inlet_element_type "Cluster3D"
        set cluster_file_name "soybeancluster3D.clu"
    } elseif {$inlet_element_type eq "CornKernel3Cluster3D"} {
        set inlet_element_type "Cluster3D"
        set cluster_file_name "corn3cluster3D.clu"
    } elseif {$inlet_element_type eq "CornKernelCluster3D"} {
        set inlet_element_type "Cluster3D"
        set cluster_file_name "cornkernelcluster3D.clu"
    } elseif {$inlet_element_type eq "Rock1Cluster3D"} {
        set inlet_element_type "Cluster3D"
        set cluster_file_name "rock1cluster3D.clu"
    } elseif {$inlet_element_type eq "Rock2Cluster3D"} {
        set inlet_element_type "Cluster3D"
        set cluster_file_name "rock2cluster3D.clu"
    } elseif {$inlet_element_type eq "Ballast1Cluster3D"} {
        set inlet_element_type "Cluster3D"
        set cluster_file_name "ballast1cluster3D.clu"
    } elseif {$inlet_element_type eq "Ballast1Cluster3Dred"} {
        set inlet_element_type "Cluster3D"
        set cluster_file_name "ballast1cluster3Dred.clu"
    } elseif {$inlet_element_type eq "Ballast2Cluster3D"} {
        set inlet_element_type "Cluster3D"
        set cluster_file_name "ballast2cluster3D.clu"
    } elseif {$inlet_element_type eq "Ballast2Cluster3Dred"} {
        set inlet_element_type "Cluster3D"
        set cluster_file_name "ballast2cluster3Dred.clu"
    } elseif {$inlet_element_type eq "Ballast3Cluster3D"} {
        set inlet_element_type "Cluster3D"
        set cluster_file_name "ballast3cluster3D.clu"
    } elseif {$inlet_element_type eq "Ballast3Cluster3Dred"} {
        set inlet_element_type "Cluster3D"
        set cluster_file_name "ballast3cluster3Dred.clu"
    } elseif {$inlet_element_type eq "Ballast4Cluster3D"} {
        set inlet_element_type "Cluster3D"
        set cluster_file_name "ballast4cluster3D.clu"
    } elseif {$inlet_element_type eq "Ballast4Cluster3Dred"} {
        set inlet_element_type "Cluster3D"
        set cluster_file_name "ballast4cluster3Dred.clu"
    } elseif {$inlet_element_type eq "Ballast5Cluster3D"} {
        set inlet_element_type "Cluster3D"
        set cluster_file_name "ballast5cluster3D.clu"
    } elseif {$inlet_element_type eq "Ballast5Cluster3Dred"} {
        set inlet_element_type "Cluster3D"
        set cluster_file_name "ballast5cluster3Dred.clu"
    } elseif {$inlet_element_type eq "Ballast6Cluster3D"} {
        set inlet_element_type "Cluster3D"
        set cluster_file_name "ballast6cluster3D.clu"
    } elseif {$inlet_element_type eq "Ballast6Cluster3Dred"} {
        set inlet_element_type "Cluster3D"
        set cluster_file_name "ballast6cluster3Dred.clu"
    } elseif {$inlet_element_type eq "SoyBean3Cluster3D"} {
        set inlet_element_type "Cluster3D"
        set cluster_file_name "soybean3cluster3D.clu"
    } elseif {$inlet_element_type eq "CapsuleCluster3D"} {
        set inlet_element_type "Cluster3D"
        set cluster_file_name "capsulecluster3D.clu"
    } elseif {$inlet_element_type eq "SingleSphereCluster3D"} {
        set inlet_element_type "Cluster3D"
        set cluster_file_name "singlespherecluster3D.clu"
    } elseif {$inlet_element_type eq "Rock3RefinedCluster3D"} {
        set inlet_element_type "Cluster3D"
        set cluster_file_name "rock3refinedcluster3D.clu"
    } else {
        error "No cluster found"
    }
    
    return [list $inlet_element_type $cluster_file_name]
}

proc DEM::write::writeMaterialsInlet { } {
    
    write::WriteString "Begin Properties 0"
    write::WriteString "End Properties"
    write::WriteString ""
    
}

proc DEM::write::processInletMaterials { } {
    variable inletProperties
    set inlet_xpath [DEM::write::GetInletConditionXpath]
    write::processMaterials $inlet_xpath/group
    set inletProperties [write::getPropertiesListByConditionXPath $inlet_xpath 0 DEMInletPart]

}