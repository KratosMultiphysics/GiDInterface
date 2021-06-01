
proc DEM::write::GetInletElementType {} {
    set elem_name SphericContinuumParticle3D
    if {$::Model::SpatialDimension eq "2D"} {
        set elem_name CylinderContinuumParticle2D
    }
    return $elem_name
}
