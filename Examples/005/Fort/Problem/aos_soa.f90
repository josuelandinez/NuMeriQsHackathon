program aos_soa
    implicit none
    integer, parameter :: NUM_PARTICLES = 10000000
    integer, parameter :: ITERATIONS = 200
    integer :: i, iter
    real(8) :: dt = 0.01d0

    ! BAD: Array of Structures (AoS) via Derived Types
    type :: particle
        real(8) :: x, y, z
        real(8) :: vx, vy, vz
    end type particle
    type(particle), allocatable :: aos(:)

    ! GOOD: Structure of Arrays (SoA)
    real(8), allocatable :: soa_x(:), soa_y(:), soa_z(:)
    real(8), allocatable :: soa_vx(:), soa_vy(:), soa_vz(:)

    ! Initialization
    allocate(aos(NUM_PARTICLES))
    allocate(soa_x(NUM_PARTICLES), soa_y(NUM_PARTICLES), soa_z(NUM_PARTICLES))
    allocate(soa_vx(NUM_PARTICLES), soa_vy(NUM_PARTICLES), soa_vz(NUM_PARTICLES))
    
    do i = 1, NUM_PARTICLES
        aos(i)%x = 1.0d0; aos(i)%y = 1.0d0; aos(i)%z = 1.0d0
        aos(i)%vx = 0.1d0; aos(i)%vy = 0.1d0; aos(i)%vz = 0.1d0
    end do
    soa_x = 1.0d0; soa_y = 1.0d0; soa_z = 1.0d0
    soa_vx = 0.1d0; soa_vy = 0.1d0; soa_vz = 0.1d0

    ! --- AoS Update ---
    do iter = 1, ITERATIONS
        do i = 1, NUM_PARTICLES
            aos(i)%x = aos(i)%x + aos(i)%vx * dt
            aos(i)%y = aos(i)%y + aos(i)%vy * dt
            aos(i)%z = aos(i)%z + aos(i)%vz * dt
        end do
    end do

    ! --- SoA Update ---
    do iter = 1, ITERATIONS
        do i = 1, NUM_PARTICLES
            soa_x(i) = soa_x(i) + soa_vx(i) * dt
            soa_y(i) = soa_y(i) + soa_vy(i) * dt
            soa_z(i) = soa_z(i) + soa_vz(i) * dt
        end do
    end do

    print *, "Done. Sample AoS X: ", aos(1)%x, ", SoA X: ", soa_x(1)
end program aos_soa
