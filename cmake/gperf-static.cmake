cmake_minimum_required(VERSION 3.2)
file(READ ${INPUT_FILENAME} INPUT)
string(REGEX REPLACE "\n(const struct alias )" "\nstatic \\1" INPUT "${INPUT}")
file(WRITE ${OUTPUT_FILENAME} "${INPUT}")
