#!/usr/bin/env python

'''
*+
*  Name:
*     POL2MAP

*  Purpose:
*     Create Q, U and I maps from a group of POL-2 "spin&scan" data files.

*  Description:
*     This script creates maps (Q, U and I) and a vector catalogue from a
*     set of POL-2 observation. New observations can be added into the map
*     without the need to re-process previously processed observations.
*     The output maps are all in units of pW.
*
*     Note, with the default configuration this script can take up to
*     an hour to run for each observation on a typical SCUBA-2-capabale
*     computer.
*
*     Masking of models within makemap (AST, etc) can be based either on the
*     SNR of the map created as the end of each iteration, or on an external
*     map, or on a fixed circle centred on the origin - see parameter MASK.
*
*     By default, the Q, U, I and PI catalogue values are in units of
*     mJy/beam (see parameter Jy).

*  Usage:
*     pol2map in iout qout uout [cat] [config] [pixsize] [qudir] [mapdir]
*             [mask] [masktype] [ipcor] [ipref] [reuse] [ref] [north] [reffcf]
*             [debias] [retain] [maskout1] [maskout2] [msg_filter] [ilevel]
*             [glevel] [logfile]

*  ADAM Parameters:
*     BINSIZE = _REAL (Read)
*        The bin size in the output vector catalogue, in arcsec. The
*        value supplied for parameter PIXSIZE is used as the default for
*        BINSIZE. An error is reported if BINSIZE is smaller than
*        PIXSIZE. []
*     CAT = LITERAL (Read)
*        The output FITS vector catalogue. No catalogue is created if
*        null (!) is supplied. The Q, U  and PI values in this catalogue
*        will be in units of pW or mJy/beam, as selected using parameter
*        JY . The bin size is specified by parameter BINSIZE. [!]
*     CONFIG = LITERAL (Read)
*        Extra parameter values to include in the MAKEMAP configuration
*        used to create both the I maps and the Q/U maps.
*
*        In general, it is important that the I, Q and U maps are all
*        created using the same configuration so that they can be compared
*        directly. However, if it is necessary to use a different
*        configuration for I and Q/U maps, the differences may be
*        specified using the ADAM parameters "ICONFIG" and "QUCONFIG". The
*        ADAM parameter "CONFIG" specifies the configuration parameters
*        that are always used, whether an I map or a Q/U map is being
*        created. In all cases the configuration parameters specified by
*        "CONFIG" are applied first, followed  by the configuration
*        parameters specified by "ICONFIG" (if creating an I map) or
*        "QUCONFIG" (if creating a Q or U map). Thus values supplied in
*        "ICONFIG" or "QUCONFIG" over-ride values for the same parameters
*        specified in "CONFIG".
*
*        The configurations specified by CONFIG, ICONFIG and QUCONFIG are
*        applied on top of the following set of default parameters:
*        ---
*           ^$STARLINK_DIR/share/smurf/.dimmconfig_pol2.lis
*           numiter = -200
*           modelorder=(com,gai,pca,ext,flt,ast,noi)
*
*           maptol = 0.05
*           maptol_mask = <undef>
*           maptol_mean = 0
*           maptol_box = 60
*           maptol_hits = 1
*
*           ast.mapspike_freeze = 5
*           pca.pcathresh = -150
*           pca.zero_niter = 0.5
*           com.zero_niter = 0.5
*           flt.zero_niter = 0.5
*           com.freeze_flags = 30
*        ---
*        Additional parameters are also set, depending on the value of
*        parameter MASK. If MASK is set to "AUTO", the following
*        parameters are added to the above default config:
*        ---
*           ast.skip = 10
*           ast.zero_snr = 3
*           ast.zero_snrlo = 2
*           ast.zero_freeze = 0.2
*
*           pca.pcathresh = -50
*           pca.zero_snr = 5
*           pca.zero_snrlo = 3
*           pca.zero_freeze = -1
*
*           com.zero_snr = 5
*           com.zero_snrlo = 3
*           com.zero_freeze = -1
*
*           flt.zero_snr = 5
*           flt.zero_snrlo = 3
*           flt.zero_freeze = -1
*        ---
*        If MASK is set to "CIRCLE", the following parameters are added
*        to the above default config:
*        ---
*           ast.zero_circle = 0.0083  (degrees, i.e. 30 arc-seconds)
*           pca.zero_circle = 0.0038
*           com.zero_circle = 0.0083
*           flt.zero_circle = 0.0083
*        ---
*        The default value for pca.pcathresh indicated above will be
*        changed if it is too high to allow convergence of the I maps
*        within the number of iterations allowed by numiter.
*
*        If MASK is set to the name of an NDF, this script creates fixed
*        masks from the NDF, and the following parameters are added
*        to the above default config:
*        ---
*           ast.zero_mask = ref
*           pca.zero_mask = mask2
*           com.zero_mask = mask2
*           flt.zero_mask = mask2
*        ---
*        The above "ref" mask consists of clumps of pixel with SNR greater
*        than 3, extended down to an SNR level of 2. The "mask2" mask
*        consists of clumps of pixel with SNR greater than 5, extended
*        down to an SNR level of 3. However, the above SNR levels are
*        raised if necessary to ensure that the source occupies no more
*        than 20% of the pixels within the "ref" mask, and 10% of the
*        pixels within the "mask2" mask.
*
*        The same configuration is used for all three Stokes parameters -
*        I, Q and U with the exception that "com.noflag=1" is added to
*        the configuration when creating maps for Q and U.
*
*        If a configuration is supplied using parameter CONFIG, values
*        supplied for any of the above parameters will over-write the
*        values specified above. In addition, the following mandatory
*        values are always appended to the end of the used configuration:
*        ---
*           flagslow = 0.01
*           downsampscale = 0
*           noi.usevar=1
*        ---
*        If null (!) or "def" is supplied, the above set of default
*        configuration parameters are used without change. ["def"]
*     DEBIAS = LOGICAL (Given)
*        TRUE if a correction for statistical bias is to be made to
*        percentage polarization and polarized intensity in the output
*        vector catalogue specified by parameter CAT. [FALSE]
*     FCF = _REAL (Read)
*        The FCF value that is used to convert I, Q and U values from pW
*        to Jy/Beam. If a null (!) value is supplied a default value is
*        used that depends on the waveband in use - 725.0 for 850 um and
*        962.0 for 450 um. [!]
*     GLEVEL = LITERAL (Read)
*        Controls the level of information to write to a text log file.
*        Allowed values are as for "ILEVEL". The log file to create is
*        specified via parameter "LOGFILE. In adition, the glevel value
*        can be changed by assigning a new integer value (one of
*        starutil.NONE, starutil.CRITICAL, starutil.PROGRESS,
*        starutil.ATASK or starutil.DEBUG) to the module variable
*        starutil.glevel. ["ATASK"]
*     ICONFIG = LITERAL (Read)
*        Extra parameter values to include in the MAKEMAP configuration
*        used to create I maps. The values specified by "ICONFIG" are
*        applied after those specified by "CONFIG". [!]
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
*        debugging information.
*
*        In adition, the glevel value can be changed by assigning a new
*        integer value (one of starutil.NONE, starutil.CRITICAL,
*        starutil.PROGRESS, starutil.ATASK or starutil.DEBUG) to the module
*        variable starutil.glevel. ["PROGRESS"]
*     IN = NDF (Read)
*        A group of input files. Each specified file must be one of the
*        following types:
*
*        - a raw POL-2 data file. Any supplied raw POL-2 data files will
*        be converted into time-series Q,U and I files using SMURF:CALCQU
*        and placed in the directory specified by parameter QUDIR. These
*        will then be converted into maps using SMURF:MAKEMAP, and placed
*        in the directory specified by parameter MAPDIR.
*
*        - a time-series file holding Stokes Q, U or I values. Any supplied
*        time-series files will be converted into individual maps (one for
*        each file) using SMURF:MAKEMAP, and placed in the directory
*        specified by parameter MAPDIR. These maps are created only for
*        the required Stokes parameters - as indicated by parameters
*        IOUT, QOUT and UOUT.
*
*        - a two-dimensional map holding Stokes Q, U or I values. Any
*        maps must be in units of pW. The final output I map is created by
*        coadding any supplied I maps with the I maps created by this script.
*        These coadded maps are created only for the required Stokes
*        parameters - as indiciated by parameters IOUT, QOUT and UOUT.
*
*        Any combination of the above types can be supplied. Note, if
*        parameter REUSE is TRUE, then any required output files that
*        already exist in the directory specified by parameter MAPDIR
*        are re-used rather than being re-created from the corresponding
*        input data.
*     IOUT = NDF (Write)
*        The output NDF in which to return the total intensity (I) map
*        including all supplied observations. This will be in units of pW.
*        Supply null (!) if the I map is not to be retained on exit. In
*        this case, the I map will only be created if it is needed
*        to create the output vector catalogue (see parameter CAT) and
*        will be deleted on exit.
*     IPCOR = _LOGICAL (Read)
*        If TRUE, then IP correction is used when creating Q and U maps,
*        based on the values in the total intensity map specified by
*        parameter IPREF. If FALSE, then no IP correction is performed.
*        The default is TRUE if any Q or U output maps are being created,
*        and FALSE otherwise. []
*     IPREF = NDF (Read)
*        The total intensity map to be used for IP correction. Only
*        accessed if parameter IPCOR is set TRUE. If null (!) is supplied
*        for IPREF, the map supplied for parameter REF is used. The map must
*        be in units of pW. If the same value is supplied for both IOUT
*        and IPREF, the output I map will be used for IP correction. [!]
*     JY = _LOGICAL (Read)
*        If TRUE, the I, Q and U values in the output catalogue will be
*        in units of mJy/beam. Otherwise they will be in units of pW. Note,
*        the Q, U and I maps are always in units of pW. The same FCF value
*        is used to convert all three Stokes parameters from pW to mJy/beam,
*        derived from the value supplied for parameter FCF. [TRUE]
*     LOGFILE = LITERAL (Read)
*        The name of the log file to create if GLEVEL is not NONE. The
*        default is "<command>.log", where <command> is the name of the
*        executing script (minus any trailing ".py" suffix), and will be
*        created in the current directory. Any file with the same name is
*        over-written. The script can change the logfile if necessary by
*        assign the new log file path to the module variable
*        "starutil.logfile". Any old log file will be closed befopre the
*        new one is opened. []
*     MAPDIR = LITERAL (Read)
*        The name of a directory in which to put the Q, U an I maps made
*        from each individual observation supplied via "IN", before
*        coadding them. If
*        null is supplied, the new maps are placed in the same temporary
*        directory as all the other intermediate files and so will be
*        deleted when the script exists (unless parameter RETAIN is set
*        TRUE). Note, these maps are always in units of pW. Each one will
*        contain FITS headers specifying the pointing corrections needed
*        to align the map with the reference map. [!]
*     MAPVAR = _LOGICAL (Read)
*        Determines how the variance information in the final I, Q and
*        U coadded maps (parameters IOUT, QOUT and UOUT) are derived.
*
*        If MAPVAR is FALSE, the variances in the coadded maps are
*        calculated by propagating the variance information from the
*        individual observation maps. These variances are determined by
*        makemap and are based on the spread of bolometer I, Q or U
*        values that fall in each pixel of the individual observation
*        map.
*
*        If MAPVAR is TRUE, the variances in the coadded maps are
*        determined from the spread of input values (i.e. the pixel
*        values from the individual observation maps) that fall in each
*        pixel of the coadd.
*
*        The two methods produce similar variance estimates in the
*        background regions, but MAPDIR=TRUE usually creates much higher
*        on-source errors than MAPDIR=FALSE. Only use MAPDIR=TRUE if you
*        have enough input observations to make the variance between the
*        individual observation maps statistically meaningful. [FALSE]
*     MASK = LITERAL (Read)
*        Specifies the type of masking to be used within makemap (the
*        same type of masking is used to create all three maps - I, Q
*        and U):
*
*        - "AUTO": makemap uses automatically generated masks based
*        on the SNR map at the end of each iteration. The SNR levels
*        used are specified by the "xxx.ZERO_SNR" and "xxx.ZERO_SNRLO"
*        configuration parameters (see parameter CONFIG).
*
*        - "CIRCLE": makemap uses a fixed circular mask of radius 60
*        arc-seconds centred on the expected source position.
*
*        - Any other value is assumed to be a group of one or two NDFs
*        that specify the "external" AST and PCA masks to be used. The
*        way in which these NDFs are used depends on the value of
*        parameter MASKTYPE. These NDFs must be aligned in pixel
*        coordinates with the reference map (parameter REF).
*
*        ["AUTO"]
*     MASKOUT1 = LITERAL (Write)
*        If a non-null value is supplied for MASKOUT, it specifies the NDF
*        in which to store the AST mask created from the NDF specified by
*        parameter MASK. Only used if an NDF is supplied for parameter
*        MASK. [!]
*     MASKOUT2 = LITERAL (Write)
*        If a non-null value is supplied for MASKOUT, it specifies the NDF
*        in which to store the PCA mask created from the NDF specified by
*        parameter MASK. Only used if an NDF is supplied for parameter
*        MASK. [!]
*     MASKTYPE = LITERAL (Read)
*        Specifies the way in which NDFs supplied for parameter MASK
*        are to be used. This parameter can be set to either of the
*        following values:
*
*        - "Signal": A single NDF should be supplied for parameter MASK
*        holding the astronomical signal level at each pixel within the
*        astronomical field being mapped. It can be in any units, but
*        must have a Variance component. The AST and PCA masks are
*        created from this map by finding all clumps of contiguous pixels
*        above a fixed SNR limit, and then extending these clumps down to
*        a lower SNR limit. For the AST model, the upper and lower SNR
*        limits are of 3.0 and 2.0. For the PCA mask, the limits are 5.0
*        and 3.0. The AST and PCA masks created in this way can be saved
*        using parameters MASKOUT1 and MASKOUT2.
*
*        - "Mask": A pair of NDFs should be supplied for parameter MASK,
*        each holding a mask in which background pixels have bad values
*        and source pixels have good values. The first supplied NDF is
*        used directly as the AST mask, and the second is used as the PCA
*        mask.
*
*        ["Signal"]
*     MSG_FILTER = LITERAL (Read)
*        Controls the default level of information reported by Starlink
*        atasks invoked within the executing script. This default can be
*        over-ridden by including a value for the msg_filter parameter
*        within the command string passed to the "invoke" function. The
*        accepted values are the list defined in SUN/104 ("None", "Quiet",
*        "Normal", "Verbose", etc). ["Normal"]
*     NEWMAPS = LITERAL (Read)
*        The name of a text file to create, in which to put the paths of
*        all the new maps written to the directory specified by parameter
*        MAPDIR (one per line). If a null (!) value is supplied no file is
*        created. [!]
*     NORTH = LITERAL (Read)
*        Specifies the celestial coordinate system to use as the reference
*        direction in any newly created Q and U time series files. For
*        instance if NORTH="AZEL", then they use the elevation axis as the
*        reference direction, and if "ICRS" is supplied, they use the ICRS
*        Declination axis. If "TRACKING" is supplied, they use north in the
*        tracking system - what ever that may be. ["TRACKING"]
*     PIXSIZE = _REAL (Read)
*        Pixel dimensions in the output I, Q and U maps, in arcsec. The default
*        is 4 arc-sec for 850 um data and 2 arc-sec for 450 um data. The
*        bin size for the output catalogue can be specified separately -
*        see parameter BINSIZE and CAT. []
*     QOUT = NDF (Write)
*        The output NDF in which to return the Q map including all supplied
*        observations. This will be in units of pW. Supply null (!) if no Q
*        map is required.
*     QUCONFIG = LITERAL (Read)
*        Extra parameter values to include in the MAKEMAP configuration
*        used to create Q and U maps. The values specified by "QUCONFIG"
*        are applied after those specified by "CONFIG". [!]
*     QUDIR = LITTERAL (Read)
*        The name of a directory in which to put the Q, U and I time series
*        generated by SMURF:CALCQU, prior to generating maps from them. If
*        null (!) is supplied, they are placed in the same temporary directory
*        as all the other intermediate files and so will be deleted when the
*        script exists (unless parameter RETAIN is set TRUE). [!]
*     REF = NDF (Read)
*        An optional map defining the pixel grid for the output maps,
*        and which is used to determine pointing corrections. If null
*        (!) is supplied, then the map (if any) specified by parameter
*        MASK is used. See also parameter REFFCF. [!]
*     REFFCF = _REAL (Read)
*        The FCF that should be used to convert the supplied REF map
*        to pW. This parameter is only used if the supplied REF map is
*        not already in units of pW. The default is the FCF value stored
*        in the FITS extension of the map, or the standard FCF for the
*        band concerned (450 or 840) if there is no FCF value in the FITS
*        header. Specify a new value on the pol2map command line if the
*        default value described above is inappropriate. []
*     REUSE = _LOGICAL (Read)
*        If TRUE, then any output maps or time-treams that already exist
*        (for instance, created by a previous run of this script) are re-used
*        rather than being re-created from the corresponding input files.
*        If FALSE, any previously created output maps or time-streams are
*        ignored and new ones are created from the corresponding input
*        files. [TRUE]
*     RETAIN = _LOGICAL (Read)
*        Should the temporary directory containing the intermediate files
*        created by this script be retained? If not, it will be deleted
*        before the script exits. If retained, a message will be
*        displayed at the end specifying the path to the directory. [FALSE]
*     UOUT = NDF (Write)
*        The output NDF in which to return the U map including all supplied
*        observations. This will be in units of pW. Supply null (!) if no U
*        map is required.

*  Copyright:
*     Copyright (C) 2017 East Asian Observatory.
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
*     DSB: David S. Berry (EAO)
*     {enter_new_authors_here}

*  History:
*     25-JAN-2017 (DSB):
*        Original version
*     27-FEB-2017 (DSB):
*        If makemap fails, ensure any resulting map is deleted.
*     3-MAY-2017 (DSB):
*        - Add parameter MAPVAR.
*        - Re-structure so that coadded maps can be created from a list
*        of input observation maps.
*        - Use kappa:wcsmosaic to create the coadded maps rather than
*        ccdpack:makemos. This is because wcsmosaic allows input variance
*        to be used for weighting, whilst  generating output variances from
*        the spread of the input values. makemos does not allow this
*        combination.
*     20-JUN-2017 (DSB):
*        - If parameter JY is true, create output values in mJy/beam,
*        rather than Jy/beam.
*     12-JUL-2017 (DSB):
*        Added parameters ICONFIG and QUCONFIG.
*     24-AUG-2017 (DSB):
*        When checking whether "modelorder" contains PCA in the user
*        supplied config, allow for the possibility that the config may contain
*        no modelorder value at all. This bug prevented the abortsoon
*        parameter being used with makemap in the majority of cases.
*     7-FEB-2018 (DSB):
*        Some maps have low correlation with the reference but can still
*        be aligned successfully using kappa:align2d. So remove the
*        correlation limit when running align2d. But guard against cases
*        where the map cannot be masked (in which case align2d may be
*        influenced by the bright noisey edge pixels) by masking off the
*        edges using the EXP_TIME values.
*     9-FEB-2018 (DSB):
*        Remove hardwired assumption of 850 data when looking for
*        pre-existing I,Q,U time-stream data, and when checking value of
*        NUMITER in the supplied config.
'''

