function catted = DataArrayObject__cat(varargin)

for i = 1:length(varargin)
    current = varargin{i};
    
    if isa(current,'DataArrayObject')
        current_points = current.DataPoints;
    elseif isa(current,'DataPointObject')
        current_points = {current};
    end
    
    if i == 1
        all_points = current_points; continue;
    end
    
    all_points = [all_points current_points];
    
end

catted = DataArrayObject(all_points{:});

end