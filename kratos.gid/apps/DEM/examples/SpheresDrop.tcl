
proc ::DEM::examples::SpheresDrop {args} {
    if {![Kratos::IsModelEmpty]} {
        set txt "We are going to draw the example geometry.\nDo you want to lose your previous work?"
        set retval [tk_messageBox -default ok -icon question -message $txt -type okcancel]
        if { $retval == "cancel" } { return }
    }
    
    DrawGeometry
    AssignToTree
    AssignMeshSize
    
    GiD_Process 'Redraw
    GidUtils::UpdateWindow GROUPS
    GidUtils::UpdateWindow LAYER
}

proc ::DEM::examples::DrawGeometry { } {
    Kratos::ResetModel
    GiD_Process Mescape Geometry Create Object Rectangle -5 -5 0 5 5 0 escape 
    GiD_Process Mescape Geometry Create Object Rectangle -2 -2 5 2 2 5 escape 
    GiD_Process Mescape Geometry Create Object Sphere 0 0 2 1 escape escape 
    
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
    set DEMPartsNode [customlib::AddConditionGroupOnXPath $DEMParts Body]
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
    set wallsNode [customlib::AddConditionGroupOnXPath $walls Floor]
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
        set inletNode [customlib::AddConditionGroupOnXPath $DEMInlet "Inlet//$interval_name"]
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

    # General data
    # Time parameters
    set change_list [list EndTime 20 DeltaTime 1e-5 DEM-NeighbourSearchFrequency 20]
    set xpath [spdAux::getRoute DEMTimeParameters]
    foreach {name value} $change_list {
        set node [[customlib::GetBaseRoot] selectNodes "$xpath/value\[@n = '$name'\]"]
        if {$node ne ""} {
            $node setAttribute v $value
        } else {
            W "Couldn't find $name - Check SpheresDrop script"
        }
    }
    
    # Bounding box
    set change_list [list UseBoundingBox true MinZ -1.0]
    set xpath [spdAux::getRoute DEM-Boundingbox]
    foreach {name value} $change_list {
        set node [[customlib::GetBaseRoot] selectNodes "$xpath/value\[@n = '$name'\]"]
        if {$node ne ""} {
            $node setAttribute v $value
        } else {
            W "Couldn't find $name - Check SpheresDrop script"
        }
    }

    spdAux::RequestRefresh
}

proc DEM::examples::AssignMeshSize { } {
    GiD_Process Mescape Meshing AssignSizes Volumes 0.2 1:end escape escape escape
    GiD_Process Mescape Meshing AssignSizes Surfaces 0.2 1:end escape escape escape
    GiD_Process Mescape Meshing AssignSizes Lines 0.2 1:end escape escape escape
}


proc DEM::examples::ErasePreviousIntervals { } {
    set root [customlib::GetBaseRoot]
    set interval_base [spdAux::getRoute "Intervals"]
    foreach int [$root selectNodes "$interval_base/blockdata\[@n='Interval'\]"] {
        if {[$int @name] ni [list Initial Total Custom1]} {$int delete}
    }
}