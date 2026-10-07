function pass = test_printf(verbose)

    arguments
        verbose logical = true
    end

    pass = false;

    % values, sep, ends, and the exact text printf writes
    cases = { ...
        {1, 2}, " ", newline, "1 2" + newline; ...
        {1, "a", [1 2]}, " ", newline, "1 a [1, 2]" + newline; ...
        {1, 2}, ", ", newline, "1, 2" + newline; ...
        {1, 2}, "{", "", "1{2"; ...
        {1, 2}, "}", "", "1}2"; ...
        {1, 2}, "{obj}", "", "1{obj}2"; ...
        {1, 2}, "\", "", "1\2"; ...
        {1, 2}, "\n", "", "1\n2"; ... % sep prints as is, like ends
        {1, 2}, "%", "", "1%2"; ...
        {1, 2}, "%d", "", "1%d2"; ...
        {1, 2}, " ", "{}\t", "1 2{}\t"; ...
        {NaN}, " ", newline, "NaN" + newline; ...
        {"only"}, ", ", "", "only"; ...
        {}, ", ", "!", "!" ...
    };

    out_file = tempname();
    cleanup = onCleanup(@() delete(out_file));

    for k = 1:height(cases)
        [vals, sep, ends, expected] = cases{k, :};
        file_id = fopen(out_file, "w");
        printf(vals{:}, sep=sep, ends=ends, file=file_id);
        fclose(file_id);
        actual = string(fileread(out_file));

        if verbose; fprintf("case %d: ""%s"" ... ", k, actual); end

        if actual~=expected
            fprintf("printf case %d wrote ""%s"" rather than ""%s""\n", k, actual, expected);
            return
        end

        if verbose; fprintf("PASSED\n"); end
    end

    pass = true;
end
