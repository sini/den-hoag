let
  f = builtins.getFlake (toString ../.);
in
  builtins.trace (builtins.attrNames f.outputs.lib.internal.aspects) true
