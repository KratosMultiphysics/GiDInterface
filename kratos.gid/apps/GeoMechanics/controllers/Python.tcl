proc ::GeoMechanics::PythonButton { } {
    set param1 "example parameter"
    GiD_Python_Source [file join $::GeoMechanics::dir controllers geomechanics_script.py]
    set result_python [GiD_Python_Call geomechanics_script.my_python_procedure $param1]
    W $result_python
}