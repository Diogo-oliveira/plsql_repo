create or replace procedure Act_rep_name is

cursor c_rep is
select id_report, old_code,
    (select min (d.code_domain) from sys_domain d 
     where d.val = a.old_code and d.code_domain like 'PRINT.FLG_TYPE%' 
     and d.id_language = 1) code_val,
     r.code_reports
from (select distinct id_report, old_code from rb_rep_name z) a, reports r
where r.id_reports = a.id_report;

cursor c_lang (pcur_code_val varchar2, pcur_val varchar2) is
select l.id_language, d.desc_val
from sys_domain d, language l
where d.code_domain = pcur_code_val
and d.val = pcur_val
and d.id_language = l.id_language
order by l.id_language;

prox_rep_sec_det        rep_section_det.id_rep_section_det%type;
l_code_section            rep_section.code_rep_section%type;
l_error                 varchar2(2000);

begin

  for i in c_rep loop
  begin    
    --Actualiza as descrições na translation, tanto para as novas descrições como para as antigas
    for j in c_lang (i.code_val, i.old_code) loop
        update translation set desc_translation = j.desc_val
        where id_language = j.id_language 
        and code_translation = i.code_reports 
        and desc_translation is null;
        PROC_WRITE_LOG ('rep_name.txt', null, 'update translation set desc_translation = '''||j.desc_val ||''' where id_language = '''||j.id_language ||
        ''' and code_translation = '''||i.code_reports||
        ''' and desc_translation is null;', l_error);
    end loop;
    exception 
        when others then 
            rollback;
  end;
  end loop;
  
  --Guarda alterações e sai
  commit;
exception 
    when others then 
        rollback;  
end Act_rep_name;
/
DROP PROCEDURE ACT_REP_NAME;
