-- CHANGED BY: Fábio Oliveira
-- CHANGE DATE: 13/05/2011
-- CHANGE REASON: [ALERT-178899]

UPDATE sys_shortcut
   SET id_sys_shortcut = 10489
 WHERE id_sys_shortcut IN (167324, 167321, 167322, 167323);

UPDATE profile_templ_access
   SET id_sys_shortcut = 10489
 WHERE id_sys_shortcut IN (167324, 167321, 167322, 167323);

UPDATE grid_task gt
   SET gt.supplies = regexp_replace(regexp_replace(regexp_replace(regexp_replace(gt.supplies, '^167324|', '10489|'),
                                                                  '^167323|',
                                                                  '10489|'),
                                                   '^167321|',
                                                   '10489|'),
                                    '^167322|',
                                    '10489|')
 WHERE gt.supplies IS NOT NULL;

COMMIT;

-- CHANGE END: Fábio Oliveira
