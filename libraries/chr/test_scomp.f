      SUBROUTINE TEST_SCOMP(STATUS)
*+
*  Name:
*     TEST_SCOMP

*  Purpose:
*     Test CHR_SCOMP.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL TEST_SCOMP(STATUS)

*  Description:
*     Test CHR_SCOMP.
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
*     CHR_SCOMP

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
      LOGICAL CHR_SCOMP

*  Local Variables:
      INTEGER ISTAT              ! Local status

*.

*    Test CHR_SCOMP

*    Equal strings
      ISTAT = SAI__OK
      IF ( .NOT. CHR_SCOMP ( 'ABCD', 'ABCD' )) THEN
         PRINT *, 'CHR_SCOMP equal strings FAILS'
         ISTAT = SAI__ERROR
      END IF

*    First precedes second
      IF ( .NOT. CHR_SCOMP ( 'ABCD', 'ABCE' )) THEN
         PRINT *, 'CHR_SCOMP first precedes second FAILS'
         ISTAT = SAI__ERROR
      END IF

*    Second precedes first
      IF ( CHR_SCOMP ( 'ABCE', 'ABCD' )) THEN
         PRINT *, 'CHR_SCOMP second precedes first FAILS'
         ISTAT = SAI__ERROR
      END IF
         
      IF ( ISTAT .EQ. SAI__OK ) THEN
         PRINT *, 'CHR_SCOMP OK'
      ELSE
         STATUS = SAI__ERROR
      END IF

      END
