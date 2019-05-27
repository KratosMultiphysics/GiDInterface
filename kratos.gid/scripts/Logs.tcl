###############################################################
#   This file is common for all Kratos Applications.
#   Do not change anything here unless it's strictly necessary.
###############################################################

package require logger


proc Kratos::GetLogFilePath { } {
    variable kratos_private
    set dir_name [file dirname [GiveGidDefaultsFile]]
    set file_name $kratos_private(LogNameName)
    if {$file_name eq ""} {}
    if { $::tcl_platform(platform) == "windows" } {
        return [file join $dir_name KratosLogs $file_name]
    } else {
        return [file join $dir_name KratosLogs .$file_name]
    }
}

proc Kratos::InitLog { } {
    variable kratos_private
    set kratos_private(LogNameName) [clock format [clock seconds] -format "%Y%m%d%H%M%S"].log 
    set logpath [Kratos::GetLogFilePath]
    file mkdir [file dirname $logpath]
    set logfile [open $logpath "a+"];
    puts $logfile "Allah"
    close $logfile
    W $logpath
}

proc Kratos::Log {msg} {

}

proc Kratos::FlushLog { }  {

}
