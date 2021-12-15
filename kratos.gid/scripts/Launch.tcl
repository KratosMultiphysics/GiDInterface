
proc Kratos::InstallAllPythonDependencies { } {
    package require gid_cross_platform

    if { $::tcl_platform(platform) == "windows" } { set os win } {set os unix}
    set dir [lindex [Kratos::GetLaunchConfigurationFile] 0]
    if {$os eq "win"} {set py "python"} {set py "python3"}
    # Check if python is installed. minimum 3.5, best 3.9
    set python_version [pythonVersion $py]
    if { $python_version <= 0 || [GidUtils::TwoVersionsCmp $python_version "3.9.0"] <0 } {
        ::GidUtils::SetWarnLine "Installing python"
        if {$os eq "win"} {
            gid_cross_platform::run_as_administrator [file join $::Kratos::kratos_private(Path) exec install_python_and_dependencies.win.bat ] $dir
        } {
            gid_cross_platform::run_as_administrator [file join $::Kratos::kratos_private(Path) exec install_python_and_dependencies.unix.sh ]
        }
    }

    if {$os ne "win"} {
        ::GidUtils::SetWarnLine "Installing python dependencies"
        gid_cross_platform::run_as_administrator [file join $::Kratos::kratos_private(Path) exec install_python_and_dependencies.unix.sh ]
    }

    if {$os eq "win"} {set pip "pyw"} {set pip "python3"}
    set missing_packages [Kratos::GetMissingPipPackages]
    ::GidUtils::SetWarnLine "Installing pip packages $missing_packages"
    if {[llength $missing_packages] > 0} {
        exec $pip -m pip install --no-cache-dir --disable-pip-version-check {*}$missing_packages
    }
    exec $pip -m pip install --upgrade --no-cache-dir --disable-pip-version-check {*}$Kratos::pip_packages_required
    ::GidUtils::SetWarnLine "Packages updated"
}

proc Kratos::InstallPip { } {
    W ""
}

proc Kratos::pythonVersion {{pythonExecutable "python"}} {
    # Tricky point: Python 2.7 writes version info to stderr!
    set ver 0
    catch {
        set info [exec $pythonExecutable --version 2>@1]
        if {[regexp {^Python ([\d.]+)$} $info --> version]} {
            set ver $version
        }
    }
    return $ver
}

proc Kratos::pipVersion { } {

    if { $::tcl_platform(platform) == "windows" } { set os win } {set os unix}
    if {$os eq "win"} {set pip "pyw"} {set pip "python3"}
    set ver 0
    catch {
        set info [exec $pip -m pip --version 2>@1]
        if {[regexp {^pip ([\d.]+)*} $info --> version]} {
            set ver $version
        }
    }
    return $ver
}

proc Kratos::GetMissingPipPackages { } {
    variable pip_packages_required
    set missing_packages [list ]


    if { $::tcl_platform(platform) == "windows" } { set os win } {set os unix}
    if {$os eq "win"} {set pip "pyw"} {set pip "python3"}
    set pip_packages_installed [list ]
    set pip_packages_installed_raw [exec $pip -m pip list --format=freeze --disable-pip-version-check 2>@1]
    foreach package $pip_packages_installed_raw {
        lappend pip_packages_installed [lindex [split $package "=="] 0]
    }
    foreach required_package $pip_packages_required {
        if {$required_package ni $pip_packages_installed} {lappend missing_packages $required_package}
    }
    return $missing_packages
}


proc Kratos::CheckDependencies { } {
    set curr_mode [Kratos::GetLaunchMode]
    # W $curr_mode
    if {[dict exists $curr_mode dependency_check]} {
        set deps [dict get $curr_mode dependency_check]
        $deps
    }
}

