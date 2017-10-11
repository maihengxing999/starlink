/* Ready to test:

aryAnnul.c
aryFind.c
aryLock.c
aryLocked.c
aryMap.c
aryNew.c
aryPlace.c
aryTemp.c
aryTrace.c
aryUnlock.c

*/




#include "ary.h"
#include "mers.h"
#include "star/hds.h"
#include "sae_par.h"

int main(){
   Ary *ary;
   AryPlace *place = NULL;
   HDSLoc *loc = NULL;
   hdsdim lbnd[ ARY__MXDIM ];
   hdsdim ubnd[ ARY__MXDIM ];
   int status_value = 0;
   int *status = &status_value;
   int can_lock;
   int ival;
   size_t el;
   void *pntr;

/* Test accessing an existing array.
   ================================ */

   hdsOpen( "$KAPPA_DIR/m31", "Read", &loc, status );
   ival = datLocked( loc, status );
   if( ival == -1 ) {
      can_lock = 0;   /* HDS V4 - cannot lock objects */
   } else if( ival != 3 && *status == SAI__OK ){
      *status = SAI__ERROR;
      errRepf( " ", "Error 1 (%d != 3 )", status, ival );
   } else {
      can_lock = 1;
   }

   aryFind( loc, "data_array", &ary, status );

/* NB - THESE TWO CALLS FAIL IF THEY ARE SWAPPED !!! But the same
   happens with the F77 version of ARY, so presumably it's correct
   behaviour. */
   aryAnnul( &ary, status );
   datAnnul( &loc, status );



/* Test creating a new array.
   ======================== */

   hdsNew( "cary_test", "TEST", "TEST", 0, 0, &loc, status );
   aryPlace( loc, "newly", &place, status );
   lbnd[ 0 ] = -10;
   lbnd[ 1 ] = -30;
   lbnd[ 2 ] = -20;
   lbnd[ 3 ] = -50;
   ubnd[ 0 ] = 0;
   ubnd[ 1 ] = 10;
   ubnd[ 2 ] = 20;
   ubnd[ 3 ] = 30;

   aryNew( "_UWORD", 4, lbnd, ubnd, &place, &ary, status );
   aryMap( ary, "_INTEGER", "Write/ZERO", &pntr, &el, status );

   aryAnnul( &ary, status );
   datAnnul( &loc, status );


   return *status;
}
