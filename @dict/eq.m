function r = eq(A, B)

    r = false;

    if A.len ~= B.len
        return
    end

    len = A.len;

    Aks = A.sorted_keys();
    Bks = B.sorted_keys();

    for kn = 1:len
        Ak = Aks{kn};
        Bk = Bks{kn};

        if keyHash(Ak)~=keyHash(Bk)
            return
        end

        Av = A.get(Ak);
        Bv = B.get(Bk);

        if keyHash(Av)~=keyHash(Bv)
            return
        end
    end

    r = true;

end