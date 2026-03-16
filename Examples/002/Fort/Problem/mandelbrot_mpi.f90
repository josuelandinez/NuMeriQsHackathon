program mandelbrot
    use mpi
    implicit none
    integer :: rank, size, ierr, y
    integer :: width = 800, height = 800, max_iter = 100000
    integer :: rows_per_rank, local_work, global_work
    integer :: start_row, end_row

    call MPI_Init(ierr)
    call MPI_Comm_rank(MPI_COMM_WORLD, rank, ierr)
    call MPI_Comm_size(MPI_COMM_WORLD, size, ierr)

    rows_per_rank = height / size
    local_work = 0

    ! BLOCK DISTRIBUTION: Ranks get contiguous chunks of rows.
    start_row = rank * rows_per_rank
    end_row   = (rank + 1) * rows_per_rank - 1

    do y = start_row, end_row
        local_work = local_work + compute_row(y, width, height, max_iter)
    end do

    ! Fast ranks will stall here in MPI_Reduce waiting for the slow center ranks
    call MPI_Reduce(local_work, global_work, 1, MPI_INTEGER, MPI_SUM, 0, MPI_COMM_WORLD, ierr)

    if (rank == 0) print *, "Total iterations: ", global_work

    call MPI_Finalize(ierr)

contains

    ! Encapsulated for visibility in the profiler
    integer function compute_row(y, w, h, m_iter)
        integer, intent(in) :: y, w, h, m_iter
        integer :: x, iter
        real(kind=8) :: cx, cy, zx, zy, tmp
        
        compute_row = 0
        do x = 0, w - 1
            cx = (x - w/2.0d0) * 4.0d0/w
            cy = (y - h/2.0d0) * 4.0d0/w
            zx = 0.0d0; zy = 0.0d0; iter = 0
            
            do while (zx*zx + zy*zy <= 4.0d0 .and. iter < m_iter)
                tmp = zx*zx - zy*zy + cx
                zy = 2.0d0*zx*zy + cy
                zx = tmp
                iter = iter + 1
                compute_row = compute_row + 1
            end do
        end do
    end function compute_row

end program mandelbrot