proc Kratos::CheckDependenciesPipMode {} {
    if { [GidUtils::IsTkDisabled] } {
        return 0
    }
    if { $::tcl_platform(platform) == "windows" } { set os win } {set os unix}
    if {$os eq "win"} {set py "python"} {set py "python3"}
    set py_version [Kratos::pythonVersion $py]
    if {$py_version <= 0} {
        set msgBox_type yesno
        #  -do_not_ask_again 1 -do_not_ask_again_key "kratos_install_python"
        set reply [tk_messageBox -icon warning -type $msgBox_type -parent .gid \
                -message "Python 3 not installed on this system. Do you want Kratos to install it?" \
                -title [_ "Missing python"]]
        if {[string equal $reply "yes"]} {
            Kratos::InstallAllPythonDependencies
        }
        if {[string equal $reply "cancel"]} {

        }
    }
    set pip_version [Kratos::pipVersion]
    if {$pip_version <= 0} {
        WarnWin "pip is not installed on your system. Please install it."
    } else {
        set missing_packages [Kratos::GetMissingPipPackages]
        if {[llength $missing_packages] > 0} {
            set msgBox_type yesno
            #  -do_not_ask_again 1 -do_not_ask_again_key "kratos_install_python"
            set reply [tk_messageBox -icon warning -type $msgBox_type -parent .gid \
                    -message "Python $py_version is installed, but there are some missing packages. Do you want Kratos to install them? \n\nPackages to be installed: \n$missing_packages" \
                    -title [_ "Missing python packages"]]
            if {[string equal $reply "yes"]} {
                Kratos::InstallAllPythonDependencies
            }
            if {[string equal $reply "cancel"]} {

            }
        }
    }
}
proc Kratos::CheckDependenciesLocalPipMode {} {

}
proc Kratos::CheckDependenciesLocalMode {} {
    W "local"
}
proc Kratos::CheckDependenciesDockerMode {} {

}

proc Kratos::GetLaunchConfigurationFile { } {
    set new_dir [file join $::env(HOME) .kratos_multiphysics]
    set file [file join $new_dir launch_configuration.json]
    return [list $new_dir $file]
}

proc Kratos::LoadLaunchModes { {force 0} } {
    # Get location of launch config script
    lassign [Kratos::GetLaunchConfigurationFile] new_dir file

    # If it does not exist, copy it from exec
    if {[file exists $new_dir] == 0} {file mkdir $new_dir}
    if {[file exists $file] == 0 || $force} {
        ::GidUtils::SetWarnLine "Loading launch mode"
        set source [file join $::Kratos::kratos_private(Path) exec launch.json]
        file copy -force $source $file
    }

    # Load configurations
    Kratos::LoadConfigurationFile $file
}

proc Kratos::LoadConfigurationFile {config_file} {
    if {[file exists $config_file] == 0} { error "Configuration file not found: $config_file" }

    set dic [Kratos::ReadJsonDict $config_file]
    set ::Kratos::kratos_private(configurations) [dict get $dic configurations]
}

proc Kratos::SetDefaultLaunchMode { } {
    set curr_mode $Kratos::kratos_private(launch_configuration)
    set modes [list ]
    set first ""
    foreach mode $::Kratos::kratos_private(configurations) {
        set mode_name [dict get $mode name]
        lappend modes $mode_name
        if {$first eq ""} {set first $mode_name}
    }
    if {$curr_mode ni $modes} {set Kratos::kratos_private(launch_configuration) $first}
}

proc Kratos::ExecuteLaunchByMode {launch_mode} {
    set bat_file ""
    if { $::tcl_platform(platform) == "windows" } { set os win } {set os unix}
    set mode [Kratos::GetLaunchMode $launch_mode]
    if {$mode ne ""} {
        set bat [dict get $mode script]
        set bat_file [file join exec $bat.$os.bat]
    }

    return $bat_file
}

proc Kratos::GetLaunchMode { {launch_mode "current"} } {
    set curr_mode ""
    if {$launch_mode eq "current"} {set launch_mode $Kratos::kratos_private(launch_configuration)}
    foreach mode $::Kratos::kratos_private(configurations) {
        set mode_name [dict get $mode name]
        if {$mode_name eq $launch_mode} {
            set curr_mode $mode
        }
    }
    return $curr_mode
}