-- CHANGED BY: Telmo Castro
-- CHANGE DATE: 05-03-2010
-- CHANGE REASON: SCH_386
CREATE OR REPLACE VIEW V_PROF_DEP_CLIN_SERV AS
SELECT pdcs.id_prof_dep_clin_serv,
       pdcs.id_professional,
       pdcs.id_dep_clin_serv,
       pdcs.flg_status,
       pdcs.flg_default,
       pdcs.id_institution
  FROM prof_dep_clin_serv pdcs;
  
-- CHANGE END: Telmo Castro