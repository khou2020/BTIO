!
!  Copyright (C) 2022, Northwestern University
!  See COPYRIGHT notice in top-level directory.
!

        module adios2_m
            USE ISO_C_BINDING
            use header
            implicit none

            interface 
                integer(kind = c_int) function adios2_setup(io_mode, io_method) bind(C,name="adios2_setup")
                    use iso_c_binding    
                    implicit none
                    integer(kind = c_int), intent(in) :: io_method
                    character(len=1,kind=C_char), dimension(*), intent(in) :: io_mode
                end function adios2_setup
                subroutine adios2_cleanup()  bind(C,name="adios2_cleanup")
                    implicit none
                end subroutine adios2_cleanup
                subroutine adios2_write()  bind(C,name="adios2_write")
                    implicit none
                end subroutine adios2_write
                subroutine adios2_read()  bind(C,name="adios2_read")
                    implicit none
                end subroutine adios2_read
            end interface
        end module adios2_m
  