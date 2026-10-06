function pass = test_string_builder(verbose)

    arguments
        verbose logical = true
    end

    pass = false;
    cases = cell(0, 3);

    sb = StringBuilder();
    cases(end + 1, :) = {"empty builder", sb.to_str(), ""};

    sb.append('abc');
    sb.append("def");
    cases(end + 1, :) = {"append char then string", sb.to_str(), "abcdef"};

    sb.append("x", 'y', ["z1", "z2"]);
    cases(end + 1, :) = {"append several values", sb.to_str(), "abcdefxyz1z2"};

    sb.append(strings(1, 0));
    sb.append("");
    sb.append('');
    sb.append(65, true, {'a'});
    cases(end + 1, :) = {"append empty and non-text values", string(sb), "abcdefxyz1z2"};

    sb.append(['1'; '2']);
    cases(end + 1, :) = {"append column char", sb.to_str(), "abcdefxyz1z212"};

    sb2 = sb + "!";
    cases(end + 1, :) = {"sb + text", sb.to_str(), "abcdefxyz1z212!"};
    cases(end + 1, :) = {"sb + text returns the same handle", string(sb2 == sb), "true"};

    sb = "<" + sb;
    cases(end + 1, :) = {"text + sb appends", sb.to_str(), "abcdefxyz1z212!<"};

    sb = sb + 65;
    cases(end + 1, :) = {"sb + number appends a character code", sb.to_str(), "abcdefxyz1z212!<A"};

    % to_str shares storage with the builder; copy-on-write must keep
    % snapshots and the builder independent
    sb = StringBuilder("ab");
    snapshot = sb.to_str();
    sb.append("cd");
    cases(end + 1, :) = {"snapshot unchanged by append", snapshot, "ab"};
    snapshot = snapshot + "zz";
    cases(end + 1, :) = {"builder unchanged by snapshot edit", sb.to_str(), "abcd"};

    cases(end + 1, :) = {"len", string(sb.len), "4"};
    cases(end + 1, :) = {"size", string(sb.size), "4"};
    cases(end + 1, :) = {"buffer", string(class(sb.buffer)) + " " + sb.buffer, "char abcd"};

    sb.len = 2;
    cases(end + 1, :) = {"len = 2 truncates", sb.to_str(), "ab"};
    sb.len = 0;
    sb.append("new");
    cases(end + 1, :) = {"len = 0 resets", sb.to_str(), "new"};

    % a rejected value raises an error and keeps the earlier text
    sb = StringBuilder("keep");
    cases(end + 1, :) = {"char matrix error", error_id(@() sb.append("+", ['ab'; 'cd'])), ...
        "MMGA:StringBuilder:charMatrix"};
    cases(end + 1, :) = {"text after char matrix error", sb.to_str(), "keep+"};
    cases(end + 1, :) = {"missing string error", error_id(@() sb.append(string(missing))), ...
        "MMGA:StringBuilder:missingString"};
    cases(end + 1, :) = {"text after missing string error", sb.to_str(), "keep+"};
    cases(end + 1, :) = {"sb + logical error", error_id(@() sb + true), ...
        "MMGA:StringBuilder:invalidOperand"};

    sb = StringBuilder();
    for k = 1:300
        sb.append("0123456789");
    end
    cases(end + 1, :) = {"300 appends of 10 chars", sb.to_str(), string(repmat('0123456789', 1, 300))};

    long_text = repmat('abcde', 1, 1000);
    sb.append(long_text);
    cases(end + 1, :) = {"one long append", sb.to_str(), ...
        string([repmat('0123456789', 1, 300), long_text])};

    sb = StringBuilder("ab", 'cd', ["e", "f"]);
    cases(end + 1, :) = {"construct from values", sb.to_str(), "abcdef"};

    sb = StringBuilder("");
    cases(end + 1, :) = {"construct from """"", sb.to_str(), ""};

    sb = StringBuilder('');
    cases(end + 1, :) = {"construct from ''", sb.to_str(), ""};

    sb = StringBuilder(1000);
    sb.append("hi");
    cases(end + 1, :) = {"construct with capacity", sb.to_str(), "hi"};

    % MATLAB appends to an unshared string in place; if that stops
    % applying, appends turn quadratic and this takes about 20 s, not 20 ms
    num_appends = 1e5;
    sb = StringBuilder();
    t0 = tic;
    for k = 1:num_appends
        sb.append("0123456789");
    end
    elapsed = toc(t0);
    cases(end + 1, :) = {sprintf("linear growth (%d appends in %.3f s)", num_appends, elapsed), ...
        string(elapsed < 1), "true"};

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

function id = error_id(f)
    try
        f();
        id = "no error";
    catch err
        id = string(err.identifier);
    end
end
