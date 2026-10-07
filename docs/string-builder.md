# StringBuilder

`StringBuilder` accumulates text through repeated appends, like Java's
`StringBuilder` or Python's `io.StringIO`. Each append takes amortized
constant time, so building a long text costs time linear in its length. It is
a handle class: assignment shares one builder, and a function that receives
it appends to the caller's text.

```matlab
sb = StringBuilder("squares:");
for k = 1:3
    sb.append(" ", string(k^2));
end
sb = sb + " done";

sb.to_str()                     % squares: 1 4 9 done
sb.len                          % 19
sb.len = 8;                     % truncates the text to squares:
```

In TMI's namespace layout, call it as `mtools.StringBuilder`.

## Calls

```matlab
sb = StringBuilder()
sb = StringBuilder(text1, text2, ...)
sb.append(text1, text2, ...)
sb = sb + text
s = sb.to_str()
s = string(sb)
```

- Each `text` is a character vector or a string array. A string array adds
  its elements in column order, and a character column adds as a row. Empty
  values add nothing, and `append` skips values that are not text, such as
  numbers and cells.
- `sb + text` and `text + sb` both append `text` to the end and return `sb`
  itself. A number appends the character with that code, so `sb + 65` adds
  `A`.
- `to_str()` and `string(sb)` return the text as a string scalar. The result
  is a copy: later appends do not change it.
- `StringBuilder(n)`, with a number `n`, makes an empty builder. The number
  used to set the capacity and is now ignored, as are any arguments after it.
  A non-scalar `n` warns with `MMGA:StringBuilder:nonscalarCapacity`.

## Python to MATLAB

| Python | MATLAB |
| --- | --- |
| `buf = io.StringIO()`, `io.StringIO("ab")` | `sb = StringBuilder()`, `StringBuilder("ab")` |
| `buf.write(s)` | `sb.append(s)` or `sb + s` |
| `buf.getvalue()` | `sb.to_str()` or `string(sb)` |
| `len(buf.getvalue())` | `sb.len` |
| `buf.seek(0); buf.truncate()` | `sb.len = 0` |

## Properties

| Property | Meaning |
| --- | --- |
| `len` | Number of characters. Assigning a smaller value truncates the text, a larger one pads it with spaces, and `0` clears it. |
| `size` | Read-only; equals `len`. |
| `buffer` | Read-only; the text as a character row vector. |

## Warnings and errors

| Identifier | Cause |
| --- | --- |
| `MMGA:StringBuilder:nonscalarCapacity` | Warning: `StringBuilder(n)` got a non-scalar number `n`. |
| `MMGA:StringBuilder:charMatrix` | `append` got a character matrix. |
| `MMGA:StringBuilder:missingString` | `append` got a missing string. |
| `MMGA:StringBuilder:invalidOperand` | `sb + x` got an `x` that is not text or a number. |

An error keeps the text appended before the failing value, so
`sb.append("+", ['ab'; 'cd'])` still adds `+`.

## Limitations

- `text + sb` appends `text`; it does not prepend it.
- `sb + text` changes `sb` itself, unlike `+` on strings, so
  `sb2 = sb + "!"` changes `sb` too. There is no `copy`; start a new builder
  with `StringBuilder(sb.to_str())`.
- Inside one function, a local `s = s + v` loop is faster still. Use a
  builder when several functions or objects add to the same text.
