
proc ::Dam::examples::ThermoMechaDam {args} {
    
    DrawDamGeometry
    #~ AssignGroupsDam
    #~ AssignDamMeshSizes
    #~ TreeAssignationDam

    GiD_Process 'Redraw
    #~ GidUtils::UpdateWindow GROUPS
    #~ GidUtils::UpdateWindow LAYER
}

proc Dam::examples::DrawDamGeometry {args} {
    
    Kratos::ResetModel
    GiD_Layers create Dam
    GiD_Layers edit to_use Dam

    # Geometry creation
    ## Points ##
    set coordinates [list 0 0 0 10 0 0 3 30 0 0 30 0 ]
    set damPoints [list ]
    foreach {x y z} $coordinates {
         lappend damPoints [GiD_Geometry create point append Dam $x $y $z]
    }

    ## Lines ##
    set damLines [list ]
    set initial [lindex $damPoints 0]
    foreach point [lrange $damPoints 1 end] {
        lappend damLines [GiD_Geometry create line append stline Dam $initial $point]
        set initial $point
    }
    lappend damLines [GiD_Geometry create line append stline Dam $initial [lindex $damPoints 0]]

     ## Surface ##
    GiD_Process Mescape Geometry Create NurbsSurface {*}$damLines escape escape

    #~ # Soil #
    GiD_Layers create Soil
    GiD_Layers edit to_use Soil
    
    #~ # Geometry creation
    #~ ## Points ##
    set soil_coordinates [list -5 0 0 -5 -5 0 15 -5 0 15 0 0 ]
    set soilPoints [list ]
    foreach {x y z} $soil_coordinates {
        lappend soilPoints [GiD_Geometry create point append Soil $x $y $z]
    }
    
    ## Lines ##
    set soilLines [list ]
    set initial [lindex $damPoints 0]
    foreach point [lrange $soilPoints 0 end] {
        lappend soilLines [GiD_Geometry create line append stline Soil $initial $point]
        set initial $point
    }
    lappend soilLines [GiD_Geometry create line append stline Dam $initial [lindex $damPoints 1]]
    
    
    lappend soilLines 1
    
    ## Surface ##
    GiD_Process Mescape Geometry Create NurbsSurface {*}$soilLines escape escape
        
    
}

