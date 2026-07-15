# den-compat NESTED ASPECT KEYS + the DISPATCH-EMITTED content-set include (ledger row u7 — the
# blade.shuo rung). v1's discriminator is `isNestedKey` (den nix/lib/aspects/fx/key-classification.nix:
# 69-80 @ pin 11866c16): a non-structural/non-class/non-quirk aspect key whose ATTRSET value carries ≥1
# recognized sub-key (structural | quirk | class-with-class-like-content) is a NESTED ASPECT — never
# emitted at the parent's scope (":67-68 sub-aspects are never auto-walked"); anything else is an
# `unregisteredClassKey` (a typo, an error). The corpus manifestation: `den.aspects.<host>.<user>`
# per-user sub-aspects (blade.nix:51/61, cortex.nix:175/185) consumed by the dispatch-emitted
# `user-aspect-auto-include` (defaults.nix:14-22) — a `policy.include den.aspects.${host.name}.${user.name}`
# whose value crosses the bridge as a BARE content set (no id_hash/name). This suite pins:
#   • the SPLIT (compile.nix translateAspect + mkIsNestedAspectKey): nested keys are STRIPPED from the
#     parent (strip-only, Fork-B — the emission re-reads the bridge config), so the parent resolves at
#     its own scope without the §2.2 abort and the nested content NEVER lands at the parent's scope;
#   • the TYPO POSTURE: a non-nested unknown key (scalar value, or attrset with no recognized sub-key)
#     stays on the parent and still aborts LOUDLY at the §2.2 three-branch dispatch;
#   • the EMITTED-INCLUDE arm (translateEffect + mkEmittedAspect): the emitted bare content set grounds
#     through normalizeList (class keys grounded, includes wrapped). IDENTITY — SUPERSEDED by board #58
#     (the __provider annotation rung): an ANNOTATED emitted value (the corpus path — the bridge's `den`
#     module arg is annotated) takes v1's PROVIDER identity (wrapChild, normalize.nix:95-119 @ pin), so
#     the old cell-identity ceilings (two emitters at one cell; one set from two cells) dissolve. The
#     deterministic SCOPE-COORD identity (`<emitted>@<coord names>`, id_hash over the cell's coord
#     id_hashes — distinct per cell, stable across eval order) remains as the annotation-LESS FALLBACK,
#     which is what the closure-captured fixtures here exercise;
#   • the INTEGRATION: at a real (user,host) cell the auto-included sub-aspect's home-manager content
#     materializes in the cell's home-manager bucket (the relaxed w3 witness; full byte-parity rides the
#     ship-gate content oracle).
{ denCompat, ... }:
let
  bucketAt =
    den: id: cls:
    (den.structural.eval.get id "class-modules").${cls} or [ ];
  keysAt = den: id: map (n: n.key) (den.structural.eval.get id "resolved-aspects");
  raOkAt = den: id: (builtins.tryEval (builtins.deepSeq (keysAt den id) true)).success;
  cmOkAt =
    den: id:
    (builtins.tryEval (builtins.deepSeq (den.structural.eval.get id "class-modules") true)).success;

  # ── (1) the SPLIT at compile level: blade carries real content AND two nested per-user sub-aspects. ──
  bladeDecl = {
    includes = [ ];
    nixos.bladeMarker = true;
    sini = {
      includes = [ { homeManager.siniMarker = true; } ];
    };
    shuo = {
      includes = [ { homeManager.shuoMarker = true; } ];
    };
  };
  splitCompiled = denCompat.compile {
    aspects.blade = bladeDecl;
    hosts.x86_64-linux.blade.class = "nixos";
  };

  # ── (2) the split at a REAL host (R5 self-provide edges `blade` at host:blade): the host resolves
  #    clean, its nixos bucket carries the parent content, and the nested home-manager content does NOT
  #    land at the host scope. ─────────────────────────────────────────────────────────────────────────
  splitFleet =
    (denCompat.mkDen [
      {
        config.den = {
          aspects.blade = bladeDecl;
          hosts.x86_64-linux.blade.class = "nixos";
        };
      }
    ]).den;

  # ── (3) TYPO NEGATIVES — v1's `unregisteredClassKeys` posture: both non-nested unknown shapes stay on
  #    the parent and abort at §2.2 when the aspect resolves (never a silent swallow by the split). ─────
  scalarTypoFleet =
    (denCompat.mkDen [
      {
        config.den = {
          aspects.h1 = {
            nixos.ok = true;
            typo = "x";
          };
          hosts.x86_64-linux.h1.class = "nixos";
        };
      }
    ]).den;
  attrsTypoFleet =
    (denCompat.mkDen [
      {
        config.den = {
          aspects.h1 = {
            nixos.ok = true;
            # an attrset with NO recognized sub-key — NOT a nested aspect (v1 isNestedKey false).
            typo.foo = "bar";
          };
          hosts.x86_64-linux.h1.class = "nixos";
        };
      }
    ]).den;

  # ── (4) EMITTED-INCLUDE unit (translateEffect include arm): an annotation-LESS emitted content set
  #    gets the scope-coord FALLBACK identity (board #58 posture), and the emitted content's class keys
  #    are GROUNDED (homeManager → home-manager, the lookahead-iii fix: the emission rides the same
  #    normalizeList as translateAspect).
  peCompiled = denCompat.compile {
    policies.p =
      { host, user, ... }:
      [
        {
          __policyEffect = "include";
          value = {
            includes = [ ];
            homeManager.x = true;
          };
        }
      ];
    hosts.x86_64-linux.h1.class = "nixos";
  };
  emitAt =
    hostEntry: userEntry:
    builtins.head (
      peCompiled.policies.p.fn {
        host = hostEntry;
        user = userEntry;
      }
    );
  bladeEmit =
    emitAt
      {
        id_hash = "H-blade";
        name = "blade";
      }
      {
        id_hash = "U-shuo";
        name = "shuo";
      };
  cortexEmit =
    emitAt
      {
        id_hash = "H-cortex";
        name = "cortex";
      }
      {
        id_hash = "U-shuo";
        name = "shuo";
      };
  bladeEmitAgain =
    emitAt
      {
        id_hash = "H-blade";
        name = "blade";
      }
      {
        id_hash = "U-shuo";
        name = "shuo";
      };

  # ── (4') NATIVE identity: the SAME emission with a NAVIGATED value — a content set carrying its OWN native
  #    gen-aspects `.key` (what a corpus policy navigates off the typed `den` arg — `den.aspects.blade.shuo`):
  #    `mkEmittedAspect` grounds it through `normalizeList` by that `.key`, so identity is name = last segment,
  #    meta.aspect-chain = its ancestors, id_hash = the aspectEntry convention over the path — CELL-INDEPENDENT
  #    (the same value emitted at two cells is ONE identity, the value's own key, not the cell's). ──────────
  peProvCompiled = denCompat.compile {
    policies.p =
      { host, user, ... }:
      [
        {
          __policyEffect = "include";
          value = {
            includes = [ ];
            homeManager.x = true;
            name = "shuo";
            key = "blade/shuo";
            meta.aspect-chain = [ "blade" ];
          };
        }
      ];
    hosts.x86_64-linux.h1.class = "nixos";
  };
  provEmitAt =
    hostEntry: userEntry:
    builtins.head (
      peProvCompiled.policies.p.fn {
        host = hostEntry;
        user = userEntry;
      }
    );
  provEmitBlade =
    provEmitAt
      {
        id_hash = "H-blade";
        name = "blade";
      }
      {
        id_hash = "U-shuo";
        name = "shuo";
      };
  provEmitCortex =
    provEmitAt
      {
        id_hash = "H-cortex";
        name = "cortex";
      }
      {
        id_hash = "U-shuo";
        name = "shuo";
      };

  # ── (5) INTEGRATION — the corpus shape end-to-end: nested sub-aspects on two hosts (byte-identical
  #    content, mirroring corpus blade.shuo ≡ cortex.shuo, so identity distinctness is proven by SCOPE
  #    not content) + the user-aspect-auto-include policy (defaults.nix:14-22 verbatim shape, closed over
  #    the raw aspect decls exactly as the corpus policy closes over the bridge's `config.den`). ────────
  rawAspects = {
    blade = {
      nixos.bladeMarker = true;
      shuo = {
        includes = [ { homeManager.fromNested = "shuo-hm"; } ];
      };
    };
    cortex = {
      nixos.cortexMarker = true;
      shuo = {
        includes = [ { homeManager.fromNested = "shuo-hm"; } ];
      };
    };
  };
  autoInclude = {
    __isPolicy = true;
    name = "user-aspect-auto-include";
    fn =
      { host, user, ... }:
      if rawAspects ? ${host.name} && rawAspects.${host.name} ? ${user.name} then
        [
          {
            __policyEffect = "include";
            value = rawAspects.${host.name}.${user.name};
          }
        ]
      else
        [ ];
  };
  autoFleet =
    (denCompat.mkDen [
      {
        config.den = {
          aspects = rawAspects;
          # Declaring `schema.user` at all re-parents the kind (ingest buildSchema reads `parent or
          # null`), so the corpus's `den.schema.user.parent = "host"` (topology.nix:7) must ride along
          # for the user to stay a CELL under its host.
          schema.user.parent = "host";
          schema.user.includes = [ autoInclude ];
          hosts.x86_64-linux.blade = {
            class = "nixos";
            users.shuo.classes = [ "homeManager" ];
          };
          hosts.x86_64-linux.cortex = {
            class = "nixos";
            users.shuo.classes = [ "homeManager" ];
          };
          # a host with NO matching nested aspect: the policy emits [] there (the corpus `lib.optional`
          # false branch) — the cell resolves clean with no emitted aspect.
          hosts.x86_64-linux.plain = {
            class = "nixos";
            users.shuo.classes = [ "homeManager" ];
          };
        };
      }
    ]).den;
  emittedKeysAt =
    id: builtins.filter (k: builtins.substring 0 10 k == "<emitted>@") (keysAt autoFleet id);
