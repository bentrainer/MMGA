function val = fstr(varargin)
    % FSTR  Format Python-style f-strings in the caller's workspace.
    %   val = fstr(fmt1, fmt2, ...) formats each argument and concatenates
    %   the results into one string.
    %
    %   {expr}      evaluates expr in the caller and formats the result
    %   {expr:fmt}  formats each element with sprintf("%fmt", element)
    %   {{ and }}   print literal braces
    %
    %   The format spec starts at the first ":" outside brackets and quotes,
    %   so {x(1:3)} works; wrap a top-level range in parentheses: {(1:3)}.
    %   Literal text passes through sprintf, so escapes such as \n expand,
    %   while % prints as is. An unclosed { or a lone } prints as is.
    %
    %   Arrays print row-major, nested along the first dimension, and a
    %   dimension longer than 20 shows only its first and last 5 entries.
    %
    %   Example: A = rand(2, 3); fstr("A = {A:.2f}")
    %
    %   Never pass untrusted text as a format: the {} contents run as code.

    val = "";
    for k = 1:nargin
        fchar = varargin{k};
        if isstring(fchar) && isscalar(fchar) && ~ismissing(fchar)
            fchar = char(fchar);
        end

        if ~ischar(fchar) || ~(isrow(fchar) || isempty(fchar))
            warning( ...
                "MMGA:fstr:notText", ...
                "fstr: expected a string scalar or character vector but got a %s %s at argument %d", ...
                join(string(size(fchar)), "x"), class(fchar), k ...
            );
            val = val + disp_str(fchar);
            continue
        end

        [texts, exprs, specs] = parse_fields(fchar);
        for m = 1:numel(exprs)
            val = val + literal(texts(m));
            if strip(exprs(m)) == ""
                continue
            end

            % evalin must stay here: inside a helper, "caller" would be fstr
            try
                obj = evalin("caller", exprs(m));
            catch ME
                warning( ...
                    "MMGA:fstr:evalFailed", ...
                    "fstr: failed to eval ""%s"" with error:\n  %s\n%s", ...
                    exprs(m), ME.message, stack_str(ME.stack) ...
                );
                continue
            end

            val = val + format_field(obj, specs(m));
        end
        val = val + literal(texts(end));
    end
end

function [texts, exprs, specs] = parse_fields(s)
    % Split the character row s around its {expr} and {expr:spec} fields.
    % texts holds the literal text before each field and after the last
    % one, with {{ and }} already reduced to single braces.
    texts = strings(1, 0);
    exprs = strings(1, 0);
    specs = strings(1, 0);

    text = "";
    pos = 1;
    n = numel(s);
    for i = find(s == '{' | s == '}')
        if i < pos
            continue  % part of an escape or a field already consumed
        end

        if i < n && s(i + 1) == s(i)
            text = text + s(pos:i);
            pos = i + 2;
        elseif s(i) == '{'
            [stop, colon] = scan_field(s, i + 1);
            if stop > 0
                if colon == 0
                    colon = stop;
                end
                texts(end + 1) = text + s(pos:i - 1); %#ok<AGROW>
                exprs(end + 1) = s(i + 1:colon - 1); %#ok<AGROW>
                specs(end + 1) = s(colon + 1:stop - 1); %#ok<AGROW>
                text = "";
                pos = stop + 1;
            end
        end
    end
    texts(end + 1) = text + s(pos:n);
end

function [stop, colon] = scan_field(s, first)
    % Find the "}" that closes a field whose expression starts at s(first),
    % and the first ":" outside brackets and quotes, which starts the format
    % spec. stop is 0 if the field never closes, and colon is 0 if it has
    % no spec.
    depth = 0;
    colon = 0;
    quote = '';
    k = first;
    while k <= numel(s)
        c = s(k);
        if ~isempty(quote)
            if c == quote && k < numel(s) && s(k + 1) == quote
                k = k + 1;  % a doubled quote is an escaped quote
            elseif c == quote
                quote = '';
            end
        elseif colon == 0 && (c == '"' || (c == '''' && ~is_transpose(s, k, first)))
            quote = c;
        elseif c == '(' || c == '[' || c == '{'
            depth = depth + 1;
        elseif c == ')' || c == ']' || c == '}'
            if depth > 0
                depth = depth - 1;
            elseif c == '}'
                stop = k;
                return
            end
        elseif c == ':' && depth == 0 && colon == 0
            colon = k;
        end
        k = k + 1;
    end
    stop = 0;
end

function tf = is_transpose(s, k, first)
    % A quote right after a name, number, closing bracket, dot, or another
    % quote transposes; anywhere else it starts a character vector.
    tf = k > first && (isletter(s(k - 1)) || any(s(k - 1) == '0123456789_)]}.'''));
