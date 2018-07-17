##################################################################################
#   This file is common for all Kratos Applications.
#   Do not change anything here unless it's strictly necessary.
##################################################################################

namespace eval Model {
# Clase Solution Strategey
catch {Solver destroy}
oo::class create Solver {
    superclass Entity
    
    variable parallelism 
    constructor {n} {
        next $n
        variable parallelism
        set parallelism OpenMP
    }
    
    method setParallelism {partype} {variable parallelism; set parallelism [split $partype ","]}
    method getParallelism { } {variable parallelism; return $parallelism}
}

# Clase Solution Strategey
catch {SolverEntry destroy}
oo::class create SolverEntry {
    superclass Entity
    variable listofdefaults
    variable defaultvalues
    variable solver_filters
    
    constructor {n} {
        variable listofdefaults
        variable defaultvalues
        variable solver_filters
        next $n
        set listofdefaults [list ]
        set defaultvalues [dict create]
        set solver_filters [dict create]
    }
    method addDefaultSolver {solname} {variable listofdefaults; lappend listofdefaults $solname}
    method getDefaultSolvers {} {variable listofdefaults; return $listofdefaults}

    method setSolverFilters {att val} {variable solver_filters; dict set solver_filters $att $val}
    method hasSolverFilters {att} {
        variable solver_filters
        return [dict exists $solver_filters $att]
    }
    method getSolverFilters {att} {
        variable solver_filters
        set v ""
        if {[dict exists $solver_filters $att]} {
            set v [dict get $solver_filters $att]
        }
        return $v
    }
    method addSolverFilters {key values} {variable solver_filters; dict set solver_filters $key $values}
    method getSolverFilters {} {variable solver_filters; return $solver_filters}
}
}


proc Model::ForgetSolvers { } {
    variable Solvers
    set Solvers [list ]
}

proc Model::ForgetSolver { elem_id } {
    variable Solvers
    set Solvers2 [list ]
    foreach elem $Solvers {
        if {[$elem getName] ne $elem_id} {
            lappend Solvers2 $elem
        }
    }
    set Solvers $Solvers2
}

proc Model::GetSolver { id } {
    variable Solvers
    
    foreach s $Solvers {
        if {[$s getName] eq $id} {return $s}
    }
    
}

proc Model::GetAllSolvers { } {
    variable Solvers
    return $Solvers
}

proc Model::ParseSolvers { doc } {
    variable Solvers
    
    set SolNodeList [$doc getElementsByTagName solver]
    foreach SolNode $SolNodeList {
        lappend Solvers [ParseSolverNode $SolNode]
    }
}

proc Model::ParseSolverNode { node } {
    set name [$node getAttribute n]
    
    set sl [::Model::Solver new $name]
    $sl setPublicName [$node getAttribute pn]
    if {[$node hasAttribute Parallelism]} {$sl setParallelism [$node getAttribute Parallelism]}
    foreach attr [$node attributes] {
        $sl setAttribute $attr [$node getAttribute $attr]
    }
    foreach in [[$node getElementsByTagName inputs] getElementsByTagName parameter] {
        set sl [ParseInputParamNode $sl $in]
    }
    return $sl
}

proc Model::ParseSolverEntry {st sen} {
    set n [$sen @n]
    set pn [$sen @pn]
    
    set se [::Model::SolverEntry new $n]
    $se setPublicName $pn
    foreach attr [$sen attributes] {
        $se setAttribute $attr [$sen getAttribute $attr]
    }
    foreach f [$sen getElementsByTagName filter] {
        $se addSolverFilters [$f @field] [$f @value]    
    }
    set defnodes [$sen selectNodes "./defaults/solver"]
    if {$defnodes ne ""} {
        foreach defnode $defnodes {
            set defsolname [$defnode @n]
            $se addDefaultSolver $defsolname
        }
    }
    $st addSolverEntry $se
    
    return $st
}

proc Model::GetAllSolversParams {} {
    variable Solvers
    
    set inputs [dict create ]
    foreach s $Solvers {
        foreach {k v} [$s getInputs] {
            dict set inputs $k $v
        }
    }
    return $inputs
}

proc Model::getSolverParamState {args} {
    variable Solvers
    lassign $args solvid inputid
    foreach solver $Solvers {
        if {[$solver getName] eq $solvid} {
            return [string compare [$solver getInputPn $inputid] ""]
        }
    }
    return 0
}
