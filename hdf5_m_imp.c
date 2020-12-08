#include "hdf5_m_imp.h"

#include <hdf5.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define CHECK_ERR                                                     \
	{                                                                 \
		if (err < 0) {                                                \
			printf ("Error at line %d in %s:\n", __LINE__, __FILE__); \
			H5Eprint1 (stdout);                                       \
			goto err_out;                                             \
		}                                                             \
	}

#define CHECK_ID(A)                                                   \
	{                                                                 \
		if (A < 0) {                                                  \
			printf ("Error at line %d in %s:\n", __LINE__, __FILE__); \
			H5Eprint1 (stdout);                                       \
			goto err_out;                                             \
		}                                                             \
	}

#define PRINT_VECTOR(V, L, F)                             \
	{                                                     \
		int i;                                            \
		printf (#V " = {");                               \
		for (i = 0; i < L; i++) { printf (F " ", V[i]); } \
		printf ("}\n");                                   \
	}

#define CHECK_MPIERR                                                             \
	{                                                                            \
		if (ret != MPI_SUCCESS) {                                             \
			int el = 256;                                                        \
			char errstr[256];                                                    \
			MPI_Error_string (ret, errstr, &el);                              \
			printf ("Error at line %d in %s: %s\n", __LINE__, __FILE__, errstr); \
			err = -1;                                                            \
			goto err_out;                                                        \
		}                                                                        \
	}

#define FIVE_DBL_SIZE 5

hid_t fid	 = -1;
hid_t did	 = -1;
hid_t msid	 = -1;
hid_t dxplid = -1;

hsize_t cellsize;

hsize_t griddim[5], gridmdim[5];

char dir_path[512];

void print_params (char *io_mode, int *io_method) {
	printf ("io_mode=%c, io_method=%d\n", *io_mode, *io_method);
	printf ("num_io=%d, ncells=%d\n", num_io, ncells);
	printf ("dir_path_len=%d\n", dir_path_len);
	printf ("nprocs=%d\n", nprocs);
	printf ("dir_path=%s\n", dir_path_p);

	PRINT_VECTOR (grid_points, 3, "%ld");
	PRINT_VECTOR (cell_coord_p, 3 * ncells, "%d");
	PRINT_VECTOR (cell_low_p, 3 * ncells, "%d");
	PRINT_VECTOR (cell_high_p, 3 * ncells, "%d");
	PRINT_VECTOR (cell_size_p, 3 * ncells, "%d");
}

int hdf5_setup (char *io_mode, int *io_method) {
	int ret		 = 1;
	herr_t err	 = 0;
	hid_t faplid = -1;
	hid_t dsid	 = -1;
	hid_t dcplid;
	MPI_File fh;
	char path[1024];
	double t;

	// printf ("hdf5_setup\n");
	// print_params (io_mode, io_method);

	t_post_w = 0.0;
	t_wait_w = 0.0;
	t_post_r = 0.0;
	t_wait_r = 0.0;

	t = MPI_Wtime ();

	faplid = H5Pcreate (H5P_FILE_ACCESS);
	CHECK_ID (faplid);

	H5Pset_fapl_mpio (faplid, MPI_COMM_WORLD, MPI_INFO_NULL);
	H5Pset_all_coll_metadata_ops (faplid, 1);
	// H5Pset_vol(faplid, log_vlid, NULL);

	cellsize = cell_size_p[0] * cell_size_p[1] * cell_size_p[2] * FIVE_DBL_SIZE;

	strncpy (dir_path, dir_path_p, dir_path_len);
	dir_path[dir_path_len] = '\0';
	sprintf (path, "%s/btio.nc", dir_path);

	if (*io_mode == 'w') {
		fid = H5Fcreate (path, H5F_ACC_TRUNC, H5P_DEFAULT, faplid);
		CHECK_ID (fid);

		griddim[0]	= 0;
		gridmdim[0] = H5S_UNLIMITED;
		griddim[1] = gridmdim[1] = grid_points[2];
		griddim[2] = gridmdim[2] = grid_points[1];
		griddim[3] = gridmdim[3] = grid_points[0];
		griddim[4] = gridmdim[4] = FIVE_DBL_SIZE;
		dsid					 = H5Screate_simple (5, griddim, gridmdim);
		msid					 = H5Screate_simple (1, &cellsize, &cellsize);

		dcplid	   = H5Pcreate (H5P_DATASET_CREATE);
		griddim[0] = 1;
		H5Pset_chunk (dcplid, 5, griddim);
		did = H5Dcreate2 (fid, "var", H5T_IEEE_F64BE, dsid, H5P_DEFAULT, dcplid, H5P_DEFAULT);
		CHECK_ID (did)
	} else {
		fid = H5Fopen (path, H5F_ACC_RDONLY, faplid);
		CHECK_ID (fid);

		griddim[0]	= 0;
		gridmdim[0] = H5S_UNLIMITED;
		griddim[1] = gridmdim[1] = grid_points[2];
		griddim[2] = gridmdim[2] = grid_points[1];
		griddim[3] = gridmdim[3] = grid_points[0];
		griddim[4] = gridmdim[4] = FIVE_DBL_SIZE;
		msid					 = H5Screate_simple (1, &cellsize, &cellsize);

		did = H5Dopen2 (fid, "var", H5P_DEFAULT);
		CHECK_ID (did)
	}

	dxplid = H5Pcreate (H5P_DATASET_XFER);
	CHECK_ID (dxplid)
	H5Pset_dxpl_mpio (dxplid, H5FD_MPIO_COLLECTIVE);

	t = MPI_Wtime () - t;
	if (*io_mode == 'w') {
		t_create = t;
	} else {
		t_open = t;
	}

	if (*io_mode == 'w') {
		ret = MPI_File_open (MPI_COMM_WORLD, path, MPI_MODE_RDWR, MPI_INFO_NULL, &fh);
	} else {
		ret = MPI_File_open (MPI_COMM_WORLD, path, MPI_MODE_RDONLY, MPI_INFO_NULL, &fh);
	}
	CHECK_MPIERR
	ret = MPI_File_get_info (fh, &info_used);
	CHECK_MPIERR
	MPI_File_close(&fh);

err_out:;

	if (faplid >= 0) { H5Pclose (faplid); }
	if (dcplid >= 0) { H5Pclose (dcplid); }
	if (dsid >= 0) { H5Sclose (dsid); }
	if (err) ret = 0;
	return ret;
}

void hdf5_write () {
	herr_t err = 0;
	int i;
	hid_t dsid = -1;
	double t_start, t_end;
	hsize_t start[5], count[5], one[5] = {1, 1, 1, 1, 1};

	// printf ("hdf5_write\n");

	t_start = MPI_Wtime ();

	/* Add 1 slice */
	griddim[0] = num_io + 1;
	err		   = H5Dset_extent (did, griddim);
	CHECK_ERR
	dsid = H5Dget_space (did);
	CHECK_ID (dsid)

	for (i = 0; i < ncells; i++) {
		start[0] = num_io;
		start[1] = cell_low_p[2 + i * 3];
		start[2] = cell_low_p[1 + i * 3];
		start[3] = cell_low_p[0 + i * 3];
		start[4] = 0;

		count[0] = 1;
		count[1] = cell_size_p[2 + i * 3];
		count[2] = cell_size_p[1 + i * 3];
		count[3] = cell_size_p[0 + i * 3];
		count[4] = FIVE_DBL_SIZE;

		err = H5Sselect_hyperslab (dsid, H5S_SELECT_SET, start, NULL, one, count);
		CHECK_ERR

		err = H5Dwrite (did, H5T_NATIVE_DOUBLE, msid, dsid, dxplid, u_p + i * cellsize);
		CHECK_ERR
	}

	num_io = num_io + 1;

	t_end	 = MPI_Wtime ();
	t_post_w = t_post_w + t_end - t_start;
	t_start	 = t_end;

	err = H5Fflush (fid, H5F_SCOPE_LOCAL);
	CHECK_ERR

	t_end	 = MPI_Wtime ();
	t_wait_w = t_wait_w + t_end - t_start;

err_out:;
	if (dsid >= 0) { H5Sclose (dsid); }
}

void hdf5_read () {
	herr_t err = 0;
	int i;
	hid_t dsid = -1;
	double t_start, t_end;
	hsize_t start[5], count[5], one[5] = {1, 1, 1, 1, 1};

	// printf ("hdf5_read\n");

	t_start = MPI_Wtime ();

	dsid = H5Dget_space (did);
	CHECK_ID (dsid)

	for (i = 0; i < ncells; i++) {
		start[0] = num_io;
		start[1] = cell_low_p[2 + i * 3];
		start[2] = cell_low_p[1 + i * 3];
		start[3] = cell_low_p[0 + i * 3];
		start[4] = 0;

		count[0] = 1;
		count[1] = cell_size_p[2 + i * 3];
		count[2] = cell_size_p[1 + i * 3];
		count[3] = cell_size_p[0 + i * 3];
		count[4] = FIVE_DBL_SIZE;

		err = H5Sselect_hyperslab (dsid, H5S_SELECT_SET, start, NULL, one, count);
		CHECK_ERR

		err = H5Dread (did, H5T_NATIVE_DOUBLE, msid, dsid, dxplid, u_p + i * cellsize);
		CHECK_ERR
	}

	num_io = num_io + 1;

	t_end	 = MPI_Wtime ();
	t_post_r = t_post_r + t_end - t_start;
	t_start	 = t_end;

	err = H5Fflush (fid, H5F_SCOPE_LOCAL);
	CHECK_ERR

	t_end	 = MPI_Wtime ();
	t_wait_r = t_wait_r + t_end - t_start;

err_out:;
	if (dsid >= 0) { H5Sclose (dsid); }
}

void hdf5_cleanup () {
	// printf ("hdf5_cleanup\n");

	if (msid >= 0) { H5Sclose (msid); }
	if (dxplid >= 0) { H5Pclose (dxplid); }
	if (did >= 0) { H5Dclose (did); }
	if (fid >= 0) { H5Fclose (fid); }
}