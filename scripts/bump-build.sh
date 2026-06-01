#!/bin/bash
# Auto-increment build number on every build.
# Reads/writes the integer counter in NewLXP/BuildNumber.txt and patches the
# embedded Info.plist of the freshly built .app with the incremented value.

set -euo pipefail

if [ "${CONFIGURATION}" != "Debug" ] && [ "${CONFIGURATION}" != "Release" ]; then
    exit 0
fi

PROJECT_DIR_REAL="${PROJECT_DIR}"
COUNTER_FILE="${PROJECT_DIR_REAL}/NewLXP/BuildNumber.txt"

if [ ! -f "${COUNTER_FILE}" ]; then
    echo "0" > "${COUNTER_FILE}"
fi

CURRENT="$(cat "${COUNTER_FILE}" | tr -d '[:space:]')"
if ! [[ "${CURRENT}" =~ ^[0-9]+$ ]]; then
    CURRENT=0
fi
NEXT=$((CURRENT + 1))
echo "${NEXT}" > "${COUNTER_FILE}"

PLIST="${TARGET_BUILD_DIR}/${INFOPLIST_PATH}"
if [ -f "${PLIST}" ]; then
    /usr/libexec/PlistBuddy -c "Set :CFBundleVersion ${NEXT}" "${PLIST}" 2>/dev/null \
        || /usr/libexec/PlistBuddy -c "Add :CFBundleVersion string ${NEXT}" "${PLIST}"
    echo "Bumped CFBundleVersion → ${NEXT}"
fi
