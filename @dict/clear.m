function clear(self)
% CLEAR
% Clear all items in the dictionary.

    % if GC works correctly, I should do
    % nothing special here except for just
    % simply setting self.mdict to a new value.
    self.mdict = dictionary({}, {});
    self.len   = 0;
end