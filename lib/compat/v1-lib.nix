{ denHoag, deliverLib }:
let
  # Structural keys used by den v1 configurations (e.g. for skipKey).
  structuralKeysSet = {
    settings = true;
    includes = true;
    neededBy = true;
    meta = true;
    tags = true;
    projects = true;
    name = true;
    description = true;
    key = true;
    id_hash = true;
  };

  aspects = {
    fx = {
      keyClassification = {
        inherit structuralKeysSet;
      };
    };
    resolve =
      className: nodeId:
      # Return the classes.${className} module for all present aspects on this node.
      # denHoag.aspectsAt evaluates the presence guard and settings override.
      let
        nodeAspects = denHoag.aspectsAt nodeId;
        presentNames = builtins.filter (name: nodeAspects.${name}.present) (builtins.attrNames nodeAspects);
      in
      map (name: denHoag.aspects.${name}.${className} or { }) presentNames;
  };

  policy = {
    resolve = {
      to = kind: value: {
        __policyEffect = "resolve";
        value = if builtins.isAttrs value && value ? ${kind} then value.${kind} else value;
      };
    };
    instantiate = spec: {
      __policyEffect = "instantiate";
      value = spec;
    };
    include = aspect: {
      __policyEffect = "include";
      value = aspect;
    };
    exclude = aspect: {
      __policyEffect = "exclude";
      value = aspect;
    };

    # Expose the delivery descriptors from deliver.nix.
    inherit (deliverLib) deliver route provide;

    pipe = {
      from = pipeName: stages: {
        __policyEffect = "pipe";
        value = {
          inherit pipeName stages;
        };
      };
      filter = fn: {
        __pipeStage = "filter";
        inherit fn;
      };
      transform = fn: {
        __pipeStage = "transform";
        inherit fn;
      };
      fold = init: fn: {
        __pipeStage = "fold";
        inherit init fn;
      };
      for = fn: {
        __pipeStage = "for";
        inherit fn;
      };
      to = aspects: {
        __pipeStage = "to";
        inherit aspects;
      };
      as = targetPipeName: {
        __pipeStage = "as";
        inherit targetPipeName;
      };
      append = value: {
        __pipeStage = "append";
        inherit value;
      };
      expose = {
        __pipeStage = "expose";
      };
      broadcast = fn: {
        __pipeStage = "broadcast";
        inherit fn;
      };
      collect = fn: {
        __pipeStage = "collect";
        inherit fn;
      };
      collectAll = fn: {
        __pipeStage = "collectAll";
        inherit fn;
      };
      withProvenance = {
        __pipeStage = "withProvenance";
      };
    };
    mkPolicy = name: fn: fn;
  };

  resolveEntity = kind: args: "${kind}:${args.${kind}.name}";

  capture = {
    captureFleet = _: {
      # Stub for den-diagram / diagram.nix rendering
      scopeEntityKind = { };
      scopeParent = { };
    };
  };

  home-env = {
    makeHomeEnv = args: {
      # Stub for nix-on-droid battery and home-manager integration
      hostConf = { };
      battery = { self, ... }: [ ];
      userDetect = { self, ... }: [ ];
    };
  };

in
{
  inherit
    aspects
    policy
    resolveEntity
    capture
    home-env
    ;
}
