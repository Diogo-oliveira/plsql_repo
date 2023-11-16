CREATE OR REPLACE VIEW V_PHYSICIAN_INSTITUTION_UK AS
SELECT pi.id_prof_institution,
       pi.id_institution,
       pi.flg_external,
       nvl((SELECT ia.value
             FROM institution_accounts ia
            WHERE ia.id_institution = pi.id_institution
              AND ia.id_account = 18
              AND rownum = 1),
           NULL) institution_gp_code,
       p.id_professional,
       p.title,
       p.name,
       p.first_name,
       p.middle_name,
       p.last_name,
       p.initials,
       p.dt_birth_tstz,
       p.gender,
       p.address,
       p.zip_code,
       p.city,
       p.work_phone,
       p.num_contact,
       p.fax,
       p.email,
       p.num_order gmc,
       nvl((SELECT pa.value
             FROM prof_accounts pa
            WHERE pa.id_professional = p.id_professional
              AND pa.id_account = 51
              AND pa.id_institution = 0
              AND rownum = 1),
           NULL) gp_code,
       p.id_speciality,
       nvl((SELECT pa.value
             FROM prof_accounts pa
            WHERE pa.id_professional = p.id_professional
              AND pa.id_account = 16
              AND pa.id_institution = 0
              AND rownum = 1),
           NULL) prescriber_type
  FROM professional p
 INNER JOIN prof_institution pi
    ON (pi.id_professional = p.id_professional AND pi.flg_external = 'N' AND pi.dt_end_tstz IS NULL AND
       pi.flg_state = 'A')
 INNER JOIN prof_cat pc
    ON (pc.id_professional = p.id_professional AND pc.id_category = 1 AND pc.id_institution = pi.id_institution)
 INNER JOIN institution i
    ON (i.id_institution = pi.id_institution AND i.flg_available = 'Y' AND i.id_market = 8)
UNION ALL
SELECT pi.id_prof_institution,
       pi.id_institution,
       pi.flg_external,
       nvl((SELECT ifd.value
             FROM institution_field_data ifd
             JOIN field_market fm
               ON ifd.id_field_market = fm.id_field_market
            WHERE ifd.id_institution = pi.id_institution
              AND fm.id_field = 18
              AND fm.id_market = 8
              AND rownum = 1),
           NULL) institution_gp_code,
       p.id_professional,
       p.title,
       p.name,
       p.first_name,
       p.middle_name,
       p.last_name,
       p.initials,
       p.dt_birth_tstz,
       p.gender,
       p.address,
       p.zip_code,
       p.city,
       p.work_phone,
       p.num_contact,
       p.fax,
       p.email,
       p.num_order gmc,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 51
              AND fm.id_market = 8
              AND pfd.id_institution = 0
              AND rownum = 1),
           NULL) gp_code,
       p.id_speciality,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 43
              AND fm.id_market = 8
              AND pfd.id_institution = 0
              AND rownum = 1),
           NULL) prescriber_type
  FROM professional p
 INNER JOIN prof_institution pi
    ON (pi.id_professional = p.id_professional AND pi.flg_external = 'Y' AND pi.dt_end_tstz IS NULL AND
       pi.flg_state = 'A')
 INNER JOIN institution i
    ON (i.id_institution = pi.id_institution AND i.flg_available = 'Y' AND i.id_market = 8)
