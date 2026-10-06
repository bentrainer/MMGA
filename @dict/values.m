function v = values(self)
% Return a cell array contains all the values in the dict, in insertion order.

    v = self.mdict(self.keys());
end
