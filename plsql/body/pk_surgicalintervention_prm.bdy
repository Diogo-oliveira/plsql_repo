/*-- Last Change Revision: $Rev: 1790427 $*/
/*-- Last Change by: $Author: pedro.henriques $*/
/*-- Date of last change: $Date: 2017-07-14 16:27:32 +0100 (sex, 14 jul 2017) $*/

CREATE OR REPLACE PACKAGE BODY pk_surgicalintervention_prm IS
    -- Package info
    g_package_owner t_low_char := 'ALERT';
    g_package_name  t_low_char := 'PK_SURGICALINTERVENTION_prm';

    g_table_name t_med_char;
    -- Private Methods

-- content loader method
/*FUNCTION load_sr_intervention_def
    (
        i_lang       IN language.id_language%TYPE,
        o_result_tbl OUT NUMBER,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_code_translation translation.code_translation%TYPE := upper('intervention.code_intervention.');
        l_level_array      table_number := table_number();
    BEGIN
        g_func_name := upper('load_sr_intervention_def');
    
        SELECT DISTINCT LEVEL BULK COLLECT
          INTO l_level_array
          FROM alert_default.intervention i
         WHERE i.flg_status = g_active
         START WITH i.id_interv_parent IS NULL
        CONNECT BY PRIOR i.id_intervention = i.id_interv_parent
         ORDER BY LEVEL ASC;
    
        FORALL c_level IN 1 .. l_level_array.count
            INSERT INTO sr_intervention
                (id_sr_intervention,
                 id_sr_interv_parent,
                 code_sr_intervention,
                 flg_status,
                 flg_type,
                 duration,
                 prev_recovery_time,
                 gdh,
                 icd,
                 gender,
                 age_min,
                 age_max,
                 cost,
                 price,
                 id_system_organ,
                 id_speciality,
                 adw_last_update,
                 flg_coding,
                 id_content)
                SELECT seq_sr_intervention.nextval,
                       id_sr_interv_parent,
                       l_code_translation || seq_sr_intervention.currval,
                       g_active,
                       flg_type,
                       duration,
                       prev_recovery_time,
                       gdh,
                       icd,
                       gender,
                       age_min,
                       age_max,
                       cost,
                       price,
                       id_system_organ,
                       id_speciality,
                       SYSDATE,
                       flg_coding,
                       id_content
                  FROM (SELECT si.id_sr_intervention,
                               decode(si.id_sr_interv_parent,
                                      NULL,
                                      NULL,
                                      nvl((SELECT sr.id_sr_intervention
                                            FROM sr_intervention sr
                                            JOIN alert_default.sr_intervention sr1
                                              ON sr.id_content = sr1.id_content
                                           WHERE sr1.id_sr_intervention = si.id_sr_interv_parent
                                             AND sr.flg_status = g_active),
                                          0)) id_sr_interv_parent,
                               si.flg_type,
                               si.duration,
                               si.prev_recovery_time,
                               si.gdh,
                               si.icd,
                               si.gender,
                               si.age_min,
                               si.age_max,
                               si.cost,
                               si.price,
                               si.id_system_organ,
                               si.id_speciality,
                               si.flg_coding,
                               si.id_content,
                               LEVEL lvl
                          FROM alert_default.sr_intervention si
                         WHERE si.flg_status = g_active
                        
                         START WITH si.id_sr_interv_parent IS NULL
                        CONNECT BY PRIOR si.id_sr_intervention = si.id_sr_interv_parent) def_data
                 WHERE def_data.lvl = l_level_array(c_level)
                   AND def_data.id_sr_interv_parent > 0
                    OR def_data.id_sr_interv_parent IS NULL
                   AND NOT EXISTS (SELECT 0
                          FROM sr_intervention dest_tbl
                         WHERE dest_tbl.id_content = def_data.id_content
                           AND dest_tbl.flg_status = g_active);
        o_result_tbl := SQL%ROWCOUNT;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            RETURN FALSE;
    END load_sr_intervention_def;*/
-- searcheable loader method
/*FUNCTION set_sr_interv_duration_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_mkt         IN table_number,
        i_vers        IN table_varchar,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_func_name := upper('set_sr_interv_duration_search');
        INSERT INTO sr_interv_duration
            (id_sr_intervention, id_institution, avg_duration, flg_available)
            SELECT def_data.id_sr_intervention, i_institution, def_data.avg_duration, g_flg_available
              FROM (SELECT temp_data.id_sr_intervention,
                           temp_data.avg_duration,
                           row_number() over(PARTITION BY temp_data.id_sr_intervention
                           
                           ORDER BY temp_data.id_market DESC, decode(temp_data.version, 'DEFAULT', 0, 1) DESC) records_count
                      FROM (SELECT nvl((SELECT ext_si.id_sr_intervention
                                         FROM sr_intervention ext_si
                                        INNER JOIN alert_default.sr_intervention int_si
                                           ON (int_si.id_content = ext_si.id_content)
                                        WHERE ext_si.flg_status = g_active
                                          AND int_si.id_sr_intervention = src_tbl.id_sr_intervention),
                                       0) id_sr_intervention,
                                   avg_duration,
                                   simv.id_market,
                                   simv.version
                            -- decode FKS to dest_vals
                              FROM alert_default.sr_interv_duration src_tbl
                             INNER JOIN alert_default.sr_intervention_mrk_vrs simv
                                ON (simv.id_sr_intervention = src_tbl.id_sr_intervention)
                             WHERE simv.id_market IN (SELECT \*+ dynamic_sampling(p 2) *\
                                                       column_value
                                                        FROM TABLE(CAST(i_mkt AS table_number)) p)
                                  
                               AND simv.version IN (SELECT \*+ dynamic_sampling(p 2) *\
                                                     column_value
                                                      FROM TABLE(CAST(i_vers AS table_varchar)) p)) temp_data
                     WHERE temp_data.id_sr_intervention > 0) def_data
             WHERE def_data.records_count = 1
               AND NOT EXISTS (SELECT 0
                      FROM sr_interv_duration ext_tbl
                     WHERE ext_tbl.id_sr_intervention = def_data.id_sr_intervention
                       AND ext_tbl.id_institution = i_institution
                       AND ext_tbl.flg_available = g_flg_available);
        o_result_tbl := SQL%ROWCOUNT;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            RETURN FALSE;
    END set_sr_interv_duration_search;*/
