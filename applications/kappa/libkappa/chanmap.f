      SUBROUTINE CHANMAP( STATUS )
*+
*  Name:
*     CHANMAP

*  Purpose:
*     Creates a channel map from a cube NDF by compressing slices along
*     a nominated axis.

*  Language:
*     Starlink Fortran 77

*  Type of Module:
*     ADAM A-task

*  Invocation:
*     CALL CHANMAP( STATUS )

*  Arguments:
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Description:
*     This application creates a channel-map two-dimensional image from
*     a three-dimensional NDF.  It collapses along a nominated pixel
*     axis in a series of slices.  The collapsed slices are tiled with
*     no margins to form the output image.  This grid of channel maps
*     is filled from left to right, and bottom to top.  A specified 
*     range of axis values can be used instead of the whole axis (see
*     parameters LOW and HIGH).  The number of channels and their 
*     arrangement into an image is controlled through parameters 
*     NCHAN and SHAPE.
*
*     For each output pixel, all corresponding input pixel values 
*     between the channel bounds of the the nominated axis to be
*     collapsed are combined together using one of a selection of
*     estimators, including a mean, mode, or median, to produce the
*     output pixel value.
*
*  Usage:
*     chanmap in out axis nchan shape [low] [high] [estimator] [wlim]

*  ADAM Parameters:
*     AXIS = LITERAL (Read)
*        The axis along which to collapse the NDF.  This can be
*        specified by its integer index within the current Frame of the 
*        input NDF (in the range 1 to the number of axes in the current
*        Frame), or by its symbol string.  A list of acceptable values
*        is displayed if an illegal value is supplied.  If the axes of 
*        the current Frame are not parallel to the NDF pixel axes, then
*        the pixel axis which is most nearly parallel to the specified
*        current Frame axis will be used.
*     ESTIMATOR = LITERAL (Read)
*        The method to use for estimating the output pixel values.  It
*        can be one of the following options.  The first four are
*        more for general collapsing, and the remainder are for cube
*        analysis.
*          "Mean"   -- Mean value
*          "WMean"  -- Weighted mean in wich each data value is weighted
*                      by the reciprocal of the associated variance.  
*          "Mode"   -- Modal value
*          "Median" -- Median value.  Note that this is extremely memory
*                      and CPU intensive for large datasets; use with 
*                      care!  If strange things happen, use "Mean".
*
*          "Absdev" -- Mean absolute deviation from the unweighted mean.
*          "Comax"  -- Co-ordinate of the maximum value.
*          "Comin"  -- Co-ordinate of the minimum value.
*          "Integ"  -- Integrated value, being the sum of the products 
*                      of the value and pixel width in world
*                      co-ordinates.
*          "Iwc"    -- Intensity-weighted co-ordinate, being the sum of 
*                      each value times its co-ordinate, all divided by
*                      the integrated value (see the "Integ" option).
*          "Iwd"    -- Intensity-weighted dispersion of the
*                      co-ordinate, normalised like "Iwc" by the 
*                      integrated value.
*          "Max"    -- Maximum value.
*          "Min"    -- Minimum value.
*          "Rms"    -- Root-mean-square value.
*          "Sigma"  -- Standard deviation about the unweighted mean.
*          "Sum"    -- The total value.
*        ["Mean"]
*     HIGH = LITERAL (Read)
*        Together with parameter LOW, this parameter defines the range 
*        of values for the axis specified by parameter AXIS to be 
*        divided into channels.  For example, if AXIS is 3 and the 
*        current Frame of the input NDF has axes RA/DEC/Wavelength, then 
*        a wavelength value should be supplied.  If, on the other hand,
*        the current Frame in the NDF was the PIXEL Frame, then a pixel 
*        co-ordinate value would be required for the third axis (note, 
*        the pixel with index I covers a range of pixel co-ordinates 
*        from (I-1) to I).  
*
*        Note, HIGH and LOW should not be equal.  If a null value (!) is
*        supplied for either HIGH or LOW, the entire range of the axis 
*        fragmented into channels.  [!]
*     IN  = NDF (Read)
*        The input NDF.  This must have three dimensions.
*     LOW = LITERAL (Read)
*        Together with parameter HIGH this parameter defines the range 
*        of values for the axis specified by parameter AXIS to be 
*        divided into channels.  For example, if AXIS is 3 and the 
*        current Frame of the input NDF has axes RA/DEC/Frequency, then 
*        a frequency value should be supplied.  If, on the other hand,
*        the current Frame in the NDF was the PIXEL Frame, then a pixel 
*        co-ordinate value would be required for the third axis (note, 
*        the pixel with index I covers a range of pixel co-ordinates 
*        from (I-1) to I).  
*
*        Note, HIGH and LOW should not be equal.  If a null value (!) is
*        supplied for either HIGH or LOW, the entire range of the axis 
*        fragmented into channels.  [!]
*     NCHAN = INTEGER (Given)
*        The number of channels to appear in the channel map.  It must 
*        be a positive integer up to the lesser of 100 or one third of
*        the number of pixels along the collapsed axis.
*     OUT = NDF (Write)
*        The output NDF.
*     SHAPE = _INTEGER (Read)
*        The number of channels along the x axis of the output NDF.  The
*        number along the y axis will be (NCHAN-1)/SHAPE.  A null value 
*        (!) asks the application to select a shape.  It will generate
*        one that gives the most square output NDF possible.
*     TITLE = LITERAL (Read)
*        Title for the output NDF structure.  A null value (!)
*        propagates the title from the input NDF to the output NDF.  [!]
*     USEAXIS = GROUP (Read)
*        USEAXIS is only accessed if the current co-ordinate Frame of 
*        the input NDF has more than three axes.  A group of three 
*        strings should be supplied specifying the three axes which are 
*        to be retained in a collapsed slab.  Each axis can be 
*        specified either by its integer index within the current Frame 
*        (in the range 1 to the number of axes in the current Frame), or
*         by its symbol string.  A list of acceptable values is 
*        displayed if an illegal value is supplied.  If a null (!) value
*        is supplied, the axes with the same indices as the three used 
*        pixel axes within the NDF are used.  [!]
*     WLIM = _REAL (Read)
*        If the input NDF contains bad pixels, then this parameter
*        may be used to determine the number of good pixels which must
*        be present within the range of collapsed input pixels before a 
*        valid output pixel is generated.  It can be used, for example,
*        to prevent output pixels from being generated in regions where
*        there are relatively few good pixels to contribute to the
*        collapsed result.
*
*        WLIM specifies the minimum fraction of good pixels which must
*        be present in order to generate a good output pixel.  If this 
*        specified minimum fraction of good input pixels is not present,
*        then a bad output pixel will result, otherwise an good output 
*        value will be calculated.  The value of this parameter should 
*        lie between 0.0 and 1.0 (the actual number used will be rounded
*        up if necessary to correspond to at least one pixel).  [0.3]

