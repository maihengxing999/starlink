package Starlink::Autoastrom;

=head1 NAME

Starlink::Autoastrom - Perform automated astrometric corrections on
an astronomical frame.

=head1 SYNOPSIS

use Starlink::Autoastrom;

my $auto = new Starlink::Autoastrom( ndf => $ndf );
$auto->solve;

=head1 DESCRIPTION

This module performs automated astrometric corrections on an astronomical
frame. It is essentially a wrapper around L<Starlink::Astrom> with bits
added on to allow one to pass an NDF and have its astrometry corrected.

=cut

use strict;

use Carp;
use File::Temp qw/ tempdir /;
use Data::Dumper;
# We need a wack of other modules.
#
# That's right, a WACK.
use Starlink::AST;
use Starlink::Astrom;
use Starlink::Extractor;
use Astro::Coords;
use Astro::Correlate;
use Astro::Catalog;
use Astro::Catalog::Query::SkyCat;
use Astro::FITS::HdrTrans qw/ translate_from_FITS /;
use Astro::FITS::Header;
use Astro::FITS::Header::NDF;
use Astro::WaveBand;
use NDF;

use vars qw/ $VERSION $DEBUG /;

$VERSION = '0.01';
$DEBUG = 0;

=head1 METHODS

=head2 Constructor

=over 4

=item B<new>

  $auto = new Starlink::Autoastrom( ndf => $ndf );

The constructor returns an C<Starlink::Autoastrom> object.

=cut

sub new {
  my $proto = shift;
  my $class = ref( $proto ) || $proto;

# Retrieve the arguments.
  my %args = @_;

# Create the object.
  my $auto = {};
  bless( $auto, $class );

# Configure the object.
  $auto->_configure( \%args );

# Set up default options.
  $auto->catalogue( 'USNO@ESO' ) if( ! defined( $auto->catalogue ) );
  $auto->defects( 'warn' ) if ( ! defined( $auto->defects ) );
  $auto->insert( 1 ) if ( ! defined( $auto->insert ) );
  $auto->keeptemps( 0 ) if ( ! defined( $auto->keeptemps ) );
  $auto->match( 'FINDOFF' ) if ( ! defined( $auto->match ) );
  $auto->maxfit( 6 ) if ( ! defined( $auto->maxfit ) );
  $auto->maxobj( 500 ) if ( ! defined( $auto->maxobj ) );
  $auto->messages( 1 ) if ( ! defined( $auto->messages ) );
  $auto->obsdata( 'source=USER:AST:FITS,angle=0,scale=1,invert=0' ) if ( ! defined( $auto->obsdata ) );
  $auto->temp( tempdir( CLEANUP => ( ! $auto->keeptemps ) ) ) if ( ! defined( $auto->temp ) );
  $auto->timeout( 180 ) if ( ! defined( $auto->timeout ) );
  $auto->verbose( 0 ) if ( ! defined( $auto->verbose ) );

# Return.
  return $auto;
}

=back

=head2 Accessor Methods

=over 4

=item B<bestfitlog>

Retrieve or set the filename to write information about the best fit
to.

  my $bestfitlog = $auto->bestfitlog
  $auto->bestfitlog( 'bestfit.log' );

Will write the file to the current working directory. If undefined,
which is the default, no log will be written.

=cut

sub bestfitlog {
  my $self = shift;
  if( @_ ) {
    my $bestfitlog = shift;
    $self->{BESTFITLOG} = $bestfitlog;
  }
  return $self->{BESTFITLOG};
}

=item B<catalogue>

Retrieve or set the SkyCat name of the online catalogue to use
for queries.

  my $skycat = $auto->catalogue;
  $auto->catalogue( 'usno@eso' );

Take care to avoid string interpolation with the @ sign. Returns a
string. Defaults to 'USNO@ESO'. The string is upper-cased when stored
and returned.

For a list of available SkyCat catalogue names, see
http://archive.eso.org/skycat/

=cut

sub catalogue {
  my $self = shift;
  if( @_ ) {
    my $catalogue = uc( shift );
    $self->{CATALOGUE} = $catalogue;
  }
  return $self->{CATALOGUE};
}

=item B<ccdcatalogue>

Retrieve or set a pre-existing catalogue of objects in the CCD frame.

  my $ccdcatalogue = $auto->ccdcatalogue;
  $auto->ccdcatalogue( 'm31.cat' );

The format is that as produced as output by SExtractor when the
CATALOG_TYPE parameter is set to ASCII_HEAD. The catalogue must
have all of the fields NUMBER, FLUX_ISO, X_IMAGE, Y_IMAGE, A_IMAGE,
B_IMAGE, X2_IMAGE, Y2_IMAGE, ERRX2_IMAGE, ERRY2_IMAGE, and ISOAREA_IMAGE,
of which X2_IMAGE, Y2_IMAGE, A_IMAGE, B_IMAGE, ERRX2_IMAGE, and
ERRY2_IMAGE are not generated by default.

This parameter defaults to undef, which means a catalogue will be
formed by running SExtractor on the input frame instead of relying
on the pre-existing catalogue.

=cut

sub ccdcatalogue {
  my $self = shift;
  if( @_ ) {
    my $ccdcatalogue = shift;
    $self->{CCDCATALOGUE} = $ccdcatalogue;
  }
  return $self->{CCDCATALOGUE};
}

=item B<defects>

Retrieve or set the keyword that dictates how defects in the
CCD catalogue are treated.

  my $defects = $auto->defects;
  $auto->defects( 'remove' );

