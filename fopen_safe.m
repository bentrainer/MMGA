function fp = fopen_safe(varargin)
    fp = fopen(varargin{:});

    [~, tmp_fn] = fileparts(tempname()); % put a variable of random name in the caller for onCleanup()
    evalin("caller", sprintf("persist_fopen_safe_%s = onCleanup(@() fclose(%d));", tmp_fn, fp));
end