namespace eval Dam::xml {
     variable dir
}

proc Dam::xml::Init { } {
     variable dir
     Model::InitVariables dir $Dam::dir

     Model::getSolutionStrategies Strategies.xml
     Model::getElements Elements.xml
     Model::getNodalConditions NodalConditions.xml
     Model::getConstitutiveLaws ConstitutiveLaws.xml
     Model::getProcesses Processes.xml
     Model::getConditions Conditions.xml
     Model::getSolvers "../../Common/xml/Solvers.xml"
}

proc Dam::xml::getUniqueName {name} {
    return Dam$name
}


proc ::Dam::xml::MultiAppEvent {args} {
   if {$args eq "init"} {
     spdAux::parseRoutes
     spdAux::ConvertAllUniqueNames SL Dam
   }
}

proc Dam::xml::ProcGetSchemes {domNode args} {
     set type_of_problem [write::getValue DamTypeofProblem]
     
     set sol_stratUN "DamSolStratTherm"
     if {$type_of_problem ne "Thermal"} {
           set sol_stratUN "DamSolStrat"
     }
     
     set solStratName [write::getValue $sol_stratUN]
     set schemes [::Model::GetAvailableSchemes $solStratName]
     
     set ids [list ]
     if {[llength $schemes] == 0} {
         if {[get_domnode_attribute $domNode v] eq ""} {$domNode setAttribute v "None"}
         return "None"
     }
     set names [list ]
     set pnames [list ]
     foreach cl $schemes {
         lappend names [$cl getName]
         lappend pnames [$cl getName] 
         lappend pnames [$cl getPublicName]
     }
     if {$type_of_problem in [list "Acoustic" "UP_Mechanical"]} {
          set names [list "Newmark"]
          set pnames [list "Newmark" "Newmark"]
     }
     
     $domNode setAttribute values [join $names ","]
     
     if {[get_domnode_attribute $domNode v] eq ""} {$domNode setAttribute v [lindex $names 0]}
     if {[get_domnode_attribute $domNode v] ni $names} {$domNode setAttribute v [lindex $names 0]}
     spdAux::RequestRefresh
     return [join $pnames ","]
}


proc Dam::xml::SolStratParamState {outnode} {
    set doc $gid_groups_conds::doc
    set root [$doc documentElement]
    
    set solstrat_un "DamSolStrat"
    
    #W $solstrat_un
    if {[get_domnode_attribute [$root selectNodes [spdAux::getRoute $solstrat_un]] v] eq ""} {
        get_domnode_attribute [$root selectNodes [spdAux::getRoute $solstrat_un]] dict
    }
    set SolStrat [get_domnode_attribute [$root selectNodes [spdAux::getRoute $solstrat_un]] v]
    set paramName [$outnode @n]
    set ret [::Model::CheckSolStratInputState $SolStrat $paramName]
    if {$ret} {
        lassign [Model::GetSolStratParamDep $SolStrat $paramName] depN depV
        foreach node [[$outnode parent] childNodes] {
            if {[$node @n] eq $depN} {
                if {[get_domnode_attribute $node v] ni [split $depV ,]} {
                    set ret 0
                    break
                }
            }
        }
    }
    return $ret
}

proc Dam::xml::ProcGetConstitutiveLaws {domNode args} {
     set Elementname [$domNode selectNodes {string(../value[@n='Element']/@v)}]
     set Claws [::Model::GetAvailableConstitutiveLaws $Elementname]
     
     set type_of_problem [write::getValue DamTypeofProblem]
     set goodList [list ]
     foreach cl $Claws {
          set type [$cl getAttribute Type]
          if {[string first "Therm" $type] eq -1 && $type_of_problem ne "Thermo-Mechanical"} {
               lappend goodList $cl
          } elseif {[string first "Therm" $type] ne -1 && $type_of_problem eq "Thermo-Mechanical"} {
               lappend goodList $cl
          } elseif {[string first "Interface" $type] ne -1} {lappend goodList $cl}
     }
     set Claws $goodList
     set analysis_type [write::getValue DamAnalysisType]
     set TypeofProblem [get_domnode_attribute [$domNode selectNodes [spdAux::getRoute DamTypeofProblem]] v]
           switch $TypeofProblem {
               "Mechanical" {
                    set analysis_type [get_domnode_attribute [$domNode selectNodes "[spdAux::getRoute DamMechanicalData]/value\[@n='AnalysisType'\]"] v]                    
               }
               "Thermo-Mechanical" {
                    set analysis_type [get_domnode_attribute [$domNode selectNodes "[spdAux::getRoute "DamThermo-MechanicalData"]/container\[@n='MechanicalPartProblem'\]/value\[@n='AnalysisType'\]"] v]
               }
               "UP_Mechanical" {
                    set analysis_type [get_domnode_attribute [$domNode selectNodes "[spdAux::getRoute "DamUP_MechanicalData"]/value\[@n='AnalysisType'\]"] v]
               }
               "Acoustic" {
                    set analysis_type ""
               }
               default {
                    error [= "Check type of problem"]
               }
           }
     set goodList [list ]
     foreach cl $Claws {
          if {$analysis_type eq ""} {
               lappend goodList $cl
          } else {
               set type [$cl getAttribute AnalysisType]
               if {$analysis_type eq "Non-Linear"} {
                    lappend goodList $cl
               }
               if {$type ne "Non-Linear" && $analysis_type eq "Linear"} {
                    lappend goodList $cl
               }
          }
     }
     set Claws $goodList
   
     #W "Const Laws que han pasado la criba: $Claws"
     if {[llength $Claws] == 0} {
         if {[get_domnode_attribute $domNode v] eq ""} {$domNode setAttribute v "None"}
         return "None"
     }
     set names [list ]
     foreach cl $Claws {
         lappend names [$cl getName]
     }
     set values [join $names ","]
     if {[get_domnode_attribute $domNode v] eq "" || [get_domnode_attribute $domNode v] ni $names} {$domNode setAttribute v [lindex $names 0]; spdAux::RequestRefresh}
     
     
     return $values
}

