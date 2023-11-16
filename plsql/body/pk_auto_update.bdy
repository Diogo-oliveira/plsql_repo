/*-- Last Change Revision: $Rev: 901556 $*/
/*-- Last Change by: $Author: sergio.lopes $*/
/*-- Date of last change: $Date: 2011-03-02 10:12:19 +0000 (qua, 02 mar 2011) $*/

/
create or replace package body pk_auto_update is

  procedure start_balance(
    i_vers IN VARCHAR2, i_sup_vers IN VARCHAR2
  )
  as
    cursor c_upd_table is
      select *
        from upd_table ut
       where ut.flg_available = 'Y'
         and ut.vers = i_vers
         order by ut.id_upd_table asc;

    l_num_blocks  upd_config.num_blocks%type;

    e_running exception;
    l_cnt number(24);
    l_cnt_reg number(24);
    l_cnt_log number(24);
    l_avg number(24);
    l_query_update varchar2(4000);
    l_query varchar2(4000);

    l_fjob         number(24);
    --l_fexist       number(24);
    l_vers         upd_table.vers%type;
    

  begin

    select uc.num_blocks into l_num_blocks from upd_config uc;
      
------------------------------   STOP if Jobs are running
    select count(1)
      into l_fjob
      FROM dba_scheduler_jobs dsj
     where dsj.job_name like 'JOB_BALANCE_UPDATE_%'
     order by dsj.start_date;
     
    IF l_fjob <> 0 THEN
    RAISE e_running;
    END IF;
    
-------------------------------------- 
    dbms_output.put_line(sysdate || '- Número de blocos - > ' || l_num_blocks);
    dbms_output.put_line(sysdate || '- Mercado - > ' || i_vers);
------------------------------------ Upd_balance_job is never truncated
/* 
    l_query_update := 'select count(1) from upd_balance_job'; 
    execute immediate (l_query_update) into l_cnt;     */
   
    
    l_query := 'select count(1) from upd_med_log'; 
    execute immediate (l_query) into l_cnt_log;      -- UPD_MED_LOG
    
    l_vers := ''''||i_vers||''''; -- VERS
    
    l_query_update := 'delete from upd_balance_job where vers is null or vers= '||l_vers; -- clears dashboard UPD_BALANCE_JOB
    execute immediate (l_query_update);  

    l_query := 'select max(id) from upd_balance_job'; 
    execute immediate (l_query) into l_cnt;      -- UPD_BALANCE_JOB
    IF l_cnt is null THEN
    l_cnt := 0;
    END IF;

    for c_rec in c_upd_table 
    loop 

      for j in 1..l_num_blocks 
      loop
      
        l_cnt := l_cnt + 1;             -- UPD_BALANCE_JOB
        l_cnt_log := l_cnt_log + 1;     -- UPD_MED_LOG
        
        insert into upd_balance_job     -- updates dashboard UPD_BALANCE_JOB
          (id, table_name, id_process, vers)
        values
          (l_cnt, c_rec.source_table, j, i_vers);
        
        --  updates UPD_MED_LOG
        insert into upd_med_log
          (id_upd_med_log,
           table_name,
           UPDATE_READY_DATE,
           SUPPLIER_VERSION,
           id_process,
           vers)
        values
          (l_cnt_log,
           c_rec.source_table,
           null,
           i_sup_vers,
           j,
           i_vers);

        commit;
        
      end loop;

      l_query_update := 'select count(1) from ' || c_rec.source_table || ' where vers = '|| l_vers; 
      execute immediate (l_query_update) into l_cnt_reg; 

      l_avg := trunc(l_cnt_reg/l_num_blocks)+1; 

      for i in 1..l_num_blocks 
      loop
        l_query_update := 'update ' || c_rec.source_table ||
                          ' set id_process = ' || i ||
                          ' where rownum between 1 and ' || l_avg ||
                          ' and id_process is null
                          and vers=' ||l_vers;
        execute immediate (l_query_update);
        COMMIT;
        
        l_query_update := 'update ' || c_rec.source_table ||
                          ' set flg_Status = NULL where flg_status != ''Y''
                          and vers=' ||l_vers;
        execute immediate (l_query_update);

        COMMIT;

      end loop;
    end loop;
    
	BEGIN
    update upd_med_log     -- updates dashboard UPD_MED_LOG
    set UPDATE_READY_DATE = sysdate
    where vers = i_vers
    and UPDATE_READY_DATE is null;

    commit;
	END;
    
    EXCEPTION 

      WHEN e_running THEN  
        dbms_output.put_line('A medication update process is already running. Plese stop it or let it end before starting a new process.'); 
      WHEN OTHERS THEN 
        
        DBMS_OUTPUT.PUT_LINE('Error Message = ' || SQLERRM);
        ROLLBACK;

  end start_balance;


  procedure run_job_balance(
    i_vers IN VARCHAR2
  )
  as
    l_num_blocks  upd_config.num_blocks%type;
    e_running    exception;
    l_fjob       number(24);
    
  begin
  

------------------------------   STOP if Jobs are running
    select count(1)
      into l_fjob
      from dba_scheduler_jobs dsj
     where dsj.job_name like 'JOB_BALANCE_UPDATE_%'
     order by dsj.start_date;
     
    IF l_fjob <> 0 THEN
    RAISE e_running;
    END IF;
