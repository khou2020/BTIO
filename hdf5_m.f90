!
!  Copyright (C) 2021, Northwestern University
!  See COPYRIGHT notice in top-level directory.
!

        module hdf5_m
            USE ISO_C_BINDING
            use header
            implicit none

            interface 
                integer(kind = c_int) function hdf5_setup(io_mode, io_method) bind(C,name="hdf5_setup")
                    use iso_c_binding    
                    implicit none
                    integer(kind = c_int), intent(in) :: io_method
                    character(len=1,kind=C_char), dimension(*), intent(in) :: io_mode
                end function hdf5_setup
                subroutine hdf5_cleanup()  bind(C,name="hdf5_cleanup")
                    implicit none
                end subroutine hdf5_cleanup
                subroutine hdf5_write()  bind(C,name="hdf5_write")
                    implicit none
                end subroutine hdf5_write
                subroutine hdf5_read()  bind(C,name="hdf5_read")
                    implicit none
                end subroutine hdf5_read
            end interface
        end module hdf5_m
  