## Example

```matlab
A_n = rand(2, 3);
B_n = true(1, 100);
C_n = 'chars';
S_n = ["a", "bb", "ccc"];
foo = @fstr;

disp(fstr("A_n = \n{A_n}\n"));
disp(fstr("B_n = {B_n}\n"));
disp(fstr("C_n = {C_n}\n"));
disp(fstr("S_n = {S_n}\n"));
disp(fstr("foo = {foo}, and \{foo\} will be escaped.\n"));

% an example output:
% A_n =
% [[0.7655, 0.1869, 0.4456],
%  [0.7952, 0.4898, 0.6463]]

% B_n = [true, true, true, true, true, ..., true, true, true, true, true]

% C_n = 'chars'

% S_n = ["a", "bb", "ccc"]

% foo = <function handle of @fstr>, and {foo} will be escaped.
```

