#!/usr/bin/env bash
# =============================================================================
# trigger-passwd-fim-test.sh
# homelab-elk-soc — Lab validation script
# =============================================================================
# Purpose: Tests the Auditbeat file integrity monitoring (FIM) pipeline by
#          creating and modifying a SAFE test file — NOT /etc/passwd or any
#          system authentication file.
#
#          /etc/passwd, /etc/shadow, and /etc/sudoers should never be modified
#          casually for testing purposes. This script uses a dedicated test file
#          at /tmp/fim-test-file to verify the FIM pipeline is working end-to-end.
#
#          After confirming the pipeline works with this test file, you can be
#          confident the Auditbeat rule will fire on real changes to the
#          monitored critical paths.
#
# Prerequisites:
#   - Auditbeat must be installed and running
#   - /tmp/fim-test-file must be added to the Auditbeat file_integrity paths
#     in /etc/auditbeat/auditbeat.yml:
#
#       - module: file_integrity
#         paths:
#           - /etc/passwd
#           - /etc/shadow
#           - /etc/sudoers
#           - /tmp/fim-test-file    <-- add this for testing
#
#   - Restart Auditbeat after updating the config:
#       sudo systemctl restart auditbeat
#
# Usage:
#   chmod +x trigger-passwd-fim-test.sh
#   ./trigger-passwd-fim-test.sh
#
# After running, check Kibana Discover for:
#   event.module: "file_integrity" AND file.path: "/tmp/fim-test-file"
# =============================================================================

set -euo pipefail

TEST_FILE="/tmp/fim-test-file"

echo "============================================================"
echo "  Auditbeat FIM Pipeline Test"
echo "  Test file: ${TEST_FILE}"
echo "  $(date)"
echo "============================================================"
echo ""
echo "  NOTE: This script modifies ONLY ${TEST_FILE}."
echo "  It does NOT touch /etc/passwd, /etc/shadow, or /etc/sudoers."
echo ""

echo "--- Step 1: Check Auditbeat is running ---"
if systemctl is-active --quiet auditbeat; then
  echo "  auditbeat: RUNNING"
else
  echo "  [ERROR] Auditbeat is not running. Start it first:"
  echo "  sudo systemctl start auditbeat"
  exit 1
fi

echo ""
echo "--- Step 2: Create test file ---"
echo "fim-test-baseline $(date)" > "${TEST_FILE}"
echo "  Created: ${TEST_FILE}"
sleep 2

echo ""
echo "--- Step 3: Modify test file (triggers FIM change event) ---"
echo "fim-test-modified $(date)" >> "${TEST_FILE}"
echo "  Modified: ${TEST_FILE}"
sleep 2

echo ""
echo "--- Step 4: Verify Auditbeat is logging ---"
echo "  Recent auditbeat log lines:"
sudo journalctl -u auditbeat -n 10 --no-pager

echo ""
echo "============================================================"
echo "  FIM test complete."
echo ""
echo "  Next step: In Kibana Discover, search for:"
echo "    event.module: \"file_integrity\" AND file.path: \"/tmp/fim-test-file\""
echo ""
echo "  If events appear, the Auditbeat FIM pipeline is working."
echo "  The Rule 10 detection will fire on real changes to the"
echo "  monitored critical paths (/etc/passwd, /etc/shadow, /etc/sudoers)."
echo "============================================================"

# Cleanup — remove the test file after verification
echo ""
echo "  Cleaning up test file..."
rm -f "${TEST_FILE}"
echo "  ${TEST_FILE} removed."
