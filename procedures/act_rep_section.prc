create or replace procedure Act_rep_section is

cursor c_rep is
select id_linha, 
       id_reports, 
       id_reports_section, 
       id_reports_section_old, 
       rank, 
       internal_name, 
       desc_rep
from rb_rep
order by id_linha;

cursor c_lang (pcur_desc_rep varchar2) is
select l.id_language, m.code_message, m.desc_message
from sys_message m, language l
where m.code_message = pcur_desc_rep
and m.id_language = l.id_language
order by l.id_language;

prox_rep_sec_det        rep_section_det.id_rep_section_det%type;
l_code_section            rep_section.code_rep_section%type;
l_error                 varchar2(2000);

begin

  for i in c_rep loop
  begin
    if i.id_reports_section is not null then
        --A secção ainda não existe e vai ser inserida
        insert into rep_section (id_rep_section, internal_name, rank)
        values (i.id_reports_section, i.internal_name, i.rank);
        PROC_WRITE_LOG ('rep_section.txt', null, 'insert into rep_section (id_rep_section, internal_name, rank) values ('||
                i.id_reports_section||', '''||i.internal_name||''', '||i.rank||');', l_error);
        
        l_code_section := 'REP_SECTION.CODE_REP_SECTION.'||i.id_reports_section;
        
        --Insere o detalhe do report
        select seq_rep_section_det.nextval into prox_rep_sec_det from dual;
        
        insert into rep_section_det (id_rep_section_det, id_reports, id_rep_section, id_software, id_institution, rank)
        values (prox_rep_sec_det, i.id_reports, i.id_reports_section, 0, 0, i.rank);
        PROC_WRITE_LOG ('rep_section.txt', null, 'insert into rep_section_det (id_rep_section_det, id_reports, id_rep_section, id_software, id_institution, rank) '||
                ' values ('||prox_rep_sec_det||', '||i.id_reports||', '||i.id_reports_section||', 0, 0, '||i.rank||');', l_error);
    else
        --A secção já existia por isso apenas insere apenas na det
        select seq_rep_section_det.nextval into prox_rep_sec_det from dual;
        
        insert into rep_section_det (id_rep_section_det, id_reports, id_rep_section, id_software, id_institution, rank)
        values (prox_rep_sec_det, i.id_reports, i.id_reports_section_old, 0, 0, i.rank);
        PROC_WRITE_LOG ('rep_section.txt', null, 'insert into rep_section_det (id_rep_section_det, id_reports, id_rep_section, id_software, id_institution, rank) '||
                ' values ('||prox_rep_sec_det||', '||i.id_reports||', '||i.id_reports_section_old||', 0, 0, '||i.rank||');', l_error);
                
        l_code_section := 'REP_SECTION.CODE_REP_SECTION.'||i.id_reports_section_old;
    end if;
    
    --Actualiza as descrições na translation, tanto para as novas descrições como para as antigas
    for j in c_lang (i.desc_rep) loop
        update translation set desc_translation = j.desc_message where id_language = j.id_language and code_translation = l_code_section and desc_translation is null;
        PROC_WRITE_LOG ('rep_section.txt', null, 'update translation set desc_translation = '''||j.desc_message||''' where id_language = '||j.id_language||' and code_translation = '''||l_code_section||''' and desc_translation is null;', l_error);
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
end Act_rep_section;
/
DROP PROCEDURE ACT_REP_SECTION;

