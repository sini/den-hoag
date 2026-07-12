#!/usr/bin/env python3
# THE ORDER-EQUIVALENCE CHECKER (ledger u24 — the owner's C3 ruling: "We are fine with equivalent
# config — list ordering isn't a requirement"). Mechanically classifies every differing leaf of a
# recursive derivation-show walk between two system drvs into:
#   ORDER-ONLY — the masked values are equal as multisets (string: line multiset; structured: sorted
#                canonical JSON; single differing lines additionally compared as token multisets);
#   CASCADE    — equal after masking /nix/store/<hash>- prefixes (a pure downstream re-hash);
#   CONTENT    — anything else (NEVER waivable; blocks the n=1 gate).
# The ship criterion under the ruling: byte-EQUAL OR every differing leaf ∈ {ORDER-ONLY, CASCADE},
# with each ORDER-ONLY leaf's semantic caveat NAMED in the ledger row (u24) — never silently.
#
# Usage: order-equivalence-check.py <v1-drv> <candidate-drv>
import json, re, subprocess, sys
from collections import Counter

def show(drv):
    j = json.loads(subprocess.run(["nix", "derivation", "show", drv], capture_output=True, text=True).stdout)
    return list(j["derivations"].values())[0]

def mask(s):
    return re.sub(r"/nix/store/[a-z0-9]{32}-", "/nix/store/MASK-", s)

def sort_json(v):
    if isinstance(v, list):
        return sorted(json.dumps(sort_json(x), sort_keys=True) for x in v)
    if isinstance(v, dict):
        return {k: sort_json(x) for k, x in v.items()}
    return v

def token_multiset_equal(a, b):
    # single-line list-order refinement (the zsh-highlighters shape): the differing LINES between the
    # two strings pair up with equal token multisets.
    da = [l for l in a.splitlines() if l not in b.splitlines()]
    db = [l for l in b.splitlines() if l not in a.splitlines()]
    if len(da) != len(db) or not da:
        return False
    tok = lambda s: sorted(re.findall(r"[A-Za-z0-9_./-]+", s))
    return all(tok(x) == tok(y) for x, y in zip(da, db))

def classify_pair(va, vb):
    ma = mask(va) if isinstance(va, str) else json.loads(mask(json.dumps(va)))
    mb = mask(vb) if isinstance(vb, str) else json.loads(mask(json.dumps(vb)))
    if ma == mb:
        return "CASCADE"
    if isinstance(ma, str):
        if sorted(ma.splitlines()) == sorted(mb.splitlines()):
            return "ORDER-ONLY(lines)"
        if token_multiset_equal(ma, mb):
            return "ORDER-ONLY(tokens)"
        return "CONTENT"
    if json.dumps(sort_json(ma), sort_keys=True) == json.dumps(sort_json(mb), sort_keys=True):
        return "ORDER-ONLY(json)"
    return "CONTENT"

def walk(pa, pb, seen, rows, depth=0, maxdepth=20):
    a, b = show(pa), show(pb)
    na = {k.split("-", 1)[1]: k for k in a["inputs"]["drvs"]}
    nb = {k.split("-", 1)[1]: k for k in b["inputs"]["drvs"]}
    oa, ob = sorted(set(na) - set(nb)), sorted(set(nb) - set(na))
    verdicts = []
    for field in ("env", "structuredAttrs"):
        ea, eb = a.get(field) or {}, b.get(field) or {}
        for k in sorted(set(ea) | set(eb)):
            va, vb = ea.get(k), eb.get(k)
            if va != vb and k != "out":
                verdicts.append((k, classify_pair(va, vb)))
    if verdicts or oa or ob:
        rows.append((a["name"], verdicts, oa, ob))
    if depth < maxdepth:
        for n in sorted(set(na) & set(nb)):
            if na[n] != nb[n] and (na[n], nb[n]) not in seen:
                seen.add((na[n], nb[n]))
                walk("/nix/store/" + na[n], "/nix/store/" + nb[n], seen, rows, depth + 1, maxdepth)
    return rows

def main():
    v1, cand = sys.argv[1], sys.argv[2]
    if v1 == cand:
        print("VERDICT: BYTE-EQUAL")
        return 0
    rows = walk(v1, cand, set(), [])
    content = []
    for name, verdicts, oa, ob in rows:
        tags = {t for _, t in verdicts}
        if oa or ob:
            tags.add(f"INPUT-SET(v1={len(oa)},cand={len(ob)})")
        print(f"{name}: " + " + ".join(sorted(tags)))
        # a CONTENT field, or an input-set delta with no order/cascade explanation, blocks the gate.
        if any(t == "CONTENT" for t in tags) or ((oa or ob) and not verdicts):
            content.append(name)
    print()
    if content:
        print(f"VERDICT: NOT MET — {len(content)} CONTENT leaf(s): {sorted(set(content))}")
        return 1
    print("VERDICT: ORDER-EQUIVALENT (every differing leaf ORDER-ONLY/CASCADE — the u24 ruling gate)")
    return 0

if __name__ == "__main__":
    sys.exit(main())
