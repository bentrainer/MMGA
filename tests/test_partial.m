function pass = test_partial(verbose)

    arguments
        verbose logical = true
    end

    pass = false;
    cases = cell(0, 3);
    echo_args = @(varargin) varargin;

    g = functools.partial(@minus, 10);
    cases(end + 1, :) = {"bind a leading argument", string(g(3)), "7"};

    g = functools.partial(@max, [3 9 2]);
    [m, i] = g();
    cases(end + 1, :) = {"forward every output", string(m) + " " + string(i), "9 2"};

    g = functools.partial(@plus, 1);
    g(2);
    cases(end + 1, :) = {"bare call sets ans", string(ans), "3"}; %#ok<NOANS>

    g = functools.partial(@disp, "hi"); %#ok<NASGU>
    cases(end + 1, :) = {"call a function with no outputs", string(evalc("g()")), "hi" + newline};

    cases(end + 1, :) = {"cellfun", string(mat2str(cellfun(functools.partial(@plus, 1), {1, 2}))), "[2 3]"};

    a = 1;
    g = functools.partial(@plus, a);
    a = 5; %#ok<NASGU>
    cases(end + 1, :) = {"capture values at creation", string(g(0)), "1"};

    % Python returns a new partial object here; returning @abs behaves the same
    lastwarn("");
    g = functools.partial(@abs);
    cases(end + 1, :) = {"partial(@abs) returns @abs", string(isequal(g, @abs)), "true"};
    cases(end + 1, :) = {"partial(@abs) does not warn", string(lastwarn()), ""};

    g = functools.partial(@abs, keywords={});
    cases(end + 1, :) = {"empty keywords cell", string(isequal(g, @abs)), "true"};
    g = functools.partial(@abs, keywords=struct());
    cases(end + 1, :) = {"empty keywords struct", string(isequal(g, @abs)), "true"};

    cases(end + 1, :) = {"positional func2str", string(func2str(functools.partial(@plus, 1))), ...
        "@(varargin)func(args{:},varargin{:})"};
    cases(end + 1, :) = {"keyword func2str", ...
        string(func2str(functools.partial(@contains, keywords={"IgnoreCase", true}))), ...
        "@(varargin)call_with_keywords(func,args,keywords,varargin)"};

    g = functools.partial(@contains, keywords=struct(IgnoreCase=true));
    cases(end + 1, :) = {"keywords from a struct", string(g("ABC", "b")), "true"};
    cases(end + 1, :) = {"call-time keyword overrides", string(g("ABC", "b", IgnoreCase=false)), "false"};
    cases(end + 1, :) = {"override ignores case", string(g("ABC", "b", ignorecase=false)), "false"};

    g = functools.partial(@contains, "ABC", keywords={"IgnoreCase", true});
    cases(end + 1, :) = {"keywords from a cell with an argument", string(g("b")), "true"};

    % bound keywords go after the call's arguments; a trailing pair replaces
    % only the keyword it names
    g = functools.partial(echo_args, 1, keywords={"k", 2, "m", 7});
    cases(end + 1, :) = {"keywords go last", show_args(g(3)), "1 3 k 2 m 7"};
    cases(end + 1, :) = {"override one keyword", show_args(g(3, "k", 4)), "1 3 k 4 m 7"};
    cases(end + 1, :) = {"a lone text argument does not override", show_args(g("k")), "1 k k 2 m 7"};
    cases(end + 1, :) = {"a non-text slot ends the scan", show_args(g("k", 5, 6)), "1 k 5 6 k 2 m 7"};

    % only the exact name keywords, in any case, is the option; an
    % arguments-block option would also take a prefix such as k
    g = functools.partial(echo_args, "k", 1);
    cases(end + 1, :) = {"bound ""k"", 1 stays positional", show_args(g()), "k 1"};
    g = functools.partial(echo_args, "KEYWORDS", {"k", 2});
    cases(end + 1, :) = {"keywords in any case", show_args(g()), "k 2"};

    cases(end + 1, :) = {"no arguments", error_id(@() functools.partial()), "MATLAB:minrhs"};
    cases(end + 1, :) = {"not a function handle", error_id(@() functools.partial("plus", 1)), ...
        "MATLAB:validation:UnableToConvert"};
    cases(end + 1, :) = {"odd keyword count", ...
        error_id(@() functools.partial(@contains, keywords={"IgnoreCase"})), "MMGA:partial:invalidKeywords"};
    cases(end + 1, :) = {"non-text keyword name", ...
        error_id(@() functools.partial(@contains, keywords={1, true})), "MMGA:partial:invalidKeywords"};
    cases(end + 1, :) = {"non-cell keywords", ...
        error_id(@() functools.partial(@contains, keywords=5)), "MMGA:partial:invalidKeywords"};

    for k = 1:size(cases, 1)
        [label, val, dval] = cases{k, :};

        if verbose
            fprintf("%s ... ", label);
        end

        if ~isstring(val) || ~isscalar(val) || val ~= dval
            fprintf("%s gives ""%s"" rather than ""%s""\n", label, val, dval);
            return
        end

        if verbose
            fprintf("PASSED\n");
        end
    end

    pass = true;
end

function text = show_args(args)
    text = join(string(args), " ");
end

function id = error_id(f)
    try
        f();
        id = "no error";
    catch err
        id = string(err.identifier);
    end
end
