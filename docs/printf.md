# printf

`printf` prints values like Python's `print`. It formats each value as
`fstr("{value}")` does, puts `sep` between them, and ends with `ends`. Unlike
C's `printf`, it takes no format string; build formatted text with `fstr`.

```matlab
printf("loss:", 0.25, "at epoch", 3)            % loss: 0.25 at epoch 3
printf([1 2 3], true)                           % [1, 2, 3] true
printf(1, 2, 3, sep = ", ", ends = "!" + newline)   % 1, 2, 3!
printf(fstr("pi = {pi:.2f}"))                   % pi = 3.14
```

## Calls

```matlab
printf(value1, value2, ..., sep = " ", ends = newline, file = 1)
```

| Option | Default | Meaning |
| --- | --- | --- |
| `sep` | `" "` | Text between values |
| `ends` | `newline` | Text after the last value; `end` is a MATLAB keyword |
| `file` | `1` | File identifier: `1` for standard output, `2` for standard error, or one from `fopen` |

- `sep` and `ends` print as is, so write `sep = newline`, not `sep = "\n"`.
- A scalar string prints without quotes, a character vector with single
  quotes, and an array as a nested list, as in `fstr`.
- `printf()` with no values prints only `ends`.

## Python to MATLAB

| Python | MATLAB |
| --- | --- |
| `print(a, b)` | `printf(a, b)` |
| `print(a, b, sep=", ")` | `printf(a, b, sep = ", ")` |
| `print(a, end="")` | `printf(a, ends = "")` |
| `print(a, file=f)` | `printf(a, file = fid)`, with `fid` from `fopen` |
| `print(f"{a:.2f}")` | `printf(fstr("{a:.2f}"))` |
