# dict

`dict` is a Python-like dictionary. One dict can mix key and value types, and
it keeps insertion order. It is a handle class: assignment shares the same
object, as in Python, and `copy()` makes a new one.

```matlab
d = dict("a", 1, "b", 2);       % or dict(a = 1, b = 2)
d("c") = 3;                     % d["c"] = 3
d("a")                          % 1
d.get("z", 0)                   % 0
d("b") = [];                    % del d["b"]
disp(d)                         % {"a": 1, "c": 3}

for k = d.keys()'
    printf(k{1}, d(k{1}));
end
```

## Python to MATLAB

| Python | MATLAB |
| --- | --- |
| `dict(a=1)`, `dict(other)`, `dict(other, a=1)` | `dict(a = 1)`, `dict(other)`, `dict(other, "a", 1)` |
| `dict.fromkeys(ks, v)` | `dict.fromkeys(ks, v)` |
| `d[k]`, `d[k] = v`, `del d[k]` | `d(k)`, `d(k) = v` or `d.set(k, v)`, `d(k) = []` or `d.del(k)` |
| `d.get(k)`, `d.get(k, default)` | `d.get(k)` gives `[]`, `d.get(k, default)` |
| `k in d`, `len(d)` | `d.contains(k)`, `len(d)` |
| `d.keys()`, `d.values()`, `d.items()` | Same names; cells and a `Key`/`Value` table |
| `d.update(other, a=1)` | `d.update(other, a = 1)` |
| `d.pop(k)`, `d.pop(k, default)` | Same |
| `k, v = d.popitem()` | `[k, v] = d.popitem()` |
| `d.setdefault(k, v)` | Same; `v` defaults to `[]` |
| `d.copy()`, `d.clear()` | Same |
| `d1 \| d2`, `d1 == d2`, `d1 != d2` | `d1 \| d2`, `d1 == d2`, `d1 ~= d2` |
| `str(d)` | `string(d)` or `disp(d)` |

A mapping passed to `dict` or `update` can be another dict, a struct, a MATLAB
`dictionary`, or an N-by-2 cell of key-value pairs.

`d1 & d2` is an MMGA addition: it keeps the keys in both, with values from
`d1`, and warns with `MMGA:dict:valueMismatch` when the values differ.

## Differences from Python

- Keys that MATLAB's `==` treats as equal are one key: `'a'` and `"a"`, and
  `1`, `int8(1)`, and `true`. `keys()` returns them as a string or a double.
- `d(k) = []` deletes `k`. Use `d.set(k, [])` to store an empty value.
- MATLAB has no `None`, so `get`, `setdefault`, and `fromkeys` use `[]`.
- A missing key in `d(k)`, `del`, or `pop` throws `MMGA:dict:missingKey`, and
  `popitem` on an empty dict throws `MMGA:dict:empty`.
- `for k = d` does not loop over keys, and `length(d)` is 1. Loop over
  `d.keys()'` and use `len(d)`.
- Dicts cannot form arrays such as `[d1, d2]`; keep several in a cell.