*  Examples:
*     chanmap cube chan4 lambda 4 2 4500 4550 
*        The current Frame in the input three-dimensional NDF called 
*        cube has axes with labels "RA", "DEC" and "Lambda", with the 
*        lambda axis being parallel to the third pixel axis.  The above 
*        command extracts four slabs of the input cube between 
*        wavelengths 4500 and 4550 Angstroms, and collapses each slab,
*        into a single two-dimensional array with RA and DEC axes
*        forming a channel image.  Each channel image is pasted into a
*        2x2 grid within the output NDF called chan4.  Each pixel in the
*        output NDF is the mean of the corresponding input pixels with 
*        wavelengths in 12.5-Angstrom bins.
*     chanmap in=cube out=chan4 axis=3 low=4500 high=4550 nchan=4 
*             shape=2
*        The same as above except the axis to collapse along is
*        specified by index (3) rather than label (lambda), and it uses
*        keywords rather than positional parameters.
*     chanmap cube chan4 3 4 2 9.0 45.0
*        This is the same as the above examples, except that the current
*        Frame in the input NDF has been set to the PIXEL Frame (using
*        WCSFRAME), and so the high and low axis values are specified in
*        pixel co-ordinates instead of Angstroms, and each channel
*        covers nine pixels.  Note the difference between floating-point
*        pixel co-ordinates, and integer pixel indices (for instance the
*        pixel with index 10 extends from pixel co-ordinate 9.0 to pixel
*        co-ordinate 10.0).
*     chanmap in=zcube out=vel7 axis=1 low=-30 high=40 nchan=7 shape=!
*             estimator=max
*        This command assumes that the zcube NDF has a current
*        co-ordinate system where the first axis is radial velocity
*        (perhaps selected using WCSFRAME and WCSATTRIB), and the
*        the second and third axes are "RA", and "DEC".  It extracts 
*        seven velocity slabs of the input cube between -30 and +40 km/s,
*        and collapses each slab, into a single two-dimensional array
*        with RA and DEC axes forming a channel image.  Each channel 
*        image is pasted into a default grid (likely 4x2) within the 
*        output NDF called vel7.  Each pixel in the output NDF is the 
*        maximum of the corresponding input pixels with velocities in
*        10-km/s bins.

*  Notes:
*     -  The collapse is always performed along one of the pixel axes,
*     even if the current Frame in the input NDF is not the PIXEL Frame.
*     Special care should be taken if the current Frame axes are not
*     parallel to the pixel axes.  The algorithm used to choose the 
*     pixel axis and the range of values to collapse along this pixel
*     axis proceeds as follows.
*     
*     The current Frame co-ordinates of the central pixel in the input
*     NDF are determined (or some other point if the co-ordinates of the
*     central pixel are undefined).  Two current Frame positions are
*     then generated by substituting in turn into this central position 
*     each of the HIGH and LOW values for the current Frame axis 
*     specified by parameter AXIS.  These two current Frame positions
*     are transformed into pixel co-ordinates, and the projections of 
*     the vector joining these two pixel positions on to the pixel axes 
*     are found.  The pixel axis with the largest projection is selected
*     as the collapse axis, and the two end points of the projection 
*     define the range of axis values to collapse.
*     -  The WCS of the output NDF retains the three-dimensional
*     co-ordinate system of the input cube for every tile, except that
*     each tile has a single representative mean co-ordinate for the
*     collapsed axis.

*  Related Applications:
*     KAPPA: COLLAPSE, CLINPLOT.

*  Implementation Status:
*     -  This routine correctly processes the DATA, VARIANCE, LABEL,
*     TITLE, UNITS, WCS, and HISTORY components of the input NDF; and
*     propagates all extensions.  AXIS and QUALITY are not propagated.
*     -  Processing of bad pixels and automatic quality masking are
*     supported.
*     -  All non-complex numeric data types can be handled.
*     -  The origin of the output NDF is at (1,1).

*  Authors:
*     MJC: Malcolm J. Currie (STARLINK)
*     {enter_new_authors_here}

*  History:
*     2006 April 13 (MJC):
*        Original version adapted from COLLAPSE.
*     2006 April 24 (MJC):
*        Added SwitchMap to modify the output NDF's WCS to be
*        three-dimensional to retain the original spatial co-ordinates
*        with each tile, and to give a representative channel
*        co-ordinate to each tile.
*     2006 April 28 (MJC):
*        Removed call to KPS1_CLPA0 and called NDF_PTWCS after creating
*        the SwitchMap.
*     {enter_further_changes}

*  Bugs:
*     {note_new_bugs_here}

*-

*  Type Definitions:
      IMPLICIT NONE              ! No default typing allowed

*  Global Constants:
      INCLUDE  'SAE_PAR'         ! Global SSE definitions
      INCLUDE  'PAR_ERR'         ! Parameter-system errors
      INCLUDE  'NDF_PAR'         ! NDF_ public constants
      INCLUDE  'DAT_PAR'         ! HDS public constants
      INCLUDE  'AST_PAR'         ! AST constants and functions
      INCLUDE  'CNF_PAR'         ! For CNF_PVAL function
      INCLUDE  'MSG_PAR'         ! Message-system reporting levels

*  Status:
      INTEGER STATUS

*  External References:
      INTEGER KPG1_FLOOR         ! Most positive integer .LE. a given
                                 ! real
      INTEGER KPG1_CEIL          ! Most negative integer .GE. a given
                                 ! real

*  Local Constants:
      INTEGER MAXPIX 
      PARAMETER ( MAXPIX = 8388608 ) ! Guestimate a size: 8 mega

      INTEGER MAXCHN             ! Maximum number of channels
      PARAMETER ( MAXCHN = 100 )

      INTEGER MINWID             ! Minimum channel width in pixels
      PARAMETER( MINWID = 3 )

      INTEGER NDIM               ! Input dimensionality required
      PARAMETER( NDIM = 3 )


