proc DEM::write::WriteMDPAInlet { } {
    # Headers
    write::writeModelPartData

    writeMaterialsInlet

    # Nodal coordinates (only for DEM Parts <inefficient> )
    W "xxxxxxxxxxxxxxxxxxxxx inlet"
    write::writeNodalCoordinatesOnGroups [GetInletGroups]
    W "xxxxxxxxxxxxxxxxxxxxx inlet end"

    # SubmodelParts
    if {$::Model::SpatialDimension eq "2D"} { writeInletMeshes2D
    } else {writeInletMeshes}

    #Copy cluster files (.clu)
    copyClusterFiles
}

proc DEM::write::GetInletGroups { } {
    set groups [list ]
    if {$::Model::SpatialDimension eq "2D"} {set xp1 "[spdAux::getRoute [GetAttribute conditions_un]]/condition\[@n = 'Inlet2D'\]/group"
    } else { set xp1 "[spdAux::getRoute [GetAttribute conditions_un]]/condition\[@n = 'Inlet'\]/group"
    }
    foreach group [[customlib::GetBaseRoot] selectNodes $xp1] {
	set groupid [$group @n]
	lappend groups [write::GetWriteGroupName $groupid]
    }
    return $groups
}


proc DEM::write::copyClusterFiles { } {

    set dir [write::GetConfigurationAttribute dir]
    set src_dir $::Kratos::kratos_private(Path)
    set cluster_dir [file join $src_dir exec Kratos applications DEMApplication custom_elements custom_clusters]
    foreach cluster [GetUsedClusters ] {
	set cluster_dem [lindex [DEM::write::GetClusterFileNameAndReplaceInletElementType $cluster] 1]
	set totalpath [file join $cluster_dir $cluster_dem]
	file copy -force $totalpath $dir
    }
}

proc DEM::write::GetUsedClusters { } {
    variable inletProperties
    set cluster_list [list ]
    foreach groupid [dict keys $inletProperties ] {
	if {[dict get $inletProperties $groupid InletElementType] in [list "Cluster2D" "Cluster3D"]} {
	    set inlet_element_type [dict get $inletProperties $groupid ClusterType]
	    lappend cluster_list $inlet_element_type
	}
    }
    return $cluster_list
}