UNION ALL
SELECT pi.id_prof_institution,
       pi.id_institution,
       pi.flg_external,
       nvl((SELECT ifd.value
             FROM institution_field_data ifd
             JOIN field_market fm
               ON ifd.id_field_market = fm.id_field_market
            WHERE ifd.id_institution = pi.id_institution
              AND fm.id_field = 18
              AND fm.id_market = 8
              AND rownum = 1),
           NULL) institution_gp_code,
       p.id_professional,
       p.title,
       p.name,
       p.first_name,
       p.middle_name,
       p.last_name,
       p.initials,
       p.dt_birth_tstz,
       p.gender,
       p.address,
       p.zip_code,
       p.city,
       p.work_phone,
       p.num_contact,
       p.fax,
       p.email,
       p.num_order gmc,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 51
              AND fm.id_market = 8
              AND pfd.id_institution = 0
              AND rownum = 1),
           NULL) gp_code,
       p.id_speciality,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 43
              AND fm.id_market = 8
              AND pfd.id_institution = 0
              AND rownum = 1),
           NULL) prescriber_type
  FROM professional p
 INNER JOIN prof_institution pi
    ON (pi.id_professional = p.id_professional AND pi.flg_external = 'N' AND pi.dt_end_tstz IS NULL AND
       pi.flg_state = 'A')
 INNER JOIN institution i
    ON (i.id_institution = pi.id_institution AND i.flg_available = 'Y' AND i.flg_external = 'Y' AND i.id_market = 8);


CREATE OR REPLACE VIEW V_PHYSICIAN_INSTITUTION_UK AS
SELECT pi.id_prof_institution,
       pi.id_institution,
       pi.flg_external,
       nvl((SELECT ia.value
             FROM institution_accounts ia
            WHERE ia.id_institution = pi.id_institution
              AND ia.id_account = 18
              AND rownum = 1),
           NULL) institution_gp_code,
       p.id_professional,
       pk_backoffice.get_prof_title_desc(pk_utils.get_institution_language(pi.id_institution), p.title) title,
       p.name,
       p.first_name,
       p.middle_name,
       p.last_name,
       p.initials,
       p.dt_birth_tstz,
       p.gender,
       p.address,
       p.zip_code,
       p.city,
       p.work_phone,
       p.num_contact,
       p.fax,
       p.email,
       p.num_order gmc,
       nvl((SELECT pa.value
             FROM prof_accounts pa
            WHERE pa.id_professional = p.id_professional
              AND pa.id_account = 51
              AND pa.id_institution = 0
              AND rownum = 1),
           NULL) gp_code,
       p.id_speciality,
       nvl((SELECT pa.value
             FROM prof_accounts pa
            WHERE pa.id_professional = p.id_professional
              AND pa.id_account = 16
              AND pa.id_institution = 0
              AND rownum = 1),
           NULL) prescriber_type
  FROM professional p
 INNER JOIN prof_institution pi
    ON (pi.id_professional = p.id_professional AND pi.flg_external = 'N' AND pi.dt_end_tstz IS NULL AND
       pi.flg_state = 'A')
 INNER JOIN prof_cat pc
    ON (pc.id_professional = p.id_professional AND pc.id_category = 1 AND pc.id_institution = pi.id_institution)
 INNER JOIN institution i
    ON (i.id_institution = pi.id_institution AND i.flg_available = 'Y' AND i.id_market = 8)
UNION ALL
SELECT pi.id_prof_institution,
       pi.id_institution,
       pi.flg_external,
       nvl((SELECT ifd.value
             FROM institution_field_data ifd
             JOIN field_market fm
               ON ifd.id_field_market = fm.id_field_market
            WHERE ifd.id_institution = pi.id_institution
              AND fm.id_field = 18
              AND fm.id_market = 8
              AND rownum = 1),
           NULL) institution_gp_code,
       p.id_professional,
       pk_backoffice.get_prof_title_desc(pk_utils.get_institution_language(pi.id_institution), p.title) title,
       p.name,
       p.first_name,
       p.middle_name,
       p.last_name,
       p.initials,
       p.dt_birth_tstz,
       p.gender,
       p.address,
       p.zip_code,
       p.city,
       p.work_phone,
       p.num_contact,
       p.fax,
       p.email,
       p.num_order gmc,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 51
              AND fm.id_market = 8
              AND pfd.id_institution = 0
              AND rownum = 1),
           NULL) gp_code,
       p.id_speciality,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 43
              AND fm.id_market = 8
              AND pfd.id_institution = 0
              AND rownum = 1),
           NULL) prescriber_type
  FROM professional p
 INNER JOIN prof_institution pi
    ON (pi.id_professional = p.id_professional AND pi.flg_external = 'Y' AND pi.dt_end_tstz IS NULL AND
       pi.flg_state = 'A')
 INNER JOIN institution i
    ON (i.id_institution = pi.id_institution AND i.flg_available = 'Y' AND i.id_market = 8)
