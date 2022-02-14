#include "adios2_m_imp.h"

#include <adios2_c.h>
#include <mpi.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define CHECK_AERR                                                    \
	{                                                                 \
		if (aerr != adios2_error_none) {                              \
			printf ("Error at line %d in %s:\n", __LINE__, __FILE__); \
			goto err_out;                                             \
		}                                                             \
	}

#define CHECK_APTR(P)                                              \
	{                                                              \
		if (P == NULL) {                                           \
			printf ("Error in %s:%d: NULL\n", __FILE__, __LINE__); \
			goto err_out;                                          \
		}                                                          \
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
		if (mpierr != MPI_SUCCESS) {                                             \
			int el = 256;                                                        \
			char errstr[256];                                                    \
			MPI_Error_string (ret, errstr, &el);                                 \
			printf ("Error at line %d in %s: %s\n", __LINE__, __FILE__, errstr); \
			err = -1;                                                            \
			goto err_out;                                                        \
		}                                                                        \
	}

#define FIVE_DBL_SIZE 5

adios2_adios *adp	= NULL;
adios2_io *iop		= NULL;
adios2_engine *ep	= NULL;
adios2_variable *vp = NULL;
size_t cellsize;

size_t griddim[5], gridmdim[5];

char dir_path[512];

void print_params_adios2 (char *io_mode, int *io_method) {
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

int adios2_setup (char *io_mode, int *io_method) {
	int err	   = 0;
	int ret	   = 1;
	int mpierr = 0;
	int i;
	adios2_error aerr = adios2_error_none;
	adios2_step_status stat;
	MPI_File fh;
	char path[1024];
	size_t cdim[5];
	char ng[32];
	double t;

	// printf ("adios2_setup\n");
	// print_params_adios2 (io_mode, io_method);

	t_post_w = 0.0;
	t_wait_w = 0.0;
	t_post_r = 0.0;
	t_wait_r = 0.0;
	t_close	 = 0.0;

	t = MPI_Wtime ();

	adp = adios2_init (MPI_COMM_WORLD, "");
	CHECK_APTR (adp)

	iop = adios2_declare_io (adp, "btio_wrap");
	CHECK_APTR (iop)
	aerr = adios2_set_engine (iop, "BP4");
	CHECK_AERR

	sprintf (ng, "%d", 1);
	aerr = adios2_set_parameter (iop, "substreams", ng);
	CHECK_AERR
	aerr = adios2_set_parameter (iop, "CollectiveMetadata", "OFF");
	CHECK_AERR
	ep = NULL;

	griddim[1] = gridmdim[1] = grid_points[2];
	griddim[2] = gridmdim[2] = grid_points[1];
	griddim[3] = gridmdim[3] = grid_points[0];
	griddim[4] = gridmdim[4] = FIVE_DBL_SIZE;

	strncpy (dir_path, dir_path_p, dir_path_len);
	dir_path[dir_path_len] = '\0';
	sprintf (path, "%s/btio.bp", dir_path);

	if (*io_mode == 'w') {
		ep = adios2_open (iop, path, adios2_mode_write);
		CHECK_APTR (ep)
		vp = adios2_define_variable (iop, "var", adios2_type_double, 4, griddim + 1, NULL, NULL,
									 adios2_constant_dims_false);
		CHECK_APTR (vp)
	} else {
		ep = adios2_open (iop, path, adios2_mode_read);
		CHECK_APTR (ep)
		vp = adios2_inquire_variable (iop, "var");
		CHECK_APTR (vp)
	}

	t = MPI_Wtime () - t;
	if (*io_mode == 'w') {
		t_create = t;
	} else {
		t_open = t;
	}

	sprintf (path, "%s/btio.bp/data.0", dir_path);
	if (*io_mode == 'w') {
		mpierr = MPI_File_open (MPI_COMM_WORLD, path, MPI_MODE_RDWR, MPI_INFO_NULL, &fh);
	} else {
		mpierr = MPI_File_open (MPI_COMM_WORLD, path, MPI_MODE_RDONLY, MPI_INFO_NULL, &fh);
	}
	CHECK_MPIERR
	mpierr = MPI_File_get_info (fh, &info_used);
	CHECK_MPIERR
	MPI_File_close (&fh);

err_out:;
	return ret;
}

void adios2_write () {
	adios2_error aerr = adios2_error_none;
	adios2_step_status stat;
	int i;
	double t_start, t_end;
	size_t start[5], count[5];

	// printf ("adios2_write\n");

	t_start = MPI_Wtime ();

	aerr = adios2_begin_step (ep, adios2_step_mode_append, -1, &stat);
	CHECK_AERR

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

		aerr = adios2_set_selection (vp, 4, start, count);
		CHECK_AERR

		aerr = adios2_put (ep, vp, u_p + i * cellsize, adios2_mode_deferred);
		CHECK_AERR
	}

	num_io = num_io + 1;

	t_end	 = MPI_Wtime ();
	t_post_w = t_post_w + t_end - t_start;
	t_start	 = t_end;

	aerr = adios2_end_step (ep);
	CHECK_AERR

	t_end	 = MPI_Wtime ();
	t_wait_w = t_wait_w + t_end - t_start;

err_out:;
}

void adios2_read () {
	adios2_error aerr = adios2_error_none;
	adios2_step_status stat;
	int i;
	double t_start, t_end;
	size_t start[5], count[5];

	// printf ("adios2_read\n");

	t_start = MPI_Wtime ();

	aerr = adios2_begin_step (ep, adios2_step_mode_append, -1, &stat);
	CHECK_AERR

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

		aerr = adios2_set_selection (vp, 4, start, count);
		CHECK_AERR

		aerr = adios2_get (ep, vp, u_p + i * cellsize, adios2_mode_deferred);
		CHECK_AERR
	}

	num_io = num_io + 1;

	t_end	 = MPI_Wtime ();
	t_post_r = t_post_r + t_end - t_start;
	t_start	 = t_end;

	aerr = adios2_end_step (ep);
	CHECK_AERR

	t_end	 = MPI_Wtime ();
	t_wait_r = t_wait_r + t_end - t_start;

err_out:;
}

void adios2_cleanup () {
	adios2_error aerr = adios2_error_none;
	adios2_bool ret;
	double t_start, t_end;

	t_start = MPI_Wtime ();

	// printf ("adios2_cleanup\n");

	aerr = adios2_close (ep);
	CHECK_AERR

	aerr = adios2_remove_io (&ret, adp, "btio_wrap");
	CHECK_AERR

	adios2_finalize (adp);

	t_end = MPI_Wtime ();
	t_close += t_end - t_start;
err_out:;
}
