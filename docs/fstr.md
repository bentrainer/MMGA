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
disp(fstr("foo = {foo}, and \{foo\} will be escaped."));

% an example output:
% A_n =
% [[0.7655, 0.1869, 0.4456],
%  [0.7952, 0.4898, 0.6463]]
% B_n = [true, true, true, true, true, ..., true, true, true, true, true]
% C_n = 'chars'
% S_n = ["a", "bb", "ccc"]
% foo = <function handle of @fstr>, and {foo} will be escaped.
```

### Notice
The matrix is stored in column-major order by default in MATLAB, however it is difficult to display it in that way. fstr() will display the matrix looks like row-major, just to make it more human-readable.

`fstr` is implemented in pure MATLAB, so the performance is not guaranteed, try not to use `fstr` in performance critical path.