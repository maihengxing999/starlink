/*
*+
*  Name:
*     mers1.h

*  Purpose:
*     Private prototypes for MERS

*  Description:
*     This include file is for internal C definitions only.

*  Copyright:
*     Copyright (C) 2008 Science and Technology Facilities Council
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
*     TIMJ: Tim Jenness (JAC, Hawaii)

*  History:
*     24-JUL-2008 (TIMJ):
*        Initial version.
*     23-DEC-2008 (TIMJ):
*        Use msglev_t rather than simple integer.

*-
*/

#include <stdlib.h>
#include "msg_par.h"

/* This is the type of struct used for ERR globals */
typedef struct {
  int errwsz;
  int errstm;
  int errrvl;
  int msgwsz;
  int msgstm;
  msglev_t msginf;
} MersTune;


int mers1Getenv( int usemsg, const char * param, int * status );

void err1Bell( int * status );
void err1Flush ( int * errbel, int * status );
void err1Prerr( const char * text, int * status );
void err1Print( const char * text, int * errbel, int * status );

void err1Gtglbl( int *errwsz, int *errstm, int *errrvl );
int err1Gtrvl ( void );
int err1Gtstm ( void );
int err1Gtwsz ( void );

void err1Ptwsz( int errwsz );
void err1Ptstm( int errstm );
void err1Ptrvl( int errrvl );

void err1RestoreEms( MersTune * ems, int * status );
void err1TuneEms( MersTune * ems, int * status );


void msg1Form ( const char * param, const char * text, int clean,
                size_t msglen, char * msgstr, int * status );
int msg1Genv( const char * param, char *msgstr, size_t msglen );
int msg1Gref( const char * param, char *refstr, size_t reflen );
int msg1Gkey( const char * param, char *keystr, size_t keylen );

void msg1Ktok ( void );
void msg1Prtln( const char * text, int * status );
void msg1Print( const char * text, int * status );

msglev_t msg1Gtinf ( void );
int msg1Gtstm ( void );
int msg1Gtwsz ( void );

void msg1Ptwsz( int msgwsz );
void msg1Ptstm( int msgstm );
void msg1Ptinf( msglev_t msginf );



