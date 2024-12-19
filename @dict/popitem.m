function value = popitem(self)
% Pop the last record in the dict, the order is determined by MATLAB dictionary.keys() so the FILO may not be guaranteed.

    if self.len > 0
        keys  = self.keys();
        key   = keys{end};
        value = self.pop(key);
    end
end