#include <string.h>
#include "f77.h"                 /* CNF macros and prototypes               */

void cnfImpch( const char *source_f, int nchars, char *dest_c )

/*
*+
*  Name:
*     cnfImpch

*  Purpose:
*     Import a FORTRAN string into a C array of char.

*  Language:
*     ANSI C

*  Invocation:
*     cnfImpch( source_f, nchars, dest_c )

*  Description:
*     Import a FORTRAN string into a C array of char, copying `nchars'
*     characters.
*     No characters, are special so this may be used to import an HDS locator
*     which could contain any character.

*  Arguments:
*     const char *source_f (Given)
*        A pointer to the input FORTRAN string
*     int nchars (Given)
*        The number of characters to be copied from source_f to
*        dest_c
*     char *dest_c (Returned via pointer)
*        A pointer to the C array of char.

*  Notes:
*     No check is made that there is sufficient space allocated to
*     the C array to hold the FORTRAN string.
*     It is the responsibility of the programmer to check this.
 
*  Copyright:
*     Copyright (C) 1996 Council for the Central Laboratory of the Research
*     Councils

*  Authors:
*     AJC: A.J. Chipperfield (Starlink, RAL)
*     {enter_new_authors_here}

*  History:
*     28-JUN-1996 (AJC):
*        Original version.
*     16-Aug-1996 (AJC):
*        Correct include file
*     24-SEP-1998 (AJC):
*        Specify const char * for input strings
*     {enter_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-

*...........................................................................*/

{
/* Local Variables:							    */

   int i;			 /* Loop counter			    */


/* Copy the characters of the input C array to the output FORTRAN string.  */

   bcopy( (const void *)source_f, (void *)dest_c, (size_t)nchars );

}
