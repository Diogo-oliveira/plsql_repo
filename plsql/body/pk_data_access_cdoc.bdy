/*-- Last Change Revision: $Rev: 2050730 $*/
/*-- Last Change by: $Author: carlos.ferreira $*/
/*-- Date of last change: $Date: 2022-11-22 15:25:53 +0000 (ter, 22 nov 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_data_access_cdoc IS

    k_default_software CONSTANT NUMBER := pk_data_access.k_default_software;

    k_limit_days CONSTANT NUMBER := 1;

    k_diag_mode_primary     CONSTANT VARCHAR2(0200 CHAR) := 'P';
    k_diag_mode_secondary   CONSTANT VARCHAR2(0200 CHAR) := 'S';
    k_diag_type_diferencial CONSTANT VARCHAR2(0200 CHAR) := 'P';
    k_diag_type_final       CONSTANT VARCHAR2(0200 CHAR) := 'D';

    --k_limit_days CONSTANT NUMBER := 1;

    k_vs_pain_order_first CONSTANT VARCHAR2(0050 CHAR) := 'FIRST';
    k_vs_pain_order_last  CONSTANT VARCHAR2(0050 CHAR) := 'LAST';

    FUNCTION get_treatment_physicians_base
    (
        i_lang    IN NUMBER,
        i_prof    IN profissional,
        i_episode IN NUMBER,
        i_mode    IN VARCHAR2
    ) RETURN table_varchar;

    FUNCTION array_2_field(i_tbl IN table_varchar) RETURN VARCHAR2 IS
        l_return VARCHAR2(4000);
        k_sep CONSTANT VARCHAR2(0010) := ',';
        k_sp  CONSTANT VARCHAR2(0010) := chr(32);
        l_value VARCHAR2(4000);
    BEGIN
    
        <<lup_thru_diags>>
        FOR i IN 1 .. i_tbl.count
        LOOP
        
            l_value := TRIM(i_tbl(i));
            IF length(l_return) > 0
               AND length(l_value) > 0
            THEN
                l_return := l_return || k_sep || k_sp;
            END IF;
        
            l_return := l_return || l_value;
        
        END LOOP lup_thru_diags;
    
        RETURN l_return;
    
    END array_2_field;

    --*****************************************************
    FUNCTION get_lprof(i_institution IN NUMBER) RETURN profissional IS
        l_institution NUMBER;
    BEGIN
    
        IF i_institution IS NOT NULL
        THEN
            l_institution := i_institution;
        ELSE
            l_institution := pk_sysconfig.get_data_access_inst();
        END IF;
    
        RETURN profissional(0, l_institution, k_default_software);
    
    END get_lprof;

    --#####################################################

    FUNCTION get_all_beds(i_institution IN institution.id_institution%TYPE DEFAULT NULL) RETURN t_table_bmng_beds IS
    
        l_table_bmng_beds t_table_bmng_beds := t_table_bmng_beds(NULL);
    
        l_cursor pk_types.cursor_type;
    
        l_sql_header VARCHAR2(32000);
        l_sql_from   VARCHAR2(32000);
        l_sql_inner  VARCHAR2(32000);
        l_sql_footer VARCHAR2(32000);
        l_sql_stmt   CLOB;
        l_curid      INTEGER;
        l_ret        INTEGER;
    
    BEGIN
    
        l_curid      := dbms_sql.open_cursor;
        l_sql_header := 'SELECT t_rec_bmng_beds( ' || --
                        '                      id_institution      => id_institution, ' || --
                        '                      institution_name    => institution_name, ' || --
                        '                      id_bed              => id_bed, ' || --
                        '                      bed_name            => bed_name, ' || --
                        '                      date_begin_tstz     => date_begin_tstz, ' || --
                        '                      date_begin          => date_begin, ' || --
                        '                      date_end_tstz       => date_end_tstz, ' || --
                        '                      date_end            => date_end, ' || --
                        '                      room_type           => room_type, ' || --
                        '                      ward_code           => ward_code, ' || --
                        '                      ward                => ward, ' || --
                        '                      patient_file_number => pk_data_access_cdoc.set_mrn_null_on_unoccupied( i_code => desc_bed_code, i_mrn => patient_mrn ), ' || --
                        '                      room_code           => room_code, ' || --
                        '                      room                => room_name, ' || --
                        '                      bed_code            => desc_bed_code, ' || --
                        '                      bed_status          => desc_bed_status, ' || --
                        '                      bed_type => bed_type,' ||
                        '                      bed_type_desc => bed_type_desc,' ||
                        '                      dt_last_update_tstz => dt_last_update_tstz, ' || -- 
                        '                      dt_last_update      => dt_last_update) ' || --
                        '  FROM (SELECT t.id_institution, ' || --
                        '               pk_translation.get_translation(id_lang, t.code_institution) institution_name, ' || --
                        '               t.id_room room_code, ' || --
                        '               nvl(t.desc_room, pk_translation.get_translation(id_lang, t.code_room)) room_name, ' || --
                        '               t.id_department ward_code, ' || --
                        '               pk_translation.get_translation(id_lang, t.code_department) ward, ' || --
                        '               t.id_bed, ' || --
                        '               decode(t.flg_type, ' || --
                        '                      :bed_type_t, ' || --
                        '                      t.desc_bed, ' || --
                        '                      nvl(t.desc_bed, pk_translation.get_translation(id_lang, t.code_bed))) bed_name, ' || --
                        '               pk_patient.get_alert_process_number(t.id_lang, profissional(NULL, t.id_institution, NULL), t.id_episode) patient_mrn, ' || --
                        '               nvl(t.desc_room_type, pk_translation.get_translation(id_lang, t.code_room_type)) room_type, ' || --
                        '               t.dt_begin date_begin_tstz, ' || --
                        '              pk_data_access_cdoc.format_date( profissional(null, id_institution,11), t.dt_begin) date_begin,' || --
                        '               t.dt_end date_end_tstz, ' || --
                        '              pk_data_access_cdoc.format_date( profissional(null, id_institution,11), t.dt_end) date_end,' || --
                        q'[               pk_data_access_cdoc.get_bed_status(id_lang,profissional(null, id_institution,11),flg_bed_ocupacity_status,flg_bed_status,'CODE' )  desc_bed_code, ]' || --
                        q'[               pk_data_access_cdoc.get_bed_status(id_lang,profissional(null, id_institution,11), flg_bed_ocupacity_status,flg_bed_status, 'DESC')  desc_bed_status, ]' || --
                        ' t.BED_TYPE,' ||
                        q'[ pk_sysdomain.get_domain(i_code_dom => 'BED.FLG_TYPE', i_val => t.BED_TYPE, i_lang => id_lang) BED_TYPE_DESC, ]' ||
                        '               dt_last_update_tstz dt_last_update_tstz, ' || --
                        '              pk_data_access_cdoc.format_date( profissional(null, id_institution,11), t.dt_last_update_tstz) dt_last_update' || --
                        '          FROM (SELECT pk_sysconfig.get_config(''LANGUAGE'', i.id_institution, 0) id_lang, ' || --
                        '                       i.id_institution, ' || --
                        '                       i.code_institution, ' || --
                        '                       r.desc_room, ' || --
                        '                       r.code_room, ' || --
                        '                       r.id_room, ' || --
                        '                       r.id_department, ' || --
                        '                       d.code_department, ' || --
                        '                       b.id_bed, ' || --
                        '                       b.flg_type, ' || --
                        '                       b.desc_bed, ' || --
                        '                       b.code_bed, ' || --
                        '                       bbea.id_episode, ' || --
                        '                       rt.desc_room_type, ' || --
                        '                       rt.code_room_type, ' || --
                        '                       bbea.dt_begin, ' || --
                        '                       bbea.dt_end , ' || --
                        '                       bbea.id_bmng_action, ' || --
                        '                       b.flg_type BED_TYPE,' || --
                        '                       bbea.flg_bed_status, ' || --
                        '                       bbea.flg_bed_ocupacity_status, ' || --                        
                        '                       coalesce(bbea.dt_dg_last_update, b.dt_last_update) dt_last_update_tstz  ';
    
        l_sql_from := '  FROM bed b ' || --
                      ' INNER JOIN room r ' || --
                      '    ON (r.id_room = b.id_room AND r.flg_available = :g_yes) ' || --
                      ' INNER JOIN department d ' || --
                      '    ON (d.id_department = r.id_department AND d.flg_available = :g_yes) ' || --
                      '  JOIN institution i ' || --
                      '    ON d.id_institution = i.id_institution ' || --
                      '  LEFT JOIN bmng_bed_ea bbea ' || --
                      '    ON bbea.id_bed = b.id_bed ' || --
                     --   '   AND bbea.flg_bed_ocupacity_status = :bed_status_o ' || --
                      '  LEFT JOIN bmng_allocation_bed bab ' || --
                      '    ON bab.id_bmng_allocation_bed = bbea.id_bmng_allocation_bed ' || --
                      '   AND bab.flg_outdated = :g_no ' || --
                      '  LEFT JOIN room_type rt ' || --
                      '    ON rt.id_room_type = r.id_room_type ' || --
                      ' WHERE 1 = 1 ';
    
        l_sql_inner := ' AND ((b.flg_type = ''P'' AND pk_sysconfig.get_config(''BMNG_COUNT_TEMP_BEDS'', profissional(NULL, d.id_institution, 11)) = :g_no)';
        l_sql_inner := l_sql_inner ||
                       ' OR pk_sysconfig.get_config(''BMNG_COUNT_TEMP_BEDS'', profissional(NULL, d.id_institution, 11)) = :g_yes)';
    
        IF i_institution IS NOT NULL
        THEN
            l_sql_inner := l_sql_inner || ' AND d.id_institution = :i_institution';
        END IF;
    
        l_sql_inner  := l_sql_inner || ' AND b.flg_available = :g_yes';
        l_sql_inner  := l_sql_inner || ' AND instr(d.flg_type, ''I'') > 0';
        l_sql_footer := l_sql_footer || ' ) t)';
    
        l_sql_stmt := to_clob(l_sql_header || l_sql_from || l_sql_inner || l_sql_footer);
    
        dbms_sql.parse(l_curid, l_sql_stmt, dbms_sql.native);
    
        --definição da bind variables 
        IF i_institution IS NOT NULL
        THEN
            dbms_sql.bind_variable(l_curid, 'i_institution', i_institution);
        END IF;
    
        dbms_sql.bind_variable(l_curid, 'g_yes', 'Y');
        dbms_sql.bind_variable(l_curid, 'g_no', 'N');
        dbms_sql.bind_variable(l_curid, 'bed_type_t', 'T');
        --    dbms_sql.bind_variable(l_curid, 'bed_status_o', 'O');
    
        l_ret := dbms_sql.execute(l_curid);
    
        l_cursor := dbms_sql.to_refcursor(l_curid);
    
        FETCH l_cursor BULK COLLECT
            INTO l_table_bmng_beds;
        CLOSE l_cursor;
    
        RETURN l_table_bmng_beds;
    
    END get_all_beds;

    FUNCTION get_total_beds(i_institution IN institution.id_institution%TYPE DEFAULT NULL) RETURN t_table_bmng_total_beds IS
    
        l_table_bmng_total_beds t_table_bmng_total_beds := t_table_bmng_total_beds(NULL);
    
        l_cursor pk_types.cursor_type;
    
        l_sql_header VARCHAR2(32000);
        l_sql_from   VARCHAR2(32000);
        l_sql_inner  VARCHAR2(32000);
        l_sql_footer VARCHAR2(32000);
        l_sql_stmt   CLOB;
        l_curid      INTEGER;
        l_ret        INTEGER;
    
    BEGIN
    
        l_curid      := dbms_sql.open_cursor;
        l_sql_header := 'SELECT t_rec_bmng_total_beds(id_institution, ' || --
                        '                             institution_name, ' || --
                        '                             total_beds, ' || --
                        '                             total_available, ' || --
                        '                             total_not_active, ' || --
                        '                             total_occupied) ' || --
                        '  FROM (SELECT t.*, pk_translation.get_translation(id_lang, i.code_institution) institution_name ' || --
                        '          FROM (SELECT d.id_institution, ' || --
                        '                       pk_sysconfig.get_config(''LANGUAGE'', d.id_institution, 0) id_lang, ' || --
                        '                       SUM(bdea.beds_ocuppied) + SUM(bdea.beds_reserved) total_occupied, ' || --
                        '                       SUM(bdea.beds_blocked) total_not_active, ' || --
                        '                       SUM(bdea.total_available_beds) total_available, ' || --
                        '                       SUM(bdea.beds_ocuppied) + SUM(bdea.beds_reserved) + SUM(bdea.beds_blocked) + ' || --
                        '                       SUM(bdea.total_available_beds) total_beds ';
    
        l_sql_from := '  FROM bmng_department_ea bdea ' || --
                      '  JOIN department d ' || --
                      '    ON bdea.id_department = d.id_department ' || --
                      '   AND d.flg_available = :g_yes ' || --
                      ' WHERE 1 = 1 ';
    
        IF i_institution IS NOT NULL
        THEN
            l_sql_inner := l_sql_inner || ' AND d.id_institution = :i_institution';
        END IF;
    
        l_sql_inner := l_sql_inner || ' AND instr(d.flg_type, ''I'') > 0';
    
        l_sql_footer := l_sql_footer || ' GROUP BY d.id_institution) t ' || --
                        '  JOIN institution i ' || --
                        '    ON t.id_institution = i.id_institution)';
    
        l_sql_stmt := to_clob(l_sql_header || l_sql_from || l_sql_inner || l_sql_footer);
    
        dbms_sql.parse(l_curid, l_sql_stmt, dbms_sql.native);
    
        --definição da bind variables 
        IF i_institution IS NOT NULL
        THEN
            dbms_sql.bind_variable(l_curid, 'i_institution', i_institution);
        END IF;
    
        dbms_sql.bind_variable(l_curid, 'g_yes', 'Y');
    
        l_ret := dbms_sql.execute(l_curid);
    
        l_cursor := dbms_sql.to_refcursor(l_curid);
    
        FETCH l_cursor BULK COLLECT
            INTO l_table_bmng_total_beds;
    
        RETURN l_table_bmng_total_beds;
    
    END get_total_beds;

    --************************************************************
    FUNCTION get_death_det_value
    (
        i_text              IN VARCHAR2,
        i_id_death_registry IN NUMBER,
        i_ds_component      IN NUMBER
    ) RETURN VARCHAR2 IS
        tbl_value table_varchar;
        l_return  VARCHAR2(4000);
        l_bool    BOOLEAN;
    BEGIN
    
        l_return := i_text;
        l_bool   := i_text IS NULL AND i_id_death_registry IS NOT NULL;
    
        IF l_bool
        THEN
        
            SELECT drd.value_vc2
              BULK COLLECT
              INTO tbl_value
              FROM death_registry_det drd
             WHERE drd.id_death_registry = i_id_death_registry
               AND drd.id_ds_component = i_ds_component;
        
            IF tbl_value.count > 0
            THEN
                l_return := tbl_value(1);
            END IF;
        
        END IF;
    
        RETURN l_return;
    
    END get_death_det_value;

    --************************************************************
    FUNCTION get_death_cause
    (
        i_motive            IN VARCHAR2,
        i_id_death_registry IN NUMBER
    ) RETURN VARCHAR2 IS
        l_return VARCHAR2(4000);
        k_ds_comp_death_cause CONSTANT NUMBER := 834;
    BEGIN
    
        l_return := get_death_det_value(i_motive, i_id_death_registry, k_ds_comp_death_cause);
    
        RETURN l_return;
    
    END get_death_cause;

    --************************************************************
    FUNCTION get_death_place
    (
        i_place             IN VARCHAR2,
        i_id_death_registry IN NUMBER
    ) RETURN VARCHAR2 IS
        l_return VARCHAR2(4000);
        k_ds_comp_place_death CONSTANT NUMBER := 833;
    BEGIN
    
        l_return := get_death_det_value(i_place, i_id_death_registry, k_ds_comp_place_death);
    
        RETURN l_return;
    
    END get_death_place;

    -- ***********************************************
    FUNCTION get_department
    (
        i_lang IN NUMBER,
        i_dcs  IN NUMBER,
        i_mode IN VARCHAR2 DEFAULT 'DESC'
    ) RETURN VARCHAR2 IS
        tbl_department table_varchar;
        tbl_id         table_number;
        l_return       VARCHAR2(4000);
    BEGIN
    
        SELECT pk_translation.get_translation(i_lang, d.code_department), d.id_department
          BULK COLLECT
          INTO tbl_department, tbl_id
          FROM dep_clin_serv dcs
          JOIN department d
            ON d.id_department = dcs.id_department
         WHERE dcs.id_dep_clin_serv = i_dcs;
    
        IF tbl_department.count > 0
        THEN
            IF i_mode = 'DESC'
            THEN
                l_return := tbl_department(1);
            ELSE
                l_return := tbl_id(1);
            END IF;
        END IF;
    
        RETURN l_return;
    
    END get_department;

    --***********************************************************
    --***********************************************************
    FUNCTION get_process
    (
        i_patient     IN NUMBER,
        i_institution IN NUMBER
    ) RETURN VARCHAR2 IS
        l_process_number pat_identifier.alert_process_number%TYPE;
        --********************************************
        FUNCTION get_process_number(i_id_pat_identifier IN NUMBER) RETURN VARCHAR2 IS
            tbl_process table_varchar;
            l_return    VARCHAR2(4000);
        BEGIN
        
            IF i_id_pat_identifier IS NOT NULL
            THEN
            
                SELECT pi.alert_process_number
                  BULK COLLECT
                  INTO tbl_process
                  FROM pat_identifier pi
                 WHERE pi.id_pat_identifier = i_id_pat_identifier;
            
                IF tbl_process.count > 0
                THEN
                    l_return := tbl_process(1);
                END IF;
            
            END IF;
        
            RETURN l_return;
        END get_process_number;
        -- ################################
    
        -- **************************************
        FUNCTION get_back_process_number
        (
            i_patient     IN NUMBER,
            i_institution IN NUMBER
        ) RETURN VARCHAR2 IS
            tbl_process table_varchar;
            l_return    VARCHAR2(4000);
            k_active CONSTANT VARCHAR2(0010 CHAR) := pk_alert_constant.g_active;
        BEGIN
        
            SELECT crn.num_clin_record
              BULK COLLECT
              INTO tbl_process
              FROM clin_record crn
             WHERE crn.id_patient = i_patient
               AND crn.flg_status = k_active
             ORDER BY decode(crn.id_institution, i_institution, 1, 0) DESC;
        
            IF tbl_process.count > 0
            THEN
                l_return := tbl_process(1);
            END IF;
        
            RETURN l_return;
        
        END get_back_process_number;
        -- ################################
    
    BEGIN
    
        l_process_number := get_process_number(NULL);
    
        -- IF_001
        IF l_process_number IS NULL
        THEN
            l_process_number := get_back_process_number(i_patient, i_institution);
        END IF; -- IF_001
    
        RETURN coalesce(l_process_number, '---');
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN '---';
    END get_process;

    --******************************************************************
    FUNCTION process_base_date
    (
        i_lang IN NUMBER,
        i_prof IN profissional,
        i_dt   IN VARCHAR2
    ) RETURN death_registry.dt_death%TYPE IS
        l_return death_registry.dt_death%TYPE;
    BEGIN
    
        l_return := pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                  i_prof      => i_prof,
                                                  i_timestamp => i_dt,
                                                  i_timezone  => '',
                                                  i_mask      => 'yyyy-mm-dd');
    
        l_return := pk_date_utils.trunc_insttimezone(i_prof, l_return);
    
        RETURN l_return;
    
    END process_base_date;

    --***************************************
    PROCEDURE date_processing
    (
        i_lang   IN NUMBER,
        i_prof   IN profissional,
        i_dt_ini IN VARCHAR2,
        i_dt_end IN VARCHAR2,
        o_dt_ini OUT death_registry.dt_death%TYPE,
        o_dt_end OUT death_registry.dt_death%TYPE
    ) IS
        l_dt_ini death_registry.dt_death%TYPE;
        l_dt_end death_registry.dt_death%TYPE;
    BEGIN
    
        IF i_dt_ini IS NOT NULL
        THEN
            l_dt_ini := process_base_date(i_lang => i_lang, i_prof => i_prof, i_dt => i_dt_ini);
            l_dt_ini := pk_date_utils.trunc_insttimezone(i_prof, l_dt_ini);
        ELSE
            l_dt_ini := pk_date_utils.trunc_insttimezone(i_prof, current_timestamp);
            l_dt_ini := l_dt_ini - numtodsinterval(k_limit_days, 'DAY');
        END IF;
    
        IF i_dt_end IS NOT NULL
        THEN
            l_dt_end := process_base_date(i_lang => i_lang, i_prof => i_prof, i_dt => i_dt_end);
        ELSE
            l_dt_end := current_timestamp;
        END IF;
    
        l_dt_end := pk_date_utils.trunc_insttimezone(i_prof, l_dt_end);
        l_dt_end := l_dt_end + numtodsinterval(1, 'DAY') - numtodsinterval(1, 'SECOND');
    
        o_dt_ini := l_dt_ini;
        o_dt_end := l_dt_end;
    
    END date_processing;

    --**********************************************************
    -- select * from table(pk_data_access_cdoc.get_deaths( 11111, '01-09-2018', '30-09-2019' ))
    --************************************************************

    FUNCTION get_deaths
    (
        i_institution IN NUMBER DEFAULT NULL,
        i_dt_ini      IN VARCHAR2 DEFAULT NULL,
        i_dt_end      IN VARCHAR2 DEFAULT NULL
    ) RETURN t_tbl_data_death IS
        tbl_list t_tbl_data_death;
        l_lang   NUMBER;
    
        l_dt_ini death_registry.dt_death%TYPE;
        l_dt_end death_registry.dt_death%TYPE;
        l_prof   profissional;
    
    BEGIN
    
        l_prof := get_lprof(i_institution);
        l_lang := pk_sysconfig.get_config('LANGUAGE', l_prof.institution, l_prof.software);
    
        date_processing(l_lang, l_prof, i_dt_ini, i_dt_end, l_dt_ini, l_dt_end);
    
        SELECT t_rec_data_death(id_institution      => xmain.id_institution,
                                institution         => xmain.institution,
                                main_death_cause    => xmain.main_death_cause,
                                death_date_tstz     => xmain.death_date_tstz,
                                death_date          => xmain.death_date,
                                death_place         => xmain.death_place,
                                ward_code           => xmain.ward_code,
                                ward                => xmain.ward,
                                final_diagnosis     => xmain.final_diagnosis,
                                initial_diagnosis   => xmain.initial_diagnosis,
                                secondary_diagnosis => xmain.secondary_diagnosis,
                                patient_file_number => xmain.patient_file_number,
                                dt_last_update_tstz => xmain.dt_last_update_tstz,
                                dt_last_update      => xmain.dt_last_update)
          BULK COLLECT
          INTO tbl_list
          FROM (SELECT xsub1.id_institution,
                       (SELECT pk_data_access_cdoc.get_inst_name(l_lang, xsub1.id_institution)
                          FROM dual) institution,
                       pk_data_access_cdoc.get_death_cause(xsub1.deceased_motive, xsub1.id_death_registry) main_death_cause,
                       xsub1.dt_death death_date_tstz,
                       pk_data_access_cdoc.format_date(xsub1.l_prof, xsub1.dt_death) death_date,
                       pk_data_access_cdoc.get_death_place(xsub1.deceased_place, id_death_registry) death_place,
                       pk_data_access_cdoc.get_department(l_lang, xsub1.id_dep_clin_serv, 'CODE') ward_code,
                       pk_data_access_cdoc.get_department(l_lang, xsub1.id_dep_clin_serv) ward,
                       pk_data_access_cdoc.get_diag_final_icd_code(xsub1.id_episode) final_diagnosis,
                       pk_data_access_cdoc.get_diag_initial_icd_code(xsub1.id_episode) initial_diagnosis,
                       pk_data_access_cdoc.get_diag_secondary_icd_code(xsub1.id_episode) secondary_diagnosis,
                       pk_data_access_cdoc.get_process(xsub1.id_patient, xsub1.id_institution) patient_file_number,
                       xsub1.dt_last_update_tstz,
                       pk_data_access_cdoc.format_date(xsub1.l_prof, xsub1.dt_last_update_tstz) dt_last_update
                  FROM (SELECT xsub2.*, profissional(0, xsub2.id_institution, xsub2.id_software) l_prof
                          FROM (SELECT xtbl2.id_institution,
                                       xtbl2.id_patient,
                                       xtbl2.dt_death,
                                       xtbl2.id_episode,
                                       xtbl2.id_prev_episode,
                                       xtbl2.id_epis_type,
                                       xtbl2.id_death_registry,
                                       xtbl2.id_dep_clin_serv,
                                       xtbl2.id_software,
                                       xtbl2.deceased_motive,
                                       xtbl2.deceased_place,
                                       xtbl2.dt_last_update_tstz
                                  FROM TABLE(pk_data_access_cdoc.get_deaths_base(i_institution, l_dt_ini, l_dt_end)) xtbl2) xsub2) xsub1) xmain;
    
        RETURN tbl_list;
    
    END get_deaths;

    FUNCTION get_base_sql
    (
        i_tbl_col   IN table_varchar,
        i_tbl_from  IN table_varchar,
        i_tbl_where IN table_varchar
    ) RETURN VARCHAR2 IS
        l_return    VARCHAR2(32000);
        xlf         VARCHAR2(00010 CHAR) := chr(10);
        l_select    VARCHAR2(32000);
        l_from      VARCHAR2(32000);
        l_where_fix VARCHAR2(32000);
    BEGIN
    
        <<lup_thru_needed_columns>>
        FOR i IN 1 .. i_tbl_col.count
        LOOP
            l_select := l_select || i_tbl_col(i) || xlf;
        END LOOP lup_thru_needed_columns;
    
        <<lup_thru_from_clause>>
        FOR i IN 1 .. i_tbl_from.count
        LOOP
            l_from := l_from || i_tbl_from(i) || xlf;
        END LOOP lup_thru_from_clause;
    
        <<lup_thru_where_fixed>>
        FOR i IN 1 .. i_tbl_where.count
        LOOP
            l_where_fix := l_where_fix || i_tbl_where(i) || xlf;
        END LOOP lup_thru_where_fixed;
    
        l_return := l_select || l_from || l_where_fix;
    
        RETURN l_return;
    
    END get_base_sql;

    -- ************************************************
    FUNCTION get_deaths_base
    (
        i_institution IN NUMBER DEFAULT NULL,
        i_dt_ini      IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_dt_end      IN TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN t_tbl_data_death_base IS
        tbl_return t_tbl_data_death_base;
    
        -- var for cursor 
        l_full_sql CLOB;
        l_curid    INTEGER;
        l_ret      INTEGER;
        l_cursor   pk_types.cursor_type;
    
        -- var for building sql
        xlf VARCHAR2(00010 CHAR) := chr(10);
        --l_select    VARCHAR2(32000);
        --l_from      VARCHAR2(32000);
        --l_where_fix VARCHAR2(32000);
        l_where_opt VARCHAR2(32000);
        l_base_sql  VARCHAR2(32000);
    
        tbl_columns table_varchar := table_varchar(q'[select]',
                                                   q'[T_REC_DATA_DEATH_BASE ]',
                                                   q'[(]',
                                                   q'[ id_institution       => xsql.id_institution]',
                                                   q'[,id_patient             => xsql.id_patient]',
                                                   q'[,dt_death               => xsql.dt_death]',
                                                   q'[,id_episode             => xsql.id_episode]',
                                                   q'[,id_prev_episode        => xsql.id_prev_episode]',
                                                   q'[,id_epis_type           => xsql.id_epis_type]',
                                                   q'[,id_death_registry      => xsql.id_death_registry]',
                                                   q'[,id_dep_clin_serv       => xsql.id_dep_clin_serv]',
                                                   q'[,id_software            => ( select pk_data_access_cdoc.get_soft_by_epis_type( xsql.id_epis_type, xsql.id_institution ) from dual )]',
                                                   q'[,deceased_motive    => xsql.deceased_motive]',
                                                   q'[,deceased_place         => xsql.deceased_place]',
                                                   q'[,DT_LAST_UPDATE_TSTZ    => coalesce( xsql.update_time, xsql.create_time )]',
                                                   q'[)]');
    
        tbl_from table_varchar := table_varchar(q'[from ]',
                                                q'[(]',
                                                q'[select]',
                                                q'[coalesce( xd.id_institution, pat.institution_key ) id_institution,]',
                                                q'[pat.id_patient,]',
                                                q'[pat.dt_deceased dt_death,]',
                                                q'[pat.deceased_motive,]',
                                                q'[pat.deceased_place,]',
                                                q'[xd.id_episode,]',
                                                q'[xd.id_prev_episode,]',
                                                q'[xd.id_epis_type,]',
                                                q'[xd.id_death_registry,]',
                                                q'[xd.id_dep_clin_serv,]',
                                                q'[pat.create_time,]',
                                                q'[pat.update_time]',
                                                q'[from patient pat]',
                                                q'[left join ( ]',
                                                q'[        select ]',
                                                q'[        dr.id_death_registry, ]',
                                                q'[        dr.dt_death, ]',
                                                q'[        vis.id_patient, ]',
                                                q'[        epis.id_episode, ]',
                                                q'[        epis.id_prev_episode,]',
                                                q'[        epis.id_epis_type, ]',
                                                q'[        vis.id_institution, ]',
                                                q'[        ei.id_dep_clin_serv]',
                                                q'[        from death_registry dr ]',
                                                q'[        join episode epis on dr.id_episode = epis.id_episode]',
                                                q'[        join epis_info ei on ei.id_episode = epis.id_episode]',
                                                q'[        join visit vis on vis.id_visit = epis.id_visit]',
                                                q'[        where dr.flg_status != 'C']',
                                                q'[        ) xd on xd.id_patient = pat.id_patient]',
                                                q'[) xsql]');
    
        tbl_where_fix table_varchar := table_varchar(q'[where xsql.dt_death between :l_dt_ini and :l_dt_end]');
        tbl_where_opt table_varchar := table_varchar(q'[and xsql.id_institution = :i_institution]');
    
    BEGIN
    
        l_base_sql := get_base_sql(i_tbl_col => tbl_columns, i_tbl_from => tbl_from, i_tbl_where => tbl_where_fix);
    
        IF i_institution IS NOT NULL
        THEN
            l_where_opt := l_where_opt || tbl_where_opt(1) || xlf;
        END IF;
    
        l_full_sql := to_clob(l_base_sql || l_where_opt);
    
        -- binding vars and running sql
        l_curid := dbms_sql.open_cursor;
        dbms_sql.parse(l_curid, l_full_sql, dbms_sql.native);
    
        dbms_sql.bind_variable(l_curid, 'l_dt_ini', i_dt_ini);
        dbms_sql.bind_variable(l_curid, 'l_dt_end', i_dt_end);
    
        IF i_institution IS NOT NULL
        THEN
            dbms_sql.bind_variable(l_curid, 'i_institution', i_institution);
        END IF;
    
        l_ret := dbms_sql.execute(l_curid);
    
        l_cursor := dbms_sql.to_refcursor(l_curid);
    
        FETCH l_cursor BULK COLLECT
            INTO tbl_return;
        CLOSE l_cursor;
    
        RETURN tbl_return;
    
    END get_deaths_base;

    -- ****************************************** 
    FUNCTION get_soft_by_epis_type
    (
        i_epis_type   IN NUMBER,
        i_institution IN NUMBER
    ) RETURN NUMBER IS
        tbl_id_software table_number;
        l_return        NUMBER;
    BEGIN
    
        IF i_epis_type IS NOT NULL
        THEN
            SELECT etsi.id_software
              BULK COLLECT
              INTO tbl_id_software
              FROM epis_type_soft_inst etsi
             WHERE etsi.id_epis_type = i_epis_type
               AND etsi.id_institution IN (i_institution, 0)
             ORDER BY etsi.id_institution DESC;
        
            IF tbl_id_software.count > 0
            THEN
                l_return := tbl_id_software(1);
            END IF;
        
        END IF;
    
        RETURN l_return;
    
    END get_soft_by_epis_type;

    FUNCTION get_diag_icd_code
    (
        i_episode IN NUMBER,
        i_mode    IN VARCHAR2,
        i_type    IN VARCHAR2
    ) RETURN table_varchar IS
        tbl_code table_varchar := table_varchar();
        --l_return VARCHAR2(4000);
    BEGIN
    
        IF i_episode IS NOT NULL
        THEN
        
            SELECT d.code_icd
              BULK COLLECT
              INTO tbl_code
              FROM epis_diagnosis ed
              JOIN diagnosis d
                ON d.id_diagnosis = ed.id_diagnosis
             WHERE ed.flg_type = i_type
               AND ed.flg_status NOT IN ('C', 'R')
               AND ed.id_episode = i_episode
               AND ((ed.flg_final_type = i_mode AND i_type = k_diag_type_final) OR (i_type = k_diag_type_diferencial))
             ORDER BY ed.dt_epis_diagnosis_tstz DESC;
        
        END IF;
    
        RETURN tbl_code;
    
    END get_diag_icd_code;

    --****************************************************
    FUNCTION get_diag_final_icd_code(i_episode IN NUMBER) RETURN VARCHAR2 IS
        tbl_result table_varchar := table_varchar();
        l_return   VARCHAR2(4000);
    BEGIN
    
        tbl_result := get_diag_icd_code(i_episode, k_diag_mode_primary, k_diag_type_final);
        l_return   := array_2_field(tbl_result);
    
        RETURN l_return;
    
    END get_diag_final_icd_code;

    --************************************************
    FUNCTION get_diag_death_icd_code(i_episode IN NUMBER) RETURN VARCHAR2 IS
        l_return VARCHAR2(4000);
    BEGIN
    
        l_return := get_diag_final_icd_code(i_episode);
        RETURN l_return;
    
    END get_diag_death_icd_code;

    --****************************************************
    FUNCTION get_diag_initial_icd_code(i_episode IN NUMBER) RETURN VARCHAR2 IS
        tbl_result table_varchar := table_varchar();
        l_return   VARCHAR2(4000);
    BEGIN
    
        tbl_result := get_diag_icd_code(i_episode, k_diag_mode_primary, k_diag_type_diferencial);
        l_return   := array_2_field(tbl_result);
    
        RETURN l_return;
    
    END get_diag_initial_icd_code;

    --****************************************************
    FUNCTION get_diag_primary_icd_code(i_episode IN NUMBER) RETURN VARCHAR2 IS
        tbl_result table_varchar := table_varchar();
        l_return   VARCHAR2(4000);
    BEGIN
    
        tbl_result := get_diag_icd_code(i_episode, k_diag_mode_primary, k_diag_type_final);
        l_return   := array_2_field(tbl_result);
    
        RETURN l_return;
    
    END get_diag_primary_icd_code;

    --****************************************************
    FUNCTION get_diag_secondary_icd_code(i_episode IN NUMBER) RETURN VARCHAR2 IS
        tbl_result table_varchar := table_varchar();
        l_return   VARCHAR2(4000);
    BEGIN
    
        tbl_result := get_diag_icd_code(i_episode, k_diag_mode_secondary, k_diag_type_final);
        l_return   := array_2_field(tbl_result);
    
        RETURN l_return;
    
    END get_diag_secondary_icd_code;

    -- ************************************************

    FUNCTION get_child_birth
    (
        i_institution IN NUMBER DEFAULT NULL,
        i_dt_ini      IN VARCHAR2 DEFAULT NULL,
        i_dt_end      IN VARCHAR2 DEFAULT NULL
    ) RETURN t_table_data_child_birth IS
        tbl_list t_table_data_child_birth;
    
        l_doc_area_newborn CONSTANT NUMBER := 1048;
        --l_doc_area_delivery      CONSTANT NUMBER := 1047;
        l_dt_doc_internal_name   CONSTANT VARCHAR2(200) := 'Data e hora do nascimento';
        l_del_type_internal_name CONSTANT VARCHAR2(200) := 'Tipo de parto_';
        l_dt_mask_date           CONSTANT VARCHAR2(200) := 'DD/MM/YYYY';
        l_dt_mask_time           CONSTANT VARCHAR2(200) := 'HH24:MI';
        l_no                     CONSTANT VARCHAR2(1) := 'N';
    
        l_lang      NUMBER;
        l_cd_gender VARCHAR2(2000);
    
        l_dt_ini      epis_doc_delivery.dt_delivery_tstz%TYPE;
        l_dt_end      epis_doc_delivery.dt_delivery_tstz%TYPE;
        l_institution institution.id_institution%TYPE;
        l_prof        profissional;
    
    BEGIN
    
        l_institution := coalesce(i_institution, pk_sysconfig.get_data_access_inst());
        l_prof        := profissional(0, l_institution, k_default_software);
        l_lang        := pk_sysconfig.get_config('LANGUAGE', l_prof.institution, l_prof.software);
        l_cd_gender   := 'PATIENT.GENDER';
    
        date_processing(l_lang, l_prof, i_dt_ini, i_dt_end, l_dt_ini, l_dt_end);
    
        SELECT t_rec_data_child_birth(id_institution          => t.id_institution,
                                      institution_name        => t.institution_name,
                                      id_episode              => t.id_episode,
                                      delivery_date_time      => t.delivery_date_time,
                                      delivery_date_time_tstz => t.delivery_date_time_tstz,
                                      child_gender            => t.child_gender,
                                      child_gender_desc       => t.child_gender_desc,
                                      child_file_number       => t.child_file_number,
                                      delivery_type_code      => pk_data_access_cdoc.get_birth_type(i_epis_documentation => t.i_epis_documentation,
                                                                                                    i_doc_int_name       => t.i_doc_int_name),
                                      delivery_type           => pk_data_access_cdoc.get_epis_doc_component_desc(i_lang               => l_lang,
                                                                                                                 i_prof               => profissional(NULL,
                                                                                                                                                      t.id_institution,
                                                                                                                                                      NULL),
                                                                                                                 i_doc_int_name       => t.i_doc_int_name,
                                                                                                                 i_epis_documentation => t.i_epis_documentation,
                                                                                                                 i_has_title          => l_no),
                                      patient_file_number     => t.patient_file_number,
                                      dt_last_update_tstz     => t.dt_last_update_tstz,
                                      dt_last_update          => dt_last_update)
          BULK COLLECT
          INTO tbl_list
          FROM (SELECT cb.id_institution,
                       pk_translation.get_translation(l_lang, cb.code_institution) institution_name,
                       cb.id_episode,
                       cb.delivery_dt delivery_date_time,
                       CAST((pk_date_utils.get_string_tstz(i_lang      => l_lang,
                                                           i_prof      => profissional(NULL, cb.id_institution, NULL),
                                                           i_timestamp => cb.delivery_dt,
                                                           i_timezone  => '',
                                                           i_mask      => 'DD/MM/YYYY HH24:MI')) AS TIMESTAMP WITH LOCAL TIME ZONE) delivery_date_time_tstz,
                       cb.flg_child_gender child_gender,
                       pk_sysdomain.get_domain_no_avail(i_code_dom => l_cd_gender,
                                                        i_val      => cb.flg_child_gender,
                                                        i_lang     => l_lang) child_gender_desc,
                       pk_data_access_cdoc.get_process(cb.echild_id_patient, cb.id_institution) child_file_number,
                       l_del_type_internal_name || cb.edoc_child_number i_doc_int_name,
                       pk_data_access_cdoc.get_mother_epis_doc_deliv_type(cb.emother_id_episode, cb.id_pat_pregnancy) i_epis_documentation,
                       pk_data_access_cdoc.get_process(cb.emother_id_patient, cb.id_institution) patient_file_number,
                       CAST((pk_date_utils.get_string_tstz(i_lang      => l_lang,
                                                           i_prof      => profissional(NULL, cb.id_institution, NULL),
                                                           i_timestamp => cb.delivery_dt,
                                                           i_timezone  => '',
                                                           i_mask      => 'DD/MM/YYYY HH24:MI')) AS TIMESTAMP WITH LOCAL TIME ZONE) dt_last_update_tstz,
                       cb.delivery_dt dt_last_update
                  FROM (SELECT cb1.*,
                               pk_patient.get_pat_gender(cb1.echild_id_patient) flg_child_gender,
                               pk_delivery.get_delivery_value(i_lang          => l_lang,
                                                              i_prof          => NULL,
                                                              i_pat_pregnancy => cb1.id_pat_pregnancy,
                                                              i_child_number  => cb1.edoc_child_number,
                                                              i_doc_area      => l_doc_area_newborn,
                                                              i_doc_int_name  => l_dt_doc_internal_name,
                                                              i_mask          => l_dt_mask_date || ' ' || l_dt_mask_time) delivery_dt
                          FROM (SELECT cbb.id_institution,
                                       cbb.code_institution,
                                       cbb.dt_delivery_tstz,
                                       cbb.echild_id_patient,
                                       cbb.echild_id_episode,
                                       cbb.id_pat_pregnancy,
                                       cbb.edoc_child_number,
                                       cbb.child_nation,
                                       cbb.emother_id_patient,
                                       cbb.emother_id_episode,
                                       cbb.mother_nation,
                                       cbb.id_episode
                                  FROM TABLE(pk_data_access_cdoc.get_child_birth_base(i_institution, l_dt_ini, l_dt_end)) cbb) cb1) cb) t;
    
        RETURN tbl_list;
    
    END get_child_birth;

    FUNCTION get_child_birth_base
    (
        i_institution IN NUMBER DEFAULT NULL,
        i_dt_ini      IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_dt_end      IN TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN t_tbl_data_child_birth_base IS
        tbl_return t_tbl_data_child_birth_base;
    
        -- var for cursor 
        l_full_sql CLOB;
        l_curid    INTEGER;
        l_ret      INTEGER;
        l_cursor   pk_types.cursor_type;
    
        -- var for building sql
        xlf VARCHAR2(00010 CHAR) := chr(10);
    
        l_where_opt VARCHAR2(32000);
        l_base_sql  VARCHAR2(32000);
        --l_order_by_sql VARCHAR2(32000);
    
        tbl_columns table_varchar := table_varchar('SELECT',
                                                   'T_REC_DATA_CHILD_BIRTH_BASE(',
                                                   'echild.id_institution,',
                                                   'i.code_institution,',
                                                   'edoc.dt_delivery_tstz,',
                                                   'echild.id_patient,',
                                                   'echild.id_episode,',
                                                   'preg.id_pat_pregnancy,',
                                                   'edoc.child_number,',
                                                   'psachild.id_country_nation,',
                                                   'emother.id_patient,',
                                                   'emother.id_episode,',
                                                   'psamother.id_country_nation,',
                                                   'emother.id_episode',
                                                   ')');
    
        tbl_from table_varchar := table_varchar(q'[FROM (SELECT row_number() over(PARTITION BY pp.id_patient ORDER BY pp.n_pregnancy DESC) pregnancy_rn, pp.*]',
                                                q'[FROM pat_pregnancy pp]',
                                                q'[WHERE pp.flg_status NOT IN ('C', 'A')) preg]',
                                                q'[JOIN (SELECT t.id_pat_pregnancy, t.id_child_episode, t.child_number, id_episode, t.dt_delivery_tstz]',
                                                q'[FROM (SELECT row_number() over(PARTITION BY edd.id_pat_pregnancy ORDER BY edd.dt_register_tstz) rn,]',
                                                q'[edd.id_pat_pregnancy,edd.id_child_episode,edd.child_number,]',
                                                q'[ed.id_episode, edd.dt_delivery_tstz]',
                                                q'[FROM epis_doc_delivery edd]',
                                                q'[JOIN epis_documentation ed ON edd.id_epis_documentation = ed.id_epis_documentation]',
                                                q'[WHERE edd.id_child_episode IS NOT NULL) t) edoc]',
                                                q'[ON edoc.id_pat_pregnancy = preg.id_pat_pregnancy]',
                                                q'[JOIN episode emother ON emother.id_episode = edoc.id_episode]',
                                                q'[JOIN episode echild ON echild.id_episode = edoc.id_child_episode]',
                                                q'[join institution i ON emother.id_institution = i.id_institution]',
                                                q'[join pat_soc_attributes psachild on psachild.id_patient=echild.id_patient]',
                                                q'[join pat_soc_attributes psamother on psamother.id_patient=emother.id_patient]');
    
        tbl_where_fix table_varchar := table_varchar(q'[where edoc.dt_delivery_tstz between :l_dt_ini and :l_dt_end]');
        tbl_where_opt table_varchar := table_varchar(q'[and echild.id_institution = :i_institution]');
    
    BEGIN
    
        l_base_sql := get_base_sql(i_tbl_col => tbl_columns, i_tbl_from => tbl_from, i_tbl_where => tbl_where_fix);
    
        IF i_institution IS NOT NULL
        THEN
            l_where_opt := l_where_opt || tbl_where_opt(1) || xlf;
        END IF;
    
        l_full_sql := to_clob(l_base_sql || l_where_opt);
    
        -- binding vars and running sql
        l_curid := dbms_sql.open_cursor;
        dbms_sql.parse(l_curid, l_full_sql, dbms_sql.native);
    
        dbms_sql.bind_variable(l_curid, 'l_dt_ini', i_dt_ini);
        dbms_sql.bind_variable(l_curid, 'l_dt_end', i_dt_end);
    
        IF i_institution IS NOT NULL
        THEN
            dbms_sql.bind_variable(l_curid, 'i_institution', i_institution);
        END IF;
    
        l_ret := dbms_sql.execute(l_curid);
    
        l_cursor := dbms_sql.to_refcursor(l_curid);
    
        FETCH l_cursor BULK COLLECT
            INTO tbl_return;
        CLOSE l_cursor;
    
        RETURN tbl_return;
    
    END get_child_birth_base;

    FUNCTION get_patient_type_arabic
    (
        i_lang    IN NUMBER,
        i_prof    IN profissional,
        i_patient IN NUMBER
    ) RETURN VARCHAR2 IS
        l_return VARCHAR2(4000);
    BEGIN
    
        l_return := pk_adt.get_patient_type_arabic(i_prof => i_prof, i_patient => i_patient);
    
        l_return := pk_sysdomain.get_domain('PATIENT_HAJJ_UMRAH', l_return, i_lang);
    
        RETURN l_return;
    
    END get_patient_type_arabic;

    FUNCTION get_treatment_physicians_base
    (
        i_lang    IN NUMBER,
        i_prof    IN profissional,
        i_episode IN NUMBER,
        i_mode    IN VARCHAR2
    ) RETURN table_varchar IS
        tbl_return table_varchar := table_varchar();
        tbl_name   table_varchar;
        tbl_id     table_varchar;
        --l_return        VARCHAR2(32000);
        --l_sep           VARCHAR2(0010 CHAR);
        l_hand_off_type VARCHAR2(0100 CHAR);
    
    BEGIN
    
        pk_hand_off_core.get_hand_off_type(i_lang, i_prof, l_hand_off_type);
    
        IF l_hand_off_type = pk_hand_off.g_handoff_multiple
        THEN
        
            SELECT pk_prof_utils.get_name_signature(i_lang, i_prof, xsql.id_professional), xsql.id_professional
              BULK COLLECT
              INTO tbl_name, tbl_id
              FROM (SELECT DISTINCT empr.id_professional
                      FROM epis_prof_resp epr
                      JOIN epis_multi_prof_resp empr
                        ON empr.id_epis_prof_resp = epr.id_epis_prof_resp
                     WHERE epr.id_episode = i_episode
                       AND epr.flg_type = pk_hand_off.g_prof_cat_doc
                       AND epr.flg_status = pk_hand_off.g_hand_off_f) xsql;
        
        ELSE
        
            SELECT pk_prof_utils.get_name_signature(i_lang, i_prof, xsql.id_professional), xsql.id_professional
              BULK COLLECT
              INTO tbl_name, tbl_id
              FROM (SELECT DISTINCT xsub.id_professional
                      FROM (SELECT nvl(epr.id_prof_to, epr.id_prof_comp) id_professional
                              FROM epis_prof_resp epr
                             WHERE epr.id_episode = i_episode
                               AND epr.flg_type = pk_hand_off.g_prof_cat_doc
                               AND epr.flg_status = pk_hand_off.g_hand_off_f) xsub) xsql;
        
        END IF;
    
        IF i_mode = 'NAME'
        THEN
            tbl_return := tbl_name;
        ELSE
            tbl_return := tbl_id;
        END IF;
    
        RETURN tbl_return;
    
    END get_treatment_physicians_base;

    -- *************************
    FUNCTION get_treatment_physicians
    (
        i_lang    IN NUMBER,
        i_prof    IN profissional,
        i_episode IN NUMBER
    ) RETURN VARCHAR2 IS
        tbl_name table_varchar := table_varchar();
        l_return VARCHAR2(32000);
        l_sep    VARCHAR2(0010 CHAR);
        --l_hand_off_type VARCHAR2(0100 CHAR);
    BEGIN
    
        tbl_name := get_treatment_physicians_base(i_lang    => i_lang,
                                                  i_prof    => i_prof,
                                                  i_episode => i_episode,
                                                  i_mode    => 'NAME');
    
        FOR i IN 1 .. tbl_name.count
        LOOP
        
            l_sep := ',' || chr(32);
            IF i = 1
            THEN
                l_sep := '';
            END IF;
            l_return := l_return || l_sep || tbl_name(i);
        
        END LOOP;
    
        RETURN l_return;
    
    END get_treatment_physicians;

    -- *************************
    FUNCTION get_treatment_physicians_id
    (
        i_lang    IN NUMBER,
        i_prof    IN profissional,
        i_episode IN NUMBER
    ) RETURN VARCHAR2 IS
        tbl_return table_varchar := table_varchar();
        l_return   VARCHAR2(4000);
    BEGIN
    
        tbl_return := get_treatment_physicians_base(i_lang    => i_lang,
                                                    i_prof    => i_prof,
                                                    i_episode => i_episode,
                                                    i_mode    => 'IDS');
    
        l_return := pk_data_access.array_to_var(tbl_return);
        RETURN l_return;
    
    END get_treatment_physicians_id;

    FUNCTION get_complaint_desc
    (
        i_lang              IN NUMBER,
        i_patient_complaint IN VARCHAR2,
        i_code_complaint    IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_return VARCHAR2(4000);
        l_part1  VARCHAR2(4000);
        l_part2  VARCHAR2(4000);
    BEGIN
    
        IF i_patient_complaint IS NOT NULL
        THEN
            l_part1 := i_patient_complaint;
        END IF;
    
        IF i_code_complaint IS NOT NULL
        THEN
            l_part2 := pk_translation.get_translation(i_lang, i_code_complaint);
        END IF;
    
        IF l_part1 IS NOT NULL
           AND l_part2 IS NOT NULL
        THEN
            l_part2 := ' (' || l_part2 || ')';
        END IF;
    
        l_return := l_part1 || l_part2;
    
        RETURN l_return;
    
    END get_complaint_desc;

    FUNCTION get_triage_level
    (
        i_lang              IN NUMBER,
        i_prof              IN profissional,
        i_id_epis_triage    IN NUMBER,
        i_code_triage_color IN VARCHAR2,
        i_flg_type          IN VARCHAR2,
        i_code_accuity      IN VARCHAR2,
        i_id_triage_type    IN NUMBER,
        i_id_triage_color   NUMBER,
        i_msg               IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_tmp VARCHAR2(4000);
    BEGIN
    
        CASE
            WHEN i_id_epis_triage IS NOT NULL THEN
            
                l_tmp := pk_translation.get_translation(i_lang, i_code_triage_color);
            
                IF i_flg_type != 'N'
                THEN
                    l_tmp := l_tmp || ' - ' || pk_translation.get_translation(i_lang, i_code_accuity);
                END IF;
            
                IF i_id_triage_color IS NOT NULL
                THEN
                    l_tmp := l_tmp || chr(10) || '(' || i_msg || chr(32);
                    l_tmp := l_tmp || pk_edis_triage.get_triage_color_orig(i_lang,
                                                                           i_prof,
                                                                           'V',
                                                                           i_id_triage_type,
                                                                           i_id_triage_color);
                
                    l_tmp := l_tmp || ')';
                END IF;
            
            ELSE
                l_tmp := NULL;
        END CASE;
    
        RETURN l_tmp;
    
    END get_triage_level;

    --***************************************************************
    FUNCTION is_unknown
    (
        i_prof    IN profissional,
        i_patient IN NUMBER
    ) RETURN VARCHAR2 IS
        l_count  NUMBER;
        l_return VARCHAR2(0010 CHAR) := 'Y';
        l_docid  VARCHAR2(4000);
    BEGIN
    
        l_docid := get_patient_docid(i_prof, i_patient);
    
        SELECT COUNT(*)
          INTO l_count
          FROM patient pat
         WHERE pat.id_patient = i_patient
              --AND pat.age IS NOT NULL
           AND pat.dt_birth IS NOT NULL
           AND l_docid IS NOT NULL
        --AND last_name IS NOT NULL
        ;
    
        IF l_count > 0
        THEN
            l_return := 'N';
        END IF;
    
        RETURN l_return;
    
    END is_unknown;

    FUNCTION get_vs_pain
    (
        i_episode IN NUMBER,
        i_mode    IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_return  VARCHAR2(4000);
        tbl_value table_varchar;
        k_id_content_vs_pain CONSTANT VARCHAR2(0050 CHAR) := 'TMP33.108';
    BEGIN
    
        SELECT VALUE
          BULK COLLECT
          INTO tbl_value
          FROM vital_sign_read vsr
          JOIN vital_sign vs
            ON vs.id_vital_sign = vsr.id_vital_sign
         WHERE vsr.id_episode = i_episode
           AND vsr.flg_state = pk_alert_constant.g_active
           AND vs.id_content = k_id_content_vs_pain
         ORDER BY vsr.dt_vital_sign_read_tstz ASC;
    
        IF tbl_value.count > 0
        THEN
        
            IF i_mode = k_vs_pain_order_first
            THEN
                l_return := tbl_value(1);
            ELSE
                l_return := tbl_value(tbl_value.count);
            END IF;
        END IF;
    
        RETURN l_return;
    
    END get_vs_pain;

    FUNCTION admission_reason(i_episode IN NUMBER) RETURN CLOB IS
        l_return  CLOB;
        tbl_notes table_clob;
    BEGIN
    
        IF i_episode IS NOT NULL
        THEN
        
            SELECT desc_epis_anamnesis
              BULK COLLECT
              INTO tbl_notes
              FROM epis_anamnesis ea
             WHERE ea.id_episode = i_episode
               AND flg_status = 'A'
             ORDER BY ea.dt_epis_anamnesis_tstz DESC;
        
            IF tbl_notes.count > 0
            THEN
            
                FOR i IN 1 .. tbl_notes.count
                LOOP
                    IF i = 1
                    THEN
                        l_return := tbl_notes(i);
                    ELSE
                        l_return := l_return || chr(10) || tbl_notes(i);
                    END IF;
                END LOOP;
            
            END IF;
        
        END IF;
    
        RETURN l_return;
    
    END admission_reason;

    FUNCTION get_origin
    (
        i_lang    IN NUMBER,
        i_episode IN NUMBER
    ) RETURN VARCHAR2 IS
        tbl_code_prev table_varchar;
        tbl_code_inp  table_varchar;
        l_code        VARCHAR2(4000);
        l_return      VARCHAR2(4000);
    BEGIN
    
        IF i_episode IS NOT NULL
        THEN
        
            SELECT et_prev.code_epis_type, et_inp.code_epis_type
              BULK COLLECT
              INTO tbl_code_prev, tbl_code_inp
              FROM episode ep
              JOIN epis_type et_inp
                ON et_inp.id_epis_type = ep.id_epis_type
              LEFT JOIN episode prev
                ON prev.id_episode = ep.id_prev_episode
              LEFT JOIN epis_type et_prev
                ON et_prev.id_epis_type = prev.id_epis_type
             WHERE ep.id_episode = i_episode;
        
            IF tbl_code_inp.count > 0
            THEN
            
                l_code := tbl_code_prev(1);
                IF l_code IS NULL
                THEN
                    l_code := tbl_code_inp(1);
                END IF;
                l_return := pk_translation.get_translation(i_lang, l_code);
            END IF;
        
        END IF;
    
        RETURN l_return;
    
    END get_origin;

    FUNCTION get_admission_ward
    (
        i_lang IN NUMBER,
        i_dcs  IN NUMBER
    ) RETURN VARCHAR2 IS
        tbl_desc table_varchar;
        l_return VARCHAR2(4000);
    BEGIN
    
        IF i_dcs IS NOT NULL
        THEN
        
            SELECT pk_translation.get_translation(i_lang, dep.code_department)
              BULK COLLECT
              INTO tbl_desc
              FROM dep_clin_serv dcs
              JOIN department dep
                ON dep.id_department = dcs.id_department
             WHERE dcs.id_dep_clin_serv = i_dcs;
        
            IF tbl_desc.count > 0
            THEN
                l_return := tbl_desc(1);
            END IF;
        
        END IF;
    
        RETURN l_return;
    
    END get_admission_ward;

    -- ************************************************
    FUNCTION get_emr_outpatient
    (
        i_institution IN NUMBER DEFAULT NULL,
        i_dt_ini      IN VARCHAR2 DEFAULT NULL,
        i_dt_end      IN VARCHAR2 DEFAULT NULL
    ) RETURN t_tbl_data_emr_outpatient IS
        tbl_list t_tbl_data_emr_outpatient;
    
        l_software CONSTANT NUMBER := pk_alert_constant.g_soft_outpatient;
    
        l_lang NUMBER;
    
        l_dt_ini      schedule_outp.dt_target_tstz%TYPE;
        l_dt_end      schedule_outp.dt_target_tstz%TYPE;
        l_institution institution.id_institution%TYPE;
        l_prof        profissional;
    
    BEGIN
    
        l_institution := coalesce(i_institution, pk_sysconfig.get_data_access_inst());
        l_prof        := profissional(0, l_institution, l_software);
        l_lang        := pk_sysconfig.get_config('LANGUAGE', l_prof.institution, l_prof.software);
    
        date_processing(l_lang, l_prof, i_dt_ini, i_dt_end, l_dt_ini, l_dt_end);
    
        SELECT t_rec_data_emr_outpatient(id_institution        => t.id_institution,
                                         code_institution      => t.code_institution,
                                         so_flg_state          => t.so_flg_state,
                                         flg_sched             => t.flg_sched,
                                         flg_ehr               => t.flg_ehr,
                                         id_epis_type          => t.id_epis_type,
                                         dis_flg_status        => t.dis_flg_status,
                                         dis_dt_pend_tstz      => t.dis_dt_pend_tstz,
                                         dis_flg_type          => t.dis_flg_type,
                                         flg_contact_type      => t.flg_contact_type,
                                         id_patient            => t.id_patient,
                                         id_episode            => t.id_episode,
                                         patient_complaint     => t.patient_complaint,
                                         code_complaint        => t.code_complaint,
                                         ei_id_professional    => t.ei_id_professional,
                                         ps_id_professional    => t.ps_id_professional,
                                         id_prof_discharge     => t.id_prof_discharge,
                                         dt_discharge          => t.dt_discharge,
                                         dt_examinat           => t.dt_examinat,
                                         dt_visit              => t.dt_visit,
                                         appointment_type      => t.appointment_type,
                                         appointment_type_code => t.appointment_type_code,
                                         discharge_destination => t.discharge_destination,
                                         discharge_status      => t.discharge_status,
                                         clinical_service      => t.clinical_service,
                                         dt_first_obs          => t.dt_first_obs,
                                         dt_last_update_tstz   => t.dt_last_update_tstz)
          BULK COLLECT
          INTO tbl_list
          FROM (pk_data_access_cdoc.get_outpatient_base(l_institution, l_dt_ini, l_dt_end)) t;
    
        RETURN tbl_list;
    
    END get_emr_outpatient;

    FUNCTION get_outpatient
    (
        i_institution IN NUMBER DEFAULT NULL,
        i_dt_ini      IN VARCHAR2 DEFAULT NULL,
        i_dt_end      IN VARCHAR2 DEFAULT NULL
    ) RETURN t_tbl_data_outpatient IS
        tbl_list t_tbl_data_outpatient;
    
        l_software CONSTANT NUMBER := pk_alert_constant.g_soft_outpatient;
    
        l_lang NUMBER;
    
        l_dt_ini      schedule_outp.dt_target_tstz%TYPE;
        l_dt_end      schedule_outp.dt_target_tstz%TYPE;
        l_institution institution.id_institution%TYPE;
        l_prof        profissional;
    
    BEGIN
    
        l_institution := coalesce(i_institution, pk_sysconfig.get_data_access_inst());
        l_prof        := profissional(0, l_institution, l_software);
        l_lang        := pk_sysconfig.get_config('LANGUAGE', l_prof.institution, l_prof.software);
    
        date_processing(l_lang, l_prof, i_dt_ini, i_dt_end, l_dt_ini, l_dt_end);
    
        SELECT t_rec_data_outpatient(id_institution           => t.id_institution,
                                     institution_name         => t.institution_name,
                                     id_episode               => t.id_episode,
                                     complaint                => t.complaint,
                                     professional             => t.professional,
                                     dt_discharge_tstz        => t.dt_discharge,
                                     dt_discharge             => t.dt_discharge_fmt,
                                     dt_examination_tstz      => t.dt_examination,
                                     dt_examination           => t.dt_examination_fmt,
                                     dt_visit_tstz            => t.dt_visit,
                                     dt_visit                 => t.dt_visit_fmt,
                                     appointment_type         => t.appointment_type,
                                     appointment_type_desc    => t.appointment_type_desc,
                                     id_discharge_destination => t.id_discharge_destination,
                                     discharge_destination    => t.discharge_destination,
                                     smoker                   => t.smoker,
                                     discharge_status         => t.discharge_status,
                                     discharge_status_desc    => t.discharge_status_desc,
                                     final_diagnosis          => t.final_diagnosis,
                                     initial_diagnosis        => t.initial_diagnosis,
                                     secondary_diagnosis      => t.secondary_diagnosis,
                                     clinical_service         => t.clinical_service,
                                     treatment_physician_code => t.treatment_physician_code,
                                     treatment_physician      => t.treatment_physician,
                                     discharge_physician_code => t.discharge_physician_code,
                                     discharge_physician      => t.discharge_physician,
                                     patient_file_number      => t.patient_file_number,
                                     dt_last_update_tstz      => t.dt_last_update_tstz,
                                     dt_last_update           => t.dt_last_update)
          BULK COLLECT
          INTO tbl_list
          FROM (SELECT cb.id_institution,
                       pk_translation.get_translation(l_lang, cb.code_institution) institution_name,
                       cb.id_episode,
                       pk_data_access_cdoc.get_complaints(l_lang, cb.id_episode) complaint,
                       pk_prof_utils.get_name_signature(l_lang, l_prof, cb.id_professional) professional,
                       cb.dt_discharge,
                       pk_data_access_cdoc.format_date(profissional(NULL, cb.id_institution, NULL), cb.dt_discharge) dt_discharge_fmt,
                       cb.dt_examination dt_examination,
                       pk_data_access_cdoc.format_date(profissional(NULL, cb.id_institution, NULL), cb.dt_examination) dt_examination_fmt,
                       cb.dt_visit dt_visit,
                       pk_data_access_cdoc.format_date(profissional(NULL, cb.id_institution, NULL), cb.dt_visit) dt_visit_fmt,
                       cb.appointment_type appointment_type,
                       pk_translation.get_translation(i_lang => l_lang, i_code_mess => cb.appointment_type_code) appointment_type_desc,
                       cb.discharge_destination id_discharge_destination,
                       pk_data_access_cdoc.get_discharge_destination_desc(l_lang, cb.discharge_destination) discharge_destination,
                       pk_data_access_cdoc.is_smoker(cb.id_patient) smoker,
                       cb.discharge_status discharge_status,
                       pk_sysdomain.get_domain(i_code_dom => 'DISCHARGE_DETAIL.FLG_PAT_CONDITION',
                                               i_val      => cb.discharge_status,
                                               i_lang     => l_lang) discharge_status_desc,
                       pk_data_access_cdoc.get_diag_final_icd_code(cb.id_episode) final_diagnosis,
                       pk_data_access_cdoc.get_diag_initial_icd_code(cb.id_episode) initial_diagnosis,
                       pk_data_access_cdoc.get_diag_secondary_icd_code(cb.id_episode) secondary_diagnosis,
                       pk_data_access_cdoc.get_clinical_serv_desc(l_lang, cb.clinical_service) clinical_service,
                       cb.ei_id_professional treatment_physician_code,
                       pk_prof_utils.get_name_signature(l_lang, l_prof, cb.ei_id_professional) treatment_physician,
                       cb.id_prof_discharge discharge_physician_code,
                       pk_prof_utils.get_name_signature(l_lang, l_prof, cb.id_prof_discharge) discharge_physician,
                       pk_data_access_cdoc.get_process(cb.id_patient, cb.id_institution) patient_file_number,
                       cb.dt_last_update_tstz,
                       pk_data_access_cdoc.format_date(profissional(NULL, cb.id_institution, NULL),
                                                       cb.dt_last_update_tstz) dt_last_update
                  FROM (SELECT cb1.*,
                               coalesce(cb1.ei_id_professional, cb1.ps_id_professional) id_professional,
                               coalesce(cb1.dt_examinat, cb1.dt_first_obs) dt_examination,
                               row_number() over(PARTITION BY cb1.id_episode ORDER BY cb1.dt_visit DESC) ec_rn
                          FROM (SELECT cbb.id_institution,
                                       cbb.code_institution,
                                       cbb.id_patient,
                                       cbb.id_episode,
                                       cbb.patient_complaint,
                                       cbb.code_complaint,
                                       cbb.ei_id_professional,
                                       cbb.ps_id_professional,
                                       cbb.dt_discharge,
                                       cbb.dt_examinat,
                                       cbb.dt_visit,
                                       cbb.appointment_type,
                                       cbb.appointment_type_code,
                                       cbb.discharge_destination,
                                       cbb.discharge_status,
                                       cbb.clinical_service,
                                       cbb.dt_first_obs,
                                       cbb.id_prof_discharge,
                                       cbb.dt_last_update_tstz
                                  FROM TABLE(pk_data_access_cdoc.get_outpatient_base(i_institution, l_dt_ini, l_dt_end)) cbb) cb1) cb
                 WHERE cb.ec_rn = 1) t;
    
        RETURN tbl_list;
    
    END get_outpatient;

    FUNCTION get_outpatient_base
    (
        i_institution IN NUMBER DEFAULT NULL,
        i_dt_ini      IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_dt_end      IN TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN t_tbl_data_outpatient_base IS
        tbl_return t_tbl_data_outpatient_base;
    
        -- var for cursor 
        l_full_sql CLOB;
        l_curid    INTEGER;
        l_ret      INTEGER;
        l_cursor   pk_types.cursor_type;
    
        -- var for building sql
        xlf VARCHAR2(00010 CHAR) := chr(10);
    
        l_where_opt VARCHAR2(32000);
        l_base_sql  VARCHAR2(32000);
    
        tbl_columns table_varchar := table_varchar();
    
        tbl_from table_varchar := table_varchar();
    
        tbl_where_fix table_varchar := table_varchar(q'[where ei.id_software = 1]',
                                                     q'[AND e.flg_status != 'C']',
                                                     q'[and so.dt_target_tstz between :l_dt_ini and :l_dt_end]');
        tbl_where_opt table_varchar := table_varchar(q'[and v.id_institution = :i_institution]');
    
    BEGIN
    
        tbl_columns := pk_data_access_cdoc_aux.get_cols_outp_base();
    
        tbl_from := pk_data_access_cdoc_aux.get_from_outp_base();
    
        l_base_sql := get_base_sql(i_tbl_col => tbl_columns, i_tbl_from => tbl_from, i_tbl_where => tbl_where_fix);
    
        IF i_institution IS NOT NULL
        THEN
            l_where_opt := l_where_opt || tbl_where_opt(1) || xlf;
        END IF;
    
        l_full_sql := to_clob(l_base_sql || l_where_opt);
    
        -- binding vars and running sql
        l_curid := dbms_sql.open_cursor;
        dbms_sql.parse(l_curid, l_full_sql, dbms_sql.native);
    
        dbms_sql.bind_variable(l_curid, 'l_dt_ini', i_dt_ini);
        dbms_sql.bind_variable(l_curid, 'l_dt_end', i_dt_end);
    
        IF i_institution IS NOT NULL
        THEN
            dbms_sql.bind_variable(l_curid, 'i_institution', i_institution);
        END IF;
    
        l_ret := dbms_sql.execute(l_curid);
    
        l_cursor := dbms_sql.to_refcursor(l_curid);
    
        FETCH l_cursor BULK COLLECT
            INTO tbl_return;
        CLOSE l_cursor;
    
        RETURN tbl_return;
    
    END get_outpatient_base;

    FUNCTION get_clinical_serv_desc
    (
        i_lang             IN NUMBER,
        i_id_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE
    ) RETURN VARCHAR2 IS
        l_return pk_translation.t_desc_translation;
        tbl_name table_varchar;
    BEGIN
    
        SELECT cs.code_clinical_service
          BULK COLLECT
          INTO tbl_name
          FROM dep_clin_serv dcs
          JOIN clinical_service cs
            ON cs.id_clinical_service = dcs.id_clinical_service
         WHERE dcs.id_dep_clin_serv = i_id_dep_clin_serv;
    
        IF tbl_name.count > 0
        THEN
        
            l_return := tbl_name(1);
            l_return := pk_translation.get_translation(i_lang, l_return);
        END IF;
    
        RETURN l_return;
    
    END get_clinical_serv_desc;

    FUNCTION get_mother_epis_doc_deliv_type
    (
        i_episode      IN NUMBER,
        i_pat_pregancy IN NUMBER
    ) RETURN NUMBER IS
        l_return   epis_documentation.id_epis_documentation%TYPE;
        tbl_number table_number;
        l_doc_area_delivery CONSTANT NUMBER := 1047;
        l_status_outdated   CONSTANT VARCHAR2(2 CHAR) := 'O';
    BEGIN
        SELECT ed.id_epis_documentation
          BULK COLLECT
          INTO tbl_number
          FROM epis_documentation ed
          JOIN epis_doc_delivery edd
            ON ed.id_epis_documentation = edd.id_epis_documentation
          JOIN pat_pregnancy pp
            ON pp.id_pat_pregnancy = edd.id_pat_pregnancy
         WHERE ed.id_episode = i_episode
           AND ed.flg_status NOT IN (l_status_outdated)
           AND ed.id_doc_area = l_doc_area_delivery
           AND edd.id_pat_pregnancy = i_pat_pregancy;
    
        IF tbl_number.count > 0
        THEN
            l_return := tbl_number(1);
        END IF;
        RETURN l_return;
    
    END get_mother_epis_doc_deliv_type;

    FUNCTION get_discharge_destination
    (
        i_lang           IN NUMBER,
        i_id_destination IN NUMBER
    ) RETURN VARCHAR2 IS
        tbl_dest table_varchar;
        l_return VARCHAR2(4000);
    BEGIN
    
        SELECT pk_translation.get_translation(i_lang, dd.code_discharge_dest)
          BULK COLLECT
          INTO tbl_dest
          FROM disch_reas_dest d
          JOIN discharge_dest dd
            ON dd.id_discharge_dest = d.id_discharge_dest
         WHERE d.id_disch_reas_dest = i_id_destination;
    
        IF tbl_dest.count > 0
        THEN
            l_return := tbl_dest(1);
        END IF;
    
        RETURN l_return;
    
    END get_discharge_destination;

    FUNCTION is_smoker(i_patient IN NUMBER) RETURN VARCHAR2 IS
        l_count  NUMBER;
        l_return VARCHAR(0010 CHAR);
    BEGIN
    
        SELECT COUNT(*)
          INTO l_count
          FROM pat_problem pp
          JOIN habit h
            ON h.id_habit = pp.id_habit
         WHERE pp.flg_status = 'A'
           AND h.id_content = 'TMP191.7'
           AND pp.id_patient = i_patient;
    
        l_return := 'N';
        IF l_count > 0
        THEN
            l_return := 'Y';
        END IF;
    
        RETURN l_return;
    
    END is_smoker;

    FUNCTION ifnull_tstz
    (
        i_episode IN NUMBER,
        i_date    IN TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN TIMESTAMP
        WITH LOCAL TIME ZONE IS
        l_return TIMESTAMP WITH LOCAL TIME ZONE;
    BEGIN
    
        IF i_episode IS NULL
        THEN
            l_return := i_date;
        END IF;
    
        RETURN l_return;
    
    END ifnull_tstz;

    FUNCTION ifnull_vc2
    (
        i_episode IN NUMBER,
        i_value   IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_return VARCHAR2(4000);
    BEGIN
    
        IF i_episode IS NULL
        THEN
            l_return := i_value;
        END IF;
    
        RETURN l_return;
    
    END ifnull_vc2;

    FUNCTION get_inst_name
    (
        i_lang IN NUMBER,
        i_inst IN NUMBER
    ) RETURN VARCHAR2 IS
        tbl_name table_varchar;
        l_return VARCHAR2(4000);
    BEGIN
    
        SELECT pk_translation.get_translation(i_lang, i.code_institution)
          BULK COLLECT
          INTO tbl_name
          FROM institution i
         WHERE i.id_institution = i_inst;
    
        IF tbl_name.count > 0
        THEN
            l_return := tbl_name(1);
        END IF;
    
        RETURN l_return;
    
    END get_inst_name;

    FUNCTION get_bed_status
    (
        i_lang                     IN language.id_language%TYPE,
        i_prof                     IN profissional,
        i_flg_bed_ocupacity_status IN VARCHAR2,
        i_flg_bed_status           IN VARCHAR2,
        i_mode                     IN VARCHAR2 DEFAULT k_bed_status_desc
    ) RETURN VARCHAR2 IS
        l_return          VARCHAR2(200 CHAR);
    BEGIN
        IF i_mode = k_bed_status_desc
        THEN
            IF i_flg_bed_ocupacity_status = 'O'
            THEN
                CASE i_flg_bed_status
                    WHEN 'R' THEN
                        l_return := 'BMNG_I003';
                    WHEN 'N' THEN
                        l_return := 'BMNG_I002';
                END CASE;
            
            ELSE
                CASE i_flg_bed_status
                    WHEN 'B' THEN
                        l_return := 'BMNG_I004';
                    WHEN 'S' THEN
                        l_return := 'BMNG_I020';
                    ELSE
                        l_return := 'BMNG_I001';
                END CASE;
            
            END IF;
        
            l_return := pk_message.get_message(i_lang, l_return);
        
        ELSE
        
            IF i_flg_bed_ocupacity_status = 'O'
            THEN
            
                CASE i_flg_bed_status
                    WHEN 'R' THEN
                        l_return := 'R';
                    WHEN 'N' THEN
                        l_return := 'O';
                END CASE;
            ELSE
                CASE i_flg_bed_status
                    WHEN 'B' THEN
                        l_return := 'B';
                    WHEN 'S' THEN
                        l_return := 'S';
                    ELSE
                        l_return := 'V';
                END CASE;
            END IF;
        
        END IF;
    
        RETURN l_return;
    END get_bed_status;

    FUNCTION format_date
    (
        i_prof IN profissional,
        i_dt   IN TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN VARCHAR2 IS
        l_return VARCHAR2(4000);
    BEGIN
    
        l_return := pk_date_utils.to_char_insttimezone(i_prof, i_dt, 'DD/MM/YYYY HH24:MI');
    
        RETURN l_return;
    
    END format_date;

    FUNCTION get_epis_doc_component_desc
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_epis_documentation IN epis_documentation.id_epis_documentation%TYPE,
        i_doc_int_name       IN documentation.internal_name%TYPE DEFAULT NULL,
        i_is_bold            IN VARCHAR2 DEFAULT NULL,
        i_has_title          IN VARCHAR2 DEFAULT pk_alert_constant.g_yes
    ) RETURN VARCHAR2 IS
        l_doc_component table_number;
        l_output        VARCHAR2(32767);
    BEGIN
    
        SELECT d.id_doc_component
          BULK COLLECT
          INTO l_doc_component
          FROM documentation d
         WHERE d.internal_name = i_doc_int_name;
    
        IF l_doc_component.count > 0
        THEN
        
            --g_error := 'GET epis_doc_component_desc';
            SELECT decode(i_has_title,
                          'Y',
                          (decode(i_is_bold, 'Y', '<B>', '') || t.desc_component || decode(i_is_bold, 'Y', '</B> ', '')),
                          '') || t.desc_element ||
                   decode(i_has_title, 'Y', decode(instr(t.desc_element, '.', length(t.desc_element)), 0, '.', ''), '')
              INTO l_output
              FROM (SELECT DISTINCT dc.id_doc_component,
                                    ed.id_episode,
                                    pk_translation.get_translation(i_lang, dc.code_doc_component) || ': ' desc_component,
                                    pk_utils.concatenate_list(CURSOR
                                                              (SELECT nvl2(edd1.value,
                                                                           nvl2(pk_touch_option.get_element_description(i_lang,
                                                                                                                        i_prof,
                                                                                                                        de.flg_type,
                                                                                                                        edd1.value,
                                                                                                                        edd1.value_properties,
                                                                                                                        sec1.id_doc_element_crit,
                                                                                                                        de.id_unit_measure_reference,
                                                                                                                        de.id_master_item,
                                                                                                                        sec1.code_element_close),
                                                                                pk_touch_option.get_element_description(i_lang,
                                                                                                                        i_prof,
                                                                                                                        de.flg_type,
                                                                                                                        edd1.value,
                                                                                                                        edd1.value_properties,
                                                                                                                        sec1.id_doc_element_crit,
                                                                                                                        de.id_unit_measure_reference,
                                                                                                                        de.id_master_item,
                                                                                                                        sec1.code_element_close) || ': ',
                                                                                NULL) ||
                                                                           pk_touch_option.get_formatted_value(i_lang,
                                                                                                               i_prof,
                                                                                                               de.flg_type,
                                                                                                               edd1.value,
                                                                                                               edd1.value_properties,
                                                                                                               de.input_mask,
                                                                                                               de.flg_optional_value,
                                                                                                               de.flg_element_domain_type,
                                                                                                               de.code_element_domain,
                                                                                                               edd.dt_creation_tstz),
                                                                           pk_touch_option.get_element_description(i_lang,
                                                                                                                   i_prof,
                                                                                                                   de.flg_type,
                                                                                                                   edd1.value,
                                                                                                                   edd1.value_properties,
                                                                                                                   sec1.id_doc_element_crit,
                                                                                                                   de.id_unit_measure_reference,
                                                                                                                   de.id_master_item,
                                                                                                                   sec1.code_element_close)) ||
                                                                      pk_summary_page.get_epis_doc_qualif(i_lang,
                                                                                                          edd1.id_epis_documentation_det) desc_qualification
                                                                 FROM epis_documentation     ed1,
                                                                      epis_documentation_det edd1,
                                                                      documentation          sd1,
                                                                      doc_element_crit       sec1,
                                                                      doc_element            de
                                                                WHERE ed1.id_epis_documentation =
                                                                      edd1.id_epis_documentation
                                                                  AND edd1.id_epis_documentation =
                                                                      edd.id_epis_documentation
                                                                  AND sd1.id_documentation = edd1.id_documentation
                                                                  AND edd1.id_doc_element_crit = sec1.id_doc_element_crit
                                                                  AND sd1.id_doc_component = dc.id_doc_component
                                                                  AND de.id_doc_element = edd1.id_doc_element
                                                                ORDER BY ed1.dt_creation_tstz DESC, sd1.rank, de.rank),
                                                              ', ') desc_element,
                                    sd.rank
                      FROM epis_documentation ed
                     INNER JOIN epis_documentation_det edd
                        ON edd.id_epis_documentation = ed.id_epis_documentation
                     INNER JOIN documentation sd
                        ON sd.id_documentation = edd.id_documentation
                     INNER JOIN doc_component dc
                        ON dc.id_doc_component = sd.id_doc_component
                     WHERE edd.id_epis_documentation = i_epis_documentation
                       AND dc.id_doc_component = l_doc_component(1)) t;
            RETURN l_output;
        ELSE
            RETURN '';
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            RETURN NULL;
    END get_epis_doc_component_desc;

    FUNCTION get_trans_desc
    (
        i_lang             IN NUMBER,
        i_id_transp_entity IN NUMBER
    ) RETURN VARCHAR2 IS
        l_return VARCHAR2(4000);
        k_code CONSTANT VARCHAR2(0500 CHAR) := 'TRANSP_ENTITY.CODE_TRANSP_ENTITY.';
    BEGIN
    
        l_return := pk_translation.get_translation(i_lang, k_code || to_char(i_id_transp_entity));
    
        RETURN l_return;
    
    END get_trans_desc;

    FUNCTION get_discharge_destination_desc
    (
        i_lang              IN NUMBER,
        i_id_discharge_dest IN NUMBER
    ) RETURN VARCHAR2 IS
        l_return VARCHAR2(4000);
        k_code CONSTANT VARCHAR2(0500 CHAR) := 'DISCHARGE_DEST.CODE_DISCHARGE_DEST.';
    BEGIN
    
        l_return := pk_translation.get_translation(i_lang, k_code || to_char(i_id_discharge_dest));
    
        RETURN l_return;
    
    END get_discharge_destination_desc;

    FUNCTION get_patient_type_desc
    (
        i_lang         IN NUMBER,
        i_patient_type IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_return VARCHAR2(4000);
        k_code CONSTANT VARCHAR2(0500 CHAR) := 'PATIENT_HAJJ_UMRAH';
    BEGIN
    
        l_return := pk_sysdomain.get_domain(i_lang => i_lang, i_code_dom => k_code, i_val => i_patient_type);
    
        RETURN l_return;
    
    END get_patient_type_desc;

    FUNCTION get_complaints
    (
        i_lang    IN language.id_language%TYPE,
        i_episode IN episode.id_episode%TYPE
    ) RETURN CLOB IS
        l_all_chief_complaint table_clob;
        l_chief_complaint_ft  epis_anamnesis.desc_epis_anamnesis%TYPE;
        l_chief_complaints    CLOB;
        l_description         CLOB;
        tbl_complaint         table_varchar;
        tbl_complaint_arabic  table_varchar;
        k_sep CONSTANT VARCHAR2(0010 CHAR) := ',' || chr(32);
    BEGIN
    
        SELECT ea.desc_epis_anamnesis
          BULK COLLECT
          INTO l_all_chief_complaint
          FROM epis_anamnesis ea
         WHERE ea.id_episode = i_episode
           AND ea.flg_type = 'C'
           AND ea.flg_status = 'A'
         ORDER BY ea.dt_epis_anamnesis_tstz DESC;
    
        l_chief_complaint_ft := NULL;
        IF l_all_chief_complaint.count > 0
        THEN
            l_chief_complaint_ft := l_all_chief_complaint(1);
        END IF;
    
        SELECT pk_translation.get_translation(i_lang, c.code_complaint) desc_complaint,
               patient_complaint,
               patient_complaint_arabic
          BULK COLLECT
          INTO l_all_chief_complaint, tbl_complaint, tbl_complaint_arabic
          FROM epis_complaint ec
          JOIN complaint c
            ON c.id_complaint = ec.id_complaint
         WHERE ec.id_episode = i_episode
           AND ec.flg_status = 'A'
         ORDER BY ec.create_time DESC;
    
        IF l_all_chief_complaint.count > 0
        THEN
            --l_chief_complaints := pk_utils.concat_table(l_all_chief_complaint, k_sep);
            l_chief_complaints := NULL;
            <<lup_thru_complaints>>
            FOR i IN 1 .. tbl_complaint.count
            LOOP
            
                IF l_all_chief_complaint(i) IS NOT NULL
                THEN
                    IF l_chief_complaints IS NOT NULL
                    THEN
                        l_chief_complaints := l_chief_complaints || k_sep || l_all_chief_complaint(i);
                    ELSE
                        l_chief_complaints := l_all_chief_complaint(i);
                    END IF;
                END IF;
            
                IF tbl_complaint(i) IS NOT NULL
                THEN
                    IF l_chief_complaints IS NOT NULL
                    THEN
                        l_chief_complaints := l_chief_complaints || k_sep || tbl_complaint(i);
                    ELSE
                        l_chief_complaints := tbl_complaint(i);
                    END IF;
                END IF;
            
                IF tbl_complaint_arabic(i) IS NOT NULL
                THEN
                    IF l_chief_complaints IS NOT NULL
                    THEN
                        l_chief_complaints := l_chief_complaints || k_sep || tbl_complaint_arabic(i);
                    ELSE
                        l_chief_complaints := tbl_complaint_arabic(i);
                    END IF;
                END IF;
            
            END LOOP lup_thru_complaints;
        
        END IF;
    
        IF l_chief_complaint_ft IS NOT NULL
        THEN
            l_description := l_chief_complaint_ft;
        END IF;
    
        IF l_chief_complaints IS NOT NULL
        THEN
            IF l_description IS NOT NULL
            THEN
                l_description := l_description || k_sep || l_chief_complaints;
            ELSE
                l_description := l_chief_complaints;
            END IF;
        END IF;
    
        RETURN l_description;
    
    END get_complaints;

    --************************************************************
    FUNCTION get_id_epis_type(i_id_episode IN NUMBER) RETURN NUMBER IS
        tbl_id   table_number;
        l_return NUMBER;
    BEGIN
    
        IF i_id_episode IS NOT NULL
        THEN
        
            SELECT id_epis_type
              BULK COLLECT
              INTO tbl_id
              FROM episode
             WHERE id_episode = i_id_episode;
        
            IF tbl_id.count > 0
            THEN
                l_return := tbl_id(1);
            END IF;
        
        END IF;
    
        RETURN l_return;
    
    END get_id_epis_type;

    --*******************************************************************
    FUNCTION get_major_incident(i_id_episode IN NUMBER) RETURN VARCHAR2 IS
        tbl_result     table_varchar;
        l_id_epis_type NUMBER;
        l_return       VARCHAR2(4000);
        k_epis_type_edis CONSTANT NUMBER := 2;
    BEGIN
    
        l_id_epis_type := get_id_epis_type(i_id_episode);
    
        IF l_id_epis_type = k_epis_type_edis
        THEN
        
            SELECT ba.bulk_name
              BULK COLLECT
              INTO tbl_result
              FROM epis_bulk_admission eba
              JOIN bulk_admission ba
                ON ba.id_bulk_admission = eba.id_bulk_admission
             WHERE eba.id_episode = i_id_episode;
        
            IF tbl_result.count > 0
            THEN
                l_return := tbl_result(1);
            END IF;
        
        END IF;
    
        RETURN l_return;
    
    END get_major_incident;

    --******************************************************
    FUNCTION get_patient_docid
    (
        i_prof    IN profissional,
        i_patient IN NUMBER
    ) RETURN VARCHAR2 IS
        k_max_value CONSTANT NUMBER := 999999999999999999999999;
        tbl_docid table_varchar;
        l_return  VARCHAR2(4000);
    BEGIN
    
        SELECT xmain.document_identifier_number
          BULK COLLECT
          INTO tbl_docid
          FROM (SELECT xsql.document_identifier_number,
                       decode(xsql.id_institution, i_prof.institution, k_max_value, xsql.id_institution) value_for_sort
                  FROM (SELECT psa.id_patient, psa.id_institution, psa.document_identifier_number
                          FROM pat_soc_attributes psa
                          JOIN institution_group ig_grp
                            ON ig_grp.id_institution = psa.id_institution
                          JOIN institution_group ig_inst
                            ON ig_inst.id_group = ig_grp.id_group
                         WHERE ig_inst.id_institution = i_prof.institution
                           AND ig_inst.flg_relation = 'ADT'
                           AND psa.id_patient = i_patient
                        UNION ALL
                        SELECT psa.id_patient, psa.id_institution, psa.document_identifier_number
                          FROM pat_soc_attributes psa
                         WHERE psa.id_institution = 0
                           AND psa.id_patient = i_patient) xsql) xmain
         ORDER BY value_for_sort DESC;
    
        IF tbl_docid.count > 0
        THEN
            l_return := tbl_docid(1);
        END IF;
    
        RETURN l_return;
    
    END get_patient_docid;

    --**********************************
    FUNCTION get_arrival_method_id
    (
        i_id_arrival_method IN NUMBER,
        i_id_episode        IN NUMBER
    ) RETURN NUMBER IS
        l_return NUMBER := i_id_arrival_method;
        tbl_id   table_number;
        l_bool   BOOLEAN;
    BEGIN
    
        l_bool := (i_id_arrival_method IS NULL) OR (i_id_arrival_method = -1);
        IF l_bool
        THEN
        
            SELECT t.id_transp_entity
              BULK COLLECT
              INTO tbl_id
              FROM transportation t
             WHERE t.id_episode = i_id_episode
             ORDER BY t.dt_transportation_tstz DESC;
        
            IF tbl_id.count > 0
            THEN
                IF tbl_id(1) != -1
                THEN
                    l_return := tbl_id(1);
                END IF;
            
            END IF;
        
        END IF;
    
        RETURN l_return;
    
    END get_arrival_method_id;

    --****************************************
    FUNCTION get_emergency_base
    (
        i_institution IN NUMBER DEFAULT NULL,
        i_dt_ini      IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_dt_end      IN TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN t_tbl_data_emergency_base IS
        tbl_return t_tbl_data_emergency_base;
    
        -- var for cursor 
        l_full_sql CLOB;
        l_curid    INTEGER;
        l_ret      INTEGER;
        l_cursor   pk_types.cursor_type;
    
        -- var for building sql
        xlf         VARCHAR2(00010 CHAR) := chr(10);
        l_where_opt VARCHAR2(32000);
        l_base_sql  VARCHAR2(32000);
    
        tbl_columns table_varchar := table_varchar();
    
        tbl_from table_varchar := table_varchar();
    
        tbl_where_fix table_varchar := table_varchar(q'[where 1 = 1]', q'[and e.rn = 1]');
    
        tbl_where_opt table_varchar := table_varchar(q'[and v.id_institution = :i_institution]');
    
    BEGIN
    
        tbl_columns := pk_data_access_cdoc_aux.get_cols_edis_base();
        tbl_from    := pk_data_access_cdoc_aux.get_from_edis_base();
    
        l_base_sql := get_base_sql(i_tbl_col => tbl_columns, i_tbl_from => tbl_from, i_tbl_where => tbl_where_fix);
    
        IF i_institution IS NOT NULL
        THEN
            l_where_opt := l_where_opt || tbl_where_opt(1) || xlf;
        END IF;
    
        l_full_sql := to_clob(l_base_sql || l_where_opt);
    
        -- binding vars and running sql
        l_curid := dbms_sql.open_cursor;
        dbms_sql.parse(l_curid, l_full_sql, dbms_sql.native);
    
        dbms_sql.bind_variable(l_curid, 'l_dt_ini', i_dt_ini);
        dbms_sql.bind_variable(l_curid, 'l_dt_end', i_dt_end);
    
        IF i_institution IS NOT NULL
        THEN
            dbms_sql.bind_variable(l_curid, 'i_institution', i_institution);
        END IF;
    
        l_ret := dbms_sql.execute(l_curid);
    
        l_cursor := dbms_sql.to_refcursor(l_curid);
    
        FETCH l_cursor BULK COLLECT
            INTO tbl_return;
        CLOSE l_cursor;
    
        RETURN tbl_return;
    
    END get_emergency_base;

    -- ***************************************************************
    FUNCTION get_emergency
    (
        i_institution IN NUMBER DEFAULT NULL,
        i_dt_ini      IN VARCHAR2 DEFAULT NULL,
        i_dt_end      IN VARCHAR2 DEFAULT NULL
    ) RETURN t_tbl_data_emergency IS
        tbl_list t_tbl_data_emergency;
        l_lang   NUMBER;
    
        l_dt_ini death_registry.dt_death%TYPE;
        l_dt_end death_registry.dt_death%TYPE;
        l_prof   profissional;
        k_msg    VARCHAR2(4000);
    
    BEGIN
    
        l_prof := get_lprof(i_institution);
        l_lang := pk_sysconfig.get_config('LANGUAGE', l_prof.institution, l_prof.software);
        k_msg  := pk_message.get_message(l_lang, 'TRIAGE_T039');
    
        date_processing(l_lang, l_prof, i_dt_ini, i_dt_end, l_dt_ini, l_dt_end);
    
        SELECT t_rec_data_emergency(id_institution           => xmain.id_institution,
                                    institution              => xmain.institution,
                                    id_episode               => xmain.id_episode,
                                    complaint                => xmain.complaint,
                                    dt_discharge_tstz        => xmain.dt_discharge,
                                    dt_discharge             => xmain.dt_discharge_fmt,
                                    dt_examination_tstz      => xmain.dt_examination,
                                    dt_examination           => xmain.dt_examination_fmt,
                                    dt_triage_tstz           => xmain.dt_triage,
                                    dt_triage                => xmain.dt_triage_fmt,
                                    dt_visit_tstz            => xmain.dt_visit,
                                    dt_visit                 => xmain.dt_visit_fmt,
                                    arrival_method_code      => xmain.id_arrival_method,
                                    arrival_method           => pk_data_access_cdoc.get_trans_desc(l_lang,
                                                                                                   xmain.id_arrival_method),
                                    id_discharge_destination => xmain.id_discharge_destination,
                                    discharge_destination    => xmain.discharge_destination,
                                    discharge_status_code    => xmain.discharge_status_code,
                                    discharge_status         => xmain.discharge_status,
                                    smoker                   => xmain.smoker,
                                    triage_level             => xmain.triage_level,
                                    arrival_status           => xmain.arrival_status,
                                    initial_diagnosis        => xmain.initial_diagnosis,
                                    final_diagnosis          => xmain.final_diagnosis,
                                    secondary_diagnosis      => xmain.secondary_diagnosis,
                                    --is_unknown               => xmain.is_unknown,
                                    pain_level_scale_first => xmain.pain_level_scale_first,
                                    pain_level_scale_last  => xmain.pain_level_scale_last,
                                    --patient_type             => xmain.patient_type,
                                    --patient_type_desc        => xmain.patient_type_desc,
                                    treatment_physician_code => xmain.treatment_physician_code,
                                    treatment_physician      => xmain.treatment_physician,
                                    discharge_physician_code => xmain.discharge_physician_code,
                                    discharge_physician      => xmain.discharge_physician,
                                    patient_file_number      => xmain.patient_file_number,
                                    major_incident           => xmain.major_incident,
                                    dt_last_update_tstz      => xmain.dt_last_update_tstz,
                                    dt_last_update           => xmain.dt_last_update)
          BULK COLLECT
          INTO tbl_list
          FROM (SELECT x01.id_institution,
                       (SELECT pk_data_access_cdoc.get_inst_name(l_lang, x01.id_institution)
                          FROM dual) institution,
                       x01.id_episode,
                       pk_data_access_cdoc.get_complaints(l_lang, x01.id_episode) complaint,
                       x01.dt_discharge dt_discharge,
                       pk_data_access_cdoc.format_date(x01.l_prof, x01.dt_discharge) dt_discharge_fmt,
                       x01.dt_examination dt_examination,
                       pk_data_access_cdoc.format_date(x01.l_prof, x01.dt_examination) dt_examination_fmt,
                       x01.dt_triage dt_triage,
                       pk_data_access_cdoc.format_date(x01.l_prof, x01.dt_triage) dt_triage_fmt,
                       x01.dt_visit,
                       pk_data_access_cdoc.format_date(x01.l_prof, x01.dt_visit) dt_visit_fmt,
                       row_number() over(PARTITION BY x01.id_episode ORDER BY x01.dt_triage DESC) rn,
                       pk_data_access_cdoc.get_arrival_method_id(x01.arrival_method, x01.id_episode) id_arrival_method,
                       NULL arrival_method,
                       x01.discharge_destination id_discharge_destination,
                       pk_data_access_cdoc.get_discharge_destination_desc(l_lang, x01.discharge_destination) discharge_destination,
                       x01.discharge_status discharge_status_code,
                       (SELECT pk_sysdomain.get_domain(i_code_dom => 'DISCHARGE_DETAIL.FLG_PAT_CONDITION',
                                                       i_val      => x01.discharge_status,
                                                       i_lang     => l_lang)
                          FROM dual) discharge_status,
                       pk_data_access_cdoc.is_smoker(x01.id_patient) smoker,
                       pk_data_access_cdoc.get_triage_level(i_lang              => l_lang,
                                                            i_prof              => x01.l_prof,
                                                            i_id_epis_triage    => x01.id_epis_triage,
                                                            i_code_triage_color => x01.code_triage_color,
                                                            i_flg_type          => x01.flg_type,
                                                            i_code_accuity      => x01.code_accuity,
                                                            i_id_triage_type    => x01.id_triage_type,
                                                            i_id_triage_color   => x01.id_triage_color,
                                                            i_msg               => k_msg) triage_level,
                       pk_data_access_cdoc.get_triage_level(i_lang              => l_lang,
                                                            i_prof              => x01.l_prof,
                                                            i_id_epis_triage    => x01.id_epis_triage_first,
                                                            i_code_triage_color => x01.code_triage_color_first,
                                                            i_flg_type          => x01.flg_type_first,
                                                            i_code_accuity      => x01.code_accuity_first,
                                                            i_id_triage_type    => x01.id_triage_type_first,
                                                            i_id_triage_color   => x01.id_triage_color_first,
                                                            i_msg               => k_msg) arrival_status,
                       pk_data_access_cdoc.get_diag_initial_icd_code(x01.id_episode) initial_diagnosis,
                       pk_data_access_cdoc.get_diag_final_icd_code(x01.id_episode) final_diagnosis,
                       pk_data_access_cdoc.get_diag_secondary_icd_code(x01.id_episode) secondary_diagnosis,
                       --pk_data_access_cdoc.is_unknown(x01.l_prof, x01.id_patient) is_unknown,
                       pk_data_access_cdoc.get_vs_pain(x01.id_episode, k_vs_pain_order_first) pain_level_scale_first,
                       pk_data_access_cdoc.get_vs_pain(x01.id_episode, k_vs_pain_order_last) pain_level_scale_last,
                       pk_data_access_cdoc.get_treatment_physicians_id(l_lang, x01.l_prof, x01.id_episode) treatment_physician_code,
                       pk_data_access_cdoc.get_treatment_physicians(l_lang, x01.l_prof, x01.id_episode) treatment_physician,
                       x01.id_prof_discharge discharge_physician_code,
                       pk_prof_utils.get_name_signature(l_lang, x01.l_prof, x01.id_prof_discharge) discharge_physician,
                       pk_data_access_cdoc.get_process(x01.id_patient, x01.id_institution) patient_file_number,
                       pk_data_access_cdoc.get_major_incident(x01.id_episode) major_incident,
                       x01.dt_last_update_tstz,
                       pk_data_access_cdoc.format_date(x01.l_prof, x01.dt_last_update_tstz) dt_last_update
                  FROM (SELECT xsub2.*, profissional(0, xsub2.id_institution, xsub2.id_software) l_prof
                        --,row_number() over(PARTITION BY xsub2.id_episode ORDER BY xsub2.dt_complaint DESC) ec_rn
                          FROM (SELECT xtbl2.id_institution,
                                       xtbl2.id_patient,
                                       xtbl2.id_episode,
                                       xtbl2.id_next_episode,
                                       xtbl2.flg_status,
                                       pk_data_access_cdoc.ifnull_tstz(xtbl2.id_next_episode, xtbl2.dt_discharge) dt_discharge,
                                       xtbl2.dt_examination,
                                       xtbl2.dt_triage,
                                       xtbl2.dt_visit,
                                       xtbl2.arrival_method,
                                       pk_data_access_cdoc.ifnull_vc2(xtbl2.id_next_episode, xtbl2.discharge_destination) discharge_destination,
                                       pk_data_access_cdoc.ifnull_vc2(xtbl2.id_next_episode, xtbl2.discharge_status) discharge_status,
                                       pk_data_access_cdoc.ifnull_vc2(xtbl2.id_next_episode, xtbl2.id_prof_discharge) id_prof_discharge,
                                       xtbl2.id_habit,
                                       xtbl2.id_epis_triage,
                                       xtbl2.code_triage_color,
                                       xtbl2.flg_type,
                                       xtbl2.code_accuity,
                                       xtbl2.id_triage_type,
                                       xtbl2.id_triage_color,
                                       xtbl2.id_epis_triage_first,
                                       xtbl2.code_triage_color_first,
                                       xtbl2.flg_type_first,
                                       xtbl2.code_accuity_first,
                                       xtbl2.id_triage_type_first,
                                       xtbl2.id_triage_color_first,
                                       xtbl2.id_software,
                                       xtbl2.patient_complaint,
                                       xtbl2.code_complaint,
                                       xtbl2.dt_last_update_tstz,
                                       xtbl2.dt_complaint
                                  FROM TABLE(pk_data_access_cdoc.get_emergency_base(i_institution, l_dt_ini, l_dt_end)) xtbl2) xsub2) x01
                 WHERE 1 = 1
                -- and x01.ec_rn = 1
                ) xmain;
    
        RETURN tbl_list;
    
    END get_emergency;

    --****************************************
    FUNCTION get_inpatient_base
    (
        i_institution IN NUMBER DEFAULT NULL,
        i_dt_ini      IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_dt_end      IN TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN t_tbl_data_inpatient_base IS
        tbl_return t_tbl_data_inpatient_base;
    
        -- var for cursor 
        l_full_sql CLOB;
        l_curid    INTEGER;
        l_ret      INTEGER;
        l_cursor   pk_types.cursor_type;
    
        -- var for building sql
        xlf         VARCHAR2(00010 CHAR) := chr(10);
        l_where_opt VARCHAR2(32000);
        l_base_sql  VARCHAR2(32000);
        tbl_columns table_varchar := table_varchar();
        tbl_from    table_varchar := table_varchar();
    
        tbl_where_fix table_varchar := table_varchar();
        tbl_where_opt table_varchar := table_varchar(q'[where xsql.id_institution = :i_institution]');
    
    BEGIN
    
        tbl_columns := pk_data_access_cdoc_aux.get_cols_inp_base();
        tbl_from    := pk_data_access_cdoc_aux.get_from_inp_base();
    
        l_base_sql := get_base_sql(i_tbl_col => tbl_columns, i_tbl_from => tbl_from, i_tbl_where => tbl_where_fix);
    
        IF i_institution IS NOT NULL
        THEN
        
            FOR i IN 1 .. tbl_where_opt.count
            LOOP
                l_where_opt := l_where_opt || tbl_where_opt(i) || xlf;
            END LOOP;
        
        END IF;
    
        l_full_sql := to_clob(l_base_sql || l_where_opt);
    
        -- binding vars and running sql
        l_curid := dbms_sql.open_cursor;
        dbms_sql.parse(l_curid, l_full_sql, dbms_sql.native);
    
        dbms_sql.bind_variable(l_curid, 'l_dt_ini', i_dt_ini);
        dbms_sql.bind_variable(l_curid, 'l_dt_end', i_dt_end);
    
        IF i_institution IS NOT NULL
        THEN
            dbms_sql.bind_variable(l_curid, 'i_institution', i_institution);
        END IF;
    
        l_ret := dbms_sql.execute(l_curid);
    
        l_cursor := dbms_sql.to_refcursor(l_curid);
    
        FETCH l_cursor BULK COLLECT
            INTO tbl_return;
        CLOSE l_cursor;
    
        RETURN tbl_return;
    
    END get_inpatient_base;

    FUNCTION get_inpatient
    (
        i_institution IN NUMBER DEFAULT NULL,
        i_dt_ini      IN VARCHAR2 DEFAULT NULL,
        i_dt_end      IN VARCHAR2 DEFAULT NULL
    ) RETURN t_tbl_data_inpatient IS
        tbl_list t_tbl_data_inpatient;
        l_lang   NUMBER;
    
        l_dt_ini death_registry.dt_death%TYPE;
        l_dt_end death_registry.dt_death%TYPE;
        l_prof   profissional;
        --k_msg    VARCHAR2(4000);
    
    BEGIN
    
        l_prof := get_lprof(i_institution);
        l_lang := pk_sysconfig.get_config('LANGUAGE', l_prof.institution, l_prof.software);
        --k_msg  := pk_message.get_message(l_lang, 'TRIAGE_T039');
    
        date_processing(l_lang, l_prof, i_dt_ini, i_dt_end, l_dt_ini, l_dt_end);
    
        SELECT t_rec_data_inpatient(id_institution           => xmain.id_institution,
                                    institution              => xmain.institution,
                                    id_episode               => xmain.id_episode,
                                    complaint                => xmain.complaint,
                                    treatment_physician_code => xmain.treatment_physician_code,
                                    treatment_physician      => xmain.treatment_physician,
                                    discharge_physician_code => xmain.discharge_physician_code,
                                    discharge_physician      => xmain.discharge_physician,
                                    dt_admission_tstz        => xmain.dt_admission,
                                    dt_admission             => xmain.dt_admission_fmt,
                                    dt_admission_req_tstz    => xmain.dt_admission_req,
                                    dt_admission_req         => xmain.dt_admission_req_fmt,
                                    dt_discharge_tstz        => xmain.dt_discharge,
                                    dt_discharge             => xmain.dt_discharge_fmt,
                                    id_discharge_destination => xmain.id_discharge_destination,
                                    discharge_destination    => xmain.discharge_destination,
                                    smoker                   => xmain.smoker,
                                    origin                   => xmain.origin,
                                    admission_ward_code      => xmain.admission_ward_code,
                                    admission_ward           => xmain.admission_ward,
                                    final_diagnosis          => xmain.final_diagnosis,
                                    initial_diagnosis        => xmain.initial_diagnosis,
                                    secondary_diagnosis      => xmain.secondary_diagnosis,
                                    patient_file_number      => xmain.patient_file_number,
                                    room_code                => xmain.room_code,
                                    room                     => xmain.room,
                                    bed_code                 => xmain.bed_code,
                                    bed                      => xmain.bed,
                                    major_incident           => xmain.major_incident,
                                    dt_last_update_tstz      => xmain.dt_last_update_tstz,
                                    dt_last_update           => xmain.dt_last_update,
                                    flg_ehr                  => xmain.flg_ehr)
          BULK COLLECT
          INTO tbl_list
          FROM (SELECT x01.id_institution,
                       (SELECT pk_data_access_cdoc.get_inst_name(l_lang, x01.id_institution)
                          FROM dual) institution,
                       x01.id_episode,
                       pk_data_access_cdoc.admission_reason(x01.id_episode) complaint,
                       pk_data_access_cdoc.get_treatment_physicians_id(l_lang, x01.l_prof, x01.id_episode) treatment_physician_code,
                       pk_data_access_cdoc.get_treatment_physicians(l_lang, x01.l_prof, x01.id_episode) treatment_physician,
                       x01.id_prof_discharge discharge_physician_code,
                       pk_prof_utils.get_name_signature(l_lang, x01.l_prof, x01.id_prof_discharge) discharge_physician,
                       x01.dt_epis_dt_begin_tstz dt_admission,
                       pk_data_access_cdoc.format_date(x01.l_prof, x01.dt_epis_dt_begin_tstz) dt_admission_fmt,
                       x01.dt_vis_dt_begin_tstz dt_admission_req,
                       pk_data_access_cdoc.format_date(x01.l_prof, x01.dt_vis_dt_begin_tstz) dt_admission_req_fmt,
                       x01.dt_discharge dt_discharge,
                       pk_data_access_cdoc.format_date(x01.l_prof, x01.dt_discharge) dt_discharge_fmt,
                       x01.id_discharge_destination id_discharge_destination,
                       pk_data_access_cdoc.get_discharge_destination(l_lang, x01.id_discharge_destination) discharge_destination,
                       pk_data_access_cdoc.is_smoker(x01.id_patient) smoker,
                       pk_data_access_cdoc.get_origin(l_lang, x01.id_episode) origin,
                       pk_data_access_cdoc.get_department(l_lang, x01.id_first_dep_clin_serv, 'CODE') admission_ward_code,
                       pk_data_access_cdoc.get_admission_ward(l_lang, x01.id_first_dep_clin_serv) admission_ward,
                       pk_data_access_cdoc.get_diag_final_icd_code(x01.id_episode) final_diagnosis,
                       pk_data_access_cdoc.get_diag_initial_icd_code(x01.id_episode) initial_diagnosis,
                       pk_data_access_cdoc.get_diag_secondary_icd_code(x01.id_episode) secondary_diagnosis,
                       pk_data_access_cdoc.get_process(x01.id_patient, x01.id_institution) patient_file_number,
                       x01.id_room room_code,
                       pk_translation.get_translation(l_lang, x01.code_room) room,
                       x01.id_bed bed_code,
                       pk_translation.get_translation(l_lang, x01.code_bed) bed,
                       pk_data_access_cdoc.get_major_incident(i_id_episode => x01.id_prev_episode) major_incident,
                       x01.dt_last_update_tstz,
                       pk_data_access_cdoc.format_date(x01.l_prof, x01.dt_last_update_tstz) dt_last_update,
                       x01.flg_ehr
                  FROM (SELECT xsub2.*, profissional(0, xsub2.id_institution, xsub2.id_software) l_prof
                          FROM (SELECT xtbl2.id_institution,
                                       xtbl2.id_episode,
                                       xtbl2.id_prev_episode,
                                       xtbl2.id_software,
                                       xtbl2.id_first_dep_clin_serv,
                                       xtbl2.id_prof_discharge,
                                       xtbl2.dt_epis_dt_begin_tstz,
                                       xtbl2.dt_vis_dt_begin_tstz,
                                       xtbl2.id_discharge_destination,
                                       xtbl2.dt_discharge,
                                       xtbl2.id_habit,
                                       xtbl2.id_patient,
                                       xtbl2.code_room_now            code_room,
                                       xtbl2.id_room_now              id_room,
                                       xtbl2.id_bed_alloc             id_bed,
                                       xtbl2.code_bed_alloc           code_bed,
                                       xtbl2.dt_last_update_tstz,
                                       xtbl2.flg_ehr
                                  FROM TABLE(pk_data_access_cdoc.get_inpatient_base(i_institution, l_dt_ini, l_dt_end)) xtbl2) xsub2) x01) xmain;
    
        RETURN tbl_list;
    
    END get_inpatient;

    --**********************************************
    FUNCTION get_birth_type
    (
        i_epis_documentation IN epis_documentation.id_epis_documentation%TYPE,
        i_doc_int_name       IN documentation.internal_name%TYPE DEFAULT NULL
    ) RETURN VARCHAR2 IS
        l_doc_component table_number;
        l_birth_type    table_varchar := table_varchar();
        l_return        VARCHAR2(4000);
    BEGIN
    
        SELECT d.id_doc_component
          BULK COLLECT
          INTO l_doc_component
          FROM documentation d
         WHERE d.internal_name = i_doc_int_name;
    
        IF l_doc_component.count > 0
        THEN
        
            --g_error := 'GET epis_doc_component_desc';
            SELECT de.internal_name
              BULK COLLECT
              INTO l_birth_type
              FROM epis_documentation ed
              JOIN epis_documentation_det edd
                ON edd.id_epis_documentation = ed.id_epis_documentation
              JOIN documentation sd
                ON sd.id_documentation = edd.id_documentation
              JOIN doc_component dc
                ON dc.id_doc_component = sd.id_doc_component
              JOIN doc_element de
                ON edd.id_doc_element = de.id_doc_element
             WHERE edd.id_epis_documentation = i_epis_documentation
               AND dc.id_doc_component = l_doc_component(1);
        
        END IF;
    
        l_return := pk_data_access.array_to_var(l_birth_type);
        RETURN l_return;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            RETURN l_return;
    END get_birth_type;

    --*******************************************
    FUNCTION set_mrn_null_on_unoccupied
    (
        i_code IN VARCHAR2,
        i_mrn  IN VARCHAR2
    ) RETURN VARCHAR2 IS
        k_bed_status_unoccupied CONSTANT VARCHAR2(0050 CHAR) := 'V';
    BEGIN
    
        IF i_code = k_bed_status_unoccupied
        THEN
            RETURN NULL;
        ELSE
            RETURN i_mrn;
        END IF;
    
    END set_mrn_null_on_unoccupied;

    -- ***************************************************************
    FUNCTION get_emr_emergency
    (
        i_institution IN NUMBER DEFAULT NULL,
        i_dt_ini      IN VARCHAR2 DEFAULT NULL,
        i_dt_end      IN VARCHAR2 DEFAULT NULL
    ) RETURN t_tbl_data_emr_emergency IS
    
        tbl_list t_tbl_data_emr_emergency;
        l_lang   NUMBER;
        l_dt_ini death_registry.dt_death%TYPE;
        l_dt_end death_registry.dt_death%TYPE;
        l_prof   profissional;
        --k_msg    VARCHAR2(4000);
        l_software CONSTANT NUMBER := pk_alert_constant.g_soft_edis;
        l_institution NUMBER;
    
    BEGIN
    
        l_institution := coalesce(i_institution, pk_sysconfig.get_data_access_inst());
        l_prof        := profissional(0, l_institution, l_software);
        l_lang := pk_sysconfig.get_config('LANGUAGE', l_prof.institution, l_prof.software);
    
        --k_msg := pk_message.get_message(l_lang, 'TRIAGE_T039');
    
        date_processing(l_lang, l_prof, i_dt_ini, i_dt_end, l_dt_ini, l_dt_end);
    
        SELECT t_rec_data_emr_emergency(id_institution          => tt.id_institution,
                                        id_patient              => tt.id_patient,
                                        id_episode              => tt.id_episode,
                                        id_next_episode         => tt.id_next_episode,
                                        flg_status              => tt.flg_status,
                                        dt_discharge            => tt.dt_discharge,
                                        dis_flg_status          => tt.dis_flg_status,
                                        dis_flg_type            => tt.dis_flg_type,
                                        dis_dt_pend_tstz        => tt.dis_dt_pend_tstz,
                                        dt_examination          => tt.dt_examination,
                                        dt_triage               => tt.dt_triage,
                                        dt_visit                => tt.dt_visit,
                                        arrival_method          => tt.arrival_method,
                                        discharge_destination   => tt.discharge_destination,
                                        discharge_status        => tt.discharge_status,
                                        id_prof_discharge       => tt.id_prof_discharge,
                                        id_habit                => tt.id_habit,
                                        id_epis_triage          => tt.id_epis_triage,
                                        code_triage_color       => tt.code_triage_color,
                                        flg_type                => tt.flg_type,
                                        code_accuity            => tt.code_accuity,
                                        id_triage_type          => tt.id_triage_type,
                                        id_triage_color         => tt.id_triage_color,
                                        id_epis_triage_first    => tt.id_epis_triage_first,
                                        code_triage_color_first => tt.code_triage_color_first,
                                        flg_type_first          => tt.flg_type_first,
                                        code_accuity_first      => tt.code_accuity_first,
                                        id_triage_type_first    => tt.id_triage_type_first,
                                        id_triage_color_first   => tt.id_triage_color_first,
                                        id_software             => tt.id_software,
                                        patient_complaint       => tt.patient_complaint,
                                        code_complaint          => tt.code_complaint,
                                        dt_complaint            => tt.dt_complaint,
                                        dt_last_update_tstz     => tt.dt_last_update_tstz)
          BULK COLLECT
          INTO tbl_list
          FROM TABLE(pk_data_access_cdoc.get_emergency_base(l_institution, l_dt_ini, l_dt_end)) tt;
    
        RETURN tbl_list;
    
    END get_emr_emergency;

    --******************************************************************
    FUNCTION get_id_clinical_service(i_dcs IN NUMBER) RETURN NUMBER IS
        tbl_id   table_number;
        l_return NUMBER;
    BEGIN
    
        SELECT dcs.id_clinical_service
          BULK COLLECT
          INTO tbl_id
          FROM dep_clin_serv dcs
         WHERE dcs.id_dep_clin_serv = i_dcs;
    
        IF tbl_id.count > 0
        THEN
            l_return := tbl_id(1);
        END IF;
    
        RETURN l_return;
    
    END get_id_clinical_service;

    --******************************************************************
    FUNCTION get_img_state
    (
        i_lang      IN NUMBER,
        i_prof      IN profissional,
        i_dcs       IN NUMBER,
        i_flg_ehr   IN VARCHAR2,
        i_flg_state IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_return              VARCHAR2(4000);
        l_id_clinical_service NUMBER;
        l_real_state          VARCHAR2(4000);
    BEGIN
    
        l_id_clinical_service := pk_data_access_cdoc.get_id_clinical_service(i_dcs);
        l_real_state          := pk_grid.get_schedule_real_state(i_flg_state, i_flg_ehr);
    
        l_return := pk_grid.get_pre_nurse_appointment(i_lang, i_prof, l_id_clinical_service, i_flg_ehr, l_real_state);
    
        l_return := pk_sysdomain.get_domain('SCHEDULE_OUTP.FLG_STATE', l_return, i_lang);
    
        RETURN l_return;
    
    END get_img_state;

    --********************************************************
    FUNCTION get_outp_department
    (
        i_lang IN NUMBER,
        i_dcs  IN NUMBER
    ) RETURN VARCHAR2 IS
        tbl_desc table_varchar;
        l_return VARCHAR2(4000);
    BEGIN
    
        SELECT pk_translation.get_translation(i_lang, d.code_department) desc_department
          BULK COLLECT
          INTO tbl_desc
          FROM department d
          JOIN dep_clin_serv dcs
            ON dcs.id_department = d.id_department
         WHERE dcs.id_dep_clin_serv = i_dcs;
    
        IF tbl_desc.count > 0
        THEN
            l_return := tbl_desc(1);
        END IF;
    
        RETURN l_return;
    
    END get_outp_department;

    -- ************************************************
    FUNCTION get_emr_outpatient_plus
    (
        i_institution IN NUMBER DEFAULT NULL,
        i_dt_ini      IN VARCHAR2 DEFAULT NULL,
        i_dt_end      IN VARCHAR2 DEFAULT NULL
    ) RETURN t_tbl_data_emr_outpatient_plus IS
        tbl_list t_tbl_data_emr_outpatient_plus;
    
        l_software CONSTANT NUMBER := pk_alert_constant.g_soft_outpatient;
    
        l_lang NUMBER;
    
        l_dt_ini      schedule_outp.dt_target_tstz%TYPE;
        l_dt_end      schedule_outp.dt_target_tstz%TYPE;
        l_institution institution.id_institution%TYPE;
        l_prof        profissional;
    
    BEGIN
    
        l_institution := coalesce(i_institution, pk_sysconfig.get_data_access_inst());
        l_prof        := profissional(0, l_institution, l_software);
        l_lang        := pk_sysconfig.get_config('LANGUAGE', l_prof.institution, l_prof.software);
    
        date_processing(l_lang, l_prof, i_dt_ini, i_dt_end, l_dt_ini, l_dt_end);
    
        SELECT t_rec_data_emr_outpatient_plus(id_institution        => t.id_institution,
                                              code_institution      => t.code_institution,
                                              desc_institution      => t.desc_institution,
                                              so_flg_state          => t.so_flg_state,
                                              desc_so_flg_state     => t.desc_so_flg_state,
                                              img_state             => t.img_state,
                                              flg_sched             => t.flg_sched,
                                              desc_flg_sched        => t.desc_flg_sched,
                                              flg_ehr               => t.flg_ehr,
                                              desc_flg_ehr          => t.desc_flg_ehr,
                                              id_epis_type          => t.id_epis_type,
                                              dis_flg_status        => t.dis_flg_status,
                                              desc_dis_flg_status   => t.desc_dis_flg_status,
                                              dis_dt_pend_tstz      => t.dis_dt_pend_tstz,
                                              dis_flg_type          => t.dis_flg_type,
                                              desc_dis_flg_type     => t.desc_dis_flg_type,
                                              flg_contact_type      => t.flg_contact_type,
                                              desc_contact_type     => t.desc_contact_type,
                                              id_patient            => t.id_patient,
                                              id_episode            => t.id_episode,
                                              patient_complaint     => t.patient_complaint,
                                              code_complaint        => t.code_complaint,
                                              desc_complaint        => t.desc_complaint,
                                              ei_id_professional    => t.ei_id_professional,
                                              ps_id_professional    => t.ps_id_professional,
                                              id_prof_discharge     => t.id_prof_discharge,
                                              dt_discharge          => t.dt_discharge,
                                              dt_examinat           => t.dt_examinat,
                                              dt_visit              => t.dt_visit,
                                              appointment_type      => t.appointment_type,
                                              appointment_type_code => t.appointment_type_code,
                                              desc_appointment_type => t.desc_appointment_type,
                                              discharge_destination => t.discharge_destination,
                                              discharge_status      => t.discharge_status,
                                              clinical_service      => t.clinical_service,
                                              desc_contact          => t.desc_contact,
                                              dt_first_obs          => t.dt_first_obs,
                                              dt_last_update_tstz   => t.dt_last_update_tstz)
          BULK COLLECT
          INTO tbl_list
          FROM (SELECT tt.id_institution,
                       tt.code_institution,
                       (SELECT pk_translation.get_translation(l_lang, tt.code_institution)
                          FROM dual) desc_institution,
                       tt.so_flg_state,
                       (SELECT pk_sysdomain.get_domain('SCHEDULE_OUTP.FLG_STATE', tt.so_flg_state, l_lang)
                          FROM dual) desc_so_flg_state,
                       (SELECT pk_data_access_cdoc.get_img_state(i_lang      => l_lang,
                                                                 i_prof      => l_prof,
                                                                 i_dcs       => tt.clinical_service,
                                                                 i_flg_ehr   => tt.flg_ehr,
                                                                 i_flg_state => tt.so_flg_state)
                          FROM dual) img_state,
                       tt.flg_sched,
                       (SELECT pk_sysdomain.get_domain('SCHEDULE_OUTP.FLG_SCHED', tt.flg_sched, l_lang)
                          FROM dual) desc_flg_sched,
                       tt.flg_ehr,
                       (SELECT pk_sysdomain.get_domain('EPISODE.FLG_EHR', tt.flg_ehr, l_lang)
                          FROM dual) desc_flg_ehr,
                       tt.id_epis_type,
                       tt.dis_flg_status,
                       (SELECT pk_sysdomain.get_domain('DISCHARGE.FLG_STATUS', tt.dis_flg_status, l_lang)
                          FROM dual) desc_dis_flg_status,
                       tt.dis_dt_pend_tstz,
                       tt.dis_flg_type,
                       (SELECT pk_sysdomain.get_domain('DISCHARGE.FLG_TYPE', tt.dis_flg_type, l_lang)
                          FROM dual) desc_dis_flg_type,
                       tt.flg_contact_type,
                       (SELECT pk_sysdomain.get_domain('SCH_GROUP.FLG_CONTACT_TYPE', tt.flg_contact_type, l_lang)
                          FROM dual) desc_contact_type,
                       tt.id_patient,
                       tt.id_episode,
                       tt.patient_complaint,
                       tt.code_complaint,
                       (SELECT pk_translation.get_translation(l_lang, tt.code_complaint)
                          FROM dual) desc_complaint,
                       tt.ei_id_professional,
                       tt.ps_id_professional,
                       tt.id_prof_discharge,
                       tt.dt_discharge,
                       tt.dt_examinat,
                       tt.dt_visit,
                       tt.appointment_type,
                       tt.appointment_type_code,
                       (pk_translation.get_translation(l_lang, tt.appointment_type_code)) desc_appointment_type,
                       tt.discharge_destination,
                       tt.discharge_status,
                       tt.clinical_service,
                       pk_data_access_cdoc.get_outp_department(l_lang, tt.clinical_service) desc_contact,
                       tt.dt_first_obs,
                       tt.dt_last_update_tstz
                  FROM (pk_data_access_cdoc.get_outpatient_base(l_institution, l_dt_ini, l_dt_end)) tt) t;
    
        RETURN tbl_list;
    
    END get_emr_outpatient_plus;

    -- ***************************************************************
    FUNCTION get_emr_emergency_plus
    (
        i_institution IN NUMBER DEFAULT NULL,
        i_dt_ini      IN VARCHAR2 DEFAULT NULL,
        i_dt_end      IN VARCHAR2 DEFAULT NULL
    ) RETURN t_tbl_data_emr_emergency_plus IS
    
        tbl_list t_tbl_data_emr_emergency_plus;
        l_lang   NUMBER;
        l_dt_ini death_registry.dt_death%TYPE;
        l_dt_end death_registry.dt_death%TYPE;
        l_prof   profissional;
        --k_msg    VARCHAR2(4000);
        l_software CONSTANT NUMBER := pk_alert_constant.g_soft_edis;
        l_institution NUMBER;
    
    BEGIN
    
        l_institution := coalesce(i_institution, pk_sysconfig.get_data_access_inst());
        l_prof        := profissional(0, l_institution, l_software);
        l_lang        := pk_sysconfig.get_config('LANGUAGE', l_prof.institution, l_prof.software);
        --k_msg         := pk_message.get_message(l_lang, 'TRIAGE_T039');
    
        date_processing(l_lang, l_prof, i_dt_ini, i_dt_end, l_dt_ini, l_dt_end);
    
        SELECT t_rec_data_emr_emergency_plus(id_institution        => tt.id_institution,
                                             id_patient            => tt.id_patient,
                                             id_episode            => tt.id_episode,
                                             id_next_episode       => tt.id_next_episode,
                                             flg_status            => tt.flg_status,
                                             desc_flg_status       => (SELECT (pk_sysdomain.get_domain('EPISODE.FLG_STATUS',
                                                                                                       tt.flg_status,
                                                                                                       l_lang))
                                                                         FROM dual),
                                             dt_discharge          => tt.dt_discharge,
                                             dis_flg_status        => tt.dis_flg_status,
                                             /*
                                             desc_dis_flg_status   => (SELECT (pk_sysdomain.get_domain('DISCHARGE.FLG_STATUS',
                                                                                                       tt.dis_flg_status,
                                                                                                       l_lang))
                                                                         FROM dual),
                                             */
                                             desc_dis_flg_status => (SELECT pk_data_access_cdoc.get_disp_transf_reopen(l_lang,
                                                                                                                       l_prof,
                                                                                                                       tt.id_episode)
                                                                       FROM dual),
                                             
                                             dis_flg_type          => tt.dis_flg_type,
                                             desc_dis_flg_type     => (SELECT (pk_sysdomain.get_domain('DISCHARGE.FLG_TYPE',
                                                                                                       tt.dis_flg_type,
                                                                                                       l_lang))
                                                                         FROM dual),
                                             dis_dt_pend_tstz      => tt.dis_dt_pend_tstz,
                                             dis_dt_admin_tstz      => tt.dis_dt_admin_tstz,
                                             dt_examination        => tt.dt_examination,
                                             dt_triage             => tt.dt_triage,
                                             dt_visit              => tt.dt_visit,
                                             arrival_method        => tt.arrival_method,
                                             discharge_destination => tt.discharge_destination,
                                             discharge_status      => tt.discharge_status,
                                             desc_discharge_status => (SELECT (pk_sysdomain.get_domain('DISCHARGE_DETAIL.FLG_PAT_CONDITION',
                                                                                                       tt.discharge_status,
                                                                                                       l_lang))
                                                                         FROM dual),
                                             id_prof_discharge     => tt.id_prof_discharge,
                                             id_habit              => tt.id_habit,
                                             id_epis_triage        => tt.id_epis_triage,
                                             code_triage_color     => tt.code_triage_color,
                                             --
                                             desc_triage_color => (SELECT pk_translation.get_translation(l_lang,
                                                                                                         tt.code_triage_color)
                                                                     FROM dual),
                                             
                                             flg_type      => tt.flg_type,
                                             desc_flg_type => (SELECT (pk_sysdomain.get_domain('TRIAGE_COLOR_GROUP.FLG_TYPE',
                                                                                               tt.flg_type,
                                                                                               l_lang))
                                                                 FROM dual),
                                             code_accuity  => tt.code_accuity,
                                             --
                                             desc_accuity        => (SELECT pk_translation.get_translation(l_lang,
                                                                                                           tt.code_accuity)
                                                                       FROM dual),
                                             id_triage_type      => tt.id_triage_type,
                                             id_triage_color     => tt.id_triage_color,
                                             id_software         => tt.id_software,
                                             patient_complaint   => tt.patient_complaint,
                                             code_complaint      => tt.code_complaint,
                                             desc_complaint      => (pk_data_access_cdoc.get_complaints(l_lang,
                                                                                                        tt.id_episode)),
                                             dt_complaint        => tt.dt_complaint,
                                             dt_last_update_tstz => tt.dt_last_update_tstz)
          BULK COLLECT
          INTO tbl_list
          FROM TABLE(pk_data_access_cdoc.get_emergency_base(l_institution, l_dt_ini, l_dt_end)) tt;
    
        RETURN tbl_list;
    
    END get_emr_emergency_plus;

    --****************************************
    FUNCTION get_emr_inpatient
    (
        i_institution IN NUMBER DEFAULT NULL,
        i_dt_ini      IN VARCHAR2 DEFAULT NULL,
        i_dt_end      IN VARCHAR2 DEFAULT NULL
    ) RETURN t_tbl_data_emr_inpatient IS
        tbl_list t_tbl_data_emr_inpatient;
        l_software CONSTANT NUMBER := pk_alert_constant.g_soft_inpatient;
        l_lang        NUMBER;
        l_institution NUMBER;
    
        l_dt_ini death_registry.dt_death%TYPE;
        l_dt_end death_registry.dt_death%TYPE;
        l_prof   profissional;
    
    BEGIN
    
        l_institution := coalesce(i_institution, pk_sysconfig.get_data_access_inst());
        l_prof        := profissional(0, l_institution, l_software);
        l_lang        := pk_sysconfig.get_config('LANGUAGE', l_prof.institution, l_prof.software);
    
        date_processing(l_lang, l_prof, i_dt_ini, i_dt_end, l_dt_ini, l_dt_end);
    
        SELECT t_rec_data_emr_inpatient(id_institution           => tt.id_institution,
                                        id_software              => tt.id_software,
                                        id_episode               => tt.id_episode,
                                        id_prev_episode          => tt.id_prev_episode,
                                        id_prof_discharge        => tt.id_prof_discharge,
                                        dt_epis_dt_begin_tstz    => tt.dt_epis_dt_begin_tstz,
                                        dt_vis_dt_begin_tstz     => tt.dt_vis_dt_begin_tstz,
                                        dt_discharge             => tt.dt_discharge,
                                        dis_flg_status           => tt.dis_flg_status,
                                        dt_discharge_pend        => tt.dt_discharge_pend,
                                        dt_discharge_adm         => tt.dt_discharge_adm,
                                        id_discharge_destination => tt.id_discharge_destination,
                                        id_habit                 => tt.id_habit,
                                        id_patient               => tt.id_patient,
                                        id_first_dep_clin_serv   => tt.id_first_dep_clin_serv,
                                        id_room                  => tt.id_room_now,
                                        code_room                => tt.code_room_now,
                                        id_bed                   => tt.id_bed_alloc,
                                        code_bed                 => tt.code_bed_alloc,
                                        dt_last_update_tstz      => tt.dt_last_update_tstz,
                                        flg_ehr                  => tt.flg_ehr)
          BULK COLLECT
          INTO tbl_list
          FROM (pk_data_access_cdoc.get_inpatient_base(l_institution, l_dt_ini, l_dt_end)) tt;
    
        dbms_output.put_line('count:' || tbl_list.count);
        RETURN tbl_list;
    
    END get_emr_inpatient;

    --****************************************
    FUNCTION get_emr_inpatient_plus
    (
        i_institution IN NUMBER DEFAULT NULL,
        i_dt_ini      IN VARCHAR2 DEFAULT NULL,
        i_dt_end      IN VARCHAR2 DEFAULT NULL
    ) RETURN t_tbl_data_emr_inpatient_plus IS
    
        tbl_list t_tbl_data_emr_inpatient_plus;
        l_lang   NUMBER;
    
        l_dt_ini death_registry.dt_death%TYPE;
        l_dt_end death_registry.dt_death%TYPE;
        l_prof   profissional;
        l_software CONSTANT NUMBER := pk_alert_constant.g_soft_inpatient;
        l_institution NUMBER;
    
    BEGIN
    
        l_institution := coalesce(i_institution, pk_sysconfig.get_data_access_inst());
        l_prof        := profissional(0, l_institution, l_software);
        l_lang        := pk_sysconfig.get_config('LANGUAGE', l_prof.institution, l_prof.software);
    
        date_processing(l_lang, l_prof, i_dt_ini, i_dt_end, l_dt_ini, l_dt_end);
    
        SELECT t_rec_data_emr_inpatient_plus(id_institution           => tt.id_institution,
                                             id_software              => tt.id_software,
                                             id_episode               => tt.id_episode,
                                             id_prev_episode          => tt.id_prev_episode,
                                             id_prof_discharge        => tt.id_prof_discharge,
                                             dt_epis_dt_begin_tstz    => tt.dt_epis_dt_begin_tstz,
                                             dt_vis_dt_begin_tstz     => tt.dt_vis_dt_begin_tstz,
                                             dt_discharge             => tt.dt_discharge,
                                             dt_discharge_pend        => tt.dt_discharge_pend,
                                             dt_discharge_adm        => tt.dt_discharge_adm,
                                             dis_flg_status           => tt.dis_flg_status,
                                             desc_dis_flg_status      => (SELECT pk_data_access_cdoc.get_disp_transf_reopen(l_lang,
                                                                                                                            l_prof,
                                                                                                                            tt.id_episode)
                                                                            FROM dual),
                                             id_discharge_destination => tt.id_discharge_destination,
                                             desc_discharge_dest      => pk_data_access_cdoc.get_discharge_destination(l_lang,
                                                                                                                       tt.id_discharge_destination),
                                             id_patient               => tt.id_patient,
                                             id_first_dep_clin_serv   => tt.id_first_dep_clin_serv,
                                             id_department_f          => tt.id_department_f,
                                             --code_department_f        => tt.code_department_f,
                                             desc_department_f        => (SELECT pk_translation.get_translation(l_lang,
                                                                                                                tt.code_department_f)
                                                                            FROM dual),
                                             id_clinical_service_f    => tt.id_clinical_service_f,
                                             --code_clinical_service_f  => tt.code_clinical_service_f,
                                             desc_clinical_service_f  => (SELECT pk_translation.get_translation(l_lang,
                                                                                                                tt.code_clinical_service_f)
                                                                            FROM dual),
                                             id_dep_clin_serv         => tt.id_dep_clin_serv,
                                             id_department_c          => tt.id_department_c,
                                             --code_department_c        => tt.code_department_c,
                                             desc_department_c        => (SELECT pk_translation.get_translation(l_lang,
                                                                                                                tt.code_department_c)
                                                                            FROM dual),
                                             id_clinical_service_c    => tt.id_clinical_service_c,
                                             --code_clinical_service_c  => tt.code_clinical_service_c,
                                             desc_clinical_service_c  => (SELECT pk_translation.get_translation(l_lang,
                                                                                                                tt.code_clinical_service_c)
                                                                            FROM dual),
                                             id_department_now        => tt.id_department_now,
                                             --code_department_now      => tt.code_department_now,
                                             desc_department_now      => (SELECT pk_translation.get_translation(l_lang,
                                                                                                                tt.code_department_now)
                                                                            FROM dual),
                                             id_room_now              => tt.id_room_now,
                                             --code_room_now            => tt.code_room_now,
                                             desc_room_now => pk_translation.get_translation(l_lang, tt.code_room_now),
                                             id_bed_alloc             => tt.id_bed_alloc,
                                             --code_bed_alloc           => tt.code_bed_alloc,
                                             desc_bed_alloc => pk_translation.get_translation(l_lang, tt.code_bed_alloc),
                                             id_room_alloc            => tt.id_room_alloc,
                                             --code_room_alloc          => tt.code_room_alloc,
                                             desc_room_alloc          => (SELECT pk_translation.get_translation(l_lang,
                                                                                                                tt.code_room_alloc)
                                                                            FROM dual),
                                             id_department_alloc      => tt.id_department_alloc,
                                             --code_department_alloc    => tt.code_department_alloc,
                                             desc_department_alloc    => (SELECT pk_translation.get_translation(l_lang,
                                                                                                                tt.code_department_alloc)
                                                                            FROM dual),
                                             
                                             dt_last_update_tstz => tt.dt_last_update_tstz,
                                             flg_ehr             => tt.flg_ehr,
                                             desc_flg_ehr        => (SELECT pk_sysdomain.get_domain('EPISODE.FLG_EHR',
                                                                                                    tt.flg_ehr,
                                                                                                    l_lang)
                                                                       FROM dual))
          BULK COLLECT
          INTO tbl_list
          FROM (pk_data_access_cdoc.get_inpatient_base(l_institution, l_dt_ini, l_dt_end)) tt;
    
        RETURN tbl_list;
    
    END get_emr_inpatient_plus;

    FUNCTION is_expected_patient(i_episode IN NUMBER) RETURN BOOLEAN IS
    BEGIN
        RETURN pk_announced_arrival.get_ann_arrival_status(i_episode => i_episode) = pk_announced_arrival.g_aa_arrival_status_e;
    END is_expected_patient;

    FUNCTION is_announced_arrival(i_episode IN NUMBER) RETURN BOOLEAN IS
    BEGIN
        RETURN pk_announced_arrival.get_ann_arrival_status(i_episode => i_episode) = pk_announced_arrival.g_aa_arrival_status_a;
    END is_announced_arrival;

    FUNCTION get_disp_transf_reopen
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2 IS
        l_status VARCHAR2(4000);
    
        FUNCTION get_msg066 RETURN VARCHAR2 IS
        BEGIN
            RETURN pk_message.get_message(i_lang, i_prof, 'ANN_ARRIV_MSG066');
        END get_msg066;
    
    BEGIN
    
        IF (is_expected_patient(i_id_episode))
        THEN
            --Announced arrival
            l_status := get_msg066();
        ELSE
            l_status := pk_hea_prv_aux.get_disp_transf_reopen(i_lang, i_prof, i_id_episode);
            IF l_status IS NULL
               AND is_announced_arrival(i_id_episode)
            THEN
                l_status := get_msg066();
            END IF;
        END IF;
    
        RETURN l_status;
    
    END get_disp_transf_reopen;

    --****************************************
    FUNCTION get_consult_base
    (
        i_institution IN NUMBER DEFAULT NULL,
        i_dt_ini      IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_dt_end      IN TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN t_tbl_data_consult_base IS
        tbl_return t_tbl_data_consult_base;
    
        -- var for cursor 
        l_full_sql CLOB;
        l_curid    INTEGER;
        l_ret      INTEGER;
        l_cursor   pk_types.cursor_type;
    
        -- var for building sql
        xlf         VARCHAR2(00010 CHAR) := chr(10);
        l_where_opt VARCHAR2(32000);
        l_base_sql  VARCHAR2(32000);
        tbl_columns table_varchar := table_varchar();
        tbl_from    table_varchar := table_varchar();
    
        tbl_where_fix table_varchar := table_varchar();
        tbl_where_opt table_varchar := table_varchar(q'[and vi.id_institution = :i_institution]');
    
        l_dt_ini TIMESTAMP WITH LOCAL TIME ZONE;
        l_dt_end TIMESTAMP WITH LOCAL TIME ZONE;
        l_prof   profissional := profissional(0, i_institution, 11);
    
    BEGIN
    
        tbl_columns := pk_data_access_cdoc_aux.get_cols_consult_base();
        tbl_from    := pk_data_access_cdoc_aux.get_from_consult_base();
    
        l_base_sql := get_base_sql(i_tbl_col => tbl_columns, i_tbl_from => tbl_from, i_tbl_where => tbl_where_fix);
    
        IF i_institution IS NOT NULL
        THEN
        
            FOR i IN 1 .. tbl_where_opt.count
            LOOP
                l_where_opt := l_where_opt || tbl_where_opt(i) || xlf;
            END LOOP;
        
        END IF;
    
        l_full_sql := to_clob(l_base_sql || l_where_opt);
    
        -- binding vars and running sql
    
        l_curid := dbms_sql.open_cursor;
        dbms_sql.parse(l_curid, l_full_sql, dbms_sql.native);
    
        l_dt_ini := pk_date_utils.trunc_insttimezone(l_prof, i_dt_ini, 'DD');
        l_dt_ini := l_dt_ini - numtodsinterval(1, 'DAY');
    
        l_dt_end := pk_date_utils.trunc_insttimezone(l_prof, i_dt_end, 'DD');
        l_dt_end := l_dt_end + numtodsinterval(24, 'HOUR') + numtodsinterval(-1, 'SECOND');
    
        /*
        l_dt_range := pk_date_utils.trunc_insttimezone( l_prof,  current_timestamp , 'DD');
        l_dt_range := l_dt_range - numtodsinterval( alert_context('l_day_range'), 'DAY');
        l_dt_range := l_dt_range + numtodsinterval( alert_context('l_hour_range'), 'HOUR')
        */
    
        dbms_sql.bind_variable(l_curid, 'l_dt_ini', l_dt_ini);
        dbms_sql.bind_variable(l_curid, 'l_dt_end', l_dt_end);
    
        IF i_institution IS NOT NULL
        THEN
            dbms_sql.bind_variable(l_curid, 'i_institution', i_institution);
        END IF;
    
        l_ret := dbms_sql.execute(l_curid);
    
        l_cursor := dbms_sql.to_refcursor(l_curid);
    
        FETCH l_cursor BULK COLLECT
            INTO tbl_return;
        CLOSE l_cursor;
    
        RETURN tbl_return;
    
    END get_consult_base;

    --****************************************
    FUNCTION get_emr_consult
    (
        i_institution IN NUMBER DEFAULT NULL,
        i_dt_ini      IN VARCHAR2 DEFAULT NULL,
        i_dt_end      IN VARCHAR2 DEFAULT NULL
    ) RETURN t_tbl_data_emr_consult IS
        tbl_list t_tbl_data_emr_consult;
        l_software CONSTANT NUMBER := pk_alert_constant.g_soft_inpatient;
        l_lang        NUMBER;
        l_institution NUMBER;
    
        l_dt_ini TIMESTAMP WITH LOCAL TIME ZONE;
        l_dt_end TIMESTAMP WITH LOCAL TIME ZONE;
        l_prof   profissional;
    
    BEGIN
    
        l_institution := coalesce(i_institution, pk_sysconfig.get_data_access_inst());
        l_prof        := profissional(0, l_institution, l_software);
        l_lang        := pk_sysconfig.get_config('LANGUAGE', l_prof.institution, l_prof.software);
    
        date_processing(l_lang, l_prof, i_dt_ini, i_dt_end, l_dt_ini, l_dt_end);
    
        SELECT t_rec_data_emr_consult(id_opinion          => tt.id_opinion,
                                      id_episode          => tt.id_episode,
                                      id_epis_type        => tt.id_epis_type,
                                      id_institution      => tt.id_institution,
                                      flg_state           => tt.flg_state,
                                      id_prof_questions   => tt.id_prof_questions,
                                      id_prof_questioned  => tt.id_prof_questioned,
                                      id_speciality       => tt.id_speciality,
                                      dt_problem_tstz     => tt.dt_problem_tstz,
                                      dt_cancel_tstz      => tt.dt_cancel_tstz,
                                      status_flg          => tt.status_flg,
                                      flg_type            => tt.flg_type,
                                      id_cancel_reason    => tt.id_cancel_reason,
                                      id_patient          => tt.id_patient,
                                      id_opinion_type     => tt.id_opinion_type,
                                      id_clinical_service => tt.id_clinical_service,
                                      dt_approved         => tt.dt_approved,
                                      id_prof_approved    => tt.id_prof_approved,
                                      flg_auto_follow_up  => tt.flg_auto_follow_up,
                                      id_prof_cancel      => tt.id_prof_cancel,
                                      flg_priority        => tt.flg_priority)
          BULK COLLECT
          INTO tbl_list
          FROM (pk_data_access_cdoc.get_consult_base(l_institution, l_dt_ini, l_dt_end)) tt;
    
        RETURN tbl_list;
    
    END get_emr_consult;

    -- ***************************************************************
    FUNCTION get_emr_consult_plus
    (
        i_institution IN NUMBER DEFAULT NULL,
        i_dt_ini      IN VARCHAR2 DEFAULT NULL,
        i_dt_end      IN VARCHAR2 DEFAULT NULL
    ) RETURN t_tbl_data_emr_consult_plus IS
    
        tbl_list t_tbl_data_emr_consult_plus;
        l_lang   NUMBER;
        l_dt_ini TIMESTAMP WITH LOCAL TIME ZONE;
        l_dt_end TIMESTAMP WITH LOCAL TIME ZONE;
        l_prof   profissional;
        l_software CONSTANT NUMBER := 11;
        l_institution NUMBER;
    
        k_inst_name    CONSTANT VARCHAR(0200 CHAR) := 'INSTITUTION.CODE_INSTITUTION.';
        k_spec_desc    CONSTANT VARCHAR(0200 CHAR) := 'SPECIALITY.CODE_SPECIALITY.';
        k_creason_desc CONSTANT VARCHAR(0200 CHAR) := 'CANCEL_REASON.CODE_CANCEL_REASON.';
        k_opinion_type CONSTANT VARCHAR(0200 CHAR) := 'OPINION_TYPE.CODE_OPINION_TYPE.';
        k_cli_service  CONSTANT VARCHAR(0200 CHAR) := 'CLINICAL_SERVICE.CODE_CLINICAL_SERVICE.';
    
    BEGIN
    
        l_institution := coalesce(i_institution, pk_sysconfig.get_data_access_inst());
        l_prof        := profissional(0, l_institution, l_software);
        l_lang        := pk_sysconfig.get_config('LANGUAGE', l_prof.institution, l_prof.software);
        --k_msg         := pk_message.get_message(l_lang, 'TRIAGE_T039');
    
        date_processing(l_lang, l_prof, i_dt_ini, i_dt_end, l_dt_ini, l_dt_end);
    
        SELECT t_rec_data_emr_consult_plus(id_opinion            => tt.id_opinion,
                                           id_episode            => tt.id_episode,
                                           id_epis_type          => tt.id_epis_type,
                                           id_institution        => tt.id_institution,
                                           institution_name      => (SELECT pk_translation.get_translation(l_lang,
                                                                                                           k_inst_name ||
                                                                                                           tt.id_institution)
                                                                       FROM dual),
                                           flg_state             => tt.flg_state,
                                           flg_state_desc        => (SELECT pk_sysdomain.get_domain('OPINION.FLG_STATE',
                                                                                                    tt.flg_state,
                                                                                                    l_lang)
                                                                       FROM dual),
                                           id_prof_questions     => tt.id_prof_questions,
                                           prof_name_questions   => (SELECT px.name
                                                                       FROM professional px
                                                                      WHERE px.id_professional = tt.id_prof_questions),
                                           id_prof_questioned    => tt.id_prof_questioned,
                                           prof_name_questioned  => (SELECT px.name
                                                                       FROM professional px
                                                                      WHERE px.id_professional = tt.id_prof_questioned),
                                           id_speciality         => tt.id_speciality,
                                           speciality_name       => (SELECT pk_translation.get_translation(l_lang,
                                                                                                           k_spec_desc ||
                                                                                                           tt.id_speciality)
                                                                       FROM dual),
                                           dt_problem_tstz       => tt.dt_problem_tstz,
                                           dt_cancel_tstz        => tt.dt_cancel_tstz,
                                           status_flg            => tt.status_flg,
                                           status_flg_desc       => (SELECT pk_sysdomain.get_domain('OPINION.STATUS_FLG',
                                                                                                    tt.status_flg,
                                                                                                    l_lang)
                                                                       FROM dual),
                                           flg_type              => tt.flg_type,
                                           flg_type_desc         => (SELECT pk_sysdomain.get_domain('OPINION.FLG_TYPE',
                                                                                                    tt.flg_type,
                                                                                                    l_lang)
                                                                       FROM dual),
                                           id_cancel_reason      => tt.id_cancel_reason,
                                           cancel_reason_desc    => (SELECT pk_translation.get_translation(l_lang,
                                                                                                           k_creason_desc ||
                                                                                                           tt.id_cancel_reason)
                                                                       FROM dual),
                                           id_patient            => tt.id_patient,
                                           id_opinion_type       => tt.id_opinion_type,
                                           opinion_type_desc     => (SELECT pk_translation.get_translation(l_lang,
                                                                                                           k_opinion_type ||
                                                                                                           tt.id_opinion_type)
                                                                       FROM dual),
                                           id_clinical_service   => tt.id_clinical_service,
                                           clinical_service_desc => (SELECT pk_translation.get_translation(l_lang,
                                                                                                           k_cli_service ||
                                                                                                           tt.id_clinical_service)
                                                                       FROM dual),
                                           dt_approved           => tt.dt_approved,
                                           id_prof_approved      => tt.id_prof_approved,
                                           prof_approved_name    => (SELECT px.name
                                                                       FROM professional px
                                                                      WHERE px.id_professional = tt.id_prof_approved),
                                           flg_auto_follow_up    => tt.flg_auto_follow_up,
                                           flg_auto_fup_desc     => (SELECT pk_sysdomain.get_domain('OPINION.FLG_AUTO_FOLLOW_UP',
                                                                                                    tt.flg_auto_follow_up,
                                                                                                    l_lang)
                                                                       FROM dual),
                                           id_prof_cancel        => tt.id_prof_cancel,
                                           prof_cancel_name      => (SELECT px.name
                                                                       FROM professional px
                                                                      WHERE px.id_professional = tt.id_prof_cancel),
                                           flg_priority          => tt.flg_priority,
                                           flg_priority_desc     => (SELECT pk_sysdomain.get_domain('OPINION.FLG_PRIORITY',
                                                                                                    tt.flg_priority,
                                                                                                    l_lang)
                                                                       FROM dual))
          BULK COLLECT
          INTO tbl_list
          FROM TABLE(pk_data_access_cdoc.get_consult_base(l_institution, l_dt_ini, l_dt_end)) tt;
    
        RETURN tbl_list;
    
    END get_emr_consult_plus;


    --****************************************
    FUNCTION get_transfer_base
    (
        i_institution IN NUMBER DEFAULT NULL,
        i_dt_ini      IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_dt_end      IN TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN t_tbl_data_transfer_base IS
        tbl_return t_tbl_data_transfer_base;
    
        -- var for cursor 
        l_full_sql CLOB;
        l_curid    INTEGER;
        l_ret      INTEGER;
        l_cursor   pk_types.cursor_type;
    
        -- var for building sql
        xlf         VARCHAR2(00010 CHAR) := chr(10);
        l_where_opt VARCHAR2(32000);
        l_base_sql  VARCHAR2(32000);
        tbl_columns table_varchar := table_varchar();
        tbl_from    table_varchar := table_varchar();
    
        tbl_where_fix table_varchar := table_varchar();
        tbl_where_opt table_varchar := table_varchar(q'[and v.id_institution = :i_institution]');
    
        l_dt_ini TIMESTAMP WITH LOCAL TIME ZONE;
        l_dt_end TIMESTAMP WITH LOCAL TIME ZONE;
        l_prof   profissional := profissional(0, i_institution, 11);
    
    BEGIN
    
        tbl_columns := pk_data_access_cdoc_aux.get_cols_transfer_base();
        tbl_from    := pk_data_access_cdoc_aux.get_from_transfer_base();
    
        l_base_sql := get_base_sql(i_tbl_col => tbl_columns, i_tbl_from => tbl_from, i_tbl_where => tbl_where_fix);
    
        IF i_institution IS NOT NULL
        THEN
        
            FOR i IN 1 .. tbl_where_opt.count
            LOOP
                l_where_opt := l_where_opt || tbl_where_opt(i) || xlf;
            END LOOP;
        
        END IF;
    
        l_full_sql := to_clob(l_base_sql || l_where_opt);
    
        -- binding vars and running sql
    
        l_curid := dbms_sql.open_cursor;
        dbms_sql.parse(l_curid, l_full_sql, dbms_sql.native);
    
        l_dt_ini := pk_date_utils.trunc_insttimezone(l_prof, i_dt_ini, 'DD');
        l_dt_ini := l_dt_ini - numtodsinterval(1, 'DAY');
    
        l_dt_end := pk_date_utils.trunc_insttimezone(l_prof, i_dt_end, 'DD');
        l_dt_end := l_dt_end + numtodsinterval(24, 'HOUR') + numtodsinterval(-1, 'SECOND');
    
        dbms_sql.bind_variable(l_curid, 'l_dt_ini', l_dt_ini);
        dbms_sql.bind_variable(l_curid, 'l_dt_end', l_dt_end);
    
        IF i_institution IS NOT NULL
        THEN
            dbms_sql.bind_variable(l_curid, 'i_institution', i_institution);
        END IF;
    
        l_ret := dbms_sql.execute(l_curid);
    
        l_cursor := dbms_sql.to_refcursor(l_curid);
    
        FETCH l_cursor BULK COLLECT
            INTO tbl_return;
        CLOSE l_cursor;
    
        RETURN tbl_return;
    
    END get_transfer_base;

    --****************************************
    FUNCTION get_emr_transfer
    (
        i_institution IN NUMBER DEFAULT NULL,
        i_dt_ini      IN VARCHAR2 DEFAULT NULL,
        i_dt_end      IN VARCHAR2 DEFAULT NULL
    ) RETURN t_tbl_data_emr_transfer IS
        tbl_list t_tbl_data_emr_transfer;
        l_software CONSTANT NUMBER := pk_alert_constant.g_soft_inpatient;
        l_lang        NUMBER;
        l_institution NUMBER;
    
        l_dt_ini TIMESTAMP WITH LOCAL TIME ZONE;
        l_dt_end TIMESTAMP WITH LOCAL TIME ZONE;
        l_prof   profissional;
    
    BEGIN
    
        l_institution := coalesce(i_institution, pk_sysconfig.get_data_access_inst());
        l_prof        := profissional(0, l_institution, l_software);
        l_lang        := pk_sysconfig.get_config('LANGUAGE', l_prof.institution, l_prof.software);
    
        date_processing(l_lang, l_prof, i_dt_ini, i_dt_end, l_dt_ini, l_dt_end);
    
        SELECT t_rec_data_emr_transfer(
       id_institution      => tt.id_institution     
      ,id_episode              => tt.id_episode                 
      ,id_prof_req             => tt.id_prof_req                
      ,dt_request_tstz         => tt.dt_request_tstz            
      ,flg_type                => tt.flg_type                   
      ,flg_status              => tt.flg_status                 
      ,id_clinical_service_orig=> tt.id_clinical_service_orig   
      ,id_department_orig      => tt.id_department_orig         
      )
          BULK COLLECT
          INTO tbl_list
          FROM (pk_data_access_cdoc.get_transfer_base(l_institution, l_dt_ini, l_dt_end)) tt;
    
        RETURN tbl_list;
    
    END get_emr_transfer;

    --****************************************
    FUNCTION get_emr_transfer_plus
    (
        i_institution IN NUMBER DEFAULT NULL,
        i_dt_ini      IN VARCHAR2 DEFAULT NULL,
        i_dt_end      IN VARCHAR2 DEFAULT NULL
    ) RETURN t_tbl_data_emr_transfer_plus IS
        tbl_list t_tbl_data_emr_transfer_plus;
        l_software CONSTANT NUMBER := pk_alert_constant.g_soft_inpatient;
        l_lang        NUMBER;
        l_institution NUMBER;
    
        l_dt_ini TIMESTAMP WITH LOCAL TIME ZONE;
        l_dt_end TIMESTAMP WITH LOCAL TIME ZONE;
        l_prof   profissional;

        k_inst_name    CONSTANT VARCHAR(0200 CHAR) := 'INSTITUTION.CODE_INSTITUTION.';
        k_cli_service  CONSTANT VARCHAR(0200 CHAR) := 'CLINICAL_SERVICE.CODE_CLINICAL_SERVICE.';
        k_dep_name     CONSTANT VARCHAR(0200 CHAR) := 'DEPARTMENT.CODE_DEPARTMENT.';
    
    BEGIN
    
        l_institution := coalesce(i_institution, pk_sysconfig.get_data_access_inst());
        l_prof        := profissional(0, l_institution, l_software);
        l_lang        := pk_sysconfig.get_config('LANGUAGE', l_prof.institution, l_prof.software);
    
        date_processing(l_lang, l_prof, i_dt_ini, i_dt_end, l_dt_ini, l_dt_end);
    
        SELECT t_rec_data_emr_transfer_plus(
       id_institution      => tt.id_institution     
      ,institution_name    => ( SELECT pk_translation.get_translation(l_lang,k_inst_name ||tt.id_institution) FROM dual)
      ,id_episode              => tt.id_episode                 
      ,id_prof_req             => tt.id_prof_req                
      ,prof_req_name       => (SELECT px.name FROM professional px WHERE px.id_professional = tt.id_prof_req)
      ,dt_request_tstz         => tt.dt_request_tstz            
      ,flg_type                => tt.flg_type                   
      ,flg_type_desc       => (SELECT pk_sysdomain.get_domain('EPIS_PROF_RESP.FLG_TYPE',tt.flg_TYPE, l_lang) FROM dual)
      ,flg_status              => tt.flg_status                 
      ,flg_Status_desc     => (SELECT pk_sysdomain.get_domain('EPIS_PROF_RESP.FLG_STATUS',tt.flg_STATUS, l_lang) FROM dual)
      ,id_clinical_service_orig=> tt.id_clinical_service_orig   
      ,clinical_service_orig_desc=> ( SELECT pk_translation.get_translation(l_lang, k_cli_service ||tt.id_clinical_service_orig) FROM dual)
      ,id_department_orig      => tt.id_department_orig         
      ,department_orig_desc  => ( SELECT pk_translation.get_translation(l_lang, k_dep_name ||tt.id_department_orig) FROM dual)
      )
          BULK COLLECT
          INTO tbl_list
          FROM (pk_data_access_cdoc.get_transfer_base(l_institution, l_dt_ini, l_dt_end)) tt;
    
        RETURN tbl_list;
    
    END get_emr_transfer_plus;


END pk_data_access_cdoc;
/
