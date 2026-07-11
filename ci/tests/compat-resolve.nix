# Slice R2 — THE RESOLVE ARM (design note 2026-07-11 §3(i), §5 R2). Un-stubs `den.lib.policy.resolve`
# (v1's functor bag, policy-effects.nix:128-171) and the compat `__targetKind`-dispatching translate arm:
# a v1 `resolve.to <kind> { … }` compiles to a den-hoag resolve-family declaration the STAGED
# ROOT-RESOLUTION pre-pass (slice R1) then routes —
#
#   • a product LEAF dim (a cell kind) → a MEMBER tuple (identity-wrapped entity under the firing node);
#   • an EXISTING-node kind (a root) → a RELATION carrying the non-entity bindings into the target root;
#   • the corpus-UNEXERCISED arms (bare resolve / shared / withIncludes) → a NAMED abort (never silent);
#   • REQUIREMENT 1: a resolve-family emission at a root by a NON-feed policy aborts LOUD (untagged guard).
#
# The arm witnesses discriminate leaf-vs-root from the DISCOVERED schema (`ing.schema`), zero kind literals,
# over a SYNTHETIC topology `zone <- rack <- blade` (blade the leaf; rack a parent-kind root) — the
# genericity pin (no env/host/user names in the arm proofs).
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
      # ROOT target → relation. Carries the NON-entity bindings ({ token }); the entity key names the target.
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
  relateDecl = builtins.head (
    compiledArm.policies.grant.fn {
      zone = {
        id_hash = "zone-h";
        name = "z1";
      };
    }
  );
  forceEffect = name: ctx: builtins.deepSeq (compiledArm.policies.${name}.fn ctx) true;

  # ── REQUIREMENT 1 witness: the untagged-loud guard (native mkDen, `zone <- rack <- blade`) ─────────────
  # A zone RELATE carries `authToken` into rack:r1 (detected → auto-tagged → the pre-pass routes it); a rack
  # value-conditional MEMBER policy reads it and emits at rack:r1 (a membership-INDEPENDENT root). The main
  # run's structural consumers never read member at a root, and the pre-pass only routes a FEED policy's
  # emission — so an UNTAGGED emitter would silently drop. R2 REQUIREMENT 1 aborts it LOUD.
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
            (declare.relate {
              target = config.den.rack.r1;
              bindings.authToken = "tok";
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

    # ── (3) ROOT target → RELATE (identity-wrapped target id; bindings = the emission's NON-entity keyset).
    test-root-target-to-relate = {
      expr = {
        action = relateDecl.__action;
        targetId = relateDecl.target.id_hash;
        targetConvention = relateDecl.target.id_hash == sha "rack|name=r1";
        bindings = relateDecl.bindings; # the honest keyset: `value` minus the entity key
      };
      expected = {
        action = "relate";
        targetId = sha "rack|name=r1";
        targetConvention = true;
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
  };
}
