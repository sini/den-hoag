# den-compat bare-fn kind-include classification (R14 — the agenix rung). v1's discriminator is the
# `den.policies` record coercion (den `nix/lib/aspects/policy-type.nix`, reproduced at the bridge): a
# `den.policies.<name>` REFERENCE is a `{ __isPolicy }` RECORD → a POLICY (children.nix `register-aspect-
# policy`); a LOCAL bare-fn kind-include is a bare fn → a PARAMETRIC ASPECT (normalize.nix `wrapBareFn`,
# result type-dispatched by `mkParametricNext`). This suite pins the three arms of `compile.nix`'s
# `kindInclude` partition:
#   • a bare-fn kind-include → a SYNTHETIC ASPECT (`__kindInclude__<kind>__aspect__<i>`) the edge policy
#     edges at every instance; its ATTRSET result materializes as CONTENT (agenix's `${host.class}` shape,
#     the exact content whose `${host.class}` dynamic key hard-failed the value-less probe when it was
#     mis-labelled a policy → `compilePolicy`'s `concatMap` on aspect content);
#   • a coerced `{ __isPolicy }` reference → a POLICY (`__kindInclude__<kind>__policy__<i>`), UNCHANGED;
#   • a bare-fn that returns a LIST → a NAMED abort (v1 `mkParametricNext`'s include-effect-ONLY branch is
#     unbuilt, out-of-corpus, self-announcing — never a silent drop or a groundKeys-on-a-list crash).
{ denCompat, ... }:
let
  bucketAt =
    den: id: cls:
    (den.structural.eval.get id "class-modules").${cls} or [ ];
  keysAt = den: id: map (n: n.key) (den.structural.eval.get id "resolved-aspects");
  raOkAt = den: id: (builtins.tryEval (builtins.deepSeq (keysAt den id) true)).success;

  # An agenix-shaped bare-fn kind-include: aspect CONTENT keyed by the per-class `${host.class}` dynamic
  # attr (the exact shape of corpus agenix.nix `agenixHostAspect`; the `${host.class}` key is what the
  # value-less probe hard-failed on when this was misclassified as a policy).
  agShaped =
    { host, ... }:
    {
      name = "ag/${host.name}";
      ${host.class}.agMarker = "F-${host.name}";
    };
  agCompiled = denCompat.compile {
    schema.host.includes = [ agShaped ];
    hosts.x86_64-linux.h1.class = "nixos";
  };
  agFleet =
    (denCompat.mkDen [
      {
        config.den = {
          schema.host.includes = [ agShaped ];
          hosts.x86_64-linux.h1.class = "nixos";
        };
      }
    ]).den;

  # A den.policies REFERENCE (the bridge-coerced `{ __isPolicy }` record shape; direct `compile` applies it
  # by hand) in a kind-include → stays a POLICY, unchanged.
  pRec = {
    __isPolicy = true;
    name = "kp";
    fn = _ctx: [
      {
        __policyEffect = "include";
        value = {
          name = "a";
        };
      }
    ];
  };
  pCompiled = denCompat.compile {
    aspects.a = { };
    policies.kp = pRec;
    schema.host.includes = [ pRec ];
    hosts.x86_64-linux.h1.class = "nixos";
  };

  # A bare-fn kind-include returning a LIST of include effects → v1 `mkParametricNext`'s include-only
  # branch (aspect.nix:72-84), now BUILT in `grndDispatch` (§5.1): each `include`-effect entry contributes
  # its `.value`, re-resolved as the parametric aspect's includes, so the inline content materializes at the
  # firing node.
  listFn =
    { host, ... }:
    [
      {
        __policyEffect = "include";
        value = {
          nixos.listMarker = true;
        };
      }
    ];
  listFleet =
    (denCompat.mkDen [
      {
        config.den = {
          schema.host.includes = [ listFn ];
          hosts.x86_64-linux.h1.class = "nixos";
        };
      }
    ]).den;

  # A bare CONTENT SET kind-include — the corpus `den.aspects.<path>` shape: a class/quirk-keyed set with NO
  # id_hash/name (v1 identifies it via __provider, which the raw bridge drops). Two representative shapes: a
  # HOST-class content set (firewall-collector's `{ nixos = …; }`) and a USER content set (syncthing.peer).
  hostContentSet = {
    nixos.csMarker = "H";
  };
  userContentSet = {
    home-manager.csMarker = "U";
  };
  csCompiled = denCompat.compile {
    schema.host.includes = [ hostContentSet ];
    schema.user.includes = [ userContentSet ];
    hosts.x86_64-linux.h1.class = "nixos";
  };
  csFleet =
    (denCompat.mkDen [
      {
        config.den = {
          schema.host.includes = [ hostContentSet ];
          hosts.x86_64-linux.h1.class = "nixos";
        };
      }
    ]).den;
  # An UNRESOLVABLE ref (an int) matches NONE of the arms → the edge policy's resolveAspectRef keeps its named
  # identity abort (the R9 fall-through stays LOUD, never a silent drop).
  intFleet =
    (denCompat.mkDen [
      {
        config.den = {
          schema.host.includes = [ 42 ];
          hosts.x86_64-linux.h1.class = "nixos";
        };
      }
    ]).den;
