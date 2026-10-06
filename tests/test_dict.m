function pass = test_dict(verbose)

    arguments
        verbose logical = true
    end

    pass = false;

    % set inserts new keys and replaces existing ones in place
    d = dict();
    d.set("a", 1);
    d.set(2, "two");
    d.set("a", 10);
    if ~check("set", {d.len(), d.get("a"), d.get(2), d.keys()}, {2, 10, "two", {"a"; 2}}, verbose)
        return
    end

    % keys that == treats as equal are one key, as in Python
    big = int64(2)^53 + 1;
    d = dict('a', 1, int8(2), "two", true, "one");
    d.set("a", 10);
    d.set(1, "uno");
    d.set(big, "big");
    if ~check( ...
        "equal keys", ...
        {d.len(), d.get('a'), d.get(2), d.get(int8(1)), d.contains(double(big)), cellfun(@class, d.keys(), UniformOutput = false)}, ...
        {4, 10, "two", "uno", false, {'string'; 'double'; 'double'; 'int64'}}, ...
        verbose ...
    )
        return
    end

    % keys, values, and items keep insertion order; a deleted key moves to the end
    d = dict("c", 1, "a", 2, "b", 3);
    d.set("c", 10);
    d.del("a");
    d.set("a", 20);
    t = d.items();
    if ~check( ...
        "insertion order", ...
        {d.keys(), d.values(), t.Key, t.Value}, ...
        {{"c"; "b"; "a"}, {10; 3; 20}, {"c"; "b"; "a"}, {10; 3; 20}}, ...
        verbose ...
    )
        return
    end

    % update and the constructor take a mapping, key-value pairs, or both
    other = dict("b", 20, "c", 30);
    d = dict("a", 1, "b", 2);
    d.update(other);
    d.update(struct("e", 5), "f", 6);
    d.update(g = 7);
    if ~check( ...
        "update", ...
        {d.keys(), d.values(), other.len()}, ...
        {{"a"; "b"; "c"; "e"; "f"; "g"}, {1; 20; 30; 5; 6; 7}, 2}, ...
        verbose ...
    )
        return
    end

    from_dict = dict(other, "d", 4);
    from_dict.set("b", 0);
    from_cell = dict({"x", 1; 2, 'y'});
    from_dictionary = dict(dictionary(["m", "n"], [1, 2]));
    if ~check( ...
        "constructor", ...
        {from_dict.keys(), from_dict.values(), other.get("b"), from_cell.keys(), from_cell.values(), from_dictionary.keys(), from_dictionary.values(), ...
            error_id(@() dict("a", 1, "b")), error_id(@() d.update(5))}, ...
        {{"b"; "c"; "d"}, {0; 30; 4}, 20, {"x"; 2}, {1; 'y'}, {"m"; "n"}, {1; 2}, ...
            "MMGA:dict:invalidArguments", "MMGA:dict:invalidArguments"}, ...
        verbose ...
    )
        return
    end

    % get returns the default, or [] without one, for a missing key
    d = dict("a", 1);
    if ~check( ...
        "get", ...
        {d.get("a", 0), d.get("z", 0), d.get("z", "none"), d.get("z"), d.len(), d.contains("z")}, ...
        {1, 0, "none", [], 1, false}, ...
        verbose ...
    )
        return
    end

    % d(key) reads, assigns, and deletes like Python's d[key]
    d = dict("a", 1, "s", struct("x", 1));
    d("b") = 2;
    d("a") = 10;
    d("s").x = 3;
    d("b") = [];
    if ~check( ...
        "d(key)", ...
        {d("a"), d("s").x, d.keys(), error_id(@() d("z")), error_id(@() d("a", "b")), error_id(@() [d, d])}, ...
        {10, 3, {"a"; "s"}, "MMGA:dict:missingKey", "MMGA:dict:invalidIndex", "MMGA:dict:noArray"}, ...
        verbose ...
    )
        return
    end

    % del, pop, and popitem throw for a missing key like Python's KeyError
    d = dict("a", 1, "b", 2, "c", 3);
    popped = d.pop("a");
    [last_key, last_value] = d.popitem();
    if ~check( ...
        "del, pop, popitem", ...
        {popped, d.pop("z", 0), last_key, last_value, d.keys(), ...
            error_id(@() d.del("z")), error_id(@() d.remove("z")), error_id(@() d.pop("z")), error_id(@() dict().popitem())}, ...
        {1, 0, "c", 3, {"b"}, ...
            "MMGA:dict:missingKey", "MMGA:dict:missingKey", "MMGA:dict:missingKey", "MMGA:dict:empty"}, ...
        verbose ...
    )
        return
    end

    % setdefault returns the value and inserts a missing key, [] by default
    d = dict("a", 1);
    existing = d.setdefault("a", 10);
    added = d.setdefault("b", 2);
    d.setdefault("c");
    if ~check( ...
        "setdefault", ...
        {existing, added, d.keys(), d.get("a"), d.contains("c"), d.get("c", 0)}, ...
        {1, 2, {"a"; "b"; "c"}, 1, true, []}, ...
        verbose ...
    )
        return
    end

    % fromkeys, copy, and | build new dicts
    d = dict.fromkeys(["x", "y"], 0);
    e = d.copy();
    e("x") = 1;
    f = d | dict("y", 2, "z", 3);
    if ~check( ...
        "fromkeys, copy, |", ...
        {d.keys(), d.values(), e("x"), d("x"), f.keys(), f.values()}, ...
        {{"x"; "y"}, {0; 0}, 1, 0, {"x"; "y"; "z"}, {0; 2; 3}}, ...
        verbose ...
    )
        return
    end

    % == compares content in any order and across numeric types, and ~= negates it
    a = dict("x", 1, "n", dict("k", 1));
    b = dict("n", dict("k", 1), "x", int8(1));
    c = dict("x", 2, "n", dict("k", 1));
    loop = dict();
    loop("self") = loop;
    if ~check( ...
        "== and ~=", ...
        {a == b, a ~= b, a == c, a ~= c, a == 1, loop == loop}, ...
        {true, false, false, true, false, true}, ...
        verbose ...
    )
        return
    end

    % silence the & mismatch warning; lastwarn still records it
    state = warning("off", "MMGA:dict:valueMismatch");
    restore_warning = onCleanup(@() warning(state)); %#ok<NASGU>

    % & keeps the shared keys with values from the first dict
    small = dict("a", 1, "b", 2);
    large = dict("a", 10, "b", 2, "c", 30);
    lastwarn("");
    C = small & large;
    [~, warn_id] = lastwarn();
    if ~check( ...
        "small & large", ...
        {C.len(), C.get("a"), C.get("b"), C.contains("c"), string(warn_id)}, ...
        {2, 1, 2, false, "MMGA:dict:valueMismatch"}, ...
        verbose ...
    )
        return
    end

    lastwarn("");
    C = large & small;
    [~, warn_id] = lastwarn();
    if ~check( ...
        "large & small", ...
        {C.keys(), C.get("a"), C.get("b"), string(warn_id)}, ...
        {{"a"; "b"}, 10, 2, "MMGA:dict:valueMismatch"}, ...
        verbose ...
    )
        return
    end

    lastwarn("");
    C = dict("b", 2) & large;
    [~, warn_id] = lastwarn();
    if ~check("matching &", {C.len(), C.get("b"), string(warn_id)}, {1, 2, ""}, verbose)
        return
    end

    C = small & dict("x", 1);
    if ~check("disjoint &", {C.len(), small.len(), large.len()}, {0, 2, 3}, verbose)
        return
    end

    % string, disp, and fstr show the items like Python's str(d)
    d = dict("a", 1, 'b', 'x', "c", "y", 2, true, "e", [], "n", dict("k", 0.5));
    d("self") = d;
    expected = "{""a"": 1, ""b"": 'x', ""c"": ""y"", 2: true, ""e"": [], ""n"": {""k"": 0.5}, ""self"": {...}}";
    if ~check( ...
        "string", ...
        {string(d), string(strip(formattedDisplayText(d))), fstr("{d}")}, ...
        {expected, expected, expected}, ...
        verbose ...
    )
        return
    end

    pass = true;
end

function ok = check(name, actual, expected, verbose)
% Compare one case and report it in the style of test_fstr.

    ok = isequal(actual, expected);

    if verbose
        fprintf("%s ... ", name);
    end

    if ~ok
        fprintf("%s gives %s rather than %s\n", name, show(actual), show(expected));
    elseif verbose
        fprintf("PASSED\n");
    end
end

function id = error_id(f)
% Return the identifier of the error that f throws, or "" if it throws none.

    id = "";
    try
        f();
    catch err
        id = string(err.identifier);
    end
end

function s = show(values)
% Format a cell of values as "{v1, v2, ...}" for failure messages.

    texts = cell(size(values));
    for k = 1:numel(values)
        texts{k} = strip(formattedDisplayText( ...
            values{k}, LineSpacing = "compact", SuppressMarkup = true, UseTrueFalseForLogical = true ...
        ));
    end

    s = "{" + strjoin(string(texts), ", ") + "}";
end
