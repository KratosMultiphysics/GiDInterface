
proc Kratos::InstallAllPythonDependencies { } {

    if { $::tcl_platform(platform) == "windows" } { set os win } {set os unix}

    # Check if python is installed
    if {[pythonVersion] <= 0} {
        if {os eq "win"} {
            VisitWeb "https://www.microsoft.com/es-es/p/python-39/9p7qfqmjrfp7"
        } {
            exec "sudo apt-get install python3.9"
        }
    }

    # Check if pip is installed

    # Install pip packages
}

proc Kratos::pythonVersion {{pythonExecutable "python"}} {
    # Tricky point: Python 2.7 writes version info to stderr!
    catch {
        set info [exec $pythonExecutable --version 2>@1]
        if {[regexp {^Python ([\d.]+)$} $info --> version]} {
            return $version
        }
    }
    return 0
}


proc Kratos::CheckDependencies { } {
    if {[pythonVersion] <= 0} {error "Python not installed on this system. Please install python 3 manually or click on menu Kratos > Install dependencies"}

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