This method can take one of four possible keywords:

=over 4

=item ignore - Completely ignore defects.

=item warn - Warn about possible defects, but do nothing further.

=item remove - Remove any suspected defects from the catalogue of
CCD objects.

=item badness - Provide the threshold for defect removal and warnings.
Any objects with a badness greater than the value specified here are
noted or removed.

=back

The badness heuristic works by assigning a 'badness' to each object
detected. Objects with a position variance smaller than one pixel
and whose flux density is significantly higher than the average
are given high scores.

The default behaviour is to warn about possible defects (i.e. the
default keyword is 'warn'), and the default badness level is 1.

To set the badness level, set this keyword to 'badness=2' if, for example,
you wanted the badness threshold to be 2.

=cut

sub defects {
  my $self = shift;
  if( @_ ) {
    my $defects = shift;
    if( $defects !~ /^(ignore|warn|remove|badness)/i ) {
      $defects = 'warn';
    } else {
      $defects = lc( $defects );
    }
    $self->{DEFECTS} = $defects;
  }
  return $self->{DEFECTS};
}

=item B<insert>

Whether or not to insert the final astrometric fit into the input NDF
as an AST WCS component. If false, the insertion is not done.

  my $insert = $auto->insert;
  $auto->insert( 1 );

The default is true.

=cut

sub insert {
  my $self = shift;
  if( @_ ) {
    my $insert = shift;
    $self->{INSERT} = $insert;
  }
  return $self->{INSERT};
}

=item B<keepfits>

Whether or not to keep the final astrometric fit as a FITS-WCS file.

  my $keepfits = $auto->keepfits;
  $auto->keepfits('wcs.fits');

If this parameter is undefined (which is the default), then no FITS-WCS
file will be kept. If it is defined, then the FITS-WCS file will have
the name given as this value. Using the above example, the FITS-WCS
file will be saved as 'wcs.fits' in the current working directory.

=cut

sub keepfits {
  my $self = shift;
  if( @_ ) {
    my $keepfits = shift;
    $self->{KEEPFITS} = $keepfits;
  }
  return $self->{KEEPFITS};
}

=item B<keeptemps>

Whether or not to keep temporary files after processing is completed.

  my $keeptemps = $auto->keeptemps;
  $auto->keeptemps( 1 );

Temporary files are created in a temporary directory that is reported
during execution. The location of this temporary directory can be
controlled using the C<temp> method.

This parameter defaults to false, so all temporary files are deleted
after processing.

=cut

sub keeptemps {
  my $self = shift;
  if( @_ ) {
    my $keeptemps = shift;
    $self->{KEEPTEMPS} = $keeptemps;
  }
  return $self->{KEEPTEMPS};
}

=item B<match>

The matching algorithm to be used.

  my $match = $auto->match;
  $auto->match( 'FINDOFF' );

Currently, the only available matching algorithm is the Starlink
FINDOFF application, part of CCDPACK. FINDOFF has certain limitations
(i.e. it's slow, it doesn't work if you have unequal X and Y scales),
but works if your data get around these limitations.

=cut

sub match {
  my $self = shift;
  return $self->{MATCH};
}

=item B<matchcatalogue>

Retrieve or set a filename that will take the set of positions matched
by the matching process. The file is formatted like a SExtractor output
file with five columns: the object number, RA and Dec of the source on
the sky, and x and y positions of the source on the CCD.

  my $matchcatalogue = $auto->matchcatalogue;
  $auto->matchcatalogue( 'match.cat' );

Defaults to undef, meaning that no such file will be written. If defined,
it will write the catalogue in the current working directory.

=cut

sub matchcatalogue {
  my $self = shift;
  if( @_ ) {
    my $matchcatalogue = shift;
    $self->{MATCHCATALOGUE} = $matchcatalogue;
  }
  return $self->{MATCHCATALOGUE};
}

=item B<maxfit>

Retrieve or set the maximum number of fit parameters to use to obtain
the astrometric fit.

  my $maxfit = $auto->maxfit;
  $auto->maxfit( 7 );

Allowed values are 6, 7, and 9, and the default is 6.

=cut

sub maxfit {
  my $self = shift;
  if( @_ ) {
    my $maxfit = shift;
    if( $maxfit != 6 ||
        $maxfit != 7 ||
        $maxfit != 9 ) {
      $maxfit = 6;
    }
    $self->{MAXFIT} = $maxfit;
  }
  return $self->{MAXFIT};
}

=item B<maxobj>

Retrieve or set the maximum number of objects to retrieve from the
catalogue server.

  my $maxobj = $auto->maxobj;
  $auto->maxobj( 1000 );

Defaults to 500.

=cut

sub maxobj {
  my $self = shift;
  if( @_ ) {
    my $maxobj = shift;
    $self->{MAXOBJ} = $maxobj;
  }
  return $self->{MAXOBJ};
}

=item B<messages>

Whether or not to display messages from the Starlink applications.

  my $messages = $auto->messages;
  $auto->messages( 0 );

Defaults to true (1).

=cut

sub messages {
  my $self = shift;
  if( @_ ) {
    my $messages = shift;
    $self->{MESSAGES} = $messages;
  }
  return $self->{MESSAGES};
}

=item B<ndf>

Retrieve or set the NDF that will have its astrometry solved.

  my $ndf = $auto->ndf;
  $auto->ndf( $ndf );

Returns a string.

=cut

