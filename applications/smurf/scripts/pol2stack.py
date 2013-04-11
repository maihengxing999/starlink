#!/usr/bin/env python

'''
*+
*  Name:
*     pol2stack

*  Purpose:
*     Combine multiple Q, U and I images and create a vector catalogue
*     from them.

*  Language:
*     python (2.7 or 3.*)

*  Description:

*  Usage:
*     pol2stack in cat pi [retain] [msg_filter] [ilevel] [glevel]
*               [logfile]

*  Parameters:
*     CAT = LITERAL (Read)
*        The output FITS vector catalogue.
*     DEBIAS = LOGICAL (Given)
*        TRUE if a correction for statistical bias is to be made to
*        percentage polarization and polarized intensity. [FALSE]
*     GLEVEL = LITERAL (Read)
*        Controls the level of information to write to a text log file.
*        Allowed values are as for "ILEVEL". The log file to create is
*        specified via parameter "LOGFILE. In adition, the glevel value
*        can be changed by assigning a new integer value (one of
*        starutil.NONE, starutil.CRITICAL, starutil.PROGRESS,
*        starutil.ATASK or starutil.DEBUG) to the module variable
*        starutil.glevel. ["ATASK"]
*     ILEVEL = LITERAL (Read)
*        Controls the level of information displayed on the screen by the
*        script. It can take any of the following values (note, these values
*        are purposefully different to the SUN/104 values to avoid confusion
*        in their effects):
*
*        - "NONE": No screen output is created
*
*        - "CRITICAL": Only critical messages are displayed such as warnings.
*
*        - "PROGRESS": Extra messages indicating script progress are also
*        displayed.
*
*        - "ATASK": Extra messages are also displayed describing each atask
*        invocation. Lines starting with ">>>" indicate the command name
*        and parameter values, and subsequent lines hold the screen output
*        generated by the command.
*
*        - "DEBUG": Extra messages are also displayed containing unspecified
*        debugging information. In addition scatter plots showing how each Q
*        and U image compares to the mean Q and U image are displayed at this
*        ILEVEL.
*
*        In adition, the glevel value can be changed by assigning a new
*        integer value (one of starutil.NONE, starutil.CRITICAL,
*        starutil.PROGRESS, starutil.ATASK or starutil.DEBUG) to the module
*        variable starutil.glevel. ["PROGRESS"]
*     IN = Literal (Read)
*        A group of container files, each containing three 2D NDFs in
*        components Q, U and I, as created using the QUI parameter of the
*        pol2cat script.
*     LOGFILE = LITERAL (Read)
*        The name of the log file to create if GLEVEL is not NONE. The
*        default is "<command>.log", where <command> is the name of the
*        executing script (minus any trailing ".py" suffix), and will be
*        created in the current directory. Any file with the same name is
*        over-written. The script can change the logfile if necessary by
*        assign the new log file path to the module variable
*        "starutil.logfile". Any old log file will be closed befopre the
*        new one is opened. []
*     MSG_FILTER = LITERAL (Read)
*        Controls the default level of information reported by Starlink
*        atasks invoked within the executing script. This default can be
*        over-ridden by including a value for the msg_filter parameter
*        within the command string passed to the "invoke" function. The
*        accepted values are the list defined in SUN/104 ("None", "Quiet",
*        "Normal", "Verbose", etc). ["Normal"]
*     PI = NDF (Read)
*        The output NDF in which to return the polarised intensity map.
*        No polarised intensity map will be created if null (!) is supplied.
*        If a value is supplied for parameter IREF, then PI defaults to
*        null. Otherwise, the user is prompted for a value if none was
*        supplied on the command line. []
*     RETAIN = _LOGICAL (Read)
*        Should the temporary directory containing the intermediate files
*        created by this script be retained? If not, it will be deleted
*        before the script exits. If retained, a message will be
*        displayed at the end specifying the path to the directory. [FALSE]

*  Copyright:
*     Copyright (C) 2013 Science & Technology Facilities Council.
*     All Rights Reserved.

*  Licence:
*     This program is free software; you can redistribute it and/or
*     modify it under the terms of the GNU General Public License as
*     published by the Free Software Foundation; either Version 2 of
*     the License, or (at your option) any later version.
*
*     This program is distributed in the hope that it will be
*     useful, but WITHOUT ANY WARRANTY; without even the implied
*     warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
*     PURPOSE. See the GNU General Public License for more details.
*
*     You should have received a copy of the GNU General Public License
*     along with this program; if not, write to the Free Software
*     Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
*     02110-1301, USA.

*  Authors:
*     DSB: David S. Berry (JAC, Hawaii)
*     {enter_new_authors_here}

*  History:
*     11-APR-2013 (DSB):
*        Original version

*-
'''


import starutil
from starutil import invoke
from starutil import NDG
from starutil import Parameter
from starutil import ParSys
from starutil import msg_out

#  Assume for the moment that we will not be retaining temporary files.
retain = 0

#  A function to clean up before exiting. Delete all temporary NDFs etc,
#  unless the script's RETAIN parameter indicates that they are to be
#  retained. Also delete the script's temporary ADAM directory.
def cleanup():
   global retain
   ParSys.cleanup()
   if retain:
      msg_out( "Retaining temporary files in {0}".format(NDG.tempdir))
   else:
      NDG.cleanup()