*  Local Variables:
      INTEGER AEL                ! Number of collapse axis elements
      CHARACTER AUNITS*( 30 )    ! Units of co-ordinates 
      CHARACTER ATTRIB*( 10 )    ! AST attribute name
      INTEGER AXES( NDF__MXDIM ) ! A list of axis indices
      DOUBLE PRECISION AXHIGH    ! High bound of collapse axis in
                                 ! current Frame
      DOUBLE PRECISION AXLOW     ! Low bound of collapse axis in current
                                 ! Frame
      LOGICAL BAD                ! Bad values may be present?
      INTEGER CAEL               ! Number of collapse axis elements in
                                 ! a channel
      INTEGER CBL                ! Identifier for channel block
      INTEGER CBLSIZ( NDIM )     ! Channel-image sizes for processing 
                                 ! large datasets in blocks
      INTEGER CDIMS( NDF__MXDIM ) ! Channel image dimensions
      DOUBLE PRECISION CHAVER    ! Average channel PIXEL co-ordinate
      INTEGER CHDIMS( NDIM - 1 ) ! Dimensions of an unblocked channel
                                 ! image
      INTEGER CHIND( NDIM - 1 )  ! Channel image indices within output
                                 ! array
      INTEGER CFRM               ! Original Current Frame pointer
      CHARACTER COMP * ( 13 )    ! List of components to process
      DOUBLE PRECISION CPOS( 2, NDIM ) ! Two current Frame 
                                 ! positions
      DOUBLE PRECISION CURPOS( NDIM ) ! Valid current Frame position
      INTEGER D                  ! A dimension size
      DOUBLE PRECISION DLBND( NDIM ) ! Lower bounds in pixel co-ords
      DOUBLE PRECISION DLBNDS( NDIM - 1 ) ! Slab lower bounds in pixel
                                 ! spatial co-ords
      CHARACTER DTYPE*( NDF__SZFTP ) ! Numeric type for output arrays
      DOUBLE PRECISION DUBND( NDIM ) ! Upper bounds in pixel co-ords
      DOUBLE PRECISION DUBNDS( NDIM - 1 ) ! Slab bounds in pixel spatial 
                                 ! co-ords
      INTEGER ELC                ! Number of elements in a channel
                                 ! mapped array
      INTEGER ELI                ! Number of elements in an input mapped
                                 ! array
      INTEGER ELO                ! Number of elements in an output 
                                 ! mapped array
      CHARACTER ESTIM*( 6 )      ! Method to use to estimate collapsed
                                 ! values
      DOUBLE PRECISION GRDPOS( NDIM ) ! Valid grid Frame position
      LOGICAL HIGHER             ! Significant dimensions above collapse
                                 ! axis?
      INTEGER I                  ! Loop count
      INTEGER IAXIS              ! Index of collapse axis within current
                                 ! Frame
      INTEGER IBL                ! Identifier for input-NDF block
      INTEGER IBLOCK             ! Loop counter for the NDF blocks
      INTEGER IBLSIZ( NDIM )     ! Input-NDF sizes for processing 
                                 ! large datasets in blocks
      INTEGER ICH                ! Channel counter
      INTEGER IERR               ! Position of first numerical error
      INTEGER INDFC              ! NDF identifier for single channel map
      INTEGER INDFI              ! Input NDF identifier
      INTEGER INDFO              ! Output NDF identifier
      INTEGER INDFS              ! Input NDF-section identifier
      INTEGER IPAXCO             ! Pointers to mapped d.p. axis array
      INTEGER IPCH( 2 )          ! Pointers to mapped channel arrays
      INTEGER IPCO               ! Pointers to mapped co-ordinate array
      INTEGER IPERM( NDIM - 1 )  ! Input permutation
      INTEGER IPIN( 2 )          ! Pointers to mapped input arrays
      INTEGER IPIX               ! Index of PIXEL Frame within input
                                 ! WCS FrameSet
      INTEGER IPIXO              ! Index of PIXEL Frame within output
                                 ! WCS FrameSet
      INTEGER IPOUT( 2 )         ! Pointers to mapped output arrays
      INTEGER IPW1               ! Pointer to first work array
      INTEGER IPW2               ! Pointer to second work array
      INTEGER IPW3               ! Pointer to third work array
      INTEGER IPWID              ! Pointers to mapped width work array
      CHARACTER ITYPE*( NDF__SZTYP ) ! Numeric type for processing
      INTEGER IWCS               ! WCS FrameSet pointer
      INTEGER IWCSO              ! Output NDF's WCS FrameSet pointer
      INTEGER J                  ! Loop count
      INTEGER JAXIS              ! Index of collapse axis within PIXEL
                                 ! Frame
      INTEGER JHI                ! High pixel index for collapse axis
      INTEGER JLO                ! Low pixel index for collapse axis
      INTEGER LBND( NDIM )       ! Lower pixel index bounds of the input
                                 ! NDF
      INTEGER LBNDBI( NDIM )     ! Lower pixel index bounds of the
                                 ! cube's block 
      INTEGER LBNDBO( NDIM - 1 ) ! Lower pixel index bounds of the
                                 ! channel-map block 
      INTEGER LBNDC( NDIM - 1 )  ! Lower pixel index bounds of the
                                 ! channel section of the input NDF
      INTEGER LBNDO( NDIM - 1 )  ! Lower pixel index bounds of the
                                 ! output NDF
      INTEGER LBNDS( NDIM )      ! Lower pixel index bounds of the
                                 ! slab of the input NDF
      LOGICAL LOOP               ! Continue to loop through dimensions?
      INTEGER MAXSIZ             ! Maximum size of block along current
                                 ! dimension
      INTEGER MAP                ! Pointer to Mapping from PIXEL Frame 
                                 ! to Current Frame, input NDF
      INTEGER MAPC               ! Pointer to Compound Mapping PIXEL 
                                 ! 2-D Frame to 3-D Current Frame 
      INTEGER NAXC               ! Original number of current Frame axes
      INTEGER NBLOCK             ! Number of NDF blocks
      INTEGER NCOMP              ! No. of components within cell of AXIS
                                 ! array
      INTEGER NERR               ! Number of numerical errors
      INTEGER NC                 ! Used length of string
      INTEGER ND                 ! Number of dimensniosn (dummy)
      INTEGER NDIMO              ! Number of pixel axes in output NDF
      INTEGER NOCHAN             ! Number of channels
      INTEGER NSHAPE             ! Number of shape values
      INTEGER NVAL               ! Number of values obtained (1)
      INTEGER OBL                ! Identifier for output-NDF block
      INTEGER ODIMS( NDF__MXDIM ) ! Output NDF dimensions
      INTEGER OFFSET( NDF__MXDIM ) ! Channel image pixel offsets within
                                 ! output array
      INTEGER OPERM( NDIM )      ! Output permutation
      INTEGER PERMAP             ! PermMap pointer
      REAL PIXPCH                ! Collapse-axis pixels per channel
      DOUBLE PRECISION PIXPOS( NDF__MXDIM ) ! Valid pixel Frame position
      INTEGER PLACE              ! NDF placeholder
      DOUBLE PRECISION PPOS( 2, NDF__MXDIM ) ! Two pixel Frame positions
      INTEGER PFRMO              ! Output PIXEL Frame pointer
      DOUBLE PRECISION PRJ       ! Vector length projected on to a pixel
                                 ! axis
      DOUBLE PRECISION PRJMAX    ! Maximum vector length projected on to
                                 ! an axis
      INTEGER ROUMAP( MAXCHN )   ! Route maps for each channel
      INTEGER SDIM( NDIM )       ! Significant dimensions
      INTEGER SELMAP             ! SelectorMap pointer
      INTEGER SHAPE( 2 )         ! Number of channel maps per axis
      DOUBLE PRECISION SHIFTS( NDIM - 1 ) ! Shifts from output origin
                                 ! to current tile's origin
      INTEGER SHIMAP             ! SwitchMap pointer
      INTEGER SLABIN( MAXCHN )   ! Pointers to spatial-pixel slab 
                                 ! intervals for each channel
      INTEGER SWIMAP             ! SwitchMap pointer
      CHARACTER TTLC*( 255 )     ! Title of original current Frame
      INTEGER UBND( NDIM )       ! Upper pixel index bounds of the input
                                 ! NDF
      INTEGER UBNDBI( NDIM )     ! Upper pixel index bounds of the
                                 ! cube's block 
      INTEGER UBNDBO( NDIM - 1 ) ! Upper pixel index bounds of the
                                 ! channel-map block 
      INTEGER UBNDC( NDIM - 1 )  ! Upper pixel index bounds of the
                                 ! channel section of the input NDF
      INTEGER UBNDO( NDIM - 1 )  ! Upper pixel index bounds of the 
                                 ! output NDF
      INTEGER UBNDS( NDIM )      ! Upper pixel index bounds of the
                                 ! slab of the input NDF
      CHARACTER UNITS*( 60 )     ! Units of data 
      LOGICAL USEALL             ! Use the entire collapse pixel axis?
      LOGICAL VAR                ! Process variances?
      REAL WLIM                  ! Value of WLIM parameter

