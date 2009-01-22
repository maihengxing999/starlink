#pragma once on#include "CoreHeadersMach-O.h"// These symbols are defined from MSL MacHeadersMach-O.h // (errno.h and stat.h are in the Kernel.framework)// and are redefined later in TclErrno.h : undef them// to avoid error message#undef	EOVERFLOW#undef	EOPNOTSUPP// This avoids the loading of stat.h from tclMacPort.h#define	_MSL_STAT_H// ---------------------------------------------------------------// Replace #include "tclMacCommonPch.h" by its partial contents.#if !__option(enumsalwaysint)#error Tcl requires the Metrowerks setting "Enums always ints".#endif// Tell Tcl (or any Tcl extensions) that we are compiling for the Macintosh platform.#define MAC_TCL// ---------------------------------------------------------------#define USE_TCL_STUBS 1// See dom.h for this one:#define USE_NORMAL_ALLOCATOR#define TCL_MEM_DEBUG#define MAC_OSX_TCL#define TDOM_NO_UNKNOWN_CMD#define VERSION "0.8.2"#include <Tcl/tcl.h>
