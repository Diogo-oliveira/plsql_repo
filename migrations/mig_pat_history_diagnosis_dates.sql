UPDATE pat_history_diagnosis phd
   SET phd.dt_diagnosed           = pk_date_utils.get_string_tstz(i_lang      => NULL,
                                                                  i_prof      => profissional(phd.id_professional,
                                                                                              phd.id_institution,
                                                                                              NULL),
                                                                  i_timestamp => nvl2(phd.year_begin,
                                                                                      phd.year_begin ||
                                                                                      nvl2(phd.month_begin,
                                                                                           lpad(phd.month_begin, 2, '0'),
                                                                                           '01') ||
                                                                                      nvl2(phd.day_begin,
                                                                                           lpad(phd.day_begin, 2, '0'),
                                                                                           '01'),
                                                                                      NULL) ||
                                                                                 nvl2(phd.year_begin, '000000', NULL),
                                                                  i_timezone  => NULL),
       phd.dt_diagnosed_precision = nvl2(phd.day_begin, 'D', nvl2(phd.month_begin, 'M', nvl2(phd.year_begin, 'Y', 'H')))
 WHERE phd.year_begin IS NOT NULL
   AND phd.year_begin <> '-1'
   AND phd.dt_diagnosed IS NULL
   AND phd.dt_diagnosed_precision IS NULL;

UPDATE pat_history_diagnosis phd
   SET phd.dt_diagnosed_precision = 'U'
 WHERE phd.year_begin = -1
   AND phd.dt_diagnosed_precision IS NULL;

UPDATE pat_history_diagnosis phd
   SET phd.dt_resolved           = pk_date_utils.get_string_tstz(i_lang      => NULL,
                                                                 i_prof      => profissional(phd.id_professional,
                                                                                             phd.id_institution,
                                                                                             NULL),
                                                                 i_timestamp => decode(length(phd.dt_resolution),
                                                                                       4,
                                                                                       phd.dt_resolution || '0101',
                                                                                       6,
                                                                                       phd.dt_resolution || '01',
                                                                                       phd.dt_resolution) || '000000',
                                                                 i_timezone  => NULL),
       phd.dt_resolved_precision = decode(length(phd.dt_resolution), 4, 'Y', 6, 'M', 8, 'D', 'H')
 WHERE phd.dt_resolution IS NOT NULL
   AND phd.dt_resolution <> 'U'
   AND phd.dt_resolved IS NULL
   AND phd.dt_resolved_precision IS NULL;

UPDATE pat_history_diagnosis phd
   SET phd.dt_resolved_precision = 'U'
 WHERE phd.dt_resolution = 'U'
   AND phd.dt_resolved_precision IS NULL;
