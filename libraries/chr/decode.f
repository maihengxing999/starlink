      SUBROUTINE TEST_DECODE(STATUS)
*+
*  Name:
*     TEST_DECODE

*  Purpose:
*     Test the decoding routines.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL TEST_DECODE(STATUS)

*  Description:
*     Test each of the decoding routines listed in Appendix A.1 of SUN/40.3.
*     If any failure occurs, return STATUS = SAI__ERROR.
*     Otherwise, STATUS is unchanged.

*  Arguments:
*     STATUS = INTEGER (Returned)
*        The status of the tests. 

*  Authors:
*     RLVAD::ACC: A C Charles (STARLINK)
*     {enter_new_authors_here}

*  History:
*     14-SEP-1993 (ACC)
*        Original version.
*     01-MAR-1994 (ACC)
*        Broke into separate routines for each routine tested.
*     {enter_further_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*  Subprograms called:   
*     TEST_BTOI, TEST_CTOC, TEST_CTOD, TEST_CTOI, TEST_CTOL, 
*     TEST_CTOR, TEST_HTOI, TEST_OTOI

*-

*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Arguments Given:
*     None

*  Arguments Returned:
      INTEGER STATUS

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'CHR_ERR'

*  Local Variables:
      INTEGER ISTAT              ! Local status

*.

      PRINT *,' '
      PRINT *,'*** Test decoding routines ***'

      STATUS = SAI__OK

*    Test CHR_BTOI

      ISTAT = SAI__OK
      CALL TEST_BTOI(ISTAT)
      IF (ISTAT .NE. SAI__OK) THEN
         STATUS = SAI__ERROR
      END IF

*    Test CHR_CTOC
 
      ISTAT = SAI__OK
      CALL TEST_CTOC(ISTAT)
      IF (ISTAT .NE. SAI__OK) THEN
         STATUS = SAI__ERROR
      END IF
 
*    Test CHR_CTOD

      ISTAT = SAI__OK
      CALL TEST_CTOD(ISTAT)
      IF (ISTAT .NE. SAI__OK) THEN
         STATUS = SAI__ERROR
      END IF

*    Test CHR_CTOI

      ISTAT = SAI__OK
      CALL TEST_CTOI(ISTAT)
      IF (ISTAT .NE. SAI__OK) THEN
         STATUS = SAI__ERROR
      END IF

*    Test CHR_CTOL

      ISTAT = SAI__OK
      CALL TEST_CTOL(ISTAT)
      IF (ISTAT .NE. SAI__OK) THEN
         STATUS = SAI__ERROR
      END IF

*    Test CHR_CTOR

      ISTAT = SAI__OK
      CALL TEST_CTOR(ISTAT)
      IF (ISTAT .NE. SAI__OK) THEN
         STATUS = SAI__ERROR
      END IF

*    Test CHR_HTOI

      ISTAT = SAI__OK
      CALL TEST_HTOI(ISTAT)
      IF (ISTAT .NE. SAI__OK) THEN
         STATUS = SAI__ERROR
      END IF

*    Test CHR_OTOI

      ISTAT = SAI__OK
      CALL TEST_OTOI(ISTAT)
      IF (ISTAT .NE. SAI__OK) THEN
         STATUS = SAI__ERROR
      END IF

*    Write summary message

      IF (STATUS .EQ. SAI__OK) THEN 
         PRINT *,'*** All decode routines OK ***'
      ELSE
         PRINT *,'*** Error(s) in decode routines ***'
      END IF

      END
