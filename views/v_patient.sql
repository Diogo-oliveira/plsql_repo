-->V_PATIENT
CREATE OR REPLACE VIEW V_PATIENT AS
SELECT p.id_patient,
       p.name,
       p.middle_name,
       p.last_name,
       p.nick_name,
       p.gender,
       p.dt_birth,
       pk_patient.get_pat_short_name(p.id_patient) short_name,
       psa.marital_status,
       psa.address,
       psa.location,
       psa.district,
       psa.zip_code,
       psa.id_country_address,
       psa.id_country_nation,
       country_nation.code_country,
       country_nation.alpha2_code,
       psa.num_main_contact,
       psa.num_contact,
       psa.flg_job_status,
       psa.father_name,
       psa.mother_name,
       psa.id_isencao,
       psa.dt_isencao,
       psa.id_scholarship,
       psa.id_religion,
       pci.reason_type care_inst_reason_type,
       pci.reason care_inst_reason,
       pci.dt_begin_tstz care_inst_dt_begin_tstz,
       pci.id_institution_enroled care_inst_id_inst_enroled
  FROM patient p, pat_soc_attributes psa, country country_nation, patient_care_inst pci
 WHERE p.id_patient = psa.id_patient(+)
   AND psa.id_country_nation = country_nation.id_country(+)
   AND pci.id_patient(+) = p.id_patient;

--V_PATIENT
CREATE OR REPLACE VIEW V_PATIENT AS
SELECT p.id_patient,
       p.name,
       p.middle_name,
       p.last_name,
       p.nick_name,
       p.gender,
       p.dt_birth,
       pk_patient.get_pat_short_name(p.id_patient) short_name
  FROM patient p;

-- CHANGED BY: Bruno Martins
-- CHANGED DATE: 2009-05-29
-- CHANGED REASON: ADT-862
drop view alert.v_patient;
  -- CHANGE END: Bruno Martins