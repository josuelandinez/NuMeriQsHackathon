program aos_soa
    implicit none
    integer, parameter :: NUM_PARTICLES = 10000000
    integer, parameter :: ITERATIONS = 200
    integer :: i, iter
    real(8) :: dt = 0.01d0

    ! FIXED: Native Fortran contiguous arrays instead of Derived Types
    real(8), allocatable :: x(:), y(:), z(:)
    real(8), allocatable :: vx(:), vy(:), vz(:)

    ! Initialization
    allocate(x(NUM_PARTICLES), y(NUM_PARTICLES), z(NUM_PARTICLES))
    allocate(vx(NUM_PARTICLES), vy(NUM_PARTICLES), vz(NUM_PARTICLES))
    
    x = 1.0d0; y = 1.0d0; z = 1.0d0
    vx = 0.1d0; vy = 0.1d0; vz = 0.1d0

    ! --- SoA Update ---
    ! The compiler will heavily auto-vectorize this loop
    do iter = 1, ITERATIONS
        do i = 1, NUM_PARTICLES
            x(i) = x(i) + vx(i) * dt
            y(i) = y(i) + vy(i) * dt
            z(i) = z(i) + vz(i) * dt
        end do
    end do

    print *, "Done. Final SoA X for particle 1: ", x(1)
end program aos_soa