import glob
import os
import math
import shutil
import starutil
import numpy as np
from starutil import invoke
from starutil import NDG
from starutil import Parameter
from starutil import ParSys
from starutil import msg_out
from starutil import AtaskError
from starutil import get_fits_header
from starutil import get_task_par

#  Assume for the moment that we will not be retaining temporary files.
retain = 0

#  A function to find the PCA.PCATHRESH value used to create the most
#  recent auto-masked or ext-masked map.
def getPcaThresh( mapdir, automask ):
   if automask:
      base = "[iqu]map"
   else:
      base = "[IQU]map"

   pcathresh = 0
   this_map = None
   nsecmin = 1E30
   for tmap in glob.glob("{0}/*{1}.sdf".format(mapdir, base )):
      nsec = os.path.getmtime( tmap )
      if nsec < nsecmin:
         try:
            pcathresh = float( invoke("$KAPPA_DIR/configecho name=pca.pcathresh "
                                      "ndf={0} config=! application=makemap "
                                      "defaults=$SMURF_DIR/smurf_makemap.def"
                                      .format(tmap)))
            nsecmin = nsec
            this_map = tmap
         except starutil.AtaskError:
            pass

   return (pcathresh,this_map)



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



#  Main entry...
#  Catch any exception so that we can always clean up, even if control-C
#  is pressed.
try:

