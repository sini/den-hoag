# den-compat INCLUDE IDENTITY (board #58, Fork A) — the F1-F5 witnesses of the content-delivery rung.
#
# DIAGNOSIS HISTORY (the corpus zero-content finding): a navigated STATIC include (`includes = with
# den.aspects; [ … ]`) grounded NAMELESS (`compile.nix groundRec` stamped no identity), so gen-aspects
# `identity.key` keyed every one `"<anon>"`; resolved-aspects' forwardExpand seen-dedup kept only the
# FIRST sibling (F4), a transitive chain starved behind its intermediate's key (F2/F3), and — because
# the member spine is CONTENT-DRIVEN (output-modules `contentIdsOf` filters on a non-empty
# class-modules bucket) — a starved host vanished from `nixosConfigurations` entirely. The fn arm had
# been fixed (DISTINCT WRAP NAMES, per-position `meta.loc`); the static arm was that fix's uncovered
# twin. Under the corpus (every host = a multi-element include list of role aspects with their own
# includes) this collapsed ALL aspect content delivery.
#
# THE FIX (two halves, both compat-side — zero core edits):
#   • ANNOTATION — the post-fold `__provider` walk (annotate.nix; v1 annotateDeep, pin 11866c16
#     types.nix:561-574) stamps every aspect-tree node's root-relative path, at the bridge (corpus) and
#     the flake-module wiring (this direct path) alike;
#   • IDENTITY — `stampProvider` (compile.nix; v1 wrapChild, normalize.nix:95-119) derives
#     `name = last __provider` + `meta.aspect-chain = init __provider`, so `identity.key` = the FULL
#     provider path — the SAME identity from every inclusion path (F5: N references dedup to ONE
#     resolution, v1's `__provider`-name dedup — ledger u5 fixed-by), with the DISTINCT POSITIONAL name
#     as the annotation-less inline-literal fallback (v1's `<parent>/<anon>:<idx>` posture). The stamped
#     value CARRIES its content — no registry lookup (the resolveAspectRef no-lookup posture).
{ denCompat, ... }:
let
  keysAt = den: id: map (n: n.key) (den.structural.eval.get id "resolved-aspects");
  bucketAt =
    den: id: cls:
    (den.structural.eval.get id "class-modules").${cls} or [ ];
  mk = fx: denCompat.mkDen [ fx ];

  # F1 — entity → SINGLE nested-path leaf (the always-worked baseline; provider identity now).
  f1 =
    { den, ... }:
    {
      den.hosts.x86_64-linux.h1.class = "nixos";
      den.aspects.core.systemd.boot.nixos = {
        marker.f1 = true;
      };
      den.aspects.h1.includes = with den.aspects; [ core.systemd.boot ];
    };
  f1den = (mk f1).den;

  # F2 — entity → INTERMEDIATE role aspect → leaf (the corpus `roles.default` shape; the transitive
  # chain that starved pre-fix: intermediate and leaf both keyed "<anon>", leaf never resolved, bucket
  # empty, host DROPPED from the content-driven spine).
  f2 =
    { den, ... }:
    {
      den.hosts.x86_64-linux.h2.class = "nixos";
      den.aspects.svc.openssh.nixos = {
        marker.f2 = true;
      };
      den.aspects.roles.default.includes = with den.aspects; [ svc.openssh ];
      den.aspects.h2.includes = with den.aspects; [ roles.default ];
    };
  f2den = (mk f2).den;
  f2built = mk f2;

  # F3 — the same transitive chain with all SINGLE-LEVEL names (mechanism is indirection, not nesting).
  f3 =
    { den, ... }:
    {
      den.hosts.x86_64-linux.h3.class = "nixos";
      den.aspects.leaf.nixos = {
        marker.f3 = true;
      };
      den.aspects.mid.includes = with den.aspects; [ leaf ];
      den.aspects.h3.includes = with den.aspects; [ mid ];
    };
  f3built = mk f3;

  # F4 — entity → TWO sibling leaves (first-sibling-wins pre-fix: leafb's content silently dropped).
  f4 =
    { den, ... }:
    {
      den.hosts.x86_64-linux.h4.class = "nixos";
      den.aspects.leafa.nixos = {
        marker.a = true;
      };
      den.aspects.leafb.nixos = {
        marker.b = true;
      };
      den.aspects.h4.includes = with den.aspects; [
        leafa
        leafb
      ];
    };
  f4den = (mk f4).den;

  # F4' — sibling INLINE LITERALS (annotation-less): the positional fallback keys them distinctly.
  f4lit =
    { den, ... }:
    {
      den.hosts.x86_64-linux.h4.class = "nixos";
      den.aspects.h4.includes = [
        { nixos.marker.la = true; }
        { nixos.marker.lb = true; }
      ];
    };
  f4litden = (mk f4lit).den;

  # F5 — MULTI-REFERENCE dedup (the u5 shape, the corpus's 11× nginx): one aspect referenced from TWO
  # sibling includes resolves ONCE — one provider-keyed node, one bucket entry (list-typed nixos options
  # can no longer concatenate duplicates).
  f5 =
    { den, ... }:
    {
      den.hosts.x86_64-linux.h5.class = "nixos";
      den.aspects.services.networking.nginx.nixos = {
        marker.nginx = true;
      };
      den.aspects.appA.includes = with den.aspects; [ services.networking.nginx ];
      den.aspects.appB.includes = with den.aspects; [ services.networking.nginx ];
      den.aspects.h5.includes = with den.aspects; [
        appA
        appB
      ];
    };
  f5den = (mk f5).den;
