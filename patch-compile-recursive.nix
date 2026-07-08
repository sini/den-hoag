{
  patch = ''
--- lib/compat/compile.nix	2026-07-08 05:08:00.000000000 +0000
+++ lib/compat/compile.nix	2026-07-08 05:08:00.000000000 +0000
@@ -167,8 +167,14 @@
                 grounded.meta or null
               else
                 meta // { drop = (meta.drop or [ ]) ++ excludes; };
+            translatedIncludes = map (inc:
+              if builtins.isFunction inc then
+                setFunctionArgs (ctx: inc ctx) (builtins.functionArgs inc) // { __isWrappedFn = true; }
+              else if builtins.isAttrs inc && !(inc.__isWrappedFn or false) then
+                translateAspect (inc.name or name) inc
+              else inc
+            ) aspect.includes;
           in
-          (grounded // (if metaWithDrop == null then { } else { meta = metaWithDrop; })) // (if aspect ? includes then { includes = map (inc: if builtins.isFunction inc then setFunctionArgs (ctx: inc ctx) (builtins.functionArgs inc) // { __isWrappedFn = true; } else inc) aspect.includes; } else {})
+          (grounded // (if metaWithDrop == null then { } else { meta = metaWithDrop; })) // (if aspect ? includes then { includes = translatedIncludes; } else {})
       )
     );
'';
}
