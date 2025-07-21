namespace eval ::PfemSw::write {
    namespace path ::PfemSw
    Kratos::AddNamespace [namespace current]

    variable pfem_project_parameters
    variable sw_project_parameters
    variable mdpa_names
}

proc ::PfemSw::write::Init { } {
    variable pfem_project_parameters
    variable sw_project_parameters
    set pfem_project_parameters [dict create ]
    set sw_project_parameters [dict create ]

    variable mdpa_names
    set mdpa_names [dict create ]
}

# Events
proc ::PfemSw::write::writeModelPartEvent { } {
    variable mdpa_names
    set filename [Kratos::GetModelName]

    # check folder exists

    PfemFluid::write::Init
    PfemFluid::write::InitConditionsMap
    PfemFluid::write::SetCoordinatesByGroups 1
    write::writeAppMDPA PfemFluid
    dict set mdpa_names PfemFluid "${filename}_PFEM"
    write::RenameFileInModel "$filename.mdpa" "pfem/[dict get $mdpa_names PfemFluid].mdpa"

    ShallowWater::write::Init
    ShallowWater::write::SetCoordinatesByGroups 1
    write::writeAppMDPA ShallowWater
    dict set mdpa_names ShallowWater "${filename}_SW"
    write::RenameFileInModel "$filename.mdpa" "sw/[dict get $mdpa_names ShallowWater].mdpa"
}
