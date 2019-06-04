
proc Kratos::ManagePreferences { cmd name {value ""}} {
    set ret ""
    switch $cmd {
        "GetValue" {
            set ret $::Kratos::kratos_private($name)
        }
        "SetValue" {
            set ::Kratos::kratos_private($name) $value
        }
        "GetDefaultValue" {
            # same as GetValue
            switch $name {
            "DevMode" {
                set ret "release"
            }
            "echo_level" {
                set ret 0
            }
            }
        }
    }
    
    Kratos::RegisterEnvironment
    spdAux::RequestRefresh
    return $ret
}

proc Kratos::ModifyPreferencesWindow { root } {
    variable kratos_private

    if {[info exists kratos_private(Path)]} {
        set findnode [$root find "name" "general"]
        
        if { $findnode != "" } {
            set xml_preferences_filename [file join $kratos_private(Path) scripts controllers Preferences.xml]
            set xml_data [GidUtils::ReadFile $xml_preferences_filename] 
            CreateWidgetsFromXml::AddAfterName $root "general" $xml_data 
            CreateWidgetsFromXml::UpdatePreferencesWindow
        }
    }
    return 0
}

