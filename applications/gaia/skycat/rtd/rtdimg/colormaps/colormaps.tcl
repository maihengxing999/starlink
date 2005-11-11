#!../bin/rtdimage_wish
#
# E.S.O. - VLT project
#
# "@(#) $Id: colormaps.tcl,v 1.2 2005/02/02 01:43:03 brighton Exp $"
#
# script to generate C code including static colormaps, so that the ,
# (binary) application doesn't have to be delivered with the colormap files.
#
# who             when       what
# --------------  ---------  ----------------------------------------
# Allan Brighton  19 Nov 97  Created
# pbiereic        31/01/05   Fixed: too many open files

puts {
/*
 * E.S.O. - VLT project 
 * "@(#) $Id: colormaps.tcl,v 1.2 2005/02/02 01:43:03 brighton Exp $"
 *
 * Colormap definitions for RTD
 *
 * This file was generated by ../colormaps/colormaps.tcl  - DO NO EDIT
 */

#include <ColorMapInfo.h>
#include <ITTInfo.h>

}

puts "void defineColormaps() {"

# colormaps
foreach file [glob *.lasc] {
    set fd [open $file]
    set name [file tail $file]
    set root [file rootname $name]
    set ar ${root}_lasc
    puts "\tstatic RGBColor $ar\[\] = {"
    while {[gets $fd line] != -1} {
	puts "\t\t{[join $line {, }]},"
    }
    puts "\t};"
    puts "\tnew ColorMapInfo(\"$name\", $ar);\n"
    close $fd
}

# itts
foreach file [glob *.iasc] {
    set fd [open $file]
    set name [file tail $file]
    set root [file rootname $name]
    set ar ${root}_iasc
    puts "\tstatic double $ar\[\] = {"
    while {[gets $fd line] != -1} {
	puts "\t\t[lindex $line 0],"
    }
    puts "\t};"
    puts "\tnew ITTInfo(\"$name\", $ar);\n"
    close $fd
}

puts "}"
exit 0
