{ lib, denHoag, ... }:
{
  flake.tests.scaffold = {
    test-errors-present = {
      expr = builtins.isAttrs denHoag.errors;
      expected = true;
    };
    test-mkden-callable = {
      expr = builtins.isAttrs (denHoag.mkDen [ ]);
      expected = true;
    };
  };
}
