program halo_exchange
    use mpi
    implicit none

    integer :: ierr, rank, size, step, i, w
    integer, parameter :: local_elements = 600000
    integer, parameter :: halo_size = 500000
    integer, parameter :: num_steps = 200
    integer :: left, right
    real(8), dimension(:), allocatable :: data_arr, new_data
    real(8) :: start_time, total_time, max_time
    integer :: total_size

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
        ! Sync communication
        call MPI_Sendrecv(data_arr(halo_size + 1), halo_size, MPI_DOUBLE_PRECISION, left, 1, &
                          data_arr(halo_size + local_elements + 1), halo_size, MPI_DOUBLE_PRECISION, right, 1, &
                          MPI_COMM_WORLD, MPI_STATUS_IGNORE, ierr)

        call MPI_Sendrecv(data_arr(local_elements + 1), halo_size, MPI_DOUBLE_PRECISION, right, 0, &
                          data_arr(1), halo_size, MPI_DOUBLE_PRECISION, left, 0, &
                          MPI_COMM_WORLD, MPI_STATUS_IGNORE, ierr)

        ! Encapsulated stencil call
        call compute_stencil(halo_size + 1, halo_size + local_elements, data_arr, new_data)
        
        data_arr = new_data
    end do

    total_time = MPI_Wtime() - start_time
    call MPI_Reduce(total_time, max_time, 1, MPI_DOUBLE_PRECISION, MPI_MAX, 0, MPI_COMM_WORLD, ierr)

    if (rank == 0) print *, "SYNC Heavy-Net Time Fortran: ", max_time, "s"

    deallocate(data_arr, new_data)
    call MPI_Finalize(ierr)

contains

    subroutine compute_stencil(start_idx, end_idx, d, nd)
        integer, intent(in) :: start_idx, end_idx
        real(8), dimension(:), intent(in) :: d
        real(8), dimension(:), intent(out) :: nd
        integer :: j, k
        real(8) :: val

        do j = start_idx, end_idx
            val = (d(j-1) + d(j) + d(j+1)) / 3.0d0
            do k = 1, 2
                val = sin(val) + 1.0d0
            end do
            nd(j) = val
        end do
    end subroutine compute_stencil

end program halo_exchange
