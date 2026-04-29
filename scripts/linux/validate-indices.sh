#!/usr/bin/env bash
# =============================================================================
# validate-indices.sh
# homelab-elk-soc — Lab validation script
# =============================================================================
# Purpose: Lists all Elasticsearch indices and reports event counts for the
#          three main lab index patterns: winlogbeat-*, filebeat-*, auditbeat-*
#          Run on ELK-SIEM (192.168.10.100).
#
# Usage:
#   chmod +x validate-indices.sh
#   ES_USER=elastic ES_PASSWORD=your_password_here ./validate-indices.sh
# =============================================================================

set -euo pipefail

ES_HOST="${ES_HOST:-https://localhost:9200}"
ES_USER="${ES_USER:-elastic}"
ES_PASSWORD="${ES_PASSWORD:-}"

if [[ -z "${ES_PASSWORD}" ]]; then
  echo "[ERROR] ES_PASSWORD is not set."
  echo "  export ES_PASSWORD=your_password_here"
  exit 1
fi

echo "============================================================"
echo "  Elasticsearch Index Validation"
echo "  Host: ${ES_HOST}"
echo "  $(date)"
echo "============================================================"

echo ""
echo "--- All Indices ---"
curl -sk -u "${ES_USER}:${ES_PASSWORD}" \
  "${ES_HOST}/_cat/indices?v&s=index&h=index,docs.count,store.size,health"

echo ""
echo "--- Winlogbeat Event Count ---"
WINLOG_COUNT=$(curl -sk -u "${ES_USER}:${ES_PASSWORD}" \
  "${ES_HOST}/winlogbeat-*/_count" | grep -o '"count":[0-9]*' | cut -d: -f2)
echo "  winlogbeat-*: ${WINLOG_COUNT} events"

echo ""
echo "--- Filebeat Event Count ---"
FB_COUNT=$(curl -sk -u "${ES_USER}:${ES_PASSWORD}" \
  "${ES_HOST}/filebeat-*/_count" | grep -o '"count":[0-9]*' | cut -d: -f2)
echo "  filebeat-*: ${FB_COUNT} events"

echo ""
echo "--- Auditbeat Event Count ---"
AB_COUNT=$(curl -sk -u "${ES_USER}:${ES_PASSWORD}" \
  "${ES_HOST}/auditbeat-*/_count" | grep -o '"count":[0-9]*' | cut -d: -f2)
echo "  auditbeat-*: ${AB_COUNT} events"

echo ""
echo "--- Total ---"
TOTAL=$((WINLOG_COUNT + FB_COUNT + AB_COUNT))
echo "  Total across all lab indices: ${TOTAL} events"

echo ""
echo "============================================================"
echo "  Index validation complete."
echo "============================================================"
