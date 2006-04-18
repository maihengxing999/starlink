/*
 * Low level numerical conversion functions for primdat, to fill
 * the gap on systems where the Fortran compiler doesn't support the
 * intrinsics IZEXT and friends.
 *
 * The functions below are to be invoked from Fortran, hence the
 * trailing underscores.  We might want to use the CNF macros at some
 * point, and we certainly should do so if we require anything more
 * involved than the single trailing underscore below.
 */

/* 
 * Config.h defines WORDS_BIGENDIAN if the current platform stores
 * words with the most significant byte first (Motorola, Sparc), and
 * doesn't define if on platforms with the least significant byte
 * first (Intel, VAX).
 */
#include <config.h>

/*
 * We don't have to do anything if the Fortran compiler has the IZEXT
 * intrinsic, because then the functions below will have been defined
 * as Fortran statement functions within NUM_DEV_CVT.
 */
#if !HAVE_INTRINSIC_IZEXT

/*
 * The bigendian code below relies on integers being 4 bytes, and words
 * being 2, and will lose badly if this is not the case.  So check
 * this.  I think we could get around this by looking at the contents
 * of float.h: that doesn't actually give the number of bytes in a
 * float, but it would allow you to work it out.
 */
#if WORDS_BIGENDIAN
#  if SIZEOF_INT != 4*SIZEOF_CHAR
#    error "num1_cvt.c is specific to 4-byte integers"
#  endif
#  if SIZEOF_SHORT_INT != 2*SIZEOF_CHAR
#    error "num1_cvt.c is specific to 2-byte short integers"
#  endif
#endif

int num1_ubtoi_( unsigned char *num_argub )
{
/*
*+
*  Name:
*     NUM1_UBTOI

*  Purpose:
*     Convert an unsigned byte to an integer.

*  Language:
*     C

*  Copyright:
*     Copyright (C) 1995, 2004 Central Laboratory of the Research Councils.
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
*     BKM: B.K. McIlwrath (STARLINK, RAL)
*     NG: Norman Gray (Starlink, Glasgow)
*     {enter_new_authors_here}

*  History:
*     04-OCT-1995 (BKM):
*        Original version.
*     16-MAR-2004 (NG):
*        Bytesex-agnostic version
*     {enter_changes_here}

*  Bugs:
*     This implementation involves a function call overhead.
*     {note_any_bugs_here}
*-
*/

#if WORDS_BIGENDIAN
    union {
        int ret_val;
        unsigned char ubyte[4];
    } un;

    un.ret_val = 0;
    un.ubyte[3] = *num_argub;

#else

    union {
	int ret_val;
        unsigned char ubyte;
    } un;

    un.ret_val = 0;
    un.ubyte = *num_argub;
#endif

    return un.ret_val;
}


unsigned short int num1_ubtouw_( unsigned char *num_argub )
{
/*
*+
*  Name:
*     NUM1_UBTOUW

*  Purpose:
*     Convert an unsigned byte to an unsigned word.

*  Language:
*     C

*  Authors:
*     BKM: B.K. McIlwrath (STARLINK, RAL)
*     NG: Norman Gray (Starlink, Glasgow)
*     {enter_new_authors_here}

*  History:
*     04-OCT-1995 (BKM):
*        Original version.
*     {enter_changes_here}

*  Bugs:
*     This implementation involves a function call overhead.
*     {note_any_bugs_here}
*-
*/

#if WORDS_BIGENDIAN
    union {
        unsigned short ret_val;
        unsigned char ubyte[2];
    } un;

    un.ret_val = 0;
    un.ubyte[1] = *num_argub;

#else

    union {
	unsigned short int ret_val;
        unsigned char ubyte;
    } un;

    un.ret_val = 0;
    un.ubyte = *num_argub;

#endif

    return un.ret_val;
}


