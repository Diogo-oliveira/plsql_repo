CREATE OR REPLACE VIEW V_PHYSICIAN_INSTITUTION_IT AS
SELECT pi.id_prof_institution,
       pi.id_institution,
       p.id_professional,
       p.name,
       p.first_name,
       p.middle_name,
       p.last_name,
       p.gender,
       p.id_speciality,
       p.title,
       p.address,
       p.zip_code postal_code,
       p.id_country,
       NULL as id_region,
       NULL as id_province,
       p.city,
       p.work_phone,
       p.cell_phone,
       p.fax,
       p.email,
       to_char(pc.id_category) prof_cat_id,
       pk_translation.get_translation(5, (SELECT c.code_category FROM category c WHERE c.id_category = pc.id_category)) prof_cat_desc
  FROM professional p, prof_institution pi, prof_cat pc, institution i
 WHERE nvl(p.flg_prof_test, 'N') != 'Y'
 AND p.id_professional = pi.id_professional
 AND pi.flg_state = 'A'
 AND pi.flg_external = 'N'
 AND pi.dt_end_tstz IS NULL
 AND pc.id_professional = p.id_professional
 AND pc.id_category = 1 -- Médico
 AND pc.id_institution = pi.id_institution
 AND pi.id_institution (+)= i.id_institution
 AND i.id_market = 4 -- IT market
 UNION
--Profissionais externos
SELECT pi.id_prof_institution,
       pi.id_institution,
       p.id_professional,
       p.name,
       p.first_name,
       p.middle_name,
       p.last_name,
       p.gender,
       p.id_speciality,
       p.title,
       p.address,
       p.zip_code postal_code,
       p.id_country,
       NVL((SELECT pfd.value
            FROM professional_field_data pfd
            join field_market fm
            on pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
            AND fm.id_field = 45 and fm.id_market = 4
            AND pfd.id_institution = 0
            AND rownum = 1), NULL)
       region,
       NVL((SELECT pfd.value
            FROM professional_field_data pfd
            join field_market fm
            on pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
            AND fm.id_field = 46 and fm.id_market = 4
            AND pfd.id_institution = 0
            AND rownum = 1), NULL)
       province,
       NVL((SELECT pfd.value
            FROM professional_field_data pfd
            join field_market fm
            on pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
            AND fm.id_field = 47 and fm.id_market = 4
            AND pfd.id_institution = 0
            AND rownum = 1), NULL)
       city,
       p.work_phone,
       p.cell_phone,
       p.fax,
       p.email,
        NVL((SELECT pfd.value
            FROM professional_field_data pfd
            join field_market fm
            on pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
            AND fm.id_field = 43 and fm.id_market = 4
            AND pfd.id_institution = 0
            AND rownum = 1), NULL) prof_cat_id,
        NVL((SELECT stgpc.ext_prof_cat_desc
            FROM stg_ext_prof_cat stgpc
            WHERE stgpc.id_market = 4
            AND stgpc.id_ext_prof_cat = (SELECT pfd.value
                                          FROM professional_field_data pfd
                                          join field_market fm
                                          on pfd.id_field_market = fm.id_field_market
                                          WHERE pfd.id_professional = p.id_professional
                                          AND fm.id_field = 43 and fm.id_market = 4
                                          AND pfd.id_institution = 0
                                          AND rownum = 1)
            AND rownum = 1), NULL) prof_cat_desc
  FROM professional p, prof_institution pi, institution i
 WHERE nvl(p.flg_prof_test, 'N') != 'Y'
 AND p.id_professional = pi.id_professional
 AND pi.flg_state = 'A'
 AND pi.flg_external = 'Y'
 AND pi.dt_end_tstz IS NULL
 AND pi.id_institution (+)= i.id_institution
 AND i.id_market = 4;


