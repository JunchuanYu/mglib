; docformat = 'rst'

;+
; 2-dimensional table of heterogeneous columns.
;
; Should have:
;   * basic read/write capability from/to CSV, Markdown, reStructured Text
;   * print to screen nicely (including using ... for too many rows, etc.)
;   * create new tables by indexing
;   * easily get underlying data
;   * allow each column to be a different type
;
; :Properties:
;   data : type=2d array or array of structures
;     data to present
;   types : type=lonarr(n_columns)
;   column_names : type=strarr
;     names of columns of the table
;-


;= helper methods

;+
; Helper method to subset an array of structures because some array indexing
; methods don't work on the columns.
;
; :Private:
;
; :Returns:
;   array of structures
;
; :Params:
;   data : in, required, type=array of structures
;     array of structures to subset
;   cols : in, required, type=lonarr
;     indices of the columns to extract
;   is_range : in, required, type=boolean
;     whether the `rows` parameter is an index array or `lonarr(3)`
;     representing `[start:stop:stride]`
;   rows : in, required, type=lonarr
;     index array or `lonarr(3)` representing `[start:stop:stride]`
;-
function mg_table::_subset_struct, data, cols, is_range, rows
  compile_opt strictarr

  tags = tag_names(data)
  for c = 0L, n_elements(cols) - 1L do begin
    if (c eq 0L) then begin
      s = create_struct(tags[c], data[0].(cols[c]))
    endif else begin
      s = create_struct(s, tags[c], data[0].(cols[c]))
    endelse
  endfor

  if (is_range) then begin
    _rows = rows
    if (rows[1] lt 0) then _rows[1] += self.n_rows
    n_rows = ceil((abs(_rows[1] - _rows[0]) + 1L) / abs(float(_rows[2])))
  endif else begin
    n_rows = n_elements(rows)
  endelse
  struct = replicate(s, n_rows)

  if (is_range) then begin
    for c = 0L, n_elements(cols) - 1L do begin
      struct.(c) = (data.(cols[c]))[rows[0]:rows[1]:rows[2]]
    endfor
  endif else begin
    for c = 0L, n_elements(cols) - 1L do struct.(c) = (data.(cols[c]))[rows]
  endelse

  return, struct
end


;+
; Ingest new data into the table.
;
; :Private:
;
; :Params:
;   data : in, required, type=2d numeric array/array of structures
;     data represented by table
;-
pro mg_table::_ingest, data
  compile_opt strictarr

  *self.data = data

  type = size(data, /type)
  dims = size(data, /dimensions)

  if (type eq 8L) then begin
    self.n_columns = n_tags(data)
    self.n_rows = n_elements(data)
    *self.types = lonarr(self.n_columns)
    for c = 0L, self.n_columns - 1L do (*self.types)[c] = size(data.(c), /type)
    *self.column_names = tag_names(data)
  endif else begin
    self.n_columns = dims[0]
    self.n_rows = dims[1]
    *self.types = lonarr(self.n_columns) + type
    *self.column_names = !null
  endelse
end


;= overload methods

