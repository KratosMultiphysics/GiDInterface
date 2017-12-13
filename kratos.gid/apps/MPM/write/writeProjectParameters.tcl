# Project Parameters
proc ::MPM::write::getParametersDict { } {
      
}
proc ::MPM::write::writeParametersEvent { } {
   
    set fc [open [file join [apps::getMyDir "MPM"] python "ProjectParameters.py"] r]
    set template [read $fc]
    close $fc
    
    set domain_size [string index [write::getValue nDim] 0]
    set solution_type "\"[write::getValue MPMSoluType]Solver\""

    set time_step [write::getValue MPMTimeParameters DeltaTime] 
    set end_time [write::getValue MPMTimeParameters EndTime] 

    set echo_level [write::getValue GiDOptions EchoLevel]

    set echo_level [write::getValue GiDOptions EchoLevel]

    set solver_type "\"[write::getValue MPMimplicitlinear_solver_settings Solver]\""
    set scaling "\"[write::getValue MPMimplicitlinear_solver_settings scaling]\""

    set GiDWriteFrequency [write::getValue Results OutputDeltaTime]  

    set problem_name_grid "\"[file tail [GiD_Info project ModelName]]_Grid\""
    set problem_name_body "\"[file tail [GiD_Info project ModelName]]_Body\""

    # Variable substitution
    set s [string map {\{ <} $template]
    set s [string map {\} >} $s]
    set s [string map {\[ ~} $s]
    set s [string map {\] &} $s]
    set t2 [subst "$s"]
    set s [string map {< \{} $t2]
    set s [string map {> \}} $s]
    set s [string map {~ \[} $s]
    set s [string map {& \]} $s]
    customlib::WriteString $s

    customlib::EndWriteFile
    
}