UNION ALL
SELECT pi.id_prof_institution,
       pi.id_institution,
       pi.flg_external,
       nvl((SELECT ifd.value
             FROM institution_field_data ifd
             JOIN field_market fm
               ON ifd.id_field_market = fm.id_field_market
            WHERE ifd.id_institution = pi.id_institution
              AND fm.id_field = 18
              AND fm.id_market = 8
              AND rownum = 1),
           NULL) institution_gp_code,
       p.id_professional,
       pk_backoffice.get_prof_title_desc(pk_utils.get_institution_language(pi.id_institution), p.title) title,
       p.name,
       p.first_name,
       p.middle_name,
       p.last_name,
       p.initials,
       p.dt_birth_tstz,
       p.gender,
       p.address,
       p.zip_code,
       p.city,
       p.work_phone,
       p.num_contact,
       p.fax,
       p.email,
       p.num_order gmc,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 51
              AND fm.id_market = 8
              AND pfd.id_institution = 0
              AND rownum = 1),
           NULL) gp_code,
       p.id_speciality,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 43
              AND fm.id_market = 8
              AND pfd.id_institution = 0
              AND rownum = 1),
           NULL) prescriber_type
  FROM professional p
 INNER JOIN prof_institution pi
    ON (pi.id_professional = p.id_professional AND pi.flg_external = 'N' AND pi.dt_end_tstz IS NULL AND
       pi.flg_state = 'A')
 INNER JOIN institution i
    ON (i.id_institution = pi.id_institution AND i.flg_available = 'Y' AND i.flg_external = 'Y' AND i.id_market = 8);

