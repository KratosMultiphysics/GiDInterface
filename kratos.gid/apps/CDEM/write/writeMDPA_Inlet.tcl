proc DEM::write::DefineInletConditions {inletProperties groupid mid contains_clusters} {
    set inlet_element_type SphericContinuumParticle3D
    if {[dict get $inletProperties $groupid InletElementType] eq "Cluster3D"} {
        set inlet_element_type [dict get $inletProperties $groupid ClusterType]
        set contains_clusters 1
        lassign [GetClusterFileNameAndReplaceInletElementType $inlet_element_type] inlet_element_type cluster_file_name
    }
    if {$inlet_element_type eq "Cluster3D"} {
        write::WriteString "        CLUSTER_FILE_NAME $cluster_file_name"
    }
    if {[dict get $inletProperties $groupid InletElementType] eq "SphericParticle3D"} {
        dict set inletProperties $groupid InletElementType SphericContinuumParticle3D
    }
    write::WriteString "        IDENTIFIER $mid"
    write::WriteString "        INJECTOR_ELEMENT_TYPE SphericContinuumParticle3D"
    write::WriteString "        ELEMENT_TYPE [dict get $inletProperties $groupid InletElementType]"
    write::WriteString "        CONTAINS_CLUSTERS $contains_clusters"
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