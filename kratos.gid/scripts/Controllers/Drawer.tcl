namespace eval Drawer {
    variable registered_procs
    variable vars
}

proc Drawer::Init { } {
    variable registered_procs
    set registered_procs [dict create]
    variable vars
    set vars [dict create ]
    variable ids
    set ids [dict create ]
}

proc Drawer::Register {name procedure varis} {
    variable registered_procs
    dict set registered_procs $name $procedure
    variable vars
    dict set vars $name $varis
    variable ids
    dict set ids $name [GiD_OpenGL register $procedure]
}

proc Drawer::Unregister {name} {
    variable registered_procs
    variable vars
    variable ids
    if {[dict exist $ids $name]} {
        set id [dict get $ids $name]
        GiD_OpenGL unregister $id
        dict unset registered_procs $name
        dict unset vars $name
        dict unset ids $name
    }
}

proc Drawer::UnregisterAll {} {
    variable ids
    foreach key [dict keys $ids] {
        Unregister $key
    }
}

proc Drawer::GetVars {name} {
    variable vars
    return [dict get $vars $name]
}

proc Drawer::IsRegistered {name} {
    variable ids
    return [dict exist $ids $name]
}

Drawer::Init