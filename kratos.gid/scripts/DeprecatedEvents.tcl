##################################################################################
#   This file is common for all Kratos Applications.
#   Do not change anything here unless it's strictly necessary.
##################################################################################

# Deprecated events that have been replaced
# If you are using one of this old methods, change to the new one or die!
WarnWin 1

##########################################################
#################### GiD Tcl events ######################
##########################################################

# Load GiD project files (initialise XML Tdom structure)
proc GiD_Event_AfterReadGIDProject { filename } {
    #W "GiD_Event_AfterReadGIDProject"
    set name [file tail $filename]
    set spd_file [file join ${filename}.gid ${name}.spd]
    Kratos::Event_LoadModelSPD $spd_file
}

proc EndGIDProject {} {
    Kratos::Event_EndProblemtype
}
WarnWin 2
proc ChangedLanguage { newlan } {
    Kratos::Event_ChangedLanguage
}

proc InitGIDPostProcess {} {
    ::Kratos::Event_InitGIDPostProcess
}

proc EndGIDPostProcess {} {
    ::Kratos::Event_EndGIDPostProcess
}
WarnWin 3
# Save GiD project files (save XML Tdom structure to spd file)
proc SaveGIDProject { filespd } {
    Kratos::Event_SaveModelSPD $filespd
}

proc AfterWriteCalcFileGIDProject { fname errorflag } {
    return [Kratos::Event_AfterWriteCalculationFile $fname $errorflag]
}

proc GiD_Event_BeforeMeshGeneration { elementsize } {
    return [Kratos::Event_BeforeMeshGeneration $elementsize]
}
WarnWin 4
proc AfterMeshGeneration { fail } {
    Kratos::Event_AfterMeshGeneration $fail
}

proc BeforeRunCalculation { batfilename basename dir problemtypedir gidexe args } {
    Kratos::Event_BeforeRunCalculation $batfilename $basename $dir $problemtypedir $gidexe {*}$args 
}

proc GiD_Event_BeforeSaveGIDProject { modelname} {
    Kratos::Event_BeforeSaveGIDProject $modelname
}

proc AfterRenameGroup { oldname newname } {
    spdAux::RenameIntervalGroup $oldname $newname
}
WarnWin 5