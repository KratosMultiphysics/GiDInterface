
proc Kratos::ManagePreferences { cmd name {value ""}} {
    return 0
    #name is of the form tk_NormalFont_family tk_NormalFont_size tk_NormalFont_weight
    set pref_name_list [ split $name _]
    set tkfont_name [ lindex $pref_name_list 1]
    set tkfont_option [ lindex $pref_name_list 2]
    set ret ""
    switch $cmd {
        "GetValue" {
            switch $tkfont_option {
                "dev_mode" {
                    set ret $::Kratos::kratos_private(DevMode)
                }
            }
        }
        "SetValue" {
            set err [ catch {
                switch $tkfont_option {
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
            switch $tkfont_option {
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
    W "called"
    if {[info exists kratos_private(Path)]} {
        set findnode [$root find "name" "general"]
        
        if { $findnode != "" } {
            set xml_preferences_filename [file join $kratos_private(Path) scripts controllers Preferences.xml]
            set xml_data [GidUtils::ReadFile $xml_preferences_filename] 
            CreateWidgetsFromXml::AddAfterName $root "general" $xml_data 
            W "cargado"
        }
    }
    return 0
}

