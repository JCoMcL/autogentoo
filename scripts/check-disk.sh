#!/usr/bin/env sh

# Usage: ./check-disk-integrity.sh <device-or-image>
# Example: ./check-disk-integrity.sh /dev/sda
#          ./check-disk-integrity.sh myimage.img

if [ $# -ne 1 ]; then
    echo "Usage: $0 <device-or-image>"
    exit 1
fi

TARGET="$1"

# Helper: check if a command exists
have() { command -v "$1" >/dev/null 2>&1; }

# Detect device type
if [[ "$TARGET" =~ ^/dev/nvme ]]; then
    TYPE="nvme"
elif [[ "$TARGET" =~ ^/dev/sd ]] || [[ "$TARGET" =~ ^/dev/hd ]] || [[ "$TARGET" =~ ^/dev/vd ]]; then
    TYPE="ata"
elif [[ "$TARGET" =~ ^/dev/mmcblk ]]; then
    TYPE="mmc"
elif [[ -f "$TARGET" ]]; then
    TYPE="image"
else
    echo "Unknown or unsupported device/image: $TARGET"
    exit 2
fi

echo "Detected type: $TYPE"

# S.M.A.R.T. check (if supported)
if [[ "$TYPE" == "ata" || "$TYPE" == "mmc" ]]; then
    if have smartctl; then
        echo "=== S.M.A.R.T. health summary ==="
        smartctl -H "$TARGET" || true
        echo "=== S.M.A.R.T. detailed info ==="
        smartctl -a "$TARGET" || true
    else
        echo "smartctl not found, skipping S.M.A.R.T. check."
    fi
elif [[ "$TYPE" == "nvme" ]]; then
    if have nvme; then
        echo "=== NVMe health summary ==="
        nvme smart-log "$TARGET" || true
    else
        echo "nvme-cli not found, skipping NVMe health check."
    fi
fi

# Performance test (non-destructive)
if [[ "$TYPE" == "ata" || $TYPE == "nvme" ]]; then
    if have hdparm; then
        echo "=== hdparm read speed test ==="
        hdparm -tT --direct "$TARGET"
    fi
fi

# Fake capacity check (for flash devices/images)
if [[ "$TYPE" == "mmc" || "$TYPE" == "image" ]]; then
    if have f3probe; then
        echo "=== f3probe fake capacity check ==="
        f3probe --destructive --time-ops "$TARGET"
    elif have f3write && have f3read; then
        echo "=== f3write/f3read fake capacity check ==="
        TMPDIR=$(mktemp -d)
        f3write -v "$TMPDIR"
        f3read -v "$TMPDIR"
        rm -rf "$TMPDIR"
    else
        echo "f3 tools not found, skipping fake capacity check."
    fi
fi

# Bad blocks scan (read-only)
if have badblocks; then
    echo "=== Scanning for bad blocks (read-only) ==="
    badblocks -sv "$TARGET"
else
    echo "badblocks not found, skipping bad block scan."
fi

# Image integrity check (for qcow2, etc.)
if [[ "$TYPE" == "image" ]]; then
    if have qemu-img; then
        echo "=== qemu-img check ==="
        qemu-img check "$TARGET"
    fi
fi

echo "Disk integrity checks completed for $TARGET"