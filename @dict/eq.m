function r = eq(A, B)
% Return true if both dicts have the same keys with equal values, like Python's ==.
% Order does not matter, values compare with isequal, and nested dicts compare by content.

    r = false;

    if ~strcmp(class(A), class(B))
        return
    end

    % A dict that contains itself is equal to itself without recursing.
    if eq@handle(A, B)
        r = true;
        return
    end

    if A.len ~= B.len
        return
    end

    Aks = A.keys();
    for kn = 1:numel(Aks)
        k = Aks{kn};
        if ~B.contains(k) || ~A.same_value(A.get(k), B.get(k))
            return
        end
    end

    r = true;

end
