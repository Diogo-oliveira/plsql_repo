CREATE OR REPLACE VIEW ALERT.V_PHYSICIAN_INSTITUTION_MZ AS
SELECT pi.id_prof_institution,
       pi.id_institution,
       pi.flg_external,
       p.id_professional,
       p.name,
       p.first_name,
       p.middle_name,
       p.last_name,
       p.gender,
       p.id_speciality,
       pk_backoffice.get_prof_title_desc(pk_utils.get_institution_language(pi.id_institution), p.title) title,
       p.suffix suffix,
       p.address,
       p.zip_code postal_code,
       p.id_country,
       p.city,
       p.work_phone,
       p.cell_phone,
       p.fax,
       p.email,
       NULL alternate_email,
       NULL state,
       to_char(pc.id_category) prof_cat_id,
       pk_translation.get_translation(2,
                                      (SELECT c.code_category
                                         FROM category c
                                        WHERE c.id_category = pc.id_category)) prof_cat_desc,
       nvl((SELECT pa.value
             FROM prof_accounts pa
            WHERE pa.id_professional = p.id_professional
              AND pa.id_account = 1
              AND pa.id_institution = pi.id_institution),
           (SELECT pa.value
              FROM prof_accounts pa
             WHERE pa.id_professional = p.id_professional
               AND pa.id_account = 1
               AND pa.id_institution = 0)) npi,
               p.county,
               p.address_other_name
  FROM professional p, prof_institution pi, prof_cat pc, institution i
 WHERE nvl(p.flg_prof_test, 'N') != 'Y'
   AND p.id_professional = pi.id_professional
   AND pi.flg_state = 'A'
   AND pi.flg_external = 'N'
   AND pi.dt_end_tstz IS NULL
   AND pc.id_professional = p.id_professional
   AND pc.id_category = 1
   AND pc.id_institution = pi.id_institution
   AND pi.id_institution(+) = i.id_institution
   AND i.id_market = 22
   AND i.flg_type != 'L'
UNION
--Profissionais externos
SELECT pi.id_prof_institution,
       pi.id_institution,
       pi.flg_external,
       p.id_professional,
       p.name,
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
              AND fm.id_field = 31
              AND fm.id_market = 22
              AND pfd.id_institution = 0
              AND rownum = 1),
           NULL) suffix,
       p.address,
       p.zip_code postal_code,
       p.id_country,
       p.city,
       p.work_phone,
       p.cell_phone,
       p.fax,
       p.email,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 27
              AND fm.id_market = 22
              AND pfd.id_institution = 0
              AND rownum = 1),
           NULL) alternate_email,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 30
              AND fm.id_market = 22
              AND pfd.id_institution = 0
              AND rownum = 1),
           NULL) state,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 43
              AND fm.id_market = 22
              AND pfd.id_institution = 0
              AND rownum = 1),
           NULL) prof_cat_id,
       nvl((SELECT stgpc.ext_prof_cat_desc
             FROM stg_ext_prof_cat stgpc
            WHERE stgpc.id_market = 22
              AND stgpc.id_ext_prof_cat = (SELECT pfd.value
                                             FROM professional_field_data pfd
                                             JOIN field_market fm
                                               ON pfd.id_field_market = fm.id_field_market
                                            WHERE pfd.id_professional = p.id_professional
                                              AND fm.id_field = 43
                                              AND fm.id_market = 22
                                              AND pfd.id_institution = 0
                                              AND rownum = 1)
              AND rownum = 1),
           NULL) prof_cat_desc,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
            WHERE pfd.id_professional = p.id_professional
              AND pfd.id_field_market = (SELECT x.id_field_market
                                           FROM field_market x
                                          WHERE x.id_field = 1
                                            AND x.id_market = 22
                                            AND x.flg_available = 'Y')
              AND pfd.id_institution = pi.id_institution),
           (SELECT pfd.value
              FROM professional_field_data pfd
             WHERE pfd.id_professional = p.id_professional
               AND pfd.id_field_market = (SELECT x.id_field_market
                                            FROM field_market x
                                           WHERE x.id_field = 1
                                             AND x.id_market = 22
                                             AND x.flg_available = 'Y')
               AND pfd.id_institution = 0)) npi,
               null county,
               null address_other_name
  FROM professional p, prof_institution pi, institution i
 WHERE nvl(p.flg_prof_test, 'N') != 'Y'
   AND p.id_professional = pi.id_professional
   AND pi.flg_state = 'A'
   AND pi.flg_external = 'Y'
   AND pi.dt_end_tstz IS NULL
   AND pi.id_institution(+) = i.id_institution
   AND i.id_market = 22
   AND i.flg_type != 'L';