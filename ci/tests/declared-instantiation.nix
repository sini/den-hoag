# Declared instantiation surface (D7/D8, ship-gate #50 N1) — a system class DECLARES how it crosses:
# `den.classes.<name>.instantiation = { evaluator ? null; output ? null; }`. The evaluator is the
# `{ modules, specialArgs } -> system` builder (gen-flake `mkSystemTerminal`, #48); the output names the
# flake-parts target the built systems mount at (D8). The crossings map + output faces are now MECHANISM
# reading these declarations — no per-class core constant. This suite pins that the declaration is READ +
# OVERRIDABLE and that the generic `outputs.<target>` map surfaces the face (nixosConfigurations is its
# alias). The concrete droid class (its own `output = "nixOnDroidConfigurations"`) rides this surface in N2.
{ denHoag, ... }:
let
  # A fake `{ modules, specialArgs } -> system` evaluator (like darwin-class.nix's fakeDarwin): it just
  # tags + reflects the terminal's argument, proving the crossing routes THROUGH the declared evaluator
  # without a real nixpkgs (den-hoag CI carries none for this path).
  fakeEval = args: { __fakeCrossed = true; } // args;
  fleetModules = [
    { config.den.schema.server.parent = null; }
    {
      config.den = {
        server.box1 = { };
        contentClass.server = "nixos";
        aspects.srv.nixos.marker = "n";
        # OVERRIDE the nixos default instantiation's evaluator with a declaration (D7 overridable default).
        classes.nixos.instantiation.evaluator = fakeEval;
      };
    }
    (
      { config, ... }:
      {
        config.den.include = [
          {
            at = config.den.server.box1;
            aspects = [ config.den.aspects.srv ];
          }
        ];
      }
    )
  ];
  fleet = denHoag.mkDen fleetModules;
in
{
  flake.tests.declared-instantiation = {
    # the DECLARED evaluator is read + crossed through gen-flake's generic terminal (crossVia) — the nixos
    # host reaches the fake builder, proving instantiation is a declaration, not a core constant.
    test-declared-evaluator-crosses = {
      expr = fleet.nixosConfigurations.box1.__fakeCrossed or false;
      expected = true;
    };
    # the generic terminal handed the evaluator the terminal contract (wrapped modules + a specialArgs
    # carrying the cross-host `nodes` accessor) — same contract crossNixos/crossDarwin get.
    test-declared-terminal-contract = {
      expr = {
        hasModules = fleet.nixosConfigurations.box1 ? modules;
        hasNodes = fleet.nixosConfigurations.box1.specialArgs ? nodes;
      };
      expected = {
        hasModules = true;
        hasNodes = true;
      };
    };
    # the generic declared-target map (D8): `outputs.<target>` surfaces the class's face, and
    # nixosConfigurations is exactly its built-in alias — the mechanism a droid class rides for its own target.
    test-outputs-declared-target = {
      expr = {
        aliased = (fleet.outputs.nixosConfigurations.box1.__fakeCrossed or false);
        sameAsFace = fleet.outputs.nixosConfigurations ? box1 && fleet.nixosConfigurations ? box1;
      };
      expected = {
        aliased = true;
        sameAsFace = true;
      };
    };
  };
}