#  Constants.
   pcathresh_def1 = -50    # Default value for auto-masking
   pcathresh_def2 = -150   # Default value for external-masking

#  Declare the script parameters. Their positions in this list define
#  their expected position on the script command line. They can also be
#  specified by keyword on the command line. No validation of default
#  values or values supplied on the command line is performed until the
#  parameter value is first accessed within the script, at which time the
#  user is prompted for a value if necessary. The parameters "MSG_FILTER",
#  "ILEVEL", "GLEVEL" and "LOGFILE" are added automatically by the ParSys
#  constructor.
   params = []



   params.append(starutil.ParNDG("IN", "The input POL2 data",
                                 get_task_par("DATA_ARRAY","GLOBAL",
                                              default=Parameter.UNSET)))

   params.append(starutil.ParNDG("IOUT", "The output total intensity map",
                                 default=None, exists=False, minsize=0,
                                 maxsize=1 ))

   params.append(starutil.ParNDG("QOUT", "The output Q map",
                                 default=None, exists=False, minsize=0,
                                 maxsize=1 ))

   params.append(starutil.ParNDG("UOUT", "The output U map",
                                 default=None, exists=False, minsize=0,
                                 maxsize=1 ))

   params.append(starutil.Par0S("CAT", "The output FITS vector catalogue",
                                 default=None, noprompt=True))

   params.append(starutil.Par0S("CONFIG", "Map-maker tuning parameters",
                                "def", noprompt=True))

   params.append(starutil.Par0F("PIXSIZE", "Pixel size (arcsec)", None,
                                 maxval=1000, minval=0.01, noprompt=True))

   params.append(starutil.Par0S("QUDIR", "Directory in which to save new "
                                "Q, U and I time series", None, noprompt=True))

   params.append(starutil.Par0S("MAPDIR", "Directory in which to save new "
                                "I maps before they are co-added", None,
                                noprompt=True))

   params.append(starutil.Par0S("MASK", "Type of masking to use in makemap",
                                "AUTO", noprompt=True ))

   params.append(starutil.ParChoice("MASKTYPE", ("SIGNAL","MASK"),
                                    "Type of map supplied for parameter MASK",
                                    "SIGNAL", noprompt=True ))

   params.append(starutil.Par0L("IPCOR", "Perform IP correction?", None,
                                 noprompt=True))

   params.append(starutil.ParNDG("IPREF", "The total intensity map to use "
                                 "for IP correction", default=None, exists=False,
                                 noprompt=True, minsize=0, maxsize=1 ))

   params.append(starutil.Par0L("REUSE", "Re-use existing time-streams and maps?", True,
                                 noprompt=True))

   params.append(starutil.ParNDG("REF", "Reference map defining the pixel grid", default=None,
                                 noprompt=True, minsize=0, maxsize=1 ))

   params.append(starutil.ParChoice( "NORTH", ("TRACKING","FK5","ICRS","AZEL",
                                     "GALACTIC","GAPPT","FK4","FK4-NO-E",
                                     "ECLIPTIC"), "Celestial system to "
                                     "use as reference direction", "TRACKING",
                                     noprompt=True ))

   params.append(starutil.Par0F("REFFCF",
                                 "FCF needed to convert REF map to pW",
                                 None, noprompt=True))

   params.append(starutil.Par0L("DEBIAS", "Remove statistical bias from P"
                                "and PI?", False, noprompt=True))

   params.append(starutil.Par0L("RETAIN", "Retain temporary files?", False,
                                 noprompt=True))

   params.append(starutil.ParNDG("MASKOUT1", "The output AST mask",
                                 default=None, exists=False, minsize=0,
                                 maxsize=1, noprompt=True ))

   params.append(starutil.ParNDG("MASKOUT2", "The output PCA mask",
                                 default=None, exists=False, minsize=0,
                                 maxsize=1, noprompt=True ))

   params.append(starutil.Par0S("NEWMAPS", "Text file to hold list of new map",
                                 default=None, noprompt=True))

   params.append(starutil.Par0L("MAPVAR", "Use variance between observation maps?",
                                 False, noprompt=True))

   params.append(starutil.Par0L("Jy", "Should outputs be converted from pW to mJy/beam?",
                                True, noprompt=True))

   params.append(starutil.Par0F("FCF", "pW to Jy/beam conversion factor",
                                None, noprompt=True ))

   params.append(starutil.Par0S("ICONFIG", "Map-maker tuning parameters for I maps",
                                "def", noprompt=True))

   params.append(starutil.Par0S("QUCONFIG", "Map-maker tuning parameters for Q/U maps",
                                "def", noprompt=True))

   params.append(starutil.Par0F("BINSIZE", "Catalogue bin size (arcsec)", None,
                                 maxval=1000, minval=0.01, noprompt=True))


#  Initialise the parameters to hold any values supplied on the command
#  line.
   parsys = ParSys( params )

#  It's a good idea to get parameter values early if possible, in case
#  the user goes off for a coffee whilst the script is running and does not
#  see a later parameter propmpt or error...

#  Get the input POL-2 data files. They should be supplied as the first item on
#  the command line, in the form of a Starlink "group expression" (i.e.
#  the same way they are supplied to other SMURF commands such as makemap).
   indata = parsys["IN"].value

#  Now get the I, Q and U output maps.
   imap = parsys["IOUT"].value
   qmap = parsys["QOUT"].value
   umap = parsys["UOUT"].value

#  Get the output catalogue.
   outcat = parsys["CAT"].value

#  If a catalogue is required, we need to create all three maps, so
#  ensure this is the case (use temporary files for any that have not
#  been requested by the user).
   catref = None
   if outcat:
      if not imap:
         imap = NDG( 1 )
      if not qmap:
         qmap = NDG( 1 )
      if not umap:
         umap = NDG( 1 )

#  Get the binsize for the catalogue.
      binsize = parsys["BINSIZE"].value

#  See if statistical debiasing is to be performed.
   debias = parsys["DEBIAS"].value

#  The user-supplied makemap configs, and pixel size.
   config = parsys["CONFIG"].value
   iconfig = parsys["ICONFIG"].value
   quconfig = parsys["QUCONFIG"].value
   pixsize = parsys["PIXSIZE"].value
   if pixsize:
      pixsize_par = "pixsize={0}".format(pixsize)
   else:
      pixsize_par = ""

#  See if temp files are to be retained.
   retain = parsys["RETAIN"].value

#  See if existing output files are to be re-used. If not, they are
#  re-created from the corresponding input files.
   reuse = parsys["REUSE"].value

#  See if variances in the co-added maps are to be derived form the
#  spread of values in corresponding pixels of the observation maps.
#  If not, variances in the coadds are propagated from the variances
#  in the observation maps.
   mapvar = parsys["MAPVAR"].value

#  Get the type of masking to use. If a map is supplied, assume external
#  masking.
   mask = parsys["MASK"].value
   upmask = mask.upper()

   pcamask = None
   pcamaskpar = ""

   if upmask == "AUTO":
      automask = True
      circlemask = False
      maskmap = None
   elif upmask == "CIRCLE":
      automask = False
      circlemask = True
      maskmap = None

#  Otherwise, the MASK parameter must sopecify one (if MASKTYPE is
#  "Signal") or two (if MASKTYPE is "Mask") NDFs.
   else:
      automask = False
      circlemask = False
      maskmap = NDG(mask)

      masktype = parsys["MASKTYPE"].value
      if masktype == "SIGNAL":
         if len(maskmap) != 1:
            raise starutil.InvalidParameterError("More than one NDF "
                      "supplied for parameter MASK." )
         msg_out("Masking will be based on SNR values in {0}.".format(maskmap))

#  See where (if at all) the masks are to be saved.
         astmask = parsys["MASKOUT1"].value
         if astmask is None:
            astmask = NDG(1)
         pcamask = parsys["MASKOUT2"].value
         if pcamask is None:
            pcamask = NDG(1)

      else:
         if len(maskmap) != 2:
            raise starutil.InvalidParameterError("Exactly two NDFs must be"
                                            " supplied for parameter MASK." )
         astmask = maskmap[0]
         pcamask = maskmap[1]
         msg_out("AST mask: {0}.".format(astmask))
         msg_out("PCA mask: {0}.".format(pcamask))

#  Get the reference map
   ref = parsys["REF"].value
   if not ref:
      use_ref_for_alignment = False
      if maskmap is not None:
         ref = maskmap[0]
         if masktype == "SIGNAL":
            use_ref_for_alignment = True
      else:
         ref = "!"

   else:
      use_ref_for_alignment = True

