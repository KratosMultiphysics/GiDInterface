
proc spdAux::reactiveApp { } {
    #W "Reactive"
    variable initwind
    destroy $initwind
    
    set root [customlib::GetBaseRoot]
    set ::Model::SpatialDimension [[$root selectNodes "value\[@n='nDim'\]"] getAttribute v ]
    set appname [[$root selectNodes "hiddenfield\[@n='activeapp'\]"] @v ]
    
    apps::setActiveApp $appname
}

proc spdAux::deactiveApp { appid } {
    
    set root [customlib::GetBaseRoot]
    [$root selectNodes "hiddenfield\[@n='activeapp'\]"] setAttribute v ""
    foreach elem [$root getElementsByTagName "appLink"] {
        if {$appid eq [$elem getAttribute "appid"] && [$elem getAttribute "active"] eq "1"} {
            $elem setAttribute "active" 0
            break
        } 
    }
}
proc spdAux::activeApp { appid } {
    #W "Active $appid"
    variable initwind
    catch {
        set root [customlib::GetBaseRoot]
        [$root selectNodes "hiddenfield\[@n='activeapp'\]"] setAttribute v $appid
        foreach elem [$root getElementsByTagName "appLink"] {
            if {$appid eq [$elem getAttribute "appid"] && [$elem getAttribute "active"] eq "0"} {
                $elem setAttribute "active" 1
            } else {
                $elem setAttribute "active" 0
            }
        }
    }
    if {$::Kratos::must_quit} {return ""}
    set nd [$root selectNodes "value\[@n='nDim'\]"]
    if {[$nd getAttribute v] ne "wait"} {
        if {[$nd getAttribute v] ne "undefined"} {
            set ::Model::SpatialDimension [$nd getAttribute v]
            spdAux::SwitchDimAndCreateWindow $::Model::SpatialDimension
            spdAux::TryRefreshTree
        } {
            ::spdAux::CreateDimensionWindow
        }
    }
}

proc spdAux::CreateWindow {} {
    variable initwind
    variable must_open_init_window
    
    if {$must_open_init_window == 0} {return ""}
    set root [customlib::GetBaseRoot]
    
    set activeapp_node [$::gid_groups_conds::doc selectNodes "//hiddenfield\[@n='activeapp'\]"]
    if {$activeapp_node ne ""} {
        set activeapp [get_domnode_attribute $activeapp_node v]
    } else {
        return ""   
    }
    spdAux::DestroyInitWindow
        
    if { $activeapp ne "" } {
        apps::setActiveApp $activeapp
        return ""
    }
    
    set w .gid.win_example
    toplevel $w
    wm withdraw $w
    
    set x [expr [winfo rootx .gid]+[winfo width .gid]/2-[winfo width $w]/2]
    set y [expr [winfo rooty .gid]+[winfo height .gid]/2-[winfo height $w]/2]
    
    wm geom $w +$x+$y
    wm transient $w .gid    
    
    InitWindow $w [_ "Kratos Multiphysics"] Kratos "" "" 1
    set initwind $w
    ttk::frame $w.top
    ttk::label $w.top.title_text -text [_ " Application market"]
    ttk::frame $w.information  -relief ridge 
    
    set appsid [::apps::getAllApplicationsID]
    set appspn [::apps::getAllApplicationsName]
    
    set col 0
    set row 0
    foreach appname $appspn appid $appsid {
        if {[apps::isPublic $appid]} {
            set img [::apps::getImgFrom $appid]
            ttk::button $w.information.img$appid -image $img -command [list apps::setActiveApp $appid]
            ttk::label $w.information.text$appid -text $appname
            
            grid $w.information.img$appid -column $col -row $row
            grid $w.information.text$appid -column $col -row [expr $row +1]
            
            incr col
            if {$col >= 5} {set col 0; incr row; incr row}
        }
    }
    
    # More button
    if {$::Kratos::kratos_private(DevMode) eq "dev"} {
        set more_path [file nativename [file join $::Kratos::kratos_private(Path) images "more.png"] ]
        set img [gid_themes::GetImageModule $more_path]
        ttk::button $w.information.img_more -image $img -command [list VisitWeb "https://github.com/KratosMultiphysics/GiDInterface"]
        ttk::label $w.information.text_more -text "More..."
        
        grid $w.information.img_more -column $col -row $row
        grid $w.information.text_more -column $col -row [expr $row +1]
    }
    
    grid $w.top
    grid $w.top.title_text
    
    grid $w.information
}

