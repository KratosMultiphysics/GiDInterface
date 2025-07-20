namespace eval ::ThermicLauncher {
    Kratos::AddNamespace [namespace current]
    
    variable available_apps
}

proc ::ThermicLauncher::Init { app } {
    variable available_apps
    
    set available_apps [dict get [$app getProperty requirements] display_apps]

    ::ThermicLauncher::AppSelectorWindow
}

proc ::ThermicLauncher::AppSelectorWindow { } {
    variable available_apps
    
    spdAux::CreateLauncherWindow ThermicLauncher $available_apps [_ "Thermic applications"] [_ "Select a Thermic application"]
}