#  If the REF map is in units of mJy/beam, convert it to pW using the FCF
#  in the "FCF" FITS header if available, or the standard FCF for the
#  wavelength otherwise.
      invoke("$KAPPA_DIR/ndftrace ndf={0} quiet".format(ref) )
      ref_units = get_task_par( "UNITS", "ndftrace" ).replace(" ", "")
      if ref_units != "pW":

         try:
            filter = int( float( get_fits_header( ref, "FILTER", True )))
         except starutil.NoValueError:
            filter = 850
            msg_out( "No value found for FITS header 'FILTER' in {0} - assuming 850".format(ref))

         if filter != 450 and filter != 850:
            raise starutil.InvalidParameterError("Invalid FILTER header value "
                   "'{0} found in {1}.".format( filter, ref ) )

         if ref_units == "mJy/beam":
            if filter == 450:
               fcf = 491000.0
            else:
               fcf = 537000.0

         elif ref_units == "Jy/beam":
            if filter == 450:
               fcf = 491.0
            else:
               fcf = 537.0

         elif ref_units == "mJy/arcsec**2" or ref_units == "mJy/arcsec^2" :
            if filter == 450:
               fcf = 4710
            else:
               fcf = 2340

         elif ref_units == "Jy/arcsec**2" or ref_units == "Jy/arcsec^2" :
            if filter == 450:
               fcf = 4.71
            else:
               fcf = 2.34

         else:
            raise starutil.InvalidParameterError("REF map {0} has unsupported units {1}".
                                                 format(ref, ref_units) )

         fcfhead = get_fits_header( ref, "FCF" )
         if fcfhead is not None:
            fcfhead = float( fcfhead )
            ratio = fcfhead/fcf
            if ratio < 0.5 or ratio > 2.0:
               msg_out("WARNING: REF map {0} has units {1} but the FCF header is {2} "
                       "- which looks wrong (the expected FCF is {3}).".
                       format(ref, ref_units, fcfhead, fcf) )
            fcf = fcfhead

         parsys["REFFCF"].default = fcf
         ref_fcf = parsys["REFFCF"].value

         msg_out( "Converting REF map ({0}) from {1} to pW using FCF={2}...".
                  format(ref,ref_units,ref_fcf))
         refpw = NDG(1)
         invoke("$KAPPA_DIR/cdiv in={0} scalar={1} out={2}".format(ref,ref_fcf,refpw) )
         ref = refpw

#  Get the waveband of the supplied data (450 or 850).
   try:
      filter = int( float( starutil.get_fits_header( indata[0], "FILTER", True )))
   except starutil.NoValueError:
      filter = 850
      msg_out( "No value found for FITS header 'FILTER' in {0} - assuming 850".format(indata[0]))

   if filter != 450 and filter != 850:
      raise starutil.InvalidParameterError("Invalid FILTER header value "
             "'{0} found in {1}.".format( filter, indata[0] ) )

#  See if we should store I, Q and U values in mJy/beam in the output
#  calatlogue.
   jy = parsys["JY"].value

#  If we are converting to mJy/beam, get the FCF (Jy/pw).
   if jy:
      fcf = parsys["FCF"].value

#  If no FCF supplied, get the default FCF for the waveband
      if fcf is None:
         if filter == 450:
            fcf = 962.0
         else:
            fcf = 725.0

#  If IP correction is to be performed, get the map to be used to define
#  the IP correction.
   parsys["IPCOR"].default = ( qmap is not None or umap is not None )
   if parsys["IPCOR"].value:
      ipref = parsys["IPREF"].value
      if not ipref:
         if not ref or ref == "!":
            raise starutil.InvalidParameterError("IP correction requested "
                                        "but no IP reference map supplied.")
         ipref = ref

      else:
         if ipref != imap:
            invoke("$KAPPA_DIR/ndftrace ndf={0} quiet".format(ipref) )
            units = get_task_par( "UNITS", "ndftrace" ).replace(" ", "")
            if units != "pW":
               raise starutil.InvalidParameterError("IP reference map {0} is"
                    " has units {1} - units must be pW".format(ipref,units))

      ip = "ipref={0}".format(ipref)
   else:
      ip = "ipref=!"

#  See where to put new Q, U and I maps for individual observations, and
#  ensure the directory exists.
   mapdir =  parsys["MAPDIR"].value
   if not mapdir:
      mapdir = NDG.tempdir
   elif not os.path.exists(mapdir):
      os.makedirs(mapdir)

#  See where to put new Q, U and I time series, and ensure the directory
#  exists.
   qudir =  parsys["QUDIR"].value
   if not qudir:
      qudir = NDG.tempdir
   elif not os.path.exists(qudir):
      os.makedirs(qudir)

#  Get the reference direction.
   north = parsys["NORTH"].value

#  The name of the output text file to create in which to store the paths
#  to the new individual observation maps created by the current
#  invocation of this script.
   newmaps = parsys["NEWMAPS"].value







#  -----------  CLASSIFY THE INPUT DATA FILES ------------------------


#  Classify each input data file as raw, QUI time-series or QUI map. Create
#  three separate text files containing all input NDFs of each type (plus
#  a fourth holing non-POL2 data). Also, create another text file
#  containing a list of any missing raw sub-scan files.
   junks = NDG.tempfile()
   inraws = NDG.tempfile()
   inquis = NDG.tempfile()
   inmaps = NDG.tempfile()
   rawinfo = NDG.tempfile()
   missing = NDG.tempfile()
   mapinfo = NDG.tempfile()
   invoke("$SMURF_DIR/pol2check in={0} quiet=yes junkfile={1} mapfile={2} "
          "rawfile={3} stokesfile={4} rawinfo={5} missing={6} mapinfo={7}".
          format(indata,junks,inmaps,inraws,inquis,rawinfo,missing,mapinfo))

#  Warn about any non-POL2 input data files that are being ignored.
   if get_task_par( "JUNKFOUND", "pol2check" ):
      msg_out( " ")
      msg_out( "WARNING: The following inappropriate input data files are "
               "being ignored: " )
      with open( junks ) as f:
         msg_out( f.read() )
      msg_out( " ")

#  Warn about any missing raw data scub-scans.
   if os.path.isfile( missing ):
      msg_out( " ")
      msg_out( "WARNING: The raw data files for the following sub-scans seem "
               "to be missing from the supplied list of input files: " )
      with open( missing ) as f:
         msg_out( f.read() )
      msg_out( " ")

#  Initialise the list of all Stokes time-series files to be processed by
#  makemap so that it holds any Stokes time-series files supplied by
#  parameter IN.
   allquis = NDG.tempfile()
   if get_task_par( "STOKESFOUND", "pol2check" ):
      shutil.copyfile( inquis, allquis )

#  Initialise a list of new maps created by this run of pol2map.
   new_maps = []

#  Set up a dict for each Stokes parameter holding paths to any supplied maps
#  for that Stokes parameter. The keys are of the form "<UT>_<OBS>_<SUBSCAN>".
#  Check that any supplied maps are in units of pW and are created from
#  POL2 data.
   imaps = {}
   qmaps = {}
   umaps = {}

   if get_task_par( "MAPFOUND", "pol2check" ):

      with open(inmaps) as infile:
         lines = infile.readlines()
      paths = [line.strip() for line in lines]

      with open(mapinfo) as infile:
         lines = infile.readlines()
      infos = [line.strip() for line in lines]

      for (path,info) in zip( paths, infos ):
         (stokes,id) = info.split()
         if stokes == "I":
            imaps[id] = path
         elif stokes == "Q":
            qmaps[id] = path
         else:
            umaps[id] = path

         inbeam = get_fits_header( NDG(path), "INBEAM" )
         if not inbeam or ("pol" not in inbeam):
            raise starutil.InvalidParameterError("One of the {0} maps ({1}) "
                                          "was not created from POL2 data or "
                                          "is corrupt.".format(stokes,path))

         invoke("$KAPPA_DIR/ndftrace ndf={0} quiet".format(path) )
         units = get_task_par( "UNITS", "ndftrace" ).replace(" ", "")
         if units != "pW":
            raise starutil.InvalidParameterError("All supplied "
                 "maps must be in units of 'pW', but '{0}' has units '{1}'.".
                 format(path,units))



#  -----------  CREATE STOKES TIME SERIES FROM RAW DATA ------------------------


#  If any raw analysed intensity files were supplied, use smurf:calcqu to
#  convert them into Stokes paramater time-series files.
   if get_task_par( "RAWFOUND", "pol2check" ):
      msg_out( "Calculating Q, U and I time streams from raw analysed intensity data...")

#  Get a dict in which each key is an observation identifier of the form
#  <UT>_<OBS>, and each value is a list of raw data files for the observation.
      with open(inraws) as infile:
         lines = infile.readlines()
      paths = [line.strip() for line in lines]

      with open(rawinfo) as infile:
         lines = infile.readlines()
      infos = [line.strip() for line in lines]

      rawlist = {}
      for (path,id) in zip( paths, infos ):
         if id in rawlist:
            if path not in rawlist[id]:
               rawlist[id].append( path )
         else:
            rawlist[id] = [ path ]

#  Run calcqu separately on each observation.
      nobs = len(rawlist)
      iobs = 0
      for id in rawlist:
         iobs += 1

#  Create an NDG object holding the raw POL2 files for the current
#  observation.
         rawdata = NDG( rawlist[ id ] )

#  Use CALCQU to create the new Q, U and I time streams from the supplied
#  analysed intensity time streams. Put them in the QUDIR directory.
         new_q = NDG.tempfile()
         new_u = NDG.tempfile()
         new_i = NDG.tempfile()
         try:

#  If REUSE is TRUE and old Q, U and I time-streams exists, re-use them.
            try:
               if reuse:
                  w = filter // 100
                  aqts = NDG("{0}/s{2}a{1}\*_QT".format(qudir,id,w), True)
                  auts = NDG("{0}/s{2}a{1}\*_UT".format(qudir,id,w), True)
                  aits = NDG("{0}/s{2}a{1}\*_IT".format(qudir,id,w), True)
                  anq = len( aqts )
                  anu = len( auts )
                  ani = len( aits )
                  if anq != anu or anq != ani:
                     raise starutil.NoNdfError("Ignoring pre-existing data")

                  bqts = NDG("{0}/s{2}b{1}\*_QT".format(qudir,id,w), True)
                  buts = NDG("{0}/s{2}b{1}\*_UT".format(qudir,id,w), True)
                  bits = NDG("{0}/s{2}b{1}\*_IT".format(qudir,id,w), True)
                  bnq = len( bqts )
                  bnu = len( buts )
                  bni = len( bits )
                  if bnq != anq or bnu != anu or bni != ani:
                     raise starutil.NoNdfError("Ignoring pre-existing data")

                  cqts = NDG("{0}/s{2}c{1}\*_QT".format(qudir,id,w), True)
                  cuts = NDG("{0}/s{2}c{1}\*_UT".format(qudir,id,w), True)
                  cits = NDG("{0}/s{2}c{1}\*_IT".format(qudir,id,w), True)
                  cnq = len( cqts )
                  cnu = len( cuts )
                  cni = len( cits )
                  if cnq != anq or cnu != anu or cni != ani:
                     raise starutil.NoNdfError("Ignoring pre-existing data")

                  dqts = NDG("{0}/s{2}d{1}\*_QT".format(qudir,id,w), True)
                  duts = NDG("{0}/s{2}d{1}\*_UT".format(qudir,id,w), True)
                  dits = NDG("{0}/s{2}d{1}\*_IT".format(qudir,id,w), True)
                  dnq = len( dqts )
                  dnu = len( duts )
                  dni = len( dits )
                  if dnq != anq or dnu != anu or dni != ani:
                     raise starutil.NoNdfError("Ignoring pre-existing data")

                  msg_out("   Re-using previously created Q, U and I "
                          "time-streams for observation {0}".format(id))

                  with open(new_q, "w") as outfile:
                     for ndg in (aqts,bqts,cqts,dqts):
                        for ndf in ndg:
                           outfile.write(ndf+"\n")

                  with open(new_u, "w") as outfile:
                     for ndg in (auts,buts,cuts,duts):
                        for ndf in ndg:
                           outfile.write(ndf+"\n")

                  with open(new_i, "w") as outfile:
                     for ndg in (aits,bits,cits,dits):
                        for ndf in ndg:
                           outfile.write(ndf+"\n")

               else:
                  raise starutil.NoNdfError("Ignoring any pre-existing data")

