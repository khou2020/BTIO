dnl
dnl Copyright (C) 2020, Northwestern University and Argonne National Laboratory
dnl See COPYRIGHT notice in top-level directory.
dnl

dnl -*- Mode: shell-script-mode; -*-
dnl Process this file with GNU autoconf(1) to produce a configure script.
dnl

dnl autoconf v2.69 was released in 2012-04-24
AC_PREREQ([2.69])
AC_INIT([btio],[1.0.0],[],[btio],[])

AM_EXTRA_RECURSIVE_TARGETS([tests])

AC_CONFIG_HEADERS([config.h])
AH_TOP([/*
 * Copyright (C) 2020, Northwestern University and Argonne National Laboratory
 * See COPYRIGHT notice in top-level directory.
 */
])
AC_CONFIG_SRCDIR([header.f90])

AC_CONFIG_AUX_DIR([./scripts])

AM_INIT_AUTOMAKE([foreign])
AM_SILENT_RULES([yes])
AM_MAINTAINER_MODE([enable])

AC_DEFUN([UD_MSG_DEBUG],
         [if test "x${pnc_ac_debug}" = xyes ; then
             AC_MSG_NOTICE([DEBUG: $1])
          fi
         ]
)

dnl parse the version numbers to 3 env variables
BTIO_VERSION_MAJOR=`echo ${PACKAGE_VERSION} | cut -d. -f1`
BTIO_VERSION_MINOR=`echo ${PACKAGE_VERSION} | cut -d. -f2`
BTIO_VERSION_SUB=`echo ${PACKAGE_VERSION} | cut -d. -f3`
BTIO_VERSION=${PACKAGE_VERSION}
AC_SUBST(BTIO_VERSION_MAJOR)
AC_SUBST(BTIO_VERSION_MINOR)
AC_SUBST(BTIO_VERSION_SUB)
AC_SUBST(BTIO_VERSION)

dnl Note that command 'date' is not portable across Unix platforms.
dnl But release date matters only to btio developers who make the releases.
BTIO_RELEASE_DATE="`date '+%B %-d, %Y'`"
AC_SUBST(BTIO_RELEASE_DATE)
BTIO_RELEASE_DATE_FULL="`date '+%Y-%m-%d'`"
AC_SUBST(BTIO_RELEASE_DATE_FULL)
AC_SUBST(PACKAGE_VERSION)

