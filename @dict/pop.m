function value = pop(self, key, default)
% Return the record based on the given key and delete that record, like Python's dict.pop.
% If the key is not in the dict, return default, or throw MMGA:dict:missingKey without one.

    if self.contains(key)
        value = self.get(key);
        self.del(key);
    elseif nargin > 2
        value = default;
    else
        self.missing_key(key);
    end
end
