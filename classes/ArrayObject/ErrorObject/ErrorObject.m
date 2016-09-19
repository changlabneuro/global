classdef ErrorObject
    
    properties (Constant = true, Hidden = true)
        errors = struct(...
            'refIsNotPeriod',       'The reference is not a struct (period) reference', ...
            'inputIsNotStruct',     'Input must be a structure', ...
            'inputIsNotCell',       'Input must be a cell array', ...
            'inputIsNotString',     'Input must be a string', ...
            'inputIsNotCellString', 'Input must be a cell arry of strings', ...
            'inputIsNotLabelObject','Input must be a LabelObject', ...
            'inputIsNotDataObject', 'Input must be a DataObject', ...
            'inputIsNotDataPointObject','Input must be a DataPointObject', ...
            'fieldDoesNotExist',    'The specified field does not exist', ...
            'inconsistentDtype',    'The doctypes of the objects are not consistent', ...
            'inconsistentLabels',   'The label objects are not consistent', ...
            'inconsistentDimensions','Dimensions are not consistent' ...
        );
    end
    
    methods
        
        function obj = ErrorObject()
        end
        
        %{
            return an error message
        %}
        
        function err = subsref(obj,s)
            
            sub_type = s.type;
            subs = s.subs;
            
            assert(strcmp(sub_type,'.'),ErrorObject.errors.refIsNotPeriod);
            assert(ischar(subs),ErrorObject.errors.inputIsNotString);
            
            err = obj.errors.(subs);
            
        end
        
        %{
            display errors
        %}
        
        function disp(obj)
            disp(obj.errors);
        end
        
    end
    
end