sub ndf {
  my $self = shift;
  if( @_ ) {
    my $ndf = shift;
    $self->{NDF} = $ndf;
  }
  return $self->{NDF};
}

=item B<obsdata>

Retrieve or set a source for the observation data, including WCS
information.

  my $obsdata = $auto->obsdata;
  $auto->obsdata( $obsdata );

This method returns or takes a hash reference containing the following
keys:

=over 4

=item source - A colon-separated list of sources of WCS information.
The values may be 'AST', indicating that the information should come
from the AST WCS component of the WCS, 'FITS', indicating that it
should come from any FITS extension in the NDF, or 'USER', indicating
that values given by this method are to be used. The default is
'USER:AST:FITS', so that any WCS information given by this method
has precedence. The values are not case-sensitive. If no WCS information
can be obtained, an error will be thrown.

=item ra - Right ascension of the centre of the pixel grid, given in
colon-separated HMS or decimal hours. This is stored internally
as an C<Astro::Coords::Angle::Hour> object, and if the obsdata()
method is called then the value for this key will also be an
C<Astro::Coords::Angle::Hour> object.

=item dec - Declination of the centre of the pixel grid, given in colon-
separated DMS or decimal degrees. This is stored internally as an
C<Astro::Coords::Angle> object, and if the obsdata() method is called then
the value for this key will also be an C<Astro::Coords::Angle> object.

=item angle - Position angle of the pixel grid. This is the rotation
in degrees counter-clockwise of the declination axis with respect to
the y-axis of the data array. Defaults to 0.

=item scale - Plate scale in arcseconds per pixel. Defaults to 1.

=item invert - If true, the axes are inverted. Defaults to 0.

=back

There are additional observation data keywords that can be defined.
These are used to refine higher-order astrometric fits.

=over 4

=item time - An observation time, given as a Julian epoch (in the
format r), a local sideral time (in the format i:i), or UT (in the
format i:i:i:i:r specifying four-digit year, month, day, hours,
and minutes).

=item obs - An observation station, given either as one of the
SLALIB observatory codes, or in the format i:r:i:r[:r] specifying
longitude, latitude, and optional height. Longitudes are east longitudes,
so west longitudes may be given as minus degrees or longitudes
greater than 180.

=item met - Temperature and pressure at the telescope, in degrees
Kelvin and millibars. The defaults are 278K and a pressure computed
from the observatory height. Format r[:r].

=item col - The effective colour of the observations, as a wavelength
in nanometres. The default is 500nm.

=back

In the format specifications for the above four keywords, r represents
a real, i represents an integer, and optional entries are in [...].

When returned as a hash reference, the keys have been converted to upper-case.
For example, to retrieve the value for the 'source', you would do:

  $source = $auto->obsdata->{'SOURCE'};

=cut

sub obsdata {
  my $self = shift;
  if( @_ ) {
    my $obsdata_input = shift;
    my @obsdata = split( ',', $obsdata_input );
    foreach my $thing ( @obsdata ) {
      ( my $key, my $value ) = split( '=', $thing );
      $key = uc( $key );

      # Perform format checking on the value.

      if( $key eq 'SOURCE' ) {
        my @values = split( ':', $value );
        my @valid = map { uc($_) } grep { /^(ast|fits|user)$/i } @values;
        $value = join ':', @valid;
      }

      if( $key eq 'RA' ) {
        # Convert to Astro::Coords::Angle::Hour object.
        if( $value =~ /^\d+:\d+:[\d\.]+$/ ) {
          $value = new Astro::Coords::Angle::Hour( $value, units => 'sex' );
        } elsif( $value =~ /^[\d\.]+$/ ) {
          $value = new Astro::Coords::Angle::Hour( $value, units => 'hour' );
        } else {
          croak "Could not parse $value to form Right Ascension from obsdata information";
        }
      }

      if( $key eq 'DEC' ) {
        # Convert to Astro::Coords::Angle object.
        if( $value =~ /^-?\d+:\d+:[\d\.]+$/ ) {
          $value = new Astro::Coords::Angle( $value, units => 'sex' );
        } elsif( $value =~ /^-?[\d\.]+$/ ) {
          $value = new Astro::Coords::Angle( $value, units => 'hour' );
        } else {
          croak "Could not parse $value to form Declination from obsdata information";
        }
      }

      if( $key eq 'ANGLE' ) {
        if( $value !~ /^-?\d+(\.\d*)?$/ ) {
          carp "Cannot parse position angle of $value from obsdata information. Setting position angle to 0 degrees";
          $value = 0;
        }
      }

      if( $key eq 'SCALE' ) {
        if( $value !~ /^\d+(\.\d*)?$/ ) {
          carp "Cannot parse plate scale of $value from obsdata information. Setting plate scale to 1 arcsec/pixel";
          $value = 1;
        }
      }

      if( $key eq 'INVERT' ) {
        if( ( $value != 1 ) && ( $value != 0 ) ) {
          carp "Value of invert from obsdata information must be 0 or 1, not $value. Setting invert to 0";
          $value = 0;
        }
      }

      if( $key eq 'TIME' ) {
        if( $value !~ /^\d+(\.\d+)?$/ ||
            $value !~ /^\d+:\d+$/ ||
            $value !~ /^\d+:\d+:\d+:\d+:\d+(\.\d*)?$/ ) {
          croak "Could not parse time of $value from obsdata information";
        }
      }

      if( $key eq 'OBS' ) {
        if( $value !~ /^([\w\.])+$/ ||
            $value !~ /^-?\d+:\d+(\.\d*)?:\d+:\d+(\.\d*)?(:\d+(\.\d*)?)?$/ ) {
          # And who says Perl is line noise? :-)
          croak "Could not parse observatory code of $value from obsdata information";
        }
      }

      if( $key eq 'MET' ) {
        if( $value !~ /^\d+(\.\d*)?(:\d+(\.\d*)?)?$/ ) {
          croak "Could not parse meteorological information of $value from obsdata information";
        }
      }

      if( $key eq 'COL' ) {
        if( $value !~ /^\d+(\.\d*)?$/ ) {
          croak "Could not parse effective colour of $value from obsdata information";
        }
      }

      $self->{OBSDATA}->{$key} = $value;
    }
  }

  # Make sure defaults are set up.
  $self->{OBSDATA}->{ANGLE} = 0 unless defined( $self->{OBSDATA}->{ANGLE} );
  $self->{OBSDATA}->{SCALE} = 1 unless defined( $self->{OBSDATA}->{SCALE} );
  $self->{OBSDATA}->{INVERT} = 0 unless defined( $self->{OBSDATA}->{INVERT} );
  $self->{OBSDATA}->{SOURCE} = 'USER:AST:FITS' unless defined( $self->{OBSDATA}->{SOURCE} );

  return $self->{OBSDATA};
}

