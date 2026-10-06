function k = keys(self)
% Return a cell array contains all the keys in the dict, in insertion order.

    k = self.order.keys();
    [~, idx] = sort(self.order.values());
    k = k(idx);
end
