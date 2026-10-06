function other = copy(self)
% Return a shallow copy, like Python's dict.copy. Values that are handles, such as dicts, are shared.

    other = feval(class(self));
    other.mdict    = self.mdict;
    other.order    = self.order;
    other.len      = self.len;
    other.next_seq = self.next_seq;
end