#  Otherwise create new time-streams.
            except starutil.NoNdfError:
               msg_out("   {0}/{1}: Processing {2} raw data files from observation {3} ... ".
                       format(iobs,nobs,len(rawlist[ id ]), id ) )
               invoke("$SMURF_DIR/calcqu in={0} lsqfit=yes config=def outq={1}/\*_QT "
                      "outu={1}/\*_UT outi={1}/\*_IT fix=yes north={2} outfilesi={3} "
                      "outfilesq={4} outfilesu={5}".
                      format( rawdata, qudir, north, new_i, new_q, new_u ) )

#  Append the new Stokes parameter time series files created above to the
#  list of all Stokes parameter time series files.
            with open(allquis, 'a') as outfile:
               for fname in ( new_q, new_u, new_i ):
                   if os.path.isfile( fname ):
                       with open(fname) as infile:
                          outfile.write(infile.read())

         except starutil.AtaskError as err:
            msg_out( err )
            msg_out( "\nAn error occurred within CALCQU. The above observation will be ignored.\nContinuing to process any remaining observations...\n" )








#  -----------  CREATE INDIVIDUAL MAPS FROM STOKES TIME SERIES DATA ---------

#  Do some initialisation in case no time-series data is supplied.
   pcathresh_i = 0.0;
   pcathresh_qu = 0.0;

#  Initialise three dicts - one each for Q, U and I - holding Stokes
#  time-stream files to be processed.
   ilist = {}
   qlist = {}
   ulist = {}

#  Paths to config files.
   conf = NDG.tempfile()
   iconf = NDG.tempfile()
   quconf = NDG.tempfile()

#  If we have some Stokes parameter time-series files to process...
   if os.path.isfile(allquis):

#  Create a text file holding information about all the Stokes time-series
#  files to be processed. For each one, get the Stokes parameter (Q, U or I)
#  and a key that is unique for the chunk of data, of the form
#  "<UT>_<OBS>_<SUBSCAN>".
      stokesinfo = NDG.tempfile()
      quindg = NDG("^{0}".format(allquis) )
      invoke("$SMURF_DIR/pol2check in={0} quiet=yes stokesinfo={1}".
             format(quindg,stokesinfo))

#  Set up three dicts - one each for Q, U and I. Each key is as described
#  above. Each value is a list of paths for NDFs holding data with the same
#  key and the same Stokes parameter (Q, U or I).
      with open(allquis) as infile:
         lines = infile.readlines()
      paths = [line.strip() for line in lines]

      with open(stokesinfo) as infile:
         lines = infile.readlines()
      infos = [line.strip() for line in lines]

      for (path,info) in zip( paths, infos ):
         (stokes,id) = info.split()
         if stokes == "Q":
            if id in qlist:
               if path not in qlist[id]:
                  qlist[id].append( path )
            else:
               qlist[id] = [ path ]

         elif stokes == "U":
            if id in ulist:
               if path not in ulist[id]:
                  ulist[id].append( path )
            else:
               ulist[id] = [ path ]

         else:
            if id in ilist:
               if path not in ilist[id]:
                  ilist[id].append( path )
            else:
               ilist[id] = [ path ]

#  If required, generate the AST and PCA masks from the supplied MASK
#  map.
      if maskmap and masktype == "SIGNAL":
         snr = NDG(1)
         invoke("$KAPPA_DIR/makesnr in={0} out={1} minvar=0".format(maskmap,snr))

#  Very strong sources such as Orion A can create masks in which there
#  are insufficient background pixels to allow future invocations of
#  makemap to succeed. We therefore loop round raising the SNR limits for
#  the mask until no more than 20% of the originally good pixels are
#  designated as source pixels.
         invoke("$KAPPA_DIR/stats ndf={0}".format(snr))
         ngood = float( get_task_par( "numgood", "stats" ) )
         maxgood = ngood / 5

         noise = 2
         minheight = 3
         aconf = NDG.tempfile()

         while True:
            fd = open(aconf,"w")
            fd.write("FellWalker.FlatSlope=0\n")
            fd.write("FellWalker.MinDip=1.0E30\n")
            fd.write("FellWalker.Noise={0}\n".format(noise))
            fd.write("FellWalker.MinHeight={0}\n".format(minheight))
            fd.close()
            invoke("$CUPID_DIR/findclumps in={0} method=fellwalker rms=1 "
                   "outcat=! out={1} config=^{2}".format(snr,astmask,aconf))

            try:
               invoke("$KAPPA_DIR/stats ndf={0}".format(astmask))
               ngood = float( get_task_par( "numgood", "stats" ) )
            except starutil.AtaskError:
               raise starutil.InvalidParameterError( "No significant emission "
                               "found in total intensity map {0} supplied for "
                               "parameter MASK".format(maskmap))

            if ngood < maxgood:
               break
            else:
               if noise == minheight:
                  minheight *= 1.2
               noise = minheight

#  The source regions within the PCA mask need to be smaller than in the
#  AST mask. Make sure it uses no more than 10% of the original good
#  pixels.
         maxgood = ngood / 2

         noise = 3
         minheight = 5
         pconf = NDG.tempfile()

         while True:
            fd = open(pconf,"w")
            fd.write("FellWalker.FlatSlope=0\n")
            fd.write("FellWalker.MinDip=1.0E30\n")
            fd.write("FellWalker.Noise={0}\n".format(noise))
            fd.write("FellWalker.MinHeight={0}\n".format(minheight))
            fd.close()
            invoke("$CUPID_DIR/findclumps in={0} method=fellwalker rms=1 "
                   "outcat=! out={1} config=^{2}".format(snr,pcamask,pconf))

            try:
               invoke("$KAPPA_DIR/stats ndf={0}".format(pcamask))
               ngood = float( get_task_par( "numgood", "stats" ) )
            except starutil.AtaskError:
               ngood = 0
               pcamask = None

            if ngood < maxgood:
               break
            else:
               if noise == minheight:
                  minheight *= 1.2
               noise = minheight


#  We need to decide on the value to use for the PCA.PCATHRESH config
#  parameter when running makemap below. If a value is given in the
#  user-supplied config, use it.
      try:
         pcathresh = float( invoke("$KAPPA_DIR/configecho name=pca.pcathresh "
                                   "config={0}".format(config)) )
      except:
         pcathresh = 0

#  If no value is supplied in the config, the default values are -50
#  (pcathresh_def1) for auto-masked maps and -150 (pcathresh_def2) for
#  external-masked maps. However, for bright sources these default are
#  too high to allow convergence to be reached within a reasonable
#  number of iterations when creating the I maps (the Q and U maps
#  are easier since they are fainter, but for consistency we should
#  use the same value for Q and U as for I, even if convergence could
#  be achieved with a higher value of PCATHRESH). We look for any
#  existing maps in the mapdir, and re-use the same PCA.PCATHRESH value
#  if any are found.
      if pcathresh == 0:

#  Get the PCA.PCATHRESH value from the most recently created map (if any)
#  of the same type (auto or external mask) as the ones we are currently
#  creating.
         (pcathresh,tmap) = getPcaThresh( mapdir, automask )

#  If an existing map of the correct type was found, we use its PCATHRESH
#  value when creating maps below. Tell the user.
         if pcathresh != 0:
            msg_out("Will use PCA.PCATHRESH value of {0} inherited from existing "
                    "map {1}.".format(pcathresh,tmap))

#  If we are creating externally-masked maps, but no existing externally-masked
#  maps were found, see if any existing auto-masked maps can be found.
         elif not automask:
            (pcathresh,tmap) = getPcaThresh( mapdir, True )

#  If the PCATHRESH value used to create any auto-masked map was not equal
#  to the default value, then we use the same non-default value to create
#  the externally masked maps. Otherwise, we leave pcathresh set to zero to
#  indicate that makemap should determine a value for PCATHRESH itself by
#  repeatedly re-running with lower PCATHRESH values until a map converges.
            if pcathresh == pcathresh_def1:
               pcathresh = 0
            elif pcathresh != 0:
               msg_out("Will use PCA.PCATHRESH value of {0} inherited from existing "
                       "map {1}.".format(pcathresh,tmap))

#  If the user-supplied config includes a value for "modelorder", but
#  that value does not include PCA, we set "pcathresh" to a non-zero
#  value to indicate that the ABORTSOON parameter should not be set
#  when running makemap. The specific non-zero value used does not matter
#  as makemap will not be using it anyway (since modelorder order does
#  include PCA), but we choose to use the appropriate default value. Note,
#  if the user-supplied config does not include  a value for modelorder,
#  (i.e. configecho returns "<***>") then the default modelorder value
#  defined below (which includes PCA) will be used. In this case we want
#  to retain pcathresh at zero, so that ABORTSOON is used when running
#  makemap.
      if pcathresh == 0:
         try:
            models = invoke("$KAPPA_DIR/configecho name=modelorder "
                            "config={0}".format(config))
            if "<***>" not in models and "pca" not in models.lower():
               pcathresh = (pcathresh_def1 if automask else pcathresh_def2)
         except:
            pass

