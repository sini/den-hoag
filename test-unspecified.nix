let
  genMerge = builtins.getFlake "github:sini/gen-merge";
in
genMerge.lib.evalModuleTree {
  modules = [
    { options.test = genMerge.lib.mkOption { type = genMerge.lib.types.unspecified; }; }
    { test.a = 1; }
    { test.b = 2; }
  ];
}
