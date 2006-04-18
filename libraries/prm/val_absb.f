      BYTE FUNCTION VAL_ABSB( BAD, ARG, STATUS )
*+
*  Name:
*     VAL_ABSB
 
*  Purpose:
*     Evaluate the BYTE Fortran ABS function.
 
*  Language:
*     Starlink Fortran
 
*  Invocation:
*     RESULT = VAL_ABSB( BAD, ARG, STATUS )
 
*  Description:
*     The routine evaluates the Fortran ABS function for a single
*     argument of type BYTE.  If a numerical error occurs, the value
*     VAL__BADB is returned and a STATUS value is set.
 
*  Arguments:
*     BAD = LOGICAL (Given)
*        Whether the argument value (ARG) may be "bad".
*     ARG = BYTE (Given)
*        The BYTE argument of the Fortran ABS function.
*     STATUS = INTEGER (Given & Returned)
*        This should be set to SAI__OK on entry, otherwise the routine
*        returns immediately with the result VAL__BADB.  A STATUS
*        value will be set by this routine if a numerical error occurs.
 
*  Returned Value:
*     VAL_ABSB = BYTE
*        Returns the evaluated Fortran ABS function result as a BYTE
*        value.  The value VAL__BADB will be returned under error
*        conditions.
 
*  Copyright:
*     Copyright (C) 1987, 1991 Science & Engineering Research Council.
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
*     15-AUG-1987 (RFWS):
*        Original version.
*     28-OCT-1991 (RFWS):
*        Added LIB$REVERT call.
*     7-NOV-1991 (RFWS):
*        Changed to use NUM_TRAP.
*     27-SEP-1995 (BKM):
*        Changed LIB$ESTABLISH and LIB$REVERT calls to NUM_HANDL and NUM_REVRT
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

      INCLUDE 'PRM_CONST'        ! PRM_ private constants

      INCLUDE 'PRM_ERR'          ! PRM_ error codes

 
*  Arguments Given:
      LOGICAL BAD                ! Bad data flag
      BYTE ARG                 ! Function argument
 
*  Status:
      INTEGER STATUS             ! Error status
 
*  External References:
      EXTERNAL NUM_TRAP          ! Error handling routine
 
*  Global Variables:
      INCLUDE 'NUM_CMN'          ! Define NUM_ERROR flag

 
*  Internal References:
      INCLUDE 'NUM_DEC_CVT'      ! Declare NUM_ conversion functions

      INCLUDE 'NUM_DEC_B'      ! Declare NUM_ arithmetic functions

      INCLUDE 'NUM_DEF_CVT'      ! Define NUM_ conversion functions

      INCLUDE 'NUM_DEF_B'      ! Define NUM_ arithmetic functions

 
*.
 
*  Check status.  Return the function result VAL__BADB if not OK.
      IF( STATUS .NE. SAI__OK ) THEN
         VAL_ABSB = VAL__BADB
 
*  If the bad data flag is set, check if the argument given is bad.
*  Return VAL__BADB if it is.
      ELSE IF( BAD .AND. ( ARG .EQ. VAL__BADB ) ) THEN
         VAL_ABSB = VAL__BADB
 
*  Check if the argument value is acceptable.  If not, return the
*  result VAL__BADB and set a STATUS value.
      ELSE IF( .NOT. ( BAD .OR. NUM_NEB( ARG, NUM__MINB ) ) ) THEN
         VAL_ABSB = VAL__BADB
         STATUS = PRM__INTOF
 
*  If the argument value is acceptable then, if required, establish the
*  numerical error handler and initialise the common block error
*  status.
      ELSE
         IF( .FALSE. ) THEN
            CALL NUM_HANDL( NUM_TRAP )
            NUM_ERROR = SAI__OK
         ENDIF
 
*  Evaluate the function.
         VAL_ABSB = NUM_ABSB( ARG )
 
*  If an error handler is established, check if the numerical error
*  flag is set.  If so, return the result VAL__BADB and set STATUS to
*  NUM_ERROR.
         IF( .FALSE. ) THEN
            IF( NUM_ERROR .NE. SAI__OK ) THEN
               VAL_ABSB = VAL__BADB
               STATUS = NUM_ERROR
            ENDIF
 
*  Remove the error handler.
            CALL NUM_REVRT
         ENDIF
      ENDIF
 
*  Exit routine.
      END
