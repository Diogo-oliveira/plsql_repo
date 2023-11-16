-->v_prof_institution
create or replace view v_prof_institution as
SELECT id_prof_institution, id_professional, id_institution, num_mecan, flg_state, dt_begin_tstz, dt_end_tstz
  FROM prof_institution
 WHERE dt_end_tstz IS NULL;

-- CHANGED BY: Telmo Castro
-- CHANGE DATE: 12-03-2010
-- CHANGE REASON: SCH-386
 CREATE OR REPLACE VIEW V_PROF_INSTITUTION AS
SELECT pi.id_prof_institution,
       pi.id_professional,
       pi.id_institution,
       pi.num_mecan,
       pi.flg_state,
       pi.dt_begin_tstz,
       pi.dt_end_tstz,
       pi.flg_schedulable
  FROM prof_institution pi
 WHERE dt_end_tstz IS NULL;
-- CHANGE END: Telmo Castro


CREATE OR REPLACE VIEW V_PROF_INSTITUTION AS
SELECT pi.id_prof_institution,
       pi.id_professional,
       pi.id_institution,
       pi.num_mecan,
       pi.flg_state,
       pi.dt_begin_tstz,
       pi.dt_end_tstz,
       pi.flg_schedulable,
			 pi.flg_type,
			 pi.flg_external
  FROM prof_institution pi
 WHERE dt_end_tstz IS NULL;


CREATE OR REPLACE VIEW V_PROF_INSTITUTION AS
SELECT pi.id_prof_institution,
       pi.id_professional,
       pi.id_institution,
       pi.num_mecan,
       pi.flg_state,
       pi.dt_begin_tstz,
       pi.dt_end_tstz,
       pi.flg_schedulable,
       pi.flg_type,
       pi.flg_external,
       pi.work_schedule_amb,
       pi.work_schedule_inp,
       pi.work_schedule_other,
       pi.flg_sus_app,
       pi.id_professional_bond
  FROM prof_institution pi
 WHERE dt_end_tstz IS NULL;

CREATE OR REPLACE VIEW V_PROF_INSTITUTION AS
SELECT pi.id_prof_institution,
       pi.id_professional,
       pi.id_institution,
       pi.num_mecan,
       pi.flg_state,
       pi.dt_begin_tstz,
       pi.dt_end_tstz,
       pi.flg_schedulable,
       pi.flg_type,
       pi.flg_external,
       pi.work_schedule_amb,
       pi.work_schedule_inp,
       pi.work_schedule_other,
       pi.flg_sus_app,
       pi.id_professional_bond,
       pi.contact_detail
  FROM prof_institution pi
 WHERE dt_end_tstz IS NULL;