proc spdAux::DestroyInitWindow { } {
    variable initwind
    if {[winfo exist $initwind]} {destroy $initwind}
}

proc spdAux::CreateDimensionWindow { } {
    #package require anigif 1.3
    variable initwind
    variable must_open_dim_window

    if {$must_open_dim_window == 0} {return ""}

    set root [customlib::GetBaseRoot]
    
    set nd [ [$root selectNodes "value\[@n='nDim'\]"] getAttribute v]
    if { $nd ne "undefined" } {
        spdAux::SwitchDimAndCreateWindow $nd
        spdAux::RequestRefresh
    } {
        if {[llength $::Model::ValidSpatialDimensions] == 1} {
            spdAux::SwitchDimAndCreateWindow [lindex $::Model::ValidSpatialDimensions 0]
            spdAux::RequestRefresh
            return ""
        }
        set dir $::Kratos::kratos_private(Path)
        
        set initwind .gid.win_example
        if { [ winfo exist $initwind]} {
            destroy $initwind
        }
        toplevel $initwind
        wm withdraw $initwind
        
        set w $initwind
        
        set x [expr [winfo rootx .gid]+[winfo width .gid]/2-[winfo width $w]/2]
        set y [expr [winfo rooty .gid]+[winfo height .gid]/2-[winfo height $w]/2]
        
        wm geom $initwind +$x+$y
        wm transient $initwind .gid    
        
        InitWindow $w [_ "Kratos Multiphysics"] Kratos "" "" 1
        set initwind $w
        ttk::frame $w.top
        ttk::label $w.top.title_text -text [_ " Dimension selection"]
        
        ttk::frame $w.information  -relief ridge
        set i 0
        foreach dim $::Model::ValidSpatialDimensions {
            set imagepath [getImagePathDim $dim]
            if {![file exists $imagepath]} {set imagepath [file nativename [file join $dir images "$dim.png"]]}
            set img [gid_themes::GetImageModule $imagepath ""]
            set but [ttk::button $w.information.img$dim -image $img -command [list spdAux::SwitchDimAndCreateWindow $dim] ]
            
            grid $w.information.img$dim -column $i -row 0
            incr i
        }
        grid $w.top
        grid $w.top.title_text
        
        grid $w.information
    }
    
}

proc spdAux::SetSpatialDimmension {ndim} {
    
    set root [customlib::GetBaseRoot]
    set ::Model::SpatialDimension $ndim
    
    set nd [$root selectNodes "value\[@n='nDim'\]"]
    
    $nd setAttribute v $::Model::SpatialDimension
}

proc spdAux::SwitchDimAndCreateWindow { ndim } {
    variable TreeVisibility
    variable ProjectIsNew
    
    SetSpatialDimmension $ndim
    spdAux::DestroyWindow
    
    processIncludes
    parseRoutes
    
    apps::ExecuteOnCurrentXML MultiAppEvent init
    
    if { $ProjectIsNew eq 0} {
        spdAux::CustomTreeCommon
        apps::ExecuteOnCurrentXML CustomTree ""
    }
    
    if {$TreeVisibility} {
        customlib::UpdateDocument
        spdAux::PreChargeTree
        spdAux::TryRefreshTree
        spdAux::OpenTree
    }
    ::Kratos::CreatePreprocessModelTBar
    ::Kratos::UpdateMenus
}