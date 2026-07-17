# The materialization SUBSTRATE suite (spec §12). Materialization is the read-through side of
# the pipeline: products/renders/receivers are queried, not folded, so the dispatch layer rests on the
# labeled-query calculus (Brzozowski derivatives over a label alphabet — the regular-path-query reading
# of reachability). This suite grows across the materialization arc; the first scenario is the dispatch-substrate
# smoke: den-hoag's OWN gen-graph pin reaches the labeled-query surface (`query`/`labeledFrom`/`regex`).
# See REFERENCE.md.
{
  denHoag,
  ...
}:
let
  # The gen-graph lib, reached through den-hoag's raw-gen-libs seam (the role-named `internal.genGraph` arm).
  inherit (denHoag.internal) genGraph;
  inherit (genGraph) query labeledFrom regex;

  # A tiny labeled relation over a single `hop` edge alphabet: a → b → c. `labeledFrom` adapts one plain
  # accessor per label into the labeled-edge contract the query engine reads.
  rel = labeledFrom {
    hop =
      id:
      {
        a = [ "b" ];
        b = [ "c" ];
        c = [ ];
      }
      .${id} or [ ];
  };

  # ── the typed-product registry seam (lib/products.nix, §4.1) ──
  # `products` = the lib (the framework table + reserved names + the mode-set); `compileProducts` compiles
  # a user registration beside the framework table; `compileConversions` compiles the single-step
  # conversion pairs. `modeOf`/`checkConsumes` are the pure definition-time helpers receivers call.
  inherit (denHoag.internal)
    products
    compileProducts
    compileConversions
    ;
  inherit (products) modeOf checkConsumes;

  # a definition-time throw forced to fire: `mapAttrs`-built registries throw lazily per entry, so force
  # the whole value (the compat-suite `deepSeq e true` precedent) before catching — a caught throw is false.
  throws = e: !(builtins.tryEval (builtins.deepSeq e true)).success;

  # a framework-only compiled table (no user registrations) — the base every scenario reads.
  frameworkProducts = compileProducts { };

  # a mixed table: one user artifact face beside the framework rows, and one non-nestable user product.
  userProducts = compileProducts {
    products = {
      CustomInfo = {
        mode = "artifact";
      };
      SidecarArgs = {
        mode = "content";
        nestable = false;
      };
    };
  };

  # a well-formed single-step conversion registry (one pair).
  oneConversion = compileConversions {
    conversions = {
      "SystemInfo->RawModulesInfo" = {
        via = info: info;
      };
    };
  };