*.

*  Check the global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Obtain input NDF and some of its AST Frames.
*  ============================================

*  Start an AST context.
      CALL AST_BEGIN( STATUS )

*  Start an NDF context.
      CALL NDF_BEGIN

*  Obtain the input NDF.
      CALL LPG_ASSOC( 'IN', 'READ', INDFI, STATUS )

*  Get an AST pointer to a FrameSet describing the co-ordinate Frames
*  present in the NDF's WCS component.  Modify it to ensure that the 
*  Base, PIXEL and Current frames all have three dimensions.  The NDF 
*  must have exactly three significant dimensions (i.e. axes 
*  spanning more than one pixel).
      CALL KPG1_ASGET( INDFI, NDIM, .TRUE., .TRUE., .TRUE., SDIM, 
     :                 LBND, UBND, IWCS, STATUS )

*  Get the WCS FrameSet from the NDF.
      CALL KPG1_GTWCS( INDFI, IWCS, STATUS )

*  Extract the current and base Frames, and get the number of axes in 
*  the current Frame, and its title.
      CFRM = AST_GETFRAME( IWCS, AST__CURRENT, STATUS )
      NAXC = AST_GETI( CFRM, 'NAXES', STATUS )
      TTLC = AST_GETC( CFRM, 'TITLE', STATUS )

*  Find the index of the PIXEL Frame.
      CALL KPG1_ASFFR( IWCS, 'PIXEL', IPIX, STATUS )

*  Extract the Mapping from PIXEL Frame to Current Frame. 
      MAP = AST_GETMAPPING( IWCS, IPIX, AST__CURRENT, STATUS )

*  Report an error if the Mapping is not defined in either direction.
      IF ( .NOT. AST_GETL( MAP, 'TRANINVERSE', STATUS ) .AND.
     :    STATUS .EQ. SAI__OK ) THEN
         STATUS = SAI__ERROR
         CALL NDF_MSG( 'NDF', INDFI )
         CALL MSG_SETC( 'T', TTLC )
         CALL ERR_REP( 'CHANMAP_ERR1', 'The transformation from the '//
     :                 'current co-ordinate Frame of ''^NDF'' '//
     :                 '(^T) to pixel co-ordinates is not defined.', 
     :                 STATUS )

      ELSE IF ( .NOT. AST_GETL( MAP, 'TRANFORWARD', STATUS ) .AND.
     :         STATUS .EQ. SAI__OK ) THEN
         STATUS = SAI__ERROR
         CALL NDF_MSG( 'NDF', INDFI )
         CALL MSG_SETC( 'T', TTLC )
         CALL ERR_REP( 'CHANMAP_ERR2', 'The transformation from '/
     :                 /'pixel co-ordinates to the current '/
     :                 /'co-ordinate Frame of ''^NDF'' (^T) is not '/
     :                 /'defined.', STATUS )
      END IF

*  Select the collapse axis and limits thereon.
*  ============================================
 
*  Get the index of the current Frame axis defining the collapse 
*  direction.  Use the last axis as the dynamic default.
      IAXIS = NAXC
      CALL KPG1_GTAXI( 'AXIS', CFRM, 1, IAXIS, STATUS )

*  Abort if an error has occurred.
      IF ( STATUS .NE. SAI__OK ) GO TO 999  

*  Get the bounding values for the specified current Frame axis defining
*  the height of the slab to be collapsed.
      AXLOW = AST__BAD
      CALL KPG1_GTAXV( 'LOW', 1, .TRUE., CFRM, IAXIS, AXLOW, NVAL, 
     :                 STATUS )

      AXHIGH = AST__BAD
      CALL KPG1_GTAXV( 'HIGH', 1, .TRUE., CFRM, IAXIS, AXHIGH, NVAL, 
     :                 STATUS )

*  If a null value was supplied for either of these parameters, annul 
*  the error and set a flag indicating that the whole axis should be
*  used.
      IF ( STATUS .EQ. PAR__NULL ) THEN
         CALL ERR_ANNUL( STATUS )
         USEALL = .TRUE.
      ELSE
         USEALL = .FALSE.
      END IF

*  Determine which pixel axis is most nearly aligned with the selected 
*  WCS axis.
*  ===================================================================

*  Find an arbitrary position within the NDF which has valid current 
*  Frame co-ordinates. Both pixel and current Frame co-ordinates for 
*  this position are returned.
      DO I = 1, NDIM
         DLBND( I ) = DBLE( LBND( I ) - 1 )
         DUBND( I ) = DBLE( UBND( I ) )
      END DO
      CALL KPG1_ASGDP( MAP, NDIM, NAXC, DLBND, DUBND, PIXPOS, CURPOS, 
     :                 STATUS )

*  Convert the pixel position into a grid position.
      DO I = 1, NDIM
         GRDPOS( I ) = PIXPOS( I ) - LBND( I ) + 1.5
      END DO 

*  Create two copies of these current Frame co-ordinates.
      DO I = 1, NAXC
         CPOS( 1, I ) = CURPOS( I )
         CPOS( 2, I ) = CURPOS( I )
      END DO 

*  If no high and low values for the collapse axis were supplied, modify
*  the collapse axis values in these positions by an arbitrary amount.
      IF ( USEALL ) THEN
         IF ( CURPOS( IAXIS ) .NE. 0.0 ) THEN
            CPOS( 1, IAXIS ) = 0.99 * CURPOS( IAXIS )
            CPOS( 2, IAXIS ) = 1.01 * CURPOS( IAXIS )
         ELSE
            CPOS( 1, IAXIS ) = CURPOS( IAXIS ) + 1.0D-4
            CPOS( 2, IAXIS ) = CURPOS( IAXIS ) - 1.0D-4
         END IF

*  If high and low values for the collapse axis were supplied,
*  substitute these into these positions.
      ELSE
         CPOS( 1, IAXIS ) = AXHIGH
         CPOS( 2, IAXIS ) = AXLOW
      END IF

*  Transform these two positions into pixel co-ordinates.
      CALL AST_TRANN( MAP, 2, NAXC, 2, CPOS, .FALSE., NDIM, 2, PPOS,
     :                STATUS ) 

*  Find the pixel axis with the largest projection of the vector joining
*  these two pixel positions.  The collapse will occur along this pixel
*  axis.  Report an error if the positions do not have valid pixel
*  co-ordinates.
      PRJMAX = -1.0
      DO I = 1, NDIM
         IF ( PPOS( 1, I ) .NE. AST__BAD .AND.
     :        PPOS( 2, I ) .NE. AST__BAD ) THEN

            PRJ = ABS( PPOS( 1, I ) - PPOS( 2, I ) )
            IF ( PRJ .GT. PRJMAX ) THEN
               JAXIS = I
               PRJMAX = PRJ
            END IF

         ELSE IF ( STATUS .EQ. SAI__OK ) THEN
            STATUS = SAI__ERROR
            CALL ERR_REP( 'CHANMAP_ERR3', 'The WCS information is '//
     :                    'too complex (cannot find two valid pixel '//
     :                    'positions).', STATUS )
            GO TO 999
         END IF

      END DO