CREATE OR REPLACE VIEW V_PHYSICIAN_INSTITUTION_IT AS
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
       p.title,
       p.address,
       p.zip_code postal_code,
       p.id_country,
       NULL as id_region,
       NULL as id_province,
       p.city,
       p.work_phone,
       p.cell_phone,
       p.fax,
       p.email,
       to_char(pc.id_category) prof_cat_id,
       pk_translation.get_translation(5, (SELECT c.code_category FROM category c WHERE c.id_category = pc.id_category)) prof_cat_desc
  FROM professional p, prof_institution pi, prof_cat pc, institution i
 WHERE nvl(p.flg_prof_test, 'N') != 'Y'
 AND p.id_professional = pi.id_professional
 AND pi.flg_state = 'A'
 AND pi.flg_external = 'N'
 AND pi.dt_end_tstz IS NULL
 AND pc.id_professional = p.id_professional
 AND pc.id_category = 1 -- Médico
 AND pc.id_institution = pi.id_institution
 AND pi.id_institution (+)= i.id_institution
 AND i.id_market = 4 -- IT market
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
       p.title,
       p.address,
       p.zip_code postal_code,
       p.id_country,
       NVL((SELECT pfd.value
            FROM professional_field_data pfd
            join field_market fm
            on pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
            AND fm.id_field = 45 and fm.id_market = 4
            AND pfd.id_institution = 0
            AND rownum = 1), NULL)
       region,
       NVL((SELECT pfd.value
            FROM professional_field_data pfd
            join field_market fm
            on pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
            AND fm.id_field = 46 and fm.id_market = 4
            AND pfd.id_institution = 0
            AND rownum = 1), NULL)
       province,
       NVL((SELECT pfd.value
            FROM professional_field_data pfd
            join field_market fm
            on pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
            AND fm.id_field = 47 and fm.id_market = 4
            AND pfd.id_institution = 0
            AND rownum = 1), NULL)
       city,
       p.work_phone,
       p.cell_phone,
       p.fax,
       p.email,
        NVL((SELECT pfd.value
            FROM professional_field_data pfd
            join field_market fm
            on pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
            AND fm.id_field = 43 and fm.id_market = 4
            AND pfd.id_institution = 0
            AND rownum = 1), NULL) prof_cat_id,
        NVL((SELECT stgpc.ext_prof_cat_desc
            FROM stg_ext_prof_cat stgpc
            WHERE stgpc.id_market = 4
            AND stgpc.id_ext_prof_cat = (SELECT pfd.value
                                          FROM professional_field_data pfd
                                          join field_market fm
                                          on pfd.id_field_market = fm.id_field_market
                                          WHERE pfd.id_professional = p.id_professional
                                          AND fm.id_field = 43 and fm.id_market = 4
                                          AND pfd.id_institution = 0
                                          AND rownum = 1)
            AND rownum = 1), NULL) prof_cat_desc
  FROM professional p, prof_institution pi, institution i
 WHERE nvl(p.flg_prof_test, 'N') != 'Y'
 AND p.id_professional = pi.id_professional
 AND pi.flg_state = 'A'
 AND pi.flg_external = 'Y'
 AND pi.dt_end_tstz IS NULL
 AND pi.id_institution (+)= i.id_institution
 AND i.id_market = 4;


CREATE OR REPLACE VIEW V_PHYSICIAN_INSTITUTION_IT AS
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
       p.address,
       p.zip_code postal_code,
       p.id_country,
       NULL as id_region,
       NULL as id_province,
       p.city,
       p.work_phone,
       p.cell_phone,
       p.fax,
       p.email,
       to_char(pc.id_category) prof_cat_id,
       pk_translation.get_translation(5, (SELECT c.code_category FROM category c WHERE c.id_category = pc.id_category)) prof_cat_desc
  FROM professional p, prof_institution pi, prof_cat pc, institution i
 WHERE nvl(p.flg_prof_test, 'N') != 'Y'
 AND p.id_professional = pi.id_professional
 AND pi.flg_state = 'A'
 AND pi.flg_external = 'N'
 AND pi.dt_end_tstz IS NULL
 AND pc.id_professional = p.id_professional
 AND pc.id_category = 1 -- Médico
 AND pc.id_institution = pi.id_institution
 AND pi.id_institution (+)= i.id_institution
 AND i.id_market = 4 -- IT market
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
       p.address,
       p.zip_code postal_code,
       p.id_country,
       NVL((SELECT pfd.value
            FROM professional_field_data pfd
            join field_market fm
            on pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
            AND fm.id_field = 45 and fm.id_market = 4
            AND pfd.id_institution = 0
            AND rownum = 1), NULL)
       region,
       NVL((SELECT pfd.value
            FROM professional_field_data pfd
            join field_market fm
            on pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
            AND fm.id_field = 46 and fm.id_market = 4
            AND pfd.id_institution = 0
            AND rownum = 1), NULL)
       province,
       NVL((SELECT pfd.value
            FROM professional_field_data pfd
            join field_market fm
            on pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
            AND fm.id_field = 47 and fm.id_market = 4
            AND pfd.id_institution = 0
            AND rownum = 1), NULL)
       city,
       p.work_phone,
       p.cell_phone,
       p.fax,
       p.email,
        NVL((SELECT pfd.value
            FROM professional_field_data pfd
            join field_market fm
            on pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
            AND fm.id_field = 43 and fm.id_market = 4
            AND pfd.id_institution = 0
            AND rownum = 1), NULL) prof_cat_id,
        NVL((SELECT stgpc.ext_prof_cat_desc
            FROM stg_ext_prof_cat stgpc
            WHERE stgpc.id_market = 4
            AND stgpc.id_ext_prof_cat = (SELECT pfd.value
                                          FROM professional_field_data pfd
                                          join field_market fm
                                          on pfd.id_field_market = fm.id_field_market
                                          WHERE pfd.id_professional = p.id_professional
                                          AND fm.id_field = 43 and fm.id_market = 4
                                          AND pfd.id_institution = 0
                                          AND rownum = 1)
            AND rownum = 1), NULL) prof_cat_desc
  FROM professional p, prof_institution pi, institution i
 WHERE nvl(p.flg_prof_test, 'N') != 'Y'
 AND p.id_professional = pi.id_professional
 AND pi.flg_state = 'A'
 AND pi.flg_external = 'Y'
 AND pi.dt_end_tstz IS NULL
 AND pi.id_institution (+)= i.id_institution
 AND i.id_market = 4;

