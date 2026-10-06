function s = string(self)
% Return the items as text in insertion order, like Python's str(d), such as
% {"a": 1, 2: 'b', "c": [1 2 3]}. A dict nested in itself shows as {...}.

    s = dict_text(self, class(self), uint64.empty());
end

function s = dict_text(d, dict_class, seen)
% Format one dict, skipping any dict already being formatted.

    seen(end + 1) = keyHash(d);

    ks = d.keys();
    parts = strings(1, numel(ks));
    for k = 1:numel(ks)
        parts(k) = value_text(ks{k}, dict_class, seen) + ": " + value_text(d.get(ks{k}), dict_class, seen);
    end

    s = "{" + strjoin(parts, ", ") + "}";
end

function s = value_text(v, dict_class, seen)
% Format a key or value: strings in double quotes, characters in single
% quotes, scalars as text, and other arrays as MATLAB shows them in a cell.

    if isa(v, dict_class)
        if any(seen == keyHash(v))
            s = "{...}";
        else
            s = dict_text(v, dict_class, seen);
        end
    elseif isstring(v) && isscalar(v)
        if ismissing(v)
            s = "<missing>";
        else
            s = """" + v + """";
        end
    elseif ischar(v) && (isrow(v) || isequal(size(v), [0 0]))
        s = "'" + string(v) + "'";
    elseif islogical(v) && isscalar(v)
        s = "false";
        if v
            s = "true";
        end
    elseif isnumeric(v) && isscalar(v)
        s = string(v);
    elseif isa(v, "double") && isequal(size(v), [0 0])
        s = "[]";
    else
        s = strip(formattedDisplayText({v}, LineSpacing = "compact", SuppressMarkup = true));
        s = extractBetween(s, 2, strlength(s) - 1);
        if ~startsWith(s, ["[", "@"])
            s = "<" + s + ">";
        end
    end
end
