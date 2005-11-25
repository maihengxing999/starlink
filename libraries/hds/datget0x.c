#if HAVE_CONFIG_H
#  include <config.h>
#endif

#include <string.h>

#include "hds1.h"
#include "rec.h"
#include "dat1.h"
#include "hds_types.h"
#include "dat_err.h"
#include "hds.h"

#include "f77.h"       /* For CNF string "import" routine */

/*
 *+
 *  Name:
 *    datGet0X

 *  Purpose:
 *    Get a scalar value from an HDS component

 *  Invocation:
 *    status = datGut0X( HDSLoc * loc, <type> value, int * status );

 *  Description:
 *     This routine reads a value from a scalar primitive object.
 *     There is a routine for each access type,
 *
 *        datGet0D    DOUBLE PRECISION
 *        datGet0R    REAL / FLOAT
 *        datGet0I    INTEGER
 *        datGet0L    LOGICAL
 *        datGet0C    CHARACTER[*n]
 *
 *     If the object data type differs from the access type, then
 *     conversion is performed.
 *
 *     Note that a Vector (1-D) object containing a single value is
 *     different from a Scalar (0-D).

 *  Arguments
 *    HDSLoc * loc = Given
 *       HDS locator associated with a primitive data object.
 *    <type> *value = Returned
 *       Pointer to variable to receive the value. For string
 *       data types the buffer must be preallocated by the caller
 *       and the size of the buffer provided as a 3rd argument. The
 *       string will be nul-terminated on return.
 *    int * status = Given & Returned
 *       Global inherited status.

 *  Authors:
 *    Jack Giddings (UCL::JRG)
 *    Sid Wright (UCL::SLW)
 *    Dennis Kelly (REVAD::BDK)
 *    Alan Chipperfield (RAL::AJC)
 *    Tim Jenness (JAC, Hawaii)

 *  History:
 *     3-JAN-1983 (UCL::JRG):
 *       Original.
 *     31-AUG-1983 (UCL::SLW):
 *       Standardise.
 *     05-NOV-1984: (REVAD::BDK)
 *       Remove calls to error system
 *     15-APR-1987 (RAL::AJC):
 *       Improved prologue layout
 *     21-NOV-2005 (TIMJ):
 *       Rewrite in C
 *     25-NOV-2005 (TIMJ):
 *       NUL terminate

 *  Notes:
 *    For datGet0C the buffer must be preallocated by the caller
 *    and the size provided as a 3rd argument. The specified string
 *    size must allow for the terminating nul.

 *  Copyright:
 *    Copyright (C) 2005 Particle Physics and Astronomy Research Council.
 *    All Rights Reserved.

 *  Licence:
 *     This program is free software; you can redistribute it and/or
 *     modify it under the terms of the GNU General Public License as
 *     published by the Free Software Foundation; either version 2 of
 *     the License, or (at your option) any later version.
 *
 *     This program is distributed in the hope that it will be
 *     useful, but WITHOUT ANY WARRANTY; without even the implied
 *     warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
 *     PURPOSE. See the GNU General Public License for more details.
 *
 *     You should have received a copy of the GNU General Public
 *     License along with this program; if not, write to the Free
 *     Software Foundation, Inc., 59 Temple Place, Suite 330, Boston,
 *     MA 02111-1307, USA

 *  Bugs:
 *     {note_any_bugs_here}

 *-
 */

int datGet0C ( HDSLoc * loc, char * value, size_t str_len, int * status ) {

  int ndims = 0;
  hdsdim dim[] = { 0 };

  if ( *status != DAT__OK ) return *status;

  /* Obtain the unterminated string but pass in a size one less than
     the allocated size to allow us to terminate */
  value[0] = '\0';
  datGetC( loc, ndims, dim, value, str_len-1, status );

  /* Terminate the string but first make sure we fool CNF by forcing
     a ' ' as the last character in the "fortran" string */
  value[str_len-1] = ' ';
  cnfImprt( value, str_len, value );
  return *status;
}

int datGet0D ( HDSLoc * loc, double * value, int * status ) {

  int ndims = 0;
  hdsdim dim[] = { 0 };

  if ( *status != DAT__OK ) return *status;

  datGetD( loc, ndims, dim, value, status );
  return *status;
}

int datGet0R ( HDSLoc * loc, float * value, int * status ) {

  int ndims = 0;
  hdsdim dim[] = { 0 };

  if ( *status != DAT__OK ) return *status;

  datGetR( loc, ndims, dim, value, status );
  return *status;
}

int datGet0I ( HDSLoc * loc, int * value, int * status ) {

  int ndims = 0;
  hdsdim dim[] = { 0 };

  if ( *status != DAT__OK ) return *status;

  datGetI( loc, ndims, dim, value, status );

  return *status;
}

int datGet0L ( HDSLoc * loc, int * value, int * status ) {

  int ndims = 0;
  hdsdim dim[] = { 0 };

  if ( *status != DAT__OK ) return *status;

  datGetL( loc, ndims, dim, value, status );
  return *status;
}
