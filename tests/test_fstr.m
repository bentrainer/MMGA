function pass = test_fstr(verbose)

    arguments
        verbose logical = true
    end

    pass = false;

    data = dictionary(...
        "", "", ...
        "{}", "", ...
        "{1+1}", "2", ...
        "{{}}", "{}", ...
        "}}", "}", ...
        "{{", "{", ...
        "{{{", "{{", ...
        "}}}", "}}", ...
        "{ { {", "{ { {", ...
        "{ { { } } }", "{0×0 cell}", ...
        "no variable", "no variable" ...
    );

    keys = data.keys();

    for k = 1:length(keys)
        expr = keys(k);
        dval = data(expr);
        val  = fstr(expr);

        if verbose; fprintf("""%s"" -> ""%s"" ... ", expr, val); end

        if val~=dval
            fprintf("fstr(""%s"") gives ""%s"" rather than ""%s""\n", expr, val, dval);
            return
        end

        if verbose; fprintf("PASSED\n"); end
    end

    pass = true;
end