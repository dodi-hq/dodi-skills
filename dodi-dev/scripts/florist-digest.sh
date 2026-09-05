#!/usr/bin/env bash
# Emit the Florist digest (florist-worker-contract.md § 4, per-seat table § 9)
# mechanically, validated against the lane in FLORIST_LANE, so the closing
# step of a seat is "run this" rather than "remember the grammar".
#
#   florist-digest.sh <outcome> [key=value ...] [--evidence kind=<k> ref=<r> sha=<s|->]...
#
# Prints exactly the FLORIST-STATUS line and the FLORIST-EVIDENCE lines, in
# order, and nothing else on stdout. Exit 2 with the reason on stderr when the
# digest would NOT be a submission (wrong lane, missing required field or
# evidence row, reserved ref, bad kind) — fix the input and run again; the
# kernel would otherwise throw the run away and settle the attempt.
# Refuses in manual mode (FLORIST_UNIT unset): a digest is never emitted there.
set -euo pipefail

die() { echo "florist-digest: $*" >&2; exit 2; }

[[ -n "${FLORIST_UNIT:-}" ]] || die "FLORIST_UNIT is unset — manual mode, no digest is ever emitted"
lane="${FLORIST_LANE:-}"
[[ -n "$lane" ]] || die "FLORIST_LANE is unset — cannot validate the digest against a seat"
[[ $# -ge 1 ]] || die "usage: florist-digest.sh <outcome> [key=value ...] [--evidence kind=.. ref=.. sha=..]..."

outcome="$1"; shift
fields=()
ev_kinds=(); ev_refs=(); ev_shas=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --evidence)
      shift
      k=""; r=""; s=""
      while [[ $# -gt 0 && "$1" != "--evidence" ]]; do
        case "$1" in
          kind=*) k="${1#kind=}" ;;
          ref=*) r="${1#ref=}" ;;
          sha=*) s="${1#sha=}" ;;
          *) die "unexpected evidence token '$1' (want kind= ref= sha=)" ;;
        esac
        shift
      done
      [[ -n "$k" && -n "$r" && -n "$s" ]] || die "an --evidence row needs kind=, ref= and sha= (sha=- when there is none)"
      case "$k" in pr|ci|artifact|thread|verdict) ;; *) die "unknown evidence kind '$k' (pr|ci|artifact|thread|verdict)" ;; esac
      [[ "$r" == clean-final:* ]] && die "ref=clean-final:… is manager-reserved — never emit it"
      ev_kinds+=("$k"); ev_refs+=("$r"); ev_shas+=("$s")
      ;;
    *=*) fields+=("$1"); shift ;;
    *) die "unexpected token '$1' (fields are key=value; evidence rows start with --evidence)" ;;
  esac
done

field() { local key="$1" f; for f in "${fields[@]+"${fields[@]}"}"; do [[ "$f" == "$key="* ]] && { printf '%s' "${f#"$key"=}"; return 0; }; done; return 1; }
has_kind() { local want="$1" i; for i in "${!ev_kinds[@]}"; do [[ "${ev_kinds[$i]}" == "$want" ]] && return 0; done; return 1; }
has_kind_sha() { local want="$1" sha="$2" i; for i in "${!ev_kinds[@]}"; do [[ "${ev_kinds[$i]}" == "$want" && "${ev_shas[$i]}" == "$sha" ]] && return 0; done; return 1; }
has_kind_real_sha() { local want="$1" i; for i in "${!ev_kinds[@]}"; do [[ "${ev_kinds[$i]}" == "$want" && "${ev_shas[$i]}" != "-" ]] && return 0; done; return 1; }