=item B<skycatconfig>

Retrieve or set the location of the SkyCat configuration file.

  my $skycatconfig = $auto->skycatconfig;
  $auto->skycatconfig( '/home/bradc/skycat.cfg' );

This method checks to see if the file exists, and if it doesn't,
croaks.

=cut

sub skycatconfig {
  my $self = shift;
  if( @_ ) {
    my $skycatconfig = shift;
    if( ! -e $skycatconfig ) {
      croak "Could not find $skycatconfig";
    }
    $self->{SKYCATCONFIG} = $skycatconfig;
  }
  return $self->{SKYCATCONFIG};
}

=item B<temp>

Retrieve or set the directory to be used for temporary files.

  my $temp = $auto->temp;
  $auto->temp( '/tmp' );

If undef (which is the default), a temporary directory will be
created using C<File::Temp>.

=cut

sub temp {
  my $self = shift;
  if( @_ ) {
    my $temp = shift;
    $self->{TEMP} = $temp;
  }
  return $self->{TEMP};
}

=item B<timeout>

Retrieve or set the timeout for Starlink applications to return.

  my $timeout = $auto->timeout;
  $auto->timeout( 30 );

The time is in seconds, and defaults to 180.

=cut

sub timeout {
  my $self = shift;
  if( @_ ) {
    my $timeout = shift;
    $self->{TIMEOUT} = $timeout;
  }
  return $self->{TIMEOUT};
}

=item B<verbose>

Retrieve or set the verbosity level.

  my $verbose = $auto->verbose;
  $auto->verbose( 1 );

If set to true, then much output will be output to STD_ERR. Defaults to false.

=cut

sub verbose {
  my $self = shift;
  if( @_ ) {
    my $verbose = shift;
    $self->{VERBOSE} = $verbose;
  }
  return $self->{VERBOSE};
}

=back

=head2 General Methods

=over 4

=item B<solve>

Perform automated astrometry correction for the supplied NDF.

  $auto->solve;

This method modifies the WCS for the NDF in place.

=cut

