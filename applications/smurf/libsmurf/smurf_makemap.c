/*
*+
*  Name:
*     MAKEMAP

*  Purpose:
*     Top-level MAKEMAP implementation

*  Language:
*     Starlink ANSI C

*  Type of Module:
*     ADAM A-task

*  Invocation:
*     smurf_makemap( int *status );

*  Arguments:
*     status = int* (Given and Returned)
*        Pointer to global status.

*  Description:
*     This is the main routine implementing the MAKEMAP task.

*  ADAM Parameters:
*     ALIGNSYS = _LOGICAL (Read)
*        If TRUE, then the spatial positions of the input data are
*        aligned in the co-ordinate system specified by parameter
*        SYSTEM. Otherwise, they are aligned in the ICRS co-ordinate
*        system. For instance, if the output co-ordinate system is
*        AZEL, then setting ALIGNSYS to TRUE will result in the AZEL
*        values of the input data positions being compared directly,
*        disregarding the fact that a given AZEL will correspond to
*        different positions on the sky at different times. [FALSE]
*     CONFIG = GROUP (Read) 
*        Specifies values for the configuration parameters used by the
*        iterative map maker (METHOD=ITERATE). If the string "def"
*        (case-insensitive) or a null (!) value is supplied, a set of
*        default configuration parameter values will be used.
*
*        The supplied value should be either a comma-separated list of strings 
*        or the name of a text file preceded by an up-arrow character
*        "^", containing one or more comma-separated list of strings. Each
*        string is either a "keyword=value" setting, or the name of a text 
*        file preceded by an up-arrow character "^". Such text files should
*        contain further comma-separated lists which will be read and 
*        interpreted in the same manner (any blank lines or lines beginning 
*        with "#" are ignored). Within a text file, newlines can be used
*        as delimiters as well as commas. Settings are applied in the order 
*        in which they occur within the list, with later settings over-riding 
*        any earlier settings given for the same keyword.
*
*        Each individual setting should be of the form:
*
*           <keyword>=<value>
*        
*        The parameters available for are listed in the "Configuration
*        Parameters" sections below. Default values will be used for
*        any unspecified parameters. Unrecognised options are ignored
*        (that is, no error is reported). [current value]
*     CROTA = _REAL (Read)
*          Only accessed if a null value is supplied for parameter REF.
*          The angle, in degrees, from north through east (in the
*          coordinate system specified by the SYSTEM parameter) to the second
*          pixel axis in the output cube. 
*     FBL( ) = _DOUBLE (Write)
*          Sky coordinates (radians) of the bottom left corner of the output map
*          (the corner with the smallest PIXEL dimension for axis 1 and the smallest
*          pixel dimension for axis 2). No check is made that the pixel corresponds
*          valid data. Note that the position is reported for the centre of the pixel.
*     FBR( ) = _DOUBLE (Write)
*          Sky coordinates (radians) of the bottom right corner of the output map
*          (the corner with the largest PIXEL dimension for axis 1 and the smallest
*          pixel dimension for axis 2). No check is made that the pixel corresponds
*          valid data. Note that the position is reported for the centre of the pixel.
*     FLBND( ) = _DOUBLE (Write)
*          The lower bounds of the bounding box enclosing the output map in the
*          selected output WCS Frame. The values are calculated even if no output
*          cube is created. Celestial axis values will be in units of radians.
*          The parameter is named to be consistent with KAPPA NDFTRACE output.
*     FUBND( ) = _DOUBLE (Write)
*          The upper bounds of the bounding box enclosing the output map in the
*          selected output WCS Frame. The values are calculated even if no output
*          cube is created. Celestial axis values will be in units of radians.
*          The parameter is named to be consistent with KAPPA NDFTRACE output.
*     FTL( ) = _DOUBLE (Write)
*          Sky coordinates (radians) of the top left corner of the output map
*          (the corner with the smallest PIXEL dimension for axis 1 and the largest
*          pixel dimension for axis 2). No check is made that the pixel corresponds
*          valid data. Note that the position is reported for the centre of the pixel.
*     FTR( ) = _DOUBLE (Write)
*          Sky coordinates (radians) of the top right corner of the output map
*          (the corner with the largest PIXEL dimension for axis 1 and the largest
*          pixel dimension for axis 2). No check is made that the pixel corresponds
*          valid data. Note that the position is reported for the centre of the pixel.
*     IN = NDF (Read)
*          Input file(s)
*     LBND( 2 ) = _INTEGER (Read)
*        An array of values giving the lower pixel index bound on each
*        spatial axis of the output NDF. The suggested default values 
*        encompass all the input spatial information. []
*     LBOUND( 2 ) = _INTEGER (Write)
*          The lower pixel bounds of the output NDF. Note, values will be
*          written to this output parameter even if a null value is supplied 
*          for parameter OUT.
*     METHOD = LITERAL (Read)
*          Specify which map maker should be used to construct the map. The
*          parameter can take the following values:
*          - "REBIN" -- Use a single pass rebinning algorithm. This
*          technique assumes that the data have previously had
*          atmosphere and instrument signatures removed. It makes use
*          of the standard AST library rebinning algorithms (see also
*          KAPPA WCSMOSAIC). It's an excellent choice for obtaining an
*          image quickly, especially of a bright source.
*          - "ITERATE" -- Use the iterative map maker. This map maker
*          is much slower than the REBIN algorithm because it
*          continually makes a map, constructs models for different
*          data components (common-mode, spikes etc).
*     NTILE = _INTEGER (Write)
*          The number of output tiles used to hold the entire output
*          array (see parameter TILEDIMS). If no input data falls within
*          a specified tile, then no output NDF will be created for the
*          tile, but the tile will still be included in the tile numbering 
*     OUT = NDF (Write)
*          Output file
*     PARAMS( 2 ) = _DOUBLE (Read)
*          An optional array which consists of additional parameters
*          required by the Sinc, SincSinc, SincCos, SincGauss, Somb,
*          SombCos, and Gauss spreading methods (see parameter SPREAD).
*	   
*          PARAMS( 1 ) is required by all the above schemes. It is used to 
*          specify how many pixels on either side of the output position
*          (that is, the output position corresponding to the centre of the 
*          input pixel) are to receive contributions from the input pixel.
*          Typically, a value of 2 is appropriate and the minimum allowed 
*          value is 1 (i.e. one pixel on each side). A value of zero or 
*          fewer indicates that a suitable number of pixels should be 
*          calculated automatically. [0]
*	   
*          PARAMS( 2 ) is required only by the SombCos, Gauss, SincSinc, 
*          SincCos, and SincGauss schemes.  For the SombCos, SincSinc, and
*          SincCos schemes, it specifies the number of pixels at which the
*          envelope of the function goes to zero.  The minimum value is
*          1.0, and the run-time default value is 2.0.  For the Gauss and
*          SincGauss scheme, it specifies the full-width at half-maximum
*          (FWHM) of the Gaussian envelope.  The minimum value is 0.1, and
*          the run-time default is 1.0.  On astronomical images and 
*          spectra, good results are often obtained by approximately 
*          matching the FWHM of the envelope function, given by PARAMS(2),
*          to the point-spread function of the input data.
*     PIXSIZE( 2 ) = _REAL (Read)
*          Pixel dimensions in the output image, in arcsec. If only one value 
*          is supplied, the same value will be used for both axes.
*     REF = NDF (Read)
*          An existing NDF that is to be used to define the output grid.
*          If supplied, the output grid will be aligned with the supplied 
*          reference NDF. The reference can be either 2D or 3D and the spatial
*          frame will be extracted. If a null (!) value is supplied then the output
*          grid is determined by parameters REFLON, REFLAT, etc. [!]
*     REFLAT = LITERAL (Read)
*          The formatted celestial latitude value at the tangent point of 
*          the spatial projection in the output cube. This should be provided 
*          in the system specified by parameter SYSTEM. 
*     REFLON = LITERAL (Read)
*          The formatted celestial longitude value at the tangent point of 
*          the spatial projection in the output cube. This should be provided 
*          in the system specified by parameter SYSTEM. 
*     SPREAD = LITERAL (Read)
*          The method to use when spreading each input pixel value out
*          between a group of neighbouring output pixels. If SPARSE is set 
*          TRUE, then SPREAD is not accessed and a value of "Nearest" is
*          always assumed. SPREAD can take the following values:
*	   
*          - "Linear" -- The input pixel value is divided bi-linearly between 
*          the four nearest output pixels.  Produces smoother output NDFs than 
*          the nearest-neighbour scheme.
*	   
*          - "Nearest" -- The input pixel value is assigned completely to the
*          single nearest output pixel. This scheme is much faster than any
*          of the others. 
*	   
*          - "Sinc" -- Uses the sinc(pi*x) kernel, where x is the pixel
*          offset from the interpolation point (resampling) or transformed
*          input pixel centre (rebinning), and sinc(z)=sin(z)/z.  Use of 
*          this scheme is not recommended.
*	   
*          - "SincSinc" -- Uses the sinc(pi*x)sinc(k*pi*x) kernel. A
*          valuable general-purpose scheme, intermediate in its visual
*          effect on NDFs between the bi-linear and nearest-neighbour
*          schemes. 
*	   
*          - "SincCos" -- Uses the sinc(pi*x)cos(k*pi*x) kernel.  Gives
*          similar results to the "Sincsinc" scheme.
*	   
*          - "SincGauss" -- Uses the sinc(pi*x)exp(-k*x*x) kernel.  Good 
*          results can be obtained by matching the FWHM of the
*          envelope function to the point-spread function of the
*          input data (see parameter PARAMS).
*	   
*          - "Somb" -- Uses the somb(pi*x) kernel, where x is the pixel
*          offset from the transformed input pixel centre, and 
*          somb(z)=2*J1(z)/z (J1 is the first-order Bessel function of the 
*          first kind.  This scheme is similar to the "Sinc" scheme.
*	   
*          - "SombCos" -- Uses the somb(pi*x)cos(k*pi*x) kernel.  This
*          scheme is similar to the "SincCos" scheme.
*	   
*          - "Gauss" -- Uses the exp(-k*x*x) kernel. The FWHM of the Gaussian 
*          is given by parameter PARAMS(2), and the point at which to truncate 
*          the Gaussian to zero is given by parameter PARAMS(1).
*	   
*          For further details of these schemes, see the descriptions of 
*          routine AST_REBINx in SUN/211. ["Nearest"]
*     SYSTEM = LITERAL (Read)
*          The celestial coordinate system for the output cube. One of
*          ICRS, GAPPT, FK5, FK4, FK4-NO-E, AZEL, GALACTIC, ECLIPTIC. It
*          can also be given the value "TRACKING", in which case the
*          system used will be which ever system was used as the tracking
*          system during in the observation.
*
*          The choice of system also determines if the telescope is 
*          considered to be tracking a moving object such as a planet or 
*          asteroid. If system is GAPPT or AZEL, then each time slice in
*          the input data will be shifted in order to put the base
*          telescope position (given by TCS_AZ_BC1/2 in the JCMTSTATE
*          extension of the input NDF) at the same pixel position that it
*          had for the first time slice. For any other system, no such 
*          shifts are applied, even if the base telescope position is
*          changing through the observation. [TRACKING]
*     TRIMTILES = _LOGICAL (Read)
*          Only accessed if the output is being split up into more than
*          one spatial tile (see parameter TILEDIMS). If TRUE, then the 
*          tiles around the border will be trimmed to exclude areas that 
*          fall outside the bounds of the full sized output array. This
*          will result in the border tiles being smaller than the central 
*          tiles. [FALSE]
*     TILEBORDER = _INTEGER (Read)
*          Only accessed if a non-null value is supplied for parameter
*          TILEDIMS. It gives the width, in pixels, of a border to add to
*          each output tile. These borders contain data from the adjacent
*          tile. This results in an overlap between adjacent tiles equal to
*          twice the supplied border width. If the default value of zero 
*          is accepted, then output tiles will abut each other in pixel
*          space without any overlap. If a non-zero value is supplied,
*          then each pair of adjacent tiles will overlap by twice the 
*          given number of pixels. Pixels within the overlap border will
*          be given a quality name of "BORDER" (see KAPPA:SHOWQUAL). [0]
*     TILEDIMS( 2 ) = _INTEGER (Read)
*          For large data sets, it may sometimes be beneficial to break 
*          the output array up into a number of smaller rectangular tiles, 
*          each created separately and stored in a separate output NDF. This 
*          can be accomplished by supplying non-null values for the TILEDIMS 
*          parameter. If supplied, these values give the spatial size of each 
*          output tile, in pixels. If only one value is supplied, the
*          supplied value is duplicated to create square tiles. Tiles are
*          created in a raster fashion, from bottom left to top right of
*          the spatial extent. The NDF file name specified by "out" is
*          modified for each tile by appending "_<N>" to the end of it, 
*          where <N> is the integer tile index (starting at 1). The
*          number of tiles used to cover the entire output cube is written 
*          to output parameter NTILES. The tiles all share the same 
*          projection and so can be simply pasted together in pixel 
*          coordinates to reconstruct the full size output array. The tiles 
*          are centred so that the reference position (given by REFLON and 
*          REFLAT) falls at the centre of a tile. If a tile receives no
*          input data, then no corresponding output NDF is created, but 
*          the tile is still included in the tile numbering scheme. If a 
*          null (!) value is supplied for TILEDIMS, then the 
*          entire output array is created as a single tile and stored in 
*          a single output NDF with the name given by parameter OUT 
*          (without any "_<N>" appendix). [!]
*     UBND( 2 ) = _INTEGER (Read)
*        An array of values giving the upper pixel index bound on each
*        spatial axis of the output NDF. The suggested default values 
*        encompass all the input spatial information. []
*     UBOUND( 2 ) = _INTEGER (Write)
*          The upper pixel bounds of the output NDF. Note, values will be
*          written to this output parameter even if a null value is supplied 
*          for parameter OUT.

*  Iterative MapMaker Configuration Parameters:
*     The following configuration parameters are available for the iterative
*     map maker:
*          - "NUMITER"
*          - "MODELORDER"

*  Authors:
*     Tim Jenness (JAC, Hawaii)
*     Andy Gibb (UBC)
*     Edward Chapin (UBC)
*     David Berry (JAC, UCLan)
*     {enter_new_authors_here}

*  History:
*     2005-09-27 (EC):
*        Clone from smurf_extinction
*     2005-12-16 (EC):
*        Working for simple test case with astRebinSeq 
*     2006-01-04 (EC):
*        Properly setting rebinflags
*     2006-01-13 (EC):
*        Automatically determine map size
*        Use VAL__BADD for pixels with no data in output map
*     2006-01-25 (TIMJ):
*        Replace malloc with smf_malloc.
*     2006-01-25 (TIMJ):
*        sc2head is now embedded in smfHead.
*     2006-01-27 (TIMJ):
*        - Try to jump out of loop if status bad.
*        - sc2head is now a pointer again
*     2006-02-02 (EC):
*        - Broke up mapbounds/regridding into subroutines smf_mapbounds and
*          smf_rebinmap
*        - fits header written to output using ndfputwcs
*     2006-03-23 (AGG):
*        Update to take account of new API for rebinmap
*     2006-03-23 (DSB):
*        Guard against null pointer when reporting error.
*     2006-04-21 (AGG):
*        Now calls sky removal and extinction correction routines.
*     2006-05-24 (AGG):
*        Check that the weights array pointer is not NULL
*     2006-05-25 (EC):
*        Add iterative map-maker + associated command line parameters
*     2006-06-24 (EC):
*        Iterative map-maker parameters given in CONFIG file
*     2006-08-07 (TIMJ):
*        GRP__NOID is not a Fortran concept.
*     2006-08-21 (JB):
*        Write data, variance, and weights using smfData structures
*     2006-08-22 (JB):
*        Add odata for output, add smf_close_file for odata.
*     2006-10-11 (AGG):
*        - Update to new API for smf_open_newfile, remove need for dims array
*        - Remove calls to subtract sky and correct for extinction
*     2006-10-12 (JB):
*        Use bad bolometer mask if supplied; add usebad flag
*     2006-12-18 (AGG):
*        Fix incorrect indf declaration, delete ogrp if it exists
*     2007-01-12 (AGG):
*        Add SYSTEM parameter for specifying output coordinate system
*     2007-01-25 (AGG):
*        Update API in calls to smf_mapbounds and smf_rebinmap
*     2007-02-06 (AGG):
*        Add uselonlat flag rather that specify hard-wired value in
*        smf_mapbounds
*     2007-03-05 (EC):
*        Changed smf_correct_extinction interface
*     2007-03-20 (TIMJ):
*        Write an output FITS header
*     2007-06-22 (TIMJ):
*        Rework to handle PRV* as well as OBS*
*     2007-07-05 (TIMJ):
*        Fix provenance file name handling.
*     2007-07-12 (EC):
*        Add moving to smf_bbrebinmap interface
*        Add moving to smf_calc_mapcoord interface
*     2007-10-29 (EC):
*        Modified interface to smf_open_file.
*     2007-11-15 (EC):
*        Modified smf_iteratemap interface.
*     2007-11-28 (EC):
*        Fixed flag in smf_open_file
*     2008-01-22 (EC):
*        Added hitsmap to smf_iteratemap interface
*     2008-02-12 (AGG):
*        - Update to reflect new API for smf_rebinmap
*        - Note smf_bbrebinmap is now deprecated
*        - Remove sky subtraction and extinction calls
*     2008-02-13 (AGG):
*        Add SPREAD and PARAMS parameters to allow choice of
*        pixel-spreading scheme, update call to smf_rebinmap
*     2008-02-15 (AGG):
*        Expand number of dimensions for weights array if using REBIN
*     2008-02-18 (AGG):
*        - Check for all ADAM parameters before call to smf_mapbounds
*        - Change weightsloc to smurfloc
*        - Add EXP_TIME component to output file
*     2008-02-19 (AGG):
*        - Add status check before attempting to access hitsmap pointer
*        - Set exp_time values to BAD if no data exists for that pixel
*     2008-02-20 (AGG):
*        Calculate median exposure time and write FITS entry
*     2008-03-11 (AGG):
*        Update call to smf_rebinmap
*     2008-04-01 (AGG):
*        Write WCS to EXP_TIME component in output file
*     2008-04-02 (AGG):
*        Write 2-D WEIGHTS component + WCS in output file, protect
*        against attempting to access NULL smfFile pointer
*     2008-04-22 (AGG):
*        Use faster histogram-based method for calculating median
*        exposure time
*     2008-04-23 (DSB):
*        Modify call to kpg1Ghstd to pass max and min values by reference
*        rather than by value.
*     2008-04-24 (EC):
*        Added MAXMEM parameter, memory checking for output map
*     2008-05-01 (TIMJ):
*        - Use BAD in EXP_TIME when no integration time.
*        - Tidy up some status logic.
*        - Add units and label to output file.
*     2008-05-02 (EC):
*        - Added mapbounds timing message
*     2008-05-03 (EC):
*        - In provenance loop for iterate use READ instead of UPDATE
*     2008-05-14 (EC):
*        Added projection functionality cloned from smurf_makecube. See 
*        ADAM parameters: PIXSIZE, REFLAT, REFLON, [L/U]BND/BOUND.
*     2008-05-15 (EC):
*        - Trap SMF__NOMEM from smf_checkmem_map; request new [L/U]BND
*        - Set [L/U]BOUND
*        - Fix read error caused by status checking in for loop
*     2008-05-26 (EC):
*        - changed default map size to use ~50% of memory if too big
*        - handle OUT=! case to test map size
*        - started adding tiling infrastructure: NTILE + TILEDIMS
*        - check for minimum numbin for histogram
*     2008-05-28 (TIMJ):
*        "Proper" provenance propagation.
*     2008-05-29 (EC):
*        Don't call smf_checkmem_map if OUT=!
*     2008-06-02 (EC):
*        Handle 1-element TILEDIMS
*     2008-06-04 (TIMJ):
*        - Calculate and free smfBox in smf_mapbounds
*        - Handle pixel bounds in smf_mapbounds.
*        - Use smf_store_outputbounds and document new F* parameters.
*     2008-06-05 (TIMJ):
*        - Add ALIGNSYS parameter.
*        - Add REF parameter.
*     2008-06-06 (TIMJ):
*        - support TILES in REBIN mode
*        - use smf_find_median
*        - new interface to smf_open_ndfname
*     2008-07-11 (TIMJ):
*        use strlcat
*     2008-07-22 (AGG):
*        Refactor provenance handling loop, initialize spread
*        parameter to AST__NEAREST
*     2008-07-25 (TIMJ):
*        Filter out darks. Use kaplibs.
*     2008-07-29 (TIMJ):
*        Steptime is now in smfHead.
*     2008-08-22 (AGG):
*        Check coordinate system before writing frameset to output
*        file and set attributes for moving sources accordingly
*     {enter_further_changes_here}

*  Copyright:
*     Copyright (C) 2005-2007 Particle Physics and Astronomy Research
*     Council. Copyright (C) 2005-2008 University of British Columbia.
*     Copyright (C) 2007-2008 Science and Technology Facilities Council.
*     All Rights Reserved.

*  Licence:
*     This program is free software; you can redistribute it and/or
*     modify it under the terms of the GNU General Public License as
*     published by the Free Software Foundation; either version 3 of
*     the License, or (at your option) any later version.
*
*     This program is distributed in the hope that it will be
*     useful,but WITHOUT ANY WARRANTY; without even the implied
*     warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
*     PURPOSE. See the GNU General Public License for more details.
*
*     You should have received a copy of the GNU General Public
*     License along with this program; if not, write to the Free
*     Software Foundation, Inc., 59 Temple Place,Suite 330, Boston,
*     MA 02111-1307, USA

*  Bugs:
*     {note_any_bugs_here}
*-
*/

