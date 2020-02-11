##################################################################################
#   This file is common for all Kratos Applications.
#   Do not change anything here unless it's strictly necessary.
##################################################################################

namespace eval Model {
# Clase Topology features
catch {Topology destroy}
oo::class create Topology {
    variable geometryType
    variable numNodes
    variable kratosName
    variable attributes
    
    constructor {geo nod kname} {
        variable numNodes
        variable kratosName
        
        my setGeometryType $geo
        set numNodes $nod
        set kratosName $kname
        
        variable attributes
        set attributes [dict create]
    }
    
    method setGeometryType {geo} {
        variable geometryType
        
        set accepted [list "Point" "Line" "Circle" "Triangle" "Quadrilateral" "Tetrahedra" "Hexahedra" "Prism" "Sphere"]
        if {$geo in $accepted} {
            set geometryType $geo
        } {
            W "Topology Features Error -> Geometry type $geo not accepted.
            Only - $accepted - are accepted
            check XML files on your app"
        }
    }
    
    method getGeometry { } {
        variable geometryType
        return $geometryType
    }
    method getNodes { } {
        variable numNodes
        return $numNodes
    }
    method getKratosName { } {
        variable kratosName
        return $kratosName
    }

    method setAttribute {att val} {variable attributes; dict set attributes $att $val}
    method hasAttribute {att} {
        variable attributes
        return [dict exists $attributes $att]
    }
    method getAttribute {att} {
        variable attributes
        set v ""
        if {[dict exists $attributes $att]} {
            set v [dict get $attributes $att]
        }
        return $v
    }
    method addAttribute {key values} {variable attributes; dict set attributes $key $values}
    method getAttributes {} {variable attributes; return $attributes}
    
}

}

# parent object must be from a "Topology" implemented interface
# it means that class or parent class must implement "addTopologyFeature topobj" function
proc Model::ParseTopologyNode {parentObject topNode} {
    set geo [$topNode @GeometryType]
    set nod [$topNode @nodes]
    set krn [$topNode @KratosName]
    
    set topObj [::Model::Topology new $geo $nod $krn]

    set avoid [list GeometryType nodes KratosName]
    foreach att [$topNode attributes] {
        if {$att ni $avoid} {
            $topObj setAttribute $att [$topNode @$att]
        }
    }
        
    $parentObject addTopologyFeature $topObj
    
    return $parentObject
}