*  Report an error if the selected WCS axis is independent of pixel
*  position.
      IF ( PRJMAX .EQ. 0.0 ) THEN
         IF ( STATUS .EQ. SAI__OK ) THEN
            STATUS = SAI__ERROR
            CALL MSG_SETI( 'I', IAXIS )   
            CALL ERR_REP( 'CHANMAP_ERR3B', 'The specified WCS axis '//
     :                    '(axis ^I) has a constant value over the '//
     :                    'whole NDF and so cannot be collapsed.',
     :                    STATUS )
         END IF
         GO TO 999
      END IF

*  Derive the pixel-index bounds along the collapse axis.
*  ======================================================

*  Choose the pixel index bounds of the slab to be collapsed on the
*  collapse pixel axis.  If no axis limits supplied, use the upper and
*  lower bounds.
      IF ( USEALL ) THEN
         JLO = LBND( JAXIS )
         JHI = UBND( JAXIS )

*  If limits were supplied...
      ELSE

*  Find the projection of the two test points on to the collapse axis.
         JLO = KPG1_FLOOR( REAL( MIN( PPOS( 1, JAXIS ), 
     :                                PPOS( 2, JAXIS ) ) ) ) + 1
         JHI = KPG1_CEIL( REAL( MAX( PPOS( 1, JAXIS ), 
     :                               PPOS( 2, JAXIS ) ) ) )

*  Ensure these are within the bounds of the pixel axis.
         JLO = MAX( LBND( JAXIS ), JLO )
         JHI = MIN( UBND( JAXIS ), JHI )

*  Report an error if there is no intersection.
         IF ( JLO .GT. JHI .AND. STATUS .EQ. SAI__OK ) THEN
            STATUS = SAI__ERROR
            CALL ERR_REP( 'CHANMAP_ERR4', 'The axis range to '/
     :                    /'collapse covers zero pixels (are the '/
     :                    /'HIGH and LOW parameter values equal '/
     :                    /'or outside the bounds of the NDF?)', 
     :                    STATUS )
            GO TO 999
         END IF

      END IF

*  Tell the user the range of pixels being collapsed.
      CALL MSG_SETI( 'I', JAXIS )
      CALL MSG_SETI( 'L', JLO )
      CALL MSG_SETI( 'H', JHI )
      CALL MSG_OUTIF( MSG__NORM, 'CHANMAP_MSG1', 
     :               '   Forming channel map along pixel axis ^I '/
     :               /'between pixel ^L to pixel ^H inclusive.',
     :               STATUS )
      CALL MSG_BLANK( ' ', STATUS )
      AEL = JHI - JLO + 1

*  Set the bounds and dimensions of a single tile in the map.
*  ==========================================================

*  The output NDF will have one fewer axes than the input NDF.
      NDIMO = NDIM - 1

*  For each pixel axis I in the final output NDF, find the 
*  corresponding axis in the input NDF.
      DO I = 1, NDIMO
         IF ( I .LT. JAXIS ) THEN
            AXES( I ) = I
         ELSE
            AXES( I ) = I + 1
         END IF
      END DO

*  Find the pixel bounds of the NDF after axis permutation.
      DO I = 1, NDIMO
         LBNDC( I ) = LBND( AXES( I ) )
         UBNDC( I ) = UBND( AXES( I ) )
         CHDIMS( I ) = UBNDC( I ) - LBNDC( I ) + 1
      END DO

*  Obtain the number of channels and their arrangement.
*  ====================================================
      CALL PAR_GDR0I( 'NCHAN', 6, 1, MAXCHN, .FALSE., NOCHAN, STATUS )
      IF ( STATUS .NE. SAI__OK ) GOTO 999

*  The constraints are that the values are positive, and each
*  channel must have at least three pixels.  (This may be made 
*  dependent on the estimator.)
      CALL PAR_GDR0I( 'SHAPE', 4, 1, MIN( 100, AEL / MINWID ), 
     :                .FALSE., SHAPE( 1 ), STATUS )

      IF ( STATUS .EQ. PAR__NULL ) THEN
         CALL ERR_ANNUL( STATUS )

*  The aspect ratio is 1.0 and the tiles abut.
         CALL KPS1_CHSHA( NOCHAN, CHDIMS, 1.0, 0.0, SHAPE, STATUS )
      END IF

*  Propagate the input to the output NDF and define latter's bounds.
*  =================================================================

*  Create the output NDF by propagation from the input NDF.  This
*  results in history, etc., being passed on.  The shape and 
*  dimensionality will be wrong but this will be corrected later.
      CALL LPG_PROP( INDFI, 'Units', 'OUT', INDFO, STATUS )

*  Set the title of the output NDF.
      CALL KPG1_CCPRO( 'TITLE', 'TITLE', INDFI, INDFO, STATUS )

*  See if the input NDF has a Variance component.
      CALL NDF_STATE( INDFI, 'VARIANCE', VAR, STATUS )

*  Store a list of components to be accessed.
      IF ( VAR ) THEN
         COMP = 'DATA,VARIANCE'
      ELSE
         COMP = 'DATA'
      END IF

*  Determine the numeric type to be used for processing the input
*  data and variance (if any) arrays.  Since the subroutines that
*  perform the collapse need the data and variance arrays in the same
*  data type, the component list is used.  This application supports
*  single- and double-precision floating-point processing.
      CALL NDF_MTYPE( '_REAL,_DOUBLE', INDFI, INDFO, COMP, ITYPE, DTYPE,
     :                STATUS )

*  Determine whether or not there are significant dimensions above
*  the collapse axis.
      HIGHER = JAXIS .NE. NDIM
      IF ( HIGHER ) THEN
         HIGHER = .FALSE.
         DO I = JAXIS + 1, NDIM
            HIGHER = HIGHER .OR. ( UBND( I ) - LBND( I ) ) .NE. 0
         END DO
      END IF

*  Define the shape of the channel-map image.  The original bounds
*  cannot be retained.
      DO I = 1, NDIMO
         LBNDO( I ) = 1
         UBNDO( I ) = CHDIMS( I ) * SHAPE( I )
         ODIMS( I ) = UBNDO( I )
      END DO

*  Pasting needs aray dimensions and offsets with NDF__MXDIM elements.
      DO I = NDIM, NDF__MXDIM
         OFFSET( I ) = 0
         CDIMS( I ) = 1
         ODIMS( I ) = 1
      END DO

*  Adjust output NDF to its new shape.
*  ===================================

*  The shape and size of the output NDF created above will be wrong, so
*  we need to correct it by removing the collapse axis.  To avoid
*  sawtooth axis centres that would be unpalatable to many tasks, it's
*  better to remove the AXIS structures, and use the WCS to handle the
*  repeating spatial co-ordinates.  We shall create the basic NDF
*  WCS, and add the SwitchMap Frame at the end.

*  Set the output NDF bounds to the required values.
      CALL NDF_SBND( NDIMO, LBNDO, UBNDO, INDFO, STATUS ) 

*  Get the WCS FrameSet from the output NDF.
      CALL NDF_GTWCS( INDFO, IWCSO, STATUS )