sub solve {
  my $self = shift;

# Retrieve the name of the NDF, croaking if it's undefined.
  if( ! defined( $self->ndf ) ) {
    croak "Must supply NDF in order to perform automated astrometry correction";
  }

# We need some kind of coordinates to use. Go through the list
# of sources given in obsdata->{SOURCE} and find the first one
# that returns.
  my $cencoords;
  my $radius;
  my $epoch;
  my $frameset;

  foreach my $wcssource ( split( /\s*:\s*/, $self->obsdata->{SOURCE} ) ) {

    if( $wcssource =~ /AST/ ) {

# Check for an AST component. It needs to be a proper RA/Dec SkyFrame,
# so set up an FK5 template and see if one of those exists in the WCS
# returned via ndfGtwcs.
      my $STATUS = 0;

      err_begin( $STATUS );
      ndf_begin();
      ndf_find( &NDF::DAT__ROOT, $self->ndf, my $ndf_id, $STATUS );
      my $wcs = ndfGtwcs( $ndf_id, $STATUS );
      ndf_annul( $ndf_id, $STATUS );
      ndf_end( $STATUS );

      # Handle errors.
      if( $STATUS != &NDF::SAI__OK ) {
        my ( $oplen, @errs );
        do {
          err_load( my $param, my $parlen, my $opstr, $oplen, $STATUS );
          push @errs, $opstr;
        } until ( $oplen == 1 );
        err_annul( $STATUS );
        err_end( $STATUS );
        croak "Error retrieving WCS from NDF:\n" . join "\n", @errs;
      }
      err_end( $STATUS );

      my $template = new Starlink::AST::SkyFrame( "System=FK5" );
      $frameset = $wcs->FindFrame( $template, "" );
      if( defined( $frameset ) ) {
        print "WCS information from AST.\n" if $self->verbose;
        print STDERR "WCS information from AST.\n" if $self->verbose;

# Determine the central coordinates and radius of search from information
# contained in the frameset and the NDF.
        ( $cencoords, $radius ) = _determine_search_params( frameset => $frameset,
                                                           ndf => $self->ndf );
        $epoch = $frameset->GetC("Epoch");
        if( ! defined( $epoch ) ) {
          carp "Epoch not defined in FITS headers. Defaulting to 2000.0";
          $epoch = "2000.0";
        }

        last;
      } else {
        print STDERR "AST WCS information doesn't have a SKY frame.\n" if $self->verbose;
        print "AST WCS information doesn't have a SKY frame.\n" if $self->verbose;
      }

    } elsif( $wcssource =~ /FITS/ ) {

# Check the FITS header for WCS information.
      my $hdr = new Astro::FITS::Header::NDF( File => $self->ndf );
      my $wcs = $hdr->get_wcs;
      my $template = new Starlink::AST::SkyFrame( "System=FK5" );
      $frameset = $wcs->FindFrame( $template, "" );
      if( defined( $frameset ) ) {
        print "Using WCS information from FITS headers.\n" if $self->verbose;
        print STDERR "WCS information from FITS headers.\n" if $self->verbose;

# Determine the central coordinates and radius of search from information
# contained in the frameset and the NDF.
        ( $cencoords, $radius ) = _determine_search_params( frameset => $frameset,
                                                            ndf => $self->ndf );

        $epoch = $frameset->GetC("Epoch");
        if( ! defined( $epoch ) ) {
          carp "Epoch not defined in FITS headers. Defaulting to 2000.0";
          $epoch = "2000.0";
        }

        last;
      } else {
        print "FITS headers have no useable WCS information.\n" if $self->verbose;
      }

    } elsif( $wcssource =~ /USER/ ) {

# We need, at a bare minimum, the RA and Dec.
      if( ! defined( $self->obsdata->{RA} ) ) {
        print "RA not supplied for USER WCS, not using USER-supplied WCS.\n" if $self->verbose;
        next;
      }
      if( ! defined( $self->obsdata->{DEC} ) ) {
        print "Dec not supplied for USER WCS, not using USER-supplied WCS.\n" if $self->verbose;
        next;
      }
      print "Using WCS information from USER-supplied coordinates\n" if $self->verbose;

# Determine the central coordinates and radius of search from information
# contained in the obsdata information and the NDF.
      ( $cencoords, $radius ) = _determine_search_params( obsdata => $self->obsdata,
                                                          ndf => $self->ndf );
      $frameset = $self->_create_frameset;
      $epoch = $frameset->GetC("Epoch");
      if( ! defined( $epoch ) ) {
        carp "Epoch not defined in user-supplied information. Defaulting to 2000.0";
        $epoch = "2000.0";
      }

      last;
    }
  }

  print sprintf( "Central coordinates: $cencoords\nSearch radius: %.4f arcminutes\n", $radius ) if $self->verbose;

# If we have a user-supplied catalogue, use that. Otherwise, use
# Starlink::Extractor to extract objects from the NDF.
  my $ndfcat;
  if( defined( $self->ccdcatalogue ) ) {
    print "Using " . $self->ccdcatalogue . " as input catalogue for sources in frame.\n" if $self->verbose;
    $ndfcat = new Astro::Catalog( Format => 'SExtractor',
                                  File => $self->ccdcatalogue );
  } else {
    print "Extracting objects in " . $self->ndf . " at 5.0 sigma or higher..." if $self->verbose;
    my $filter = new Astro::WaveBand( Filter => 'unknown' );
    my $ext = new Starlink::Extractor;
    $ext->detect_thresh( 5.0 );
    $ndfcat = $ext->extract( frame => $self->ndf,
                             filter => $filter );
    print "done.\n" if $self->verbose;
  }

# We cannot do automated astrometry corrections if we have fewer
# than 4 objects, so croak if we do.
  if( $ndfcat->sizeof < 4 ) {
    croak "Only detected " . $ndfcat->sizeof . " objects in " . $self->ndf . ". Cannot perform automated astrometry corrections with so few objects";
  }

# Query the SkyCat catalogue.
  my $racen = $cencoords->ra2000;
  my $deccen = $cencoords->dec2000;
  $racen->str_delim(' ');
  $deccen->str_delim(' ');

  $racen = "$racen";
  $deccen = "$deccen";
  $racen =~ s/^\s+//;
  $deccen =~ s/^\s+//;

  print "Querying " . $self->catalogue . "..." if $self->verbose;
  my $query = new Astro::Catalog::Query::SkyCat( catalog => $self->catalogue,
                                                 RA => "$racen",
                                                 Dec => "$deccen",
                                                 Radius => $radius,
                                               );
  my $querycat = $query->querydb();
  print "done.\n" if $self->verbose;

# Again, croak if we have fewer than 4 objects.
  if( $querycat->sizeof < 4 ) {
    croak "Only retrieved " . $querycat->sizeof . " objects from " . $self->catalogue . ". Cannot perform automated astrometry corrections with so few objects";
  }

# Add the NDF's WCS to the 2MASS catalogue, allowing us to get
# X and Y positions for the retrieved objects.
  my $allstars = $querycat->allstars;
  foreach my $star ( @$allstars ) {
    $star->wcs( $frameset );
  }

# Perform the correlation.
  my $corr = new Astro::Correlate( catalog1 => $ndfcat,
                                   catalog2 => $querycat );
  ( my $corrndfcat, my $corrquerycat ) = $corr->correlate( method => 'FINDOFF',
                                                           verbose => $self->verbose );

# And yes, croak if the correlation resulted in fewer than 4 matches.
  if( $corrndfcat->sizeof < 4 ) {
    croak "Only " . $corrndfcat->sizeof . " object matched between reference catalogue and extracted catalogue. Cannot perform automated astrometry corrections with so few objects";
  }

# Merge the two catalogues so that the RA/Dec from 2MASS matches
# with the x/y from the extracted catalogue. This allows us to
# perform the astrometric solution.
  my $merged = new Astro::Catalog;
  $merged->fieldcentre( Coords => $cencoords );
  my $nobjs = $corrndfcat->sizeof;
  for( my $i = 1; $i <= $nobjs; $i++ ) {
    my $ndfstar = $corrndfcat->popstarbyid( $i );
    $ndfstar = $ndfstar->[0];
    my $querystar = $corrquerycat->popstarbyid( $i );
    $querystar = $querystar->[0];
    my $newstar = new Astro::Catalog::Star( ID => $querystar->id,
                                            Coords => $querystar->coords,
                                            X => $ndfstar->x,
                                            Y => $ndfstar->y,
                                            WCS => $querystar->wcs,
                                          );
    $merged->pushstar( $newstar );
  }

# Solve astrometry.
  my $astrom = new Starlink::Astrom( catalog => $merged );
  my $newwcs = $astrom->solve;

# Stick the WCS into the NDF.
  my $STATUS = &NDF::SAI__OK;
  err_begin($STATUS);
  ndf_begin();
  ndf_open( &NDF::DAT__ROOT(), $self->ndf, 'UPDATE', 'OLD', my $ndf_id, my $place, $STATUS );
  ndfPtwcs( $newwcs, $ndf_id, $STATUS );
  ndf_annul( $ndf_id, $STATUS );

  # extract error messages and annul error status

  ndf_end($STATUS);
  if( $STATUS != &NDF::SAI__OK ) {
    my ( $oplen, @errs );
    do {
      err_load( my $param, my $parlen, my $opstr, $oplen, $STATUS );
      push @errs, $opstr;
    } until ( $oplen == 1 );
    err_annul( $STATUS );
    err_end( $STATUS );
    croak "Error writing new WCS to NDF:\n" . join "\n", @errs;
  }

  err_end( $STATUS );

  print "WCS updated in " . $self->ndf . "\n" if $self->verbose;
}

