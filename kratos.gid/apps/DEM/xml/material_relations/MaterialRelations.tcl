##################################################################################
#   This file is common for all Kratos Applications.
#   Do not change anything here unless it's strictly necessary.
##################################################################################

namespace eval Model {
catch {MaterialRelation destroy}
oo::class create MaterialRelation {
    superclass Entity
    
    variable Materials
    
    constructor {n} {
        next $n
        variable Materials
        
        set Materials [list ]
    }
    method setMaterials { ms } {variable Materials; set Materials $ms}
    method getMaterials { } {variable Materials; return $Materials}
    method addMaterial {mat} {variable Materials; lappend Materials $mat}
    method getMaterial {i} {variable Materials; return [lindex $Materials $i]}
}
    variable MaterialRelations
    set MaterialRelations [list ]
}


proc Model::ParseMaterialRelations { doc } {
    variable MaterialRelations
    
    set MatNodeList [$doc getElementsByTagName MaterialRelation]
    foreach MatNode $MatNodeList {
        set mat_rel [ParseMatRelNode $MatNode]
        set ma [Model::getMaterialRelation [$mat_rel getName] ]
        if {$ma eq ""} {
            lappend MaterialRelations $mat_rel
        } else {
            foreach input [dict values [$mat_rel getInputs]] {
                $ma addInputDone $input
            }
        }
    }
}

proc Model::ParseMatRelNode { node } {
    set name [$node getAttribute n]
    
    set mat [::Model::MaterialRelation new $name]
    $mat setPublicName [$node getAttribute n]
    $mat setHelp [$node getAttribute help]
    
    foreach att [$node attributes] {
        $mat setAttribute $att [split [$node getAttribute $att] ","]
    }
    foreach in [[$node getElementsByTagName inputs] getElementsByTagName parameter]  {
        set mat [ParseInputParamNode $mat $in]
    }
    
    return $mat
}

proc Model::getMaterialRelations { MaterialRelationsFileName } {
    variable dir
    dom parse [tDOM::xmlReadFile [file join $dir xml $MaterialRelationsFileName]] doc
    ParseMaterialRelations $doc
}

proc Model::GetMaterialRelations {args} { 
    variable MaterialRelations
    # W "Get materials $args"
    set cumplen [list ]
    foreach mat_rel $MaterialRelations {
        # W [$mat getName]
        if {[$mat_rel cumple {*}$args]} { lappend cumplen $mat_rel}
    }
    # W "Good materials $cumplen"
    return $cumplen
}
proc Model::GetMaterialRelationNames {args} { 
    set material_relations [list ]
    foreach mat [GetMaterialRelations {*}$args] {
        lappend material_relations [$mat getName]
    }
    return $material_relations
}

proc Model::getMaterialRelation {mid} { 

    foreach mat_rel [GetMaterialRelations] {
        if {[$mat_rel getName] eq $mid} { return $mat_rel}
    }
    return ""
}


proc Model::ForgetMaterialRelations { } {
    variable MaterialRelations
    set MaterialRelations [list ]
}

proc Model::ForgetMaterialRelation { mid } {
    variable MaterialRelations
    set MaterialRelations2 [list ]
    foreach material_relation $MaterialRelations {
        if {[$material_relation getName] ne $mid} {
            lappend MaterialRelations2 $material_relation
        }
    }
    set MaterialRelations $MaterialRelations2
}