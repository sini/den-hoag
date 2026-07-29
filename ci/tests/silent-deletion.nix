# TWO MEASURED KERNEL DEFECTS OF ONE FAMILY: a failure that REMOVES something and REPORTS NOTHING. In
# both, the observable outcome was a smaller context or a missing policy with no error, so a caller saw a
# well-formed answer that was quietly wrong — and a silent DELETION is the hardest kind to notice, because
# nothing is left to look at.
#
#   (1) AN EMPTY DECLARED CODOMAIN COMPILED THE POLICY AWAY ENTIRELY. `emits = [ ]` classified to no
#       stratum, so the policy contributed no rule and its body fired at no node — taking its `selects`,
#       its `gate` and its fleet-wide `ops` with it, since every feed is a filter over the compiled rules.
#       The ruling (concern-policies.nix header): an empty codomain is an empty HEAD, not an absent rule.
#       The policy compiles, fires, and produces nothing; producing ANYTHING violates its own codomain and
#       aborts named through the contract every other policy already runs. `compileOne` is TOTAL onto one
#       rule per policy, so the deletion is unrepresentable rather than merely refused.
#
#   (2) A THROWING ENRICHMENT VALUE WAS SWALLOWED AND ITS KEY SILENTLY DROPPED. That swallow is gone
#       already — it lived in the kernel's fire-and-classify probe, which the declared-codomain surface
#       retired, and the supportedness law forces every enrichment fact before any consumer can read one.
#       What remained was an UNATTRIBUTED abort: the policy author's own `throw` surfaced at whichever
#       consumer read the key, with no path back to the rule that wrote it. The fact now carries its
#       justification (`errors.enrichValueContext`, attached at the binding).
#
# ★ WHAT THESE FIXTURES CAN AND CANNOT PIN. The asserter has no message-text channel for a THROW (no
# `expectedError`; b1-supportedness.nix:22-27), and Nix cannot recover a caught throw's text at all — so
# the ATTRIBUTION added for (2) is not assertable here and is not claimed to be. `test-throwing-enrich-
# value-is-loud` pins the property a regression would break (the key is not silently absent), NOT the
# frame naming the policy; that frame is verified by reading the trace. Where a contract IS a value
# (`policyMessage`) the text is matched directly.
{
  denHoag,
  ...
}:
let
  d = denHoag.declare;
  compile = denHoag.internal.compilePolicies;
  msg = denHoag.internal.policyMessage;
  indexFeed = denHoag.internal.indexPolicyFeed;
  aborts = x: !(builtins.tryEval (builtins.deepSeq x x)).success;

  # the one-node fleet, driven through the USER surface (`den.policies` via `mkDen`).
  mk =
    policies:
    denHoag.mkDen [
      {
        config.den.schema.node.parent = null;
        config.den.node.h = { };
        config.den.policies = policies;
      }
    ];
  ctxOf = policies: (mk policies).den.structural.eval.get "node:h" "enriched-context";
  declsOf = policies: (mk policies).den.structural.eval.get "node:h" "declarations";

  # ── (1) the empty head ──────────────────────────────────────────────────────────────────────────────
  # A NON-EMPTY body under an EMPTY codomain: the shape the defect deleted outright. It is a MIS-declared
  # policy, and the point is that its mis-declaration is now loud instead of its existence being silent.
  ghost = {
    emits = [ ];
    fn = _: [
      (d.enrich {
        key = "g";
        value = "G";
      })
    ];
  };
  # its honestly-declared twin — the positive control: same body, same fleet, declared codomain.
  ghostDeclared = ghost // {
    emits = [ "enrich" ];
  };
  # The GENUINELY inert policy: an empty head whose body really does produce nothing. This is a live
  # shape, not a synthetic one — a v1 built-in exists only to satisfy a by-name reference and must never
  # emit — and under the deletion reading it was the one case the deletion happened to serve.
  inert = {
    emits = [ ];
    fn = _: [ ];
  };
  # A fleet-wide compose commitment that is NOT site-mark data (`marks = [ ]`), so `policyMessage`'s ops
  # law admits it. Under the deletion reading this rode an empty-codomain policy into oblivion.
  composeOp = {
    __action = "pipeOp";
    marks = [ ];
  };

  # ── (2) the throwing enrichment fact ────────────────────────────────────────────────────────────────
  throwing = {
    emits = [ "enrich" ];
    fn = _: [
      (d.enrich {
        key = "t";
        value = throw "«fixture: the policy author's own diagnostic»";
      })
    ];
  };
  safe = throwing // {
    fn = _: [
      (d.enrich {
        key = "t";
        value = 1;
      })
    ];
  };