*  Find the index of the PIXEL Frame in the output FrameSet.
      CALL KPG1_ASFFR( IWCSO, 'PIXEL', IPIXO, STATUS )

*  Extract the Mapping from PIXEL Frame to Current Frame, and the
*  Pixel Frame.
      PFRMO = AST_GETFRAME( IWCSO, IPIXO, STATUS )

*  Obtain the remaining parameters.
*  ================================

*  Get the ESTIMATOR and WLIM parameters.
      CALL PAR_CHOIC( 'ESTIMATOR', 'Mean','Mean,WMean,Mode,Median,Max,'/
     :                /'Min,Comax,Comin,Absdev,RMS,Sigma,Sum,Iwc,Iwd,'/
     :                /'Integ', .FALSE., ESTIM, STATUS )

      CALL PAR_GDR0R( 'WLIM', 0.3, 0.0, 1.0, .FALSE., WLIM, STATUS )

*  Redefine the data units.
*  ========================
      IF ( ESTIM .EQ. 'COMAX' .OR. ESTIM .EQ. 'COMIN' .OR.
     :     ESTIM .EQ. 'IWC' .OR. ESTIM .EQ. 'IWD' ) THEN

*  Obtain the collapsed-axis units of the input NDF; these now become
*  the data units in output NDF.
         ATTRIB = 'UNIT('
         NC = 5
         CALL CHR_PUTI( IAXIS, ATTRIB, NC )
         CALL CHR_PUTC( ')', ATTRIB, NC )
         UNITS = AST_GETC( IWCS, ATTRIB( :NC ), STATUS )

         CALL NDF_CPUT( UNITS, INDFO, 'Units', STATUS )

*  New unit is the existing unit times the co-ordinate's unit.  So
*  obtain each unit and concatenate the two inserting a blank between
*  them.
      ELSE IF ( ESTIM .EQ. 'INTEG' ) THEN
         ATTRIB = 'UNIT('
         NC = 5
         CALL CHR_PUTI( IAXIS, ATTRIB, NC )
         CALL CHR_PUTC( ')', ATTRIB, NC )
         AUNITS = AST_GETC( IWCS, ATTRIB( :NC ), STATUS )

         UNITS = ' '
         CALL NDF_CGET( INDFI, 'Unit', UNITS, STATUS )
         CALL NDF_CLEN( INDFI, 'Unit', NC, STATUS )
         NC = NC + 1
         UNITS( NC:NC ) = ' '
         CALL CHR_APPND( AUNITS, UNITS, NC )

         CALL NDF_CPUT( UNITS, INDFO, 'Units', STATUS )
      END IF

*  Prepare for the channel-map loop.
*  =================================

*  Map the channel map.
      CALL KPG1_MAP( INDFO, COMP, ITYPE, 'WRITE', IPOUT, ELO, STATUS )

*  Let's define the number of pixels per channel.
      PIXPCH = REAL( AEL ) / REAL( NOCHAN )
      BAD = .TRUE.

*  Set the pixel bounds of the slab NDF.
      DO I = 1, NDIM
         LBNDS( I ) = LBND( I )
         UBNDS( I ) = UBND( I )
      END DO
      UBNDS( JAXIS ) = JLO - 1

*  Inside the loop we'll need the permutation of the axes to create
*  a two-dimensional to three-dimensional Mapping, with a constant
*  along the third axis, being a representative collapsed-axis
*  PIXEL co-ordinate (indicated by the negative axis).
      DO I = 1, NDIMO
         IPERM( I ) = I
         OPERM( I ) = AXES( I )
      END DO
      OPERM( NDIM ) = -1

*  Make a temporary NDF to store a single channel's image.
      CALL NDF_TEMP( PLACE, STATUS )
      CALL NDF_NEW( ITYPE, NDIMO, LBNDC, UBNDC, PLACE, INDFC, STATUS )

*  Iterate through the channels.
      DO ICH = 1, NOCHAN
 
*  See the bounds of the channel along the collapse axis.  Strictly
*  we should divide the co-ordinates limits of the current WCS Frame 
*  equally and convert those channel limits to pixels.
         LBNDS( JAXIS ) = UBNDS( JAXIS ) + 1
         UBNDS( JAXIS ) = JLO - 1 + INT( PIXPCH * REAL( ICH ) )
         CAEL = UBNDS( JAXIS ) - LBNDS( JAXIS ) + 1

*  Obtain the indices of the tile within the large output
*  two-dimensional array.
         CHIND( 1 ) = MOD( ICH - 1, SHAPE( 1 ) ) + 1
         CHIND( 2 ) = ( ICH - 1 ) / SHAPE( 1 ) + 1

*  Process in blocks.
*  ==================

*  For large datasets, there may be insufficient memory.  Therefore
*  we form blocks to process, one at a time.  For this by definition
*  we need the collapse-axis pixels to always be present in full for
*  each pixel along the other pixel axes.  If this leaves room for a
*  full span of a dimension that becomes the block size along that
*  axis.  Partial fills take the remaining maximum size and subsequent
*  dimensions' block sizes are unity.
         IBLSIZ( JAXIS ) = CAEL
         MAXSIZ = MAX( 1, MAXPIX / CAEL )
         LOOP = .TRUE.
         J = 0
         DO I = 1, NDIM
            IF ( I .NE. JAXIS ) THEN
               IF ( LOOP ) THEN
                  D = UBNDS( I ) - LBNDS( I ) + 1
                  IF ( MAXSIZ .GE. D ) THEN
                     IBLSIZ( I ) = D
                     MAXSIZ = MAXSIZ / D
                  ELSE
                     IBLSIZ( I ) = MAXSIZ
                     LOOP = .FALSE.
                  END IF
               ELSE
                  IBLSIZ( I ) = 1
               END IF

*  Copy the output NDF block sizes in sequence omitting the
*  collapse axis.
               J = J + 1
               CBLSIZ( J ) = IBLSIZ( I )
            END IF
         END DO

*  The channel limits have reduced the collapsed section from the
*  whole collapsed dimension, then we cannot use the original input
*  NDF to derive the number of blocks.  Instead we create a subsection
*  spanning the actual collapse limits, as if the user had supplied
*  this section with the input NDF.
         CALL NDF_SECT( INDFI, NDIM, LBNDS, UBNDS, INDFS, STATUS )

*  Determine the number of blocks.
         CALL NDF_NBLOC( INDFS, NDIM, IBLSIZ, NBLOCK, STATUS )

*  Loop through each block.  Start a new NDF context.
         DO IBLOCK = 1, NBLOCK
            CALL NDF_BEGIN
            CALL NDF_BLOCK( INDFS, NDIM, IBLSIZ, IBLOCK, IBL, STATUS )
            CALL NDF_BLOCK( INDFC, NDIMO, CBLSIZ, IBLOCK, CBL, STATUS ) 

*  Map the NDF arrays and workspace required.
*  ==========================================

*  Map the full input, and output data and (if needed) variance arrays.
            CALL NDF_MAP( IBL, COMP, ITYPE, 'READ', IPIN, ELI, STATUS )
            CALL NDF_MAP( CBL, COMP, ITYPE, 'WRITE', IPCH, ELC,
     :                    STATUS )

            IF ( .NOT. VAR ) THEN
               IPIN( 2 ) = IPIN( 1 )
               IPCH( 2 ) = IPCH( 1 )
            END IF

