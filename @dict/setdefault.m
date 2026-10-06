function value = setdefault(self, key, value)
% Return the value of the key, like Python's dict.setdefault.
% Only if the given key is not in the dict, set it to value ([] by default) first.

    arguments
        self
        key
        value = []
    end

    if self.contains(key)
        value = self.get(key);
    else
        self.set(key, value);
    end
end