in
{
  flake.tests.silent-deletion = {
    # ── (1) an empty codomain is an empty HEAD ────────────────────────────────────────────────────────
    # THE DEFECT'S DIRECT INVERSE: the policy still compiles to a rule. Under the deletion reading this
    # was 0, which is the whole bug — no rule, no acts, no error, nothing to look at.
    test-empty-head-compiles-to-one-rule = {
      expr = builtins.length (compile { p = ghost; }).policy;
      expected = 1;
    };
    # and it is THAT policy's rule, not an anonymous one: the identity survives to the feed.
    test-empty-head-rule-keeps-its-identity = {
      expr = map (r: r.identity) (compile { p = ghost; }).policy;
      expected = [ "p" ];
    };
    # `produces` IS the declared codomain — empty, and honestly so. The rule is in the program with an
    # empty consequence set; it is not a rule pretending to produce something.
    test-empty-head-produces-is-empty = {
      expr = (builtins.head (compile { p = ghost; }).policy).produces;
      expected = [ ];
    };
    # An empty head names no relation, so ABW's level condition imposes no lower bound and the BOTTOM
    # stratum is the canonical assignment (concern-policies.nix `groupOf`). Read off `declare.strata`
    # rather than spelled, so inserting a stratum cannot leave this asserting a stale name.
    test-empty-head-sits-at-the-bottom-stratum = {
      expr = (builtins.head (compile { p = ghost; }).policy).group == builtins.head d.strata;
      expected = true;
    };
    # An empty-head policy is NOT an enrich policy: `enrich` feed membership is `produces == [ "enrich" ]`,
    # a declaration it did not make. Pinned so the totality fix cannot be read as widening a feed.
    test-empty-head-is-not-in-the-enrich-feed = {
      expr = builtins.length (compile { p = ghost; }).enrich;
      expected = 0;
    };

    # THE COLLATERAL DELETIONS, each pinned separately — the deletion took more than the body, and
    # "the policy is inert anyway" was never true of these.
    #   `ops`: the fleet-wide compose commitment is DATA on the record, read off the compiled rules.
    test-empty-head-keeps-its-fleet-ops = {
      expr =
        (compile {
          p = inert // {
            ops = [ composeOp ];
          };
        }).pipeOps;
      expected = [ composeOp ];
    };
    #   `selects`: the 3-valued dispatch selection still places the rule in exactly its own buckets.
    test-empty-head-keeps-its-selects = {
      expr =
        let
          feed =
            (compile {
              p = inert // {
                selects = [ "node" ];
              };
            }).policy;
          at = k: builtins.length (indexFeed [ "node" "other" ] feed k);
        in
        {
          node = at "node";
          other = at "other";
        };
      expected = {
        node = 1;
        other = 0;
      };
    };

    # THE EMPTINESS IS ENFORCED, by the codomain contract every other policy already runs — so the
    # honest reading is not merely documented. A body emitting under an empty head aborts NAMED at the
    # emitting site rather than being tolerated.
    test-empty-head-body-that-emits-aborts = {
      expr = aborts (declsOf {
        p = ghost;
      });
      expected = true;
    };
    # CONTROL, same body and same fleet: declared honestly, it resolves. Without this the abort above
    # could be any unrelated failure of the fixture.
    test-declared-twin-resolves = {
      expr = builtins.isAttrs (declsOf {
        p = ghostDeclared;
      });
      expected = true;
    };
    # CONTROL for the abort's SCOPE: a genuinely inert empty head is not itself an error. The ruling
    # refuses the DELETION, not the declaration — a rule may legitimately have an empty consequence set.
    test-genuinely-inert-empty-head-is-clean = {
      expr = {
        registration = msg { p = inert; };
        resolves = builtins.isAttrs (declsOf {
          p = inert;
        });
      };
      expected = {
        registration = null;
        resolves = true;
      };
    };
    # An OMITTED codomain stays refused, and by its own named message. Doubles as the positive control
    # that `policyMessage` is live in this run — without it, `registration = null` above could be a
    # validator that never fires.
    test-omitted-codomain-still-refused-by-name = {
      expr =
        builtins.match ".*declares no `emits`.*" (msg {
          p = {
            fn = _: [ ];
          };
        }) != null;
      expected = true;
    };

    # ── (2) the enrichment fact carries its justification ─────────────────────────────────────────────
    # THE PROPERTY THE SWALLOW BROKE: a throwing enrichment fact must not leave a smaller context behind.
    # Listing the context's KEYS is the discriminating read — under the swallow this returned a key list
    # with `t` quietly missing, which is a well-formed answer and the reason nothing noticed.
    test-throwing-enrich-value-is-loud = {
      expr = aborts (
        builtins.attrNames (ctxOf {
          p = throwing;
        })
      );
      expected = true;
    };
    # CONTROL: the non-throwing twin, same fleet and same policy shape, publishes its key — so the
    # absence above is caused by the throw and the fixture is not vacuous.
    test-nonthrowing-twin-publishes-its-key = {
      expr = builtins.elem "t" (
        builtins.attrNames (ctxOf {
          p = safe;
        })
      );
      expected = true;
    };
    # THE ATTRIBUTION IS FREE OF THE VALUE. `errors.enrichValueContext` decorates rather than catches, so
    # the fact a consumer reads is the value the policy derived — unwrapped, uncoerced, unchanged. A
    # wrapper that perturbed this would break the supportedness law's own comparison silently.
    test-attribution-does-not-alter-the-fact = {
      expr = (ctxOf { p = safe; }).t;
      expected = 1;
    };
  };
}
