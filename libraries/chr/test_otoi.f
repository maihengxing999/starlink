      SUBROUTINE TEST_OTOI(STATUS)
*+
*  Name:
*     TEST_OTOI

*  Purpose:
*     Test CHR_OTOI.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL TEST_OTOI(STATUS)

*  Description:
*     Test CHR_OTOI.
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
*     01-MAR-1994 (ACC)
*        Second modularised version: broken further into one routine for 
*        each of subroutine tested.  This subroutine created.
*     {enter_further_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*  Subprograms called:   
*     CHR_OTOI

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
      INTEGER I                  ! INTEGER value

*.

*    Test CHR_OTOI

*    Given illegal string
      ISTAT = SAI__OK
      CALL CHR_OTOI ('X', I, ISTAT)
      IF (ISTAT .EQ. SAI__ERROR) THEN
         PRINT *, 'CHR_OTOI detecting error OK'
      ELSE
         PRINT *, 'CHR_OTOI detecting error FAILS'
         STATUS = SAI__ERROR
      ENDIF

*    Given valid string
      ISTAT = SAI__OK
      CALL CHR_OTOI ('1750', I, ISTAT)
      IF ((ISTAT .EQ. SAI__OK) .AND. (I .EQ. 1000)) THEN
         PRINT *, 'CHR_OTOI OK'
      ELSE
         PRINT *, 'CHR_OTOI FAILS - 1750 converted to', I
         STATUS = SAI__ERROR
      ENDIF

      END
