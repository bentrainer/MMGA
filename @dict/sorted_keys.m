function keys = sorted_keys(self)
% Return a cell array contains the keys in the dict sorted by keys' hash calculated by keyHash().

    ks = self.mdict.keys();
    kh = zeros(size(ks));

    for kn = 1:length(ks)
        kh(kn) = keyHash(ks{kn});
    end

    [~, idx] = sort(kh);
    keys = cell(size(ks));
    for k = 1:length(idx)
        keys{k} = ks{idx(k)};
    end
end