short int num1_ubtow_( unsigned char *num_argub )
{
/*
*+
*  Name:
*     NUM1_UBTOW

*  Purpose:
*     Convert an unsigned byte to a word.

*  Language:
*     C

*  Authors:
*     BKM: B.K. McIlwrath (STARLINK, RAL)
*     NG: Norman Gray (Starlink, Glasgow)
*     {enter_new_authors_here}

*  History:
*     04-OCT-1995 (BKM):
*        Original version.
*     16-MAR-2004 (NG):
*        Bytesex-agnostic version
*     {enter_changes_here}

*  Bugs:
*     This implementation involves a function call overhead.
*     {note_any_bugs_here}
*-
*/

#if WORDS_BIGENDIAN

    union {
        short ret_val;
        unsigned char ubyte[2];
    } un;

    un.ret_val = 0;
    un.ubyte[1] = *num_argub;

#else

    union {
	short ret_val;
        unsigned char ubyte;
    } un;

    un.ret_val = 0;
    un.ubyte = *num_argub;

#endif

    return un.ret_val;
}

int num1_uwtoi_( unsigned short int *num_arguw )
{
/*
*+
*  Name:
*     NUM1_UWTOI

*  Purpose:
*     Convert an unsigned word to an integer.

*  Language:
*     C

*  Authors:
*     BKM: B.K. McIlwrath (STARLINK, RAL)
*     NG: Norman Gray (Starlink, Glasgow)
*     {enter_new_authors_here}

*  History:
*     04-OCT-1995 (BKM):
*        Original version.
*     16-MAR-2004 (NG):
*        Bytesex-agnostic version
*     {enter_changes_here}

*  Bugs:
*     This implementation involves a function call overhead.
*     {note_any_bugs_here}
*-
*/

#if WORDS_BIGENDIAN

    union {
        int ret_val;
        unsigned short uword[2];
    } un;

    un.ret_val = 0;
    un.uword[1] = *num_arguw;

#else

    union {
	int ret_val;
        unsigned short uword;
    } un;

    un.ret_val = 0;
    un.uword = *num_arguw;

#endif

    return un.ret_val;
}

unsigned char num1_wtoub_( short int *num_argw )
{
/*
*+
*  Name:
*     NUM1_WTOU

*  Purpose:
*     Convert a word to an unsigned byte.

*  Language:
*     C

*  Authors:
*     BKM: B.K. McIlwrath (STARLINK, RAL)
*     NG: Norman Gray (Starlink, Glasgow)
*     {enter_new_authors_here}

*  History:
*     04-OCT-1995 (BKM):
*        Original version.
*     16-MAR-2004 (NG):
*        Bytesex-agnostic version
*     {enter_changes_here}

*  Bugs:
*     This implementation involves a function call overhead.
*     {note_any_bugs_here}
*-
*/

#if WORDS_BIGENDIAN

    union {
        unsigned char ret_val[2];
        short word;
    } un;

    un.word = *num_argw;
    return un.ret_val[1];

#else

    union {
	unsigned char ret_val;
        short word;
    } un;

    un.word = *num_argw;

    return un.ret_val;
#endif
}

unsigned short int num1_itouw_( int *num_argi )
{
/*
*+
*  Name:
*     NUM1_ITOUW

*  Purpose:
*     Convert an integer to an unsigned word.

*  Language:
*     C

*  Authors:
*     BKM: B.K. McIlwrath (STARLINK, RAL)
*     NG: Norman Gray (Starlink, Glasgow)
*     {enter_new_authors_here}

*  History:
*     04-OCT-1995 (BKM):
*        Original version.
*     16-MAR-2004 (NG):
*        Bytesex-agnostic version
*     {enter_changes_here}

*  Bugs:
*     This implementation involves a function call overhead.
*     {note_any_bugs_here}
*-
*/

#if WORDS_BIGENDIAN

    union {
        unsigned short ret_val[2];
        int i;
    } un;

    un.i = *num_argi;
    return un.ret_val[1];

#else
           
    union {
	unsigned short ret_val;
        int i;
    } un;

    un.i = *num_argi;

    return un.ret_val;
#endif
}

#endif /* !HAVE_INTRINSIC_IZEXT */