--------------------------------------------------------

    select uc.num_blocks
      into l_num_blocks
      from upd_config uc;

    dbms_output.put_line(sysdate || '- Número de blocos - > ' || l_num_blocks);
    dbms_output.put_line(sysdate || '- Mercado - > ' || i_vers);
    
    update upd_balance_job ubj -- reprocessa todas as tabelas que não terminaram.
       set ubj.started = null
     where ubj.ended is null
       and ubj.vers = i_vers;

    commit;

    for i in 1..l_num_blocks
    loop
      dbms_scheduler.create_job(
        job_name => 'JOB_BALANCE_UPDATE_' || i
       ,job_type => 'PLSQL_BLOCK'
       ,job_action => 'begin pk_auto_update.run_balance(' || i || ', ''' || i_vers || '''); end;'
       ,start_date => sysdate+(1/(60*24))
       ,repeat_interval => null --run only once
       ,enabled => TRUE
       ,comments => 'job schedule to balance updates.');
    end loop;
    
    --Actualiza UPD_MED_LOG
    update UPD_MED_LOG set UPDATE_EXECUTED_DATE = sysdate 
    where 
    VERS = i_vers  and 
    UPDATE_EXECUTED_DATE is null
    and UPDATE_READY_DATE in (select max(UPDATE_READY_DATE) from upd_med_log where vers = i_vers);
    
    commit;
    
    EXCEPTION
    WHEN e_running THEN  
    dbms_output.put_line('A medication update process is already running. Plese stop it or let it end before starting a new process.');
    WHEN OTHERS THEN ROLLBACK;
    
  end run_job_balance;

  procedure run_balance(
    i_id_process IN NUMBER,
    i_vers       IN VARCHAR2
  )
  as
    a boolean;
    l_id_process upd_balance_job.id_process%type;
    l_vers       upd_table.vers%type;
    l_vers2       upd_table.vers%type;
    l_table_name upd_table.target_table%type;
    err_num      upd_med_log.error_number%type;
    
    l_query_update varchar2(4000);
    

    cursor c_upd_table (l_c_id_process upd_balance_job.id_process%type, l_c_vers upd_table.vers%type) is
      select ut.*,ubj.id_process
        from upd_table ut
        ,    upd_balance_job ubj
       where ut.flg_available = 'Y'
         and ut.source_table = ubj.table_name
         and ubj.id_process = l_c_id_process
         and ubj.ended is null
         and ut.vers = l_c_vers
         and ut.vers = ubj.vers
       order by ut.id_upd_table asc;

  begin

    l_id_process := i_id_process;
    l_vers := i_vers;
    l_vers2 := ''''||i_vers||''''; -- VERS

    for c_rec in c_upd_table(l_id_process, l_vers)
    loop

      update upd_balance_job ubj
         set ubj.started = 'Y'
         ,   ubj.start_date = sysdate
         ,   ubj.end_date = NULL
       where ubj.id_process = l_id_process
         and ubj.table_name = c_rec.source_table
         and ubj.vers= l_Vers;


      commit;

      l_table_name:=c_rec.source_table;

      CASE c_rec.source_table
        when 'UPD_ME_MED' then a := update_me_med(l_id_process,l_vers);
        when 'UPD_ICD9_DXID' then a := update_icd9_dxid(l_id_process,l_vers);
        when 'UPD_ME_MED_ATC' then a := update_me_med_atc(l_id_process,l_vers);
        when 'UPD_ME_MED_REGULATION' then a := update_me_med_regulation(l_id_process,l_vers);
        when 'UPD_ME_MED_SUBST' then a := update_me_med_subst(l_id_process,l_vers);
        when 'UPD_ME_REGULATION' then a := update_me_regulation(l_id_process,l_vers);
        when 'UPD_ME_PRICE_TYPE' then a := update_ME_price_type(l_id_process,l_vers);
        when 'UPD_ME_MED_PRICE_HIST_DET' THEN  a := update_me_med_price_hist_det(l_id_process,l_vers);
        when 'UPD_DRUG_UNIT' then a := update_drug_unit(l_id_process,l_vers);
        when 'UPD_MI_MED' then a := update_mi_med(l_id_process,l_vers);
        when 'UPD_ME_ROUTE' then a := update_me_route(l_id_process,l_vers);
        when 'UPD_MI_ROUTE' then a := update_mi_route(l_id_process,l_vers);
        when 'UPD_MI_PHARM_GROUP' then a := update_mi_pharm_group(l_id_process,l_vers);
        when 'UPD_ME_PHARM_GROUP' then a := update_me_pharm_group(l_id_process,l_vers);
        when 'UPD_MED_INGRED' then a := update_med_ingred(l_id_process,l_vers);
        when 'UPD_MED_ALRGN_GRP' then a := update_med_alrgn_grp(l_id_process,l_vers);
        when 'UPD_MED_ALRGN_PICK_LIST' then a := update_med_alrgn_pick_list(l_id_process,l_vers);
        when 'UPD_OTHER_PRODUCT' then a := update_other_product(l_id_process,l_vers);
        when 'UPD_FORM_FARM_UNIT' then a := update_form_farm_unit(l_id_process,l_vers);
        when 'UPD_ME_DIETARY' then a := update_me_dietary(l_id_process,l_vers);
        when 'UPD_ME_MANIP_GROUP' then a := update_me_manip_group(l_id_process,l_vers);
        when 'UPD_ME_MANIP' then a := update_me_manip(l_id_process,l_vers);
        when 'UPD_ME_INGRED' then a := update_me_ingred(l_id_process,l_vers);
        when 'UPD_ME_MANIP_INGRED' then a := update_me_manip_ingred(l_id_process,l_vers);
        when 'UPD_ME_MED_PHARM_GROUP' then a := update_me_med_pharm_group(l_id_process,l_vers);
        when 'UPD_MI_MED_PHARM_GROUP' then a := update_mi_med_pharm_group(l_id_process,l_vers);
        when 'UPD_ME_MED_ATC_INTERACTION' then a := update_me_med_atc_interaction(l_id_process,l_vers);
        when 'UPD_MI_MED_ATC_INTERACTION' then a := update_mi_med_atc_interaction(l_id_process,l_vers);
        when 'UPD_MI_DXID_ATC_CONTRA' then a := update_mi_dxid_atc_contra(l_id_process,l_vers);
        when 'UPD_ME_DXID_ATC_CONTRA' then a := update_me_dxid_atc_contra(l_id_process,l_vers);
        when 'UPD_ME_MED_ROUTE' then a := update_me_med_route(l_id_process,l_vers);
        when 'UPD_MED_ALRGN_GRP_INGRED' then a := update_med_alrgn_grp_ingred(l_id_process,l_vers);
        when 'UPD_MED_ALRGN_CROSS_GRP' then a := update_med_alrgn_cross_grp(l_id_process,l_vers);
        when 'UPD_MI_MED_INGRED' then a := update_mi_med_ingred(l_id_process,l_vers);
        when 'UPD_ME_MED_INGRED' then a := update_me_med_ingred(l_id_process,l_vers);
        when 'UPD_MED_ALRGN_CROSS' then a := update_med_alrgn_cross(l_id_process,l_vers);
        when 'UPD_INTERACT_MESSAGE' then a := update_interact_message(l_id_process,l_vers);
        when 'UPD_INTERACT_MESSAGE_FORMAT' then a := update_interact_message_format(l_id_process,l_vers);
        when 'UPD_MI_MED_ROUTE' then a := update_mi_med_route(l_id_process,l_vers);

      END CASE;

      update upd_balance_job
         set ended = 'Y'
         ,   end_date = sysdate
       where id_process = l_id_process
         and table_name = c_rec.source_table
         and vers= i_Vers;

      commit;
      
    l_query_update := 'select count(1)
        from '|| c_rec.source_table ||
        ' where ERR_DESCRIPTION is not null
        and vers='|| l_vers2 ||
        ' and id_process= '||l_id_process; 
    execute immediate (l_query_update) into err_num;    

    
     BEGIN --Actualiza UPD_MED_LOG
    
      update UPD_MED_LOG set 
         UPDATE_END_DATE = sysdate,
         ERROR_NUMBER = err_num
       where VERS = i_vers
         and id_process = l_id_process
         and UPDATE_END_DATE is null
         and table_name = c_rec.source_table
         and UPDATE_EXECUTED_DATE in (select max(UPDATE_EXECUTED_DATE) from upd_med_log where vers = i_vers);
        
      commit;
     END;
     
    end loop;

  end run_balance;


  FUNCTION update_mi_med
  (
    i_id_process IN NUMBER,
    i_vers       IN VARCHAR2
  ) RETURN BOOLEAN IS
      l_block       upd_config.size_blocks%type;
      l_block_size  upd_config.size_blocks%type;
      l_id          upd_mi_med.id_drug%TYPE;
      
      l_sqlerrm     VARCHAR2(4000);

  BEGIN

      select uc.size_blocks
        into l_block_size
        from upd_config uc;

      l_block := 1;
      FOR c IN (SELECT *
                  FROM upd_mi_med
                 WHERE id_process = i_id_process
                   AND (flg_status is NULL OR flg_Status = 'E')  AND vers = i_Vers)
      LOOP

          l_id := c.id_drug;

          BEGIN
              SAVEPOINT sp_iteration;

               update mi_med tt
                  set tt.med_descr_formated  = c.med_descr_formated,
                      tt.med_descr           = c.med_descr,
                      tt.short_med_descr     = c.short_med_descr,
                      tt.flg_type            = c.flg_type,
                      tt.flg_available       = c.flg_available,
                      tt.flg_justify         = c.flg_justify,
                      tt.id_drug_brand       = c.id_drug_brand,
                      tt.dci_id              = c.dci_id,
                      tt.dci_descr           = c.dci_descr,
                      tt.form_farm_id        = c.form_farm_id,
                      tt.form_farm_id_id     = c.form_farm_id_id,
                      tt.form_farm_descr     = c.form_farm_descr,
                      tt.form_farm_abrv      = c.form_farm_abrv,
                      tt.route_id            = c.route_id,
                      tt.route_descr         = c.route_descr,
                      tt.route_abrv          = c.route_abrv,
                      tt.qt_dos_comp         = c.qt_dos_comp,
                      tt.unit_dos_comp       = c.unit_dos_comp,
                      tt.dosagem             = c.dosagem,
                      tt.gender              = c.gender,
                      tt.age_min             = c.age_min,
                      tt.age_max             = c.age_max,
                      tt.mdm_coding          = c.mdm_coding,
                      tt.chnm_id             = c.chnm_id,
                      tt.flg_mix_fluid       = c.flg_mix_fluid,
                      tt.id_unit_measure     = c.id_unit_measure,
                      tt.notes               = c.notes,
                      tt.flg_controlled_drug = c.flg_controlled_drug
                where tt.id_drug = c.id_drug
                  and tt.vers = c.vers;

              IF SQL%ROWCOUNT = 0
              THEN
                  INSERT INTO mi_med (id_drug,
                                      med_descr_formated,
                                      med_descr,
                                      short_med_descr,
                                      flg_type,
                                      flg_available,
                                      flg_justify,
                                      id_drug_brand,
                                      dci_id,
                                      dci_descr,
                                      form_farm_id,
                                      form_farm_id_id,
                                      form_farm_descr,
                                      form_farm_abrv,
                                      route_id,
                                      route_descr,
                                      route_abrv,
                                      qt_dos_comp,
                                      unit_dos_comp,
                                      dosagem,
                                      gender,
                                      age_min,
                                      age_max,
                                      mdm_coding,
                                      chnm_id,
                                      flg_mix_fluid,
                                      id_unit_measure,
                                      notes,
                                      vers,
                                      flg_controlled_drug
                                      )
                  VALUES
                      (c.id_drug,
                       c.med_descr_formated,
                       c.med_descr,
                       c.short_med_descr,
                       c.flg_type,
                       c.flg_available,
                       c.flg_justify,
                       c.id_drug_brand,
                       c.dci_id,
                       c.dci_descr,
                       c.form_farm_id,
                       c.form_farm_id_id,
                       c.form_farm_descr,
                       c.form_farm_abrv,
                       c.route_id,
                       c.route_descr,
                       c.route_abrv,
                       c.qt_dos_comp,
                       c.unit_dos_comp,
                       c.dosagem,
                       c.gender,
                       c.age_min,
                       c.age_max,
                       c.mdm_coding,
                       c.chnm_id,
                       c.flg_mix_fluid,
                       c.id_unit_measure,
                       c.notes,
                       c.vers,
                       c.flg_controlled_drug);
              END IF;

              UPDATE upd_mi_med ts
                 SET ts.flg_status = 'Y'
               WHERE ts.id_drug = c.id_drug
               AND ts.vers = c.vers;

              IF MOD(l_block, l_block_size) = 0
              THEN
                  COMMIT;
                  l_block := 0;


              END IF;

          EXCEPTION
              WHEN OTHERS THEN
                  l_sqlerrm := SQLERRM;

                  ROLLBACK TO SAVEPOINT sp_iteration;

                  UPDATE upd_mi_med ts
                     SET ts.flg_status = 'E', ts.err_description = 'Error: ' || l_sqlerrm
                   WHERE ts.id_drug = l_id
                   AND ts.vers = c.vers;
                  COMMIT;
          END;

          l_block := l_block + 1;

      END LOOP;

      COMMIT;

      RETURN TRUE;
  END update_mi_med;


  FUNCTION update_mi_route
  (
    i_id_process IN NUMBER, i_vers IN VARCHAR2
  ) RETURN BOOLEAN IS

      l_block       upd_config.size_blocks%type;
      l_block_size  upd_config.size_blocks%type;
      l_id_1        mi_route.route_id%TYPE;
      l_id_3        mi_route.vers%TYPE;
      
      
      
      l_sqlerrm     VARCHAR2(4000);

      
  BEGIN

      select uc.size_blocks
        into l_block_size
        from upd_config uc;

      l_block := 1;
      FOR c IN (SELECT *
                  FROM upd_mi_route
                 WHERE id_process = i_id_process
                   AND (flg_status is NULL OR flg_Status = 'E')  AND vers = i_Vers)
      LOOP

          l_id_1 := c.route_id;
          l_id_3 := c.vers;

/*          select to_number(to_char(systimestamp,'mi') || to_char(systimestamp,'ss') || ',' || to_char(systimestamp,'FF'))
            into l_start_time
            from dual;*/

          BEGIN
              SAVEPOINT sp_iteration;

               update mi_route tt
                  set tt.route_descr   = c.route_descr
                  ,   tt.route_abrv    = c.route_abrv
                  ,   tt.gender        = c.gender
                  ,   tt.age_min       = c.age_min
                  ,   tt.age_max       = c.age_max
                  ,   tt.flg_available = c.flg_available
                where tt.route_id = c.route_id
                  and tt.vers = c.vers;

              IF SQL%ROWCOUNT = 0
              THEN
                  INSERT INTO mi_route(route_id
                  ,                    route_descr
                  ,                    route_abrv
                  ,                    gender
                  ,                    age_min
                  ,                    age_max
                  ,                    flg_available
                  ,                    vers)
                       VALUES (c.route_id
                       ,       c.route_descr
                       ,       c.route_abrv
                       ,       c.gender
                       ,       c.age_min
                       ,       c.age_max
                       ,       c.flg_available
                       ,       c.vers);
              END IF;

              UPDATE upd_mi_route ts
                 SET ts.flg_status = 'Y'
               WHERE ts.route_id = c.route_id
                 AND ts.vers = c.vers;

              IF MOD(l_block, l_block_size) = 0
              THEN
                  COMMIT;
                  l_block := 0;

              END IF;

          EXCEPTION
              WHEN OTHERS THEN
                  l_sqlerrm := SQLERRM;

                  ROLLBACK TO SAVEPOINT sp_iteration;

                  UPDATE upd_mi_route ts
                     SET ts.flg_status = 'E', ts.err_description = 'Error: ' || l_sqlerrm
                   WHERE ts.route_id = l_id_1
                     AND ts.vers = l_id_3;
                  COMMIT;
          END;

          l_block := l_block + 1;

      END LOOP;

      COMMIT;

      RETURN TRUE;
  END update_mi_route;


  FUNCTION update_mi_pharm_group
  (
    i_id_process IN NUMBER, i_vers IN VARCHAR2
  ) RETURN BOOLEAN IS

      l_block       upd_config.size_blocks%type;
      l_block_size  upd_config.size_blocks%type;
      l_id_1        mi_pharm_group.group_id%TYPE;
      l_id_3        mi_pharm_group.vers%TYPE;
      
      
      
      l_sqlerrm     VARCHAR2(4000);

      
  BEGIN

      select uc.size_blocks
        into l_block_size
        from upd_config uc;

      l_block := 1;
      FOR c IN (SELECT *
                  FROM upd_mi_pharm_group
                 WHERE id_process = i_id_process
                   AND (flg_status is NULL OR flg_Status = 'E')  AND vers = i_Vers)
      LOOP

          l_id_1 := c.group_id;
          l_id_3 := c.vers;

/*          select to_number(to_char(systimestamp,'mi') || to_char(systimestamp,'ss') || ',' || to_char(systimestamp,'FF'))
            into l_start_time
            from dual;*/

          BEGIN
              SAVEPOINT sp_iteration;

               update mi_pharm_group tt
                  set tt.group_descr    = c.group_descr
                  ,   tt.flg_available  = c.flg_available
                  ,   tt.flg_antibiotic  = c.flg_antibiotic
                where tt.group_id = c.group_id
                  and tt.vers = c.vers;

              IF SQL%ROWCOUNT = 0
              THEN
                  INSERT INTO mi_pharm_group(group_id
                  ,                          group_descr
                  ,                          flg_available
                  ,                          vers
                  ,                          flg_antibiotic)
                       VALUES (c.group_id
                       ,       c.group_descr
                       ,       c.flg_available
                       ,       c.vers
                       ,       c.flg_antibiotic);
              END IF;

              UPDATE upd_mi_pharm_group ts
                 SET ts.flg_status = 'Y'
               WHERE ts.group_id = c.group_id
                 AND ts.vers = c.vers;

              IF MOD(l_block, l_block_size) = 0
              THEN
                  COMMIT;
                  l_block := 0;

              END IF;

          EXCEPTION
              WHEN OTHERS THEN
                  l_sqlerrm := SQLERRM;

                  ROLLBACK TO SAVEPOINT sp_iteration;

                  UPDATE upd_mi_pharm_group ts
                     SET ts.flg_status = 'E', ts.err_description = 'Error: ' || l_sqlerrm
                   WHERE ts.group_id = l_id_1
                     AND ts.vers = l_id_3;
                  COMMIT;
          END;

          l_block := l_block + 1;

      END LOOP;

      COMMIT;

      RETURN TRUE;
  END update_mi_pharm_group;


  FUNCTION update_med_ingred
  (
    i_id_process IN NUMBER, i_vers IN VARCHAR2
  ) RETURN BOOLEAN IS

      l_block       upd_config.size_blocks%type;
      l_block_size  upd_config.size_blocks%type;
      l_id_1        med_ingred.id_ingred%TYPE;
      l_id_3        med_ingred.vers%TYPE;
      
      
      
      l_sqlerrm     VARCHAR2(4000);

      
  BEGIN

      select uc.size_blocks
        into l_block_size
        from upd_config uc;

      l_block := 1;
      FOR c IN (SELECT *
                  FROM upd_med_ingred
                 WHERE id_process = i_id_process
                   AND (flg_status is NULL OR flg_Status = 'E')  AND vers = i_Vers)
      LOOP

          l_id_1 := c.id_ingred;
          l_id_3 := c.vers;

/*          select to_number(to_char(systimestamp,'mi') || to_char(systimestamp,'ss') || ',' || to_char(systimestamp,'FF'))
            into l_start_time
            from dual;*/

          BEGIN
              SAVEPOINT sp_iteration;

               update med_ingred tt
                  set tt.ingred_desc          = c.ingred_desc
                  ,   tt.flg_available        = c.flg_available
                  ,   tt.flg_hic_pot_inactiv  = c.flg_hic_pot_inactiv
                where tt.id_ingred = c.id_ingred
                  and tt.vers = c.vers;

              IF SQL%ROWCOUNT = 0
              THEN
                  INSERT INTO med_ingred(id_ingred
                  ,           ingred_desc
                  ,           flg_available
                  ,           vers
                  ,           flg_hic_pot_inactiv)
                       VALUES (c.id_ingred
                       ,       c.ingred_desc
                       ,       c.flg_available
                       ,       c.vers
                       ,       c.flg_hic_pot_inactiv);
              END IF;

              UPDATE upd_med_ingred ts
                 SET ts.flg_status = 'Y'
               WHERE ts.id_ingred = c.id_ingred
                 AND ts.vers = c.vers;

              IF MOD(l_block, l_block_size) = 0
              THEN
                  COMMIT;
                  l_block := 0;

              END IF;

          EXCEPTION
              WHEN OTHERS THEN
                  l_sqlerrm := SQLERRM;

                  ROLLBACK TO SAVEPOINT sp_iteration;

                  UPDATE upd_med_ingred ts
                     SET ts.flg_status = 'E', ts.err_description = 'Error: ' || l_sqlerrm
                   WHERE ts.id_ingred = l_id_1
                     AND ts.vers = l_id_3;
                  COMMIT;
          END;

          l_block := l_block + 1;

      END LOOP;

      COMMIT;

      RETURN TRUE;
  END update_med_ingred;


  FUNCTION update_med_alrgn_grp
  (
    i_id_process IN NUMBER, i_vers IN VARCHAR2
  ) RETURN BOOLEAN IS

      l_block       upd_config.size_blocks%type;
      l_block_size  upd_config.size_blocks%type;
      l_id_1        med_alrgn_grp.id_alrgn_grp%TYPE;
      l_id_3        med_alrgn_grp.vers%TYPE;

      l_sqlerrm     VARCHAR2(4000);

  BEGIN

      select uc.size_blocks
        into l_block_size
        from upd_config uc;

      l_block := 1;
      FOR c IN (SELECT *
                  FROM upd_med_alrgn_grp
                 WHERE id_process = i_id_process
                   AND (flg_status is NULL OR flg_Status = 'E')  AND vers = i_Vers)
      LOOP

          l_id_1 := c.id_alrgn_grp;
          l_id_3 := c.vers;

/*          select to_number(to_char(systimestamp,'mi') || to_char(systimestamp,'ss') || ',' || to_char(systimestamp,'FF'))
            into l_start_time
            from dual;*/

          BEGIN
              SAVEPOINT sp_iteration;

               update med_alrgn_grp tt
                  set tt.alrgn_grp_desc       = c.alrgn_grp_desc
                  ,   tt.flg_available       = c.flg_available
                  ,   tt.flg_grp_pot_inactiv = c.flg_grp_pot_inactiv
                where tt.id_alrgn_grp = c.id_alrgn_grp
                  and tt.vers = c.vers;

              IF SQL%ROWCOUNT = 0
              THEN
                  INSERT INTO med_alrgn_grp(id_alrgn_grp
                  ,                         alrgn_grp_desc
                  ,                         flg_available
                  ,                         vers
                  ,                         flg_grp_pot_inactiv)
                       VALUES (c.id_alrgn_grp
                       ,       c.alrgn_grp_desc
                       ,       c.flg_available
                       ,       c.vers
                       ,       c.flg_grp_pot_inactiv);
              END IF;

              UPDATE upd_med_alrgn_grp ts
                 SET ts.flg_status = 'Y'
               WHERE ts.id_alrgn_grp = c.id_alrgn_grp
                 AND ts.vers = c.vers;

              IF MOD(l_block, l_block_size) = 0
              THEN
                  COMMIT;
                  l_block := 0;

              END IF;

          EXCEPTION
              WHEN OTHERS THEN
                  l_sqlerrm := SQLERRM;

                  ROLLBACK TO SAVEPOINT sp_iteration;

                  UPDATE upd_med_alrgn_grp ts
                     SET ts.flg_status = 'E', ts.err_description = 'Error: ' || l_sqlerrm
                   WHERE ts.id_alrgn_grp = l_id_1
                     AND ts.vers = l_id_3;
                  COMMIT;
          END;

          l_block := l_block + 1;

      END LOOP;

      COMMIT;

      RETURN TRUE;
  END update_med_alrgn_grp;


  FUNCTION update_med_alrgn_pick_list
  (
    i_id_process IN NUMBER, i_vers IN VARCHAR2
  ) RETURN BOOLEAN IS

      l_block       upd_config.size_blocks%type;
      l_block_size  upd_config.size_blocks%type;
      l_id_1        med_alrgn_pick_list.id_ccpt_alrgn%TYPE;
      l_id_3        med_alrgn_pick_list.vers%TYPE;

      
      
      l_sqlerrm     VARCHAR2(4000);

      
  BEGIN

      select uc.size_blocks
        into l_block_size
        from upd_config uc;

      l_block := 1;
      FOR c IN (SELECT *
                  FROM upd_med_alrgn_pick_list
                 WHERE id_process = i_id_process
                   AND (flg_status is NULL OR flg_Status = 'E')  AND vers = i_Vers)
      LOOP

          l_id_1 := c.id_ccpt_alrgn;
          l_id_3 := c.vers;

/*          select to_number(to_char(systimestamp,'mi') || to_char(systimestamp,'ss') || ',' || to_char(systimestamp,'FF'))
            into l_start_time
            from dual;*/

          BEGIN
              SAVEPOINT sp_iteration;

               update med_alrgn_pick_list tt
                  set tt.ccpt_alrgn_desc  = c.ccpt_alrgn_desc
                  ,   tt.id_ccpt_alrgn_typ  = c.id_ccpt_alrgn_typ
                  ,   tt.flg_available  = c.flg_available
                where tt.id_ccpt_alrgn = c.id_ccpt_alrgn
                  and tt.vers = c.vers;

              IF SQL%ROWCOUNT = 0
              THEN
                  INSERT INTO med_alrgn_pick_list(id_ccpt_alrgn
                  ,                               ccpt_alrgn_desc
                  ,                               id_ccpt_alrgn_typ
                  ,                               vers
                  ,                               flg_available)
                       VALUES (c.id_ccpt_alrgn
                       ,       c.ccpt_alrgn_desc
                       ,       c.id_ccpt_alrgn_typ
                       ,       c.vers
                       ,       c.flg_available);
              END IF;

              UPDATE upd_med_alrgn_pick_list ts
                 SET ts.flg_status = 'Y'
               WHERE ts.id_ccpt_alrgn = c.id_ccpt_alrgn
                 AND ts.vers = c.vers;

              IF MOD(l_block, l_block_size) = 0
              THEN
                  COMMIT;
                  l_block := 0;

              END IF;

          EXCEPTION
              WHEN OTHERS THEN
                  l_sqlerrm := SQLERRM;

                  ROLLBACK TO SAVEPOINT sp_iteration;

                  UPDATE upd_med_alrgn_pick_list ts
                     SET ts.flg_status = 'E', ts.err_description = 'Error: ' || l_sqlerrm
                   WHERE ts.id_ccpt_alrgn = l_id_1
                     AND ts.vers = l_id_3;
                  COMMIT;
          END;

          l_block := l_block + 1;

      END LOOP;

      COMMIT;

      RETURN TRUE;
  END update_med_alrgn_pick_list;


  FUNCTION update_other_product
  (
    i_id_process IN NUMBER, i_vers IN VARCHAR2
  ) RETURN BOOLEAN IS

      l_block       upd_config.size_blocks%type;
      l_block_size  upd_config.size_blocks%type;
      l_id_1        other_product.id_other_product%TYPE;
      l_id_3        other_product.vers%TYPE;

      
      
      l_sqlerrm     VARCHAR2(4000);

      
  BEGIN

      select uc.size_blocks
        into l_block_size
        from upd_config uc;

      l_block := 1;
      FOR c IN (SELECT *
                  FROM upd_other_product
                 WHERE id_process = i_id_process
                   AND (flg_status is NULL OR flg_Status = 'E')  AND vers = i_Vers)
      LOOP

          l_id_1 := c.id_other_product;
          l_id_3 := c.vers;

/*          select to_number(to_char(systimestamp,'mi') || to_char(systimestamp,'ss') || ',' || to_char(systimestamp,'FF'))
            into l_start_time
            from dual;*/

          BEGIN
              SAVEPOINT sp_iteration;

               update other_product tt
                  set tt.other_product_desc  = c.other_product_desc
                  ,   tt.flg_type            = c.flg_type
                  ,   tt.flg_available      = c.flg_available
                where tt.id_other_product = c.id_other_product
                  and tt.vers = c.vers;

              IF SQL%ROWCOUNT = 0
              THEN
                  INSERT INTO other_product(id_other_product
                  ,                         other_product_desc
                  ,                         flg_type
                  ,                         flg_available
                  ,                         vers)
                       VALUES (c.id_other_product
                       ,       c.other_product_desc
                       ,       c.flg_type
                       ,       c.flg_available
                       ,       c.vers);
              END IF;

              UPDATE upd_other_product ts
                 SET ts.flg_status = 'Y'
               WHERE ts.id_other_product = c.id_other_product
                 AND ts.vers = c.vers;

              IF MOD(l_block, l_block_size) = 0
              THEN
                  COMMIT;
                  l_block := 0;

              END IF;

          EXCEPTION
              WHEN OTHERS THEN
                  l_sqlerrm := SQLERRM;

                  ROLLBACK TO SAVEPOINT sp_iteration;

                  UPDATE upd_other_product ts
                     SET ts.flg_status = 'E', ts.err_description = 'Error: ' || l_sqlerrm
                   WHERE ts.id_other_product = l_id_1
                     AND ts.vers = l_id_3;
                  COMMIT;
          END;

          l_block := l_block + 1;

      END LOOP;

      COMMIT;

      RETURN TRUE;
  END update_other_product;


  FUNCTION update_me_manip_group
  (
    i_id_process IN NUMBER, i_vers IN VARCHAR2
  ) RETURN BOOLEAN IS

      l_block       upd_config.size_blocks%type;
      l_block_size  upd_config.size_blocks%type;
      l_id_1        me_manip_group.id_manipulated_group%TYPE;
      l_id_3        me_manip_group.vers%TYPE;

      
      
      l_sqlerrm     VARCHAR2(4000);

      
  BEGIN

      select uc.size_blocks
        into l_block_size
        from upd_config uc;

      l_block := 1;
      FOR c IN (SELECT *
                  FROM upd_me_manip_group
                 WHERE id_process = i_id_process
                   AND (flg_status is NULL OR flg_Status = 'E')  AND vers = i_Vers)
      LOOP

          l_id_1 := c.id_manipulated_group;
          l_id_3 := c.vers;

/*          select to_number(to_char(systimestamp,'mi') || to_char(systimestamp,'ss') || ',' || to_char(systimestamp,'FF'))
            into l_start_time
            from dual;*/

          BEGIN
              SAVEPOINT sp_iteration;

               update me_manip_group tt
                  set tt.group_descr          = c.group_descr
                  ,   tt.flg_available        = c.flg_available
                where tt.id_manipulated_group = c.id_manipulated_group
                  and tt.vers = c.vers;

              IF SQL%ROWCOUNT = 0
              THEN
                  INSERT INTO me_manip_group(id_manipulated_group
                  ,                          group_descr
                  ,                          vers
                  ,                          flg_available)
                       VALUES (c.id_manipulated_group
                       ,       c.group_descr
                       ,       c.vers
                       ,       c.flg_available);
              END IF;

              UPDATE upd_me_manip_group ts
                 SET ts.flg_status = 'Y'
               WHERE ts.id_manipulated_group = c.id_manipulated_group
                 AND ts.vers = c.vers;

              IF MOD(l_block, l_block_size) = 0
              THEN
                  COMMIT;
                  l_block := 0;

              END IF;

          EXCEPTION
              WHEN OTHERS THEN
                  l_sqlerrm := SQLERRM;

                  ROLLBACK TO SAVEPOINT sp_iteration;

                  UPDATE upd_me_manip_group ts
                     SET ts.flg_status = 'E', ts.err_description = 'Error: ' || l_sqlerrm
                   WHERE ts.id_manipulated_group = l_id_1
                     AND ts.vers = l_id_3;
                  COMMIT;
          END;

          l_block := l_block + 1;

      END LOOP;

      COMMIT;

      RETURN TRUE;
  END update_me_manip_group;


  FUNCTION update_me_dietary
  (
    i_id_process IN NUMBER, i_vers IN VARCHAR2
  ) RETURN BOOLEAN IS

      l_block       upd_config.size_blocks%type;
      l_block_size  upd_config.size_blocks%type;
      l_id_1        me_dietary.id_dietary_drug%TYPE;
      l_id_3        me_dietary.vers%TYPE;

      
      
      l_sqlerrm     VARCHAR2(4000);

      
  BEGIN

      select uc.size_blocks
        into l_block_size
        from upd_config uc;

      l_block := 1;
      FOR c IN (SELECT *
                  FROM upd_me_dietary
                 WHERE id_process = i_id_process
                   AND (flg_status is NULL OR flg_Status = 'E')  AND vers = i_Vers)
      LOOP

          l_id_1 := c.id_dietary_drug;
          l_id_3 := c.vers;

/*          select to_number(to_char(systimestamp,'mi') || to_char(systimestamp,'ss') || ',' || to_char(systimestamp,'FF'))
            into l_start_time
            from dual;*/

          BEGIN
              SAVEPOINT sp_iteration;

               update me_dietary tt
                  set tt.qty              = c.qty
                  ,   tt.measure_unit      = c.measure_unit
                  ,   tt.flg_type          = c.flg_type
                  ,   tt.dietary_descr    = c.dietary_descr
                  ,   tt.flg_available    = c.flg_available
                where tt.id_dietary_drug = c.id_dietary_drug
                  and tt.vers = c.vers;

              IF SQL%ROWCOUNT = 0
              THEN
                  INSERT INTO me_dietary(id_dietary_drug
                  ,                      qty
                  ,                      measure_unit
                  ,                      flg_type
                  ,                      dietary_descr
                  ,                      vers
                  ,                      flg_available)
                       VALUES (c.id_dietary_drug
                       ,       c.qty
                       ,       c.measure_unit
                       ,       c.flg_type
                       ,       c.dietary_descr
                       ,       c.vers
                       ,       c.flg_available);
              END IF;

              UPDATE upd_me_dietary ts
                 SET ts.flg_status = 'Y'
               WHERE ts.id_dietary_drug = c.id_dietary_drug
                 AND ts.vers = c.vers;

              IF MOD(l_block, l_block_size) = 0
              THEN
                  COMMIT;
                  l_block := 0;

              END IF;

          EXCEPTION
              WHEN OTHERS THEN
                  l_sqlerrm := SQLERRM;

                  ROLLBACK TO SAVEPOINT sp_iteration;

                  UPDATE upd_me_dietary ts
                     SET ts.flg_status = 'E', ts.err_description = 'Error: ' || l_sqlerrm
                   WHERE ts.id_dietary_drug = l_id_1
                     AND ts.vers = l_id_3;
                  COMMIT;
          END;

          l_block := l_block + 1;

      END LOOP;

      COMMIT;

      RETURN TRUE;
  END update_me_dietary;


  FUNCTION update_me_manip
  (
    i_id_process IN NUMBER, i_vers IN VARCHAR2
  ) RETURN BOOLEAN IS

      l_block       upd_config.size_blocks%type;
      l_block_size  upd_config.size_blocks%type;
      l_id_1        me_manip.id_manipulated%TYPE;
      l_id_3        me_manip.vers%TYPE;

      
      
      l_sqlerrm     VARCHAR2(4000);

      
  BEGIN

      select uc.size_blocks
        into l_block_size
        from upd_config uc;

      l_block := 1;
      FOR c IN (SELECT *
                  FROM upd_me_manip
                 WHERE id_process = i_id_process
                   AND (flg_status is NULL OR flg_Status = 'E')  AND vers = i_Vers)
      LOOP

          l_id_1 := c.id_manipulated;
          l_id_3 := c.vers;

/*          select to_number(to_char(systimestamp,'mi') || to_char(systimestamp,'ss') || ',' || to_char(systimestamp,'FF'))
            into l_start_time
            from dual;*/

          BEGIN
              SAVEPOINT sp_iteration;

               update me_manip tt
                  set tt.id_manipulated_group  = c.id_manipulated_group
                  ,   tt.flg_type  = c.flg_type
                  ,   tt.manip_descr  = c.manip_descr
                  ,   tt.flg_available  = c.flg_available
                  ,   tt.form_farm_id  = c.form_farm_id
                  ,   tt.form_farm_descr  = c.form_farm_descr
                  ,   tt.form_farm_abrv  = c.form_farm_abrv
                  ,   tt.route_id  = c.route_id
                  ,   tt.route_descr  = c.route_descr
                  ,   tt.route_abrv  = c.route_abrv
                where tt.id_manipulated = c.id_manipulated
                  and tt.vers = c.vers;

              IF SQL%ROWCOUNT = 0
              THEN
                  INSERT INTO me_manip(id_manipulated
                  ,                    id_manipulated_group
                  ,                    flg_type
                  ,                    manip_descr
                  ,                    vers
                  ,                    flg_available
                  ,                    form_farm_id
                  ,                    form_farm_descr
                  ,                    form_farm_abrv
                  ,                    route_id
                  ,                    route_descr
                  ,                    route_abrv)
                       VALUES (c.id_manipulated
                       ,       c.id_manipulated_group
                       ,       c.flg_type
                       ,       c.manip_descr
                       ,       c.vers
                       ,       c.flg_available
                       ,       c.form_farm_id
                       ,       c.form_farm_descr
                       ,       c.form_farm_abrv
                       ,       c.route_id
                       ,       c.route_descr
                       ,       c.route_abrv);
              END IF;

              UPDATE upd_me_manip ts
                 SET ts.flg_status = 'Y'
               WHERE ts.id_manipulated = c.id_manipulated
                 AND ts.vers = c.vers;

              IF MOD(l_block, l_block_size) = 0
              THEN
                  COMMIT;
                  l_block := 0;

              END IF;

          EXCEPTION
              WHEN OTHERS THEN
                  l_sqlerrm := SQLERRM;

                  ROLLBACK TO SAVEPOINT sp_iteration;

                  UPDATE upd_me_manip ts
                     SET ts.flg_status = 'E', ts.err_description = 'Error: ' || l_sqlerrm
                   WHERE ts.id_manipulated = l_id_1
                     AND ts.vers = l_id_3;
                  COMMIT;
          END;

          l_block := l_block + 1;

      END LOOP;

      COMMIT;

      RETURN TRUE;
  END update_me_manip;


  FUNCTION update_me_ingred
  (
    i_id_process IN NUMBER, i_vers IN VARCHAR2
  ) RETURN BOOLEAN IS

      l_block       upd_config.size_blocks%type;
      l_block_size  upd_config.size_blocks%type;
      l_id_1        me_ingred.id_ingredient%TYPE;
      l_id_3        me_ingred.vers%TYPE;

      
      
      l_sqlerrm     VARCHAR2(4000);

      
  BEGIN

      select uc.size_blocks
        into l_block_size
        from upd_config uc;

      l_block := 1;
      FOR c IN (SELECT *
                  FROM upd_me_ingred
                 WHERE id_process = i_id_process
                   AND (flg_status is NULL OR flg_Status = 'E')  AND vers = i_Vers)
      LOOP

          l_id_1 := c.id_ingredient;
          l_id_3 := c.vers;

/*          select to_number(to_char(systimestamp,'mi') || to_char(systimestamp,'ss') || ',' || to_char(systimestamp,'FF'))
            into l_start_time
            from dual;*/

          BEGIN
              SAVEPOINT sp_iteration;

               update me_ingred tt
                  set tt.flg_type       = c.flg_type
                  ,   tt.ingred_descr   = c.ingred_descr
                  ,   tt.flg_available = c.flg_available
                where tt.id_ingredient = c.id_ingredient
                  and tt.vers = c.vers;

              IF SQL%ROWCOUNT = 0
              THEN
                  INSERT INTO me_ingred(id_ingredient
                  ,                     flg_type
                  ,                     ingred_descr
                  ,                     vers
                  ,                     flg_available)
                       VALUES (c.id_ingredient
                       ,       c.flg_type
                       ,       c.ingred_descr
                       ,       c.vers
                       ,       c.flg_available);
              END IF;

              UPDATE upd_me_ingred ts
                 SET ts.flg_status = 'Y'
               WHERE ts.id_ingredient = c.id_ingredient
                 AND ts.vers = c.vers;

              IF MOD(l_block, l_block_size) = 0
              THEN
                  COMMIT;
                  l_block := 0;

              END IF;

          EXCEPTION
              WHEN OTHERS THEN
                  l_sqlerrm := SQLERRM;

                  ROLLBACK TO SAVEPOINT sp_iteration;

                  UPDATE upd_me_ingred ts
                     SET ts.flg_status = 'E', ts.err_description = 'Error: ' || l_sqlerrm
                   WHERE ts.id_ingredient = l_id_1
                     AND ts.vers = l_id_3;
                  COMMIT;
          END;

          l_block := l_block + 1;

      END LOOP;

      COMMIT;

      RETURN TRUE;
  END update_me_ingred;


  FUNCTION update_me_manip_ingred
  (
    i_id_process IN NUMBER, i_vers IN VARCHAR2
  ) RETURN BOOLEAN IS

      l_block       upd_config.size_blocks%type;
      l_block_size  upd_config.size_blocks%type;
      l_id_1        me_manip_ingred.id_ingredient%TYPE;
      l_id_2        me_manip_ingred.id_manipulated%TYPE;
      l_id_3        me_manip_ingred.vers%TYPE;

      
      
      l_sqlerrm     VARCHAR2(4000);

      
  BEGIN

      select uc.size_blocks
        into l_block_size
        from upd_config uc;

      l_block := 1;
      FOR c IN (SELECT *
                  FROM upd_me_manip_ingred
                 WHERE id_process = i_id_process
                   AND (flg_status is NULL OR flg_Status = 'E')  AND vers = i_Vers)
      LOOP

          l_id_1 := c.id_ingredient;
          l_id_2 := c.id_manipulated;
          l_id_3 := c.vers;

/*          select to_number(to_char(systimestamp,'mi') || to_char(systimestamp,'ss') || ',' || to_char(systimestamp,'FF'))
            into l_start_time
            from dual;*/

          BEGIN
              SAVEPOINT sp_iteration;

               update me_manip_ingred tt
                  set tt.percent       = c.percent
                  ,   tt.flg_available = c.flg_available
                where tt.id_ingredient = c.id_ingredient
                  and tt.id_manipulated = c.id_manipulated
                  and tt.vers = c.vers;

              IF SQL%ROWCOUNT = 0
              THEN
                  INSERT INTO me_manip_ingred (id_ingredient
                  ,                            id_manipulated
                  ,                            percent
                  ,                            vers
                  ,                            flg_available)
                  VALUES (c.id_ingredient
                  ,       c.id_manipulated
                  ,       c.percent
                  ,       c.vers
                  ,       c.flg_available);
              END IF;

              UPDATE upd_me_manip_ingred ts
                 SET ts.flg_status = 'Y'
               WHERE ts.id_ingredient = c.id_ingredient
                 AND ts.id_manipulated = c.id_manipulated
                 AND ts.vers = c.vers;

              IF MOD(l_block, l_block_size) = 0
              THEN
                  COMMIT;
                  l_block := 0;

              END IF;

          EXCEPTION
              WHEN OTHERS THEN
                  l_sqlerrm := SQLERRM;

                  ROLLBACK TO SAVEPOINT sp_iteration;

                  UPDATE upd_me_manip_ingred ts
                     SET ts.flg_status = 'E', ts.err_description = 'Error: ' || l_sqlerrm
                   WHERE ts.id_ingredient = l_id_1
                     AND ts.id_manipulated = l_id_2
                     AND ts.vers = l_id_3;
                  COMMIT;
          END;

          l_block := l_block + 1;

      END LOOP;

      COMMIT;

      RETURN TRUE;
  END update_me_manip_ingred;


  FUNCTION update_mi_med_pharm_group
  (
    i_id_process IN NUMBER, i_vers IN VARCHAR2
  ) RETURN BOOLEAN IS

      l_block       upd_config.size_blocks%type;
      l_block_size  upd_config.size_blocks%type;
      l_id_1        mi_med_pharm_group.id_drug%TYPE;
      l_id_2        mi_med_pharm_group.group_id%TYPE;
      l_id_3        mi_med_pharm_group.vers%TYPE;

      
      
      l_sqlerrm     VARCHAR2(4000);

      
  BEGIN

      select uc.size_blocks
        into l_block_size
        from upd_config uc;

      l_block := 1;
      FOR c IN (SELECT *
                  FROM upd_mi_med_pharm_group
                 WHERE id_process = i_id_process
                   AND (flg_status is NULL OR flg_Status = 'E')  AND vers = i_Vers)
      LOOP

          l_id_1 := c.id_drug;
          l_id_2 := c.group_id;
          l_id_3 := c.vers;

/*          select to_number(to_char(systimestamp,'mi') || to_char(systimestamp,'ss') || ',' || to_char(systimestamp,'FF'))
            into l_start_time
            from dual;*/

          BEGIN
              SAVEPOINT sp_iteration;

               -- nas tabelas de relações como estas, não são efectuadas operações de update
               -- as alterações de relação são: remoção ou inserção.
               update mi_med_pharm_group tt
                  set tt.id_drug  = c.id_drug
                  ,   tt.group_id  = c.group_id
                  ,   tt.vers  = c.vers
                where tt.id_drug = c.id_drug
                  and tt.group_id = c.group_id
                  and tt.vers = c.vers;

              IF SQL%ROWCOUNT = 0
              THEN
                  INSERT INTO mi_med_pharm_group(id_drug
                  ,                              group_id
                  ,                              vers)
                  VALUES(c.id_drug
                  ,      c.group_id
                  ,      c.vers);
              END IF;

              UPDATE upd_mi_med_pharm_group ts
                 SET ts.flg_status = 'Y'
               WHERE ts.id_drug  = c.id_drug
                 AND ts.group_id = c.group_id
                 AND ts.vers     = c.vers;

              IF MOD(l_block, l_block_size) = 0
              THEN
                  COMMIT;
                  l_block := 0;

              END IF;

          EXCEPTION
              WHEN OTHERS THEN
                  l_sqlerrm := SQLERRM;

                  ROLLBACK TO SAVEPOINT sp_iteration;

                  UPDATE upd_mi_med_pharm_group ts
                     SET ts.flg_status = 'E'
                     ,   ts.err_description = 'Error: ' || l_sqlerrm
                   WHERE ts.id_drug  = l_id_1
                     AND ts.group_id = l_id_2
                     AND ts.vers     = l_id_3;
                  COMMIT;
          END;

          l_block := l_block + 1;

      END LOOP;

      COMMIT;

      RETURN TRUE;
  END update_mi_med_pharm_group;


  FUNCTION update_me_med_atc_interaction
  (
    i_id_process IN NUMBER, i_vers IN VARCHAR2
  ) RETURN BOOLEAN IS

      l_block       upd_config.size_blocks%type;
      l_block_size  upd_config.size_blocks%type;
      l_id_1        me_med_atc_interaction.emb_id%TYPE;
      l_id_2        me_med_atc_interaction.ddi%TYPE;
      l_id_3        me_med_atc_interaction.vers%TYPE;
      l_id_4        me_med_atc_interaction.interddi%TYPE;

      
      
      l_sqlerrm     VARCHAR2(4000);

      
  BEGIN

      select uc.size_blocks
        into l_block_size
        from upd_config uc;



      l_block := 1;
      
      FOR c IN (SELECT *
                  FROM upd_me_med_atc_interaction
                 WHERE id_process = i_id_process
                   AND (flg_status is NULL OR flg_Status = 'E')  AND vers = i_Vers)
      LOOP

          l_id_1 := c.emb_id;
          l_id_2 := c.ddi;
          l_id_3 := c.vers;
          l_id_4 := c.interddi;

/*          select to_number(to_char(systimestamp,'mi') || to_char(systimestamp,'ss') || ',' || to_char(systimestamp,'FF'))
            into l_start_time
            from dual;*/

          BEGIN
              SAVEPOINT sp_iteration;

               update me_med_atc_interaction tt
                  set tt.atcd                        = c.atcd
                  ,   tt.atcdescd                    = c.atcdescd
                  ,   tt.ddi_desd                    = c.ddi_desd
                  ,   tt.ddi_sld                    = c.ddi_sld
                  ,   tt.emb_id_interact            = c.emb_id_interact
                  ,   tt.id_interact_message        = c.id_interact_message
                  ,   tt.id_interact_message_format = c.id_interact_message_format
                where tt.emb_id   = c.emb_id
                  and tt.ddi      = c.ddi
                  and tt.vers     = c.vers
                  and tt.interddi = c.interddi;

              IF SQL%ROWCOUNT = 0
              THEN
                  INSERT INTO me_med_atc_interaction(emb_id
                  ,                                  atcd
                  ,                                  atcdescd
                  ,                                  ddi
                  ,                                  interddi
                  ,                                  ddi_desd
                  ,                                  ddi_sld
                  ,                                  vers
                  ,                                  emb_id_interact
                  ,                                  id_interact_message
                  ,                                  id_interact_message_format)
                  VALUES(c.emb_id
                  ,      c.atcd
                  ,      c.atcdescd
                  ,      c.ddi
                  ,      c.interddi
                  ,      c.ddi_desd
                  ,      c.ddi_sld
                  ,      c.vers
                  ,      c.emb_id_interact
                  ,      c.id_interact_message
                  ,      c.id_interact_message_format);
              END IF;

              UPDATE upd_me_med_atc_interaction ts
                 SET ts.flg_status = 'Y'
               WHERE ts.emb_id   = c.emb_id
                 AND ts.ddi      = c.ddi
                 AND ts.vers     = c.vers
                 ANd ts.interddi = c.interddi;

              IF MOD(l_block, l_block_size) = 0
              THEN
                  COMMIT;
                  l_block := 0;

              END IF;

          EXCEPTION
              WHEN OTHERS THEN
                  l_sqlerrm := SQLERRM;

                  ROLLBACK TO SAVEPOINT sp_iteration;

                  UPDATE upd_me_med_atc_interaction ts
                     SET ts.flg_status = 'E'
                     ,   ts.err_description = 'Error: ' || l_sqlerrm
                   WHERE ts.emb_id   = l_id_1
                     AND ts.ddi      = l_id_2
                     AND ts.vers     = l_id_3
                     AND ts.interddi = l_id_4;
                  COMMIT;
          END;

          l_block := l_block + 1;

      END LOOP;

      COMMIT;

      RETURN TRUE;
      
  END update_me_med_atc_interaction;


  FUNCTION update_mi_med_atc_interaction
  (
    i_id_process IN NUMBER, i_vers IN VARCHAR2
  ) RETURN BOOLEAN IS

      l_block       upd_config.size_blocks%type;
      l_block_size  upd_config.size_blocks%type;
      l_id_1        mi_med_atc_interaction.id_drug%TYPE;
      l_id_2        mi_med_atc_interaction.ddi%TYPE;
      l_id_3        mi_med_atc_interaction.vers%TYPE;
      l_id_4        mi_med_atc_interaction.interddi%TYPE;

      
      
      l_sqlerrm     VARCHAR2(4000);

      
  BEGIN

      select uc.size_blocks
        into l_block_size
        from upd_config uc;

      l_block := 1;
      FOR c IN (SELECT *
                  FROM upd_mi_med_atc_interaction
                 WHERE id_process = i_id_process
                   AND (flg_status is NULL OR flg_Status = 'E')  AND vers = i_Vers)
      LOOP

          l_id_1 := c.id_drug;
          l_id_2 := c.ddi;
          l_id_3 := c.vers;
          l_id_4 := c.interddi;

/*          select to_number(to_char(systimestamp,'mi') || to_char(systimestamp,'ss') || ',' || to_char(systimestamp,'FF'))
            into l_start_time
            from dual;*/

          BEGIN
              SAVEPOINT sp_iteration;

               update mi_med_atc_interaction tt
                  set tt.atcd                        = c.atcd
                  ,   tt.atcdescd                    = c.atcdescd
                  ,   tt.ddi_desd                    = c.ddi_desd
                  ,   tt.ddi_sld                    = c.ddi_sld
                  ,   tt.id_drug_interact            = c.id_drug_interact
                  ,   tt.id_interact_message        = c.id_interact_message
                  ,   tt.id_interact_message_format = c.id_interact_message_format
                where tt.id_drug  = c.id_drug
                  and tt.ddi      = c.ddi
                  and tt.vers     = c.vers
                  and tt.interddi = c.interddi;

              IF SQL%ROWCOUNT = 0
              THEN
                  INSERT INTO mi_med_atc_interaction(id_drug
                  ,                                  atcd
                  ,                                  atcdescd
                  ,                                  ddi
                  ,                                  interddi
                  ,                                  ddi_desd
                  ,                                  ddi_sld
                  ,                                  vers
                  ,                                  id_drug_interact
                  ,                                  id_interact_message
                  ,                                  id_interact_message_format)
                  VALUES(c.id_drug
                  ,      c.atcd
                  ,      c.atcdescd
                  ,      c.ddi
                  ,      c.interddi
                  ,      c.ddi_desd
                  ,      c.ddi_sld
                  ,      c.vers
                  ,      c.id_drug_interact
                  ,      c.id_interact_message
                  ,      c.id_interact_message_format);
              END IF;

              UPDATE upd_mi_med_atc_interaction ts
                 SET ts.flg_status = 'Y'
               WHERE ts.id_drug   = c.id_drug
                 AND ts.ddi       = c.ddi
                 AND ts.vers      = c.vers
                 ANd ts.interddi  = c.interddi;

              IF MOD(l_block, l_block_size) = 0
              THEN
                  COMMIT;
                  l_block := 0;

              END IF;

          EXCEPTION
              WHEN OTHERS THEN
                  l_sqlerrm := SQLERRM;

                  ROLLBACK TO SAVEPOINT sp_iteration;

                  UPDATE upd_mi_med_atc_interaction ts
                     SET ts.flg_status = 'E'
                     ,   ts.err_description = 'Error: ' || l_sqlerrm
                   WHERE ts.id_drug  = l_id_1
                     AND ts.ddi      = l_id_2
                     AND ts.vers     = l_id_3
                     AND ts.interddi = l_id_4;
                  COMMIT;
          END;

          l_block := l_block + 1;

      END LOOP;

      COMMIT;

      RETURN TRUE;
  END update_mi_med_atc_interaction;


  FUNCTION update_me_dxid_atc_contra
  (
    i_id_process IN NUMBER, i_vers IN VARCHAR2
  ) RETURN BOOLEAN IS

      l_block       upd_config.size_blocks%type;
      l_block_size  upd_config.size_blocks%type;
      l_id_1        me_dxid_atc_contra.dxid%TYPE;
      l_id_2        me_dxid_atc_contra.emb_id%TYPE;
      l_id_3        me_dxid_atc_contra.vers%TYPE;

      
      
      l_sqlerrm     VARCHAR2(4000);

      
  BEGIN

      select uc.size_blocks
        into l_block_size
        from upd_config uc;

      l_block := 1;
      FOR c IN (SELECT *
                  FROM upd_me_dxid_atc_contra
                 WHERE id_process = i_id_process
                   AND (flg_status is NULL OR flg_Status = 'E')  AND vers = i_Vers)
      LOOP

          l_id_1 := c.dxid;
          l_id_2 := c.emb_id;
          l_id_3 := c.vers;

/*          select to_number(to_char(systimestamp,'mi') || to_char(systimestamp,'ss') || ',' || to_char(systimestamp,'FF'))
            into l_start_time
            from dual;*/

          BEGIN
              SAVEPOINT sp_iteration;

               update me_dxid_atc_contra tt
                  set tt.ddxcn_sl   = c.ddxcn_sl
                  ,   tt.atc       = c.atc
                  ,   tt.atc_desc   = c.atc_desc
                  ,   tt.dxid_desc = c.dxid_desc
                  ,   tt.ddxcn_sn   = c.ddxcn_sn
                where tt.dxid   = c.dxid
                  and tt.emb_id = c.emb_id
                  and tt.vers   = c.vers;

              IF SQL%ROWCOUNT = 0
              THEN
                  INSERT INTO me_dxid_atc_contra(dxid
                  ,                              emb_id
                  ,                              ddxcn_sl
                  ,                              atc
                  ,                              atc_desc
                  ,                              vers
                  ,                              dxid_desc
                  ,                              ddxcn_sn)
                  VALUES(c.dxid
                  ,      c.emb_id
                  ,      c.ddxcn_sl
                  ,      c.atc
                  ,      c.atc_desc
                  ,      c.vers
                  ,      c.dxid_desc
                  ,      c.ddxcn_sn);
              END IF;

              UPDATE upd_me_dxid_atc_contra ts
                 SET ts.flg_status = 'Y'
               WHERE ts.dxid   = c.dxid
                 AND ts.emb_id = c.emb_id
                 AND ts.vers   = c.vers;

              IF MOD(l_block, l_block_size) = 0
              THEN
                  COMMIT;
                  l_block := 0;

              END IF;

          EXCEPTION
              WHEN OTHERS THEN
                  l_sqlerrm := SQLERRM;

                  ROLLBACK TO SAVEPOINT sp_iteration;

                  UPDATE upd_me_dxid_atc_contra ts
                     SET ts.flg_status = 'E'
                     ,   ts.err_description = 'Error: ' || l_sqlerrm
                   WHERE ts.dxid   = l_id_1
                     AND ts.emb_id = l_id_2
                     AND ts.vers   = l_id_3;
                  COMMIT;
          END;

          l_block := l_block + 1;

      END LOOP;

      COMMIT;

      RETURN TRUE;
  END update_me_dxid_atc_contra;


  FUNCTION update_mi_dxid_atc_contra
  (
    i_id_process IN NUMBER, i_vers IN VARCHAR2
  ) RETURN BOOLEAN IS

      l_block       upd_config.size_blocks%type;
      l_block_size  upd_config.size_blocks%type;
      l_id_1        mi_dxid_atc_contra.dxid%TYPE;
      l_id_2        mi_dxid_atc_contra.id_drug%TYPE;
      l_id_3        mi_dxid_atc_contra.vers%TYPE;

      
      
      l_sqlerrm     VARCHAR2(4000);

      
  BEGIN

      select uc.size_blocks
        into l_block_size
        from upd_config uc;

      l_block := 1;
      FOR c IN (SELECT *
                  FROM upd_mi_dxid_atc_contra
                 WHERE id_process = i_id_process
                   AND (flg_status is NULL OR flg_Status = 'E')  AND vers = i_Vers)
      LOOP

          l_id_1 := c.dxid;
          l_id_2 := c.id_drug;
          l_id_3 := c.vers;

/*          select to_number(to_char(systimestamp,'mi') || to_char(systimestamp,'ss') || ',' || to_char(systimestamp,'FF'))
            into l_start_time
            from dual;*/

          BEGIN
              SAVEPOINT sp_iteration;

               update mi_dxid_atc_contra tt
                  set tt.ddxcn_sl   = c.ddxcn_sl
                  ,   tt.atc       = c.atc
                  ,   tt.atc_desc   = c.atc_desc
                  ,   tt.dxid_desc = c.dxid_desc
                  ,   tt.ddxcn_sn   = c.ddxcn_sn
                where tt.dxid    = c.dxid
                  and tt.id_drug = c.id_drug
                  and tt.vers    = c.vers;

              IF SQL%ROWCOUNT = 0
              THEN
                  INSERT INTO mi_dxid_atc_contra(dxid
                  ,                              id_drug
                  ,                              ddxcn_sl
                  ,                              atc
                  ,                              atc_desc
                  ,                              vers
                  ,                              dxid_desc
                  ,                              ddxcn_sn)
                  VALUES(c.dxid
                  ,      c.id_drug
                  ,      c.ddxcn_sl
                  ,      c.atc
                  ,      c.atc_desc
                  ,      c.vers
                  ,      c.dxid_desc
                  ,      c.ddxcn_sn);
              END IF;

              UPDATE upd_mi_dxid_atc_contra ts
                 SET ts.flg_status = 'Y'
               WHERE ts.dxid    = c.dxid
                 AND ts.id_drug = c.id_drug
                 AND ts.vers    = c.vers;

              IF MOD(l_block, l_block_size) = 0
              THEN
                  COMMIT;
                  l_block := 0;

              END IF;

          EXCEPTION
              WHEN OTHERS THEN
                  l_sqlerrm := SQLERRM;

                  ROLLBACK TO SAVEPOINT sp_iteration;

                  UPDATE upd_mi_dxid_atc_contra ts
                     SET ts.flg_status = 'E'
                     ,   ts.err_description = 'Error: ' || l_sqlerrm
                   WHERE ts.dxid    = l_id_1
                     AND ts.id_drug = l_id_2
                     AND ts.vers    = l_id_3;
                  COMMIT;
          END;

          l_block := l_block + 1;

      END LOOP;

      COMMIT;

      RETURN TRUE;
  END update_mi_dxid_atc_contra;


  FUNCTION update_med_alrgn_grp_ingred
  (
    i_id_process IN NUMBER, i_vers IN VARCHAR2
  ) RETURN BOOLEAN IS

      l_block       upd_config.size_blocks%type;
      l_block_size  upd_config.size_blocks%type;
      l_id_1        med_alrgn_grp_ingred.id_alrgn_grp%TYPE;
      l_id_2        med_alrgn_grp_ingred.id_ingred%TYPE;
      l_id_3        med_alrgn_grp_ingred.vers%TYPE;

      
      
      l_sqlerrm     VARCHAR2(4000);

      
  BEGIN

      select uc.size_blocks
        into l_block_size
        from upd_config uc;

      l_block := 1;
      FOR c IN (SELECT *
                  FROM upd_med_alrgn_grp_ingred
                 WHERE id_process = i_id_process
                   AND (flg_status is NULL OR flg_Status = 'E')  AND vers = i_Vers)
      LOOP

          l_id_1 := c.id_alrgn_grp;
          l_id_2 := c.id_ingred;
          l_id_3 := c.vers;

/*          select to_number(to_char(systimestamp,'mi') || to_char(systimestamp,'ss') || ',' || to_char(systimestamp,'FF'))
            into l_start_time
            from dual;*/

          BEGIN
              SAVEPOINT sp_iteration;

               update med_alrgn_grp_ingred tt
                  set tt.id_alrgn_grp  = c.id_alrgn_grp
                  ,   tt.id_ingred  = c.id_ingred
                  ,   tt.vers  = c.vers
                where tt.id_alrgn_grp = c.id_alrgn_grp
                  and tt.id_ingred = c.id_ingred
                  and tt.vers = c.vers;

              IF SQL%ROWCOUNT = 0
              THEN
                  INSERT INTO med_alrgn_grp_ingred(id_alrgn_grp
                  ,                                id_ingred
                  ,                                vers)
                  VALUES (c.id_alrgn_grp
                  ,       c.id_ingred
                  ,       c.vers);
              END IF;

              UPDATE upd_med_alrgn_grp_ingred ts
                 SET ts.flg_status = 'Y'
               WHERE ts.id_alrgn_grp = c.id_alrgn_grp
                 AND ts.id_ingred = c.id_ingred
                 AND ts.vers = c.vers;

              IF MOD(l_block, l_block_size) = 0
              THEN
                  COMMIT;
                  l_block := 0;

              END IF;

          EXCEPTION
              WHEN OTHERS THEN
                  l_sqlerrm := SQLERRM;

                  ROLLBACK TO SAVEPOINT sp_iteration;

                  UPDATE upd_med_alrgn_grp_ingred ts
                     SET ts.flg_status = 'E', ts.err_description = 'Error: ' || l_sqlerrm
                   WHERE ts.id_alrgn_grp = l_id_1
                     AND ts.id_ingred = l_id_2
                     AND ts.vers = l_id_3;
                  COMMIT;
          END;

          l_block := l_block + 1;

      END LOOP;

      COMMIT;

      RETURN TRUE;
  END update_med_alrgn_grp_ingred;


  FUNCTION update_med_alrgn_cross_grp
  (
    i_id_process IN NUMBER, i_vers IN VARCHAR2
  ) RETURN BOOLEAN IS

      l_block       upd_config.size_blocks%type;
      l_block_size  upd_config.size_blocks%type;
      l_id_1        med_alrgn_cross_grp.id_alrgn_grp%TYPE;
      l_id_2        med_alrgn_cross_grp.id_alrgn_cross_grp%TYPE;
      l_id_3        med_alrgn_cross_grp.vers%TYPE;
      l_id_4        med_alrgn_cross_grp.id_ingred%TYPE;

      
      
      l_sqlerrm     VARCHAR2(4000);

      
  BEGIN

      select uc.size_blocks
        into l_block_size
        from upd_config uc;

      l_block := 1;
      FOR c IN (SELECT *
                  FROM upd_med_alrgn_cross_grp
                 WHERE id_process = i_id_process
                   AND (flg_status is NULL OR flg_Status = 'E')  AND vers = i_Vers)
      LOOP

          l_id_1 := c.id_alrgn_grp;
          l_id_2 := c.id_alrgn_cross_grp;
          l_id_3 := c.vers;
          l_id_4 := c.id_ingred;

/*          select to_number(to_char(systimestamp,'mi') || to_char(systimestamp,'ss') || ',' || to_char(systimestamp,'FF'))
            into l_start_time
            from dual;*/

          BEGIN
              SAVEPOINT sp_iteration;

               update med_alrgn_cross_grp tt
                  set tt.alrgn_cross_grp_desc  = c.alrgn_cross_grp_desc
                  ,   tt.flg_available        = c.flg_available
                  ,   tt.flg_grp_pot_inactiv  = c.flg_grp_pot_inactiv
                where tt.id_alrgn_grp       = c.id_alrgn_grp
                  and tt.id_alrgn_cross_grp = c.id_alrgn_cross_grp
                  and tt.vers               = c.vers
                  and tt.id_ingred          = c.id_ingred;

              IF SQL%ROWCOUNT = 0
              THEN
                  INSERT INTO med_alrgn_cross_grp(id_alrgn_grp
                  ,                               id_alrgn_cross_grp
                  ,                               vers
                  ,                               alrgn_cross_grp_desc
                  ,                               id_ingred
                  ,                               flg_available
                  ,                               flg_grp_pot_inactiv)
                  VALUES (c.id_alrgn_grp
                  ,       c.id_alrgn_cross_grp
                  ,       c.vers
                  ,       c.alrgn_cross_grp_desc
                  ,       c.id_ingred
                  ,       c.flg_available
                  ,       c.flg_grp_pot_inactiv);
              END IF;

              UPDATE upd_med_alrgn_cross_grp ts
                 SET ts.flg_status = 'Y'
               WHERE ts.id_alrgn_grp       = c.id_alrgn_grp
                 AND ts.id_alrgn_cross_grp = c.id_alrgn_cross_grp
                 AND ts.vers               = c.vers
                 AND ts.id_ingred          = c.id_ingred;

              IF MOD(l_block, l_block_size) = 0
              THEN
                  COMMIT;
                  l_block := 0;

              END IF;

          EXCEPTION
              WHEN OTHERS THEN
                  l_sqlerrm := SQLERRM;

                  ROLLBACK TO SAVEPOINT sp_iteration;

                  UPDATE upd_med_alrgn_cross_grp ts
                     SET ts.flg_status = 'E'
                     ,   ts.err_description = 'Error: ' || l_sqlerrm
                   WHERE ts.id_alrgn_grp       = l_id_1
                     AND ts.id_alrgn_cross_grp = l_id_2
                     AND ts.vers               = l_id_3
                     AND ts.id_ingred          = l_id_4;
                  COMMIT;
          END;

          l_block := l_block + 1;

      END LOOP;

      COMMIT;

      RETURN TRUE;
  END update_med_alrgn_cross_grp;


  FUNCTION update_mi_med_ingred
  (
    i_id_process IN NUMBER, i_vers IN VARCHAR2
  ) RETURN BOOLEAN IS

      l_block       upd_config.size_blocks%type;
      l_block_size  upd_config.size_blocks%type;
      l_id_1        mi_med_ingred.id_drug%TYPE;
      l_id_2        mi_med_ingred.id_ingred%TYPE;
      l_id_3        mi_med_ingred.vers%TYPE;
      l_id_4        mi_med_ingred.dci_id%TYPE;

      
      
      l_sqlerrm     VARCHAR2(4000);

      
  BEGIN

      select uc.size_blocks
        into l_block_size
        from upd_config uc;

      l_block := 1;
      FOR c IN (SELECT *
                  FROM upd_mi_med_ingred
                 WHERE id_process = i_id_process
                   AND (flg_status is NULL OR flg_Status = 'E')  AND vers = i_Vers)
      LOOP

          l_id_1 := c.id_drug;
          l_id_2 := c.id_ingred;
          l_id_3 := c.vers;
          l_id_4 := c.dci_id;

/*          select to_number(to_char(systimestamp,'mi') || to_char(systimestamp,'ss') || ',' || to_char(systimestamp,'FF'))
            into l_start_time
            from dual;*/

          BEGIN
              SAVEPOINT sp_iteration;

               update mi_med_ingred tt
                  set tt.dci_desc        = c.dci_desc
                  ,   tt.flg_available  = c.flg_available
                where tt.id_drug   = c.id_drug
                  and tt.id_ingred = c.id_ingred
                  and tt.vers      = c.vers
                  and tt.dci_id    = c.dci_id;

              IF SQL%ROWCOUNT = 0
              THEN
                  INSERT INTO mi_med_ingred(id_drug
                  ,                         dci_id
                  ,                         dci_desc
                  ,                         id_ingred
                  ,                         flg_available
                  ,                         vers)
                  VALUES (c.id_drug
                  ,       c.dci_id
                  ,       c.dci_desc
                  ,       c.id_ingred
                  ,       c.flg_available
                  ,       c.vers);
              END IF;

              UPDATE upd_mi_med_ingred ts
                 SET ts.flg_status = 'Y'
               WHERE ts.id_drug   = c.id_drug
                 AND ts.id_ingred = c.id_ingred
                 AND ts.vers      = c.vers
                 AND ts.dci_id    = c.dci_id;

              IF MOD(l_block, l_block_size) = 0
              THEN
                  COMMIT;
                  l_block := 0;

              END IF;

          EXCEPTION
              WHEN OTHERS THEN
                  l_sqlerrm := SQLERRM;

                  ROLLBACK TO SAVEPOINT sp_iteration;

                  UPDATE upd_mi_med_ingred ts
                     SET ts.flg_status = 'E'
                     ,   ts.err_description = 'Error: ' || l_sqlerrm
                   WHERE ts.id_drug   = l_id_1
                     AND ts.id_ingred = l_id_2
                     AND ts.vers      = l_id_3
                     AND ts.dci_id    = l_id_4;
                  COMMIT;
          END;

          l_block := l_block + 1;

      END LOOP;

      COMMIT;

      RETURN TRUE;
  END update_mi_med_ingred;


  FUNCTION update_me_med_ingred
  (
    i_id_process IN NUMBER, i_vers IN VARCHAR2
  ) RETURN BOOLEAN IS

      l_block       upd_config.size_blocks%type;
      l_block_size  upd_config.size_blocks%type;
      l_id_1        me_med_ingred.emb_id%TYPE;
      l_id_2        me_med_ingred.id_ingred%TYPE;
      l_id_3        me_med_ingred.vers%TYPE;
      l_id_4        me_med_ingred.dci_id%TYPE;

      
      
      l_sqlerrm     VARCHAR2(4000);

      
  BEGIN

      select uc.size_blocks
        into l_block_size
        from upd_config uc;

      l_block := 1;
      FOR c IN (SELECT *
                  FROM upd_me_med_ingred
                 WHERE id_process = i_id_process
                   AND (flg_status is NULL OR flg_Status = 'E')  AND vers = i_Vers)
      LOOP

          l_id_1 := c.emb_id;
          l_id_2 := c.id_ingred;
          l_id_3 := c.vers;
          l_id_4 := c.dci_id;

/*          select to_number(to_char(systimestamp,'mi') || to_char(systimestamp,'ss') || ',' || to_char(systimestamp,'FF'))
            into l_start_time
            from dual;*/

          BEGIN
              SAVEPOINT sp_iteration;

               update me_med_ingred tt
                  set tt.dci_desc  = c.dci_desc
                  ,   tt.flg_available  = c.flg_available
                where tt.emb_id    = c.emb_id
                  and tt.id_ingred = c.id_ingred
                  and tt.vers      = c.vers
                  and tt.dci_id    = c.dci_id;

              IF SQL%ROWCOUNT = 0
              THEN
                  INSERT INTO me_med_ingred(emb_id
                  ,                         dci_id
                  ,                         dci_desc
                  ,                         id_ingred
                  ,                         flg_available
                  ,                         vers)
                  VALUES (c.emb_id
                  ,       c.dci_id
                  ,       c.dci_desc
                  ,       c.id_ingred
                  ,       c.flg_available
                  ,       c.vers);
              END IF;

              UPDATE upd_me_med_ingred ts
                 SET ts.flg_status = 'Y'
               WHERE ts.emb_id    = c.emb_id
                 AND ts.id_ingred = c.id_ingred
                 AND ts.dci_id    = c.dci_id
                 AND ts.vers      = c.vers;

              IF MOD(l_block, l_block_size) = 0
              THEN
                  COMMIT;
                  l_block := 0;

              END IF;

          EXCEPTION
              WHEN OTHERS THEN
                  l_sqlerrm := SQLERRM;

                  ROLLBACK TO SAVEPOINT sp_iteration;

                  UPDATE upd_me_med_ingred ts
                     SET ts.flg_status = 'E'
                     ,   ts.err_description = 'Error: ' || l_sqlerrm
                   WHERE ts.emb_id    = l_id_1
                     AND ts.id_ingred = l_id_2
                     AND ts.vers      = l_id_3
                     AND ts.dci_id    = l_id_4;
                  COMMIT;
          END;

          l_block := l_block + 1;

      END LOOP;

      COMMIT;

      RETURN TRUE;
  END update_me_med_ingred;


  FUNCTION update_med_alrgn_cross
  (
    i_id_process IN NUMBER, i_vers IN VARCHAR2
  ) RETURN BOOLEAN IS

      l_block       upd_config.size_blocks%type;
      l_block_size  upd_config.size_blocks%type;
      l_id_1        med_alrgn_cross.id_alrgn%TYPE;
      l_id_2        med_alrgn_cross.id_cross_ingred%TYPE;
      l_id_3        med_alrgn_cross.vers%TYPE;

      
      
      l_sqlerrm     VARCHAR2(4000);

      
  BEGIN

      select uc.size_blocks
        into l_block_size
        from upd_config uc;

      l_block := 1;
      FOR c IN (SELECT *
                  FROM upd_med_alrgn_cross
                 WHERE id_process = i_id_process
                   AND (flg_status is NULL OR flg_Status = 'E')  AND vers = i_Vers)
      LOOP

          l_id_1 := c.id_alrgn;
          l_id_2 := c.id_cross_ingred;
          l_id_3 := c.vers;

/*          select to_number(to_char(systimestamp,'mi') || to_char(systimestamp,'ss') || ',' || to_char(systimestamp,'FF'))
            into l_start_time
            from dual;*/

          BEGIN
              SAVEPOINT sp_iteration;

               update med_alrgn_cross tt
                  set tt.flg_available  = c.flg_available
                  ,   tt.flg_hic_pot_inactiv  = c.flg_hic_pot_inactiv
                where tt.id_alrgn        = c.id_alrgn
                  and tt.id_cross_ingred = c.id_cross_ingred
                  and tt.vers      = c.vers;

              IF SQL%ROWCOUNT = 0
              THEN
                  INSERT INTO med_alrgn_cross(id_alrgn
                  ,                           id_cross_ingred
                  ,                           vers
                  ,                           flg_available
                  ,                           flg_hic_pot_inactiv)
                  VALUES (c.id_alrgn
                  ,       c.id_cross_ingred
                  ,       c.vers
                  ,       c.flg_available
                  ,       c.flg_hic_pot_inactiv);
              END IF;

              UPDATE upd_med_alrgn_cross ts
                 SET ts.flg_status = 'Y'
               WHERE ts.id_alrgn        = c.id_alrgn
                 AND ts.id_cross_ingred = c.id_cross_ingred
                 AND ts.vers            = c.vers;

              IF MOD(l_block, l_block_size) = 0
              THEN
                  COMMIT;
                  l_block := 0;

              END IF;

          EXCEPTION
              WHEN OTHERS THEN
                  l_sqlerrm := SQLERRM;

                  ROLLBACK TO SAVEPOINT sp_iteration;

                  UPDATE upd_med_alrgn_cross ts
                     SET ts.flg_status = 'E'
                     ,   ts.err_description = 'Error: ' || l_sqlerrm
                   WHERE ts.id_alrgn        = l_id_1
                     AND ts.id_cross_ingred = l_id_2
                     AND ts.vers            = l_id_3;
                  COMMIT;
          END;

          l_block := l_block + 1;

      END LOOP;

      COMMIT;

      RETURN TRUE;
  END update_med_alrgn_cross;


  FUNCTION update_me_med
  (
    i_id_process IN NUMBER, i_vers IN VARCHAR2
  ) RETURN BOOLEAN IS
      l_block       upd_config.size_blocks%type;
      l_block_size  upd_config.size_blocks%type;
      l_id          upd_me_med.emb_id%TYPE;

      l_sqlerrm     VARCHAR2(4000);
      
  BEGIN

      select uc.size_blocks
        into l_block_size
        from upd_config uc;

      l_block := 1;
      FOR c IN (SELECT *
                  FROM upd_me_med
                 WHERE id_process = i_id_process
                   AND (flg_status is NULL OR flg_Status = 'E')  AND vers = i_Vers)
      LOOP

          l_id := c.emb_id;

/*          select to_number(to_char(systimestamp,'mi') || to_char(systimestamp,'ss') || ',' || to_char(systimestamp,'FF'))
            into l_start_time
            from dual;*/

          BEGIN
              SAVEPOINT sp_iteration;

               update me_med tt
                  set tt.med_id             = c.med_id,
                      tt.med_name           = c.med_name,
                      tt.med_descr_formated = c.med_descr_formated,
                      tt.med_descr          = c.med_descr,
                      tt.short_med_descr    = c.short_med_descr,
                      tt.emb_descr          = c.emb_descr,
                      tt.otc_descr          = c.otc_descr,
                      tt.generico           = c.generico,
                      tt.generico_descr     = c.generico_descr,
                      tt.dci_id             = c.dci_id,
                      tt.dci_descr          = c.dci_descr,
                      tt.form_farm_id       = c.form_farm_id,
                      tt.form_farm_id_id    = c.form_farm_id_id,
                      tt.form_farm_descr    = c.form_farm_descr,
                      tt.form_farm_abrv     = c.form_farm_abrv,
                      tt.tipo_prod_id       = c.tipo_prod_id,
                      tt.qt_dos_comp        = c.qt_dos_comp,
                      tt.unit_dos_comp      = c.unit_dos_comp,
                      tt.n_units            = c.n_units,
                      tt.qt_per_unit        = c.qt_per_unit,
                      tt.dosagem            = c.dosagem,
                      tt.titular_id         = c.titular_id,
                      tt.titular_descr      = c.titular_descr,
                      tt.data_aim           = c.data_aim,
                      tt.estado_id          = c.estado_id,
                      tt.estado_descr       = c.estado_descr,
                      tt.disp_id            = c.disp_id,
                      tt.disp_descr         = c.disp_descr,
                      tt.estup_id           = c.estup_id,
                      tt.estup_descr        = c.estup_descr,
                      tt.trat_id            = c.trat_id,
                      tt.trat_descr         = c.trat_descr,
                      tt.emb_unit_id        = c.emb_unit_id,
                      tt.emb_unit_descr     = c.emb_unit_descr,
                      tt.grupo_hom_id       = c.grupo_hom_id,
                      tt.grupo_hom_descr    = c.grupo_hom_descr,
                      tt.n_registo          = c.n_registo,
                      tt.compart            = c.compart,
                      tt.flg_comerc         = c.flg_comerc,
                      tt.flg_available      = c.flg_available,
                      tt.dispo_id           = c.dispo_id,
                      tt.dispo_data         = c.dispo_data,
                      tt.price_pvp          = c.price_pvp,
                      tt.price_ref          = c.price_ref,
                      tt.price_pens         = c.price_pens,
                      tt.price_pvpmax100    = c.price_pvpmax100,
                      tt.pmu_euro           = c.pmu_euro,
                      tt.id_unit_measure    = c.id_unit_measure
                where tt.emb_id = c.emb_id
                  and tt.vers = c.vers;

              IF SQL%ROWCOUNT = 0
              THEN
                  INSERT INTO me_med (emb_id,
                                          med_id,
                                          med_name,
                                          med_descr_formated,
                                          med_descr,
                                          short_med_descr,
                                          emb_descr,
                                          otc_descr,
                                          generico,
                                          generico_descr,
                                          dci_id,
                                          dci_descr,
                                          form_farm_id,
                                          form_farm_id_id,
                                          form_farm_descr,
                                          form_farm_abrv,
                                          tipo_prod_id,
                                          qt_dos_comp,
                                          unit_dos_comp,
                                          n_units,
                                          qt_per_unit,
                                          dosagem,
                                          titular_id,
                                          titular_descr,
                                          data_aim,
                                          estado_id,
                                          estado_descr,
                                          disp_id,
                                          disp_descr,
                                          estup_id,
                                          estup_descr,
                                          trat_id,
                                          trat_descr,
                                          emb_unit_id,
                                          emb_unit_descr,
                                          grupo_hom_id,
                                          grupo_hom_descr,
                                          n_registo,
                                          compart,
                                          flg_comerc,
                                          flg_available,
                                          dispo_id,
                                          dispo_data,
                                          vers,
                                          price_pvp,
                                          price_ref,
                                          price_pens,
                                          price_pvpmax100,
                                          pmu_euro,
                                          id_unit_measure)
                  VALUES
                      (c.emb_id,
                       c.med_id,
                       c.med_name,
                       c.med_descr_formated,
                       c.med_descr,
                       c.short_med_descr,
                       c.emb_descr,
                       c.otc_descr,
                       c.generico,
                       c.generico_descr,
                       c.dci_id,
                       c.dci_descr,
                       c.form_farm_id,
                       c.form_farm_id_id,
                       c.form_farm_descr,
                       c.form_farm_abrv,
                       c.tipo_prod_id,
                       c.qt_dos_comp,
                       c.unit_dos_comp,
                       c.n_units,
                       c.qt_per_unit,
                       c.dosagem,
                       c.titular_id,
                       c.titular_descr,
                       c.data_aim,
                       c.estado_id,
                       c.estado_descr,
                       c.disp_id,
                       c.disp_descr,
                       c.estup_id,
                       c.estup_descr,
                       c.trat_id,
                       c.trat_descr,
                       c.emb_unit_id,
                       c.emb_unit_descr,
                       c.grupo_hom_id,
                       c.grupo_hom_descr,
                       c.n_registo,
                       c.compart,
                       c.flg_comerc,
                       c.flg_available,
                       c.dispo_id,
                       c.dispo_data,
                       c.vers,
                       c.price_pvp,
                       c.price_ref,
                       c.price_pens,
                       c.price_pvpmax100,
                       c.pmu_euro,
                       c.id_unit_measure);
              END IF;

              UPDATE upd_me_med ts
                 SET ts.flg_status = 'Y'
               WHERE ts.emb_id = c.emb_id
               AND ts.vers = c.vers;

              IF MOD(l_block, l_block_size) = 0
              THEN
                  COMMIT;
                  l_block := 0;

              END IF;

          EXCEPTION
              WHEN OTHERS THEN
                  l_sqlerrm := SQLERRM;

                  ROLLBACK TO SAVEPOINT sp_iteration;

                  UPDATE upd_me_med ts
                     SET ts.flg_status = 'E', ts.err_description = 'Error: ' || l_sqlerrm
                   WHERE ts.emb_id = l_id
                   AND ts.vers = c.vers;
                   
                  COMMIT;
          END;

          l_block := l_block + 1;

      END LOOP;

      COMMIT;

      RETURN TRUE;
  END update_me_med;


  FUNCTION update_icd9_dxid
  (
    i_id_process IN NUMBER, i_vers IN VARCHAR2
  ) RETURN BOOLEAN IS
      l_block       upd_config.size_blocks%type;
      l_block_size  upd_config.size_blocks%type;
      l_id_1        upd_icd9_dxid.dxid%TYPE;
      l_id_2        upd_icd9_dxid.icd9cm_code%TYPE;
      l_id_3        upd_icd9_dxid.vers%TYPE;

      
      
      l_sqlerrm     VARCHAR2(4000);

      
  BEGIN

      select uc.size_blocks
        into l_block_size
        from upd_config uc;

      l_block := 1;
      FOR c IN (SELECT *
                  FROM upd_icd9_dxid
                 WHERE id_process = i_id_process
                   AND (flg_status is NULL OR flg_Status = 'E')  AND vers = i_Vers)
      LOOP

          l_id_1 := c.dxid;
          l_id_2 := c.icd9cm_code;
          l_id_3 := c.vers;

/*          select to_number(to_char(systimestamp,'mi') || to_char(systimestamp,'ss') || ',' || to_char(systimestamp,'FF'))
            into l_start_time
            from dual;*/

          BEGIN
              SAVEPOINT sp_iteration;

               update icd9_dxid tt
                  set tt.icd9cm_desc = c.icd9cm_desc,
                      tt.nav_code = c.nav_code
                where tt.dxid = c.dxid
                  and tt.icd9cm_code = c.icd9cm_code
                  and tt.vers = c.vers;

              IF SQL%ROWCOUNT = 0
              THEN
                  INSERT INTO icd9_dxid (dxid,
                                              icd9cm_code,
                                              icd9cm_desc,
                                              vers,
                                              nav_code)
                  VALUES (c.dxid,
                          c.icd9cm_code,
                          c.icd9cm_desc,
                          c.vers,
                          c.nav_code);
              END IF;

              UPDATE upd_icd9_dxid ts
                 SET ts.flg_status = 'Y'
               WHERE ts.dxid = c.dxid
                 AND ts.icd9cm_code = c.icd9cm_code
                 AND ts.vers = c.vers;

              IF MOD(l_block, l_block_size) = 0
              THEN
                  COMMIT;
                  l_block := 0;
              END IF;

          EXCEPTION
              WHEN OTHERS THEN
                  l_sqlerrm := SQLERRM;

                  ROLLBACK TO SAVEPOINT sp_iteration;

                  UPDATE upd_icd9_dxid ts
                     SET ts.flg_status = 'E', ts.err_description = 'Error: ' || l_sqlerrm
                   WHERE ts.dxid = l_id_1
                     AND ts.icd9cm_code = l_id_2
                     AND ts.vers = l_id_3;
                  COMMIT;
          END;

          l_block := l_block + 1;

      END LOOP;

      COMMIT;

      RETURN TRUE;
  END update_icd9_dxid;


  FUNCTION update_me_med_atc
  (
    i_id_process IN NUMBER, i_vers IN VARCHAR2
  ) RETURN BOOLEAN IS

      l_block       upd_config.size_blocks%type;
      l_block_size  upd_config.size_blocks%type;
      l_id_1        me_med_atc.emb_id%TYPE;
      l_id_2        me_med_atc.atc_id%TYPE;
      l_id_3        me_med_atc.vers%TYPE;

      
      
      l_sqlerrm     VARCHAR2(4000);

      
  BEGIN

      select uc.size_blocks
        into l_block_size
        from upd_config uc;

      l_block := 1;
      FOR c IN (SELECT *
                  FROM upd_me_med_atc
                 WHERE id_process = i_id_process
                   AND (flg_status is NULL OR flg_Status = 'E')  AND vers = i_Vers)
      LOOP

          l_id_1 := c.emb_id;
          l_id_2 := c.atc_id;
          l_id_3 := c.vers;

/*          select to_number(to_char(systimestamp,'mi') || to_char(systimestamp,'ss') || ',' || to_char(systimestamp,'FF'))
            into l_start_time
            from dual;*/

          BEGIN
              SAVEPOINT sp_iteration;

               update me_med_atc tt
                  set tt.atc_descr = c.atc_descr
                where tt.emb_id = c.emb_id
                  and tt.atc_id = c.atc_id
                  and tt.vers = c.vers;

              IF SQL%ROWCOUNT = 0
              THEN
                  INSERT INTO me_med_atc (emb_id,
                                               atc_id,
                                               atc_descr,
                                               vers)
                  VALUES (c.emb_id,
                          c.atc_id,
                          c.atc_descr,
                          c.vers);
              END IF;

              UPDATE upd_me_med_atc ts
                 SET ts.flg_status = 'Y'
               WHERE ts.emb_id = c.emb_id
                 AND ts.atc_id = c.atc_id
                 AND ts.vers = c.vers;

              IF MOD(l_block, l_block_size) = 0
              THEN
                  COMMIT;
                  l_block := 0;

              END IF;

          EXCEPTION
              WHEN OTHERS THEN
                  l_sqlerrm := SQLERRM;

                  ROLLBACK TO SAVEPOINT sp_iteration;

                  UPDATE upd_me_med_atc ts
                     SET ts.flg_status = 'E', ts.err_description = 'Error: ' || l_sqlerrm
                   WHERE ts.emb_id = l_id_1
                     AND ts.atc_id = l_id_2
                     AND ts.vers = l_id_3;
                  COMMIT;
          END;

          l_block := l_block + 1;

      END LOOP;

      COMMIT;

      RETURN TRUE;
  END update_me_med_atc;


  FUNCTION update_me_med_pharm_group
  (
    i_id_process IN NUMBER, i_vers IN VARCHAR2
  ) RETURN BOOLEAN IS

      l_block       upd_config.size_blocks%type;
      l_block_size  upd_config.size_blocks%type;
      l_id_1        me_med_pharm_group.emb_id%TYPE;
      l_id_2        me_med_pharm_group.group_id%TYPE;
      l_id_3        me_med_pharm_group.vers%TYPE;

      
      
      l_sqlerrm     VARCHAR2(4000);

      
  BEGIN

      select uc.size_blocks
        into l_block_size
        from upd_config uc;

      l_block := 1;
      FOR c IN (SELECT *
                  FROM upd_me_med_pharm_group
                 WHERE id_process = i_id_process
                   AND (flg_status is NULL OR flg_Status = 'E')  AND vers = i_Vers)
      LOOP

          l_id_1 := c.emb_id;
          l_id_2 := c.group_id;
          l_id_3 := c.vers;

/*          select to_number(to_char(systimestamp,'mi') || to_char(systimestamp,'ss') || ',' || to_char(systimestamp,'FF'))
            into l_start_time
            from dual;*/

          BEGIN
              SAVEPOINT sp_iteration;

               update me_med_pharm_group tt
                  set tt.group_id = c.group_id
                where tt.emb_id = c.emb_id
                  and tt.group_id = c.group_id
                  and tt.vers = c.vers;

              IF SQL%ROWCOUNT = 0
              THEN
                  INSERT INTO me_med_pharm_group (emb_id,
                                                       group_id,
                                                       vers)
                  VALUES (c.emb_id,
                          c.group_id,
                          c.vers);
              END IF;

              UPDATE upd_me_med_pharm_group ts
                 SET ts.flg_status = 'Y'
               WHERE ts.emb_id = c.emb_id
                 AND ts.group_id = c.group_id
                 AND ts.vers = c.vers;

              IF MOD(l_block, l_block_size) = 0
              THEN
                  COMMIT;
                  l_block := 0;

              END IF;

          EXCEPTION
              WHEN OTHERS THEN
                  l_sqlerrm := SQLERRM;

                  ROLLBACK TO SAVEPOINT sp_iteration;

                  UPDATE upd_me_med_pharm_group ts
                     SET ts.flg_status = 'E', ts.err_description = 'Error: ' || l_sqlerrm
                   WHERE ts.emb_id = l_id_1
                     AND ts.group_id = l_id_2
                     AND ts.vers = l_id_3;
                  COMMIT;
          END;

          l_block := l_block + 1;

      END LOOP;

      COMMIT;

      RETURN TRUE;
  END update_me_med_pharm_group;


  FUNCTION update_me_med_regulation
  (
    i_id_process IN NUMBER, i_vers IN VARCHAR2
  ) RETURN BOOLEAN IS

      l_block       upd_config.size_blocks%type;
      l_block_size  upd_config.size_blocks%type;
      l_id_1        me_med_regulation.emb_id%TYPE;
      l_id_2        me_med_regulation.regulation_id%TYPE;
      l_id_3        me_med_regulation.vers%TYPE;

      
      
      l_sqlerrm     VARCHAR2(4000);

      
  BEGIN

      select uc.size_blocks
        into l_block_size
        from upd_config uc;

      l_block := 1;
      FOR c IN (SELECT *
                  FROM upd_me_med_regulation
                 WHERE id_process = i_id_process
                   AND (flg_status is NULL OR flg_Status = 'E')  AND vers = i_Vers)
      LOOP

          l_id_1 := c.emb_id;
          l_id_2 := c.regulation_id;
          l_id_3 := c.vers;

/*          select to_number(to_char(systimestamp,'mi') || to_char(systimestamp,'ss') || ',' || to_char(systimestamp,'FF'))
            into l_start_time
            from dual;*/

          BEGIN
              SAVEPOINT sp_iteration;

               update me_med_regulation tt
                  set tt.compart = c.compart
                  ,   tt.regulation_descr = c.regulation_descr
                where tt.emb_id = c.emb_id
                  and tt.regulation_id = c.regulation_id
                  and tt.vers = c.vers;

              IF SQL%ROWCOUNT = 0
              THEN
                  INSERT INTO me_med_regulation(emb_id
                              ,                      regulation_id
                              ,                      compart
                              ,                      regulation_descr
                              ,                      vers)
                       VALUES (c.emb_id
                       ,       c.regulation_id
                       ,       c.compart
                       ,       c.regulation_descr
                       ,       c.vers);
              END IF;

              UPDATE upd_me_med_regulation ts
                 SET ts.flg_status = 'Y'
               WHERE ts.emb_id = c.emb_id
                 AND ts.regulation_id = c.regulation_id
                 AND ts.vers = c.vers;

              IF MOD(l_block, l_block_size) = 0
              THEN
                  COMMIT;
                  l_block := 0;

              END IF;

          EXCEPTION
              WHEN OTHERS THEN
                  l_sqlerrm := SQLERRM;

                  ROLLBACK TO SAVEPOINT sp_iteration;

                  UPDATE upd_me_med_regulation ts
                     SET ts.flg_status = 'E', ts.err_description = 'Error: ' || l_sqlerrm
                   WHERE ts.emb_id = l_id_1
                     AND ts.regulation_id = l_id_2
                     AND ts.vers = l_id_3;
                  COMMIT;
          END;

          l_block := l_block + 1;

      END LOOP;

      COMMIT;

      RETURN TRUE;
  END update_me_med_regulation;


  FUNCTION update_me_med_route
  (
    i_id_process IN NUMBER, i_vers IN VARCHAR2
  ) RETURN BOOLEAN IS

      l_block       upd_config.size_blocks%type;
      l_block_size  upd_config.size_blocks%type;
      l_id_1        me_med_route.emb_id%TYPE;
      l_id_2        me_med_route.route_id%TYPE;
      l_id_3        me_med_route.vers%TYPE;

      
      
      l_sqlerrm     VARCHAR2(4000);

      
  BEGIN

      select uc.size_blocks
        into l_block_size
        from upd_config uc;

      l_block := 1;
      FOR c IN (SELECT *
                  FROM upd_me_med_route
                 WHERE id_process = i_id_process
                   AND (flg_status is NULL OR flg_Status = 'E')  AND vers = i_Vers)
      LOOP

          l_id_1 := c.emb_id;
          l_id_2 := c.route_id;
          l_id_3 := c.vers;

/*          select to_number(to_char(systimestamp,'mi') || to_char(systimestamp,'ss') || ',' || to_char(systimestamp,'FF'))
            into l_start_time
            from dual;*/

          BEGIN
              SAVEPOINT sp_iteration;

               update me_med_route tt
                  set tt.route_descr = c.route_descr
                  ,   tt.route_abrv = c.route_abrv
                  ,   tt.flg_available = c.flg_available
                where tt.emb_id = c.emb_id
                  and tt.route_id = c.route_id
                  and tt.vers = c.vers;

              IF SQL%ROWCOUNT = 0
              THEN
                  INSERT INTO me_med_route(emb_id
                              ,                 route_id
                              ,                 route_descr
                              ,                 route_abrv
                              ,                 vers
                              ,                 flg_available)
                       VALUES (c.emb_id
                       ,       c.route_id
                       ,       c.route_descr
                       ,       c.route_abrv
                       ,       c.vers
                       ,       c.flg_available);
              END IF;

              UPDATE upd_me_med_route ts
                 SET ts.flg_status = 'Y'
               WHERE ts.emb_id = c.emb_id
                 AND ts.route_id = c.route_id
                 AND ts.vers = c.vers;

              IF MOD(l_block, l_block_size) = 0
              THEN
                  COMMIT;
                  l_block := 0;

              END IF;

          EXCEPTION
              WHEN OTHERS THEN
                  l_sqlerrm := SQLERRM;

                  ROLLBACK TO SAVEPOINT sp_iteration;

                  UPDATE upd_me_med_route ts
                     SET ts.flg_status = 'E', ts.err_description = 'Error: ' || l_sqlerrm
                   WHERE ts.emb_id = l_id_1
                     AND ts.route_id = l_id_2
                     AND ts.vers = l_id_3;
                  COMMIT;
          END;

          l_block := l_block + 1;

      END LOOP;

      COMMIT;

      RETURN TRUE;
  END update_me_med_route;


  FUNCTION update_me_med_subst
  (
    i_id_process IN NUMBER, i_vers IN VARCHAR2
  ) RETURN BOOLEAN IS

      l_block       upd_config.size_blocks%type;
      l_block_size  upd_config.size_blocks%type;
      l_id_1        me_med_subst.emb_id%TYPE;
      l_id_2        me_med_subst.subst_id%TYPE;
      l_id_3        me_med_subst.vers%TYPE;

      
      
      l_sqlerrm     VARCHAR2(4000);

      
  BEGIN

      select uc.size_blocks
        into l_block_size
        from upd_config uc;

      l_block := 1;
      FOR c IN (SELECT *
                  FROM upd_me_med_subst
                 WHERE id_process = i_id_process
                   AND (flg_status is NULL OR flg_Status = 'E')  AND vers = i_Vers)
      LOOP

          l_id_1 := c.emb_id;
          l_id_2 := c.subst_id;
          l_id_3 := c.vers;

/*          select to_number(to_char(systimestamp,'mi') || to_char(systimestamp,'ss') || ',' || to_char(systimestamp,'FF'))
            into l_start_time
            from dual;*/

          BEGIN
              SAVEPOINT sp_iteration;

               update me_med_subst tt
                  set tt.subst_descr = c.subst_descr
                  ,   tt.subst_quant = c.subst_quant
                where tt.emb_id = c.emb_id
                  and tt.subst_id = c.subst_id
                  and tt.vers = c.vers;

              IF SQL%ROWCOUNT = 0
              THEN
                  INSERT INTO me_med_subst(emb_id
                              ,                 subst_id
                              ,                 subst_descr
                              ,                 subst_quant
                              ,                 vers)
                       VALUES (c.emb_id
                       ,       c.subst_id
                       ,       c.subst_descr
                       ,       c.subst_quant
                       ,       c.vers);
              END IF;

              UPDATE upd_me_med_subst ts
                 SET ts.flg_status = 'Y'
               WHERE ts.emb_id = c.emb_id
                 AND ts.subst_id = c.subst_id
                 AND ts.vers = c.vers;

              IF MOD(l_block, l_block_size) = 0
              THEN
                  COMMIT;
                  l_block := 0;

              END IF;

          EXCEPTION
              WHEN OTHERS THEN
                  l_sqlerrm := SQLERRM;

                  ROLLBACK TO SAVEPOINT sp_iteration;

                  UPDATE upd_me_med_subst ts
                     SET ts.flg_status = 'E', ts.err_description = 'Error: ' || l_sqlerrm
                   WHERE ts.emb_id = l_id_1
                     AND ts.subst_id = l_id_2
                     AND ts.vers = l_id_3;
                  COMMIT;
          END;

          l_block := l_block + 1;

      END LOOP;

      COMMIT;

      RETURN TRUE;
  END update_me_med_subst;


  FUNCTION update_me_pharm_group
  (
    i_id_process IN NUMBER, i_vers IN VARCHAR2
  ) RETURN BOOLEAN IS

      l_block       upd_config.size_blocks%type;
      l_block_size  upd_config.size_blocks%type;
      l_id_1        me_pharm_group.group_id%TYPE;
      l_id_3        me_pharm_group.vers%TYPE;

      
      
      l_sqlerrm     VARCHAR2(4000);

      
  BEGIN

      select uc.size_blocks
        into l_block_size
        from upd_config uc;

      l_block := 1;
      FOR c IN (SELECT *
                  FROM upd_me_pharm_group
                 WHERE id_process = i_id_process
                   AND (flg_status is NULL OR flg_Status = 'E')  AND vers = i_Vers)
      LOOP

          l_id_1 := c.group_id;
          l_id_3 := c.vers;

/*          select to_number(to_char(systimestamp,'mi') || to_char(systimestamp,'ss') || ',' || to_char(systimestamp,'FF'))
            into l_start_time
            from dual;*/

          BEGIN
              SAVEPOINT sp_iteration;

               update me_pharm_group tt
                  set tt.group_descr = c.group_descr
                  ,   tt.parent_id = c.parent_id
                  ,   tt.parent_descr = c.parent_descr
                  ,   tt.level_num = c.level_num
                  ,   tt.rank = c.rank
                where tt.group_id = c.group_id
                  and tt.vers = c.vers;

              IF SQL%ROWCOUNT = 0
              THEN
                  INSERT INTO me_pharm_group(group_id
                              ,                   group_descr
                              ,                   parent_id
                              ,                   parent_descr
                              ,                   level_num
                              ,                   rank
                              ,                   vers)
                       VALUES (c.group_id
                       ,       c.group_descr
                       ,       c.parent_id
                       ,       c.parent_descr
                       ,       c.level_num
                       ,       c.rank
                       ,       c.vers);
              END IF;

              UPDATE upd_me_pharm_group ts
                 SET ts.flg_status = 'Y'
               WHERE ts.group_id = c.group_id
                 AND ts.vers = c.vers;

              IF MOD(l_block, l_block_size) = 0
              THEN
                  COMMIT;
                  l_block := 0;

              END IF;

          EXCEPTION
              WHEN OTHERS THEN
                  l_sqlerrm := SQLERRM;

                  ROLLBACK TO SAVEPOINT sp_iteration;

                  UPDATE upd_me_pharm_group ts
                     SET ts.flg_status = 'E', ts.err_description = 'Error: ' || l_sqlerrm
                   WHERE ts.group_id = l_id_1
                     AND ts.vers = l_id_3;
                  COMMIT;
          END;

          l_block := l_block + 1;

      END LOOP;

      COMMIT;

      RETURN TRUE;
  END update_me_pharm_group;


  FUNCTION update_me_regulation
  (
    i_id_process IN NUMBER, i_vers IN VARCHAR2
  ) RETURN BOOLEAN IS

      l_block       upd_config.size_blocks%type;
      l_block_size  upd_config.size_blocks%type;
      l_id_1        me_regulation.regulation_id%TYPE;
      l_id_3        me_regulation.vers%TYPE;

      l_sqlerrm     VARCHAR2(4000);

      
  BEGIN

      select uc.size_blocks
        into l_block_size
        from upd_config uc;

      l_block := 1;
      FOR c IN (SELECT *
                  FROM upd_me_regulation
                 WHERE id_process = i_id_process
                   AND (flg_status is NULL OR flg_Status = 'E')  AND vers = i_Vers)
      LOOP

          l_id_1 := c.regulation_id;
          l_id_3 := c.vers;

/*          select to_number(to_char(systimestamp,'mi') || to_char(systimestamp,'ss') || ',' || to_char(systimestamp,'FF'))
            into l_start_time
            from dual;*/

          BEGIN
              SAVEPOINT sp_iteration;

               update me_regulation tt
                  set tt.regulation_descr = c.regulation_descr
                  ,   tt.suggested_descr = c.suggested_descr
                where tt.regulation_id = c.regulation_id
                  and tt.vers = c.vers;

              IF SQL%ROWCOUNT = 0
              THEN
                  INSERT INTO me_regulation(regulation_id
                              ,                  regulation_descr
                              ,                  vers
                              ,                  suggested_descr)
                       VALUES (c.regulation_id
                       ,       c.regulation_descr
                       ,       c.vers
                       ,       c.suggested_descr);
              END IF;

              UPDATE upd_me_regulation ts
                 SET ts.flg_status = 'Y'
               WHERE ts.regulation_id = c.regulation_id
                 AND ts.vers = c.vers;

              IF MOD(l_block, l_block_size) = 0
              THEN
                  COMMIT;
                  l_block := 0;

              END IF;

          EXCEPTION
              WHEN OTHERS THEN
                  l_sqlerrm := SQLERRM;

                  ROLLBACK TO SAVEPOINT sp_iteration;

                  UPDATE upd_me_regulation ts
                     SET ts.flg_status = 'E', ts.err_description = 'Error: ' || l_sqlerrm
                   WHERE ts.regulation_id = l_id_1
                     AND ts.vers = l_id_3;
                  COMMIT;
          END;

          l_block := l_block + 1;

      END LOOP;

      COMMIT;

      RETURN TRUE;
  END update_me_regulation;


  FUNCTION update_me_route
  (
    i_id_process IN NUMBER, i_vers IN VARCHAR2
  ) RETURN BOOLEAN IS

      l_block       upd_config.size_blocks%type;
      l_block_size  upd_config.size_blocks%type;
      l_id_1        me_route.route_id%TYPE;
      l_id_3        me_route.vers%TYPE;

      
      
      l_sqlerrm     VARCHAR2(4000);

      
  BEGIN

      select uc.size_blocks
        into l_block_size
        from upd_config uc;

      l_block := 1;
      FOR c IN (SELECT *
                  FROM upd_me_route
                 WHERE id_process = i_id_process
                   AND (flg_status is NULL OR flg_Status = 'E')  AND vers = i_Vers)
      LOOP

          l_id_1 := c.route_id;
          l_id_3 := c.vers;

/*          select to_number(to_char(systimestamp,'mi') || to_char(systimestamp,'ss') || ',' || to_char(systimestamp,'FF'))
            into l_start_time
            from dual;*/

          BEGIN
              SAVEPOINT sp_iteration;

               update me_route tt
                  set tt.route_descr = c.route_descr
                  ,   tt.route_abrv = c.route_abrv
                where tt.route_id = c.route_id
                  and tt.vers = c.vers;

              IF SQL%ROWCOUNT = 0
              THEN
                  INSERT INTO me_route(route_id
                              ,             route_descr
                              ,             vers
                              ,             route_abrv)
                       VALUES (c.route_id
                       ,       c.route_descr
                       ,       c.vers
                       ,       c.route_abrv);
              END IF;

              UPDATE upd_me_route ts
                 SET ts.flg_status = 'Y'
               WHERE ts.route_id = c.route_id
                 AND ts.vers = c.vers;

              IF MOD(l_block, l_block_size) = 0
              THEN
                  COMMIT;
                  l_block := 0;

              END IF;

          EXCEPTION
              WHEN OTHERS THEN
                  l_sqlerrm := SQLERRM;

                  ROLLBACK TO SAVEPOINT sp_iteration;

                  UPDATE upd_me_route ts
                     SET ts.flg_status = 'E', ts.err_description = 'Error: ' || l_sqlerrm
                   WHERE ts.route_id = l_id_1
                     AND ts.vers = l_id_3;
                  COMMIT;
          END;

          l_block := l_block + 1;

      END LOOP;

      COMMIT;

      RETURN TRUE;
  END update_me_route;


  FUNCTION update_me_price_type
  (
    i_id_process IN NUMBER, i_vers IN VARCHAR2
  ) RETURN BOOLEAN IS

      l_block       upd_config.size_blocks%type;
      l_block_size  upd_config.size_blocks%type;
      l_id_1        me_price_type.id_me_price_type%TYPE;
      l_id_3        me_price_type.vers%TYPE;

      
      
      l_sqlerrm     VARCHAR2(4000);

      
  BEGIN

      select uc.size_blocks
        into l_block_size
        from upd_config uc;

      l_block := 1;
      FOR c IN (SELECT *
                  FROM upd_me_price_type
                 WHERE id_process = i_id_process
                   AND (flg_status is NULL OR flg_Status = 'E')  AND vers = i_Vers)
      LOOP

          l_id_1 := c.id_me_price_type;
          l_id_3 := c.vers;

/*          select to_number(to_char(systimestamp,'mi') || to_char(systimestamp,'ss') || ',' || to_char(systimestamp,'FF'))
            into l_start_time
            from dual;*/

          BEGIN
              SAVEPOINT sp_iteration;

               update me_price_type tt
                  set tt.descr = c.descr
                where tt.id_me_price_type = c.id_me_price_type
                  and tt.vers = c.vers;

              IF SQL%ROWCOUNT = 0
              THEN
                  INSERT INTO me_price_type(id_me_price_type
                              ,                  descr
                              ,                  vers)
                       VALUES (c.id_me_price_type
                       ,       c.descr
                       ,       c.vers);
              END IF;

              UPDATE upd_me_price_type ts
                 SET ts.flg_status = 'Y'
               WHERE ts.id_me_price_type = c.id_me_price_type
                 AND ts.vers = c.vers;

              IF MOD(l_block, l_block_size) = 0
              THEN
                  COMMIT;
                  l_block := 0;

              END IF;

          EXCEPTION
              WHEN OTHERS THEN
                  l_sqlerrm := SQLERRM;

                  ROLLBACK TO SAVEPOINT sp_iteration;

                  UPDATE upd_me_price_type ts
                     SET ts.flg_status = 'E', ts.err_description = 'Error: ' || l_sqlerrm
                   WHERE ts.id_me_price_type = l_id_1
                     AND ts.vers = l_id_3;
                  COMMIT;
          END;

          l_block := l_block + 1;

      END LOOP;

      COMMIT;

      RETURN TRUE;
  END update_me_price_type;


  FUNCTION update_me_med_price_hist_det
  (
    i_id_process IN NUMBER, i_vers IN VARCHAR2
  ) RETURN BOOLEAN IS

      l_block       upd_config.size_blocks%type;
      l_block_size  upd_config.size_blocks%type;
      l_id_1        me_med_price_hist_det.id_me_med_price_hist_det%TYPE;
      l_id_2        me_med_price_hist_det.emb_id%TYPE;
      l_id_3        me_med_price_hist_det.vers%TYPE;
      l_id_4        me_med_price_hist_det.id_me_price_type%type;

      l_sqlerrm     VARCHAR2(4000);

  BEGIN

      select uc.size_blocks
        into l_block_size
        from upd_config uc;
        
      /*  IF i_id_process = 1 THEN
        
        l_update_query := 'TRUNCATE TABLE me_med_price_hist_det';
        execute immediate (l_update_query); 

        INSERT INTO me_med_price_hist_det(id_me_med_price_hist_det
                              ,                          emb_id
                              ,                          id_me_price_type
                              ,                          price
                              ,                          dt_update_tstz
                              ,                          vers)
                       select c.id_me_med_price_hist_det
                       ,       c.emb_id
                       ,       c.id_me_price_type
                       ,       c.price
                       ,       c.dt_update_tstz
                       ,       c.vers from upd_me_med_price_hist_det c;
                       
         ELSE NULL;
         END IF;*/

      l_block := 1;
      FOR c IN (SELECT *
                  FROM upd_me_med_price_hist_det
                 WHERE id_process = i_id_process
                   AND (flg_status is NULL OR flg_Status = 'E')  AND vers = i_Vers)
      LOOP

          l_id_1 := c.id_me_med_price_hist_det;
          l_id_2 := c.emb_id;
          l_id_3 := c.vers;
          l_id_2 := c.id_me_price_type;

/*          select to_number(to_char(systimestamp,'mi') || to_char(systimestamp,'ss') || ',' || to_char(systimestamp,'FF'))
            into l_start_time
            from dual;*/

          BEGIN
              SAVEPOINT sp_iteration;

               update me_med_price_hist_det tt
                  set tt.price = c.price
                  ,   tt.dt_update_tstz = c.dt_update_tstz
                where tt.id_me_med_price_hist_det = c.id_me_med_price_hist_det
                  and tt.emb_id = c.emb_id
                  and tt.id_me_price_type = c.id_me_price_type
                  and tt.vers = c.vers;

              IF SQL%ROWCOUNT = 0
              THEN
                  INSERT INTO me_med_price_hist_det(id_me_med_price_hist_det
                              ,                          emb_id
                              ,                          id_me_price_type
                              ,                          price
                              ,                          dt_update_tstz
                              ,                          vers)
                       VALUES (c.id_me_med_price_hist_det
                       ,       c.emb_id
                       ,       c.id_me_price_type
                       ,       c.price
                       ,       c.dt_update_tstz
                       ,       c.vers);
              END IF;

              UPDATE upd_me_med_price_hist_det ts
                 SET ts.flg_status = 'Y'
               WHERE ts.id_me_med_price_hist_det = c.id_me_med_price_hist_det
                 AND ts.emb_id = c.emb_id
                 AND ts.id_me_price_type = c.id_me_price_type
                 AND ts.vers = c.vers;

              IF MOD(l_block, l_block_size) = 0
              THEN
                  COMMIT;
                  l_block := 0;

              END IF;

          EXCEPTION
              WHEN OTHERS THEN
                  l_sqlerrm := SQLERRM;

                  ROLLBACK TO SAVEPOINT sp_iteration;

                  UPDATE upd_me_med_price_hist_det ts
                     SET ts.flg_status = 'E', ts.err_description = 'Error: ' || l_sqlerrm
                   WHERE ts.id_me_med_price_hist_det = l_id_1
                     AND ts.emb_id = l_id_2
                     AND ts.vers = l_id_3
                     AND ts.id_me_price_type = l_id_4;
                  COMMIT;
          END;

          l_block := l_block + 1;

      END LOOP;

      COMMIT;

      RETURN TRUE;
  END update_me_med_price_hist_det;

  FUNCTION update_drug_unit
  (
    i_id_process IN NUMBER, i_vers IN VARCHAR2
  ) RETURN BOOLEAN IS

      l_block       upd_config.size_blocks%type;
      l_block_size  upd_config.size_blocks%type;
      l_id_1        drug_unit.id_drug_unit%TYPE;

      
      
      l_sqlerrm     VARCHAR2(4000);

      
  BEGIN

      select uc.size_blocks
        into l_block_size
        from upd_config uc;

      l_block := 1;
      FOR c IN (SELECT *
                  FROM upd_drug_unit
                 WHERE id_process = i_id_process
                   AND (flg_status is NULL OR flg_Status = 'E')  AND vers = i_Vers)
      LOOP

          l_id_1 := c.id_drug_unit;

/*          select to_number(to_char(systimestamp,'mi') || to_char(systimestamp,'ss') || ',' || to_char(systimestamp,'FF'))
            into l_start_time
            from dual;*/

          BEGIN
              SAVEPOINT sp_iteration;

               update drug_unit tt
                  set tt.id_drug = c.id_drug
                  ,   tt.chnm_id = c.chnm_id
                  ,   tt.drug_flg_type = c.drug_flg_type
                  ,   tt.flg_type = c.flg_type
                  ,   tt.flg_available = c.flg_available
                  ,   tt.vers = c.vers
                  ,   tt.id_unit_measure = c.id_unit_measure
                  ,   tt.flg_default = c.flg_default
                where tt.id_drug_unit = c.id_drug_unit;

              IF SQL%ROWCOUNT = 0
              THEN
                  INSERT INTO drug_unit(id_drug
                              ,              chnm_id
                              ,              drug_flg_type
                              ,              flg_type
                              ,              flg_available
                              ,              vers
                              ,              id_unit_measure
                              ,              flg_default
                              ,              id_drug_unit)
                       VALUES (c.id_drug
                       ,       c.chnm_id
                       ,       c.drug_flg_type
                       ,       c.flg_type
                       ,       c.flg_available
                       ,       c.vers
                       ,       c.id_unit_measure
                       ,       c.flg_default
                       ,       c.id_drug_unit);
              END IF;

              UPDATE upd_drug_unit ts
                 SET ts.flg_status = 'Y'
               WHERE ts.id_drug_unit = c.id_drug_unit;

              IF MOD(l_block, l_block_size) = 0
              THEN
                  COMMIT;
                  l_block := 0;

              END IF;

          EXCEPTION
              WHEN OTHERS THEN
                  l_sqlerrm := SQLERRM;

                  ROLLBACK TO SAVEPOINT sp_iteration;

                  UPDATE upd_drug_unit ts
                     SET ts.flg_status = 'E', ts.err_description = 'Error: ' || l_sqlerrm
                   WHERE ts.id_drug_unit = l_id_1;
                  COMMIT;
          END;

          l_block := l_block + 1;

      END LOOP;

      COMMIT;

      RETURN TRUE;
  END update_drug_unit;


  FUNCTION update_form_farm_unit
  (
    i_id_process IN NUMBER, i_vers IN VARCHAR2
  ) RETURN BOOLEAN IS

      l_block       upd_config.size_blocks%type;
      l_block_size  upd_config.size_blocks%type;
      l_id_1        form_farm_unit.id_form_farm_unit%TYPE;

      
      
      l_sqlerrm     VARCHAR2(4000);

      
  BEGIN

      select uc.size_blocks
        into l_block_size
        from upd_config uc;

      l_block := 1;
      FOR c IN (SELECT *
                  FROM upd_form_farm_unit
                 WHERE id_process = i_id_process
                   AND (flg_status is NULL OR flg_Status = 'E')  AND vers = i_Vers)
      LOOP

          l_id_1 := c.id_form_farm_unit;

/*          select to_number(to_char(systimestamp,'mi') || to_char(systimestamp,'ss') || ',' || to_char(systimestamp,'FF'))
            into l_start_time
            from dual;*/

          BEGIN
              SAVEPOINT sp_iteration;

               update form_farm_unit tt
                  set tt.form_farm_id = c.form_farm_id
                  ,   tt.id_unit_measure = c.id_unit_measure
                  ,   tt.type = c.type
                  ,   tt.vers = c.vers
                  ,   tt.flg_default = c.flg_default
                  ,   tt.med_id = c.med_id
                where tt.id_form_farm_unit = c.id_form_farm_unit;

              IF SQL%ROWCOUNT = 0
              THEN
                  INSERT INTO form_farm_unit(id_form_farm_unit
                              ,                   form_farm_id
                              ,                   id_unit_measure
                              ,                   type
                              ,                   vers
                              ,                   flg_default
                              ,                   med_id)
                       VALUES (c.id_form_farm_unit
                       ,       c.form_farm_id
                       ,       c.id_unit_measure
                       ,       c.type
                       ,       c.vers
                       ,       c.flg_default
                       ,       c.med_id);
              END IF;

              UPDATE upd_form_farm_unit ts
                 SET ts.flg_status = 'Y'
               WHERE ts.id_form_farm_unit = c.id_form_farm_unit;

              IF MOD(l_block, l_block_size) = 0
              THEN
                  COMMIT;
                  l_block := 0;

              END IF;

          EXCEPTION
              WHEN OTHERS THEN
                  l_sqlerrm := SQLERRM;

                  ROLLBACK TO SAVEPOINT sp_iteration;

                  UPDATE upd_form_farm_unit ts
                     SET ts.flg_status = 'E', ts.err_description = 'Error: ' || l_sqlerrm
                   WHERE ts.id_form_farm_unit = l_id_1;
                  COMMIT;
          END;

          l_block := l_block + 1;

      END LOOP;

      COMMIT;

      RETURN TRUE;
  END update_form_farm_unit;


  FUNCTION update_interact_message
  (
    i_id_process IN NUMBER, i_vers IN VARCHAR2
  ) RETURN BOOLEAN IS

      l_block       upd_config.size_blocks%type;
      l_block_size  upd_config.size_blocks%type;
      l_id_1        upd_interact_message.id_interact_message%TYPE;
      l_id_2        upd_interact_message.vers%TYPE;

      
      
      l_sqlerrm     VARCHAR2(4000);

      
  BEGIN

      select uc.size_blocks
        into l_block_size
        from upd_config uc;

      l_block := 1;
      FOR c IN (SELECT *
                  FROM upd_interact_message
                 WHERE id_process = i_id_process
                   AND (flg_status is NULL OR flg_Status = 'E')  AND vers = i_Vers)
      LOOP

          l_id_1 := c.id_interact_message;
          l_id_2 := c.vers;

/*          select to_number(to_char(systimestamp,'mi') || to_char(systimestamp,'ss') || ',' || to_char(systimestamp,'FF'))
            into l_start_time
            from dual;*/

          BEGIN
              SAVEPOINT sp_iteration;

               update interact_message tt
                  set tt.interact_message_desc = c.interact_message_desc
                where tt.id_interact_message = c.id_interact_message
                  and tt.vers = c.vers;

              IF SQL%ROWCOUNT = 0
              THEN
                  INSERT INTO interact_message(id_interact_message
                  ,                            vers
                  ,                            interact_message_desc)
                       VALUES (c.id_interact_message
                       ,       c.vers
                       ,       c.interact_message_desc);
              END IF;

              UPDATE upd_interact_message ts
                 SET ts.flg_status = 'Y'
               WHERE ts.id_interact_message = c.id_interact_message
                 AND ts.vers = c.vers;

              IF MOD(l_block, l_block_size) = 0
              THEN
                  COMMIT;
                  l_block := 0;

              END IF;

          EXCEPTION
              WHEN OTHERS THEN
                  l_sqlerrm := SQLERRM;

                  ROLLBACK TO SAVEPOINT sp_iteration;

                  UPDATE upd_interact_message ts
                     SET ts.flg_status = 'E', ts.err_description = 'Error: ' || l_sqlerrm
                   WHERE ts.id_interact_message = l_id_1
                     AND ts.vers = l_id_2;
                  COMMIT;
          END;

          l_block := l_block + 1;

      END LOOP;

      COMMIT;

      RETURN TRUE;
  END update_interact_message;


  FUNCTION update_interact_message_format
  (
    i_id_process IN NUMBER, i_vers IN VARCHAR2
  ) RETURN BOOLEAN IS

      l_block       upd_config.size_blocks%type;
      l_block_size  upd_config.size_blocks%type;
      l_id_1        upd_interact_message_format.id_interact_message_format%TYPE;
      l_id_2        upd_interact_message_format.vers%TYPE;

      l_sqlerrm     VARCHAR2(4000);

  BEGIN

      select uc.size_blocks
        into l_block_size
        from upd_config uc;

      l_block := 1;
      FOR c IN (SELECT *
                  FROM upd_interact_message_format
                 WHERE id_process = i_id_process
                   AND (flg_status is NULL OR flg_Status = 'E')  AND vers = i_Vers)
      LOOP

          l_id_1 := c.id_interact_message_format;
          l_id_2 := c.vers;



          BEGIN
              SAVEPOINT sp_iteration;

               update interact_message_format tt
                  set tt.interact_message_config = c.interact_message_config
                  ,   tt.interact_message_config_desc = c.interact_message_config_desc
                where tt.id_interact_message_format = c.id_interact_message_format
                  and tt.vers = c.vers;

              IF SQL%ROWCOUNT = 0
              THEN
                  INSERT INTO interact_message_format(id_interact_message_format
                  ,                                   vers
                  ,                                   interact_message_config
                  ,                                   interact_message_config_desc)
                       VALUES (c.id_interact_message_format
                       ,       c.vers
                       ,       c.interact_message_config
                       ,       c.interact_message_config_desc);
              END IF;

              UPDATE upd_interact_message_format ts
                 SET ts.flg_status = 'Y'
               WHERE ts.id_interact_message_format = c.id_interact_message_format
                 AND ts.vers = c.vers;

              IF MOD(l_block, l_block_size) = 0
              THEN
                  COMMIT;
                  l_block := 0;

              END IF;

          EXCEPTION
              WHEN OTHERS THEN
                  l_sqlerrm := SQLERRM;

                  ROLLBACK TO SAVEPOINT sp_iteration;

                  UPDATE upd_interact_message_format ts
                     SET ts.flg_status = 'E', ts.err_description = 'Error: ' || l_sqlerrm
                   WHERE ts.id_interact_message_format = l_id_1
                     AND ts.vers = l_id_2;
                  COMMIT;
          END;

          l_block := l_block + 1;

      END LOOP;

      COMMIT;

      RETURN TRUE;
  END update_interact_message_format;
  
FUNCTION update_mi_med_route
  (
    i_id_process IN NUMBER, i_vers IN VARCHAR2
  ) RETURN BOOLEAN IS

      l_block       upd_config.size_blocks%type;
      l_block_size  upd_config.size_blocks%type;
      l_id_1        mi_med_route.route_id%TYPE;
      l_id_2        mi_med_route.id_drug%TYPE;
      l_id_3        mi_med_route.vers%TYPE;
      l_sqlerrm     VARCHAR2(4000);

  BEGIN

      select uc.size_blocks
        into l_block_size
        from upd_config uc;

      l_block := 1;
      FOR c IN (SELECT *
                  FROM upd_mi_med_route
                 WHERE id_process = i_id_process
                   AND (flg_status is NULL OR flg_Status = 'E')  AND vers = i_Vers)
      LOOP

          l_id_1 := c.route_id;
          l_id_2 := c.id_drug;
          l_id_3 := c.vers;


          BEGIN
              SAVEPOINT sp_iteration;

               update mi_med_route tt
                  set tt.flg_available = c.flg_available
                where tt.route_id = c.route_id
                  and tt.vers = c.vers
                  and tt.id_Drug = c.id_drug;

              IF SQL%ROWCOUNT = 0
              THEN
                  INSERT INTO mi_med_route(route_id
                  ,                      id_drug
                  ,                      flg_available
                  ,                      vers)
                       VALUES (c.route_id
                       ,       c.id_drug
                       ,       c.flg_available
                       ,       c.vers);
              END IF;

              UPDATE upd_mi_med_route ts
                 SET ts.flg_status = 'Y'
               WHERE ts.route_id = c.route_id
                 AND ts.vers = c.vers
                 AND ts.id_drug = c.id_drug;

              IF MOD(l_block, l_block_size) = 0
              THEN
                  COMMIT;
                  l_block := 0;

              END IF;

          EXCEPTION
              WHEN OTHERS THEN
                  l_sqlerrm := SQLERRM;

                  ROLLBACK TO SAVEPOINT sp_iteration;

                  UPDATE upd_mi_med_route ts
                     SET ts.flg_status = 'E', ts.err_description = 'Error: ' || l_sqlerrm
                   WHERE ts.route_id = l_id_1
                     AND ts.vers = l_id_3
                     AND ts.id_drug= l_id_2;
                  COMMIT;
          END;

          l_block := l_block + 1;

      END LOOP;

      COMMIT;

      RETURN TRUE;
  END update_mi_med_route;


begin
  null;
end pk_auto_update;
/