in
{
  flake.tests.materialization = {
    # The dispatch substrate is reachable: run ONE real regular-path query through the pin. `hop` matches
    # exactly one edge label, so from `a` the answer set is `{ b }` (the single-hop derivative is nullable
    # at b, not at c — `hop hop` is not in the language of `hop`).
    test-dispatch-substrate-single-hop = {
      expr = query {
        graph = rel;
        from = "a";
        follow = regex.parse "hop";
        mode = "all";
      };
      expected = [ "b" ];
    };

    # ── §4.1 the framework product table is EXACTLY the spec's rows ──
    # the pre-registered products + their modes, read straight off the compiled framework table.
    test-products-framework-table = {
      expr = builtins.mapAttrs (_: e: e.mode) frameworkProducts;
      expected = {
        ModulesInfo = "content";
        RawModulesInfo = "content";
        SystemInfo = "artifact";
        HmInfo = "artifact";
        DroidInfo = "artifact";
        NixidyEnvInfo = "artifact";
        ShellInfo = "artifact";
        TerranixInfo = "artifact";
        HiveInfo = "artifact";
        EvalHandleInfo = "extend";
        ArgsInfo = "content";
      };
    };
    # ArgsInfo is the non-nestable arg-environment payload — NEVER a consumes (its nestable flag is false).
    test-products-argsinfo-non-nestable = {
      expr = frameworkProducts.ArgsInfo.nestable;
      expected = false;
    };
    # every artifact-face framework row is nestable (a receiver may consume it).
    test-products-artifact-faces-nestable = {
      expr = builtins.all (n: frameworkProducts.${n}.nestable) [
        "SystemInfo"
        "HmInfo"
        "DroidInfo"
        "NixidyEnvInfo"
        "ShellInfo"
        "TerranixInfo"
        "HiveInfo"
      ];
      expected = true;
    };

    # ── §4.1 user registration ──
    # a user product registers beside the framework table with its declared mode.
    test-products-user-registration = {
      expr = userProducts.CustomInfo.mode;
      expected = "artifact";
    };
    # a user product may declare nestable = false (its own non-nestable payload).
    test-products-user-non-nestable = {
      expr = userProducts.SidecarArgs.nestable;
      expected = false;
    };
    # re-registering a framework product name aborts NAMED (the reserved posture, disciplines-registry shape).
    test-products-reserved-throw = {
      expr = throws (compileProducts {
        products = {
          SystemInfo = {
            mode = "artifact";
          };
        };
      });
      expected = true;
    };
    # a user product declaring a mode outside the closed set aborts NAMED.
    test-products-unknown-mode-throw = {
      expr = throws (compileProducts {
        products = {
          BogusInfo = {
            mode = "teleport";
          };
        };
      });
      expected = true;
    };
    # a user product name in the reserved `ArtifactRef ` prefix namespace aborts NAMED — the value-mode
    # wrapper is recognized structurally by that prefix, so a table row wearing it would be silently
    # misclassified (modeOf reads its prefix as value, ignoring its declared mode). The prefix is reserved.
    test-products-artifactref-prefix-throw = {
      expr = throws (compileProducts {
        products = {
          "ArtifactRef Foo" = {
            mode = "artifact";
          };
        };
      });
      expected = true;
    };

    # ── §4.1 modeOf totality + the ArtifactRef wrapper ──
    # modeOf is total over the registered nestable products.
    test-modeof-registered = {
      expr = modeOf frameworkProducts "ModulesInfo";
      expected = "content";
    };
    # `ArtifactRef P` is the value-mode WRAPPER (the prebuilt arm of a row consuming artifact-face P): it is
    # NOT a table row, so modeOf recognizes it structurally and returns value.
    test-modeof-artifactref-value = {
      expr = modeOf frameworkProducts "ArtifactRef SystemInfo";
      expected = "value";
    };

    # ── §4.1 checkConsumes (the definition-time gate receivers call) ──
    # a registered nestable product name passes the consumes gate (returns the name).
    test-checkconsumes-ok = {
      expr = checkConsumes frameworkProducts "SystemInfo";
      expected = "SystemInfo";
    };
    # an unregistered name in a consumes position aborts NAMED.
    test-checkconsumes-unregistered-throw = {
      expr = throws (checkConsumes frameworkProducts "NopeInfo");
      expected = true;
    };
    # a non-nestable product (ArgsInfo) in a consumes position aborts NAMED (never a consumes).
    test-checkconsumes-non-nestable-throw = {
      expr = throws (checkConsumes frameworkProducts "ArgsInfo");
      expected = true;
    };
    # `ArtifactRef` literally in a consumes aborts NAMED (same rule as a non-nestable product) — the wrapper
    # is a production short-circuit, never a receiver's declared consumes.
    test-checkconsumes-artifactref-throw = {
      expr = throws (checkConsumes frameworkProducts "ArtifactRef SystemInfo");
      expected = true;
    };

    # ── §4.1 conversions: single-step, global per-pair uniqueness ──
    # a well-formed conversion compiles to a per-pair entry keyed `<from>-><to>`.
    test-conversions-registered = {
      expr = oneConversion ? "SystemInfo->RawModulesInfo";
      expected = true;
    };
    # the compiled entry carries its `via` function (a registry holds functions freely — the fingerprint
    # law bans functions from edge DATA, never from a registry entry).
    test-conversions-via-present = {
      expr = builtins.isFunction oneConversion."SystemInfo->RawModulesInfo".via;
      expected = true;
    };
    # a malformed pair key — one whose `->` split is not exactly two faces — aborts NAMED at definition
    # time. Per-pair uniqueness is GLOBAL by construction: the registry is one attrset keyed by the pair,
    # so two registrations of the same (from, to) are the SAME key — a genuine cross-module collision is
    # the module system's unique-merge CONFLICT (raw never last-wins on non-equal records), never a silent
    # shadow; the compile gate enforces the KEY WELL-FORMEDNESS that keying relies on.
    test-conversions-malformed-key-throw = {
      expr = throws (compileConversions {
        conversions = {
          "SystemInfo->RawModulesInfo->ShellInfo" = {
            via = x: x;
          };
        };
      });
      expected = true;
    };
    # an empty face — a key with a missing `<from>` or `<to>` side — aborts NAMED.
    test-conversions-empty-face-throw = {
      expr = throws (compileConversions {
        conversions = {
          "->RawModulesInfo" = {
            via = x: x;
          };
        };
      });
      expected = true;
    };
    # a pair declaring no `via` aborts NAMED — the materialization function is required.
    test-conversions-no-via-throw = {
      expr = throws (compileConversions {
        conversions = {
          "SystemInfo->RawModulesInfo" = { };
        };
      });
      expected = true;
    };
    # `ArtifactRef` as a conversion endpoint aborts NAMED (conversions never apply to the prebuilt arm).
    test-conversions-artifactref-endpoint-throw = {
      expr = throws (compileConversions {
        conversions = {
          "ArtifactRef SystemInfo->RawModulesInfo" = {
            via = x: x;
          };
        };
      });
      expected = true;
    };
  };
}
