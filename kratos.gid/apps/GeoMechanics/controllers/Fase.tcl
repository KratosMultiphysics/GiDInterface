catch {Phase destroy}
oo::class create Phase {
    variable name

    constructor {n} {
        variable name

        set name $n
    }

    method setAttribute {att val} {}
    
}