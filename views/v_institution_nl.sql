CREATE OR REPLACE VIEW V_INSTITUTION_NL AS
SELECT i.id_institution,
       nvl((SELECT ia.value
             FROM institution_accounts ia
            WHERE ia.id_institution = i.id_institution
              AND ia.id_account = 13
              AND rownum = 1),
           NULL) institution_agb_code,
       NULL house_number,
       NULL house_letter
  FROM institution i
 WHERE i.flg_external = 'N'
   AND i.id_market = 5
UNION
SELECT i.id_institution,
       nvl((SELECT ifd.value
             FROM institution_field_data ifd
             JOIN field_market fm
               ON ifd.id_field_market = fm.id_field_market
            WHERE ifd.id_institution = i.id_institution
              AND fm.id_field = 40
              AND fm.id_market = 5
              AND rownum = 1),
           NULL) institution_agb_code,
       nvl((SELECT ifd.value
             FROM institution_field_data ifd
             JOIN field_market fm
               ON ifd.id_field_market = fm.id_field_market
            WHERE ifd.id_institution = i.id_institution
              AND fm.id_field = 41
              AND fm.id_market = 5
              AND rownum = 1),
           NULL) house_number,
       nvl((SELECT ifd.value
             FROM institution_field_data ifd
             JOIN field_market fm
               ON ifd.id_field_market = fm.id_field_market
            WHERE ifd.id_institution = i.id_institution
              AND fm.id_field = 42
              AND fm.id_market = 5
              AND rownum = 1),
           NULL) house_letter
  FROM institution i
 WHERE i.flg_external = 'Y'
   AND i.id_market = 5;