in
{
  flake.tests.compat-include-identity = {
    # F1: the nested-path leaf resolves under its PROVIDER key (not "<anon>"), content delivered.
    test-f1-single-nested-path = {
      expr = {
        keys = keysAt f1den "host:h1";
        delivered = builtins.length (bucketAt f1den "host:h1" "nixos");
      };
      expected = {
        keys = [
          "h1"
          "core/systemd/boot"
        ];
        delivered = 1;
      };
    };
    # F2: the transitive chain resolves through the intermediate; the corpus role shape delivers.
    test-f2-transitive-role-chain = {
      expr = {
        keys = keysAt f2den "host:h2";
        delivered = builtins.length (bucketAt f2den "host:h2" "nixos");
      };
      expected = {
        keys = [
          "h2"
          "roles/default"
          "svc/openssh"
        ];
        delivered = 1;
      };
    };
    # F2/F3 spine: the host is PRESENT in the content-driven member spine (pre-fix: attrNames = [ ]).
    test-f2-f3-member-spine-present = {
      expr = {
        f2 = builtins.attrNames f2built.nixosConfigurations;
        f3 = builtins.attrNames f3built.nixosConfigurations;
      };
      expected = {
        f2 = [ "h2" ];
        f3 = [ "h3" ];
      };
    };
    # F4: BOTH navigated siblings deliver (pre-fix: 1 — the "<anon>" first-wins drop).
    test-f4-sibling-includes-both-deliver = {
      expr = {
        keys = keysAt f4den "host:h4";
        delivered = builtins.length (bucketAt f4den "host:h4" "nixos");
      };
      expected = {
        keys = [
          "h4"
          "leafa"
          "leafb"
        ];
        delivered = 2;
      };
    };
    # F4': sibling inline LITERALS take the distinct positional fallback and both deliver.
    test-f4-literal-positional-fallback = {
      expr = {
        keys = keysAt f4litden "host:h4";
        delivered = builtins.length (bucketAt f4litden "host:h4" "nixos");
      };
      expected = {
        keys = [
          "h4"
          "h4:include:0"
          "h4:include:1"
        ];
        delivered = 2;
      };
    };
    # F5: N references of ONE aspect = ONE identity = ONE resolution (u5 fixed-by; v1 provider dedup).
    test-f5-multi-reference-dedup = {
      expr = {
        keys = keysAt f5den "host:h5";
        delivered = builtins.length (bucketAt f5den "host:h5" "nixos");
      };
      expected = {
        keys = [
          "h5"
          "appA"
          "services/networking/nginx"
          "appB"
        ];
        delivered = 1;
      };
    };
  };
}
