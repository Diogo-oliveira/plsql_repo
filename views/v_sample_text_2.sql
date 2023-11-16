create or replace view v_sample_text_2 as
select
st.id_sample_text
--, pk_translation.get_Translation( 19, stt.code_sample_text_type ) xarea
--, pk_translation.get_Translation( 19, st.code_title_sample_text ) xtitle
--, pk_translation.get_Translation( 19, st.code_desc_sample_text ) xtext
, stt.code_sample_text_type code_area
, st.code_title_sample_text code_title
, st.code_desc_sample_text  code_text
, stt.id_sample_text_type
, stsi.id_institution
, sttc.id_category
, sts.id_software
from sample_text st
JOIN sample_text_soft_inst stsi    ON stsi.id_sample_text = st.id_sample_text
JOIN sample_text_type_soft sts     ON sts.id_sample_text_type = stsi.id_sample_text_type AND sts.id_software = stsi.id_software
JOIN sample_text_type stt          ON stt.id_sample_text_type = stsi.id_sample_text_type
JOIN sample_text_type_cat sttc     ON sttc.id_sample_text_type = stsi.id_sample_text_type and sttc.id_institution = stsi.id_institution
where st.flg_available = 'Y'
--and stsi.id_institution = 11111
--and stsi.id_software= 1
;
