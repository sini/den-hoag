# The demand concern (r2 §B demand stratum): route `demand` declarations into a dedicated gen-pipe
# channel whose B5-pinned order is `gen-demand.resolveAll`'s ordered intake, register the demand
# kinds as a downward-only DAG, run ONE resolveAll per fleet, and feed resources/wiring into gen-edge
# constructors. den-hoag owns only the wiring; the cascade discipline (termination, stratification,
# dedup, provenance) lives in gen-demand, the channel algebra in gen-pipe, the edge algebra in gen-edge.
#
# NO EFFECT RUNTIME: a demand is inert data; `local-demand-data` is one map + one producer sort;
# `collectDemands` is one concat; `resolveDemands` is one gen-demand call; `toEdges` is pure record
# construction. Emission ⊥ consumption is gen-demand's by SIGNATURE — a resolver receives its demand's
# own fields plus the static ctx, never resolved state (verified there, relied on here).
{
  prelude,
  demand,
  pipe,
  edge,
  resolve,
  scopeAdapter,
}:
let
  # den-internal keys on a `demand` declaration (declare.demand) that are not gen-demand payload.
  declKeys = [
    "__action"
    "__policy"
  ];
  # A `demand` declaration → a gen-demand demand record. The declaration's `subject` is already
  # entry-checked (A2, declarations.nix); its `kind` + remaining payload pass verbatim to
  # gen-demand.demand (which re-checks subject id_hash and reserved-key shadowing at intake).
  toDemand = d: demand.demand (removeAttrs d declKeys);

  # The dedicated demand channel (§B5): ordered-list merge, so its pinned contribution sequence IS the
  # ordered intake `resolveAll` consumes. It rides the ONE fleet-level quirk compose (lib/default.nix
  # threads it through `policyOps`), so channel-name uniqueness (E4b) stays fleet-wide. Bound here (not
  # only re-exported) so `localDemandData` contributes against it.
  demandChannel = pipe.channel {
    name = "__den-demands";
    merge = "ordered-list";
  };
in
{
  inherit demandChannel;

  # den.demandKinds.<name> = { below ? []; resolve; dedupKey ? null; fold ? null; } → gen-demand.mkKinds.
  # The downward-only DAG (acyclic `below`) is checked HERE, at registration — a cyclic / self / upward
  # `below` aborts naming the offending kinds (gen-demand.mkKinds via gen-graph condensation).
  registerKinds =
    kinds:
    demand.mkKinds (prelude.mapAttrsToList (name: k: demand.mkKind ({ inherit name; } // k)) kinds);

  # Collection-stratum attribute — this node's `demand` declarations, emitted as demand-channel
  # contributions in the A12 producer order (the SAME tie-break quirk emissions use: pinned by producer
  # identity, so the order is independent of policy declaration order and attrset iteration). Reads the
  # structural `declarations` attribute's demand group (a collection attr reading a structural one is
  # schedule-safe — `neron-order` reads `imports` the same way). Value is inert data: a list of gen-pipe
  # contributions whose `.value` is the gen-demand demand.
  localDemandData = resolve.attr {
    name = "local-demand-data";
    kind = "synthesized";
    stratum = "collection";
    readsAttrs = [ "declarations" ];
    compute =
      self: id:
      let
        node = self.node id;
        ownEntry = node.decls.__entry or null;
        demandDecls = (self.get id "declarations").actions.demand or [ ];
        # Per-producer emission index: two demands from ONE policy keep their emission order, while the
        # producer key (the emitting policy) orders ACROSS producers — the pinned order is therefore
        # permutation-stable. `contribution` rides each record for `sortByProducer` to project back.
        indexed =
          (prelude.foldl'
            (
              acc: d:
              let
                p = d.__policy or "«unattributed»";
                n = acc.counts.${p} or 0;
              in
              {
                counts = acc.counts // {
                  ${p} = n + 1;
                };
                out = acc.out ++ [
                  {
                    rank = 1; # policy producer (demands are relationship-concern facts; aspects are rank 0)
                    identity = p; # A12 producer key = the emitting policy
                    emissionIndex = n;
                    contribution = pipe.contribute {
                      channel = demandChannel;
                      value = toDemand d;
                      producer = {
                        entity = ownEntry;
                        scope = null;
                        aspect = null;
                        classes = [ ]; # demands are class-neutral data (gen-pipe T3)
                      };
                      class = null;
                    };
                  }
                ];
              }
            )
            {
              counts = { };
              out = [ ];
            }
            demandDecls
          ).out;
      in
      scopeAdapter.sortByProducer indexed;
  };

  # orderedDemands — the fleet-wide pinned intake list. No single scope node's neron cone covers the
  # whole fleet (neron is self → imports → parent, i.e. UPWARD), so den gathers each node's local demand
  # contributions and concatenates them in a canonical (sorted node-id) fleet order; within a node the
  # A12 tie-break already pins the order. Ordered-list merge is concatenation, so this IS the demand
  # channel's value read fleet-wide. Lazy: only forced when the resolution/edges below are demanded.
  collectDemands =
    eval:
    prelude.concatMap (nid: map (c: c.value) (eval.get nid "local-demand-data")) (
      prelude.sort (a: b: a < b) (builtins.attrNames eval.allNodes)
    );

  # ONE gen-demand.resolveAll per fleet. `orderedDemands` is the demand channel's pinned order;
  # resolvers receive each demand's own fields + the static `ctx` ONLY (emission ⊥ consumption is
  # gen-demand's invariant by signature — no resolved state is ever threaded in).
  resolveDemands =
    {
      kinds,
      orderedDemands,
      ctx,
    }:
    demand.resolveAll {
      inherit kinds ctx;
      demands = orderedDemands;
    };

  # resources → provider-target edges (a terminal output sink per (kind, resource key)); wiring →
  # consumer-target edges (the subject's instantiation root). Pure gen-edge record construction — the
  # edges are INERT (Task 9's edge toposort + materialization consumes them); both lists join the
  # fleet edge set (attribute 12).
  toEdges =
    resolution:
    let
      resourceEdges = prelude.concatLists (
        prelude.mapAttrsToList (
          kindName: byKey:
          prelude.mapAttrsToList (
            key: res:
            edge.edge {
              source = edge.sources.value res;
              target = edge.targets.output {
                output = [
                  "demands"
                  kindName
                  key
                ];
              };
              # the demand edge kind — the first live labeled kind (the typed-edge K component; an
              # un-labeled edge is unchanged, see REFERENCE.md). Cites the pre-registered `demand` row.
              kind = "demand";
            }
          ) byKey
        ) resolution.resources
      );
      wiringEdges = prelude.mapAttrsToList (
        idHash: w:
        edge.edge {
          source = edge.sources.value w.byKind;
          target = edge.targets.root {
            root = idHash;
            class = "wiring";
          };
          # the demand edge kind (K component) — the wiring arm, stamped like the resource arm above.
          kind = "demand";
        }
      ) resolution.wiring;
    in
    resourceEdges ++ wiringEdges;
}