#  Catch any exception so that we can always clean up, even if control-C
#  is pressed.
try:

#  Declare the script parameters. Their positions in this list define
#  their expected position on the script command line. They can also be
#  specified by keyword on the command line. No validation of default
#  values or values supplied on the command line is performed until the
#  parameter value is first accessed within the script, at which time the
#  user is prompted for a value if necessary. The parameters "MSG_FILTER",
#  "ILEVEL", "GLEVEL" and "LOGFILE" are added automatically by the ParSys
#  constructor.
   params = []

   params.append(starutil.ParNDG("IN", "The input Q, U and I images",
                                 Parameter.UNSET))

   params.append(starutil.Par0S("CAT", "The output FITS vector catalogue",
                                 "out.FIT"))

   params.append(starutil.ParNDG("PI", "The output polarised intensity map",
                                 default=None, exists=False, minsize=0, maxsize=1 ))

   params.append(starutil.Par0L("RETAIN", "Retain temporary files?", False,
                                 noprompt=True))

   params.append(starutil.Par0L("DEBIAS", "Remove statistical bias from P"
                                "and IP?", False, noprompt=True))

#  Initialise the parameters to hold any values supplied on the command
#  line.
   parsys = ParSys( params )

#  It's a good idea to get parameter values early if possible, in case
#  the user goes off for a coffee whilst the script is running and does not
#  see a later parameter propmpt or error...

#  Get the input Q, U and I images.
   inqui = parsys["IN"].value

#  Now get the PI value to use.
   pimap = parsys["PI"].value

#  Get the output catalogue now to avoid a long wait before the user gets
#  prompted for it.
   outcat = parsys["CAT"].value

#  See if temp files are to be retained.
   retain = parsys["RETAIN"].value

#  See statistical debiasing is to be performed.
   debias = parsys["DEBIAS"].value

#  Get groups containing all the Q, U and I images.
   qin = inqui.filter("\.Q" )
   uin = inqui.filter("\.U" )
   iin = inqui.filter("\.I" )

#  Rotate them to use the same polarimetric reference direction.
   qrot = NDG(qin)
   urot = NDG(uin)
   invoke( "$POLPACK_DIR/polrotref qin={0} uin={1} like={2} qout={3} uout={4} ".
           format(qin,uin,qin[0],qrot,urot) )

#  Mosaic them into a single set of Q, U and I images.
   qmos = NDG( 1 )
   invoke( "$KAPPA_DIR/wcsmosaic in={0} out={1} method=bilin accept".format(qrot,qmos) )
   umos = NDG( 1 )
   invoke( "$KAPPA_DIR/wcsmosaic in={0} out={1} method=bilin accept".format(urot,umos) )
   imos = NDG( 1 )
   invoke( "$KAPPA_DIR/wcsmosaic in={0} out={1} method=bilin accept".format(iin,imos) )

#  The polarisation vectors are calculated by the polpack:polvec command,
#  which requires the input Stokes vectors in the form of a 3D cube. Paste
#  the 2-dimensional Q, U and I images into a 3D cube.
   planes = NDG( [qmos,umos,imos] )
   cube = NDG( 1 )
   invoke( "$KAPPA_DIR/paste in={0} shift=\[0,0,1\] out={1}".format(planes,cube))

#  Check that the cube has a POLANAL frame, as required by POLPACK. First
#  note the DOmain of the original current Frame
   domain = invoke( "$KAPPA_DIR/wcsattrib {0} get Domain".format(cube) )
   try:
      invoke( "$KAPPA_DIR/wcsframe {0} POLANAL".format(cube) )

#  If it does not, see if it has a "POLANAL-" Frame (kappa:paste can
#  cause this by appending "-" to the end of the domain name to account for
#  the extra added 3rd axis).
   except AtaskError:
      invoke( "$KAPPA_DIR/wcsframe {0} POLANAL-".format(cube) )

#  We only arrive here if the POLANAL- frame was found, so rename it to POLANAL
      invoke( "$KAPPA_DIR/wcsattrib {0} set domain POLANAL".format(cube) )

#  Re-instate the original current Frame
   invoke( "$KAPPA_DIR/wcsframe {0} {1}".format(cube,domain) )

#  POLPACK needs to know the order of I, Q and U in the 3D cube. Store
#  this information in the POLPACK enstension within "cube.sdf".
   invoke( "$POLPACK_DIR/polext {0} stokes=qui".format(cube) )

#  Create a FITS catalogue containing the polarisation vectors.
   command = "$POLPACK_DIR/polvec {0} cat={1} debias={2}".format(cube,outcat,debias)
   if pimap:
      command = "{0} ip={1}".format(command,pimap)
      msg_out( "Creating the output catalogue {0} and polarised intensity map {1}...".format(outcat,pimap) )
   else:
      msg_out( "Creating the output catalogue: {0}...".format(outcat) )
   msg = invoke( command )
   msg_out( "\n{0}\n".format(msg) )

#  Remove temporary files.
   cleanup()

#  If an StarUtilError of any kind occurred, display the message but hide the
#  python traceback. To see the trace back, uncomment "raise" instead.
except starutil.StarUtilError as err:
#  raise
   print( err )
   cleanup()

# This is to trap control-C etc, so that we can clean up temp files.
except:
   cleanup()
   raise

