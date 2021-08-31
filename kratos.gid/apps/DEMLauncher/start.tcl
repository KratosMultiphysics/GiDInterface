namespace eval ::DemLauncher {
    variable available_apps
}

proc ::DemLauncher::Init { app } {
    variable available_apps

    # TODO: Get apps from json
    set available_apps [list DEM DEMPFEM FluidDEM CDEM]
    # Allow to open the tree
    set ::spdAux::TreeVisibility 0

    ::DemLauncher::AppSelectorWindow
}

proc ::DemLauncher::AppSelectorWindow { } {
    variable available_apps
    set initwind $::spdAux::initwind

    set root [customlib::GetBaseRoot]
    set nd [ [$root selectNodes "value\[@n='nDim'\]"] getAttribute v]
    if { $nd ne "undefined" } {
        # if {[apps::getActiveAppId] eq "Fluid"} {
        #     spdAux::SwitchDimAndCreateWindow $nd
        # }
    } {
        [$root selectNodes "value\[@n='nDim'\]"] setAttribute v wait

        set initwind .gid.win_dem_launcher
        spdAux::DestroyWindows
        spdAux::RegisterWindow $initwind
        toplevel $initwind
        wm withdraw $initwind

        set w $initwind

        set x [expr [winfo rootx .gid]+[winfo width .gid]/2-[winfo width $w]/2]
        set y [expr [winfo rooty .gid]+[winfo height .gid]/2-[winfo height $w]/2]

        wm geom $initwind +$x+$y
        wm transient $initwind .gid

        InitWindow $w [_ "DEM applications"] Kratos "" "" 1
        set initwind $w
        ttk::frame $w.top
        ttk::label $w.top.title_text -text [_ "Select a DEM application"]

        ttk::frame $w.information  -relief ridge
        set i 0
        foreach app $available_apps {
            set img [::apps::getImgFrom $app]
            set app_publicname [[::apps::getAppById $app] getPublicName]
            set but [ttk::button $w.information.img$app -image $img -command [list ::DemLauncher::ChangeAppTo $app] ]
            ttk::label $w.information.text$app -text $app_publicname
            grid $w.information.img$app -column $i -row 0
            grid $w.information.text$app -column $i -row 1
            incr i
        }
        grid $w.top
        grid $w.top.title_text

        grid $w.information
    }
}

proc ::DemLauncher::ChangeAppTo {appid} {
    spdAux::deactiveApp DemLauncher
    spdAux::SetSpatialDimmension undefined
    apps::setActiveApp $appid
}
