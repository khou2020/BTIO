AM_CPPFLAGS = -I$(top_srcdir)

bin_PROGRAMS = btio

btio_SOURCES = 	io_info.f90 \
				header.f90 \
				mpiio_m.f90 \
				make_set.f90 \
				pnetcdf_m.f90 \
				bt.f90

if ENABLE_HDF5
btio_SOURCES += hdf5_m.f90 hdf5_m_imp.c 
btio_SOURCES += hdf5_m_imp.h
endif