=back

=head2 Private Methods

The following methods are private and are not exported.

=over 4

=item B<_configure>

Configures the object.

  $auto->configure( $args );

Takes one argument, a hash reference. The hash contains key/value pairs
that correspond to the various accessor methods of this module.

=cut

sub _configure {
  my $self = shift;
  my $args = shift;

  foreach my $key ( keys %$args ) {
    if( $self->can( $key ) ) {
      $self->$key( $args->{$key} );
    }
  }
}

=item B<_create_frameset>

Create a Starlink::AST Frameset object from user-supplied observation data
and an NDF.

  my $frameset = $self->_create_frameset;

There must be sufficient information in the observation data stored in the
obsdata accessor to create a frameset. This information is RA, Dec, and
plate scale. The RA and Dec will refer to the central pixel of the NDF.

=cut

sub _create_frameset {
  my $self = shift;

  if( ! defined( $self->obsdata->{RA} ) ||
      ! defined( $self->obsdata->{DEC} ) ) {
    croak "obsdata information must include RA and Dec to form an AST FrameSet";
  }

  my $ra = $self->obsdata->{RA}->degrees;
  my $dec = $self->obsdata->{DEC}->degrees;
  my $scale = $self->obsdata->{SCALE} / 3600;
  my $rotangle = $self->obsdata->{ANGLE} * 3.1415926535 / 180.0;
  my $invert = $self->obsdata->{INVERT};
  my $ndf = $self->ndf;

  my $epoch;
  if( defined( $self->obsdata->{TIME} ) ) {
    $epoch = parse_fits_date( $self->obsdata->{TIME} );
  } else {
    $epoch = '2000.0';
  }

  my $sign = 1;
  if( $invert ) {
    $sign = -1;
  }

  # Get the central coordinates of the NDF.
  ( my $xcen, my $ycen ) = central_coordinates( $ndf );

  # Create a string of FITS headers that can represent the WCS.
  # Follow the FITS Paper II convention, using the CDn_n matrix.
  my $fits = '';
  $fits .= sprintf( "RADESYS = 'FK5     '           / Mean IAU 1984 equatorial co-ordinates          " );
  $fits .= sprintf( "WCSAXES =                    2 / Number of axes in world co-ordinate system     " );
  $fits .= sprintf( "CTYPE1  = 'DEC--TAN'           / Dec tangent-plane axis with no distortion      " );
  $fits .= sprintf( "CTYPE2  = 'RA---TAN'           / RA tangent-plane axis with no distortion       " );
  $fits .= sprintf( "CUNIT1  = 'deg     '           / Unit of declination co-ordinates               " );
  $fits .= sprintf( "CUNIT2  = 'deg     '           / Unit of right ascension co-ordinates           " );
  $fits .= sprintf( "CRVAL1  =   %18.12f / [deg] Declination at the reference pixel       ", $dec );
  $fits .= sprintf( "CRVAL2  =   %18.12f / [deg] Right ascension at the reference pixel   ", $ra );
  $fits .= sprintf( "CRPIX1  =                %5.1f / [pixel] Reference pixel along Dec axis         ", $xcen );
  $fits .= sprintf( "CRPIX2  =                %5.1f / [pixel] Reference pixel along RA axis          ", $ycen );
  $fits .= sprintf( "CD1_1   =   %18.12f /                                                ", $sign * $scale * cos( $rotangle ) );
  $fits .= sprintf( "CD1_2   =   %18.12f /                                                ", $sign * $scale * sin( $rotangle ) );
  $fits .= sprintf( "CD2_1   =   %18.12f /                                                ", -1.0 * $scale * sin( $rotangle ) );
  $fits .= sprintf( "CD2_2   =   %18.12f /                                                ", $scale * cos( $rotangle ) );
  $fits .= sprintf( "EQUINOX =   %18.1f /                                                ", $epoch );

  # Pass the header on to the FitsChan creator.
  my $fitschan = new Starlink::AST::FitsChan;
  $fitschan->PutCards( $fits );

  my $frameset = $fitschan->Read;

  return $frameset;
}

