#!/usr/bin/bash
set -euo pipefail

# This script copies from vulkan headers to jai's vulkan module and generates the bindings

# TODO: other than default linux support
VULKAN_HEADERS_DIR="/usr/local/include/vulkan"
JAI_VULKAN_MODULE_DIR=$1
if [ -z "$JAI_VULKAN_MODULE_DIR" ]; then
    echo "Usage: $0 <path_to_jai_vulkan_module>"
    exit 1
fi

cp $VULKAN_HEADERS_DIR/vulkan.h $JAI_VULKAN_MODULE_DIR/source/vulkan.h
cp $VULKAN_HEADERS_DIR/vulkan_core.h $JAI_VULKAN_MODULE_DIR/source/vulkan_core.h
cp $VULKAN_HEADERS_DIR/vk_platform.h $JAI_VULKAN_MODULE_DIR/source/vk_platform.h

CWD=$(pwd)

cd $JAI_VULKAN_MODULE_DIR
jai $JAI_VULKAN_MODULE_DIR/generate.jai
cd $CWD
