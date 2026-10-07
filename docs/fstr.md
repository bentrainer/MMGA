## Example

```matlab
A_n = rand(2, 3);
B_n = true(1, 100);
C_n = 'chars';
S_n = ["a", "bb", "ccc"];
foo = @fstr;

disp(fstr("A_n = \n{A_n:.4f}"));
disp(fstr("B_n = {B_n}"));
disp(fstr("C_n = {C_n}"));
disp(fstr("S_n = {S_n}"));
disp(fstr("foo = {foo}, and {{foo}} will be escaped."));

% an example output:
% A_n =
% [[0.7655, 0.1869, 0.4456],
%  [0.7952, 0.4898, 0.6463]]
% B_n = [true, true, true, true, true, ..., true, true, true, true, true]
% C_n = 'chars'
% S_n = ["a", "bb", "ccc"]
% foo = <function handle of @fstr>, and {foo} will be escaped.
```

## Syntax

- `{expr}` evaluates `expr` in the caller's workspace and formats the result.
- `{expr:fmt}` formats each element with `sprintf("%fmt", element)`, as in `{A:.4f}`.
- `{{` and `}}` print literal braces. An unclosed `{` or a lone `}` prints as is.
- The format spec starts at the first `:` outside brackets and quotes, as in Python, so `{x(2:end)}` and `{d("a:b")}` work. Wrap a top-level range in parentheses: write `{(1:3)}`, not `{1:3}`.
- Literal text passes through `sprintf`, so escapes such as `\n` and `\t` expand. A `%` prints as is, and `%%` also prints one `%`.

### Notice
The matrix is stored in column-major order by default in MATLAB, however it is difficult to display it in that way. fstr() will display the matrix looks like row-major, just to make it more human-readable. Arrays with more dimensions nest along the first dimension, so `reshape(1:8, 2, 2, 2)` prints as two 2-by-2 blocks, and a dimension longer than 20 shows only its first and last 5 entries.

When a field cannot be evaluated or formatted, `fstr` warns and continues. The warnings have identifiers, so you can turn them off one by one, for example `warning("off", "MMGA:fstr:evalFailed")`:

| Identifier | Cause |
|---|---|
| `MMGA:fstr:notText` | An argument is not a string scalar or character vector; its display text is used. |
| `MMGA:fstr:evalFailed` | A field's expression throws; the field prints nothing. |
| `MMGA:fstr:badFormat` | A format spec is not a `sprintf` conversion, as in `{1:3}`; the default format is used. |
| `MMGA:fstr:formatFailed` | Formatting fails, as with `{c:.2f}` on a cell; MATLAB's display text is used. |

`fstr` uses `evalin` to handle `{}` content, it may cause arbitrary code execution (ACE) vulnerability, use it with cautious.

`fstr` is implemented in pure MATLAB, so the performance is not guaranteed, try not to use `fstr` in performance critical path.