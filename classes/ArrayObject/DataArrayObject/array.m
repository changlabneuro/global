%{
    alias for DataArrayObject (shorter name)
%}

function obj = array(varargin)
    obj = DataArrayObject(varargin{:});
end