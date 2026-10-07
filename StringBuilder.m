classdef StringBuilder < handle
    % Accumulate text with append and read it back with to_str.
    %
    % The text lives in one string scalar. append moves it out of the
    % property before concatenating, so the local copy is unshared and
    % MATLAB appends to it in place with amortized growth. Writing
    % self.str = self.str + v instead copies the whole text on every call.

    properties (Dependent)
        len     % number of characters; assign to truncate or pad
        size    % kept from the old char buffer; equals len
        buffer  % the text as a char row vector
    end

    properties (Access = private)
        str = ""
    end

    methods
        function obj = StringBuilder(varargin)
            if nargin == 0
                return
            end

            % a numeric first argument was the old buffer capacity;
            % MATLAB now manages the capacity, so the value is ignored
            if isnumeric(varargin{1})
                if ~isscalar(varargin{1})
                    warning("MMGA:StringBuilder:nonscalarCapacity", "ignoring a non-scalar capacity argument");
                end
            else
                obj.append(varargin{:});
            end
        end

        function append(self, varargin)
            % fast path for one char row or non-missing string scalar
            if nargin == 2
                v = varargin{1};
                if ischar(v) && isrow(v) || isstring(v) && isscalar(v) && ~ismissing(v)
                    s = self.str;
                    self.str = "";
                    s = s + v;
                    self.str = s;
                    return
                end
            end

            % restore the text before any error so it is never lost
            s = self.str;
            self.str = "";
            for k = 1:numel(varargin)
                v = varargin{k};
                if ischar(v)
                    if isempty(v)
                        continue
                    end
                    if ~isvector(v)
                        self.str = s;
                        error("MMGA:StringBuilder:charMatrix", "cannot append a char matrix");
                    end
                    s = s + reshape(v, 1, []);
                elseif isstring(v)
                    for vk = 1:numel(v)
                        if ismissing(v(vk))
                            self.str = s;
                            error("MMGA:StringBuilder:missingString", "cannot append a missing string");
                        end
                        s = s + v(vk);
                    end
                end
            end
            self.str = s;
        end

        function s = to_str(self)
            s = self.str;
        end

        function s = string(self)
            s = self.str;
        end

        % overload sb + str
        function sb = plus(a, b)
            if isstring(a) || ischar(a)
                tmp = a;
                a = b;
                b = tmp;
            end

            % the old char buffer stored numbers as character codes
            if isnumeric(b)
                b = char(b);
            elseif ~ischar(b) && ~isstring(b)
                error("MMGA:StringBuilder:invalidOperand", "cannot add %s and %s", class(a), class(b));
            end

            a.append(b);
            sb = a;
        end

        function n = get.len(self)
            n = strlength(self.str);
        end

        function set.len(self, n)
            % the old buffer could be truncated, or reset with len = 0
            c = char(self.str);
            c(end + 1:n) = ' ';
            self.str = string(c(1:n));
        end

        function n = get.size(self)
            n = strlength(self.str);
        end

        function c = get.buffer(self)
            c = char(self.str);
        end
    end

end

% Previous implementation, kept for reference: a char buffer that grows
% geometrically like a Go slice, with a one-value fast path for append.
% Indexed writes into the buffer property are in place, so it is linear,
% but 1e6 appends of 10 chars took 0.40 s against 0.14 s for the string
% version above and 0.04 s for a native s = s + p loop (R2025a).
%{
classdef StringBuilder < handle

    properties
        len = 0
        size = 255
        buffer = blanks(255)
    end

    methods (Access=private)
        function grow(self, at_least)
            arguments
                self
                at_least = 0
            end
            if self.size > 1024
                new_size = floor(self.size*1.25);
            else
                new_size = self.size*2;
            end

            if new_size<at_least
                new_size = at_least;
            end

            self.buffer(new_size) = ' ';
            self.size = length(self.buffer);
        end

        function append_single(self, s)
            if isstring(s)
                s = char(s);
            end

            add_len = length(s);
            new_len = self.len + add_len;

            if new_len>self.size
                self.grow(new_len);
            end

            self.buffer((self.len+1):new_len) = s;
            self.len = new_len;
        end
    end

    methods
        function obj = StringBuilder(varargin)
            if nargin==0
                return
            else
                if isnumeric(varargin{1})
                    if isscalar(varargin{1})
                        obj.buffer = blanks(varargin{1});
                        obj.size = length(obj.buffer);
                    else
                        warning("idk");
                    end
                else
                    count = 0;
                    for k = 1:nargin
                        v = varargin{k};
                        if ischar(v)
                            count = count + length(v);
                        elseif isstring(v)
                            if isscalar(v)
                                count = count + strlength(v);
                            else
                                for vk = 1:numel(v)
                                    count = count + strlength(v(vk));
                                end
                            end
                        end
                    end

                    if count > obj.size
                        obj.grow(count);
                    end

                    obj.append(varargin{:});
                end
            end

        end

        function append(self, varargin)
            % fast path for one char vector or string scalar: the varargin
            % loop below costs about as much as the copy itself
            if nargin == 2
                v = varargin{1};
                if ischar(v) || isstring(v) && isscalar(v)
                    self.append_single(v);
                    return
                end
            end

            for k = 1:length(varargin)
                v = varargin{k};
                if ischar(v)
                    self.append_single(v);
                elseif isstring(v)
                    if isscalar(v)
                        self.append_single(v);
                    else
                        for vk = 1:numel(v)
                            self.append_single(v(vk));
                        end
                    end
                end
            end
        end

        function s = to_str(self)
            s = string(self.buffer(1:self.len));
        end
        function s = string(self)
            s = self.to_str();
        end

        % overload sb + str
        function sb = plus(a, b)
            if isstring(a) || ischar(a)
                tmp = a;
                a = b;
                b = tmp;
            end

            a.append_single(b);
            sb = a;
        end

    end

end
%}
