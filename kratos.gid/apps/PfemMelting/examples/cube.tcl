namespace eval ::PfemMelting::examples::Cube  {
    namespace path ::PfemMelting::examples
    Kratos::AddNamespace [namespace current]

    variable group_body
    variable group_bottom
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
    GiD_Process Mescape Geometry Create Object Prism 4 0.0 0.0 0.0 0.0 0.0 1.0 0.07071067811865475 0.05 Mescape

}

# Group assign
proc PfemMelting::examples::Cube::AssignGroups {args} {
    # Create the groups

    variable group_body
    set group_body body
    GiD_Groups create $group_body
    GiD_Groups edit color $group_body "#26d1a8ff"
    GiD_EntitiesGroups assign $group_body volume 1

    variable group_bottom
    set group_bottom floor
    GiD_Groups create floor
    GiD_Groups edit color floor "#e0210fff"
    GiD_EntitiesGroups assign floor surface 1

    GiD_Groups create top
    GiD_Groups edit color top "#e0210fff"
    GiD_EntitiesGroups assign top surface 6

    # GiD_Groups create skin
    # GiD_Groups edit color skin "#e0210fff"
    # GiD_EntitiesGroups assign skin surface {1 2 3 4 5 6}

}

proc PfemMelting::examples::Cube::TreeAssignation {args} {
    #  parts
    variable group_body
    set parts_xpath [spdAux::getRoute [PfemMelting::GetUniqueName parts]]
    set part_node [customlib::AddConditionGroupOnXPath $parts_xpath $group_body]
    set props [list Material polymer1]
    spdAux::SetValuesOnBaseNode $part_node $props

    # Laser file into model
    set laser_filename "LaserSettings.json"
    set laser_filename_origin [file join $PfemMelting::dir examples $laser_filename]
    set laser_filename [::FileSelector::_ProcessFile $laser_filename_origin]
    ::spdAux::SaveModelFile $laser_filename

    # Laser condition
    set laser_xpath "[spdAux::getRoute [PfemMelting::GetUniqueName laser]]/blockdata\[@name='Laser Path 1'\]/value\[@n='laser_path'\]"
    spdAux::SetFieldOnPath $laser_xpath v $laser_filename

    # Set ambient temperature
    set temperature_xpath [spdAux::getRoute [PfemMelting::GetUniqueName ambient_temperature]]
    spdAux::SetFieldOnPath $temperature_xpath v 293.16

    # Fix Velocity Constraints
    set xpath [spdAux::getRoute [PfemMelting::GetUniqueName conditions]]
    customlib::AddConditionGroupOnXPath "$xpath/condition\[@n='VelocityConstraints3D'\]" floor

    # Temperature file into model
    set temp_filename "temperature_dynamicviscosity.csv"
    set temp_filename_origin [file join $PfemMelting::dir examples $temp_filename]
    set temp_filename [::FileSelector::_ProcessFile $temp_filename_origin]
    ::spdAux::SaveModelFile $temp_filename

    set temp_xpath "[spdAux::getRoute [PfemMelting::GetUniqueName materials]]/blockdata\[@name='Polymer 1'\]/value\[@n='Temperature_Viscosity'\]"
    spdAux::SetFieldOnPath $temp_xpath v $temp_filename

}
