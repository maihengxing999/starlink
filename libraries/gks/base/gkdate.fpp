#include <config.h>
      SUBROUTINE GKDATE(IYEAR,MONTH,IDAY)
*
* Copyright (C) SERC 1986
*
*-----------------------------------------------------------------------
*
*  Type of Routine:  SYSTEM INTERFACE
*  Author:           PJWR
*
      INCLUDE '../include/check.inc'
*
*  PURPOSE OF THE ROUTINE
*  ----------------------
*
*     Obtains the date from the system.
*
*  MAINTENANCE LOG
*  ---------------
*
*     30/07/86  PJWR  Original UNIX version stabilised.
*     26/06/91  DLT   Modified for DEC fortran V3.0
*     03/10/96  BKM   Modified for Linux
*     17/06/04  TIMJ  Modified for generic autoconf build system
*
*  ARGUMENTS
*  ---------
*     IYEAR  OUT  2-digit Year  (86:??)
*     MONTH  OUT  Month of year (01:12)
*     IDAY   OUT  Day of month  (01:31)
*
      EXTERNAL IDATE
      INTEGER IYEAR,MONTH,IDAY
*
* LOCALS
* ------
*     These are for IDATE
      INTEGER IARRAY(3)
      INTEGER ISCALE            ! Power of ten to divide by result
      REAL YDIV                 ! year divided by iscale

*     These are for DATE
      CHARACTER *10 CDATE
      
*
*-----------------------------------------------------------------------

#if HAVE_INTRINSIC_IDATE || HAVE_IDATE

* On MIPS systems the order of arguments to IDATE is MONTH, DAY, YEAR
* but ignore that for now.

      CALL IDATE(IARRAY)

      print *,'Year from gkdate ' , IARRAY(3)

      IDAY  = IARRAY(1)
      MONTH = IARRAY(2)

* We do not test to see whether IYEAR is a 2 digit year or 
* a 4 digit year or a 4 digit year with 1900 subtracted.
* Since we know that this code is being run after the year 2000
* we can use simple heuristics to get the 2 digit year

      IF (IARRAY(3) .LT. 100) THEN
*     This is what we want
         IYEAR = IARRAY(3)

      ELSE
*     We have to extract the last 2 digits
*     We do this by shifting the number by the correct power of 10
*     and then multiplying it without the integer part

         IF (IARRAY(3) .GT. 1000) THEN
*     The actual 4 digit year (or the year 3000!)
            ISCALE = 1000

         ELSE
*     Presumably a YEAR-1900 result
            ISCALE = 100

         END IF

*     Now divide by scale, extract that fraction and multiply by scale again
         YDIV = IARRAY(3) / REAL(ISCALE)
         YDIV = YDIV - REAL(INT(YDIV))

*     Include trap for rounding errors 2004 -> 2.0399 -> 0.03999 -> 3
         IYEAR = INT((YDIV * REAL(ISCALE)) + 0.5)

      END IF

#elif HAVE_INTRINSIC_DATE || HAVE_DATE

* g77 DATE function returns a string of the form 06-JUN-04
* Cray DATE function returns a string of the form 06-06-04
* If we really cared we could look at the length of the string
* and try determine the format.
* Note that we only get here if IDATE is missing

*     error "Have not yet implemented DATE() functionality"

*     This is the code from the Cray implementation
      WRITE (CDATE,100) DATE()
 100  FORMAT ( A8 )
      READ (CDATE,101) MONTH, IDAY, IYEAR
 101  FORMAT (I2,1X,I2,1X,I2)
      RETURN

#else

* Do not have an intrinsic date function
* We could use PSX_LOCALTIME instead

 warning 'No date implementation discovered. To use constant remove this line'

*     Beginning of unix epoch!
      IYEAR = 70
      IDAY  = 1
      MONTH = 1

#endif

      RETURN

      END
