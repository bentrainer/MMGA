# ternary

`ternary(cond, a, b)` returns `a` when `cond` is true and `b` otherwise, like
C's `cond ? a : b` or Python's `a if cond else b`. It is an ordinary
function, so MATLAB evaluates both `a` and `b` before the call.

```matlab
n = 3;
label = ternary(n == 1, "item", "items")    % items
ternary([1 0], "all", "not all")            % not all
```

## Calls

```matlab
val = ternary(cond, a, b)
```

- `cond` is converted with `logical` and tested as an `if` statement tests
  it: an array is true only when it is nonempty and all its elements are
  nonzero. Text throws, as `logical` does.

## Python to MATLAB

| Python | MATLAB |
| --- | --- |
| `a if cond else b` | `ternary(cond, a, b)` |

## Limitations

- Python evaluates only the branch it returns, but `ternary` receives both.
  Do not use it to guard an expression that can fail:
  `ternary(isempty(x), 0, x(1))` throws on an empty `x`. Use `if` instead.
