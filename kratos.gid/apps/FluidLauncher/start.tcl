namespace eval ::FluidLauncher {
    variable available_apps
}

proc ::FluidLauncher::Init { } {
    variable available_apps

    set available_apps [list Fluid EmbeddedFluid PotentialFluid Buoyancy ConjugateHeatTransfer FluidDEM]
    # Allow to open the tree
    set ::spdAux::TreeVisibility 0
    
    ::FluidLauncher::FluidAppSelectorWindow
}

proc ::FluidLauncher::FluidAppSelectorWindow { } {
    variable available_apps
    
    set root [customlib::GetBaseRoot]
    set nd [ [$root selectNodes "value\[@n='nDim'\]"] getAttribute v]
    if { $nd ne "undefined" } {
        if {[apps::getActiveAppId] eq "Fluid"} {
            spdAux::SwitchDimAndCreateWindow $nd
        }
    } {
        [$root selectNodes "value\[@n='nDim'\]"] setAttribute v wait

        set initwind .gid.win_fluid_launcher
        spdAux::DestroyWindows
        spdAux::RegisterWindow $initwind
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

        InitWindow $w [_ "Fluid applications"] Kratos "" "" 1
        set initwind $w
        ttk::frame $w.top
        ttk::label $w.top.title_text -text [_ "Select a fluid application"]

        ttk::frame $w.information  -relief ridge
        set r 0
        set c 0
        set max_cols 3
        foreach app $available_apps {
            set img [::apps::getImgFrom $app]
            set app_publicname [[::apps::getAppById $app] getPublicName]
            set but [ttk::button $w.information.img$app -image $img -command [list ::FluidLauncher::ChangeAppTo $app] ]
            ttk::label $w.information.text$app -text $app_publicname
            grid $w.information.img$app -column $r -row $c
            grid $w.information.text$app -column $r -row [expr $c + 1]
            incr r
            if {$r >= $max_cols} {incr c 2; set r 0}
        }
        grid $w.top
        grid $w.top.title_text

        grid $w.information
    }
}

proc ::FluidLauncher::ChangeAppTo {appid} {
    spdAux::deactiveApp FluidLauncher
    spdAux::SetSpatialDimmension undefined
    apps::setActiveApp $appid
}

::FluidLauncher::Init
