##################################################################################
#   This file is common for all Kratos Applications.
#   Do not change anything here unless it's strictly necessary.
##################################################################################

namespace eval ::Model {

# Clase CLaw
catch {CLaw destroy}
oo::class create CLaw {
    superclass Entity
    
    variable kratos_name
    variable output_mode
    variable MaterialFilters

    constructor {n} {
        next $n
        variable kratos_name
        set kratos_name ""

        # Can be "Parameter"|"Material"
        variable output_mode
        set output_mode "Parameters"

        variable MaterialFilters
        set MaterialFilters [dict create]
    }
    
    method cumple {args} {
        set c [next {*}$args]
         
        if {$c} {
            set ptdim $::Model::SpatialDimension
            set eldim [split [my getAttribute "Dimension"] ","]
            if {$eldim ne ""} {
                if {$ptdim ni $eldim} {set c 0}
            }
        }
        
        return $c
    }

    method setKratosName {kn} {
        variable kratos_name
        set kratos_name $kn
    }
    method getKratosName { } {
        variable kratos_name
        if {$kratos_name eq ""} {return [my getName]} {return $kratos_name}
    }
    method setOutputMode {om} {
        variable output_mode
        set output_mode $om
    }
    method getOutputMode { } {
        variable output_mode
        return $output_mode
    }
    method addMaterialFilter {key value} {variable MaterialFilters; dict set MaterialFilters $key $value}
    method getMaterialFilterValue {key} {
        variable constLawFilters;
        
        set v ""
        if {[dict exists $MaterialFilters $key]} {
            set v [dict get $MaterialFilters $key]
        }
        return $v
    }
    method getMaterialFilters {} {
        variable MaterialFilters
        
        set v [list ]
        if {[info exists MaterialFilters]} {
            foreach k [dict keys $MaterialFilters] {
                lappend v $k [dict get $MaterialFilters $k] 
            }
        }
        return $v
    }
}

}

proc Model::ParseConstitutiveLaws { doc } {
    variable ConstitutiveLaws
    
    set SolNodeList [$doc getElementsByTagName CLaw]
    foreach SolNode $SolNodeList {
        lappend ConstitutiveLaws [ParseClawNode $SolNode]
    }
}

proc Model::ParseClawNode { node } {
    set name [$node getAttribute n]
    
    set cl [::Model::CLaw new $name]
    $cl setPublicName [$node getAttribute pn]
    $cl setHelp [$node getAttribute help]
    if {[$node hasAttribute OutputMode]} {$cl setOutputMode [$node getAttribute OutputMode]}
    
    if {[$node hasAttribute KratosName]} {$cl setKratosName [$node getAttribute KratosName]}
    
    foreach attr [$node attributes] {
        $cl addAttribute $attr [$node getAttribute $attr]
    }
    
    foreach in [[$node getElementsByTagName inputs] getElementsByTagName parameter] {
        set $cl [ParseInputParamNode $cl $in]
    }
    foreach out [[$node getElementsByTagName outputs] getElementsByTagName parameter] {
        $cl addOutput [$out getAttribute n] [$out getAttribute pn]
    }
    if {[$node getElementsByTagName Material_FilterFeatures] != ""} {
        foreach mft [[$node getElementsByTagName Material_FilterFeatures] getElementsByTagName filter] {
            $cl addMaterialFilter [$mft getAttribute field] [$mft getAttribute value]
        }
    }
    return $cl
}


proc Model::GetConstitutiveLaws { args } {
    variable ConstitutiveLaws
    set cumplen [list ]
    foreach cl $ConstitutiveLaws {
        if {[$cl cumple {*}$args]} { lappend cumplen $cl}
    }
    return $cumplen
}
proc Model::getConstitutiveLaw {clid} { 
    variable ConstitutiveLaws

    foreach cl $ConstitutiveLaws {
        if {[$cl getName] eq $clid} { return $cl}
    }
    return ""
}

proc Model::GetAllCLInputs {} {
    variable ConstitutiveLaws
    
    set inputs [dict create]
    foreach cl $ConstitutiveLaws {
        foreach in [dict keys [$cl getInputs]] {
            dict set inputs $in [$cl getInputPn $in]
        }
    }
    return $inputs
}

proc Model::GetAllCLOutputs {args} {
    set outputs [dict create]
    foreach cl [GetConstitutiveLaws {*}$args] {
        foreach in [dict keys [$cl getOutputs]] {
            dict set outputs $in [$cl getOutputPn $in]
        }
    }
    return $outputs
}

proc Model::CheckConstLawParamState {args} {
    variable ConstitutiveLaws
    
    lassign $args clid inputid
    foreach claw $ConstitutiveLaws {
        if {[$claw getName] eq $clid} {
            return [string compare [$claw getInputPn $inputid] ""]
        }
    }
    return 0
}


proc Model::CheckConstLawOutputState { constlawactive paramName} {
    variable ConstitutiveLaws
    
    set state 0
    foreach cl $ConstitutiveLaws {
       if {[$cl getName] in $constlawactive} {
           if {$paramName in [$cl getOutputs]} {
                set state 1
                break
           }
       }
    }
    return $state
}


proc Model::ForgetConstitutiveLaws { } {
    variable ConstitutiveLaws
    set ConstitutiveLaws [list ]
}

proc Model::ForgetConstitutiveLaw { cl_id } {
    variable ConstitutiveLaws
    set ConstitutiveLaws2 [list ]
    foreach cl $ConstitutiveLaws {
        if {[$cl getName] ne $cl_id} {
            lappend ConstitutiveLaws2 $cl
        }
    }
    set ConstitutiveLaws $ConstitutiveLaws2
}