;+
; There are several indexing modes depending on the type of data represented by
; the table.
;
; Tables representing a 2-dimensional array can use all the normal
; 2-dimensional accessing methods to return a new table. For example, if we
; define a table with::
;
;   IDL> t = mg_table(findgen(10, 100))
;
; Then we can index it like::
;
;   IDL> help, t[0:3, *]
;   T               MG_TABLE  = <4 columns, 100 rows>
;   IDL> help, t[[0, 1, 5], 0:9:2]
;   T               MG_TABLE  = <3 columns, 5 rows>
;
; Single elements access, returns the data value instead of a new table::
;
;   IDL> print, t[3, 20]
;         0.00000
;
; Tables representing an array of structures can use the same indexing methods,
; but may also use `COLUMN_NAMES` to refer to the columns of the table. For
; example, define `s` as this::
;
;   data = [{price: 850000.0, rooms: 4, neighborhood: 'Queen Anne'}, $
;           {price: 700000.0, rooms: 3, neighborhood: 'Fremont'}, $
;           {price: 650000.0, rooms: 3, neighborhood: 'Wallingford'}, $
;           {price: 600000.0, rooms: 2, neighborhood: 'Fremont'}]
;   s = mg_table(data, column_names=['price', 'rooms', 'neighborhood'])
;
; Then, we can index like this::
;
;   IDL> help, s[['price', 'neighborhood'], *]
;   S               MG_TABLE  = <2 columns, 4 rows>
;
; If only columns are indexed (with either indices or string names), with no
; row indexing, then a structure will be returned::
;
;   IDL> help, s[['price', 'neighborhood']]
;   <Expression>    STRUCT    = -> <Anonymous> Array[4]
;   IDL> help, s[[0, 1]]
;   <Expression>    STRUCT    = -> <Anonymous> Array[4]
;   IDL> help, s[0:1]
;   <Expression>    STRUCT    = -> <Anonymous> Array[4]
;
; If only a single colum is indexed this way, the values are returned::
;
;   IDL> help, s['price']
;   <Expression>    FLOAT     = Array[4]
;   IDL> help, s[0]
;   <Expression>    FLOAT     = Array[4]
;-
function mg_table::_overloadBracketsRightSide, is_range, sub1, sub2
  compile_opt strictarr

  if (n_elements(sub2) eq 0L) then begin
    _is_range = [is_range[0], 1L]
    _sub2 = [0L, self.n_rows - 1L, 1L]
  endif else begin
    _is_range = is_range
    _sub2 = sub2
  endelse

  if (size(*self.data, /type) eq 8) then begin
    if (size(sub1, /type) eq 7) then begin
      n_matches = mg_match(*self.column_names, sub1, $
                           a_matches=column_indices, $
                           b_matches=sub_matches)
      column_indices = column_indices[sort(sub_matches)]
    endif else begin
      if (_is_range[0]) then begin
        column_indices = (lindgen(self.n_columns))[sub1[0]:sub1[1]:sub1[2]]
      endif else begin
        column_indices = sub1
      endelse
    endelse
    new_data = self->_subset_struct(*self.data, column_indices, _is_range[1], _sub2)
    new_column_names = (*self.column_names)[column_indices]
  endif else begin
    case 1 of
      _is_range[0] && _is_range[1]: begin
          new_data = (*self.data)[sub1[0]:sub1[1]:sub1[2], $
                                  _sub2[0]:_sub2[1]:_sub2[2]]
        end
      _is_range[0]: new_data = (*self.data)[sub1[0]:sub1[1]:sub1[2], _sub2]
      _is_range[1]: new_data = (*self.data)[sub1, _sub2[0]:_sub2[1]:_sub2[2]]
      else: new_data = (*self.data)[sub1, _sub2]
    endcase
    new_column_names = n_elements(*self.column_names) eq 0L $
                         ? !null $
                         : (_is_range[0] $
                              ? (*self.column_names)[sub1[0]:sub1[1]:sub1[2]] $
                              : (*self.column_names)[sub1])
  endelse

  if (n_elements(sub2) eq 0L) then begin
    if (n_elements(new_column_names) eq 1L) then begin
      return, new_data.(0)
    endif else return, new_data
  endif else begin
    single_element = (n_elements(new_data) eq 1) $
                        && (size(new_data, /type) ne 8 || n_elements(new_data.(0)) eq 1)
    if (single_element) then begin
      return, size(new_data, /type) eq 8 ? new_data[0].(0) : new_data[0, 0]
    endif else begin
      new_table = mg_table(new_data, column_names=new_column_names)
      return, new_table
    endelse
  endelse
end


;+
; Returns helpful string for `HELP`.
;
; :Examples:
;   For example::
;
;     IDL> help, df
;     DF              MG_TABLE  = <3 columns, 4 rows>
;
; :Returns:
;   string
;
; :Params:
;   varname : in, required, type=string
;     name of variable to retrieve `HELP` for
;-
function mg_table::_overloadHelp, varname
  compile_opt strictarr

  _type = 'MG_TABLE'
  _specs = string(self.n_columns, self.n_rows, format='(%"<%d columns, %d rows>")')
  return, string(varname, _type, _specs, format='(%"%-15s %-9s = %s")')
end


;+
; Returns string used by `PRINT`.
;
; :Examples:
;   For example::
;
;     IDL> print, df
;             price    rooms  neighborhood
;     ============= ======== =============
;           850000.        4    Queen Anne
;           700000.        3       Fremont
;           650000.        3   Wallingford
;           600000.        2       Fremont
;-
function mg_table::_overloadPrint
  compile_opt strictarr

  formats = (self._default_formats)[*self.types]
  format_lengths = (self._default_format_lengths)[*self.types]

  print_header = n_elements(*self.column_names) gt 0L
  if (print_header) then begin
    format_lengths >= (strlen(*self.column_names) + 1)
    header_format = '(%"' + strjoin('%' + strtrim(format_lengths, 2) + 's', ' ') + '")'
    line = strarr(self.n_columns)
    for c = 0L, self.n_columns - 1L do begin
      line[c] = strjoin(strarr(format_lengths[c]) + '=')
    endfor
  endif

  print_ellipses = 0B

  ; TODO: handle complex types
  data_format = '(%"' + strjoin('%' + strtrim(format_lengths, 2) + formats, ' ') + '")'

  if (self.n_rows gt self.n_printable_rows) then begin
    print_ellipses = 1B
    ellipses_format = '(%"' + strjoin('%' + strtrim(format_lengths, 2) + 's', ' ') + '")'
    ellipses = strarr(self.n_columns) + '...'
    if (size(*self.data, /type) eq 8) then begin
      data_subset = (*self.data)[0:self.n_printable_rows - 1]
    endif else begin
      data_subset = (*self.data)[*, 0:self.n_printable_rows - 1]
    endelse
  endif else data_subset = *self.data
  result = strarr(2 * print_header + (self.n_rows < self.n_printable_rows) + print_ellipses)
  if (print_header) then begin
    result[0:1] = [string(*self.column_names, format=header_format), $
                   string(line, format=header_format)]
    result[2] = string(data_subset, format=data_format)
  endif else begin
    result[0] = string(data_subset, format=data_format)
  endelse
  if (print_ellipses) then result[-1] = string(ellipses, format=ellipses_format)
  return, transpose(result)
