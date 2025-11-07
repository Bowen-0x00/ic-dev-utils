if { [info exists env(TOP)] && $env(TOP) ne "" } {
    set top_name "$env(TOP)"
} else {
    set top_name "tb"
}
if { [info exists env(fsdb_file)] && $env(fsdb_file) ne "" } {
    fsdbDumpfile "$env(fsdb_file).fsdb"
    fsdbDumpvars 0 "$(top_name)" "+all" "+trace_process"
}
run
exit

