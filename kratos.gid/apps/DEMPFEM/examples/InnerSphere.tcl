namespace eval ::DEMPFEM::examples::InnerSphere {
    namespace path ::DEMPFEM::examples
}

proc ::DEMPFEM::examples::InnerSphere::Init {args} {
    if {![Kratos::IsModelEmpty]} {
        set txt "We are going to draw the example geometry.\nDo you want to lose your previous work?"
        set retval [tk_messageBox -default ok -icon question -message $txt -type okcancel]
		if { $retval == "cancel" } { return }
    }
    DrawGeometry3D
    AssignGroups3D
    TreeAssignation3D
    MeshAssignation3D
    
    spdAux::RequestRefresh
    GiD_Process 'Redraw
    GidUtils::UpdateWindow GROUPS
    GidUtils::UpdateWindow LAYER
    GiD_Process 'Zoom Frame
}


# Draw Geometry
proc ::DEMPFEM::examples::InnerSphere::DrawGeometry3D {args} {
    
    Kratos::ResetModel

    # FLUID
    GiD_Layers create Fluid
    GiD_Layers edit to_use Fluid
    GiD_Process Mescape Geometry Create Object Sphere 0 0 0 1 escape 
    
    # DEM
    GiD_Layers create DEM
    GiD_Layers edit to_use DEM
    GiD_Process Mescape Geometry Create Object Sphere 0 0 0 0.2 escape 

    # Create platform
    GiD_Process Mescape utilities SwapNormals Lines Select 1 escape 
    GiD_Process Mescape Utilities Copy Lines Duplicate DoExtrude Surfaces MaintainLayers Offset 0.3 1 3 escape Mescape 

}


# Group assign
proc ::DEMPFEM::examples::InnerSphere::AssignGroups3D {args} {
    # Create the groups
    GiD_Groups create Fluid
    GiD_Groups edit color Fluid "#26d1a8ff"
    GiD_EntitiesGroups assign Fluid volumes 1

    GiD_Groups create FixedVelocity
    GiD_Groups edit color FixedVelocity "#26d1a8ff"
    GiD_EntitiesGroups assign FixedVelocity surfaces [list 1 2 9 10]

    GiD_Groups create Walls
    GiD_Groups edit color Walls "#3b3b3bff"
    GiD_EntitiesGroups assign Walls surfaces [list 1 2 9 10]

    GiD_Groups create Dem
    GiD_Groups edit color Dem "#3b3b3bff"
    GiD_EntitiesGroups assign Dem volumes 2

}

# Tree assign
proc ::DEMPFEM::examples::InnerSphere::TreeAssignation3D {args} {
    
    set root [customlib::GetBaseRoot]
    set condtype surface
    set fluidtype volume 

    # DEM - PARTS
    set demPart [customlib::AddConditionGroupOnXPath [spdAux::getRoute "DEMParts"] Dem]
    set props [list Element SphericPartDEMElement3D]
    $demPart setAttribute ov $fluidtype
    spdAux::SetValuesOnBaseNode $demPart $props
    
    # Fluid PFEM - PARTS
    set first_body [$root selectNodes "[spdAux::getRoute "PFEMFLUID_Bodies"]/blockdata\[@name = 'Body1'\]"]
    [$first_body selectNodes "./value\[@n = 'BodyType'\]"] setAttribute v Fluid
    set part_xpath [[$first_body selectNodes "./condition\[@n = 'Parts'\]"] toXPath]
    set demPart [customlib::AddConditionGroupOnXPath $part_xpath Fluid]
    
    
    set new_body [$first_body cloneNode -deep]
    [$new_body selectNodes "./condition\[@n = 'Parts'\]/group"] delete
    $new_body setAttribute name RigidBody
    [$new_body selectNodes "./value\[@n = 'BodyType'\]"] setAttribute v Rigid
    [$new_body selectNodes "./value\[@n = 'MeshingStrategy'\]"] setAttribute v "No remesh"
    [$first_body parent] insertBefore $new_body $first_body
    set part_xpath [[$new_body selectNodes "./condition\[@n = 'Parts'\]"] toXPath]
    set demPart [customlib::AddConditionGroupOnXPath $part_xpath Walls]
    
    [$new_body selectNodes "./condition\[@n = 'Parts'\]/group"] setAttribute ov surface

    # Fix velocity
    set pfem_velocity "[spdAux::getRoute "PFEMFLUID_NodalConditions"]/condition\[@n='VELOCITY'\]"
    GiD_Groups create "FixedVelocity//Total"
    GiD_Groups edit state "FixedVelocity//Total" hidden
    spdAux::AddIntervalGroup FixedVelocity "FixedVelocity//Total"
    set vel_node [customlib::AddConditionGroupOnXPath $pfem_velocity "FixedVelocity//Total"]
    $vel_node setAttribute ov $condtype
    set props [list selector_component_X ByValue value_component_X 0.0 selector_component_Y ByValue value_component_Y 0.0 selector_component_Z ByValue value_component_Z 0.0 Interval Total]
    spdAux::SetValuesOnBaseNode $vel_node $props

}

proc ::DEMPFEM::examples::InnerSphere::MeshAssignation3D {} {
    set list_vols [GiD_EntitiesGroups get Dem volumes]
    GiD_Process Mescape Meshing ElemType Sphere Volumes {*}$list_vols escape 
}
