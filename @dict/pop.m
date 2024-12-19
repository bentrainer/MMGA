function value = pop(self, key)
% Return the record based on the given key and delete that record.

    if self.contains(key)
        value = self.get(key);
        self.del_nocheck(key);
    end
end