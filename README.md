# MMGA

Make MATLAB Great Again: Python-style conveniences for MATLAB, such as
f-strings, `print`, `dict`, and `functools.partial`, plus helpers for figures
and files.

## Why

MATLAB is fast at matrix work, but everyday code is clumsier than Python.
Printing several values is a good example. `fprintf` needs a format for each
value, and `disp` takes only one argument, so values must go into a cell:

```matlab
disp({1, 2, 3, "four", [5, 6]})
% gives:     {[1]}    {[2]}    {[3]}    {["four"]}    {[5 6]}
```

Python does it with an f-string:

```python
one, two, three, four, five_and_six = 1, 2, 3, "four", [5, 6]
print(f"{one}, {two}, {three}, {four}, {five_and_six}")
# gives: 1, 2, 3, four, [5, 6]
```

MMGA brings the same style to MATLAB:

```matlab
one = 1; two = 2; three = 3; four = "four"; five_and_six = [5, 6];
printf(fstr("{one}, {two}, {three}, {four}, {five_and_six}"))
% gives: 1, 2, 3, four, [5, 6]
```

## Install

MMGA needs MATLAB R2022b or later.

- In R2024b or later, install it as a package with
  `mpminstall("path/to/MMGA")`.
- Or add it to the path with `addpath("path/to/MMGA")`, and run `savepath`
  to keep it there.

## Usage

Each heading links to the full document.

### [fstr](docs/fstr.md)

Format Python-style f-strings, evaluated in the caller's workspace.

```matlab
x = 3;
names = ["a", "bb"];
fstr("x = {x}, pi = {pi:.2f}, names = {names}")   % x = 3, pi = 3.14, names = ["a", "bb"]
```

### [printf](docs/printf.md)

Print values like Python's `print`, with `sep`, `ends`, and `file` options.

```matlab
printf("loss:", 0.25, "at epoch", 3)            % loss: 0.25 at epoch 3
printf(1, 2, 3, sep = ", ")                     % 1, 2, 3
```

### [StringBuilder](docs/string-builder.md)

Accumulate text with fast appends.

```matlab
sb = StringBuilder("squares:");
for k = 1:3
    sb.append(" ", string(k^2));
end
sb.to_str()                                     % squares: 1 4 9
```

### [dict](docs/dict.md)

A Python-like dictionary that keeps insertion order and mixes key and value
types.

```matlab
d = dict("a", 1, "b", 2);
d("c") = 3;
d.get("z", 0)                                   % 0
disp(d)                                         % {"a": 1, "b": 2, "c": 3}
```

### [functools.partial](docs/functools.md)

Bind leading arguments, and optionally keywords, to a function handle.

```matlab
add_one = functools.partial(@plus, 1);
add_one(2)                                      % 3
```

### [ternary](docs/ternary.md)

Return one of two values, like C's `cond ? a : b`. Both values are evaluated.

```matlab
n = 3;
label = ternary(n == 1, "item", "items")        % items
```

### [prettyplot](docs/prettyplot.md)

Apply the lab plot style to a finished figure through selector rules.

```matlab
plot(1:3, [1 4 9]);
xlabel("time (s)");
prettyplot();                                   % the current figure, lab defaults
prettyplot(gcf, "FontSize", 12, figsize = [3.5 2.6]);
```

### [set_fig_resolution](docs/set-fig-resolution.md)

Resize a figure in pixels and center it on the screen.

```matlab
set_fig_resolution(gcf, 1920, 1080);
```

### [get_screen_size](docs/get-screen-size.md)

Return the width and height of the primary screen in pixels.

```matlab
[w, h] = get_screen_size();
```

### [fopen_safe](docs/fopen-safe.md)

Open a file that closes itself when the calling function exits.

```matlab
function save_lines(filename, lines)
    fid = fopen_safe(filename, "w");
    fprintf(fid, "%s\n", lines);
end
```

## License

MIT; see [LICENSE](LICENSE).
