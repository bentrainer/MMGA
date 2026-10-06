function setdefault(self, key, value)
% Only if the given key is not in the dict, set it to value.

    if ~self.contains(key)
        self.set(key, value);
    end
end