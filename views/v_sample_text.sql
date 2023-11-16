CREATE OR REPLACE VIEW V_SAMPLE_TEXT AS
SELECT stp.id_sample_text_prof    id_sample_text_prof,
       stp.rank                   rank,
       stp.title_sample_text_prof title_sample_text_prof,
       stp.desc_sample_text_prof  desc_sample_text_prof,
       stt.code_sample_text_type  code_sample_text_type,
       stp.id_professional        id_professional,
       stp.id_software            id_software
  FROM sample_text_prof stp
  JOIN sample_text_type stt
    ON stp.id_sample_text_type = stt.id_sample_text_type
 WHERE stt.flg_available = 'Y';
