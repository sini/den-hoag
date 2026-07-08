let
  f = builtins.getFlake (toString ../.);
  denHoag = f.outputs.lib;
  flakeModule = f.outputs.lib.compat.flakeModule;
in
  builtins.trace (builtins.attrNames denHoag.aspects) true
