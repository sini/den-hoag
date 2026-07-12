# Slice R2 — THE RESOLVE ARM (design note 2026-07-11 §3(i), §5 R2). Un-stubs `den.lib.policy.resolve`
# (v1's functor bag, policy-effects.nix:128-171) and the compat `__targetKind`-dispatching translate arm:
# a v1 `resolve.to <kind> { … }` compiles to a den-hoag resolve-family declaration the STAGED
# ROOT-RESOLUTION pre-pass (slice R1) then routes —
#
#   • a CELL kind (registry-less leaf) → a bare MEMBER tuple (identity-wrapped entity under the firing node);
#   • a ROOT kind → a CONTAINMENT member (`containTo` set) carrying the non-entity bindings + the source
#     coordinate as the target root's ancestor (§3c-UNIFIED, `relate` dissolved);
#   • the corpus-UNEXERCISED arms (bare resolve / shared / withIncludes) → a NAMED abort (never silent);
#   • REQUIREMENT 1: a resolve-family emission at a root by a NON-feed policy aborts LOUD (untagged guard).
#
# The arm witnesses discriminate cell-vs-root from the DISCOVERED schema (`ing.schema`) + the node-class law
# (`ing.registries`), zero kind literals, over a SYNTHETIC topology `zone <- rack <- blade` (blade the leaf;
# rack a parent-kind root) — the genericity pin (no env/host/user names in the arm proofs).
{ denCompat, denHoag, ... }:
let
  inherit (denHoag) declare;
  R = denHoag.policy.resolve;
  sha = s: builtins.hashString "sha256" s;
  aborts = e: !(builtins.tryEval (builtins.deepSeq e e)).success;

  # ── the synthetic schema the arm dispatches against (rack is a PARENT kind → a root; blade is a leaf) ──
  compiledArm = denCompat.compile {
    schema = {
      zone.parent = null;
      rack.parent = "zone";
      blade.parent = "rack";
    };
    policies = {
      # LEAF target → member. Fires at the parent-dim (rack) scope; `ctx.rack` is the firing node's own entry.
      enroll = { rack, ... }: [
        (R.to "blade" {
          blade = {
            name = "b1";
          };
        })
      ];
      # LEAF target with a FULL resolved entity (the corpus's `resolve.to "user" { user = registry.<n>; }`
      # shape: the target carries the registry entity's fields — the content-field rung). The member leaf
      # coord must ride the WHOLE entity (so the cell's kind-includes + batteries read `blade.role`/etc.),
      # with the canonical ingest id_hash OVERLAID and `_module` (a module-system internal) stripped.
      enrollFull = { rack, ... }: [
        (R.to "blade" {
          blade = {
            name = "b2";
            role = "compute";
            classes = [ "os" ];
            settings.mem = 64;
            _module.args = { };
          };
        })
      ];
      # ROOT target → CONTAINMENT member. Carries the NON-entity bindings ({ token }); `containTo = "rack"`
      # names the target coord; the source coord is the firing node's own entry.
      grant = { zone, ... }: [
        (R.to "rack" {
          rack = {
            name = "r1";
          };
          token = "t";
        })
      ];
      # corpus-UNEXERCISED arms — each must abort NAMED at translation.
      bare = { zone, ... }: [ (R { anything = 1; }) ];
      sharedTo = { zone, ... }: [
        (R.shared.to "rack" {
          rack = {
            name = "r1";
          };
        })
      ];
      withInc = { zone, ... }: [
        (R.to.withIncludes "rack" [ "cls" ] {
          rack = {
            name = "r1";
          };
        })
      ];
      unknownKind = { zone, ... }: [
        (R.to "widget" {
          widget = {
            name = "w";
          };
        })
      ];
    };
  };
  memberDecl = builtins.head (
    compiledArm.policies.enroll.fn {
      rack = {
        id_hash = "rack-h";
        name = "r1";
      };
    }
  );
  memberFullDecl = builtins.head (
    compiledArm.policies.enrollFull.fn {
      rack = {
        id_hash = "rack-h";
        name = "r1";
      };
    }
  );
  containDecl = builtins.head (
    compiledArm.policies.grant.fn {
      zone = {
        id_hash = "zone-h";
        name = "z1";
      };
    }
  );
  forceEffect = name: ctx: builtins.deepSeq (compiledArm.policies.${name}.fn ctx) true;

  # ── REQUIREMENT 1 witness: the untagged-loud guard (native mkDen, `zone <- rack <- blade`) ─────────────
  # A zone CONTAINMENT member carries `authToken` into rack:r1 (detected → auto-tagged → the pre-pass routes
  # it); a rack value-conditional CELL-member policy reads it and emits at rack:r1 (a membership-INDEPENDENT
  # root). The main run's structural consumers never read member at a root, and the pre-pass only routes a
  # FEED policy's emission — so an UNTAGGED emitter would silently drop. R2 REQUIREMENT 1 aborts it LOUD.
  base = [
    {
      config.den.schema = {
        zone.parent = null;
        rack.parent = "zone";
        blade.parent = "rack";
      };
    }
    {
      config.den = {
        zone.z1 = { };
        rack.r1 = { };
        blade.b1 = { };
      };
    }
    { config.den.contentClass.blade = "nixos"; } # the collect terminal (den.nixpkgs = null)
    (
      { config, ... }:
      {
        config.den.policies.grant =
          { zone, ... }:
          [
            (declare.member {
              coords = {
                inherit zone;
                rack = config.den.rack.r1;
              };
              bindings.authToken = "tok";
              containTo = "rack";
            })
          ];
      }
    )
  ];
  # `enroll` needs the blade entry; a bare module cannot close over `config`, so wire it as a `{ config }` fn.
  enrollMod =
    tag:
    { config, ... }:
    {
      config.den.policies.enroll = {
        __condition.rack = false;
        __firesAtKinds = [ "rack" ];
      }
      // tag
      // {
        fn =
          ctx:
          if (ctx.authToken or null) != null then
            [
              (declare.member {
                rack = ctx.rack;
                blade = config.den.blade.b1;
              })
            ]
          else
            [ ];
      };
    };
  untaggedDen = (denHoag.mkDen (base ++ [ (enrollMod { }) ])).den; # NO tag → untagged → loud
  taggedDen = (denHoag.mkDen (base ++ [ (enrollMod { __resolveFamily = true; }) ])).den; # tagged → benign
  forceRackDecls =
    den:
    (builtins.tryEval (builtins.deepSeq (den.structural.eval.get "rack:r1" "declarations") true))
    .success;

  # ── R2 TAG-PROPAGATION witnesses (blocker #2): the corpus wires its resolve policies via
  #    `den.schema.<kind>.includes`, so compile keys them SYNTHETICALLY (`__kindInclude__<kind>__policy__<i>`)
  #    and concern-policies' `name ∈ resolveFamilyNames` NEVER matches. compile.nix therefore stamps
  #    `__resolveFamily` on an include policy whose SOURCE REF's v1 name is in the tag set — the ONLY path
  #    for a kind-include resolve policy to reach the staged pre-pass's resolve-family feed. The synthetic
  #    corpus-shape in miniature: a VALUE-CONDITIONAL member emitter wired onto rack via `rack.includes`.
  mkKI =
    policyName:
    denCompat.compile {
      schema = {
        zone.parent = null;
        rack.parent = "zone";
        blade.parent = "rack";
        rack.includes = [
          {
            __isPolicy = true; # the coerced `{ __isPolicy; name; fn }` shape a `den.policies.<name>` ref carries
            name = policyName;
            fn =
              {
                token ? null,
                ...
              }: # value-conditional (empty probe → expansion) — the corpus resolve idiom
              if token != null then
                [
                  (R.to "blade" {
                    blade = {
                      name = "b1";
                    };
                  })
                ]
              else
                [ ];
          }
        ];
      };
      policies = { };
    };
  # The compiled include policy (its synthetic key) + the pre-pass resolve-family feed it should reach.
  kiPolicy = policyName: (mkKI policyName).policies."__kindInclude__rack__policy__0";
  kiFeedIds =
    policyName:
    map (r: r.identity) (denHoag.internal.compilePolicies (mkKI policyName).policies).resolveFamily;

  # The RUNTIME R2 posture for a synthetic-keyed include record (the shape compile emits): the loud guard
  # names it at the main run when untagged, benign when the tag rides. Reuses `base` (the zone→rack relate
  # seeds authToken) — the emitter keyed as compile would key a `rack.includes` policy.
  enrollKIMod =
    tag:
    { config, ... }:
    {
      config.den.policies."__kindInclude__rack__policy__0" = {
        __condition.rack = false;
        __firesAtKinds = [ "rack" ];
      }
      // tag
      // {
        fn =
          ctx:
          if (ctx.authToken or null) != null then
            [
              (declare.member {
                rack = ctx.rack;
                blade = config.den.blade.b1;
              })
            ]
          else
            [ ];
      };
    };
  untaggedKIDen = (denHoag.mkDen (base ++ [ (enrollKIMod { }) ])).den; # synthetic-keyed, untagged → loud
  taggedKIDen = (denHoag.mkDen (base ++ [ (enrollKIMod { __resolveFamily = true; }) ])).den; # tagged → benign
