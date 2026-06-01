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

# Build the argument list
ARGS="-s ${SCENE_PATH} -r ${REGULARIZATION_TYPE}"

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

echo "========================================"
echo " SuGaR – train_full_pipeline.py"
echo " Args: $ARGS"
echo "========================================"

exec python /app/train_full_pipeline.py $ARGS
