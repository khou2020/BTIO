!
!  Copyright (C) 2013, Northwestern University
!  See COPYRIGHT notice in top-level directory.
!

      module header
      USE ISO_C_BINDING
      implicit none

      integer, bind(C, name="num_io") :: num_io 
      integer, bind(C, name="ncells") :: ncells 
      integer(KIND=8), bind(C, name="grid_points") :: grid_points(3) ! global array size

      integer, allocatable, target :: cell_coord (:,:), &
                              cell_low   (:,:), &
                              cell_high  (:,:), &
                              cell_size  (:,:)

      type(c_ptr), bind(C, name="cell_coord_p") :: cell_coord_p
      type(c_ptr), bind(C, name="cell_low_p") :: cell_low_p
      type(c_ptr), bind(C, name="cell_high_p") :: cell_high_p
      type(c_ptr), bind(C, name="cell_size_p") :: cell_size_p

      ! cell_coord (3,ncells), cell_low (3,ncells), &
      ! cell_high  (3,ncells), cell_size(3,ncells), &
      ! start      (3,ncells), end      (3,ncells)

      integer(KIND=8), bind(C, name="iaxm") :: IMAX
      integer(KIND=8), bind(C, name="jmax") :: JMAX
      integer(KIND=8), bind(C, name="kmax") :: KMAX

      double precision, allocatable, target :: u(:, :, :, :, :)
      type(c_ptr), bind(C, name="u_p") :: u_p
      ! u(5, -2:IMAX+1, -2:JMAX+1, -2:KMAX+1, ncells)

      integer, bind(C, name="rank") :: rank
      integer, bind(C, name="nprocs") ::  nprocs
      integer, bind(C, name="root") ::   root
      integer, bind(C, name="niter") ::    niter
      integer, bind(C, name="info_used") ::   info_used

      character(len=512), target :: dir_path
      type(c_ptr), bind(C, name="dir_path_p") :: dir_path_p
      integer, bind(C, name="dir_path_len") :: dir_path_len

      double precision, bind(C, name="t_create") :: t_create
      double precision, bind(C, name="t_post_w") :: t_post_w
      double precision, bind(C, name="t_wait_w") :: t_wait_w
      double precision, bind(C, name="t_open") :: t_open
      double precision, bind(C, name="t_post_r") :: t_post_r
      double precision, bind(C, name="t_wait_r") :: t_wait_r
      
      contains

      !----< allocate_variables >--------------------------------------
      subroutine allocate_variables
          use mpi
          implicit none

          info_used = MPI_INFO_NULL

          IMAX = (grid_points(1)/ncells) + 1
          JMAX = (grid_points(2)/ncells) + 1
          KMAX = (grid_points(3)/ncells) + 1

          allocate(cell_coord(3,ncells))
          allocate(  cell_low(3,ncells))
          allocate( cell_high(3,ncells))
          allocate( cell_size(3,ncells))
          cell_coord_p =c_loc(cell_coord)
          cell_low_p =c_loc(cell_low)
          cell_high_p =c_loc(cell_high)
          cell_size_p =c_loc(cell_size)
        
          allocate(u(5, -2:IMAX+1, -2:JMAX+1, -2:KMAX+1, ncells))
          u_p = c_loc(u)

          dir_path_p = c_loc(dir_path)

          ! initialize contents of variable u
          call RANDOM_NUMBER(u(1:5,-2:IMAX+1,-2:JMAX+1,-2:KMAX+1,1:ncells))

      end subroutine allocate_variables

      !----< deallocate_variables >------------------------------------
      subroutine deallocate_variables
          implicit none

          deallocate(u)
          deallocate(cell_coord)
          deallocate(  cell_low)
          deallocate( cell_high)
          deallocate( cell_size)
      end subroutine deallocate_variables

      end module header