end


;+
; Returns dimensions, used by `N_ELEMENTS` and `SIZE`.
;
; :Returns:
;   lonarr(2)
;-
function mg_table::_overloadSize
  compile_opt strictarr

  return, [self.n_columns, self.n_rows]
end


;= property access

;+
; Get properties.
;-
pro mg_table::getProperty, data=data, types=types, column_names=column_names, $
                           n_columns=n_columns, n_rows=n_rows
  compile_opt strictarr

  if (arg_present(data)) then data = *self.data
  if (arg_present(types)) then types = *self.types
  if (arg_present(column_names)) then column_names = *self.column_names
  if (arg_present(n_columns)) then n_columns = self.n_columns
  if (arg_present(n_rows)) then n_rows = self.n_rows
end


;+
; Set properties.
;-
pro mg_table::setProperty, data=data, column_names=column_names
  compile_opt strictarr

  if (n_elements(data) gt 0L) then self->_ingest, data
  if (n_elements(column_names) gt 0L) then *self.column_names = column_names
end


;= lifecycle methods

;+
; Free table resources.
;-
pro mg_table::cleanup
  compile_opt strictarr

  ptr_free, self.data, self.types, self.column_names
end


;+
; Create a table object;
;
; :Params:
;   data : in, required, type=2d numeric array/array of structures
;     data represented by table
;
; :Keywords:
;   _extra : in, optional, type=keywords
;     keywords accepted by `setProperty`
;-
function mg_table::init, data, _extra=e
  compile_opt strictarr

  self.n_printable_rows = 20

  self._default_formats = ['', 'd', 'd', 'd', $
                           '.6g', '.8g', '(%13.6g,%13.6g)', 's', $
                           '', '(%16.8g,%16.8g)', 'lu', 'lu', $
                           'u', 'u', 'lld', 'llu']
  self._default_format_lengths = [0, 4, 8, 12, 13, 16, 29, 10, $
                                  0, 35, 12, 12, 8, 12, 22, 22]

  self.data = ptr_new(/allocate_heap)
  self.types = ptr_new(/allocate_heap)
  self.column_names = ptr_new(/allocate_heap)

  self->_ingest, data

  self->setProperty, _extra=e
  return, 1
end


;+
; Define the table class.
;-
pro mg_table__define
  compile_opt strictarr

  !null = {mg_table, inherits IDL_Object, $
           _default_formats: strarr(16), $
           _default_format_lengths: lonarr(16), $
           n_printable_rows: 0L, $
           data: ptr_new(), $
           n_columns: 0L, $
           n_rows: 0L, $
           types: ptr_new(), $
           column_names: ptr_new()}
end


; main-level example program

print, format='(%"# Simple array")'
iris = mg_learn_dataset('iris')
df = mg_table(iris.data, column_names=iris.feature_names)
help, df
print, n_elements(df), format='(%"n_elements(df) = %d")'
print, strjoin(strtrim(size(df), 2), ', '), format='(%"size(df) = [%s]")'
print, df

print, format='(%"\n# Subtable of simple array")'
new_df = df[[0, 3], 0:49]
help, new_df
print, n_elements(new_df), format='(%"n_elements(new_df) = %d")'
print, strjoin(strtrim(size(new_df), 2), ', '), format='(%"size(new_df) = [%s]")'
print, new_df
obj_destroy, new_df

obj_destroy, df

print, format='(%"\n# Array of structures")'
data = [{price: 850000.0, rooms: 4, neighborhood: 'Queen Anne'}, $
        {price: 700000.0, rooms: 3, neighborhood: 'Fremont'}, $
        {price: 650000.0, rooms: 3, neighborhood: 'Wallingford'}, $
        {price: 600000.0, rooms: 2, neighborhood: 'Fremont'}]
df = mg_table(data, column_names=['price', 'rooms', 'neighborhood'])
help, df
print, n_elements(df), format='(%"n_elements(df) = %d")'
print, strjoin(strtrim(size(df), 2), ', '), format='(%"size(df) = [%s]")'
print, df

print, format='(%"\n# Subtable of array of structures")'
print, strjoin(df['neighborhood'], ', '), format='(%"Neighborhoods: %s")'
new_df = df[['neighborhood', 'price'], *]
help, new_df
print, n_elements(new_df), format='(%"n_elements(new_df) = %d")'
print, strjoin(strtrim(size(new_df), 2), ', '), format='(%"size(new_df) = [%s]")'
print, new_df

obj_destroy, df

venus_filename = filepath('VenusCraterData.csv', subdir=['examples', 'data'])

end