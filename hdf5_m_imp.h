#include <stdint.h>

extern int num_io;
extern int ncells;
extern int64_t grid_points[3];

extern int64_t imax, jmax, kmax;

extern int *cell_coord_p;
extern int *cell_low_p;
extern int *cell_high_p;
extern int *cell_size_p;

extern int rank;
extern int nprocs;
extern int root;
extern int niter;
extern int info_used;

extern double *u_p;

extern char *dir_path_p;
extern int dir_path_len;

extern double t_create, t_post_w, t_wait_w;
extern double t_open, t_post_r, t_wait_r;

int hdf5_setup(char *io_mode, int *io_method);
void hdf5_write();
void hdf5_read();
void hdf5_cleanup();