*  Obtain the bounds of the blocks.
            CALL NDF_BOUND( IBL, NDIM, LBNDBI, UBNDBI, ND, STATUS )
            CALL NDF_BOUND( CBL, NDIMO, LBNDBO, UBNDBO, ND, STATUS )

*  Allocate work space, unless the last axis is being collapsed (in
*  which case no work space is needed).
            IF ( HIGHER ) THEN
               CALL PSX_CALLOC( ELC * CAEL, ITYPE, IPW1, STATUS )
               IF ( VAR ) THEN
                  CALL PSX_CALLOC( ELC * CAEL, ITYPE, IPW2, STATUS )
               ELSE
                  IPW2 = IPW1
               END IF  

*  Store safe pointer values if no work space is needed.
            ELSE
              IPW1 = IPIN( 1 )
              IPW2 = IPIN( 1 )
            END IF

*  Associate co-ordinate information.
*  ==================================

*  Obtain co-ordinates along the collapse axis for the following
*  methods.
            IF ( ESTIM .EQ. 'COMAX' .OR. ESTIM .EQ. 'COMIN' .OR.
     :           ESTIM .EQ. 'IWC' .OR. ESTIM .EQ. 'IWD' .OR. 
     :           ESTIM .EQ. 'INTEG' ) THEN

*  Create workspace for the co-ordinates along a single WCS axis
*  in the correct data type.
               CALL PSX_CALLOC( ELI, '_DOUBLE', IPAXCO, STATUS )
               CALL PSX_CALLOC( ELI, ITYPE, IPCO, STATUS )

*  Allocate work space, unless the last pixel axis is being collapsed 
*  (in which case no work space is needed).
               IF ( HIGHER ) THEN
                  CALL PSX_CALLOC( ELC * CAEL, ITYPE, IPW3, STATUS )
               END IF

*  Obtain the double-precision co-ordinate centres along the collapse
*  axis in the current Frame.
               CALL KPG1_WCFAX( IBL, IWCS, IAXIS, ELI, 
     :                          %VAL( CNF_PVAL( IPAXCO ) ), STATUS )

*  Copy the centres to the required precision.
               IF ( ITYPE .EQ. '_REAL' ) THEN
                  CALL VEC_DTOR( .TRUE., ELI,
     :                           %VAL( CNF_PVAL( IPAXCO ) ),
     :                           %VAL( CNF_PVAL( IPCO ) ), IERR, NERR,
     :                           STATUS )

               ELSE IF ( ITYPE .EQ. '_DOUBLE' ) THEN
                  CALL VEC_DTOD( .TRUE., ELI,
     :                           %VAL( CNF_PVAL( IPAXCO ) ),
     :                           %VAL( CNF_PVAL( IPCO ) ), IERR, NERR,
     :                           STATUS )

               END IF
               CALL PSX_FREE( IPAXCO, STATUS )

*  Store safe pointer value if axis centres are not needed.
            ELSE
               IPCO = IPIN( 1 )
               IPW3 = IPIN( 1 )
            END IF

*  Associate AXIS-width information.
*  =================================

*  Obtain AXIS widths along the collapse axis for the following
*  methods.
            IF ( ESTIM .EQ. 'INTEG' ) THEN
         
*  Allocate work space for thw widths to be derived from the
*  co-ordinates.  This assumes full filling of pixels.
               CALL PSX_CALLOC( ELC * CAEL, ITYPE, IPWID, STATUS )

*  Store safe pointer value if widths are not needed.
            ELSE
               IPWID = IPIN( 1 )
            END IF

*  Collapse.
*  =========

*  Now do the work, using a routine appropriate to the numeric type.
            IF ( ITYPE .EQ. '_REAL' ) THEN
               CALL KPS1_CLPSR( JAXIS, LBNDS( JAXIS ), UBNDS( JAXIS ),
     :                          VAR, ESTIM, WLIM, ELC, NDIM, LBNDBI, 
     :                          UBNDBI, %VAL( CNF_PVAL( IPIN( 1 ) ) ),
     :                          %VAL( CNF_PVAL( IPIN( 2 ) ) ), 
     :                          %VAL( CNF_PVAL( IPCO ) ),
     :                          %VAL( CNF_PVAL( IPWID ) ), NDIMO, 
     :                          LBNDBO, UBNDBO, HIGHER,
     :                          %VAL( CNF_PVAL( IPCH( 1 ) ) ), 
     :                          %VAL( CNF_PVAL( IPCH( 2 ) ) ),
     :                          %VAL( CNF_PVAL( IPW1 ) ), 
     :                          %VAL( CNF_PVAL( IPW2 ) ), 
     :                          %VAL( CNF_PVAL( IPW3 ) ), STATUS )

            ELSE IF ( ITYPE .EQ. '_DOUBLE' ) THEN
               CALL KPS1_CLPSD( JAXIS, LBNDS( JAXIS ), UBNDS( JAXIS ),
     :                          VAR, ESTIM, WLIM, ELC, NDIM, LBNDBI, 
     :                          UBNDBI, %VAL( CNF_PVAL( IPIN( 1 ) ) ),
     :                          %VAL( CNF_PVAL( IPIN( 2 ) ) ), 
     :                          %VAL( CNF_PVAL( IPCO ) ),
     :                          %VAL( CNF_PVAL( IPWID ) ), NDIMO, 
     :                          LBNDBO, UBNDBO, HIGHER,
     :                          %VAL( CNF_PVAL( IPCH( 1 ) ) ), 
     :                          %VAL( CNF_PVAL( IPCH( 2 ) ) ),
     :                          %VAL( CNF_PVAL( IPW1 ) ), 
     :                          %VAL( CNF_PVAL( IPW2 ) ), 
     :                          %VAL( CNF_PVAL( IPW3 ) ), STATUS )

            ELSE IF ( STATUS .EQ. SAI__OK ) THEN
               STATUS = SAI__ERROR
               CALL MSG_SETC( 'T', ITYPE )
               CALL ERR_REP( 'CHANMAP_ERR5', 'CHANMAP: Unsupported '/
     :                       /'data type ^T (programming error).',
     :                       STATUS )
            END IF

*  Free the work space.
            IF ( HIGHER ) THEN
               CALL PSX_FREE( IPW1, STATUS )
               IF ( VAR ) CALL PSX_FREE( IPW2, STATUS )
            END IF

            IF ( ESTIM .EQ. 'COMAX' .OR. ESTIM .EQ. 'COMIN' .OR.
     :           ESTIM .EQ. 'IWC' .OR. ESTIM .EQ. 'IWD' ) THEN
                CALL PSX_FREE( IPCO, STATUS )
                IF ( HIGHER ) CALL PSX_FREE( IPW3, STATUS )
            END IF
         
            IF ( ESTIM .EQ. 'INTEG' ) THEN
               CALL PSX_FREE( IPWID, STATUS )
               IF ( HIGHER ) CALL PSX_FREE( IPW3, STATUS )
            END IF

