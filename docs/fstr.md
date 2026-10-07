# fstr

`fstr` formats Python-style f-strings: `fstr("x = {x}")` does what Python's
`f"x = {x}"` does. It evaluates each `{expr}` in the caller's workspace and
returns a string scalar, so call it from the function or script that owns the
variables. Arrays print row by row, as nested lists.

```matlab
x = 3;
A = [1 2; 3 4];
names = ["a", "bb"];

fstr("x = {x}, x^2 = {x^2}")         % x = 3, x^2 = 9
fstr("pi = {pi:.4f}, n = {x:4d}")    % pi = 3.1416, n =    3
fstr("{names}, {names(1)}, {'c'}")   % ["a", "bb"], a, 'c'
fstr("{{x}} = {x}")                  % {x} = 3

disp(fstr("A =\n{A:.1f}"))
% A =
% [[1.0, 2.0],
%  [3.0, 4.0]]
```

## Calls

```matlab
val = fstr(fmt)
val = fstr(fmt1, fmt2, ...)
```

- Each `fmt` is a string scalar or character vector. `fstr` formats each one
  and joins the results, with no separator, into the string scalar `val`.
- An argument of another type warns with `MMGA:fstr:notText`, and its display
  text takes its place.

## Python to MATLAB

| Python | MATLAB |
| --- | --- |
| `f"{x}"`, `f"{x + 1}"` | `fstr("{x}")`, `fstr("{x + 1}")` |
| `f"{x:.2f}"`, `f"{n:4d}"` | `fstr("{x:.2f}")`, `fstr("{n:4d}")`; an array formats each element |
| `f"{{x}}"` | `fstr("{{x}}")` |
| `f"a = " f"{a}"` | `fstr("a = ", "{a}")` |
| `f"{x:>8}"`, `f"{x:,}"`, `f"{x!r}"`, `f"{x=}"` | Not supported; use `sprintf` flags and widths, such as `{x:-8d}` |

## Fields

- `{expr}` evaluates `expr` in the caller's workspace and formats the result.
- `{expr:fmt}` formats each element with `sprintf("%fmt", element)`, as in
  `{A:.4f}`. `fmt` must be a `sprintf` conversion, such as `.4f`, `5d`, or
  `s`.
- `{{` and `}}` print literal braces. An unclosed `{` or a lone `}` prints as
  is.
- The format spec starts at the first `:` outside brackets and quotes, as in
  Python, so `{x(2:end)}` and `{d("a:b")}` work. Wrap a top-level range in
  parentheses: write `{(1:3)}`, not `{1:3}`.
- Literal text passes through `sprintf`, so escapes such as `\n` and `\t`
  expand. A `%` prints as is, and `%%` also prints one `%`.

## Arrays and values

MATLAB stores arrays column-major, but `fstr` prints them row by row, which
is easier to read:

- A matrix prints one row per line, as in the example above. An array with
  more dimensions nests along the first dimension, so
  `reshape(1:8, 2, 2, 2)` prints as two 2-by-2 blocks.
- A dimension longer than 20 shows its first and last 5 entries around
  `...`, so `{(1:30)}` prints `[1, 2, 3, 4, 5, ..., 26, 27, 28, 29, 30]`.
- Strings inside arrays are double-quoted, and a scalar string is not.
  Character arrays are single-quoted, and logical values print as `true` and
  `false`.
- An empty array prints as `<empty double>`, with its class, and a function
  handle as `<function handle of @sin>`. Structs, cells, and tables print as
  MATLAB's display text.

## Warnings

When a field cannot be evaluated or formatted, `fstr` warns and continues.
Each warning has an identifier, so you can turn them off one at a time, as in
`warning("off", "MMGA:fstr:evalFailed")`:

| Identifier | Cause |
| --- | --- |
| `MMGA:fstr:notText` | An argument is not a string scalar or character vector; its display text is used. |
| `MMGA:fstr:evalFailed` | A field's expression throws; the field prints nothing. |
| `MMGA:fstr:badFormat` | A format spec is not a `sprintf` conversion, as in `{1:3}`; the default format is used. |
| `MMGA:fstr:formatFailed` | Formatting fails, as with `{c:.2f}` on a cell; MATLAB's display text is used. |

## Limitations

- The contents of `{}` run as code through `evalin`. Never pass untrusted
  text, such as user input or file contents, as a format. Pass it as a value
  instead: `fstr("{msg}")` prints `msg` without parsing it.
- `fstr` sees only the workspace of its direct caller. Called through
  `cellfun` or a helper function, it cannot see your variables. A wrapper
  must copy the values into its own workspace first, as `printf` does.
- `fstr` is pure MATLAB and slow. Keep it out of performance-critical loops.
