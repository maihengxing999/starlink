      SUBROUTINE TEST_LEN(STATUS)
*+
*  Name:
*     TEST_LEN

*  Purpose:
*     Test CHR_LEN.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL TEST_LEN(STATUS)

*  Description:
*     Test CHR_LEN.
*     If any failure occurs, return STATUS = SAI__ERROR.
*     Otherwise, STATUS is unchanged.

*  Arguments:
*     STATUS = INTEGER (Returned)
*        The status of the tests. 

*  Authors:
*     RLVAD::AJC: A J Chipperfield (STARLINK)
*     RLVAD::ACC: A C Charles (STARLINK)
*     {enter_new_authors_here}

*  History:
*     17-AUG-1989 (RLVAD::AJC):
*        Original version.
*     14-SEP-1993 (ACC)
*        Modularised version: broken into one routine for each of 5 main 
*        categories of tests.
*     02-MAR-1994 (ACC)
*        Second modularised version: broken further into one routine for 
*        each of subroutine tested.  This subroutine created.
*     {enter_further_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*  Subprograms called:    
*     CHR_LEN

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

*  External References:
      INTEGER CHR_LEN

*  Local Variables:
      INTEGER ISTAT              ! Local status
      INTEGER I                  ! INTEGER value
      CHARACTER*120 STRING

*.

*    Test CHR_LEN

      ISTAT = SAI__OK
      STRING = '12345  '
      I = CHR_LEN(STRING)
      IF (I .NE. 5) THEN
         PRINT *, 'CHR_LEN failure, I should be 5, is ',I
	 ISTAT = SAI__ERROR
      ENDIF

      STRING = '  1234  '
      I = CHR_LEN(STRING)
      IF (I .NE. 6) THEN
         PRINT *, 'CHR_LEN failure, I should be 6, is ',I
	 ISTAT = SAI__ERROR
      ENDIF
      STRING = '1234  5'
      I = CHR_LEN(STRING)
      IF (I .NE. 7) THEN
         PRINT *, 'CHR_LEN failure, I should be 7, is ',I
	 ISTAT = SAI__ERROR
      ENDIF

      STRING = '  12  34  '
      I = CHR_LEN(STRING)
      IF (I .NE. 8) THEN
         PRINT *, 'CHR_LEN failure, I should be 8, is ',I
	 ISTAT = SAI__ERROR
      ENDIF
      IF (ISTAT .EQ. SAI__OK) THEN
         PRINT *, 'CHR_LEN OK'
      ELSE
         STATUS = ISTAT
      ENDIF

      END
