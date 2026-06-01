#!/bin/bash
# Auto-increment CFBundleVersion on every build.
#
# Why we patch the .pbxproj instead of the produced Info.plist:
#   With GENERATE_INFOPLIST_FILE=YES, Xcode runs ProcessInfoPlistFile *after*
#   user shell-script phases and regenerates Info.plist from build settings.
#   Patching .app/Info.plist directly would be silently overwritten —
#   exactly what was happening (xcodebuild logs showed "Bumped → N", but the
#   installed binary always reported CFBundleVersion=1).
#
# Now the script bumps the counter, writes the next value into BOTH
# CURRENT_PROJECT_VERSION lines in NewLXP.xcodeproj/project.pbxproj, and
# Xcode then naturally embeds it in Info.plist via -expandbuildsettings.

set -euo pipefail

if [ "${CONFIGURATION}" != "Debug" ] && [ "${CONFIGURATION}" != "Release" ]; then
    exit 0
fi

PROJECT_DIR_REAL="${PROJECT_DIR}"
COUNTER_FILE="${PROJECT_DIR_REAL}/NewLXP/BuildNumber.txt"
PBXPROJ="${PROJECT_DIR_REAL}/NewLXP.xcodeproj/project.pbxproj"

if [ ! -f "${COUNTER_FILE}" ]; then
    echo "0" > "${COUNTER_FILE}"
fi

CURRENT="$(cat "${COUNTER_FILE}" | tr -d '[:space:]')"
if ! [[ "${CURRENT}" =~ ^[0-9]+$ ]]; then
    CURRENT=0
fi
NEXT=$((CURRENT + 1))
echo "${NEXT}" > "${COUNTER_FILE}"

# Replace every "CURRENT_PROJECT_VERSION = <number>;" with the new value.
# BSD sed (the macOS default) needs the empty -i argument.
if [ -f "${PBXPROJ}" ]; then
    /usr/bin/sed -i '' -E "s/CURRENT_PROJECT_VERSION = [0-9]+;/CURRENT_PROJECT_VERSION = ${NEXT};/g" "${PBXPROJ}"
    echo "Bumped CURRENT_PROJECT_VERSION → ${NEXT}"
fi

# Belt-and-suspenders: also patch the produced Info.plist if it already exists
# (covers the rare case where ProcessInfoPlistFile happened to run first).
PLIST="${TARGET_BUILD_DIR}/${INFOPLIST_PATH}"
if [ -f "${PLIST}" ]; then
    /usr/libexec/PlistBuddy -c "Set :CFBundleVersion ${NEXT}" "${PLIST}" 2>/dev/null || true
fi
