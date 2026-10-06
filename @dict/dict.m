classdef dict < handle & matlab.mixin.indexing.RedefinesParen

    properties (Access = private)
        mdict    = dictionary({}, {})
        order    = dictionary({}, [])
        len      = 0
        next_seq = 0
    end

    properties
        docstring = "Class of dummy-dictionary, type `help dict` for more information."
    end

    methods
        function obj = dict(varargin)
            % DICT - Python-like dictionary that accepts any key and value types.
            %   dict("a", 1, "b", 2) and dict(a = 1, b = 2) take key-value pairs.
            %   dict(mapping) copies a dict, struct, dictionary, or N-by-2 cell
            %   of pairs, and dict(mapping, "c", 3) adds pairs after it.
            obj.update(varargin{:});
        end

        function set(self, key, value)
            % Set record in the dict to the given value using the given key.
            key = normalize_key(key);
            if isKey(self.mdict, {key})
                self.call_set(key, value);
            else
                self.add_newitem(key, value);
            end
        end

        function update(self, varargin)
            % Merge items like Python's dict.update: a mapping (dict, struct,
            % dictionary, or N-by-2 cell of pairs), key-value pairs, or both.
            pairs = varargin;
            if mod(numel(pairs), 2) == 1
                [ks, vs] = mapping_items(pairs{1}, class(self));
                for j = 1:numel(ks)
                    self.set(ks{j}, vs{j});
                end
                pairs = pairs(2:end);
            end

            for j = 1:2:numel(pairs)
                self.set(pairs{j}, pairs{j + 1});
            end
        end

        function value = get(self, key, default)
            % GET Get the value using the given key, like Python's dict.get.
            % If the key is not in the dict, returns default, which is [].
            % Use d(key) for a lookup that throws MMGA:dict:missingKey.
            arguments
                self
                key
                default = []
            end

            key = {normalize_key(key)};
            if isKey(self.mdict, key)
                value = self.mdict(key);
                value = value{1};
            else
                value = default;
            end
        end

        function r = contains(self, key)
            % Check if the given key is in the dict, like Python's `key in d`.
            r = isKey(self.mdict, {normalize_key(key)});
        end

        function del(self, key)
            % Delete the record, like Python's `del d[key]`.
            % Throws MMGA:dict:missingKey if the key is not in the dict.
            key = normalize_key(key);
            if ~isKey(self.mdict, {key})
                self.missing_key(key);
            end

            self.del_nocheck(key);
        end

        function remove(self, key)
            % An alias to dict.del().
            self.del(key);
        end

        function varargout = size(~, varargin)
            % A dict is one object, so its size is 1-by-1. Use len() for
            % the number of items.
            [varargout{1:max(nargout, 1)}] = size(1, varargin{:});
        end

        function C = cat(~, varargin) %#ok<STOUT>
            error("MMGA:dict:noArray", "dicts cannot form arrays; merge them with | or update");
        end
    end

    methods (Static)
        function obj = fromkeys(iterable, value)
            % Create a dict with every key set to value, like Python's
            % dict.fromkeys. The keys are the elements of a cell or an array.
            arguments
                iterable
                value = []
            end

            obj = feval(mfilename("class"));
            if ~iscell(iterable)
                iterable = num2cell(iterable);
            end

            for k = 1:numel(iterable)
                obj.set(iterable{k}, value);
            end
        end

        function obj = empty(varargin) %#ok<STOUT>
            error("MMGA:dict:noArray", "dicts cannot form arrays; merge them with | or update");
        end
    end

    methods (Access = protected)
        function varargout = parenReference(self, index_op)
            % d(key) returns the value, like Python's d[key].
            key = normalize_key(paren_key(index_op(1)));
            if ~isKey(self.mdict, {key})
                self.missing_key(key);
            end

            value = self.get(key);
            if isscalar(index_op)
                varargout{1} = value;
            else
                [varargout{1:nargout}] = value.(index_op(2:end));
            end
        end

        function self = parenAssign(self, index_op, varargin)
            % d(key) = value sets the value, and d(key).field = value updates
            % part of an existing value.
            key = paren_key(index_op(1));
            if isscalar(index_op)
                self.set(key, varargin{1});
                return
            end

            value = self.parenReference(index_op(1));
            [value.(index_op(2:end))] = varargin{:};
            self.set(key, value);
        end

        function self = parenDelete(self, index_op)
            % d(key) = [] deletes the key, like Python's `del d[key]`.
            self.del(paren_key(index_op(1)));
        end

        function n = parenListLength(~, ~, ~)
            n = 1;
        end
    end

    methods (Access = private)
        function add_newitem(self, key, value)
            self.call_set(key, value);
            self.order({key}) = self.next_seq;
            self.next_seq = self.next_seq + 1;
            self.len = self.len + 1;
        end

        function del_nocheck(self, key)
            self.mdict({key}) = [];
            self.order({key}) = [];
            self.len = self.len - 1;
        end

        function call_set(self, key, value)
            self.mdict({key}) = {value};
        end

        function missing_key(~, key)
            error( ...
                "MMGA:dict:missingKey", "key '%s' does not exist in the dict", ...
                strip(formattedDisplayText(key, LineSpacing = "compact", SuppressMarkup = true, UseTrueFalseForLogical = true)) ...
            );
        end

        function r = same_value(self, a, b)
            % Compare values like Python's ==: nested dicts by content and
            % everything else with isequal, so 1 equals int8(1).
            if isa(a, class(self)) && isa(b, class(self))
                r = a == b;
            else
                r = isequal(a, b);
            end
        end
    end

end

function key = normalize_key(key)
% Give keys that MATLAB's == treats as equal one stored form, as Python
% does for "a" and 1 == 1.0 == True: a character row becomes a string, and
% a logical or numeric key becomes double when the conversion is exact.

    if ischar(key) && (isrow(key) || isequal(size(key), [0 0]))
        key = string(key);
    elseif islogical(key)
        key = double(key);
    elseif isnumeric(key) && ~isa(key, "double")
        as_double = double(key);
        if isequaln(cast(as_double, class(key)), key)
            key = as_double;
        end
    end
end

function key = paren_key(index_op)
% Return the single key in d(key).

    if numel(index_op.Indices) ~= 1
        error( ...
            "MMGA:dict:invalidIndex", ...
            "index a dict with one key, as in d(key); to loop over the keys, use for k = d.keys()'" ...
        );
    end

    key = index_op.Indices{1};
end

function [ks, vs] = mapping_items(mapping, dict_class)
% Return the keys and values of a mapping as two cells.

    if isa(mapping, dict_class)
        ks = mapping.keys();
        vs = mapping.values();
    elseif isstruct(mapping) && isscalar(mapping)
        ks = num2cell(string(fieldnames(mapping)));
        vs = struct2cell(mapping);
    elseif isa(mapping, "dictionary")
        ks = {};
        vs = {};
        if numEntries(mapping) > 0
            ks = keys(mapping);
            vs = values(mapping);
        end
        if ~iscell(ks)
            ks = num2cell(ks);
        end
        if ~iscell(vs)
            vs = num2cell(vs);
        end
    elseif iscell(mapping) && ismatrix(mapping) && size(mapping, 2) == 2
        ks = mapping(:, 1);
        vs = mapping(:, 2);
    else
        error( ...
            "MMGA:dict:invalidArguments", ...
            "expected key-value pairs, optionally after a dict, struct, dictionary, or N-by-2 cell, but got a %s first", ...
            class(mapping) ...
        );
    end
end
