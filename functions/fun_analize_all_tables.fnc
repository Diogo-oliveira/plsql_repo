CREATE OR REPLACE FUNCTION FUN_ANALIZE_ALL_TABLES return boolean is

fich_name varchar2(200) := 'analize.txt';
desc_error varchar2(2000) := null;

cursor c1 is
select table_name,
       'analyze table '||table_name||' compute statistics for table for all indexes for all indexed columns'
       tabela
from user_tables
where table_name = 'ALLERGY'
order by table_name;

begin
    for i in c1 loop
        proc_write_log(fich_name, null, 'Início do analyze da tabela '||i.table_name||' : '||i.tabela, desc_error);
        
        EXECUTE IMMEDIATE i.tabela;

    end loop;
    
	 proc_write_log(fich_name, null, 'Fim do processo!', desc_error);
    return true;
    
  exception 
  when others then
    proc_write_log(fich_name, null, sqlerrm, desc_error);
    return false;
end;
/
