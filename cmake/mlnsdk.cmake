find_program(GIT_EXECUTABLE git)

ExternalProject_Add(
    mlnsdk
    PREFIX ${CMAKE_BINARY_DIR}/vendor/mlnsdk
    GIT_REPOSITORY "https://github.com/lazychase/mlnsdk.git"
    GIT_TAG "v0.0.5"
    TIMEOUT 10
    CONFIGURE_COMMAND ""
    BUILD_COMMAND ""
    INSTALL_COMMAND ""
    UPDATE_COMMAND ""
)

ExternalProject_Get_Property(mlnsdk source_dir)
set(MLNSDK_INCLUDE_DIR ${source_dir}/include)
