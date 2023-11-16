create or replace view v_institution_language as
select il.id_institution_language,il.id_language, il.id_institution, il.flg_available from institution_language il;
