namespace eval ::PfemMelting::examples::Cube  {
    namespace path ::PfemMelting::examples
    Kratos::AddNamespace [namespace current]

    variable group_body
}

proc ::PfemMelting::examples::Cube::Init {args} {
    if {![Kratos::IsModelEmpty]} {
        set txt "We are going to draw the example geometry.\nDo you want to lose your previous work?"
        set retval [tk_messageBox -default ok -icon question -message $txt -type okcancel]
                if { $retval == "cancel" } { return }
    }

    Kratos::ResetModel
    DrawGeometry
    AssignGroups
    TreeAssignation

    GiD_Process 'Redraw
    GidUtils::UpdateWindow GROUPS
    GidUtils::UpdateWindow LAYER
    GiD_Process 'Zoom Frame
    spdAux::RequestRefresh
}

proc PfemMelting::examples::Cube::DrawGeometry {args} {
    set layer Body
    GiD_Layers create $layer
    GiD_Layers edit to_use $layer

    # Create a prism 10x10x1
    GiD_Process Mescape Geometry Create Object Prism 4 0.0 0.0 0.0 0.0 0.0 1.0 7.071067811865475 1 Mescape

}

# Group assign
proc PfemMelting::examples::Cube::AssignGroups {args} {
    variable group_body
    set group_body body
    # Create the groups
    GiD_Groups create $group_body
    GiD_Groups edit color $group_body "#26d1a8ff"
    GiD_EntitiesGroups assign $group_body volume 1

    GiD_Groups create floor
    GiD_Groups edit color floor "#e0210fff"
    GiD_EntitiesGroups assign floor surface 1

    GiD_Groups create top
    GiD_Groups edit color top "#e0210fff"
    GiD_EntitiesGroups assign top surface 6

    GiD_Groups create skin
    GiD_Groups edit color skin "#e0210fff"
    GiD_EntitiesGroups assign skin surface {1 2 3 4 5 6}

}

proc PfemMelting::examples::Cube::TreeAssignation {args} {
    variable group_body
    # Fluid parts
    set fluid_parts_xpath [spdAux::getRoute [::Fluid::GetUniqueName parts]]
    set fluid_node [customlib::AddConditionGroupOnXPath $fluid_parts_xpath $group_body]
    set props [list Element QSVMS3D ConstitutiveLaw Newtonian3DLaw]
    spdAux::SetValuesOnBaseNode $fluid_node $props
}