-- frequent loader method
/*FUNCTION set_sr_intervention_freq
    (
        i_lang              IN language.id_language%TYPE,
        i_institution       IN institution.id_institution%TYPE,
        i_mkt               IN table_number,
        i_vers              IN table_varchar,
        i_software          IN table_number,
        i_clin_serv_in      IN table_number,
        i_clin_serv_out     IN clinical_service.id_clinical_service%TYPE,
        i_dep_clin_serv_out IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_result_tbl        OUT NUMBER,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        pos CONSTANT NUMBER := 1;
    BEGIN
        g_func_name := upper('set_sr_intervention_freq');
        INSERT INTO sr_interv_dep_clin_serv
            (id_sr_interv_dep_clin_serv,
             id_institution,
             id_dep_clin_serv,
             id_sr_intervention,
             flg_type,
             id_software,
             rank,
             adw_last_update)
            SELECT seq_interv_dep_clin_serv.nextval,
                   i_institution,
                   i_dep_clin_serv_out,
                   def_data.alert_id,
                   def_data.flg_type,
                   def_data.id_software,
                   def_data.rank,
                   SYSDATE
              FROM (SELECT temp_data.flg_type,
                           temp_data.rank,
                           temp_data.alert_id,
                           i_software(pos) id_software,
                           row_number() over(PARTITION BY temp_data.alert_id, temp_data.flg_type
                           
                           ORDER BY temp_data.id_software DESC, temp_data.id_market DESC, decode(temp_data.version, 'DEFAULT', 0, 1) DESC) frecords_count
                      FROM (SELECT srcs.flg_type,
                                   srcs.rank,
                                   nvl((SELECT a_sri.id_sr_intervention
                                         FROM sr_intervention a_sri
                                        WHERE a_sri.id_content = sri.id_content
                                          AND a_sri.flg_status = g_active
                                          AND rownum = 1),
                                       0) AS alert_id,
                                   srimv.id_market,
                                   srimv.version,
                                   srcs.id_software
                              FROM alert_default.sr_interv_clin_serv srcs
                             INNER JOIN alert_default.sr_intervention sri
                                ON (sri.id_sr_intervention = srcs.id_sr_intervention)
                             INNER JOIN alert_default.sr_intervention_mrk_vrs srimv
                                ON (srimv.id_sr_intervention = sri.id_sr_intervention AND
                                   srimv.id_market IN (SELECT \*+ dynamic_sampling(p 2) *\
                                                         column_value
                                                          FROM TABLE(CAST(i_mkt AS table_number)) p) AND
                                   srimv.version IN (SELECT \*+ dynamic_sampling(p 2) *\
                                                       column_value
                                                        FROM TABLE(CAST(i_vers AS table_varchar)) p))
                             WHERE srcs.id_software IN
                                   (SELECT \*+ dynamic_sampling(p 2) *\
                                     column_value
                                      FROM TABLE(CAST(i_software AS table_number)) p)
                               AND srcs.flg_type = 'M'
                               AND srcs.id_clinical_service IN
                                   (SELECT \*+ dynamic_sampling(p 2) *\
                                     column_value
                                      FROM TABLE(CAST(i_clin_serv_in AS table_number)) p)) temp_data
                     WHERE temp_data.alert_id > 0) def_data
             WHERE def_data.frecords_count = 1
               AND NOT EXISTS (SELECT 0
                      FROM sr_interv_dep_clin_serv sridcs
                     WHERE sridcs.id_dep_clin_serv = i_dep_clin_serv_out
                       AND sridcs.id_sr_intervention = def_data.alert_id
                       AND sridcs.flg_type = 'M'
                       AND sridcs.id_software = i_software(pos));
        o_result_tbl := SQL%ROWCOUNT;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            RETURN FALSE;
    END set_sr_intervention_freq;*/
-- global vars
BEGIN
    -- Initializes log context

    pk_alertlog.who_am_i(owner => g_package_owner, name => g_package_name);
    pk_alertlog.log_init(g_package_name);

    g_flg_available := pk_alert_constant.g_available;
    g_active        := pk_alert_constant.g_active;

    g_array_size  := 100;
    g_array_size1 := 10000;
END pk_surgicalintervention_prm;
/
