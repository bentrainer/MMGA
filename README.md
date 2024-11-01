# MMGA
Make MATLAB Great Again

## Why

MATLAB is fast in matrix operation, however writing MATLAB code is not as free as Python, makes it hard to write bigger project while maintaining good readability for debug / update.

For example, there's no built-in logger package in MATLAB, and if anyone want to print out some log information, it has to be achieved by using `fprintf`, `disp` or similar functions. However, `fprintf` has limited formatting operators, rather than Python you could do `"{}".format(any_obj)` or simply use f-string like `f"{any_obj}"`. If you choose `disp`, then you will find it only accepts single input, to output multiple variables together, it will be like: 

```matlab
disp({1, 2, 3, "four", [5,6]})
% gives:     {[1]}    {[2]}    {[3]}    {["four"]}    {[5 6]}
```

Then the output becomes ugly. While in Python:

```python
one, two, three, four, five_and_six = 1, 2, 3, "four", [5,6]
print(f"{one}, {two}, {three}, {four}, {five_and_six}")
# gives: 1, 2, 3, four, [5, 6]
```

To make everything clean and nice, you need to spend lot of effort on formatting. And there are other examples I cannot list here.

To make programming more easy in MATLAB, I want to implement a series of functions / classes / packages, so that a MATLAB program could be written in a way close to Python.

Currently I just have a naïve thinking of this, let's see if it could be done.

## Install

* Recommend to use `mpminstall` if you are using `MATLAB>=R2024b`.
* Or use `addpath(...)` / Copy the file you need to the destination folder.

## Usage
* [fstr](docs/fstr.md)
* printf: `printf(varargin, sep=" ", ends=newline(), file=fileID)` % all key-value pairs are optional
* ternary: `ternary(cond, a, b)` % equals to `cond?a:b` in C