# Declared-classes surface (assembly spec §2.2) — a user module may DECLARE an output class
# (`config.den.classes.<name>`), and a declared class joins the REGISTERED-CLASS branch of the
# three-branch aspect-key dispatch (facet | registered class | quirk channel). The spec says "a
# registered class name", NOT "a built-in class name": the registered set is core's built-ins UNION the
# fleet's declared classes, discovered up front (a static `den.classes` name probe, like the quirk-channel
# and kind probes). An aspect keying a declared class then classifies as `class` and its content folds
# into that class's bucket (attribute 9, class-modules); an UNDECLARED key still aborts named (typo).
#
# This is the general core injection point (no legacy vocabulary): den-compat's os/user register through
# THIS public surface (legacy/batteries), rather than the shim reaching into core's fixed classNames.
{ denHoag, ... }:
let
  # A fleet declaring the output class `foo` + an aspect `a` keying `foo`, included at host `h1`.
  schemaMod = {
    config.den.schema = {
      host.parent = null;
      user.parent = "host";
    };
  };
  fooFleet = denHoag.mkDen [
    schemaMod
    {
      config.den = {
        host.h1 = { };
        classes.foo = { }; # DECLARE the output class `foo`
        aspects.a = {
          foo = {
            marker = 1;
          }; # a `foo` class-key content bucket
        };
      };
    }
    (
      { config, ... }:
      {
        config.den.include = [
          {
            at = config.den.host.h1;
            aspects = [ config.den.aspects.a ];
          }
        ];
      }
    )
  ];
  fooDen = fooFleet.den;
  # class-modules at h1: the resolved aspect `a`'s `foo` content folds into the `foo` bucket.
  fooBucket = (fooDen.structural.eval.get "host:h1" "class-modules").foo or [ ];

  # A declared class is a real registered class: it carries a class ENTRY (identity law) in the fleet's
  # class-tag vocabulary, alongside the built-ins.
  fooEntry = fooDen.classes.foo or null;

  # The TYPO guard MUST still fire: an UNDECLARED aspect key aborts named when its content is classified
  # (reading class-modules forces the three-branch dispatch over `a`'s keys).
  typoAborts =
    !(builtins.tryEval (
      let
        f = denHoag.mkDen [
          schemaMod
          {
            config.den = {
              host.h1 = { };
              aspects.a = {
                bogusUndeclaredKey = {
                  x = 1;
                };
              };
            };
          }
          (
            { config, ... }:
            {
              config.den.include = [
                {
                  at = config.den.host.h1;
                  aspects = [ config.den.aspects.a ];
                }
              ];
            }
          )
        ];
      in
      builtins.deepSeq (f.den.structural.eval.get "host:h1" "class-modules") true
    )).success;

  # Built-in classNames stay exactly the three core classes (declared classes extend PER-FLEET, never the
  # core constant) — a fleet declaring no classes has only the built-in registered set.
  baseFleet = denHoag.mkDen [
    schemaMod
    { config.den.host.h1 = { }; }
  ];
  baseClassNames = builtins.attrNames baseFleet.den.classes;
in
{
  flake.tests.declared-classes = {
    # a declared class `foo` classifies as `class` and its aspect content folds into the `foo` bucket.
    test-declared-class-folds = {
      expr = builtins.length fooBucket;
      expected = 1;
    };
    # the declared class carries a real class entry (identity law) in the fleet's class vocabulary.
    test-declared-class-has-entry = {
      expr = fooEntry != null && (fooEntry.name or null) == "foo";
      expected = true;
    };
    # the typo-abort still fires on an UNDECLARED key (declared-classes widens the class branch, it does
    # NOT dissolve the three-branch strictness — R9's no-strictness-escape holds).
    test-undeclared-key-still-aborts = {
      expr = typoAborts;
      expected = true;
    };
    # core built-ins unchanged: a fleet declaring no classes sees exactly the three built-in classes.
    test-builtin-classnames-unchanged = {
      expr = builtins.sort (a: b: a < b) baseClassNames;
      expected = [
        "home-manager"
        "k8s-manifests"
        "nixos"
      ];
    };
  };
}
