# den-compat legacy: v1 default class configuration and hierarchy routes
#
# Emulates den-v1's implicit schema and default configurations that populate the `os` and
# `homeManager` buckets out of the box, fulfilling the C8/C9 parity requirement.
{ prelude, ... }:
{
  desugar =
    v1:
    let
      defaults = {
        classes = {
          os = {
            forwardTo = "nixos";
          };
        };
        schema = {
          host = {
            classes = [ "homeManager" ];
          };
          user = {
            classes = [ "homeManager" ];
          };
        };
        default = {
          nixos = {
            system = {
              stateVersion = "25.11";
            };
          };
          homeManager = {
            home = {
              stateVersion = "25.11";
            };
          };
        };
      };
    in
    prelude.recursiveUpdate defaults v1;
}
