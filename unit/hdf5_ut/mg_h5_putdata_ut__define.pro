function mg_h5_putdata_ut::test_scalar
  compile_opt strictarr

  root = mg_src_root()
  filename = filepath('mg_h5_putdata_test.h5', root=root)
  file_delete, filename, /allow_nonexistent

  standard = 5L

  mg_h5_putdata, filename, 'data', standard

  data = mg_h5_getdata(filename, 'data')

  assert, data eq standard, 'scalar value not correct'
  assert, size(data, /type) eq size(standard, /type), 'scalar type not correct'

  file_delete, filename

  return, 1
end


function mg_h5_putdata_ut::test_data
  compile_opt strictarr

  root = mg_src_root()
  filename = filepath('mg_h5_putdata_test.h5', root=root)
  file_delete, filename, /allow_nonexistent

  standard = findgen(10)

  mg_h5_putdata, filename, 'data', standard

  data = mg_h5_getdata(filename, 'data')

  assert, array_equal(data, standard, /no_typeconv), 'array value not correct'

  file_delete, filename

  return, 1
end


pro mg_h5_putdata_ut__define
  compile_opt strictarr

  define = { mg_h5_putdata_ut, inherits MGutLibTestCase }
end
