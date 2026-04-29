#!/usr/bin/env bash
# =============================================================================
# validate-elastic-health.sh
# homelab-elk-soc — Lab validation script
# =============================================================================
# Purpose: Checks Elasticsearch cluster health and reports basic status.
#          Run on ELK-SIEM (192.168.10.100) as the medina_ja user.
#
# Usage:
#   chmod +x validate-elastic-health.sh
#   ES_USER=elastic ES_PASSWORD=your_password_here ./validate-elastic-health.sh
#
# Or set the variables in your shell environment before running.
# Never hardcode passwords in scripts.
# =============================================================================

set -euo pipefail

ES_HOST="${ES_HOST:-https://localhost:9200}"
ES_USER="${ES_USER:-elastic}"
ES_PASSWORD="${ES_PASSWORD:-}"

if [[ -z "${ES_PASSWORD}" ]]; then
  echo "[ERROR] ES_PASSWORD is not set. Export it before running this script."
  echo "  export ES_PASSWORD=your_password_here"
  exit 1
fi

echo "============================================================"
echo "  Elasticsearch Health Check"
echo "  Host: ${ES_HOST}"
echo "  $(date)"
echo "============================================================"

echo ""
echo "--- Cluster Health ---"
curl -sk -u "${ES_USER}:${ES_PASSWORD}" \
  "${ES_HOST}/_cluster/health?pretty"

echo ""
echo "--- Node Info ---"
curl -sk -u "${ES_USER}:${ES_PASSWORD}" \
  "${ES_HOST}/_cat/nodes?v"

echo ""
echo "--- Elasticsearch Service Status ---"
systemctl is-active elasticsearch && echo "  elasticsearch: RUNNING" || echo "  elasticsearch: NOT RUNNING"

echo ""
echo "============================================================"
echo "  Health check complete."
echo "============================================================"
