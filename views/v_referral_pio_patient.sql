CREATE OR REPLACE VIEW V_REFERRAL_PIO_PATIENT AS
SELECT p.id_patient,
       p.id_inst_orig,
       p.id_inst_dest,
       p.n_sns,
       p.sequential_number,
       p.name,
       p.gender,
       p.dt_birth,
       p.alpha_code_country_nat code_country_nationality, -- alpha2_code nat
       (SELECT pk_translation.get_translation(1, code_country_nat)
          FROM dual) desc_country_nationality, -- desc nat
       p.address,
       p.postal_code,
       p.locality,
       pk_translation.get_translation(1, p.code_district) district,
       p.alpha_code_country_add code_country_address, -- alpha2_code add
       (SELECT pk_translation.get_translation(1, code_country_add)
          FROM dual) desc_country_address -- desc add
  FROM (SELECT DISTINCT pt.id_patient, -- distinct because one patient can have several referrals
                        exr.id_inst_orig,
                        exr.id_inst_dest,
                        php.num_health_plan n_sns,
                        m.sequential_number sequential_number,
                        pt.name,
                        pt.gender,
                        pt.dt_birth,
                        cn.code_country     code_country_nat,
                        cn.alpha2_code      alpha_code_country_nat,
                        psa.address,
                        psa.zip_code        postal_code,
                        psa.location        locality,
                        d.code_district,
                        ca.code_country     code_country_add,
                        ca.alpha2_code      alpha_code_country_add
          FROM p1_external_request exr
          JOIN patient pt
            ON (pt.id_patient = exr.id_patient)
          LEFT JOIN pat_health_plan php
            ON (php.id_patient = exr.id_patient AND php.id_institution IS NULL AND php.flg_status = 'A' AND
               php.id_health_plan =
               to_number(sys_context('ALERT_CONTEXT', 'IDENT_ID_HEALTH_PLAN')))
          LEFT JOIN pat_soc_attributes psa
            ON (psa.id_patient = pt.id_patient AND psa.id_institution = 0)
          LEFT JOIN p1_match m
            ON (pt.id_patient = m.id_patient AND m.id_institution = exr.id_inst_dest AND m.flg_status = 'A')
          LEFT JOIN country ca
            ON (ca.id_country = psa.id_country_address AND ca.flg_available = 'Y')
          LEFT JOIN country cn
            ON (cn.id_country = psa.id_country_nation AND cn.flg_available = 'Y')
          LEFT JOIN contact c
            ON (pt.id_person = c.id_contact_entity)
          LEFT JOIN contact_address_pt ca_pt
            ON (ca_pt.id_contact_address_pt = c.id_contact)
          LEFT JOIN district d
            ON (d.id_district = ca_pt.id_district)) p;
