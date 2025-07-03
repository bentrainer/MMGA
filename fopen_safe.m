function fp = fopen_safe(varargin)
    fp = fopen(varargin{:});
    evalin("caller", sprintf("onCleanup(@() fclose(%d));", fp));
end