end

function val = literal(text)
    % Expand escapes such as \n in literal text. A lone % prints as is, and
    % %% still prints one %.
    val = text;
    if contains(text, ["\", "%"])
        val = sprintf(replace(replace(text, "%%", "%"), "%", "%%"));
    end
end

function val = format_field(obj, spec)
    % Format an evaluated field, falling back to MATLAB's display text.
    fmt = "";
    if spec ~= ""
        if isempty(regexp(spec, "^(\d+\$)?[-+ 0#]*(\d+|\*)?(\.(\d+|\*))?[bt]?[cdeEfgGiosuxX]", "once"))
            warning( ...
                "MMGA:fstr:badFormat", ...
                "fstr: ""%s"" is not a sprintf format; wrap a top-level range in parentheses, as in {(1:3)}", ...
                spec ...
            );
        else
            fmt = "%" + spec;
        end
    end

    try
        val = format_value(obj, fmt, 1);
    catch ME
        warning( ...
            "MMGA:fstr:formatFailed", ...
            "fstr: could not format a %s value, showing its display text:\n  %s", ...
            class(obj), ME.message ...
        );
        val = disp_str(obj);
    end
end

function val = format_value(A, fmt, depth)
    % Format A row-major, nested along its first dimension, such as
    % [[1, 2], [3, 4]]. fmt is a sprintf format, or "" for the default.
    if isempty(A)
        val = sprintf("<empty %s>", class(A));
    elseif isscalar(A)
        val = elem_to_str(A, fmt, false);
    elseif istable(A) || istimetable(A)
        val = disp_str(A);
    elseif ischar(A) && isvector(A)
        val = "'" + string(A(:)') + "'";
    elseif isvector(A)
        idx = shown_indices(numel(A));
        parts = strings(1, numel(idx));
        parts(idx == 0) = "...";
        for k = find(idx)
            parts(k) = elem_to_str(A(idx(k)), fmt, true);
        end
        val = "[" + join(parts, ", ") + "]";
    else
        idx = shown_indices(size(A, 1));
        parts = strings(1, numel(idx));
        parts(idx == 0) = "...";
        for k = find(idx)
            parts(k) = format_value(first_dim_slice(A, idx(k)), fmt, depth + 1);
        end
        val = "[" + join(parts, "," + newline + blanks(depth)) + "]";
    end
end

function idx = shown_indices(n)
    % Indices to show along a dimension of length n. A longer dimension
    % shows EDGE_SHOWN entries at each end around a 0, which marks "...".
    MAX_SHOWN = 20;
    EDGE_SHOWN = 5;
    if n <= MAX_SHOWN
        idx = 1:n;
    else
        idx = [1:EDGE_SHOWN, 0, n - EDGE_SHOWN + 1:n];
    end
end

function sub = first_dim_slice(A, k)
    % Return A(k, :, ...) without its leading singleton dimension, so a
    % 2-by-3-by-4 array gives 3-by-4 slices.
    sz = size(A);
    if numel(sz) == 2
        sub = A(k, :);
    else
        sub = reshape(A(k, :), sz(2:end));
    end
end

function val = elem_to_str(v, fmt, quote)
    % Format one element. fmt is a sprintf format, or "" for the default;
    % quote wraps a string in double quotes, as inside arrays.
    if fmt ~= ""
        val = sprintf(fmt, v);
    elseif isnumeric(v)
        val = string(v);
        if ismissing(val)
            val = string(num2str(v));  % string(NaN) is <missing>
        end
    elseif islogical(v)
        val = ternary(v, "true", "false");
    elseif ischar(v)
        val = "'" + v + "'";
    elseif isstring(v) && ismissing(v)
        val = "<missing>";
    elseif isstring(v)
        val = ternary(quote, """" + v + """", v);
    elseif isstruct(v) || iscell(v)
        val = disp_str(v);
    elseif isa(v, "function_handle")
        val = "<function handle of " + disp_str(v) + ">";
    elseif ismethod(v, "disp") || ~isobject(v)
        val = disp_str(v);
    else
        val = sprintf("<%s object>", class(v));
    end
end

function val = disp_str(obj)
    val = strip(formattedDisplayText(obj, LineSpacing="compact", SuppressMarkup=true, UseTrueFalseForLogical=true));
end

function val = stack_str(stack)
    val = "";
    for k = 1:length(stack)
        sk = stack(k);
        val = val + sprintf("  > %s > %s (line %d)\n", sk.file, sk.name, sk.line);
    end
end

function val = ternary(cond, val_true, val_false)
    if logical(cond)
        val = val_true;
    else
        val = val_false;
    end
end
