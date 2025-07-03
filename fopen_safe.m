function fp = fopen_safe(varargin)
    fp = fopen(varargin{:});
    evalin("caller", sprintf("persist_onCleanup_return = onCleanup(@() fclose(%d));", fp));
end