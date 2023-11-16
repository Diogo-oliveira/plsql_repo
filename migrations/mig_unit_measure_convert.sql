declare

-- #########################################
procedure do_msg( i_str in varchar2 ) is
l_str     varchar2(0240 char);
begin
  
l_str := substr( i_str, 1, 240 );
dbms_output.put_line( l_str );
end do_msg;
-- *****************************************


procedure run_script is

L_COUNT      NUMBER(24) := 0;

k_cns_name  constant varchar2(0050 char)  := 'UNITMC_PK';
k_owner      constant varchar2(0050 char) := 'ALERT';
k_pk        constant varchar2(200 char ) := 'ALTER TABLE UNIT_MEASURE_CONVERT ADD CONSTRAINT UNITMC_PK PRIMARY KEY (ID_UNIT_MEASURE_CONVERT)';

k_yes        constant varchar2(0001 char)  := 'Y';

l_msg          varchar2(1000 char);
l_flg_execute  varchar2(0001 char);
l_total_ini    number(24);
l_total_fim    number(24);
l_num          number(24);

cursor loop_count_dups is
        select id_unit_measure1, id_unit_measure2, count(1)  row_count
        from unit_measure_convert
        group by id_unit_measure1, id_unit_measure2  
        ;

cursor loop_dups( i_id_unit_measure1 in number, i_id_unit_measure2 in number )  is
        select rowid, id_unit_measure1, id_unit_measure2 
        from unit_measure_convert
        where id_unit_measure1 = i_id_unit_measure1
        and   id_unit_measure2 = i_id_unit_measure2
        order by id_unit_measure_convert;


RECORD_NOT_CREATED      EXCEPTION;
PK_NOT_CREATED          EXCEPTION;

begin

l_msg := 'Beginning Process...'; do_msg( l_msg);

l_flg_execute := 'Y';
l_num         := 0;

<<SEARCH_CNS_PK>>
SELECT COUNT(1) INTO L_COUNT FROM all_constraints where constraint_name = k_cns_name;

IF L_COUNT = 0 THEN

    l_msg := 'Constraint not found. Processing....'; do_msg( l_msg );
    

    
    select count(1) into l_total_ini from 
    (
    select umc.id_unit_measure1, umc.id_unit_measure2 
    from unit_measure_convert umc
    group by umc.id_unit_measure1, umc.id_unit_measure2
    ) xgrp;
    
    l_msg := 'Total apurado:'||to_char(l_total_ini);  do_msg( l_msg );

    <<LOOP_THRU_GROUPS>>
    FOR xcnt in loop_count_dups loop

        if xcnt.row_count > 1 then 

            l_msg := 'Cleaning Duplicated records KEY:'||TO_CHAR(xcnt.id_unit_measure1)||'+'||TO_CHAR(xcnt.id_unit_measure2)||' count:'||to_char(xcnt.row_count);
            do_msg( l_msg);      

            delete unit_measure_convert 
            where id_unit_measure1 = xcnt.id_unit_measure1 
            and id_unit_measure2   = xcnt.id_unit_measure2
            and rownum <= ( xcnt.row_count -1 );

            l_msg := 'Apagados:'||SQL%ROWCOUNT;
            do_msg( l_msg);      
            
        end if;
    
    end loop LOOP_THRU_GROUPS;
      
    select count(1) into l_total_fim from unit_measure_convert;
    l_msg := 'Total final:'||to_char(l_total_fim);  do_msg( l_msg );
    
    if l_total_fim = l_total_ini then
        l_msg := 'Table cleaned.';
        do_msg( l_msg );
        if l_flg_execute = k_yes then
            l_msg := 'Creating PK.';
            do_msg( l_msg );
            execute immediate k_pk;
        else
            l_msg := 'Simulating PK creation.';
            do_msg( l_msg );
        end if;
        
        SELECT COUNT(1) INTO L_COUNT FROM all_constraints where constraint_name = k_cns_name;
        if l_count = 0 then raise PK_NOT_CREATED; end if;
        
    else
        l_msg := 'Table still incorrect. Verify data...'; do_msg( l_msg );
        RAISE RECORD_NOT_CREATED;

    end if;
    
    l_msg := 'Done...'; do_msg( l_msg );


else

    l_msg := 'Constraint already exists. No processing needed.'; do_msg( l_msg );

end if;

l_msg := 'Ending Process...'; do_msg( l_msg);

exception
  when RECORD_NOT_CREATED OR PK_NOT_CREATED  then
    rollback; 
    l_msg := 'RECORDS NOT CREATED OR PK_NOT_CREATED';
    do_msg(l_msg);
  when OTHERS then 
    rollback; 
    l_msg := sqlerrm;  do_msg(l_msg);
    
end run_script;    

begin
  

do_msg( 'ola' );
run_script;
--rollback;

end;
