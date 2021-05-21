/* Indicate that we want to use the 8-byte NDF interface */
#define NDF_I8 1

#include "f77.h"
#include "mers.h"
#include "ndf.h"
#include "prm.h"
#include "par.h"
#include "sae_par.h"
#include "star/util.h"
#include "star/lpg.h"
#include <string.h>
#include "star/thr.h"
#include "kaplibs.h"


F77_SUBROUTINE(csub)( INTEGER(STATUS) ){
/*

*+
*  Name:
*     CSUB

*  Purpose:
*     Subtracts a scalar from an NDF data structure.

*  Language:
*     Starlink Fortran 77

*  Type of Module:
*     ADAM A-task

*  Invocation:
*     CALL CSUB( STATUS )

*  Arguments:
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Description:
*     The routine subtracts a scalar (i.e. constant) value from each
*     pixel of an NDF's data array to produce a new NDF data structure.

*  Usage:
*     csub in scalar out

*  ADAM Parameters:
*     IN = NDF (Read)
*        Input NDF data structure, from which the value is to be
*        subtracted.
*     OUT = NDF (Write)
*        Output NDF data structure.
*     SCALAR = _DOUBLE (Read)
*        The value to be subtracted from the NDF's data array.
*     TITLE = LITERAL (Read)
*        Value for the title of the output NDF.  A null value will cause
*        the title of the NDF supplied for parameter IN to be used
*        instead. [!]

*  Examples:
*     csub a 10 b
*        This subtracts ten from the NDF called a, to make the NDF
*        called b.  NDF b inherits its title from a.
*     csub title="HD123456" out=b in=a scalar=21.9
*        This subtracts 21.9 from the NDF called a, to make the NDF
*        called b.  NDF b has the title "HD123456".

*  Related Applications:
*     KAPPA: ADD, CADD, CDIV, CMULT, DIV, MATHS, MULT, SUB.

*  Implementation Status:
*     -  This routine correctly processes the AXIS, DATA, QUALITY,
*     LABEL, TITLE, UNITS, HISTORY, WCS and VARIANCE components of an NDF
*     data structure and propagates all extensions.
*     -  Processing of bad pixels and automatic quality masking are
*     supported.
*     -  All non-complex numeric data types can be handled.
*     -  Huge NDFs are supported.

*  Copyright:
*     Copyright (C) 2021 East Asian Observatory
*     Council.  All Rights Reserved.

*  Licence:
*     This program is free software; you can redistribute it and/or
*     modify it under the terms of the GNU General Public License as
*     published by the Free Software Foundation; either Version 2 of
*     the License, or (at your option) any later version.
*
*     This program is distributed in the hope that it will be
*     useful, but WITHOUT ANY WARRANTY; without even the implied
*     warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
*     PURPOSE. See the GNU General Public License for more details.
*
*     You should have received a copy of the GNU General Public License
*     along with this program; if not, write to the Free Software
*     Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
*     02110-1301, USA.

*  Authors:
*     RFWS: R.F. Warren-Smith (STARLINK)
*     MJC: Malcolm J. Currie (STARLINK)
*     DSB: David S. Berry (STARLINK)
*     TIMJ: Tim Jenness (JAC, Hawaii)
*     {enter_new_authors_here}

*  History:
*     21-MAY-2021 (DSB):
*        Original C version, based on equivalent Fortran function by RFWS
*        et al.
*     {enter_further_changes_here}

*-
*/
   GENPTR_INTEGER(STATUS)

/* Local Variables: */
   ThrWorkForce *wf;     /* Pointer to pool of worker threads */
   char form[ NDF__SZFRM + 1 ];    /* Form of the ARRAY */
   char itype[ NDF__SZTYP + 1 ];   /* Data type for processing */
   double cons;          /* Constant to be subtracted */
   int bad;              /* Need to check for bad pixels? */
   int ndf1;             /* Identifier for 1st NDF (input) */
   int ndf2;             /* Identifier for 2nd NDF (input) */
   size_t el;            /* Number of mapped elements */
   size_t nerr;          /* Number of numerical errors */
   void *pntr1;          /* Pointer to 1st NDF mapped array */
   void *pntr2;          /* Pointer to 2nd NDF mapped array */

/* Check inherited global status. */
   if( *STATUS != SAI__OK ) return;

/* Begin an NDF context. */
   ndfBegin();

/* Obtain an identifier for the input NDF. */
   lpgAssoc( "IN", "READ", &ndf1, STATUS );

/* Obtain the scalar value to be subtracted. */
   parGet0d( "SCALAR", &cons, STATUS );

/* Create a new output NDF based on the input NDF. Propagate the WCS, axis,
   quality, units and variance components. */
   lpgProp( ndf1, "WCS,Axis,Quality,Units,Variance", "OUT", &ndf2, STATUS );

/* Determine which data type to use to process the input data array. */
   ndfType( ndf1, "Data", itype, sizeof(itype), STATUS );

/* Map the input and output data arrays. */
   ndfMap( ndf1, "Data", itype, "READ", &pntr1, &el, STATUS );
   ndfMap( ndf2, "Data", itype, "WRITE", &pntr2, &el, STATUS );

/* See if checks for bad pixels are needed. */
   ndfBad( ndf1, "Data", 0, &bad, STATUS );

/* Find the number of cores/processors available and create a pool of
   threads of the same size. */
   wf = thrGetWorkforce( thrGetNThread( "KAPPA_THREADS", STATUS ), STATUS );

/* Select the appropriate function for the data type being processed and
   do the arithmetic. */
   if( !strcmp( itype, "_BYTE" ) ) {
      kpgCsubB( wf, bad, el, pntr1, cons, pntr2, &(nerr), STATUS );

   } else if( !strcmp( itype, "_UBYTE" ) ) {
      kpgCsubUB( wf, bad, el, pntr1, cons, pntr2, &(nerr), STATUS );

   } else if( !strcmp( itype, "_DOUBLE" ) ) {
      kpgCsubD( wf, bad, el, pntr1, cons, pntr2, &(nerr), STATUS );

   } else if( !strcmp( itype, "_INTEGER" ) ) {
      kpgCsubI( wf, bad, el, pntr1, cons, pntr2, &(nerr), STATUS );

   } else if( !strcmp( itype, "_INT64" ) ) {
      kpgCsubK( wf, bad, el, pntr1, cons, pntr2, &(nerr), STATUS );

   } else if( !strcmp( itype, "_REAL" ) ) {
      kpgCsubF( wf, bad, el, pntr1, cons, pntr2, &(nerr), STATUS );

   } else if( !strcmp( itype, "_WORD" ) ) {
      kpgCsubW( wf, bad, el, pntr1, cons, pntr2, &(nerr), STATUS );

   } else if( !strcmp( itype, "_UWORD" ) ) {
      kpgCsubUW( wf, bad, el, pntr1, cons, pntr2, &(nerr), STATUS );

   } else if( *STATUS == SAI__OK ){
      *STATUS = SAI__ERROR;
      errRepf( " ", "Unsupported data type'%s'.", STATUS, itype );
   }

/* See if there may be bad pixels in the output data array and set the
   output bad pixel flag value accordingly unless the output NDF is
   primitive. */
   if( nerr > 0 ) bad = 1;
   ndfForm( ndf2, "Data", form, sizeof(form), STATUS );
   if( strcmp( form, "PRIMITIVE" ) ) ndfSbad( bad, ndf2, "Data", STATUS );

/* Unmap the data arrays. */
   ndfUnmap( ndf1, "Data", STATUS );
   ndfUnmap( ndf2, "Data", STATUS );

/* Obtain a new title for the output NDF. */
   ndfCinp( "TITLE", ndf2, "Title", STATUS );

/* End the NDF context. */
   ndfEnd( STATUS );

/* If an error occurred, then report context information. */
   if( *STATUS != SAI__OK ) errRep( " ", "CSUB: Error subtracting a scalar "
                                    "value from an NDF data structure.",
                                    STATUS );
}

