CREATE OR REPLACE VIEW V_CREATEPROCEDURE_MFR AS
SELECT ris.id_institution,
           rst.id_content,
           NULL id_content_group_procedure,
           rst.code_rehab_session_type code_translation,
           'PM' flg_characteristic,
           NULL duration,
           NULL icd,
           NULL gdh,
           NULL gender,
           NULL agemin,
           NULL agemax,
           se.num_min_profs min_nbr_hresource,
           se.num_max_profs max_nbr_hresource,
           se.num_max_patients number_of_persons,
           CAST(COLLECT(to_number(rdcs.id_dep_clin_serv)) AS table_number) coll_id_dep_clin_serv,
           'A' flg_available
      FROM rehab_session_type rst
      JOIN rehab_dep_clin_serv rdcs
        ON rdcs.id_rehab_session_type = rst.id_rehab_session_type
      JOIN (SELECT DISTINCT id_institution, id_rehab_session_type
              FROM rehab_inst_soft) ris
        ON ris.id_rehab_session_type = rst.id_rehab_session_type
      JOIN sch_event se on DEP_TYPE = 'PM' -- join to sch_event to be able to get the min and max human resources and nr_patients
     GROUP BY ris.id_institution, rst.id_content, rst.code_rehab_session_type,
              se.num_min_profs,
              se.num_max_profs,
              se.num_max_patients;
							
-- CHANGED BY: Nuno Neves
-- CHANGE DATE: 2011-09-07
-- CHANGE REASON: APS-1771
CREATE OR REPLACE VIEW V_CREATEPROCEDURE_MFR AS
SELECT ris.id_institution,
           rst.id_rehab_session_type id_content,--[APS-1759]
           rst.id_content id_content_rst,--[APS-1759]
           NULL id_content_group_procedure,
           rst.code_rehab_session_type code_translation,
           'PM' flg_characteristic,
           NULL duration,
           NULL icd,
           NULL gdh,
           NULL gender,
           NULL agemin,
           NULL agemax,
           se.num_min_profs min_nbr_hresource,
           se.num_max_profs max_nbr_hresource,
           se.num_max_patients number_of_persons,
           CAST(COLLECT(to_number(rdcs.id_dep_clin_serv)) AS table_number) coll_id_dep_clin_serv,
           'A' flg_available
      FROM rehab_session_type rst
      JOIN rehab_dep_clin_serv rdcs
        ON rdcs.id_rehab_session_type = rst.id_rehab_session_type
      JOIN (SELECT DISTINCT id_institution, id_rehab_session_type
              FROM rehab_inst_soft) ris
        ON ris.id_rehab_session_type = rst.id_rehab_session_type
      JOIN sch_event se on DEP_TYPE = 'PM' -- join to sch_event to be able to get the min and max human resources and nr_patients
     GROUP BY ris.id_institution, rst.id_rehab_session_type, rst.id_content, rst.code_rehab_session_type,
              se.num_min_profs,
              se.num_max_profs,
              se.num_max_patients;
-- CHANGE END
