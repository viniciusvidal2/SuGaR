#!/usr/bin/env bash
# =============================================================================
# docker-entrypoint.sh
# Translates environment variables into CLI flags for train_full_pipeline.py
# =============================================================================
set -e

# Validate required arguments
if [ -z "$SCENE_PATH" ]; then
    echo "[ERROR] SCENE_PATH environment variable is required."
    echo "        Set it with: -e SCENE_PATH=/data/my_scene"
    exit 1
fi

if [ -z "$REGULARIZATION_TYPE" ]; then
    echo "[ERROR] REGULARIZATION_TYPE environment variable is required."
    echo "        Supported values: sdf | density | dn_consistency"
    exit 1
fi

if [ -z "$OUTPUT_DIR" ]; then
    echo "[ERROR] OUTPUT_DIR environment variable is required."
    echo "        In Docker this is always /app/output (mounted from host)."
    exit 1
fi

# Build the argument list
ARGS="-s ${SCENE_PATH} -r ${REGULARIZATION_TYPE} --output_dir ${OUTPUT_DIR}"

[ -n "$GS_OUTPUT_DIR" ]                  && ARGS="$ARGS --gs_output_dir ${GS_OUTPUT_DIR}"
[ -n "$SURFACE_LEVEL" ]                  && ARGS="$ARGS -l ${SURFACE_LEVEL}"
[ -n "$N_VERTICES_IN_MESH" ]             && ARGS="$ARGS -v ${N_VERTICES_IN_MESH}"
[ -n "$PROJECT_MESH_ON_SURFACE_POINTS" ] && ARGS="$ARGS --project_mesh_on_surface_points ${PROJECT_MESH_ON_SURFACE_POINTS}"
[ -n "$BBOXMIN" ]                        && ARGS="$ARGS -b ${BBOXMIN}"
[ -n "$BBOXMAX" ]                        && ARGS="$ARGS -B ${BBOXMAX}"
[ -n "$CENTER_BBOX" ]                    && ARGS="$ARGS --center_bbox ${CENTER_BBOX}"
[ -n "$GAUSSIANS_PER_TRIANGLE" ]         && ARGS="$ARGS -g ${GAUSSIANS_PER_TRIANGLE}"
[ -n "$REFINEMENT_ITERATIONS" ]          && ARGS="$ARGS -f ${REFINEMENT_ITERATIONS}"
[ -n "$EXPORT_OBJ" ]                     && ARGS="$ARGS -t ${EXPORT_OBJ}"
[ -n "$SQUARE_SIZE" ]                    && ARGS="$ARGS --square_size ${SQUARE_SIZE}"
[ -n "$POSTPROCESS_MESH" ]               && ARGS="$ARGS --postprocess_mesh ${POSTPROCESS_MESH}"
[ -n "$POSTPROCESS_DENSITY_THRESHOLD" ]  && ARGS="$ARGS --postprocess_density_threshold ${POSTPROCESS_DENSITY_THRESHOLD}"
[ -n "$POSTPROCESS_ITERATIONS" ]         && ARGS="$ARGS --postprocess_iterations ${POSTPROCESS_ITERATIONS}"
[ -n "$EXPORT_PLY" ]                     && ARGS="$ARGS --export_ply ${EXPORT_PLY}"
[ -n "$LOW_POLY" ]                       && ARGS="$ARGS --low_poly ${LOW_POLY}"
[ -n "$HIGH_POLY" ]                      && ARGS="$ARGS --high_poly ${HIGH_POLY}"
[ -n "$REFINEMENT_TIME" ]                && ARGS="$ARGS --refinement_time ${REFINEMENT_TIME}"
[ -n "$ITERATIONS" ]                     && ARGS="$ARGS -i ${ITERATIONS}"
[ -n "$EVAL" ]                           && ARGS="$ARGS --eval ${EVAL}"
[ -n "$GPU" ]                            && ARGS="$ARGS --gpu ${GPU}"
[ -n "$WHITE_BACKGROUND" ]               && ARGS="$ARGS --white_background ${WHITE_BACKGROUND}"

# Note: OUTPUT_DIR is always included in ARGS (validated above), not optional.

echo "========================================"
echo " SuGaR – train_full_pipeline.py"
echo " Args: $ARGS"
echo "========================================"

# Add Python site-packages library paths (torch/lib and nvidia/*/lib) to LD_LIBRARY_PATH
# This resolves missing shared object errors (like libcudart.so) for PyTorch C++ extensions.
export LD_LIBRARY_PATH=$(python -c '
import os, torch
torch_lib = os.path.join(os.path.dirname(torch.__file__), "lib")
site_packages = os.path.dirname(os.path.dirname(torch.__file__))
nvidia_dir = os.path.join(site_packages, "nvidia")
paths = [torch_lib]
if os.path.exists(nvidia_dir):
    for d in os.listdir(nvidia_dir):
        lib_path = os.path.join(nvidia_dir, d, "lib")
        if os.path.isdir(lib_path):
            paths.append(lib_path)
print(":".join(paths))
'):$LD_LIBRARY_PATH

exec python /app/train_full_pipeline.py $ARGS
