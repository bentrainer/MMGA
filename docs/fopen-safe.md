# fopen_safe

`fopen_safe` opens a file like `fopen` and closes it when the calling
function returns or throws, like Python's `with open(...) as f:`. It stores
an `onCleanup` object in the caller's workspace, so call it directly from the
function that uses the file.

```matlab
function save_lines(filename, lines)
    fid = fopen_safe(filename, "w");
    fprintf(fid, "%s\n", lines);
end   % the file closes here, also after an error
```

## Calls

```matlab
fid = fopen_safe(filename)
fid = fopen_safe(filename, permission, ...)
```

- `fopen_safe` takes the same arguments as `fopen` and returns its file
  identifier, or `-1` when the file cannot be opened. A failed open stores no
  cleanup. `fopen`'s second output, the error message, is not available.
- The cleanup is a caller variable named `persist_fopen_safe_<random>`. The
  file closes when that variable is cleared: when the function returns or
  throws, or on `clear`.
- Closing the file early with `fclose(fid)` is safe. The cleanup closes the
  identifier only while it still refers to the same file, opened with the
  same permission, machine format, and encoding. An identifier that is
  already closed, or that a later `fopen` reused for another file, is left
  alone.

## Python to MATLAB

| Python | MATLAB |
| --- | --- |
| `with open(name, "w") as f:` | `fid = fopen_safe(name, "w");`, closed when the function exits |
| `f.close()` | `fclose(fid)`; optional |

## Limitations

- After an early `fclose`, reopening the same file with the same permission,
  machine format, and encoding can return the same identifier. The cleanup
  cannot tell the two apart and closes the reopened file when the function
  exits.
- Called from a script or the Command Window, the file stays open until the
  base workspace is cleared.
- Called inside a helper function, the cleanup belongs to the helper, so the
  file closes as soon as the helper returns.
