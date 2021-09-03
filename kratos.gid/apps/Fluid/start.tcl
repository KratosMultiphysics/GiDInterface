namespace eval ::Kratos::Fluid {
    # Variable declaration
    variable _app
    variable dir


    proc Init { app } {
        # Variable initialization
        variable _app
        variable dir

        set _app $app
        set dir [apps::getMyDir "Fluid"]
        
        # XML init event
        xml::Init $dir
        write::Init
    }

    proc GetAttribute {name}     {variable _app; return [$_app getProperty $name]}
    proc GetUniqueName {name}    {variable _app; return [$_app getUniqueName $name]}
    proc GetWriteProperty {name} {variable _app; return [$_app getWriteProperty $name]}
}