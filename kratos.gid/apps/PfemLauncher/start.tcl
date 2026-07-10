namespace eval ::PfemLauncher {
    Kratos::AddNamespace [namespace current]
    
    variable available_apps
}

proc ::PfemLauncher::Init { app } {
    variable available_apps

    set available_apps [dict get [$app getProperty requirements] display_apps]
    
    ::PfemLauncher::AppSelectorWindow
}

proc ::PfemLauncher::AppSelectorWindow { } {
    variable available_apps
    
    spdAux::CreateLauncherWindow PfemLauncher $available_apps [_ "Pfem applications"] [_ "Select a Pfem application"]
}
