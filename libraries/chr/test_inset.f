      SUBROUTINE TEST_INSET(STATUS)
*+
*  Name:
*     TEST_INSET

*  Purpose:
*     Test CHR_INSET.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL TEST_INSET(STATUS)

*  Description:
*     Test CHR_INSET.
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
*     CHR_INSET

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
      LOGICAL CHR_INSET

*.

*    Test CHR_INSET

      IF (CHR_INSET('AA,BB,@BB', '@Bb') .AND.          
     :    .NOT.
     :    CHR_INSET('!,0,~', '@')) THEN
         PRINT *, 'CHR_INSET OK'
      ELSE
         PRINT *, 'CHR_INSET FAILS'
         STATUS = SAI__ERROR
      ENDIF

      END
