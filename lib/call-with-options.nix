{ lib }:

callee: options:

with builtins;
with lib;

let
  # callCfg = options: cfg: call cfg.package (filterAttrs (k: v: (options.${k}.flag or false) != false) cfg)

  result = join [ calleeString (optionsString options) ];

  join = arr: concatStringsSep " " (remove "" arr);

  calleeString = if (callee.type or "") == "derivation"
    then "${getBin callee}/bin/${getPName callee}"
    else toString callee;

  getPName = drv: drv.pname or (parseDrvName drv.name).name;

  optionsString = options:
    /**/ if typeOf options == "set"
    then join (mapAttrsToList attrToOption options)

    else if typeOf options == "list"
    then join (map optionsString options)

    else if typeOf options == "string"
    then options

    else throw "not implemented: optionsString on ${typeOf options}";

  attrToOption = k: v:
    if elem v [ false null "" [] ]
    then ""
    else if v == true
    then keyToFlag k
    else keyToFlag k + " " + toString v;

  keyToFlag = k: assert k != "";
    if substring 0 1 k == "-"
    then k
    else
      if stringLength k == 1
      then  "-" + k
      else "--" + toDashCase k;

  toDashCase = s: concatStrings (map toLower (foldl'
    (a: x: a ++ optional (isTransition (length a) (secondLast a) (last a) x) "-" ++ [x])
    []
    (stringToCharacters s)));

  # Note that punctuation is neither upper nor lower
  isTransition = n: x: y: z: n > 0 && isLower y && isUpper z || n > 1 && isUpper x && isUpper y && isLower z;

  # FIXME: Unicode support?
  isLower = c: elem c lowerChars;
  isUpper = c: elem c upperChars;

  secondLast = arr: last (init arr);

  tests = map toDashCase
    [ "foo" "Foo" "FOO" "fooBar"  "FooBar"  "fooBAR"  "FOObar"  "fooFNORDbar" ] ==
    [ "foo" "foo" "foo" "foo-bar" "foo-bar" "foo-bar" "foo-bar" "foo-fnord-bar" ]
  ;
in
  assert tests; result
