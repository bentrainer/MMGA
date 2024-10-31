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

    for k = 1:nargin
        obj = varargin{k}; %#ok<NASGU>

        if k==1
            fprintf(opts.file, fstr("{obj}"));
        else
            fprintf(opts.file, fstr(f_content));
        end
    end

    fprintf(opts.file, opts.ends);

end