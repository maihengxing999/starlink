#+
#  Name:
#     GaiaNDAccess

#  Type of Module:
#     [incr Tcl] class

#  Purpose:
#     Handles multidimensional dataset access in GAIA. 

#  Description:
#     This class is designed to handle the access and description of datasets
#     that don't have 2 dimensions. Superficially it is datatype independent,
#     supporting access to NDF and FITS data, relying on the ndf:: and
#     fits:: (too be written) Tcl commands. Sections of the data can be
#     generated for passing into GAIA/Skycat for display as images and
#     spectra.

#  Invocations:
#
#        GaiaNDAccess object_name [configuration options]
#
#     This creates an instance of a GaiaNDAccess object. The return is
#     the name of the object.
#
#        object_name configure -configuration_options value
#
#     Applies any of the configuration options (after the instance has
#     been created).
#
#        object_name method arguments
#
#     Performs the given method on this object.

#  Configuration options:
#     See below.

#  Methods:
#     See below.

#  Inheritance:
#     This object inherits no other classes.

#  Authors:
#     PWD: Peter Draper (JAC - Durham University)
#     {enter_new_authors_here}

#  History:
#     21-MAR-2006 (PWD):
#        Original version.
#     {enter_further_changes_here}

#-

#.

itcl::class gaia::GaiaNDAccess {

   #  Inheritances:
   #  -------------

   #  Nothing

   #  Constructor:
   #  ------------

   #  One argument, the specification of the dataset. NDF or FITS file.
   constructor { args } {

      #  Create object for parsing image names.
      set namer_ [GaiaImageName \#auto]

      #  Evaluate any options, should be the dataset name usually.
      eval configure $args
   }

   #  Destructor:
   #  -----------
   destructor  {
      close
   }

   #  Methods:
   #  --------

   #  Parse specification to determine data type and get an access name.
   protected method parse_name_ {} {
      
      #  Release previous dataset, if any.
      close

      $namer_ configure -imagename $dataset
      if { "[$namer_ type]" == ".sdf" } {
         set type_ "ndf"
      } else {
         set type_ "fits"
         error {Cannot access FITS files that are not 2D. \
                You should convert this file to an NDF first using the \
                ndf2fits command in the CONVERT package.}
      }
      
      #  Open the dataset.
      open_
   }
   
   #  Open the dataset. Wraps two methods, one for NDFs and one for FITS files.
   #  These should be light-weight accesses that just get meta-data at this
   #  stage.
   protected method open_ {} {
      set handle_ [${type_}::open [$namer_ ndfname 0]]
   }
   
   #  Close the dataset, if open.
   public method close {} {
      if { $handle_ != {} } {
         ${type_}::close $handle_
         set handle_ {}
         set addr_ 0
         set nel_ 0
         set hdstype_ {}
      }
   }

   #  Get the dimensions of the full data. Returns a list of integers.
   public method dims {} {
      return [${type_}::dims $handle_]
   }

   #  Get the pixel ranges/bounds of the full data. Returns pairs of
   #  integers, one for each dimension. For FITS files the lower bound will
   #  always be 1.
   public method bounds {} {
      return [${type_}::bounds $handle_]
   }

   #  Return the formatted coordinate of a position along a given axis.
   #
   #  The arguments are the index of the axis, a list of all the pixel indices
   #  needed to identify the coordinate, and an optional boolean argument that
   #  determines if to add a trailing label and units strings to the return
   #  value.
   public method coord {axis indices {trail 0} } {
      return [${type_}::coord $handle_  $axis $indices $trail]
   }

   #  Map in the dataset "data component". Returns the address, number of
   #  elements and the data type (these are in the HDS format).
   public method map {} {
      lassign [${type_}::map $handle_] addr_ nel_ hdstype_
      return [list $addr_ $nel_ $hdstype_]
   }

   #  Return the value of a "character component" of the dataset. These may be 
   #  the units of the data and a label describing the units, nothing else is
   #  supported. So valid values for "what" are "units" and "label".
   public method getc {what} {
      return [${type_}::getc $handle_ $what]
   }

   #  Return a WCS describing the coordinates of a given WCS axis. Note axes
   #  may or may not be fixed to a given dataset axis, that isn't worried
   #  about here.
   public method getwcs {axis} {
      return [${type_}::getwcs $handle_ $axis]
   }

   #  Configuration options: (public variables)
   #  ----------------------

   #  Name of the dataset as supplied by the user.
   public variable dataset {} {
      if { $dataset != {} } {
         parse_name_
      }
   }

   #  Protected variables: (available to instance)
   #  --------------------

   #  Object to parse names.
   protected variable namer_ {}

   #  Data access type, one of "ndf" or "fits".
   protected variable type_ {}

   #  The handle to the opened dataset. NDF or FITS identifier.
   protected variable handle_ {}

   #  The memory address of the dataset data component.
   protected variable addr_ 0

   #  The number of elements in the dataset data component.
   protected variable nel_ 0

   #  The HDS data type of the dataset data.
   protected variable hdstype_ {}

   #  Common variables: (shared by all instances)
   #  -----------------


#  End of class definition.
}
