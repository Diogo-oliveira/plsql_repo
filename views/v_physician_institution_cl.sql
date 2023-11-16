CREATE OR REPLACE VIEW V_PHYSICIAN_INSTITUTION_CL AS
SELECT pi.id_prof_institution,
       pi.flg_external,
       pi.id_institution,
       p.id_professional,
       p.name,
       NULL suffix,
       p.first_name,
       p.middle_name,
       p.last_name,
       p.gender,
       p.id_speciality,
       p.title,
       (SELECT pa.value
          FROM prof_accounts pa
         INNER JOIN accounts a
            ON (a.id_account = pa.id_account AND a.flg_available = 'Y')
         WHERE pa.id_professional = p.id_professional
           AND a.id_account = 60) run,
       (SELECT pa.value
          FROM prof_accounts pa
         INNER JOIN accounts a
            ON (a.id_account = pa.id_account AND a.flg_available = 'Y')
         WHERE pa.id_professional = p.id_professional
           AND a.id_account = 61) rut,
       
       NULL calle_type,
       NULL direction_num,
       NULL direction_last,
       p.address,
       p.zip_code postal_code,
       p.id_country,
       p.city,
       p.district,
       NULL county,
       p.num_contact primary_phone,
       p.work_phone altern_phone,
       p.cell_phone,
       p.fax,
       p.email,
       NULL ruralidad_comuna,
       to_char(pc.id_category) prof_cat_id,
       pk_translation.get_translation(2,
                                      (SELECT c.code_category
                                         FROM category c
                                        WHERE c.id_category = pc.id_category)) prof_cat_desc
  FROM professional p, prof_institution pi, prof_cat pc, institution i
 WHERE nvl(p.flg_prof_test, 'N') != 'Y'
   AND p.id_professional = pi.id_professional
   AND pi.flg_state = 'A'
   AND pi.flg_external = 'N'
   AND pi.dt_end_tstz IS NULL
   AND pc.id_professional = p.id_professional
      -- Médico
   AND pc.id_category = 1
   AND pc.id_institution = pi.id_institution
   AND pi.id_institution(+) = i.id_institution
      -- CL market
   AND i.id_market = 12
UNION

--Profissionais externos
SELECT pi.id_prof_institution,
       pi.flg_external,
       pi.id_institution,
       p.id_professional,
       p.name,
       NULL suffix,
       p.first_name,
       p.middle_name,
       p.last_name,
       p.gender,
       p.id_speciality,
       p.title,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 60
              AND fm.id_market = 12
              AND pfd.id_institution = 0
              AND rownum = 1),
           NULL) run,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 61
              AND fm.id_market = 12
              AND pfd.id_institution = 0
              AND rownum = 1),
           NULL) rut,
       NULL calle_type,
       NULL direction_num,
       NULL direction_last,
       p.address,
       p.zip_code postal_code,
       p.id_country,
       p.city,
       p.district,
       NULL county,
       p.num_contact primary_phone,
       p.work_phone altern_phone,
       p.cell_phone,
       p.fax,
       p.email,
       NULL ruralidad_comuna,
       NULL prof_cat_id,
       NULL prof_cat_desc
  FROM professional p, prof_institution pi, institution i
 WHERE nvl(p.flg_prof_test, 'N') != 'Y'
   AND p.id_professional = pi.id_professional
   AND pi.flg_state = 'A'
   AND pi.flg_external = 'Y'
   AND pi.dt_end_tstz IS NULL
   AND pi.id_institution(+) = i.id_institution
      -- CL market
   AND i.id_market = 12;


CREATE OR REPLACE VIEW V_PHYSICIAN_INSTITUTION_CL AS
SELECT pi.id_prof_institution,
       pi.flg_external,
       pi.id_institution,
       p.id_professional,
       p.name,
       NULL suffix,
       p.first_name,
       p.middle_name,
       p.last_name,
       p.gender,
       p.id_speciality,
       pk_backoffice.get_prof_title_desc(pk_utils.get_institution_language(pi.id_institution), p.title) title,
       (SELECT pa.value
          FROM prof_accounts pa
         INNER JOIN accounts a
            ON (a.id_account = pa.id_account AND a.flg_available = 'Y')
         WHERE pa.id_professional = p.id_professional
           AND a.id_account = 60) run,
       (SELECT pa.value
          FROM prof_accounts pa
         INNER JOIN accounts a
            ON (a.id_account = pa.id_account AND a.flg_available = 'Y')
         WHERE pa.id_professional = p.id_professional
           AND a.id_account = 61) rut,
       
       NULL calle_type,
       NULL direction_num,
       NULL direction_last,
       p.address,
       p.zip_code postal_code,
       p.id_country,
       p.city,
       p.district,
       NULL county,
       p.num_contact primary_phone,
       p.work_phone altern_phone,
       p.cell_phone,
       p.fax,
       p.email,
       NULL ruralidad_comuna,
       to_char(pc.id_category) prof_cat_id,
       pk_translation.get_translation(2,
                                      (SELECT c.code_category
                                         FROM category c
                                        WHERE c.id_category = pc.id_category)) prof_cat_desc
  FROM professional p, prof_institution pi, prof_cat pc, institution i
 WHERE nvl(p.flg_prof_test, 'N') != 'Y'
   AND p.id_professional = pi.id_professional
   AND pi.flg_state = 'A'
   AND pi.flg_external = 'N'
   AND pi.dt_end_tstz IS NULL
   AND pc.id_professional = p.id_professional
      -- Médico
   AND pc.id_category = 1
   AND pc.id_institution = pi.id_institution
   AND pi.id_institution(+) = i.id_institution
      -- CL market
   AND i.id_market = 12
