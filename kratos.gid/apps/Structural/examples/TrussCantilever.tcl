
proc ::Structural::examples::TrussCantilever {args} {
    if {![Kratos::IsModelEmpty]} {
        set txt "We are going to draw the example geometry.\nDo you want to lose your previous work?"
        set retval [tk_messageBox -default ok -icon question -message $txt -type okcancel]
		if { $retval == "cancel" } { return }
    }
    DrawTrussCantileverGeometry
    AssignTrussCantileverMeshSizes
    TreeAssignationTrussCantilever
}

proc Structural::examples::DrawTrussCantileverGeometry {args} {
    Kratos::ResetModel
    set structure_layer Structure
    GiD_Process Mescape 'Layers ChangeName Layer0 $structure_layer escape

    # Geometry creation
    set coordinates [list 0 0 0 2 0 0 4 0 0 6 0 0 8 0 0 10 0 0 10 -5 0 8 -4 0 6 -3 0 4 -2 0 2 -1 0]
    set structurePoints [list ]
    foreach {x y z} $coordinates {
        lappend structurePoints [GiD_Geometry create point append $structure_layer $x $y $z]
    }

    set structureLines [list ]
    set initial [lindex $structurePoints 0]
    foreach point [lrange $structurePoints 1 end] {
        lappend structureLines [GiD_Geometry create line append stline $structure_layer $initial $point]
        set initial $point
    }
    lappend strucLines [GiD_Geometry create line append stline $structure_layer $initial [lindex $structurePoints 0]]

    lappend structureLines [GiD_Geometry create line append stline $structure_layer 2 11]
    lappend structureLines [GiD_Geometry create line append stline $structure_layer 11 3]
    lappend structureLines [GiD_Geometry create line append stline $structure_layer 3 10]
    lappend structureLines [GiD_Geometry create line append stline $structure_layer 10 4]
    lappend structureLines [GiD_Geometry create line append stline $structure_layer 4 9]
    lappend structureLines [GiD_Geometry create line append stline $structure_layer 9 5]
    lappend structureLines [GiD_Geometry create line append stline $structure_layer 5 8]
    lappend structureLines [GiD_Geometry create line append stline $structure_layer 8 6]
    
    GiD_Process 'Zoom Frame

    # Group creation
    GiD_Groups create Structure
    GiD_Groups create XYZ
    GiD_Groups create XZ
    GiD_Groups create Z
    GiD_Groups create Load
    
    GiD_EntitiesGroups assign Structure lines [GiD_EntitiesLayers get $structure_layer lines]
    GiD_EntitiesGroups assign XYZ points 6
    GiD_EntitiesGroups assign XZ points 7
    GiD_EntitiesGroups assign Z points {1 2 3 4 5 8 9 10 11}
    GiD_EntitiesGroups assign Load points {1 2 3 4 5}
    
    GidUtils::UpdateWindow GROUPS
}

proc Structural::examples::AssignTrussCantileverMeshSizes {args} {
    GiD_Process Mescape Meshing Structured Lines 1 {*}[GiD_EntitiesGroups get Structure lines] escape escape 
}


