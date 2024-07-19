namespace eval ::BasicLauncher {
    Kratos::AddNamespace [namespace current]

    variable available_apps
}

proc ::BasicLauncher::Init { app } {
    variable available_apps

    set available_apps [dict get [$app getProperty requirements] display_apps]
    
    ::BasicLauncher::AppSelectorWindow
}

proc ::BasicLauncher::AppSelectorWindow { } {
    variable available_apps

    spdAux::CreateLauncherWindow BasicLauncher $available_apps [_ "Basic applications"] [_ "Select a basic application"]
}
