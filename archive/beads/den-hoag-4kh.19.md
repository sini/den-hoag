# den-hoag-4kh.19 — Migrate project STATE out of memory files into beads — memory keeps how-to-work, beads keep the dependency graph

> Evacuated from the beads payload on 2026-08-17 by strip-back **P10**.
> The bead still exists: id, title, status, priority, labels, parent and every dependency
> edge are unchanged. Only its description was replaced by a pointer stub naming this file.

| field | value |
| --- | --- |
| id | `den-hoag-4kh.19` |
| status at evacuation | deferred |
| priority | P1 |
| type | task |
| labels | (none) |
| parent | `den-hoag-4kh` |
| created | 2026-07-28T04:55:34Z by Jason Bowman |
| last updated | 2026-08-05T20:48:31Z |
| description bytes | 4183 |
| notes bytes | 0 |
| comments | 0 |
| dependencies | `None` (None) |

## Description

<!-- verbatim; restoring this bead means pasting exactly the block between this marker
     and the next `## ` heading back into the description. -->

MIGRATE PROJECT STATE OUT OF MEMORY FILES AND INTO BEADS. Memory keeps HOW-TO-WORK; beads keep STATE with a
real dependency graph. Owner-directed 2026-07-28.

OWNER: "these memories are useless if they aren't accessed and fed to context … memories that are too big to
read are too large to be kept — these predate me giving you access to codememory and beads tools."

════ MEASURED BASELINE (2026-07-28) ════
145 files / 5914 lines. By type: project 59 files / 3341 lines (56%) · feedback 69 / 1621 · reference 16 /
694 · user 1 / 16. MEMORY.md (the only guaranteed-read file, loaded every session) = 128 lines.
★ ONE FILE IS 927 LINES — 16% OF THE WHOLE CORPUS. It fails both ways at once: recalled it floods context,
un-recalled it is dead weight that goes stale unobserved. IT HAD GONE STALE, and was used on 2026-07-28 to
file a bead asserting work that had already shipped (see den-hoag-4kh.16's correction).
Removed already: a Syncthing sync-conflict duplicate of MEMORY.md, 114 lines, 93 lines divergent from the
live index.

════ THE ARCHITECTURE (recorded in memory as feedback_memory_architecture) ════
memory  = how to work (feedback) · who the user is (user) · pointers (reference) · THIN project pointers only
beads   = project state, work items, decisions with reasons, measured facts, AND THE DEPENDENCY GRAPH
codebase-memory = code structure, derived from the tree, never stale by construction
HARD CAP ~40 LINES per memory file. Over it: state (→ beads) or two facts (→ split).
★ THE LOAD-BEARING REASON FOR BEADS OVER MEMORY: A BEAD CAN BLOCK ANOTHER; A MEMORY CANNOT. Ordering,
blocking and "what must happen first" are GRAPH FACTS and belong in the graph. That is the capability the old
memories predate.

════ MIGRATION SURFACE — 18 project files over the cap, ~2400 lines ════
  927 project_den_hoag_features       ← IN PROGRESS: reconciliation dispatched, will land as beads + a thin pointer
  220 project_gen_rebuild
  211 project_gen_package
  114 project_opkssh_ssh_auth
  112 project_gen_select
  111 project_replicated_home_syncthing
   90 project_gen_resolve
   71 project_kernel_purity_arc
   69 project_hola
   64 project_gen_flake_rescope
   59 project_gen_theory_audit
   56 project_den_server_lsp_mcp
   52 project_denhoag_effects_audit
   46 project_delivery_edge_unification
   45 project_den_hoag_value_injection
   45 project_class_bucket_holdover      ← already carries a verified-at-HEAD correction header
   44 project_hoag_architecture
   44 project_gen_spec_audit

════ METHOD — per file, and it is NOT a copy-paste ════
1. READ it and classify every claim: SHIPPED / OPEN / STALE-OR-WRONG / DURABLE-GUIDANCE.
2. ★ VERIFY AT HEAD. A memory naming a file:line is a HYPOTHESIS. Two failures already this session came from
   trusting one: the class/channel disambiguation (shipped, filed as open) and the 2-stage schedule
   ("already tracked as 9xo.10" — a different bug, since closed; the construct was live and untracked).
3. SHIPPED → close or annotate the bead with the shipping evidence; DELETE from memory.
4. OPEN → ensure a bead exists, anchored to a VERIFIED site, with its dependency edges. Mark each edge
   CORRECTNESS or COST — cost edges are notes, never blocks.
5. STALE → delete, or correct with a verified-at-HEAD header if the file must survive.
6. DURABLE GUIDANCE → keep, but if it is really about HOW TO WORK it is a `feedback` memory, not `project`.
7. What remains is a THIN POINTER: what the project is, where its state lives (bead id), and any fact not
   derivable from the repo or the tracker.

════ ACCEPTANCE ════
No memory file over ~40 lines. `project` memories are pointers, not status logs. Every claim that survived is
verified at HEAD or explicitly marked unverified. MEMORY.md's one-line entries say enough to decide whether
to open the file. The state that left memory is in beads WITH ITS EDGES, not as a flat list.

★ DO NOT BULK-DELETE. Each file is an audit: the point is to recover the OPEN and MISSED work these files
have been silently holding, which is exactly what the reconciliation of the 927-line file is already
surfacing. A file deleted without that audit takes its untracked work with it.


## Comments (0)

(none)