# Walls are accepted in every lane and need no evidence (§ 5).
case "$outcome" in
  blocked|declined)
    reason="$(field reason || true)"
    [[ -n "$reason" ]] || die "$outcome needs reason=<reasonId>"
    ;;
  *)
    case "$lane" in
      contract-drafting)
        [[ "$outcome" == artifact-ready ]] || die "lane contract-drafting accepts only artifact-ready (or blocked/declined), not '$outcome'"
        has_kind_real_sha artifact || die "artifact-ready needs an artifact row with a real sha (the pushed contract commit)"
        ;;
      contract-review)
        case "$outcome" in
          clean-final)
            tier="$(field delivery-tier || true)"
            [[ "$tier" == standard || "$tier" == capable ]] || die "clean-final in contract-review needs delivery-tier=standard|capable"
            has_kind_real_sha thread || die "clean-final needs a thread row whose sha is the pinned contract SHA"
            ;;
          findings) has_kind thread || die "findings needs a thread row" ;;
          *) die "lane contract-review accepts clean-final|findings (or blocked/declined), not '$outcome'" ;;
        esac
        ;;
      implementing)
        case "$outcome" in
          impl-ready)
            head="$(field head || true)"; [[ -n "$head" ]] || die "impl-ready needs head=<pushed sha>"
            has_kind_sha artifact "$head" || die "impl-ready needs an artifact row with sha=head ($head)"
            has_kind thread || die "impl-ready needs a thread row (the clean closing pre-PR round)"
            has_kind_sha ci "$head" || die "impl-ready needs a ci row with sha=head ($head)"
            ;;
          demote) has_kind thread || die "demote needs a thread row (the demotion record)" ;;
          *) die "lane implementing accepts impl-ready|demote (or blocked/declined), not '$outcome'" ;;
        esac
        ;;
      code-review)
        case "$outcome" in
          clean-final) has_kind_real_sha thread || die "clean-final needs a thread row whose sha is the branch head now" ;;
          findings) has_kind thread || die "findings needs a thread row" ;;
          demote) has_kind thread || die "demote needs a thread row (the demotion record)" ;;
          *) die "lane code-review accepts clean-final|findings|demote (or blocked/declined), not '$outcome'" ;;
        esac
        ;;
      integrating)
        case "$outcome" in
          synced)
            head="$(field head || true)"; [[ -n "$head" ]] || die "synced needs head=<sha>"
            ;;
          merge-ready)
            head="$(field head || true)"; [[ -n "$head" ]] || die "merge-ready needs head=<sha>"
            has_kind_sha verdict "$head" || die "merge-ready needs a verdict row with sha=head ($head)"
            for i in "${!ev_kinds[@]}"; do
              [[ "${ev_kinds[$i]}" == verdict ]] || continue
              v="${ev_refs[$i]}"; base="${v%%:*}"
              case "$base" in ALIGNED|MINOR|LEGITIMATE_DIVERGENCE|MATERIAL_DRIFT|GATE1_AMENDMENT|GATE1_REFRESH) ;; *) die "verdict ref '$v' is not one of ALIGNED|MINOR|LEGITIMATE_DIVERGENCE|MATERIAL_DRIFT|GATE1_AMENDMENT|GATE1_REFRESH[:<unit>,…]" ;; esac
              [[ "$v" == *:* && "$base" != LEGITIMATE_DIVERGENCE ]] && die "only LEGITIMATE_DIVERGENCE carries siblings (got '$v')"
            done
            has_kind thread || die "merge-ready needs a thread row (the register entry / Seat Record)"
            ;;
          *) die "lane integrating accepts synced|merge-ready (or blocked/declined), not '$outcome'" ;;
        esac
        ;;
      *) die "unknown FLORIST_LANE '$lane' — no seat owes a digest here" ;;
    esac
    ;;
esac

line="FLORIST-STATUS: $outcome"
for f in "${fields[@]+"${fields[@]}"}"; do line+=" $f"; done
printf '%s\n' "$line"
for i in "${!ev_kinds[@]}"; do
  printf 'FLORIST-EVIDENCE: kind=%s ref=%s sha=%s\n' "${ev_kinds[$i]}" "${ev_refs[$i]}" "${ev_shas[$i]}"
done
