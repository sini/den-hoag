# TEMPORARY PROBE — delete before landing.
{
  denCompat,
  denHoag,
  ...
}:
let
  inherit (denHoag) declare;
  base = [
    {
      den.hosts.x86_64-linux.igloo = {
        class = "nixos";
        users.tux = { };
        users.pol = { };
        users.amy = { };
      };
      den.schema.user.parent = "host";
      den.aspects.hostc.nixos.tag = "nixos-host";
      den.schema.host.includes = [ "hostc" ];
      den.aspects.acct =
        { user, ... }:
        {
          nixos.tag = "nixos-${user.name}";
          homeManager.tag = "hm-${user.name}";
        };
      den.schema.user.includes = [ "acct" ];
    }
  ];
  rerouteMod = {
    den.policies.relocate-hm = {
      emits = [ "reroute" ];
      fn =
        { host, ... }:
        [
          (declare.reroute {
            from = denHoag.classes.home-manager;
            to = denHoag.classes.nixos;
          })
        ];
    };
  };
  fleet = denCompat.mkDen (base ++ [ rerouteMod ]);
  out = fleet.den.output;
  igloo = "host:igloo";
  tags =
    m:
    if builtins.isAttrs m then
      (if m ? tag then [ m.tag ] else [ ])
      ++ (if m ? imports then builtins.concatMap tags m.imports else [ ])
    else
      [ ];
in
{
  flake.tests.zz-akj-probe = {
    test-hm-project = {
      expr = builtins.concatMap tags (out.projectClass igloo "home-manager");
      expected = "SHOW";
    };
    test-hm-subtree = {
      expr = builtins.concatMap tags (out.classSubtreeAt igloo "home-manager");
      expected = "SHOW";
    };
    test-nixos-project = {
      expr = builtins.concatMap tags (out.projectClass igloo "nixos");
      expected = "SHOW";
    };
    test-nixos-subtree = {
      expr = builtins.concatMap tags (out.classSubtreeAt igloo "nixos");
      expected = "SHOW";
    };
    test-hm-eq = {
      expr = out.projectClass igloo "home-manager" == out.classSubtreeAt igloo "home-manager";
      expected = "SHOW";
    };
    test-hm-lengths = {
      expr = {
        project = builtins.length (out.projectClass igloo "home-manager");
        subtree = builtins.length (out.classSubtreeAt igloo "home-manager");
      };
      expected = "SHOW";
    };
    test-acts = {
      expr = map (a: a.__action or "?") (
        (fleet.den.structural.eval.get igloo "declarations").actions.resolution or [ ]
      );
      expected = "SHOW";
    };
    test-acts-full = {
      expr = builtins.toJSON (
        map (a: builtins.attrNames a) (
          (fleet.den.structural.eval.get igloo "declarations").actions.resolution or [ ]
        )
      );
      expected = "SHOW";
    };
    test-nodes = {
      expr = builtins.attrNames (fleet.den.structural.eval.nodes or { });
      expected = "SHOW";
    };
    test-class-names = {
      expr = builtins.attrNames (fleet.den.structural.eval.get igloo "class-seeds");
      expected = "SHOW";
    };
    test-class-entry-name = {
      expr = denHoag.classes.home-manager.name or "NO-NAME";
      expected = "SHOW";
    };
    test-fleet-attrs = {
      expr = builtins.attrNames fleet.den;
      expected = "SHOW";
    };
    test-policies = {
      expr = builtins.attrNames (fleet.den.config.den.policies or { });
      expected = "SHOW";
    };
    test-eval-attrs = {
      expr = builtins.attrNames fleet.den.structural.eval;
      expected = "SHOW";
    };
  };
}
