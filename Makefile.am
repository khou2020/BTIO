AM_CPPFLAGS = -I$(top_srcdir)

bin_PROGRAMS = btio

btio_SOURCES = 

if ENABLE_HDF5
btio_SOURCES += hdf5_m.f90 hdf5_m_imp.c 
btio_SOURCES += hdf5_m_imp.h
endif

if ENABLE_ADIOS2
btio_SOURCES += adios2_m.f90 adios2_m_imp.c 
btio_SOURCES += adios2_m_imp.h
endif

btio_SOURCES += io_info.f90 \
				header.f90 \
				mpiio_m.f90 \
				make_set.f90 \
				pnetcdf_m.f90 \
				bt.f90