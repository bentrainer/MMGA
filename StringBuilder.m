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

                    obj.size = count;
                    obj.grow();

                    obj.append(varargin{:});
                end
            end

        end

        function append(self, varargin)
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

    end

end