CREATE OR REPLACE VIEW V_PHYSICIAN_INSTITUTION_UK AS
SELECT pi.id_prof_institution,
           pi.id_institution,
           pi.flg_external,
           nvl((SELECT ia.value
                 FROM institution_accounts ia
                WHERE ia.id_institution = pi.id_institution
                  AND ia.id_account = 18
                  AND rownum = 1),
               NULL) institution_gp_code,
           p.id_professional,
           pk_backoffice.get_prof_title_desc(alert.pk_utils.get_institution_language(pi.id_institution), p.title) title,
           p.name,
           p.first_name,
           p.middle_name,
           p.last_name,
           p.initials,
           p.dt_birth_tstz,
           p.gender,
           p.address,
           p.zip_code,
           p.city,
           p.work_phone,
           p.num_contact,
           p.fax,
           p.email,
           p.num_order gmc,
           nvl((SELECT pa.value
                 FROM prof_accounts pa
                WHERE pa.id_professional = p.id_professional
                  AND pa.id_account = 51
                  AND pa.id_institution = 0
                  AND rownum = 1),
               NULL) gp_code,
           p.id_speciality,
           nvl((SELECT pa.value
                 FROM prof_accounts pa
                WHERE pa.id_professional = p.id_professional
                  AND pa.id_account = 16
                  AND pa.id_institution = 0
                  AND rownum = 1),
               NULL) prescriber_type
      FROM professional p
     INNER JOIN prof_institution pi
        ON (pi.id_professional = p.id_professional AND pi.flg_external = 'N' AND pi.dt_end_tstz IS NULL AND
           pi.flg_state = 'A')
     INNER JOIN prof_cat pc
        ON (pc.id_professional = p.id_professional AND pc.id_category = 1 AND pc.id_institution = pi.id_institution)
     INNER JOIN institution i
        ON (i.id_institution = pi.id_institution AND i.flg_available = 'Y' AND i.id_market = 8 AND i.flg_type != 'L')
    UNION ALL
    SELECT pi.id_prof_institution,
           pi.id_institution,
           pi.flg_external,
           nvl((SELECT ifd.value
                 FROM alert.institution_field_data ifd
                 JOIN alert.field_market fm
                   ON ifd.id_field_market = fm.id_field_market
                WHERE ifd.id_institution = pi.id_institution
                  AND fm.id_field = 18
                  AND fm.id_market = 8
                  AND rownum = 1),
               NULL) institution_gp_code,
           p.id_professional,
           pk_backoffice.get_prof_title_desc(alert.pk_utils.get_institution_language(pi.id_institution), p.title) title,
           p.name,
           p.first_name,
           p.middle_name,
           p.last_name,
           p.initials,
           p.dt_birth_tstz,
           p.gender,
           p.address,
           p.zip_code,
           p.city,
           p.work_phone,
           p.num_contact,
           p.fax,
           p.email,
           p.num_order gmc,
           nvl((SELECT pfd.value
                 FROM alert.professional_field_data pfd
                 JOIN alert.field_market fm
                   ON pfd.id_field_market = fm.id_field_market
                WHERE pfd.id_professional = p.id_professional
                  AND fm.id_field = 51
                  AND fm.id_market = 8
                  AND pfd.id_institution = 0
                  AND rownum = 1),
               NULL) gp_code,
           p.id_speciality,
           nvl((SELECT pfd.value
                 FROM alert.professional_field_data pfd
                 JOIN alert.field_market fm
                   ON pfd.id_field_market = fm.id_field_market
                WHERE pfd.id_professional = p.id_professional
                  AND fm.id_field = 43
                  AND fm.id_market = 8
                  AND pfd.id_institution = 0
                  AND rownum = 1),
               NULL) prescriber_type
      FROM professional p
     INNER JOIN prof_institution pi
        ON (pi.id_professional = p.id_professional AND pi.flg_external = 'Y' AND pi.dt_end_tstz IS NULL AND
           pi.flg_state = 'A')
     INNER JOIN institution i
        ON (i.id_institution = pi.id_institution AND i.flg_available = 'Y' AND i.id_market = 8 AND i.flg_type != 'L')
    UNION ALL
    SELECT pi.id_prof_institution,
           pi.id_institution,
           pi.flg_external,
           nvl((SELECT ifd.value
                 FROM alert.institution_field_data ifd
                 JOIN alert.field_market fm
                   ON ifd.id_field_market = fm.id_field_market
                WHERE ifd.id_institution = pi.id_institution
                  AND fm.id_field = 18
                  AND fm.id_market = 8
                  AND rownum = 1),
               NULL) institution_gp_code,
           p.id_professional,
           pk_backoffice.get_prof_title_desc(alert.pk_utils.get_institution_language(pi.id_institution), p.title) title,
           p.name,
           p.first_name,
           p.middle_name,
           p.last_name,
           p.initials,
           p.dt_birth_tstz,
           p.gender,
           p.address,
           p.zip_code,
           p.city,
           p.work_phone,
           p.num_contact,
           p.fax,
           p.email,
           p.num_order gmc,
           nvl((SELECT pfd.value
                 FROM alert.professional_field_data pfd
                 JOIN alert.field_market fm
                   ON pfd.id_field_market = fm.id_field_market
                WHERE pfd.id_professional = p.id_professional
                  AND fm.id_field = 51
                  AND fm.id_market = 8
                  AND pfd.id_institution = 0
                  AND rownum = 1),
               NULL) gp_code,
           p.id_speciality,
           nvl((SELECT pfd.value
                 FROM alert.professional_field_data pfd
                 JOIN alert.field_market fm
                   ON pfd.id_field_market = fm.id_field_market
                WHERE pfd.id_professional = p.id_professional
                  AND fm.id_field = 43
                  AND fm.id_market = 8
                  AND pfd.id_institution = 0
                  AND rownum = 1),
               NULL) prescriber_type
      FROM professional p
     INNER JOIN prof_institution pi
        ON (pi.id_professional = p.id_professional AND pi.flg_external = 'N' AND pi.dt_end_tstz IS NULL AND
           pi.flg_state = 'A')
     INNER JOIN institution i
        ON (i.id_institution = pi.id_institution AND i.flg_available = 'Y' AND i.flg_external = 'Y' AND i.id_market = 8 AND i.flg_type != 'L');