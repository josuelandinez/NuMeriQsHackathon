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
    local_inside = run_monte_carlo_vector(points_per_rank)

    call MPI_Reduce(local_inside, global_inside, 1, MPI_INTEGER8, MPI_SUM, 0, MPI_COMM_WORLD, ierr)

    if (rank == 0) then
        pi_estimate = 4.0d0 * real(global_inside, 8) / real(points_per_rank * size, 8)
        print *, "Estimated Pi (Vectorized): ", pi_estimate
    end if

    call MPI_Finalize(ierr)

contains

    integer(kind=8) function run_monte_carlo_vector(n)
        integer(kind=8), intent(in) :: n
        integer(kind=8) :: i, chunk
        integer, parameter :: CHUNK_SIZE = 10000
        real(kind=8) :: x(CHUNK_SIZE), y(CHUNK_SIZE)
        
        run_monte_carlo_vector = 0
        do chunk = 1, n, CHUNK_SIZE
            ! Fortran Intrinsic Vectorization
            call random_number(x)
            call random_number(y)
            do i = 1, CHUNK_SIZE
                if (x(i)*x(i) + y(i)*y(i) <= 1.0d0) then
                    run_monte_carlo_vector = run_monte_carlo_vector + 1
                end if
            end do
        end do
    end function run_monte_carlo_vector

end program pi_calc