AH_TOP([#ifndef _CONFIG_H
#define _CONFIG_H])
AH_BOTTOM([#endif])

MPI_INSTALL=
AC_ARG_WITH(mpi,
   [AS_HELP_STRING([--with-mpi=/path/to/implementation],
                   [The installation prefix path for MPI implementation.])
   ],[ dnl this clause is run when --with-mpi or --without-mpi is used
   if test "x${withval}" = xno ; then
      AC_MSG_ERROR([
      -----------------------------------------------------------------------
        btio is built on top of MPI. Configure option --without-mpi or
        --with-mpi=no should not be used. Abort.
      -----------------------------------------------------------------------])
   elif test "x${withval}" = x ; then
      AC_MSG_ERROR(--with-mpi is set but the value is NULL)
   elif test "x${withval}" != xyes && test ! -d "${withval}" ; then
      # user may use --with-mpi without an argument, which results in withval
      # being "yes". This case is OK and we simply take no action, as btio
      # requires MPI compilers and will check them.
      AC_MSG_ERROR(Directory '${withval}' specified in --with-mpi does not exist or is not a directory)
   fi
   MPI_INSTALL=${withval}
   ]
)

AC_ARG_VAR(MPICC,  [MPI C compiler, @<:@default: CC@:>@])
AC_ARG_VAR(MPIF90, [MPI Fortran 90 compiler, @<:@default: FC@:>@])

ac_user_MPICC=$MPICC
ac_user_MPICXX=$MPICXX
ac_user_MPIF90=$MPIF90
if test "x$MPICC"  = x && test "x$CC"  != x ; then ac_user_MPICC=$CC   ; fi
if test "x$MPICXX" = x && test "x$CXX" != x ; then ac_user_MPICXX=$CXX ; fi
if test "x$MPIF90" = x && test "x$F90" != x ; then ac_user_MPIF90=$F90 ; fi
if test "x$MPIF90" = x && test "x$FC"  != x ; then ac_user_MPIF90=$FC  ; fi

CANDIDATE_MPICC="${MPICC} mpicc mpicc_r"
CANDIDATE_MPICXX="${MPICXX} mpicxx mpic++ mpiCC mpcxx mpc++ mpicxx_r mpiCC_r mpcxx_r mpic++_r mpc++_r"
CANDIDATE_MPIF90="${MPIF90} mpif90 mpif90_r mpf90 mpf90_r mpif95 mpif95_r mpf95 mpf95_r"
dnl add GNU MPI compilers
CANDIDATE_MPICC="$CANDIDATE_MPICC mpigcc mpgcc mpigcc_r mpgcc_r"
CANDIDATE_MPICXX="$CANDIDATE_MPICXX mpig++ mpg++ mpig++_r mpg++_r"
CANDIDATE_MPIF90="$CANDIDATE_MPIF90 mpigfortran mpgfortran mpigfortran_r mpgfortran_r"
dnl add IBM MPI compilers
CANDIDATE_MPICC="$CANDIDATE_MPICC mpcc_r mpcc mpixlc_r mpixlc"
CANDIDATE_MPICXX="$CANDIDATE_MPICXX mpCC_r mpCC mpixlcxx_r mpixlcxx mpixlC_r mpixlC"
CANDIDATE_MPIF90="$CANDIDATE_MPIF90 mpixlf90_r mpixlf90"
dnl add IBM BGL MPI compilers
CANDIDATE_MPICC="$CANDIDATE_MPICC blrts_xlc mpxlc_r mpxlc"
CANDIDATE_MPICXX="$CANDIDATE_MPICXX blrts_xlC mpxlC_r mpxlC mpixlc++ mpxlcxx mpxlc++ mpxlCC mpixlc++_r mpxlcxx_r mpxlc++_r mpxlCC_r"
CANDIDATE_MPIF90="$CANDIDATE_MPIF90 blrts_xlf90 mpxlf90_r mpxlf90 mpxlf95_r mpxlf95 mpixlf95 mpixlf95_r"
dnl add Fujitsu MPI compilers
CANDIDATE_MPICC="$CANDIDATE_MPICC mpifccpx"
CANDIDATE_MPICXX="$CANDIDATE_MPICXX mpiFCCpx"
CANDIDATE_MPIF90="$CANDIDATE_MPIF90 mpifrtpx"
dnl add Cray MPI compiler wrappers
CANDIDATE_MPICC="$CANDIDATE_MPICC cc"
CANDIDATE_MPICXX="$CANDIDATE_MPICXX CC"
CANDIDATE_MPIF90="$CANDIDATE_MPIF90 ftn"
dnl add Intel MPI compiler wrappers
CANDIDATE_MPICC="$CANDIDATE_MPICC mpiicc icc"
CANDIDATE_MPICXX="$CANDIDATE_MPICXX mpiicpc mpiicxx mpiic++ mpiiCC icpc"
CANDIDATE_MPIF90="$CANDIDATE_MPIF90 mpiifort mpiifc mpiif95 mpiif90 ifort"
dnl add PGI MPI compiler wrappers
CANDIDATE_MPICC="$CANDIDATE_MPICC mpipgcc mppgcc"
CANDIDATE_MPICXX="$CANDIDATE_MPICXX mpipgCC mppgCC"
CANDIDATE_MPIF90="$CANDIDATE_MPIF90 mpipgf90 mpipgf95 mppgf90 mppgf95"

dnl find the full path of MPICC from CANDIDATE_MPICC and MPI_INSTALL
if test "x${ac_user_MPICC}" = x ; then
   dnl if MPICC or CC has not been set by users, then search from
   dnl CANDIDATE_MPICC, and find the full path of MPICC
   UD_MPI_PATH_PROGS([MPICC], [$CANDIDATE_MPICC])
else
   dnl check whether user specified MPICC is valid
   UD_MPI_PATH_PROG([MPICC], [$ac_user_MPICC])
fi

if test "x${MPICC}" = x ; then
   if test "x$ac_user_MPICC" = x ; then
      ERR_MSG="No MPI C compiler can be found"
   else
      ERR_MSG="Specified MPI C compiler \"$ac_user_MPICC\" cannot be found"
   fi
   if test "x$MPI_INSTALL" != x ; then
      ERR_MSG="$ERR_MSG under $MPI_INSTALL"
   fi
   AC_MSG_ERROR([
   -----------------------------------------------------------------------
     $ERR_MSG
     btio requires a working MPI C compiler. Please specify the
     location of an MPI C compiler, either in the MPICC environment
     variable (not CC variable) or through --with-mpi configure flag.
     Abort.
   -----------------------------------------------------------------------])
fi
CC=${MPICC}
AC_PROG_CC

dnl find the full path of MPICXX from CANDIDATE_MPICXX and MPI_INSTALL
if test "x${ac_user_MPICXX}" = x ; then
   dnl if MPICXX or CXX has not been set by users, then search from
   dnl CANDIDATE_MPICXX, and find the full path of MPICXX
   UD_MPI_PATH_PROGS([MPICXX], [$CANDIDATE_MPICXX])
else
   dnl check whether user specified MPICXX is valid
   UD_MPI_PATH_PROG([MPICXX], [$ac_user_MPICXX])
fi
if test "x${MPICXX}" = x ; then
   if test "x$ac_user_MPICXX" = x ; then
      ERR_MSG="No MPI C++ compiler can be found"
   else
      ERR_MSG="Specified MPI C++ compiler \"$ac_user_MPICXX\" cannot be found"
   fi
   if test "x$MPI_INSTALL" != x ; then
      ERR_MSG="$ERR_MSG under $MPI_INSTALL"
   fi
   AC_MSG_ERROR([
   -----------------------------------------------------------------------
     $ERR_MSG
     btio requires a working MPI C++ compiler. Please specify the
     location of an MPI C++ compiler, either in the MPICXX environment
     variable (not CXX variable) or through --with-mpi configure flag.
     Abort.
   -----------------------------------------------------------------------])
fi
CXX=${MPICXX}
AC_PROG_CXX


dnl Set output variable CPP to a command that runs the C preprocessor.
dnl Some C compilers require -E to be used as C preprocessor.
AC_PROG_CPP

dnl check if MPICXX works for basic MPI call: MPI_Comm_rank()
AC_LANG_PUSH(C++)
AC_CHECK_FUNC([MPI_Comm_rank], [],
   dnl maybe -lmpi is needed at link stage
   [AC_SEARCH_LIBS([MPI_Comm_rank], [mpi mpi++ mpich mpichcxx mpi_cxx], [],
                   [AC_MSG_ERROR([
   -----------------------------------------------------------------------
     Invalid MPI compiler specified or detected: "${MPICXX}"
     A working MPI C++ compiler is required. Please specify the location
     of one either in the MPICXX environment variable (not CXX variable)
     or through --with-mpi configure flag. Abort.
   -----------------------------------------------------------------------])
])])

has_fortran=yes
if test "x${ac_user_MPIF90}" = x ; then
   dnl if MPIF90 or F90 has not been set by users, then search from
   dnl CANDIDATE_MPIF90, and find the full path of MPIF90
   UD_MPI_PATH_PROGS([MPIF90], [$CANDIDATE_MPIF90])
else
   dnl check whether user specified MPIF90 is valid
   UD_MPI_PATH_PROG([MPIF90], [$ac_user_MPIF90])
fi

if test "x${MPIF90}" = x ; then
   has_fortran=no
   if test "x$ac_user_MPIF90" = x ; then
      ERR_MSG="No MPI Fortran 90 compiler can be found"
   else
      ERR_MSG="Specified MPI Fortran 90 compiler \"$ac_user_MPIF90\" cannot be found"
   fi
   if test "x$MPI_INSTALL" != x ; then
      ERR_MSG="$ERR_MSG under $MPI_INSTALL"
   fi

   AC_MSG_ERROR([
-----------------------------------------------------------------------
   $ERR_MSG.
   Please specify the location of the MPI Fortran 90 compiler, either in the
   MPIF90 environment variable or the --with-mpi configure flag. Abort.
-----------------------------------------------------------------------])
fi

mpi_mod=no
if test "x${has_fortran}" = xyes ; then

   dnl Check if MPIF90 is a valid MPI compiler
   FC=${MPIF90}
   AC_PROG_FC
   dnl FCFLAGS is set in AC_PROG_FC

   dnl FCLIBS_save="$FCLIBS"
   dnl FCLIBS=""
   AC_FC_LIBRARY_LDFLAGS
   dnl UD_MSG_DEBUG([before FCLIBS=$FCLIBS])
   dnl The autoconf macro for finding FCLIBS sometimes makes mistakes
   dnl (particularly with the Fujitsu frt compiler).  This next step
   dnl first sees if the FCLIBS is valid with the Fortran compiler
   dnl This also happens to Solaris Studio Fortran compilers
   dnl AC_PROG_FC_FCLIBS_VALID
   dnl Now see if FCLIBS works with the C compiler (remove invalid ones)
   dnl PAC_PROG_FC_CHECK_FCLIBS

   dnl replace FLIBS and F90LIBS with FCLIBS
   dnl UD_MSG_DEBUG([after FCLIBS=$FCLIBS])
   dnl FLIBS="$FCLIBS"
   dnl F90LIBS="$FCLIBS"

   AC_MSG_CHECKING([whether mpi.mod is available])
   AC_LANG_PUSH([Fortran])
   AC_COMPILE_IFELSE([AC_LANG_PROGRAM([], [[        use mpi]])],
                     [mpi_mod=yes], [mpi_mod=no]
   )
   AC_MSG_RESULT($mpi_mod)
   AC_MSG_CHECKING([whether $MPIF90 is a valid MPI compiler])
   if test "x${mpi_mod}" = xyes ; then
      AC_COMPILE_IFELSE([AC_LANG_PROGRAM([], [[
           use mpi
           integer err, rank
           call MPI_Comm_rank(MPI_COMM_WORLD, rank, err)]])],
         [valid_mpif90=yes],[valid_mpif90=no]
      )
   else
      AC_MSG_WARN([Fortran module mpi.mod is not available or invalid. Use mpif.h instead.])
      dnl mpi.mod is not available, check if can use mpif.h
      AC_COMPILE_IFELSE([AC_LANG_PROGRAM([], [[
           include "mpif.h"
           integer err, rank
           call MPI_Comm_rank(MPI_COMM_WORLD, rank, err)]])],
         [valid_mpif90=yes],[valid_mpif90=no]
      )
   fi
   AC_LANG_POP([Fortran])
   AC_MSG_RESULT($valid_mpif90)

   if test "x${valid_mpif90}" = xno ; then
      has_fortran=no
      AC_MSG_ERROR([
   -----------------------------------------------------------------------
     Invalid MPI Fortran 90 compiler: "${MPIF90}"
     A working MPI Fortran 90 compiler is required. Please specify the
     location of a valid MPI Fortran 90 compiler, either in the MPIF90
     environment variable or through --with-mpi configure flag. Abort.
   -----------------------------------------------------------------------])

      if test "x${mpi_mod}" = xyes ; then
         USE_MPIF_HEADER="use mpi, only: MPI_OFFSET_KIND"
      else
         USE_MPIF_HEADER="include \"mpif.h\""
      fi
      AC_SUBST(USE_MPIF_HEADER)
   fi
fi
AM_CONDITIONAL(HAVE_MPI_MOD, [test x$mpi_mod = xyes])

AC_CHECK_FUNC([MPI_File_open], [],
   dnl maybe -lmpi++ is needed at link stage
   [AC_SEARCH_LIBS([MPI_File_open], [mpio], [],
                   [AC_MSG_ERROR([
   -----------------------------------------------------------------------
     The underneath MPI implementation does not support MPI-IO.
     btio requires MPI-IO support to work properly. Abort.
   -----------------------------------------------------------------------])
])])
AC_LANG_POP(C++)

AC_CHECK_DECL([access], [], [], [[#include <unistd.h>]])
if test "x$ac_cv_have_decl_access" = xyes ; then
   AC_CHECK_FUNCS([access])
fi
AC_CHECK_DECL([unlink], [], [], [[#include <unistd.h>]])
if test "x$ac_cv_have_decl_unlink" = xyes ; then
   AC_CHECK_FUNCS([unlink])
fi

AC_ARG_ENABLE([debug],
    [AS_HELP_STRING([--enable-debug],
                    [Enable btio internal debug mode.
                     @<:@default: disabled@:>@])],
    [debug=${enableval}], [debug=no]
)
AM_CONDITIONAL(BTIO_DEBUG, [test "x$debug" = xyes])

if test "x${debug}" = xyes; then
   dnl add -g flag if not presented
   dnl remove all -O and -fast flags
   dnl add -O0 to all flags
   # check exit status of grep command is more portable than using -q
   str_found=`echo "${CXXFLAGS}" | ${EGREP} -- "-g"`
   if test "x$?" != x0 ; then
      CXXFLAGS="$CXXFLAGS -g"
   fi
   CXXFLAGS=`echo $CXXFLAGS | ${SED} 's/-O. *//g' | ${SED} 's/-fast *//g'`
   CXXFLAGS="$CXXFLAGS -O0"

   str_found=`echo "${CFLAGS}" | ${EGREP} -- "-g"`
   if test "x$?" != x0 ; then
      CFLAGS="$CFLAGS -g"
   fi
   CFLAGS=`echo $CFLAGS | ${SED} 's/-O. *//g' | ${SED} 's/-fast *//g'`
   CFLAGS="$CFLAGS -O0"

   unset str_found
   AC_DEFINE([BTIO_DEBUG], [1], [Enable debug mode])
fi

# Check for pnc
AC_ARG_WITH([pnetcdf],
   [AS_HELP_STRING([--with-pnetcdf=/path/to/pnetcdf], [Specify PnetCDF installation path(s):
    --with-pnetcdf=INC,LIB for include directory and library directory separated by a comma
    --with-pnetcdf=DIR for directory containing include/ and lib/ subdirectories
   ])], [
   case $withval in
     *,*)
        pnc_inc="`echo $withval |cut -f1 -d,`"
        pnc_lib="`echo $withval |cut -f2 -d, -s`"
        ;;
     *)
        if test -n "$withval"; then
          pnc_inc="$withval/include"
          pnc_lib="$withval/lib"
        fi
        ;;
   esac
   if test "x$pnc_inc" != x ; then
      if test "x$CPPFLAGS" = x ; then
         CPPFLAGS="-I$pnc_inc"
      elif ! echo "${CPPFLAGS}" | ${EGREP} -q -w -- "-I$pnc_inc" ; then
         # append only if not already appear in CPPFLAGS
         CPPFLAGS="$CPPFLAGS -I$pnc_inc"
      fi
   fi
   if test "x$pnc_lib" != x ; then
      if test "x$LDFLAGS" = x ; then
         LDFLAGS="-L$pnc_lib"
      elif ! echo "${LDFLAGS}" | ${EGREP} -q -w -- "-L$pnc_lib" ; then
         # append only if not already appear in LDFLAGS
         LDFLAGS="$LDFLAGS -L$pnc_lib"
      fi
   fi
])
AC_CHECK_HEADER([pnetcdf.h], [have_pnc=yes], [have_pnc=no])
if test "x$have_pnc" = xno ; then
      AC_MSG_ERROR([
      -----------------------------------------------------------------------
      Missing PnetCDF-header files 'pnetcdf.h' required to build BTIO. Use
      configure command-line option --with-pnetcdf=/path/to/implementation
      to specify the location of PnetCDF installation. Abort.
      -----------------------------------------------------------------------])
fi

# Check for HDF5
AC_ARG_WITH([hdf5],
   [AS_HELP_STRING([--with-hdf5=/path/to/hdf5], [Specify HDF5 installation path(s):
    --with-hdf5=INC,LIB for include directory and library directory separated by a comma
    --with-hdf5=DIR for directory containing include/ and lib/ subdirectories
   ])], [
   case $withval in
     *,*)
        hdf5_inc="`echo $withval |cut -f1 -d,`"
        hdf5_lib="`echo $withval |cut -f2 -d, -s`"
        ;;
     *)
        if test -n "$withval"; then
          hdf5_inc="$withval/include"
          hdf5_lib="$withval/lib"
        fi
        ;;
   esac
   if test "x$hdf5_inc" != x ; then
      if test "x$CPPFLAGS" = x ; then
         CPPFLAGS="-I$hdf5_inc"
      elif ! echo "${CPPFLAGS}" | ${EGREP} -q -w -- "-I$hdf5_inc" ; then
         # append only if not already appear in CPPFLAGS
         CPPFLAGS="$CPPFLAGS -I$hdf5_inc"
      fi
   fi
   if test "x$hdf5_lib" != x ; then
      if test "x$LDFLAGS" = x ; then
         LDFLAGS="-L$hdf5_lib"
      elif ! echo "${LDFLAGS}" | ${EGREP} -q -w -- "-L$hdf5_lib" ; then
         # append only if not already appear in LDFLAGS
         LDFLAGS="$LDFLAGS -L$hdf5_lib"
      fi
   fi
])
AC_CHECK_HEADER([hdf5.h], [have_hdf5=yes], [have_hdf5=no])
if test "x$have_hdf5" = xno ; then
      AC_MSG_WARN([
      -----------------------------------------------------------------------
      Missing HDF5-header files 'hdf5.h' required to build BTIO. Use
      configure command-line option --with-hdf5=/path/to/implementation
      to specify the location of HDF5 installation. Disable HDF5 support.
      -----------------------------------------------------------------------])
else
    AC_MSG_CHECKING([whether HDF5 parallel I/O is enabled])
    AC_COMPILE_IFELSE([AC_LANG_PROGRAM([[
    #include <hdf5.h>
    #if !defined(H5_HAVE_PARALLEL) || H5_HAVE_PARALLEL != 1
    #error Parallel I/O is not enabled in HDF5
    #endif
    ]])], [hdf5_parallel_io=yes], [hdf5_parallel_io=no])
    AC_MSG_RESULT([$hdf5_parallel_io])
    if test "x$hdf5_parallel_io" = xno ; then
        AC_MSG_WARN([
        -----------------------------------------------------------------------
            BTIO requires parallel I/O feature enabled in HDF5. Disable HDF5 support.
        -----------------------------------------------------------------------])
        have_hdf5=no
    fi
fi
AM_CONDITIONAL(ENABLE_HDF5, [test "x$have_hdf5" = xyes])

if test "x$LIBS" = x ; then
LIBS="-lpnetcdf"
else
LIBS="$LIBS -lpnetcdf"
fi

if test "x$have_hdf5" = xyes ; then
    if test "x$LIBS" = x ; then
    LIBS="-lhdf5"
    else
    LIBS="$LIBS -lhdf5"
    fi
    AC_DEFINE([ENABLE_HDF5], [1], [Build HDF5 benchmark])
fi

FCFLAGS="$FCFLAGS $CPPFLAGS"

AC_CONFIG_FILES(Makefile)

AC_OUTPUT
echo "------------------------------------------------------------------------------"
echo \
"
   ${PACKAGE_NAME} Version ${PACKAGE_VERSION}

   Features:  Internal debug mode         - ${debug}
              Internal profiling mode     - ${enable_profiling}"

echo "\

   Compilers: MPICC    = ${MPICC}
              MPICXX   = ${MPICXX}
              MPIF90   = ${MPIF90}"
if test "x${CPPFLAGS}" != x ; then
   echo "\
              CPPFLAGS = ${CPPFLAGS}"
fi
echo "\
              CFLAGS   = ${CFLAGS}
              FCFLAGS   = ${FCLAGS}"
if test "${CXXFLAGS}" != x ; then
   echo "\
              CXXFLAGS = ${CXXFLAGS}"
fi
if test "x${LDFLAGS}" != x ; then
   echo "\
              LDFLAGS  = ${LDFLAGS}"
fi
if test "x${LIBS}" != x ; then
   echo "\
              LIBS     = ${LIBS}"
fi
echo "\

   Now run 'make' to build the executable.

------------------------------------------------------------------------------"

