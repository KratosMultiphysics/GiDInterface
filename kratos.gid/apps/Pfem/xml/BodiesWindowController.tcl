proc Pfem::xml::StartBodiesWindow { } {
    # 1 - Create Window 
        set w ".gid.bodieswindow"
        if {[winfo exists $w]} {destroy $w}
        toplevel $w -class Toplevel -relief groove 
        #wm maxsize $w 500 300
        wm minsize $w 500 300
        wm overrideredirect $w 0
        wm resizable $w 1 1
        wm deiconify $w
        wm title $w [= "Body create/edit window"]
        wm attribute $w -topmost 1

        # 2 - Top frame - window content
            set topframe [ttk::frame $w.topframe]

            # 3 - Left panel - Bodies frame
                set bodyframe [ttk::frame $topframe.bodyframe]
                
                # 4 - Top labelframe - List of bodies container
                    set listbodieslabel [ttk::labelframe $bodyframe.lflist -text "Bodies"]
                    
                    # 5 - List of bodies
                        set listbodies [listbox $listbodieslabel.list]
                        grid $listbodies -sticky nswe
                        grid $listbodieslabel -sticky nswe
                    # 5 - Body description
                        set descriptionframe [ttk::frame $listbodieslabel.description]
                        # 6 - Name entry
                            set namelabel [ttk::label $descriptionframe.namelabel -text "Name"]
                            set nameentry [ttk::entry $descriptionframe.nameentry]
                            grid $namelabel $nameentry -sticky nswe
                        # 6 - Body type combo
                            set type_values [list Fluid Solid Rigid]
                            set typelabel [ttk::label $descriptionframe.typelabel -text "Type"]
                            set typecombo [ttk::combobox $descriptionframe.typecombo -values $type_values]
                            grid $typelabel $typecombo -sticky nswe
                        # 6 - Remesh combo
                            set remesh_values [list "No remesh" "Remesh and refine"]
                            set remeshlabel [ttk::label $descriptionframe.remeshlabel -text "Remesh"]
                            set remeshcombo [ttk::combobox $descriptionframe.remeshcombo -values $remesh_values]
                            grid $remeshlabel $remeshcombo -sticky nswe
                        # 6 - Contact combo
                            set contact_values [list Yes No]
                            set contactlabel [ttk::label $descriptionframe.contactlabel -text "Contact"]
                            set contactcombo [ttk::combobox $descriptionframe.contactcombo -values $contact_values]
                            grid $contactlabel $contactcombo -sticky nswe
                            
                        # 6 - Bottom frame - ok / cancel buttons
                            set botframe [ttk::frame $descriptionframe.botframe]
                            ttk::button $botframe.cancel -text Cancel -command [list destroy $w] -style BottomFrame.TButton
                            ttk::button $botframe.ok -text Ok -command [list destroy $w] -style BottomFrame.TButton
                            grid $botframe.ok $botframe.cancel -sticky sew
                            grid $botframe -sticky swe -columnspan 2
                        
                        grid $descriptionframe -sticky swe
                    # 5 - Bottom frame - Add, delete, draw buttons
                        set bodybotframe [ttk::frame $listbodieslabel.bodybotframe]
                            set but_add [ttk::button $bodybotframe.add -text +Add -command [list destroy $w] -style BottomFrame.TButton]
                            set but_del [ttk::button $bodybotframe.del -text -Del -command [list destroy $w] -style BottomFrame.TButton]
                            set but_dra [ttk::button $bodybotframe.drw -text Draw -command [list destroy $w] -style BottomFrame.TButton]
                            grid $but_add $but_del $but_dra -sticky sew
                        grid $bodybotframe -sticky swe

                grid $bodyframe -sticky nswe -row 0 -column 0

            # 3 - Right panel - Parts  frame
                set partframe [ttk::frame $topframe.partframe]
                
                # 4 - Top labelframe - List of bodies container
                    set listpartslabel [ttk::labelframe $partframe.lflist -text "Parts"]
                    
                    # 5 - List of bodies
                        set listparts [listbox $listpartslabel.list]
                        grid $listparts -sticky nswe
                        grid $listpartslabel -sticky nswe
                    # 5 - Body description
                        set descriptionframe [ttk::frame $listpartslabel.description]
                        # 6 - Part selector combo
                            set type_values [list Group1 Group2]
                            set typelabel [ttk::label $descriptionframe.typelabel -text "Type"]
                            set typecombo [ttk::combobox $descriptionframe.typecombo -values $type_values]
                            grid $typelabel $typecombo -sticky nswe
                            
                        # 6 - Bottom frame - ok / cancel buttons
                            set botframe [ttk::frame $descriptionframe.botframe]
                            ttk::button $botframe.cancel -text Cancel -command [list destroy $w] -style BottomFrame.TButton
                            ttk::button $botframe.ok -text Ok -command [list destroy $w] -style BottomFrame.TButton
                            grid $botframe.ok $botframe.cancel -sticky sew
                            grid $botframe -sticky swe -columnspan 2
                        
                        grid $descriptionframe -sticky swe
                    # 5 - Bottom frame - Add, delete, draw buttons
                        set bodybotframe [ttk::frame $listpartslabel.bodybotframe]
                            set but_add [ttk::button $bodybotframe.add -text +Add -command [list destroy $w] -style BottomFrame.TButton]
                            set but_del [ttk::button $bodybotframe.del -text -Del -command [list destroy $w] -style BottomFrame.TButton]
                            set but_dra [ttk::button $bodybotframe.drw -text Draw -command [list destroy $w] -style BottomFrame.TButton]
                            grid $but_add $but_del $but_dra -sticky sew
                        grid $bodybotframe -sticky swe
                grid $partframe -sticky nswe -row 0 -column 1

            grid $topframe -sticky nswe

    # 1 - Fill with data
        set list_of_bodies [list Body1 Body2 Body3]
        $listbodies insert 0 {*}$list_of_bodies
        set list_of_parts [list Group1 Group2]
        $listparts insert 0 {*}$list_of_parts
}