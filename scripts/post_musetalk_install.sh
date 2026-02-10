#!/bin/bash
# Post-installation script for MuseTalk avatar
# This script configures mmdet and mmcv after installation

set -e  # Exit on error

echo "MuseTalk Post-Installation Script"
echo "=================================="

# Detect virtual environment path
if [[ -n "$VIRTUAL_ENV" ]]; then
    VENV_PATH="$VIRTUAL_ENV"
else
    # Try to detect uv's virtual environment
    VENV_PATH=".venv"
    if [[ ! -d "$VENV_PATH" ]]; then
        echo "Warning: Virtual environment not found. Using system Python path."
        VENV_PATH=$(python -c "import sys; print(sys.prefix)")
    fi
fi

echo "Using virtual environment: $VENV_PATH"

# 1. Modify mmcv_maximum_version in mmdet's __init__.py file
# Try different Python versions
for PYTHON_VER in 3.10 3.11 3.12; do
    MMDET_INIT_FILE="$VENV_PATH/lib/python${PYTHON_VER}/site-packages/mmdet/__init__.py"
    
    if [[ -f "$MMDET_INIT_FILE" ]]; then
        echo "Found mmdet at: $MMDET_INIT_FILE"
        echo "Modifying mmcv_maximum_version in mmdet/__init__.py..."
        sed -i "s/mmcv_maximum_version = '[^']*'/mmcv_maximum_version = '2.2.1'/g" "$MMDET_INIT_FILE"
        echo "✓ mmcv_maximum_version has been updated to 2.2.1"
        break
    fi
done

if [[ ! -f "$MMDET_INIT_FILE" ]]; then
    echo "Warning: mmdet __init__.py file not found"
fi

# # 2. Install mmcv==2.2.0
# echo ""
# echo "Installing mmcv==2.2.0..."
# uv pip uninstall mmcv
# uv run mim install mmcv==2.2.0 --force --no-build-isolation

echo ""
echo "=================================="
echo "✓ Post-installation completed!"
echo "==================================" 