program mandelbrot_omp
    use omp_lib
    implicit none
    integer :: y
    integer :: width = 800, height = 800, max_iter = 100000
    integer(kind=8) :: total_work
    real(kind=8) :: start_time, end_time

    total_work = 0
    start_time = omp_get_wtime()

    ! BAD: Default static scheduling.
    !$omp parallel do reduction(+:total_work) schedule(static)
    do y = 0, height - 1
        total_work = total_work + compute_row_work(y, width, height, max_iter)
    end do
    !$omp end parallel do

    end_time = omp_get_wtime()

    print *, "Total iterations: ", total_work
    print *, "Time taken: ", end_time - start_time, " seconds"

contains

    ! Encapsulated for visibility in Cube/Score-P
    integer(kind=8) function compute_row_work(y, w, h, m_iter)
        integer, intent(in) :: y, w, h, m_iter
        integer :: x, iter
        real(kind=8) :: cx, cy, zx, zy, tmp

        compute_row_work = 0
        do x = 0, w - 1
            cx = (x - w/2.0d0) * 4.0d0/w
            cy = (y - h/2.0d0) * 4.0d0/w
            zx = 0.0d0; zy = 0.0d0; iter = 0
            
            do while (zx*zx + zy*zy <= 4.0d0 .and. iter < m_iter)
                tmp = zx*zx - zy*zy + cx
                zy = 2.0d0*zx*zy + cy
                zx = tmp
                iter = iter + 1
            end do
            compute_row_work = compute_row_work + iter
        end do
    end function compute_row_work

end program mandelbrot_omp
