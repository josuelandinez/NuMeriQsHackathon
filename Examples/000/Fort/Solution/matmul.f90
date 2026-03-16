program matmul
    implicit none

    integer, parameter :: N = 1024
    real(8), allocatable :: A(:,:), B(:,:), C(:,:)
    real(8) :: t_start, t_end

    allocate(A(N,N), B(N,N), C(N,N))
    call random_number(A)
    call random_number(B)
    C = 0.0d0

    call cpu_time(t_start)

    ! Call the optimized subroutine
    call compute_matmul_optimized(A, B, C, N)

    call cpu_time(t_end)

    write(*,'(A,I4,A,I4)') 'Matrix size : ', N, ' x ', N
    write(*,'(A,F10.4,A)')  'Time (fast) : ', t_end - t_start, ' s'
    write(*,'(A,F20.10)')   'Checksum C(1,1) = ', C(1,1)

    deallocate(A, B, C)
end program matmul

! --------------------------------------------------------------------------
! Optimized kernel 
! --------------------------------------------------------------------------
subroutine compute_matmul_optimized(A, B, C, N)
    implicit none
    integer, intent(in) :: N
    real(8), intent(in) :: A(N,N), B(N,N)
    real(8), intent(inout) :: C(N,N) 
    integer :: i, j, k
    real(8) :: b_kj

    ! ---- optimised kernel: k->j->i (innermost = row index) -------------------
    do k = 1, N
        do j = 1, N
            b_kj = B(k,j)              ! scalar: stays in register
            do i = 1, N                ! innermost over i -> stride-1 for A & C
                C(i,j) = C(i,j) + A(i,k) * b_kj
            end do
        end do
    end do
end subroutine compute_matmul_optimized
