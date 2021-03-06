; docformat = 'rst'

function mgffncgroup_ut::test_sample
  compile_opt strictarr

  assert, mg_idlversion(require='8.0'), /skip, $
          'test requires IDL 8.0, %s present', !version.release

  f = obj_new('MGffNCFile', filename=file_which('sample.nc'))

  assert, f.groups eq !null, 'incorrect groups'

  obj_destroy, f

  return, 1
end


function mgffncgroup_ut::test_group
  compile_opt strictarr

  assert, mg_idlversion(require='8.0'), /skip, $
          'test requires IDL 8.0, %s present', !version.release

  f = obj_new('MGffNCFile', filename=file_which('ncgroup.nc'))

  assert, array_equal(f.groups, ['Submarine']), $
          'incorrect groups for file'

  g1 = f['Submarine']

  assert, array_equal(g1.groups, ['Diesel_Electric', 'Nuclear']), $
          'incorrect groups for Submarine'

  g2 = g1['Diesel_Electric']

  sub_depth1 = g2['Sub Depth']

  g3 = g1['Nuclear']

  assert, array_equal(g3.groups, ['Attack', 'Missile']), $
          'incorrect groups for Nuclear'

  g4 = g3['Attack']

  sub_depth2 = g4['Sub Depth']

  g5 = g3['Missile']

  sub_depth3 = g5['Sub Depth']

  obj_destroy, f

  return, 1
end


function mgffncgroup_ut::init, _extra=e
  compile_opt strictarr

  if (~self->MGutLibTestCase::init(_extra=e)) then return, 0

  self->addTestingRoutine, ['mgffncgroup__define', $
                            'mgffncgroup::cleanup', $
                            'mgffncgroup::getProperty']
  self->addTestingRoutine, ['mgffncgroup::init', $
                            'mgffncgroup::_overloadBracketsRightSide', $
                            'mgffncgroup::_overloadPrint', $
                            'mgffncgroup::dump', $
                            'mgffncgroup::_overloadHelp', $
                            'mgffncgroup::_getAttribute'], $
                           /is_function

  return, 1
end


pro mgffncgroup_ut__define
  compile_opt strictarr

  define = { MGffNCGroup_ut, inherits MGutLibTestCase }
end
