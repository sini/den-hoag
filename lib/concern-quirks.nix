# Compile the quirks concern (`den.quirks`) onto gen-pipe. A quirk is a scoped data channel: its
# value at a scope position is a deterministic fold over the contributions visible from that
# position under the pinned self → imports → parent traversal (gen-pipe B5). This file owns two
# things — (1) the ONE fleet-level `gen-pipe.compose` that assembles every quirk's channel plus its
# `ops` plus the fleet-wide policy `route`/`join`/`tee` ops into a single DAG (reference closure E4a
# and channel-name uniqueness E4b are therefore fleet-wide, not per-quirk); (2) `consumeAt`, the
# class-relative read that discharges the cross-class discipline (§2.5) with a den-framed abort.
#
# NO EFFECT RUNTIME: nothing here iterates or accumulates — `compose` is one gen-pipe call over a
# concatenated declaration list; `consumeAt` is one filter + one gen-pipe call. The channel algebra
# (fold order, dedup, provenance, class tags) all lives in gen-pipe (Law A1).
{
  prelude,
  pipe,
  errors,
}:
let
  # Duck-typed entry identity (gen-pipe compares class entries by id_hash without a gen-schema edge;
  # den mirrors that here for the cross-class pre-check). Falls back to `name` for hand-built entries.
  idOf = e: if e == null then null else (e.id_hash or e.name or (builtins.toJSON e));
  sameEntry = a: b: idOf a == idOf b;

  # A quirk's gen-pipe channel declaration: name is the quirk key, the channel record (type / merge /
  # dedup) rides from `q.channel`, and the quirk's declared cross-class `adapters` become the
  # channel's `class.adapters` (the only place a C′→C coercion is authorised — §2.5, never implicit).
  channelDeclOf =
    name: q:
    pipe.channel (
      {
        inherit name;
      }
      // (q.channel or { })
      // {
        class = {
          adapters = q.adapters or [ ];
        };
      }
    );
in
{
  # quirks    : { <name> = { channel ? { }; ops ? [ ]; adapters ? [ ]; }; }
  # policyOps : [ <gen-pipe op> ]  (route/join/tee, collected fleet-wide from collection-stratum
  #             policy declarations; per-quirk `ops` ride alongside — both feed the ONE compose).
  compose =
    {
      quirks,
      policyOps ? [ ],
    }:
    let
      channelDecls = prelude.mapAttrsToList channelDeclOf quirks;
      # ops (map/filter/route/…) declared on a quirk are derived channels/edges feeding the SAME
      # compose, so a cross-quirk `route`/`join` reaches its target within the one declaration set.
      opDecls = prelude.concatMap (q: q.ops or [ ]) (builtins.attrValues quirks);
    in
    pipe.compose (channelDecls ++ opDecls ++ policyOps);

  # The declared channel names (the quirk keys) — `local-collection-data` iterates these to know which
  # aspect content keys are channel emissions, and reads the composed record from `quirkDag.channels`.
  channelNames = quirks: builtins.attrNames quirks;

  # Class-relative read (§2.5, the cross-class discipline den owns). A consumer at class C reading a
  # channel receives class-neutral and same-class contributions freely; a contribution tagged C′ ≠ C
  # is legal ONLY through a declared C′→C adapter on the quirk. den frames the missing-adapter abort
  # (naming producer, channel, and both classes) BEFORE delegating the actual adaptation + "adapted"
  # provenance hop to `gen-pipe.consume` — den owns the policy, gen-pipe owns the mechanism.
  consumeAt =
    {
      outputs,
      at,
      channel,
      class,
      mode ? "values",
    }:
    let
      # gen-pipe's `outputs.at` emits an entry for EVERY composed channel (evaluate.nix: `at = p:
      # mapAttrs (name: ch: …) dag.channels`), so `.${channel.name}` is always present for a channel
      # in this dag; `or [ ]` is the same defensive default `localDataOf` uses — inert under that
      # contract, robust to a caller passing a channel from a different compose.
      seq = (outputs.at at).${channel.name}.contributions or [ ];
      adapters = channel.class.adapters or [ ];
      crossClass =
        c:
        let
          tag = c.class;
        in
        tag != null
        && !(sameEntry tag class)
        && !(builtins.any (a: sameEntry a.from tag && sameEntry a.to class) adapters);
      offenders = builtins.filter crossClass seq;
    in
    if offenders != [ ] then
      let
        c = builtins.head offenders;
      in
      errors.crossClassNoAdapter {
        channel = channel.name;
        producer = c.producer;
        tag = c.class;
        consuming = class;
      }
    else
      pipe.consume {
        inherit
          outputs
          at
          channel
          class
          mode
          ;
      };
}
