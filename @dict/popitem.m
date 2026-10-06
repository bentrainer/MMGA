function [key, value] = popitem(self)
% Remove and return the last inserted key and its value, like Python's dict.popitem.
% Throws MMGA:dict:empty if the dict is empty.

    if self.len == 0
        error("MMGA:dict:empty", "popitem(): dict is empty");
    end

    ks = self.order.keys();
    [~, idx] = max(self.order.values());
    key = ks{idx};
    value = self.pop(key);
end
