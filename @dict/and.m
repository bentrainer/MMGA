function C = and(A, B)
% Return a new dict object with the keys in both dict.
% If two dicts have different value for a same key, the
% value from the first one is used.

    if A.len > B.len
        C = A;
        A = B;
        B = C;
    end

    Aks = A.keys();
    C   = dict();

    for kn = 1:length(Aks)
        k = Aks{kn};
        if B.contains(k)
            % TODO: check if A(k)=B(k)?
            C.update(k, A.get(k));
        end
    end

end