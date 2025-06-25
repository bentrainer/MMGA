function fp = safe_fopen(varargin)
    fp = fopen(varargin{:});
    evalin("caller", sprintf("onCleanup(@() fclose(%d));", fp));
end