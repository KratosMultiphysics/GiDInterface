
proc Kratos::InstallAllPythonDependencies { } {
    package require gid_cross_platform

    if { $::tcl_platform(platform) == "windows" } { set os win } {set os unix}
    set dir [lindex [Kratos::GetLaunchConfigurationFile] 0]
    set py [Kratos::GetPythonExeName]
    # Check if python is installed. minimum 3.5, best 3.9
    set python_version [pythonVersion $py]
    if { $python_version <= 0 || [GidUtils::TwoVersionsCmp $python_version "3.10.8"] <0 } {
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
    # W ""
}

proc Kratos::GetPythonExeName { } {

    if { $::tcl_platform(platform) == "windows" } { set os win } {set os unix}
    if {$os eq "win"} {set py "python"} {set py "python3"}
    return $py
}

proc Kratos::GetDefaultPythonPath { } {
    set pat ""
    if {true} {
        set pat [GiD_Python_GetPythonExe]
    } else {
        catch {
            set py [Kratos::GetPythonExeName]
            set pat [exec $py -c "import sys; print(sys.executable)"  2>@1]
        }
    }
    return $pat
}

proc Kratos::pythonVersion {{pythonExecutable "python"}} {
    # Tricky point: Python 2.7 writes version info to stderr!
    set ver 0
    catch {
        set info [exec $pythonExecutable --version 2>@1]
        set rege "{Python\s+(\d+)}"
        if {[regexp  {Python\s+(\d+\.\d+\.\d+)} $info --> version]} {
            set ver $version
        }
    }
    return $ver
}

proc Kratos::pipVersion { {pythonExecutable ""} } {

    if {$pythonExecutable eq ""} {
        if { $::tcl_platform(platform) == "windows" } { set os win } {set os unix}
        if {$os eq "win"} {set pip "pyw"} {set pip "python3"}
    } else {
        set pip $pythonExecutable
    }
    set ver 0

    catch {
        set info [exec $pip -m pip --version 2>@1]
        if {[regexp {pip\s+(\d+\.\d+)} $info --> version]} {
            set ver $version
        }
    }

    return $ver
}

proc Kratos::GetMissingPipPackages { } {
    variable pip_packages_required
    set missing_packages [list ]

    set py [Kratos::GetPythonExeName]
    set python_exe_path [Kratos::ManagePreferences GetValue python_path]
    set pip_packages_installed [list ]
    set pip_packages_installed_raw [exec $python_exe_path -m pip list --format=freeze --disable-pip-version-check 2>@1]
    foreach package $pip_packages_installed_raw {
        lappend pip_packages_installed [lindex [split $package "=="] 0]
    }
    foreach required_package $pip_packages_required {
        set required_package_name [lindex [split $required_package "=="] 0]
        if {$required_package_name ni $pip_packages_installed} {lappend missing_packages $required_package}
    }
    return $missing_packages
}

proc Kratos::GetMissingPipPackagesGiDsPython { } {
    variable pip_packages_required
    set missing_packages [list ]

    set pip_packages_installed [list ]
    set pip_packages_installed_versions [list ]
    set pip_packages_installed_raw [exec [Kratos::GetDefaultPythonPath] -m pip list --format=freeze --disable-pip-version-check 2>@1]
    foreach package $pip_packages_installed_raw {
        lappend pip_packages_installed [lindex [split $package "=="] 0]
        lappend pip_packages_installed_versions [lindex [split $package "=="] end]
    }
    foreach required_package $pip_packages_required {
        set required_package_name [lindex [split $required_package "=="] 0]
        set required_package_version [lindex [split $required_package "=="] end]

        set pos [lsearch $pip_packages_installed $required_package_name]
        if {$pos eq -1} {
            lappend missing_packages "${required_package}"
        } else {
            set installed_version [lindex $pip_packages_installed_versions $pos]
            if {$installed_version ne $required_package_version} {
                lappend missing_packages "${required_package}"
            }
        }
    }
    return $missing_packages
}

proc Kratos::CheckDependencies { {show 1} } {
    set curr_mode [Kratos::GetLaunchMode]
    set ret 0

    if {[dict exists $curr_mode dependency_check]} {
        set deps [dict get $curr_mode dependency_check]
        set ret [$deps]
    }
    if {$show} {ShowErrorsAndActions $ret}
    return $ret
}

proc Kratos::ShowErrorsAndActions {errs} {
    if { [GidUtils::IsTkDisabled] } {
        return 0
    }
    switch $errs {
        "MISSING_PYTHON" {
            W "Python 3 could not be found on this system."
            W "Please install python 3.9 with pip, and add the PATH to Kratos preferences before run the case."
            W "https://www.python.org/downloads/release/python-3913/"
        }
        "MISSING_PIP" {
            W "Pip is not installed on your system. Please install it by running in a terminal:"
            set py [Kratos::GetPythonExeName]
            set python_exe_path [Kratos::ManagePreferences GetValue python_path]
            set install_pip_path [file join $::Kratos::kratos_private(Path) exec get-pip.py]
            W "$python_exe_path $install_pip_path"
        }
        "MISSING_PIP_PACKAGES" {
            W "Kratos package was not found on your system."
            set py [Kratos::GetPythonExeName]
            set python_exe_path [Kratos::ManagePreferences GetValue python_path]
            W "Run the following command on a terminal (note: On Windows systems, use cmd, not PowerShell):"
            W "$python_exe_path -m pip install --upgrade --force-reinstall --no-cache-dir $Kratos::pip_packages_required"
        }
        "MISSING_PIP_PACKAGES_GiDS_PYTHON" {
            W "Kratos package was not found on your system."
            set py [Kratos::GetPythonExeName]
            set python_exe_path [Kratos::ManagePreferences GetValue python_path]
            W "Run the following command on the GiD Command line:"
            W "-np- W \[GiD_Python_PipInstallMissingPackages \[list $Kratos::pip_packages_required \] \]"
        }
        "DOCKER_NOT_FOUND" {
            W "Could not start docker. Please check if the Docker service is enabled."
        }
        "EXE_NOT_FOUND" {

        }
    }
}

proc Kratos::CheckDependenciesPipGiDsPythonMode {} {
    set ret 0

    # Assume GiD Always comes with python and pip
    set missing_packages [Kratos::GetMissingPipPackagesGiDsPython]
    if {[llength $missing_packages] > 0} {
        set ret "MISSING_PIP_PACKAGES_GiDS_PYTHON"
    }
    return $ret
}

proc Kratos::CheckDependenciesPipMode {} {
    set ret 0
    set python_exe_path [Kratos::ManagePreferences GetValue python_path]
    set py [Kratos::GetPythonExeName]

    set py_version [Kratos::pythonVersion $python_exe_path]
    if {$py_version <= 0} {
        set ret "MISSING_PYTHON"
    } else {
        set pip_version [Kratos::pipVersion]
        if {$pip_version <= 0} {
            set ret "MISSING_PIP"
        } else {
            set missing_packages [Kratos::GetMissingPipPackages]
            if {[llength $missing_packages] > 0} {
                set ret "MISSING_PIP_PACKAGES"
            }
        }
    }
    return $ret
}
proc Kratos::CheckDependenciesLocalPipMode {} {
    return 0
}
proc Kratos::CheckDependenciesLocalMode {} {
    return 0
}
proc Kratos::CheckDependenciesDockerMode {} {
    set ret 0
    set result ""
    try {
        set result [exec docker ps]
    } on error {msg} {
        set ret "DOCKER_NOT_FOUND"
    }
    return $ret
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
    switch [dict get $mode name] {
        Docker {
            set docker_image [Kratos::ManagePreferences GetValue docker_image]
            set ::env(kratos_docker_image) $docker_image
        }
        {Your compiled Kratos} {
            set python_path [Kratos::ManagePreferences GetValue python_path]
            set ::env(python_path) $python_path
            set kratos_bin_path [Kratos::ManagePreferences GetValue kratos_bin_path]
            set ::env(kratos_bin_path) $kratos_bin_path
        }
        {External python} {
            set python_path [Kratos::ManagePreferences GetValue python_path]
            set ::env(python_path) $python_path
        }
        Default {
            set python_path [GiD_Python_GetPythonExe]
            set ::env(python_path) $python_path
        }
        default {}
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

proc Kratos::StopCalculation { } {
    if {[dict get [Kratos::GetLaunchMode] name] eq "Docker"} {
        exec docker stop [Kratos::GetModelName]
    }
    GiD_Process Mescape Utilities CancelProcess escape escape
}

proc Kratos::CreateModeCombo {  } {
    global GidPriv
    set w .gid.bitmapsStdBar.execombo
    if { [winfo exists $w] } {
        destroy $w
    }
    ttk::frame $w -style Horizontal.ForcedFrame

    ttk::frame $w.f -borderwidth 0 -style ForcedFrame
    ttk::entry $w.e -cursor arrow -style ForcedCombobox

    bind $w.e <Enter> {
        %W state pressed
    }
    bind $w.e <Leave> {
        %W state !pressed
    }

    grid $w.f -sticky ew
    grid $w.e -in $w.f -sticky ew
    grid rowconfigure $w 0 -weight 1

    bind $w.e <ButtonPress-1> "[list open_layers_as_menu .gid $w.f]; break"
    bind $w.e <ButtonRelease-1> "break"
    bind $w.e <KeyPress> "break"
    bind $w.e <Key-Down> "[list open_layers_as_menu .gid $w.f]; break"

    set GidPriv(ComboLayers,entry) $w.e
    $w.e insert end [ GiD_Info Project LayerToUse]


    grid $w -col 9 -row 0 -padx 10 -sticky news

}