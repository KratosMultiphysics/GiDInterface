proc DEM::write::DefineInletConditions {inletProperties groupid mid contains_clusters} {
    set inlet_element_type SphericContinuumParticle3D
    if {[dict get $inletProperties $groupid InletElementType] eq "Cluster3D"} {
        set contains_clusters 1
        if {[dict get $inletProperties $groupid ClusterType] eq "FromFile"} {
            set custom_file_name [dict get $inletProperties $groupid ClusterFilename]
            set only_name [file tail $custom_file_name]
            write::WriteString "        CLUSTER_FILE_NAME $only_name"

        } else {
            set cluster_file_name [dict get $inletProperties $groupid ClusterType]
            lassign [GetClusterFileNameAndReplaceInletElementType $cluster_file_name] inlet_element_type cluster_file_name
            write::WriteString "        CLUSTER_FILE_NAME $cluster_file_name"
        }
    }

    if {[dict get $inletProperties $groupid InletElementType] eq "SphericParticle3D"} {
        dict set inletProperties $groupid InletElementType SphericContinuumParticle3D
    }

    write::WriteString "        IDENTIFIER $mid"
    write::WriteString "        INJECTOR_ELEMENT_TYPE SphericContinuumParticle3D"
    write::WriteString "        ELEMENT_TYPE [dict get $inletProperties $groupid InletElementType]"
    write::WriteString "        CONTAINS_CLUSTERS $contains_clusters"
    # Change to SphericSwimmingParticle3D in FLUIDDEM interface
}

proc DEM::write::DefineInletConditions2D {inletProperties groupid mid contains_clusters} {
    set inlet_element_type CylinderContinuumParticle2D

    if {[dict get $inletProperties $groupid InletElementType] eq "CylinderParticle2D"} {
        dict set inletProperties $groupid InletElementType CylinderContinuumParticle2D
    }
    write::WriteString "        IDENTIFIER $mid"
    write::WriteString "        INJECTOR_ELEMENT_TYPE [dict get $inletProperties $groupid InletElementType]"
    write::WriteString "        ELEMENT_TYPE [dict get $inletProperties $groupid InletElementType]"
    write::WriteString "        CONTAINS_CLUSTERS 0"
    # Change to SphericSwimmingParticle3D in FLUIDDEM interface
}