###############################################################
#   This file is common for all Kratos Applications.
#   Do not change anything here unless it's strictly necessary.
###############################################################

proc Kratos::GetLogFilePath { } {
    variable kratos_private
    set gid_defaults [GiD_GetUserSettingsFilename -create_folders]
    set dir_name [file dirname $gid_defaults]
    set file_name $kratos_private(LogFilename)
    if {$file_name eq ""} {}
    if { $::tcl_platform(platform) == "windows" } {
        return [file join $dir_name KratosLogs $file_name]
    } else {
        return [file join $dir_name KratosLogs .$file_name]
    }
}

proc Kratos::InitLog { } {
    variable kratos_private
    set kratos_private(LogFilename) [clock format [clock seconds] -format "%Y%m%d%H%M%S"].log 
    set logpath [Kratos::GetLogFilePath]
    file mkdir [file dirname $logpath]
    set logfile [open $logpath "a+"];
    puts $logfile "Kratos Log Session"
    close $logfile
    set kratos_private(Log) [list ]
}

proc Kratos::Log {msg} {
    variable kratos_private
    
    if {[info exists kratos_private(Log)]} {
        lappend kratos_private(Log) "*~* [clock format [clock seconds] -format {%Z %Y-%m-%d %H:%M:%S }] | $msg"

        # One of the triggers is to flush if we've stored more than 5 
        if {[llength $kratos_private(Log)] > 5} {
            Kratos::FlushLog
        }
    }
}

proc Kratos::FlushLog { }  {
    variable kratos_private
    W "Hey"
    if {[info exists kratos_private(Log)]} {
        if {[llength $kratos_private(Log)] > 0} {
            set logpath [Kratos::GetLogFilePath]

            set logfile [open $logpath "a+"];

            try {
                foreach msg $kratos_private(Log) {
                    puts $logfile $msg
                }
                
            } finally {
                close $logfile
            }

            set kratos_private(Log) [list ]
        }
    }
    
}

proc Kratos::AutoFlush {} {
    Kratos::FlushLog
    after 5000 {Kratos::AutoFlush}
}

proc Kratos::ViewLog {} {
    package require gid_cross_platform
    FlushLog
    gid_cross_platform::open_by_extension [Kratos::GetLogFilePath]
}

#do not save preferences starting with flag gid.exe -c (that specify read only an alternative file)
if { [GiD_Set SaveGidDefaults] } {
    Kratos::InitLog
    Kratos::AutoFlush
}

