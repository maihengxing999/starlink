#include "f77.h"                 /* CNF macros and prototypes               */
void cnfCopyf( const char *source_f, int source_len, char *dest_f,
                int dest_len )

/*
*+
*  Name:
*     cnfCopyf

*  Purpose:
*     Copy one FORTRAN string to another FORTRAN string

*  Language:
*     ANSI C

*  Invocation:
*     cnfCopyf( source_f, source_len, dest_f, dest_len )

*  Description:
*     The FORTRAN string in source_f is copied to dest_f.
*     The destination string is filled with trailing blanks or
*     truncated as nesessary.

*  Arguments:
*     const char  *source_f  (Given)
*        A pointer to the input FORTRAN string
*     int  source_len  (Given)
*        The length of the input FORTRAN string
*     char  *dest_f  (Returned via pointer)
*        A pointer to the output FORTRAN string
*     int  dest_len  (Given)
*        The length of the output FORTRAN string

*  Copyright:
*     Copyright (C) 1991 Science & Engineering Research Council

*  Authors:
*     PMA: Peter Allan (Starlink, RAL)
*     AJC: Alan Chipperfield (Starlink, RAL)
*     {enter_new_authors_here}

*  History:
*     26-MAR-1991 (PMA):
*        Original version.
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


/* Handle the case where the input string is shorter than the output	    */
/* string.								    */

   if( source_len < dest_len )
   {
      for( i = 0 ; i < source_len ; i++ )
         dest_f[i] = source_f[i];
      for(  ; i < dest_len ; i++ )
         dest_f[i] = ' ';
   }

   else

/* Handle the case where the input string is longer than the output string. */

   {
      for( i = 0 ; i < dest_len ; i++ )
         dest_f[i] = source_f[i];
   }
}