CREATE OR REPLACE VIEW V_PHYSICIAN_INSTITUTION_IT AS
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
       p.address,
       p.zip_code postal_code,
       p.id_country,
       NULL as id_region,
       NULL as id_province,
       p.city,
       p.work_phone,
       p.cell_phone,
       p.fax,
       p.email,
       to_char(pc.id_category) prof_cat_id,
       pk_translation.get_translation(5, (SELECT c.code_category FROM category c WHERE c.id_category = pc.id_category)) prof_cat_desc
  FROM professional p, prof_institution pi, prof_cat pc, institution i
 WHERE nvl(p.flg_prof_test, 'N') != 'Y'
 AND p.id_professional = pi.id_professional
 AND pi.flg_state = 'A'
 AND pi.flg_external = 'N'
 AND pi.dt_end_tstz IS NULL
 AND pc.id_professional = p.id_professional
 AND pc.id_category = 1 -- Médico
 AND pc.id_institution = pi.id_institution
 AND pi.id_institution (+)= i.id_institution
 AND i.id_market = 4 -- IT market
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
       p.address,
       p.zip_code postal_code,
       p.id_country,
       NVL((SELECT pfd.value
            FROM professional_field_data pfd
            join field_market fm
            on pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
            AND fm.id_field = 45 and fm.id_market = 4
            AND pfd.id_institution = 0
            AND rownum = 1), NULL)
       region,
       NVL((SELECT pfd.value
            FROM professional_field_data pfd
            join field_market fm
            on pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
            AND fm.id_field = 46 and fm.id_market = 4
            AND pfd.id_institution = 0
            AND rownum = 1), NULL)
       province,
       NVL((SELECT pfd.value
            FROM professional_field_data pfd
            join field_market fm
            on pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
            AND fm.id_field = 47 and fm.id_market = 4
            AND pfd.id_institution = 0
            AND rownum = 1), NULL)
       city,
       p.work_phone,
       p.cell_phone,
       p.fax,
       p.email,
        NVL((SELECT pfd.value
            FROM professional_field_data pfd
            join field_market fm
            on pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
            AND fm.id_field = 43 and fm.id_market = 4
            AND pfd.id_institution = 0
            AND rownum = 1), NULL) prof_cat_id,
        NVL((SELECT stgpc.ext_prof_cat_desc
            FROM stg_ext_prof_cat stgpc
            WHERE stgpc.id_market = 4
            AND stgpc.id_ext_prof_cat = (SELECT pfd.value
                                          FROM professional_field_data pfd
                                          join field_market fm
                                          on pfd.id_field_market = fm.id_field_market
                                          WHERE pfd.id_professional = p.id_professional
                                          AND fm.id_field = 43 and fm.id_market = 4
                                          AND pfd.id_institution = 0
                                          AND rownum = 1)
            AND rownum = 1), NULL) prof_cat_desc
  FROM professional p, prof_institution pi, institution i
 WHERE nvl(p.flg_prof_test, 'N') != 'Y'
 AND p.id_professional = pi.id_professional
 AND pi.flg_state = 'A'
 AND pi.flg_external = 'Y'
 AND pi.dt_end_tstz IS NULL
 AND pi.id_institution (+)= i.id_institution
 AND i.id_market = 4
 AND i.flg_type != 'L';