classdef dict < handle

    properties (Access = private)
        mdict = dictionary({}, {})
        len   = 0
    end

    properties
        docstring = "Class of dummy-dictionary, type `help dict` for more information."
    end

    methods
        function obj = dict(varargin)
            % DICT - Object behaves like MATLAB's dictionary but accepts variable types of key/value.

            for i = 1:length(varargin)
                if mod(i, 2)==1
                    k = varargin{i};
                else
                    v = varargin{i};
                    obj.update(k, v);
                end
            end
        end

        function update(self, key, value)
            % Set record in the dict to the given value using the given key.
            if self.contains(key)
                self.call_update(key, value);
            else
                self.add_newitem(key, value);
            end
        end
        function set(self, key, value)
            % An alias to dict.update().
            self.update(key, value);
        end

        function A = get(self, key)
            % GET Get the value using the given key,
            % if the key is not in the dict, returns noting
            key = {key};

            if isKey(self.mdict, key)
                A = self.mdict(key);
                if iscell(A)
                    A = A{1};
                end
            end
        end

        function r = contains(self, key)
            % Check if the given key is in the dict.
            r = isKey(self.mdict, {key});
        end

        function del(self, key)
            % Delete the record based on the given key.
            if self.contains(key)
                self.del_nocheck(key);
            end
        end
        function remove(self, key)
            % An alias to dict.del().
            self.del(key);
        end
    end

    methods (Access = private)
        function add_newitem(self, key, value)
            self.call_update(key, value);
            self.len = self.len + 1;
        end
        function del_nocheck(self, key)
            self.mdict({key}) = [];
            self.len = self.len - 1;
        end
        function call_update(self, key, value)
            self.mdict({key}) = {value};
        end
    end

end