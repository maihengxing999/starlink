      SUBROUTINE VEC_DIVW( BAD, N, ARGV1, ARGV2, RESV, IERR, NERR,
     :                          STATUS )
*+
*  Name:
*     VEC_DIVW
 
*  Purpose:
*     Vectorised WORD floating divide operation.
 
*  Language:
*     Starlink Fortran
 
*  Invocation:
*     CALL VEC_DIVW( BAD, N, ARGV1, ARGV2, RESV, IERR, NERR,
*                         STATUS )
 
*  Description:
*     The routine performs an arithmetic floating divide operation between
*     two vectorised arrays ARGV1 and ARGV2 of WORD values.  If
*     numerical errors occur, the value VAL__BADW is returned in
*     appropriate elements of the result array RESV and a STATUS value
*     is set.
 
*  Arguments:
*     BAD = LOGICAL (Given)
*        Whether the argument values (ARGV1 & ARGV2) may be "bad".
*     N = INTEGER (Given)
*        The number of argument pairs to be processed.  If N is not
*        positive the routine returns with IERR and NERR set to zero,
*        but without processing any values.
*     ARGV1( N ), ARGV2( N ) = INTEGER*2 (Given)
*        Two vectorised (1-dimensional) arrays containing the N pairs
*        of WORD argument values for the floating divide operation.
*     RESV( N ) = INTEGER*2 (Returned)
*        A vectorised (1-dimensional) array with at least N elements to
*        receive the results.  Each element I of RESV receives the
*        WORD value:
*
*           RESV( I ) = ARGV1( I ) / ARGV2( I )
*
*        for I = 1 to N.  The value VAL__BADW will be set in
*        appropriate elements of RESV under error conditions.
*     IERR = INTEGER (Returned)
*        The index of the first input array element to generate a
*        numerical error.  Zero is returned if no errors occur.
*     NERR = INTEGER (Returned)
*        A count of the number of numerical errors which occur.
*     STATUS = INTEGER (Given & Returned)
*        This should be set to SAI__OK on entry, otherwise the routine
*        returns without action.  A STATUS value will be set by this
*        routine if any numerical errors occur.
 
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
*     15-AUG-1988 (RFWS):
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
      LOGICAL BAD                ! Bad data flag
      INTEGER N                  ! Number of elements to process
      INTEGER*2 ARGV1( * )          ! First argument array
      INTEGER*2 ARGV2( * )          ! Second argument array
 
*  Arguments Returned:
      INTEGER*2 RESV( * )           ! Result array
      INTEGER IERR               ! Numerical error pointer
      INTEGER NERR               ! Numerical error count
 
*  Status:
      INTEGER STATUS             ! Error status
 
*  External References:
      EXTERNAL NUM_TRAP          ! Error handling routine
 
*  Global Variables:
      INCLUDE 'NUM_CMN'          ! Define NUM_ERROR flag

 
*  Local Variables:
      INTEGER I                  ! Loop counter
 
*  Internal References:
      INCLUDE 'NUM_DEC_CVT'      ! Declare NUM_ conversion functions

      INCLUDE 'NUM_DEC_W'      ! Declare NUM_ arithmetic functions

      INCLUDE 'NUM_DEF_CVT'      ! Define NUM_ conversion functions

      INCLUDE 'NUM_DEF_W'      ! Define NUM_ arithmetic functions

 
*.
 
*  Check status.
      IF( STATUS .NE. SAI__OK ) RETURN
 
*  Establish the numerical error handler and initialise the common
*  block error flag.
      CALL NUM_HANDL( NUM_TRAP )
      NUM_ERROR = SAI__OK
 
*  Initialise the numerical error pointer and the error count.
      IERR = 0
      NERR = 0
 
*  If the bad data flag is set:
*  ---------------------------
*  Loop to process each pair of elements from the input argument arrays
*  in turn.
      IF( BAD ) THEN
         DO 1 I = 1, N
 
*  Check if the argument values are bad.  If either is, then put a
*  value of VAL__BADW in the corresponding element of the result
*  array.
            IF( ARGV1( I ) .EQ. VAL__BADW .OR.
     :          ARGV2( I ) .EQ. VAL__BADW ) THEN
               RESV( I ) = VAL__BADW
 
*  If the argument values are not bad, perform the floating divide
*  operation.
            ELSE
               RESV( I ) = NUM_DIVW( ARGV1( I ), ARGV2( I ) )
 
*  Check if the numerical error flag is set.  If so, put a value of
*  VAL__BADW in the corresponding element of the result array and
*  increment the error count.
               IF( NUM_ERROR .NE. SAI__OK ) THEN
                  RESV( I ) = VAL__BADW
                  NERR = NERR + 1
 
*  Set a STATUS value (if not already set) and update the error
*  pointer.
                  IF( STATUS .EQ. SAI__OK ) THEN
                     STATUS = NUM_ERROR
                     IERR = I
                  ENDIF
 
*  Clear the error flag.
                  NUM_ERROR = SAI__OK
               ENDIF
            ENDIF
 1       CONTINUE
 
*  If the bad data flag is not set:
*  -------------------------------
*  Loop to process each pair of elements from the input argument arrays
*  in turn.
      ELSE
         DO 2 I = 1, N
 
*  Perform the floating divide operation.
            RESV( I ) = NUM_DIVW( ARGV1( I ), ARGV2( I ) )
 
*  Check if the numerical error flag is set.  If so, put a value of
*  VAL__BADW in the corresponding element of the result array and
*  increment the error count.
            IF( NUM_ERROR .NE. SAI__OK ) THEN
               RESV( I ) = VAL__BADW
               NERR = NERR + 1
 
*  Set a STATUS value (if not already set) and update the error
*  pointer.
               IF( STATUS .EQ. SAI__OK ) THEN
                  STATUS = NUM_ERROR
                  IERR = I
               ENDIF
 
*  Clear the error flag.
               NUM_ERROR = SAI__OK
            ENDIF
 2       CONTINUE
      ENDIF
 
*  Remove the error handler.
      CALL NUM_REVRT
 
*  Exit routine.
      END
