function C = or(A, B)
% Return a new dict with the items of A updated by B, like Python's A | B.

    C = A.copy();
    C.update(B);
end
