classdef DBManager
  
  properties
    outerfolder = '';
    filename = '';
    dbpath = '';
    conn = [];
    cursor = [];
  end
  
  methods
    function obj = DBManager(outerfolder, filename)
      assert( isa(outerfolder, 'char'), ['Outerfolder must be a string; was a' ...
        , ' ''%s'''], class(outerfolder) );
      assert( isa(filename, 'char'), ['Filename must be a string; was a' ...
        , ' ''%s'''], class(filename) );
      DBManager.validate__directory( outerfolder );
      obj.outerfolder = outerfolder;
      obj.filename = filename;
      obj.dbpath = fullfile( obj.outerfolder, obj.filename );
    end
    
    %{
        CREATION + CONNECTION
    %}
    
    function obj = connect(obj, flag)
      
      %   CONNECT -- Connect to the object's database.
      %
      %     Will re-validate the outerfolder. Will throw an error if the
      %     specified database file does not exist, unless flag is true. 
      %     If any warnings occur when creating the connection, the 
      %     warnings will be printed.
      %
      %     IN:
      %       - `flag` (logical) |SCALAR| -- If true, `connect()` will
      %         *not* verify that the filename in `obj.filename` exists.
      %         Connecting to a nonexistent file will create a new
      %         database.
      %     OUT:
      %       - `obj` (DBManager) -- Database object with its conn
      %         property updated to reflect the current connection.
      
      if ( nargin < 2 ), flag = false; end;
      DBManager.validate__directory( obj.outerfolder );
      user = '';
      password = '';
      driver = 'org.sqlite.JDBC';
      protocol = 'jdbc';
      subprotocol = 'sqlite';
      resource = obj.dbpath;
      if ( ~flag )
        assert( exist(resource, 'file') == 2, ['The specified file ''%s''' ...
          , ' does not exist. Call create() explicitly to create a new database'], ...
          obj.filename );
      end
      url = strjoin( {protocol, subprotocol, resource}, ':' );
      obj.conn = database( resource, user, password, driver, url );
      if ( ~isempty(obj.conn.Message) )
        if ( isequal(obj.conn.Message, 'Unable to find JDBC driver.') )
          error( ['No JDBC driver is installed; see' ...
            , ' https://www.mathworks.com/help/database/ug/sqlite-jdbc-mac.html'] );
        end
        fprintf( '\n ! DBManager/connect: %s\n', obj.conn.Message );
      end
      set( obj.conn, 'AutoCommit', 'off' );
    end
    
    function obj = create(obj)
      
      %   CREATE -- Create a new database.
      %
      %     Will re-validate the current outerfolder; will ask to overwrite
      %     an existing database.
      %
      %     OUT:
      %       - `obj` (DBManager) -- Database object with its conn
      %         property a connection to the newly created database.
      
      DBManager.validate__directory( obj.outerfolder );
      if ( exist(obj.dbpath, 'file') == 2 )
        prompt = sprintf( ['\n ! DBManager/create: The database ''%s'' already exists.' ...
          , '\n\t Do you wish to overwrite it? (y/n)\n\n'], obj.filename );
        inp = input( prompt, 's' );
        if ( ~isequal(lower(inp), 'y') )
          fprintf( '\n ! DBManager/create: Not overwriting ''%s''\n', obj.filename );
          return;
        else
          fprintf( '\n ! DBManager/create: Overwriting ''%s''\n', obj.filename );
          delete( obj.dbpath );
        end
      end
      obj = connect( obj, true );
    end
    
    %{
        QUERY
    %}
    
    
    function obj = exec(obj, query)
      
      %   EXEC -- Execute a query, and retrieve the results.
      %
      %     IN:
      %       - `query` (char) -- Query to execute.
      %     OUT:
      %       - `obj` (DBManager) -- Object with its cursor property
      %         updated to reflect the executed query.
      
      obj.cursor = exec( obj.conn, query );
      if ( ~isempty(obj.cursor.Message) )
        fprintf( '\n ! DBManager/exec: %s\n', obj.cursor.Message );
      end
    end
    
    function obj = fetch(obj)
      
      %   FETCH -- Get set the object's cursor object to obtain data, after
      %     executing a query.
      %
      %     This does not access the data itself; it only makes the data
      %     available in the cursor object. Call `gather()` to obtain the
      %     actual data.
      %
      %     OUT:
      %       - `obj` (DBManager) -- Object with its cursor property
      %         updated to have fetched data, if it exists.
      
      if ( isequal(obj.cursor, []) ), return; end;
      obj.cursor = fetch( obj.cursor );
    end
    
    function data = gather(obj)
      
      %   GATHER -- Get the actual data obtained from executing a query.
      %
      %     Calls `fetch()`, and then returns the data.
      %
      %     OUT:
      %       - `data` (/any/) -- Data obtained from the query made with
      %       `exec()`.
      
      if ( isequal(obj.cursor, []) ), return; end;
      obj = fetch( obj );
      data = obj.cursor.Data;
    end
    
    function data = exec_and_gather(obj, query)
      
      %   EXEC_AND_GATHER -- Shortcut function to get data immediately
      %     after executing a query.
      %
      %     IN:
      %       - `query` (char) -- Valid SQLITE query.
      %     OUT:
      %       - `data` (cell) -- Result of the query. Note that data will
      %         be a cell with 'No Data' if the query is invalid.
      
      data = gather( exec(obj, query) );
    end
    
    function obj = commit(obj)
      
      %   COMMIT -- Commit changes to the database.
      %
      %     OUT:
      %       - `obj` (DBManager) -- Object with its changes committed.
      
      commit( obj.conn );
    end
    
    function obj = begin(obj)
      
      %   BEGIN -- Begin a transaction.
      
      if ( isequal(obj.cursor, []) ), return; end;
      exec( obj.conn, 'BEGIN;' );
    end
    
    function obj = rollback(obj)
      
      %   ROLLBACK -- Revert to the previous commit.
      
      if ( isequal(obj.cursor, []) ), return; end;
      exec( obj.conn, 'ROLLBACK;' );
    end
    
    function obj = close(obj)
      
      %   CLOSE -- Close the database connection.
      %
      %     If the object's `conn` property is empty, the object is
      %     returned unchanged.
      %
      %     OUT:
      %       - `obj` (DBManager) -- Object with its sqlite database
      %         connection closed.
      
      if ( isequal(obj.conn, []) || isequal(obj.cursor, []) ), return; end;
      close( obj.conn );
      close( obj.cursor );
    end
    
    %{
        MUTATION
    %}
    
    function obj = insert_row(obj, table_name, values)
      
      assert( isa(table_name, 'char'), ['table_name must be a char; was' ...
        , ' a ''%s'''], class(table_name) );
      msg = ['Specify values to insert as a cell array' ...
          , ' of strings, even if some or all of the values are numeric'];
      if ( iscell(values) )
        assert( iscellstr(values), msg );
        n_values = numel(values);
        values = strjoin( values, ',' );
      else
        assert( isa(values, 'char'), msg );
        split_values = strsplit( values, ',' );
        n_values = numel(split_values);
      end
      fs = get_field_names( obj, table_name );
      assert( numel(fs) == n_values, ['Attempted to assign %d column''s' ...
        , ' worth of data, but there are %d columns in the table ''%s'''] ...
        , n_values, numel(fs), table_name );
      query = sprintf( 'INSERT INTO %s (%s) VALUES (%s);', table_name, ...
        strjoin(fs, ','), values );
      obj = exec( obj, query );
    end
    
    %{
        GET DATA
    %}
    
    function row = get_n_rows(obj, table_name)
      
      %   GET_N_ROWS -- Get the current number of rows in the specified
      %     table.
      %
      %     An error is thrown if the table does not exist.
      %
      %     IN:
      %       - `table_name` (char) -- Name of the table to query.
      %     OUT:
      %       - `row` (number) -- Number of rows in the table.
      
      assert( isa(table_name, 'char'), ['Expected table_name to be a string' ...
        , ' was a ''%s'''], class(table_name) );
      assert( tables_exist(obj, table_name), ['The requested table ''%s'' does not exist in' ...
        , ' the database ''%s'''], table_name, obj.filename );
      row = exec_and_gather( obj, sprintf('SELECT count(*) FROM %s', table_name) );
      row = row{1};
    end
    
    function data = get_fields(obj, field_names, table_name)
      
      %   GET_FIELDS -- Get all data in the requested fields.
      %
      %     It is an error to request fields that do not exist. It is an
      %     error to specify a nonexistent table. Specify `field_names` as
      %     '*' to get all fields.
      %
      %     IN:
      %       - `field_names` (cell array of strings, char) -- Field
      %         name(s) from which to draw data. If `field_names` is '*',
      %         all fields will be used.
      %       - `table_name` (char) -- Table from which to draw the data.
      %     OUT:
      %       - `data` (cell array) -- Data in the specified fields.
      
      if ( ~isequal(field_names, '*') )
        field_names = DBManager.ensure_cell( field_names );
        check_existence = fields_exist( obj, field_names, table_name );
        if ( ~all(check_existence) )
          fprintf( '\n%s\n\n', strjoin(unique(field_names), ',') );
          error( 'The above fields do not exist in the table ''%s''', table_name );
        end
        query = sprintf( 'SELECT %s FROM %s', strjoin(field_names, ','), table_name );
      else
        assert( isa(table_name, 'char'), ['Table_name must be a string; was' ...
          , ' a ''%s'''], class(table_name) );
        assert( tables_exist(obj, table_name), ['The specified table ''%s'' does' ...
          , ' not exist'], table_name );
        query = sprintf( 'SELECT * FROM %s', table_name );
      end
      data = exec_and_gather( obj, query );
    end
    
    %{
        CHECK EXISTENCE
    %}
    
    function names = get_field_names(obj, table_name)
      
      %   GET_FIELDS -- Get the fieldnames in a given table.
      %
      %     It is an error to speciy a non-existent table.
      %
      %     IN:
      %       - `table_name` (char) -- Table whose fields are
      %         to-be-obtained.
      %     OUT:
      %       - `names` (cell array of strings) -- Fieldnames in the table.
      
      assert( tables_exist(obj, table_name), ['The table ''%s'' does not exist' ...
        , ' in the file ''%s'''], table_name, obj.filename );
      query = sprintf( 'PRAGMA table_info(%s)', table_name );
      fields = exec_and_gather( obj, query );
      names = fields(:,2);
    end
    
    function names = get_table_names(obj)
      
      %   GET_TABLE_NAMES -- List the names of the tables in the database.
      %
      %     Returns an empty cell array if there are no tables.
      %
      %     OUT:
      %       - `names` (cell array of strings, {}) -- Names of the tables
      %         in the database.
      
      data = exec_and_gather( obj, 'SELECT name FROM sqlite_master WHERE type="table"' );
      names = {};
      if ( isequal(data{1}, 'No Data') ), return; end;
      names = data;
    end
    
    function tf = fields_exist(obj, field_names, table_names)
      
      %   FIELDS_EXIST -- Check if the given fields exist in the database.
      %
      %     For each field name, specify a table name in which to search;
      %     or, if all fields are in the same table, you can specify a
      %     single table name.
      %
      %     Note that it is an error to specify non-existent table-names.
      %
      %     IN:
      %       - `field_names` (cell array of strings, char) -- Field names
      %         to check.
      %       - `table_names` (cell array of strings, char) -- Table
      %         name(s) corresponding to each `field_names`(i). If a char,
      %         or if a cell of length 1, each field_names(i) is assumed to
      %         be located in that `table_name`.
      %     OUT:
      %       - `tf` (logical) -- Index where each `tf`(i) corresponds to
      %         the existence of `field_names`(i).
      
      field_names = DBManager.ensure_cell( field_names );
      table_names = DBManager.ensure_cell( table_names );
      msg = [ 'Expected %s to be a cell array of strings, or a char;' ...
        , ' was a ''%s''' ];
      assert( iscellstr(field_names), msg, 'field_names', class(field_names) );
      assert( iscellstr(table_names), msg, 'table_names', class(table_names) );
      if ( numel(field_names) ~= numel(table_names) )
        assert( numel(table_names) == 1, ['If specifying multiple table_names', ...
          ' the number of table_names must match the number of field_names'] );
        table_names = repmat( table_names, 1, numel(field_names) );
      end
      valid_tables = tables_exist( obj, table_names );
      if ( ~all(valid_tables) )
        fprintf( '\n%s\n\n', strjoin(unique(table_names(~valid_tables))) );
        error( 'The above table-names do not exist' );
      end
      tf = false( 1, numel(field_names) );
      for i = 1:numel(field_names)
        names = get_field_names( obj, table_names{i} );
        tf(i) = any( strcmp(names, field_names{i}) );
      end
    end
    
    function tf = tables_exist(obj, table_names)
      
      %   TABLES_EXIST -- Check if the given tables exist in the database.
      %
      %     IN:
      %       - `table_names` (cell array of strings, char) -- Table
      %         name(s) to check.
      %     OUT:
      %       - `tf` (logical) -- Index where each `tf`(i) corresponds to
      %         the existence of `table_names`(i).
      
      table_names = DBManager.ensure_cell( table_names );
      assert( iscellstr(table_names), ['Table_names can be a cell array of strings' ...
        , ' or a char; was a ''%s'''], class(table_names) );
      tf = false( 1, numel(table_names) );
      for i = 1:numel(tf)
        query = sprintf( ['SELECT name FROM sqlite_master WHERE type="table"' ...
          , ' AND name="%s"'], table_names{i} );
        data = exec_and_gather( obj, query );
        if ( isempty(data) ), continue; end;
        if ( isequal(data{1}, 'No Data') ), continue; end;
        if ( isequal(data{1}, table_names{i}) ), tf(i) = true; end;
      end
    end
    
    function tf = exists_in_field(obj, values, field_name, table_name)
      
      %   EXISTS_IN_FIELD -- Determine whether given values are present in
      %     a field of the table.
      %
      %     IN:
      %       - `values` (cell array of strings, char) -- Values to search
      %       	for. Note that, even for numeric data, values must be
      %       	specified as strings; to search for character values, wrap
      %       	those values in quotes, e.g. '"hi"';
      %       - `field_name` (char) -- Name of the field in which to
      %         search.
      %       - `table_name` (char) -- Name of the table in which to
      %         search.
      %     OUT:
      %       - `tf` (logical) -- True at `tf`(i) if `values`(i) exists in
      %         the specified field of the specified table.
      
      values = DBManager.ensure_cell( values );
      assert( iscellstr(values), [ 'Values can be a string or cell array of strings.' ...
        , ' Specify inputs as strings even if the desired values are numeric' ]);
      msg = 'Expected table_name to be a char; was a ''%s''';
      assert( isa(field_name, 'char'), msg, class(field_name) );
      assert( isa(table_name, 'char'), msg, class(table_name) );
      assert( tables_exist(obj, table_name), 'The table ''%s'' does not exist', ...
        table_name );
      assert( fields_exist(obj, field_name, table_name), ...
        'The field ''%s'' does not exist', field_name );
      tf = false( 1, numel(values) );
      for i = 1:numel(values)
        query = sprintf( 'SELECT * FROM %s where %s=%s;', table_name, ...
          field_name, values{i} );
        obj = exec( obj, query );
        data = gather( obj );
        if ( isequal(data{1}, 'No Data') )
          continue;
        else
          tf(i) = true;
        end
      end
    end
  end
  
  methods (Static = true)
    
    function validate__directory( str )
      
      %   VALIDATE_DIRECTORY -- Validate a path by attempting to change to
      %     it.
      %
      %     IN:
      %       - `str` (char) -- Path to test
      
      assert( isa(str, 'char'), 'Expected path to be a string; was a ''%s''', class(str) );
      orig = cd;
      try
        cd( str ); cd( orig );
      catch
        error( 'Invalid directory ''%s''', str );
      end
    end
    
    function arr = ensure_cell(arr)
      if ( ~iscell(arr) ), arr = { arr }; end;
    end
    
    %{
        STATIC ASSERTIONS
    %}
    
    function assert__file_exists( file )
      
      %   ASSERT__FILE_EXISTS -- Ensure a given file exists.
      %
      %     IN:
      %       - `file` (char) -- Path to the file.
      
      assert( isa(file, 'char'), 'File-path must be a char; was a ''%s''', class(file) );
      assert( exist(file, 'file') == 2, 'The specified file ''%s'' does not exist', ...
        file );
    end
    
    %{
        TEXT FILE READING
    %}
    
    function s = csv_cell_to_struct( file )
      
      %   CSV_CELL_TO_STRUCT -- Parse a comma-delimited text file formatted
      %     as (field, value), and convert into a struct where each (field)
      %     corresponds to each (value).
      %
      %     IN:
      %       - `file` (char) -- Full path to the text file. An error is
      %         thrown if the file does not exist. Errors are thrown if the
      %         text file is not formatted correctly.
      %     OUT:
      %       - `s` (struct) -- Struct containing the fields and values in
      %         `file`.
      
      DBManager.assert__file_exists( file );
      data = DBManager.csv_to_cell (file );
      assert( mod(numel(data)/2, 1) == 0, ['The data are not formatted' ...
        , ' correctly; there must be an even number of comma-separated' ...
        , ' elements, in which odd numbered values are field-names'] );
      %   make column vector
      data = reshape( data(:), 2, numel(data)/2 );
      for i = 1:size(data, 2)
        try
          s.(data{1,i}) = data{2,i};
        catch err
          fprintf( ['\n ! DBManager/csv_cell_to_struct: The following error' ...
            , ' ocurred when attempting to convert a csv-text file to a struct:'] );
          error( err.message );
        end
      end
    end
    
    function data = csv_to_cell( file )
      
      %   CSV_TO_CELL -- Read-in a comma-separated text file.
      %
      %     IN:
      %       - `file` (char) -- Full path to the desired file. The
      %         existence of the file is checked; an error is thrown if the
      %         file does not exist. An error is thrown if the text-file is
      %         not comma-delimited
      %     OUT:
      %       - `data` (cell) -- Comma-separated values stored cell-wise.
      
      DBManager.assert__file_exists( file );
      fid = fopen( file, 'r' );
      data = textscan( fid, '%s', 'Delimiter', ',' );
      fclose( fid );
      data = data{1};
      assert( iscell(data), ['Data were not formatted correctly; specify' ...
        , ' values as comma-separated, and on a single line']);      
    end
    
  end
  
end