UNION

--Profissionais externos
SELECT pi.id_prof_institution,
       pi.flg_external,
       pi.id_institution,
       p.id_professional,
       p.name,
       NULL suffix,
       p.first_name,
       p.middle_name,
       p.last_name,
       p.gender,
       p.id_speciality,
       pk_backoffice.get_prof_title_desc(pk_utils.get_institution_language(pi.id_institution), p.title) title,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 60
              AND fm.id_market = 12
              AND pfd.id_institution = 0
              AND rownum = 1),
           NULL) run,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 61
              AND fm.id_market = 12
              AND pfd.id_institution = 0
              AND rownum = 1),
           NULL) rut,
       NULL calle_type,
       NULL direction_num,
       NULL direction_last,
       p.address,
       p.zip_code postal_code,
       p.id_country,
       p.city,
       p.district,
       NULL county,
       p.num_contact primary_phone,
       p.work_phone altern_phone,
       p.cell_phone,
       p.fax,
       p.email,
       NULL ruralidad_comuna,
       NULL prof_cat_id,
       NULL prof_cat_desc
  FROM professional p, prof_institution pi, institution i
 WHERE nvl(p.flg_prof_test, 'N') != 'Y'
   AND p.id_professional = pi.id_professional
   AND pi.flg_state = 'A'
   AND pi.flg_external = 'Y'
   AND pi.dt_end_tstz IS NULL
   AND pi.id_institution(+) = i.id_institution
      -- CL market
   AND i.id_market = 12;

CREATE OR REPLACE VIEW V_PHYSICIAN_INSTITUTION_CL AS
SELECT pi.id_prof_institution,
       pi.flg_external,
       pi.id_institution,
       p.id_professional,
       p.name,
       NULL suffix,
       p.first_name,
       p.middle_name,
       p.last_name,
       p.gender,
       p.id_speciality,
       pk_backoffice.get_prof_title_desc(pk_utils.get_institution_language(pi.id_institution), p.title) title,
       (SELECT pa.value
          FROM prof_accounts pa
         INNER JOIN accounts a
            ON (a.id_account = pa.id_account AND a.flg_available = 'Y')
         WHERE pa.id_professional = p.id_professional
           AND a.id_account = 60) run,
       (SELECT pa.value
          FROM prof_accounts pa
         INNER JOIN accounts a
            ON (a.id_account = pa.id_account AND a.flg_available = 'Y')
         WHERE pa.id_professional = p.id_professional
           AND a.id_account = 61) rut,

       NULL calle_type,
       NULL direction_num,
       NULL direction_last,
       p.address,
       p.zip_code postal_code,
       p.id_country,
       p.city,
       p.district,
       NULL county,
       p.num_contact primary_phone,
       p.work_phone altern_phone,
       p.cell_phone,
       p.fax,
       p.email,
       NULL ruralidad_comuna,
       to_char(pc.id_category) prof_cat_id,
       pk_translation.get_translation(2,
                                      (SELECT c.code_category
                                         FROM category c
                                        WHERE c.id_category = pc.id_category)) prof_cat_desc
  FROM professional p, prof_institution pi, prof_cat pc, institution i
 WHERE nvl(p.flg_prof_test, 'N') != 'Y'
   AND p.id_professional = pi.id_professional
   AND pi.flg_state = 'A'
   AND pi.flg_external = 'N'
   AND pi.dt_end_tstz IS NULL
   AND pc.id_professional = p.id_professional
      -- Médico
   AND pc.id_category = 1
   AND pc.id_institution = pi.id_institution
   AND pi.id_institution(+) = i.id_institution
      -- CL market
   AND i.id_market = 12
	 AND i.flg_type != 'L'
UNION

--Profissionais externos
SELECT pi.id_prof_institution,
       pi.flg_external,
       pi.id_institution,
       p.id_professional,
       p.name,
       NULL suffix,
       p.first_name,
       p.middle_name,
       p.last_name,
       p.gender,
       p.id_speciality,
       pk_backoffice.get_prof_title_desc(pk_utils.get_institution_language(pi.id_institution), p.title) title,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 60
              AND fm.id_market = 12
              AND pfd.id_institution = 0
              AND rownum = 1),
           NULL) run,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 61
              AND fm.id_market = 12
              AND pfd.id_institution = 0
              AND rownum = 1),
           NULL) rut,
       NULL calle_type,
       NULL direction_num,
       NULL direction_last,
       p.address,
       p.zip_code postal_code,
       p.id_country,
       p.city,
       p.district,
       NULL county,
       p.num_contact primary_phone,
       p.work_phone altern_phone,
       p.cell_phone,
       p.fax,
       p.email,
       NULL ruralidad_comuna,
       NULL prof_cat_id,
       NULL prof_cat_desc
  FROM professional p, prof_institution pi, institution i
 WHERE nvl(p.flg_prof_test, 'N') != 'Y'
   AND p.id_professional = pi.id_professional
   AND pi.flg_state = 'A'
   AND pi.flg_external = 'Y'
   AND pi.dt_end_tstz IS NULL
   AND pi.id_institution(+) = i.id_institution
      -- CL market
   AND i.id_market = 12
	 AND i.flg_type != 'L';