in
{
  flake.tests.compat-kindinclude = {
    # (1) CLASSIFICATION: a bare-fn kind-include compiles to a SYNTHETIC ASPECT + the kind's edge policy —
    #     NOT a policy record (that mis-route was the agenix crash).
    test-barefn-is-synthetic-aspect = {
      expr = {
        aspect = agCompiled.aspects ? "__kindInclude__host__aspect__0";
        edge = agCompiled.policies ? "__kindInclude__host";
        notPolicy = agCompiled.policies ? "__kindInclude__host__policy__0";
      };
      expected = {
        aspect = true;
        edge = true;
        notPolicy = false;
      };
    };
    # (2) FIRES AT A REAL HOST: the `${host.class}` content materializes in the host's nixos bucket — the
    #     content that hard-failed the value-less probe now resolves cleanly (host.class present at the node).
    test-barefn-content-at-real-host = {
      expr = {
        ok = raOkAt agFleet "host:h1";
        hasNixos = (bucketAt agFleet "host:h1" "nixos") != [ ];
      };
      expected = {
        ok = true;
        hasNixos = true;
      };
    };
    # (3) DISCRIMINATOR: a coerced `{ __isPolicy }` reference in a kind-include stays a POLICY (not an
    #     aspect) — the record shape is exactly what the bridge coercion produces for a `den.policies` ref.
    test-policy-reference-is-policy = {
      expr = {
        policy = pCompiled.policies ? "__kindInclude__host__policy__0";
        notAspect = pCompiled.aspects ? "__kindInclude__host__aspect__0";
      };
      expected = {
        policy = true;
        notAspect = false;
      };
    };
    # (4) RESULT-TYPE DISPATCH: a bare-fn kind-include that returns a LIST of include effects RESOLVES at
    #     the real node (v1 `mkParametricNext`'s include-only branch, now built in `grndDispatch` §5.1) — the
    #     include effect's inline content lands in the host's nixos bucket.
    test-barefn-list-result-resolves = {
      expr = {
        ok = raOkAt listFleet "host:h1";
        hasContent = (bucketAt listFleet "host:h1" "nixos") != [ ];
      };
      expected = {
        ok = true;
        hasContent = true;
      };
    };
    # (5) CONTENT-SET ARM (the identity-boundary rung): a bare `den.aspects.<x>` content set — at BOTH host
    #     and user kind-includes — compiles to a SYNTHETIC ASPECT (not a policy, not the resolveAspectRef
    #     abort), the same arm as a bare fn.
    test-contentset-is-synthetic-aspect = {
      expr = {
        hostAspect = csCompiled.aspects ? "__kindInclude__host__aspect__0";
        userAspect = csCompiled.aspects ? "__kindInclude__user__aspect__0";
        hostEdge = csCompiled.policies ? "__kindInclude__host";
        notPolicy = csCompiled.policies ? "__kindInclude__host__policy__0";
      };
      expected = {
        hostAspect = true;
        userAspect = true;
        hostEdge = true;
        notPolicy = false;
      };
    };
    # (6) FIRES AT A REAL HOST: the content-set's class content materializes in the host's nixos bucket (the
    #     grounded synthetic-aspect content forwardExpand folds like any registered aspect — no crash).
    test-contentset-content-at-real-host = {
      expr = {
        ok = raOkAt csFleet "host:h1";
        hasNixos = (bucketAt csFleet "host:h1" "nixos") != [ ];
      };
      expected = {
        ok = true;
        hasNixos = true;
      };
    };
    # (7) FALL-THROUGH STAYS LOUD: an unresolvable ref (an int) matches no arm → the edge policy's
    #     resolveAspectRef keeps its named identity abort (R9), never a silent drop.
    test-unresolvable-fallthrough-aborts = {
      expr = raOkAt intFleet "host:h1";
      expected = false;
    };
  };
}
