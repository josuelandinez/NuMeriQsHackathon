program halo_exchange
    use mpi
    implicit none

    integer :: ierr, rank, size, step, n
    integer, parameter :: local_elements = 600000
    integer, parameter :: halo_size = 500000
    integer, parameter :: num_steps = 200
    integer :: left, right
    real(8), dimension(:), allocatable :: data_arr, new_data
    real(8) :: start_time, total_time, max_time
    integer :: total_size
    integer, dimension(4) :: reqs
    integer, dimension(MPI_STATUS_SIZE, 4) :: stats

    ! Arrays to store indices for the edge cleanup
    integer, dimension(2) :: edge_starts, edge_ends

    call MPI_Init(ierr)
    call MPI_Comm_rank(MPI_COMM_WORLD, rank, ierr)
    call MPI_Comm_size(MPI_COMM_WORLD, size, ierr)

    total_size = local_elements + 2 * halo_size
    allocate(data_arr(total_size))
    allocate(new_data(total_size))
    data_arr = 1.0d0
    new_data = 1.0d0

    left = rank - 1
    right = rank + 1
    if (rank == 0) left = MPI_PROC_NULL
    if (rank == size - 1) right = MPI_PROC_NULL

    call MPI_Barrier(MPI_COMM_WORLD, ierr)
    start_time = MPI_Wtime()

    do step = 1, num_steps
        n = 0
        ! 1. Initiate non-blocking communication
        if (left /= MPI_PROC_NULL) then
            n = n + 1
            call MPI_Irecv(data_arr(1), halo_size, MPI_DOUBLE_PRECISION, left, 0, &
                           MPI_COMM_WORLD, reqs(n), ierr)
            n = n + 1
            call MPI_Isend(data_arr(halo_size + 1), halo_size, MPI_DOUBLE_PRECISION, left, 1, &
                           MPI_COMM_WORLD, reqs(n), ierr)
        end if

        if (right /= MPI_PROC_NULL) then
            n = n + 1
            call MPI_Irecv(data_arr(halo_size + local_elements + 1), halo_size, MPI_DOUBLE_PRECISION, right, 1, &
                           MPI_COMM_WORLD, reqs(n), ierr)
            n = n + 1
            call MPI_Isend(data_arr(local_elements + 1), halo_size, MPI_DOUBLE_PRECISION, right, 0, &
                           MPI_COMM_WORLD, reqs(n), ierr)
        end if

        ! 2. OVERLAP: Compute the bulk of the stencil (Inner cells)
        ! We pass a single range to the multi-range subroutine
        call compute_stencil_multi([halo_size + 2], [halo_size + local_elements - 1], 1, data_arr, new_data)

        ! 3. WAIT: Synchronize to ensure halo data has arrived
        if (n > 0) call MPI_Waitall(n, reqs, stats, ierr)

        ! 4. CLEANUP: Compute the edge cells that required halo data
        ! We pass two ranges at once to minimize subroutine call overhead
        edge_starts = [halo_size + 1, halo_size + local_elements]
        edge_ends   = [halo_size + 1, halo_size + local_elements]
        call compute_stencil_multi(edge_starts, edge_ends, 2, data_arr, new_data)

        ! 5. Update data for next step
        data_arr = new_data
    end do

    total_time = MPI_Wtime() - start_time
    call MPI_Reduce(total_time, max_time, 1, MPI_DOUBLE_PRECISION, MPI_MAX, 0, MPI_COMM_WORLD, ierr)

    if (rank == 0) print *, "ASYNC Overlap Time Fortran: ", max_time, "s"

    deallocate(data_arr, new_data)
    call MPI_Finalize(ierr)

contains

    subroutine compute_stencil_multi(starts, ends, num_ranges, d, nd)
        integer, dimension(:), intent(in) :: starts, ends
        integer, intent(in) :: num_ranges
        real(8), dimension(:), intent(in) :: d
        real(8), dimension(:), intent(out) :: nd
        integer :: r, j, k
        real(8) :: val

        do r = 1, num_ranges
            do j = starts(r), ends(r)
                val = (d(j-1) + d(j) + d(j+1)) / 3.0d0
                do k = 1, 2
                    val = sin(val) + 1.0d0
                end do
                nd(j) = val
            end do
        end do
    end subroutine compute_stencil_multi

end program halo_exchange