in
{
  flake.tests.compat-resolve = {
    # ── (1) THE FAITHFUL CONSTRUCTOR BAG (policy-effects.nix:128-171) — every arm present + the pinned shape.
    test-constructor-resolve-to = {
      expr = R.to "user" {
        user = {
          id_hash = "u";
          name = "sini";
        };
      };
      expected = {
        __policyEffect = "resolve";
        __shared = false;
        __targetKind = "user";
        value = {
          user = {
            id_hash = "u";
            name = "sini";
          };
        };
        includes = [ ];
      };
    };
    test-constructor-bag-arms = {
      expr = {
        bare = (R { a = 1; }).__shared;
        bareTag = (R { a = 1; }).__policyEffect;
        withIncludes = (R.withIncludes [ "c" ] { a = 1; }).includes;
        sharedFunctor = (R.shared { a = 1; }).__shared;
        sharedTo = (R.shared.to "host" { a = 1; }).__shared;
        sharedToKind = (R.shared.to "host" { a = 1; }).__targetKind;
        sharedWithIncludes = (R.shared.withIncludes [ "c" ] { a = 1; }).__shared;
        toFunctorShared = (R.to "host" { a = 1; }).__shared;
        toWithIncludes = (R.to.withIncludes "host" [ "c" ] { a = 1; }).includes;
        toWithIncludesKind = (R.to.withIncludes "host" [ "c" ] { a = 1; }).__targetKind;
      };
      expected = {
        bare = false;
        bareTag = "resolve";
        withIncludes = [ "c" ];
        sharedFunctor = true;
        sharedTo = true;
        sharedToKind = "host";
        sharedWithIncludes = true;
        toFunctorShared = false;
        toWithIncludes = [ "c" ];
        toWithIncludesKind = "host";
      };
    };

    # ── (2) LEAF target → MEMBER (identity-wrapped leaf entity; parent coord = the firing node's own entry).
    test-leaf-target-to-member = {
      expr = {
        action = memberDecl.__action;
        leafId = memberDecl.coords.blade.id_hash;
        leafConvention = memberDecl.coords.blade.id_hash == sha "blade|name=b1";
        leafName = memberDecl.coords.blade.name;
        parentEntry = memberDecl.coords.rack; # the firing node's own entry, verbatim from ctx
        coordDims = builtins.sort (a: b: a < b) (builtins.attrNames memberDecl.coords);
      };
      expected = {
        action = "member";
        leafId = sha "blade|name=b1";
        leafConvention = true;
        leafName = "b1";
        parentEntry = {
          id_hash = "rack-h";
          name = "r1";
        };
        coordDims = [
          "blade"
          "rack"
        ];
      };
    };

    # ── (2b) THE CONTENT-FIELD RUNG (user-delivery). A member leaf coord carries the FULL resolved entity —
    #    the corpus's `resolve.to "user" { user = registry.<n>; }` makes the target its OWN instantiation
    #    root, so the cell binding IS the registry entity (its `classes`/`role`/`settings`/… reach the cell's
    #    kind-includes + batteries). The canonical ingest id_hash is OVERLAID (matches the factor node / pre-
    #    pass index); `_module` (a module-system internal) is stripped. A minimal `{ id_hash; name }` coord
    #    DROPPED every registry field, so a user-cell aspect-fn destructuring one threw `attribute '<f>' missing`
    #    at resolved-aspects (the corpus's resolved-user-emitter reads `user.system.uid`/`user.identity.sshKeys`,
    #    inputs'/user reads `user.classes`).
    test-leaf-member-carries-full-entity = {
      expr = {
        action = memberFullDecl.__action;
        # the canonical id_hash is overlaid (name-derived, ≠ any authored one)
        leafId = memberFullDecl.coords.blade.id_hash == sha "blade|name=b2";
        leafName = memberFullDecl.coords.blade.name;
        # the FULL entity fields ride the coord (the content-field fix)
        role = memberFullDecl.coords.blade.role or "MISSING";
        classes = memberFullDecl.coords.blade.classes or "MISSING";
        mem = memberFullDecl.coords.blade.settings.mem or "MISSING";
        # `_module` is stripped (never part of an entity's identity/content)
        moduleStripped = !(memberFullDecl.coords.blade ? _module);
        # the parent coord is still the firing node's own entry
        parentEntry = memberFullDecl.coords.rack;
      };
      expected = {
        action = "member";
        leafId = true;
        leafName = "b2";
        role = "compute";
        classes = [ "os" ];
        mem = 64;
        moduleStripped = true;
        parentEntry = {
          id_hash = "rack-h";
          name = "r1";
        };
      };
    };

    # ── (3) ROOT target → CONTAINMENT member (§3c-UNIFIED, `relate` dissolved): coords = { target =
    #    identity-wrapped root; source = the firing node's own entry }; `containTo` names the target coord;
    #    bindings = the emission's NON-entity keyset (the honest B1 keyset — `value` minus the entity key).
    test-root-target-to-containment-member = {
      expr = {
        action = containDecl.__action;
        containTo = containDecl.containTo;
        targetId = containDecl.coords.rack.id_hash;
        targetConvention = containDecl.coords.rack.id_hash == sha "rack|name=r1";
        sourceEntry = containDecl.coords.zone; # the firing node's own entry, verbatim from ctx
        bindings = containDecl.bindings;
      };
      expected = {
        action = "member";
        containTo = "rack";
        targetId = sha "rack|name=r1";
        targetConvention = true;
        sourceEntry = {
          id_hash = "zone-h";
          name = "z1";
        };
        bindings = {
          token = "t";
        };
      };
    };

    # ── (4) corpus-UNEXERCISED arms + an unknown target kind → NAMED abort (never a silent pass-through).
    test-unexercised-arms-abort = {
      expr = {
        bare = aborts (
          forceEffect "bare" {
            zone = {
              id_hash = "z";
              name = "z1";
            };
          }
        );
        shared = aborts (
          forceEffect "sharedTo" {
            zone = {
              id_hash = "z";
              name = "z1";
            };
          }
        );
        withIncludes = aborts (
          forceEffect "withInc" {
            zone = {
              id_hash = "z";
              name = "z1";
            };
          }
        );
        unknownKind = aborts (
          forceEffect "unknownKind" {
            zone = {
              id_hash = "z";
              name = "z1";
            };
          }
        );
      };
      expected = {
        bare = true;
        shared = true;
        withIncludes = true;
        unknownKind = true;
      };
    };

    # ── (5) REQUIREMENT 1: the untagged-loud guard. A value-conditional member-emitting rule WITHOUT the tag
    #    aborts LOUD at the main run's root; the SAME rule WITH the tag is the benign double-fire (no abort).
    test-untagged-resolve-family-aborts = {
      expr = forceRackDecls untaggedDen;
      expected = false;
    };
    test-tagged-resolve-family-benign = {
      expr = forceRackDecls taggedDen;
      expected = true;
    };

    # ── (6) R2 TAG PROPAGATION through KIND-INCLUDE compilation (blocker #2). A resolve policy wired via
    #    `den.schema.<kind>.includes` whose v1 name ∈ the tag set gets `__resolveFamily` stamped on its
    #    synthetic-keyed compiled record → it reaches the pre-pass resolve-family feed. A name NOT in the
    #    set gets NO stamp → absent from the feed (the synthetic key never matches the name-based check).
    test-kindinclude-tag-propagation = {
      expr = {
        tagged = (kiPolicy "env-to-hosts").__resolveFamily or false; # v1 name ∈ resolveFamilyNames → stamped
        untagged = (kiPolicy "local-noise").__resolveFamily or false; # v1 name ∉ set → no stamp
        feedTagged = kiFeedIds "env-to-hosts"; # reaches the pre-pass resolve-family feed (structural sub-rule)
        feedUntagged = kiFeedIds "local-noise"; # absent — synthetic key never matched by the name check
      };
      expected = {
        tagged = true;
        untagged = false;
        feedTagged = [ "__kindInclude__rack__policy__0#structural" ];
        feedUntagged = [ ];
      };
    };

    # ── (7) The R2 loud-guard posture VERIFIED for the synthetic kind-include key: an untagged
    #    synthetic-keyed member emitter at a root aborts LOUD (the guard names the synthetic key); the tag
    #    makes it benign — the pre-pass routes it and the main run's double-fire is silent.
    test-kindinclude-synthetic-key-guard = {
      expr = {
        untagged = forceRackDecls untaggedKIDen; # false — loud abort at the main run
        tagged = forceRackDecls taggedKIDen; # true — tag → benign
      };
      expected = {
        untagged = false;
        tagged = true;
      };
    };
  };
}
