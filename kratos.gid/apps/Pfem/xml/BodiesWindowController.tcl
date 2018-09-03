namespace eval ::Pfem::xml::BodiesWindow {
    variable window
    variable list_of_bodies
    variable description_frame

    variable name_entry
    variable type_combo
    variable mesh_combo
    variable cont_combo
    
    variable current_body
    variable current_part
    
    variable list_of_parts
    variable part_frame
    variable part_combo
    variable part_description_frame
}

proc Pfem::xml::BodiesWindow::Init { } {
    variable window
    set window ".gid.bodieswindow"
}

proc Pfem::xml::BodiesWindow::Start { } {
    variable window
    variable part_frame
    variable description_frame
    variable name_entry
    variable type_combo
    variable mesh_combo
    variable cont_combo
    variable part_description_frame

    # 1 - Create Window 
        if {[winfo exists $window]} {destroy $window}
        toplevel $window -class Toplevel -relief groove 
        #wm maxsize $w 500 300
        wm minsize $window 500 300
        wm overrideredirect $window 0
        wm resizable $window 1 1
        wm deiconify $window
        wm title $window [= "Body create/edit window"]
        wm attribute $window -topmost 1

        # 2 - Top frame - window content
            set topframe [ttk::frame $window.topframe]

            # 3 - Left panel - Bodies frame
                set bodyframe [ttk::frame $topframe.bodyframe]
                
                # 4 - Top labelframe - List of bodies container
                    set listbodieslabel [ttk::labelframe $bodyframe.lflist -text "Bodies"]
                    
                    # 5 - List of bodies
                        set bodies_list [listbox $listbodieslabel.list -listvariable Pfem::xml::BodiesWindow::list_of_bodies]
                        grid $bodies_list -sticky nswe
                        grid $listbodieslabel -sticky nswe
                    # 5 - Body description
                        set description_frame [ttk::frame $listbodieslabel.description]
                        # 6 - Name entry
                            set namelabel [ttk::label $description_frame.namelabel -text "Name"]
                            set nameentry [ttk::entry $description_frame.nameentry -textvariable ::Pfem::xml::BodiesWindow::name_entry]
                            grid $namelabel $nameentry -sticky nswe
                        # 6 - Body type combo
                            set type_values [list Fluid Solid Rigid]
                            set typelabel [ttk::label $description_frame.typelabel -text "Type"]
                            set typecombo [ttk::combobox $description_frame.typecombo -values $type_values -textvariable ::Pfem::xml::BodiesWindow::type_combo -state readonly]
                            grid $typelabel $typecombo -sticky nswe
                        # 6 - Remesh combo
                            set remesh_values [list "No remesh" "Remesh and refine"]
                            set remeshlabel [ttk::label $description_frame.remeshlabel -text "Remesh"]
                            set remeshcombo [ttk::combobox $description_frame.remeshcombo -values $remesh_values -textvariable ::Pfem::xml::BodiesWindow::mesh_combo -state readonly]
                            grid $remeshlabel $remeshcombo -sticky nswe
                        # 6 - Contact combo
                            set contact_values [list Yes No]
                            set contactlabel [ttk::label $description_frame.contactlabel -text "Contact"]
                            set contactcombo [ttk::combobox $description_frame.contactcombo -values $contact_values -textvariable ::Pfem::xml::BodiesWindow::cont_combo -state readonly] 
                            grid $contactlabel $contactcombo -sticky nswe
                            
                        # 6 - Bottom frame - ok / cancel buttons
                            set botframe [ttk::frame $description_frame.botframe]
                            ttk::button $botframe.cancel -text Close -command [list Pfem::xml::BodiesWindow::InitialState] -style BottomFrame.TButton
                            ttk::button $botframe.ok -text Ok -command [list destroy $window] -style BottomFrame.TButton
                            grid $botframe.ok $botframe.cancel -sticky sew
                            grid $botframe -sticky swe -columnspan 2
                        
                    # 5 - Bottom frame - Add, delete, draw buttons
                        set bodybotframe [ttk::frame $listbodieslabel.bodybotframe]
                            set but_add [ttk::button $bodybotframe.add -text +Add -command [list Pfem::xml::BodiesWindow::AddBody] -style BottomFrame.TButton]
                            set but_del [ttk::button $bodybotframe.del -text -Del -command [list Pfem::xml::BodiesWindow::DelBody] -style BottomFrame.TButton]
                            set but_dra [ttk::button $bodybotframe.drw -text Draw -command [list Pfem::xml::BodiesWindow::DrawBody] -style BottomFrame.TButton]
                            grid $but_add $but_del $but_dra -sticky sew
                        grid $bodybotframe -sticky swe

                grid $bodyframe -sticky nswe -row 0 -column 0

            # 3 - Right panel - Parts  frame
                set part_frame [ttk::frame $topframe.partframe]
                
                # 4 - Top labelframe - List of bodies container
                    set listpartslabel [ttk::labelframe $part_frame.lflist -text "Parts"]
                    
                    # 5 - List of bodies
                        set parts_list [listbox $listpartslabel.list -listvariable Pfem::xml::BodiesWindow::list_of_parts]
                        grid $parts_list -sticky nswe
                        grid $listpartslabel -sticky nswe
                    # 5 - Body description
                        set part_description_frame [ttk::frame $listpartslabel.description]
                        # 6 - Part selector combo
                            # TODO : get available only - no repeat - just the type
                            set part_values [Pfem::xml::GetPartsGroups]
                            set part_label [ttk::label $part_description_frame.partlabel -text "Part name"]
                            set partcombo [ttk::combobox $part_description_frame.partcombo -textvariable Pfem::xml::BodiesWindow::part_combo -values $part_values -state readonly]
                            grid $part_label $partcombo -sticky nswe
                            
                        # 6 - Bottom frame - ok / cancel buttons
                            set botframe [ttk::frame $part_description_frame.botframe]
                            ttk::button $botframe.cancel -text Close -command [list Pfem::xml::BodiesWindow::InitialState] -style BottomFrame.TButton
                            ttk::button $botframe.ok -text Ok -command [list Pfem::xml::BodiesWindow::AcceptPartAdd] -style BottomFrame.TButton
                            grid $botframe.ok $botframe.cancel -sticky sew
                            grid $botframe -sticky swe -columnspan 2
                        
                    # 5 - Bottom frame - Add, delete, draw buttons
                        set bodybotframe [ttk::frame $listpartslabel.bodybotframe]
                            set but_add [ttk::button $bodybotframe.add -text +Add -command [list Pfem::xml::BodiesWindow::AddPart] -style BottomFrame.TButton]
                            set but_del [ttk::button $bodybotframe.del -text -Del -command [list Pfem::xml::BodiesWindow::DelPart] -style BottomFrame.TButton]
                            set but_dra [ttk::button $bodybotframe.drw -text Draw -command [list Pfem::xml::BodiesWindow::DrawPart] -style BottomFrame.TButton]
                            grid $but_add $but_del $but_dra -sticky sew
                        grid $bodybotframe -sticky swe
                
            grid $topframe -sticky nswe

    bind $bodies_list <<ListboxSelect>> [list Pfem::xml::BodiesWindow::BodySelection %W] 
    bind $parts_list <<ListboxSelect>> [list Pfem::xml::BodiesWindow::PartSelected %W] 

    Pfem::xml::BodiesWindow::InitialState
}

