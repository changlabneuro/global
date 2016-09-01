%{


    DataObject.m -- class for extending the functionality of a struct.
    

    BACKGROUND
        --
        The basic idea is to identify each data point in your matrix, cell
        array, etc. by a set of labels. Put simply, the row id of a given
        label should correspond to the row id of the data point(s) it
        accompanies. You can then have an arbitrary number of label_fields
        (category names) -- the *set* of labels at row N will correspond to the
        data point(s) at row N.

        For example, if you measured peoples' heights, you might end up 
        with a data matrix that looks like this:
        
        5.5         %   feet
        5.7
        6.0
        ...

        The accompanying labels might be:
        
        NAME:
            'John'
            'Jane'
            'Alice'
            ...
        GENDER:
            'male'
            'female'
            'female'
            ...
        BIRTHPLACE: 
            'ohio'
            'ohio'
            'ohio'

        etc.
        
        Thus data for 'Female' genders resides in rows 2:3; data for
        'Alice' resides in row 3, etc.

    INPUT STRUCTURE
        --
        To initialize a DataObject, pass in a struct with fields 'data' and
        'labels'. 'labels' must itself be a structure with fields
        corresponding to the category names of their accompanying labels.
        For example, in the above height example, the necessary input
        structure would be:
        
        input.data = [5.5;5.7;6.0];
        
        labels.name = {'John';'Jane';'Alice'};
        labels.gender = {'male';'female';'female'};
        labels.birthplace = {'ohio';'ohio';'ohio'};
        
        input.labels = labels;

        new_object = DataObject(input);

        **  Note that you can use external funtion create_label_struct to
            facilitate this label-making process.

        **  Note that data and labels *are* expected to be stored row-wise

    USAGE
        --
        ** Equality
        --

        The biggest boon to initializing a DataObject is that the data within
        can be indexed / referenced via the '==' operator. E.g.,
        using our height example:
            
        female_index = new_object == 'female';

        would return a logical index : [0;1;1]

        DataObjects can then be filtered by this index:
        
        female_data = new_obj(female_index);
        
        OR (in one step): female_data = new_obj(new_obj == 'female');

        --
        You can add filters by passing in a cell array to the '==' function
        instead of a single string (ALTHOUGH: see caveats below):

        females_from_ohio = new_obj(new_obj == {'female','ohio'});

        --
        You can similarly filter by ~= with the same syntax:
        
        males = new_obj(new_obj ~= 'female');
        
        --
        ** Subscript referencing
        --

        You can specify column and row indices to return a data object with
        the corresponding values. For example, if the data in new_obj.data
        have two columns, one_column = new_obj(:,1) will return a new
        DataObject with only the first columns' data from new_obj.

        --
        ** Operations
        --
        
        Some basic operations / calculations are supported directly,
        without the need to extract the data from the object.
        
        val = count(obj,<dimension>) returns the size of the object in that
        <dimension>. Calling count(obj) returns the size of the largest
        dimension (works like length()).

        vals = mean(obj) will return the column-wise mean(s) of the data

        vals = std(obj) will return the column-wise std deviation(s) of the
        data
        
        new_obj = obj1 ./ obj2 is supported, so long as the data matrices
        of each obj1 are of the same size (or obj2 can be of count() == 1)

        vertical concatenation of an arbitrary number objects is supported,
        *so long as the label-fields (category names) of each object match*
        new_obj = [obj1;obj2;obj3 ...];

        --
        ** Helpers
        --
        
        structure = obj2struct(obj) will convert the DataObject to a
        structure, which will be useful when attempting to reference nested
        data (see caveats below). 

        --
        ** Caveats:
        --
    
            * If a label resides in more than one label_field (category), it can't be
                filtered with the '==' method: using '==' will return an error.
                Instead, you should use the 'only' function:
        
                females_from_ohio = only(new_obj, ...
                                        'gender',       {'female'}, ...
                                        'birthplace',   {'ohio'});
            
            * You currently cannot search for multiple labels within a
                category with quite the same syntax. For example:
            
                males_and_females = new_obj(new_obj == {'male','female'})

                will *NOT* work.
                
                males_and_females = new_obj(new_obj == 'male' | new_obj ==
                'female')
                
                *WILL* work.
            
            * The default behavior is such that objects can be tested
            	for equality with the same syntax: 
    
                objects_are_equal = obj1 == obj2;
                objects_are_not_equal = obj1 ~= obj2;

                Thus, the equality operator, perhaps confusingly, has two
                different uses: filtering labels, and determining object
                equivalence.

            * There are a certain number of bugs that arise when overloading
                matlab's subscript referencing and assignment. For example,
                even though the 'data' field might be just an ordinary 
                matlab matrix, attempting to access obj.data(:,1) *will* 
                throw an error. Similarly, if you try to store a cell array 
                of structures, trying to access obj.data(1).('field') 
                *will* throw an error.
            
        You should decide whether these caveats outweigh the convenience of
        using '==', which is basically the whole point of this thing.


%}

