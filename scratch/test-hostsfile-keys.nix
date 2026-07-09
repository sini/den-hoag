let
  res = import ./test-compiled.nix;
in
{
  hostsfile = res.compiled.aspects."core.network.hostsfile";
  slash_hostsfile = res.compiled.aspects."core.network/hostsfile" or null;
}
