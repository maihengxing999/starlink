      SUBROUTINE CHR_PUTD( DVALUE, STRING, IPOSN )
*+
*  Name:
*     CHR_PUTD

*  Purpose:
*     Put a DOUBLE PRECISION value into a string at a given position.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL CHR_PUTD( DVALUE, STRING, IPOSN )

*  Description:
*     The DOUBLE PRECISION value is encoded into a concise string
*     which is then copied into the given string beginning at
*     position IPOSN+1. IPOSN is returned updated to indicate the 
*     end position of the encoded number within STRING. This is a 
*     combination of CHR_DTOC and CHR_PUTC.

*  Arguments:
*     DVALUE = DOUBLE PRECISION (Given)
*        The value to be encoded into the string.
*     STRING = CHARACTER * ( * ) (Given and Returned)
*        The string into which DVALUE is to be copied.
*     IPOSN = INTEGER (Given and Returned)
*        The position pointer within STRING.

*  Authors:
*     JRG: Jack Giddings (UCL)
*     ACD: A.C. Davenhall (ROE)
*     AJC: A.J. Chipperfield (STARLINK)
*     {enter_new_authors_here}

*  History:
*     3-JAN-1983 (JRG):
*        Original version.
*     2-OCT-1984 (ACD):
*        Documentation improved.
*     13-SEP-1988 (AJC):
*        Remove calculation of LEN( STRING ).
*        Documentation improved.
*     {enter_further_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-

*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Arguments Given:
      DOUBLE PRECISION DVALUE

*  Arguments Given and Returned:
      CHARACTER STRING * ( * )

      INTEGER IPOSN

*  Local Constants:
      INTEGER SZSTR              ! Token size
      PARAMETER ( SZSTR = 80 )

*  Local Variables:
      CHARACTER STR1 * ( SZSTR ) ! Temporary string to hold number

      INTEGER SIZE1              ! Size of STR1

*.

*  Perform copy using calls to CHR_DTOC and CHR_PUTC.
      CALL CHR_DTOC( DVALUE, STR1, SIZE1 )
      CALL CHR_PUTC( STR1( 1 : SIZE1 ), STRING, IPOSN )

      END
