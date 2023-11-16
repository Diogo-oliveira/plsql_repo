/*-- Last Change Revision: $Rev: 1830062 $*/
/*-- Last Change by: $Author: ana.moita $*/
/*-- Date of last change: $Date: 2018-03-12 11:45:39 +0000 (seg, 12 mar 2018) $*/

CREATE OR REPLACE PACKAGE BODY pk_surgicalequipment_prm IS
    -- Package info
    g_package_owner t_low_char := 'alert';
    g_package_name  t_low_char := 'PK_SurgicalEquipment_prm';

    g_table_name t_med_char;
    -- Private Methods

    -- content loader method
    FUNCTION load_sr_equip_def
    (
        i_lang       IN language.id_language%TYPE,
        o_result_tbl OUT NUMBER,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_code_translation translation.code_translation%TYPE := upper('sr_equip.code_sr_equip.');
        l_level_array      table_number := table_number();
    BEGIN
        g_func_name := upper('load_sr_equip_def');

        SELECT DISTINCT LEVEL BULK COLLECT
          INTO l_level_array
          FROM alert_default.sr_equip sr
         WHERE sr.flg_available = g_flg_available
         START WITH sr.id_sr_equip_parent IS NULL
        CONNECT BY PRIOR sr.id_sr_equip = sr.id_sr_equip_parent
         ORDER BY LEVEL ASC;

        FORALL c_level IN 1 .. l_level_array.count
            INSERT INTO sr_equip
                (id_sr_equip,
                 id_sr_equip_parent,
                 code_equip,
                 flg_available,
                 flg_schedule_yn,
                 flg_hemo_yn,
                 rank,
                 adw_last_update,
                 flg_type,
                 id_content,
                 id_content_new)
                SELECT seq_sr_equip.nextval,
                       id_sr_equip_parent,
                       l_code_translation || seq_sr_equip.currval,
                       g_flg_available,
                       flg_schedule_yn,
                       flg_hemo_yn,
                       NULL,
                       SYSDATE,
                       flg_type,
                       id_content,
                       id_content_new
                  FROM (SELECT se.id_sr_equip,
                               decode(se.id_sr_equip_parent,
                                      NULL,
                                      NULL,
                                      nvl((SELECT asr.id_sr_equip
                                            FROM sr_equip asr
                                            JOIN alert_default.sr_equip sre
                                              ON asr.id_content = sre.id_content
                                           WHERE sre.id_sr_equip = se.id_sr_equip_parent
                                             AND sre.flg_available = g_flg_available
                                             AND asr.flg_available = g_flg_available
                                             AND rownum = 1),
                                          0)) id_sr_equip_parent,
                               se.flg_schedule_yn,
                               se.flg_hemo_yn,
                               se.flg_type,
                               se.id_content,
                               se.id_content_new,
                               LEVEL lvl
                          FROM alert_default.sr_equip se
                         WHERE se.flg_available = g_flg_available
                           AND NOT EXISTS (SELECT 0
                                  FROM sr_equip dest_tbl
                                 WHERE dest_tbl.id_content = se.id_content
                                   AND dest_tbl.flg_available = g_flg_available)
                         START WITH se.id_sr_equip_parent IS NULL
                        CONNECT BY PRIOR se.id_sr_equip = se.id_sr_equip_parent) def_data
                 WHERE (def_data.id_sr_equip_parent IS NULL OR def_data.id_sr_equip_parent > 0)
                   AND def_data.lvl = l_level_array(c_level);
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
    END load_sr_equip_def;

    FUNCTION load_sr_equip_kit_def
    (
        i_lang       IN language.id_language%TYPE,
        o_result_tbl OUT NUMBER,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_func_name := upper('load_sr_equip_kit_def');
        INSERT INTO sr_equip_kit
            (id_sr_equip_kit,
             id_sr_equip_parent,
             id_sr_equip,
             desc_equip_kit,
             flg_available,
             id_speciality,
             qty,
             create_date_tstz)
            SELECT seq_sr_equip_kit.nextval,
                   id_sr_equip_parent,
                   id_sr_equip,
                   desc_equip_kit,
                   g_flg_available,
                   id_speciality,
                   qty,
                   current_timestamp
              FROM (SELECT nvl((SELECT sr.id_sr_equip
                                 FROM sr_equip sr
                                 JOIN alert_default.sr_equip asr
                                   ON sr.id_content = asr.id_content
                                WHERE sek.id_sr_equip_parent = asr.id_sr_equip
                                  AND sr.flg_available = g_flg_available
                                  AND asr.flg_available = g_flg_available
                                  AND rownum = 1),
                               0) id_sr_equip_parent,
                           nvl((SELECT sr.id_sr_equip
                                 FROM sr_equip sr
                                 JOIN alert_default.sr_equip asr
                                   ON sr.id_content = asr.id_content
                                WHERE sek.id_sr_equip = asr.id_sr_equip
                                  AND sr.flg_available = g_flg_available
                                  AND asr.flg_available = g_flg_available
                                  AND rownum = 1),
                               0) id_sr_equip,
                           sek.desc_equip_kit,
                           nvl((SELECT ss.id_speciality
                                 FROM speciality ss
                                WHERE sek.id_sr_equip = sek.id_sr_equip
                                  AND ss.id_speciality = sek.id_speciality
                                  AND ss.flg_available = g_flg_available),
                               NULL) id_speciality,
                           sek.qty
                      FROM alert_default.sr_equip_kit sek
                     WHERE sek.flg_available = g_flg_available) def_data
             WHERE def_data.id_sr_equip > 0
               AND def_data.id_sr_equip_parent > 0
               AND NOT EXISTS (SELECT 0
                      FROM sr_equip_kit dest_tbl
                     WHERE dest_tbl.id_sr_equip = def_data.id_sr_equip
                       AND dest_tbl.id_sr_equip_parent = def_data.id_sr_equip_parent
                       AND dest_tbl.flg_available = g_flg_available);
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
    END load_sr_equip_kit_def;

    FUNCTION load_sr_equip_period_def
    (
        i_lang       IN language.id_language%TYPE,
        o_result_tbl OUT NUMBER,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_func_name := upper('load_sr_equip_period_def');
        INSERT INTO sr_equip_period
            (id_sr_equip_period, id_sr_equip, id_surg_period, flg_available, adw_last_update, flg_default)
            SELECT seq_sr_equip_period.nextval, id_sr_equip, id_surg_period, g_flg_available, SYSDATE, FLG_DEFAULT
              FROM (SELECT nvl((SELECT se.id_sr_equip
                                 FROM sr_equip se
                                 JOIN alert_default.sr_equip sr
                                   ON se.id_content = sr.id_content
                                WHERE se.flg_available = g_flg_available
                                  AND sr.flg_available = g_flg_available
                                  AND sep.id_sr_equip = sr.id_sr_equip
                                  AND rownum = 1),
                               0) id_sr_equip,
                           sep.id_surg_period,
													 sep.flg_default
                      FROM alert_default.sr_equip_period sep
                     WHERE sep.flg_available = g_flg_available) def_data
             WHERE NOT EXISTS (SELECT 0
                      FROM sr_equip_period dest_tbl
                     WHERE dest_tbl.flg_available = g_flg_available
                       AND dest_tbl.id_sr_equip = def_data.id_sr_equip
                       AND dest_tbl.id_surg_period = def_data.id_surg_period)
               AND def_data.id_sr_equip != 0;

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
    END load_sr_equip_period_def;
    -- searcheable loader method

-- frequent loader method

-- global vars
BEGIN
    -- Initializes log context

    pk_alertlog.who_am_i(owner => g_package_owner, name => g_package_name);
    pk_alertlog.log_init(g_package_name);

    g_flg_available := pk_alert_constant.g_available;
    g_active        := pk_alert_constant.g_active;

    g_array_size  := 100;
    g_array_size1 := 10000;
END pk_surgicalequipment_prm;

/
