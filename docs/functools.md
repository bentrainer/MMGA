# functools

`functools.partial` binds leading arguments, and optionally keywords, to a
function handle, like Python's `functools.partial`. The result is a plain
`function_handle`, so it works anywhere MATLAB expects one, such as `cellfun`,
`integral`, or `ode45`.

```matlab
add_one = functools.partial(@plus, 1);
add_one(2)                                  % 3
cellfun(add_one, {1, 2})                    % [2 3]

[m, i] = feval(functools.partial(@max, [3 9 2]))   % every output is forwarded

has = functools.partial(@contains, keywords=struct(IgnoreCase=true));
has("ABC", "b")                             % true
has("ABC", "b", IgnoreCase=false)           % false: the call overrides
```

In TMI's namespace layout, call it as `mtools.functools.partial`.

## Python to MATLAB

| Python | MATLAB |
| --- | --- |
| `partial(f, a, b)` | `functools.partial(@f, a, b)` |
| `partial(f, k=v)` | `functools.partial(@f, keywords=struct(k=v))` or `keywords={"k", v}` |
| `p(x)` calls `f(*args, x, **keywords)` | `p(x)` calls `f(args{:}, x, keywords{:})` |
| `p(x, k=w)` overrides `k` | `p(x, k=w)` overrides `k`; see the rule below |
| `p.func`, `p.args`, `p.keywords` | Fields of `functions(p).workspace{1}`; `func2str(p)` shows the call |
| `partial(f)` | `functools.partial(@f)` returns `@f` itself |
| `partial(partial(f, a), b)` flattens | Nests; the result is the same |
| `functools.Placeholder` | Not supported |

## Keywords

MATLAB passes `Name=value` to a function as the two arguments `"Name", value`,
so `partial` cannot tell a bound keyword from a positional argument. Pass
keywords through the `keywords` option instead, as a scalar struct or a cell
of name-value pairs. They are added after the call's own arguments, because
MATLAB requires name-value arguments to come last.

A call-time keyword overrides a bound one, as in Python. `partial` reads the
call's arguments from the end in pairs, while each pair starts with text, and
drops a bound keyword that one of those names matches. The match ignores
case, as MATLAB name-value arguments do, but it needs the full name: `p(Ignore=false)`
does not override `IgnoreCase`. A positional text argument in one of those
name slots that equals a bound keyword name also drops that keyword.

Only the exact name `keywords`, in any case, followed by a value at the end of
the bound arguments is taken as the option. To pass the text `"keywords"` as
the second-to-last positional argument, pass it at call time instead.
