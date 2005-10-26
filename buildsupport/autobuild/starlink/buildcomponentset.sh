#!/bin/sh

#HOSTNAME
hostname -f
 
NAME="Starlink CVS"
 
# Exit immediately if command fails
set -e
 
# Print command executed to stdout
set -v
# Make env for build.

#Set the DISPLAY env, yes we do need this.
DISPLAY=EXPORT_DISPLAY

export DISPLAY
BUILD_SYSTEM=BUILDDIR
export BUILD_SYSTEM
MY_CVS_ROOT=$CVSROOT
export MY_CVS_ROOT
BUILD_HOME=$BUILD_SYSTEM/build-home
export BUILD_HOME
STARCONF_DEFAULT_STARLINK=$BUILD_SYSTEM/install-comp
export STARCONF_DEFAULT_STARLINK
STARCONF_DEFAULT_PREFIX=$BUILD_SYSTEM/install-comp
export STARCONF_DEFAULT_PREFIX
PATH=$STARCONF_DEFAULT_PREFIX/buildsupport/bin:$PATH
export PATH
PATH=$STARCONF_DEFAULT_PREFIX/bin:$PATH
export PATH
PATH=JDK_HOME/bin:$PATH
export PATH
JAVA=JDK_HOME/bin/java
export JAVA


# Let us see the full environment for the build

env

#Delete only the ##'s to get the code, single #'s
#are comments.

# For everything else, generic build.
# Do ./bootstrap
##./bootstrap
 
# Do make configure-deps
##make configure-deps

# Do ./configure -C
##./configure -C

#Remake componentset.xml Makefile.dependencies.
#Only have to do this on one of the nightly builds
#so it should be commented out unless it is needed.


##md5sum componentset.xml > componentset.xml-md5
##mv componentset.xml componentset.xml-orig
##mv Makefile.dependencies Makefile.dependencies-orig

##make Makefile.dependencies

#Check to see if they have changed from the originals
#if so, check in to cvs

##if md5sum --status -c componentset.xml-md5; then

##echo "componentset.xml has not changed, no need to check it in"

##else

#check in componentset.xml Makefile.dependencies to cvs
##echo "componentset.xml has changed, check it in along with Makefile.dependencies"

##cvs -d $MY_CVS_ROOT commit -m "Generated by Nightly Build" componentset.xml Makefile.dependencies

##fi
