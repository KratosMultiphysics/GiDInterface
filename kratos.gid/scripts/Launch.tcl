
proc Kratos::InstallAllPythonDependencies { } {

    if { $::tcl_platform(platform) == "windows" } { set os win } {set os unix}
    set dir [lindex [Kratos::GetLaunchConfigurationFile] 0]
    if {$os eq "win"} {set py "python"} {set py "python3"}
    # Check if python is installed. minimum 3.5, best 3.9
    set python_version [pythonVersion $py]
    if { $python_version <= 0 || [GidUtils::TwoVersionsCmp $python_version "3.9.0"] <0 } {
        if {$os eq "win"} {
            package require gid_cross_platform
            gid_cross_platform::run_as_administrator [file join $::Kratos::kratos_private(Path) exec install_python_and_dependencies.win.bat ] $dir
        } {
            exec "sudo apt-get install python3.9"
        }
    }

    set missing_packages [Kratos::GetMissingPipPackages]
    ::GidUtils::SetWarnLine "Installing pip packages $missing_packages"
    if {[llength $missing_packages] > 0} {
        exec pyw -m pip install --no-cache-dir --disable-pip-version-check {*}$missing_packages
    }
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
    set ver 0
    catch {
        set info [exec pyw -m pip --version 2>@1]
        if {[regexp {^pip ([\d.]+)*} $info --> version]} {
            set ver $version
        }
    }
    return $ver
}

proc Kratos::GetMissingPipPackages { } {
    set missing_packages [list ]
    set pip_packages_required [list KratosMultiphysics KratosFluidDynamicsApplication KratosConvectionDiffusionApplication \
    KratosDEMApplication numpy KratosDamApplication KratosSwimmingDEMApplication KratosStructuralApplication KratosMeshMovingApplication \
    KratosMappingApplication KratosParticleMechanicsApplication KratosLinearSolversApplication KratosContactStructuralMechanicsApplication]

    set pip_packages_installed [list ]
    set pip_packages_installed_raw [exec pyw -m pip list --format=freeze --disable-pip-version-check 2>@1]
    foreach package $pip_packages_installed_raw {
        lappend pip_packages_installed [lindex [split $package "=="] 0]
    }
    foreach required_package $pip_packages_required {
        if {$required_package ni $pip_packages_installed} {lappend missing_packages $required_package}
    }
    return $missing_packages
}


proc Kratos::CheckDependencies { } {
    if {[pythonVersion] <= 0} {
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
    } else {

    }
}

proc Kratos::GetLaunchConfigurationFile { } {
    set new_dir [file join $::env(HOME) .kratos_multiphysics]
    set file [file join $new_dir launch_configuration.json]
    return [list $new_dir $file]
}

proc Kratos::LoadLaunchModes { } {
    # Get location of launch config script
    lassign [Kratos::GetLaunchConfigurationFile] new_dir file

    # If it does not exist, copy it from exec
    if {[file exists $new_dir] == 0} {file mkdir $new_dir}
    if {[file exists $file] == 0} {
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
    foreach mode $::Kratos::kratos_private(configurations) {
        set mode_name [dict get $mode name]
        if {$mode_name eq $launch_mode} {
            set bat [dict get $mode script]
            set bat_file [file join exec $bat.$os.bat]
        }
    }
    return $bat_file
}