classdef DataObject
    properties (Access = public)
        data;
        labels;
        label_fields;
        dtype;
        meta = struct(...
            'author',   'Nick Fagan', ...
            'email',    'fagan.nicholas@gmail.com', ...
            'version',  VersionObject(...
                'release',  0,...
                'revision', 1 ...
            ) ...
        );
    end
    
    methods
        function obj = DataObject(data_struct)
            
            if isa(data_struct,'DataObject')
                data_struct = obj2struct(data_struct);
            end
            
            obj.validate(data_struct);
            obj.data = data_struct.data;
            obj.labels = data_struct.labels;
            obj.label_fields = fieldnames(obj.labels);
            obj.dtype = get_dtype(obj);
        end
        
        %   old way of selecting specific labels -- use if the label
        %   you're trying to select could be in multiple label fields
        
        function [obj,ind] = only(obj,varargin)
            [separated,ind] = separate_data_obj(obj,varargin{:});
            obj = DataObject(separated);
        end
        
        function obj = index(obj,ind)
            obj = DataObject(index_obj(obj2struct(obj),ind));
        end
        
        function obj = flush(obj)
            obj.data = [];
            for i = 1:length(obj.label_fields)
                obj.labels.(obj.label_fields{i}) = [];
            end
            obj.dtype = get_dtype(obj);
        end
        
        %   -
        %   Label handling
        %   -
        
        %   for a given label_field (e.g., 'sessions'), set labels for
        %   that field to <setas>
        
        function obj = setlabels(obj,field,setas,index)
            
            if iscell(setas)
                if (length(setas) > 1 && length(setas) ~= sum(index))
                    error('Dimension mismatch in subscript assignment');
                end
                
            elseif isa(setas,'char')
                setas = {setas};
                
            else
                error(['Using this assignment format, the to-be-assigned value(s)' ...
                    , ' must either be a string, or a cell array']);
            end

            if ~islabelfield(obj,field)
                error('Desired field %s does not exist',field);
            end
            
            if nargin < 4
                if length(setas) == 1
                    index = true(count(obj,1),1);
                    
                else
                    error(['You must supply an index to assign values, unless you' ...
                        , ' are assigning all labels in a field to a single value']);
                end
            end
            
            labels = obj.labels;            %#ok<PROPLC>
            labels.(field)(index) = setas;  %#ok<PROPLC>
            
            obj.labels = labels;            %#ok<PROPLC>
        end
        
        function obj = addlabelfield(obj,field,labels)
            if nargin < 3
                labels = repmat({''},count(obj,1),1);
            end
            
            if any(strcmp(field,obj.label_fields))
                error('The field ''%s'' already exists in the object.', field);
            end
            
            obj.labels.(field) = labels;
            obj.label_fields{end+1} = field;
            
        end
        
        %   -
        %   label helpers
        %   -
        
        function iswithin = islabelfield(obj,field)
            
            iswithin = false;
            
            if any(strcmp(obj.label_fields,field))
                iswithin = true; return;
            end
        end
        
        %   -
        %   equality testing
        %   -
        
        %   return an index of where the data labels = <wanted_labels>
        %   
        %   Optionally specify <search_fields> to limit the scope of the
        %   search (can speed things significantly if there are many
        %   <label_fields>. Note that, if <search_fields> are specified,
        %   the function cannot be called with the '==' operator. Instead,
        %   you must use the full syntax: [ind, fields] = eq( ... )
        
        function [ind,fields] = eq(obj,wanted_labels,search_fields)
            
            %   search all fields, unless specific fields are given
            
            if nargin < 3
                search_fields = obj.label_fields;
            else %  make sure <search_fields> are formatted correctly
                search_fields = cell_if_not_cell(obj,search_fields);
            end
            
            %   if <wanted_labels> is actually another data object, redirect
            %   to test_object_equality.
            
            if isa(wanted_labels,'DataObject')
                ind = test_object_equality(obj,wanted_labels); fields = -1;
                return;
            end
            
            %   Otherwise, get an index of the desired data in obj.data
            
            wanted_labels = cell_if_not_cell(obj,wanted_labels);
            ind = true(size(obj.data,1),1);
            fields = cell(size(wanted_labels)); %   for storing which fields
                                                %   were not empty
            label_size = length(obj.labels.(search_fields{1}));
            
            for i = 1:length(wanted_labels)
                matches_label_field = false(label_size,length(search_fields));
                
                label = wanted_labels{i};
                
                for j = 1:length(search_fields)

                    current_labels = obj.labels.(search_fields{j});

                    %   If string begins with *, treat as a wildcard,
                    %   and search labels for all strings where the
                    %   pattern matches, **regardless of case**
                    %   Otherwise, search for the exact string

                    if strncmpi(wanted_labels{i},'*',1)
                        label = label(2:end);
                        matches_label_field(:,j) = cellfun(@(x) ~isempty(strfind(lower(x),label)),current_labels);
                        wildcard = true; %%% note
                    else
                        wildcard = false;
                        matches_label_field(:,j) = strcmp(current_labels,label);
                    end

                    if any(sum(matches_label_field(:,j)))
                        fields(i) = search_fields(j);
                        
                        if wildcard
                            break;
                        end
                    end
                end
                
                %   important check -- make sure that labels were not found
                %   in more than one <label_field>, in which case the index
                %   will not be reliable.
                
                if any(sum(matches_label_field,2) > 1)
                    error(['The label ''%s'' was found in multiple label' ...
                        , ' fields -- indexing with ''=='' would be ambiguous.' ...
                        , ' Use function ''only'' instead'],label);
                end
            ind = ind & (sum(matches_label_field,2) >= 1);
            end
        end
        
        %   test ''object'' equality (not overloaded)
        
        function equiv = test_object_equality(obj1,obj2)
            equiv = true; %#ok<NASGU>
            
            %   data equality
            
            if ~strcmp(obj1.dtype,obj2.dtype)
                fprintf('doc type inequality');
                equiv = false; return;
            end
            obj1_size = size(obj1.data);
            obj2_size = size(obj2.data);
            if any(obj1_size ~= obj2_size)
                fprintf('size inequality');
                equiv = false; return;
            end
            if ~strcmp(obj1.dtype,'cell')
                for i = 1:obj1_size(2)
                    if sum(obj1.data(:,i) == obj2.data(:,i)) ~= obj1_size(1)
                        if any(isnan(obj1.data(:,i)) | isnan(obj2.data(:,i)))
                            fprintf('\nData contain NaNs ...');
                        end
                        equiv = false; return;
                    end
                end
            else
                fprintf(['\nWARNING: Testing equality of cell-array stored' ...
                    , ' data is currently unsupported. The given output may not be accurate!']);
            end
            
            %   label equality
            
            equiv = labeleq(obj1,obj2);
            
        end
        
        %   test label equality
        
        function equiv = labeleq(obj1,obj2)
            equiv = true;
            if count(obj1,1) ~= count(obj2,1)
                equiv = false; return;
            end
            if length(obj1.label_fields) ~= length(obj2.label_fields)
                equiv = false; return;
            end
            if ~strcmp(obj1.label_fields,obj2.label_fields)
                equiv = false; return;
            end
            for i = 1:length(obj1.label_fields)
                n_equal = sum(strcmp(obj1.labels.(obj1.label_fields{i}),obj2.labels.(obj1.label_fields{i})));
                if n_equal < count(obj1)
                    equiv = false; return;
                end
            end
        end
        
        %   testing inequality
        
        function ind = ne(obj,wanted_labels)
            if ~isa(wanted_labels,'DataObject')
                wanted_labels = cell_if_not_cell(obj,wanted_labels);
                ind = zeros(size(obj.data,1),length(wanted_labels));
                for i = 1:length(wanted_labels)
                    ind(:,i) = obj == wanted_labels{i};
                end
                ind = sum(ind,2) >= 1; ind = ~ind;
            else
                ind = ~test_object_equality(obj,wanted_labels);
            end
        end
        
        %   -
        %   Subscript assign / ref overloading
        %   -
        
        %   subscript referencing
        
        function obj = subsref(obj,S)
            for i = 1:length(S)
                is_struct_ref = strcmp(S(i).type,'.');
                is_parenth_ref = strcmp(S(i).type,'()');
                if is_struct_ref
                    obj = obj.(S(i).subs);
                end
                
                %   return a field of labels with parenthetical reference
                
                if is_parenth_ref && ~strcmp(S(i).subs{1},':') && ischar(S(i).subs{1})
                    labels = obj.labels; %#ok<PROPLC>
                    obj = labels.(S(i).subs{1}); return; %#ok<PROPLC>
                end
                
                %   otherwise, return a new data object
                
                if is_parenth_ref && length(S(i).subs) == 1
                    indexed = obj2struct(obj);
                    obj = DataObject(index_obj(indexed,S(i).subs{1}));
                elseif is_parenth_ref && strcmp(S(i).subs{1},':')
                    indexed = obj2struct(obj); indexed.data = indexed.data(:,S(i).subs{2});
                    obj = DataObject(indexed);
                elseif is_parenth_ref && strcmp(S(i).subs{2},':')
                    ind = false(count(obj,1),1); ind(S(i).subs{1}) = true;
                    obj = DataObject(index_obj(obj2struct(obj),ind));
                elseif is_parenth_ref && length(S(i).subs) == 2
                    ind = false(count(obj,1),1); ind(S(i).subs{1}) = true;
                    indexed = index_obj(obj2struct(obj),ind);
                    indexed.data = indexed.data(:,S(i).subs{2});
                    obj = DataObject(indexed);
                end
            end
        end
        
        %   subscript assignment
        
        function obj = subsasgn(obj,S,vals)
            for i = 1:length(S)
                if strcmp(S(i).type,'()')
                    
                    %   set labels associated with <field>
                    
                    if isa(S.subs{1},'char') && ~any(strcmp(S.subs,':'))
                        
                        %   if format is: obj('somefield') = 'some string'
                        
                        if length(S.subs) == 1
                            obj = setlabels(obj,S.subs{1},vals);
                            return;
                            
                        %   if format is: obj('somefield',index) = 'some string'
                        %   OR obj('somefield',index) = {'1st string', 2nd
                        %   string', '...'} 
                        
                        elseif length(S.subs) == 2
                            obj = setlabels(obj,S.subs{1},vals,S.subs{2});
                            return;
                            
                        else
                            error('Unsupported assignment method');
                        end
                    end
                    
                    %   otherwise, set data
                    
                    if ~any(strcmp(S.subs,':'))
                        obj.data(S(i).subs{1}) = vals;
                    elseif strcmp(S(i).subs{2},':')
                        if ~isempty(vals)
                            obj.data(S(i).subs{1},:) = vals;
                        else
                            ind = S(i).subs{1}; ind = ~ind; 
                            obj = DataObject(index_obj(obj2struct(obj),ind));
                        end
                    else
                        error('Unsupported index method');
                    end
                elseif strcmp(S(i).type,'.')
                    obj.(S(i).subs) = vals;
                end
            end
        end
        
        %   -
        %   Other overloaded operators
        %   -
        
        %   less than
        
        function ind = lt(obj,vals)
            if isa(vals,'DataObject')
                vals = vals.data;
            end
            ind = obj.data < vals;
        end
        
        %   less than or equal to
        
        function ind = le(obj,vals)
            if isa(vals,'DataObject')
                vals = vals.data;
            end
            ind = obj.data <= vals;
        end
        
        %   greater than
        
        function ind = gt(obj,vals)
            if isa(vals,'DataObject')
                vals = vals.data;
            end
            ind = obj.data > vals;
        end
        
        %   greater than or equal to
        
        function ind = ge(obj,vals)
            if isa(vals,'DataObject')
                vals = vals.data;
            end
            ind = obj.data >= vals;
        end
        
        %   divide
        
        function obj = rdivide(obj,divisor)
            cell_divide_error(obj); 
            if isa(divisor,'DataObject');
                divisor = divisor.data;
                cell_divide_error(divisor);
            end
            obj.data = obj.data ./ divisor;
            
            %   if dtype is cell, cannot divide
            
            function cell_divide_error(a)
                if strcmp(a.dtype,'cell')
                    error('Cannot divide with cell-array data');
                end
            end
        end
        
        %   subtraction
        
        function obj = minus(obj,subtractor)
            if isa(subtractor,'DataObject')
                if ~labeleq(obj,subtractor)
                    error('Labels must be equivalent between objects');
                end
                obj.data = obj.data - subtractor.data;
                return;
            end
            
            obj = obj.data - subtractor;
            
        end
        
        %   -
        %   Other overloaded matrix manipulation functions
        %   -
        
        %   max, min
        
        function val = max(obj)
            val = max(obj.data);
        end
        
        function val = min(obj)
            val = min(obj.data);
        end
        
        %   transposition
        
        function obj = transpose(obj)
            obj.data = obj.data.';
            for i = 1:length(obj.label_fields)
                obj.labels.(obj.label_fields{i}) = ...
                    obj.labels.(obj.label_fields{i}).';
            end
        end
        
        %   sum
        
        function vals = sum(obj)
            vals = sum(obj.data);
        end
        
        %   concatenation
        
        function concat = vertcat(varargin)
            concat = DataObject(concatenate_data_obj(varargin{:}));
        end
        
        %   standin for "size"
        
        function tot = count(obj,dim)
            if nargin < 2
                tot = max(size(obj.data));
            else tot = size(obj.data,dim);
            end
        end
        
        %   -
        %   stats / means
        %   -
        
        function val = std(obj)
            val = std(obj.data);
        end
        
        function val = mean(obj)
            val = mean(obj.data);
        end
        
        %   -
        %   indexing helpers
        %   -
        
        function [new_obj,ind] = no_zeros(obj)
            ind = ~~obj.data(:,1); new_obj = index(obj,ind); ind = ~ind;
        end
        
        function [new_obj,ind] = no_nans(obj)
            ind = ~isnan(obj); new_obj = index(obj,ind);
        end
        
        function ind = isnan(obj)
            ind = isnan(obj.data);
        end
        
        function valid = isempty(obj)
            valid = isempty(obj.data);
        end
        
        function [obj, ind] = truthy(obj)
            ind = isnan(obj) | isinf(obj.data) | obj.data == 0;
            obj = index(obj,~ind); 
        end
        
        %   getindices.m -- returns <indices> of all the unique combinations of unique
        %   labels in the categories of <fields>. <allcombs> indicates the 
        %   combination of labels used to construct each index.
        
        %   Very useful for avoiding nested loops -- instead, you can iterate through 
        %   the cell array of indices returned here. Alternatively, you can 
        %   prepend '**' to a string in <fields>, in which case that single
        %   string value (rather than all unique values associated with a 
        %   field) will be indexed.
        
        %   TODO: it shouldn't be possible to specify a field and also a
        %   double-starred (**) label which is present in that field. Add an error
        %   check to prevent this from occurring.
        
        function [indices, allcombs] = getindices(obj,fields,show_progress)
            tic;
            if nargin < 3
                show_progress = 'no';
            end
            
            fields = cell_if_not_cell(obj,fields);
            
            uniques = cell(size(fields));
            for k = 1:length(fields)
                
                %   if ** is prepended to the search string, it will be
                %   treated as its own unique value, rather than as a field
                %   in label_fields
                
                if ~strncmpi(fields{k},'**',2)
                    uniques(k) = {unique(obj.labels.(fields{k}))};
                else
                    uniques(k) = {{fields{k}(3:end)}};
                    
                    %   find out which field 
                    
                    [~, field] = obj == uniques{k}; %#ok<RHSFN>
                    fields{k} = field{1};
                end
            end
            
            %   get all unique combinations of data labels
            
            allcombs = allcomb(uniques);
            
            indices = cell(size(allcombs,1),1);
            empty = true(size(allcombs,1),1);
            
            for i = 1:size(allcombs,1)
                if strcmpi(show_progress,'showprogress')
                   fprintf('\nProcessing %d of %d',i,size(allcombs,1)); 
                end
%                 index = obj == allcombs(i,:);
                index = eq(obj,allcombs(i,:),fields);
                if sum(index) >= 1
                    indices(i) = {index};
                    empty(i) = false;
                end                
            end
            
            indices(empty) = []; %  remove empty indices
            allcombs(empty,:) = [];
            
            toc;
        end
        
        %   -
        %   helpers
        %   -
        
        %   preallocation
        
        function obj = pre(prototype,dims,type)
            
            %   prototype must be an object with label fields
            
            if nargin < 3
                type = 'zeros';
            end
            
            input_struct = struct(); 
            
            switch type
                case 'zeros'
                    data = zeros(dims); %#ok<PROPLC>
                case 'nans'
                    data = nan(dims); %#ok<PROPLC>
                case 'ones'
                    data = ones(dims); %#ok<PROPLC>
                otherwise
                    error('Unrecognized preallocation type ''%s''',type);
            end
            
            input_struct.data = data; %#ok<PROPLC>
            
            labels = struct();  %#ok<PROPLC>
            labelfields = prototype.label_fields;
            
            for i = 1:length(labelfields)
                labels.(labelfields{i}) = cell(dims(1),1); %#ok<PROPLC>
            end
            
            input_struct.labels = labels; %#ok<PROPLC>
            
            obj = DataObject(input_struct);
        end
        
        %   initial input validation upon object construction
        
        function validate(obj,data_struct)
            struct_fields = fieldnames(data_struct);
            if ~any(strcmp(struct_fields,'data')) || ~any(strcmp(struct_fields,'labels'))
                error(['The input to the data object must be a data structure with ''data''' ...
                    , ' and ''labels'' as fieldnames (note capitalization).']);
            end
            label_fields = fieldnames(data_struct.labels); %#ok<PROPLC>
            if isempty(label_fields) %#ok<PROPLC>
                error('labels'' must be a structure with at least one field');
            end
            if size(data_struct.labels.(label_fields{1}),1) ~= size(data_struct.data,1) %#ok<PROPLC>
                error('Data must be the same length as labels');
            end
        end
        
        %   get the array type of the data in obj.data
        
        function dtype = get_dtype(obj)
            if ~isempty(obj.data)
                if isa(obj.data(1),'cell')
                    dtype = 'cell';
                elseif isa(obj.data(1),'double')
                    dtype = 'double';
                end
            else
                dtype = 'undf';
            end
        end
        
        %   helper for eq() -- puts inputs into cell array behind the
        %   scenes
        
        function wanted_labels = cell_if_not_cell(obj,wanted_labels)
            if ~iscell(wanted_labels)
                wanted_labels = {wanted_labels};
            end
        end
        
        function s = obj2struct(obj)
            s = struct();
            s.data = obj.data;
            s.labels = obj.labels;
        end
        
        %   print unique labels present
        
        function disp(obj,label_fields,verbose)
            if nargin < 2
                label_fields = obj.label_fields;
            else
                label_fields = obj.cell_if_not_cell(label_fields);
            end
            if nargin < 3
                verbose = false;
            end
            for i = 1:length(label_fields)
                uniques = unique(obj.labels.(label_fields{i}));
                fprintf('\n%s:',upper(label_fields{i}));
                if length(uniques) < 20 || verbose
                    for j = 1:length(uniques)
                        fprintf('\n\t%s',uniques{j});
                    end
                else
                    fprintf('\n\tToo many to display ... Rerun with verbose = true to see all');
                end
            end
        end
    end
end