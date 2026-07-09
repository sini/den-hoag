let
  flake = builtins.getFlake (toString ../../sini/nix-config);
in
# Wait, flake doesn't expose `den` directly if mkDen wasn't called.
# But we can look at the error log from trace!
null