*  Derive the offsets of the original input NDFs with respect to the
*  origin of the output NDF.  Also extract the dimensions of the
*  current NDF.
            DO J = 1, NDIMO
               OFFSET( J ) = ( CHIND( J ) - 1 ) * CHDIMS( J ) +
     :                       LBNDBO( J ) - LBNDC( J ) 
               CDIMS( J ) = UBNDBO( J ) - LBNDBO( J ) + 1
            END DO

*  Paste the data array.
*  =====================

*  Call the appropriate routine that performs the pasting of the data
*  array.
            IF ( ITYPE .EQ. '_REAL' ) THEN
               CALL KPG1_PASTR( .FALSE., BAD, OFFSET, CDIMS, ELC,
     :                          %VAL( CNF_PVAL( IPCH( 1 ) ) ), 
     :                          ODIMS, ELO,
     :                          %VAL( CNF_PVAL( IPOUT( 1 ) ) ), STATUS )

            ELSE IF ( ITYPE .EQ. '_DOUBLE' ) THEN
               CALL KPG1_PASTD( .FALSE., BAD, OFFSET, CDIMS, ELC,
     :                          %VAL( CNF_PVAL( IPCH( 1 ) ) ), 
     :                          ODIMS, ELO,
     :                          %VAL( CNF_PVAL( IPOUT( 1 ) ) ), STATUS )

            END IF

*  Paste the variance array.
*  =========================
            IF ( VAR ) THEN

*  Call the appropriate routine that performs the pasting of the data
*  array.
               IF ( ITYPE .EQ. '_REAL' ) THEN
                  CALL KPG1_PASTR( .FALSE., BAD, OFFSET, CDIMS, ELC,
     :                             %VAL( CNF_PVAL( IPCH( 2 ) ) ), 
     :                             ODIMS, ELO,
     :                             %VAL( CNF_PVAL( IPOUT( 2 ) ) ), 
     :                             STATUS )

               ELSE IF ( ITYPE .EQ. '_DOUBLE' ) THEN
                  CALL KPG1_PASTD( .FALSE., BAD, OFFSET, CDIMS, ELC,
     :                             %VAL( CNF_PVAL( IPCH( 2 ) ) ), 
     :                             ODIMS, ELO,
     :                             %VAL( CNF_PVAL( IPOUT( 2 ) ) ), 
     :                             STATUS )
               END IF
            END IF

*  Close NDF context.
            CALL NDF_END( STATUS )
         END DO

*  Create WCS Frame
*  ================

*  Each tile of the channel map should have three co-ordinates: the
*  spatial co-ordinates, that are the same for each tile; and a
*  constant co-ordinate representative of the channel, currently
*  the average of the channel bounds.  The goal is to be able to
*  inquire the spatial and spectral co-ordinates of a feature
*  (with a task like CURSOR).  The steps involved are as follows.
*
*  For each channel tile (i.e. ignoring any blocking) we proceed as
*  below.
*  a) Create a `route map' transforming two-dimensional PIXEL
*  co-ordinates in the output array into three-dimensional PIXEL
*  co-ordinates in the input cube.  This comprises a shift of origin of
*  the spatial PIXEL co-ordinates from the lower-left of the output 
*  array to the lower-left of the current tile, combined with a 
*  conversion to three dimensions, using a constant---the average 
*  co-ordinate along the collapsed axis---for the third dimension; and
*  b) Create intervals using the range of spatial PIXEL co-ordinates.

*  Once all the tiles have been pasted into the output array the
*  steps are as follows.
*  c) Form a SelectorMap using the array of spatial intervals from b).
*  d) In turn form a SwitchMap using the SelectorMap, and route maps
*  from step a).
*  e) Create a compound Mapping of the SwitchMap and the original
*  PIXEL-to-current Frame Mapping.  The result maps from
*  two-dimensional pixel to the input current Frame.
*  f) Add a new Frame to the output FrameSet using the Mapping
*  from step e) to connect the frameSet to the two-dimensional pixel
*  Frame.

*  Create a ShiftMap from two-dimensional co-ordinates in the large
*  output file (i.e. for the ICHth tile) to two-dimensional co-ordinates
*  in the original cube.
         DO J = 1, NDIMO
            SHIFTS( J ) = -DBLE( ( CHIND( J ) - 1 ) * CHDIMS( J ) )
         END DO
         SHIMAP = AST_SHIFTMAP( NDIMO, SHIFTS, ' ', STATUS )

*  Create a PermMap increasing the dimensionality by one and setting
*  the new dimension position to the average pixel position of the slab.
         CHAVER = DBLE( UBNDS( JAXIS ) + LBNDS( JAXIS ) - 1 ) * 0.5D0
         PERMAP = AST_PERMMAP( NDIMO, IPERM, NDIM, OPERM, CHAVER, ' ',
     :                         STATUS )

*  Combine the ShiftMap and the PermMap to form the route map for the
*  current tile.
         ROUMAP( ICH ) = AST_CMPMAP( SHIMAP, PERMAP, .TRUE., ' ',
     :                               STATUS )

*  Note that this would need changing if the tiles did not abut.  Also
*  the bounds are double precision.
         DO J = 1, NDIMO
             DLBNDS( J ) = DBLE( ( CHIND( J ) - 1 ) * CHDIMS( J ) )
             DUBNDS( J ) = DBLE( CHIND( J ) * CHDIMS( J ) ) - 1.0D-10
         END DO

         SLABIN( ICH ) = AST_INTERVAL( PFRMO, DLBNDS, DUBNDS, AST__NULL,
     :                                 ' ', STATUS )

*  Free up the AST resources we don't need to retain outside of the
*  channel loop.
         CALL AST_ANNUL( PERMAP, STATUS )
         CALL AST_ANNUL( SHIMAP, STATUS )
      END DO

*  Create the SelectorMap and SwitchMap.
      SELMAP = AST_SELECTORMAP( NOCHAN, SLABIN, ' ', STATUS )
      SWIMAP = AST_SWITCHMAP( SELMAP, AST__NULL, NOCHAN, ROUMAP,
     :                        ' ', STATUS )

*  Combine in sequence the SwitchMap (that goes from two-dimensional
*  PIXEL to three-dimensional PIXEL) with the Mapping from 
*  three-dimensional PIXEL co-ordinates to the original 
*  three-dimensional current Frame. 
      MAPC = AST_CMPMAP( SWIMAP, MAP, .TRUE., ' ', STATUS )

*  Add the input three-dimensional current Frame into the output 
*  FrameSet, using the above Mapping to connect it to the
*  two-dimensional PIXEL Frame.
      CALL AST_ADDFRAME( IWCSO, IPIXO, MAPC,
     :                   AST_GETFRAME( IWCS, AST__CURRENT, STATUS ),
     :                   STATUS )

*  Save this modified WCS FrameSet in the output NDF.
      CALL NDF_PTWCS( IWCSO, INDFO, STATUS )      

*  Come here if something has gone wrong.
  999 CONTINUE

*  End the NDF context.
      CALL NDF_END( STATUS )

*  End the AST context.
      CALL AST_END( STATUS )

*  Report a contextual message if anything went wrong.
      IF ( STATUS .NE. SAI__OK ) THEN
         CALL ERR_REP( 'CHANMAP_ERR6', 'CHANMAP: Unable to form '/
     :                 /'a channel-map NDF.', STATUS )
      END IF

      END
