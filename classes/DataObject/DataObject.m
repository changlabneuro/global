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
        
        %{
            constructor
        %}
        
        function obj = DataObject(varargin)
            if nargin == 0
                data_struct.data = [];
                data_struct.labels = struct(); data_struct.labels.empty = '';
            elseif nargin == 1
                data_struct = varargin{1};
            elseif nargin == 2
                data_struct = struct();
                data_struct.data = varargin{1}; 
                data_struct.labels = varargin{2};
            else
                error('Wrong number of inputs');
            end
            
            if isa(data_struct,'DataObject')
                data_struct = obj2struct(data_struct);
            end
            
            obj.validate(data_struct);
            obj.data = data_struct.data;
            obj.labels = data_struct.labels;
            obj.label_fields = fieldnames(obj.labels);
            obj.dtype = get_dtype(obj);
        end
        
        %{
            indexing functions
        %}
        
        %   function used in subsref to index the object -- return an
        %   object that only contains values and labels associated with
        %   true values in ind
        
        function obj = index(obj, ind)
            fields = obj.label_fields;
            obj.data = obj.data(ind,:);
            for i = 1:numel(fields)
                obj.labels.(fields{i}) = obj.labels.(fields{i})(ind);
            end
        end
        
        %   Return an index of where the obj equals the labels in <labels>.
        %   Within a label-field, indices are OR indices; across label-fields,
        %   indices are AND indices. E.g., if calling obj.where({a,b,c}),
        %   and a and b are associated with 'heights', and c is associated
        %   with 'weights', then the returned index will be true where the
        %   ( obj == a OR obj == b ) AND ( obj == c )
        
        function allinds = where(obj, labels)
            labels = cell_if_not_cell(obj, labels);
            
            assert( iscellstr(labels), 'Labels must be a cell array of strings' );
            
            foundlabels = layeredstruct( {obj.label_fields}, {} );
            
            %{
                identify which label fields are present
            %}
            
            for i = 1:numel(labels)
                [~, field] = obj == labels{i};
                if isempty( field{1} )  %   if we can't find one of the labels,
                                        %   the entire index is false by
                                        %   definition
                    allinds = false( count(obj,1), 1 ); return;
                end
                foundlabels.( field{1} ) = [foundlabels.( field{1} ) labels{i}];
            end
            
            %{
                remove empty fields (<label> could not be found)
            %}
            
            for i = 1:numel(obj.label_fields)
                if ( isempty( foundlabels.(obj.label_fields{i}) ) )
                    foundlabels = rmfield(foundlabels, obj.label_fields{i});
                end
            end
            
            validfields = fieldnames(foundlabels);
            
            allinds = true( count(obj,1), 1 );
            for i = 1:numel(validfields)
                current = foundlabels.(validfields{i});
                within_field = false( count(obj,1), 1 );
                for j = 1:numel(current)
                    within_field = within_field | obj == current{j};
                end
                allinds = allinds & within_field;
            end
        end
        
        %   - remove elements that equal <label>
        
        function obj = remove(obj, labels)
            
            for i = 1:numel(labels)
                ind = obj == labels{i};
                
                if ( ~any(ind) || isempty(obj) ); continue; end;
                
                obj = index(obj, ~ind);
            end

        end
        
        %   - only retain elements associated with <labels>. Within a
        %   label-field, indices are OR indices; across label-fields,
        %   indices are AND indices. E.g., if calling obj.only({a,b,c}),
        %   and a and b are associated with 'heights', and c is associated
        %   with 'weights', then the returned object will contain elements
        %   that match EITHER a or b, AND c
        
        function obj = only(obj, labels)
            allinds = where(obj, labels);
            
            obj = index(obj, allinds);
            
            if ( isempty(obj) ); fprintf('\nObject is empty\n\n'); end;
        end
        
        %   return <indices> of all the unique combinations of unique
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
        
       	%{
            Label handling
        %}
        
        %   - for a given label_field (e.g., 'sessions'), set labels for
        %   that field to <setas>
        
        function obj = setlabels(obj,field,setas,index)
            
            setas = cell_if_not_cell(obj, setas);
            
            if nargin < 4
                if ( length(setas) == 1 ) ...
                        || ( length(setas) == count(obj,1) ) ...
                        || ( length(setas) == 1 );
                    
                    index = true( count(obj,1), 1 );
                    
                else
                    error(['You must supply an index to assign values, unless you' ...
                        , ' are assigning all labels in a field to a single value']);
                end
            end

            if ~islabelfield(obj,field)
                error('Desired field %s does not exist',field);
            end
            
            labels = obj.labels;            %#ok<PROPLC>
            labels.(field)(index) = setas;  %#ok<PROPLC>
            
            obj.labels = labels;            %#ok<PROPLC>
        end
        
        %   - add any number of fields to the object
        
        function obj = addfield(obj,fields)
            fields = cell_if_not_cell(obj,fields);
            
            for i = 1:numel(fields)
                field = fields{i};
                add_one_field();
            end
            
            function add_one_field()
                labels = repmat({''},count(obj,1),1); %#ok<PROPLC>

                if any(strcmp(field,obj.label_fields))
                    error('The field ''%s'' already exists in the object.', field);
                end

                obj.labels.(field) = labels; %#ok<PROPLC>
                obj.label_fields{end+1} = field;
            end
        end
        
        %   - remove fields one at a time
        
        function obj = rmfield(obj,field)
            
            if ~islabelfield(obj,field)
                error('The field ''%s'' is not in the object',field)
            end
            
            matches_field = strcmp(obj.label_fields,field);
            obj.label_fields(matches_field) = [];
            
            labs = struct();
            
            for i = 1:length(obj.label_fields)
                labs.(obj.label_fields{i}) = obj.labels.(obj.label_fields{i});
            end
            
            obj.labels = labs;
        end
        
        %   - rename a field
        
        function obj = renamefield(obj, orig, new)
            assert(all( [ischar(orig), ischar(new)] ), ['Old and new fields' ...
                , ' must be input as strings']);
            
            current = getfield(obj, orig);
            obj = rmfield(obj, orig);
            obj = addfield(obj, new);
            obj.labels.(new) = current;
        end
        
        %   - get the <labels> associated with field
        
        function labels = getfield(obj, field)
            assert(any(strcmp(obj.label_fields, field)), sprintf(['The requested field' ...
                , ' ''%s'' is not in the object'],field));
            
            labels = obj.labels.(field);
        end
        
        %   - replace elements that equal <values> with <with>
        
        function obj = replace(obj, values, with)
            values = cell_if_not_cell(obj, values);
            
            assert(iscellstr(values), 'Labels must be a cell array of strings');
            assert(ischar(with), 'Must replace <x> with a string');
            
            labels = obj.labels; %#ok<PROPLC>
            
            replacements = 0;
            
            for i = 1:numel(values)
                [ind, field] = obj == values{i};
                
                if ~any(ind); fprintf('\nCouln''t find %s\n', values{i}); continue; end;
                
                current = labels.(field{1}); %#ok<PROPLC>
                
                current(ind) = {with};
                
                labels.(field{1}) = current; %#ok<PROPLC>
                
                replacements = replacements + sum(ind);
            end
            
            fprintf('\nMade %d replacements\n', replacements);
            
            obj.labels = labels; %#ok<PROPLC>
        end
        
        %   - find label <value>, remove the character at index <at>, and
        %   replace it with string <with>. If <at> is greater than the len
        %   of the value, no changes will be made
        
        function obj = replaceat(obj, value, with, at)
            assert(ischar(value), 'The value to replace must be a string');
            assert(ischar(with), 'Must replace <x> with a string');
            assert(at > 0, 'Index must be greater than 0');
            
            labels = obj.labels; %#ok<PROPLC>
            
            [ind, field] = obj == value;
            
            if ~any(ind); fprintf('\nCouldn''t find %s\n', value); return; end;
            
            current = labels.(field{1})(ind);
            
            for i = 1:numel(current)
                if ( length(current{i}) < at ); continue; end;
                if ( at == 1 ); current{i} = [with current{i}(2:end)]; continue; end;
                if ( length(current{i}) == at )
                    current{i} = [current{i}(1:at-1) with];
                end
                
                current{i} = [current{i}(1:at-1) with current{i}(at+1:end)];
            end
            
            obj.labels.(field{1})(ind) = current;
        end
        
        %   - make the labels lowercase
        
        function obj = lower(obj, fields)
            if ( nargin < 2 ); fields = obj.label_fields; end;
            fields = cell_if_not_cell(obj, fields);
            
            for i = 1:numel(fields)
                obj.labels.(fields{i}) = ...
                    cellfun(@(x) lower(x), obj.labels.(fields{i}), 'UniformOutput', false);
            end
        end
        
        %   only keep alpha component of labels
        
        function obj = alpha(obj, fields)
            if ( nargin < 2 ); fields = obj.label_fields; end;
            fields = cell_if_not_cell(obj, fields);
            
            for i = 1:numel(fields)
                obj.labels.(fields{i}) = ...
                    cellfun(@(x) x(isstrprop(x, 'alpha')), obj.labels.(fields{i}), ...
                    'UniformOutput', false);
            end
        end
        
        %   create a new label structure using the given <obj>'s label
        %   structure as a template.
        
        function labelstruct = labelbuilder(obj,combinations)
            if ~iscell(combinations)
                error('Combinations must be a cell array');
            end
            
            store_fields = cell(size(combinations));
            
            labelstruct = struct(); 
            obj_labels = obj.labels;
            
            for i = 1:length(combinations)
                [~, field] = obj == combinations{i};
                if ~iscell(field)
                    error('Could not find label ''%s''', combinations{i});
                end
                
                field = char(field);
                
                if i > 1
                    if any(strcmp(store_fields,field))
                        error(['Attempting to build a label structure with multiple' ...
                            , ' labels from the same category is an error']);
                    end
                end
                
                store_fields{i} = field;
                
                labels = unique(obj_labels.(field));
                
                if length(labels) > 1
                    fprintf(['\n\nWarning: there were multiple unique labels associated' ...
                        , ' with field ''%s'''],field);
                end
                
                labelstruct.(field) = combinations(i);
            end
        end
        
        %   - get unique pairs of elements 
        
        function uniqued = pairs(obj, field)
            assert( islabelfield(obj, field), 'The requested field does not exist' );
            alllabs = unique( obj.labels.(field) );
            combs = allcomb( {alllabs, alllabs} );
            
            uniqued = cell(size(combs)); uniqued(1,:) = combs(1,:);
            empty = false( size(uniqued,1),1 );
            
            for i = 2:size(combs,1)
                matchfnc = @(x) sum( strcmp(uniqued, combs(i,x)), 2) >= 1;
                
                matches = matchfnc(1);
                matches = any( matches & matchfnc(2) );
                
                if ( matches ); empty(i) = true; continue; end;  %   the pair already exists
                
                uniqued(i,:) = combs(i,:);
            end
            
            %   remove skipped items and self-self pairs
            
            bothsame = strcmp( uniqued(:,1), uniqued(:,2) );
            
            uniqued( (empty | bothsame),: ) = [];
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
        
        %{
            equality testing / MAIN indexing
        %}
        
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
                
                %   If string begins with *, treat as a wildcard,
                %   and search labels for all strings where the
                %   pattern matches, **regardless of case**
                %   Otherwise, search for the exact string
                
                wildcard = false;

                if strncmpi(wanted_labels{i},'*',1)
                    label = label(2:end);
                    wildcard = true; %%% note
                end
                
                for j = 1:length(search_fields)

                    current_labels = obj.labels.(search_fields{j});
                    
                    %   cellfun method if <wildcard>

                    if wildcard
                        matches_label_field(:,j) = cellfun(@(x) ~isempty(strfind(lower(x),label)),current_labels);
                    else
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
        
        function out = subsref(obj,s)
            current = s(1);
            s(1) = [];

            subs = current.subs;
            type = current.type;

            switch type
                case '.'
                    
                    %   call the function if subs is a method
                    
                    if any(strcmp(methods(obj),subs))
                        func = eval(sprintf('@%s',subs));
                        inputs = [{obj} {s(:).subs{:}}];
                        out = func(inputs{:}); return;
                    end
                    
                    %   otherwise, get the property <subs>
                    
                    out = obj.(subs);
                case '()'
                    ref = subs{1};
                    
                    %   if format is obj('some field')
                    
                    if ischar(ref)
                        out = getfield(obj,ref); return; %#ok<*GFLD>
                    end
                    
                    %   otherwise, filter the data object by a logical
                    %   index
                    
                    %   if format is obj(1) or obj(2)
                    
                    if ( numel(ref) ~= count(obj,1) )
                        ind = false(count(obj,1),1); ind(ref) = true; ref = ind;
                    end
                    
                    out = index(obj, ref);
                otherwise
                    error('Unsupported reference method');
            end

            if isempty(s)
                return;
            end

            out = subsref(out,s);
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
            
            if ~strcmp(obj.dtype,'cell')
                if isa(divisor,'DataObject');
                    divisor = divisor.data;
                end
                obj.data = obj.data ./ divisor; return;
            end
            
            if strcmp(obj.dtype,'cell')
                
                msg = 'Can only divide cell DataObjects by other cell DataObjects';
                
                if ~isa(divisor,'DataObject')
                    error(msg);
                end
                
                if ~strcmp(divisor.dtype,'cell')
                    error(msg);
                end
                
                if ~labeleq(obj,divisor)
                    error('Labels don''t match between numerator and divisor');
                end
                
                if dimensions(obj) ~= dimensions(divisor)
                    error('Dimension mismatch between numerator and divisor');
                end
                
                num = obj.data;
                div = divisor.data;
                
                for i = 1:count(obj,1)
                    for k = 1:count(obj,2)
                        num{i,k} = num{i,k} ./ div{i,k};
                    end
                end
            
            obj.data = num; return;
            
            end
            
        end
        
        %   subtraction
        
        function obj = minus(obj,subtractor)
            if isa(subtractor,'DataObject')
                if ~labeleq(obj,subtractor)
                    error('Labels must be equivalent between objects');
                end
                
                if strcmp(obj.dtype,'double')
                    obj.data = obj.data - subtractor.data; return;
                end
                
                if dimensions(obj) ~= dimensions(subtractor)
                    error(['When subtracting cell arrays,' ...
                        , ' dimensions must be the same']);
                end
                
                if strcmp(obj.dtype,'cell')
                    tosub = obj.data; subtractor = subtractor.data;
                    
                    for i = 1:count(obj,1)
                        for k = 1:count(obj,2)
                            tosub{i,k} = tosub{i,k} - subtractor{i,k};
                        end
                    end
                    
                    obj.data = tosub; return;
                end
            end
            
            obj = obj.data - subtractor; %  obj is no longer a dataobject
            
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
        
        %   data dimensions
        
        function dim = dimensions(obj)
            dim(1) = count(obj,1); dim(2) = count(obj,2);
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
        
        %   -
        %   data manipulation
        %   -
        
        function obj = cellfun(obj, func, varargin)
            params.UniformOutput = true;
            params.OutputObject = true;
            params = parsestruct(params, varargin);
            
            assert(strcmp(obj.dtype,'cell'), ['The object does not contain cell' ...
                , ' array-stored data']);
            
            obj.data = cellfun(func, obj.data, 'uniformoutput', params.UniformOutput);
            if ( params.OutputObject ); return; end;
            obj = obj.data;
        end
        
        function obj = cell2double(obj)
            assert(strcmp(obj.dtype,'cell'), ['The object does not contain cell' ...
                , ' array-stored data']);
            sizes = concatenateData(cellfun(@size, obj.data, 'UniformOutput', false));
            
            for i = 1:size(sizes,2)
                assert(length(unique(sizes(:,i))) == 1, ['Dimensions are not consistent' ...
                    , ' between arrays']);
            end
            
            matrix = zeros(count(obj,1), size(obj.data{1},2));
            
            for i = 1:count(obj,1);
                matrix(i,:) = obj.data{i};
            end
            obj.data = matrix;
            obj.dtype = 'double';
        end
        
        %   -
        %   helpers
        %   -
        
        %   clear the data and labels of an object, but leave its structure
        %   (including label_fields) intact
        
        function obj = flush(obj)
            obj.data = [];
            for i = 1:length(obj.label_fields)
                obj.labels.(obj.label_fields{i}) = [];
            end
            obj.dtype = get_dtype(obj);
        end
        
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
        
        function validate(obj, data_struct)
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
        
        function wanted_labels = cell_if_not_cell(obj, wanted_labels)
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

