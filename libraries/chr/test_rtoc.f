      SUBROUTINE TEST_RTOC(STATUS)
*+
*  Name:
*     TEST_RTOC

*  Purpose:
*     Test CHR_RTOC.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL TEST_RTOC(STATUS)

*  Description:
*     Test CHR_RTOC.
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
*     CHR_RTOC

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
      INTEGER PTR1,              ! String indexes
     :        ISTAT              ! Local status
      CHARACTER*120 STRING

*.

*    Test CHR_RTOC -- Real to character

      ISTAT = SAI__OK
      STRING = ' '
      PTR1 = 0
      CALL CHR_RTOC (33.3, STRING, PTR1)
      IF (STRING(1:PTR1) .NE. '33.3') THEN
         PRINT *, 'CHR_RTOC FAILS- STRING is:',STRING
         ISTAT = SAI__ERROR
      ENDIF

      STRING = ' '
      PTR1 = 0
      CALL CHR_RTOC (-3.0, STRING, PTR1)      
      IF (STRING(1:PTR1) .NE. '-3') THEN
         PRINT *, 'CHR_RTOC FAILS- STRING is:',STRING
         ISTAT = SAI__ERROR
      ENDIF

      IF (ISTAT .EQ. SAI__OK) THEN
         PRINT *, 'CHR_RTOC OK'
      ELSE
         STATUS = SAI__ERROR
      ENDIF

      END
