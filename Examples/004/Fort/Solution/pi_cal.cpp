program pi_calc_fixed
    use mpi
    implicit none
    integer :: rank, size, ierr, chunk
    integer(kind=8) :: i, points_per_rank = 500000000
    integer(kind=8) :: local_inside = 0, global_inside = 0
    integer, parameter :: CHUNK_SIZE = 10000
    real(kind=8) :: x(CHUNK_SIZE), y(CHUNK_SIZE), pi_estimate

    call MPI_Init(ierr)
    call MPI_Comm_rank(MPI_COMM_WORLD, rank, ierr)
    call MPI_Comm_size(MPI_COMM_WORLD, size, ierr)

    ! FIX: Generate random numbers in array chunks for massive speedup
    do chunk = 1, points_per_rank, CHUNK_SIZE
        call random_number(x)
        call random_number(y)
        do i = 1, CHUNK_SIZE
            if (x(i)*x(i) + y(i)*y(i) <= 1.0d0) then
                local_inside = local_inside + 1
            end if
        end do
    end do

    call MPI_Reduce(local_inside, global_inside, 1, MPI_INTEGER8, MPI_SUM, 0, MPI_COMM_WORLD, ierr)

    if (rank == 0) then
        pi_estimate = 4.0d0 * real(global_inside, 8) / real(points_per_rank * size, 8)
        print *, "Estimated Pi: ", pi_estimate
    end if

    call MPI_Finalize(ierr)
end program pi_calc_fixed
