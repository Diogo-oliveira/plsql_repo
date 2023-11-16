-- CHANGED BY: Ana Monteiro
-- CHANGED DATE: 2012-JAN-09
-- CHANGED REASON: ALERT-211941
CREATE OR REPLACE VIEW V_REFERRAL_PAT_SHORT AS
SELECT DISTINCT exr.id_patient id_patient, 
                exr.id_inst_orig id_inst_orig, 
                exr.id_inst_dest id_inst_dest, 
                p.name name, 
                p.gender gender, 
                p.dt_birth, 
                psa.address address, 
                psa.zip_code postal_code, 
                psa.location locality, 
                cn.code_country country_nationality_code, -- 
                cn.alpha2_code code_country_nationality, 
                ca.code_country country_address_code, -- 
                ca.alpha2_code code_country_address 
  FROM p1_external_request exr 
  JOIN patient p 
    ON (exr.id_patient = p.id_patient) 
  LEFT JOIN contact c 
    ON (p.id_person = c.id_contact_entity) 
  LEFT JOIN contact_address_pt ca_pt 
    ON (ca_pt.id_contact_address_pt = c.id_contact) 
  LEFT JOIN district d 
    ON (d.id_district = ca_pt.id_district) 
  LEFT JOIN pat_soc_attributes psa 
    ON (psa.id_patient = p.id_patient AND psa.id_institution = 0) 
  LEFT JOIN country ca 
    ON (ca.id_country = psa.id_country_address AND ca.flg_available = 'Y') 
  LEFT JOIN country cn 
    ON (cn.id_country = psa.id_country_nation AND cn.flg_available = 'Y');