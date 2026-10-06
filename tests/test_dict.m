function pass = test_dict(verbose)

    arguments
        verbose logical = true
    end

    pass = false;

    % set inserts new keys and replaces existing ones
    d = dict();
    d.set("a", 1);
    d.set(2, "two");
    d.set("a", 10);
    if ~check("set", {d.len(), d.get("a"), d.get(2)}, {2, 10, "two"}, verbose)
        return
    end

    % update merges another dict and leaves it unchanged
    d = dict("a", 1, "b", 2);
    other = dict("b", 20, "c", 30);
    d.update(other);
    if ~check( ...
        "update", ...
        {d.len(), d.get("a"), d.get("b"), d.get("c"), other.len(), other.get("b")}, ...
        {3, 1, 20, 30, 2, 20}, ...
        verbose ...
    )
        return
    end

    % get returns the default only for a missing key
    d = dict("a", 1);
    if ~check( ...
        "get with default", ...
        {d.get("a", 0), d.get("z", 0), d.get("z", "none"), d.len(), d.contains("z")}, ...
        {1, 0, "none", 1, false}, ...
        verbose ...
    )
        return
    end

    % setdefault inserts a missing key and keeps an existing one
    d = dict("a", 1);
    d.setdefault("b", 2);
    d.setdefault("a", 10);
    if ~check("setdefault", {d.len(), d.get("a"), d.get("b")}, {2, 1, 2}, verbose)
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
        {C.len(), C.get("a"), C.get("b"), C.contains("c"), string(warn_id)}, ...
        {2, 10, 2, false, "MMGA:dict:valueMismatch"}, ...
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

function s = show(values)
% Format a cell of scalars as "{v1, v2, ...}" for failure messages.

    texts = cell(size(values));
    for k = 1:numel(values)
        texts{k} = strip(formattedDisplayText( ...
            values{k}, LineSpacing = "compact", SuppressMarkup = true, UseTrueFalseForLogical = true ...
        ));
    end

    s = "{" + strjoin(string(texts), ", ") + "}";
end
