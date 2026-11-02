#!/usr/bin/env bash
#
# Turns a Trivy JSON report into a markdown summary on stdout.
#
#   buildscripts/vuln-summary.sh <trivy-report.json> [title]
#
# Exit status: 0 when the report has no CRITICAL vulnerability that already has
# a fixed version, 1 otherwise. CRITICAL ones without a fix and everything below
# CRITICAL are listed but never fail the run.

set -euo pipefail

report="${1:?usage: vuln-summary.sh <trivy-report.json> [title]}"
title="${2:-Vulnerabilities}"

jq -r --arg title "${title}" '
  [.Results[]? | .Target as $t | .Vulnerabilities[]? | . + {target: $t}] as $v
  | def total($s): [$v[] | select(.Severity == $s)] | length;
    def fixable($s): [$v[] | select(.Severity == $s and ((.FixedVersion // "") != ""))] | length;
    def line: "- \(.Severity) \(.VulnerabilityID) \(.PkgName) \(.InstalledVersion) (fixed in \((.FixedVersion // "") | if . == "" then "no release yet" else . end))";
    "### \($title)\n\n| Severity | Found | With a fix |\n|---|---|---|\n"
    + (["CRITICAL", "HIGH", "MEDIUM", "LOW"] | map("| \(.) | \(total(.)) | \(fixable(.)) |") | join("\n"))
    + "\n\n"
    + (
        [$v[] | select(.Severity == "CRITICAL" or .Severity == "HIGH")]
        | unique_by(.VulnerabilityID + .PkgName + .InstalledVersion)
        | sort_by(.Severity, .PkgName)
        | if length == 0 then "No CRITICAL or HIGH vulnerabilities."
          else "CRITICAL and HIGH:\n\n" + (map(line) | join("\n")) end
      )
    + "\n"
' "${report}"

fixable_critical="$(jq '[.Results[]?.Vulnerabilities[]? | select(.Severity == "CRITICAL" and ((.FixedVersion // "") != ""))] | length' "${report}")"
if [ "${fixable_critical}" -gt 0 ]; then
  echo "${fixable_critical} CRITICAL vulnerabilities have a fix available." >&2
  exit 1
fi