%             for i = 1:length(S)
%                 is_struct_ref = strcmp(S(i).type,'.');
%                 is_parenth_ref = strcmp(S(i).type,'()');
%                 if is_struct_ref
%                     obj = obj.(S(i).subs);
%                 end
%                 
%                 %   return a field of labels with parenthetical reference
%                 
%                 if is_parenth_ref && ~strcmp(S(i).subs{1},':') && ischar(S(i).subs{1})
%                     labels = obj.labels; %#ok<PROPLC>
%                     obj = labels.(S(i).subs{1}); return; %#ok<PROPLC>
%                 end
%                 
%                 %   otherwise, return a new data object
%                 
%                 if is_parenth_ref && length(S(i).subs) == 1
%                     indexed = obj2struct(obj);
%                     obj = DataObject(index_obj(indexed,S(i).subs{1}));
%                 elseif is_parenth_ref && strcmp(S(i).subs{1},':')
%                     indexed = obj2struct(obj); indexed.data = indexed.data(:,S(i).subs{2});
%                     obj = DataObject(indexed);
%                 elseif is_parenth_ref && strcmp(S(i).subs{2},':')
%                     ind = false(count(obj,1),1); ind(S(i).subs{1}) = true;
%                     obj = DataObject(index_obj(obj2struct(obj),ind));
%                 elseif is_parenth_ref && length(S(i).subs) == 2
%                     ind = false(count(obj,1),1); ind(S(i).subs{1}) = true;
%                     indexed = index_obj(obj2struct(obj),ind);
%                     indexed.data = indexed.data(:,S(i).subs{2});
%                     obj = DataObject(indexed);
%                 end
%             end
%         end