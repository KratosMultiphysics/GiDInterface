namespace eval ::FluidLauncher {
    Kratos::AddNamespace [namespace current]

    variable available_apps
}

proc ::FluidLauncher::Init { app } {
    variable available_apps

    set available_apps [dict get [$app getProperty requirements] display_apps]
    
    ::FluidLauncher::FluidAppSelectorWindow
}

proc ::FluidLauncher::FluidAppSelectorWindow { } {
    variable available_apps

    spdAux::CreateLauncherWindow FluidLauncher $available_apps [_ "Fluid applications"] [_ "Select a fluid application"]
}