proc DEM::write::writeInletMeshes { } {
    variable inletProperties
    foreach groupid [dict keys $inletProperties ] {
	set what nodal
	if {![dict exists $::write::submodelparts [list Inlet ${groupid}]]} {
	    set mid [expr [llength [dict keys $::write::submodelparts]] +1]
	    set good_name [write::transformGroupName $groupid]
	    set mid "Inlet_${good_name}"
	    dict set ::write::submodelparts [list Inlet ${groupid}] $mid
	    set gdict [dict create]
	    set f "%10i\n"
	    set f [subst $f]
	    set group_real_name [write::GetWriteGroupName $groupid]
	    dict set gdict $group_real_name $f
	    write::WriteString "Begin SubModelPart $mid // Group $groupid // Subtree Inlet"
	    write::WriteString "    Begin SubModelPartData"
	    write::WriteString "        PROPERTIES_ID [dict get $inletProperties $groupid MID]"

	    set is_active [dict get $inletProperties $groupid SetActive]
	    if {$is_active=="No"} {
		    continue
		    }

	    if {[write::isBooleanTrue $is_active]} {
		set motion_type [dict get $inletProperties $groupid InletMotionType]
		set TableNumber 0
		set TableVelocityComponent 0
		if {$motion_type == "FromATable"} {
		    set TableNumber $mid
		    set TableVelocityComponent [dict get $inletProperties $groupid TableVelocityComponent]
		    }
		if {$motion_type=="LinearPeriodic"} {

		    # Linear velocity
		    set velocity  [dict get $inletProperties $groupid VelocityModulus]
		    lassign [split [dict get $inletProperties $groupid DirectionVector] ","] velocity_X velocity_Y velocity_Z
		    lassign [MathUtils::VectorNormalized [list $velocity_X $velocity_Y $velocity_Z]] velocity_X velocity_Y velocity_Z
		    lassign [MathUtils::ScalarByVectorProd $velocity [list $velocity_X $velocity_Y $velocity_Z] ] vx vy vz
		    write::WriteString "        LINEAR_VELOCITY \[3\] ($vx, $vy, $vz)"

		    # Period
		    set periodic  [dict get $inletProperties $groupid LinearPeriodic]
		    if {[write::isBooleanTrue $periodic]} {
		        #set period [write::getValueByNode [$group_node selectNodes "./value\[@n='LinearPeriod'\]"]]
		        set period  [dict get $inletProperties $groupid LinearPeriod]
		    } else {
		        set period 0.0
		    }
		    write::WriteString "        VELOCITY_PERIOD $period"

		    # Angular velocity
		    #set velocity [write::getValueByNode [$group_node selectNodes "./value\[@n='AngularVelocityModulus'\]"]]
		    set velocity  [dict get $inletProperties $groupid AngularVelocityModulus]
		    lassign [split [dict get $inletProperties $groupid AngularDirectionVector] ","] velocity_X velocity_Y velocity_Z
		    lassign [MathUtils::VectorNormalized [list $velocity_X $velocity_Y $velocity_Z]] velocity_X velocity_Y velocity_Z
		    lassign [MathUtils::ScalarByVectorProd $velocity [list $velocity_X $velocity_Y $velocity_Z] ] wX wY wZ
		    write::WriteString "        ANGULAR_VELOCITY \[3\] ($wX,$wY,$wZ)"


		    # Angular center of rotation
		    #lassign [write::getValueByNode [$group_node selectNodes "./value\[@n='CenterOfRotation'\]"]] oX oY oZ
		    lassign [split [dict get $inletProperties $groupid CenterOfRotation] ","] oX oY oZ
		    write::WriteString "        ROTATION_CENTER \[3\] ($oX,$oY,$oZ)"

		    # Angular Period
		    set angular_periodic [dict get $inletProperties $groupid AngularPeriodic]
		    if {[write::isBooleanTrue $angular_periodic]} {
		        set angular_period [dict get $inletProperties $groupid AngularPeriod]
		    } else {
		        set angular_period 0.0
		    }
		    write::WriteString "        ANGULAR_VELOCITY_PERIOD $angular_period"

		    # # Interval
		    # set interval [write::getValueByNode [$group_node selectNodes "./value\[@n='Interval'\]"]]
		    # lassign [write::getInterval $interval] ini end
		    # if {![string is double $ini]} {
		    #     set ini [write::getValue DEMTimeParameters StartTime]
		    # }
		    # # write::WriteString "    ${cond}_START_TIME $ini"
		    # write::WriteString "    VELOCITY_START_TIME $ini"
		    # write::WriteString "    ANGULAR_VELOCITY_START_TIME $ini"
		    # if {![string is double $end]} {
		    #     set end [write::getValue DEMTimeParameters EndTime]
		    # }
		    # # write::WriteString "    ${cond}_STOP_TIME $end"
		    # write::WriteString "    VELOCITY_STOP_TIME $end"
		    # write::WriteString "    ANGULAR_VELOCITY_STOP_TIME $end"


		    set LinearStartTime [dict get $inletProperties $groupid LinearStartTime]
		    set LinearEndTime  [dict get $inletProperties $groupid LinearEndTime]
		    set AngularStartTime [dict get $inletProperties $groupid AngularStartTime]
		    set AngularEndTime  [dict get $inletProperties $groupid AngularEndTime]
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

		# TODO. review cluster injection options for $inlet_element_type
		set inlet_element_type SphericParticle3D
		if {[dict get $inletProperties $groupid InletElementType] eq "Cluster3D"} {
		    set inlet_element_type [dict get $inletProperties $groupid ClusterType]
		    set contains_clusters 1
		    lassign [GetClusterFileNameAndReplaceInletElementType $inlet_element_type] inlet_element_type cluster_file_name
		}

		if {$inlet_element_type eq "Cluster3D"} {
		    write::WriteString "        CLUSTER_FILE_NAME $cluster_file_name"
		}

		write::WriteString "        IDENTIFIER $mid"
		write::WriteString "        INJECTOR_ELEMENT_TYPE SphericParticle3D"
		write::WriteString "        ELEMENT_TYPE [dict get $inletProperties $groupid InletElementType]"
		write::WriteString "        CONTAINS_CLUSTERS $contains_clusters"
		# Change to SphericSwimmingParticle3D in FLUIDDEM interface

		set velocity_modulus [dict get $inletProperties $groupid InVelocityModulus]
		lassign [split [dict get $inletProperties $groupid InDirectionVector] ","] velocity_X velocity_Y velocity_Z
		#lassign [write::getValueByNode [dict get $inletProperties $groupid DirectionVector]] velocity_X velocity_Y velocity_Z
		lassign [MathUtils::VectorNormalized [list $velocity_X $velocity_Y $velocity_Z]] velocity_X velocity_Y velocity_Z
		lassign [MathUtils::ScalarByVectorProd $velocity_modulus [list $velocity_X $velocity_Y $velocity_Z] ] vx vy vz
		write::WriteString "        VELOCITY \[3\] ($vx, $vy, $vz)"

		set max_deviation_angle [dict get $inletProperties $groupid VelocityDeviation]
		write::WriteString "        MAX_RAND_DEVIATION_ANGLE $max_deviation_angle"


		if {[dict get $inletProperties $groupid InletElementType] eq "Cluster3D"} {
		    if {[dict get $inletProperties $groupid ClusterType] eq "SingleSphereCluster3D"} {
		        write::WriteString "        EXCENTRICITY [dict get $inletProperties $groupid Excentricity]"
		        write::WriteString "        EXCENTRICITY_PROBABILITY_DISTRIBUTION [dict get $inletProperties $groupid ProbabilityDistributionOfExcentricity]"
		        write::WriteString "        EXCENTRICITY_STANDARD_DEVIATION [dict get $inletProperties $groupid StandardDeviationOfExcentricity]"
		    }
		}

		set type_of_measurement [dict get $inletProperties $groupid TypeOfFlowMeasurement]
		if {$type_of_measurement eq "Kilograms"} {
		    set mass_flow_option 1
		} else {
		    set mass_flow_option 0
		}

		if {$mass_flow_option == 0} {
		    set inlet_number_of_particles [dict get $inletProperties $groupid NumberOfParticles]
		    write::WriteString "        INLET_NUMBER_OF_PARTICLES $inlet_number_of_particles"
		}

		write::WriteString "        IMPOSED_MASS_FLOW_OPTION $mass_flow_option"

		# search for tem id="InletLimitedVelocity" related to dense inlet in spreaddem
		if {$mass_flow_option == 1} {
		set inlet_mass_flow [dict get $inletProperties $groupid InletMassFlow]
		    write::WriteString "        MASS_FLOW $inlet_mass_flow"
		}
		set inlet_start_time [dict get $inletProperties $groupid InletStartTime]
		write::WriteString "        INLET_START_TIME $inlet_start_time"
		set inlet_stop_time [dict get $inletProperties $groupid InletStopTime]
		write::WriteString "        INLET_STOP_TIME $inlet_stop_time"
		set particle_diameter [dict get $inletProperties $groupid ParticleDiameter]
		write::WriteString "        RADIUS [expr {0.5 * $particle_diameter}]"
		set probability_distribution [dict get $inletProperties $groupid ProbabilityDistribution]
		write::WriteString "        PROBABILITY_DISTRIBUTION $probability_distribution"
		set standard_deviation [dict get $inletProperties $groupid StandardDeviation]
		write::WriteString "        STANDARD_DEVIATION $standard_deviation"

                if {[dict get $inletProperties $groupid InletElementType] eq "Cluster3D"} {
                    if {[dict get $inletProperties $groupid RandomOrientation] == "Yes"} {
                        set random_orientation 1
                    } else {
                        set random_orientation 0
                        set orientation_x [dict get $inletProperties $groupid OrientationX]
                        set orientation_y [dict get $inletProperties $groupid OrientationY]
                        set orientation_z [dict get $inletProperties $groupid OrientationZ]
                        set orientation_w [dict get $inletProperties $groupid OrientationW]
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

    write::WriteString "        Begin Table 0 TIME VELOCITY"
    write::WriteString "        0.0  0.0"
    write::WriteString "        1.0  0.0"
    write::WriteString "        End Table"
    write::WriteString "        "
    }
}


proc DEM::write::writeInletMeshes2D { } {
    variable inletProperties
    foreach groupid [dict keys $inletProperties ] {
        set what nodal
        if {![dict exists $::write::submodelparts [list Inlet ${groupid}]]} {
            set mid [expr [llength [dict keys $::write::submodelparts]] +1]
            set good_name [write::transformGroupName $groupid]
            set mid "Inlet_${good_name}"
            dict set ::write::submodelparts [list Inlet ${groupid}] $mid
            set gdict [dict create]
            set f "%10i\n"
            set f [subst $f]
            set group_real_name [write::GetWriteGroupName $groupid]
            dict set gdict $group_real_name $f
            write::WriteString "Begin SubModelPart $mid // Group $groupid // Subtree Inlet"
            write::WriteString "    Begin SubModelPartData"
            write::WriteString "        PROPERTIES_ID [dict get $inletProperties $groupid MID]"

            set is_active [dict get $inletProperties $groupid SetActive]
            if {$is_active=="No"} {
	            continue
	            }

            if {[write::isBooleanTrue $is_active]} {
                set motion_type [dict get $inletProperties $groupid InletMotionType]
                set TableNumber 0
                set TableVelocityComponent 0
                if {$motion_type == "FromATable"} {
                    set TableNumber $mid
                    set TableVelocityComponent [dict get $inletProperties $groupid TableVelocityComponent]
                    }
                if {$motion_type=="LinearPeriodic"} {

                    # Linear velocity
                    set velocity  [dict get $inletProperties $groupid VelocityModulus]
                    lassign [split [dict get $inletProperties $groupid DirectionVector] ","] velocity_X velocity_Y
                    lassign [MathUtils::VectorNormalized [list $velocity_X $velocity_Y]] velocity_X velocity_Y
                    lassign [MathUtils::ScalarByVectorProd $velocity [list $velocity_X $velocity_Y] ] vx vy
                    write::WriteString "        LINEAR_VELOCITY \[3\] ($vx, $vy, 0.0)"


                    # Period
                    set periodic  [dict get $inletProperties $groupid LinearPeriodic]
                    if {[write::isBooleanTrue $periodic]} {
                        #set period [write::getValueByNode [$group_node selectNodes "./value\[@n='LinearPeriod'\]"]]
                        set period  [dict get $inletProperties $groupid LinearPeriod]
                    } else {
                        set period 0.0
                    }
                    write::WriteString "        VELOCITY_PERIOD $period"

                    # Angular velocity
                    #set velocity [write::getValueByNode [$group_node selectNodes "./value\[@n='AngularVelocityModulus'\]"]]
                    set avelocity  [dict get $inletProperties $groupid AngularVelocityModulus]
                    write::WriteString "        ANGULAR_VELOCITY \[3\] (0.0,0.0,$avelocity)"

                    # Angular center of rotation
                    #lassign [write::getValueByNode [$group_node selectNodes "./value\[@n='CenterOfRotation'\]"]] oX oY oZ
                    lassign [split [dict get $inletProperties $groupid CenterOfRotation] ","] oX oY
                    write::WriteString "        ROTATION_CENTER \[3\] ($oX,$oY,0.0)"

                    # Angular Period
                    set angular_periodic [dict get $inletProperties $groupid AngularPeriodic]
                    if {[write::isBooleanTrue $angular_periodic]} {
                        set angular_period [dict get $inletProperties $groupid AngularPeriod]
                    } else {
                        set angular_period 0.0
                    }
                    write::WriteString "        ANGULAR_VELOCITY_PERIOD $angular_period"

                    # # Interval
                    # set interval [write::getValueByNode [$group_node selectNodes "./value\[@n='Interval'\]"]]
                    # lassign [write::getInterval $interval] ini end
                    # if {![string is double $ini]} {
                    #     set ini [write::getValue DEMTimeParameters StartTime]
                    # }
                    # # write::WriteString "    ${cond}_START_TIME $ini"
                    # write::WriteString "    VELOCITY_START_TIME $ini"
                    # write::WriteString "    ANGULAR_VELOCITY_START_TIME $ini"
                    # if {![string is double $end]} {
                    #     set end [write::getValue DEMTimeParameters EndTime]
                    # }
                    # # write::WriteString "    ${cond}_STOP_TIME $end"
                    # write::WriteString "    VELOCITY_STOP_TIME $end"
                    # write::WriteString "    ANGULAR_VELOCITY_STOP_TIME $end"


                    set LinearStartTime [dict get $inletProperties $groupid LinearStartTime]
                    set LinearEndTime  [dict get $inletProperties $groupid LinearEndTime]
                    set AngularStartTime [dict get $inletProperties $groupid AngularStartTime]
                    set AngularEndTime  [dict get $inletProperties $groupid AngularEndTime]
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

                # TODO. review cluster injection options for $inlet_element_type
                set inlet_element_type CylinderPartDEMElement2D

                write::WriteString "        IDENTIFIER $mid"
                write::WriteString "        INJECTOR_ELEMENT_TYPE [dict get $inletProperties $groupid InletElementType]"
                write::WriteString "        ELEMENT_TYPE [dict get $inletProperties $groupid InletElementType]"
                write::WriteString "        CONTAINS_CLUSTERS 0"
                # Change to SphericSwimmingParticle3D in FLUIDDEM interface

                set velocity_modulus [dict get $inletProperties $groupid InVelocityModulus]
                lassign [split [dict get $inletProperties $groupid InDirectionVector] ","] velocity_X velocity_Y
                lassign [MathUtils::VectorNormalized [list $velocity_X $velocity_Y]] velocity_X velocity_Y
                lassign [MathUtils::ScalarByVectorProd $velocity_modulus [list $velocity_X $velocity_Y] ] vx vy
                write::WriteString "        VELOCITY \[3\] ($vx, $vy, 0.0)"

                set max_deviation_angle [dict get $inletProperties $groupid VelocityDeviation]
                write::WriteString "        MAX_RAND_DEVIATION_ANGLE $max_deviation_angle"

                set type_of_measurement [dict get $inletProperties $groupid TypeOfFlowMeasurement]
                if {$type_of_measurement eq "Kilograms"} {
                    set mass_flow_option 1
                } else {
                    set mass_flow_option 0
                }

                if {$mass_flow_option == 0} {
                    set inlet_number_of_particles [dict get $inletProperties $groupid NumberOfParticles]
                    write::WriteString "        INLET_NUMBER_OF_PARTICLES $inlet_number_of_particles"
                }

                write::WriteString "        IMPOSED_MASS_FLOW_OPTION $mass_flow_option"

                # search for tem id="InletLimitedVelocity" related to dense inlet in spreaddem
                if {$mass_flow_option == 1} {
                set inlet_mass_flow [dict get $inletProperties $groupid InletMassFlow]
                    write::WriteString "        MASS_FLOW $inlet_mass_flow"
                }
                set inlet_start_time [dict get $inletProperties $groupid InletStartTime]
                write::WriteString "        INLET_START_TIME $inlet_start_time"
                set inlet_stop_time [dict get $inletProperties $groupid InletStopTime]
                write::WriteString "        INLET_STOP_TIME $inlet_stop_time"
                set particle_diameter [dict get $inletProperties $groupid ParticleDiameter]
                write::WriteString "        RADIUS [expr {0.5 * $particle_diameter}]"
                set probability_distribution [dict get $inletProperties $groupid ProbabilityDistribution]
                write::WriteString "        PROBABILITY_DISTRIBUTION $probability_distribution"
                set standard_deviation [dict get $inletProperties $groupid StandardDeviation]
                write::WriteString "        STANDARD_DEVIATION $standard_deviation"

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

    write::WriteString "        Begin Table 0 TIME VELOCITY"
    write::WriteString "        0.0  0.0"
    write::WriteString "        1.0  0.0"
    write::WriteString "        End Table"
    write::WriteString "        "
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



proc DEM::write::writeInletMeshes-old { } {
    variable inletProperties
    foreach groupid [dict keys $inletProperties ] {
	set what nodal
	if {![dict exists $::write::submodelparts [list Inlet ${groupid}]]} {
	    set mid [expr [llength [dict keys $::write::submodelparts]] +1]
	    set good_name [write::transformGroupName $groupid]
	    set mid "Inlet_${good_name}"
	    dict set ::write::submodelparts [list Inlet ${groupid}] $mid
	    set gdict [dict create]
	    set f "%10i\n"
	    set f [subst $f]
	    set group_real_name [write::GetWriteGroupName $groupid]
	    dict set gdict $group_real_name $f
	    write::WriteString "Begin SubModelPart $mid // Group $groupid // Subtree Inlet"
	    write::WriteString "    Begin SubModelPartData"
	    write::WriteString "        PROPERTIES_ID [dict get $inletProperties $groupid MID]"
	    write::WriteString "        RIGID_BODY_MOTION 0"
	    write::WriteString "        IDENTIFIER $mid"
	    write::WriteString "        INJECTOR_ELEMENT_TYPE [dict get $inletProperties $groupid InletElementType]"
	    write::WriteString "        ELEMENT_TYPE [dict get $inletProperties $groupid InletElementType]"
	    write::WriteString "        CONTAINS_CLUSTERS 0"
	    set velocity [dict get $inletProperties $groupid VELOCITY_MODULUS]
	    lassign [split [dict get $inletProperties $groupid DIRECTION_VECTOR] ","] velocity_X velocity_Y velocity_Z
	    lassign [MathUtils::VectorNormalized [list $velocity_X $velocity_Y $velocity_Z]] velocity_X velocity_Y velocity_Z
	    lassign [MathUtils::ScalarByVectorProd $velocity [list $velocity_X $velocity_Y $velocity_Z] ] vx vy vz
	    write::WriteString "        VELOCITY \[3\] ($vx, $vy, $vz)"
	    write::WriteString "        MAX_RAND_DEVIATION_ANGLE [dict get $inletProperties $groupid MAX_RAND_DEVIATION_ANGLE]"
	    set type_of_measurement [dict get $inletProperties $groupid FLOW_MEASUREMENT]
	    if {$type_of_measurement eq "Kilograms"} {
		set number_of_particles 200.0
		set mass_flow_option 1
		set mass_flow [dict get $inletProperties $groupid INLET_NUMBER_OF_KILOGRAMS]
	    } else {
		set number_of_particles [dict get $inletProperties $groupid INLET_NUMBER_OF_PARTICLES]
		set mass_flow_option 0
		set mass_flow 0.5
		write::WriteString "        INLET_NUMBER_OF_PARTICLES $number_of_particles"
	    }
	    write::WriteString "        IMPOSED_MASS_FLOW_OPTION $mass_flow_option"
	    write::WriteString "        MASS_FLOW $mass_flow"
	    set interval [dict get $inletProperties $groupid Interval]
	    lassign [write::getInterval $interval] ini end
	    write::WriteString "        INLET_START_TIME $ini"
	    if {$end in [list "End" "end"]} {set end [write::getValue DEMTimeParameters EndTime]}
	    write::WriteString "        INLET_STOP_TIME $end"
	    set diameter [dict get $inletProperties $groupid DIAMETER]
	    write::WriteString "        RADIUS [expr $diameter / 2]"
	    write::WriteString "        PROBABILITY_DISTRIBUTION [dict get $inletProperties $groupid PROBABILITY_DISTRIBUTION]"
	    write::WriteString "        STANDARD_DEVIATION [dict get $inletProperties $groupid STANDARD_DEVIATION]"
	    write::WriteString "        RANDOM_ORIENTATION 1"
	    write::WriteString "        ORIENTATION \[4\] (0.0, 0.0, 0.0, 1.0)"

	    write::WriteString "    End SubModelPartData"
	    write::WriteString "    Begin SubModelPartNodes"
	    GiD_WriteCalculationFile nodes -sorted $gdict
	    write::WriteString "    End SubModelPartNodes"
	    write::WriteString "End SubModelPart"
	}
    }
}

proc DEM::write::writeMaterialsInlet { } {
    variable inletProperties
    variable last_property_id
    W "1-"
    if {$::Model::SpatialDimension eq "2D"} {set xp1 "[spdAux::getRoute [GetAttribute conditions_un]]/condition\[@n = 'Inlet2D'\]/group"
    } else { set xp1 "[spdAux::getRoute [GetAttribute conditions_un]]/condition\[@n = 'Inlet'\]/group"
    }
    W $xp1
    W $last_property_id
    W [dict size $::write::mat_dict]
    set old_mat_dict $::write::mat_dict
    set ::write::mat_dict [dict create]
    W "2-"
    write::processMaterials $xp1 $DEM::write::last_property_id
    W "3-"
    set DEM::write::last_property_id [expr $last_property_id + [dict size $::write::mat_dict]]
    W "4-"
    set inletProperties $::write::mat_dict
    set ::write::mat_dict $old_mat_dict
    # WV inletProperties
    W "5-"
    set printable [list PARTICLE_DENSITY YOUNG_MODULUS POISSON_RATIO FRICTION PARTICLE_COHESION COEFFICIENT_OF_RESTITUTION PARTICLE_MATERIAL ROLLING_FRICTION ROLLING_FRICTION_WITH_WALLS PARTICLE_SPHERICITY DEM_DISCONTINUUM_CONSTITUTIVE_LAW_NAME DEM_CONTINUUM_CONSTITUTIVE_LAW_NAME]

    foreach group [dict keys $inletProperties] {
        W "foreach group inletProperties"
        write::WriteString "Begin Properties [dict get $inletProperties $group MID] // Inlet group: [write::GetWriteGroupName $group]"
        if {$::Model::SpatialDimension eq "2D"} {set DEM_D_law "DEM_D_Hertz_viscous_Coulomb2D"
        } else { set DEM_D_law "DEM_D_Hertz_viscous_Coulomb"
        }

        dict set inletProperties $group DEM_DISCONTINUUM_CONSTITUTIVE_LAW_NAME $DEM_D_law
        dict set inletProperties $group DEM_CONTINUUM_CONSTITUTIVE_LAW_NAME DEMContinuumConstitutiveLaw
        foreach {prop val} [dict get $inletProperties $group] {
            if {$prop in $printable} {
                write::WriteString "    $prop $val"
            }
        }
        write::WriteString "End Properties\n"
    }
    W "end"
}