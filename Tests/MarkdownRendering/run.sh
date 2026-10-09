#!/bin/sh
set -eu
cd "$(dirname "$0")/../.."
mkdir -p .build/MarkdownRendering
swiftc -module-cache-path .build/MarkdownRendering/ModuleCache \
    MarkEdit/Services/MarkdownRenderer.swift Tests/MarkdownRendering/main.swift \
    -o .build/MarkdownRendering/checks
.build/MarkdownRendering/checks "${1:-.build/DerivedData/Build/Products/Debug-iphonesimulator/MarkEdit.app}"