#  See if the ICONFIG or QUCONFIG configurations provide a value for
#  PCA.PCATHRESH, in which case it over-rides the above value.
      try:
         pcathresh_i = float( invoke("$KAPPA_DIR/configecho name=pca.pcathresh "
                                     "config={0}".format(iconfig)) )
      except:
         pcathresh_i = pcathresh

      try:
         pcathresh_qu = float( invoke("$KAPPA_DIR/configecho name=pca.pcathresh "
                                     "config={0}".format(quconfig)) )
      except:
         pcathresh_qu = pcathresh

#  Create a config file to use with makemap. This file contains stuff
#  that is used when creating both I maps and Q/U maps.
      fd = open(conf,"w")

#  Store the default set of config parameters in the config file.
      fd.write("^$STARLINK_DIR/share/smurf/.dimmconfig_pol2.lis\n")
      fd.write("numiter = -200\n")
      fd.write("modelorder = (com,gai,pca,ext,flt,ast,noi)\n")

      fd.write("maptol = 0.05\n")
      fd.write("maptol_mask = <undef>\n")
      fd.write("maptol_mean = 0\n")
      fd.write("maptol_box = 60\n")
      fd.write("maptol_hits = 1\n")

      fd.write("pca.pcathresh = {0}\n".format( pcathresh_def2 if (pcathresh==0) else pcathresh))
      fd.write("ast.mapspike_freeze = 5\n")
      fd.write("pca.zero_niter = 0.5\n")
      fd.write("com.zero_niter = 0.5\n")
      fd.write("flt.zero_niter = 0.5\n")
      fd.write("com.freeze_flags = 30\n")

#  Some depend on the masking type.
      if automask:
         fd.write("ast.skip = 10\n")
         fd.write("ast.zero_snr = 3\n")
         fd.write("ast.zero_snrlo = 2\n")
         fd.write("ast.zero_freeze = 0.2\n")

         fd.write("pca.pcathresh = {0}\n".format( pcathresh_def1 if (pcathresh==0) else pcathresh))
         fd.write("pca.zero_snr = 5\n")
         fd.write("pca.zero_snrlo = 3\n")
         fd.write("pca.zero_freeze = -1\n")

         fd.write("com.zero_snr = 5\n")
         fd.write("com.zero_snrlo = 3\n")
         fd.write("com.zero_freeze = -1\n")

         fd.write("flt.zero_snr = 5\n")
         fd.write("flt.zero_snrlo = 3\n")
         fd.write("flt.zero_freeze = -1\n")

      elif circlemask:
         fd.write("ast.zero_circle = (0.0083)\n")
         fd.write("pca.zero_circle = (0.0083)\n")
         fd.write("com.zero_circle = (0.0083)\n")
         fd.write("flt.zero_circle = (0.0083)\n")

      else:
         fd.write("ast.zero_mask = ref\n")
         if pcamask:
            pcamaskpar = "mask2={0}".format(pcamask)
            fd.write("pca.zero_mask = mask2\n")
            fd.write("com.zero_mask = mask2\n")
            fd.write("flt.zero_mask = mask2\n")

#  If the user supplied extra config parameters, append them to the
#  config file. Note, "config" will include any required "^" character and
#  so the format string below does not need to include an explicit "^"
#  character.
      if config and config != "def":
         fd.write("{0}\n".format(config))

#  Close the basic config file that contains stuff used when creating both
#  I and Q/U maps.
      fd.close()

#  We create two derived config files that inherit the above common config:
#  one for use when creating I maps and one for use when creating Q or U
#  maps. They may contain different values if the user supplies anything
#  for ICONFIG or QUCONFIG. First create the I config file.
      fd = open(iconf,"w")

#  Include the common config created above. Note, "conf" is a simple file
#  name - not a configuration - and so we need to include the "^" explicitly
#  in the format string.
      fd.write("^{0}\n".format(conf))

#  If the user has supplied any I-specific config parameters, include them
#  now so that they over-ride values in the common config. Note, "iconfig"
#  is a complete configuration, and so will already include any required "^"
#  character. So do not include a "^" in the format string.
      if iconfig and iconfig != "def":
         fd.write("{0}\n".format(iconfig))

#  Put in values that are absolutely required by this script. These
#  over-write any values in the user-supplied configs.
      fd.write("noi.usevar=1\n")
      fd.write("flagslow=0.01\n")
      fd.write("downsampscale=0\n")
      fd.close()

#  Create the QU config file in the same way. For Q and U maps, the
#  astronomical signal is much weaker and the common mode is much less
#  well defined. This can cause the COM model to throw out huge amounts
#  of data. To prevent, this disable common-mode flagging when creating
#  Q/U maps.
      fd = open(quconf,"w")
      fd.write("com.noflag=1\n")
      fd.write("^{0}\n".format(conf))
      if quconfig and quconfig != "def":
         fd.write("{0}\n".format(quconfig))
      fd.write("noi.usevar=1\n")
      fd.write("flagslow=0.01\n")
      fd.write("downsampscale=0\n")
      fd.close()




#  Loop over each Stokes parameter, creating maps from each observation
#  if reqired.
   for qui in ('I', 'Q', 'U'):

#  Pass on to the next parameter if we are not creating a map for the
#  current parameter. Also set up pointers to the arrays etc to use for
#  the current Stokes parameter.
      if qui == 'I':
         if imap:
            qui_maps = imaps
            qui_list = ilist
            conf = iconf
            coadd = imap
            pcathresh = pcathresh_i
            imap_cat = NDG(1)
            coadd_cat = imap_cat
         else:
            continue

      elif qui == 'Q':
         if qmap:
            qui_maps = qmaps
            qui_list = qlist
            conf = quconf
            coadd = qmap
            pcathresh = pcathresh_qu
            qmap_cat = NDG(1)
            coadd_cat = qmap_cat
         else:
            continue

      else:
         if umap:
            qui_maps = umaps
            qui_list = ulist
            conf = quconf
            coadd = umap
            pcathresh = pcathresh_qu
            umap_cat = NDG(1)
            coadd_cat = umap_cat
         else:
            continue

#  Loop over all the time series files for the current Stokes parameter. Each
#  separate observation will usually have one time series file (although
#  there may be more if the observation was split into two or more discontiguous
#  chunks). We form a map for each observation chunk present in the supplied
#  list of input raw data.
      for key in qui_list:

#  Get the Stokes time stream files for the current observation chunk.
         isdf = NDG( qui_list[ key ] )
         msg_out("\n>>>>   Making {1} map from {0}...\n".format(key,qui) )

#  AZ/EL pointing correction, for data between 20150606 and 20150930.
         ut = int(get_fits_header( isdf[0], "UTDATE", True ))
         if ut >= 20150606 and ut <= 20150929:
            pntfile = NDG.tempfile()
            fd = open(pntfile,"w")
            fd.write("# system=azel\n")
            fd.write("# tai dlon dlat\n")
            fd.write("54000 32.1 27.4\n")
            fd.write("56000 32.1 27.4\n")
            fd.close()
         else:
            pntfile = "!"

#  If an auto-masked I map from a previous run exists for the current
#  observation, see if it has pointing corrections recorded in its FITS
#  header. If so, we use them when creating the new map.
         try:
            hmap = NDG("{0}/{1}_imap".format(mapdir,key))
            dx = get_fits_header( hmap, "PNTRQ_DX" )
            dy = get_fits_header( hmap, "PNTRQ_DY" )
         except starutil.NoNdfError:
            dx = None
            dy = None

#  Create the pointing correction file to use when running makemap. If
#  a file is already in use (because of the data being old) append the
#  new pointing correction to the end of the file, preceeded by an
#  "end-of-table" Marker (two minus signs). Makemap will then apply
#  both correction.
         if dx is not None and dy is not None:
            dx = float( dx )
            dy = float( dy )
            if pntfile == "!":
               pntfile = NDG.tempfile()
               fd = open(pntfile,"w")
            else:
               fd = open(pntfile,"a")
               fd.write("--\n")

            fd.write("# system=tracking\n")
            fd.write("# tai dlon dlat\n")
            fd.write("54000 {0} {1}\n".format(dx,dy))
            fd.write("56000 {0} {1}\n".format(dx,dy))
            fd.close()

#  Get the path to the map.
         if automask:
            mapname = "{0}/{1}_{2}map".format(mapdir,key,qui.lower())
         else:
            mapname = "{0}/{1}_{2}map".format(mapdir,key,qui)

#  If REUSE is TRUE and an old map exists, re-use it.
         try:
            if reuse:
               qui_maps[key] = NDG(mapname, True)
               msg_out("   Re-using previously created map {0}".format(qui_maps[key]))
            else:
               raise starutil.NoNdfError("Ignoring pre-existing data")

#  Otherwise create a new map.  The call signature for makemap depends on
#  whether an external mask is being supplied or not.
         except starutil.NoNdfError:

            if dx is not None and dy is not None:
               msg_out( "   Using pre-calculated pointing corrections of ({0},{1}) arc-seconds".format(dx,dy) )

            qui_maps[key] = NDG(mapname, False)
            try:

