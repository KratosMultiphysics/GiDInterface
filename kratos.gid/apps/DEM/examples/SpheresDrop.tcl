
proc ::DEM::examples::SpheresDrop {args} {
    if {![Kratos::IsModelEmpty]} {
        set txt "We are going to draw the example geometry.\nDo you want to lose your previous work?"
        set retval [tk_messageBox -default ok -icon question -message $txt -type okcancel]
        if { $retval == "cancel" } { return }
    }
    
    DrawGeometry
    AssignToTree
    
    GiD_Process 'Redraw
    GidUtils::UpdateWindow GROUPS
    GidUtils::UpdateWindow LAYER
}

proc ::DEM::examples::DrawGeometry { } {
    GiD_Process Mescape Geometry Create Object Rectangle -5 -5 0 5 5 0 escape 
    GiD_Process Mescape Geometry Create Object Rectangle -2 -2 5 2 2 5 escape 
    GiD_Process Mescape Geometry Create Object Sphere 0 0 2 1 escape 
    
    GiD_Groups create "Floor"
    GiD_Groups create "Inlet"
    GiD_Groups create "Body"
    
    GiD_EntitiesGroups assign "Floor" surfaces 1
    GiD_EntitiesGroups assign "Inlet" surfaces 2
    GiD_EntitiesGroups assign "Body" volumes 1
}

proc ::DEM::examples::AssignToTree { } {
    # Parts
    set DEMParts [spdAux::getRoute "DEMParts"]
    set DEMPartsNode [spdAux::AddConditionGroupOnXPath $DEMParts Body]
    set props [list PARTICLE_DENSITY 2500.0 YOUNG_MODULUS 1.0e6]
    foreach {prop val} $props {
        set propnode [$DEMPartsNode selectNodes "./value\[@n = '$prop'\]"]
        if {$propnode ne "" } {
            $propnode setAttribute v $val
        } else {
            W "Warning - Couldn't find property Parts $prop"
        }
    }
    
    # DEM FEM Walls
    set DEMConditions [spdAux::getRoute "DEMConditions"]
    set walls "$DEMConditions/condition\[@n='DEM-FEM-Wall'\]"
    set wallsNode [spdAux::AddConditionGroupOnXPath $walls Floor]
    $wallsNode setAttribute ov surface
    set props [list ]
    foreach {prop val} $props {
        set propnode [$wallsNode selectNodes "./value\[@n = '$prop'\]"]
        if {$propnode ne "" } {
            $propnode setAttribute v $val
        } else {
            W "Warning - Couldn't find property Outlet $prop"
        }
    }
    
    # Inlet
    set DEMInlet "$DEMConditions/condition\[@n='Inlet'\]"
    set inlets [list Total 2]
    ErasePreviousIntervals
    foreach {interval_name modulus} $inlets {
        GiD_Groups create "Inlet//$interval_name"
        GiD_Groups edit state "Inlet//$interval_name" hidden
        spdAux::AddIntervalGroup Inlet "Inlet//$interval_name"
        set inletNode [spdAux::AddConditionGroupOnXPath $DEMInlet "Inlet//$interval_name"]
        $inletNode setAttribute ov surface
        set props [list DIAMETER 0.1 PARTICLE_MATERIAL 2 YOUNG_MODULUS 1.0e6 VELOCITY_MODULUS $modulus Interval $interval_name DIRECTION_VECTORX 0.0 DIRECTION_VECTORZ -1.0]
        foreach {prop val} $props {
            set propnode [$inletNode selectNodes "./value\[@n = '$prop'\]"]
            if {$propnode ne "" } {
                $propnode setAttribute v $val
            } else {
                W "Warning - Couldn't find property Inlet $prop"
            }
        }
    }
    spdAux::RequestRefresh
}

proc DEM::examples::ErasePreviousIntervals { } {
    set root [customlib::GetBaseRoot]
    set interval_base [spdAux::getRoute "Intervals"]
    foreach int [$root selectNodes "$interval_base/blockdata\[@n='Interval'\]"] {
        if {[$int @name] ni [list Initial Total Custom1]} {$int delete}
    }
}