in
{
  flake.tests.compat-nested-aspects = {
    # (1) SPLIT: the nested per-user keys are stripped from the compiled parent; the real content stays.
    test-nested-keys-split-from-parent = {
      expr = {
        sini = splitCompiled.aspects.blade ? sini;
        shuo = splitCompiled.aspects.blade ? shuo;
        nixos = splitCompiled.aspects.blade ? nixos;
        includes = splitCompiled.aspects.blade ? includes;
      };
      expected = {
        sini = false;
        shuo = false;
        nixos = true;
        includes = true;
      };
    };
    # (2) HOST RESOLVES: the exact corpus abort (`aspect \`blade\` declares key \`shuo\`` at
    #     class-modules on host:blade) is gone; parent content folds, nested content does NOT land here.
    test-host-resolves-nested-content-absent = {
      expr = {
        ok = raOkAt splitFleet "host:blade";
        cmOk = cmOkAt splitFleet "host:blade";
        hasNixos = bucketAt splitFleet "host:blade" "nixos" != [ ];
        hmEmpty = bucketAt splitFleet "host:blade" "home-manager" == [ ];
      };
      expected = {
        ok = true;
        cmOk = true;
        hasNixos = true;
        hmEmpty = true;
      };
    };
    # (3) TYPO POSTURE: both non-nested unknown shapes still abort at §2.2 (the split never swallows).
    test-scalar-typo-still-aborts = {
      expr = cmOkAt scalarTypoFleet "host:h1";
      expected = false;
    };
    test-unrecognized-attrset-typo-still-aborts = {
      expr = cmOkAt attrsTypoFleet "host:h1";
      expected = false;
    };
    # (4) EMITTED IDENTITY — the annotation-less scope-coord FALLBACK (board #58): deterministic name +
    #     id_hash — distinct per cell, stable across invocations, class keys grounded.
    test-emitted-identity-scope-coord = {
      expr = {
        name = bladeEmit.aspect.name;
        distinct = bladeEmit.aspect.id_hash != cortexEmit.aspect.id_hash;
        stable = bladeEmit.aspect.id_hash == bladeEmitAgain.aspect.id_hash;
        grounded = bladeEmit.aspect ? home-manager && !(bladeEmit.aspect ? homeManager);
      };
      expected = {
        name = "<emitted>@blade.shuo";
        distinct = true;
        stable = true;
        grounded = true;
      };
    };
    # (4') EMITTED IDENTITY — NATIVE: a navigated emitted value carrying its OWN `.key` grounds by that key —
    #      name = its last segment, aspect-chain = its ancestors, id_hash = the aspectEntry convention over the
    #      path, CELL-INDEPENDENT (both old u7 ceilings dissolve); class keys still grounded through normalizeList.
    test-emitted-identity-native = {
      expr = {
        name = provEmitBlade.aspect.name;
        chain = provEmitBlade.aspect.meta.aspect-chain;
        idHash = provEmitBlade.aspect.id_hash;
        cellIndependent = provEmitBlade.aspect.id_hash == provEmitCortex.aspect.id_hash;
        grounded = provEmitBlade.aspect ? home-manager && !(provEmitBlade.aspect ? homeManager);
      };
      expected = {
        name = "shuo";
        chain = [ "blade" ];
        idHash = builtins.hashString "sha256" "den-aspect:blade/shuo";
        cellIndependent = true;
        grounded = true;
      };
    };
    # (5) INTEGRATION: both cells resolve; the auto-included sub-aspect's home-manager content lands in
    #     the CELL's bucket (the relaxed w3 witness).
    test-autoinclude-cell-content = {
      expr = {
        bladeOk = raOkAt autoFleet "user:shuo@host:blade";
        cortexOk = raOkAt autoFleet "user:shuo@host:cortex";
        bladeHm = bucketAt autoFleet "user:shuo@host:blade" "home-manager" != [ ];
        cortexHm = bucketAt autoFleet "user:shuo@host:cortex" "home-manager" != [ ];
      };
      expected = {
        bladeOk = true;
        cortexOk = true;
        bladeHm = true;
        cortexHm = true;
      };
    };
    # (6) IDENTITY AT THE CELLS: one emitted aspect per matching cell, keyed by ITS cell (byte-identical
    #     content on both hosts — the fixtures are closure-captured, so the scope-coord FALLBACK applies;
    #     the corpus path takes provider identity, test 4'); the non-matching cell and the host scope
    #     carry none. board #58 flip: the emitted set's static include CHILD now carries the distinct
    #     POSITIONAL identity (`…:content:0:include:0`) instead of the old shared `"<anon>"` — it lands
    #     in the prefix filter, and two such children can no longer collapse onto one dedup key.
    test-autoinclude-identity-per-cell = {
      expr = {
        blade = emittedKeysAt "user:shuo@host:blade";
        cortex = emittedKeysAt "user:shuo@host:cortex";
        plain = emittedKeysAt "user:shuo@host:plain";
        host = emittedKeysAt "host:blade";
      };
      expected = {
        blade = [
          "<emitted>@blade.shuo"
          "<emitted>@blade.shuo:content:0:include:0"
        ];
        cortex = [
          "<emitted>@cortex.shuo"
          "<emitted>@cortex.shuo:content:0:include:0"
        ];
        plain = [ ];
        host = [ ];
      };
    };
  };
}
