      SUBROUTINE TEST_PORT(STATUS)
*+
*  Name:
*     TEST_PORT

*  Purpose:
*     Test the portability routines.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL TEST_PORT(STATUS)

*  Description:
*     Test each of the portability routines listed in Appendix A.1 of 
*     SUN/40.3.
*     If any failure occurs, return STATUS = SAI__ERROR.
*     Otherwise, STATUS is unchanged.

*  Arguments:
*     STATUS = INTEGER (Returned)
*        The status of the tests. 

*  Authors:
*     RLVAD::ACC: A C Charles (STARLINK)
*     {enter_new_authors_here}

*  History:
*     28-Feb-1994 (ACC)
*        Original version.
*     02-MAR-1994 (ACC)
*        Broke into separate routines for each routine tested.
*     {enter_further_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*  Subprograms called:   
*     TEST_ACHR, TEST_ATOK, TEST_IACHR, TEST_MTOE, TEST_ETOM

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
      PRINT *,'*** Test portability routines ***'

      STATUS = SAI__OK

*  Test CHR_ACHR
 
      ISTAT = SAI__OK
      CALL TEST_ACHR(ISTAT)
      IF (ISTAT .NE. SAI__OK) THEN
         STATUS = SAI__ERROR
      END IF
 
*  Test CHR_ATOK
 
      ISTAT = SAI__OK
      CALL TEST_ATOK(ISTAT)
      IF (ISTAT .NE. SAI__OK) THEN
         STATUS = SAI__ERROR
      END IF
 
*  Test CHR_ETOM
 
      ISTAT = SAI__OK
      CALL TEST_ETOM(ISTAT)
      IF (ISTAT .NE. SAI__OK) THEN
         STATUS = SAI__ERROR
      END IF
 
*  Test CHR_IACHR
 
      ISTAT = SAI__OK
      CALL TEST_IACHR(ISTAT)
      IF (ISTAT .NE. SAI__OK) THEN
         STATUS = SAI__ERROR
      END IF
 
*  Test CHR_MTOE
 
      ISTAT = SAI__OK
      CALL TEST_MTOE(ISTAT)
      IF (ISTAT .NE. SAI__OK) THEN
         STATUS = SAI__ERROR
      END IF
 
*    Write summary message

      IF (STATUS .EQ. SAI__OK) THEN 
         PRINT *,'*** All portability routines OK ***'
      ELSE
         PRINT *,'*** Error(s) in portability routines ***'
      END IF

      END