=item B<central_coordinates>

Determine the coordinates of the central pixel of an NDF.

  ( $xcen, $ycen ) = central_coordinates( $ndf );

=cut

sub central_coordinates {
  my $ndf = shift;

  my $STATUS = 0;
  err_begin( $STATUS );
  ndf_begin();
  ndf_find( &NDF::DAT__ROOT(), $ndf, my $ndf_id, $STATUS );
  ndf_bound( $ndf_id, 2, my @lbnd, my @ubnd, my $ndim, $STATUS );
  ndf_annul( $ndf_id, $STATUS );
  ndf_end( $STATUS );

  # Handle errors
  if ( $STATUS != &NDF::SAI__OK ) {
    my ( $oplen, @errs );
    do {
      err_load( my $param, my $parlen, my $opstr, $oplen, $STATUS );
      push @errs, $opstr;
    } until ( $oplen == 1 );
    err_annul( $STATUS );
    err_end( $STATUS );
    croak "Error determining central coordinates of NDF:\n" . join "\n", @errs;
  }
  err_end( $STATUS );

  my $xcen = ( $lbnd[0] + $ubnd[0] ) / 2;
  my $ycen = ( $lbnd[1] + $ubnd[1] ) / 2;

  return ( $xcen, $ycen );

}

=item B<determine_search_params>

Determines the search parameters - central coordinates and search radius.

  ( $racen, $deccen, $radius ) = _determine_search_params( frameset => $frameset,
                                                           ndf => $ndf );

There are three possible named parameters:

=item * frameset - A Starlink::AST object containing information about the WCS.

=item * ndf - An NDF that can be queried for x and y dimensions.

=item * obsdata - A hash reference containing information as described in the
obsdata method, above.

Sufficient information must be contained in the input to be able to calculate
the output, which usually means either a frameset or RA and Dec in the obsdata
information. An NDF is definitely mandatory.

This function returns two values, an Astro::Coords object for the centre of the
field and the search radius in arcminutes.

=cut

sub _determine_search_params {
  my %args = @_;

  my $cencoords;
  my $radius;

  my $frameset;
  if( exists( $args{'frameset'} ) && defined( $args{'frameset'} ) ) {
    $frameset = $args{'frameset'};
  }
  my $ndf;
  if( exists( $args{'ndf'} ) && defined( $args{'ndf'} ) ) {
    $ndf = $args{'ndf'};
  } else {
    croak "Must supply an NDF to _determine_search_params";
  }
  my $obsdata;
  if( exists( $args{'obsdata'} ) && defined( $args{'obsdata'} ) ) {
    $obsdata = $args{'obsdata'};
  }

# Determine the bounds of the NDF.
  my $STATUS = 0;
  err_begin( $STATUS );
  ndf_begin();
  ndf_find( &NDF::DAT__ROOT(), $ndf, my $ndf_id, $STATUS );
  ndf_bound( $ndf_id, 2, my @lbnd, my @ubnd, my $ndim, $STATUS );
  ndf_annul( $ndf_id, $STATUS );
  ndf_end( $STATUS );

# Handle errors.
  if( $STATUS != &NDF::SAI__OK ) {
    my ( $oplen, @errs );
    do {
      err_load( my $param, my $parlen, my $opstr, $oplen, $STATUS );
      push @errs, $opstr;
    } until ( $oplen == 1 );
    err_annul( $STATUS );
    err_end( $STATUS );
    croak "Error determining NDF pixel bounds:\n" . join "\n", @errs;
  }
  err_end( $STATUS );

  my $xcen = ( $lbnd[0] + $ubnd[0] ) / 2;
  my $ycen = ( $lbnd[1] + $ubnd[1] ) / 2;

  if( defined( $frameset ) ) {
    ( my $ra, my $dec ) = $frameset->Tran2( [$xcen, $lbnd[0]], [$ycen, $lbnd[1]], 1 );
    my $racen = $ra->[0];
    my $deccen = $dec->[0];
    my $rabotleft = $ra->[1];
    my $decbotleft = $dec->[1];

    $cencoords = new Astro::Coords( ra => $racen,
                                    dec => $deccen,
                                    type => 'J2000',
                                    units => 'radians' );
    my $cornercoords = new Astro::Coords( ra => $rabotleft,
                                          dec => $decbotleft,
                                          type => 'J2000',
                                          units => 'radians' );

    my $radius_angle = $cencoords->distance( $cornercoords );
    $radius = $radius_angle->arcmin;

  } elsif( defined( $obsdata ) ) {
    $cencoords = new Astro::Coords( ra => $obsdata->{RA},
                                    dec => $obsdata->{DEC},
                                    type => 'J2000' );

    # Distance between centre and corner is...
    my $rad_pixels = sqrt( ( $lbnd[0] - $xcen ) * ( $lbnd[0] - $xcen ) +
                           ( $lbnd[1] - $ycen ) * ( $lbnd[1] - $ycen ) );

    $radius = $rad_pixels * $obsdata->{SCALE} / 60;
  }

  return ( $cencoords, $radius );

}

