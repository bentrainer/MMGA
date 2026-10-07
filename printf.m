function printf(varargin, opts)
    % printf(varargin, sep=" ", ends=newline(), file=1) % 1 stands for stdout
    % sep and ends print as is; only the values go through fstr.

    arguments (Repeating)
        varargin
    end
    arguments
        opts.sep  string = " "
        opts.ends string = newline()
        opts.file double = 1 % stdout
    end

    file_id = opts.file;

    for k = 1:nargin
        obj = varargin{k}; %#ok<NASGU>

        if k>1
            fprintf(file_id, "%s", opts.sep);
        end
        fprintf(file_id, "%s", fstr("{obj}"));
    end

    fprintf(file_id, "%s", opts.ends);

end