proc Pfem::xml::BodiesWindow::InitialState { } {
    # 1 - Fill with data
        variable list_of_bodies
        set list_of_bodies [list ]
        foreach body [Pfem::xml::GetBodiesInformation] {
            lappend list_of_bodies [dict get $body name]
        }
    
    # 2 - Hide lateral panel
        variable part_frame
        grid forget $part_frame
        variable description_frame
        grid forget $description_frame
        variable part_description_frame
        grid forget $part_description_frame
}

proc Pfem::xml::BodiesWindow::BodySelection { w } {
    set selected [$w curselection]
    if {$selected ne ""} {
        Pfem::xml::BodiesWindow::BodySelected $selected
    }
}
proc Pfem::xml::BodiesWindow::BodySelected { body_id } {
    variable description_frame
    variable name_entry
    variable type_combo
    variable mesh_combo
    variable cont_combo

    variable part_frame
    variable list_of_parts

    variable current_body
    variable current_part

    set current_body $body_id
    # Get data from tree
    set data [lindex [Pfem::xml::GetBodiesInformation] $body_id]

    # Fill data in description frame
    set name_entry [dict get $data name]
    set type_combo [dict get $data type]
    set mesh_combo [dict get $data mesh]
    set cont_combo [dict get $data cont]

    # Show description frame
    grid $description_frame -sticky swe
    
    # Fill data in Parts panel
    set list_of_parts [dict get $data parts]

    # Show parts panel
    grid $part_frame -sticky nswe -row 0 -column 1
    
}
proc Pfem::xml::BodiesWindow::PartSelected { w } {
    variable part_description_frame
    variable current_body
    variable current_part

    set selected [$w curselection]
    if {$selected ne ""} {
        set current_part $selected
    }
}

