set(PARALLEL_NETCDF ON  CACHE BOOL "Enable parallel NetCDF" FORCE)
set(AVX2            ON CACHE BOOL "Enable AVX2 instruction set" FORCE)
set(CMAKE_INTERPROCEDURAL_OPTIMIZATION TRUE)

#only LLVM ifx supports 
set(X86_64V3        ON  CACHE BOOL "Enable x86_64v3 arch build" FORCE)

# set(CMAKE_AR "xiar" CACHE FILEPATH "Intel Archiver" FORCE)
message("Configuring UFS app for IOOS Sandbox Intel Compiler")
