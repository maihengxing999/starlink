      DOUBLE PRECISION FUNCTION VAL_DIVD( BAD, ARG1, ARG2, STATUS )
*+
*  Name:
*     VAL_DIVD
 
*  Purpose:
*     Perform a DOUBLE PRECISION floating divide operation.
 
*  Language:
*     Starlink Fortran
 
*  Invocation:
*     RESULT = VAL_DIVD( BAD, ARG1, ARG2, STATUS )
 
*  Description:
*     The routine performs an arithmetic floating divide operation between
*     a pair of arguments of type DOUBLE PRECISION.  If a numerical error occurs,
*     the value VAL__BADD is returned and a STATUS value is set.
 
*  Arguments:
*     BAD = LOGICAL (Given)
*        Whether the argument values (ARG1 & ARG2) may be "bad".
*     ARG1, ARG2 = DOUBLE PRECISION (Given)
*        The two DOUBLE PRECISION arguments for the floating divide operation.
*     STATUS = INTEGER (Given & Returned)
*        This should be set to SAI__OK on entry, otherwise the routine
*        returns immediately with the result VAL__BADD.  A STATUS
*        value will be set by this routine if a numerical error occurs.
 
*  Returned Value:
*     VAL_DIVD = DOUBLE PRECISION
*        Returns the result of the floating divide operation as a value of
*        type DOUBLE PRECISION.  The value returned is:
*
*           VAL_DIVD = ARG1 / ARG2
*
*        The value VAL__BADD will be returned under error conditions.
 
*  Copyright:
*     Copyright (C) 1988, 1991 Science & Engineering Research Council.
*     Copyright (C) 1995 Central Laboratory of the Research Councils.
*     All Rights Reserved.

*  Licence:
*     This program is free software; you can redistribute it and/or
*     modify it under the terms of the GNU General Public License as
*     published by the Free Software Foundation; either version 2 of
*     the License, or (at your option) any later version.
*     
*     This program is distributed in the hope that it will be
*     useful,but WITHOUT ANY WARRANTY; without even the implied
*     warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
*     PURPOSE. See the GNU General Public License for more details.
*     
*     You should have received a copy of the GNU General Public License
*     along with this program; if not, write to the Free Software
*     Foundation, Inc., 59 Temple Place,Suite 330, Boston, MA
*     02111-1307, USA

*  Authors:
*     R.F. Warren-Smith (STARLINK)
*     {enter_new_authors_here}
 
*  History:
*     11-AUG-1988 (RFWS):
*        Original version.
*     28-OCT-1991 (RFWS):
*        Added LIB$REVERT call.
*     7-NOV-1991 (RFWS):
*        Changed to use NUM_TRAP.
*     27-SEP-1995 (BKM):
*        Changed LIB$ESTABLISH and LIB$REVERT calls to NUM_HANDL and NUM_REVRT
*     {enter_further_changes_here}
 
*  Bugs:
*     {note_any_bugs_here}
 
*-
 
*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing
 
*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants

      INCLUDE 'PRM_PAR'          ! PRM_ public constants

 
*  Arguments Given:
      LOGICAL BAD                ! The bad data flag
      DOUBLE PRECISION ARG1                ! The first argument
      DOUBLE PRECISION ARG2                ! The second argument
 
*  Status:
      INTEGER STATUS             ! Error status
 
*  External References:
      EXTERNAL NUM_TRAP          ! Error handling routine
 
*  Global Variables:
      INCLUDE 'NUM_CMN'          ! Define NUM_ERROR flag

 
*  Internal References:
      INCLUDE 'NUM_DEC_CVT'      ! Declare NUM_ conversion functions

      INCLUDE 'NUM_DEC_D'      ! Declare NUM_ arithmetic functions

      INCLUDE 'NUM_DEF_CVT'      ! Define NUM_ conversion functions

      INCLUDE 'NUM_DEF_D'      ! Define NUM_ arithmetic functions

 
*.
 
*  Check status.  Return the function result VAL__BADD if not OK.
      IF( STATUS .NE. SAI__OK ) THEN
         VAL_DIVD = VAL__BADD
 
*  If the bad value flag is set, check the arguments given are not bad.
*  Return VAL__BADD if either is.
      ELSE IF( BAD .AND.( ( ARG1 .EQ. VAL__BADD ) .OR.
     :                    ( ARG2 .EQ. VAL__BADD ) ) ) THEN
         VAL_DIVD = VAL__BADD
 
*  Establish the error handler and initialise the common block error
*  flag.
      ELSE
         CALL NUM_HANDL( NUM_TRAP )
         NUM_ERROR = SAI__OK
 
*  Perform the floating divide operation.
         VAL_DIVD = NUM_DIVD( ARG1, ARG2 )
 
*  Check if the numerical error flag is set.  If so, return the result
*  VAL__BADD and set STATUS to NUM_ERROR.
         IF( NUM_ERROR .NE. SAI__OK ) THEN
            VAL_DIVD = VAL__BADD
            STATUS = NUM_ERROR
         ENDIF
 
*  Remove the error handler.
         CALL NUM_REVRT
      ENDIF
 
*  Exit routine.
      END
