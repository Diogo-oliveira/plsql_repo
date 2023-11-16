-- CHANGED BY: João Martins
-- CHANGE DATE: 06/10/2009 18:07
-- CHANGE REASON: [ALERT-48003] Parametrization of wound characteristics' measure units
alter table wound_charac_unit_mea move tablespace table_s;
-- CHANGE END: João Martins