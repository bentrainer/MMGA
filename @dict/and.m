function C = and(A, B)
% Return a new dict object with the keys in both dict.
% If two dicts have different value for a same key, the
% value from the first one is used, with an
% MMGA:dict:valueMismatch warning.

    % Scan the smaller dict, but take every value from A.
    small = A;
    large = B;
    if A.len > B.len
        small = B;
        large = A;
    end

    small_keys = small.keys();

    % Construct the result through class(A) rather than calling dict().
    % As the +mtools submodule, the class is mtools.dict, and an unqualified
    % dict() would resolve to a top-level MMGA on the path, or fail without
    % one. class(A) gives "dict" or "mtools.dict" to match the layout.
    C = feval(class(A));

    for kn = 1:length(small_keys)
        k = small_keys{kn};
        if large.contains(k)
            value = A.get(k);

            % Values compare by keyHash, as in eq.m.
            if keyHash(value) ~= keyHash(B.get(k))
                warning( ...
                    "MMGA:dict:valueMismatch", ...
                    "key '%s' has different values in the two dicts, using the value from the first", ...
                    strip(formattedDisplayText(k, LineSpacing = "compact", SuppressMarkup = true, UseTrueFalseForLogical = true)) ...
                );
            end

            C.set(k, value);
        end
    end

end