#if HAVE_CONFIG_H
#include <config.h>
#endif

#include <string.h>
#include <stdio.h>
#include <sys/time.h>
#include <time.h>
#include <math.h>

/* STARLINK includes */
#include "ast.h"
#include "mers.h"
#include "par.h"
#include "par_par.h"
#include "prm_par.h"
#include "ndf.h"
#include "sae_par.h"
#include "star/hds.h"
#include "star/ndg.h"
#include "star/grp.h"
#include "star/kaplibs.h"
#include "star/atl.h"
#include "star/one.h"

/* SMURF includes */
#include "smurf_par.h"
#include "smurflib.h"
#include "libsmf/smf.h"
#include "libsmf/smf_err.h"
#include "smurf_typ.h"

#include "sc2da/sc2store_par.h"
#include "sc2da/sc2math.h"
#include "sc2da/sc2store.h"
#include "sc2da/sc2ast.h"

#include "libsc2sim/sc2sim.h"

#define FUNC_NAME "smurf_makemap"
#define TASK_NAME "MAKEMAP"
#define LEN__METHOD 20

void smurf_makemap( int *status ) {

  /* Local Variables */
  int alignsys;              /* Align data in the output system? */
  const char *astsys = NULL; /* Name of AST-supported coordinate system */
  char basename[ GRP__SZNAM + 1 ]; /* Output base file name */
  int blank=0;                 /* Was a blank line just output? */
  smfBox *boxes = NULL;      /* Pointer to array of i/p file bounding boxes */
  Grp *confgrp = NULL;       /* Group containing configuration file */
  smfArray *darks = NULL;   /* Dark data */
  smfData *data=NULL;        /* Pointer to SCUBA2 data struct */
  char data_units[SMF__CHARLABEL+1]; /* Units string */
  double *exp_time = NULL;    /* Exposure time array written to output file */
  AstFitsChan *fchan = NULL; /* FitsChan holding output NDF FITS extension */
  Grp * fgrp = NULL;         /* Filtered group, no darks */
  smfFile *file=NULL;        /* Pointer to SCUBA2 data file struct */
  int first;                 /* Is this the first input file? */
  int *histogram = NULL;     /* Histogram for calculating exposure statistics */
  unsigned int *hitsmap;     /* Hitsmap array calculated in ITERATE method */
  dim_t i;                   /* Loop counter */
  int ifile;                 /* Input file index */
  Grp *igrp = NULL;          /* Group of input files */
  Grp *igrp4 = NULL;         /* Group holding output NDF names */
  int ilast;                 /* Index of the last input file */
  int iout;                  /* Index of next output NDF name */
  int ipbin=0;               /* Index of current polarisation angle bin */
  int iterate=0;             /* Flag to denote ITERATE method */
  size_t itile;              /* Output tile index */
  int jin;                   /* Input NDF index within igrp */
  AstKeyMap *keymap=NULL;    /* Pointer to keymap of config settings */
  size_t ksize=0;            /* Size of group containing CONFIG file */
  int lbnd_out[2];           /* Lower pixel bounds for output map */
  double *map=NULL;          /* Pointer to the rebinned map data */
  size_t mapmem=0;           /* Memory needed for output map */
  size_t maxmem=0;           /* Max memory usage in bytes */
  int maxmem_mb;             /* Max memory usage in Mb */
  double maxtexp = 0.0;      /* Maximum exposure time */
  float medtexp = 0.0;       /* Median exposure time */
  char method[LEN__METHOD];  /* String for map-making method */
  int moving = 0;            /* Is the telescope base position changing? */
  int nparam = 0;            /* Number of extra parameters for pixel spreading*/
  size_t ntile;              /* Number of output tiles */
  int nval;                  /* Number of parameter values supplied */
  size_t nxy;                /* Number of pixels in output image */
  smfData *odata=NULL;       /* Pointer to output SCUBA2 data struct */
  Grp *ogrp = NULL;          /* Group containing output file */
  int ondf = NDF__NOID;      /* output NDF identifier */
  size_t outsize;            /* Number of files in output group */
  AstFrameSet *outfset=NULL; /* Frameset containing sky->output mapping */
  char pabuf[ 10 ];          /* Text buffer for parameter value */
  double params[ 4 ];        /* astRebinSeq parameters */
  char *pname = NULL;        /* Name of currently opened data file */
  int ***ptime = NULL;       /* Holds time slice indices for each bol bin */
  int *pt = NULL;            /* Holds time slice indices for each bol bin */
  int rebin=1;               /* Flag to denote whether to use the REBIN method*/
  size_t size;               /* Number of files in input group */
  int smfflags=0;            /* Flags for smfData */
  HDSLoc *smurfloc=NULL;     /* HDS locator of SMURF extension */
  AstFrameSet *spacerefwcs = NULL;/* WCS Frameset for spatial reference axes */
  AstFrameSet *specrefwcs = NULL;/* WCS Frameset for spectral reference axis */
  int spread = AST__NEAREST; /* Code for pixel spreading scheme */
  double steptime = VAL__BADD; /* Integration time per sample, from FITS header */
  char system[10];           /* Celestial coordinate system for output image */
  smfData *tdata=NULL;       /* Exposure time data */
  int tileborder;            /* Dimensions (in pixels) of tile overlap */
  int tiledims[2];           /* Dimensions (in pixels) of each output tile */
  smfTile *tile = NULL;      /* Pointer to next output tile description */
  smfTile *tiles=NULL;       /* Pointer to array of output tile descriptions */
  int trimtiles;             /* Trim the border tiles to exclude bad pixels? */
  AstMapping *tskymap = NULL;/* GRID->SkyFrame Mapping from output tile WCS */
  int ubnd_out[2];           /* Upper pixel bounds for output map */
  void *variance=NULL;       /* Pointer to the variance map */
  smfData *wdata=NULL;       /* Pointer to SCUBA2 data struct for weights */
  double *weights=NULL;      /* Pointer to the weights map */
  double *weights3d = NULL;  /* Pointer to 3-D weights array */
  AstFrameSet *wcstile2d = NULL;/* WCS Frameset describing 2D spatial axes */
  int wndf = NDF__NOID;      /* NDF identifier for WEIGHTS */

  struct timeval tv1, tv2;

  if (*status != SAI__OK) return;

  /* initialisation */
  data_units[0] = '\0';

  /* Main routine */
  ndfBegin();

  /* Get group of input files */
  kpg1Rgndf( "IN", 0, 1, "", &igrp, &size, status );

  /* Filter out darks */
  smf_find_darks( igrp, &fgrp, NULL, 1, &darks, status );

  /* input group is now the filtered group so we can use that and
     free the old input group */
  size = grpGrpsz( fgrp, status );
  grpDelet( &igrp, status);
  igrp = fgrp;
  fgrp = NULL;

  if (size == 0) {
    msgOutif(MSG__NORM, " ","All supplied input frames were DARK,"
             " nothing from which to make a map", status );
    goto L998;
  }

  /* Get the celestial coordinate system for the output map */
  parChoic( "SYSTEM", "TRACKING", "TRACKING,FK5,ICRS,AZEL,GALACTIC,"
            "GAPPT,FK4,FK4-NO-E,ECLIPTIC", 1, system, 10, status );

  /* Get the maximum amount of memory that we can use */
  parGdr0i( "MAXMEM", 2000, 1, VAL__MAXI, 1, &maxmem_mb, status );
  if( *status==SAI__OK ) {
    maxmem = (size_t) maxmem_mb * SMF__MB;
  }

  /* Get METHOD - set rebin/iterate flags */
  parChoic( "METHOD", "REBIN", "REBIN, ITERATE.", 1,
            method, LEN__METHOD, status);

  if( strncmp( method, "REBIN", 5 ) == 0 ) {
    rebin = 1;
    iterate = 0;
  } else if ( strncmp( method, "ITERATE", 7 ) == 0 ) {
    rebin = 0;
    iterate = 1;
  }
  
  /* Get remaining parameters so errors are caught early */
  if( rebin ) {
    /* Obtain desired pixel-spreading scheme */
    parChoic( "SPREAD", "NEAREST", "NEAREST,LINEAR,SINC,"
              "SINCSINC,SINCCOS,SINCGAUSS,SOMB,SOMBCOS,GAUSS", 
              1, pabuf, 10, status );
    
    smf_get_spread( pabuf, &spread, &nparam, status );
    
    /* Get an additional parameter vector if required. */
    if( nparam>0 ) {
      parExacd( "PARAMS", nparam, params, status );
    }
    
  } else if ( iterate ) {
    /* Read a group of configuration settings into keymap */
    kpg1Gtgrp( "CONFIG", &confgrp, &ksize, status );
    kpg1Kymap( confgrp, &keymap, status );
    if( confgrp ) grpDelet( &confgrp, status );      
  }

  /* Calculate the map bounds */

  smf_getrefwcs( "REF", &specrefwcs, &spacerefwcs, status );
  if( specrefwcs ) specrefwcs = astAnnul( specrefwcs );

  /* See if the input data is to be aligned in the output coordinate system
     rather than the default of ICRS. */
  parGet0l( "ALIGNSYS", &alignsys, status );

  msgOutif(MSG__VERB, " ", "SMURF_MAKEMAP: Determine map bounds", status);
  gettimeofday( &tv1, NULL );
  smf_mapbounds( 1, igrp, size, system, spacerefwcs, alignsys,
                 lbnd_out, ubnd_out, &outfset, &moving, &boxes, status );
  gettimeofday( &tv2, NULL );
  msgBlank( status );

  msgSetd("TDIFF",((double)(tv2.tv_sec-tv1.tv_sec) +
                   (1.0E-6*(double)(tv2.tv_usec-tv1.tv_usec))));
  msgOutif( MSG__DEBUG, " ", "Mapbounds took ^TDIFF s", status);

  /* Write WCS bounds */
  smf_store_outputbounds(1, lbnd_out, ubnd_out, outfset, NULL, NULL, 
                         status);
  msgBlank( status );

  /* See if the output is to be split up into a number of separate tiles,
     each one being stored in a separate output NDF. If a null value is
     supplied for TILEDIMS, annul the error and retain the original NULL 
     pointer for the array of tile structures (this is used as a flag that 
     the entire output grid should be stored in a single output NDF). */

  if( *status == SAI__OK ) {
    parGet1i( "TILEDIMS", 2, tiledims, &nval, status );
    if( *status == PAR__NULL ) {
      errAnnul( status );
    } else {
      parGet0l( "TRIMTILES", &trimtiles, status );
      parGet0i( "TILEBORDER", &tileborder, status );
      if( nval == 1 ) tiledims[ 1 ] = tiledims[ 0 ];
      tiles = smf_choosetiles( igrp, size, lbnd_out, ubnd_out, boxes, 
                               spread, params, outfset, tiledims,
                               trimtiles, tileborder, &ntile, status );
    }
  }

  /* If we are not splitting the output up into tiles, then create an array
     containing a single tile description that encompasses the entire full
     size output grid. */
  
  if( !tiles ) {
    tiledims[ 0 ] = -1;
    tiles = smf_choosetiles( igrp, size, lbnd_out, ubnd_out, boxes, 
                             spread, params, outfset, tiledims, 
                             0, 0, &ntile, status );
  }

  /* Write the number of tiles being created to an output parameter. */
  parPut0i( "NTILE", ntile, status );
  
  /* Output the pixel bounds of the full size output array (not of an
     individual tile). */
  parPut1i( "LBOUND", 2, lbnd_out, status );
  parPut1i( "UBOUND", 2, ubnd_out, status );
  
  if ( moving ) {
    msgOutif(MSG__VERB, " ", "Tracking a moving object", status);
  } else {
    msgOutif(MSG__VERB, " ", "Tracking a stationary object", status);
  }

  /* Create a new group to hold the names of the output NDFs that have been
     created. This group does not include any NDFs that correspond to tiles
     that contain no input data. */
  igrp4 = grpNew( "", status );

  /* Create an output smfData */
  if (*status == SAI__OK) {
    kpg1Wgndf( "OUT", NULL, 1, 1, NULL, &ogrp, &outsize, status );
    /* If OUT is NULL annul the bad status but set a flag so that we
       know to skip memory checks and actual map-making */
    if( *status == PAR__NULL ) {
      errAnnul( status );
      goto L998;
    }

    /* Expand the group to hold an output NDF name for each tile. */
    smf_expand_tilegroup( ogrp, ntile, 0, &outsize, status );
  }

  /* Create the output map using the chosen METHOD */
  if ( rebin ) {

    /************************* R E B I N *************************************/

    /* Initialise the index of the next output NDF name to use in "ogrp". */
    iout = 1;

    /* Loop round, creating each tile of the output array. Each tile is
       initially made a little larger than required so that edge effects
       (caused by the width of the spreading kernel) are avoided. The NDF
       containing the tile is eventually reshaped to exclude the extra
       boundary, resulting in a set of tiles that can be assembled edge-to-edge
       to form the full output array. */
    tile = tiles;
    for( itile = 1; itile <= ntile && *status == SAI__OK; itile++, tile++ ) {

      /* Tell the user which tile is being produced. */
      if( ntile > 1 ) {
        if( !blank ) msgBlank( status );
        msgSeti( "I", itile );
        msgSeti( "N", ntile );
        msgSeti( "XLO", (int) tile->lbnd[ 0 ] );
        msgSeti( "XHI", (int) tile->ubnd[ 0 ] );
        msgSeti( "YLO", (int) tile->lbnd[ 1 ] );
        msgSeti( "YHI", (int) tile->ubnd[ 1 ] );
        msgOutif( MSG__NORM, "TILE_MSG1", "   Creating output tile ^I of "
                  "^N (pixel bounds ^XLO:^XHI, ^YLO:^YHI)...", status );
        msgOutif( MSG__NORM, "TILE_MSG3", "   -----------------------------------------------------------", status );
        msgBlank( status );
        blank = 1;
      }

      /* If the tile is empty, do not create it. */
      if( tile->size == 0 ) {

        /* Issue a warning. */
        msgOutif( MSG__NORM, "TILE_MSG2", "      No input data "
                  "contributes to this output tile. The tile "
                  "will not be created.", status );
        msgBlank( status );
        blank = 1;

        /* Skip over the unused output file names. */
        iout++;

        /* Proceed to the next tile. */
        continue;
      }

      /* Begin an AST context for the current tile. */
      astBegin;

      /* Begin an NDF context for the current tile. */
      ndfBegin();

      /* Create FrameSets that are appropriate for this tile. This involves
         remapping the base (GRID) Frame of the full size output WCS so that
         GRID position (1,1) corresponds to the centre of the first pixel int he
         tile. */
      wcstile2d = astCopy( outfset );
      if( tile->map2d ) astRemapFrame( wcstile2d, AST__BASE, tile->map2d );

      /* Get the Mapping from 2D GRID to SKY coords (the tiles equivalent of
         "oskymap"). */
      tskymap = astGetMapping( wcstile2d, AST__BASE, AST__CURRENT );

      /* Invert the output sky mapping so that it goes from sky to pixel
         coords. */
      astInvert( tskymap );
   
      /* Store the initial number of pixels per spatial plane in the output tile. */
      nxy = ( tile->eubnd[ 0 ] - tile->elbnd[ 0 ] + 1 )*
        ( tile->eubnd[ 1 ] - tile->elbnd[ 1 ] + 1 );

      /* Add the name of this output NDF to the group holding the names of the
         output NDFs that have actually been created. */
      pname = basename;
      grpGet( ogrp, iout, 1, &pname, GRP__SZNAM, status );
      grpPut1( igrp4, basename, 0, status );

      /* Create the output NDF for this tile */
      smfflags = 0;
      smfflags |= SMF__MAP_VAR;
      smf_open_newfile ( ogrp, iout++, SMF__DOUBLE, 2, tile->elbnd, tile->eubnd, smfflags, 
                         &odata, status );

      /* Abort if an error has occurred. */
      if( *status != SAI__OK ) goto L999;

      /* Convenience pointers */
      file = odata->file;
      ondf = file->ndfid;

      /* Map the data and variance arrays */
      map = (odata->pntr)[0];
      variance = (odata->pntr)[1];

      /* Create SMURF extension in the output file and map pointers to
         WEIGHTS and EXP_TIME arrays */
      smurfloc = smf_get_xloc ( odata, "SMURF", "SMURF", "WRITE", 0, 0, status );

      /* Create WEIGHTS component in output file */
      smf_open_ndfname ( smurfloc, "WRITE", NULL, "WEIGHTS", "NEW", "_DOUBLE",
                         2, tile->elbnd, tile->eubnd, "Weight", NULL, wcstile2d, &wdata, status );
      if ( wdata ) {
        weights = (wdata->pntr)[0];
        wndf = wdata->file->ndfid;
      }

      /* Create EXP_TIME component in output file */
      smf_open_ndfname ( smurfloc, "WRITE", NULL, "EXP_TIME", "NEW", "_DOUBLE",
                         2, tile->elbnd, tile->eubnd, "Total exposure time","s", wcstile2d,
                         &tdata, status );
      if ( tdata ) {
        exp_time = (tdata->pntr)[0];
      }

      /* Free the extension locator */
      datAnnul( &smurfloc, status );

      /* Now allocate memory for 3-d work array used by smf_rebinmap -
         plane 2 of this 3-D array is stored in the weights component
         later. Initialize to zero. */
      weights3d = smf_malloc( 2*nxy, sizeof(double), 1, status);

      /* Simple Regrid of the data */
      msgOutif(MSG__VERB, " ", "SMURF_MAKEMAP: Make map using REBIN method", 
               status);

      /* Find the last input file that contributes to the current output tile
         and polarisation bin. */
      ilast = 0;
      for( ifile = tile->size; ifile >= 1 && *status == SAI__OK; ifile-- ) {
        jin = ( tile->jndf ) ? tile->jndf[ ifile - 1 ] : ifile - 1;
        pt = ptime ?  ptime[ jin ][ ipbin ] : NULL;
        if( !pt || pt[ 0 ] < VAL__MAXI ) {
          ilast = ifile;
          break;
        }
      }

      /* Loop round all the input files that overlap this tile, pasting each one 
         into the output NDF. */
      first = 1;
      for( ifile = 1; ifile <= tile->size && *status == SAI__OK; ifile++ ) {

        /* Get the zero-based index of the current input file (ifile) within the 
           group of input NDFs (igrp). */
        jin = ( tile->jndf ) ? tile->jndf[ ifile - 1 ] : ifile - 1;

        /* Does this input NDF have any time slices that fall within the current
           polarisation bin? Look at the first used time slice index for this
           input NDF and polarisation angle bin. Only proceed if it is legal.
           Otherwise, pass on to the next input NDF. */
        pt = ptime ?  ptime[ jin ][ ipbin ] : NULL;
        if( !pt || pt[ 0 ] < VAL__MAXI ) {

          /* Read data from the ith input file in the group */      
          smf_open_and_flatfield( tile->grp, NULL, ifile, darks, &data,
                                  status ); 

          /* Check that the data dimensions are 3 (for time ordered data) */
          if( *status == SAI__OK ) {
            if( data->ndims != 3 ) {
              msgSeti("I",ifile);
              msgSeti("THEDIMS", data->ndims);
              *status = SAI__ERROR;
              errRep(FUNC_NAME, 
                     "File ^I data has ^THEDIMS dimensions, should be 3.", 
                     status);
              break;
            }
          }
      
          /* Check that the input data type is double precision */
          if( *status == SAI__OK ) {
            if( data->dtype != SMF__DOUBLE) {
              msgSeti("I",ifile);
              msgSetc("DTYPE", smf_dtype_string( data, status ));
              *status = SAI__ERROR;
              errRep(FUNC_NAME, 
                     "File ^I has ^DTYPE data type, should be DOUBLE.",
                     status);
              break;
            }
          }

          /* Check units are consistent */
          smf_check_units( ifile, data_units, data->hdr, status);

          /* Store steptime for calculating EXP_TIME first time round*/
          if ( steptime == VAL__BADD) {
            steptime = data->hdr->steptime;
          }

          /* Propagate provenance to the output file */
          smf_accumulate_prov( data, tile->grp, ifile, ondf, "SMURF:MAKEMAP(REBIN)",
                               status);

          /* Handle output FITS header creation */
          if (*status == SAI__OK)
            smf_fits_outhdr( data->hdr->fitshdr, &fchan, NULL, status );

          /* Report the name of the input file. */
          if (data->file && data->file->name) {
            pname =  data->file->name;
            msgSetc( "FILE", pname );
            msgSeti( "THISFILE", ifile );
            msgSeti( "NUMFILES", tile->size );
            msgOutif( MSG__VERB, " ", "Processing ^FILE (^THISFILE/^NUMFILES)",
                      status );
          }

          /* Rebin the data onto the output grid */
      
          smf_rebinmap(data, (first ? 1 : ifile), ilast, wcstile2d, spread, params, moving, 1,
                       tile->elbnd, tile->eubnd, map, variance, weights3d, status );
          first = 0;

          /* Close the data file */
          smf_close_file( &data, status);

          blank = 0;
      
          /* Break out of loop over data files if bad status */
          if (*status != SAI__OK) {
            errRep(FUNC_NAME, "Rebinning step failed", status);
            break;
          }
        }
      }
    L999:

      /* Calculate exposure time per output pixel from weights array -
         note even if weights is a 3-D array we only use the first
         mapsize number of values which represent the `hits' per
         pixel */
      for (i=0; (i<nxy) && (*status == SAI__OK); i++) {
        if ( map[i] == VAL__BADD) {
          exp_time[i] = VAL__BADD;
          weights[i] = VAL__BADD;
        } else {
          exp_time[i] = steptime * weights3d[i];
          weights[i] = weights3d[i+nxy];
          if ( exp_time[i] > maxtexp ) {
            maxtexp = exp_time[i];
          }
        }
      }
      weights3d = smf_free( weights3d, status );

      /* Write WCS */
      if (wcstile2d) {
	astsys = astGetC( wcstile2d, "SYSTEM");
	if (strcmp(astsys,"AZEL") == 0 || strcmp(astsys, "GAPPT") == 0 ) {
	  astSet( wcstile2d, "SkyRefIs=Origin,AlignOffset=1" );
	}
	ndfPtwcs( wcstile2d, ondf, status );
      }

      /* write units - hack we do not have a smfHead */
      if (strlen(data_units)) ndfCput( data_units, ondf, "UNITS", status);
      ndfCput("Flux Density", ondf, "LABEL", status);

      /* Weights are related to data_units */
      one_strlcat(data_units, "**-2", sizeof(data_units), status);
      ndfCput(data_units, wndf, "UNITS", status);


      /* Calculate median exposure time - use faster histogram-based
         method which should be accurate enough for our purposes */
      /* Note that smf_find_median does not use smf_malloc */
      msgOutif( MSG__VERB, " ", "Calculating median output exposure time",
                status );
      histogram = smf_find_median( NULL, exp_time, nxy, NULL, &medtexp, status );
      if ( medtexp != VAL__BADR ) {
        atlPtftr(fchan, "EXP_TIME", medtexp, "[s] Median MAKEMAP exposure time", status);
      }
      histogram = astFree( histogram );

      /* Store the keywords holding the number of tiles generated and the index
         of the current tile. */
      atlPtfti( fchan, "NUMTILES", ntile, 
                "No. of tiles covering the field", status );
      atlPtfti( fchan, "TILENUM", itile, 
                "Index of this tile (1->NUMTILES)", status );

      /* If the FitsChan is not empty, store it in the FITS extension of the
         output NDF (any existing FITS extension is deleted). */
      if( astGetI( fchan, "NCard" ) > 0 ) {
        kpgPtfts( ondf, fchan, status );
        fchan = astAnnul( fchan );
      }

      /* For each open output NDF (the main tile NDF, and any extension NDFs),
         first clone the NDF identifier, then close the file (which will unmap
         the NDF arrays), and then reshape the NDF to exclude the boundary 
         that was added to the tile to avoid edge effects. */
      msgOutif( MSG__VERB, " ", "Reshaping output NDFs", status );
      smf_reshapendf( &tdata, tile, status );
      smf_reshapendf( &wdata, tile, status );
      smf_reshapendf( &odata, tile, status );

      /* End contexts for current tile*/
      ndfEnd(status);
      astEnd;
    }

    /* Write out the list of output NDF names, annulling the error if a null
       parameter value is supplied. */
    if( *status == SAI__OK ) {
      grpList( "OUTFILES", 0, 0, NULL, igrp4, status );
      if( *status == PAR__NULL ) errAnnul( status );
    }


















  } else if ( iterate ) {

    /************************* I T E R A T E *************************************/

    smfflags = 0;
    smfflags |= SMF__MAP_VAR;
    smf_open_newfile ( ogrp, 1, SMF__DOUBLE, 2, lbnd_out, ubnd_out, smfflags, 
                       &odata, status );

    if ( *status == SAI__OK ) {
      file = odata->file;
      ondf = file->ndfid;
      /* Map the data and variance arrays */
      map = (odata->pntr)[0];
      variance = (odata->pntr)[1];
    }

    /* Compute number of pixels in output map */
    nxy = (ubnd_out[0] - lbnd_out[0] + 1) * (ubnd_out[1] - lbnd_out[1] + 1);

    /* Create SMURF extension in the output file and map pointers to
       WEIGHTS and EXP_TIME arrays */
    smurfloc = smf_get_xloc ( odata, "SMURF", "SMURF", "WRITE", 0, 0, status );

    /* Create WEIGHTS component in output file */
    smf_open_ndfname ( smurfloc, "WRITE", NULL, "WEIGHTS", "NEW", "_DOUBLE",
                       2, lbnd_out, ubnd_out, "Weight", NULL, outfset, &wdata, status );
    if ( wdata ) {
      weights = (wdata->pntr)[0];
      wndf = wdata->file->ndfid;
    }

    /* Create EXP_TIME component in output file */
    smf_open_ndfname ( smurfloc, "WRITE", NULL, "EXP_TIME", "NEW", "_DOUBLE",
                       2, lbnd_out, ubnd_out, "Total exposure time","s", outfset,
                       &tdata, status );
    if ( tdata ) {
      exp_time = (tdata->pntr)[0];
    }

    /* Free the extension locator */
    datAnnul( &smurfloc, status );

    /* Iterative map-maker */
    msgOutif(MSG__VERB, " ", "SMURF_MAKEMAP: Make map using ITERATE method", 
             status);

    /* Allocate space for hitsmap */
    hitsmap = smf_malloc( nxy, sizeof (int), 1, status);

    /* Loop over all input data files to setup provenance handling */
    for(i=1; (i<=size) && ( *status == SAI__OK ); i++ ) {	
      smf_open_file( igrp, i, "READ", SMF__NOCREATE_DATA, &data, status );
      if( *status != SAI__OK) {
        msgSeti("I",i);
        msgSeti("S",size);
        errRep(FUNC_NAME, "Error opening input file ^I of ^S for provenance tracking", status);
      }
        
      /* Store steptime for calculating EXP_TIME */
      if ( i==1 ) {
        steptime = data->hdr->steptime;
      }

      /* Check units are consistent */
      smf_check_units( i, data_units, data->hdr, status);

      /* Propagate provenance to the output file */
      smf_accumulate_prov( data, igrp, i, ondf, "SMURF:MAKEMAP(ITER)",
                           status);

      /* Handle output FITS header creation (since the file is open and
         the header is available) */
      smf_fits_outhdr( data->hdr->fitshdr, &fchan, NULL, status );

      /* close the input file */
      smf_close_file( &data, status );
    }

    /* Call the low-level iterative map-maker */
    smf_iteratemap( igrp, keymap, darks, outfset, moving, lbnd_out, ubnd_out,
                    maxmem-mapmem, map, hitsmap, variance, weights, status );

    /* Calculate exposure time per output pixel from hitsmap */
    for (i=0; (i<nxy) && (*status == SAI__OK); i++) {
      if ( map[i] == VAL__BADD) {
        exp_time[i] = VAL__BADD;
      } else {
        exp_time[i] = steptime * hitsmap[i];
        if ( exp_time[i] > maxtexp ) {
          maxtexp = exp_time[i];
        }
      }
    }
    hitsmap = smf_free( hitsmap, status );

    /* Write WCS */
    astsys = astGetC( outfset, "SYSTEM");
    if (strcmp(astsys,"AZEL") == 0 || strcmp(astsys, "GAPPT") == 0 ) {
      astSet( outfset, "SkyRefIs=Origin,AlignOffset=1" );
    }
    ndfPtwcs( outfset, ondf, status );

    /* write units - hack we do not have a smfHead */
    if (strlen(data_units)) ndfCput( data_units, ondf, "UNITS", status);
    ndfCput("Flux Density", ondf, "LABEL", status);

    /* Weights are related to data_units */
    one_strlcat(data_units, "**-2", sizeof(data_units), status);
    ndfCput(data_units, wndf, "UNITS", status);


    /* Calculate median exposure time - use faster histogram-based
       method which should be accurate enough for our purposes */
    /* Note that smf_find_median does not use smf_malloc */
    msgOutif( MSG__VERB, " ", "Calculating median output exposure time",
              status );
    histogram = smf_find_median( NULL, exp_time, nxy, NULL, &medtexp, status );
    if ( medtexp != VAL__BADR ) {
      atlPtftr(fchan, "EXP_TIME", medtexp, "[s] Median MAKEMAP exposure time", status);
    }
    histogram = astFree( histogram );


    /* If the FitsChan is not empty, store it in the FITS extension of the
       output NDF (any existing FITS extension is deleted). */
    if( astGetI( fchan, "NCard" ) > 0 ) {
      kpgPtfts( ondf, fchan, status );
      fchan = astAnnul( fchan );
    }

    smf_close_file ( &tdata, status );
    smf_close_file ( &wdata, status );
    smf_close_file ( &odata, status );
    
  } else {
    /* no idea what mode */
    if (*status == SAI__OK) {
      *status = SAI__ERROR;
      errRep( " ", "Map maker mode not understood. Should not be possible",
              status );
    }
  }

  /* Arrive here if no output NDF is being created. */
 L998:;
  if( spacerefwcs ) spacerefwcs = astAnnul( spacerefwcs );
  if( outfset != NULL ) outfset = astAnnul( outfset );
  if( igrp != NULL ) grpDelet( &igrp, status);
  if( igrp4 != NULL) grpDelet( &igrp4, status);
  if( ogrp != NULL ) grpDelet( &ogrp, status);
  if( boxes ) boxes = smf_free( boxes, status );
  if( tiles ) tiles = smf_freetiles( tiles, ntile, status );
  if( darks ) smf_close_related( &darks, status );

  ndfEnd( status );
  
  if( *status == SAI__OK ) {
    msgOutif(MSG__VERB," ","MAKEMAP succeeded, map written.", status);
  } else {
    msgOutif(MSG__VERB," ","MAKEMAP failed.", status);
  }

}
