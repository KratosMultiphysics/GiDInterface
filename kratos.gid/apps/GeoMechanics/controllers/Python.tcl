proc ::GeoMechanics::PythonButton { } {
    set param1 "example parameter"
    GiD_Python_Source [file join $::GeoMechanics::dir controllers geomechanics_script.py]
    set result_python [GiD_Python_Call geomechanics_script.my_python_procedure $param1]
    W $result_python
}

proc ::GeoMechanics::PythonButtonImportPlaxis { } {
    set directory [MessageBoxGetFilename directory read [_ "Select Plaxis model to import"]]
    if {$directory == ""} {
        return
    }
    GiD_Python_Source [file join $::GeoMechanics::dir controllers geomechanics_import_plaxis.py]
    set result_python [GiD_Python_Call geomechanics_import_plaxis.import_plaxis_procedure $directory]
    W $result_python
}