; docformat = 'rst'

function mg_cmp_version_ut::test_builddiffers
  compile_opt strictarr

  cmp = mg_cmp_version('1.1.0+buildinfo', '1.1.0+20141006')

  assert, cmp eq 0, 'incorrect comparison'

  return, 1
end


function mg_cmp_version_ut::test_tie
  compile_opt strictarr

  cmp = mg_cmp_version('1.1', '1.1.0')

  assert, cmp eq 0, 'incorrect comparison'

  return, 1
end


;+
; Compares each item in a list of versions to all items in the list.
;-
function mg_cmp_version_ut::test_basic
  compile_opt strictarr

  versions = ['0.1', '1.0-alpha', '1.0-beta', '1.0-rc1', '1.0-rc2', '1.0', $
              '2.0', '2.0.1', '2.0.2']

  for i = 0L, n_elements(versions) - 1L do begin
    for j = 0L, n_elements(versions) - 1L do begin
      result = mg_cmp_version(versions[i], versions[j])
      expectedResult = (i gt j)  $
                         ? 1 $
                         : ((i lt j) ? -1 : 0)
      assert, result eq expectedResult, $
              string(versions[i], versions[j], expectedResult, result, $
                     format='(%"result of (%s, %s) should be %d, but is %d")')
    endfor
  endfor

  return, 1
end


function mg_cmp_version_ut::test_too_many_parts
  compile_opt strictarr

  result = mg_cmp_version('1.1.0.1', '1.1.0.2', error=error)
  assert, error gt 0L, 'too many version parts not detected'

  return, 1
end


function mg_cmp_version_ut::init, _extra=e
  compile_opt strictarr

  if (~self->MGutLibTestCase::init(_extra=e)) then return, 0

  self->addTestingRoutine, ['mg_cmp_version', $
                            'mg_cmp_version_decompose'], $
                           /is_function

  return, 1
end


;+
; Define member variables.
;-
pro mg_cmp_version_ut__define
	compile_opt strictarr

	define = { mg_cmp_version_ut, inherits MGutLibTestCase }
end
