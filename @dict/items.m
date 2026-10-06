function r = items(self)
% Return a table contains all key-value pairs in the dict, in insertion order.

    k = self.keys();
    r = table(k, self.mdict(k), VariableNames = ["Key", "Value"]);
end
