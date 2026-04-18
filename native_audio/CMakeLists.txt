cmake_minimum_required(VERSION 3.10)

project(audio_engine)

# FFmpeg Paths
set(FFMPEG_DIR ${CMAKE_CURRENT_SOURCE_DIR}/ffmpeg)
set(FFMPEG_INCLUDE_DIR ${FFMPEG_DIR}/include)
set(FFMPEG_LIB_DIR ${FFMPEG_DIR}/libs)

# Verify FFmpeg libraries exist before attempting to link
find_library(AVFORMAT_LIB avformat PATHS ${FFMPEG_LIB_DIR} NO_DEFAULT_PATH)
find_library(AVCODEC_LIB avcodec PATHS ${FFMPEG_LIB_DIR} NO_DEFAULT_PATH)
find_library(SWRESAMPLE_LIB swresample PATHS ${FFMPEG_LIB_DIR} NO_DEFAULT_PATH)
find_library(AVUTIL_LIB avutil PATHS ${FFMPEG_LIB_DIR} NO_DEFAULT_PATH)

add_library(audio_engine SHARED
    audio_engine.cpp
)

target_include_directories(audio_engine PRIVATE 
    include
)

# Conditional FFmpeg support
if(AVFORMAT_LIB AND AVCODEC_LIB AND SWRESAMPLE_LIB AND AVUTIL_LIB)
    message(STATUS "Famsic: FFmpeg Found! Enabling Video Audio Support.")
    target_compile_definitions(audio_engine PRIVATE USE_FFMPEG)
    target_include_directories(audio_engine PRIVATE ${FFMPEG_INCLUDE_DIR})
    target_link_libraries(audio_engine
        ${AVFORMAT_LIB}
        ${AVCODEC_LIB}
        ${SWRESAMPLE_LIB}
        ${AVUTIL_LIB}
        z
        m
    )
else()
    message(WARNING "Famsic: FFmpeg NOT Found in ${FFMPEG_DIR}. Video extraction will be disabled.")
endif()

if(ANDROID)
    target_link_libraries(audio_engine
        log
    )
endif()
