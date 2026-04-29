#!/usr/bin/env bash
# =============================================================================
# validate-logstash-port.sh
# homelab-elk-soc — Lab validation script
# =============================================================================
# Purpose: Verifies Logstash is listening on port 5044 (Beats input).
#          Also checks that the Logstash service is running.
#          Run on ELK-SIEM (192.168.10.100).
#
# Usage:
#   chmod +x validate-logstash-port.sh
#   ./validate-logstash-port.sh
# =============================================================================

set -euo pipefail

LOGSTASH_PORT=5044

echo "============================================================"
echo "  Logstash Port Validation"
echo "  Checking port: ${LOGSTASH_PORT}"
echo "  $(date)"
echo "============================================================"

echo ""
echo "--- Logstash Service Status ---"
if systemctl is-active --quiet logstash; then
  echo "  logstash: RUNNING"
else
  echo "  logstash: NOT RUNNING"
  echo "  Try: sudo systemctl start logstash"
  echo "  Logs: sudo journalctl -u logstash -n 50"
  exit 1
fi

echo ""
echo "--- Port 5044 Listener Check ---"
if ss -tlnp | grep -q ":${LOGSTASH_PORT}"; then
  echo "  Port ${LOGSTASH_PORT} is OPEN and listening"
  ss -tlnp | grep ":${LOGSTASH_PORT}"
else
  echo "  [WARNING] Port ${LOGSTASH_PORT} is NOT listening."
  echo "  Logstash may still be initializing (can take 60-90 seconds)"
  echo "  Or the beats.conf pipeline may have a configuration error"
  echo "  Check: sudo journalctl -u logstash -n 100"
  exit 1
fi

echo ""
echo "--- Logstash Pipeline Config Check ---"
if [[ -f /etc/logstash/conf.d/beats.conf ]]; then
  echo "  beats.conf: FOUND at /etc/logstash/conf.d/beats.conf"
else
  echo "  [WARNING] beats.conf not found at /etc/logstash/conf.d/beats.conf"
fi

echo ""
echo "============================================================"
echo "  Logstash port validation complete."
echo "============================================================"