proc Dam::xml::ProcCheckNodalConditionState {domNode args} {
     set parts_un DamParts
     if {[spdAux::getRoute $parts_un] ne ""} {
           set conditionId [$domNode @n]
           set elems [$domNode selectNodes "[spdAux::getRoute $parts_un]/group/value\[@n='Element'\]"]
           set elemnames [list ]
           foreach elem $elems { lappend elemnames [$elem @v]}
           set elemnames [lsort -unique $elemnames]
           
           # Mirar Type of problem y acceder al contenedor correcto
           set TypeofProblem [get_domnode_attribute [$domNode selectNodes [spdAux::getRoute DamTypeofProblem]] v]
           switch $TypeofProblem {
               "Mechanical" {
                    set solutionType [get_domnode_attribute [$domNode selectNodes "[spdAux::getRoute DamMechanicalData]/value\[@n='SolutionType'\]"] v]
                    set params [list analysis_type $solutionType TypeofProblem $TypeofProblem]
               }
               "Thermo-Mechanical" {
                    set solutionType [get_domnode_attribute [$domNode selectNodes "[spdAux::getRoute "DamThermo-MechanicalData"]/container\[@n='MechanicalPartProblem'\]/value\[@n='SolutionType'\]"] v]
                    set params [list analysis_type $solutionType TypeofProblem $TypeofProblem]                    
               }
               "UP_Mechanical" {
                    set solutionType [get_domnode_attribute [$domNode selectNodes "[spdAux::getRoute "DamUP_MechanicalData"]/value\[@n='SolutionType'\]"] v]
                    set params [list analysis_type $solutionType TypeofProblem $TypeofProblem]
               }
               "Acoustic" {
                    set params [list TypeofProblem $TypeofProblem]
               }
               default {
                    error [= "Check type of problem"]
               }
           }
           if {[::Model::CheckElementsNodalCondition $conditionId $elemnames $params]} {return "normal"} else {return "hidden"}
      } {return "hidden"}
}


proc Dam::xml::ProcGetSolutionStrategies {domNode args} {
     set names ""
     set pnames ""
     set ids [list ]
     set type_of_problem [lindex $args 0]
     if {$type_of_problem eq "Mechanic"} {set n [list "Newton-Raphson" "Arc-length"]} {set n "Generic"}
     if {$type_of_problem eq "UP_Mechanic"} {set n "Newton-Raphson"}
     set Sols [::Model::GetSolutionStrategies [list n $n] ]
     foreach ss $Sols {
          lappend names [$ss getName]
          lappend pnames [$ss getName]
          lappend pnames [$ss getPublicName] 
    }
    
    $domNode setAttribute values [join $names ","]
    set dv [lindex $names 0]
    #W "dv $dv"
    if {[$domNode getAttribute v] eq ""} {$domNode setAttribute v $dv; spdAux::RequestRefresh}
    if {[$domNode getAttribute v] ni $names} {$domNode setAttribute v $dv; spdAux::RequestRefresh}
    
    return [join $pnames ","]
}

proc Dam::xml::ProcGetElementsValues {domNode args} {
     set TypeofProblem [get_domnode_attribute [$domNode selectNodes [spdAux::getRoute DamTypeofProblem]] v]
     set nodeApp [spdAux::GetAppIdFromNode $domNode]
     set sol_stratUN [apps::getAppUniqueName $nodeApp SolStrat]
     set schemeUN [apps::getAppUniqueName $nodeApp Scheme]
     if {[get_domnode_attribute [$domNode selectNodes [spdAux::getRoute $sol_stratUN]] v] eq ""} {
        get_domnode_attribute [$domNode selectNodes [spdAux::getRoute $sol_stratUN]] dict
     }
     if {[get_domnode_attribute [$domNode selectNodes [spdAux::getRoute $schemeUN]] v] eq ""} {
        get_domnode_attribute [$domNode selectNodes [spdAux::getRoute $schemeUN]] dict
     }
     
     set solStratName [::write::getValue $sol_stratUN]
     set schemeName [write::getValue $schemeUN]
     set elems [::Model::GetAvailableElements $solStratName $schemeName]
     
     set names [list ]
     foreach elem $elems {
        if {[$elem cumple {*}$args]} {
            lappend names [$elem getName]
        }
     }
     if {$TypeofProblem ni [list UP_Mechanical Acoustic]} {
          set names [lsearch -all -inline -not -exact $names WaveEquationElement2D]
          set names [lsearch -all -inline -not -exact $names WaveEquationElement3D]
     }
     if {$TypeofProblem in [list Acoustic]} {
          set names [list WaveEquationElement2D]
          if {$::Model::SpatialDimension eq "3D"} {
               set names [list WaveEquationElement3D]
          }
     }
     if {[get_domnode_attribute $domNode v] eq ""} {$domNode setAttribute v [lindex $names 0]}
     if {[get_domnode_attribute $domNode v] ni $names} {$domNode setAttribute v [lindex $names 0]; spdAux::RequestRefresh}
     set values [join $names ","]
     return $values
}

Dam::xml::Init
