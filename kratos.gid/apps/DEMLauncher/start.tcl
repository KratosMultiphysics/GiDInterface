namespace eval ::DemLauncher {
    Kratos::AddNamespace [namespace current]
    
    variable available_apps
}

proc ::DemLauncher::Init { app } {
    variable available_apps

    set available_apps [dict get [$app getProperty requirements] display_apps]

    ::DemLauncher::AppSelectorWindow
}

proc ::DemLauncher::AppSelectorWindow { } {
    variable available_apps
    
    spdAux::CreateLauncherWindow DemLauncher $available_apps 
}

