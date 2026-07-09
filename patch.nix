{
  patch = ing:
    builtins.trace "v1Decls.default is: ${builtins.toJSON (builtins.attrNames (ing.default or {}))}" true;
}
