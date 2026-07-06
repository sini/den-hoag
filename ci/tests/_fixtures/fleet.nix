# Task 1 fixture — three kinds (env, host, user), a handful of instances, a membership
# list — shaped as a `denHoag.mkDen` module list so later tasks extend it in place.
# Kinds use gen-schema's raw string `parent` form; the den entry-valued
# `{ parent; contentClass; fields; }` surface compilation lands with the class wiring
# (Task 2). No aspects yet.
let
  schema = {
    config.den.schema = {
      env = {
        parent = null;
      };
      host = {
        parent = "env";
      };
      user = {
        parent = "host";
      };
    };
  };

  instances = {
    config.den = {
      env.prod = { };
      host.axon = { };
      host.blade = { };
      user.alice = { };
      user.bob = { };
    };
  };

  # Both hosts sit in prod; alice is a member on axon; bob carries no membership tuple.
  membership =
    { config, ... }:
    {
      config.den.membership = [
        {
          coords = {
            env = config.den.env.prod;
            host = config.den.host.axon;
          };
        }
        {
          coords = {
            env = config.den.env.prod;
            host = config.den.host.blade;
          };
        }
        {
          coords = {
            host = config.den.host.axon;
            user = config.den.user.alice;
          };
        }
      ];
    };

  # A `member` tuple emitted at a membership-derived scope (A5 violation). The declaration-
  # stratum classifier (Task 3) sets `membershipDerived`; Task 1 enforces the abort.
  memberAtCell =
    { config, ... }:
    {
      config.den.membership = [
        {
          coords = {
            host = config.den.host.axon;
            user = config.den.user.bob;
          };
          via = {
            policy = "grantStaff";
            scope = "cell:prod/axon/alice";
            membershipDerived = true;
          };
        }
      ];
    };

  # A second alice-on-axon tuple — membership is a relation, so this must not add a cell.
  duplicate =
    { config, ... }:
    {
      config.den.membership = [
        {
          coords = {
            host = config.den.host.axon;
            user = config.den.user.alice;
          };
        }
      ];
    };
in
{
  inherit
    schema
    instances
    membership
    memberAtCell
    duplicate
    ;
  base = [
    schema
    instances
    membership
  ];
  bad = [
    schema
    instances
    membership
    memberAtCell
  ];
  dup = [
    schema
    instances
    membership
    duplicate
  ];
}
