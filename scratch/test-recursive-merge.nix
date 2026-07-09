let
  splitString = sep: s: builtins.filter builtins.isString (builtins.split sep s);

  nestPath =
    path: value:
    if path == [ ] then value else { ${builtins.head path} = nestPath (builtins.tail path) value; };

  recursiveMerge =
    lh: rh:
    if builtins.isAttrs lh && builtins.isAttrs rh then
      builtins.zipAttrsWith
        (
          name: values:
          if builtins.length values == 1 then
            builtins.head values
          else
            recursiveMerge (builtins.elemAt values 0) (builtins.elemAt values 1)
        )
        [
          lh
          rh
        ]
    else
      rh;
in
recursiveMerge (nestPath (splitString "\\." "disk.xfs-disk-longhorn") { device_id = "/dev/sda"; }) (
  nestPath (splitString "\\." "disk.xfs-disk-longhorn") { mountPoint = "/var/lib/longhorn"; }
)
