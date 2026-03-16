program matmul
    implicit none

    integer, parameter :: N = 1024
    real(8), allocatable :: A(:,:), B(:,:), C(:,:)
    real(8) :: t_start, t_end

    allocate(A(N,N), B(N,N), C(N,N))

    ! Initialise with pseudo-random values
    call random_number(A)
    call random_number(B)
    C = 0.0d0

    call cpu_time(t_start)

    ! Call the separate subroutine
    call compute_matmul(A, B, C, N)

    call cpu_time(t_end)

    write(*,'(A,I4,A,I4)') 'Matrix size : ', N, ' x ', N
    write(*,'(A,F10.4,A)')  'Time (naive): ', t_end - t_start, ' s'
    write(*,'(A,F20.10)')   'Checksum C(1,1) = ', C(1,1)

    deallocate(A, B, C)
end program matmul

! --------------------------------------------------------------------------
! Kernel Subroutine to study
! --------------------------------------------------------------------------
subroutine compute_matmul(A, B, C, N)
    implicit none
    integer, intent(in) :: N
    real(8), intent(in) :: A(N,N), B(N,N)
    real(8), intent(out) :: C(N,N)
    integer :: i, j, k
    real(8) :: sum_val

    ! ---- hotspot: i->j->k loop order (BAD for column-major Fortran) ----------
    do i = 1, N                        ! outermost: row of C
        do j = 1, N                    ! middle:    column of C
            sum_val = 0.0d0
            do k = 1, N                ! innermost: dot-product index
                sum_val = sum_val + A(i,k) * B(k,j)
            end do
            C(i,j) = sum_val
        end do
    end do
end subroutine compute_matmul