=item B<ymd2jd>

Converts year, month, and day to a Julian Day number.

  my $jd = ymd2jd( $year, $month, $day );

This function assumes noon for the day in question. The year must be
a four-digit integer between 1000 and 3000. The month must be an integer
between 1 and 12, and the day must be an integer between 1 and 31. There
is no sanity checking on the date, so dates of 31 February are perfectly
valid.

This function returns the Julian Day number. If the input parameters are
outside their defined ranges, undef will be returned.

The formula that does the calculation is from Graham Woan's 'The Cambridge
Handbook of Physics Formulas'.

=cut

sub ymd2jd {
  # Use the standard formula to convert Gregorian dates to Julian
  # Day numbers
  use integer;
  my ($year, $month, $day) = @_;

  # Year is (1000..3000), month is in (1..12), day in (1..31).  The
  # restriction on year is not because of any limitation on the
  # validity of the formula, but to guard against silly parameters
  # (eg, 2-digit dates).
  my $err;
  if( $year < 1000 || $year > 3000 ) {
    carp "Input year to ymd2jd() of $year must be between 1000 and 3000";
    return undef;
  }
  if( $month < 1 || $month > 12 ) {
    carp "Input month to ymd2jd() of $month must be between 1 and 12";
    return undef;
  }
  if( $day < 1 || $day > 31 ) {
    carp "Input day to ymd2jd() of $day must be between 1 and 31";
    return undef;
  }

# Here comes the big calculation...
  return $day - 32075 + 1461 * ( $year + 4800 + ( $month - 14 ) / 12 ) / 4
         + 367 * ( $month - 2 - ( $month - 14 ) / 12 * 12 ) / 12
         - 3 * ( ( $year + 4900 + ( $month - 14 ) / 12 ) / 100 ) / 4;
}

=item B<jd2je>

Converts Julian Day to Julian epoch.

  my $je = jd2je( $jd );

The conversion from JD is from Robin Green's 'Spherical Astronomy',
section 10.5.

=cut

sub jd2je {
  my $jd = shift;
  return 2000.0 + ($jd - 2451545)/365.25;
}

=item B<ymd2je>

Converts year, month, and day to a Julian epoch.

  my $je = ymd2je( $year, $month, $day );

This function assumes noon for the day in question. The year must be
a four-digit integer between 1000 and 3000. The month must be an integer
between 1 and 12, and the day must be an integer between 1 and 31. There
is no sanity checking on the date, so dates of 31 February are perfectly
valid.

If the input values are outside of these ranges, undef will be returned.

=cut

sub ymd2je ($$$) {
  my ($year,$month,$day) = @_;

  my $jd = ymd2jd( $year, $month, $day );
  if( ! defined( $jd ) ) {
    return undef;
  }

  return jd2je( $jd );
}

=item B<parse_fits_date>

Convert a FITS-standard date into a Julian epoch.

  my $je = parse_fits_date( $fits_date );

According to the FITS standard, a FITS-standard date can be of the
form:

  YYYY-MM-DDThh:mm:ss[.s...],
  YYYY-MM-DD
  DD/MM/YY

The last form represents only dates between 1900 and 1999.

If no time is given, the time is taken to be noon.

This function returns the Julian epoch. If the input date is malformed,
then undef will be returned. Leading and trailing whitespace is allowed,
but otherwise the date must adhere to the FITS standard.

The FITS standard can be found at
http://www.cv.nrao.edu/fits/documents/standards/year2000.txt.

=cut

sub parse_fits_date {
  my $fdate = shift;
  if ($fdate =~ /^\s*(\d{4})-(\d{2})-(\d{2})(T(\d{2}):(\d{2}):(\d{2}(\.\d+)?))?\s*$/) {

    # We have a date of the form YYYY-MM-DD[Thh:mm:ss[.s...]].
    if (defined($4)) {

      # We have a date of the form YYYY-MM-DDThh:mm:ss[.s...].
	    my $jd = ymd2jd ($1,$2,$3);

	    # Add time: ymd2jd returns JD at noon.  Cf ymd2je
	    return 2000 + ( $jd + ( ( $5 - 12 ) * 3600 + $6 * 60 + $7 ) /86400.0
                      - 2451545 ) / 365.25;
    } else {
	    return ymd2je ($1,$2,$3);
    }

  } elsif ($fdate =~ m{^\s*(\d{2})/(\d{2})/(\d{2})\s*$}) {

    # We have a date of the form DD/MM/YY.
    return ymd2je ( $3 + 1900, $2, $1);

  } else {

    # Crikey!
    return undef;
  }
}

=head1 CVS VERSION

$Id$

=head1 SEE ALSO

Starlink User Note 242

=head1 AUTHORS

Brad Cavanagh E<lt>b.cavanagh@jach.hawaii.eduE<gt>

=head1 COPYRIGHT

Copyright (C) 2005 Particle Physics and Astronomy Research
Council.  All Rights Reserved.

This program is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation; either version 2 of the License, or (at your option) any later
version.

This program is distributed in the hope that it will be useful,but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
this program; if not, write to the Free Software Foundation, Inc., 59 Temple
Place,Suite 330, Boston, MA  02111-1307, USA

=cut

1;
