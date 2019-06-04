
proc Kratos::ManagePreferences { cmd name {value ""}} {
    W "$cmd $name $value"
    set ret ""
    switch $cmd {
        "GetValue" {
            switch $name {
                "dev_mode" {
                    set ret $::Kratos::kratos_private(DevMode)
                }
            }
        }
        "SetValue" {
            set err [ catch {
                switch $name {
                    "dev_mode" {
                        set ::Kratos::kratos_private(DevMode) $value
                    }
                }
            } err_txt ]
            if { $err} {
                ErrorWin $err_txt
            }
        }
        "GetDefaultValue" {
            # same as GetValue
            switch $name {
            "dev_mode" {
                set ret "release"
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

