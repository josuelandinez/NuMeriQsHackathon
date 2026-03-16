program pi_calc
    use mpi
    implicit none
    integer :: rank, size, ierr
    integer(kind=8) :: points_per_rank = 500000000
    integer(kind=8) :: local_inside, global_inside
    real(kind=8) :: pi_estimate

    call MPI_Init(ierr)
    call MPI_Comm_rank(MPI_COMM_WORLD, rank, ierr)
    call MPI_Comm_size(MPI_COMM_WORLD, size, ierr)

    ! Encapsulated call for profiler visibility
    local_inside = run_monte_carlo_scalar(points_per_rank)

    call MPI_Reduce(local_inside, global_inside, 1, MPI_INTEGER8, MPI_SUM, 0, MPI_COMM_WORLD, ierr)

    if (rank == 0) then
        pi_estimate = 4.0d0 * real(global_inside, 8) / real(points_per_rank * size, 8)
        print *, "Estimated Pi (Scalar): ", pi_estimate
    end if

    call MPI_Finalize(ierr)

contains

    integer(kind=8) function run_monte_carlo_scalar(n)
        integer(kind=8), intent(in) :: n
        integer(kind=8) :: i
        real(kind=8) :: x, y
        
        run_monte_carlo_scalar = 0
        do i = 1, n
            call random_number(x)
            call random_number(y)
            if (x*x + y*y <= 1.0d0) then
                run_monte_carlo_scalar = run_monte_carlo_scalar + 1
            end if
        end do
    end function run_monte_carlo_scalar

end program pi_calc
