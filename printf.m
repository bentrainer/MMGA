function printf(varargin, opts)
    % printf(varargin, sep=" ", end=newline(), file=1) % 1 stands for stdout

    arguments (Repeating)
        varargin
    end
    arguments
        opts.sep  string = " "
        opts.ends string = newline()
        opts.file double = 1 % stdout
    end

    f_content = sprintf("%s{obj}", opts.sep);
    file_id   = opts.file;

    for k = 1:nargin
        obj = varargin{k}; %#ok<NASGU>

        if k==1
            fprintf(file_id, fstr("{obj}"));
        else
            fprintf(file_id, fstr(f_content));
        end
    end

    fprintf(file_id, opts.ends);

end