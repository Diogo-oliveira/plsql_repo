CREATE OR REPLACE VIEW V_REF_SPEC_INST_DCS AS
SELECT i.id_institution,
       i.code_institution,
			 d.id_department,
       d.abbreviation dep_abbr,
       d.code_department,
       d.id_dept,
       cs.id_clinical_service,
       cs.code_clinical_service,
       dcs.id_dep_clin_serv,       
       psdcs.id_external_sys,
       psdcs.flg_default,
       psdcs.flg_availability,
       psdcs.flg_spec_dcs_default,
       psdcs.flg_visible_orig,
			 -- specialities
       s.id_speciality,
       s.id_parent,
       s.code_speciality,
       s.gender,
       s.age_min,
       s.age_max,
       rsmt.id_market
  FROM p1_spec_dep_clin_serv psdcs
  JOIN dep_clin_serv dcs
    ON (psdcs.id_dep_clin_serv = dcs.id_dep_clin_serv)
  JOIN department d
    ON (d.id_department = dcs.id_department)
  JOIN clinical_service cs
    ON (cs.id_clinical_service = dcs.id_clinical_service)
	JOIN institution i
    ON (i.id_institution = d.id_institution)
  JOIN p1_speciality s
    ON (s.id_speciality = psdcs.id_speciality)
  JOIN ref_spec_market rsmt
    ON (rsmt.id_speciality = s.id_speciality AND rsmt.id_market = i.id_market)
 WHERE dcs.flg_available = 'Y'
   AND d.flg_available = 'Y'
   AND cs.flg_available = 'Y'
   AND s.flg_available = 'Y'
   AND rsmt.flg_available = 'Y'
   AND d.id_institution NOT IN (SELECT rsi.id_institution
                                  FROM ref_spec_institution rsi
                                 WHERE rsi.id_institution = d.id_institution
                                   AND rsi.flg_available = 'N'
                                   AND rsi.id_speciality = s.id_speciality);