proc Pfem::xml::BodiesWindow::AddBody { } {
    Pfem::xml::AddNewBodyRaw
    spdAux::RequestRefresh
    Pfem::xml::BodiesWindow::InitialState
}
proc Pfem::xml::BodiesWindow::AddPart { } {
    # Show the adding part frame
    variable part_description_frame
    grid $part_description_frame -sticky swe
}

proc Pfem::xml::BodiesWindow::AcceptPartAdd { } {
    variable current_body
    set body_name [dict get [lindex [Pfem::xml::GetBodiesInformation] $current_body] name]
    set part_name $Pfem::xml::BodiesWindow::part_combo
    if {$part_name in [GiD_Groups list]} {
        Pfem::xml::AddPartToBody $body_name $part_name
        spdAux::RequestRefresh
        Pfem::xml::BodiesWindow::InitialState
        Pfem::xml::BodiesWindow::BodySelected $current_body
    }
}

proc Pfem::xml::BodiesWindow::DelBody { } {
    variable current_body
    
    if {$current_body ne ""} {
        Pfem::xml::DeleteBody [dict get [lindex [Pfem::xml::GetBodiesInformation] $current_body] name] 
    }
    spdAux::RequestRefresh
    Pfem::xml::BodiesWindow::InitialState
}
proc Pfem::xml::BodiesWindow::DelPart { } {
    variable current_body
    variable current_part
    if {$current_body ne "" && $current_part ne ""} {
        set body_name [dict get [lindex [Pfem::xml::GetBodiesInformation] $current_body] name]
        set part_name [lindex [dict get [lindex [Pfem::xml::GetBodiesInformation] $current_body] parts] $current_part]
        Pfem::xml::DeletePartInBody $body_name $part_name
    }
    spdAux::RequestRefresh
    Pfem::xml::BodiesWindow::InitialState
    Pfem::xml::BodiesWindow::BodySelected $current_body
}

proc Pfem::xml::BodiesWindow::DrawBody { } {
    variable current_body

    set names [dict get [lindex [Pfem::xml::GetBodiesInformation] $current_body] parts]
    GiD_Groups end_draw
    GiD_Groups draw $names
    after 5000 {GiD_Groups end_draw; GiD_Process 'Redraw }
    GiD_Process 'Redraw 
}
proc Pfem::xml::BodiesWindow::DrawPart { } {
    variable current_part
    variable current_body

    set name [lindex [dict get [lindex [Pfem::xml::GetBodiesInformation] $current_body] parts] $current_part]
    GiD_Groups end_draw
    GiD_Groups draw [list $name]
    after 5000 {GiD_Groups end_draw; GiD_Process 'Redraw }
    GiD_Process 'Redraw 
}

Pfem::xml::BodiesWindow::Init