proc Structural::examples::TreeAssignationTrussCantilever {args} {
    set nd $::Model::SpatialDimension
    set root [customlib::GetBaseRoot]

    set condtype point
    if {$::Model::SpatialDimension eq "3D"} { set condtype line }

    # Structural
    # gid_groups_conds::setAttributesF {container[@n='FSI']/container[@n='Structural']/container[@n='StageInfo']/value[@n='SolutionType']} {v Dynamic}

    # Structural Parts
    set structParts {container[@n='Structural']/container[@n='Parts']/condition[@n='Parts_Truss']}
    set structPartsNode [customlib::AddConditionGroupOnXPath $structParts Structure]
    $structPartsNode setAttribute ov line
    set constLawNameStruc "TrussConstitutiveLaw"
    set props [list Element TrussElement$nd ConstitutiveLaw $constLawNameStruc CROSS_AREA 0.01 DENSITY 1500.0]
    foreach {prop val} $props {
         set propnode [$structPartsNode selectNodes "./value\[@n = '$prop'\]"]
         if {$propnode ne "" } {
              $propnode setAttribute v $val
         } else {
            W "Warning - Couldn't find property Structure $prop"
         }
    }

    # Structural Displacement
    GiD_Groups clone XYZ Total
    GiD_Groups edit parent Total XYZ
    spdAux::AddIntervalGroup XYZ "XYZ//Total"
    GiD_Groups edit state "XYZ//Total" hidden
    set structDisplacement {container[@n='Structural']/container[@n='Boundary Conditions']/condition[@n='DISPLACEMENT']}
    set structDisplacementNode [customlib::AddConditionGroupOnXPath $structDisplacement "XYZ//Total"]
    $structDisplacementNode setAttribute ov point
    set props [list selector_component_X ByValue value_component_X 0.0 selector_component_Y ByValue value_component_Y 0.0 selector_component_Z ByValue value_component_Z 0.0 Interval Total]
    foreach {prop val} $props {
         set propnode [$structDisplacementNode selectNodes "./value\[@n = '$prop'\]"]
         if {$propnode ne "" } {
              $propnode setAttribute v $val
         } else {
            W "Warning - Couldn't find property Structure $prop"
         }
    }

    # Structural Displacement
    GiD_Groups clone XZ Total
    GiD_Groups edit parent Total XZ
    spdAux::AddIntervalGroup XZ "XZ//Total"
    GiD_Groups edit state "XZ//Total" hidden
    set structDisplacement {container[@n='Structural']/container[@n='Boundary Conditions']/condition[@n='DISPLACEMENT']}
    set structDisplacementNode [customlib::AddConditionGroupOnXPath $structDisplacement "XZ//Total"]
    $structDisplacementNode setAttribute ov point
    set props [list selector_component_X ByValue value_component_X 0.0 selector_component_Y Not selector_component_Z ByValue value_component_Z 0.0 Interval Total]
    foreach {prop val} $props {
         set propnode [$structDisplacementNode selectNodes "./value\[@n = '$prop'\]"]
         if {$propnode ne "" } {
              $propnode setAttribute v $val
         } else {
            W "Warning - Couldn't find property Structure $prop"
         }
    }

    # Structural Displacement
    GiD_Groups clone Z Total
    GiD_Groups edit parent Total Z
    spdAux::AddIntervalGroup Z "Z//Total"
    GiD_Groups edit state "Z//Total" hidden
    set structDisplacement {container[@n='Structural']/container[@n='Boundary Conditions']/condition[@n='DISPLACEMENT']}
    set structDisplacementNode [customlib::AddConditionGroupOnXPath $structDisplacement "Z//Total"]
    $structDisplacementNode setAttribute ov point
    set props [list selector_component_X Not selector_component_Y Not selector_component_Z ByValue value_component_Z 0.0 Interval Total]
    foreach {prop val} $props {
         set propnode [$structDisplacementNode selectNodes "./value\[@n = '$prop'\]"]
         if {$propnode ne "" } {
              $propnode setAttribute v $val
         } else {
            W "Warning - Couldn't find property Structure $prop"
         }
    }

    # Point load
    set structLoad "container\[@n='Structural'\]/container\[@n='Loads'\]/condition\[@n='PointLoad$nd'\]"
    GiD_Groups clone Load Total
    GiD_Groups edit parent Total Load
    spdAux::AddIntervalGroup Load "Load//Total"
    GiD_Groups edit state "Load//Total" hidden
    $structDisplacementNode setAttribute ov point
    set LoadNode [customlib::AddConditionGroupOnXPath $structLoad "Load//Total"]
    set props [list ByFunction No modulus 10000 value_direction_Y -1 Interval Total]
    foreach {prop val} $props {
         set propnode [$LoadNode selectNodes "./value\[@n = '$prop'\]"]
         if {$propnode ne "" } {
              $propnode setAttribute v $val
         } else {
            W "Warning - Couldn't find property Structure $prop"
         }
    }

    # Structure domain time parameters
    #set change_list [list EndTime 25.0 DeltaTime 0.1]; # Commented delta time since the case is static
    set change_list [list EndTime 25.0]
    set xpath [spdAux::getRoute STTimeParameters]
    foreach {name value} $change_list {
        set node [$root selectNodes "$xpath/value\[@n = '$name'\]"]
        if {$node ne ""} {
            $node setAttribute v $value
        } else {
            W "Couldn't find $name - Check Truss example script"
        }
    }

    spdAux::RequestRefresh
}
