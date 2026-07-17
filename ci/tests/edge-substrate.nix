# The typed-edge SUBSTRATE suite (vocabulary spec §2, spec §12 step 2). Witnesses the two-level
# identity scheme (assembly/instance/edge hashes over canonical serialization — the applicative/nominal
# Backpack reading), the fingerprint law (function values never enter a fingerprint; produced values
# never enter the structural fill — only the producing node's instanceId STRING does, so identity
# hashing never forces content), and the fill-graph acyclicity check. See REFERENCE.md.
{
  denHoag,
  ...
}:
let
  inherit (denHoag.internal) identity;

  # A minimal, well-formed structural fill: scalars + a list coordinate + a nested producer-id string.
  s0 = {
    mount = [
      "a"
      "b"
    ];
    render = "nixos";
    args.channel = "producer:xyz";
  };
in
{
  flake.tests.edge-substrate = {
    # ── assemblyId (spec §2.1): content identity of a filled assembly ──
    # order-fixed LIST serialization — the JSON of `[ entityId class ]`, not an attrset (no key-sort
    # ambiguity). Pinned against the literal formula so a serialization drift is caught.
    test-assemblyId-formula = {
      expr = identity.assemblyId {
        entityId = "host:igloo";
        class = "nixos";
      };
      expected = builtins.hashString "sha256" (
        builtins.toJSON [
          "host:igloo"
          "nixos"
        ]
      );
    };
    # same inputs ⇒ same hash across two independent call sites (the identity law).
    test-assemblyId-stable = {
      expr =
        (identity.assemblyId {
          entityId = "e";
          class = "c";
        }) == (identity.assemblyId {
          entityId = "e";
          class = "c";
        });
      expected = true;
    };
    # a change to EITHER coordinate flips the hash.
    test-assemblyId-distinguishes-entity = {
      expr =
        (identity.assemblyId {
          entityId = "e1";
          class = "c";
        }) != (identity.assemblyId {
          entityId = "e2";
          class = "c";
        });
      expected = true;
    };
    test-assemblyId-distinguishes-class = {
      expr =
        (identity.assemblyId {
          entityId = "e";
          class = "c1";
        }) != (identity.assemblyId {
          entityId = "e";
          class = "c2";
        });
      expected = true;
    };

    # ── instanceId (spec §2.1): placement identity = hash of (assemblyId, canonical S) ──
    test-instanceId-stable = {
      expr =
        (identity.instanceId {
          assemblyId = "aaaa";
          s = s0;
        }) == (identity.instanceId {
          assemblyId = "aaaa";
          s = s0;
        });
      expected = true;
    };
    # bit-flip over the `render` scalar field ⇒ a different instanceId.
    test-instanceId-flip-render = {
      expr =
        (identity.instanceId {
          assemblyId = "aaaa";
          s = s0;
        }) != (identity.instanceId {
          assemblyId = "aaaa";
          s = s0 // {
            render = "darwin";
          };
        });
      expected = true;
    };
    # bit-flip over the `mount` list coordinate (order-bearing) ⇒ a different instanceId.
    test-instanceId-flip-mount = {
      expr =
        (identity.instanceId {
          assemblyId = "aaaa";
          s = s0;
        }) != (identity.instanceId {
          assemblyId = "aaaa";
          s = s0 // {
            mount = [
              "b"
              "a"
            ];
          };
        });
      expected = true;
    };
    # bit-flip over the nested producer-id fill ⇒ a different instanceId.
    test-instanceId-flip-producer-id = {
      expr =
        (identity.instanceId {
          assemblyId = "aaaa";
          s = s0;
        }) != (identity.instanceId {
          assemblyId = "aaaa";
          s = s0 // {
            args.channel = "producer:other";
          };
        });
      expected = true;
    };
    # a different assemblyId ⇒ a different instanceId (same fill).
    test-instanceId-flip-assembly = {
      expr =
        (identity.instanceId {
          assemblyId = "aaaa";
          s = s0;
        }) != (identity.instanceId {
          assemblyId = "bbbb";
          s = s0;
        });
      expected = true;
    };

    # ── the identity laziness law (spec §2.1), stated honestly by three witnesses ──
    test-structural-fill-is-forced = {
      # THE STRICTNESS PIN: S content is forced (structural scalars by contract) — a poison
      # thunk placed IN S therefore aborts; the discipline is "never put content in S",
      # not "hashing is lazy over S"
      expr =
        (builtins.tryEval (
          identity.instanceId {
            assemblyId = "aaaa";
            s = {
              mount = [ "x" ];
              render = builtins.throw "forced";
            };
          }
        )).success;
      expected = false;
    };
    test-identity-producer-id-not-value = {
      # produced VALUES never enter S — only the producing node's instanceId string does.
      # The poison lives BESIDE the id on the producer record; selecting `.instanceId`
      # never forces `.produced`, so hashing succeeds.
      expr =
        let
          producer = {
            instanceId = "aaaa-bbbb";
            produced = throw "content forced";
          };
          id1 = identity.instanceId {
            assemblyId = "aaaa";
            s = {
              mount = [ "m" ];
              render = "nixos";
              args.channel = producer.instanceId;
            };
          };
        in
        builtins.seq id1 true;
      expected = true;
    };
    test-identity-function-in-fill-throws-named = {
      # a function value anywhere in S violates the fingerprint law — named throw
      expr =
        (builtins.tryEval (
          identity.instanceId {
            assemblyId = "aaaa";
            s = {
              mount = [ "m" ];
              render = (x: x);
            };
          }
        )).success;
      expected = false;
    };

    # ── edgeId (spec §2.1): the edge's own identity over kind + endpoints + data fingerprint ──
    test-edgeId-formula = {
      expr = identity.edgeId {
        kind = "demand";
        fromInstanceId = "from";
        toInstanceId = "to";
        dataFingerprint = "df";
      };
      expected = builtins.hashString "sha256" (
        builtins.toJSON [
          "demand"
          "from"
          "to"
          "df"
        ]
      );
    };
    # the kind participates in edge identity (two edges identical but for kind ⇒ distinct ids).
    test-edgeId-distinguishes-kind = {
      expr =
        (identity.edgeId {
          kind = "demand";
          fromInstanceId = "f";
          toInstanceId = "t";
          dataFingerprint = "df";
        }) != (identity.edgeId {
          kind = "reach";
          fromInstanceId = "f";
          toInstanceId = "t";
          dataFingerprint = "df";
        });
      expected = true;
    };

    # ── dataFingerprint (spec §2.1): canonical JSON with function values rejected ──
    # `when` (a demand-condition NAME string) is fingerprinted like any scalar.
    test-dataFingerprint-scalar-and-name = {
      expr = identity.dataFingerprint {
        port = 8080;
        when = "prod";
      };
      expected = builtins.hashString "sha256" (
        builtins.toJSON {
          port = 8080;
          when = "prod";
        }
      );
    };
    test-dataFingerprint-stable = {
      expr = (identity.dataFingerprint { a = 1; }) == (identity.dataFingerprint { a = 1; });
      expected = true;
    };
    test-dataFingerprint-function-rejected = {
      # a function value anywhere in the edge data throws NAMED (the fingerprint law)
      expr = (builtins.tryEval (identity.dataFingerprint { transform = (x: x); })).success;
      expected = false;
    };

    # ── checkFillAcyclic (spec §2.1): fill-reference acyclicity ──
    # a DAG returns null (no cycle).
    test-fill-acyclic-dag = {
      expr = identity.checkFillAcyclic {
        a = [ "b" ];
        b = [ "c" ];
        c = [ ];
      };
      expected = null;
    };
    # an empty fill map is trivially acyclic.
    test-fill-acyclic-empty = {
      expr = identity.checkFillAcyclic { };
      expected = null;
    };
    # a two-node cycle aborts NAMED (naming one member).
    test-fill-cycle-throws = {
      expr =
        (builtins.tryEval (
          builtins.deepSeq (identity.checkFillAcyclic {
            a = [ "b" ];
            b = [ "a" ];
          }) null
        )).success;
      expected = false;
    };
    # a self-loop aborts (id ∈ closure(its own references)).
    test-fill-self-loop-throws = {
      expr =
        (builtins.tryEval (
          builtins.deepSeq (identity.checkFillAcyclic {
            a = [ "a" ];
          }) null
        )).success;
      expected = false;
    };
  };
}
