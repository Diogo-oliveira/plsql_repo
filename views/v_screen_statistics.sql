--
CREATE OR REPLACE VIEW V_SCREEN_STATISTICS AS
select
ss.SCREEN_NAME
,ss.FLG_EXTRACTION_STATUS
,ss.ID_SOFTWARE
,ss.ID_INSTITUTION
,nvl(pk_translation.get_translation(2,so.code_institution) ,'NOT AVAILABLE') desc_institution
,pk_translation.get_translation(2,s.code_software) desc_software
,to_char(ss.dt_creation, 'YYYY-MM-dd')DT_CREATION_FMT from screen_statistics ss 
JOIN software s on s.id_software = ss.id_software
JOIN institution so on so.id_institution = ss.id_institution;