#  If we are using the default value for PCA.PCATHRESH (as indicated by
#  pcathresh being zero), we need to look out for makemap not converging.
#  This can happen for very bright sources. If makemap fails to converge, we
#  try again using a smaller value for the PCA.PCATHRESH parameter. Once we
#  have found a value for PCA.PCATHRESH that allows convergence to be reached,
#  we use this same value for all subsequent maps. Set ABORTSOON=YES so that
#  makemap aborts as soon as it becomes clear that convergence will not be
#  reached in the allowed number of iterations. We only do this if variable
#  "pcathresh" is zero, indicating that no value has yet been determined for
#  PCA.PCATHRESH. We also require the NUMITER config parameter is negative
#  - i.e. MAPTOL defines convergence.
               sel =  "450=1,850=0" if ( filter == 450 ) else "450=0,850=1"
               numiter = float( invoke("$KAPPA_DIR/configecho name=numiter config=^{0} "
                                       "defaults=$SMURF_DIR/smurf_makemap.def "
                                       "select=\"\'{1}\'\"".format(conf,sel)))
               if pcathresh == 0 and numiter < 0:
                  pcathresh = pcathresh_def1 if automask else pcathresh_def2
                  abpar = "abortsoon=yes"
               else:
                  abpar = ""

               attempt = 0
               again = True
               while again:
                  attempt += 1

                  if not maskmap:
                     invoke("$SMURF_DIR/makemap in={0} config=^{1} out={2} ref={3} pointing={4} "
                         "{5} {6} {7}".format(isdf,conf,qui_maps[key],ref,pntfile,pixsize_par,ip,abpar))
                  else:
                     invoke("$SMURF_DIR/makemap in={0} config=^{1} out={2} ref={3} pointing={4} "
                         "{5} {6} {7} {8}".format(isdf,conf,qui_maps[key],astmask,pntfile,
                                                        pixsize_par,ip,pcamaskpar,abpar))

#  If we do not yet know what pcathresh value to use, see if makemap aborted
#  due to slow convergence. If so, reduce the number of PCA components
#  removed on each iteration by 25% and re-run makemap.
                  if abpar != "":
                     abortedat = int( float( get_task_par( "abortedat", "makemap" ) ) )
                     if abortedat == 0:
                        again = False
                        if attempt > 1:
                           msg_out( ">>>> MAKEMAP converged succesfully, so all further "
                                    "maps will be created using PCA.PCATHRESH={0}.".
                                    format( pcathresh ) )

                     elif attempt < 20:
                        reduction = int( -pcathresh * 0.25 )
                        if reduction < 2:
                           reduction = 2
                        pcathresh_old = pcathresh
                        pcathresh = -( -pcathresh - reduction )
                        if pcathresh > -5:
                           pcathresh = -5

                        if pcathresh <= pcathresh_old:
                           again = False
                           msg_out(">>>> MAKEMAP failed to converge but we have "
                                   "reached the lower limit for PCA.PCATHRESH, so "
                                   "all further maps will be created using "
                                   "PCA.PCATHRESH={0}.".format( pcathresh ) )
                        else:
                           msg_out(">>>> MAKEMAP failed to converge - trying "
                                   "the current observation again with "
                                   "PCA.PCATHRESH set to {0} (it was {1}).".
                                   format(pcathresh,pcathresh_old))
                           fd = open( conf, "a" )
                           fd.write( "pca.pcathresh = {0}\n".format( pcathresh ) )
                           fd.close()
                     else:
                        again = False
                        msg_out( ">>>> MAKEMAP failed to converge again - "
                                 "giving up and using PCA.PCATHRESH={0}.".
                                 format( pcathresh ) )

#  If we already knew the value to use for PCA.PCATHRESH, just proceeed without
#  checking convergence.
                  else:
                     again = False

#  Store FITS headers holding the pointing corrections that were actually used.
               if pntfile != "!":
                  sym = invoke("$KAPPA_DIR/wcsattrib ndf={0} mode=get name='Symbol(1)'".
                                     format(qui_maps[key]))
                  invoke("$KAPPA_DIR/fitsmod ndf={0} keyword=POINT_DX "
                         "edit=a value={1} comment=\"'Used {2} pointing correction [arcsec]'\""
                         " position=! mode=interface".format(qui_maps[key],dx,sym))

                  sym = invoke("$KAPPA_DIR/wcsattrib ndf={0} mode=get name='Symbol(2)'".
                               format(qui_maps[key]))
                  invoke("$KAPPA_DIR/fitsmod ndf={0} keyword=POINT_DY "
                         "edit=a value={1} comment=\"'Used {2} pointing correction [arcsec]'\""
                         " position=! mode=interface".format(qui_maps[key],dy,sym))


#  If makemap failed, warn the user and delete any map that was created,
#  and pass on to the next observation chunk.
            except starutil.AtaskError:
               msg_out("WARNING: makemap failed - could not produce a {1} map "
                       "for observation chunk {0}".format(key,qui) )
               try:
                  invoke("$KAPPA_DIR/erase object={0} ok=yes".format(qui_maps[key]))
               except starutil.AtaskError:
                  pass
               del qui_maps[key]
               if abpar != "":
                  pcathresh = 0
               continue

#  A map was obtained successfully. Add it to the list of maps in mapdir.
         new_maps.append( qui_maps[key] )













#  -----------  CREATE THE COADDED MAP FOR THE CURRENT STOKES PARAMETER -------------


#  Check some good maps remain to be processed.
      if len(qui_maps) == 0:
         raise starutil.InvalidParameterError("No usable {0} maps remains "
                                              "to be coadded.".format(qui))

#  If required, create a reference map that defines the WCS for the
#  catalogue grid, using a pixel size of BINSIZE.
      if outcat and binsize is not None and catref is None:
         key = list(qui_maps)[0]
         invoke("$KAPPA_DIR/ndftrace ndf={0} quiet".format(qui_maps[key]) )
         pxsize = float(get_task_par( "FPIXSCALE(1)", "ndftrace" ))
         if binsize < pxsize:
            raise starutil.InvalidParameterError("Requested catalogue bin "
                          "size ({0}) is smaller than the map pixel size "
                          "({1}).".format(binsize,pxsize))
         else:
            msg_out("The output vector catalogue will be based on maps "
                    "that are binned up to {0} arcsec pixels.".format(binsize))

         catref = NDG( 1 )
         invoke("$KAPPA_DIR/sqorst in={0} out={1} mode=pixelscale method=near "
                "pixscale=\"\'{2},{2},*\'\"".format(qui_maps[key],catref,binsize))


#  If we have only one observation just copy it to the output maps.
      if len(qui_maps) == 1:
         key = list(qui_maps)[0]
         invoke("$KAPPA_DIR/ndfcopy in={0} out={1}".format(qui_maps[key],coadd))

#  If required, bin it to the pixel size required by the catalogue.
         if catref:
            invoke("$KAPPA_DIR/wcsalign in={0} lbnd=! out={1} ref={2} "
                   "conserve=no method=sincsinc params=\[2,0\] rebin=yes".
                   format(qui_maps[key],coadd_cat,catref))
         elif outcat:
            invoke("$KAPPA_DIR/ndfcopy in={0} out={1}".format(coadd,coadd_cat))

#  If we have more than one observation, coadd them. Also coadd the
#  extension NDFs (EXP_TIMES and WEIGHTS), but without normalisation so
#  that the coadd is the sum rather than the mean of the inputs.
      elif len(qui_maps) > 1:

         msg_out("Coadding {0} maps from all observations:".format(qui))
         allmaps = NDG( list( qui_maps.values() ) )
         invoke("$KAPPA_DIR/wcsmosaic in={0} lbnd=! ref=! out={1} "
                "conserve=no method=near variance=yes genvar={2}".
                format(allmaps,coadd,mapvar))

         invoke("$KAPPA_DIR/erase object={0}.more.smurf.exp_time ok=yes".format(coadd))
         invoke("$KAPPA_DIR/wcsmosaic in={{{0}}}.more.smurf.exp_time lbnd=! ref=! "
                "out={1}.more.smurf.exp_time conserve=no method=bilin norm=no "
                "variance=no".format(allmaps,coadd))

         invoke("$KAPPA_DIR/erase object={0}.more.smurf.weights ok=yes".format(coadd))
         invoke("$KAPPA_DIR/wcsmosaic in={{{0}}}.more.smurf.weights lbnd=! ref=! "
                "out={1}.more.smurf.weights conserve=no method=bilin norm=no "
                "variance=no".format(allmaps,coadd))

#  If we are creating a binned up catalogue, bin the input observation maps
#  up to the required catalogue bin size, and then coadd them.
         if catref:
            catmaps = NDG(allmaps)
            invoke("$KAPPA_DIR/wcsalign in={0} lbnd=! out={1} ref={2} "
                   "conserve=no method=sincsinc params=\[2,0\] rebin=yes".
                   format(allmaps,catmaps,catref))
            invoke("$KAPPA_DIR/wcsmosaic in={0} lbnd=! ref=! out={1} "
                   "conserve=no method=near variance=yes genvar={2}".
                   format(catmaps,coadd_cat,mapvar))
         elif outcat:
            invoke("$KAPPA_DIR/ndfcopy in={0} out={1}".format(coadd,coadd_cat))









#  -----------  CALCULATE AND STORE POINTING CORRECTIONS IN NEW I MAPS ------------------------

#  If we have just created the coadd of all I maps, we determine the pointing
#  correct for each individual I map. This should give better results than
#  using the I map from an individual observation as the reference (which
#  is what was done prior to Feb 2018).
      if qui == 'I':

#  Choose the map with which to align each of the new I maps. We use the
#  external reference map if one was supplied. Otherwise we use the I mosaic
#  so long as it contains more than one observation (if there is only one
#  observation then the aligment is bound to be a unit transformation
#  because the mosaic and the individual map will be identical).
         if use_ref_for_alignment:
            aref = ref
         elif len(qui_maps) > 1 and imap:
            aref = imap
         else:
            aref = "!"

#  Loop round all observations.
         for key in qui_maps:

#  Can't align if we have no reference.
            if aref == "!":
               continue

#  See what translations (in pixels) are needed to align the new I map with
#  the reference map. The determination of the shift is more accurate if we
#  first mask out background areas. Use the AST mask to define source pixels,
#  but only if the mask contains a reasonable number of pixels (very faint
#  sources will have very small or non-existant AST masks).
            invoke("$KAPPA_DIR/showqual ndf={0}".format(qui_maps[key]))
            if get_task_par( "QNAMES(1)", "showqual" ) == "AST":
               bb = 1
            elif get_task_par( "QNAMES(2)", "showqual" ) == "AST":
               bb = 2
            elif get_task_par( "QNAMES(3)", "showqual" ) == "AST":
               bb = 4
            else:
               bb = 0

            if bb > 0:
               invoke("$KAPPA_DIR/setbb ndf={0} bb={1}".format(qui_maps[key],bb))

