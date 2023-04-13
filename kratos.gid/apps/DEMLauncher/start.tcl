namespace eval ::DemLauncher {
    Kratos::AddNamespace [namespace current]
    
    variable available_apps
}

proc ::DemLauncher::Init { app } {
    variable available_apps

    set available_apps [dict get [$app getProperty requeriments] display_apps]

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

        set initwind $::spdAux::application_window_id
        spdAux::DestroyWindows
        spdAux::RegisterWindow $initwind
        set w $initwind

        InitWindow $w [_ "DEM applications"] Kratos "" "" 1
        set initwind $w
        ttk::frame $w.top
        ttk::label $w.top.title_text -text [_ "Select a DEM application"]

        ttk::frame $w.applications  -relief ridge
        set i 0
        foreach app $available_apps {
            set img [::apps::getImgFrom $app]
            set app_publicname [[::apps::getAppById $app] getPublicName]
            set but [ttk::button $w.applications.img$app -image $img -command [list ::DemLauncher::ChangeAppTo $app] ]
            bind $w.applications.img$app <Enter> {::spdAux::PlaceInformationWindowByPath %W applications}
            ttk::label $w.applications.text$app -text $app_publicname
            grid $w.applications.img$app -column $i -row 0
            grid $w.applications.text$app -column $i -row 1
            incr i
        }
        grid $w.top
        grid $w.top.title_text

        grid $w.applications

        # Information panel
        set spdAux::info_main_window_text ""
        ttk::labelframe $w.info -text " Information " -relief ridge 
        ttk::label $w.info.text -textvariable spdAux::info_main_window_text
        grid $w.info.text
        grid $w.info -sticky we
    }
}

proc ::DemLauncher::ChangeAppTo {appid} {
    spdAux::deactiveApp DemLauncher
    spdAux::SetSpatialDimmension undefined
    apps::setActiveApp $appid
}
