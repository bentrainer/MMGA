function C = and(A, B)
% Return a new dict object with the keys in both dict, in the order of the first.
% If two dicts have different value for a same key, the
% value from the first one is used, with an
% MMGA:dict:valueMismatch warning.

    % Construct the result through class(A), as copy does.
    C = feval(class(A));

    Aks = A.keys();
    for kn = 1:length(Aks)
        k = Aks{kn};
        if B.contains(k)
            value = A.get(k);

            % Values compare as in eq.m.
            if ~A.same_value(value, B.get(k))
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