#  Clear badbits to use the whole map if the above masking results in too
#  few pixels, and instead mask the map to remove pixels that have less
#  than the mean exposure time per pixel.
            invoke("$KAPPA_DIR/stats ndf={0}".format(qui_maps[key]))
            nused = float( get_task_par( "numgood", "stats" ) )
            if nused < 400:
               invoke("$KAPPA_DIR/setbb ndf={0} bb=0".format(qui_maps[key]))
               invoke("$KAPPA_DIR/stats ndf={0}".format(qui_maps[key]))
               mean = float( get_task_par( "mean", "stats" ) )
               aligner = NDG(1)
               invoke( "$KAPPA_DIR/maths exp=\"'qif((ia.ge.pa),ib,<bad>'\" "
                       "ia={0}.more.smurf.exp_time ib={0} pa={1} out={2}".
                       format(qui_maps[key],mean,aligner) )
            else:
               aligner = qui_maps[key]

#  Find the pixel shift that aligns features in this masked, trimmed I map with
#  corresponding features in the reference map.
            try:
               invoke("$KAPPA_DIR/align2d ref={0} out=! in={1} form=3".
                      format(aref,aligner))
               dx = float( get_task_par( "TR(1)", "align2d" ) )
               dy = float( get_task_par( "TR(4)", "align2d" ) )

#  If align2d failed, use silly dx,dy values to ensure it is flagged by
#  the following code.
            except starutil.AtaskError:
               dx = 1E6
               dy = 1E6

#  Ensure the bad-bits mask has been reset.
            if bb > 0:
               invoke("$KAPPA_DIR/setbb ndf={0} bb=0".format(qui_maps[key]))

#  If the shifts are suspiciously high, we do not believe them. In which
#  case we cannot do pointing ocorrection when creating the Q and U maps.
            if abs(dx) > 8 or abs(dy) > 8:
               msg_out( "\nWARNING: {0}: The I map created from the POL2 data cannot "
                        "be aligned with the supplied reference map. Check the maps "
                        "for the current observation to see if they should be omitted "
                        "from the reduction.\n".format(key) )

#  Otherwise, convert the offset in pixels to (longitude,latitude) offsets
#  in the sky system of the reference map, in arc-seconds....
            else:

#  Strip the wavelength axis off the total intensity map created above.
               imap2d = NDG( 1 )
               invoke("$KAPPA_DIR/ndfcopy in={0} out={1} trim=yes".format(qui_maps[key],imap2d))

#  Get the pixel coords at the centre of the total intensity map.
               invoke("$KAPPA_DIR/ndftrace ndf={0}".format(imap2d))
               lbndx = float( get_task_par( "LBOUND(1)", "ndftrace" ) )
               lbndy = float( get_task_par( "LBOUND(2)", "ndftrace" ) )
               ubndx = float( get_task_par( "UBOUND(1)", "ndftrace" ) )
               ubndy = float( get_task_par( "UBOUND(2)", "ndftrace" ) )
               cenx = 0.5*( lbndx + ubndx )
               ceny = 0.5*( lbndy + ubndy )

#  Convert to SKY coords, in radians. Use ATOOLS rather than pyast in
#  order to avoid the need for people to install pyast. Also, ATOOLS
#  integrates with NDFs more easily than pyast.
               (cena,cenb) = invoke("$ATOOLS_DIR/asttran2 this={0} forward=yes "
                                    "xin={1} yin={2}".format( imap2d,cenx,ceny)).split()
               cena = float( cena )
               cenb = float( cenb )

#  Add on the pixel offsets, and convert to SKY coords, in radians.
               offx = cenx + dx
               offy = ceny + dy
               (offa,offb) = invoke("$ATOOLS_DIR/asttran2 this={0} forward=yes "
                                    "xin={1} yin={2}".format( imap2d,offx,offy)).split()
               offa = float( offa )
               offb = float( offb )

#   Now find the arc-distance parallel to the longitude axis, between the central
#   and offset positions, and convert from radians to arc-seconds.
               dx = invoke("$ATOOLS_DIR/astdistance this={0}, point1=\[{1},{2}\] "
                           "point2=\[{3},{4}\]".format(imap2d,cena,cenb,offa,cenb))
               dx = 3600.0*math.degrees( float( dx ) )

#  The value returned by astDistance is always positive. Adjust the sign
#  of dx so that it goes the right way.
               da = offa - cena
               while da > math.pi:
                  da -= math.pi
               while da < -math.pi:
                  da += math.pi
               if da < 0.0:
                  dx = -dx

#  Now find the arc-distance parallel to the latitude axis, between the central
#  and offset positions, and convert from radians to arc-seconds.
               dy = invoke("$ATOOLS_DIR/astdistance this={0}, point1=\[{1},{2}\] "
                           "point2=\[{3},{4}\]".format(imap2d,cena,cenb,cena,offb))
               dy = 3600.0*math.degrees( float( dy ) )

#  The value returned by astDistance is always positive. Adjust the sign
#  of dx so that it goes the right way.
               db = offb - cenb
               if db < 0.0:
                  dy = -dy
               msg_out( "{0}: Storing pointing corrections of ({1:5.1f},{2:5.1f}) "
                        "arc-seconds for future use".format(key,dx,dy) )

#  Store the required pointing corrections as FITS headers within the map.
               sym = invoke("$KAPPA_DIR/wcsattrib ndf={0} mode=get name='Symbol(1)'".
                                  format(qui_maps[key]))
               invoke("$KAPPA_DIR/fitsmod ndf={0} keyword=PNTRQ_DX "
                      "edit=a value={1} comment=\"'Required {2} pointing correction [arcsec]'\""
                      " position=! mode=interface".format(qui_maps[key],dx,sym))

               sym = invoke("$KAPPA_DIR/wcsattrib ndf={0} mode=get name='Symbol(2)'".
                            format(qui_maps[key]))
               invoke("$KAPPA_DIR/fitsmod ndf={0} keyword=PNTRQ_DY "
                      "edit=a value={1} comment=\"'Required {2} pointing correction [arcsec]'\""
                      " position=! mode=interface".format(qui_maps[key],dy,sym))









#  -----------  CREATE VECTOR CATALOGUE ------------------------


# The rest we only do if an output catalogue is reqired.
   if outcat:

#  We need I, Q and U maps to create a catalogue. TThe pixel size in
#  these maps will be equal to the value of parameter BINSIZE.
      if imap_cat and qmap_cat and umap_cat:

#  Ensure the Q, U and I images all have the same bounds, equal to the
#  overlap region between them. To get the overlap region, use MATHS to
#  add them together. Then use ndfcopy to produce the sections from each,
#  which match the overlap area.
         tmp = NDG( 1 )
         invoke( "$KAPPA_DIR/maths exp=\"'ia+ib+ic'\" ia={0} ib={1} ic={2} out={3}".
                 format(qmap_cat,umap_cat,imap_cat,tmp) )
         qtrim = NDG( 1 )
         invoke( "$KAPPA_DIR/ndfcopy in={0} like={1} out={2}".format(qmap_cat,tmp,qtrim) )
         utrim = NDG( 1 )
         invoke( "$KAPPA_DIR/ndfcopy in={0} like={1} out={2}".format(umap_cat,tmp,utrim) )
         itrim = NDG( 1 )
         invoke( "$KAPPA_DIR/ndfcopy in={0} like={1} out={2}".format(imap_cat,tmp,itrim) )

#  The polarisation vectors are calculated by the polpack:polvec command,
#  which requires the input Stokes vectors in the form of a 3D cube. Paste
#  the 2-dimensional Q, U and I images into a 3D cube.
         planes = NDG( [qtrim,utrim,itrim] )
         cube = NDG( 1 )
         invoke( "$KAPPA_DIR/paste in={0} shift=\[0,0,1\] out={1}".format(planes,cube))

#  The cube will have a 3D "POLANAL-SPECTRUM" WCS Frame, but POLVEC
#  requires a 2D POLANAL Frame. So use wcsframe to create the 2D Frame
#  from the 3D Frame, then delete the 3D Frame.
         invoke( "$KAPPA_DIR/wcsframe ndf={0} frame=POLANAL".format(cube) )
         invoke( "$KAPPA_DIR/wcsremove ndf={0} frame=POLANAL-SPECTRUM".format(cube) )

#  Re-instate SKY as the current Frame
         invoke( "$KAPPA_DIR/wcsframe ndf={0} frame=SKY".format(cube) )

#  POLPACK needs to know the order of I, Q and U in the 3D cube. Store
#  this information in the POLPACK enstension within "cube.sdf".
         invoke( "$POLPACK_DIR/polext in={0} stokes=qui".format(cube) )

#  If required, scale the I, Q and U values from pW to mJy/beam.
         if jy:
            tcube = NDG( 1 )
            invoke( "$KAPPA_DIR/cmult in={0} out={1} scalar={2}".
                    format(cube,tcube,1000*fcf) )
            invoke( "$KAPPA_DIR/setunits ndf={0} units=mJy/beam".format(tcube))
            cube = tcube

#  Create a FITS catalogue containing the polarisation vectors.
         msg_out( "Creating the output catalogue: '{0}'...".format(outcat) )
         msg = invoke( "$POLPACK_DIR/polvec {0} cat={1} debias={2} "
                       "radec=yes refupdate=no".format(cube,outcat,debias) )
         msg_out( "\n{0}\n".format(msg) )



#  -----------  TIDY UP ------------------------

#  Save the paths to any new single observation maps created above.
   if newmaps:
      with open(newmaps, "w") as fd:
         for path in new_maps:
            fd.write("{0}\n".format(path))

#  Remove temporary files.
   cleanup()

#  If an StarUtilError of any kind occurred, display the message but hide the
#  python traceback. To see the trace back, uncomment "raise" instead.
except starutil.StarUtilError as err:
#  raise
   print( err )
   print( "See the end of the log file ({0}) for further details.".format(starutil.logfile) )
   cleanup()

# This is to trap control-C etc, so that we can clean up temp files.
except:
   cleanup()
   raise





