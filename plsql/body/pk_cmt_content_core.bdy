/*-- Last Change Revision: $Rev: 2053893 $*/
/*-- Last Change by: $Author: ana.matos $*/
/*-- Date of last change: $Date: 2022-12-30 14:20:45 +0000 (sex, 30 dez 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_cmt_content_core IS
    o_error                        t_error_out;
    g_language                     NUMBER := 2;
    g_error                        VARCHAR2(4000);
    g_package_owner                VARCHAR(200) := 'ALERT';
    g_package_name                 VARCHAR(200) := 'PK_CMT_CONTENT_CORE';
    g_func_name                    VARCHAR(200);
    g_flg_available                VARCHAR(200) := pk_alert_constant.g_available;
    g_flg_no                       VARCHAR(200) := pk_alert_constant.get_no;
    g_flg_active                   VARCHAR(200) := pk_alert_constant.g_active;
    g_flg_inactive                 VARCHAR(200) := pk_alert_constant.g_inactive;
    g_flg_searchable               VARCHAR(1) := 'P';
    g_flg_executable               VARCHAR(1) := 'W';
    g_flg_create                   VARCHAR(1) := 'C';
    g_flg_delete                   VARCHAR(1) := 'D';
    g_flg_update                   VARCHAR(1) := 'U';
    g_flg_update_create            VARCHAR(1) := 'A';
    g_pk_apex_most_freq_create     VARCHAR(1) := 'A';
    g_pk_apex_most_freq_delete     VARCHAR(1) := 'R';
    g_pk_apex_most_freq_by_dcs     VARCHAR(1) := 'D';
    g_pk_apex_most_freq_lab_test   VARCHAR(1) := 'A';
    g_pk_apex_most_freq_exam       VARCHAR(1) := 'I';
    g_pk_apex_most_freq_other_exam VARCHAR(1) := 'O';
    g_pk_apex_most_freq_exam_cat   VARCHAR(2) := 'EC';
    g_pk_apex_most_lab_test_group  VARCHAR(2) := 'AG';
    g_pk_apex_most_freq_proc       VARCHAR(1) := 'P';
    g_pk_apex_most_freq_sr_proc    VARCHAR(2) := 'SP';
    g_cat_lab                      VARCHAR(1) := 'Y';
    g_cat_exam                     VARCHAR(1) := 'N';
    g_rank_zero                    NUMBER := 0;
    g_soft_zero                    NUMBER := 0;
    g_otherexam_type               VARCHAR(1) := 'E';
    g_imgexam_type                 VARCHAR(1) := 'I';
    g_tbl_translation              VARCHAR(100) := 'TRANSLATION';
    g_tbl_sys_message              VARCHAR(100) := 'SYS_MESSAGE';
    g_tbl_sys_domain               VARCHAR(100) := 'SYS_DOMAIN';

    g_sr_intervention VARCHAR(2) := 'SR';

    g_backoffice     NUMBER := 26;
    g_img_technician NUMBER := 15;
    g_lab_technician NUMBER := 16;

    FUNCTION check_dest_language
    (
        i_username    VARCHAR,
        i_id_language VARCHAR
    ) RETURN NUMBER IS
        l_dest_langs  VARCHAR2(300);
        l_source_lang VARCHAR2(300);
        l_help_lang   VARCHAR2(100);
    BEGIN
        SELECT id_lang_dest, id_lang_source
          INTO l_dest_langs, l_source_lang
          FROM alert_core_data.cmt_user_trans_languages
         WHERE username = i_username;
    
        l_help_lang := ':' || i_id_language || ':';
    
        IF (instr(l_dest_langs, l_help_lang) = 0 /* OR i_id_language = l_source_lang*/
           )
        THEN
            RETURN 0;
        ELSE
            RETURN 1;
        END IF;
    
    END check_dest_language;

    FUNCTION get_source_language(i_username VARCHAR) RETURN NUMBER IS
        l_source_lang VARCHAR2(300);
    BEGIN
    
        SELECT id_lang_source
          INTO l_source_lang
          FROM alert_core_data.cmt_user_trans_languages
         WHERE username = i_username;
    
        RETURN l_source_lang;
    
    END get_source_language;

    FUNCTION get_profile_template_market
    (
        i_category    NUMBER DEFAULT NULL,
        i_software    NUMBER,
        i_institution NUMBER
    ) RETURN table_number IS
        l_profiles table_number;
    BEGIN
    
        SELECT DISTINCT pt.id_profile_template
          BULK COLLECT
          INTO l_profiles
          FROM profile_template pt
          JOIN profile_template_market ptm
            ON ptm.id_profile_template = pt.id_profile_template
          JOIN profile_template_category ptc
            ON ptc.id_profile_template = pt.id_profile_template
         WHERE pt.id_software = i_software
           AND ptm.id_market IN (pk_utils.get_institution_market(2, i_institution), 0)
           AND pt.flg_available = g_flg_available
           AND decode(i_category, NULL, -1, ptc.id_category) = nvl(i_category, -1);
    
        RETURN l_profiles;
    
    END get_profile_template_market;

    FUNCTION check_profile_template
    (
        i_profile_template NUMBER,
        i_institution      NUMBER,
        i_software         NUMBER,
        i_category         NUMBER DEFAULT NULL
        
    ) RETURN BOOLEAN IS
        l_nurse BOOLEAN;
        l_cnt   NUMBER;
    BEGIN
    
        SELECT COUNT(*)
          INTO l_cnt
          FROM profile_template pt
          JOIN profile_template_market ptm
            ON ptm.id_profile_template = pt.id_profile_template
          JOIN profile_template_category ptc
            ON ptc.id_profile_template = pt.id_profile_template
         WHERE pt.id_software = i_software
           AND ptm.id_market IN (pk_utils.get_institution_market(2, i_institution), 0)
           AND pt.flg_available = g_flg_available
           AND decode(i_category, NULL, -1, ptc.id_category) = nvl(i_category, -1)
           AND pt.id_profile_template = i_profile_template;
    
        IF l_cnt = 0
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    END check_profile_template;

    PROCEDURE set_other_exam
    (
        i_action            VARCHAR,
        i_id_language       VARCHAR,
        i_id_cnt_other_exam VARCHAR,
        i_id_institution    NUMBER,
        i_id_software       NUMBER,
        i_desc_other_exam   VARCHAR,
        i_id_cnt_exam_cat   VARCHAR,
        i_age_min           NUMBER,
        i_age_max           NUMBER,
        i_gender            VARCHAR,
        i_flg_first_result  VARCHAR,
        i_flg_execute       VARCHAR,
        i_desc_alias        VARCHAR,
        i_flg_mov_pat       VARCHAR,
        i_flg_timeout       VARCHAR,
        i_flg_result_notes  VARCHAR,
        i_flg_first_execute VARCHAR,
        i_flg_pat_resp      VARCHAR,
        i_flg_pat_prep      VARCHAR,
        i_flg_technical     VARCHAR DEFAULT 'N',
        i_flg_priority      VARCHAR
    ) IS
    
        l_cod_exam      exam.code_exam%TYPE;
        l_exam          NUMBER;
        l_cnt_exam_cat  NUMBER;
        l_id_exam_alias NUMBER;
    BEGIN
        g_func_name := 'set_other_exam';
        SELECT nvl((SELECT a.id_exam
                     FROM exam a
                    WHERE a.id_content = i_id_cnt_other_exam
                      AND a.flg_available = g_flg_available),
                   0)
          INTO l_exam
          FROM dual;
    
        SELECT nvl((SELECT a.id_exam_cat
                     FROM exam_cat a
                    WHERE a.id_content = i_id_cnt_exam_cat
                      AND a.flg_available = g_flg_available),
                   0)
          INTO l_cnt_exam_cat
          FROM dual;
    
        IF l_exam = 0
           AND (i_action = g_flg_create OR i_action = g_flg_update)
           AND i_desc_other_exam IS NOT NULL
        THEN
        
            SELECT seq_exam.nextval
              INTO l_exam
              FROM dual;
        
            INSERT INTO exam
                (id_exam,
                 code_exam,
                 flg_available,
                 rank,
                 adw_last_update,
                 id_content,
                 id_exam_cat,
                 flg_type,
                 age_min,
                 age_max,
                 gender,
                 flg_technical)
            VALUES
                (l_exam,
                 'EXAM.CODE_EXAM.' || l_exam,
                 g_flg_available,
                 g_rank_zero,
                 SYSDATE,
                 i_id_cnt_other_exam,
                 l_cnt_exam_cat,
                 g_otherexam_type,
                 i_age_min,
                 i_age_max,
                 i_gender,
                 i_flg_technical);
        
            SELECT e.code_exam
              INTO l_cod_exam
              FROM exam e
             WHERE e.id_exam = l_exam;
        
            pk_translation.insert_into_translation(i_id_language, l_cod_exam, i_desc_other_exam);
        
            IF i_desc_alias IS NOT NULL
            THEN
            
                SELECT nvl((SELECT MAX(a.id_exam_alias) + 1
                             FROM exam_alias a),
                           0)
                  INTO l_id_exam_alias
                  FROM dual;
            
                INSERT INTO exam_alias
                    (id_exam_alias,
                     id_exam,
                     code_exam_alias,
                     id_institution,
                     id_software,
                     id_professional,
                     id_dep_clin_serv,
                     adw_last_update)
                VALUES
                    (l_id_exam_alias,
                     l_exam,
                     'EXAM_ALIAS.CODE_EXAM_ALIAS.' || l_id_exam_alias,
                     i_id_institution,
                     i_id_software,
                     NULL,
                     NULL,
                     SYSDATE);
                pk_translation.insert_into_translation(i_id_language,
                                                       'EXAM_ALIAS.CODE_EXAM_ALIAS.' || l_id_exam_alias,
                                                       i_desc_alias);
            END IF;
        
            INSERT INTO exam_dep_clin_serv
                (id_exam_dep_clin_serv,
                 id_exam,
                 flg_type,
                 rank,
                 id_institution,
                 id_software,
                 flg_first_result,
                 flg_execute,
                 flg_timeout,
                 flg_result_notes,
                 flg_first_execute,
                 flg_mov_pat,
                 flg_priority)
                SELECT seq_exam_dep_clin_serv.nextval,
                       e.id_exam,
                       g_flg_searchable,
                       g_rank_zero,
                       i_id_institution,
                       i_id_software,
                       i_flg_first_result,
                       i_flg_execute,
                       i_flg_timeout,
                       i_flg_result_notes,
                       i_flg_first_execute,
                       i_flg_mov_pat,
                       i_flg_priority
                  FROM exam e
                 WHERE e.id_exam = l_exam
                   AND NOT EXISTS (SELECT 1
                          FROM exam_dep_clin_serv edcs1
                         WHERE edcs1.id_exam = e.id_exam
                           AND edcs1.id_dep_clin_serv IS NULL
                           AND edcs1.id_software = i_id_software
                           AND edcs1.id_institution = i_id_institution
                           AND edcs1.flg_type = pk_exam_constant.g_exam_can_req);
        
        ELSIF i_action = g_flg_create
              AND l_exam != 0
        THEN
            INSERT INTO exam_dep_clin_serv
                (id_exam_dep_clin_serv,
                 id_exam,
                 flg_type,
                 rank,
                 id_institution,
                 id_software,
                 flg_first_result,
                 flg_execute,
                 flg_timeout,
                 flg_result_notes,
                 flg_first_execute,
                 flg_mov_pat,
                 flg_priority)
                SELECT seq_exam_dep_clin_serv.nextval,
                       e.id_exam,
                       g_flg_searchable,
                       g_rank_zero,
                       i_id_institution,
                       i_id_software,
                       i_flg_first_result,
                       i_flg_execute,
                       i_flg_timeout,
                       i_flg_result_notes,
                       i_flg_first_execute,
                       i_flg_mov_pat,
                       i_flg_priority
                  FROM exam e
                 WHERE e.id_exam = l_exam
                   AND NOT EXISTS (SELECT 1
                          FROM exam_dep_clin_serv edcs1
                         WHERE edcs1.id_exam = e.id_exam
                           AND edcs1.id_dep_clin_serv IS NULL
                           AND edcs1.id_software = i_id_software
                           AND edcs1.id_institution = i_id_institution
                           AND edcs1.flg_type = pk_exam_constant.g_exam_can_req);
        
        ELSIF i_action = g_flg_update
              AND l_exam > 0
        THEN
        
            UPDATE exam a
               SET age_min         = i_age_min,
                   age_max         = i_age_max,
                   gender          = i_gender,
                   id_exam_cat     = l_cnt_exam_cat,
                   a.flg_technical = i_flg_technical
             WHERE a.id_exam = l_exam;
        
            UPDATE exam_dep_clin_serv a
               SET a.flg_first_result  = i_flg_first_result,
                   a.flg_execute       = i_flg_execute,
                   a.flg_timeout       = i_flg_timeout,
                   a.flg_result_notes  = i_flg_result_notes,
                   a.flg_first_execute = i_flg_first_execute,
                   a.flg_mov_pat       = i_flg_mov_pat,
                   a.flg_priority      = i_flg_priority
             WHERE a.id_exam = l_exam
               AND a.id_software = i_id_software
               AND a.id_dep_clin_serv IS NULL
               AND a.id_institution = i_id_institution
               AND a.flg_type = g_flg_searchable;
        
            SELECT nvl((SELECT a.id_exam_alias
                         FROM exam_alias a
                        WHERE a.id_exam = l_exam
                          AND a.id_institution = i_id_institution
                          AND a.id_software = i_id_software),
                       0)
              INTO l_id_exam_alias
              FROM dual;
        
            IF l_id_exam_alias = 0
               AND i_desc_alias IS NOT NULL
            THEN
                SELECT nvl((SELECT MAX(a.id_exam_alias) + 1
                             FROM exam_alias a),
                           0)
                  INTO l_id_exam_alias
                  FROM dual;
            
                INSERT INTO exam_alias
                    (id_exam_alias,
                     id_exam,
                     code_exam_alias,
                     id_institution,
                     id_software,
                     id_professional,
                     id_dep_clin_serv,
                     adw_last_update)
                VALUES
                    (l_id_exam_alias,
                     l_exam,
                     'EXAM_ALIAS.CODE_EXAM_ALIAS.' || l_id_exam_alias,
                     i_id_institution,
                     i_id_software,
                     NULL,
                     NULL,
                     SYSDATE);
            
                pk_translation.insert_into_translation(i_id_language,
                                                       'EXAM_ALIAS.CODE_EXAM_ALIAS.' || l_id_exam_alias,
                                                       i_desc_alias);
            ELSIF l_id_exam_alias > 0
                  AND i_desc_alias IS NOT NULL
            THEN
            
                pk_translation.insert_into_translation(i_id_language,
                                                       'EXAM_ALIAS.CODE_EXAM_ALIAS.' || l_id_exam_alias,
                                                       i_desc_alias);
            
            ELSIF l_id_exam_alias > 0
                  AND i_desc_alias IS NULL
            THEN
            
                DELETE FROM exam_alias a
                 WHERE a.id_exam = l_exam
                   AND a.id_institution = i_id_institution
                   AND a.id_software = i_id_software;
            
                pk_translation.insert_into_translation(i_id_language,
                                                       'EXAM_ALIAS.CODE_EXAM_ALIAS.' || l_id_exam_alias,
                                                       i_desc_alias);
            
            END IF;
        
        ELSIF i_action = g_flg_delete
        THEN
        
            DELETE FROM exam_room
             WHERE id_exam_dep_clin_serv IN (SELECT id_exam_dep_clin_serv
                                               FROM exam_dep_clin_serv a
                                              WHERE a.id_exam = l_exam
                                                AND a.id_software = i_id_software
                                                AND a.id_dep_clin_serv IS NULL
                                                AND a.id_institution = i_id_institution
                                                AND a.flg_type = g_flg_searchable);
        
            DELETE FROM exam_dep_clin_serv a
             WHERE a.id_exam = l_exam
               AND a.id_software = i_id_software
               AND a.id_dep_clin_serv IS NULL
               AND a.id_institution = i_id_institution
               AND a.flg_type = g_flg_searchable;
        
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            raise_application_error(-20001, SQLERRM);
            pk_alert_exceptions.process_error(i_id_language,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
        
    END set_other_exam;

    PROCEDURE set_img_exam_room
    (
        i_action          VARCHAR,
        i_id_language     VARCHAR,
        i_id_cnt_img_exam VARCHAR,
        i_id_room         VARCHAR,
        i_rank            NUMBER,
        i_flg_default     VARCHAR,
        i_id_record       NUMBER
    ) IS
        l_id_exam        NUMBER;
        l_id_institution NUMBER;
        l_bool           BOOLEAN;
        l_ids            table_number;
        l_status         table_varchar;
    
    BEGIN
    
        SELECT id_institution
          INTO l_id_institution
          FROM department
         WHERE id_department IN (SELECT id_department
                                   FROM room
                                  WHERE id_room = i_id_room);
    
        IF (g_func_name = 'set_img_exam_avlb')
        THEN
            g_func_name := 'set_img_exam_room';
        ELSE
        
            g_func_name := 'set_img_exam_room';
        
            l_bool := validate_content(i_id_language,
                                       l_id_institution,
                                       table_varchar(i_id_room),
                                       table_varchar('ROOM'),
                                       table_number(1),
                                       l_ids,
                                       l_status);
        
        END IF;
    
        SELECT a.id_exam
          INTO l_id_exam
          FROM exam a
         WHERE a.id_content = i_id_cnt_img_exam
           AND a.flg_available = g_flg_available;
    
        IF i_action = g_flg_create
        THEN
        
            INSERT INTO exam_room
                (id_exam_room,
                 id_exam,
                 id_room,
                 rank,
                 adw_last_update,
                 flg_available,
                 flg_default,
                 id_exam_dep_clin_serv)
            VALUES
                (seq_exam_room.nextval, l_id_exam, i_id_room, i_rank, SYSDATE, g_flg_available, i_flg_default, NULL);
        
            g_error := 'ALERT_INTER.exam_room_new FOR ID_EXAM = ' || l_id_exam || 'IN ID_ROOM = ' || i_id_room;
            alert_inter.pk_ia_event_backoffice.exam_room_new(i_id_exam_room   => seq_exam_room.currval,
                                                             i_id_institution => l_id_institution);
        
        ELSIF i_action = g_flg_update
        THEN
            UPDATE exam_room
               SET flg_default = i_flg_default, rank = i_rank, id_room = i_id_room
             WHERE id_exam = l_id_exam
               AND flg_available = g_flg_available
               AND id_exam_room = i_id_record;
        
            alert_inter.pk_ia_event_backoffice.exam_room_update(i_id_exam_room   => i_id_record,
                                                                i_id_institution => l_id_institution);
        
        ELSIF i_action = g_flg_delete
        THEN
        
            g_error := 'ALERT_INTER.exam_room_delete FOR ID_EXAM = ' || l_id_exam || 'IN ID_ROOM = ' || i_id_room;
            alert_inter.pk_ia_event_backoffice.exam_room_delete(i_id_exam_room   => i_id_record,
                                                                i_id_institution => l_id_institution,
                                                                id_exam          => l_id_exam,
                                                                id_room          => i_id_room);
        
            DELETE FROM exam_room a
             WHERE id_room = i_id_room
               AND id_exam = l_id_exam
               AND flg_available = g_flg_available
               AND id_exam_room = i_id_record;
        
        ELSIF i_action = g_flg_update_create
        THEN
        
            FOR i IN (SELECT a.id_exam, a.id_room, a.id_exam_room
                        FROM exam_room a
                        JOIN room b
                          ON a.id_room = b.id_room
                        JOIN department c
                          ON b.id_department = c.id_department
                         AND c.id_institution = l_id_institution
                       WHERE a.id_exam = l_id_exam
                         AND a.flg_default = g_flg_available
                         AND a.id_exam_dep_clin_serv IS NULL)
            LOOP
            
                g_error := 'ALERT_INTER.exam_room_delete FOR ID_EXAM = ' || i.id_exam || 'IN ID_ROOM = ' || i.id_room;
                alert_inter.pk_ia_event_backoffice.exam_room_delete(i_id_exam_room   => i.id_exam_room,
                                                                    i_id_institution => l_id_institution,
                                                                    id_exam          => i.id_exam,
                                                                    id_room          => i.id_room);
            
                DELETE FROM exam_room a
                 WHERE id_exam_room = i.id_exam_room;
            
            END LOOP;
        
            INSERT INTO exam_room
                (id_exam_room,
                 id_exam,
                 id_room,
                 rank,
                 adw_last_update,
                 flg_available,
                 flg_default,
                 id_exam_dep_clin_serv)
            VALUES
                (seq_exam_room.nextval, l_id_exam, i_id_room, i_rank, SYSDATE, g_flg_available, i_flg_default, NULL);
        
            g_error := 'ALERT_INTER.exam_room_new FOR ID_EXAM = ' || l_id_exam || 'IN ID_ROOM = ' || i_id_room;
            alert_inter.pk_ia_event_backoffice.exam_room_new(i_id_exam_room   => seq_exam_room.currval,
                                                             i_id_institution => l_id_institution);
        
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            raise_application_error(-20001, SQLERRM);
            pk_alert_exceptions.process_error(i_id_language,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
        
    END set_img_exam_room;

    PROCEDURE set_ultrasound_avlb
    (
        i_action                VARCHAR,
        i_id_language           VARCHAR,
        i_id_institution        NUMBER,
        i_id_software           NUMBER,
        i_desc_alias            VARCHAR,
        i_id_cnt_ultrasound     VARCHAR,
        i_flg_first_result      VARCHAR,
        i_flg_execute           VARCHAR,
        i_flg_mov_pat           VARCHAR,
        i_flg_timeout           VARCHAR,
        i_flg_result_notes      VARCHAR,
        i_flg_first_execute     VARCHAR,
        i_flg_chargeable        VARCHAR,
        i_flg_priority          VARCHAR,
        i_flg_bypass_validation VARCHAR,
        i_id_room               NUMBER
    ) IS
    
        l_ultrasound NUMBER;
        l_exam_type  NUMBER;
        l_error      VARCHAR2(4000);
        l_bool       BOOLEAN;
        l_ids        table_number;
        l_status     table_varchar;
    
    BEGIN
        g_func_name := 'set_ultrasound_avlb';
    
        BEGIN
            SELECT id_exam_type
              INTO l_exam_type
              FROM exam_type
             WHERE flg_type = 'U';
        
        EXCEPTION
            WHEN no_data_found THEN
                l_error := 'There is no type "Ultrasounds" in table exam_type. Please contact the project''s Project Manager';
                RAISE g_exception;
        END;
    
        IF (i_id_room IS NOT NULL)
        THEN
        
            l_bool := validate_content(i_id_language,
                                       i_id_institution,
                                       table_varchar(i_id_cnt_ultrasound, i_id_room),
                                       table_varchar('ULTRASOUND', 'ROOM'),
                                       table_number(1, 1),
                                       l_ids,
                                       l_status);
        
        ELSE
        
            l_bool := validate_content(i_id_language,
                                       i_id_institution,
                                       table_varchar(i_id_cnt_ultrasound),
                                       table_varchar('ULTRASOUND'),
                                       table_number(1),
                                       l_ids,
                                       l_status);
        
        END IF;
    
        l_ultrasound := l_ids(1);
    
        IF l_ultrasound != 0
           AND (i_action = g_flg_create OR i_action = g_flg_update)
        THEN
        
            BEGIN
                INSERT INTO exam_dep_clin_serv
                    (id_exam_dep_clin_serv,
                     id_exam,
                     flg_type,
                     rank,
                     id_institution,
                     id_software,
                     flg_first_result,
                     flg_execute,
                     flg_timeout,
                     flg_result_notes,
                     flg_first_execute,
                     flg_mov_pat,
                     flg_priority)
                    SELECT seq_exam_dep_clin_serv.nextval,
                           e.id_exam,
                           g_flg_searchable,
                           g_rank_zero,
                           i_id_institution,
                           i_id_software,
                           i_flg_first_result,
                           i_flg_execute,
                           i_flg_timeout,
                           i_flg_result_notes,
                           i_flg_first_execute,
                           i_flg_mov_pat,
                           i_flg_priority
                      FROM exam e
                     WHERE e.id_exam = l_ultrasound;
            
            EXCEPTION
                WHEN dup_val_on_index THEN
                
                    UPDATE exam_dep_clin_serv a
                       SET a.flg_first_result  = i_flg_first_result,
                           a.flg_execute       = i_flg_execute,
                           a.flg_timeout       = i_flg_timeout,
                           a.flg_result_notes  = i_flg_result_notes,
                           a.flg_first_execute = i_flg_first_execute,
                           a.flg_mov_pat       = i_flg_mov_pat,
                           a.flg_chargeable    = i_flg_chargeable,
                           a.flg_priority      = i_flg_priority
                     WHERE a.id_exam = l_ultrasound
                       AND a.id_software = i_id_software
                       AND a.id_dep_clin_serv IS NULL
                       AND a.id_institution = i_id_institution
                       AND a.flg_type = g_flg_searchable;
                
            END;
        
            BEGIN
                INSERT INTO exam_dep_clin_serv
                    (id_exam_dep_clin_serv,
                     id_exam,
                     flg_type,
                     rank,
                     id_institution,
                     id_software,
                     flg_first_result,
                     flg_execute,
                     flg_timeout,
                     flg_result_notes,
                     flg_first_execute,
                     flg_mov_pat,
                     flg_priority)
                    SELECT seq_exam_dep_clin_serv.nextval,
                           e.id_exam,
                           g_flg_searchable,
                           g_rank_zero,
                           i_id_institution,
                           g_img_technician,
                           i_flg_first_result,
                           i_flg_execute,
                           i_flg_timeout,
                           i_flg_result_notes,
                           i_flg_first_execute,
                           i_flg_mov_pat,
                           i_flg_priority
                      FROM exam e
                     WHERE e.id_exam = l_ultrasound;
            
            EXCEPTION
                WHEN dup_val_on_index THEN
                
                    UPDATE exam_dep_clin_serv a
                       SET a.flg_first_result  = i_flg_first_result,
                           a.flg_execute       = i_flg_execute,
                           a.flg_timeout       = i_flg_timeout,
                           a.flg_result_notes  = i_flg_result_notes,
                           a.flg_first_execute = i_flg_first_execute,
                           a.flg_mov_pat       = i_flg_mov_pat,
                           a.flg_chargeable    = i_flg_chargeable,
                           a.flg_priority      = i_flg_priority
                     WHERE a.id_exam = l_ultrasound
                       AND a.id_software = g_img_technician
                       AND a.id_dep_clin_serv IS NULL
                       AND a.id_institution = i_id_institution
                       AND a.flg_type = g_flg_searchable;
                
            END;
        
            MERGE INTO exam_type_group etg
            USING (SELECT l_exam_type             AS id_exam_type,
                          l_ultrasound            AS id_exam,
                          i_flg_bypass_validation AS flg_bypass_validation,
                          i_id_software           AS id_software,
                          i_id_institution        AS id_institution
                     FROM dual) h
            ON (etg.id_exam = h.id_exam AND etg.id_exam_type = h.id_exam_type AND etg.id_software = h.id_software AND etg.id_institution = h.id_institution)
            WHEN MATCHED THEN
                UPDATE
                   SET etg.flg_bypass_validation = h.flg_bypass_validation
            WHEN NOT MATCHED THEN
                INSERT
                    (id_exam_type_group, id_exam_type, id_exam, flg_bypass_validation, id_software, id_institution)
                VALUES
                    (seq_exam_type_group.nextval,
                     h.id_exam_type,
                     h.id_exam,
                     h.flg_bypass_validation,
                     h.id_software,
                     h.id_institution);
        
            IF i_id_room IS NOT NULL
            THEN
            
                pk_cmt_content_core.set_ultrasound_room(g_flg_update_create,
                                                        i_id_language,
                                                        i_id_cnt_ultrasound,
                                                        i_id_room,
                                                        0,
                                                        g_flg_available,
                                                        NULL);
            END IF;
        
        ELSIF i_action = g_flg_delete
        THEN
        
            DELETE FROM exam_type_group etg
             WHERE etg.id_exam = l_ultrasound
               AND etg.id_software = i_id_software
               AND etg.id_institution = i_id_institution
               AND etg.id_exam_type = l_exam_type;
        
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            raise_application_error(-20001, nvl(l_error, SQLERRM));
            pk_alert_exceptions.process_error(i_id_language,
                                              SQLCODE,
                                              SQLERRM,
                                              l_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            l_error := NULL;
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
        
    END;

    PROCEDURE set_ultrasound_room
    (
        i_action            VARCHAR,
        i_id_language       VARCHAR,
        i_id_cnt_ultrasound VARCHAR,
        i_id_room           VARCHAR,
        i_rank              NUMBER,
        i_flg_default       VARCHAR,
        i_id_record         NUMBER
    ) IS
        l_id_ultrasound  NUMBER;
        l_id_institution NUMBER;
        l_bool           BOOLEAN;
        l_ids            table_number;
        l_status         table_varchar;
    
    BEGIN
    
        g_func_name := 'set_ultrasound_room';
    
        SELECT id_institution
          INTO l_id_institution
          FROM department
         WHERE id_department IN (SELECT id_department
                                   FROM room
                                  WHERE id_room = i_id_room);
    
        l_bool := validate_content(i_id_language,
                                   l_id_institution,
                                   table_varchar(i_id_room),
                                   table_varchar('ROOM'),
                                   table_number(1),
                                   l_ids,
                                   l_status);
    
        SELECT a.id_exam
          INTO l_id_ultrasound
          FROM exam a
         WHERE a.id_content = i_id_cnt_ultrasound
           AND a.flg_available = g_flg_available;
    
        IF i_action = g_flg_create
        THEN
        
            INSERT INTO exam_room
                (id_exam_room,
                 id_exam,
                 id_room,
                 rank,
                 adw_last_update,
                 flg_available,
                 flg_default,
                 id_exam_dep_clin_serv)
            VALUES
                (seq_exam_room.nextval,
                 l_id_ultrasound,
                 i_id_room,
                 i_rank,
                 SYSDATE,
                 g_flg_available,
                 i_flg_default,
                 NULL);
        
            g_error := 'ALERT_INTER.exam_room_new FOR ID_EXAM = ' || l_id_ultrasound || 'IN ID_ROOM = ' || i_id_room;
            alert_inter.pk_ia_event_backoffice.exam_room_new(i_id_exam_room   => seq_exam_room.currval,
                                                             i_id_institution => l_id_institution);
        
        ELSIF i_action = g_flg_update
        THEN
            UPDATE exam_room
               SET flg_default = i_flg_default, rank = i_rank, id_room = i_id_room
             WHERE id_exam = l_id_ultrasound
               AND flg_available = g_flg_available
               AND id_exam_room = i_id_record;
        
            alert_inter.pk_ia_event_backoffice.exam_room_update(i_id_exam_room   => i_id_record,
                                                                i_id_institution => l_id_institution);
        
        ELSIF i_action = g_flg_delete
        THEN
        
            g_error := 'ALERT_INTER.exam_room_delete FOR ID_EXAM = ' || l_id_ultrasound || 'IN ID_ROOM = ' || i_id_room;
            alert_inter.pk_ia_event_backoffice.exam_room_delete(i_id_exam_room   => i_id_record,
                                                                i_id_institution => l_id_institution,
                                                                id_exam          => l_id_ultrasound,
                                                                id_room          => i_id_room);
        
            DELETE FROM exam_room a
             WHERE id_room = i_id_room
               AND id_exam = l_id_ultrasound
               AND flg_available = g_flg_available
               AND id_exam_room = i_id_record;
        
        ELSIF i_action = g_flg_update_create
        THEN
        
            FOR i IN (SELECT a.id_exam, a.id_room, a.id_exam_room
                        FROM exam_room a
                        JOIN room b
                          ON a.id_room = b.id_room
                        JOIN department c
                          ON b.id_department = c.id_department
                         AND c.id_institution = l_id_institution
                       WHERE a.id_exam = l_id_ultrasound
                         AND a.flg_default = g_flg_available
                         AND a.id_exam_dep_clin_serv IS NULL)
            LOOP
            
                g_error := 'ALERT_INTER.exam_room_delete FOR ID_EXAM = ' || i.id_exam || 'IN ID_ROOM = ' || i.id_room;
                alert_inter.pk_ia_event_backoffice.exam_room_delete(i_id_exam_room   => i.id_exam_room,
                                                                    i_id_institution => l_id_institution,
                                                                    id_exam          => i.id_exam,
                                                                    id_room          => i.id_room);
            
                DELETE FROM exam_room a
                 WHERE id_exam_room = i.id_exam_room;
            
            END LOOP;
        
            INSERT INTO exam_room
                (id_exam_room,
                 id_exam,
                 id_room,
                 rank,
                 adw_last_update,
                 flg_available,
                 flg_default,
                 id_exam_dep_clin_serv)
            VALUES
                (seq_exam_room.nextval,
                 l_id_ultrasound,
                 i_id_room,
                 i_rank,
                 SYSDATE,
                 g_flg_available,
                 i_flg_default,
                 NULL);
        
            g_error := 'ALERT_INTER.exam_room_new FOR ID_EXAM = ' || l_id_ultrasound || 'IN ID_ROOM = ' || i_id_room;
            alert_inter.pk_ia_event_backoffice.exam_room_new(i_id_exam_room   => seq_exam_room.currval,
                                                             i_id_institution => l_id_institution);
        
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            raise_application_error(-20001, SQLERRM);
            pk_alert_exceptions.process_error(i_id_language,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
        
    END set_ultrasound_room;

    PROCEDURE set_exam_cat
    (
        i_action          VARCHAR,
        i_id_language     VARCHAR,
        i_id_cnt_exam_cat VARCHAR,
        i_id_institution  NUMBER,
        i_id_software     NUMBER,
        i_desc_exam_cat   VARCHAR,
        i_rank            NUMBER
    ) IS
    
        l_cod_exam_cat exam.code_exam%TYPE;
        l_exam_cat     NUMBER;
    
    BEGIN
        g_func_name := 'set_exam_cat';
    
        SELECT nvl((SELECT id_exam_cat
                     FROM exam_cat a
                    WHERE a.id_content = i_id_cnt_exam_cat
                      AND a.flg_available = g_flg_available),
                   0)
          INTO l_exam_cat
          FROM dual;
    
        IF (i_action = g_flg_create OR i_action = g_flg_update)
           AND i_desc_exam_cat IS NOT NULL
           AND l_exam_cat = 0
        THEN
            SELECT seq_exam_cat.nextval
              INTO l_exam_cat
              FROM dual;
        
            INSERT INTO exam_cat
                (id_exam_cat, code_exam_cat, adw_last_update, flg_available, flg_lab, rank, id_content)
            VALUES
                (l_exam_cat,
                 'EXAM_CAT.CODE_EXAM_CAT.' || l_exam_cat,
                 SYSDATE,
                 g_flg_available,
                 g_cat_exam,
                 i_rank,
                 i_id_cnt_exam_cat);
        
            SELECT e.code_exam_cat
              INTO l_cod_exam_cat
              FROM exam_cat e
             WHERE e.id_exam_cat = l_exam_cat;
        
            pk_translation.insert_into_translation(i_id_language, l_cod_exam_cat, i_desc_exam_cat);
        
            INSERT /*+ ignore_row_on_dupkey_index(exam_cat_dcs ECC_PK) */
            INTO exam_cat_dcs
                (id_exam_cat_dcs, id_exam_cat, id_dep_clin_serv)
                SELECT seq_exam_cat_dcs.nextval, l_exam_cat, c.id_dep_clin_serv
                  FROM clinical_service a
                  JOIN dep_clin_serv c
                    ON c.id_clinical_service = a.id_clinical_service
                  JOIN department d
                    ON d.id_department = c.id_department
                  JOIN dept de
                    ON de.id_dept = d.id_dept
                  JOIN software_dept sd
                    ON sd.id_dept = de.id_dept
                  JOIN institution i
                    ON i.id_institution = d.id_institution
                   AND i.id_institution = de.id_institution
                 WHERE d.id_institution IN (i_id_institution)
                   AND sd.id_software IN (i_id_software)
                   AND d.flg_available = g_flg_available
                   AND a.flg_available = g_flg_available;
        
        ELSIF i_action = g_flg_create
              AND l_exam_cat > 0
        THEN
        
            INSERT /*+ ignore_row_on_dupkey_index(exam_cat_dcs ECC_PK) */
            INTO exam_cat_dcs
                (id_exam_cat_dcs, id_exam_cat, id_dep_clin_serv)
                SELECT seq_exam_cat_dcs.nextval, l_exam_cat, c.id_dep_clin_serv
                  FROM clinical_service a
                  JOIN dep_clin_serv c
                    ON c.id_clinical_service = a.id_clinical_service
                  JOIN department d
                    ON d.id_department = c.id_department
                  JOIN dept de
                    ON de.id_dept = d.id_dept
                  JOIN software_dept sd
                    ON sd.id_dept = de.id_dept
                  JOIN institution i
                    ON i.id_institution = d.id_institution
                   AND i.id_institution = de.id_institution
                 WHERE d.id_institution IN (i_id_institution)
                   AND sd.id_software IN (i_id_software)
                   AND d.flg_available = g_flg_available
                   AND a.flg_available = g_flg_available;
        
        ELSIF i_action = g_flg_delete
        THEN
        
            UPDATE exam_cat a
               SET flg_available = g_flg_no
             WHERE a.id_content = i_id_cnt_exam_cat
               AND a.flg_available = g_flg_available;
        
        ELSIF i_action = g_flg_update
              AND l_exam_cat > 0
        THEN
        
            UPDATE exam_cat a
               SET rank = i_rank
             WHERE a.id_content = i_id_cnt_exam_cat
               AND a.flg_available = g_flg_available;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            raise_application_error(-20001, SQLERRM);
            pk_alert_exceptions.process_error(i_id_language,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
        
    END set_exam_cat;

    PROCEDURE set_positioning
    (
        i_action             VARCHAR,
        i_id_language        VARCHAR,
        i_id_cnt_positioning VARCHAR,
        i_desc_positioning   VARCHAR,
        i_rank               NUMBER
    ) IS
    
        l_cod_positioning positioning.code_positioning%TYPE;
        l_positioning     NUMBER;
    
    BEGIN
        g_func_name := 'set_positioning';
        SELECT nvl((SELECT id_positioning
                     FROM positioning a
                    WHERE a.id_content = i_id_cnt_positioning
                      AND a.flg_available = g_flg_available),
                   0)
          INTO l_positioning
          FROM dual;
    
        IF (i_action = g_flg_create OR i_action = g_flg_update)
           AND l_positioning = 0
           AND i_desc_positioning IS NOT NULL
        THEN
            SELECT seq_positioning.nextval
              INTO l_positioning
              FROM dual;
            INSERT INTO positioning
                (id_positioning, code_positioning, adw_last_update, flg_available, rank, id_content)
            VALUES
                (l_positioning,
                 'POSITIONING.CODE_POSITIONING.' || l_positioning,
                 SYSDATE,
                 g_flg_available,
                 i_rank,
                 i_id_cnt_positioning);
        
            SELECT e.code_positioning
              INTO l_cod_positioning
              FROM positioning e
             WHERE e.id_positioning = l_positioning;
        
            pk_translation.insert_into_translation(i_id_language, l_cod_positioning, i_desc_positioning);
        
        ELSIF i_action = g_flg_delete
        THEN
        
            UPDATE positioning a
            
               SET flg_available = g_flg_no
             WHERE a.id_content = i_id_cnt_positioning
               AND a.flg_available = g_flg_available;
        
        ELSIF i_action = g_flg_update
              AND l_positioning = 0
        THEN
        
            UPDATE positioning a
               SET rank = i_rank
             WHERE a.id_content = i_id_cnt_positioning
               AND a.flg_available = g_flg_available;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            raise_application_error(-20001, SQLERRM);
            pk_alert_exceptions.process_error(i_id_language,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
        
    END set_positioning;

    PROCEDURE set_external_cause
    (
        i_action                VARCHAR,
        i_id_language           VARCHAR,
        i_id_cnt_external_cause VARCHAR,
        i_desc_external_cause   VARCHAR,
        i_rank                  NUMBER
    ) IS
    
        l_cod_external_cause external_cause.code_external_cause%TYPE;
        l_external_cause     NUMBER;
    
    BEGIN
        g_func_name := 'set_external_cause';
        SELECT nvl((SELECT id_external_cause
                     FROM external_cause a
                    WHERE a.id_content = i_id_cnt_external_cause
                      AND a.flg_available = g_flg_available),
                   0)
          INTO l_external_cause
          FROM dual;
    
        IF (i_action = g_flg_create OR i_action = g_flg_update)
           AND l_external_cause = 0
           AND i_desc_external_cause IS NOT NULL
        THEN
            SELECT seq_external_cause.nextval
              INTO l_external_cause
              FROM dual;
            INSERT INTO external_cause
                (id_external_cause, code_external_cause, adw_last_update, flg_available, rank, id_content)
            VALUES
                (l_external_cause,
                 'EXTERNAL_CAUSE.CODE_EXTERNAL_CAUSE.' || l_external_cause,
                 SYSDATE,
                 g_flg_available,
                 i_rank,
                 i_id_cnt_external_cause);
        
            SELECT e.code_external_cause
              INTO l_cod_external_cause
              FROM external_cause e
             WHERE e.id_external_cause = l_external_cause;
        
            pk_translation.insert_into_translation(i_id_language, l_cod_external_cause, i_desc_external_cause);
        
        ELSIF i_action = g_flg_delete
        THEN
        
            UPDATE external_cause a
            
               SET flg_available = g_flg_no
             WHERE a.id_content = i_id_cnt_external_cause
               AND a.flg_available = g_flg_available;
        
        ELSIF i_action = g_flg_update
              AND l_external_cause > 0
        THEN
        
            UPDATE external_cause a
               SET rank = i_rank
             WHERE a.id_content = i_id_cnt_external_cause
               AND a.flg_available = g_flg_available;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            raise_application_error(-20001, SQLERRM);
            pk_alert_exceptions.process_error(i_id_language,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
        
    END set_external_cause;

    PROCEDURE set_diet
    (
        i_action                 VARCHAR,
        i_id_language            VARCHAR,
        i_id_cnt_diet            VARCHAR,
        i_id_cnt_diet_prt        VARCHAR,
        i_desc_diet              VARCHAR,
        i_id_institution         NUMBER,
        i_id_software            NUMBER,
        i_rank                   NUMBER,
        i_id_diet_type           NUMBER,
        i_quantity_default       NUMBER,
        i_id_unit_measure        NUMBER,
        i_energy_quantity_value  NUMBER,
        i_id_unit_measure_energy NUMBER
    ) IS
    
        l_cod_diet         diet.code_diet%TYPE;
        l_diet             NUMBER;
        l_diet_prt         NUMBER;
        l_diet_instit_soft NUMBER;
    
    BEGIN
    
        l_diet_instit_soft := 0;
    
        g_func_name := 'set_diet';
        SELECT nvl((SELECT id_diet
                     FROM diet a
                    WHERE a.id_content = i_id_cnt_diet
                      AND a.flg_available = g_flg_available),
                   0)
          INTO l_diet
          FROM dual;
    
        IF l_diet > 0
        THEN
            SELECT nvl((SELECT id_diet
                         FROM diet_instit_soft a
                        WHERE a.id_diet = l_diet
                          AND a.id_institution IN (0, i_id_institution)
                          AND a.id_software IN (0, i_id_software)
                          AND rownum = 1),
                       0)
              INTO l_diet_instit_soft
              FROM dual;
        END IF;
    
        IF i_id_cnt_diet_prt IS NOT NULL
        THEN
            SELECT nvl((SELECT id_diet
                         FROM diet a
                        WHERE a.id_content = i_id_cnt_diet_prt
                          AND a.flg_available = g_flg_available),
                       0)
              INTO l_diet_prt
              FROM dual;
        ELSE
            l_diet_prt := NULL;
        END IF;
    
        IF (i_action = g_flg_create OR i_action = g_flg_update)
           AND l_diet = 0
           AND (l_diet_prt > 0 OR l_diet_prt IS NULL)
           AND i_desc_diet IS NOT NULL
        THEN
            SELECT seq_diet.nextval
              INTO l_diet
              FROM dual;
        
            INSERT INTO diet
                (id_diet,
                 code_diet,
                 id_diet_parent,
                 flg_available,
                 adw_last_update,
                 rank,
                 id_diet_type,
                 id_content,
                 quantity_default,
                 id_unit_measure,
                 energy_quantity_value,
                 id_unit_measure_energy)
            VALUES
                (l_diet,
                 'DIET.CODE_DIET.' || l_diet,
                 l_diet_prt,
                 g_flg_available,
                 SYSDATE,
                 i_rank,
                 i_id_diet_type,
                 i_id_cnt_diet,
                 i_quantity_default,
                 i_id_unit_measure,
                 i_energy_quantity_value,
                 i_id_unit_measure_energy);
        
            SELECT e.code_diet
              INTO l_cod_diet
              FROM diet e
             WHERE e.id_diet = l_diet;
        
            pk_translation.insert_into_translation(i_id_language, l_cod_diet, i_desc_diet);
        
            INSERT INTO diet_instit_soft
                (id_diet, id_institution, flg_available, id_software)
            VALUES
                (l_diet, i_id_institution, g_flg_available, i_id_software);
        
        ELSIF i_action = g_flg_create
              AND l_diet > 0
              AND l_diet_instit_soft = 0
        THEN
        
            INSERT INTO diet_instit_soft
                (id_diet, id_institution, flg_available, id_software)
            VALUES
                (l_diet, i_id_institution, g_flg_available, i_id_software);
        
        ELSIF i_action = g_flg_update
              AND l_diet > 0
        THEN
        
            UPDATE diet
               SET rank                   = i_rank,
                   id_diet_type           = i_id_diet_type,
                   quantity_default       = i_quantity_default,
                   id_unit_measure        = i_id_unit_measure,
                   energy_quantity_value  = i_energy_quantity_value,
                   id_unit_measure_energy = i_id_unit_measure_energy,
                   id_diet_parent         = l_diet_prt
             WHERE id_diet = l_diet;
        
        ELSIF i_action = g_flg_delete
        THEN
        
            DELETE diet_instit_soft a
             WHERE a.id_diet = l_diet
               AND a.id_institution IN (i_id_institution, 0)
               AND a.id_software IN (i_id_software, 0);
        
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            raise_application_error(-20001, SQLERRM);
            pk_alert_exceptions.process_error(i_id_language,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
        
    END set_diet;

    PROCEDURE set_habit
    (
        i_action         VARCHAR,
        i_id_language    VARCHAR,
        i_id_cnt_habit   VARCHAR,
        i_desc_habit     VARCHAR,
        i_id_institution NUMBER,
        i_rank           NUMBER
    ) IS
    
        l_cod_habit habit.code_habit%TYPE;
        l_habit     NUMBER;
    
    BEGIN
        g_func_name := 'set_habit';
        SELECT nvl((SELECT id_habit
                     FROM habit a
                    WHERE a.id_content = i_id_cnt_habit
                      AND a.flg_available = g_flg_available),
                   0)
          INTO l_habit
          FROM dual;
    
        IF (i_action = g_flg_create OR i_action = g_flg_update)
           AND l_habit = 0
           AND i_desc_habit IS NOT NULL
        THEN
            SELECT seq_habit.nextval
              INTO l_habit
              FROM dual;
            INSERT INTO habit
                (id_habit, code_habit, flg_available, id_content, rank)
            VALUES
                (l_habit, 'HABIT.CODE_HABIT.' || l_habit, g_flg_available, i_id_cnt_habit, i_rank);
        
            SELECT e.code_habit
              INTO l_cod_habit
              FROM habit e
             WHERE e.id_habit = l_habit;
        
            pk_translation.insert_into_translation(i_id_language, l_cod_habit, i_desc_habit);
        
            INSERT INTO habit_inst
                (id_habit, id_institution, flg_available)
            VALUES
                (l_habit, i_id_institution, g_flg_available);
        
        ELSIF i_action = g_flg_create
              AND l_habit > 0
        THEN
        
            INSERT INTO habit_inst
                (id_habit, id_institution, flg_available)
            VALUES
                (l_habit, i_id_institution, g_flg_available);
        ELSIF i_action = g_flg_update
              AND l_habit > 0
        THEN
            UPDATE habit
               SET rank = i_rank
             WHERE id_content = i_id_cnt_habit;
        
        ELSIF i_action = g_flg_delete
        THEN
        
            DELETE habit_inst a
             WHERE a.id_habit = l_habit
               AND a.id_institution = i_id_institution;
        
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            raise_application_error(-20001, SQLERRM);
            pk_alert_exceptions.process_error(i_id_language,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
        
    END set_habit;

    PROCEDURE set_cancel_reason
    (
        i_action               VARCHAR,
        i_id_language          VARCHAR,
        i_desc_cancel_reason   VARCHAR,
        i_id_cnt_cancel_reason VARCHAR,
        i_flg_notes_mandatory  VARCHAR,
        i_rank                 NUMBER,
        i_id_reason_type       NUMBER
    ) IS
    
        l_cod_cancel_reason cancel_reason.code_cancel_reason%TYPE;
        l_cancel_reason     NUMBER;
    
    BEGIN
        g_func_name := 'set_cancel_reason';
        SELECT nvl((SELECT id_cancel_reason
                     FROM cancel_reason a
                    WHERE a.id_content = i_id_cnt_cancel_reason),
                   0)
          INTO l_cancel_reason
          FROM dual;
    
        IF (i_action = g_flg_create OR i_action = g_flg_update)
           AND l_cancel_reason = 0
           AND i_desc_cancel_reason IS NOT NULL
        THEN
            SELECT MAX(id_cancel_reason) + 1
              INTO l_cancel_reason
              FROM cancel_reason;
        
            INSERT INTO cancel_reason
                (id_cancel_reason, code_cancel_reason, id_content, flg_notes_mandatory, rank, id_reason_type)
            VALUES
                (l_cancel_reason,
                 'CANCEL_REASON.CODE_CANCEL_REASON.' || l_cancel_reason,
                 i_id_cnt_cancel_reason,
                 i_flg_notes_mandatory,
                 i_rank,
                 i_id_reason_type);
        
            SELECT e.code_cancel_reason
              INTO l_cod_cancel_reason
              FROM cancel_reason e
             WHERE e.id_cancel_reason = l_cancel_reason;
        
            pk_translation.insert_into_translation(i_id_language, l_cod_cancel_reason, i_desc_cancel_reason);
        
        ELSIF i_action = g_flg_update
              AND l_cancel_reason > 0
        THEN
            UPDATE cancel_reason
               SET rank = i_rank, flg_notes_mandatory = i_flg_notes_mandatory, id_reason_type = i_id_reason_type
             WHERE id_content = i_id_cnt_cancel_reason;
        
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            raise_application_error(-20001, SQLERRM);
            pk_alert_exceptions.process_error(i_id_language,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
        
    END set_cancel_reason;

    PROCEDURE set_cancel_reason_soft_inst
    (
        i_action               VARCHAR,
        i_id_language          VARCHAR,
        i_id_cnt_cancel_reason VARCHAR,
        i_id_institution       NUMBER,
        i_id_software          NUMBER,
        i_id_profile_template  NUMBER,
        i_rank                 NUMBER,
        i_id_cancel_rea_area   NUMBER
    ) IS
    
        l_cod_cancel_reason cancel_reason.code_cancel_reason%TYPE;
        l_cancel_reason     NUMBER;
    
    BEGIN
        g_func_name := 'set_cancel_reason';
        SELECT nvl((SELECT id_cancel_reason
                     FROM cancel_reason a
                    WHERE a.id_content = i_id_cnt_cancel_reason),
                   0)
          INTO l_cancel_reason
          FROM dual;
    
        IF i_action = g_flg_create
           AND l_cancel_reason > 0
        THEN
        
            INSERT INTO cancel_rea_soft_inst
                (id_cancel_reason,
                 id_profile_template,
                 id_software,
                 id_institution,
                 flg_available,
                 rank,
                 id_cancel_rea_area,
                 flg_error)
            VALUES
                (l_cancel_reason,
                 i_id_profile_template,
                 i_id_software,
                 i_id_institution,
                 g_flg_available,
                 i_rank,
                 i_id_cancel_rea_area,
                 'N');
        
        ELSIF i_action = g_flg_update
              AND l_cancel_reason > 0
        THEN
            UPDATE cancel_rea_soft_inst
               SET rank                = i_rank,
                   id_profile_template = i_id_profile_template,
                   id_cancel_rea_area  = i_id_cancel_rea_area
             WHERE id_cancel_reason = l_cancel_reason
               AND id_institution = i_id_institution
               AND id_software = i_id_software;
        
        ELSIF i_action = g_flg_delete
              AND l_cancel_reason > 0
        THEN
            DELETE FROM cancel_rea_soft_inst
             WHERE id_cancel_reason = l_cancel_reason
               AND id_institution = i_id_institution
               AND id_software = i_id_software
               AND id_profile_template = i_id_profile_template
               AND id_cancel_rea_area = i_id_cancel_rea_area;
        
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            raise_application_error(-20001, SQLERRM);
            pk_alert_exceptions.process_error(i_id_language,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
        
    END set_cancel_reason_soft_inst;

    PROCEDURE set_hab_characterization
    (
        i_action                      VARCHAR,
        i_id_language                 VARCHAR,
        i_id_cnt_hab_characterization VARCHAR,
        i_desc_hab_characterization   VARCHAR
    ) IS
    
        l_cod_habit_characterization habit_characterization.code_habit_characterization%TYPE;
        l_habit_characterization     NUMBER;
    
    BEGIN
        g_func_name := 'set_habit_characterization';
        SELECT nvl((SELECT id_habit_characterization
                     FROM habit_characterization a
                    WHERE a.id_content = i_id_cnt_hab_characterization
                      AND a.flg_available = g_flg_available),
                   0)
          INTO l_habit_characterization
          FROM dual;
    
        IF (i_action = g_flg_create OR i_action = g_flg_update)
           AND l_habit_characterization = 0
           AND i_desc_hab_characterization IS NOT NULL
        THEN
            SELECT seq_habit_characterization.nextval
              INTO l_habit_characterization
              FROM dual;
            INSERT INTO habit_characterization
                (id_habit_characterization, code_habit_characterization, flg_available, id_content)
            VALUES
                (l_habit_characterization,
                 'HABIT_CHARACTERIZATION.CODE_HABIT_CHARACTERIZATION.' || l_habit_characterization,
                 g_flg_available,
                 i_id_cnt_hab_characterization);
        
            SELECT e.code_habit_characterization
              INTO l_cod_habit_characterization
              FROM habit_characterization e
             WHERE e.id_habit_characterization = l_habit_characterization;
        
            pk_translation.insert_into_translation(i_id_language,
                                                   l_cod_habit_characterization,
                                                   i_desc_hab_characterization);
        
        ELSIF i_action = g_flg_delete
        THEN
        
            UPDATE habit_characterization a
               SET flg_available = g_flg_no
             WHERE a.id_content = i_id_cnt_hab_characterization
               AND a.flg_available = g_flg_available;
        
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            raise_application_error(-20001, SQLERRM);
            pk_alert_exceptions.process_error(i_id_language,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
        
    END set_hab_characterization;

    PROCEDURE set_procedure_category
    (
        i_action               VARCHAR,
        i_id_language          VARCHAR,
        i_id_cnt_procedure_cat VARCHAR,
        i_desc_procedure_cat   VARCHAR,
        i_rank                 NUMBER
    ) IS
    
        l_cod_procedure_cat   exam.code_exam%TYPE;
        l_procedure_cat       NUMBER;
        l_procedure_cat_inact NUMBER;
    
    BEGIN
        g_func_name := 'set_procedure_cat';
        SELECT nvl((SELECT id_interv_category
                     FROM interv_category a
                    WHERE a.id_content = i_id_cnt_procedure_cat
                      AND a.flg_available = g_flg_available),
                   0)
          INTO l_procedure_cat
          FROM dual;
    
        IF (i_action = g_flg_create OR i_action = g_flg_update)
           AND l_procedure_cat = 0
           AND i_desc_procedure_cat IS NOT NULL
        THEN
        
            SELECT nvl((SELECT id_interv_category
                         FROM interv_category a
                        WHERE a.id_content = i_id_cnt_procedure_cat
                          AND a.flg_available = g_flg_no),
                       0)
              INTO l_procedure_cat_inact
              FROM dual;
        
            IF l_procedure_cat_inact = 0
            THEN
                SELECT seq_interv_category.nextval
                  INTO l_procedure_cat
                  FROM dual;
            
                INSERT INTO interv_category
                    (id_interv_category, code_interv_category, adw_last_update, flg_available, rank, id_content)
                VALUES
                    (l_procedure_cat,
                     'INTERV_CATEGORY.CODE_INTERV_CATEGORY.' || l_procedure_cat,
                     SYSDATE,
                     g_flg_available,
                     i_rank,
                     i_id_cnt_procedure_cat);
            
                SELECT e.code_interv_category
                  INTO l_cod_procedure_cat
                  FROM interv_category e
                 WHERE e.id_interv_category = l_procedure_cat;
            
                pk_translation.insert_into_translation(i_id_language, l_cod_procedure_cat, i_desc_procedure_cat);
            ELSE
                UPDATE interv_category a
                   SET rank = i_rank, flg_available = g_flg_available
                 WHERE a.id_content = i_id_cnt_procedure_cat
                   AND a.flg_available = g_flg_no;
            END IF;
        
        ELSIF i_action = g_flg_create
              AND l_procedure_cat != 0
        THEN
        
            UPDATE interv_category a
               SET rank = i_rank
             WHERE a.id_content = i_id_cnt_procedure_cat
               AND a.flg_available = g_flg_available;
        
        ELSIF i_action = g_flg_delete
        THEN
        
            UPDATE interv_category a
               SET flg_available = g_flg_no
             WHERE a.id_content = i_id_cnt_procedure_cat
               AND a.flg_available = g_flg_available;
        
        ELSIF i_action = g_flg_update
              AND l_procedure_cat > 0
        THEN
        
            UPDATE interv_category a
               SET rank = i_rank
             WHERE a.id_content = i_id_cnt_procedure_cat
               AND a.flg_available = g_flg_available;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            raise_application_error(-20001, SQLERRM);
            pk_alert_exceptions.process_error(i_id_language,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
        
    END set_procedure_category;

    PROCEDURE set_hidrics
    (
        i_action          VARCHAR,
        i_id_language     VARCHAR,
        i_id_cnt_hidrics  VARCHAR,
        i_desc_hidrics    VARCHAR,
        i_flg_type        VARCHAR,
        i_flg_free_txt    VARCHAR,
        i_flg_nr_times    VARCHAR,
        i_id_unit_measure VARCHAR,
        i_gender          VARCHAR,
        i_age_max         VARCHAR,
        i_age_min         VARCHAR,
        i_rank            NUMBER
    ) IS
    
        l_cod_hidrics hidrics.code_hidrics%TYPE;
        l_hidrics     NUMBER;
    
    BEGIN
        g_func_name := 'set_hidrics';
        SELECT nvl((SELECT id_hidrics
                     FROM hidrics a
                    WHERE a.id_content = i_id_cnt_hidrics
                      AND a.flg_available = g_flg_available),
                   0)
          INTO l_hidrics
          FROM dual;
    
        IF (i_action = g_flg_create OR i_action = g_flg_update)
           AND l_hidrics = 0
           AND i_desc_hidrics IS NOT NULL
        THEN
            SELECT seq_hidrics.nextval
              INTO l_hidrics
              FROM dual;
            INSERT INTO hidrics
                (id_hidrics,
                 code_hidrics,
                 flg_type,
                 rank,
                 flg_available,
                 id_unit_measure,
                 id_content,
                 flg_gender,
                 age_min,
                 age_max,
                 flg_free_txt,
                 flg_nr_times)
            VALUES
                (l_hidrics,
                 'HIDRICS.CODE_HIDRICS.' || l_hidrics,
                 i_flg_type,
                 i_rank,
                 g_flg_available,
                 i_id_unit_measure,
                 i_id_cnt_hidrics,
                 i_gender,
                 i_age_min,
                 i_age_max,
                 i_flg_free_txt,
                 i_flg_nr_times);
        
            SELECT e.code_hidrics
              INTO l_cod_hidrics
              FROM hidrics e
             WHERE e.id_hidrics = l_hidrics;
        
            pk_translation.insert_into_translation(i_id_language, l_cod_hidrics, i_desc_hidrics);
        
        ELSIF i_action = g_flg_delete
        THEN
        
            UPDATE hidrics a
               SET flg_available = g_flg_no
             WHERE a.id_content = i_id_cnt_hidrics
               AND a.flg_available = g_flg_available;
        
        ELSIF i_action = g_flg_update
              AND l_hidrics > 0
        THEN
        
            UPDATE hidrics a
               SET flg_type        = i_flg_type,
                   flg_free_txt    = i_flg_free_txt,
                   flg_nr_times    = i_flg_nr_times,
                   id_unit_measure = i_id_unit_measure,
                   flg_gender      = i_gender,
                   age_max         = i_age_max,
                   age_min         = i_age_min,
                   rank            = i_rank
             WHERE a.id_content = i_id_cnt_hidrics
               AND a.flg_available = g_flg_available;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            raise_application_error(-20001, SQLERRM);
            pk_alert_exceptions.process_error(i_id_language,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
        
    END set_hidrics;

    PROCEDURE set_hidrics_device
    (
        i_action                VARCHAR,
        i_id_language           VARCHAR,
        i_id_cnt_hidrics_device VARCHAR,
        i_desc_hidrics_device   VARCHAR,
        i_flg_free_txt          VARCHAR
    ) IS
    
        l_cod_hidrics_device hidrics_device.code_hidrics_device%TYPE;
        l_hidrics_device     NUMBER;
    
    BEGIN
        g_func_name := 'set_hidrics_device';
        SELECT nvl((SELECT id_hidrics_device
                     FROM hidrics_device a
                    WHERE a.id_content = i_id_cnt_hidrics_device
                      AND a.flg_available = g_flg_available),
                   0)
          INTO l_hidrics_device
          FROM dual;
    
        IF i_action = g_flg_create
           AND l_hidrics_device = 0
           AND i_desc_hidrics_device IS NOT NULL
        THEN
            SELECT seq_hidrics_device.nextval
              INTO l_hidrics_device
              FROM dual;
            INSERT INTO hidrics_device
                (id_hidrics_device, code_hidrics_device, flg_available, flg_free_txt)
            VALUES
                (l_hidrics_device,
                 'HIDRICS_DEVICE.CODE_HIDRICS_DEVICE.' || l_hidrics_device,
                 g_flg_available,
                 i_flg_free_txt);
        
            SELECT e.code_hidrics_device
              INTO l_cod_hidrics_device
              FROM hidrics_device e
             WHERE e.id_hidrics_device = l_hidrics_device;
            pk_translation.insert_into_translation(i_id_language, l_cod_hidrics_device, i_desc_hidrics_device);
        
        ELSIF i_action = g_flg_delete
        THEN
        
            UPDATE hidrics_device a
               SET flg_available = g_flg_no
             WHERE a.id_content = i_id_cnt_hidrics_device
               AND a.flg_available = g_flg_available;
        
        ELSIF i_action = g_flg_update
        THEN
        
            UPDATE hidrics_device a
               SET flg_free_txt = i_flg_free_txt
             WHERE a.id_content = i_id_cnt_hidrics_device
               AND a.flg_available = g_flg_available;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            raise_application_error(-20001, SQLERRM);
            pk_alert_exceptions.process_error(i_id_language,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
        
    END set_hidrics_device;

    PROCEDURE set_hidrics_occurs_type
    (
        i_action                     VARCHAR,
        i_id_language                VARCHAR,
        i_id_cnt_hidrics_occurs_type VARCHAR,
        i_desc_hidrics_occurs_type   VARCHAR
    ) IS
    
        l_cod_hidrics_occurs_type hidrics_occurs_type.code_hidrics_occurs_type%TYPE;
        l_hidrics_occurs_type     NUMBER;
    
    BEGIN
        g_func_name := 'set_hidrics_occurs_type';
        SELECT nvl((SELECT id_hidrics_occurs_type
                     FROM hidrics_occurs_type a
                    WHERE a.id_content = i_id_cnt_hidrics_occurs_type
                      AND a.flg_available = g_flg_available),
                   0)
          INTO l_hidrics_occurs_type
          FROM dual;
    
        IF i_action = g_flg_create
           AND l_hidrics_occurs_type = 0
           AND i_desc_hidrics_occurs_type IS NOT NULL
        THEN
            SELECT seq_hidrics_occurs_type.nextval
              INTO l_hidrics_occurs_type
              FROM dual;
            INSERT INTO hidrics_occurs_type
                (id_hidrics_occurs_type, code_hidrics_occurs_type, flg_available)
            VALUES
                (l_hidrics_occurs_type,
                 'HIDRICS_OCCURS_TYPE.CODE_HIDRICS_OCCURS_TYPE.' || l_hidrics_occurs_type,
                 g_flg_available);
        
            SELECT e.code_hidrics_occurs_type
              INTO l_cod_hidrics_occurs_type
              FROM hidrics_occurs_type e
             WHERE e.id_hidrics_occurs_type = l_hidrics_occurs_type;
            pk_translation.insert_into_translation(i_id_language,
                                                   l_cod_hidrics_occurs_type,
                                                   i_desc_hidrics_occurs_type);
        
        ELSIF i_action = g_flg_delete
        THEN
        
            UPDATE hidrics_occurs_type a
               SET flg_available = g_flg_no
             WHERE a.id_content = i_id_cnt_hidrics_occurs_type
               AND a.flg_available = g_flg_available;
        
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            raise_application_error(-20001, SQLERRM);
            pk_alert_exceptions.process_error(i_id_language,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
        
    END set_hidrics_occurs_type;

    PROCEDURE set_hidrics_type
    (
        i_action                  VARCHAR,
        i_id_language             VARCHAR,
        i_id_cnt_hidrics_type     VARCHAR,
        i_desc_hidrics_type       VARCHAR,
        i_flg_ti_type             VARCHAR,
        i_id_cnt_hidrics_type_prt VARCHAR
    ) IS
    
        l_cod_hidrics_type hidrics_type.code_hidrics_type%TYPE;
        l_hidrics_type     NUMBER;
        l_hidrics_type_prt NUMBER := 0;
    BEGIN
        g_func_name := 'set_hidrics_type';
        SELECT nvl((SELECT id_hidrics_type
                     FROM hidrics_type a
                    WHERE a.id_content = i_id_cnt_hidrics_type
                      AND a.flg_available = g_flg_available),
                   0)
          INTO l_hidrics_type
          FROM dual;
    
        IF i_id_cnt_hidrics_type_prt IS NOT NULL
        THEN
            --if there is no content the process must fail
            SELECT id_hidrics_type
              INTO l_hidrics_type_prt
              FROM hidrics_type a
             WHERE a.id_content = i_id_cnt_hidrics_type_prt
               AND a.flg_available = g_flg_available;
        
        END IF;
    
        IF i_action = g_flg_create
           AND l_hidrics_type = 0
           AND i_desc_hidrics_type IS NOT NULL
        THEN
            SELECT seq_hidrics_type.nextval
              INTO l_hidrics_type
              FROM dual;
            INSERT INTO hidrics_type
                (id_hidrics_type, code_hidrics_type, flg_available, flg_ti_type, id_parent)
            VALUES
                (l_hidrics_type,
                 'HIDRICS_TYPE.CODE_HIDRICS_TYPE.' || l_hidrics_type,
                 g_flg_available,
                 i_flg_ti_type,
                 decode(l_hidrics_type_prt, 0, NULL, l_hidrics_type_prt));
        
            SELECT e.code_hidrics_type
              INTO l_cod_hidrics_type
              FROM hidrics_type e
             WHERE e.id_hidrics_type = l_hidrics_type;
            pk_translation.insert_into_translation(i_id_language, l_cod_hidrics_type, i_desc_hidrics_type);
        
        ELSIF i_action = g_flg_update
        THEN
        
            UPDATE hidrics_type a
               SET flg_available = g_flg_no,
                   flg_ti_type   = i_flg_ti_type,
                   id_parent     = decode(l_hidrics_type_prt, 0, NULL, l_hidrics_type_prt)
             WHERE a.id_content = i_id_cnt_hidrics_type
               AND a.flg_available = g_flg_available;
        
        ELSIF i_action = g_flg_delete
        THEN
        
            UPDATE hidrics_type a
               SET flg_available = g_flg_no
             WHERE a.id_content = i_id_cnt_hidrics_type
               AND a.flg_available = g_flg_available;
        
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            raise_application_error(-20001, SQLERRM);
            pk_alert_exceptions.process_error(i_id_language,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
        
    END set_hidrics_type;

    PROCEDURE set_way
    (
        i_action       VARCHAR,
        i_id_language  VARCHAR,
        i_id_cnt_way   VARCHAR,
        i_desc_way     VARCHAR,
        i_flg_type     VARCHAR,
        i_flg_way_type VARCHAR
    ) IS
    
        l_cod_way way.code_way%TYPE;
        l_way     NUMBER;
    BEGIN
        g_func_name := 'set_way';
    
        SELECT nvl((SELECT id_way
                     FROM way a
                    WHERE a.id_content = i_id_cnt_way
                      AND a.flg_available = g_flg_available),
                   0)
          INTO l_way
          FROM dual;
    
        IF (i_action = g_flg_create OR i_action = g_flg_update)
           AND l_way = 0
           AND i_desc_way IS NOT NULL
        THEN
        
            SELECT seq_way.nextval
              INTO l_way
              FROM dual;
        
            INSERT INTO way
                (id_way, code_way, flg_available, flg_type, flg_way_type)
            VALUES
                (l_way, 'WAY.CODE_WAY.' || l_way, g_flg_available, i_flg_type, i_flg_way_type);
        
            SELECT e.code_way
              INTO l_cod_way
              FROM way e
             WHERE e.id_way = l_way;
        
            pk_translation.insert_into_translation(i_id_language, l_cod_way, i_desc_way);
        
        ELSIF i_action = g_flg_update
              AND l_way > 0
        THEN
        
            UPDATE way a
               SET flg_available = g_flg_no, flg_type = i_flg_type, flg_way_type = i_flg_way_type
             WHERE a.id_content = i_id_cnt_way
               AND a.flg_available = g_flg_available;
        
        ELSIF i_action = g_flg_delete
        THEN
        
            UPDATE way a
               SET flg_available = g_flg_no
             WHERE a.id_content = i_id_cnt_way
               AND a.flg_available = g_flg_available;
        
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            raise_application_error(-20001, SQLERRM);
            pk_alert_exceptions.process_error(i_id_language,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
        
    END set_way;

    PROCEDURE set_hid_charact_rel
    (
        i_action                      VARCHAR,
        i_id_language                 VARCHAR,
        i_id_institution              NUMBER,
        i_id_cnt_way                  VARCHAR,
        i_id_cnt_hidrics              VARCHAR,
        i_id_cnt_hid_characterization VARCHAR,
        i_rank                        VARCHAR
    ) IS
    
        l_way             NUMBER;
        l_hidrics_charact NUMBER;
        l_hidrics         NUMBER;
    BEGIN
        g_func_name := 'set_hid_caract_rel';
        SELECT nvl((SELECT id_way
                     FROM way a
                    WHERE a.id_content = i_id_cnt_way
                      AND a.flg_available = g_flg_available),
                   0)
          INTO l_way
          FROM dual;
    
        SELECT nvl((SELECT id_hidrics
                     FROM hidrics a
                    WHERE a.id_content = i_id_cnt_hidrics
                      AND a.flg_available = g_flg_available),
                   0)
          INTO l_hidrics
          FROM dual;
    
        SELECT nvl((SELECT id_hidrics_charact
                     FROM hidrics_charact a
                    WHERE a.id_content = i_id_cnt_hid_characterization
                      AND a.flg_available = g_flg_available),
                   0)
          INTO l_hidrics_charact
          FROM dual;
    
        IF i_action = g_flg_create
        THEN
            INSERT INTO hidrics_charact_rel
                (id_hidrics,
                 id_hidrics_charact,
                 rank,
                 flg_available,
                 id_department,
                 id_dept,
                 id_institution,
                 id_way,
                 id_market)
            VALUES
                (l_hidrics, l_hidrics_charact, i_rank, g_flg_available, 0, 0, i_id_institution, l_way, 0);
        
        ELSIF i_action = g_flg_update
        THEN
        
            UPDATE hidrics_charact_rel
               SET rank = i_rank
             WHERE id_hidrics = l_hidrics
               AND id_hidrics_charact = l_hidrics_charact
               AND id_way = l_way
               AND id_institution = i_id_institution;
        
        ELSIF i_action = g_flg_delete
        THEN
            DELETE FROM hidrics_charact_rel
             WHERE id_hidrics = l_hidrics
               AND id_hidrics_charact = l_hidrics_charact
               AND id_way = l_way
               AND id_institution = i_id_institution;
        
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            raise_application_error(-20001, SQLERRM);
            pk_alert_exceptions.process_error(i_id_language,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
        
    END set_hid_charact_rel;

    PROCEDURE set_hid_device_rel
    (
        i_action                VARCHAR,
        i_id_language           VARCHAR,
        i_id_institution        NUMBER,
        i_id_cnt_way            VARCHAR,
        i_id_cnt_hidrics        VARCHAR,
        i_id_cnt_hidrics_device VARCHAR,
        i_rank                  VARCHAR
    ) IS
    
        l_way            NUMBER;
        l_hidrics_device NUMBER;
        l_hidrics        NUMBER;
    BEGIN
        g_func_name := 'set_hid_device_rel';
        SELECT nvl((SELECT id_way
                     FROM way a
                    WHERE a.id_content = i_id_cnt_way
                      AND a.flg_available = g_flg_available),
                   0)
          INTO l_way
          FROM dual;
    
        SELECT nvl((SELECT id_hidrics
                     FROM hidrics a
                    WHERE a.id_content = i_id_cnt_hidrics
                      AND a.flg_available = g_flg_available),
                   0)
          INTO l_hidrics
          FROM dual;
    
        SELECT nvl((SELECT id_hidrics_device
                     FROM hidrics_device a
                    WHERE a.id_content = i_id_cnt_hidrics_device
                      AND a.flg_available = g_flg_available),
                   0)
          INTO l_hidrics_device
          FROM dual;
    
        IF i_action = g_flg_create
        THEN
            INSERT INTO hidrics_device_rel
                (id_hidrics,
                 id_hidrics_device,
                 rank,
                 flg_available,
                 id_department,
                 id_dept,
                 id_institution,
                 id_way,
                 id_market)
            VALUES
                (l_hidrics, l_hidrics_device, i_rank, g_flg_available, 0, 0, i_id_institution, l_way, 0);
        
        ELSIF i_action = g_flg_update
        THEN
        
            UPDATE hidrics_device_rel
               SET rank = i_rank
             WHERE id_hidrics = l_hidrics
               AND id_hidrics_device = l_hidrics_device
               AND id_way = l_way
               AND id_institution = i_id_institution;
        
        ELSIF i_action = g_flg_delete
        THEN
            DELETE FROM hidrics_device_rel
             WHERE id_hidrics = l_hidrics
               AND id_hidrics_device = l_hidrics_device
               AND id_way = l_way
               AND id_institution = i_id_institution;
        
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            raise_application_error(-20001, SQLERRM);
            pk_alert_exceptions.process_error(i_id_language,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
        
    END set_hid_device_rel;

    PROCEDURE set_hid_location_rel
    (
        i_action           VARCHAR,
        i_id_language      VARCHAR,
        i_id_institution   NUMBER,
        i_id_cnt_way       VARCHAR,
        i_id_cnt_hidrics   VARCHAR,
        i_id_cnt_body_part VARCHAR,
        i_id_cnt_body_side VARCHAR,
        i_rank             VARCHAR
    ) IS
    
        l_way              NUMBER;
        l_body_part        NUMBER;
        l_body_side        NUMBER;
        l_hidrics          NUMBER;
        l_hidrics_location NUMBER;
    BEGIN
        g_func_name := 'set_hid_device_rel';
        SELECT nvl((SELECT id_way
                     FROM way a
                    WHERE a.id_content = i_id_cnt_way
                      AND a.flg_available = g_flg_available),
                   0)
          INTO l_way
          FROM dual;
    
        SELECT nvl((SELECT id_hidrics
                     FROM hidrics a
                    WHERE a.id_content = i_id_cnt_hidrics
                      AND a.flg_available = g_flg_available),
                   0)
          INTO l_hidrics
          FROM dual;
    
        SELECT nvl((SELECT a.id_body_part
                     FROM body_part a
                    WHERE a.id_content = i_id_cnt_body_part
                      AND a.flg_available = g_flg_available),
                   0)
          INTO l_body_part
          FROM dual;
    
        IF i_id_cnt_body_side IS NOT NULL
        THEN
            SELECT nvl((SELECT a.id_body_side
                         FROM body_side a
                        WHERE a.id_content = i_id_cnt_body_side),
                       0)
              INTO l_body_side
              FROM dual;
        
        ELSE
            l_body_side := NULL;
        
        END IF;
    
        SELECT nvl((SELECT a.id_hidrics_location
                     FROM hidrics_location a
                    WHERE a.id_body_part = l_body_part
                      AND (a.id_body_side = l_body_side OR (l_body_side IS NULL AND id_body_side IS NULL))
                      AND a.flg_available = g_flg_available),
                   0)
          INTO l_hidrics_location
          FROM dual;
    
        IF i_action = g_flg_create
           AND l_hidrics_location = 0
        THEN
        
            SELECT seq_hidrics_location.nextval
              INTO l_hidrics_location
              FROM dual;
            INSERT INTO hidrics_location
                (id_hidrics_location, id_body_side, id_body_part, flg_available)
            VALUES
                (l_hidrics_location, l_body_side, l_body_part, g_flg_available);
        
            INSERT INTO hidrics_location_rel
                (id_hidrics_location,
                 id_way,
                 id_hidrics,
                 rank,
                 flg_available,
                 id_department,
                 id_dept,
                 id_institution,
                 id_market)
            VALUES
                (l_hidrics_location, l_way, l_hidrics, i_rank, g_flg_available, 0, 0, i_id_institution, 0);
        
        ELSIF i_action = g_flg_create
              AND l_hidrics_location > 0
        THEN
            INSERT INTO hidrics_location_rel
                (id_hidrics_location,
                 id_way,
                 id_hidrics,
                 rank,
                 flg_available,
                 id_department,
                 id_dept,
                 id_institution,
                 id_market)
            VALUES
                (l_hidrics_location, l_way, l_hidrics, i_rank, g_flg_available, 0, 0, i_id_institution, 0);
        
        ELSIF i_action = g_flg_update
        THEN
        
            UPDATE hidrics_location_rel
               SET rank = i_rank
             WHERE id_hidrics = l_hidrics
               AND id_hidrics_location = l_hidrics_location
               AND id_way = l_way
               AND id_institution = i_id_institution;
        
        ELSIF i_action = g_flg_delete
        THEN
            DELETE FROM hidrics_location_rel
             WHERE id_hidrics = l_hidrics
               AND id_hidrics_location = l_hidrics_location
               AND id_way = l_way
               AND id_institution = i_id_institution;
        
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            raise_application_error(-20001, SQLERRM);
            pk_alert_exceptions.process_error(i_id_language,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
        
    END set_hid_location_rel;

    PROCEDURE set_hidrics_way_rel
    (
        i_action              VARCHAR,
        i_id_language         VARCHAR,
        i_id_institution      NUMBER,
        i_id_cnt_way          VARCHAR,
        i_id_cnt_hidrics      VARCHAR,
        i_id_cnt_hidrics_type VARCHAR,
        i_rank                VARCHAR
    ) IS
    
        l_way          NUMBER;
        l_hidrics_type NUMBER;
        l_hidrics      NUMBER;
    BEGIN
        g_func_name := 'set_hidrics_way_rel';
        SELECT nvl((SELECT id_way
                     FROM way a
                    WHERE a.id_content = i_id_cnt_way
                      AND a.flg_available = g_flg_available),
                   0)
          INTO l_way
          FROM dual;
    
        SELECT nvl((SELECT id_hidrics
                     FROM hidrics a
                    WHERE a.id_content = i_id_cnt_hidrics
                      AND a.flg_available = g_flg_available),
                   0)
          INTO l_hidrics
          FROM dual;
    
        SELECT nvl((SELECT id_hidrics_type
                     FROM hidrics_type a
                    WHERE a.id_content = i_id_cnt_hidrics_type
                      AND a.flg_available = g_flg_available),
                   0)
          INTO l_hidrics_type
          FROM dual;
    
        IF i_action = g_flg_create
        THEN
            INSERT INTO hidrics_way_rel
                (id_hidrics,
                 id_hidrics_type,
                 rank,
                 flg_available,
                 id_department,
                 id_dept,
                 id_institution,
                 id_way,
                 id_market)
            VALUES
                (l_hidrics, l_hidrics_type, i_rank, g_flg_available, 0, 0, i_id_institution, l_way, 0);
        
        ELSIF i_action = g_flg_update
        THEN
        
            UPDATE hidrics_way_rel
               SET rank = i_rank
             WHERE id_hidrics = l_hidrics
               AND id_hidrics_type = l_hidrics_type
               AND id_way = l_way
               AND id_institution = i_id_institution;
        
        ELSIF i_action = g_flg_delete
        THEN
            DELETE FROM hidrics_way_rel
             WHERE id_hidrics = l_hidrics
               AND id_hidrics_type = l_hidrics_type
               AND id_way = l_way
               AND id_institution = i_id_institution;
        
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            raise_application_error(-20001, SQLERRM);
            pk_alert_exceptions.process_error(i_id_language,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
        
    END set_hidrics_way_rel;

    PROCEDURE set_hidrics_configurations
    (
        i_action                     VARCHAR,
        i_id_language                VARCHAR,
        i_id_institution             NUMBER,
        i_id_hidrics_interval        VARCHAR,
        i_next_balance               VARCHAR,
        i_max_intake_warn_percentage VARCHAR
    ) IS
    
        l_hidrics_configurations NUMBER;
    BEGIN
        g_func_name := 'set_hidrics_configurations';
    
        IF i_action = g_flg_create
        THEN
            SELECT seq_hidrics_configurations.nextval
              INTO l_hidrics_configurations
              FROM dual;
            INSERT INTO hidrics_configurations
                (id_hidrics_configurations,
                 id_hidrics_interval,
                 id_institution,
                 id_department,
                 id_dept,
                 dt_def_next_balance,
                 almost_max_int,
                 id_market)
            VALUES
                (l_hidrics_configurations,
                 i_id_hidrics_interval,
                 i_id_institution,
                 0,
                 0,
                 i_next_balance,
                 i_max_intake_warn_percentage,
                 0);
        
        ELSIF i_action = g_flg_update
        THEN
            UPDATE hidrics_configurations
               SET dt_def_next_balance = i_next_balance, almost_max_int = i_max_intake_warn_percentage
             WHERE id_hidrics_interval = i_id_hidrics_interval
               AND id_institution = i_id_institution;
        
        ELSIF i_action = g_flg_delete
        THEN
            DELETE FROM hidrics_configurations
             WHERE id_hidrics_interval = i_id_hidrics_interval
               AND id_institution = i_id_institution;
        
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            raise_application_error(-20001, SQLERRM);
            pk_alert_exceptions.process_error(i_id_language,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
        
    END set_hidrics_configurations;
    PROCEDURE set_hid_occurs_type_rel
    (
        i_action                 VARCHAR,
        i_id_language            VARCHAR,
        i_id_institution         NUMBER,
        i_id_cnt_hidrics         VARCHAR,
        i_id_cnt_hid_occurs_type VARCHAR,
        i_rank                   VARCHAR
    ) IS
    
        l_hidrics_occurs_type NUMBER;
        l_hidrics             NUMBER;
    BEGIN
        g_func_name := 'set_hid_occurs_type_rel';
    
        SELECT nvl((SELECT id_hidrics
                     FROM hidrics a
                    WHERE a.id_content = i_id_cnt_hidrics
                      AND a.flg_available = g_flg_available),
                   0)
          INTO l_hidrics
          FROM dual;
    
        SELECT nvl((SELECT id_hidrics_occurs_type
                     FROM hidrics_occurs_type a
                    WHERE a.id_content = i_id_cnt_hid_occurs_type
                      AND a.flg_available = g_flg_available),
                   0)
          INTO l_hidrics_occurs_type
          FROM dual;
    
        IF i_action = g_flg_create
        THEN
            INSERT INTO hidrics_occurs_type_rel
                (id_hidrics,
                 id_hidrics_occurs_type,
                 rank,
                 flg_available,
                 id_department,
                 id_dept,
                 id_institution,
                 id_market)
            VALUES
                (l_hidrics, l_hidrics_occurs_type, i_rank, g_flg_available, 0, 0, i_id_institution, 0);
        
        ELSIF i_action = g_flg_update
        THEN
        
            UPDATE hidrics_occurs_type_rel
               SET rank = i_rank
             WHERE id_hidrics = l_hidrics
               AND id_hidrics_occurs_type = l_hidrics_occurs_type
               AND id_institution = i_id_institution;
        
        ELSIF i_action = g_flg_delete
        THEN
            DELETE FROM hidrics_occurs_type_rel
             WHERE id_hidrics = l_hidrics
               AND id_hidrics_occurs_type = l_hidrics_occurs_type
               AND id_institution = i_id_institution;
        
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            raise_application_error(-20001, SQLERRM);
            pk_alert_exceptions.process_error(i_id_language,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
        
    END set_hid_occurs_type_rel;

    PROCEDURE set_habit_charact_rel
    (
        i_action                      VARCHAR,
        i_id_language                 VARCHAR,
        i_id_cnt_habit                VARCHAR,
        i_id_cnt_hab_characterization VARCHAR
    ) IS
    
        l_id_cnt_hab_characterization NUMBER;
        l_id_cnt_habit                NUMBER;
    BEGIN
        g_func_name := 'set_habit_charact_rel';
    
        SELECT nvl((SELECT id_habit
                     FROM habit a
                    WHERE a.id_content = i_id_cnt_habit
                      AND a.flg_available = g_flg_available),
                   0)
          INTO l_id_cnt_habit
          FROM dual;
    
        SELECT nvl((SELECT a.id_habit_characterization
                     FROM habit_characterization a
                    WHERE a.id_content = i_id_cnt_hab_characterization
                      AND a.flg_available = g_flg_available),
                   0)
          INTO l_id_cnt_hab_characterization
          FROM dual;
    
        IF i_action = g_flg_create
        THEN
            INSERT INTO habit_charact_relation
                (id_habit_characterization, id_habit, flg_available)
            VALUES
                (l_id_cnt_hab_characterization, l_id_cnt_habit, g_flg_available);
        
        ELSIF i_action = g_flg_delete
        THEN
            DELETE FROM habit_charact_relation
             WHERE id_habit_characterization = l_id_cnt_hab_characterization
               AND id_habit = l_id_cnt_habit;
        
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            raise_application_error(-20001, SQLERRM);
            pk_alert_exceptions.process_error(i_id_language,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
        
    END set_habit_charact_rel;

    PROCEDURE set_lab_test_cat
    (
        i_action              VARCHAR,
        i_id_language         VARCHAR,
        i_id_cnt_lab_test_cat VARCHAR,
        i_id_institution      NUMBER,
        i_id_software         NUMBER,
        i_desc_lab_cat        VARCHAR,
        i_rank                NUMBER
    ) IS
    
        l_cod_exam_cat exam.code_exam%TYPE;
        l_exam_cat     NUMBER;
    
    BEGIN
        g_func_name := 'set_lab_test_cat';
    
        SELECT nvl((SELECT a.id_exam_cat
                     FROM exam_cat a
                    WHERE a.id_content = i_id_cnt_lab_test_cat
                      AND a.flg_available = g_flg_available),
                   0)
          INTO l_exam_cat
          FROM dual;
    
        IF (i_action = g_flg_create OR i_action = g_flg_update)
           AND l_exam_cat = 0
           AND i_desc_lab_cat IS NOT NULL
        THEN
            SELECT seq_exam_cat.nextval
              INTO l_exam_cat
              FROM dual;
        
            INSERT INTO exam_cat
                (id_exam_cat, code_exam_cat, adw_last_update, flg_available, flg_lab, rank, id_content)
            VALUES
                (l_exam_cat,
                 'EXAM_CAT.CODE_EXAM_CAT.' || l_exam_cat,
                 SYSDATE,
                 g_flg_available,
                 g_cat_lab,
                 i_rank,
                 i_id_cnt_lab_test_cat);
        
            IF i_desc_lab_cat IS NOT NULL
            THEN
                SELECT e.code_exam_cat
                  INTO l_cod_exam_cat
                  FROM exam_cat e
                 WHERE e.id_exam_cat = l_exam_cat;
                pk_translation.insert_into_translation(i_id_language, l_cod_exam_cat, i_desc_lab_cat);
            
            END IF;
        
            INSERT /*+ ignore_row_on_dupkey_index(exam_cat_dcs ECC_PK) */
            INTO exam_cat_dcs
                (id_exam_cat_dcs, id_exam_cat, id_dep_clin_serv)
                SELECT seq_exam_cat_dcs.nextval, l_exam_cat, c.id_dep_clin_serv
                  FROM clinical_service a
                  JOIN dep_clin_serv c
                    ON c.id_clinical_service = a.id_clinical_service
                  JOIN department d
                    ON d.id_department = c.id_department
                  JOIN dept de
                    ON de.id_dept = d.id_dept
                  JOIN software_dept sd
                    ON sd.id_dept = de.id_dept
                  JOIN institution i
                    ON i.id_institution = d.id_institution
                   AND i.id_institution = de.id_institution
                 WHERE d.id_institution IN (i_id_institution)
                   AND sd.id_software IN (i_id_software)
                   AND d.flg_available = g_flg_available
                   AND a.flg_available = g_flg_available;
        
        ELSIF i_action = g_flg_delete
        THEN
        
            UPDATE exam_cat a
               SET flg_available = g_flg_no
             WHERE a.id_content = i_id_cnt_lab_test_cat
               AND a.flg_available = g_flg_available;
        
        ELSIF i_action = g_flg_update
              AND l_exam_cat > 0
        THEN
        
            UPDATE exam_cat a
               SET rank = i_rank
             WHERE a.id_content = i_id_cnt_lab_test_cat
               AND a.flg_available = g_flg_available;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            raise_application_error(-20001, SQLERRM);
            pk_alert_exceptions.process_error(i_id_language,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
        
    END set_lab_test_cat;

    PROCEDURE set_clinical_question
    (
        i_id_language              NUMBER,
        i_action                   VARCHAR,
        i_id_cnt_clinical_question VARCHAR,
        i_desc_clinical_question   VARCHAR,
        i_gender                   VARCHAR,
        i_age_max                  VARCHAR,
        i_age_min                  VARCHAR
    ) IS
    
        l_questionnaire NUMBER;
    
    BEGIN
    
        g_func_name := 'set_clinical_question';
        SELECT nvl((SELECT id_questionnaire
                   
                     FROM questionnaire qr
                    WHERE qr.id_content = i_id_cnt_clinical_question
                      AND qr.flg_available = g_flg_available),
                   0)
          INTO l_questionnaire
          FROM dual;
    
        IF l_questionnaire = 0
           AND (i_action = g_flg_create OR i_action = g_flg_update)
           AND i_desc_clinical_question IS NOT NULL
        THEN
            SELECT seq_questionnaire.nextval
              INTO l_questionnaire
              FROM dual;
        
            INSERT INTO questionnaire
                (id_questionnaire, code_questionnaire, id_content, flg_available, gender, age_min, age_max)
            VALUES
                (l_questionnaire,
                 'QUESTIONNAIRE.CODE_QUESTIONNAIRE.' || l_questionnaire,
                 i_id_cnt_clinical_question,
                 g_flg_available,
                 i_gender,
                 i_age_min,
                 i_age_max);
        
            pk_translation.insert_into_translation(i_id_language,
                                                   'QUESTIONNAIRE.CODE_QUESTIONNAIRE.' || l_questionnaire,
                                                   i_desc_clinical_question);
        
        ELSIF i_action = g_flg_update
              AND l_questionnaire > 0
        THEN
        
            UPDATE questionnaire q
               SET q.gender = i_gender, q.age_min = i_age_min, q.age_max = i_age_max
             WHERE q.id_questionnaire = l_questionnaire;
        
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            raise_application_error(-20001, SQLERRM);
            pk_alert_exceptions.process_error(i_id_language,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
    END;

    PROCEDURE set_response
    (
        i_id_language     NUMBER,
        i_action          VARCHAR,
        i_id_cnt_response VARCHAR,
        i_desc_response   VARCHAR,
        i_gender          VARCHAR,
        i_age_max         VARCHAR,
        i_age_min         VARCHAR,
        i_flg_free_text   VARCHAR
    ) IS
    
        l_response NUMBER;
    
    BEGIN
    
        g_func_name := 'set_response';
    
        SELECT nvl((SELECT id_response
                     FROM response qr
                    WHERE qr.id_content = i_id_cnt_response
                      AND qr.flg_available = g_flg_available),
                   0)
          INTO l_response
          FROM dual;
    
        IF l_response = 0
           AND (i_action = g_flg_create OR i_action = g_flg_update)
           AND i_desc_response IS NOT NULL
        THEN
        
            SELECT seq_response.nextval
              INTO l_response
              FROM dual;
        
            INSERT INTO response
                (id_response,
                 code_response,
                 id_content,
                 flg_available,
                 
                 flg_free_text,
                 gender,
                 age_min,
                 age_max)
            VALUES
                (l_response,
                 'RESPONSE.CODE_RESPONSE.' || l_response,
                 i_id_cnt_response,
                 g_flg_available,
                 i_flg_free_text,
                 i_gender,
                 i_age_min,
                 i_age_max);
        
            pk_translation.insert_into_translation(i_id_language,
                                                   'RESPONSE.CODE_RESPONSE.' || l_response,
                                                   i_desc_response);
        
        ELSIF i_action = g_flg_update
              AND l_response > 0
        THEN
        
            UPDATE response r
               SET r.gender = i_gender, r.age_min = i_age_min, r.age_max = i_age_max, r.flg_free_text = i_flg_free_text
             WHERE r.id_response = l_response;
        
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            raise_application_error(-20001, SQLERRM);
            pk_alert_exceptions.process_error(i_id_language,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
    END;

    PROCEDURE set_question_response
    (
        i_id_language                  NUMBER,
        i_action                       VARCHAR,
        i_id_cnt_clinical_question     VARCHAR,
        i_id_cnt_response              VARCHAR,
        i_id_cnt_question_response     VARCHAR,
        i_rank                         VARCHAR,
        i_id_cnt_question_response_prt VARCHAR
    ) IS
    
        l_questionnaire_response NUMBER;
        l_questionnaire          NUMBER;
        l_questionnaire_prt      NUMBER;
        l_response_prt           NUMBER;
        l_response               NUMBER;
    
    BEGIN
    
        g_func_name := 'set_question_response';
    
        SELECT COUNT(*)
          INTO l_questionnaire_response
          FROM questionnaire_response qr
         WHERE qr.id_content = i_id_cnt_question_response;
    
        SELECT nvl((SELECT id_questionnaire
                   
                     FROM questionnaire qr
                    WHERE qr.id_content = i_id_cnt_clinical_question
                      AND qr.flg_available = g_flg_available),
                   0)
          INTO l_questionnaire
          FROM dual;
    
        SELECT nvl((SELECT id_response
                     FROM response qr
                    WHERE qr.id_content = i_id_cnt_response
                      AND qr.flg_available = g_flg_available),
                   0)
          INTO l_response
          FROM dual;
    
        IF l_questionnaire_response = 0
           AND l_questionnaire > 0
           AND l_response > 0
           AND (i_action = g_flg_create OR i_action = g_flg_update)
        THEN
            IF i_id_cnt_question_response_prt IS NOT NULL
            THEN
                SELECT qr.id_questionnaire, qr.id_response
                  INTO l_questionnaire_prt, l_response_prt
                  FROM questionnaire_response qr
                 WHERE qr.id_content = i_id_cnt_question_response_prt;
            ELSE
                l_questionnaire_prt := NULL;
                l_response_prt      := NULL;
            END IF;
            INSERT INTO questionnaire_response
                (id_questionnaire,
                 id_response,
                 id_content,
                 rank,
                 flg_available,
                 id_questionnaire_parent,
                 id_response_parent)
            VALUES
                (l_questionnaire,
                 l_response,
                 i_id_cnt_question_response,
                 i_rank,
                 g_flg_available,
                 l_questionnaire_prt,
                 l_response_prt);
        
        ELSIF i_action = g_flg_update
              AND l_questionnaire_response > 0
        THEN
        
            SELECT qr.id_questionnaire, qr.id_response
              INTO l_questionnaire, l_response
              FROM questionnaire_response qr
             WHERE qr.id_content = i_id_cnt_question_response
               AND flg_available = g_flg_available;
        
            IF i_id_cnt_question_response_prt IS NOT NULL
            THEN
                SELECT qr.id_questionnaire, qr.id_response
                  INTO l_questionnaire_prt, l_response_prt
                  FROM questionnaire_response qr
                 WHERE qr.id_content = i_id_cnt_question_response_prt;
            ELSE
                l_questionnaire_prt := NULL;
                l_response_prt      := NULL;
            END IF;
        
            UPDATE questionnaire_response qr
               SET qr.rank                    = i_rank,
                   qr.id_questionnaire_parent = l_questionnaire_prt,
                   qr.id_response_parent      = l_response_prt
             WHERE qr.id_content = i_id_cnt_question_response
               AND flg_available = g_flg_available;
        
        ELSIF i_action = g_flg_delete
        THEN
        
            UPDATE questionnaire_response qr
               SET flg_available = g_flg_no
             WHERE qr.id_content = i_id_cnt_question_response
               AND flg_available = g_flg_available;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            raise_application_error(-20001, SQLERRM);
            pk_alert_exceptions.process_error(i_id_language,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
    END;

    PROCEDURE set_lab_test_recipient
    (
        i_action                       VARCHAR,
        i_id_language                  VARCHAR,
        i_id_institution               NUMBER,
        i_id_software                  NUMBER,
        i_id_cnt_sample_recipient      VARCHAR,
        i_id_cnt_lab_test_sample_type  VARCHAR,
        i_flg_default                  VARCHAR,
        i_id_analysis_instit_recipient VARCHAR
    ) IS
        l_id_analysis                  NUMBER;
        l_id_sample_type               NUMBER;
        l_id_sample_recipient          NUMBER;
        l_bool                         BOOLEAN;
        l_ids                          table_number;
        l_status                       table_varchar;
        l_id_analysis_instit_recipient NUMBER := i_id_analysis_instit_recipient;
        l_error                        VARCHAR2(4000);
    
        l_id_analysis_instit_soft NUMBER;
    BEGIN
        g_func_name := 'set_lab_test_recipient';
    
        l_bool := validate_content(i_id_language,
                                   i_id_institution,
                                   table_varchar(i_id_cnt_sample_recipient,
                                                 i_id_cnt_lab_test_sample_type,
                                                 i_id_cnt_lab_test_sample_type),
                                   table_varchar('SAMPLE_RECIPIENT',
                                                 'LAB_TEST_SAMPLE_TYPE (LABTEST)',
                                                 'LAB_TEST_SAMPLE_TYPE (SAMPLE_TYPE)'),
                                   table_number(1, 1, 1),
                                   l_ids,
                                   l_status);
    
        l_id_sample_recipient := l_ids(1);
        l_id_analysis         := l_ids(2);
        l_id_sample_type      := l_ids(3);
    
        SELECT nvl((SELECT a.id_analysis_instit_soft
                     FROM analysis_instit_soft a
                    WHERE a.id_analysis = l_id_analysis
                      AND a.id_sample_type = l_id_sample_type
                      AND a.id_institution = i_id_institution
                      AND a.id_software = i_id_software
                      AND a.flg_type = g_flg_searchable),
                   0)
          INTO l_id_analysis_instit_soft
          FROM dual;
    
        IF l_id_analysis_instit_soft > 0
        THEN
        
            IF i_action = g_flg_create
            THEN
            
                IF i_flg_default = g_flg_available
                THEN
                    DELETE FROM analysis_instit_recipient
                     WHERE id_analysis_instit_soft = l_id_analysis_instit_soft
                       AND flg_default = g_flg_available;
                END IF;
            
                INSERT /*+ ignore_row_on_dupkey_index(airr AIR_UK) */
                INTO analysis_instit_recipient
                    (id_analysis_instit_recipient,
                     id_analysis_instit_soft,
                     id_sample_recipient,
                     flg_default,
                     id_room,
                     qty_harvest,
                     num_recipient)
                    SELECT seq_analysis_instit_recipient.nextval,
                           l_id_analysis_instit_soft,
                           l_id_sample_recipient,
                           i_flg_default,
                           NULL,
                           NULL,
                           NULL
                      FROM dual
                     WHERE NOT EXISTS (SELECT 1
                              FROM analysis_instit_recipient
                             WHERE id_analysis_instit_soft = l_id_analysis_instit_soft
                               AND id_sample_recipient = l_id_sample_recipient)
                       AND NOT EXISTS (SELECT 1
                              FROM analysis_instit_recipient
                             WHERE id_analysis_instit_soft = l_id_analysis_instit_soft
                               AND flg_default = g_flg_available);
            
                --criar tambem no soft de lab
            
                INSERT /*+ ignore_row_on_dupkey_index(ais AIS_UK) */
                INTO analysis_instit_soft ais
                    (id_analysis_instit_soft,
                     id_analysis,
                     flg_type,
                     id_institution,
                     id_software,
                     flg_mov_pat,
                     flg_first_result,
                     flg_mov_recipient,
                     flg_harvest,
                     id_exam_cat,
                     rank,
                     cost,
                     price,
                     adw_last_update,
                     id_analysis_group,
                     flg_execute,
                     flg_justify,
                     flg_interface,
                     flg_chargeable,
                     flg_available,
                     create_user,
                     create_time,
                     create_institution,
                     update_user,
                     update_time,
                     update_institution,
                     flg_duplicate_warn,
                     flg_collection_author,
                     id_sample_type,
                     flg_category_type,
                     flg_priority,
                     harvest_instructions)
                    SELECT seq_analysis_instit_soft.nextval AS id_analysis_instit_soft,
                           id_analysis,
                           flg_type,
                           id_institution,
                           g_lab_technician                 AS id_software,
                           flg_mov_pat,
                           flg_first_result,
                           flg_mov_recipient,
                           flg_harvest,
                           id_exam_cat,
                           rank,
                           cost,
                           price,
                           adw_last_update,
                           id_analysis_group,
                           flg_execute,
                           flg_justify,
                           flg_interface,
                           flg_chargeable,
                           flg_available,
                           create_user,
                           create_time,
                           create_institution,
                           update_user,
                           update_time,
                           update_institution,
                           flg_duplicate_warn,
                           flg_collection_author,
                           id_sample_type,
                           flg_category_type,
                           flg_priority,
                           harvest_instructions
                      FROM analysis_instit_soft a
                     WHERE a.id_analysis = l_id_analysis
                       AND a.id_sample_type = l_id_sample_type
                       AND a.id_institution = i_id_institution
                       AND a.id_software = i_id_software
                       AND a.flg_type = g_flg_searchable
                       AND a.flg_available = g_flg_available;
            
                SELECT nvl((SELECT a.id_analysis_instit_soft
                             FROM analysis_instit_soft a
                            WHERE a.id_analysis = l_id_analysis
                              AND a.id_sample_type = l_id_sample_type
                              AND a.id_institution = i_id_institution
                              AND a.id_software = g_lab_technician
                              AND a.flg_type = g_flg_searchable),
                           0)
                  INTO l_id_analysis_instit_soft
                  FROM dual;
            
                IF i_flg_default = g_flg_available
                THEN
                    DELETE FROM analysis_instit_recipient
                     WHERE id_analysis_instit_soft = l_id_analysis_instit_soft
                       AND flg_default = g_flg_available;
                END IF;
            
                INSERT /*+ ignore_row_on_dupkey_index(airr AIR_UK) */
                INTO analysis_instit_recipient
                    (id_analysis_instit_recipient,
                     id_analysis_instit_soft,
                     id_sample_recipient,
                     flg_default,
                     id_room,
                     qty_harvest,
                     num_recipient)
                    SELECT seq_analysis_instit_recipient.nextval,
                           l_id_analysis_instit_soft,
                           l_id_sample_recipient,
                           i_flg_default,
                           NULL,
                           NULL,
                           NULL
                      FROM dual
                     WHERE NOT EXISTS (SELECT 1
                              FROM analysis_instit_recipient
                             WHERE id_analysis_instit_soft = l_id_analysis_instit_soft
                               AND id_sample_recipient = l_id_sample_recipient)
                       AND NOT EXISTS (SELECT 1
                              FROM analysis_instit_recipient
                             WHERE id_analysis_instit_soft = l_id_analysis_instit_soft
                               AND flg_default = g_flg_available);
            
            ELSIF i_action = g_flg_update
                  AND l_id_analysis_instit_recipient IS NOT NULL
            THEN
            
                IF i_flg_default = g_flg_available
                THEN
                
                    UPDATE analysis_instit_recipient a
                       SET flg_default = 'N'
                     WHERE a.id_analysis_instit_recipient = l_id_analysis_instit_recipient;
                
                END IF;
            
                UPDATE analysis_instit_recipient a
                   SET flg_default = i_flg_default, id_sample_recipient = l_id_sample_recipient
                 WHERE a.id_analysis_instit_recipient = l_id_analysis_instit_recipient;
            
                --update tambem no soft de lab
            
                INSERT /*+ ignore_row_on_dupkey_index(ais AIS_UK) */
                INTO analysis_instit_soft ais
                    (id_analysis_instit_soft,
                     id_analysis,
                     flg_type,
                     id_institution,
                     id_software,
                     flg_mov_pat,
                     flg_first_result,
                     flg_mov_recipient,
                     flg_harvest,
                     id_exam_cat,
                     rank,
                     cost,
                     price,
                     adw_last_update,
                     id_analysis_group,
                     flg_execute,
                     flg_justify,
                     flg_interface,
                     flg_chargeable,
                     flg_available,
                     create_user,
                     create_time,
                     create_institution,
                     update_user,
                     update_time,
                     update_institution,
                     flg_duplicate_warn,
                     flg_collection_author,
                     id_sample_type,
                     flg_category_type,
                     flg_priority,
                     harvest_instructions)
                    SELECT seq_analysis_instit_soft.nextval AS id_analysis_instit_soft,
                           id_analysis,
                           flg_type,
                           id_institution,
                           g_lab_technician                 AS id_software,
                           flg_mov_pat,
                           flg_first_result,
                           flg_mov_recipient,
                           flg_harvest,
                           id_exam_cat,
                           rank,
                           cost,
                           price,
                           adw_last_update,
                           id_analysis_group,
                           flg_execute,
                           flg_justify,
                           flg_interface,
                           flg_chargeable,
                           flg_available,
                           create_user,
                           create_time,
                           create_institution,
                           update_user,
                           update_time,
                           update_institution,
                           flg_duplicate_warn,
                           flg_collection_author,
                           id_sample_type,
                           flg_category_type,
                           flg_priority,
                           harvest_instructions
                      FROM analysis_instit_soft a
                     WHERE a.id_analysis = l_id_analysis
                       AND a.id_sample_type = l_id_sample_type
                       AND a.id_institution = i_id_institution
                       AND a.id_software = i_id_software
                       AND a.flg_type = g_flg_searchable
                       AND a.flg_available = g_flg_available;
            
                SELECT nvl((SELECT a.id_analysis_instit_soft
                             FROM analysis_instit_soft a
                            WHERE a.id_analysis = l_id_analysis
                              AND a.id_sample_type = l_id_sample_type
                              AND a.id_institution = i_id_institution
                              AND a.id_software = g_lab_technician
                              AND a.flg_type = g_flg_searchable),
                           0)
                  INTO l_id_analysis_instit_soft
                  FROM dual;
            
                INSERT /*+ ignore_row_on_dupkey_index(airr AIR_UK) */
                INTO analysis_instit_recipient
                    (id_analysis_instit_recipient,
                     id_analysis_instit_soft,
                     id_sample_recipient,
                     flg_default,
                     id_room,
                     qty_harvest,
                     num_recipient)
                    SELECT seq_analysis_instit_recipient.nextval,
                           l_id_analysis_instit_soft,
                           l_id_sample_recipient,
                           i_flg_default,
                           NULL,
                           NULL,
                           NULL
                      FROM dual
                     WHERE NOT EXISTS (SELECT 1
                              FROM analysis_instit_recipient
                             WHERE id_analysis_instit_soft = l_id_analysis_instit_soft
                               AND id_sample_recipient = l_id_sample_recipient)
                       AND NOT EXISTS (SELECT 1
                              FROM analysis_instit_recipient
                             WHERE id_analysis_instit_soft = l_id_analysis_instit_soft
                               AND flg_default = g_flg_available);
            
                SELECT id_analysis_instit_recipient
                  INTO l_id_analysis_instit_recipient
                  FROM analysis_instit_recipient
                 WHERE id_analysis_instit_soft IN
                       (SELECT id_analysis_instit_soft
                          FROM analysis_instit_soft
                         WHERE id_software = g_lab_technician
                           AND (id_analysis, id_sample_type, id_institution, flg_type) IN
                               (SELECT id_analysis, id_sample_type, id_institution, flg_type
                                  FROM analysis_instit_soft
                                 WHERE id_analysis_instit_soft IN
                                       (SELECT id_analysis_instit_soft
                                          FROM analysis_instit_recipient
                                         WHERE id_analysis_instit_recipient = l_id_analysis_instit_recipient)));
            
                IF i_flg_default = g_flg_available
                THEN
                
                    UPDATE analysis_instit_recipient a
                       SET flg_default = 'N'
                     WHERE a.id_analysis_instit_recipient = l_id_analysis_instit_recipient;
                
                END IF;
            
                UPDATE analysis_instit_recipient a
                   SET flg_default = i_flg_default, id_sample_recipient = l_id_sample_recipient
                 WHERE a.id_analysis_instit_recipient = l_id_analysis_instit_recipient;
            
            ELSIF i_action = g_flg_delete
            THEN
                DELETE FROM analysis_instit_recipient a
                 WHERE a.id_analysis_instit_soft = l_id_analysis_instit_soft
                   AND id_sample_recipient = l_id_sample_recipient;
            END IF;
        
        ELSE
            l_error := 'Activate the labtest before associating a recipient!';
            RAISE g_exception;
        
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            raise_application_error(-20001, nvl(l_error, SQLERRM));
            pk_alert_exceptions.process_error(i_id_language,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
    END;

    PROCEDURE set_lab_test_recipient
    (
        i_id_language         VARCHAR,
        i_id_institution      NUMBER,
        i_id_software         NUMBER,
        i_id_sample_recipient NUMBER,
        i_id_lab_test         NUMBER,
        i_id_sample_type      NUMBER,
        i_flg_default         VARCHAR
    ) IS
        l_id_analysis_instit_soft      NUMBER;
        l_id_analysis_instit_recipient NUMBER;
    BEGIN
        g_func_name := 'set_lab_test_recipient';
    
        SELECT a.id_analysis_instit_soft
          INTO l_id_analysis_instit_soft
          FROM analysis_instit_soft a
         WHERE a.id_analysis = i_id_lab_test
           AND a.id_sample_type = i_id_sample_type
           AND a.id_institution = i_id_institution
           AND a.id_software = i_id_software
           AND a.flg_type = g_flg_searchable;
    
        SELECT nvl((SELECT a.id_analysis_instit_recipient
                     FROM analysis_instit_recipient a
                    WHERE a.id_analysis_instit_soft = l_id_analysis_instit_soft
                      AND a.id_sample_recipient = i_id_sample_recipient
                      AND a.flg_default = i_flg_default),
                   0)
          INTO l_id_analysis_instit_recipient
          FROM dual;
    
        IF l_id_analysis_instit_recipient = 0
        THEN
        
            DELETE FROM analysis_instit_recipient
             WHERE id_analysis_instit_soft = l_id_analysis_instit_soft
               AND flg_default = g_flg_available;
        
            INSERT INTO analysis_instit_recipient
                (id_analysis_instit_recipient,
                 id_analysis_instit_soft,
                 id_sample_recipient,
                 flg_default,
                 id_room,
                 qty_harvest,
                 num_recipient)
            VALUES
                (seq_analysis_instit_recipient.nextval,
                 l_id_analysis_instit_soft,
                 i_id_sample_recipient,
                 i_flg_default,
                 NULL,
                 NULL,
                 NULL);
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            raise_application_error(-20001, SQLERRM);
            pk_alert_exceptions.process_error(i_id_language,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
    END;

    PROCEDURE set_lab_test_param
    (
        i_action                      VARCHAR,
        i_id_language                 VARCHAR,
        i_id_institution              NUMBER,
        i_id_software                 NUMBER,
        i_id_cnt_lab_test_parameter   VARCHAR,
        i_id_cnt_lab_test_sample_type VARCHAR,
        i_rank                        NUMBER,
        i_flg_fill_type               VARCHAR
    ) IS
        l_id_analysis           NUMBER;
        l_id_sample_type        NUMBER;
        l_id_analysis_parameter NUMBER;
    BEGIN
        g_func_name := 'set_lab_test_param';
        BEGIN
            SELECT a.id_analysis, a.id_sample_type
              INTO l_id_analysis, l_id_sample_type
              FROM analysis_sample_type a
             WHERE id_content = i_id_cnt_lab_test_sample_type
               AND a.flg_available = g_flg_available;
        
        EXCEPTION
            WHEN OTHERS THEN
                l_id_analysis    := 0;
                l_id_sample_type := 0;
        END;
    
        SELECT nvl((SELECT a.id_analysis_parameter
                     FROM analysis_parameter a
                    WHERE a.id_content = i_id_cnt_lab_test_parameter
                      AND a.flg_available = g_flg_available),
                   0)
          INTO l_id_analysis_parameter
          FROM dual;
    
        IF l_id_analysis > 0
           AND l_id_sample_type > 0
           AND l_id_analysis_parameter > 0
        THEN
        
            IF i_action = g_flg_create
            THEN
            
                BEGIN
                    INSERT INTO analysis_param
                        (id_analysis_param,
                         id_analysis,
                         flg_available,
                         adw_last_update,
                         id_institution,
                         id_software,
                         id_analysis_parameter,
                         rank,
                         color_graph,
                         flg_fill_type,
                         id_sample_type)
                    VALUES
                        (seq_analysis_param.nextval,
                         l_id_analysis,
                         g_flg_available,
                         SYSDATE,
                         i_id_institution,
                         i_id_software,
                         l_id_analysis_parameter,
                         i_rank,
                         NULL,
                         i_flg_fill_type,
                         l_id_sample_type);
                
                EXCEPTION
                    WHEN dup_val_on_index THEN
                    
                        UPDATE analysis_param a
                           SET flg_fill_type = i_flg_fill_type
                         WHERE a.id_analysis_parameter = l_id_analysis_parameter
                           AND a.id_institution = i_id_institution
                           AND a.id_software = i_id_software
                           AND a.id_analysis = l_id_analysis
                           AND a.id_sample_type = l_id_sample_type;
                    
                END;
            
            ELSIF i_action = g_flg_update
            THEN
            
                UPDATE analysis_param a
                   SET rank = i_rank, flg_fill_type = i_flg_fill_type
                 WHERE a.id_analysis_parameter = l_id_analysis_parameter
                   AND a.id_institution = i_id_institution
                   AND a.id_software = i_id_software
                   AND a.id_analysis = l_id_analysis
                   AND a.id_sample_type = l_id_sample_type;
            
            ELSIF i_action = g_flg_delete
            THEN
            
                DELETE analysis_param_funcionality b
                 WHERE b.id_analysis_param IN (SELECT a.id_analysis_param
                                                 FROM analysis_param a
                                                WHERE a.id_analysis_parameter = l_id_analysis_parameter
                                                  AND a.id_institution = i_id_institution
                                                  AND a.id_software = i_id_software
                                                  AND a.id_analysis = l_id_analysis
                                                  AND a.id_sample_type = l_id_sample_type);
            
                DELETE analysis_param a
                 WHERE a.id_analysis_parameter = l_id_analysis_parameter
                   AND a.id_institution = i_id_institution
                   AND a.id_software = i_id_software
                   AND a.id_analysis = l_id_analysis
                   AND a.id_sample_type = l_id_sample_type;
            END IF;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            raise_application_error(-20001, SQLERRM);
            pk_alert_exceptions.process_error(i_id_language,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
    END;

    PROCEDURE set_lab_test_param
    (
        i_id_language           VARCHAR,
        i_id_institution        NUMBER,
        i_id_software           NUMBER,
        i_id_lab_test_parameter NUMBER,
        i_id_lab_test           NUMBER,
        i_id_sample_type        NUMBER,
        i_rank                  NUMBER,
        i_flg_fill_type         VARCHAR
    ) IS
    BEGIN
        g_func_name := 'set_lab_test_param';
    
        BEGIN
            INSERT INTO analysis_param
                (id_analysis_param,
                 id_analysis,
                 flg_available,
                 adw_last_update,
                 id_institution,
                 id_software,
                 id_analysis_parameter,
                 rank,
                 color_graph,
                 flg_fill_type,
                 id_sample_type)
            VALUES
                (seq_analysis_param.nextval,
                 i_id_lab_test,
                 g_flg_available,
                 SYSDATE,
                 i_id_institution,
                 i_id_software,
                 i_id_lab_test_parameter,
                 i_rank,
                 NULL,
                 i_flg_fill_type,
                 i_id_sample_type);
        
        EXCEPTION
            WHEN dup_val_on_index THEN
            
                UPDATE analysis_param a
                   SET flg_fill_type = i_flg_fill_type
                 WHERE a.id_analysis_parameter = i_id_lab_test_parameter
                   AND a.id_institution = i_id_institution
                   AND a.id_software = i_id_software
                   AND a.id_analysis = i_id_lab_test
                   AND a.id_sample_type = i_id_sample_type;
            
        END;
    
    EXCEPTION
        WHEN OTHERS THEN
            raise_application_error(-20001, SQLERRM);
            pk_alert_exceptions.process_error(i_id_language,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
    END;

    PROCEDURE set_complaint_ctlg
    (
        i_action           VARCHAR,
        i_id_language      VARCHAR,
        i_id_cnt_complaint VARCHAR,
        i_desc_complaint   VARCHAR
    ) IS
    
        l_cod_complaint    complaint.code_complaint%TYPE;
        l_complaint        NUMBER;
        l_error            VARCHAR2(4000);
        l_bool             BOOLEAN;
        l_ids              table_number;
        l_status           table_varchar;
        l_complaint_status VARCHAR2(1);
    
    BEGIN
        g_func_name := 'set_complaint_ctlg';
    
        l_bool := validate_content(i_id_language,
                                   NULL,
                                   table_varchar(i_id_cnt_complaint),
                                   table_varchar('COMPLAINT'),
                                   table_number(0),
                                   l_ids,
                                   l_status);
    
        l_complaint        := l_ids(1);
        l_complaint_status := l_status(1);
    
        IF (i_action = g_flg_create OR i_action = g_flg_update)
           AND l_complaint = 0
           AND i_desc_complaint IS NOT NULL
        THEN
        
            validate_description_exists(i_id_language, i_desc_complaint, 'COMPLAINT', 'ALERT', 'CODE_COMPLAINT');
        
            SELECT seq_complaint.nextval
              INTO l_complaint
              FROM dual;
        
            INSERT INTO complaint
                (id_complaint, code_complaint, id_content, rank, flg_available)
            VALUES
                (l_complaint, 'COMPLAINT.CODE_COMPLAINT.' || l_complaint, i_id_cnt_complaint, 10, g_flg_available);
        
            SELECT e.code_complaint
              INTO l_cod_complaint
              FROM complaint e
             WHERE e.id_complaint = l_complaint;
        
            pk_translation.insert_into_translation(i_id_language, l_cod_complaint, i_desc_complaint);
        
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            raise_application_error(-20001, SQLERRM);
            pk_alert_exceptions.process_error(i_id_language,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
        
    END;

    PROCEDURE set_complaint_alias
    (
        i_action                 VARCHAR,
        i_id_language            VARCHAR,
        i_id_cnt_complaint       VARCHAR,
        i_id_cnt_complaint_alias VARCHAR,
        i_desc_complaint_alias   VARCHAR
    ) IS
    
        l_error               VARCHAR2(4000);
        l_bool                BOOLEAN;
        l_ids                 table_number;
        l_status              table_varchar;
        l_id_complaint        NUMBER;
        l_id_complaint_alias  NUMBER;
        l_cod_complaint_alias complaint_alias.code_complaint_alias%TYPE;
    
    BEGIN
        g_func_name := 'set_complaint_alias';
    
        BEGIN
            l_bool := validate_content(i_id_language,
                                       NULL,
                                       table_varchar(i_id_cnt_complaint, i_id_cnt_complaint_alias),
                                       table_varchar('COMPLAINT', 'COMPLAINT_ALIAS'),
                                       table_number(1, 0),
                                       l_ids,
                                       l_status);
        
            l_id_complaint       := l_ids(1);
            l_id_complaint_alias := l_ids(2);
        END;
    
        IF (i_action = g_flg_create OR i_action = g_flg_update)
           AND l_id_complaint_alias = 0
           AND i_desc_complaint_alias IS NOT NULL
        THEN
        
            validate_description_exists(i_id_language,
                                        i_desc_complaint_alias,
                                        'COMPLAINT_ALIAS',
                                        'ALERT',
                                        'CODE_COMPLAINT_ALIAS');
        
            SELECT seq_complaint_alias.nextval
              INTO l_id_complaint_alias
              FROM dual;
        
            INSERT INTO complaint_alias
                (id_complaint, id_complaint_alias, code_complaint_alias, id_content, flg_available)
            VALUES
                (l_id_complaint,
                 l_id_complaint_alias,
                 'COMPLAINT_ALIAS.CODE_COMPLAINT_ALIAS.' || l_id_complaint_alias,
                 i_id_cnt_complaint_alias,
                 g_flg_available);
        
            SELECT e.code_complaint_alias
              INTO l_cod_complaint_alias
              FROM complaint_alias e
             WHERE e.id_complaint = l_id_complaint
               AND e.id_complaint_alias = l_id_complaint_alias;
        
            pk_translation.insert_into_translation(i_id_language, l_cod_complaint_alias, i_desc_complaint_alias);
        
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            raise_application_error(-20001, nvl(l_error, SQLERRM));
            pk_alert_exceptions.process_error(i_id_language,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
        
    END;

    PROCEDURE set_complaint_avlb
    (
        i_action                 VARCHAR,
        i_id_language            VARCHAR,
        i_id_institution         NUMBER,
        i_id_software            NUMBER,
        i_id_cnt_complaint       VARCHAR,
        i_id_cnt_complaint_alias VARCHAR,
        i_rank                   NUMBER DEFAULT 10,
        i_gender                 VARCHAR,
        i_age_max                NUMBER,
        i_age_min                NUMBER
    ) IS
    
        l_error              VARCHAR2(4000);
        l_bool               BOOLEAN;
        l_ids                table_number;
        l_status             table_varchar;
        l_id_complaint       NUMBER;
        l_id_complaint_alias NUMBER;
    
    BEGIN
        g_func_name := 'set_complaint_avlb';
    
        BEGIN
            l_bool := validate_content(i_id_language,
                                       NULL,
                                       table_varchar(i_id_cnt_complaint),
                                       table_varchar('COMPLAINT'),
                                       table_number(1),
                                       l_ids,
                                       l_status);
        
            l_id_complaint := l_ids(1);
        END;
    
        IF i_id_cnt_complaint_alias IS NOT NULL
        THEN
        
            SELECT *
              INTO l_id_complaint_alias
              FROM (SELECT a.id_complaint_alias
                      FROM complaint_alias a
                     WHERE a.id_content = i_id_cnt_complaint_alias)
             WHERE rownum = 1;
        
        END IF;
    
        IF i_action = g_flg_create
        THEN
        
            INSERT /*+ ignore_row_on_dupkey_index(cis CIS_UK) */
            INTO complaint_inst_soft cis
                (id_complaint,
                 id_institution,
                 id_software,
                 rank,
                 flg_available,
                 flg_gender,
                 age_max,
                 age_min,
                 id_complaint_alias)
            VALUES
                (l_id_complaint,
                 i_id_institution,
                 i_id_software,
                 i_rank,
                 g_flg_available,
                 i_gender,
                 i_age_max,
                 i_age_min,
                 l_id_complaint_alias);
        
        ELSIF i_action = g_flg_update
        THEN
        
            BEGIN
            
                UPDATE complaint_inst_soft
                   SET rank          = i_rank,
                       flg_available = g_flg_available,
                       flg_gender    = i_gender,
                       age_max       = i_age_max,
                       age_min       = i_age_min
                 WHERE id_complaint = l_id_complaint
                   AND id_software = i_id_software
                   AND id_institution = i_id_institution
                   AND ((id_complaint_alias IS NULL AND i_id_cnt_complaint_alias IS NULL) OR
                       (id_complaint_alias = l_id_complaint_alias AND i_id_cnt_complaint_alias IS NOT NULL));
            
            EXCEPTION
                WHEN dup_val_on_index THEN
                    NULL;
            END;
        
        ELSIF i_action = g_flg_delete
        THEN
        
            DELETE complaint_inst_soft
             WHERE id_complaint = l_id_complaint
               AND id_software = i_id_software
               AND id_institution = i_id_institution
               AND ((id_complaint_alias IS NULL AND i_id_cnt_complaint_alias IS NULL) OR
                   (id_complaint_alias = l_id_complaint_alias AND i_id_cnt_complaint_alias IS NOT NULL));
        
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            raise_application_error(-20001, nvl(l_error, SQLERRM));
            pk_alert_exceptions.process_error(i_id_language,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
    END;

    PROCEDURE set_lab_test_room
    (
        i_action                      VARCHAR,
        i_id_language                 VARCHAR,
        i_id_institution              NUMBER,
        i_id_room                     NUMBER,
        i_flg_type                    VARCHAR,
        i_id_cnt_lab_test_sample_type VARCHAR,
        i_rank                        NUMBER,
        i_flg_default                 VARCHAR,
        i_id_record                   NUMBER
    ) IS
        l_id_analysis    NUMBER;
        l_id_sample_type NUMBER;
        l_bool           BOOLEAN;
        l_ids            table_number;
        l_status         table_varchar;
    
    BEGIN
    
        IF (g_func_name = 'set_lab_test_sample_type_avlb')
        THEN
            g_func_name := 'set_lab_test_room';
        ELSE
            g_func_name := 'set_lab_test_room';
            l_bool      := validate_content(i_id_language,
                                            i_id_institution,
                                            table_varchar(i_id_room),
                                            table_varchar('ROOM'),
                                            table_number(1),
                                            l_ids,
                                            l_status);
        END IF;
    
        BEGIN
            SELECT a.id_analysis, a.id_sample_type
              INTO l_id_analysis, l_id_sample_type
              FROM analysis_sample_type a
             WHERE id_content = i_id_cnt_lab_test_sample_type
               AND a.flg_available = g_flg_available;
        
        EXCEPTION
            WHEN OTHERS THEN
                l_id_analysis    := 0;
                l_id_sample_type := 0;
        END;
    
        IF l_id_analysis > 0
           AND l_id_sample_type > 0
        THEN
        
            IF i_action = g_flg_create
            THEN
            
                INSERT /*+ ignore_row_on_dupkey_index(ar ARM_UK) */
                INTO analysis_room ar
                    (id_analysis_room,
                     id_analysis,
                     id_room,
                     rank,
                     adw_last_update,
                     flg_type,
                     flg_available,
                     desc_exec_destination,
                     flg_default,
                     id_institution,
                     id_sample_type,
                     id_analysis_instit_soft)
                VALUES
                    (seq_analysis_room.nextval,
                     l_id_analysis,
                     i_id_room,
                     i_rank,
                     SYSDATE,
                     i_flg_type,
                     g_flg_available,
                     NULL,
                     i_flg_default,
                     i_id_institution,
                     l_id_sample_type,
                     NULL);
            ELSIF i_action = g_flg_update
            THEN
            
                UPDATE analysis_room a
                   SET rank = i_rank, a.flg_default = i_flg_default, a.id_room = i_id_room
                 WHERE a.flg_type = i_flg_type
                   AND a.id_institution = i_id_institution
                   AND a.id_analysis = l_id_analysis
                   AND a.id_sample_type = l_id_sample_type
                   AND a.id_analysis_room = i_id_record;
            
            ELSIF i_action = g_flg_delete
            THEN
                DELETE FROM analysis_room a
                 WHERE a.flg_type = i_flg_type
                   AND a.id_institution = i_id_institution
                   AND a.id_room = i_id_room
                   AND a.id_analysis = l_id_analysis
                   AND a.id_sample_type = l_id_sample_type
                   AND a.id_analysis_room = i_id_record;
            ELSIF i_action = g_flg_update_create
            THEN
            
                DELETE FROM analysis_room a
                 WHERE flg_default = g_flg_available
                   AND a.id_analysis = l_id_analysis
                   AND a.id_sample_type = l_id_sample_type
                   AND a.flg_type = i_flg_type
                   AND a.id_analysis_instit_soft IS NULL
                   AND a.id_institution = i_id_institution;
            
                INSERT INTO analysis_room ar
                    (id_analysis_room,
                     id_analysis,
                     id_room,
                     rank,
                     adw_last_update,
                     flg_type,
                     flg_available,
                     desc_exec_destination,
                     flg_default,
                     id_institution,
                     id_sample_type,
                     id_analysis_instit_soft)
                VALUES
                    (seq_analysis_room.nextval,
                     l_id_analysis,
                     i_id_room,
                     i_rank,
                     SYSDATE,
                     i_flg_type,
                     g_flg_available,
                     NULL,
                     i_flg_default,
                     i_id_institution,
                     l_id_sample_type,
                     NULL);
            
            END IF;
        
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            raise_application_error(-20001, SQLERRM);
            pk_alert_exceptions.process_error(i_id_language,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
    END;

    PROCEDURE set_lab_test_room
    (
        i_id_language    VARCHAR,
        i_id_institution NUMBER,
        i_id_room        NUMBER,
        i_flg_type       VARCHAR,
        i_id_lab_test    NUMBER,
        i_id_sample_type NUMBER,
        i_rank           NUMBER,
        i_flg_default    VARCHAR
    ) IS
        l_id_analysis_room NUMBER;
        l_bool             BOOLEAN;
        l_ids              table_number;
        l_status           table_varchar;
    
    BEGIN
    
        IF (g_func_name = 'set_lab_test_sample_type_avlb')
        THEN
            g_func_name := 'set_lab_test_room';
        ELSE
            g_func_name := 'set_lab_test_room';
            l_bool      := validate_content(i_id_language,
                                            i_id_institution,
                                            table_varchar(i_id_room),
                                            table_varchar('ROOM'),
                                            table_number(1),
                                            l_ids,
                                            l_status);
        END IF;
    
        SELECT nvl((SELECT a.id_analysis_room
                     FROM analysis_room a
                    WHERE a.flg_type = i_flg_type
                      AND a.id_institution = i_id_institution
                      AND a.id_room = i_id_room
                      AND a.id_analysis = i_id_lab_test
                      AND a.id_sample_type = i_id_sample_type
                      AND a.flg_default = i_flg_default),
                   0)
          INTO l_id_analysis_room
          FROM dual;
    
        IF l_id_analysis_room = 0
        THEN
        
            DELETE FROM analysis_room a
             WHERE a.flg_type = i_flg_type
               AND a.id_institution = i_id_institution
               AND a.flg_default = i_flg_default
               AND a.id_analysis = i_id_lab_test
               AND a.id_sample_type = i_id_sample_type;
        
            DELETE FROM analysis_room a
             WHERE a.flg_type = i_flg_type
               AND a.id_institution = i_id_institution
               AND a.id_room = i_id_room
               AND a.id_analysis = i_id_lab_test
               AND a.id_sample_type = i_id_sample_type;
        
            INSERT INTO analysis_room ar
                (id_analysis_room,
                 id_analysis,
                 id_room,
                 rank,
                 adw_last_update,
                 flg_type,
                 flg_available,
                 desc_exec_destination,
                 flg_default,
                 id_institution,
                 id_sample_type,
                 id_analysis_instit_soft)
            VALUES
                (seq_analysis_room.nextval,
                 i_id_lab_test,
                 i_id_room,
                 i_rank,
                 SYSDATE,
                 i_flg_type,
                 g_flg_available,
                 NULL,
                 i_flg_default,
                 i_id_institution,
                 i_id_sample_type,
                 NULL);
        
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            raise_application_error(-20001, SQLERRM);
        
            pk_alert_exceptions.process_error(i_id_language,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
    END;

    PROCEDURE set_lab_test_parameter
    (
        i_action                    VARCHAR,
        i_id_language               VARCHAR,
        i_desc_lab_test_parameter   VARCHAR,
        i_id_cnt_lab_test_parameter VARCHAR
    ) IS
        l_id_analysis_parameter NUMBER;
    BEGIN
        g_func_name := 'set_lab_test_parameter';
        SELECT nvl((SELECT a.id_analysis_parameter
                     FROM analysis_parameter a
                    WHERE a.id_content = i_id_cnt_lab_test_parameter
                      AND a.flg_available = g_flg_available),
                   0)
          INTO l_id_analysis_parameter
          FROM dual;
    
        IF (i_action = g_flg_create OR i_action = g_flg_update)
           AND i_desc_lab_test_parameter IS NOT NULL
           AND l_id_analysis_parameter = 0
        THEN
        
            SELECT seq_analysis_parameter.nextval
              INTO l_id_analysis_parameter
              FROM dual;
        
            INSERT INTO analysis_parameter
                (id_analysis_parameter, code_analysis_parameter, adw_last_update, rank, flg_available, id_content)
            VALUES
                (l_id_analysis_parameter,
                 'ANALYSIS_PARAMETER.CODE_ANALYSIS_PARAMETER.',
                 SYSDATE,
                 g_rank_zero,
                 g_flg_available,
                 i_id_cnt_lab_test_parameter);
        
            pk_translation.insert_into_translation(i_id_language,
                                                   'ANALYSIS_PARAMETER.CODE_ANALYSIS_PARAMETER.' ||
                                                   l_id_analysis_parameter,
                                                   i_desc_lab_test_parameter);
        
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            raise_application_error(-20001, SQLERRM);
            pk_alert_exceptions.process_error(i_id_language,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
    END;

    PROCEDURE set_transportation
    (
        i_action                 VARCHAR,
        i_id_language            NUMBER,
        i_id_institution         NUMBER,
        i_desc_transportation    VARCHAR,
        i_id_cnt_transportation  VARCHAR,
        i_flg_doctor_admin       VARCHAR,
        i_flg_arrival_departure  VARCHAR,
        i_flg_discharge_transfer VARCHAR
    ) IS
        l_id_transp NUMBER;
    
    BEGIN
        g_func_name := 'set_transportation';
        SELECT nvl((SELECT a.id_transp_entity
                     FROM transp_entity a
                    WHERE a.id_content = i_id_cnt_transportation
                      AND a.flg_available = g_flg_available),
                   0)
          INTO l_id_transp
          FROM dual;
    
        IF i_action = g_flg_create
           AND i_desc_transportation IS NOT NULL
           AND l_id_transp = 0
        THEN
        
            SELECT seq_transp_entity.nextval
              INTO l_id_transp
              FROM dual;
        
            INSERT INTO transp_entity
                (id_transp_entity,
                 code_transp_entity,
                 rank,
                 adw_last_update,
                 flg_type,
                 id_institution,
                 flg_transp,
                 flg_available,
                 id_content)
            VALUES
                (l_id_transp,
                 'TRANSP_ENTITY.CODE_TRANSP_ENTITY.' || l_id_transp,
                 g_rank_zero,
                 SYSDATE,
                 i_flg_doctor_admin,
                 0,
                 i_flg_arrival_departure,
                 g_flg_available,
                 i_id_cnt_transportation);
        
            pk_translation.insert_into_translation(i_id_language,
                                                   'TRANSP_ENTITY.CODE_TRANSP_ENTITY.' || l_id_transp,
                                                   i_desc_transportation);
        
            INSERT INTO transp_ent_inst
                (id_institution, id_transp_ent_inst, id_transp_entity, flg_available, flg_type)
            VALUES
                (i_id_institution, seq_transp_ent_inst.nextval, l_id_transp, g_flg_available, i_flg_discharge_transfer);
        
        ELSIF i_action = g_flg_create
              AND l_id_transp != 0
        THEN
        
            INSERT INTO transp_ent_inst
                (id_institution, id_transp_ent_inst, id_transp_entity, flg_available, flg_type)
            VALUES
                (i_id_institution, seq_transp_ent_inst.nextval, l_id_transp, g_flg_available, i_flg_discharge_transfer);
        
        ELSIF i_action = g_flg_update
        THEN
            UPDATE transp_ent_inst
               SET flg_type = i_flg_discharge_transfer
             WHERE id_transp_entity = l_id_transp
               AND id_institution = i_id_institution;
        
            UPDATE transp_entity
               SET flg_type = i_flg_doctor_admin, flg_transp = i_flg_arrival_departure
             WHERE id_transp_entity = l_id_transp
               AND id_institution = i_id_institution;
        
        ELSIF i_action = g_flg_delete
        THEN
            UPDATE transp_ent_inst
               SET flg_available = g_flg_no
             WHERE id_transp_entity = l_id_transp
               AND id_institution = i_id_institution;
        
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            raise_application_error(-20001, SQLERRM);
            pk_alert_exceptions.process_error(i_id_language,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
    END;

    PROCEDURE set_trans_sys_message_cp
    (
        i_action          VARCHAR,
        i_id_language     NUMBER,
        i_id_institution  NUMBER,
        i_code_message    VARCHAR,
        i_module          VARCHAR,
        i_target_language VARCHAR
    ) IS
        l_flg_type    VARCHAR2(10);
        l_software    NUMBER;
        l_lang_dest   NUMBER;
        l_lang_source NUMBER;
    
    BEGIN
        g_func_name := 'set_trans_sys_message_cp';
    
        SELECT id_lang_dest
          INTO l_lang_dest
          FROM alert_core_data.cmt_user_trans_languages
         WHERE username = sys_context('ALERT_CONTEXT', 'CMT_USERNAME');
    
        SELECT id_lang_source
          INTO l_lang_source
          FROM alert_core_data.cmt_user_trans_languages
         WHERE username = sys_context('ALERT_CONTEXT', 'CMT_USERNAME');
    
        IF i_module IS NULL
        THEN
            SELECT DISTINCT flg_type, id_software
              INTO l_flg_type, l_software
              FROM sys_message a
             WHERE a.code_message = i_code_message
               AND a.flg_available = g_flg_available
               AND module IS NULL
               AND id_institution = 0
               AND id_language = l_lang_source;
        ELSE
        
            SELECT DISTINCT flg_type, id_software
              INTO l_flg_type, l_software
              FROM sys_message a
             WHERE a.code_message = i_code_message
               AND a.flg_available = g_flg_available
               AND module = i_module
               AND id_institution = 0
               AND id_language = l_lang_source;
        
        END IF;
    
        IF (i_action = g_flg_create OR i_action = g_flg_update)
           AND i_target_language IS NOT NULL
        THEN
        
            pk_message.insert_into_sys_message(i_lang         => l_lang_dest,
                                               i_code_message => i_code_message,
                                               i_desc_message => i_target_language,
                                               i_flg_type     => l_flg_type,
                                               i_software     => l_software,
                                               i_institution  => 0);
        
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            raise_application_error(-20001, SQLERRM);
            pk_alert_exceptions.process_error(i_id_language,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
    END;

    PROCEDURE set_trans_sys_message_mt
    (
        i_action         VARCHAR,
        i_id_language    NUMBER,
        i_id_institution NUMBER,
        i_code_message   VARCHAR,
        i_module         VARCHAR,
        i_portuguese_pt  VARCHAR,
        i_english_us     VARCHAR,
        i_spanish_es     VARCHAR,
        i_italian_it     VARCHAR,
        i_french_fr      VARCHAR,
        i_english_uk     VARCHAR,
        i_english_sa     VARCHAR,
        i_portuguese_br  VARCHAR,
        i_chinese_zh_cn  VARCHAR,
        i_chinese_zh_tw  VARCHAR,
        i_arabic_ar_sa   VARCHAR,
        i_spanish_cl     VARCHAR,
        i_spanish_mx     VARCHAR,
        i_french_ch      VARCHAR,
        i_portuguese_ao  VARCHAR,
        i_czech_cz       VARCHAR,
        i_portuguese_mz  VARCHAR
    ) IS
        l_flg_type        VARCHAR2(10);
        l_software        NUMBER;
        l_source_language NUMBER;
        l_dest_langs      VARCHAR2(300);
        l_desc_message    VARCHAR(32767);
    
    BEGIN
        g_func_name := 'set_trans_sys_message_mt';
    
        SELECT substr(id_lang_dest, 2, length(id_lang_dest) - 2), id_lang_source
          INTO l_dest_langs, l_source_language
          FROM alert_core_data.cmt_user_trans_languages
         WHERE username = sys_context('ALERT_CONTEXT', 'CMT_USERNAME');
    
        IF i_module IS NULL
        THEN
            SELECT DISTINCT flg_type, id_software
              INTO l_flg_type, l_software
              FROM sys_message a
             WHERE a.code_message = i_code_message
               AND a.flg_available = g_flg_available
               AND module IS NULL
               AND id_institution = 0
               AND id_language = l_source_language;
        ELSE
        
            SELECT DISTINCT flg_type, id_software
              INTO l_flg_type, l_software
              FROM sys_message a
             WHERE a.code_message = i_code_message
               AND a.flg_available = g_flg_available
               AND module = i_module
               AND id_institution = 0
               AND id_language = l_source_language;
        
        END IF;
    
        IF (i_action = g_flg_create OR i_action = g_flg_update)
        THEN
        
            FOR i IN (SELECT column_value
                        FROM TABLE(pk_utils.str_split(l_dest_langs, ':')))
            LOOP
            
                CASE
                    WHEN i.column_value = 1 THEN
                        l_desc_message := i_portuguese_pt;
                    WHEN i.column_value = 2 THEN
                        l_desc_message := i_english_us;
                    WHEN i.column_value = 3 THEN
                        l_desc_message := i_spanish_es;
                    WHEN i.column_value = 5 THEN
                        l_desc_message := i_italian_it;
                    WHEN i.column_value = 6 THEN
                        l_desc_message := i_french_fr;
                    WHEN i.column_value = 7 THEN
                        l_desc_message := i_english_uk;
                    WHEN i.column_value = 8 THEN
                        l_desc_message := i_english_sa;
                    WHEN i.column_value = 11 THEN
                        l_desc_message := i_portuguese_br;
                    WHEN i.column_value = 12 THEN
                        l_desc_message := i_chinese_zh_cn;
                    WHEN i.column_value = 13 THEN
                        l_desc_message := i_chinese_zh_tw;
                    WHEN i.column_value = 16 THEN
                        l_desc_message := i_spanish_cl;
                    WHEN i.column_value = 17 THEN
                        l_desc_message := i_spanish_mx;
                    WHEN i.column_value = 18 THEN
                        l_desc_message := i_french_ch;
                    WHEN i.column_value = 19 THEN
                        l_desc_message := i_portuguese_ao;
                    WHEN i.column_value = 20 THEN
                        l_desc_message := i_arabic_ar_sa;
                    WHEN i.column_value = 21 THEN
                        l_desc_message := i_czech_cz;
                    WHEN i.column_value = 22 THEN
                        l_desc_message := i_portuguese_mz;
                END CASE;
            
                IF l_desc_message IS NOT NULL
                THEN
                
                    pk_message.insert_into_sys_message(i_lang         => i.column_value,
                                                       i_code_message => i_code_message,
                                                       i_desc_message => l_desc_message,
                                                       i_flg_type     => l_flg_type,
                                                       i_software     => l_software,
                                                       i_institution  => 0);
                END IF;
            END LOOP;
        
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            raise_application_error(-20001, SQLERRM);
            pk_alert_exceptions.process_error(i_id_language,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
    END;

    PROCEDURE set_trans_sys_domain_cp
    (
        i_action          VARCHAR,
        i_id_language     NUMBER,
        i_id_institution  NUMBER,
        i_code_domain     VARCHAR,
        i_val             VARCHAR,
        i_target_language VARCHAR
    ) IS
        l_domain_owner VARCHAR2(20);
        l_img_name     VARCHAR2(200);
        l_rank         NUMBER;
        l_lang_dest    NUMBER;
        l_lang_source  NUMBER;
    
    BEGIN
        g_func_name := 'set_trans_sys_domain_cp';
    
        SELECT id_lang_dest
          INTO l_lang_dest
          FROM alert_core_data.cmt_user_trans_languages
         WHERE username = sys_context('ALERT_CONTEXT', 'CMT_USERNAME');
    
        SELECT id_lang_source
          INTO l_lang_source
          FROM alert_core_data.cmt_user_trans_languages
         WHERE username = sys_context('ALERT_CONTEXT', 'CMT_USERNAME');
    
        SELECT DISTINCT a.domain_owner, a.rank, a.img_name
          INTO l_domain_owner, l_rank, l_img_name
          FROM sys_domain a
         WHERE a.code_domain = i_code_domain
           AND a.flg_available = g_flg_available
           AND id_language = l_lang_source
           AND a.val = i_val;
    
        IF (i_action = g_flg_create OR i_action = g_flg_update)
           AND i_target_language IS NOT NULL
        THEN
        
            pk_sysdomain.insert_into_sys_domain(i_lang          => l_lang_dest,
                                                i_code_domain   => i_code_domain,
                                                i_desc_val      => i_target_language,
                                                i_val           => i_val,
                                                i_rank          => l_rank,
                                                i_img_name      => l_img_name,
                                                i_flg_available => g_flg_available,
                                                i_domain_owner  => l_domain_owner);
        
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            raise_application_error(-20001, SQLERRM);
            pk_alert_exceptions.process_error(i_id_language,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
    END;

    PROCEDURE set_trans_sys_domain_mt
    (
        i_action         VARCHAR,
        i_id_language    NUMBER,
        i_id_institution NUMBER,
        i_code_domain    VARCHAR,
        i_val            VARCHAR,
        i_portuguese_pt  VARCHAR,
        i_english_us     VARCHAR,
        i_spanish_es     VARCHAR,
        i_italian_it     VARCHAR,
        i_french_fr      VARCHAR,
        i_english_uk     VARCHAR,
        i_english_sa     VARCHAR,
        i_portuguese_br  VARCHAR,
        i_chinese_zh_cn  VARCHAR,
        i_chinese_zh_tw  VARCHAR,
        i_arabic_ar_sa   VARCHAR,
        i_spanish_cl     VARCHAR,
        i_spanish_mx     VARCHAR,
        i_french_ch      VARCHAR,
        i_portuguese_ao  VARCHAR,
        i_czech_cz       VARCHAR,
        i_portuguese_mz  VARCHAR
    ) IS
        l_domain_owner    VARCHAR2(20);
        l_img_name        VARCHAR2(200);
        l_rank            NUMBER;
        l_source_language NUMBER;
        l_dest_langs      VARCHAR2(300);
        l_desc_val        VARCHAR(32767);
    
    BEGIN
        g_func_name := 'set_trans_sys_domain_cp';
    
        SELECT substr(id_lang_dest, 2, length(id_lang_dest) - 2), id_lang_source
          INTO l_dest_langs, l_source_language
          FROM alert_core_data.cmt_user_trans_languages
         WHERE username = sys_context('ALERT_CONTEXT', 'CMT_USERNAME');
    
        SELECT DISTINCT a.domain_owner, a.rank, a.img_name
          INTO l_domain_owner, l_rank, l_img_name
          FROM sys_domain a
         WHERE a.code_domain = i_code_domain
           AND a.flg_available = g_flg_available
           AND id_language = l_source_language
           AND a.val = i_val;
    
        IF (i_action = g_flg_create OR i_action = g_flg_update)
        THEN
        
            FOR i IN (SELECT column_value
                        FROM TABLE(pk_utils.str_split(l_dest_langs, ':')))
            LOOP
            
                CASE
                    WHEN i.column_value = 1 THEN
                        l_desc_val := i_portuguese_pt;
                    WHEN i.column_value = 2 THEN
                        l_desc_val := i_english_us;
                    WHEN i.column_value = 3 THEN
                        l_desc_val := i_spanish_es;
                    WHEN i.column_value = 5 THEN
                        l_desc_val := i_italian_it;
                    WHEN i.column_value = 6 THEN
                        l_desc_val := i_french_fr;
                    WHEN i.column_value = 7 THEN
                        l_desc_val := i_english_uk;
                    WHEN i.column_value = 8 THEN
                        l_desc_val := i_english_sa;
                    WHEN i.column_value = 11 THEN
                        l_desc_val := i_portuguese_br;
                    WHEN i.column_value = 12 THEN
                        l_desc_val := i_chinese_zh_cn;
                    WHEN i.column_value = 13 THEN
                        l_desc_val := i_chinese_zh_tw;
                    WHEN i.column_value = 16 THEN
                        l_desc_val := i_spanish_cl;
                    WHEN i.column_value = 17 THEN
                        l_desc_val := i_spanish_mx;
                    WHEN i.column_value = 18 THEN
                        l_desc_val := i_french_ch;
                    WHEN i.column_value = 19 THEN
                        l_desc_val := i_portuguese_ao;
                    WHEN i.column_value = 20 THEN
                        l_desc_val := i_arabic_ar_sa;
                    WHEN i.column_value = 21 THEN
                        l_desc_val := i_czech_cz;
                    WHEN i.column_value = 22 THEN
                        l_desc_val := i_portuguese_mz;
                END CASE;
            
                IF l_desc_val IS NOT NULL
                THEN
                
                    pk_sysdomain.insert_into_sys_domain(i_lang          => i.column_value,
                                                        i_code_domain   => i_code_domain,
                                                        i_desc_val      => l_desc_val,
                                                        i_val           => i_val,
                                                        i_rank          => l_rank,
                                                        i_img_name      => l_img_name,
                                                        i_flg_available => g_flg_available,
                                                        i_domain_owner  => l_domain_owner);
                END IF;
            END LOOP;
        
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            raise_application_error(-20001, SQLERRM);
            pk_alert_exceptions.process_error(i_id_language,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
    END;

    PROCEDURE set_trans_funct_help_cp
    (
        i_action          VARCHAR,
        i_id_language     NUMBER,
        i_id_institution  NUMBER,
        i_id_software     NUMBER,
        i_code_help       VARCHAR,
        i_target_language VARCHAR
    ) IS
        l_module      VARCHAR2(100);
        l_lang_dest   NUMBER;
        l_lang_source NUMBER;
    
    BEGIN
        g_func_name := 'set_trans_funct_help_cp';
    
        SELECT id_lang_dest
          INTO l_lang_dest
          FROM alert_core_data.cmt_user_trans_languages
         WHERE username = sys_context('ALERT_CONTEXT', 'CMT_USERNAME');
    
        SELECT id_lang_source
          INTO l_lang_source
          FROM alert_core_data.cmt_user_trans_languages
         WHERE username = sys_context('ALERT_CONTEXT', 'CMT_USERNAME');
    
        SELECT module
          INTO l_module
          FROM functionality_help
         WHERE id_software = i_id_software
           AND code_help = i_code_help
           AND id_language = l_lang_source
           AND flg_available = g_flg_available;
    
        IF (i_action = g_flg_create OR i_action = g_flg_update)
           AND i_target_language IS NOT NULL
        THEN
        
            pk_func_help.insert_into_functionality_help(l_lang_dest,
                                                        i_code_help,
                                                        i_target_language,
                                                        i_id_software,
                                                        l_module);
        
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            raise_application_error(-20001, SQLERRM);
            pk_alert_exceptions.process_error(i_id_language,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
    END;

    PROCEDURE set_trans_funct_help_mt
    (
        i_action         VARCHAR,
        i_id_language    NUMBER,
        i_id_institution NUMBER,
        i_id_software    NUMBER,
        i_code_help      VARCHAR,
        i_portuguese_pt  VARCHAR,
        i_english_us     VARCHAR,
        i_spanish_es     VARCHAR,
        i_italian_it     VARCHAR,
        i_french_fr      VARCHAR,
        i_english_uk     VARCHAR,
        i_english_sa     VARCHAR,
        i_portuguese_br  VARCHAR,
        i_chinese_zh_cn  VARCHAR,
        i_chinese_zh_tw  VARCHAR,
        i_arabic_ar_sa   VARCHAR,
        i_spanish_cl     VARCHAR,
        i_spanish_mx     VARCHAR,
        i_french_ch      VARCHAR,
        i_portuguese_ao  VARCHAR,
        i_czech_cz       VARCHAR,
        i_portuguese_mz  VARCHAR
    ) IS
        l_module          VARCHAR2(100);
        l_lang_dest       NUMBER;
        l_source_language NUMBER;
        l_dest_langs      VARCHAR2(300);
        l_desc_help       VARCHAR(32767);
    
    BEGIN
        g_func_name := 'set_trans_funct_help_mt';
    
        SELECT substr(id_lang_dest, 2, length(id_lang_dest) - 2), id_lang_source
          INTO l_dest_langs, l_source_language
          FROM alert_core_data.cmt_user_trans_languages
         WHERE username = sys_context('ALERT_CONTEXT', 'CMT_USERNAME');
    
        SELECT module
          INTO l_module
          FROM functionality_help
         WHERE id_software = i_id_software
           AND code_help = i_code_help
           AND id_language = l_source_language
           AND flg_available = g_flg_available;
    
        IF (i_action = g_flg_create OR i_action = g_flg_update)
        THEN
        
            FOR i IN (SELECT column_value
                        FROM TABLE(pk_utils.str_split(l_dest_langs, ':')))
            LOOP
            
                CASE
                    WHEN i.column_value = 1 THEN
                        l_desc_help := i_portuguese_pt;
                    WHEN i.column_value = 2 THEN
                        l_desc_help := i_english_us;
                    WHEN i.column_value = 3 THEN
                        l_desc_help := i_spanish_es;
                    WHEN i.column_value = 5 THEN
                        l_desc_help := i_italian_it;
                    WHEN i.column_value = 6 THEN
                        l_desc_help := i_french_fr;
                    WHEN i.column_value = 7 THEN
                        l_desc_help := i_english_uk;
                    WHEN i.column_value = 8 THEN
                        l_desc_help := i_english_sa;
                    WHEN i.column_value = 11 THEN
                        l_desc_help := i_portuguese_br;
                    WHEN i.column_value = 12 THEN
                        l_desc_help := i_chinese_zh_cn;
                    WHEN i.column_value = 13 THEN
                        l_desc_help := i_chinese_zh_tw;
                    WHEN i.column_value = 16 THEN
                        l_desc_help := i_spanish_cl;
                    WHEN i.column_value = 17 THEN
                        l_desc_help := i_spanish_mx;
                    WHEN i.column_value = 18 THEN
                        l_desc_help := i_french_ch;
                    WHEN i.column_value = 19 THEN
                        l_desc_help := i_portuguese_ao;
                    WHEN i.column_value = 20 THEN
                        l_desc_help := i_arabic_ar_sa;
                    WHEN i.column_value = 21 THEN
                        l_desc_help := i_czech_cz;
                    WHEN i.column_value = 22 THEN
                        l_desc_help := i_portuguese_mz;
                END CASE;
            
                IF l_desc_help IS NOT NULL
                THEN
                
                    pk_func_help.insert_into_functionality_help(i.column_value,
                                                                i_code_help,
                                                                l_desc_help,
                                                                i_id_software,
                                                                l_module);
                END IF;
            END LOOP;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            raise_application_error(-20001, SQLERRM);
            pk_alert_exceptions.process_error(i_id_language,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
    END;

    PROCEDURE set_trans_translation_cp
    (
        i_action           VARCHAR,
        i_id_language      NUMBER,
        i_id_institution   NUMBER,
        i_code_translation VARCHAR,
        i_target_language  VARCHAR
    ) IS
        l_lang_dest NUMBER;
    BEGIN
    
        g_func_name := 'set_trans_translation_cp';
    
        SELECT id_lang_dest
          INTO l_lang_dest
          FROM alert_core_data.cmt_user_trans_languages
         WHERE username = sys_context('ALERT_CONTEXT', 'CMT_USERNAME');
    
        IF (i_action = g_flg_create OR i_action = g_flg_update)
           AND i_target_language IS NOT NULL
        THEN
        
            pk_translation.insert_into_translation(l_lang_dest, i_code_translation, i_target_language);
        
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            raise_application_error(-20001, SQLERRM);
            pk_alert_exceptions.process_error(i_id_language,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
    END;

    PROCEDURE set_trans_translation_mt
    (
        i_action           VARCHAR,
        i_id_language      NUMBER,
        i_id_institution   NUMBER,
        i_code_translation VARCHAR,
        i_portuguese_pt    VARCHAR,
        i_english_us       VARCHAR,
        i_spanish_es       VARCHAR,
        i_italian_it       VARCHAR,
        i_french_fr        VARCHAR,
        i_english_uk       VARCHAR,
        i_english_sa       VARCHAR,
        i_portuguese_br    VARCHAR,
        i_chinese_zh_cn    VARCHAR,
        i_chinese_zh_tw    VARCHAR,
        i_arabic_ar_sa     VARCHAR,
        i_spanish_cl       VARCHAR,
        i_spanish_mx       VARCHAR,
        i_french_ch        VARCHAR,
        i_portuguese_ao    VARCHAR,
        i_czech_cz         VARCHAR,
        i_portuguese_mz    VARCHAR
    ) IS
        l_dest_langs       VARCHAR2(300);
        l_desc_translation VARCHAR(32767);
    BEGIN
    
        g_func_name := 'set_trans_translation_mt';
    
        SELECT substr(id_lang_dest, 2, length(id_lang_dest) - 2)
          INTO l_dest_langs
          FROM alert_core_data.cmt_user_trans_languages
         WHERE username = sys_context('ALERT_CONTEXT', 'CMT_USERNAME');
    
        IF (i_action = g_flg_create OR i_action = g_flg_update)
        THEN
        
            FOR i IN (SELECT column_value
                        FROM TABLE(pk_utils.str_split(l_dest_langs, ':')))
            LOOP
            
                CASE
                    WHEN i.column_value = 1 THEN
                        l_desc_translation := i_portuguese_pt;
                    WHEN i.column_value = 2 THEN
                        l_desc_translation := i_english_us;
                    WHEN i.column_value = 3 THEN
                        l_desc_translation := i_spanish_es;
                    WHEN i.column_value = 5 THEN
                        l_desc_translation := i_italian_it;
                    WHEN i.column_value = 6 THEN
                        l_desc_translation := i_french_fr;
                    WHEN i.column_value = 7 THEN
                        l_desc_translation := i_english_uk;
                    WHEN i.column_value = 8 THEN
                        l_desc_translation := i_english_sa;
                    WHEN i.column_value = 11 THEN
                        l_desc_translation := i_portuguese_br;
                    WHEN i.column_value = 12 THEN
                        l_desc_translation := i_chinese_zh_cn;
                    WHEN i.column_value = 13 THEN
                        l_desc_translation := i_chinese_zh_tw;
                    WHEN i.column_value = 16 THEN
                        l_desc_translation := i_spanish_cl;
                    WHEN i.column_value = 17 THEN
                        l_desc_translation := i_spanish_mx;
                    WHEN i.column_value = 18 THEN
                        l_desc_translation := i_french_ch;
                    WHEN i.column_value = 19 THEN
                        l_desc_translation := i_portuguese_ao;
                    WHEN i.column_value = 20 THEN
                        l_desc_translation := i_arabic_ar_sa;
                    WHEN i.column_value = 21 THEN
                        l_desc_translation := i_czech_cz;
                    WHEN i.column_value = 22 THEN
                        l_desc_translation := i_portuguese_mz;
                END CASE;
            
                IF l_desc_translation IS NOT NULL
                THEN
                
                    pk_translation.insert_into_translation(i.column_value, i_code_translation, l_desc_translation);
                END IF;
            END LOOP;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            raise_application_error(-20001, SQLERRM);
            pk_alert_exceptions.process_error(i_id_language,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
    END;

    PROCEDURE set_trans_codes_mt
    (
        i_action            VARCHAR,
        i_id_language       NUMBER,
        i_id_institution    NUMBER,
        i_table_translation VARCHAR,
        i_code_translation  VARCHAR,
        i_val               VARCHAR,
        i_portuguese_pt     VARCHAR,
        i_english_us        VARCHAR,
        i_spanish_es        VARCHAR,
        i_italian_it        VARCHAR,
        i_french_fr         VARCHAR,
        i_english_uk        VARCHAR,
        i_english_sa        VARCHAR,
        i_portuguese_br     VARCHAR,
        i_chinese_zh_cn     VARCHAR,
        i_chinese_zh_tw     VARCHAR,
        i_arabic_ar_sa      VARCHAR,
        i_spanish_cl        VARCHAR,
        i_spanish_mx        VARCHAR,
        i_french_ch         VARCHAR,
        i_portuguese_ao     VARCHAR,
        i_czech_cz          VARCHAR,
        i_portuguese_mz     VARCHAR
    ) IS
        l_dest_langs       VARCHAR2(300);
        l_desc_translation VARCHAR(32767);
        l_source_language  NUMBER;
        l_flg_type         VARCHAR2(10);
        l_software         NUMBER;
        l_domain_owner     VARCHAR2(20);
        l_img_name         VARCHAR2(200);
        l_rank             NUMBER;
    BEGIN
    
        g_func_name := 'set_trans_translation_mt';
    
        IF (i_action = g_flg_create OR i_action = g_flg_update)
        THEN
        
            SELECT substr(id_lang_dest, 2, length(id_lang_dest) - 2), id_lang_source
              INTO l_dest_langs, l_source_language
              FROM alert_core_data.cmt_user_trans_languages
             WHERE username = sys_context('ALERT_CONTEXT', 'CMT_USERNAME');
        
            FOR i IN (SELECT column_value
                        FROM TABLE(pk_utils.str_split(l_dest_langs, ':')))
            LOOP
            
                CASE
                    WHEN i.column_value = 1 THEN
                        l_desc_translation := i_portuguese_pt;
                    WHEN i.column_value = 2 THEN
                        l_desc_translation := i_english_us;
                    WHEN i.column_value = 3 THEN
                        l_desc_translation := i_spanish_es;
                    WHEN i.column_value = 5 THEN
                        l_desc_translation := i_italian_it;
                    WHEN i.column_value = 6 THEN
                        l_desc_translation := i_french_fr;
                    WHEN i.column_value = 7 THEN
                        l_desc_translation := i_english_uk;
                    WHEN i.column_value = 8 THEN
                        l_desc_translation := i_english_sa;
                    WHEN i.column_value = 11 THEN
                        l_desc_translation := i_portuguese_br;
                    WHEN i.column_value = 12 THEN
                        l_desc_translation := i_chinese_zh_cn;
                    WHEN i.column_value = 13 THEN
                        l_desc_translation := i_chinese_zh_tw;
                    WHEN i.column_value = 16 THEN
                        l_desc_translation := i_spanish_cl;
                    WHEN i.column_value = 17 THEN
                        l_desc_translation := i_spanish_mx;
                    WHEN i.column_value = 18 THEN
                        l_desc_translation := i_french_ch;
                    WHEN i.column_value = 19 THEN
                        l_desc_translation := i_portuguese_ao;
                    WHEN i.column_value = 20 THEN
                        l_desc_translation := i_arabic_ar_sa;
                    WHEN i.column_value = 21 THEN
                        l_desc_translation := i_czech_cz;
                    WHEN i.column_value = 22 THEN
                        l_desc_translation := i_portuguese_mz;
                END CASE;
            
                IF (l_desc_translation IS NOT NULL)
                THEN
                
                    IF i_table_translation = g_tbl_translation
                    THEN
                    
                        pk_translation.insert_into_translation(i.column_value, i_code_translation, l_desc_translation);
                    
                    ELSIF i_table_translation = g_tbl_sys_message
                    THEN
                    
                        SELECT DISTINCT flg_type, id_software
                          INTO l_flg_type, l_software
                          FROM sys_message a
                         WHERE a.code_message = i_code_translation
                           AND a.flg_available = g_flg_available
                           AND id_institution = 0
                           AND id_language = l_source_language
                           AND rownum = 1;
                    
                        pk_message.insert_into_sys_message(i_lang         => i.column_value,
                                                           i_code_message => i_code_translation,
                                                           i_desc_message => l_desc_translation,
                                                           i_flg_type     => l_flg_type,
                                                           i_software     => l_software,
                                                           i_institution  => 0);
                    
                    ELSIF i_table_translation = g_tbl_sys_domain
                    THEN
                    
                        SELECT DISTINCT a.domain_owner, a.rank, a.img_name
                          INTO l_domain_owner, l_rank, l_img_name
                          FROM sys_domain a
                         WHERE a.code_domain = i_code_translation
                           AND a.flg_available = g_flg_available
                           AND id_language = l_source_language
                           AND a.val = i_val;
                    
                        pk_sysdomain.insert_into_sys_domain(i_lang          => i.column_value,
                                                            i_code_domain   => i_code_translation,
                                                            i_desc_val      => l_desc_translation,
                                                            i_val           => i_val,
                                                            i_rank          => l_rank,
                                                            i_img_name      => l_img_name,
                                                            i_flg_available => g_flg_available,
                                                            i_domain_owner  => l_domain_owner);
                    
                    END IF;
                
                END IF;
            END LOOP;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            raise_application_error(-20001, SQLERRM);
            pk_alert_exceptions.process_error(i_id_language,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
    END;

    PROCEDURE set_trans_translation_lob_cp
    (
        i_action           VARCHAR,
        i_id_language      NUMBER,
        i_id_institution   NUMBER,
        i_code_translation VARCHAR,
        i_target_language  VARCHAR
    ) IS
        l_lang_dest NUMBER;
    BEGIN
        g_func_name := 'set_trans_translation_lob_cp';
    
        SELECT id_lang_dest
          INTO l_lang_dest
          FROM alert_core_data.cmt_user_trans_languages
         WHERE username = sys_context('ALERT_CONTEXT', 'CMT_USERNAME');
    
        IF (i_action = g_flg_create OR i_action = g_flg_update)
           AND i_target_language IS NOT NULL
        THEN
        
            pk_translation_lob.insert_into_translation(l_lang_dest, i_code_translation, i_target_language);
        
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            raise_application_error(-20001, SQLERRM);
            pk_alert_exceptions.process_error(i_id_language,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
    END;

    PROCEDURE set_trans_translation_lob_mt
    (
        i_action           VARCHAR,
        i_id_language      NUMBER,
        i_id_institution   NUMBER,
        i_code_translation VARCHAR,
        i_portuguese_pt    VARCHAR,
        i_english_us       VARCHAR,
        i_spanish_es       VARCHAR,
        i_italian_it       VARCHAR,
        i_french_fr        VARCHAR,
        i_english_uk       VARCHAR,
        i_english_sa       VARCHAR,
        i_portuguese_br    VARCHAR,
        i_chinese_zh_cn    VARCHAR,
        i_chinese_zh_tw    VARCHAR,
        i_arabic_ar_sa     VARCHAR,
        i_spanish_cl       VARCHAR,
        i_spanish_mx       VARCHAR,
        i_french_ch        VARCHAR,
        i_portuguese_ao    VARCHAR,
        i_czech_cz         VARCHAR,
        i_portuguese_mz    VARCHAR
    ) IS
        l_dest_langs           VARCHAR2(300);
        l_desc_translation_lob VARCHAR(32767);
    BEGIN
        g_func_name := 'set_trans_translation_lob_mt';
    
        SELECT substr(id_lang_dest, 2, length(id_lang_dest) - 2)
          INTO l_dest_langs
          FROM alert_core_data.cmt_user_trans_languages
         WHERE username = sys_context('ALERT_CONTEXT', 'CMT_USERNAME');
    
        IF (i_action = g_flg_create OR i_action = g_flg_update)
        THEN
        
            FOR i IN (SELECT column_value
                        FROM TABLE(pk_utils.str_split(l_dest_langs, ':')))
            LOOP
            
                CASE
                    WHEN i.column_value = 1 THEN
                        l_desc_translation_lob := i_portuguese_pt;
                    WHEN i.column_value = 2 THEN
                        l_desc_translation_lob := i_english_us;
                    WHEN i.column_value = 3 THEN
                        l_desc_translation_lob := i_spanish_es;
                    WHEN i.column_value = 5 THEN
                        l_desc_translation_lob := i_italian_it;
                    WHEN i.column_value = 6 THEN
                        l_desc_translation_lob := i_french_fr;
                    WHEN i.column_value = 7 THEN
                        l_desc_translation_lob := i_english_uk;
                    WHEN i.column_value = 8 THEN
                        l_desc_translation_lob := i_english_sa;
                    WHEN i.column_value = 11 THEN
                        l_desc_translation_lob := i_portuguese_br;
                    WHEN i.column_value = 12 THEN
                        l_desc_translation_lob := i_chinese_zh_cn;
                    WHEN i.column_value = 13 THEN
                        l_desc_translation_lob := i_chinese_zh_tw;
                    WHEN i.column_value = 16 THEN
                        l_desc_translation_lob := i_spanish_cl;
                    WHEN i.column_value = 17 THEN
                        l_desc_translation_lob := i_spanish_mx;
                    WHEN i.column_value = 18 THEN
                        l_desc_translation_lob := i_french_ch;
                    WHEN i.column_value = 19 THEN
                        l_desc_translation_lob := i_portuguese_ao;
                    WHEN i.column_value = 20 THEN
                        l_desc_translation_lob := i_arabic_ar_sa;
                    WHEN i.column_value = 21 THEN
                        l_desc_translation_lob := i_czech_cz;
                    WHEN i.column_value = 22 THEN
                        l_desc_translation_lob := i_portuguese_mz;
                END CASE;
            
                IF l_desc_translation_lob IS NOT NULL
                THEN
                
                    pk_translation_lob.insert_into_translation(i.column_value,
                                                               i_code_translation,
                                                               l_desc_translation_lob);
                END IF;
            END LOOP;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            raise_application_error(-20001, SQLERRM);
            pk_alert_exceptions.process_error(i_id_language,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
    END;

    PROCEDURE set_img_exam_complaint
    (
        i_action           VARCHAR,
        i_id_language      NUMBER,
        i_id_institution   NUMBER,
        i_id_cnt_complaint VARCHAR,
        i_id_cnt_img_exam  VARCHAR
    ) IS
        l_id_exam NUMBER;
    
    BEGIN
        g_func_name := 'set_img_exam_complaint';
        SELECT nvl((SELECT a.id_exam
                     FROM exam a
                    WHERE a.id_content = i_id_cnt_img_exam
                      AND a.flg_available = g_flg_available),
                   0)
          INTO l_id_exam
          FROM dual;
        IF l_id_exam > 0
        THEN
            IF i_action = g_flg_create
            THEN
            
                UPDATE exam_complaint ec
                   SET ec.flg_available = g_flg_available
                 WHERE ec.id_exam = l_id_exam
                   AND ec.id_complaint IN (SELECT c.id_complaint
                                             FROM complaint c
                                            WHERE c.id_content = i_id_cnt_complaint
                                              AND c.flg_available = g_flg_available);
            
                INSERT INTO exam_complaint
                    (id_exam, id_complaint, flg_available)
                    SELECT l_id_exam, id_complaint, g_flg_available
                      FROM complaint a
                     WHERE a.id_content = i_id_cnt_complaint
                       AND a.flg_available = g_flg_available
                       AND NOT EXISTS (SELECT 1
                              FROM exam_complaint ec
                             WHERE ec.id_complaint = a.id_complaint
                               AND ec.flg_available = g_flg_available
                               AND ec.id_exam = l_id_exam);
            
            ELSIF i_action = g_flg_delete
            THEN
                DELETE exam_complaint ec
                 WHERE ec.id_exam = l_id_exam
                   AND ec.id_complaint IN (SELECT c.id_complaint
                                             FROM complaint c
                                            WHERE c.id_content = i_id_cnt_complaint
                                              AND c.flg_available = g_flg_available);
            
            END IF;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            raise_application_error(-20001, SQLERRM);
            pk_alert_exceptions.process_error(i_id_language,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
    END;

    PROCEDURE set_lab_test_complaint
    (
        i_action                      VARCHAR,
        i_id_language                 NUMBER,
        i_id_institution              NUMBER,
        i_id_cnt_complaint            VARCHAR,
        i_id_cnt_lab_test_sample_type VARCHAR
    ) IS
    
        l_id_sample_type NUMBER;
        l_id_analysis    NUMBER;
        l_id_complaint   NUMBER;
        l_error          VARCHAR2(4000);
        l_bool           BOOLEAN;
        l_ids            table_number;
        l_status         table_varchar;
    
    BEGIN
        g_func_name := 'set_lab_test_complaint';
    
        l_bool := validate_content(i_id_language,
                                   i_id_institution,
                                   table_varchar(i_id_cnt_lab_test_sample_type, i_id_cnt_lab_test_sample_type),
                                   table_varchar('LAB_TEST_SAMPLE_TYPE (LABTEST)', 'LAB_TEST_SAMPLE_TYPE (SAMPLE_TYPE)'),
                                   table_number(1, 1),
                                   l_ids,
                                   l_status);
    
        l_id_analysis    := l_ids(1);
        l_id_sample_type := l_ids(2);
    
        IF (i_action = g_flg_create)
        THEN
        
            UPDATE lab_tests_complaint ltc
               SET ltc.flg_available = g_flg_available
             WHERE ltc.id_analysis = l_id_analysis
               AND ltc.id_sample_type = l_id_sample_type
               AND ltc.id_complaint IN (SELECT c.id_complaint
                                          FROM complaint c
                                         WHERE c.id_content = i_id_cnt_complaint
                                           AND c.flg_available = g_flg_available);
        
            INSERT INTO lab_tests_complaint
                (id_analysis, id_complaint, flg_available, id_sample_type)
                SELECT l_id_analysis, id_complaint, g_flg_available, l_id_sample_type
                  FROM complaint a
                 WHERE a.id_content = i_id_cnt_complaint
                   AND a.flg_available = g_flg_available
                   AND NOT EXISTS (SELECT 1
                          FROM lab_tests_complaint ltc
                         WHERE ltc.id_complaint = a.id_complaint
                           AND ltc.flg_available = g_flg_available
                           AND ltc.id_analysis = l_id_analysis
                           AND ltc.id_sample_type = l_id_sample_type);
        
        ELSIF i_action = g_flg_update
        THEN
        
            raise_application_error(-20001, 'Only actions Create and Inactivate are allowed!!');
        
        ELSIF i_action = g_flg_delete
        THEN
        
            DELETE FROM lab_tests_complaint
             WHERE id_analysis = l_id_analysis
               AND id_complaint IN (SELECT c.id_complaint
                                      FROM complaint c
                                     WHERE c.id_content = i_id_cnt_complaint
                                       AND c.flg_available = g_flg_available)
               AND id_sample_type = l_id_sample_type;
        
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            raise_application_error(-20001, nvl(l_error, SQLERRM));
            pk_alert_exceptions.process_error(i_id_language,
                                              SQLCODE,
                                              SQLERRM,
                                              l_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            l_error := NULL;
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
    END;

    PROCEDURE set_other_exam_complaint
    (
        i_action            VARCHAR,
        i_id_language       NUMBER,
        i_id_institution    NUMBER,
        i_id_cnt_complaint  VARCHAR,
        i_id_cnt_other_exam VARCHAR
    ) IS
        l_id_exam NUMBER;
    
    BEGIN
        g_func_name := 'set_other_exam_complaint';
        SELECT nvl((SELECT a.id_exam
                     FROM exam a
                    WHERE a.id_content = i_id_cnt_other_exam
                      AND a.flg_available = g_flg_available),
                   0)
          INTO l_id_exam
          FROM dual;
    
        IF l_id_exam > 0
        THEN
            IF i_action = g_flg_create
            THEN
            
                UPDATE exam_complaint ec
                   SET ec.flg_available = g_flg_available
                 WHERE ec.id_exam = l_id_exam
                   AND ec.id_complaint IN (SELECT c.id_complaint
                                             FROM complaint c
                                            WHERE c.id_content = i_id_cnt_complaint
                                              AND c.flg_available = g_flg_available);
            
                INSERT INTO exam_complaint
                    (id_exam, id_complaint, flg_available)
                    SELECT l_id_exam, id_complaint, g_flg_available
                      FROM complaint a
                     WHERE a.id_content = i_id_cnt_complaint
                       AND a.flg_available = g_flg_available
                       AND NOT EXISTS (SELECT 1
                              FROM exam_complaint ec
                             WHERE ec.id_complaint = a.id_complaint
                               AND ec.flg_available = g_flg_available
                               AND ec.id_exam = l_id_exam);
            
            ELSIF i_action = g_flg_delete
            THEN
                DELETE exam_complaint ec
                 WHERE ec.id_exam = l_id_exam
                   AND ec.id_complaint IN (SELECT c.id_complaint
                                             FROM complaint c
                                            WHERE c.id_content = i_id_cnt_complaint
                                              AND c.flg_available = g_flg_available);
            
            END IF;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            raise_application_error(-20001, SQLERRM);
            pk_alert_exceptions.process_error(i_id_language,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
    END;

    PROCEDURE set_disch_reason_prof_temp
    (
        i_action                      VARCHAR,
        i_id_language                 VARCHAR,
        i_id_institution              NUMBER,
        i_id_cnt_discharge_reason     VARCHAR,
        i_id_profile_template         NUMBER,
        i_type_of_discharge           VARCHAR,
        i_professionals_accessibility VARCHAR,
        i_rank                        NUMBER,
        i_flg_default                 VARCHAR
    ) IS
    
        l_id_discharge_reason NUMBER;
        l_exists_inactive     NUMBER;
        l_flg_default         VARCHAR2(1);
    
    BEGIN
        g_func_name := 'set_disch_reason_prof_temp';
    
        SELECT decode(i_flg_default, 'No', 'N', 'Yes', 'Y', NULL)
          INTO l_flg_default
          FROM dual;
    
        SELECT nvl((SELECT a.id_discharge_reason
                     FROM discharge_reason a
                    WHERE a.id_content = i_id_cnt_discharge_reason
                      AND a.flg_available = g_flg_available),
                   0)
          INTO l_id_discharge_reason
          FROM dual;
    
        IF (l_id_discharge_reason > 0 AND (i_type_of_discharge BETWEEN 1 AND 15))
        THEN
        
            IF i_action = g_flg_create
            THEN
            
                SELECT nvl((SELECT a.id_discharge_reason
                             FROM profile_disch_reason a
                            WHERE a.id_institution = i_id_institution
                              AND a.id_discharge_reason = l_id_discharge_reason
                              AND a.flg_available = g_flg_no
                              AND a.id_profile_template = i_id_profile_template),
                           0)
                  INTO l_exists_inactive
                  FROM dual;
            
                IF l_exists_inactive != 0
                THEN
                
                    UPDATE profile_disch_reason a
                       SET a.id_discharge_flash_files = i_type_of_discharge,
                           a.flg_access               = i_professionals_accessibility,
                           a.rank                     = i_rank,
                           a.flg_default              = l_flg_default,
                           a.flg_available            = g_flg_available
                     WHERE a.id_institution = i_id_institution
                       AND a.id_discharge_reason = l_id_discharge_reason
                       AND a.flg_available = g_flg_no
                       AND a.id_profile_template = i_id_profile_template;
                
                ELSE
                
                    INSERT INTO profile_disch_reason
                        (id_profile_disch_reason,
                         id_discharge_reason,
                         id_profile_template,
                         id_institution,
                         flg_available,
                         id_discharge_flash_files,
                         flg_access,
                         rank,
                         flg_default)
                    VALUES
                        (seq_profile_disch_reason.nextval,
                         l_id_discharge_reason,
                         i_id_profile_template,
                         i_id_institution,
                         g_flg_available,
                         i_type_of_discharge,
                         i_professionals_accessibility,
                         i_rank,
                         l_flg_default);
                END IF;
            ELSIF i_action = g_flg_update
            THEN
            
                UPDATE profile_disch_reason a
                   SET a.id_discharge_flash_files = i_type_of_discharge,
                       a.flg_access               = i_professionals_accessibility,
                       a.rank                     = i_rank,
                       a.flg_default              = l_flg_default,
                       a.flg_available            = g_flg_available
                 WHERE a.id_institution = i_id_institution
                   AND a.id_discharge_reason = l_id_discharge_reason
                   AND a.flg_available = g_flg_available
                   AND a.id_profile_template = i_id_profile_template;
            
            ELSIF i_action = g_flg_delete
            THEN
            
                UPDATE profile_disch_reason a
                   SET a.flg_available = g_flg_no
                 WHERE a.id_institution = i_id_institution
                   AND a.id_discharge_reason = l_id_discharge_reason
                   AND a.flg_available = g_flg_available
                   AND a.id_profile_template = i_id_profile_template;
            END IF;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            raise_application_error(-20001, SQLERRM);
            pk_alert_exceptions.process_error(i_id_language,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
    END;

    PROCEDURE set_disch_reas_dest
    (
        i_action                  VARCHAR,
        i_id_language             VARCHAR,
        i_id_institution          NUMBER,
        i_id_institution_dest     NUMBER DEFAULT NULL,
        i_id_software             NUMBER,
        i_id_cnt_discharge_reason VARCHAR,
        i_id_department           NUMBER DEFAULT NULL,
        i_id_cnt_discharge_dest   VARCHAR DEFAULT NULL,
        i_id_dep_clin_serv        NUMBER DEFAULT NULL,
        i_flg_default             VARCHAR DEFAULT 'N',
        i_flg_diag                VARCHAR,
        i_id_reports              NUMBER DEFAULT NULL,
        i_flg_mcdt                VARCHAR DEFAULT NULL,
        i_rank                    NUMBER DEFAULT 0,
        i_flg_auto_presc_cancel   VARCHAR DEFAULT 'N',
        i_type_screen             VARCHAR,
        i_id_epis_type            NUMBER DEFAULT NULL
    ) IS
    
        l_id_discharge_reason NUMBER;
        l_id_discharge_dest   NUMBER := NULL;
        l_id_software_dest    NUMBER := NULL;
        l_id_epis_type        NUMBER := NULL;
        l_type_screen         VARCHAR2(10);
        l_id_dep_clin_serv    NUMBER;
        l_error               VARCHAR2(4000);
    BEGIN
        g_func_name := 'set_disch_reas_dest';
        SELECT nvl((SELECT a.id_discharge_reason
                     FROM discharge_reason a
                    WHERE a.id_content = i_id_cnt_discharge_reason
                      AND a.flg_available = g_flg_available),
                   0)
          INTO l_id_discharge_reason
          FROM dual;
    
        IF l_id_discharge_reason > 0
        THEN
            --se passaram e não existe pode dar erro. pk de facto n é para inserir
            IF i_id_cnt_discharge_dest IS NOT NULL
            THEN
                SELECT a.id_discharge_dest
                  INTO l_id_discharge_dest
                  FROM discharge_dest a
                 WHERE a.id_content = i_id_cnt_discharge_dest
                   AND a.flg_available = g_flg_available;
            
            END IF;
        
            IF i_id_department IS NOT NULL
            THEN
            
                IF i_id_epis_type IS NULL
                THEN
                
                    BEGIN
                        SELECT id_software
                          INTO l_id_software_dest
                          FROM (SELECT sd.id_software
                                  FROM department d
                                  JOIN software_dept sd
                                    ON sd.id_dept = d.id_dept
                                 WHERE d.id_department = i_id_department
                                   AND sd.id_software != i_id_software
                                   AND sd.id_software IN (1, 2, 8, 11)
                                   AND d.id_institution = i_id_institution
                                 ORDER BY 1 DESC)
                         WHERE rownum = 1;
                    
                    EXCEPTION
                        WHEN no_data_found THEN
                            l_error := 'ID_DEPARTMENT does not belong to the requested institution!';
                            RAISE g_exception;
                    END;
                
                    SELECT a.id_epis_type
                      INTO l_id_epis_type
                      FROM epis_type_soft_inst a
                     WHERE a.id_epis_type IN (2, 5, 1, 4)
                       AND a.id_software = l_id_software_dest
                       AND a.id_institution = 0;
                
                ELSE
                    l_id_epis_type := i_id_epis_type;
                END IF;
            
                IF i_type_screen IS NULL
                THEN
                    l_type_screen := 'D|';
                ELSE
                    IF substr(i_type_screen, -1) != '|'
                    THEN
                        l_type_screen := i_type_screen || '|';
                    ELSE
                        l_type_screen := i_type_screen;
                    END IF;
                END IF;
            
            ELSIF i_id_dep_clin_serv IS NOT NULL
            THEN
            
                BEGIN
                
                    SELECT DISTINCT c.id_dep_clin_serv
                      INTO l_id_dep_clin_serv
                      FROM clinical_service a
                      JOIN dep_clin_serv c
                        ON c.id_clinical_service = a.id_clinical_service
                      JOIN department d
                        ON d.id_department = c.id_department
                      JOIN dept de
                        ON de.id_dept = d.id_dept
                      JOIN software_dept sd
                        ON sd.id_dept = de.id_dept
                      JOIN institution i
                        ON i.id_institution = d.id_institution
                       AND i.id_institution = de.id_institution
                     WHERE d.id_institution IN (i_id_institution)
                       AND d.flg_available = g_flg_available
                       AND c.flg_available = g_flg_available
                       AND a.flg_available = g_flg_available
                       AND de.flg_available = g_flg_available
                       AND c.id_dep_clin_serv = i_id_dep_clin_serv;
                
                EXCEPTION
                    WHEN no_data_found THEN
                        l_error := 'ID_DEP_CLIN_SERV does not belong to the requested institution or it is not active!';
                        RAISE g_exception;
                END;
            
                l_id_epis_type := i_id_epis_type;
            
                IF i_type_screen IS NULL
                THEN
                    l_type_screen := i_type_screen;
                ELSE
                    IF substr(i_type_screen, -1) != '|'
                    THEN
                        l_type_screen := i_type_screen || '|';
                    ELSE
                        l_type_screen := i_type_screen;
                    END IF;
                END IF;
            
            ELSE
                l_type_screen := NULL;
            END IF;
        
            IF i_action = g_flg_create
            THEN
            
                INSERT INTO disch_reas_dest
                    (id_disch_reas_dest,
                     id_discharge_reason,
                     id_discharge_dest,
                     id_dep_clin_serv,
                     flg_active,
                     flg_diag,
                     id_institution,
                     id_instit_param,
                     id_software_param,
                     report_name,
                     id_epis_type,
                     type_screen,
                     id_department,
                     id_reports,
                     flg_mcdt,
                     rank,
                     flg_specify_dest,
                     flg_care_stage,
                     flg_default,
                     flg_rep_notes,
                     flg_def_disch_status,
                     id_def_disch_status,
                     flg_needs_overall_resp,
                     flg_auto_presc_cancel)
                    SELECT seq_disch_reas_dest.nextval,
                           l_id_discharge_reason,
                           l_id_discharge_dest,
                           i_id_dep_clin_serv,
                           g_flg_active,
                           i_flg_diag,
                           i_id_institution_dest,
                           i_id_institution,
                           i_id_software,
                           NULL,
                           l_id_epis_type,
                           l_type_screen,
                           i_id_department,
                           i_id_reports,
                           i_flg_mcdt,
                           i_rank,
                           NULL,
                           NULL,
                           i_flg_default,
                           NULL,
                           NULL,
                           NULL,
                           g_flg_no,
                           i_flg_auto_presc_cancel
                      FROM dual
                     WHERE NOT EXISTS (SELECT *
                              FROM disch_reas_dest a
                             WHERE a.id_instit_param = i_id_institution
                               AND a.id_software_param = i_id_software
                               AND a.id_discharge_reason = l_id_discharge_reason
                               AND nvl(a.id_discharge_dest, -1) = nvl(l_id_discharge_dest, -1)
                               AND nvl(a.id_dep_clin_serv, -1) = nvl(i_id_dep_clin_serv, -1)
                               AND nvl(a.id_department, -1) = nvl(i_id_department, -1)
                               AND nvl(a.id_institution, -1) = nvl(i_id_institution_dest, -1));
            
            ELSIF i_action = g_flg_update
            THEN
            
                UPDATE disch_reas_dest a
                   SET flg_diag              = i_flg_diag,
                       id_reports            = i_id_reports,
                       flg_mcdt              = i_flg_mcdt,
                       rank                  = i_rank,
                       flg_default           = i_flg_default,
                       flg_auto_presc_cancel = i_flg_auto_presc_cancel,
                       type_screen           = l_type_screen,
                       id_epis_type          = l_id_epis_type
                 WHERE a.id_instit_param = i_id_institution
                   AND a.id_software_param = i_id_software
                   AND flg_active = g_flg_active
                   AND a.id_discharge_reason = l_id_discharge_reason
                   AND nvl(a.id_discharge_dest, -1) = nvl(l_id_discharge_dest, -1)
                   AND nvl(a.id_dep_clin_serv, -1) = nvl(i_id_dep_clin_serv, -1)
                   AND nvl(a.id_department, -1) = nvl(i_id_department, -1)
                   AND nvl(a.id_institution, -1) = nvl(i_id_institution_dest, -1);
            
            ELSIF i_action = g_flg_delete
            THEN
            
                UPDATE disch_reas_dest a
                   SET flg_active = g_flg_inactive
                 WHERE a.id_instit_param = i_id_institution
                   AND a.id_software_param = i_id_software
                   AND flg_active = g_flg_active
                   AND a.id_discharge_reason = l_id_discharge_reason
                   AND nvl(a.id_discharge_dest, -1) = nvl(l_id_discharge_dest, -1)
                   AND nvl(a.id_dep_clin_serv, -1) = nvl(i_id_dep_clin_serv, -1)
                   AND nvl(a.id_department, -1) = nvl(i_id_department, -1)
                   AND nvl(a.id_institution, -1) = nvl(i_id_institution_dest, -1);
            END IF;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            raise_application_error(-20001, SQLERRM);
            pk_alert_exceptions.process_error(i_id_language,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
    END;

    PROCEDURE set_discharge_destination
    (
        i_action                       VARCHAR,
        i_id_language                  VARCHAR,
        i_desc_discharge_destination   VARCHAR,
        i_id_cnt_discharge_destination VARCHAR
    ) IS
        l_id_discharge_dest NUMBER;
    
    BEGIN
        g_func_name := 'set_discharge_destination';
        SELECT nvl((SELECT a.id_discharge_dest
                     FROM discharge_dest a
                    WHERE a.id_content = i_id_cnt_discharge_destination
                      AND a.flg_available = g_flg_available),
                   0)
          INTO l_id_discharge_dest
          FROM dual;
    
        IF (i_action = g_flg_create OR i_action = g_flg_update)
           AND i_desc_discharge_destination IS NOT NULL
           AND l_id_discharge_dest = 0
        THEN
        
            SELECT seq_discharge_dest.nextval
              INTO l_id_discharge_dest
              FROM dual;
        
            INSERT INTO discharge_dest
                (id_discharge_dest, code_discharge_dest, flg_available, rank, adw_last_update, flg_type, id_content)
            VALUES
                (l_id_discharge_dest,
                 'DISCHARGE_DEST.CODE_DISCHARGE_DEST.' || l_id_discharge_dest,
                 g_flg_available,
                 g_rank_zero,
                 SYSDATE,
                 'DASM',
                 i_id_cnt_discharge_destination);
        
            pk_translation.insert_into_translation(i_id_language,
                                                   'DISCHARGE_DEST.CODE_DISCHARGE_DEST.' || l_id_discharge_dest,
                                                   i_desc_discharge_destination);
        
        ELSIF i_action = g_flg_delete
        THEN
            UPDATE discharge_dest
               SET flg_available = g_flg_no
             WHERE id_content = i_id_cnt_discharge_destination;
        
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            raise_application_error(-20001, SQLERRM);
            pk_alert_exceptions.process_error(i_id_language,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
    END;

    PROCEDURE set_labtest_sample_type_ctlg
    (
        i_action                      VARCHAR,
        i_id_language                 VARCHAR,
        i_id_institution              NUMBER,
        i_id_software                 NUMBER,
        i_id_cnt_lab_test             VARCHAR,
        i_id_cnt_sample_type          VARCHAR,
        i_id_cnt_lab_test_sample_type VARCHAR,
        i_gender                      VARCHAR,
        i_age_min                     NUMBER,
        i_age_max                     NUMBER,
        i_desc_alias                  VARCHAR
    ) IS
    
        l_id_sample_type      NUMBER;
        l_id_analysis         NUMBER;
        l_id_sample_type_2    NUMBER;
        l_id_analysis_2       NUMBER;
        l_labtest_st_inactive VARCHAR(200);
        l_analysis_desc       VARCHAR(200);
        l_sample_desc         VARCHAR(200);
        l_code_ast            VARCHAR(200);
        l_error               VARCHAR2(4000);
        l_bool                BOOLEAN;
        l_ids                 table_number;
        l_status              table_varchar;
        l_exists              NUMBER;
        l_id_softwares        table_number;
    
    BEGIN
        g_func_name := 'set_labtest_sample_type_ctlg';
    
        l_bool := validate_content(i_id_language,
                                   i_id_institution,
                                   table_varchar(i_id_cnt_lab_test_sample_type,
                                                 i_id_cnt_lab_test_sample_type,
                                                 i_id_cnt_lab_test,
                                                 i_id_cnt_sample_type),
                                   table_varchar('LAB_TEST_SAMPLE_TYPE (LABTEST)',
                                                 'LAB_TEST_SAMPLE_TYPE (SAMPLE_TYPE)',
                                                 'LABTEST',
                                                 'SAMPLE_TYPE'),
                                   table_number(0, 0, 1, 1),
                                   l_ids,
                                   l_status);
    
        l_id_analysis      := l_ids(1);
        l_id_sample_type   := l_ids(2);
        l_id_analysis_2    := l_ids(3);
        l_id_sample_type_2 := l_ids(4);
    
        IF i_action IN (g_flg_create, g_flg_update, g_flg_delete)
           AND l_id_analysis != 0
           AND l_id_sample_type != 0
           AND (l_id_analysis != l_id_analysis_2 OR l_id_sample_type != l_id_sample_type_2)
        THEN
        
            l_error := 'The combination of the labtest, sample_type and labtest_sample_type is incorrect. Please validate!';
            RAISE g_exception;
        
            --Já existe
        ELSIF l_id_analysis != 0
              AND l_id_sample_type != 0
              AND l_id_analysis = l_id_analysis_2
              AND l_id_sample_type = l_id_sample_type_2
        THEN
        
            IF i_action IN (g_flg_create, g_flg_update)
            THEN
            
                UPDATE analysis_sample_type a
                   SET flg_available = g_flg_available, age_min = i_age_min, age_max = i_age_max, gender = i_gender
                 WHERE a.id_content = i_id_cnt_lab_test_sample_type;
            
                SELECT DISTINCT id
                  BULK COLLECT
                  INTO l_id_softwares
                  FROM (SELECT s.id_ab_software id
                          FROM software_institution si, ab_software s
                         WHERE si.id_software = s.id_ab_software
                           AND (s.flg_viewer = 'N' OR s.flg_viewer IS NULL)
                           AND si.id_institution = i_id_institution
                           AND si.id_software IN (1, 2, 3, 8, 11, 12, 16, 33, 36, 310, 312));
            
                FOR i IN 1 .. l_id_softwares.count
                LOOP
                
                    set_labtest_sample_type_alias(i_id_language,
                                                  i_id_institution,
                                                  l_id_softwares(i),
                                                  l_id_analysis,
                                                  l_id_sample_type,
                                                  i_desc_alias);
                
                END LOOP;
            
            ELSIF i_action = g_flg_delete
            THEN
                UPDATE analysis_sample_type
                   SET flg_available = g_flg_no
                 WHERE id_content = i_id_cnt_lab_test_sample_type;
            END IF;
            --Não existe
        ELSIF i_action IN (g_flg_create, g_flg_update)
              AND l_id_analysis = 0
              AND l_id_sample_type = 0
        THEN
        
            SELECT nvl((SELECT id_analysis
                         FROM analysis_sample_type
                        WHERE id_analysis = l_id_analysis_2
                          AND id_sample_type = l_id_sample_type_2),
                       0)
              INTO l_exists
              FROM dual;
        
            IF l_exists = 0
            THEN
            
                INSERT INTO analysis_sample_type
                    (id_analysis,
                     id_sample_type,
                     id_content,
                     id_content_analysis,
                     id_content_sample_type,
                     gender,
                     age_min,
                     age_max,
                     flg_available)
                VALUES
                    (l_id_analysis_2,
                     l_id_sample_type_2,
                     i_id_cnt_lab_test_sample_type,
                     i_id_cnt_lab_test,
                     i_id_cnt_sample_type,
                     i_gender,
                     i_age_min,
                     i_age_max,
                     g_flg_available);
            
                SELECT a.code_analysis_sample_type
                  INTO l_code_ast
                  FROM analysis_sample_type a
                 WHERE a.id_content = i_id_cnt_lab_test_sample_type;
            
                SELECT pk_translation.get_translation(i_id_language, a.code_analysis)
                  INTO l_analysis_desc
                  FROM analysis a
                 WHERE a.id_analysis = l_id_analysis_2;
            
                SELECT pk_translation.get_translation(i_id_language, a.code_sample_type)
                  INTO l_sample_desc
                  FROM sample_type a
                 WHERE a.id_sample_type = l_id_sample_type_2;
            
                pk_translation.insert_into_translation(i_id_language,
                                                       l_code_ast,
                                                       l_analysis_desc || ', ' || l_sample_desc);
            
                SELECT DISTINCT id
                  BULK COLLECT
                  INTO l_id_softwares
                  FROM (SELECT s.id_ab_software id
                          FROM software_institution si, ab_software s
                         WHERE si.id_software = s.id_ab_software
                           AND (s.flg_viewer = 'N' OR s.flg_viewer IS NULL)
                           AND si.id_institution = i_id_institution
                           AND si.id_software IN (1, 2, 3, 8, 11, 12, 16, 33, 36, 310, 312));
            
                FOR i IN 1 .. l_id_softwares.count
                LOOP
                
                    set_labtest_sample_type_alias(i_id_language,
                                                  i_id_institution,
                                                  l_id_softwares(i),
                                                  l_id_analysis_2,
                                                  l_id_sample_type_2,
                                                  i_desc_alias);
                
                END LOOP;
            
            ELSE
                l_error := 'The combination of the labtest and sample_type already exists with a different ID_CNT_LAB_TEST_SAMPLE_TYPE. Please validate!';
                RAISE g_exception;
            END IF;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            raise_application_error(-20001, nvl(l_error, SQLERRM));
            pk_alert_exceptions.process_error(i_id_language,
                                              SQLCODE,
                                              SQLERRM,
                                              l_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            l_error := NULL;
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
    END;

    PROCEDURE set_labtest_sample_type_alias
    (
        i_id_language    VARCHAR,
        i_id_institution NUMBER,
        i_id_software    NUMBER,
        i_id_analysis    NUMBER,
        i_id_sample_type NUMBER,
        i_desc_alias     VARCHAR
    ) IS
    
        l_code_labtest_st_alias analysis_sample_type_alias.code_ast_alias%TYPE;
        l_ast_alias             NUMBER;
    
    BEGIN
    
        SELECT nvl((SELECT a.code_ast_alias
                     FROM analysis_sample_type_alias a
                    WHERE a.id_analysis = i_id_analysis
                      AND a.id_sample_type = i_id_sample_type
                      AND a.id_institution = i_id_institution
                      AND a.id_software = i_id_software
                      AND a.id_dep_clin_serv IS NULL
                      AND rownum = 1),
                   '0')
          INTO l_code_labtest_st_alias
          FROM dual;
    
        IF l_code_labtest_st_alias = '0'
           AND i_desc_alias IS NOT NULL
        THEN
        
            SELECT seq_analysis_sample_type_alias.nextval
              INTO l_ast_alias
              FROM dual;
        
            INSERT INTO analysis_sample_type_alias
                (id_analysis_sample_type_alias,
                 id_analysis,
                 id_sample_type,
                 code_ast_alias,
                 id_institution,
                 id_software,
                 id_dep_clin_serv,
                 id_professional)
            VALUES
                (l_ast_alias,
                 i_id_analysis,
                 i_id_sample_type,
                 'ANALYSIS_SAMPLE_TYPE_ALIAS.CODE_AST_ALIAS.' || l_ast_alias,
                 i_id_institution,
                 i_id_software,
                 NULL,
                 NULL);
        
            pk_translation.insert_into_translation(i_id_language,
                                                   'ANALYSIS_SAMPLE_TYPE_ALIAS.CODE_AST_ALIAS.' || l_ast_alias,
                                                   i_desc_alias);
        ELSIF l_code_labtest_st_alias != '0'
              AND i_desc_alias IS NOT NULL
        THEN
        
            pk_translation.insert_into_translation(i_id_language, l_code_labtest_st_alias, i_desc_alias);
        
        ELSIF l_code_labtest_st_alias != '0'
              AND i_desc_alias IS NULL
        THEN
        
            DELETE FROM analysis_sample_type_alias a
             WHERE a.id_analysis = i_id_analysis
               AND a.id_sample_type = i_id_sample_type
               AND a.id_institution = i_id_institution
               AND a.id_software IN (i_id_software, g_soft_zero)
               AND a.id_dep_clin_serv IS NULL
               AND a.id_professional IS NULL;
        
        END IF;
    
    END;

    PROCEDURE set_lab_test
    (
        i_action          VARCHAR,
        i_id_language     VARCHAR,
        i_desc_lab_test   VARCHAR,
        i_id_cnt_lab_test VARCHAR
    ) IS
        l_id_analysis NUMBER;
        l_ids         table_number := table_number();
        l_bool        BOOLEAN;
        l_status      table_varchar;
    
    BEGIN
        g_func_name := 'set_lab_test';
    
        l_bool := validate_content(i_id_language,
                                   0,
                                   table_varchar(i_id_cnt_lab_test),
                                   table_varchar('LABTEST'),
                                   table_number(0),
                                   l_ids,
                                   l_status);
    
        l_id_analysis := l_ids(1);
    
        IF (i_action = g_flg_create OR i_action = g_flg_update)
           AND i_desc_lab_test IS NOT NULL
           AND l_id_analysis = 0
        THEN
        
            validate_description_exists(i_id_language, i_desc_lab_test, 'ANALYSIS', 'ALERT', 'CODE_ANALYSIS');
        
            SELECT seq_analysis.nextval
              INTO l_id_analysis
              FROM dual;
        
            INSERT INTO analysis
                (id_analysis,
                 code_analysis,
                 flg_available,
                 rank,
                 adw_last_update,
                 id_sample_type,
                 gender,
                 age_min,
                 age_max,
                 id_content,
                 flg_legacy)
            VALUES
                (l_id_analysis,
                 'ANALYSIS.CODE_ANALYSIS.' || l_id_analysis,
                 g_flg_available,
                 g_rank_zero,
                 SYSDATE,
                 NULL,
                 NULL,
                 NULL,
                 NULL,
                 i_id_cnt_lab_test,
                 NULL);
        
            pk_translation.insert_into_translation(i_id_language,
                                                   'ANALYSIS.CODE_ANALYSIS.' || l_id_analysis,
                                                   i_desc_lab_test);
        
        ELSIF i_action = g_flg_delete
        THEN
            UPDATE analysis
               SET flg_available = g_flg_no
             WHERE id_content = i_id_cnt_lab_test;
        
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            raise_application_error(-20001, SQLERRM);
            pk_alert_exceptions.process_error(i_id_language,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
    END;

    PROCEDURE set_lab_test_group_assoc
    (
        i_action                      VARCHAR,
        i_id_language                 VARCHAR,
        i_id_cnt_lab_test_group       VARCHAR,
        i_id_cnt_lab_test_sample_type VARCHAR,
        i_rank                        NUMBER,
        i_id_institution              NUMBER,
        i_id_software                 NUMBER
    ) IS
        l_id_analysis_group       NUMBER;
        l_id_analysis_instit_soft NUMBER;
    
        l_id_analysis    NUMBER;
        l_id_sample_type NUMBER;
        aux              NUMBER;
    
    BEGIN
        g_func_name := 'set_lab_test_group_assoc';
        SELECT nvl((SELECT a.id_analysis_group
                     FROM analysis_group a
                    WHERE a.id_content = i_id_cnt_lab_test_group
                      AND a.flg_available = g_flg_available),
                   0)
          INTO l_id_analysis_group
          FROM dual;
    
        BEGIN
            SELECT a.id_analysis, a.id_sample_type
              INTO l_id_analysis, l_id_sample_type
              FROM analysis_sample_type a
             WHERE id_content = i_id_cnt_lab_test_sample_type
               AND a.flg_available = g_flg_available;
        
        EXCEPTION
            WHEN OTHERS THEN
                l_id_analysis    := 0;
                l_id_sample_type := 0;
        END;
    
        IF i_action = g_flg_create
           OR i_action = g_flg_update
        THEN
        
            BEGIN
                IF l_id_analysis_group > 0
                   AND l_id_analysis > 0
                   AND l_id_sample_type > 0
                THEN
                
                    SELECT nvl((SELECT a.id_analysis_instit_soft
                                 FROM analysis_instit_soft a
                                WHERE a.id_analysis_group = l_id_analysis_group
                                  AND a.flg_available = g_flg_available
                                  AND a.id_institution IN (0, i_id_institution)
                                  AND a.id_software IN (0, i_id_software)
                                  AND a.id_analysis IS NULL
                                  AND rownum = 1),
                               0)
                      INTO l_id_analysis_instit_soft
                      FROM dual;
                
                    INSERT INTO analysis_agp
                        (id_analysis_agp, id_analysis_group, id_analysis, rank, flg_available, id_sample_type)
                    VALUES
                        (seq_analysis_agp.nextval,
                         l_id_analysis_group,
                         l_id_analysis,
                         i_rank,
                         g_flg_available,
                         l_id_sample_type);
                
                    IF l_id_analysis_instit_soft = 0
                    THEN
                    
                        set_lab_test_group_avlb('C',
                                                i_id_language,
                                                i_id_institution,
                                                i_id_software,
                                                i_id_cnt_lab_test_group);
                    
                    END IF;
                END IF;
            
            EXCEPTION
                WHEN dup_val_on_index THEN
                
                    UPDATE analysis_agp a
                       SET a.rank = i_rank
                     WHERE a.id_analysis_group = l_id_analysis_group
                       AND a.id_analysis = l_id_analysis
                       AND a.id_sample_type = l_id_sample_type;
            END;
        
        ELSIF i_action = g_flg_delete
        THEN
        
            DELETE FROM analysis_agp a
             WHERE a.id_analysis_group = l_id_analysis_group
               AND a.id_analysis = l_id_analysis
               AND a.id_sample_type = l_id_sample_type;
        
            SELECT COUNT(*)
              INTO aux
              FROM analysis_agp a
             WHERE a.id_analysis_group = l_id_analysis_group;
        
            IF aux = 0
            THEN
                DELETE FROM analysis_instit_soft
                 WHERE id_analysis_group = l_id_analysis_group;
            END IF;
        
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            raise_application_error(-20001, SQLERRM);
            pk_alert_exceptions.process_error(g_language,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
    END;

    PROCEDURE set_lab_test_group_freq
    (
        i_action                VARCHAR,
        i_id_cnt_lab_test_group VARCHAR,
        i_id_institution        NUMBER,
        i_id_software           NUMBER,
        i_id_dep_clin_serv      NUMBER
    ) IS
    
        l_analysis_group NUMBER;
    
        l_action VARCHAR(1);
    
    BEGIN
        g_func_name := 'set_lab_test_group_freq';
        SELECT a.id_analysis_group
          INTO l_analysis_group
          FROM analysis_group a
         WHERE id_content = i_id_cnt_lab_test_group
           AND a.flg_available = g_flg_available;
    
        IF i_action = g_flg_create
        THEN
            l_action := g_pk_apex_most_freq_create;
        ELSIF i_action = g_flg_delete
        THEN
            l_action := g_pk_apex_most_freq_delete;
        
        END IF;
        alert_apex_tools.pk_apex_most_freq.set_freq(i_lang           => g_default_language,
                                                    i_id_institution => i_id_institution,
                                                    i_id_software    => i_id_software,
                                                    i_operation      => l_action,
                                                    flg_context      => g_pk_apex_most_freq_by_dcs,
                                                    flg_content      => g_pk_apex_most_lab_test_group,
                                                    id_context       => table_varchar(i_id_dep_clin_serv),
                                                    id_content       => table_varchar(l_analysis_group));
    EXCEPTION
        WHEN OTHERS THEN
            raise_application_error(-20001, SQLERRM);
            pk_alert_exceptions.process_error(g_language,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
    END set_lab_test_group_freq;

    PROCEDURE set_lab_test_group
    (
        i_action                VARCHAR,
        i_id_language           VARCHAR,
        i_desc_lab_test_group   VARCHAR,
        i_id_cnt_lab_test_group VARCHAR,
        i_gender                VARCHAR,
        i_age_min               NUMBER,
        i_age_max               NUMBER
    ) IS
        l_id_analysis_group NUMBER;
    
    BEGIN
        g_func_name := 'set_lab_test_group';
        SELECT nvl((SELECT a.id_analysis_group
                     FROM analysis_group a
                    WHERE a.id_content = i_id_cnt_lab_test_group
                      AND a.flg_available = g_flg_available),
                   0)
          INTO l_id_analysis_group
          FROM dual;
    
        IF (i_action = g_flg_create OR i_action = g_flg_update)
           AND l_id_analysis_group = 0
           AND i_desc_lab_test_group IS NOT NULL
        THEN
        
            SELECT seq_analysis_group.nextval
              INTO l_id_analysis_group
              FROM dual;
        
            INSERT INTO analysis_group
                (id_analysis_group,
                 code_analysis_group,
                 flg_available,
                 rank,
                 adw_last_update,
                 gender,
                 age_min,
                 age_max,
                 id_content)
            VALUES
                (l_id_analysis_group,
                 'ANALYSIS_GROUP.CODE_ANALYSIS_GROUP.' || l_id_analysis_group,
                 g_flg_available,
                 g_rank_zero,
                 SYSDATE,
                 i_gender,
                 i_age_min,
                 i_age_max,
                 i_id_cnt_lab_test_group);
        
            pk_translation.insert_into_translation(i_id_language,
                                                   'ANALYSIS_GROUP.CODE_ANALYSIS_GROUP.' || l_id_analysis_group,
                                                   i_desc_lab_test_group);
        
        ELSIF i_action = g_flg_delete
        THEN
            UPDATE analysis_group
               SET flg_available = g_flg_no
             WHERE id_content = i_id_cnt_lab_test_group;
        
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            raise_application_error(-20001, SQLERRM);
            pk_alert_exceptions.process_error(i_id_language,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
    END;

    PROCEDURE set_lab_test_group_alias
    (
        i_id_language       VARCHAR,
        i_id_institution    NUMBER,
        i_id_software       NUMBER,
        i_id_lab_test_group VARCHAR,
        i_desc_alias        VARCHAR
    ) IS
    
        l_code_labtest_gp_alias analysis_group_alias.code_analysis_group_alias%TYPE;
        l_ag_alias              NUMBER;
    
    BEGIN
    
        SELECT nvl((SELECT a.code_analysis_group_alias
                     FROM analysis_group_alias a
                    WHERE a.id_analysis_group = i_id_lab_test_group
                      AND a.id_institution = i_id_institution
                      AND a.id_software = i_id_software
                      AND a.id_dep_clin_serv IS NULL
                      AND rownum = 1),
                   '0')
          INTO l_code_labtest_gp_alias
          FROM dual;
    
        IF l_code_labtest_gp_alias = '0'
           AND i_desc_alias IS NOT NULL
        THEN
        
            SELECT nvl((SELECT MAX(id_analysis_group_alias) + 1
                         FROM analysis_group_alias),
                       1)
              INTO l_ag_alias
              FROM dual;
        
            INSERT INTO analysis_group_alias
                (id_analysis_group_alias,
                 id_analysis_group,
                 code_analysis_group_alias,
                 id_institution,
                 id_software,
                 id_dep_clin_serv,
                 id_professional)
            VALUES
                (l_ag_alias,
                 i_id_lab_test_group,
                 'ANALYSIS_GROUP_ALIAS.CODE_ANALYSIS_GROUP_ALIAS.' || l_ag_alias,
                 i_id_institution,
                 i_id_software,
                 NULL,
                 NULL);
        
            pk_translation.insert_into_translation(i_id_language,
                                                   'ANALYSIS_GROUP_ALIAS.CODE_ANALYSIS_GROUP_ALIAS.' || l_ag_alias,
                                                   i_desc_alias);
        ELSIF l_code_labtest_gp_alias != '0'
              AND i_desc_alias IS NOT NULL
        THEN
        
            pk_translation.insert_into_translation(i_id_language, l_code_labtest_gp_alias, i_desc_alias);
        
        ELSIF l_code_labtest_gp_alias != '0'
              AND i_desc_alias IS NULL
        THEN
        
            DELETE FROM analysis_group_alias a
             WHERE a.id_analysis_group = i_id_lab_test_group
               AND a.id_institution = i_id_institution
               AND a.id_software = i_id_software
               AND a.id_dep_clin_serv IS NULL;
        
        END IF;
    
    END;

    PROCEDURE set_lab_test_group_ctlg
    (
        i_action                VARCHAR,
        i_id_language           VARCHAR,
        i_id_institution        NUMBER,
        i_id_software           NUMBER,
        i_id_cnt_lab_test_group VARCHAR,
        i_desc_lab_test_group   VARCHAR,
        i_desc_alias            VARCHAR,
        i_gender                NUMBER,
        i_age_min               NUMBER,
        i_age_max               NUMBER
    ) IS
        l_id_analysis_group     NUMBER;
        l_analysis_group_status NUMBER;
        l_bool                  BOOLEAN;
        l_ids                   table_number;
        l_status                table_varchar;
        l_cod_analysis_group    analysis_group.code_analysis_group%TYPE;
        l_error                 VARCHAR2(4000);
        l_id_softwares          table_number;
    
    BEGIN
        g_func_name := 'set_lab_test_group_avlb';
    
        l_bool := validate_content(i_id_language,
                                   i_id_institution,
                                   table_varchar(i_id_cnt_lab_test_group),
                                   table_varchar('LABTEST_GROUP'),
                                   table_number(0),
                                   l_ids,
                                   l_status);
    
        l_id_analysis_group     := l_ids(1);
        l_analysis_group_status := l_status(1);
    
        IF l_id_analysis_group = 0
        THEN
        
            IF i_action IN (g_flg_create, g_flg_update)
            THEN
            
                validate_description_exists(i_id_language,
                                            i_desc_lab_test_group,
                                            'ANALYSIS_GROUP',
                                            'ALERT',
                                            'CODE_ANALYSIS_GROUP');
            
                SELECT seq_analysis_group.nextval
                  INTO l_id_analysis_group
                  FROM dual;
            
                INSERT INTO analysis_group
                    (id_analysis_group,
                     code_analysis_group,
                     flg_available,
                     rank,
                     adw_last_update,
                     gender,
                     age_min,
                     age_max,
                     id_content)
                VALUES
                    (l_id_analysis_group,
                     'ANALYSIS_GROUP.CODE_ANALYSIS_GROUP.' || l_id_analysis_group,
                     g_flg_available,
                     g_rank_zero,
                     SYSDATE,
                     i_gender,
                     i_age_min,
                     i_age_max,
                     i_id_cnt_lab_test_group);
            
                SELECT e.code_analysis_group
                  INTO l_cod_analysis_group
                  FROM analysis_group e
                 WHERE e.id_analysis_group = l_id_analysis_group;
            
                pk_translation.insert_into_translation(i_id_language, l_cod_analysis_group, i_desc_lab_test_group);
            
                SELECT DISTINCT id
                  BULK COLLECT
                  INTO l_id_softwares
                  FROM (SELECT s.id_ab_software id
                          FROM software_institution si, ab_software s
                         WHERE si.id_software = s.id_ab_software
                           AND (s.flg_viewer = 'N' OR s.flg_viewer IS NULL)
                           AND si.id_institution = i_id_institution
                           AND si.id_software IN (1, 2, 3, 8, 11, 12, 16, 33, 36, 310, 312));
            
                FOR i IN 1 .. l_id_softwares.count
                LOOP
                
                    set_lab_test_group_alias(i_id_language,
                                             i_id_institution,
                                             l_id_softwares(i),
                                             l_id_analysis_group,
                                             i_desc_alias);
                
                END LOOP;
            
            END IF;
        
        ELSIF l_id_analysis_group != 0
        THEN
        
            IF i_action = g_flg_create
            THEN
                IF l_analysis_group_status = 'Y'
                THEN
                    l_error := 'ID_CONTENT to be created already exists!';
                    RAISE g_exception;
                ELSIF l_analysis_group_status = 'N'
                THEN
                    UPDATE analysis_group
                       SET flg_available = g_flg_available
                     WHERE id_content = i_id_cnt_lab_test_group;
                END IF;
            
            ELSIF i_action = g_flg_update
            THEN
            
                UPDATE analysis_group a
                   SET flg_available = g_flg_available, age_min = i_age_min, age_max = i_age_max, gender = i_gender
                 WHERE a.id_analysis_group = l_id_analysis_group;
            
                SELECT DISTINCT id
                  BULK COLLECT
                  INTO l_id_softwares
                  FROM (SELECT s.id_ab_software id
                          FROM software_institution si, ab_software s
                         WHERE si.id_software = s.id_ab_software
                           AND (s.flg_viewer = 'N' OR s.flg_viewer IS NULL)
                           AND si.id_institution = i_id_institution
                           AND si.id_software IN (1, 2, 3, 8, 11, 12, 16, 33, 36, 310, 312));
            
                FOR i IN 1 .. l_id_softwares.count
                LOOP
                
                    set_lab_test_group_alias(i_id_language,
                                             i_id_institution,
                                             l_id_softwares(i),
                                             l_id_analysis_group,
                                             i_desc_alias);
                
                END LOOP;
            
            ELSIF i_action = g_flg_delete
            THEN
            
                UPDATE analysis_group
                   SET flg_available = g_flg_no
                 WHERE id_content = i_id_cnt_lab_test_group;
            
            END IF;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            raise_application_error(-20001, SQLERRM);
            pk_alert_exceptions.process_error(i_id_language,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
    END;

    PROCEDURE set_lab_test_group_avlb
    (
        i_action                VARCHAR,
        i_id_language           VARCHAR,
        i_id_institution        NUMBER,
        i_id_software           NUMBER,
        i_id_cnt_lab_test_group VARCHAR
    ) IS
        l_id_analysis_group NUMBER;
        l_bool              BOOLEAN;
        l_ids               table_number;
        l_status            table_varchar;
    
    BEGIN
        g_func_name := 'set_lab_test_group_avlb';
    
        l_bool := validate_content(i_id_language,
                                   i_id_institution,
                                   table_varchar(i_id_cnt_lab_test_group),
                                   table_varchar('LABTEST_GROUP'),
                                   table_number(1),
                                   l_ids,
                                   l_status);
    
        l_id_analysis_group := l_ids(1);
    
        IF l_id_analysis_group != 0
           AND (i_action = g_flg_create OR i_action = g_flg_update)
        THEN
        
            BEGIN
                INSERT INTO analysis_instit_soft
                    (id_analysis_instit_soft,
                     id_analysis,
                     flg_type,
                     id_institution,
                     id_software,
                     flg_mov_pat,
                     flg_first_result,
                     flg_mov_recipient,
                     flg_harvest,
                     id_exam_cat,
                     rank,
                     cost,
                     price,
                     adw_last_update,
                     id_analysis_group,
                     flg_execute,
                     flg_justify,
                     flg_interface,
                     flg_chargeable,
                     flg_available,
                     flg_duplicate_warn,
                     flg_collection_author,
                     id_sample_type,
                     flg_priority,
                     harvest_instructions)
                VALUES
                    (seq_analysis_instit_soft.nextval,
                     NULL,
                     g_flg_searchable,
                     i_id_institution,
                     i_id_software,
                     NULL,
                     NULL,
                     NULL,
                     NULL,
                     NULL,
                     g_rank_zero,
                     NULL,
                     NULL,
                     SYSDATE,
                     l_id_analysis_group,
                     'Y',
                     NULL,
                     NULL,
                     NULL,
                     g_flg_available,
                     NULL,
                     NULL,
                     NULL,
                     NULL,
                     NULL);
            
            EXCEPTION
                WHEN dup_val_on_index THEN
                
                    UPDATE analysis_instit_soft
                       SET flg_available = g_flg_available
                     WHERE id_analysis_group = l_id_analysis_group
                       AND flg_type = g_flg_searchable
                       AND id_institution = i_id_institution
                       AND id_software = i_id_software
                       AND id_analysis IS NULL
                       AND id_sample_type IS NULL;
                
            END;
        
        ELSIF i_action = g_flg_delete
        THEN
            DELETE FROM analysis_instit_soft a
             WHERE id_analysis_group = l_id_analysis_group
               AND flg_type = g_flg_searchable
               AND id_institution = i_id_institution
               AND id_software = i_id_software
               AND id_analysis IS NULL
               AND id_sample_type IS NULL;
        
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            raise_application_error(-20001, SQLERRM);
            pk_alert_exceptions.process_error(i_id_language,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
    END;

    PROCEDURE set_sample_recipient
    (
        i_action                  VARCHAR,
        i_id_language             VARCHAR,
        i_desc_sample_recipient   VARCHAR,
        i_id_cnt_sample_recipient VARCHAR
    ) IS
        l_id_recipient NUMBER;
    BEGIN
        g_func_name := 'set_sample_recipient';
    
        SELECT nvl((SELECT a.id_sample_recipient
                     FROM sample_recipient a
                    WHERE a.id_content = i_id_cnt_sample_recipient
                      AND a.flg_available = g_flg_available),
                   0)
          INTO l_id_recipient
          FROM dual;
    
        IF (i_action = g_flg_create OR i_action = g_flg_update)
           AND l_id_recipient = 0
           AND i_desc_sample_recipient IS NOT NULL
        THEN
        
            SELECT seq_sample_recipient.nextval
              INTO l_id_recipient
              FROM dual;
        
            INSERT INTO sample_recipient
                (id_sample_recipient,
                 code_sample_recipient,
                 flg_available,
                 rank,
                 adw_last_update,
                 capacity,
                 code_capacity_measure,
                 id_content,
                 standard_code,
                 id_unit_measure)
            VALUES
                (l_id_recipient,
                 'SAMPLE_RECIPIENT.CODE_SAMPLE_RECIPIENT.' || l_id_recipient,
                 g_flg_available,
                 g_rank_zero,
                 SYSDATE,
                 NULL,
                 NULL,
                 i_id_cnt_sample_recipient,
                 NULL,
                 NULL);
        
            pk_translation.insert_into_translation(i_id_language,
                                                   'SAMPLE_RECIPIENT.CODE_SAMPLE_RECIPIENT.' || l_id_recipient,
                                                   i_desc_sample_recipient);
        
        ELSIF i_action = g_flg_delete
        THEN
            UPDATE sample_recipient
               SET flg_available = g_flg_no
             WHERE id_content = i_id_cnt_sample_recipient;
        
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            raise_application_error(-20001, SQLERRM);
            pk_alert_exceptions.process_error(i_id_language,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
    END;

    PROCEDURE set_sample_type
    (
        i_action             VARCHAR,
        i_id_language        VARCHAR,
        i_desc_sample_type   VARCHAR,
        i_id_cnt_sample_type VARCHAR
    ) IS
        l_id_sample NUMBER;
        l_bool      BOOLEAN;
        l_ids       table_number;
        l_status    table_varchar;
    BEGIN
        g_func_name := 'set_sample_type';
    
        l_bool := validate_content(i_id_language,
                                   0,
                                   table_varchar(i_id_cnt_sample_type),
                                   table_varchar('SAMPLE_TYPE'),
                                   table_number(0),
                                   l_ids,
                                   l_status);
    
        l_id_sample := l_ids(1);
    
        IF (i_action = g_flg_create OR i_action = g_flg_update)
           AND l_id_sample = 0
           AND i_desc_sample_type IS NOT NULL
        THEN
        
            validate_description_exists(i_id_language, i_desc_sample_type, 'SAMPLE_TYPE', 'ALERT', 'CODE_SAMPLE_TYPE');
        
            SELECT seq_sample_type.nextval
              INTO l_id_sample
              FROM dual;
        
            INSERT INTO sample_type
                (id_sample_type,
                 code_sample_type,
                 flg_available,
                 rank,
                 adw_last_update,
                 gender,
                 age_min,
                 age_max,
                 id_content)
            VALUES
                (l_id_sample,
                 'SAMPLE_TYPE.CODE_SAMPLE_TYPE.' || l_id_sample,
                 g_flg_available,
                 g_rank_zero,
                 SYSDATE,
                 NULL,
                 NULL,
                 NULL,
                 i_id_cnt_sample_type);
        
            pk_translation.insert_into_translation(i_id_language,
                                                   'SAMPLE_TYPE.CODE_SAMPLE_TYPE.' || l_id_sample,
                                                   i_desc_sample_type);
        
        ELSIF i_action = g_flg_delete
        THEN
            UPDATE sample_type
               SET flg_available = g_flg_no
             WHERE id_content = i_id_cnt_sample_type;
        
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            raise_application_error(-20001, SQLERRM);
            pk_alert_exceptions.process_error(i_id_language,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
    END;
    /*procedure set_lab_test_sample_type(i_action                      varchar,
                                         i_id_language                 varchar,
                                         i_id_institution              number,
                                         i_id_software                 number,
                                         i_id_cnt_lab_test             varchar,
                                         i_id_cnt_sample_type          varchar,
                                         i_id_cnt_lab_test_sample_type varchar,
                                         i_gender                      varchar,
                                         i_age_min                     number,
                                         i_age_max                     number,
                                         i_desc_alias                  varchar) is
    
        l_id_sample_type number;
        l_id_analysis    number;
        l_analysis_desc  varchar(200);
        l_sample_desc    varchar(200);
        l_code_ast       varchar(200);
        i_ast_alias      number;
      begin
        g_func_name := 'set_lab_test_sample_type';
        begin
          select a.id_analysis, a.id_sample_type
            into l_id_analysis, l_id_sample_type
            from analysis_sample_type a
           where a.flg_available = g_flg_available
             and id_content = i_id_cnt_lab_test_sample_type;
    
        exception
          when others then  raise_application_error(-20001, sqlerrm);
            l_id_analysis    := 0;
            l_id_sample_type := 0;
        end;
    
        if i_action = g_flg_create and l_id_analysis = 0 and
           l_id_sample_type = 0 then
    
          select a.id_analysis
            into l_id_analysis
            from analysis a
           where a.flg_available = g_flg_available
             and id_content = i_id_cnt_lab_test;
    
          select a.id_sample_type
            into l_id_sample_type
            from sample_type a
           where a.flg_available = g_flg_available
             and id_content = i_id_cnt_sample_type;
    
          insert into analysis_sample_type
            (id_analysis,
             id_sample_type,
             id_content,
             id_content_analysis,
             id_content_sample_type,
             gender,
             age_min,
             age_max,
             flg_available)
          values
            (l_id_analysis,
             l_id_sample_type,
             i_id_cnt_lab_test_sample_type,
             i_id_cnt_lab_test,
             i_id_cnt_sample_type,
             i_gender,
             i_age_min,
             i_age_max,
             g_flg_available);
    
          select a.code_analysis_sample_type
            into l_code_ast
            from analysis_sample_type a
           where a.id_content = i_id_cnt_lab_test_sample_type;
    
          select pk_translation.get_translation(i_id_language, a.code_analysis)
            into l_analysis_desc
            from analysis a
           where a.id_analysis = l_id_analysis;
          select pk_translation.get_translation(i_id_language,
                                                a.code_sample_type)
            into l_sample_desc
            from sample_type a
           where a.id_sample_type = l_id_sample_type;
    
          pk_translation.insert_into_translation(i_id_language,
                                                 l_code_ast,
                                                 l_analysis_desc || ', ' ||
                                                 l_sample_desc);
    
          if i_desc_alias is not null then
    
            insert into analysis_sample_type_alias
              (ID_ANALYSIS_SAMPLE_TYPE_ALIAS,
               ID_ANALYSIS,
               ID_SAMPLE_TYPE,
               CODE_AST_ALIAS,
               ID_INSTITUTION,
               ID_SOFTWARE,
               ID_DEP_CLIN_SERV,
               ID_PROFESSIONAL)
            values
              (seq_analysis_sample_type_alias.nextval,
               l_id_analysis,
               l_id_sample_type,
               'ANALYSIS_SAMPLE_TYPE_ALIAS.CODE_AST_ALIAS.' ||
               seq_analysis_sample_type_alias.currval,
               i_id_institution,
               g_soft_zero,
               null,
               null);
    
            pk_translation.insert_into_translation(i_id_language,
                                                   'ANALYSIS_SAMPLE_TYPE_ALIAS.CODE_AST_ALIAS.' ||
                                                   seq_analysis_sample_type_alias.currval,
                                                   i_desc_alias);
          end if;
    
        elsif i_action = g_flg_update then
    
          update analysis_sample_type a
             set age_max = i_age_max, age_min = i_age_min, gender = i_gender
           where id_content = i_id_cnt_lab_test_sample_type;
    
          if i_desc_alias is not null then
    
            select nvl((select a.id_analysis_sample_type_alias
                         from analysis_sample_type_alias a
                        where a.id_institution = i_id_institution
                          and a.id_software = g_soft_zero
                          and a.id_analysis = l_id_analysis
                          and a.id_sample_type = l_id_sample_type),
                       0)
              into i_ast_alias
              from dual;
            if i_ast_alias = 0 then
    
              select seq_analysis_sample_type_alias.nextval
                into i_ast_alias
                from dual;
              insert into analysis_sample_type_alias
                (ID_ANALYSIS_SAMPLE_TYPE_ALIAS,
                 ID_ANALYSIS,
                 ID_SAMPLE_TYPE,
                 CODE_AST_ALIAS,
                 ID_INSTITUTION,
                 ID_SOFTWARE,
                 ID_DEP_CLIN_SERV,
                 ID_PROFESSIONAL)
              values
                (i_ast_alias,
                 l_id_analysis,
                 l_id_sample_type,
                 'ANALYSIS_SAMPLE_TYPE_ALIAS.CODE_AST_ALIAS.' ||
                 i_ast_alias,
                 i_id_institution,
                 g_soft_zero,
                 null,
                 null);
    
              pk_translation.insert_into_translation(i_id_language,
                                                     'ANALYSIS_SAMPLE_TYPE.CODE_ANALYSIS_SAMPLE_TYPE.' ||
                                                     i_ast_alias,
                                                     i_desc_alias);
            else
              pk_translation.insert_into_translation(i_id_language,
                                                     'ANALYSIS_SAMPLE_TYPE.CODE_ANALYSIS_SAMPLE_TYPE.' ||
                                                     i_ast_alias,
                                                     i_desc_alias);
            end if;
          end if;
    
        end if;
      exception
        when others then  raise_application_error(-20001, sqlerrm);
          pk_alert_exceptions.process_error(i_id_language,
                                            sqlcode,
                                            sqlerrm,
                                            g_error,
                                            g_package_owner,
                                            g_package_name,
                                            g_func_name,
                                            o_error);
          pk_utils.undo_changes;
          pk_alert_exceptions.reset_error_state;
      END;
    */

    PROCEDURE set_lab_test_sample_type
    (
        i_action                      VARCHAR,
        i_id_language                 VARCHAR,
        i_id_institution              NUMBER,
        i_id_software                 NUMBER,
        i_id_cnt_lab_test             VARCHAR,
        i_id_cnt_sample_type          VARCHAR,
        i_id_cnt_lab_test_sample_type VARCHAR,
        i_gender                      VARCHAR,
        i_age_min                     NUMBER,
        i_age_max                     NUMBER,
        i_desc_alias                  VARCHAR,
        i_flg_mov_pat                 VARCHAR,
        i_flg_first_result            VARCHAR,
        i_flg_mov_recipient           VARCHAR,
        i_flg_harvest                 VARCHAR,
        i_flg_execute                 VARCHAR,
        i_flg_justify                 VARCHAR,
        i_flg_interface               VARCHAR,
        i_flg_duplicate_warn          VARCHAR,
        i_id_cnt_exam_cat             VARCHAR,
        i_flg_priority                VARCHAR
    ) IS
    
        l_id_sample_type NUMBER;
        l_id_analysis    NUMBER;
        l_analysis_desc  VARCHAR(200);
        l_sample_desc    VARCHAR(200);
        l_code_ast       VARCHAR(200);
        i_ast_alias      NUMBER;
        l_id_exam_cat    NUMBER;
        aux              NUMBER;
        l_bool           BOOLEAN;
        l_ids            table_number;
        l_status         table_varchar;
    
    BEGIN
        g_func_name := 'set_lab_test_sample_type';
    
        l_bool := validate_content(i_id_language,
                                   i_id_institution,
                                   table_varchar(i_id_cnt_lab_test_sample_type,
                                                 i_id_cnt_lab_test_sample_type,
                                                 i_id_cnt_exam_cat),
                                   table_varchar('LAB_TEST_SAMPLE_TYPE (LABTEST)',
                                                 'LAB_TEST_SAMPLE_TYPE (SAMPLE_TYPE)',
                                                 'EXAM_CAT_LABTEST'),
                                   table_number(0, 0, 1),
                                   l_ids,
                                   l_status);
    
        l_id_analysis    := l_ids(1);
        l_id_sample_type := l_ids(2);
        l_id_exam_cat    := l_ids(3);
    
        IF (i_action = g_flg_create OR i_action = g_flg_update)
           AND l_id_analysis = 0
           AND l_id_sample_type = 0
           AND l_id_exam_cat > 0
        THEN
        
            SELECT a.id_analysis
              INTO l_id_analysis
              FROM analysis a
             WHERE a.flg_available = g_flg_available
               AND id_content = i_id_cnt_lab_test;
        
            SELECT a.id_sample_type
              INTO l_id_sample_type
              FROM sample_type a
             WHERE a.flg_available = g_flg_available
               AND id_content = i_id_cnt_sample_type;
        
            INSERT INTO analysis_sample_type
                (id_analysis,
                 id_sample_type,
                 id_content,
                 id_content_analysis,
                 id_content_sample_type,
                 gender,
                 age_min,
                 age_max,
                 flg_available)
            VALUES
                (l_id_analysis,
                 l_id_sample_type,
                 i_id_cnt_lab_test_sample_type,
                 i_id_cnt_lab_test,
                 i_id_cnt_sample_type,
                 i_gender,
                 i_age_min,
                 i_age_max,
                 g_flg_available);
        
            INSERT INTO analysis_instit_soft
                (id_analysis_instit_soft,
                 id_analysis,
                 flg_type,
                 id_institution,
                 id_software,
                 flg_mov_pat,
                 flg_first_result,
                 flg_mov_recipient,
                 flg_harvest,
                 id_exam_cat,
                 rank,
                 cost,
                 price,
                 adw_last_update,
                 id_analysis_group,
                 flg_execute,
                 flg_justify,
                 flg_interface,
                 flg_chargeable,
                 flg_available,
                 flg_duplicate_warn,
                 flg_collection_author,
                 id_sample_type,
                 flg_priority,
                 harvest_instructions)
            VALUES
                (seq_analysis_instit_soft.nextval,
                 l_id_analysis,
                 g_flg_searchable,
                 i_id_institution,
                 i_id_software,
                 i_flg_mov_pat,
                 i_flg_first_result,
                 i_flg_mov_recipient,
                 i_flg_harvest,
                 l_id_exam_cat,
                 g_rank_zero,
                 NULL,
                 NULL,
                 SYSDATE,
                 NULL,
                 i_flg_execute,
                 i_flg_justify,
                 i_flg_interface,
                 NULL,
                 g_flg_available,
                 i_flg_duplicate_warn,
                 NULL,
                 l_id_sample_type,
                 i_flg_priority,
                 NULL);
        
            SELECT a.code_analysis_sample_type
              INTO l_code_ast
              FROM analysis_sample_type a
             WHERE a.id_content = i_id_cnt_lab_test_sample_type;
        
            SELECT pk_translation.get_translation(i_id_language, a.code_analysis)
              INTO l_analysis_desc
              FROM analysis a
             WHERE a.id_analysis = l_id_analysis;
        
            SELECT pk_translation.get_translation(i_id_language, a.code_sample_type)
              INTO l_sample_desc
              FROM sample_type a
             WHERE a.id_sample_type = l_id_sample_type;
        
            pk_translation.insert_into_translation(i_id_language, l_code_ast, l_analysis_desc || ', ' || l_sample_desc);
        
            IF i_desc_alias IS NOT NULL
            THEN
            
                INSERT INTO analysis_sample_type_alias
                    (id_analysis_sample_type_alias,
                     id_analysis,
                     id_sample_type,
                     code_ast_alias,
                     id_institution,
                     id_software,
                     id_dep_clin_serv,
                     id_professional)
                VALUES
                    (seq_analysis_sample_type_alias.nextval,
                     l_id_analysis,
                     l_id_sample_type,
                     'ANALYSIS_SAMPLE_TYPE_ALIAS.CODE_AST_ALIAS.' || seq_analysis_sample_type_alias.currval,
                     i_id_institution,
                     i_id_software,
                     NULL,
                     NULL);
            
                pk_translation.insert_into_translation(i_id_language,
                                                       'ANALYSIS_SAMPLE_TYPE_ALIAS.CODE_AST_ALIAS.' ||
                                                       seq_analysis_sample_type_alias.currval,
                                                       i_desc_alias);
            END IF;
        
        ELSIF i_action = g_flg_create
              AND l_id_analysis > 0
              AND l_id_sample_type > 0
              AND l_id_exam_cat > 0
        THEN
        
            UPDATE analysis_sample_type a
               SET age_max = i_age_max, age_min = i_age_min, gender = i_gender
             WHERE id_content = i_id_cnt_lab_test_sample_type;
        
            SELECT COUNT(*)
              INTO aux
              FROM analysis_instit_soft
             WHERE id_analysis = l_id_analysis
               AND flg_type = g_flg_searchable
               AND id_institution = i_id_institution
               AND id_software = i_id_software
               AND id_sample_type = l_id_sample_type;
            IF aux = 0
            THEN
            
                INSERT INTO analysis_instit_soft
                    (id_analysis_instit_soft,
                     id_analysis,
                     flg_type,
                     id_institution,
                     id_software,
                     flg_mov_pat,
                     flg_first_result,
                     flg_mov_recipient,
                     flg_harvest,
                     id_exam_cat,
                     rank,
                     cost,
                     price,
                     adw_last_update,
                     id_analysis_group,
                     flg_execute,
                     flg_justify,
                     flg_interface,
                     flg_chargeable,
                     flg_available,
                     flg_duplicate_warn,
                     flg_collection_author,
                     id_sample_type,
                     flg_priority,
                     harvest_instructions)
                VALUES
                    (seq_analysis_instit_soft.nextval,
                     l_id_analysis,
                     g_flg_searchable,
                     i_id_institution,
                     i_id_software,
                     i_flg_mov_pat,
                     i_flg_first_result,
                     i_flg_mov_recipient,
                     i_flg_harvest,
                     l_id_exam_cat,
                     g_rank_zero,
                     NULL,
                     NULL,
                     SYSDATE,
                     NULL,
                     i_flg_execute,
                     i_flg_justify,
                     i_flg_interface,
                     NULL,
                     g_flg_available,
                     i_flg_duplicate_warn,
                     NULL,
                     l_id_sample_type,
                     i_flg_priority,
                     NULL);
            
            ELSE
                UPDATE analysis_instit_soft
                   SET flg_available      = g_flg_available,
                       flg_mov_pat        = i_flg_mov_pat,
                       flg_first_result   = i_flg_first_result,
                       flg_mov_recipient  = i_flg_mov_recipient,
                       flg_harvest        = i_flg_harvest,
                       flg_execute        = i_flg_execute,
                       flg_justify        = i_flg_justify,
                       flg_interface      = i_flg_interface,
                       flg_duplicate_warn = i_flg_duplicate_warn,
                       id_exam_cat        = l_id_exam_cat,
                       flg_priority       = i_flg_priority
                 WHERE id_analysis = l_id_analysis
                   AND flg_type = g_flg_searchable
                   AND id_institution = i_id_institution
                   AND id_software = i_id_software
                   AND id_sample_type = l_id_sample_type;
            END IF;
            SELECT nvl((SELECT a.id_analysis_sample_type_alias
                         FROM analysis_sample_type_alias a
                        WHERE a.id_institution = i_id_institution
                          AND a.id_software = g_soft_zero
                          AND a.id_analysis = l_id_analysis
                          AND a.id_sample_type = l_id_sample_type),
                       0)
              INTO i_ast_alias
              FROM dual;
            IF i_ast_alias = 0
               AND i_desc_alias IS NOT NULL
            THEN
            
                SELECT seq_analysis_sample_type_alias.nextval
                  INTO i_ast_alias
                  FROM dual;
                INSERT INTO analysis_sample_type_alias
                    (id_analysis_sample_type_alias,
                     id_analysis,
                     id_sample_type,
                     code_ast_alias,
                     id_institution,
                     id_software,
                     id_dep_clin_serv,
                     id_professional)
                VALUES
                    (i_ast_alias,
                     l_id_analysis,
                     l_id_sample_type,
                     'ANALYSIS_SAMPLE_TYPE.CODE_ANALYSIS_SAMPLE_TYPE.' || i_ast_alias,
                     i_id_institution,
                     i_id_software,
                     NULL,
                     NULL);
            
                pk_translation.insert_into_translation(i_id_language,
                                                       'ANALYSIS_SAMPLE_TYPE.CODE_ANALYSIS_SAMPLE_TYPE.' || i_ast_alias,
                                                       i_desc_alias);
            ELSIF i_ast_alias > 0
                  AND i_desc_alias IS NOT NULL
            THEN
                pk_translation.insert_into_translation(i_id_language,
                                                       'ANALYSIS_SAMPLE_TYPE.CODE_ANALYSIS_SAMPLE_TYPE.' || i_ast_alias,
                                                       i_desc_alias);
            ELSIF i_ast_alias > 0
                  AND i_desc_alias IS NULL
            THEN
            
                DELETE FROM analysis_sample_type_alias a
                 WHERE a.id_institution = i_id_institution
                   AND a.id_software = g_soft_zero
                   AND a.id_analysis = l_id_analysis
                   AND a.id_sample_type = l_id_sample_type;
            
                pk_translation.insert_into_translation(i_id_language,
                                                       'ANALYSIS_SAMPLE_TYPE_ALIAS.CODE_AST_ALIAS.' || i_ast_alias,
                                                       i_desc_alias);
            END IF;
        
        ELSIF i_action = g_flg_update
              AND l_id_analysis > 0
              AND l_id_sample_type > 0
              AND l_id_exam_cat > 0
        THEN
        
            UPDATE analysis_sample_type a
               SET age_max = i_age_max, age_min = i_age_min, gender = i_gender
             WHERE id_content = i_id_cnt_lab_test_sample_type;
        
            UPDATE analysis_instit_soft
               SET flg_mov_pat        = i_flg_mov_pat,
                   flg_first_result   = i_flg_first_result,
                   flg_mov_recipient  = i_flg_mov_recipient,
                   flg_harvest        = i_flg_harvest,
                   flg_execute        = i_flg_execute,
                   flg_justify        = i_flg_justify,
                   flg_interface      = i_flg_interface,
                   flg_duplicate_warn = i_flg_duplicate_warn,
                   id_exam_cat        = l_id_exam_cat,
                   flg_priority       = i_flg_priority
             WHERE id_analysis = l_id_analysis
               AND flg_type = g_flg_searchable
               AND id_institution = i_id_institution
               AND id_software = i_id_software
               AND id_sample_type = l_id_sample_type;
        
            IF i_desc_alias IS NOT NULL
            THEN
            
                SELECT nvl((SELECT a.id_analysis_sample_type_alias
                             FROM analysis_sample_type_alias a
                            WHERE a.id_institution = i_id_institution
                              AND a.id_software = i_id_software
                              AND a.id_analysis = l_id_analysis
                              AND a.id_sample_type = l_id_sample_type),
                           0)
                  INTO i_ast_alias
                  FROM dual;
                IF i_ast_alias = 0
                THEN
                
                    SELECT seq_analysis_sample_type_alias.nextval
                      INTO i_ast_alias
                      FROM dual;
                
                    INSERT INTO analysis_sample_type_alias
                        (id_analysis_sample_type_alias,
                         id_analysis,
                         id_sample_type,
                         code_ast_alias,
                         id_institution,
                         id_software,
                         id_dep_clin_serv,
                         id_professional)
                    VALUES
                        (i_ast_alias,
                         l_id_analysis,
                         l_id_sample_type,
                         'ANALYSIS_SAMPLE_TYPE_ALIAS.CODE_AST_ALIAS.' || i_ast_alias,
                         i_id_institution,
                         i_id_software,
                         NULL,
                         NULL);
                
                    pk_translation.insert_into_translation(i_id_language,
                                                           'ANALYSIS_SAMPLE_TYPE_ALIAS.CODE_AST_ALIAS.' || i_ast_alias,
                                                           i_desc_alias);
                ELSE
                    pk_translation.insert_into_translation(i_id_language,
                                                           'ANALYSIS_SAMPLE_TYPE_ALIAS.CODE_AST_ALIAS.' || i_ast_alias,
                                                           i_desc_alias);
                END IF;
            END IF;
        ELSIF i_action = g_flg_delete
        THEN
            UPDATE analysis_instit_soft
               SET flg_available = g_flg_no
             WHERE id_analysis = l_id_analysis
               AND flg_type = g_flg_searchable
               AND id_institution = i_id_institution
               AND id_software = i_id_software
               AND id_sample_type = l_id_sample_type;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            raise_application_error(-20001, SQLERRM);
            pk_alert_exceptions.process_error(i_id_language,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
    END;

    FUNCTION format_field_trim(i_field IN NUMBER) RETURN NUMBER IS
    BEGIN
    
        RETURN TRIM(i_field);
    
    END format_field_trim;

    FUNCTION format_field_trim(i_field IN VARCHAR2) RETURN VARCHAR2 IS
    BEGIN
    
        RETURN TRIM(i_field);
    
    END format_field_trim;

    FUNCTION format_field_trim_all_upper(i_field IN VARCHAR2) RETURN VARCHAR2 IS
    BEGIN
    
        RETURN upper(TRIM(i_field));
    
    END format_field_trim_all_upper;

    FUNCTION format_field_trim_upper_gmc(i_field IN VARCHAR2) RETURN VARCHAR2 IS
    BEGIN
    
        RETURN upper(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(i_field), '-'), '_'), '/'), '\'), ' '));
    
    END format_field_trim_upper_gmc;

    FUNCTION format_prepare_for_search(i_field IN VARCHAR2) RETURN VARCHAR2 IS
    BEGIN
    
        RETURN lower(REPLACE(TRIM(regexp_replace(i_field, '[^[:alnum:]'' '']', NULL)), ' ', ''));
    
    END format_prepare_for_search;

    FUNCTION format_field_trim_all_lower(i_field IN VARCHAR2) RETURN VARCHAR2 IS
    BEGIN
    
        RETURN lower(TRIM(i_field));
    
    END format_field_trim_all_lower;

    FUNCTION format_field_trim_first_upper(i_field IN VARCHAR2) RETURN VARCHAR2 IS
    BEGIN
    
        RETURN initcap(TRIM(i_field));
    
    END format_field_trim_first_upper;

    FUNCTION validate_content
    (
        i_id_language    IN NUMBER,
        i_id_institution IN NUMBER,
        i_id_content     IN table_varchar,
        i_table          IN table_varchar,
        i_show_errors    IN table_number,
        o_results        OUT table_number,
        o_status         OUT table_varchar
    ) RETURN BOOLEAN IS
        l_id_aux      NUMBER;
        l_status_aux  VARCHAR2(1);
        l_ids         table_number := table_number();
        l_status      table_varchar := table_varchar();
        l_error       VARCHAR2(4000);
        l_room_instit NUMBER;
    BEGIN
    
        FOR i IN 1 .. i_id_content.count
        LOOP
        
            IF i_id_content(i) IS NULL
            THEN
                l_error := i_table(i) || ' is empty!';
                RAISE g_exception;
            END IF;
        
            BEGIN
            
                IF i_table(i) = 'SAMPLE_RECIPIENT'
                THEN
                
                    SELECT *
                      INTO l_id_aux, l_status_aux
                      FROM (SELECT a.id_sample_recipient, a.flg_available
                              FROM sample_recipient a
                             WHERE a.id_content = i_id_content(i)
                             ORDER BY flg_available DESC)
                     WHERE rownum = 1;
                
                ELSIF i_table(i) = 'EXAM_CAT_LABTEST'
                THEN
                
                    SELECT *
                      INTO l_id_aux, l_status_aux
                      FROM (SELECT a.id_exam_cat, a.flg_available
                              FROM exam_cat a
                             WHERE a.id_content = i_id_content(i)
                             ORDER BY 2 DESC)
                     WHERE rownum = 1;
                
                ELSIF i_table(i) = 'EXAM_CAT_EXAM'
                THEN
                
                    SELECT *
                      INTO l_id_aux, l_status_aux
                      FROM (SELECT a.id_exam_cat, a.flg_available
                              FROM exam_cat a
                             WHERE a.id_content = i_id_content(i)
                             ORDER BY 2 DESC)
                     WHERE rownum = 1;
                
                ELSIF i_table(i) = 'COMPLAINT'
                THEN
                
                    SELECT *
                      INTO l_id_aux, l_status_aux
                      FROM (SELECT a.id_complaint, a.flg_available
                              FROM complaint a
                             WHERE a.id_content = i_id_content(i)
                             ORDER BY 2 DESC)
                     WHERE rownum = 1;
                
                ELSIF i_table(i) = 'COMPLAINT_ALIAS'
                THEN
                
                    SELECT *
                      INTO l_id_aux, l_status_aux
                      FROM (SELECT a.id_complaint, a.flg_available
                              FROM complaint_alias a
                             WHERE a.id_content = i_id_content(i)
                             ORDER BY 2 DESC)
                     WHERE rownum = 1;
                
                ELSIF i_table(i) = 'ROOM'
                THEN
                
                    SELECT id_institution
                      INTO l_room_instit
                      FROM department
                     WHERE id_department IN (SELECT id_department
                                               FROM room
                                              WHERE id_room = to_number(i_id_content(i)));
                
                    IF (l_room_instit != i_id_institution)
                    THEN
                    
                        l_error := 'The room inserted does not belong to the institution that the user logged in!';
                        RAISE g_exception;
                    
                    END IF;
                
                    SELECT id_room, flg_available
                      INTO l_id_aux, l_status_aux
                      FROM (SELECT a.id_room, a.flg_available
                              FROM room a
                             WHERE a.id_room = to_number(i_id_content(i))
                             ORDER BY 2 DESC)
                     WHERE rownum = 1;
                
                ELSIF i_table(i) = 'LAB_TEST_PARAMETER'
                THEN
                
                    SELECT *
                      INTO l_id_aux, l_status_aux
                      FROM (SELECT a.id_analysis_parameter, a.flg_available
                              FROM analysis_parameter a
                             WHERE a.id_analysis_parameter = i_id_content(i)
                             ORDER BY flg_available DESC)
                     WHERE rownum = 1;
                
                ELSIF i_table(i) = 'LAB_TEST_SAMPLE_TYPE (LABTEST)'
                THEN
                
                    SELECT *
                      INTO l_id_aux, l_status_aux
                      FROM (SELECT a.id_analysis, a.flg_available
                              FROM analysis_sample_type a
                             WHERE a.id_content = i_id_content(i)
                             ORDER BY flg_available DESC)
                     WHERE rownum = 1;
                
                ELSIF i_table(i) = 'LAB_TEST_SAMPLE_TYPE (SAMPLE_TYPE)'
                THEN
                
                    SELECT *
                      INTO l_id_aux, l_status_aux
                      FROM (SELECT a.id_sample_type, a.flg_available
                              FROM analysis_sample_type a
                             WHERE a.id_content = i_id_content(i)
                             ORDER BY flg_available DESC)
                     WHERE rownum = 1;
                
                ELSIF i_table(i) = 'LABTEST'
                THEN
                
                    SELECT *
                      INTO l_id_aux, l_status_aux
                      FROM (SELECT a.id_analysis, a.flg_available
                              FROM analysis a
                             WHERE a.id_content = i_id_content(i)
                             ORDER BY flg_available DESC)
                     WHERE rownum = 1;
                
                ELSIF i_table(i) = 'LABTEST_GROUP'
                THEN
                
                    SELECT *
                      INTO l_id_aux, l_status_aux
                      FROM (SELECT a.id_analysis_group, a.flg_available
                              FROM analysis_group a
                             WHERE a.id_content = i_id_content(i)
                             ORDER BY flg_available DESC)
                     WHERE rownum = 1;
                
                ELSIF i_table(i) = 'SAMPLE_TYPE'
                THEN
                
                    SELECT *
                      INTO l_id_aux, l_status_aux
                      FROM (SELECT a.id_sample_type, a.flg_available
                              FROM sample_type a
                             WHERE a.id_content = i_id_content(i)
                             ORDER BY flg_available DESC)
                     WHERE rownum = 1;
                
                ELSIF (i_table(i) = 'IMAGE_EXAM' OR i_table(i) = 'ULTRASOUND')
                THEN
                
                    SELECT *
                      INTO l_id_aux, l_status_aux
                      FROM (SELECT a.id_exam, a.flg_available
                              FROM exam a
                             WHERE a.id_content = i_id_content(i)
                               AND a.flg_type = g_imgexam_type
                             ORDER BY flg_available DESC)
                     WHERE rownum = 1;
                
                ELSIF i_table(i) = 'OTHER_EXAM'
                THEN
                
                    SELECT *
                      INTO l_id_aux, l_status_aux
                      FROM (SELECT a.id_exam, a.flg_available
                              FROM exam a
                             WHERE a.id_content = i_id_content(i)
                               AND a.flg_type = g_otherexam_type
                             ORDER BY flg_available DESC)
                     WHERE rownum = 1;
                
                ELSIF i_table(i) = 'PROCEDURE'
                THEN
                
                    SELECT *
                      INTO l_id_aux, l_status_aux
                      FROM (SELECT a.id_intervention, a.flg_status
                              FROM intervention a
                             WHERE a.id_content = i_id_content(i)
                               AND a.flg_category_type = 'P'
                             ORDER BY flg_status)
                     WHERE rownum = 1;
                
                ELSIF i_table(i) = 'PROCEDURE_CATEGORY'
                THEN
                
                    SELECT *
                      INTO l_id_aux, l_status_aux
                      FROM (SELECT a.id_interv_category, a.flg_available
                              FROM interv_category a
                             WHERE a.id_content = i_id_content(i)
                             ORDER BY flg_available DESC)
                     WHERE rownum = 1;
                
                ELSIF i_table(i) = 'SURGICAL_PROCEDURE'
                THEN
                
                    SELECT *
                      INTO l_id_aux, l_status_aux
                      FROM (SELECT a.id_intervention, a.flg_status
                              FROM intervention a
                             WHERE a.id_content = i_id_content(i)
                               AND a.flg_category_type = g_sr_intervention
                             ORDER BY flg_status)
                     WHERE rownum = 1;
                
                END IF;
            
                IF l_status_aux IN ('N', 'I')
                   AND i_show_errors(i) = 1
                THEN
                    l_error := 'The ' || i_table(i) || ': ' || i_id_content(i) ||
                               ' is unavailable. Please make it available before performing this operation';
                    RAISE g_exception;
                END IF;
            
                l_ids.extend;
                l_ids(i) := l_id_aux;
                l_status.extend;
                l_status(i) := l_status_aux;
            
            EXCEPTION
                WHEN no_data_found THEN
                
                    IF i_show_errors(i) = 0
                    THEN
                        l_ids.extend;
                        l_ids(i) := 0;
                        l_status.extend;
                        l_status(i) := NULL;
                    ELSE
                        l_error := i_table(i) || ': ' || i_id_content(i) || ' does not exist!';
                        RAISE g_exception;
                    END IF;
                
                WHEN too_many_rows THEN
                    l_error := i_table(i) || ': ' || i_id_content(i) || ' is duplicated!';
                    RAISE g_exception;
            END;
        
        END LOOP;
    
        o_results := l_ids;
        o_status  := l_status;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            raise_application_error(-20001, nvl(l_error, SQLERRM));
            pk_alert_exceptions.process_error(i_id_language,
                                              SQLCODE,
                                              SQLERRM,
                                              l_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            l_error := NULL;
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
        
    END validate_content;

    FUNCTION validate_mandatory_fields
    (
        i_id_language        IN NUMBER,
        i_id_institution     IN NUMBER,
        i_field_number       IN table_number,
        i_field_varchar      IN table_varchar,
        i_field_name_number  IN table_varchar,
        i_field_name_varchar IN table_varchar
    ) RETURN BOOLEAN IS
        l_error VARCHAR2(4000);
    BEGIN
    
        FOR i IN 1 .. i_field_number.count
        LOOP
        
            IF i_field_number(i) IS NULL
            THEN
                l_error := i_field_name_number(i) || ' cannot be empty!';
                RAISE g_exception;
            END IF;
        END LOOP;
    
        FOR i IN 1 .. i_field_varchar.count
        LOOP
        
            IF i_field_varchar(i) IS NULL
            THEN
                l_error := i_field_name_varchar(i) || ' cannot be empty!';
                RAISE g_exception;
            END IF;
        END LOOP;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            raise_application_error(-20001, nvl(l_error, SQLERRM));
            pk_alert_exceptions.process_error(i_id_language,
                                              SQLCODE,
                                              SQLERRM,
                                              l_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            l_error := NULL;
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
        
    END validate_mandatory_fields;

    PROCEDURE validate_description_exists
    (
        i_id_language      NUMBER,
        i_desc_content     VARCHAR,
        i_table            VARCHAR,
        i_table_schema     VARCHAR,
        i_code_translation VARCHAR
    ) IS
        l_id_aux NUMBER;
        l_ids    table_number := table_number();
        l_error  VARCHAR2(4000);
        l_sql    VARCHAR2(4000);
    BEGIN
    
        IF i_desc_content IS NULL
        THEN
            l_error := i_table || ' has no description!';
            RAISE g_exception;
        END IF;
    
        IF i_table = 'INTERVENTION'
        THEN
            l_sql := 'select nvl((SELECT distinct 1
FROM (SELECT pk_cmt_content_core.format_prepare_for_search(:desc_content) AS desc_origin
FROM dual) a
JOIN (SELECT pk_cmt_content_core.format_prepare_for_search(desc_translation) AS desc_search
FROM TABLE(pk_translation.get_search_translation(:id_language, :desc_content, ''' || i_table || '.' ||
                     i_code_translation || ''')) t
JOIN ' || i_table_schema || '.' || i_table || ' a
ON t.code_translation = a.' || i_code_translation || '
WHERE a.flg_status = ''A'') tmp
ON tmp.desc_search = a.desc_origin),0) as id_cnt from dual';
        ELSE
            l_sql := 'select nvl((SELECT distinct 1
FROM (SELECT pk_cmt_content_core.format_prepare_for_search(:desc_content) AS desc_origin
FROM dual) a
JOIN (SELECT pk_cmt_content_core.format_prepare_for_search(desc_translation) AS desc_search
FROM TABLE(pk_translation.get_search_translation(:id_language, :desc_content, ''' || i_table || '.' ||
                     i_code_translation || ''')) t
JOIN ' || i_table_schema || '.' || i_table || ' a
ON t.code_translation = a.' || i_code_translation || '
WHERE a.flg_available = ''Y'') tmp
ON tmp.desc_search = a.desc_origin),0) as id_cnt from dual';
        END IF;
    
        EXECUTE IMMEDIATE l_sql
            INTO l_id_aux
            USING i_desc_content, i_id_language, i_desc_content;
    
        IF l_id_aux = 1
        THEN
            l_error := 'There is already a ' || i_table || ' with the same description! Please validate!';
            RAISE g_exception;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            raise_application_error(-20001, nvl(l_error, SQLERRM));
            pk_alert_exceptions.process_error(i_id_language,
                                              SQLCODE,
                                              SQLERRM,
                                              l_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            l_error := NULL;
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
        
    END;

    PROCEDURE set_lab_test_sample_type_avlb
    (
        i_action                      VARCHAR,
        i_id_language                 VARCHAR,
        i_id_institution              NUMBER,
        i_id_software                 NUMBER,
        i_id_cnt_lab_test_sample_type VARCHAR,
        i_id_cnt_lab_test_cat         VARCHAR,
        i_id_cnt_sample_recipient     VARCHAR,
        i_id_room_execution           NUMBER,
        i_id_room_harvest             NUMBER,
        i_id_lab_test_parameter       NUMBER,
        i_flg_fill_type_parameter     VARCHAR,
        i_flg_mov_pat                 VARCHAR,
        i_flg_first_result            VARCHAR,
        i_flg_mov_recipient           VARCHAR,
        i_flg_harvest                 VARCHAR,
        i_flg_execute                 VARCHAR,
        i_flg_justify                 VARCHAR,
        i_flg_interface               VARCHAR,
        i_flg_duplicate_warn          VARCHAR,
        i_flg_priority                VARCHAR,
        i_harvest_instructions        VARCHAR
    ) IS
    
        l_id_sample_type      NUMBER;
        l_id_analysis         NUMBER;
        l_id_exam_cat         NUMBER;
        l_id_sample_recipient NUMBER;
        l_id_parameter        NUMBER;
        l_error               VARCHAR2(4000);
        l_bool                BOOLEAN;
        l_ids                 table_number;
        l_status              table_varchar;
    
    BEGIN
        g_func_name := 'set_lab_test_sample_type_avlb';
    
        l_bool := validate_content(i_id_language,
                                   i_id_institution,
                                   table_varchar(i_id_cnt_sample_recipient,
                                                 i_id_cnt_lab_test_sample_type,
                                                 i_id_cnt_lab_test_sample_type,
                                                 i_id_lab_test_parameter,
                                                 i_id_cnt_lab_test_cat,
                                                 i_id_room_execution,
                                                 i_id_room_harvest),
                                   table_varchar('SAMPLE_RECIPIENT',
                                                 'LAB_TEST_SAMPLE_TYPE (LABTEST)',
                                                 'LAB_TEST_SAMPLE_TYPE (SAMPLE_TYPE)',
                                                 'LAB_TEST_PARAMETER',
                                                 'EXAM_CAT_LABTEST',
                                                 'ROOM',
                                                 'ROOM'),
                                   table_number(1, 1, 1, 1, 1, 1, 1),
                                   l_ids,
                                   l_status);
    
        l_id_sample_recipient := l_ids(1);
        l_id_analysis         := l_ids(2);
        l_id_sample_type      := l_ids(3);
        l_id_parameter        := l_ids(4);
        l_id_exam_cat         := l_ids(5);
    
        IF (i_action = g_flg_create OR i_action = g_flg_update)
        THEN
        
            BEGIN
                INSERT INTO analysis_instit_soft
                    (id_analysis_instit_soft,
                     id_analysis,
                     flg_type,
                     id_institution,
                     id_software,
                     flg_mov_pat,
                     flg_first_result,
                     flg_mov_recipient,
                     flg_harvest,
                     id_exam_cat,
                     rank,
                     cost,
                     price,
                     adw_last_update,
                     id_analysis_group,
                     flg_execute,
                     flg_justify,
                     flg_interface,
                     flg_chargeable,
                     flg_available,
                     flg_duplicate_warn,
                     flg_collection_author,
                     id_sample_type,
                     flg_priority,
                     harvest_instructions)
                VALUES
                    (seq_analysis_instit_soft.nextval,
                     l_id_analysis,
                     g_flg_searchable,
                     i_id_institution,
                     i_id_software,
                     i_flg_mov_pat,
                     i_flg_first_result,
                     i_flg_mov_recipient,
                     i_flg_harvest,
                     l_id_exam_cat,
                     g_rank_zero,
                     NULL,
                     NULL,
                     SYSDATE,
                     NULL,
                     i_flg_execute,
                     i_flg_justify,
                     i_flg_interface,
                     NULL,
                     g_flg_available,
                     i_flg_duplicate_warn,
                     NULL,
                     l_id_sample_type,
                     i_flg_priority,
                     i_harvest_instructions);
            
            EXCEPTION
                WHEN dup_val_on_index THEN
                
                    UPDATE analysis_instit_soft
                       SET flg_available        = g_flg_available,
                           flg_mov_pat          = i_flg_mov_pat,
                           flg_first_result     = i_flg_first_result,
                           flg_mov_recipient    = i_flg_mov_recipient,
                           flg_harvest          = i_flg_harvest,
                           flg_execute          = i_flg_execute,
                           flg_justify          = i_flg_justify,
                           flg_interface        = i_flg_interface,
                           flg_duplicate_warn   = i_flg_duplicate_warn,
                           id_exam_cat          = l_id_exam_cat,
                           flg_priority         = i_flg_priority,
                           flg_type             = g_flg_searchable,
                           harvest_instructions = i_harvest_instructions
                     WHERE id_analysis = l_id_analysis
                       AND flg_type IN (g_flg_searchable, g_flg_executable, 'E', 'X')
                       AND id_institution = i_id_institution
                       AND id_software = i_id_software
                       AND id_sample_type = l_id_sample_type;
                
            END;
        
            BEGIN
                INSERT INTO analysis_instit_soft
                    (id_analysis_instit_soft,
                     id_analysis,
                     flg_type,
                     id_institution,
                     id_software,
                     flg_mov_pat,
                     flg_first_result,
                     flg_mov_recipient,
                     flg_harvest,
                     id_exam_cat,
                     rank,
                     cost,
                     price,
                     adw_last_update,
                     id_analysis_group,
                     flg_execute,
                     flg_justify,
                     flg_interface,
                     flg_chargeable,
                     flg_available,
                     flg_duplicate_warn,
                     flg_collection_author,
                     id_sample_type,
                     flg_priority,
                     harvest_instructions)
                VALUES
                    (seq_analysis_instit_soft.nextval,
                     l_id_analysis,
                     g_flg_searchable,
                     i_id_institution,
                     g_lab_technician,
                     i_flg_mov_pat,
                     i_flg_first_result,
                     i_flg_mov_recipient,
                     i_flg_harvest,
                     l_id_exam_cat,
                     g_rank_zero,
                     NULL,
                     NULL,
                     SYSDATE,
                     NULL,
                     i_flg_execute,
                     i_flg_justify,
                     i_flg_interface,
                     NULL,
                     g_flg_available,
                     i_flg_duplicate_warn,
                     NULL,
                     l_id_sample_type,
                     i_flg_priority,
                     i_harvest_instructions);
            
            EXCEPTION
                WHEN dup_val_on_index THEN
                
                    UPDATE analysis_instit_soft
                       SET flg_available        = g_flg_available,
                           flg_mov_pat          = i_flg_mov_pat,
                           flg_first_result     = i_flg_first_result,
                           flg_mov_recipient    = i_flg_mov_recipient,
                           flg_harvest          = i_flg_harvest,
                           flg_execute          = i_flg_execute,
                           flg_justify          = i_flg_justify,
                           flg_interface        = i_flg_interface,
                           flg_duplicate_warn   = i_flg_duplicate_warn,
                           id_exam_cat          = l_id_exam_cat,
                           flg_priority         = i_flg_priority,
                           flg_type             = g_flg_searchable,
                           harvest_instructions = i_harvest_instructions
                     WHERE id_analysis = l_id_analysis
                       AND flg_type IN (g_flg_searchable, g_flg_executable, 'E', 'X')
                       AND id_institution = i_id_institution
                       AND id_software = g_lab_technician
                       AND id_sample_type = l_id_sample_type;
                
            END;
        
            set_lab_test_param(i_id_language,
                               i_id_institution,
                               i_id_software,
                               l_id_parameter,
                               l_id_analysis,
                               l_id_sample_type,
                               100,
                               i_flg_fill_type_parameter);
        
            set_lab_test_param(i_id_language,
                               i_id_institution,
                               g_lab_technician,
                               l_id_parameter,
                               l_id_analysis,
                               l_id_sample_type,
                               100,
                               i_flg_fill_type_parameter);
        
            set_lab_test_recipient(i_id_language,
                                   i_id_institution,
                                   i_id_software,
                                   l_id_sample_recipient,
                                   l_id_analysis,
                                   l_id_sample_type,
                                   'Y');
        
            set_lab_test_recipient(i_id_language,
                                   i_id_institution,
                                   g_lab_technician,
                                   l_id_sample_recipient,
                                   l_id_analysis,
                                   l_id_sample_type,
                                   'Y');
        
            set_lab_test_room(i_id_language,
                              i_id_institution,
                              i_id_room_execution,
                              'T',
                              l_id_analysis,
                              l_id_sample_type,
                              0,
                              'Y');
        
            set_lab_test_room(i_id_language,
                              i_id_institution,
                              i_id_room_harvest,
                              'M',
                              l_id_analysis,
                              l_id_sample_type,
                              0,
                              'Y');
        
        ELSIF i_action = g_flg_delete
        THEN
            UPDATE analysis_instit_soft
               SET flg_type = g_flg_executable
             WHERE id_analysis = l_id_analysis
               AND flg_type = g_flg_searchable
               AND id_institution = i_id_institution
               AND id_software = i_id_software
               AND id_sample_type = l_id_sample_type;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            raise_application_error(-20001, nvl(l_error, SQLERRM));
            pk_alert_exceptions.process_error(i_id_language,
                                              SQLCODE,
                                              SQLERRM,
                                              l_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            l_error := NULL;
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
    END;

    PROCEDURE set_lab_test_freq
    (
        i_action                      VARCHAR,
        i_id_cnt_lab_test_sample_type VARCHAR,
        i_id_institution              NUMBER,
        i_id_software                 NUMBER,
        i_id_dep_clin_serv            NUMBER
    ) IS
    
        l_analysis_sample_type VARCHAR2(100);
        --l_id_dep_clin_serv     NUMBER;
        l_exists NUMBER;
    
        l_action VARCHAR(1);
    
    BEGIN
        g_func_name := 'set_lab_test_freq';
    
        SELECT nvl((SELECT a.id_analysis
                     FROM analysis_sample_type a
                    WHERE id_content = i_id_cnt_lab_test_sample_type
                      AND a.flg_available = g_flg_available),
                   0)
          INTO l_exists
          FROM dual;
    
        /*        SELECT nvl((SELECT DISTINCT c.id_dep_clin_serv
                   FROM clinical_service a
                   JOIN dep_clin_serv c
                     ON c.id_clinical_service = a.id_clinical_service
                   JOIN department d
                     ON d.id_department = c.id_department
                   JOIN dept de
                     ON de.id_dept = d.id_dept
                   JOIN software_dept sd
                     ON sd.id_dept = de.id_dept
                   JOIN institution i
                     ON i.id_institution = d.id_institution
                    AND i.id_institution = de.id_institution
                  WHERE d.id_institution IN (i_id_institution)
                    AND sd.id_software IN (i_id_software)
                    AND d.flg_available = g_flg_available
                    AND c.flg_available = g_flg_available
                    AND a.flg_available = g_flg_available
                    AND de.flg_available = g_flg_available
                    AND a.id_content = i_id_cnt_clinical_service
                    AND d.id_department = i_id_department),
                 0)
        INTO l_id_dep_clin_serv
        FROM dual;*/
    
        IF l_exists != 0
           AND i_id_dep_clin_serv != 0
        THEN
        
            SELECT a.id_analysis || '|' || a.id_sample_type
              INTO l_analysis_sample_type
              FROM analysis_sample_type a
             WHERE id_content = i_id_cnt_lab_test_sample_type
               AND a.flg_available = g_flg_available;
        
            IF i_action = g_flg_create
            THEN
                l_action := g_pk_apex_most_freq_create;
            ELSIF i_action = g_flg_delete
            THEN
                l_action := g_pk_apex_most_freq_delete;
            
            END IF;
            alert_apex_tools.pk_apex_most_freq.set_freq(i_lang           => g_default_language,
                                                        i_id_institution => i_id_institution,
                                                        i_id_software    => i_id_software,
                                                        i_operation      => l_action,
                                                        flg_context      => g_pk_apex_most_freq_by_dcs,
                                                        flg_content      => g_pk_apex_most_freq_lab_test,
                                                        id_context       => table_varchar(i_id_dep_clin_serv),
                                                        id_content       => table_varchar(l_analysis_sample_type));
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            raise_application_error(-20001, SQLERRM);
            pk_alert_exceptions.process_error(g_language,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
    END;

    PROCEDURE set_lab_test_sample_type_prp
    (
        i_action                      VARCHAR,
        i_id_language                 VARCHAR,
        i_id_institution              NUMBER,
        i_id_software                 NUMBER,
        i_id_cnt_lab_test_sample_type VARCHAR,
        i_flg_mov_pat                 VARCHAR,
        i_flg_first_result            VARCHAR,
        i_flg_mov_recipient           VARCHAR,
        i_flg_harvest                 VARCHAR,
        i_flg_execute                 VARCHAR,
        i_flg_justify                 VARCHAR,
        i_flg_interface               VARCHAR,
        i_flg_duplicate_warn          VARCHAR,
        i_id_cnt_exam_cat             VARCHAR
    ) IS
    
        l_id_exam_cat    NUMBER;
        l_id_sample_type NUMBER;
        l_id_analysis    NUMBER;
    BEGIN
        g_func_name := 'set_lab_test_sample_type_prp';
        SELECT nvl((SELECT a.id_exam_cat
                     FROM exam_cat a
                    WHERE a.id_content = i_id_cnt_exam_cat
                      AND a.flg_available = g_flg_available),
                   0)
          INTO l_id_exam_cat
          FROM dual;
    
        IF l_id_exam_cat > 0
        THEN
        
            BEGIN
                SELECT a.id_analysis, a.id_sample_type
                  INTO l_id_analysis, l_id_sample_type
                  FROM analysis_sample_type a
                 WHERE a.flg_available = g_flg_available
                   AND id_content = i_id_cnt_lab_test_sample_type;
            
            EXCEPTION
                WHEN OTHERS THEN
                    --raise_application_error(-20001, SQLERRM);
                    l_id_analysis    := 0;
                    l_id_sample_type := 0;
            END;
        
            IF i_action = g_flg_create
            THEN
            
                INSERT INTO analysis_instit_soft
                    (id_analysis_instit_soft,
                     id_analysis,
                     flg_type,
                     id_institution,
                     id_software,
                     flg_mov_pat,
                     flg_first_result,
                     flg_mov_recipient,
                     flg_harvest,
                     id_exam_cat,
                     rank,
                     cost,
                     price,
                     adw_last_update,
                     id_analysis_group,
                     flg_execute,
                     flg_justify,
                     flg_interface,
                     flg_chargeable,
                     flg_available,
                     flg_duplicate_warn,
                     flg_collection_author,
                     id_sample_type)
                VALUES
                    (seq_analysis_instit_soft.nextval,
                     l_id_analysis,
                     g_flg_searchable,
                     i_id_institution,
                     i_id_software,
                     i_flg_mov_pat,
                     i_flg_first_result,
                     i_flg_mov_recipient,
                     i_flg_harvest,
                     l_id_exam_cat,
                     g_rank_zero,
                     NULL,
                     NULL,
                     SYSDATE,
                     NULL,
                     i_flg_execute,
                     i_flg_justify,
                     i_flg_interface,
                     NULL,
                     g_flg_available,
                     i_flg_duplicate_warn,
                     NULL,
                     l_id_sample_type);
            
            ELSIF i_action = g_flg_update
            THEN
            
                UPDATE analysis_instit_soft
                   SET flg_mov_pat        = i_flg_mov_pat,
                       flg_first_result   = i_flg_first_result,
                       flg_mov_recipient  = i_flg_mov_recipient,
                       flg_harvest        = i_flg_harvest,
                       flg_execute        = i_flg_execute,
                       flg_justify        = i_flg_justify,
                       flg_interface      = i_flg_interface,
                       flg_duplicate_warn = i_flg_duplicate_warn,
                       id_exam_cat        = l_id_exam_cat
                 WHERE id_analysis = l_id_analysis
                   AND flg_type = g_flg_searchable
                   AND id_institution = i_id_institution
                   AND id_software = i_id_software
                   AND id_sample_type = l_id_sample_type;
            
            ELSIF i_action = g_flg_delete
            THEN
            
                UPDATE analysis_instit_soft
                   SET flg_available = g_flg_no
                 WHERE id_analysis = l_id_analysis
                   AND flg_type = g_flg_searchable
                   AND id_institution = i_id_institution
                   AND id_software = i_id_software
                   AND id_sample_type = l_id_sample_type;
            END IF;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            raise_application_error(-20001, SQLERRM);
            pk_alert_exceptions.process_error(i_id_language,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
    END;

    PROCEDURE set_exam_alias
    (
        i_id_language    VARCHAR,
        i_id_institution NUMBER,
        i_id_software    NUMBER,
        i_id_cnt_exam    VARCHAR,
        i_desc_alias     VARCHAR
    ) IS
    
        l_id_exam_alias NUMBER;
        l_exam          NUMBER;
    
    BEGIN
    
        SELECT nvl((SELECT a.id_exam
                     FROM exam a
                    WHERE a.id_content = i_id_cnt_exam
                      AND a.flg_available = g_flg_available),
                   0)
          INTO l_exam
          FROM dual;
    
        SELECT nvl((SELECT a.id_exam_alias
                     FROM exam_alias a
                    WHERE a.id_exam = l_exam
                      AND a.id_institution = i_id_institution
                      AND a.id_software = i_id_software),
                   0)
          INTO l_id_exam_alias
          FROM dual;
    
        IF l_id_exam_alias = 0
           AND i_desc_alias IS NOT NULL
        THEN
            SELECT nvl((SELECT MAX(a.id_exam_alias) + 1
                         FROM exam_alias a),
                       0)
              INTO l_id_exam_alias
              FROM dual;
        
            INSERT INTO exam_alias
                (id_exam_alias,
                 id_exam,
                 code_exam_alias,
                 id_institution,
                 id_software,
                 id_professional,
                 id_dep_clin_serv,
                 adw_last_update)
            VALUES
                (l_id_exam_alias,
                 l_exam,
                 'EXAM_ALIAS.CODE_EXAM_ALIAS.' || l_id_exam_alias,
                 i_id_institution,
                 i_id_software,
                 NULL,
                 NULL,
                 SYSDATE);
        
            pk_translation.insert_into_translation(i_id_language,
                                                   'EXAM_ALIAS.CODE_EXAM_ALIAS.' || l_id_exam_alias,
                                                   i_desc_alias);
        ELSIF l_id_exam_alias > 0
              AND i_desc_alias IS NOT NULL
        THEN
        
            pk_translation.insert_into_translation(i_id_language,
                                                   'EXAM_ALIAS.CODE_EXAM_ALIAS.' || l_id_exam_alias,
                                                   i_desc_alias);
        
        ELSIF l_id_exam_alias > 0
              AND i_desc_alias IS NULL
        THEN
        
            DELETE FROM exam_alias a
             WHERE a.id_exam = l_exam
               AND a.id_institution = i_id_institution
               AND a.id_software = i_id_software;
        
        END IF;
    
    END;

    PROCEDURE set_procedure_alias
    (
        i_id_language      VARCHAR,
        i_id_institution   NUMBER,
        i_id_software      NUMBER,
        i_id_cnt_procedure VARCHAR,
        i_desc_alias       VARCHAR
    ) IS
    
        l_id_procedure_alias NUMBER;
        l_procedure          NUMBER;
        l_cat_prof           table_number := table_number(1, 2, 23, 29);
    
    BEGIN
    
        SELECT nvl((SELECT a.id_intervention
                     FROM intervention a
                    WHERE a.id_content = i_id_cnt_procedure
                      AND a.flg_status = g_flg_active),
                   0)
          INTO l_procedure
          FROM dual;
    
        SELECT nvl((SELECT a.id_intervention_alias
                     FROM intervention_alias a
                    WHERE a.id_intervention = l_procedure
                      AND a.id_institution = i_id_institution
                      AND a.id_software IN (g_soft_zero, i_id_software)
                      AND rownum = 1),
                   0)
          INTO l_id_procedure_alias
          FROM dual;
    
        IF l_id_procedure_alias = 0
           AND i_desc_alias IS NOT NULL
        THEN
        
            FOR i IN 1 .. l_cat_prof.count
            LOOP
            
                SELECT nvl((SELECT MAX(id_intervention_alias) + 1
                             FROM intervention_alias),
                           1)
                  INTO l_id_procedure_alias
                  FROM dual;
            
                INSERT INTO intervention_alias
                    (id_intervention_alias,
                     code_intervention_alias,
                     id_intervention,
                     id_category,
                     id_institution,
                     id_software,
                     id_dep_clin_serv,
                     id_professional)
                VALUES
                    (l_id_procedure_alias,
                     'INTERVENTION_ALIAS.CODE_INTERVENTION_ALIAS.' || l_id_procedure_alias,
                     l_procedure,
                     l_cat_prof(i),
                     i_id_institution,
                     g_soft_zero,
                     NULL,
                     NULL);
            
                pk_translation.insert_into_translation(i_id_language,
                                                       'INTERVENTION_ALIAS.CODE_INTERVENTION_ALIAS.' ||
                                                       l_id_procedure_alias,
                                                       i_desc_alias);
            
            END LOOP;
        
        ELSIF l_id_procedure_alias > 0
              AND i_desc_alias IS NOT NULL
        THEN
        
            FOR i IN (SELECT a.code_intervention_alias
                        FROM intervention_alias a
                       WHERE a.id_intervention = l_procedure
                         AND a.id_institution = i_id_institution
                         AND a.id_software IN (g_soft_zero, i_id_software))
            LOOP
            
                pk_translation.insert_into_translation(i_id_language, i.code_intervention_alias, i_desc_alias);
            
            END LOOP;
        
        ELSIF l_id_procedure_alias > 0
              AND i_desc_alias IS NULL
        THEN
        
            DELETE FROM intervention_alias a
             WHERE a.id_intervention = l_procedure
               AND a.id_institution = i_id_institution;
        
        END IF;
    
    END;

    PROCEDURE set_other_exam_ctlg
    (
        i_action            VARCHAR,
        i_id_language       VARCHAR,
        i_id_institution    NUMBER,
        i_id_software       NUMBER,
        i_id_cnt_other_exam VARCHAR,
        i_desc_other_exam   VARCHAR,
        i_desc_alias        VARCHAR,
        i_id_cnt_exam_cat   VARCHAR,
        i_age_min           NUMBER,
        i_age_max           NUMBER,
        i_gender            VARCHAR,
        i_flg_mov_pat       VARCHAR,
        i_flg_pat_resp      VARCHAR,
        i_flg_pat_prep      VARCHAR,
        i_flg_technical     VARCHAR DEFAULT 'N'
    ) IS
    
        l_cod_exam exam.code_exam%TYPE;
    
        l_exam          NUMBER;
        l_exam_status   VARCHAR2(1);
        l_cnt_exam_cat  NUMBER;
        l_id_exam_alias NUMBER;
        l_room          NUMBER;
        l_error         VARCHAR2(4000);
        l_bool          BOOLEAN;
        l_ids           table_number;
        l_status        table_varchar;
        l_id_softwares  table_number;
    BEGIN
    
        g_func_name := 'set_other_exam_ctlg';
    
        l_bool := validate_content(i_id_language,
                                   i_id_institution,
                                   table_varchar(i_id_cnt_other_exam, i_id_cnt_exam_cat),
                                   table_varchar('OTHER_EXAM', 'EXAM_CAT_EXAM'),
                                   table_number(0, 1),
                                   l_ids,
                                   l_status);
    
        l_exam         := l_ids(1);
        l_exam_status  := l_status(1);
        l_cnt_exam_cat := l_ids(2);
    
        IF l_exam = 0
        THEN
        
            IF i_action IN (g_flg_create, g_flg_update)
            THEN
            
                validate_description_exists(i_id_language, i_desc_other_exam, 'EXAM', 'ALERT', 'CODE_EXAM');
            
                SELECT seq_exam.nextval
                  INTO l_exam
                  FROM dual;
            
                INSERT INTO exam
                    (id_exam,
                     code_exam,
                     flg_available,
                     rank,
                     adw_last_update,
                     id_content,
                     id_exam_cat,
                     flg_type,
                     age_min,
                     age_max,
                     gender,
                     flg_technical)
                VALUES
                    (l_exam,
                     'EXAM.CODE_EXAM.' || l_exam,
                     g_flg_available,
                     g_rank_zero,
                     SYSDATE,
                     i_id_cnt_other_exam,
                     l_cnt_exam_cat,
                     g_otherexam_type,
                     i_age_min,
                     i_age_max,
                     i_gender,
                     i_flg_technical);
            
                SELECT e.code_exam
                  INTO l_cod_exam
                  FROM exam e
                 WHERE e.id_exam = l_exam;
            
                pk_translation.insert_into_translation(i_id_language, l_cod_exam, i_desc_other_exam);
            
                SELECT DISTINCT id
                  BULK COLLECT
                  INTO l_id_softwares
                  FROM (SELECT s.id_ab_software id
                          FROM software_institution si, ab_software s
                         WHERE si.id_software = s.id_ab_software
                           AND (s.flg_viewer = 'N' OR s.flg_viewer IS NULL)
                           AND si.id_institution = i_id_institution
                           AND si.id_software IN (1, 2, 3, 8, 11, 12, 25, 33, 36, 310, 312));
            
                FOR i IN 1 .. l_id_softwares.count
                LOOP
                
                    set_exam_alias(i_id_language,
                                   i_id_institution,
                                   l_id_softwares(i),
                                   i_id_cnt_other_exam,
                                   i_desc_alias);
                
                END LOOP;
            
            END IF;
        
        ELSIF l_exam != 0
        THEN
        
            IF i_action = g_flg_create
            THEN
            
                IF l_exam_status = 'Y'
                THEN
                    l_error := 'ID_CONTENT to be created already exists!';
                    RAISE g_exception;
                ELSIF l_exam_status = 'N'
                THEN
                    UPDATE exam
                       SET flg_available = g_flg_available
                     WHERE id_content = i_id_cnt_other_exam;
                END IF;
            
            ELSIF i_action = g_flg_update
            THEN
            
                UPDATE exam a
                   SET flg_available = g_flg_available,
                       age_min       = i_age_min,
                       age_max       = i_age_max,
                       gender        = i_gender,
                       id_exam_cat   = l_cnt_exam_cat,
                       flg_technical = i_flg_technical
                 WHERE a.id_exam = l_exam;
            
                SELECT DISTINCT id
                  BULK COLLECT
                  INTO l_id_softwares
                  FROM (SELECT s.id_ab_software id
                          FROM software_institution si, ab_software s
                         WHERE si.id_software = s.id_ab_software
                           AND (s.flg_viewer = 'N' OR s.flg_viewer IS NULL)
                           AND si.id_institution = i_id_institution
                           AND si.id_software IN (1, 2, 3, 8, 11, 12, 25, 33, 36, 310, 312));
            
                FOR i IN 1 .. l_id_softwares.count
                LOOP
                
                    set_exam_alias(i_id_language,
                                   i_id_institution,
                                   l_id_softwares(i),
                                   i_id_cnt_other_exam,
                                   i_desc_alias);
                
                END LOOP;
            
            ELSIF i_action = g_flg_delete
            THEN
            
                UPDATE exam
                   SET flg_available = g_flg_no
                 WHERE id_content = i_id_cnt_other_exam;
            
            END IF;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            raise_application_error(-20001, nvl(l_error, SQLERRM));
            pk_alert_exceptions.process_error(i_id_language,
                                              SQLCODE,
                                              SQLERRM,
                                              l_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            l_error := NULL;
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
        
    END;

    PROCEDURE set_other_exam_avlb
    (
        i_action            VARCHAR,
        i_id_language       VARCHAR,
        i_id_institution    NUMBER,
        i_id_software       NUMBER,
        i_desc_alias        VARCHAR,
        i_id_cnt_other_exam VARCHAR,
        i_flg_first_result  VARCHAR,
        i_flg_execute       VARCHAR,
        i_flg_mov_pat       VARCHAR,
        i_flg_timeout       VARCHAR,
        i_flg_result_notes  VARCHAR,
        i_flg_first_execute VARCHAR,
        i_flg_chargeable    VARCHAR,
        i_flg_priority      VARCHAR,
        i_id_room           NUMBER
    ) IS
    
        l_cod_exam exam.code_exam%TYPE;
        l_exam     NUMBER;
        l_error    VARCHAR2(4000);
        l_bool     BOOLEAN;
        l_ids      table_number;
        l_status   table_varchar;
        l_room     NUMBER;
    
    BEGIN
        g_func_name := 'set_other_exam_avlb';
    
        IF (i_id_room IS NULL)
        THEN
        
            SELECT nvl((SELECT id_room
                         FROM (SELECT COUNT(*), id_room
                                 FROM exam_room er
                                 JOIN exam e
                                   ON e.id_exam = er.id_exam
                                  AND e.flg_type = 'E'
                                  AND id_room IN
                                      (SELECT id_room
                                         FROM room
                                        WHERE id_department IN
                                              (SELECT id_department
                                                 FROM department d
                                                WHERE id_institution = i_id_institution
                                                  AND d.id_dept IN (SELECT id_dept
                                                                      FROM software_dept
                                                                     WHERE id_software = i_id_software)))
                                GROUP BY id_room
                                ORDER BY 1 DESC)
                        WHERE rownum = 1),
                       0)
              INTO l_room
              FROM dual;
        
            IF (l_room = 0)
            THEN
                SELECT r.id_room
                  INTO l_room
                  FROM department d
                  JOIN dept de
                    ON de.id_dept = d.id_dept
                  JOIN institution i
                    ON i.id_institution = d.id_institution
                   AND i.id_institution = de.id_institution
                  JOIN room r
                    ON d.id_department = r.id_department
                   AND r.flg_available = g_flg_available
                 WHERE d.id_institution = i_id_institution
                   AND d.flg_available = g_flg_available
                   AND de.flg_available = g_flg_available
                   AND rownum = 1;
            END IF;
        ELSE
            l_room := i_id_room;
        END IF;
    
        l_bool := validate_content(i_id_language,
                                   i_id_institution,
                                   table_varchar(i_id_cnt_other_exam, l_room),
                                   table_varchar('OTHER_EXAM', 'ROOM'),
                                   table_number(1, 1),
                                   l_ids,
                                   l_status);
    
        l_exam := l_ids(1);
    
        IF l_exam != 0
           AND (i_action = g_flg_create OR i_action = g_flg_update)
        THEN
        
            BEGIN
                INSERT INTO exam_dep_clin_serv
                    (id_exam_dep_clin_serv,
                     id_exam,
                     flg_type,
                     rank,
                     id_institution,
                     id_software,
                     flg_first_result,
                     flg_execute,
                     flg_timeout,
                     flg_result_notes,
                     flg_first_execute,
                     flg_mov_pat,
                     flg_priority)
                    SELECT seq_exam_dep_clin_serv.nextval,
                           e.id_exam,
                           g_flg_searchable,
                           g_rank_zero,
                           i_id_institution,
                           i_id_software,
                           i_flg_first_result,
                           i_flg_execute,
                           i_flg_timeout,
                           i_flg_result_notes,
                           i_flg_first_execute,
                           i_flg_mov_pat,
                           i_flg_priority
                      FROM exam e
                     WHERE e.id_exam = l_exam;
            
            EXCEPTION
                WHEN dup_val_on_index THEN
                
                    UPDATE exam_dep_clin_serv a
                       SET a.flg_first_result  = i_flg_first_result,
                           a.flg_execute       = i_flg_execute,
                           a.flg_timeout       = i_flg_timeout,
                           a.flg_result_notes  = i_flg_result_notes,
                           a.flg_first_execute = i_flg_first_execute,
                           a.flg_mov_pat       = i_flg_mov_pat,
                           a.flg_chargeable    = i_flg_chargeable,
                           a.flg_priority      = i_flg_priority
                     WHERE a.id_exam = l_exam
                       AND a.id_software = i_id_software
                       AND a.id_dep_clin_serv IS NULL
                       AND a.id_institution = i_id_institution
                       AND a.flg_type = g_flg_searchable;
                
            END;
        
            pk_cmt_content_core.set_other_exam_room(g_flg_update_create,
                                                    i_id_institution,
                                                    i_id_language,
                                                    i_id_cnt_other_exam,
                                                    l_room,
                                                    0,
                                                    g_flg_available,
                                                    NULL);
        
        ELSIF i_action = g_flg_delete
        THEN
        
            DELETE FROM exam_room
             WHERE id_exam_dep_clin_serv IN (SELECT id_exam_dep_clin_serv
                                               FROM exam_dep_clin_serv a
                                              WHERE a.id_exam = l_exam
                                                AND a.id_software = i_id_software
                                                AND a.id_dep_clin_serv IS NULL
                                                AND a.id_institution = i_id_institution
                                                AND a.flg_type = g_flg_searchable);
        
            DELETE FROM exam_dep_clin_serv a
             WHERE a.id_exam = l_exam
               AND a.id_software = i_id_software
               AND a.id_dep_clin_serv IS NULL
               AND a.id_institution = i_id_institution
               AND a.flg_type = g_flg_searchable;
        
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            raise_application_error(-20001, nvl(l_error, SQLERRM));
            pk_alert_exceptions.process_error(i_id_language,
                                              SQLCODE,
                                              SQLERRM,
                                              l_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            l_error := NULL;
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
        
    END;

    PROCEDURE set_procedure_avlb
    (
        i_action               VARCHAR,
        i_id_language          VARCHAR,
        i_id_institution       NUMBER,
        i_id_software          NUMBER,
        i_desc_alias           VARCHAR,
        i_id_cnt_procedure     VARCHAR,
        i_id_cnt_procedure_cat VARCHAR,
        i_flg_execute          VARCHAR,
        i_flg_timeout          VARCHAR,
        i_flg_chargeable       VARCHAR,
        i_flg_priority         VARCHAR,
        i_rank                 NUMBER
    ) IS
    
        l_cod_procedure intervention.code_intervention%TYPE;
        l_procedure     NUMBER;
        l_procedure_cat NUMBER;
        l_error         VARCHAR2(4000);
        l_bool          BOOLEAN;
        l_ids           table_number;
        l_status        table_varchar;
    
    BEGIN
        g_func_name := 'set_procedure_avlb';
    
        l_bool := validate_content(i_id_language,
                                   i_id_institution,
                                   table_varchar(i_id_cnt_procedure),
                                   table_varchar('PROCEDURE'),
                                   table_number(1),
                                   l_ids,
                                   l_status);
    
        l_procedure := l_ids(1);
    
        IF l_procedure != 0
           AND (i_action = g_flg_create OR i_action = g_flg_update)
        THEN
        
            BEGIN
            
                INSERT INTO interv_dep_clin_serv
                    (id_interv_dep_clin_serv,
                     id_intervention,
                     flg_type,
                     rank,
                     id_institution,
                     id_software,
                     flg_bandaid,
                     flg_execute,
                     flg_priority,
                     flg_chargeable,
                     flg_timeout)
                    SELECT seq_interv_dep_clin_serv.nextval,
                           e.id_intervention,
                           g_flg_searchable,
                           i_rank,
                           i_id_institution,
                           i_id_software,
                           g_flg_no,
                           g_flg_available,
                           i_flg_priority,
                           i_flg_chargeable,
                           i_flg_timeout
                      FROM intervention e
                     WHERE e.id_intervention = l_procedure;
            
            EXCEPTION
                WHEN dup_val_on_index THEN
                
                    UPDATE interv_dep_clin_serv a
                       SET a.flg_execute    = i_flg_execute,
                           a.flg_timeout    = i_flg_timeout,
                           a.flg_chargeable = i_flg_chargeable,
                           a.flg_priority   = i_flg_priority,
                           a.rank           = i_rank
                     WHERE a.id_intervention = l_procedure
                       AND a.id_software = i_id_software
                       AND a.id_dep_clin_serv IS NULL
                       AND a.id_institution = i_id_institution
                       AND a.flg_type = g_flg_searchable;
                
            END;
        
        ELSIF i_action = g_flg_delete
        THEN
            DELETE FROM interv_dep_clin_serv a
             WHERE a.id_intervention = l_procedure
               AND a.id_software = i_id_software
               AND a.id_dep_clin_serv IS NULL
               AND a.id_institution = i_id_institution
               AND a.flg_type = g_flg_searchable;
        
        END IF;
    
        IF i_id_cnt_procedure_cat IS NOT NULL
        THEN
        
            l_bool := validate_content(i_id_language,
                                       i_id_institution,
                                       table_varchar(i_id_cnt_procedure_cat),
                                       table_varchar('PROCEDURE_CATEGORY'),
                                       table_number(1),
                                       l_ids,
                                       l_status);
        
            l_procedure_cat := l_ids(1);
        
        END IF;
    
        IF l_procedure_cat != 0
           AND (i_action = g_flg_create OR i_action = g_flg_update)
        THEN
        
            BEGIN
            
                set_procedure_by_category(g_flg_create,
                                          i_id_language,
                                          i_id_cnt_procedure,
                                          i_id_institution,
                                          i_id_software,
                                          i_id_cnt_procedure_cat,
                                          i_rank);
            
            END;
        
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            raise_application_error(-20001, nvl(l_error, SQLERRM));
            pk_alert_exceptions.process_error(i_id_language,
                                              SQLCODE,
                                              SQLERRM,
                                              l_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            l_error := NULL;
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
        
    END;

    PROCEDURE set_sr_procedure_avlb
    (
        i_action               VARCHAR,
        i_id_language          VARCHAR,
        i_id_institution       NUMBER,
        i_id_software          NUMBER,
        i_desc_alias           VARCHAR,
        i_id_cnt_sr_procedure  VARCHAR,
        i_id_cnt_procedure_cat VARCHAR,
        i_flg_execute          VARCHAR,
        i_flg_timeout          VARCHAR,
        i_flg_chargeable       VARCHAR,
        i_flg_priority         VARCHAR,
        i_rank                 NUMBER
    ) IS
    
        l_cod_procedure intervention.code_intervention%TYPE;
        l_procedure     NUMBER;
        l_procedure_cat NUMBER;
        l_error         VARCHAR2(4000);
        l_bool          BOOLEAN;
        l_ids           table_number;
        l_status        table_varchar;
    
    BEGIN
        g_func_name := 'set_sr_procedure_avlb';
    
        l_bool := validate_content(i_id_language,
                                   i_id_institution,
                                   table_varchar(i_id_cnt_sr_procedure),
                                   table_varchar('SURGICAL_PROCEDURE'),
                                   table_number(1),
                                   l_ids,
                                   l_status);
    
        l_procedure := l_ids(1);
    
        IF l_procedure != 0
           AND (i_action = g_flg_create OR i_action = g_flg_update)
        THEN
        
            BEGIN
            
                INSERT INTO interv_dep_clin_serv
                    (id_interv_dep_clin_serv,
                     id_intervention,
                     flg_type,
                     rank,
                     id_institution,
                     id_software,
                     flg_bandaid,
                     flg_execute,
                     flg_priority,
                     flg_chargeable,
                     flg_timeout)
                    SELECT seq_interv_dep_clin_serv.nextval,
                           e.id_intervention,
                           g_flg_searchable,
                           i_rank,
                           i_id_institution,
                           i_id_software,
                           g_flg_no,
                           g_flg_available,
                           i_flg_priority,
                           i_flg_chargeable,
                           i_flg_timeout
                      FROM intervention e
                     WHERE e.id_intervention = l_procedure;
            
            EXCEPTION
                WHEN dup_val_on_index THEN
                
                    UPDATE interv_dep_clin_serv a
                       SET a.flg_execute    = i_flg_execute,
                           a.flg_timeout    = i_flg_timeout,
                           a.flg_chargeable = i_flg_chargeable,
                           a.flg_priority   = i_flg_priority,
                           a.rank           = i_rank
                     WHERE a.id_intervention = l_procedure
                       AND a.id_software = i_id_software
                       AND a.id_dep_clin_serv IS NULL
                       AND a.id_institution = i_id_institution
                       AND a.flg_type = g_flg_searchable;
                
            END;
        
        ELSIF i_action = g_flg_delete
        THEN
            DELETE FROM interv_dep_clin_serv a
             WHERE a.id_intervention = l_procedure
               AND a.id_software = i_id_software
               AND a.id_dep_clin_serv IS NULL
               AND a.id_institution = i_id_institution
               AND a.flg_type = g_flg_searchable;
        
        END IF;
    
        IF i_id_cnt_procedure_cat IS NOT NULL
        THEN
        
            l_bool := validate_content(i_id_language,
                                       i_id_institution,
                                       table_varchar(i_id_cnt_procedure_cat),
                                       table_varchar('PROCEDURE_CATEGORY'),
                                       table_number(1),
                                       l_ids,
                                       l_status);
        
            l_procedure_cat := l_ids(1);
        
        END IF;
    
        IF l_procedure_cat != 0
           AND (i_action = g_flg_create OR i_action = g_flg_update)
        THEN
        
            BEGIN
            
                set_procedure_by_category(g_flg_create,
                                          i_id_language,
                                          i_id_cnt_sr_procedure,
                                          i_id_institution,
                                          i_id_software,
                                          i_id_cnt_procedure_cat,
                                          i_rank);
            
            END;
        
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            raise_application_error(-20001, nvl(l_error, SQLERRM));
            pk_alert_exceptions.process_error(i_id_language,
                                              SQLCODE,
                                              SQLERRM,
                                              l_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            l_error := NULL;
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
        
    END;

    PROCEDURE set_img_exam_ctlg
    (
        i_action          VARCHAR,
        i_id_language     VARCHAR,
        i_id_institution  NUMBER,
        i_id_software     NUMBER,
        i_id_cnt_img_exam VARCHAR,
        i_desc_img_exam   VARCHAR,
        i_desc_alias      VARCHAR,
        i_id_cnt_exam_cat VARCHAR,
        i_age_min         NUMBER,
        i_age_max         NUMBER,
        i_gender          VARCHAR,
        i_flg_mov_pat     VARCHAR,
        i_flg_pat_resp    VARCHAR,
        i_flg_pat_prep    VARCHAR,
        i_flg_technical   VARCHAR DEFAULT 'N'
    ) IS
    
        l_cod_exam exam.code_exam%TYPE;
    
        l_exam          NUMBER;
        l_exam_status   VARCHAR2(1);
        l_cnt_exam_cat  NUMBER;
        l_id_exam_alias NUMBER;
        l_room          NUMBER;
        l_error         VARCHAR2(4000);
        l_bool          BOOLEAN;
        l_ids           table_number;
        l_status        table_varchar;
        l_id_softwares  table_number;
    BEGIN
    
        g_func_name := 'set_img_exam_ctlg';
    
        l_bool := validate_content(i_id_language,
                                   i_id_institution,
                                   table_varchar(i_id_cnt_img_exam, i_id_cnt_exam_cat),
                                   table_varchar('IMAGE_EXAM', 'EXAM_CAT_EXAM'),
                                   table_number(0, 1),
                                   l_ids,
                                   l_status);
    
        l_exam         := l_ids(1);
        l_exam_status  := l_status(1);
        l_cnt_exam_cat := l_ids(2);
    
        IF l_exam = 0
        THEN
        
            IF i_action IN (g_flg_create, g_flg_update)
            THEN
            
                validate_description_exists(i_id_language, i_desc_img_exam, 'EXAM', 'ALERT', 'CODE_EXAM');
            
                SELECT seq_exam.nextval
                  INTO l_exam
                  FROM dual;
            
                INSERT INTO exam
                    (id_exam,
                     code_exam,
                     flg_available,
                     rank,
                     adw_last_update,
                     id_content,
                     id_exam_cat,
                     flg_type,
                     age_min,
                     age_max,
                     gender,
                     flg_technical)
                VALUES
                    (l_exam,
                     'EXAM.CODE_EXAM.' || l_exam,
                     g_flg_available,
                     g_rank_zero,
                     SYSDATE,
                     i_id_cnt_img_exam,
                     l_cnt_exam_cat,
                     g_imgexam_type,
                     i_age_min,
                     i_age_max,
                     i_gender,
                     i_flg_technical);
            
                SELECT e.code_exam
                  INTO l_cod_exam
                  FROM exam e
                 WHERE e.id_exam = l_exam;
            
                pk_translation.insert_into_translation(i_id_language, l_cod_exam, i_desc_img_exam);
            
                SELECT DISTINCT id
                  BULK COLLECT
                  INTO l_id_softwares
                  FROM (SELECT s.id_ab_software id
                          FROM software_institution si, ab_software s
                         WHERE si.id_software = s.id_ab_software
                           AND (s.flg_viewer = 'N' OR s.flg_viewer IS NULL)
                           AND si.id_institution = i_id_institution
                           AND si.id_software IN (1, 2, 3, 8, 11, 12, 15, 33, 36, 310, 312));
            
                FOR i IN 1 .. l_id_softwares.count
                LOOP
                
                    set_exam_alias(i_id_language, i_id_institution, l_id_softwares(i), i_id_cnt_img_exam, i_desc_alias);
                
                END LOOP;
            
            END IF;
        
        ELSIF l_exam != 0
        THEN
        
            IF i_action = g_flg_create
            THEN
                IF l_exam_status = 'Y'
                THEN
                    l_error := 'ID_CONTENT to be created already exists!';
                    RAISE g_exception;
                ELSIF l_exam_status = 'N'
                THEN
                    UPDATE exam
                       SET flg_available = g_flg_available
                     WHERE id_content = i_id_cnt_img_exam;
                END IF;
            
            ELSIF i_action = g_flg_update
            THEN
            
                UPDATE exam a
                   SET flg_available = g_flg_available,
                       age_min       = i_age_min,
                       age_max       = i_age_max,
                       gender        = i_gender,
                       id_exam_cat   = l_cnt_exam_cat,
                       flg_technical = i_flg_technical
                 WHERE a.id_exam = l_exam;
            
                SELECT DISTINCT id
                  BULK COLLECT
                  INTO l_id_softwares
                  FROM (SELECT s.id_ab_software id
                          FROM software_institution si, ab_software s
                         WHERE si.id_software = s.id_ab_software
                           AND (s.flg_viewer = 'N' OR s.flg_viewer IS NULL)
                           AND si.id_institution = i_id_institution
                           AND si.id_software IN (1, 2, 3, 8, 11, 12, 15, 33, 36, 310, 312));
            
                FOR i IN 1 .. l_id_softwares.count
                LOOP
                
                    set_exam_alias(i_id_language, i_id_institution, l_id_softwares(i), i_id_cnt_img_exam, i_desc_alias);
                
                END LOOP;
            
            ELSIF i_action = g_flg_delete
            THEN
            
                UPDATE exam
                   SET flg_available = g_flg_no
                 WHERE id_content = i_id_cnt_img_exam;
            
            END IF;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            raise_application_error(-20001, nvl(l_error, SQLERRM));
            pk_alert_exceptions.process_error(i_id_language,
                                              SQLCODE,
                                              SQLERRM,
                                              l_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            l_error := NULL;
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
    END;

    PROCEDURE set_img_exam_avlb
    (
        i_action            VARCHAR,
        i_id_language       VARCHAR,
        i_id_institution    NUMBER,
        i_id_software       NUMBER,
        i_desc_alias        VARCHAR,
        i_id_cnt_img_exam   VARCHAR,
        i_flg_first_result  VARCHAR,
        i_flg_execute       VARCHAR,
        i_flg_mov_pat       VARCHAR,
        i_flg_timeout       VARCHAR,
        i_flg_result_notes  VARCHAR,
        i_flg_first_execute VARCHAR,
        i_flg_chargeable    VARCHAR,
        i_flg_priority      VARCHAR,
        i_id_room           NUMBER
    ) IS
    
        l_exam   NUMBER;
        l_error  VARCHAR2(4000);
        l_bool   BOOLEAN;
        l_ids    table_number;
        l_status table_varchar;
    
    BEGIN
        g_func_name := 'set_img_exam_avlb';
    
        IF ((i_id_room IS NOT NULL) OR (i_flg_execute = 'Y'))
        THEN
        
            l_bool := validate_content(i_id_language,
                                       i_id_institution,
                                       table_varchar(i_id_cnt_img_exam, i_id_room),
                                       table_varchar('IMAGE_EXAM', 'ROOM'),
                                       table_number(1, 1),
                                       l_ids,
                                       l_status);
        
        ELSE
        
            l_bool := validate_content(i_id_language,
                                       i_id_institution,
                                       table_varchar(i_id_cnt_img_exam),
                                       table_varchar('IMAGE_EXAM'),
                                       table_number(1),
                                       l_ids,
                                       l_status);
        
        END IF;
    
        l_exam := l_ids(1);
    
        IF l_exam != 0
           AND (i_action = g_flg_create OR i_action = g_flg_update)
        THEN
        
            BEGIN
                INSERT INTO exam_dep_clin_serv
                    (id_exam_dep_clin_serv,
                     id_exam,
                     flg_type,
                     rank,
                     id_institution,
                     id_software,
                     flg_first_result,
                     flg_execute,
                     flg_timeout,
                     flg_result_notes,
                     flg_first_execute,
                     flg_mov_pat,
                     flg_priority)
                    SELECT seq_exam_dep_clin_serv.nextval,
                           e.id_exam,
                           g_flg_searchable,
                           g_rank_zero,
                           i_id_institution,
                           i_id_software,
                           i_flg_first_result,
                           i_flg_execute,
                           i_flg_timeout,
                           i_flg_result_notes,
                           i_flg_first_execute,
                           i_flg_mov_pat,
                           i_flg_priority
                      FROM exam e
                     WHERE e.id_exam = l_exam;
            
            EXCEPTION
                WHEN dup_val_on_index THEN
                
                    UPDATE exam_dep_clin_serv a
                       SET a.flg_first_result  = i_flg_first_result,
                           a.flg_execute       = i_flg_execute,
                           a.flg_timeout       = i_flg_timeout,
                           a.flg_result_notes  = i_flg_result_notes,
                           a.flg_first_execute = i_flg_first_execute,
                           a.flg_mov_pat       = i_flg_mov_pat,
                           a.flg_chargeable    = i_flg_chargeable,
                           a.flg_priority      = i_flg_priority
                     WHERE a.id_exam = l_exam
                       AND a.id_software = i_id_software
                       AND a.id_dep_clin_serv IS NULL
                       AND a.id_institution = i_id_institution
                       AND a.flg_type = g_flg_searchable;
                
            END;
        
            BEGIN
                INSERT INTO exam_dep_clin_serv
                    (id_exam_dep_clin_serv,
                     id_exam,
                     flg_type,
                     rank,
                     id_institution,
                     id_software,
                     flg_first_result,
                     flg_execute,
                     flg_timeout,
                     flg_result_notes,
                     flg_first_execute,
                     flg_mov_pat,
                     flg_priority)
                    SELECT seq_exam_dep_clin_serv.nextval,
                           e.id_exam,
                           g_flg_searchable,
                           g_rank_zero,
                           i_id_institution,
                           g_img_technician,
                           i_flg_first_result,
                           i_flg_execute,
                           i_flg_timeout,
                           i_flg_result_notes,
                           i_flg_first_execute,
                           i_flg_mov_pat,
                           i_flg_priority
                      FROM exam e
                     WHERE e.id_exam = l_exam;
            
            EXCEPTION
                WHEN dup_val_on_index THEN
                
                    UPDATE exam_dep_clin_serv a
                       SET a.flg_first_result  = i_flg_first_result,
                           a.flg_execute       = i_flg_execute,
                           a.flg_timeout       = i_flg_timeout,
                           a.flg_result_notes  = i_flg_result_notes,
                           a.flg_first_execute = i_flg_first_execute,
                           a.flg_mov_pat       = i_flg_mov_pat,
                           a.flg_chargeable    = i_flg_chargeable,
                           a.flg_priority      = i_flg_priority
                     WHERE a.id_exam = l_exam
                       AND a.id_software = g_img_technician
                       AND a.id_dep_clin_serv IS NULL
                       AND a.id_institution = i_id_institution
                       AND a.flg_type = g_flg_searchable;
                
            END;
        
            IF i_id_room IS NOT NULL
            THEN
            
                pk_cmt_content_core.set_img_exam_room(g_flg_update_create,
                                                      i_id_language,
                                                      i_id_cnt_img_exam,
                                                      i_id_room,
                                                      0,
                                                      g_flg_available,
                                                      NULL);
            END IF;
        
        ELSIF i_action = g_flg_delete
        THEN
        
            DELETE FROM exam_room
             WHERE id_exam_dep_clin_serv IN (SELECT id_exam_dep_clin_serv
                                               FROM exam_dep_clin_serv a
                                              WHERE a.id_exam = l_exam
                                                AND a.id_software = i_id_software
                                                AND a.id_dep_clin_serv IS NULL
                                                AND a.id_institution = i_id_institution
                                                AND a.flg_type = g_flg_searchable);
        
            DELETE FROM exam_dep_clin_serv a
             WHERE a.id_exam = l_exam
               AND a.id_software = i_id_software
               AND a.id_dep_clin_serv IS NULL
               AND a.id_institution = i_id_institution
               AND a.flg_type = g_flg_searchable;
        
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            raise_application_error(-20001, nvl(l_error, SQLERRM));
            pk_alert_exceptions.process_error(i_id_language,
                                              SQLCODE,
                                              SQLERRM,
                                              l_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            l_error := NULL;
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
        
    END;

    PROCEDURE set_img_exam
    (
        i_action            VARCHAR,
        i_id_language       VARCHAR,
        i_id_cnt_img_exam   VARCHAR,
        i_id_institution    NUMBER,
        i_id_software       NUMBER,
        i_desc_img_exam     VARCHAR,
        i_id_cnt_exam_cat   VARCHAR,
        i_age_min           NUMBER,
        i_age_max           NUMBER,
        i_gender            VARCHAR,
        i_flg_first_result  VARCHAR,
        i_flg_execute       VARCHAR,
        i_desc_alias        VARCHAR,
        i_flg_mov_pat       VARCHAR,
        i_flg_timeout       VARCHAR,
        i_flg_result_notes  VARCHAR,
        i_flg_first_execute VARCHAR,
        i_flg_pat_resp      VARCHAR,
        i_flg_pat_prep      VARCHAR,
        i_flg_technical     VARCHAR DEFAULT 'N',
        i_flg_priority      VARCHAR
    ) IS
    
        l_cod_exam exam.code_exam%TYPE;
    
        l_exam          NUMBER;
        l_cnt_exam_cat  NUMBER;
        l_id_exam_alias NUMBER;
        l_room          NUMBER;
    BEGIN
        g_func_name := 'set_img_exam';
        SELECT nvl((SELECT a.id_exam
                     FROM exam a
                    WHERE a.id_content = i_id_cnt_img_exam
                      AND a.flg_available = g_flg_available),
                   0)
          INTO l_exam
          FROM dual;
    
        SELECT nvl((SELECT a.id_exam_cat
                     FROM exam_cat a
                    WHERE a.id_content = i_id_cnt_exam_cat
                      AND a.flg_available = g_flg_available),
                   0)
          INTO l_cnt_exam_cat
          FROM dual;
    
        IF l_exam = 0
           AND (i_action = g_flg_create OR i_action = g_flg_update)
           AND i_desc_img_exam IS NOT NULL
        THEN
        
            SELECT seq_exam.nextval
              INTO l_exam
              FROM dual;
        
            INSERT INTO exam
                (id_exam,
                 code_exam,
                 flg_available,
                 rank,
                 adw_last_update,
                 id_content,
                 id_exam_cat,
                 flg_type,
                 age_min,
                 age_max,
                 gender,
                 flg_technical)
            VALUES
                (l_exam,
                 'EXAM.CODE_EXAM.' || l_exam,
                 g_flg_available,
                 g_rank_zero,
                 SYSDATE,
                 i_id_cnt_img_exam,
                 l_cnt_exam_cat,
                 g_imgexam_type,
                 i_age_min,
                 i_age_max,
                 i_gender,
                 i_flg_technical);
        
            SELECT e.code_exam
              INTO l_cod_exam
              FROM exam e
             WHERE e.id_exam = l_exam;
        
            pk_translation.insert_into_translation(i_id_language, l_cod_exam, i_desc_img_exam);
        
            INSERT INTO exam_dep_clin_serv
                (id_exam_dep_clin_serv,
                 id_exam,
                 flg_type,
                 rank,
                 id_institution,
                 id_software,
                 flg_first_result,
                 flg_execute,
                 flg_timeout,
                 flg_result_notes,
                 flg_first_execute,
                 flg_mov_pat,
                 flg_priority)
                SELECT seq_exam_dep_clin_serv.nextval,
                       e.id_exam,
                       g_flg_searchable,
                       g_rank_zero,
                       i_id_institution,
                       i_id_software,
                       i_flg_first_result,
                       i_flg_execute,
                       i_flg_timeout,
                       i_flg_result_notes,
                       i_flg_first_execute,
                       i_flg_mov_pat,
                       i_flg_priority
                  FROM exam e
                 WHERE e.id_exam = l_exam
                   AND NOT EXISTS (SELECT 1
                          FROM exam_dep_clin_serv edcs1
                         WHERE edcs1.id_exam = e.id_exam
                           AND edcs1.id_dep_clin_serv IS NULL
                           AND edcs1.id_software = i_id_software
                           AND edcs1.id_institution = i_id_institution
                           AND edcs1.flg_type = pk_exam_constant.g_exam_can_req);
        
            IF i_desc_alias IS NOT NULL
            THEN
            
                SELECT nvl((SELECT MAX(a.id_exam_alias) + 1
                             FROM exam_alias a),
                           0)
                  INTO l_id_exam_alias
                  FROM dual;
            
                INSERT INTO exam_alias
                    (id_exam_alias,
                     id_exam,
                     code_exam_alias,
                     id_institution,
                     id_software,
                     id_professional,
                     id_dep_clin_serv,
                     adw_last_update)
                VALUES
                    (l_id_exam_alias,
                     l_exam,
                     'EXAM_ALIAS.CODE_EXAM_ALIAS.' || l_id_exam_alias,
                     i_id_institution,
                     i_id_software,
                     NULL,
                     NULL,
                     SYSDATE);
                pk_translation.insert_into_translation(i_id_language,
                                                       'EXAM_ALIAS.CODE_EXAM_ALIAS.' || l_id_exam_alias,
                                                       i_desc_alias);
            END IF;
        
            SELECT nvl((SELECT id_room
                         FROM (SELECT COUNT(*), id_room
                                 FROM exam_room
                                WHERE id_room IN
                                      (SELECT id_room
                                         FROM room
                                        WHERE id_department IN
                                              (SELECT id_department
                                                 FROM department d
                                                WHERE id_institution = i_id_institution
                                                  AND d.id_dept IN (SELECT id_dept
                                                                      FROM software_dept
                                                                     WHERE id_software = i_id_software)))
                                GROUP BY id_room
                                ORDER BY 1 DESC)
                        WHERE rownum = 1),
                       0)
              INTO l_room
              FROM dual;
        
            IF l_room != 0
            THEN
                pk_cmt_content_core.set_img_exam_room('C',
                                                      i_id_language,
                                                      i_id_cnt_img_exam,
                                                      l_room,
                                                      0,
                                                      g_flg_available,
                                                      NULL);
            END IF;
        
        ELSIF i_action = g_flg_create
              AND l_exam != 0
        THEN
            INSERT INTO exam_dep_clin_serv
                (id_exam_dep_clin_serv,
                 id_exam,
                 flg_type,
                 rank,
                 id_institution,
                 id_software,
                 flg_first_result,
                 flg_execute,
                 flg_timeout,
                 flg_result_notes,
                 flg_first_execute,
                 flg_mov_pat,
                 flg_priority)
                SELECT seq_exam_dep_clin_serv.nextval,
                       e.id_exam,
                       g_flg_searchable,
                       g_rank_zero,
                       i_id_institution,
                       i_id_software,
                       i_flg_first_result,
                       i_flg_execute,
                       i_flg_timeout,
                       i_flg_result_notes,
                       i_flg_first_execute,
                       i_flg_mov_pat,
                       i_flg_priority
                  FROM exam e
                 WHERE e.id_exam = l_exam
                   AND NOT EXISTS (SELECT 1
                          FROM exam_dep_clin_serv edcs1
                         WHERE edcs1.id_exam = e.id_exam
                           AND edcs1.id_dep_clin_serv IS NULL
                           AND edcs1.id_software = i_id_software
                           AND edcs1.id_institution = i_id_institution
                           AND edcs1.flg_type = pk_exam_constant.g_exam_can_req);
        
        ELSIF i_action = g_flg_update
              AND l_exam != 0
        THEN
        
            UPDATE exam a
               SET age_min         = i_age_min,
                   age_max         = i_age_max,
                   gender          = i_gender,
                   id_exam_cat     = l_cnt_exam_cat,
                   a.flg_technical = i_flg_technical
             WHERE a.id_exam = l_exam;
        
            UPDATE exam_dep_clin_serv a
               SET a.flg_first_result = i_flg_first_result,
                   a.flg_execute      = i_flg_execute,
                   flg_timeout        = i_flg_timeout,
                   flg_result_notes   = i_flg_result_notes,
                   flg_first_execute  = i_flg_first_execute,
                   a.flg_mov_pat      = i_flg_mov_pat,
                   a.flg_priority     = i_flg_priority
             WHERE a.id_exam = l_exam
               AND a.id_software = i_id_software
               AND a.id_dep_clin_serv IS NULL
               AND a.id_institution = i_id_institution
               AND a.flg_type = g_flg_searchable;
        
            SELECT nvl((SELECT a.id_exam_alias
                         FROM exam_alias a
                        WHERE a.id_exam = l_exam
                          AND a.id_institution = i_id_institution
                          AND a.id_software = i_id_software),
                       0)
              INTO l_id_exam_alias
              FROM dual;
        
            IF l_id_exam_alias = 0
               AND i_desc_alias IS NOT NULL
            THEN
                SELECT nvl((SELECT MAX(a.id_exam_alias) + 1
                             FROM exam_alias a),
                           0)
                  INTO l_id_exam_alias
                  FROM dual;
            
                INSERT INTO exam_alias
                    (id_exam_alias,
                     id_exam,
                     code_exam_alias,
                     id_institution,
                     id_software,
                     id_professional,
                     id_dep_clin_serv,
                     adw_last_update)
                VALUES
                    (l_id_exam_alias,
                     l_exam,
                     'EXAM_ALIAS.CODE_EXAM_ALIAS.' || l_id_exam_alias,
                     i_id_institution,
                     i_id_software,
                     NULL,
                     NULL,
                     SYSDATE);
            
                pk_translation.insert_into_translation(i_id_language,
                                                       'EXAM_ALIAS.CODE_EXAM_ALIAS.' || l_id_exam_alias,
                                                       i_desc_alias);
            ELSIF l_id_exam_alias > 0
                  AND i_desc_alias IS NOT NULL
            THEN
            
                pk_translation.insert_into_translation(i_id_language,
                                                       'EXAM_ALIAS.CODE_EXAM_ALIAS.' || l_id_exam_alias,
                                                       i_desc_alias);
            
            ELSIF l_id_exam_alias > 0
                  AND i_desc_alias IS NULL
            THEN
            
                DELETE FROM exam_alias a
                 WHERE a.id_exam = l_exam
                   AND a.id_institution = i_id_institution
                   AND a.id_software = i_id_software;
            
                pk_translation.insert_into_translation(i_id_language,
                                                       'EXAM_ALIAS.CODE_EXAM_ALIAS.' || l_id_exam_alias,
                                                       i_desc_alias);
            
            END IF;
        
        ELSIF i_action = g_flg_delete
        THEN
        
            DELETE FROM exam_room
             WHERE id_exam_dep_clin_serv IN (SELECT id_exam_dep_clin_serv
                                               FROM exam_dep_clin_serv a
                                              WHERE a.id_exam = l_exam
                                                AND a.id_software = i_id_software
                                                AND a.id_dep_clin_serv IS NULL
                                                AND a.id_institution = i_id_institution
                                                AND a.flg_type = g_flg_searchable);
        
            DELETE FROM exam_dep_clin_serv a
             WHERE a.id_exam = l_exam
               AND a.id_software = i_id_software
               AND a.id_dep_clin_serv IS NULL
               AND a.id_institution = i_id_institution
               AND a.flg_type = g_flg_searchable;
        
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            raise_application_error(-20001, SQLERRM);
        
            pk_alert_exceptions.process_error(i_id_language,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
        
    END set_img_exam;

    PROCEDURE set_supply_loc_default
    (
        i_action             VARCHAR,
        i_id_language        VARCHAR,
        i_id_institution     NUMBER,
        i_id_software        NUMBER,
        i_id_cnt_supply      VARCHAR,
        i_flg_default        VARCHAR,
        i_id_supply_location NUMBER
    ) IS
    
        l_supply           NUMBER;
        l_supply_soft_inst NUMBER;
    BEGIN
        g_func_name := 'set_supply_loc_default';
        SELECT nvl((SELECT a.id_supply
                     FROM supply a
                    WHERE a.id_content = i_id_cnt_supply
                      AND a.flg_available = g_flg_available),
                   0)
          INTO l_supply
          FROM dual;
    
        SELECT nvl((SELECT a.id_supply_soft_inst
                     FROM supply_soft_inst a
                    WHERE a.id_supply = l_supply
                      AND a.id_software = i_id_software
                      AND a.id_institution = i_id_institution),
                   0)
          INTO l_supply_soft_inst
          FROM dual;
    
        IF l_supply_soft_inst != 0
           AND i_action = g_flg_create
        THEN
        
            INSERT INTO supply_loc_default
                (id_supply_location, id_supply_loc_default, id_supply_soft_inst, flg_default)
            VALUES
                (i_id_supply_location, seq_supply_loc_default.nextval, l_supply_soft_inst, i_flg_default);
        
        ELSIF l_supply_soft_inst != 0
              AND i_action = g_flg_update
        THEN
        
            UPDATE supply_loc_default a
               SET flg_default = i_flg_default
             WHERE a.id_supply_soft_inst = l_supply_soft_inst
               AND a.id_supply_location = i_id_supply_location;
        
        ELSIF l_supply_soft_inst != 0
              AND i_action = g_flg_delete
        THEN
            DELETE supply_loc_default a
             WHERE a.id_supply_soft_inst = l_supply_soft_inst
               AND a.id_supply_location = i_id_supply_location;
        
        END IF;
    
    END;

    PROCEDURE set_supply_relation
    (
        i_action             VARCHAR,
        i_id_language        VARCHAR,
        i_id_cnt_supply      VARCHAR,
        i_id_cnt_supply_item VARCHAR,
        i_quantity           NUMBER
    ) IS
    
        l_supply      NUMBER;
        l_supply_item NUMBER;
    BEGIN
        g_func_name := 'set_supply_relation';
        SELECT nvl((SELECT a.id_supply
                     FROM supply a
                    WHERE a.id_content = i_id_cnt_supply
                      AND a.flg_available = g_flg_available),
                   0)
          INTO l_supply
          FROM dual;
    
        SELECT nvl((SELECT a.id_supply
                     FROM supply a
                    WHERE a.id_content = i_id_cnt_supply_item
                      AND a.flg_available = g_flg_available),
                   0)
          INTO l_supply_item
          FROM dual;
    
        IF l_supply != 0
           AND l_supply_item != 0
           AND i_action = g_flg_create
        THEN
        
            INSERT INTO supply_relation
                (id_supply, id_supply_item, quantity)
            
            VALUES
                (l_supply, l_supply_item, i_quantity);
        ELSIF l_supply != 0
              AND l_supply_item != 0
              AND i_action = g_flg_update
        THEN
            UPDATE supply_relation a
               SET a.quantity = i_quantity
             WHERE a.id_supply = l_supply
               AND a.id_supply_item = l_supply_item;
        
        ELSIF l_supply != 0
              AND l_supply_item != 0
              AND i_action = g_flg_delete
        THEN
            DELETE supply_relation a
             WHERE a.id_supply = l_supply
               AND a.id_supply_item = l_supply_item;
        
        END IF;
    
    END;

    PROCEDURE set_supply_context
    (
        i_action          VARCHAR,
        i_id_language     VARCHAR,
        i_id_cnt_supply   VARCHAR,
        i_flg_context     VARCHAR,
        i_id_context      VARCHAR,
        i_quantity        NUMBER,
        i_id_unit_measure NUMBER,
        i_id_institution  NUMBER,
        i_id_software     NUMBER
    ) IS
    
        l_supply  NUMBER;
        l_context VARCHAR(200);
    BEGIN
        g_func_name := 'set_supply_context';
        SELECT nvl((SELECT a.id_supply
                     FROM supply a
                    WHERE a.id_content = i_id_cnt_supply
                      AND a.flg_available = g_flg_available),
                   0)
          INTO l_supply
          FROM dual;
    
        -- ACCORDING TO SOME VALIDATIONS IN THE CLIENT, NEVER OTHER CONTEXT RATHER THEN FLG 'P' WAS USED
        IF i_flg_context = 'P'
        THEN
            SELECT nvl((SELECT a.id_intervention
                         FROM intervention a
                        WHERE a.id_content = i_id_context
                          AND a.flg_status = g_flg_active),
                       0)
              INTO l_context
              FROM dual;
        
        ELSIF i_flg_context IN ('E', 'O')
        THEN
            SELECT nvl((SELECT a.id_exam
                         FROM exam a
                        WHERE a.id_content = i_id_context
                          AND a.flg_available = g_flg_available),
                       0)
              INTO l_context
              FROM dual;
        
        ELSIF i_flg_context IN ('S')
        THEN
            SELECT nvl((SELECT a.id_intervention
                         FROM intervention a
                        WHERE a.id_content = i_id_context
                          AND a.flg_status = g_flg_active
                          AND a.flg_category_type = g_sr_intervention),
                       0)
              INTO l_context
              FROM dual;
        
        END IF;
    
        IF l_supply != 0
           AND l_context != 0
           AND i_action = g_flg_create
        THEN
            INSERT INTO supply_context
                (id_supply_context,
                 id_supply,
                 quantity,
                 id_unit_measure,
                 id_context,
                 flg_context,
                 id_software,
                 id_institution,
                 id_dept)
            VALUES
                (seq_supply_context.nextval,
                 l_supply,
                 i_quantity,
                 i_id_unit_measure,
                 l_context,
                 i_flg_context,
                 i_id_software,
                 i_id_institution,
                 0);
        
        ELSIF l_supply != 0
              AND l_context != 0
              AND i_action = g_flg_update
        THEN
            UPDATE supply_context a
               SET a.quantity = i_quantity, a.id_unit_measure = i_id_unit_measure
             WHERE a.id_supply = l_supply
               AND a.flg_context = i_flg_context
               AND a.id_context = l_context
               AND a.id_institution = i_id_institution
               AND a.id_software = i_id_software;
        
        ELSIF i_action = g_flg_delete
        THEN
            DELETE supply_context a
             WHERE a.id_supply = l_supply
               AND a.flg_context = i_flg_context
               AND a.id_context = l_context
               AND a.id_institution = i_id_institution
               AND a.id_software = i_id_software;
        
        END IF;
    
    END set_supply_context;

    PROCEDURE set_supply_sup_area
    (
        i_action         VARCHAR,
        i_id_language    VARCHAR,
        i_id_institution NUMBER,
        i_id_software    NUMBER,
        i_id_cnt_supply  VARCHAR,
        i_id_supply_area NUMBER
    ) IS
    
        l_supply           NUMBER;
        l_supply_soft_inst NUMBER;
    BEGIN
        g_func_name := 'set_supply_sup_area';
        SELECT nvl((SELECT a.id_supply
                     FROM supply a
                    WHERE a.id_content = i_id_cnt_supply
                      AND a.flg_available = g_flg_available),
                   0)
          INTO l_supply
          FROM dual;
    
        SELECT nvl((SELECT a.id_supply_soft_inst
                     FROM supply_soft_inst a
                    WHERE a.id_supply = l_supply
                      AND a.id_software = i_id_software
                      AND a.id_institution = i_id_institution),
                   0)
          INTO l_supply_soft_inst
          FROM dual;
    
        IF l_supply_soft_inst != 0
           AND i_action = g_flg_create
        THEN
        
            INSERT INTO supply_sup_area
                (id_supply_area, id_supply_soft_inst, flg_available)
            VALUES
                (i_id_supply_area, l_supply_soft_inst, g_flg_available);
        
        ELSIF l_supply_soft_inst != 0
              AND i_action = g_flg_delete
        THEN
            DELETE supply_sup_area a
             WHERE a.id_supply_soft_inst = l_supply_soft_inst
               AND a.id_supply_area = i_id_supply_area;
        
        END IF;
    
    END;

    PROCEDURE set_supply_type
    (
        i_action                    VARCHAR,
        i_id_language               VARCHAR,
        i_desc_supply_type          VARCHAR,
        i_id_institution            NUMBER,
        i_id_software               NUMBER,
        i_id_cnt_supply_type        VARCHAR,
        i_id_cnt_supply_type_parent VARCHAR
    ) IS
    
        l_cod_supply_type supply_type.code_supply_type%TYPE;
    
        l_supply_type        NUMBER;
        l_supply_type_parent NUMBER;
    BEGIN
        g_func_name := 'set_supply_type';
    
        SELECT nvl((SELECT a.id_supply_type
                     FROM supply_type a
                    WHERE a.id_content = i_id_cnt_supply_type
                      AND a.flg_available = g_flg_available),
                   0)
          INTO l_supply_type
          FROM dual;
    
        SELECT nvl((SELECT a.id_supply_type
                     FROM supply_type a
                    WHERE a.id_content = i_id_cnt_supply_type_parent
                      AND a.flg_available = g_flg_available),
                   NULL)
          INTO l_supply_type_parent
          FROM dual;
    
        IF l_supply_type = 0
           AND (i_action = g_flg_create OR i_action = g_flg_update)
           AND i_desc_supply_type IS NOT NULL
        THEN
        
            SELECT seq_supply_type.nextval
              INTO l_supply_type
              FROM dual;
        
            INSERT INTO supply_type
                (id_supply_type, code_supply_type, id_parent, id_content, flg_available)
            VALUES
                (l_supply_type,
                 'SUPPLY_TYPE.CODE_SUPPLY_TYPE.' || l_supply_type,
                 l_supply_type_parent,
                 i_id_cnt_supply_type,
                 g_flg_available);
        
            SELECT e.code_supply_type
              INTO l_cod_supply_type
              FROM supply_type e
             WHERE e.id_supply_type = l_supply_type;
        
            pk_translation.insert_into_translation(i_id_language, l_cod_supply_type, i_desc_supply_type);
        
        ELSIF i_action = g_flg_create
              AND l_supply_type != 0
        THEN
        
            UPDATE supply_type a
               SET a.id_parent = l_supply_type_parent
             WHERE a.id_supply_type = l_supply_type;
        
        ELSIF i_action = g_flg_update
              AND l_supply_type > 0
        THEN
        
            UPDATE supply_type a
               SET a.id_parent = l_supply_type_parent
             WHERE a.id_supply_type = l_supply_type;
        
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            raise_application_error(-20001, SQLERRM);
            pk_alert_exceptions.process_error(i_id_language,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
        
    END set_supply_type;

    PROCEDURE set_supply
    (
        i_action             VARCHAR,
        i_id_language        VARCHAR,
        i_desc_supply        VARCHAR,
        i_id_institution     NUMBER,
        i_id_software        NUMBER,
        i_id_cnt_supply      VARCHAR,
        i_id_cnt_supply_type VARCHAR,
        i_flg_type           VARCHAR,
        i_flg_cons_type      VARCHAR DEFAULT 'C',
        i_flg_reusable       VARCHAR DEFAULT 'N',
        i_flg_editable       VARCHAR DEFAULT 'N',
        i_flg_preparing      VARCHAR DEFAULT NULL,
        i_flg_countable      VARCHAR DEFAULT NULL
    ) IS
    
        l_cod_supply supply.code_supply%TYPE;
    
        l_supply      NUMBER;
        l_supply_type NUMBER;
    BEGIN
        g_func_name := 'set_supply';
        SELECT nvl((SELECT a.id_supply
                     FROM supply a
                    WHERE a.id_content = i_id_cnt_supply
                      AND a.flg_available = g_flg_available),
                   0)
          INTO l_supply
          FROM dual;
    
        SELECT nvl((SELECT a.id_supply_type
                     FROM supply_type a
                    WHERE a.id_content = i_id_cnt_supply_type
                      AND a.flg_available = g_flg_available),
                   0)
          INTO l_supply_type
          FROM dual;
    
        IF l_supply = 0
           AND (i_action = g_flg_create OR i_action = g_flg_update)
           AND i_desc_supply IS NOT NULL
        THEN
        
            SELECT seq_supply.nextval
              INTO l_supply
              FROM dual;
        
            INSERT INTO supply
                (id_supply, code_supply, id_supply_type, flg_type, id_content, flg_available, standard_code)
            VALUES
                (l_supply,
                 'SUPPLY.CODE_SUPPLY.' || l_supply,
                 l_supply_type,
                 i_flg_type,
                 i_id_cnt_supply,
                 g_flg_available,
                 NULL);
        
            SELECT e.code_supply
              INTO l_cod_supply
              FROM supply e
             WHERE e.id_supply = l_supply;
            pk_translation.insert_into_translation(i_id_language, l_cod_supply, i_desc_supply);
        
            INSERT INTO supply_soft_inst
                (id_supply_soft_inst,
                 id_supply,
                 id_institution,
                 id_software,
                 id_professional,
                 id_dept,
                 quantity,
                 id_unit_measure,
                 flg_cons_type,
                 flg_reusable,
                 flg_editable,
                 total_avail_quantity,
                 flg_preparing,
                 flg_countable)
            VALUES
                (seq_supply_soft_inst.nextval,
                 l_supply,
                 i_id_institution,
                 i_id_software,
                 0,
                 NULL,
                 1.000,
                 NULL,
                 i_flg_cons_type,
                 i_flg_reusable,
                 i_flg_editable,
                 10000,
                 i_flg_preparing,
                 i_flg_countable);
        
        ELSIF i_action = g_flg_create
              AND l_supply != 0
        THEN
        
            INSERT INTO supply_soft_inst
                (id_supply_soft_inst,
                 id_supply,
                 id_institution,
                 id_software,
                 id_professional,
                 id_dept,
                 quantity,
                 id_unit_measure,
                 flg_cons_type,
                 flg_reusable,
                 flg_editable,
                 total_avail_quantity,
                 flg_preparing,
                 flg_countable)
            VALUES
                (seq_supply_soft_inst.nextval,
                 l_supply,
                 i_id_institution,
                 i_id_software,
                 0,
                 NULL,
                 1.000,
                 NULL,
                 i_flg_cons_type,
                 i_flg_reusable,
                 i_flg_editable,
                 10000,
                 i_flg_preparing,
                 i_flg_countable);
        
        ELSIF i_action = g_flg_update
              AND l_supply > 0
        THEN
        
            UPDATE supply a
               SET a.flg_type = i_flg_type, a.id_supply_type = l_supply_type
             WHERE a.id_supply = l_supply;
        
            UPDATE supply_soft_inst a
               SET flg_cons_type = i_flg_cons_type,
                   flg_reusable  = i_flg_reusable,
                   flg_editable  = i_flg_editable,
                   flg_preparing = i_flg_preparing,
                   flg_countable = i_flg_countable
             WHERE a.id_supply = l_supply
               AND a.id_software = i_id_software
               AND a.id_institution = i_id_institution;
        
        ELSIF i_action = g_flg_delete
        THEN
        
            DELETE supply_sup_area b
             WHERE b.id_supply_soft_inst IN (SELECT a.id_supply_soft_inst
                                               FROM supply_soft_inst a
                                              WHERE a.id_supply = l_supply
                                                AND a.id_software = i_id_software
                                                AND a.id_institution = i_id_institution);
        
            DELETE supply_loc_default b
             WHERE b.id_supply_soft_inst IN (SELECT a.id_supply_soft_inst
                                               FROM supply_soft_inst a
                                              WHERE a.id_supply = l_supply
                                                AND a.id_software = i_id_software
                                                AND a.id_institution = i_id_institution);
        
            DELETE FROM supply_soft_inst a
             WHERE a.id_supply = l_supply
               AND a.id_software = i_id_software
               AND a.id_institution = i_id_institution;
        
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            raise_application_error(-20001, SQLERRM);
            pk_alert_exceptions.process_error(i_id_language,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
        
    END set_supply;

    PROCEDURE set_clinical_service
    (
        i_action                  VARCHAR,
        i_id_language             VARCHAR,
        i_desc_clinical_service   VARCHAR,
        i_id_cnt_clinical_service VARCHAR,
        i_abbreviation            VARCHAR,
        i_id_cnt_clin_serv_parent VARCHAR
    ) IS
    
        l_cod_clinical_service clinical_service.code_clinical_service%TYPE;
    
        l_clinical_service        NUMBER;
        l_clinical_service_parent NUMBER;
        l_temp                    NUMBER;
        l_error                   VARCHAR2(4000);
    BEGIN
        g_func_name := 'set_clinical_service';
    
        SELECT nvl((SELECT a.id_clinical_service
                     FROM clinical_service a
                    WHERE a.id_content = i_id_cnt_clinical_service),
                   0)
          INTO l_clinical_service
          FROM dual;
    
        IF i_id_cnt_clin_serv_parent IS NOT NULL
        THEN
            BEGIN
                SELECT a.id_clinical_service
                  INTO l_clinical_service_parent
                  FROM clinical_service a
                 WHERE a.id_content = i_id_cnt_clin_serv_parent
                   AND flg_available = g_flg_available
                   AND rownum = 1;
            EXCEPTION
                WHEN no_data_found THEN
                    l_error := 'The parent clinical service does not exist or it is unavailable!';
                    RAISE g_exception;
            END;
        
        END IF;
    
        IF l_clinical_service = 0
           AND (i_action = g_flg_create OR i_action = g_flg_update)
           AND i_desc_clinical_service IS NOT NULL
        THEN
        
            SELECT seq_clinical_service.nextval
              INTO l_clinical_service
              FROM dual;
        
            INSERT INTO clinical_service
                (id_clinical_service,
                 id_clinical_service_parent,
                 code_clinical_service,
                 rank,
                 flg_available,
                 id_content,
                 abbreviation)
            VALUES
                (l_clinical_service,
                 l_clinical_service_parent,
                 'CLINICAL_SERVICE.CODE_CLINICAL_SERVICE.' || l_clinical_service,
                 10,
                 g_flg_available,
                 i_id_cnt_clinical_service,
                 i_abbreviation);
        
            SELECT e.code_clinical_service
              INTO l_cod_clinical_service
              FROM clinical_service e
             WHERE e.id_clinical_service = l_clinical_service;
        
            pk_translation.insert_into_translation(i_id_language, l_cod_clinical_service, i_desc_clinical_service);
        
        ELSIF i_action = g_flg_create
              AND l_clinical_service != 0
        THEN
        
            SELECT COUNT(*)
              INTO l_temp
              FROM clinical_service
             WHERE id_clinical_service = l_clinical_service
               AND flg_available = g_flg_no;
        
            IF (l_temp = 1)
            THEN
            
                UPDATE clinical_service a
                   SET flg_available = g_flg_available
                 WHERE a.id_clinical_service = l_clinical_service;
            
            ELSE
                l_error := 'Clinical_service already exists';
                pk_alertlog.log_debug(g_error, g_package_name, g_func_name);
                RAISE g_exception;
            END IF;
        
        ELSIF i_action = g_flg_update
              AND l_clinical_service != 0
        THEN
        
            UPDATE clinical_service a
               SET abbreviation = i_abbreviation, a.id_clinical_service_parent = l_clinical_service_parent
             WHERE a.id_clinical_service = l_clinical_service;
        
        ELSIF i_action = g_flg_delete
              AND l_clinical_service != 0
        THEN
        
            UPDATE clinical_service a
               SET flg_available = g_flg_no
             WHERE a.id_clinical_service = l_clinical_service;
        
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            raise_application_error(-20001, nvl(l_error, SQLERRM));
            pk_alert_exceptions.process_error(i_id_language,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
        
    END set_clinical_service;

    PROCEDURE set_img_exam_clin_quest
    (
        i_action                   VARCHAR,
        i_id_cnt_img_exam          VARCHAR,
        i_id_cnt_question_response VARCHAR,
        i_flg_time                 VARCHAR,
        i_flg_type                 VARCHAR,
        i_flg_mandatory            VARCHAR,
        i_rank                     NUMBER,
        i_flg_copy                 VARCHAR,
        i_flg_validation           VARCHAR,
        i_flg_exterior             VARCHAR,
        i_id_unit_measure          VARCHAR,
        i_id_institution           NUMBER
    ) IS
        l_id_exam          NUMBER;
        l_id_response      NUMBER;
        l_id_questionnaire NUMBER;
    BEGIN
        g_func_name := 'set_img_exam_clin_quest';
        /*    select q.id_questionnaire
          into l_id_questionnaire
          from questionnaire q
         where q.id_content = i_id_cnt_clinical_question
           and q.flg_available = g_flg_available;
        
        if i_id_cnt_response is not null then
        
          select q.id_response
            into l_id_response
            from response q
           where q.id_content = i_id_cnt_response
             and q.flg_available = g_flg_available;
        else
          l_id_response := null;
        end if;*/
    
        SELECT q.id_questionnaire, q.id_response
          INTO l_id_questionnaire, l_id_response
          FROM questionnaire_response q
         WHERE q.id_content = i_id_cnt_question_response
           AND q.flg_available = g_flg_available;
    
        SELECT q.id_exam
          INTO l_id_exam
          FROM exam q
         WHERE q.id_content = i_id_cnt_img_exam
           AND q.flg_available = g_flg_available;
        IF i_action = g_flg_create
        THEN
            INSERT INTO exam_questionnaire
                (id_exam_questionnaire,
                 id_exam,
                 id_questionnaire,
                 flg_type,
                 flg_mandatory,
                 rank,
                 flg_available,
                 flg_time,
                 id_exam_group,
                 id_response,
                 flg_copy,
                 flg_validation,
                 flg_exterior,
                 id_unit_measure,
                 id_institution)
            VALUES
                (seq_exam_questionnaire.nextval,
                 l_id_exam,
                 l_id_questionnaire,
                 i_flg_type,
                 i_flg_mandatory,
                 i_rank,
                 g_flg_available,
                 i_flg_time,
                 NULL,
                 l_id_response,
                 i_flg_copy,
                 i_flg_validation,
                 i_flg_exterior,
                 i_id_unit_measure,
                 i_id_institution);
        ELSIF i_action = g_flg_update
        THEN
            UPDATE exam_questionnaire eq
               SET flg_type        = i_flg_type,
                   flg_mandatory   = i_flg_mandatory,
                   rank            = i_rank,
                   flg_time        = i_flg_time,
                   flg_copy        = i_flg_copy,
                   flg_validation  = i_flg_validation,
                   flg_exterior    = i_flg_exterior,
                   id_unit_measure = i_id_unit_measure
             WHERE eq.id_questionnaire = l_id_questionnaire
               AND eq.id_response = l_id_response
               AND eq.id_exam = l_id_exam
               AND eq.id_institution = i_id_institution;
        ELSIF i_action = g_flg_delete
        THEN
            DELETE exam_questionnaire eq
             WHERE eq.id_questionnaire = l_id_questionnaire
               AND eq.id_response = l_id_response
               AND eq.id_exam = l_id_exam
               AND eq.id_institution = i_id_institution;
        
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            raise_application_error(-20001, SQLERRM);
            pk_alert_exceptions.process_error(g_language,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
    END;

    PROCEDURE set_procedure_clin_quest
    (
        i_action                   VARCHAR,
        i_id_cnt_procedure         VARCHAR,
        i_id_cnt_question_response VARCHAR,
        i_flg_time                 VARCHAR,
        i_flg_type                 VARCHAR,
        i_flg_mandatory            VARCHAR,
        i_rank                     NUMBER,
        i_flg_copy                 VARCHAR,
        i_flg_validation           VARCHAR,
        i_flg_exterior             VARCHAR,
        i_id_unit_measure          VARCHAR,
        i_id_institution           NUMBER
    ) IS
        l_id_intervention  NUMBER;
        l_id_response      NUMBER;
        l_id_questionnaire NUMBER;
        l_flg_mandatory    VARCHAR2(10);
        l_flg_copy         VARCHAR2(10);
        l_flg_validation   VARCHAR2(10);
        l_flg_exterior     VARCHAR2(10);
        l_cnt              NUMBER;
    
    BEGIN
        g_func_name := 'set_procedure_clin_quest';
    
        SELECT decode(i_flg_mandatory, 'Yes', 'Y', 'No', 'N', NULL)
          INTO l_flg_mandatory
          FROM dual;
        SELECT decode(i_flg_copy, 'Yes', 'Y', 'No', 'N', NULL)
          INTO l_flg_copy
          FROM dual;
        SELECT decode(i_flg_validation, 'Yes', 'Y', 'No', 'N', NULL)
          INTO l_flg_validation
          FROM dual;
        SELECT decode(i_flg_exterior, 'Yes', 'Y', 'No', 'N', NULL)
          INTO l_flg_exterior
          FROM dual;
    
        SELECT q.id_questionnaire, q.id_response
          INTO l_id_questionnaire, l_id_response
          FROM questionnaire_response q
         WHERE q.id_content = i_id_cnt_question_response
           AND q.flg_available = g_flg_available;
    
        SELECT q.id_intervention
          INTO l_id_intervention
          FROM intervention q
         WHERE q.id_content = i_id_cnt_procedure
           AND q.flg_status = g_flg_active;
    
        SELECT nvl((SELECT id_interv_questionnaire
                     FROM interv_questionnaire
                    WHERE id_intervention = l_id_intervention
                      AND id_response = l_id_response
                      AND id_institution = i_id_institution
                      AND id_questionnaire = l_id_questionnaire),
                   0)
          INTO l_cnt
          FROM dual;
    
        IF i_action = g_flg_create
           AND l_cnt = 0
        THEN
            INSERT INTO interv_questionnaire
                (id_interv_questionnaire,
                 id_intervention,
                 id_questionnaire,
                 id_response,
                 flg_time,
                 flg_type,
                 flg_mandatory,
                 flg_copy,
                 flg_validation,
                 flg_exterior,
                 id_unit_measure,
                 rank,
                 flg_available,
                 id_institution)
            VALUES
                (seq_interv_questionnaire.nextval,
                 l_id_intervention,
                 l_id_questionnaire,
                 l_id_response,
                 i_flg_time,
                 i_flg_type,
                 l_flg_mandatory,
                 l_flg_copy,
                 l_flg_validation,
                 l_flg_exterior,
                 i_id_unit_measure,
                 i_rank,
                 g_flg_available,
                 i_id_institution);
        ELSIF i_action = g_flg_create
              AND l_cnt != 0
        THEN
            UPDATE interv_questionnaire eq
               SET flg_type        = i_flg_type,
                   flg_mandatory   = l_flg_mandatory,
                   rank            = i_rank,
                   flg_time        = i_flg_time,
                   flg_copy        = l_flg_copy,
                   flg_validation  = l_flg_validation,
                   flg_exterior    = l_flg_exterior,
                   id_unit_measure = i_id_unit_measure,
                   flg_available   = g_flg_available
             WHERE eq.id_interv_questionnaire = l_cnt;
        
        ELSIF i_action = g_flg_update
        THEN
            UPDATE interv_questionnaire eq
               SET flg_type        = i_flg_type,
                   flg_mandatory   = l_flg_mandatory,
                   rank            = i_rank,
                   flg_time        = i_flg_time,
                   flg_copy        = l_flg_copy,
                   flg_validation  = l_flg_validation,
                   flg_exterior    = l_flg_exterior,
                   id_unit_measure = i_id_unit_measure,
                   flg_available   = g_flg_available
             WHERE eq.id_questionnaire = l_id_questionnaire
               AND eq.id_response = l_id_response
               AND eq.id_intervention = l_id_intervention
               AND eq.id_institution = i_id_institution;
        
        ELSIF i_action = g_flg_delete
        THEN
            DELETE interv_questionnaire eq
             WHERE eq.id_questionnaire = l_id_questionnaire
               AND eq.id_response = l_id_response
               AND eq.id_intervention = l_id_intervention
               AND eq.id_institution = i_id_institution;
        
        END IF;
    EXCEPTION
    
        WHEN OTHERS THEN
            raise_application_error(-20001, SQLERRM);
            pk_alert_exceptions.process_error(g_language,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
    END;

    PROCEDURE set_lab_test_clin_quest
    (
        i_action                      VARCHAR,
        i_id_cnt_lab_test_sample_type VARCHAR,
        i_id_cnt_question_response    VARCHAR,
        i_flg_time                    VARCHAR,
        i_rank                        NUMBER,
        i_flg_type                    VARCHAR,
        i_flg_mandatory               VARCHAR,
        i_flg_copy                    VARCHAR,
        i_flg_validation              VARCHAR,
        i_flg_exterior                VARCHAR,
        i_id_unit_measure             NUMBER,
        i_id_institution              NUMBER
    ) IS
        l_id_analysis      NUMBER;
        l_id_sample_type   NUMBER;
        l_id_response      NUMBER;
        l_id_questionnaire NUMBER;
    
    BEGIN
        g_func_name := 'set_lab_test_clin_quest';
        /*    select q.id_questionnaire
          into l_id_questionnaire
          from questionnaire q
         where q.id_content = i_id_cnt_clinical_question
           and q.flg_available = g_flg_available;
        
        if i_id_cnt_response is not null then
        
          select q.id_response
            into l_id_response
            from response q
           where q.id_content = i_id_cnt_response
             and q.flg_available = g_flg_available;
        
        else
          l_id_response := null;
        
        end if;*/
    
        SELECT q.id_questionnaire, q.id_response
          INTO l_id_questionnaire, l_id_response
          FROM questionnaire_response q
         WHERE q.id_content = i_id_cnt_question_response
           AND q.flg_available = g_flg_available;
    
        BEGIN
            SELECT a.id_analysis, a.id_sample_type
              INTO l_id_analysis, l_id_sample_type
              FROM analysis_sample_type a
             WHERE id_content = i_id_cnt_lab_test_sample_type
               AND a.flg_available = g_flg_available;
        
        EXCEPTION
            WHEN OTHERS THEN
                --raise_application_error(-20001, SQLERRM);
                l_id_analysis    := 0;
                l_id_sample_type := 0;
            
        END;
    
        IF i_action = g_flg_create
        THEN
            INSERT INTO analysis_questionnaire
                (id_analysis_questionnaire,
                 id_analysis,
                 id_questionnaire,
                 flg_time,
                 rank,
                 flg_available,
                 id_sample_type,
                 id_response,
                 flg_type,
                 flg_mandatory,
                 flg_copy,
                 flg_validation,
                 flg_exterior,
                 id_unit_measure,
                 id_institution)
            VALUES
                (seq_analysis_questionnaire.nextval,
                 l_id_analysis,
                 l_id_questionnaire,
                 i_flg_time,
                 i_rank,
                 g_flg_available,
                 l_id_sample_type,
                 l_id_response,
                 i_flg_type,
                 i_flg_mandatory,
                 i_flg_copy,
                 i_flg_validation,
                 i_flg_exterior,
                 i_id_unit_measure,
                 i_id_institution);
        
        ELSIF i_action = g_flg_update
        THEN
            UPDATE analysis_questionnaire aq
               SET flg_type        = i_flg_type,
                   flg_mandatory   = i_flg_mandatory,
                   rank            = i_rank,
                   flg_time        = i_flg_time,
                   flg_copy        = i_flg_copy,
                   flg_validation  = i_flg_validation,
                   flg_exterior    = i_flg_exterior,
                   id_unit_measure = i_id_unit_measure
             WHERE aq.id_questionnaire = l_id_questionnaire
               AND aq.id_response = l_id_response
               AND aq.id_analysis = l_id_analysis
               AND aq.id_sample_type = l_id_sample_type
               AND aq.id_institution = i_id_institution;
        
        ELSIF i_action = g_flg_delete
        THEN
            DELETE analysis_questionnaire aq
             WHERE aq.id_questionnaire = l_id_questionnaire
               AND aq.id_response = l_id_response
               AND aq.id_analysis = l_id_analysis
               AND aq.id_sample_type = l_id_sample_type
               AND aq.id_institution = i_id_institution;
        
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            raise_application_error(-20001, SQLERRM);
            pk_alert_exceptions.process_error(g_language,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
        
    END;

    PROCEDURE set_other_exam_clin_quest
    (
        i_action                   VARCHAR,
        i_id_cnt_other_exam        VARCHAR,
        i_id_cnt_question_response VARCHAR,
        i_flg_time                 VARCHAR,
        i_flg_type                 VARCHAR,
        i_flg_mandatory            VARCHAR,
        i_rank                     NUMBER,
        i_flg_copy                 VARCHAR,
        i_flg_validation           VARCHAR,
        i_flg_exterior             VARCHAR,
        i_id_unit_measure          VARCHAR,
        i_id_institution           NUMBER
    ) IS
        l_id_exam          NUMBER;
        l_id_response      NUMBER;
        l_id_questionnaire NUMBER;
    BEGIN
        g_func_name := 'set_other_exam_clin_quest';
        /*  select q.id_questionnaire
            into l_id_questionnaire
            from questionnaire q
           where q.id_content = i_id_cnt_clinical_question
             and q.flg_available = g_flg_available;
        
          if i_id_cnt_response is not null then
        
            select q.id_response
              into l_id_response
              from response q
             where q.id_content = i_id_cnt_response
               and q.flg_available = g_flg_available;
          else
            l_id_response := null;
          end if;
        */
        SELECT q.id_questionnaire, q.id_response
          INTO l_id_questionnaire, l_id_response
          FROM questionnaire_response q
         WHERE q.id_content = i_id_cnt_question_response
           AND q.flg_available = g_flg_available;
    
        SELECT q.id_exam
          INTO l_id_exam
          FROM exam q
         WHERE q.id_content = i_id_cnt_other_exam
           AND q.flg_available = g_flg_available;
        IF i_action = g_flg_create
        THEN
            INSERT INTO exam_questionnaire
                (id_exam_questionnaire,
                 id_exam,
                 id_questionnaire,
                 flg_type,
                 flg_mandatory,
                 rank,
                 flg_available,
                 flg_time,
                 id_exam_group,
                 id_response,
                 flg_copy,
                 flg_validation,
                 flg_exterior,
                 id_unit_measure,
                 id_institution)
            VALUES
                (seq_exam_questionnaire.nextval,
                 l_id_exam,
                 l_id_questionnaire,
                 i_flg_type,
                 i_flg_mandatory,
                 i_rank,
                 g_flg_available,
                 i_flg_time,
                 NULL,
                 l_id_response,
                 i_flg_copy,
                 i_flg_validation,
                 i_flg_exterior,
                 i_id_unit_measure,
                 i_id_institution);
        ELSIF i_action = g_flg_update
        THEN
            UPDATE exam_questionnaire eq
               SET flg_type        = i_flg_type,
                   flg_mandatory   = i_flg_mandatory,
                   rank            = i_rank,
                   flg_time        = i_flg_time,
                   flg_copy        = i_flg_copy,
                   flg_validation  = i_flg_validation,
                   flg_exterior    = i_flg_exterior,
                   id_unit_measure = i_id_unit_measure
             WHERE eq.id_questionnaire = l_id_questionnaire
               AND eq.id_response = l_id_response
               AND eq.id_exam = l_id_exam
               AND eq.id_institution = i_id_institution;
        ELSIF i_action = g_flg_delete
        THEN
            DELETE exam_questionnaire eq
             WHERE eq.id_questionnaire = l_id_questionnaire
               AND eq.id_response = l_id_response
               AND eq.id_exam = l_id_exam
               AND eq.id_institution = i_id_institution;
        
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            raise_application_error(-20001, SQLERRM);
            pk_alert_exceptions.process_error(g_language,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
    END;

    --Related to ALERT-330933 Changes to inpatient and surgery request
    PROCEDURE set_procedure_core
    (
        i_action             VARCHAR,
        i_id_language        VARCHAR,
        i_id_cnt_procedure   VARCHAR,
        i_id_institution     NUMBER,
        i_id_software        NUMBER,
        i_desc_procedure     VARCHAR,
        i_age_min            NUMBER,
        i_age_max            NUMBER,
        i_gender             VARCHAR,
        i_rank               NUMBER,
        i_flg_mov_pat        VARCHAR,
        i_cpt_code           VARCHAR,
        i_ref_form_code      VARCHAR,
        i_barcode            VARCHAR,
        i_flg_execute        VARCHAR,
        i_flg_technical      VARCHAR,
        i_desc_alias         VARCHAR DEFAULT NULL,
        i_flg_category_type  VARCHAR,
        i_duration           NUMBER,
        i_prev_recovery_time NUMBER,
        i_flg_priority       VARCHAR
    ) IS
    
        l_cod_intervention exam.code_exam%TYPE;
    
        l_intervention          NUMBER;
        l_interv_p              NUMBER;
        l_cnt_interv_cat        NUMBER;
        l_cat_prof              table_number := table_number(1, 2, 23, 29);
        l_id_intervention_alias NUMBER;
    BEGIN
    
        g_func_name := 'set_procedure_core';
    
        SELECT nvl((SELECT a.id_intervention
                     FROM intervention a
                    WHERE a.id_content = i_id_cnt_procedure
                      AND a.flg_status = g_flg_active),
                   0)
          INTO l_intervention
          FROM dual;
    
        IF (i_action = g_flg_create OR i_action = g_flg_update)
           AND i_desc_procedure IS NOT NULL
           AND l_intervention = 0
        THEN
        
            SELECT seq_intervention.nextval
              INTO l_intervention
              FROM dual;
        
            INSERT INTO intervention
                (id_intervention,
                 id_intervention_parent,
                 code_intervention,
                 flg_status,
                 cost,
                 price,
                 code_help_interv,
                 rank,
                 adw_last_update,
                 id_body_part,
                 flg_mov_pat,
                 id_spec_sys_appar,
                 flg_type,
                 duration,
                 gender,
                 age_min,
                 age_max,
                 mdm_coding,
                 cpt_code,
                 ref_form_code,
                 id_content,
                 barcode,
                 flg_category_type,
                 prev_recovery_time,
                 id_system_organ,
                 flg_technical)
            VALUES
                (l_intervention,
                 NULL,
                 'INTERVENTION.CODE_INTERVENTION.' || l_intervention,
                 g_flg_active,
                 NULL, -- i_cost,
                 NULL, --i_price,
                 NULL, --code_help_interv,
                 i_rank,
                 SYSDATE,
                 NULL, --id_body_part,
                 i_flg_mov_pat,
                 NULL, --id_spec_sys_appar,
                 NULL, -- i_flg_type (bandaid products),
                 i_duration, --  i_duration,
                 i_gender,
                 i_age_min,
                 i_age_max,
                 NULL, -- i_mdm_coding,
                 i_cpt_code,
                 i_ref_form_code,
                 i_id_cnt_procedure,
                 i_barcode,
                 i_flg_category_type,
                 i_prev_recovery_time,
                 NULL,
                 i_flg_technical);
        
            SELECT e.code_intervention
              INTO l_cod_intervention
              FROM intervention e
             WHERE e.id_intervention = l_intervention;
        
            pk_translation.insert_into_translation(i_id_language, l_cod_intervention, i_desc_procedure);
        
            IF i_desc_alias IS NOT NULL
            THEN
            
                FOR i IN 1 .. l_cat_prof.count
                LOOP
                
                    SELECT nvl((SELECT MAX(a.id_intervention_alias) + 1
                                 FROM intervention_alias a),
                               0)
                      INTO l_id_intervention_alias
                      FROM dual;
                
                    INSERT INTO intervention_alias
                        (id_intervention_alias,
                         code_intervention_alias,
                         id_intervention,
                         id_category,
                         id_institution,
                         id_software,
                         id_dep_clin_serv,
                         id_professional)
                    VALUES
                        (l_id_intervention_alias,
                         'INTERVENTION_ALIAS.CODE_INTERVENTION_ALIAS.' || l_id_intervention_alias,
                         l_intervention,
                         l_cat_prof(i),
                         i_id_institution,
                         i_id_software,
                         NULL,
                         NULL);
                
                    pk_translation.insert_into_translation(i_id_language,
                                                           'INTERVENTION_ALIAS.CODE_INTERVENTION_ALIAS.' ||
                                                           l_id_intervention_alias,
                                                           i_desc_alias);
                
                END LOOP;
            
            END IF;
        
            INSERT INTO interv_dep_clin_serv
                (id_interv_dep_clin_serv,
                 id_intervention,
                 flg_type,
                 rank,
                 id_institution,
                 id_software,
                 flg_bandaid,
                 flg_execute,
                 flg_priority)
                SELECT seq_interv_dep_clin_serv.nextval,
                       e.id_intervention,
                       g_flg_searchable,
                       g_rank_zero,
                       i_id_institution,
                       i_id_software,
                       g_flg_no,
                       g_flg_available,
                       i_flg_priority
                  FROM intervention e
                 WHERE e.id_intervention = l_intervention
                   AND NOT EXISTS (SELECT 1
                          FROM interv_dep_clin_serv edcs1
                         WHERE edcs1.id_intervention = e.id_intervention
                           AND edcs1.id_dep_clin_serv IS NULL
                           AND edcs1.id_software = i_id_software
                           AND edcs1.id_institution = i_id_institution
                           AND edcs1.flg_type = pk_exam_constant.g_exam_can_req);
        
        ELSIF i_action = g_flg_update
              AND l_intervention != 0
        THEN
        
            UPDATE intervention a
               SET age_min              = i_age_min,
                   age_max              = i_age_max,
                   gender               = i_gender,
                   a.cpt_code           = i_cpt_code,
                   a.ref_form_code      = i_ref_form_code,
                   a.barcode            = i_barcode,
                   a.flg_mov_pat        = i_flg_mov_pat,
                   a.duration           = i_duration,
                   a.prev_recovery_time = i_prev_recovery_time,
                   a.flg_technical      = i_flg_technical
             WHERE a.id_intervention = l_intervention;
        
            SELECT nvl((SELECT a.id_intervention
                         FROM interv_dep_clin_serv a
                        WHERE a.id_intervention = l_intervention
                          AND a.id_software = i_id_software
                          AND a.id_dep_clin_serv IS NULL
                          AND a.id_institution = i_id_institution
                          AND a.flg_type = g_flg_searchable),
                       0)
              INTO l_interv_p
              FROM dual;
        
            IF l_interv_p != 0
            THEN
            
                UPDATE interv_dep_clin_serv a
                   SET a.flg_execute = i_flg_execute, a.flg_priority = i_flg_priority
                 WHERE a.id_intervention = l_intervention
                   AND a.id_software = i_id_software
                   AND a.id_dep_clin_serv IS NULL
                   AND a.id_institution = i_id_institution
                   AND a.flg_type = g_flg_searchable;
            
            ELSE
            
                INSERT INTO interv_dep_clin_serv
                    (id_interv_dep_clin_serv,
                     id_intervention,
                     flg_type,
                     rank,
                     id_institution,
                     id_software,
                     flg_bandaid,
                     flg_execute,
                     flg_priority)
                    SELECT seq_interv_dep_clin_serv.nextval,
                           e.id_intervention,
                           g_flg_searchable,
                           g_rank_zero,
                           i_id_institution,
                           i_id_software,
                           g_flg_no,
                           g_flg_available,
                           i_flg_priority
                      FROM intervention e
                     WHERE e.id_intervention = l_intervention;
            END IF;
        
            SELECT COUNT(*)
              INTO l_id_intervention_alias
              FROM intervention_alias a
             WHERE a.id_intervention = l_intervention
               AND a.id_institution = i_id_institution
               AND a.id_software = i_id_software;
        
            IF l_id_intervention_alias = 0
               AND i_desc_alias IS NOT NULL
            THEN
            
                FOR i IN 1 .. l_cat_prof.count
                LOOP
                
                    SELECT nvl((SELECT MAX(a.id_intervention_alias) + 1
                                 FROM intervention_alias a),
                               0)
                      INTO l_id_intervention_alias
                      FROM dual;
                
                    INSERT INTO intervention_alias
                        (id_intervention_alias,
                         code_intervention_alias,
                         id_intervention,
                         id_category,
                         id_institution,
                         id_software,
                         id_dep_clin_serv,
                         id_professional)
                    VALUES
                        (l_id_intervention_alias,
                         'INTERVENTION_ALIAS.CODE_INTERVENTION_ALIAS.' || l_id_intervention_alias,
                         l_intervention,
                         l_cat_prof(i),
                         i_id_institution,
                         i_id_software,
                         NULL,
                         NULL);
                
                    pk_translation.insert_into_translation(i_id_language,
                                                           'INTERVENTION_ALIAS.CODE_INTERVENTION_ALIAS.' ||
                                                           l_id_intervention_alias,
                                                           i_desc_alias);
                
                END LOOP;
            
            ELSIF l_id_intervention_alias > 0
                  AND i_desc_alias IS NOT NULL
            THEN
            
                FOR i IN (SELECT a.id_intervention_alias
                            FROM intervention_alias a
                           WHERE a.id_intervention = l_intervention
                             AND a.id_institution = i_id_institution
                             AND a.id_software = i_id_software)
                LOOP
                
                    pk_translation.insert_into_translation(i_id_language,
                                                           'INTERVENTION_ALIAS.CODE_INTERVENTION_ALIAS.' ||
                                                           i.id_intervention_alias,
                                                           i_desc_alias);
                
                END LOOP;
            
            ELSIF l_id_intervention_alias > 0
                  AND i_desc_alias IS NULL
            THEN
            
                FOR i IN (SELECT a.id_intervention_alias
                            FROM intervention_alias a
                           WHERE a.id_intervention = l_intervention
                             AND a.id_institution = i_id_institution
                             AND a.id_software = i_id_software)
                LOOP
                
                    pk_translation.insert_into_translation(i_id_language,
                                                           'INTERVENTION_ALIAS.CODE_INTERVENTION_ALIAS.' ||
                                                           i.id_intervention_alias,
                                                           i_desc_alias);
                
                END LOOP;
            END IF;
        
        ELSIF i_action = g_flg_delete
        THEN
            DELETE FROM intervention_alias a
             WHERE a.id_intervention = l_intervention
               AND a.id_institution = i_id_institution
               AND a.id_software = i_id_software;
        
            DELETE FROM interv_dep_clin_serv a
             WHERE a.id_intervention = l_intervention
               AND a.id_institution = i_id_institution
                  -- AND a.flg_type = g_flg_searchable
               AND a.id_software = i_id_software;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            raise_application_error(-20001, SQLERRM);
            pk_alert_exceptions.process_error(i_id_language,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
        
    END set_procedure_core;

    PROCEDURE set_sr_procedure
    (
        i_action              VARCHAR,
        i_id_language         VARCHAR,
        i_id_institution      NUMBER,
        i_id_software         NUMBER,
        i_desc_sr_procedure   VARCHAR,
        i_icd                 VARCHAR,
        i_gender              VARCHAR,
        i_age_min             NUMBER,
        i_age_max             NUMBER,
        i_duration            NUMBER,
        i_prev_recovery_time  NUMBER,
        i_flg_coding          VARCHAR,
        i_id_cnt_sr_procedure VARCHAR
    ) IS
    
    BEGIN
    
        g_func_name := 'set_sr_procedure';
        --Call the main core procedure sending
        --For surgical interventions the i_flg_category_type = SR
        set_procedure_core(i_action             => i_action,
                           i_id_language        => i_id_language,
                           i_id_cnt_procedure   => i_id_cnt_sr_procedure,
                           i_id_institution     => i_id_institution,
                           i_id_software        => i_id_software,
                           i_desc_procedure     => i_desc_sr_procedure,
                           i_age_min            => i_age_min,
                           i_age_max            => i_age_max,
                           i_gender             => i_gender,
                           i_rank               => 0,
                           i_flg_mov_pat        => 'N',
                           i_cpt_code           => i_icd,
                           i_ref_form_code      => NULL,
                           i_barcode            => NULL,
                           i_flg_execute        => NULL,
                           i_desc_alias         => NULL,
                           i_flg_category_type  => g_sr_intervention,
                           i_flg_technical      => 'N',
                           i_duration           => i_duration,
                           i_prev_recovery_time => i_prev_recovery_time,
                           i_flg_priority       => NULL);
    
    EXCEPTION
        WHEN OTHERS THEN
            raise_application_error(-20001, SQLERRM);
            pk_alert_exceptions.process_error(i_id_language,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
        
    END set_sr_procedure;

    PROCEDURE set_procedure_by_category
    (
        i_action               VARCHAR,
        i_id_language          VARCHAR,
        i_id_cnt_procedure     VARCHAR,
        i_id_institution       NUMBER,
        i_id_software          NUMBER,
        i_id_cnt_procedure_cat VARCHAR,
        i_rank                 NUMBER
    ) IS
        l_intervention   NUMBER;
        l_cnt_interv_cat NUMBER;
        l_add            VARCHAR(1) := 'A';
    BEGIN
        g_func_name := 'set_procedure_by_category';
        SELECT nvl((SELECT a.id_intervention
                     FROM intervention a
                    WHERE a.id_content = i_id_cnt_procedure
                      AND a.flg_status = g_flg_active),
                   0)
          INTO l_intervention
          FROM dual;
    
        SELECT nvl((SELECT a.id_interv_category
                     FROM interv_category a
                    WHERE a.id_content = i_id_cnt_procedure_cat
                      AND a.flg_available = g_flg_available),
                   0)
          INTO l_cnt_interv_cat
          FROM dual;
    
        IF l_intervention > 0
           AND l_cnt_interv_cat > 0
        THEN
            IF i_action = g_flg_create
            THEN
            
                INSERT /*+ ignore_row_on_dupkey_index(iic IIT_PK) */
                INTO interv_int_cat iic
                    (id_interv_category,
                     id_intervention,
                     rank,
                     adw_last_update,
                     id_software,
                     id_institution,
                     flg_add_remove)
                VALUES
                    (l_cnt_interv_cat, l_intervention, i_rank, SYSDATE, i_id_software, i_id_institution, l_add);
            
            ELSIF i_action = g_flg_update
            THEN
                UPDATE interv_int_cat
                   SET rank = i_rank, id_interv_category = l_cnt_interv_cat
                 WHERE id_intervention = l_intervention
                   AND id_institution = i_id_institution
                   AND id_software = i_id_software;
            ELSIF i_action = g_flg_delete
            THEN
            
                DELETE FROM interv_int_cat
                 WHERE id_intervention = l_intervention
                   AND id_interv_category = l_cnt_interv_cat
                   AND id_institution = i_id_institution
                   AND id_software = i_id_software;
            END IF;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            raise_application_error(-20001, SQLERRM);
            pk_alert_exceptions.process_error(i_id_language,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
        
    END;

    PROCEDURE set_procedure
    (
        i_action           VARCHAR,
        i_id_language      VARCHAR,
        i_id_cnt_procedure VARCHAR,
        i_id_institution   NUMBER,
        i_id_software      NUMBER,
        i_desc_procedure   VARCHAR,
        i_age_min          NUMBER,
        i_age_max          NUMBER,
        i_gender           VARCHAR,
        i_rank             NUMBER,
        i_flg_mov_pat      VARCHAR,
        i_cpt_code         VARCHAR,
        i_ref_form_code    VARCHAR,
        i_barcode          VARCHAR,
        i_flg_execute      VARCHAR,
        i_flg_technical    VARCHAR DEFAULT 'N',
        i_flg_priority     VARCHAR,
        i_desc_alias       VARCHAR DEFAULT NULL
    ) IS
    
        l_cod_intervention exam.code_exam%TYPE;
    
        l_intervention          NUMBER;
        l_cnt_interv_cat        NUMBER;
        i_cat_prof              table_number := table_number(1, 2, 23, 29);
        l_id_intervention_alias NUMBER;
    BEGIN
    
        g_func_name := 'set_procedure';
    
        --Call the main core procedure sending
        --For intervention the i_flg_category_type = 'P'
        set_procedure_core(i_action             => i_action,
                           i_id_language        => i_id_language,
                           i_id_cnt_procedure   => i_id_cnt_procedure,
                           i_id_institution     => i_id_institution,
                           i_id_software        => i_id_software,
                           i_desc_procedure     => i_desc_procedure,
                           i_age_min            => i_age_min,
                           i_age_max            => i_age_max,
                           i_gender             => i_gender,
                           i_rank               => i_rank,
                           i_flg_mov_pat        => i_flg_mov_pat,
                           i_cpt_code           => i_cpt_code,
                           i_ref_form_code      => i_ref_form_code,
                           i_barcode            => i_barcode,
                           i_flg_execute        => i_flg_execute,
                           i_flg_technical      => i_flg_technical,
                           i_desc_alias         => i_desc_alias,
                           i_flg_category_type  => 'P',
                           i_duration           => NULL,
                           i_prev_recovery_time => NULL,
                           i_flg_priority       => i_flg_priority);
    
    EXCEPTION
        WHEN OTHERS THEN
            raise_application_error(-20001, SQLERRM);
            pk_alert_exceptions.process_error(i_id_language,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
        
    END set_procedure;

    PROCEDURE set_procedure_ctlg
    (
        i_action           VARCHAR,
        i_id_language      VARCHAR,
        i_id_cnt_procedure VARCHAR,
        i_id_institution   NUMBER,
        i_id_software      NUMBER,
        i_desc_procedure   VARCHAR,
        i_age_min          NUMBER,
        i_age_max          NUMBER,
        i_gender           VARCHAR,
        i_rank             NUMBER,
        i_flg_mov_pat      VARCHAR,
        i_cpt_code         VARCHAR,
        i_ref_form_code    VARCHAR,
        i_barcode          VARCHAR,
        i_flg_technical    VARCHAR DEFAULT 'N',
        i_desc_alias       VARCHAR DEFAULT NULL
    ) IS
    
        l_cod_intervention intervention.code_intervention%TYPE;
    
        l_intervention          NUMBER;
        l_intervention_status   VARCHAR2(1);
        l_cnt_interv_cat        NUMBER;
        l_id_intervention_alias NUMBER;
        l_error                 VARCHAR2(4000);
        l_bool                  BOOLEAN;
        l_ids                   table_number;
        l_status                table_varchar;
    
    BEGIN
    
        g_func_name := 'set_procedure_ctlg';
    
        l_bool := validate_content(i_id_language,
                                   i_id_institution,
                                   table_varchar(i_id_cnt_procedure),
                                   table_varchar('PROCEDURE'),
                                   table_number(0),
                                   l_ids,
                                   l_status);
    
        l_intervention        := l_ids(1);
        l_intervention_status := l_status(1);
    
        IF l_intervention = 0
        THEN
        
            IF i_action IN (g_flg_create, g_flg_update)
            THEN
            
                validate_description_exists(i_id_language,
                                            i_desc_procedure,
                                            'INTERVENTION',
                                            'ALERT',
                                            'CODE_INTERVENTION');
            
                SELECT seq_intervention.nextval
                  INTO l_intervention
                  FROM dual;
            
                INSERT INTO intervention
                    (id_intervention,
                     id_intervention_parent,
                     code_intervention,
                     flg_status,
                     cost,
                     price,
                     code_help_interv,
                     rank,
                     adw_last_update,
                     id_body_part,
                     flg_mov_pat,
                     id_spec_sys_appar,
                     flg_type,
                     duration,
                     gender,
                     age_min,
                     age_max,
                     mdm_coding,
                     cpt_code,
                     ref_form_code,
                     id_content,
                     barcode,
                     flg_category_type,
                     prev_recovery_time,
                     id_system_organ,
                     flg_technical)
                VALUES
                    (l_intervention,
                     NULL,
                     'INTERVENTION.CODE_INTERVENTION.' || l_intervention,
                     g_flg_active,
                     NULL, -- i_cost,
                     NULL, --i_price,
                     NULL, --code_help_interv,
                     nvl(i_rank, 0),
                     SYSDATE,
                     NULL, --id_body_part,
                     i_flg_mov_pat,
                     NULL, --id_spec_sys_appar,
                     NULL, -- i_flg_type (bandaid products),
                     NULL, --  i_duration,
                     i_gender,
                     i_age_min,
                     i_age_max,
                     NULL, -- i_mdm_coding,
                     i_cpt_code,
                     i_ref_form_code,
                     i_id_cnt_procedure,
                     i_barcode,
                     'P',
                     NULL,
                     NULL,
                     i_flg_technical);
            
                SELECT e.code_intervention
                  INTO l_cod_intervention
                  FROM intervention e
                 WHERE e.id_intervention = l_intervention;
            
                pk_translation.insert_into_translation(i_id_language, l_cod_intervention, i_desc_procedure);
            
                set_procedure_alias(i_id_language, i_id_institution, i_id_software, i_id_cnt_procedure, i_desc_alias);
            
            END IF;
        
        ELSIF l_intervention != 0
        THEN
        
            IF i_action = g_flg_create
            THEN
            
                IF l_intervention_status = 'A'
                THEN
                    l_error := 'ID_CONTENT to be created already exists!';
                    RAISE g_exception;
                ELSIF l_intervention_status = 'I'
                THEN
                    UPDATE intervention
                       SET flg_status = 'A'
                     WHERE id_content = i_id_cnt_procedure;
                END IF;
            
            ELSIF i_action = g_flg_update
            THEN
            
                UPDATE intervention a
                   SET a.age_min       = i_age_min,
                       a.age_max       = i_age_max,
                       a.gender        = i_gender,
                       a.cpt_code      = i_cpt_code,
                       a.ref_form_code = i_ref_form_code,
                       a.barcode       = i_barcode,
                       a.flg_mov_pat   = i_flg_mov_pat,
                       a.flg_technical = i_flg_technical,
                       a.flg_status    = g_flg_active,
                       a.rank          = nvl(i_rank, 0)
                 WHERE a.id_intervention = l_intervention;
            
                set_procedure_alias(i_id_language, i_id_institution, i_id_software, i_id_cnt_procedure, i_desc_alias);
            
            ELSIF i_action = g_flg_delete
            THEN
            
                UPDATE intervention
                   SET flg_status = g_flg_inactive
                 WHERE id_content = i_id_cnt_procedure;
            
            END IF;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            raise_application_error(-20001, SQLERRM);
            pk_alert_exceptions.process_error(i_id_language,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
        
    END set_procedure_ctlg;

    PROCEDURE set_sr_procedure_ctlg
    (
        i_action              VARCHAR,
        i_id_language         VARCHAR,
        i_id_cnt_sr_procedure VARCHAR,
        i_id_institution      NUMBER,
        i_id_software         NUMBER,
        i_desc_sr_procedure   VARCHAR,
        i_age_min             NUMBER,
        i_age_max             NUMBER,
        i_gender              VARCHAR,
        i_rank                NUMBER,
        i_flg_mov_pat         VARCHAR,
        i_cpt_code            VARCHAR,
        i_ref_form_code       VARCHAR,
        i_barcode             VARCHAR,
        i_flg_technical       VARCHAR DEFAULT 'N',
        i_desc_alias          VARCHAR DEFAULT NULL
    ) IS
    
        l_cod_intervention intervention.code_intervention%TYPE;
    
        l_intervention          NUMBER;
        l_intervention_status   VARCHAR2(1);
        l_cnt_interv_cat        NUMBER;
        l_id_intervention_alias NUMBER;
        l_error                 VARCHAR2(4000);
        l_bool                  BOOLEAN;
        l_ids                   table_number;
        l_status                table_varchar;
    
    BEGIN
    
        g_func_name := 'set_sr_procedure_ctlg';
    
        l_bool := validate_content(i_id_language,
                                   i_id_institution,
                                   table_varchar(i_id_cnt_sr_procedure),
                                   table_varchar('SURGICAL_PROCEDURE'),
                                   table_number(0),
                                   l_ids,
                                   l_status);
    
        l_intervention        := l_ids(1);
        l_intervention_status := l_status(1);
    
        IF l_intervention = 0
        THEN
        
            IF i_action IN (g_flg_create, g_flg_update)
            THEN
            
                validate_description_exists(i_id_language,
                                            i_desc_sr_procedure,
                                            'INTERVENTION',
                                            'ALERT',
                                            'CODE_INTERVENTION');
            
                SELECT seq_intervention.nextval
                  INTO l_intervention
                  FROM dual;
            
                INSERT INTO intervention
                    (id_intervention,
                     id_intervention_parent,
                     code_intervention,
                     flg_status,
                     cost,
                     price,
                     code_help_interv,
                     rank,
                     adw_last_update,
                     id_body_part,
                     flg_mov_pat,
                     id_spec_sys_appar,
                     flg_type,
                     duration,
                     gender,
                     age_min,
                     age_max,
                     mdm_coding,
                     cpt_code,
                     ref_form_code,
                     id_content,
                     barcode,
                     flg_category_type,
                     prev_recovery_time,
                     id_system_organ,
                     flg_technical)
                VALUES
                    (l_intervention,
                     NULL,
                     'INTERVENTION.CODE_INTERVENTION.' || l_intervention,
                     g_flg_active,
                     NULL, -- i_cost,
                     NULL, --i_price,
                     NULL, --code_help_interv,
                     i_rank,
                     SYSDATE,
                     NULL, --id_body_part,
                     i_flg_mov_pat,
                     NULL, --id_spec_sys_appar,
                     NULL, -- i_flg_type (bandaid products),
                     NULL, --  i_duration,
                     i_gender,
                     i_age_min,
                     i_age_max,
                     NULL, -- i_mdm_coding,
                     i_cpt_code,
                     i_ref_form_code,
                     i_id_cnt_sr_procedure,
                     i_barcode,
                     g_sr_intervention,
                     NULL,
                     NULL,
                     i_flg_technical);
            
                SELECT e.code_intervention
                  INTO l_cod_intervention
                  FROM intervention e
                 WHERE e.id_intervention = l_intervention;
            
                pk_translation.insert_into_translation(i_id_language, l_cod_intervention, i_desc_sr_procedure);
            
                set_procedure_alias(i_id_language,
                                    i_id_institution,
                                    i_id_software,
                                    i_id_cnt_sr_procedure,
                                    i_desc_alias);
            
            END IF;
        
        ELSIF l_intervention != 0
        THEN
        
            IF i_action = g_flg_create
            THEN
            
                IF l_intervention_status = 'A'
                THEN
                    l_error := 'ID_CONTENT to be created already exists!';
                    RAISE g_exception;
                ELSIF l_intervention_status = 'I'
                THEN
                    UPDATE intervention
                       SET flg_status = 'A'
                     WHERE id_content = i_id_cnt_sr_procedure;
                END IF;
            
            ELSIF i_action = g_flg_update
            THEN
            
                UPDATE intervention a
                   SET a.age_min       = i_age_min,
                       a.age_max       = i_age_max,
                       a.gender        = i_gender,
                       a.cpt_code      = i_cpt_code,
                       a.ref_form_code = i_ref_form_code,
                       a.barcode       = i_barcode,
                       a.flg_mov_pat   = i_flg_mov_pat,
                       a.flg_technical = i_flg_technical,
                       a.flg_status    = g_flg_active,
                       a.rank          = i_rank
                 WHERE a.id_intervention = l_intervention;
            
                set_procedure_alias(i_id_language,
                                    i_id_institution,
                                    i_id_software,
                                    i_id_cnt_sr_procedure,
                                    i_desc_alias);
            
            ELSIF i_action = g_flg_delete
            THEN
            
                UPDATE intervention
                   SET flg_status = g_flg_inactive
                 WHERE id_content = i_id_cnt_sr_procedure;
            
            END IF;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            raise_application_error(-20001, SQLERRM);
            pk_alert_exceptions.process_error(i_id_language,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
        
    END set_sr_procedure_ctlg;

    PROCEDURE set_img_exam_freq
    (
        i_action           VARCHAR,
        i_id_cnt_img_exam  VARCHAR,
        i_id_institution   NUMBER,
        i_id_software      NUMBER,
        i_id_dep_clin_serv NUMBER
    ) IS
    
        l_exam NUMBER;
    
        l_action VARCHAR(1);
    
    BEGIN
        g_func_name := 'set_img_exam_freq';
    
        SELECT a.id_exam
          INTO l_exam
          FROM exam a
         WHERE id_content = i_id_cnt_img_exam
           AND a.flg_available = g_flg_available;
    
        IF i_action = g_flg_create
        THEN
            l_action := g_pk_apex_most_freq_create;
        ELSIF i_action = g_flg_delete
        THEN
            l_action := g_pk_apex_most_freq_delete;
        
        END IF;
        alert_apex_tools.pk_apex_most_freq.set_freq(i_lang           => g_default_language,
                                                    i_id_institution => i_id_institution,
                                                    i_id_software    => i_id_software,
                                                    i_operation      => l_action,
                                                    flg_context      => g_pk_apex_most_freq_by_dcs,
                                                    flg_content      => g_pk_apex_most_freq_exam,
                                                    id_context       => table_varchar(i_id_dep_clin_serv),
                                                    id_content       => table_varchar(l_exam));
    EXCEPTION
        WHEN OTHERS THEN
            raise_application_error(-20001, SQLERRM);
            pk_alert_exceptions.process_error(g_language,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
    END;

    PROCEDURE set_other_exam_freq
    (
        i_action            VARCHAR,
        i_id_cnt_other_exam VARCHAR,
        i_id_institution    NUMBER,
        i_id_software       NUMBER,
        i_id_dep_clin_serv  NUMBER
    ) IS
    
        l_exam NUMBER;
    
        l_action VARCHAR(1);
    
    BEGIN
        g_func_name := 'set_other_exam_freq';
    
        SELECT a.id_exam
          INTO l_exam
          FROM exam a
         WHERE id_content = i_id_cnt_other_exam
           AND a.flg_available = g_flg_available;
    
        IF i_action = g_flg_create
        THEN
            l_action := g_pk_apex_most_freq_create;
        ELSIF i_action = g_flg_delete
        THEN
            l_action := g_pk_apex_most_freq_delete;
        
        END IF;
        alert_apex_tools.pk_apex_most_freq.set_freq(i_lang           => g_default_language,
                                                    i_id_institution => i_id_institution,
                                                    i_id_software    => i_id_software,
                                                    i_operation      => l_action,
                                                    flg_context      => g_pk_apex_most_freq_by_dcs,
                                                    flg_content      => g_pk_apex_most_freq_other_exam,
                                                    id_context       => table_varchar(i_id_dep_clin_serv),
                                                    id_content       => table_varchar(l_exam));
    EXCEPTION
        WHEN OTHERS THEN
            raise_application_error(-20001, SQLERRM);
            pk_alert_exceptions.process_error(g_language,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
    END;

    PROCEDURE set_lab_test_cat_freq
    (
        i_action              VARCHAR,
        i_id_cnt_lab_test_cat VARCHAR,
        i_id_institution      NUMBER,
        i_id_software         NUMBER,
        i_id_dep_clin_serv    NUMBER
    ) IS
    
        l_exam_cat NUMBER;
    
        l_action VARCHAR(1);
    
    BEGIN
        g_func_name := 'set_lab_test_cat_freq';
    
        SELECT a.id_exam_cat
          INTO l_exam_cat
          FROM exam_cat a
         WHERE id_content = i_id_cnt_lab_test_cat
           AND a.flg_available = g_flg_available;
    
        IF i_action = g_flg_create
        THEN
            l_action := g_pk_apex_most_freq_create;
        ELSIF i_action = g_flg_delete
        THEN
            l_action := g_pk_apex_most_freq_delete;
        
        END IF;
        alert_apex_tools.pk_apex_most_freq.set_freq(i_lang           => g_default_language,
                                                    i_id_institution => i_id_institution,
                                                    i_id_software    => i_id_software,
                                                    i_operation      => l_action,
                                                    flg_context      => g_pk_apex_most_freq_by_dcs,
                                                    flg_content      => g_pk_apex_most_freq_exam_cat,
                                                    id_context       => table_varchar(i_id_dep_clin_serv),
                                                    id_content       => table_varchar(l_exam_cat));
    EXCEPTION
        WHEN OTHERS THEN
            raise_application_error(-20001, SQLERRM);
            pk_alert_exceptions.process_error(g_language,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
    END;

    PROCEDURE set_exam_cat_freq
    (
        i_action           VARCHAR,
        i_id_cnt_exam_cat  VARCHAR,
        i_id_institution   NUMBER,
        i_id_software      NUMBER,
        i_id_dep_clin_serv NUMBER
    ) IS
    
        l_exam_cat NUMBER;
    
        l_action VARCHAR(1);
    
    BEGIN
        g_func_name := 'set_exam_cat_freq';
    
        SELECT a.id_exam_cat
          INTO l_exam_cat
          FROM exam_cat a
         WHERE id_content = i_id_cnt_exam_cat
           AND a.flg_available = g_flg_available;
    
        IF i_action = g_flg_create
        THEN
            l_action := g_pk_apex_most_freq_create;
        ELSIF i_action = g_flg_delete
        THEN
            l_action := g_pk_apex_most_freq_delete;
        
        END IF;
        alert_apex_tools.pk_apex_most_freq.set_freq(i_lang           => g_default_language,
                                                    i_id_institution => i_id_institution,
                                                    i_id_software    => i_id_software,
                                                    i_operation      => l_action,
                                                    flg_context      => g_pk_apex_most_freq_by_dcs,
                                                    flg_content      => g_pk_apex_most_freq_exam_cat,
                                                    id_context       => table_varchar(i_id_dep_clin_serv),
                                                    id_content       => table_varchar(l_exam_cat));
    EXCEPTION
        WHEN OTHERS THEN
            raise_application_error(-20001, SQLERRM);
            pk_alert_exceptions.process_error(g_language,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
    END;

    PROCEDURE set_procedure_freq_core
    (
        i_action           VARCHAR,
        i_id_cnt_procedure VARCHAR,
        i_id_institution   NUMBER,
        i_id_software      NUMBER,
        i_id_dep_clin_serv NUMBER
    ) IS
    
        l_procedures NUMBER;
        --l_id_dep_clin_serv NUMBER;
    
        l_action VARCHAR(1);
    
    BEGIN
        g_func_name := 'set_procedure_freq_core';
    
        SELECT nvl((SELECT a.id_intervention
                     FROM intervention a
                    WHERE id_content = i_id_cnt_procedure
                      AND a.flg_status = g_flg_active),
                   0)
          INTO l_procedures
          FROM dual;
    
        /*        SELECT nvl((SELECT DISTINCT c.id_dep_clin_serv
                   FROM clinical_service a
                   JOIN dep_clin_serv c
                     ON c.id_clinical_service = a.id_clinical_service
                   JOIN department d
                     ON d.id_department = c.id_department
                   JOIN dept de
                     ON de.id_dept = d.id_dept
                   JOIN software_dept sd
                     ON sd.id_dept = de.id_dept
                   JOIN institution i
                     ON i.id_institution = d.id_institution
                    AND i.id_institution = de.id_institution
                  WHERE d.id_institution IN (i_id_institution)
                    AND sd.id_software IN (i_id_software)
                    AND d.flg_available = g_flg_available
                    AND c.flg_available = g_flg_available
                    AND a.flg_available = g_flg_available
                    AND de.flg_available = g_flg_available
                    AND a.id_content = i_id_cnt_clinical_service
                    AND d.id_department = i_id_department),
                 0)
        INTO l_id_dep_clin_serv
        FROM dual;*/
    
        IF i_action = g_flg_create
        THEN
            l_action := g_pk_apex_most_freq_create;
        ELSIF i_action = g_flg_delete
        THEN
            l_action := g_pk_apex_most_freq_delete;
        
        END IF;
    
        IF i_id_dep_clin_serv != 0
           AND l_procedures != 0
        THEN
        
            alert_apex_tools.pk_apex_most_freq.set_freq(i_lang           => g_default_language,
                                                        i_id_institution => i_id_institution,
                                                        i_id_software    => i_id_software,
                                                        i_operation      => l_action,
                                                        flg_context      => g_pk_apex_most_freq_by_dcs,
                                                        flg_content      => g_pk_apex_most_freq_proc,
                                                        id_context       => table_varchar(i_id_dep_clin_serv),
                                                        id_content       => table_varchar(l_procedures));
        
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            raise_application_error(-20001, SQLERRM);
            pk_alert_exceptions.process_error(g_language,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
    END;

    PROCEDURE set_professionals_cl
    (
        i_action                  VARCHAR,
        i_id_language             language.id_language%TYPE,
        i_id_institution          institution.id_institution%TYPE,
        i_titulo                  professional.title%TYPE,
        i_nombre                  professional.first_name%TYPE,
        i_apellido_materno        professional.middle_name%TYPE,
        i_apellido_paterno        professional.last_name%TYPE,
        i_nombre_en_la_fotografia professional.nick_name%TYPE,
        i_iniciales               professional.initials%TYPE,
        i_fecha_de_nacimento      VARCHAR2,
        i_sexo                    professional.gender%TYPE,
        i_estado_civil            professional.marital_status%TYPE,
        i_categoria               category.id_category%TYPE,
        i_especialidad            VARCHAR2,
        i_number_colegiado        professional.num_order%TYPE,
        i_categoria_cirurgia      category.id_category%TYPE,
        i_numero_de_profesional   prof_institution.num_mecan%TYPE,
        i_idioma                  prof_preferences.id_language%TYPE,
        i_estado_en_alert         prof_institution.flg_state%TYPE,
        i_direccion               professional.address%TYPE,
        i_ciudad                  professional.city%TYPE,
        i_provincia               professional.district%TYPE,
        i_codigo_postal           professional.zip_code%TYPE,
        i_pais                    VARCHAR2,
        i_telefono_de_trabajo     professional.work_phone%TYPE,
        i_telefono_de_casa        professional.num_contact%TYPE,
        i_movil                   professional.cell_phone%TYPE,
        i_fax                     professional.fax%TYPE,
        i_e_mail                  professional.email%TYPE,
        i_numero_del_mensafono    professional.bleep_number%TYPE,
        i_run                     VARCHAR,
        i_rut                     VARCHAR
    ) IS
    
        l_action              VARCHAR(1);
        o_error               t_error_out;
        o_id_prof             NUMBER;
        RESULT                BOOLEAN;
        l_pais                NUMBER;
        l_especialidad        NUMBER;
        l_fecha_de_nacimento  VARCHAR2(14);
        l_telefono_de_trabajo VARCHAR2(13);
        l_telefono_de_casa    VARCHAR2(13);
        l_titulo              VARCHAR2(13);
    
    BEGIN
        g_func_name := 'set_professionals_cl';
    
        BEGIN
            SELECT val
              INTO l_titulo
              FROM sys_domain a
             WHERE a.code_domain = 'PROFESSIONAL.TITLE'
               AND id_language = i_id_language
               AND desc_val = i_titulo;
        EXCEPTION
            WHEN no_data_found THEN
                l_titulo := i_titulo;
        END;
    
        IF i_telefono_de_trabajo IS NOT NULL
        THEN
            IF length(i_telefono_de_trabajo) = 12
            THEN
                l_telefono_de_trabajo := '+' || i_telefono_de_trabajo;
            ELSE
                l_telefono_de_trabajo := NULL;
            END IF;
        END IF;
    
        IF i_telefono_de_casa IS NOT NULL
        THEN
            IF length(i_telefono_de_casa) = 12
            THEN
                l_telefono_de_casa := '+' || i_telefono_de_casa;
            ELSE
                l_telefono_de_casa := NULL;
            END IF;
        END IF;
    
        IF i_pais IS NOT NULL
        THEN
            BEGIN
                SELECT id_country
                  INTO l_pais
                  FROM country
                 WHERE id_content = i_pais
                   AND flg_available = g_flg_available;
            EXCEPTION
                WHEN no_data_found THEN
                    l_pais := NULL;
            END;
        ELSE
            l_pais := NULL;
        END IF;
    
        IF i_especialidad IS NOT NULL
        THEN
            BEGIN
                SELECT id_speciality
                  INTO l_especialidad
                  FROM speciality
                 WHERE id_content = i_especialidad
                   AND flg_available = g_flg_available;
            EXCEPTION
                WHEN no_data_found THEN
                    l_especialidad := NULL;
            END;
        ELSE
            l_especialidad := NULL;
        END IF;
    
        IF i_fecha_de_nacimento IS NOT NULL
        THEN
            SELECT REPLACE(i_fecha_de_nacimento, '-') || '000000'
              INTO l_fecha_de_nacimento
              FROM dual;
        ELSE
            l_fecha_de_nacimento := NULL;
        END IF;
    
        IF (i_action = g_flg_create)
        THEN
        
            RESULT := pk_backoffice_api_ui.set_professional(i_lang                    => i_id_language,
                                                            i_id_institution          => i_id_institution,
                                                            i_id_prof                 => NULL,
                                                            i_title                   => l_titulo,
                                                            i_first_name              => i_nombre,
                                                            i_middle_name             => i_apellido_materno,
                                                            i_last_name               => i_apellido_paterno,
                                                            i_nick_name               => i_nombre_en_la_fotografia,
                                                            i_initials                => i_iniciales,
                                                            i_dt_birth                => l_fecha_de_nacimento,
                                                            i_gender                  => i_sexo,
                                                            i_marital_status          => i_estado_civil,
                                                            i_id_category             => i_categoria,
                                                            i_id_speciality           => l_especialidad,
                                                            i_num_order               => i_number_colegiado,
                                                            i_upin                    => NULL,
                                                            i_dea                     => NULL,
                                                            i_id_cat_surgery          => i_categoria_cirurgia,
                                                            i_num_mecan               => i_numero_de_profesional,
                                                            i_id_lang                 => i_idioma,
                                                            i_flg_state               => i_estado_en_alert,
                                                            i_address                 => i_direccion,
                                                            i_city                    => i_ciudad,
                                                            i_district                => i_provincia,
                                                            i_zip_code                => i_codigo_postal,
                                                            i_id_country              => l_pais,
                                                            i_work_phone              => l_telefono_de_trabajo,
                                                            i_num_contact             => l_telefono_de_casa,
                                                            i_cell_phone              => i_movil,
                                                            i_fax                     => i_fax,
                                                            i_email                   => i_e_mail,
                                                            i_adress_type             => NULL,
                                                            i_id_scholarship          => NULL,
                                                            i_agrupacion              => NULL,
                                                            i_id_road                 => NULL,
                                                            i_entity                  => NULL,
                                                            i_jurisdiction            => NULL,
                                                            i_municip                 => NULL,
                                                            i_localidad               => NULL,
                                                            i_id_postal_code_rb       => NULL,
                                                            i_bleep_num               => i_numero_del_mensafono,
                                                            i_suffix                  => NULL,
                                                            i_contact_det             => '',
                                                            i_county                  => 'Chile',
                                                            i_other_adress            => NULL,
                                                            i_commit_at_end           => TRUE,
                                                            i_parent_name             => NULL,
                                                            i_first_name_sa           => NULL,
                                                            i_parent_name_sa          => NULL,
                                                            i_middle_name_sa          => NULL,
                                                            i_last_name_sa            => NULL,
                                                            i_doc_ident_type          => NULL,
                                                            i_doc_ident_num           => NULL,
                                                            i_doc_ident_val           => NULL,
                                                            i_tin                     => NULL,
                                                            i_clinical_name           => NULL,
                                                            i_prof_spec_id            => table_number(),
                                                            i_prof_spec_ballot        => table_varchar(),
                                                            i_prof_spec_id_university => table_number(),
                                                            i_agrupacion_instit_id    => NULL,
                                                            o_id_prof                 => o_id_prof,
                                                            o_error                   => o_error);
        
            RESULT := pk_backoffice.set_prof_affiliations(i_id_language,
                                                          o_id_prof,
                                                          table_number(0, 0),
                                                          table_number(60, 61),
                                                          table_varchar(i_run, i_rut),
                                                          o_error);
        
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            raise_application_error(-20001, SQLERRM);
            pk_alert_exceptions.process_error(g_language,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
    END;

    FUNCTION get_speciality_id_content(i_speciality VARCHAR) RETURN VARCHAR IS
        l_speciality_content VARCHAR2(20);
    BEGIN
    
        IF (i_speciality = '0' OR i_speciality = '*****************')
        THEN
            l_speciality_content := '0';
        ELSE
        
            SELECT id_content
              INTO l_speciality_content
              FROM speciality
             WHERE id_speciality = to_number(i_speciality)
               AND flg_available = g_flg_available
               AND rownum = 1;
        END IF;
    
        RETURN l_speciality_content;
    
    END get_speciality_id_content;

    FUNCTION get_speciality_id(i_speciality VARCHAR) RETURN NUMBER IS
        l_speciality NUMBER;
    BEGIN
    
        SELECT id_speciality
          INTO l_speciality
          FROM speciality
         WHERE id_content = i_speciality
           AND flg_available = g_flg_available
           AND rownum = 1;
    
        RETURN l_speciality;
    
    END get_speciality_id;

    PROCEDURE associate_professional
    (
        i_prof                     professional.id_professional%TYPE,
        i_id_language              language.id_language%TYPE,
        i_id_institution           institution.id_institution%TYPE,
        i_id_number_in_institution prof_institution.num_mecan%TYPE,
        i_language                 language.id_language%TYPE,
        i_id_category              category.id_category%TYPE
    ) IS
    
        l_error        VARCHAR2(4000);
        l_prof_inst_pk prof_institution.id_prof_institution%TYPE := 0;
        l_prof_pref_pk prof_preferences.id_prof_preferences%TYPE := NULL;
    
        -- core tables new params
        l_soft_inst_pk    ab_soft_inst_user_info.id_ab_software_institution%TYPE := NULL;
        l_role_sw_inst_pk ab_soft_inst_user_info.id_ab_software_inst_role%TYPE := NULL;
        l_role_id         ab_soft_inst_user_info.id_ab_role%TYPE := NULL;
        l_comp_id         VARCHAR2(200) := '';
    
        l_list           pk_types.cursor_type;
        l_return         BOOLEAN;
        l_id_doc_types   table_number;
        l_desc_doc_types table_varchar;
    
    BEGIN
        g_func_name := 'associate_professional';
    
        SELECT nvl((SELECT pi.id_prof_institution
                     FROM prof_institution pi
                    WHERE pi.id_professional = i_prof
                      AND pi.id_institution = i_id_institution
                      AND pi.flg_state = 'A'
                      AND pi.dt_end_tstz IS NULL),
                   NULL)
          INTO l_prof_inst_pk
          FROM dual;
    
        --update bond and work fields
        pk_api_ab_tables.upd_ins_into_prof_institution(i_id_prof_institution => l_prof_inst_pk,
                                                       i_id_professional     => i_prof,
                                                       i_id_institution      => i_id_institution,
                                                       i_flg_state           => 'A',
                                                       i_num_mecan           => i_id_number_in_institution,
                                                       i_dt_begin_tstz       => SYSDATE,
                                                       i_flg_schedulable     => 'Y',
                                                       o_id_prof_institution => l_prof_inst_pk);
    
        g_error := 'INSERT INTO PROF_CAT';
        INSERT INTO prof_cat
            (id_prof_cat, id_professional, id_category, id_institution, id_category_sub)
        VALUES
            (seq_prof_cat.nextval, i_prof, i_id_category, i_id_institution, NULL);
    
        g_error := 'UPDATE OR INSERT PROF_PREFERENCES';
        SELECT nvl((SELECT pp.id_prof_preferences
                     FROM prof_preferences pp
                    WHERE pp.id_professional = i_prof
                      AND pp.id_software = 0
                      AND pp.id_institution = i_id_institution),
                   NULL)
          INTO l_prof_pref_pk
          FROM dual;
    
        SELECT nvl((SELECT si.id_software_institution
                     FROM software_institution si
                    WHERE si.id_software = 0
                      AND si.id_institution = i_id_institution),
                   NULL)
          INTO l_soft_inst_pk
          FROM dual;
    
        g_error := 'GET DEFAULT COMPONENT ID';
        pk_api_ab_tables.get_component_from_si(profissional(i_prof, i_id_institution, 0), l_comp_id);
        pk_api_ab_tables.upd_ins_into_ab_sw_ins_usr_inf(i_prof                       => profissional(i_prof,
                                                                                                     i_id_institution,
                                                                                                     0),
                                                        i_id_ab_soft_inst_user_info  => l_prof_pref_pk,
                                                        i_import_code                => NULL,
                                                        i_record_status              => 'A',
                                                        i_id_ab_software_institution => l_soft_inst_pk,
                                                        i_id_ab_software_inst_role   => l_role_sw_inst_pk,
                                                        i_id_ab_institution          => i_id_institution,
                                                        i_id_ab_software             => 0,
                                                        i_id_ab_user_info            => i_prof,
                                                        i_id_ab_role                 => l_role_id,
                                                        i_id_ab_component            => to_number(l_comp_id),
                                                        i_id_ab_language             => i_language,
                                                        i_flg_log                    => NULL,
                                                        i_id_department              => NULL,
                                                        i_dt_log_tstz                => NULL,
                                                        i_timeout                    => NULL,
                                                        i_first_screen               => NULL,
                                                        o_id_ab_soft_inst_user_info  => l_prof_pref_pk);
    
        pk_api_ab_tables.upd_ab_sw_ins_usr_inf_lang(i_id_ab_user_info => i_prof,
                                                    i_id_ab_inst      => i_id_institution,
                                                    i_id_ab_lang      => i_language);
    
        g_error := 'UPDATE ALERT_INTER PROFESSIONAL INFO FOR ID_PROFESSIONAL = ' || i_prof || 'IN ID_INSTITUTION = ' ||
                   i_id_institution;
    
        pk_alertlog.log_debug('PK_BACKOFFICE.set_professional ' || g_error);
        alert_inter.pk_ia_event_backoffice.prof_schedule_info_update(l_prof_inst_pk, i_id_institution);
    
        IF i_id_category = 20
        THEN
            IF NOT pk_api_backoffice.set_admin_template_list(i_lang             => i_id_language,
                                                             i_id_prof          => i_prof,
                                                             i_inst             => table_number(i_id_institution),
                                                             i_soft             => table_number(g_backoffice),
                                                             i_id_dep_clin_serv => NULL,
                                                             i_templ            => table_number(42),
                                                             i_commit_at_end    => TRUE,
                                                             o_error            => o_error)
            THEN
                l_error := 'PK_API_BACKOFFICE PROCESSING ERROR ' || o_error.log_id;
            END IF;
        
        END IF;
    
        l_return := pk_backoffice_api_ui.get_prof_doc_list(i_lang  => i_id_language,
                                                           i_prof  => profissional(0, i_id_institution, 26),
                                                           o_list  => l_list,
                                                           o_error => o_error);
    
        FETCH l_list BULK COLLECT
            INTO l_id_doc_types, l_desc_doc_types;
    
        INSERT INTO prof_doc
            (id_prof_doc,
             id_doc_type,
             id_professional,
             VALUE,
             id_institution,
             local_emited,
             dt_emited_tstz,
             dt_expire_tstz)
            WITH tmp AS
             (SELECT column_value AS display_id
                FROM TABLE(l_id_doc_types))
            SELECT seq_prof_doc.nextval id_prof_doc,
                   id_doc_type,
                   id_professional,
                   VALUE,
                   i_id_institution     AS id_institution,
                   local_emited,
                   dt_emited_tstz,
                   dt_expire_tstz
              FROM prof_doc pd
              JOIN tmp tmp
                ON tmp.display_id = pd.id_doc_type
             WHERE pd.id_institution IN (SELECT id_institution
                                           FROM prof_cat
                                          WHERE id_professional = i_prof
                                            AND id_category = i_id_category)
               AND pd.id_professional = i_prof
               AND pd.value IS NOT NULL
               AND rownum = 1
               AND NOT EXISTS (SELECT *
                      FROM prof_doc b
                     WHERE b.id_doc_type = pd.id_doc_type
                       AND b.id_professional = pd.id_professional
                       AND b.id_institution = i_id_institution);
    
        COMMIT;
    
    EXCEPTION
        WHEN dup_val_on_index THEN
            RETURN;
        WHEN OTHERS THEN
            raise_application_error(-20001, nvl(nvl(l_error, g_error), SQLERRM));
            pk_alert_exceptions.process_error(g_language,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
    END;

    PROCEDURE set_professionals_sa
    (
        i_action                   VARCHAR,
        i_id_language              language.id_language%TYPE,
        i_id_institution           institution.id_institution%TYPE,
        i_title                    professional.title%TYPE,
        i_first_name_arabic        professional.first_name_sa%TYPE,
        i_father_name_arabic       professional.parent_name_sa%TYPE,
        i_middle_name_arabic       professional.middle_name_sa%TYPE,
        i_last_name_arabic         professional.last_name_sa%TYPE,
        i_first_name               professional.first_name%TYPE,
        i_father_name              professional.parent_name%TYPE,
        i_middle_name              professional.middle_name%TYPE,
        i_last_name                professional.last_name%TYPE,
        i_display_name_over_photo  professional.nick_name%TYPE,
        i_initials                 professional.initials%TYPE,
        i_birth_date               VARCHAR2,
        i_gender                   professional.gender%TYPE,
        i_civil_status             professional.marital_status%TYPE,
        i_prof_category            category.id_category%TYPE,
        i_speciality               VARCHAR2,
        i_gmc                      professional.num_order%TYPE,
        i_surgical_category        category.id_category%TYPE,
        i_id_number_in_institution prof_institution.num_mecan%TYPE,
        i_language                 language.id_language%TYPE,
        i_adress                   professional.address%TYPE,
        i_city                     professional.city%TYPE,
        i_county                   professional.district%TYPE,
        i_postcode                 professional.zip_code%TYPE,
        i_country                  VARCHAR2,
        i_work_phone               professional.work_phone%TYPE,
        i_home_phone               professional.num_contact%TYPE,
        i_mobile_phone             professional.cell_phone%TYPE,
        i_fax                      professional.fax%TYPE,
        i_e_mail                   professional.email%TYPE,
        i_bleep_number             professional.bleep_number%TYPE,
        i_document_type            VARCHAR2,
        i_document_number          prof_doc.value%TYPE,
        i_document_expiration_date VARCHAR2,
        i_username                 VARCHAR2
    ) IS
    
        l_action                   VARCHAR(1);
        o_error                    t_error_out;
        o_id_prof                  NUMBER;
        RESULT                     BOOLEAN;
        l_country                  NUMBER;
        l_speciality               NUMBER;
        l_birth_date               VARCHAR2(14);
        l_document_expiration_date VARCHAR2(14);
        l_title                    VARCHAR2(13);
        l_work_phone               VARCHAR2(25);
        l_home_phone               VARCHAR2(25);
        l_fax                      VARCHAR2(25);
        l_mobile_phone             VARCHAR2(25);
        l_pass_hash                VARCHAR2(1000 CHAR);
        l_username                 VARCHAR2(100);
        l_login_exists_ab          NUMBER;
        l_login_exists_ru          NUMBER;
        l_error                    VARCHAR2(4000);
        l_nick_name                professional.nick_name%TYPE;
        l_speciality_temp          VARCHAR2(4000);
        l_country_temp             VARCHAR2(4000);
        l_e_mail                   professional.email%TYPE;
        l_document_type            NUMBER;
        l_document_type_upper      VARCHAR2(4000) := format_field_trim_all_upper(i_document_type);
        l_document_number_trimmed  VARCHAR2(4000) := format_field_trim_all_upper(i_document_number);
        l_num_order                VARCHAR2(4000);
        l_same_prof                NUMBER;
        l_gmc                      VARCHAR2(4000) := format_field_trim_upper_gmc(i_gmc);
        l_gender_duplicate         professional.gender%TYPE;
        l_speciality_duplicate     NUMBER;
        l_already_associated       NUMBER := 0;
    
    BEGIN
        g_func_name := 'set_professionals_sa';
    
        RESULT := validate_mandatory_fields(i_id_language        => i_id_language,
                                            i_id_institution     => i_id_institution,
                                            i_field_number       => table_number(i_prof_category, i_language),
                                            i_field_varchar      => table_varchar(i_first_name_arabic,
                                                                                  i_last_name_arabic,
                                                                                  i_first_name,
                                                                                  i_last_name,
                                                                                  i_gender,
                                                                                  i_document_type,
                                                                                  i_document_number,
                                                                                  i_e_mail,
                                                                                  i_birth_date,
                                                                                  i_mobile_phone),
                                            i_field_name_number  => table_varchar('PROF CATEGORY', 'LANGUAGE'),
                                            i_field_name_varchar => table_varchar('FIRST NAME ARABIC',
                                                                                  'LAST NAME ARABIC',
                                                                                  'FIRST NAME',
                                                                                  'LAST NAME',
                                                                                  'GENDER',
                                                                                  'DOCUMENT TYPE',
                                                                                  'DOCUMENT NUMBER',
                                                                                  'E-MAIL',
                                                                                  'BIRTH DATE',
                                                                                  'MOBILE PHONE'));
    
        IF i_prof_category = 1
        THEN
        
            RESULT := validate_mandatory_fields(i_id_language        => i_id_language,
                                                i_id_institution     => i_id_institution,
                                                i_field_number       => table_number(),
                                                i_field_varchar      => table_varchar(i_speciality, i_gmc),
                                                i_field_name_number  => table_varchar(),
                                                i_field_name_varchar => table_varchar('SPECIALITY', 'GMC'));
        
        END IF;
    
        /*IF (i_username IS NOT NULL)
        THEN
        
            l_username := format_field_trim_all_upper(i_username);
        
        ELSE
        
            IF (instr(format_field_trim_all_lower(i_e_mail), '@moh.gov.sa') > 0)
            THEN
            
                l_e_mail := format_field_trim_all_upper(i_e_mail);
            
                SELECT REPLACE(l_e_mail, '@MOH.GOV.SA')
                  INTO l_username
                  FROM dual;
            
            ELSE
            
                l_error := 'The e-mail does not contain the domain "@moh.gov.sa"! Please validate!';
                RAISE g_exception;
            
            END IF;
        
        END IF;*/
    
        SELECT CASE l_document_type_upper
                   WHEN 'PASSPORT' THEN
                    1034
                   WHEN 'NATIONAL ID' THEN
                    1035
                   WHEN 'IQAMA' THEN
                    10050
                   WHEN 'BORDER ID' THEN
                    10105
                   WHEN 'OTHER' THEN
                    2573
                   ELSE
                    0
               END
          INTO l_document_type
          FROM dual;
    
        IF l_document_type = 0
        THEN
        
            l_error := 'The document type is not valid! Please validate!';
            RAISE g_exception;
        
        END IF;
    
        IF l_document_type_upper IN ('NATIONAL ID', 'IQAMA', 'BORDER ID')
        THEN
        
            IF length(to_char(l_document_number_trimmed)) != 10
            THEN
            
                l_error := 'It must be a 10-digit number! Please validate!';
                RAISE g_exception;
            
            ELSIF (l_document_number_trimmed = '0000000000' OR l_document_number_trimmed = '1234567890' OR
                  l_document_number_trimmed = '1111111111' OR l_document_number_trimmed = '2222222222' OR
                  l_document_number_trimmed = '3333333333' OR l_document_number_trimmed = '4444444444' OR
                  l_document_number_trimmed = '5555555555' OR l_document_number_trimmed = '6666666666' OR
                  l_document_number_trimmed = '7777777777' OR l_document_number_trimmed = '8888888888' OR
                  l_document_number_trimmed = '9999999999')
            THEN
            
                l_error := 'Invalid number! Please validate!';
                RAISE g_exception;
            
            ELSIF (substr(l_document_number_trimmed, 1, 1) = 1 AND substr(l_document_number_trimmed, 2, 1) > 1)
            THEN
            
                l_error := 'Invalid number! Please validate!';
                RAISE g_exception;
            
            END IF;
        
        END IF;
    
        /*SELECT COUNT(1)
          INTO l_login_exists_ab
          FROM alert_core_data.ab_user_info
         WHERE upper(login) = l_username;
        
        SELECT COUNT(1)
          INTO l_login_exists_ru
          FROM alert_idp.reg_user
         WHERE upper(username) = l_username;*/
    
        /*IF (l_login_exists_ab != 0 OR l_login_exists_ru != 0)
        THEN
        
            SELECT id_ab_user_info
              INTO l_same_prof
              FROM alert_core_data.ab_user_info
             WHERE upper(login) = l_username;
        
            SELECT upper(num_order)
              INTO l_num_order
              FROM professional
             WHERE id_professional = l_same_prof;*/
    
        /*IF (l_gmc IS NOT NULL AND l_num_order IS NOT NULL AND l_num_order = l_gmc)
        THEN*/
    
        IF i_speciality IS NOT NULL
        THEN
        
            l_speciality_temp := format_field_trim(i_speciality);
        
            BEGIN
                SELECT id_speciality
                  INTO l_speciality
                  FROM speciality
                 WHERE id_content = l_speciality_temp
                   AND flg_available = g_flg_available;
            EXCEPTION
                WHEN no_data_found THEN
                    l_speciality := NULL;
            END;
        ELSE
            l_speciality := NULL;
        END IF;
    
        IF (l_gmc IS NOT NULL AND i_prof_category = 1)
        THEN
        
            BEGIN
            
                SELECT gender, id_speciality, id_professional
                  INTO l_gender_duplicate, l_speciality_duplicate, l_same_prof
                  FROM professional
                 WHERE num_order IS NOT NULL
                   AND format_field_trim_upper_gmc(num_order) = l_gmc;
            
                l_num_order := 1;
            
            EXCEPTION
                WHEN OTHERS THEN
                    l_num_order := 0;
            END;
        
            IF (l_num_order = 1 AND l_gender_duplicate = i_gender AND l_speciality_duplicate = l_speciality)
            THEN
            
                associate_professional(i_prof                     => l_same_prof,
                                       i_id_language              => i_id_language,
                                       i_id_institution           => i_id_institution,
                                       i_id_number_in_institution => i_id_number_in_institution,
                                       i_language                 => i_language,
                                       i_id_category              => i_prof_category);
            
                l_already_associated := 1;
            
            END IF;
        
        END IF;
    
        BEGIN
            SELECT val
              INTO l_title
              FROM sys_domain a
             WHERE a.code_domain = 'PROFESSIONAL.TITLE'
               AND id_language = i_id_language
               AND desc_val = i_title;
        EXCEPTION
            WHEN no_data_found THEN
                l_title := i_title;
        END;
    
        IF i_country IS NOT NULL
        THEN
        
            l_country_temp := format_field_trim(i_country);
        
            BEGIN
                SELECT id_country
                  INTO l_country
                  FROM country
                 WHERE id_content = l_country_temp
                   AND flg_available = g_flg_available;
            EXCEPTION
                WHEN no_data_found THEN
                    l_country := NULL;
            END;
        ELSE
            l_country := NULL;
        END IF;
    
        IF i_work_phone IS NOT NULL
        THEN
            IF substr(i_work_phone, 1, 4) != '+966'
               AND substr(i_work_phone, 1, 3) != '966'
            THEN
                l_work_phone := '+966' || i_work_phone;
            
            ELSIF substr(i_work_phone, 1, 3) = '966'
            THEN
                l_work_phone := '+' || i_work_phone;
            END IF;
        END IF;
    
        IF i_home_phone IS NOT NULL
        THEN
            IF substr(i_home_phone, 1, 4) != '+966'
               AND substr(i_home_phone, 1, 3) != '966'
            THEN
                l_home_phone := '+966' || i_home_phone;
            
            ELSIF substr(i_home_phone, 1, 3) = '966'
            THEN
                l_home_phone := '+' || i_home_phone;
            END IF;
        END IF;
    
        IF i_fax IS NOT NULL
        THEN
            IF substr(i_fax, 1, 4) != '+966'
               AND substr(i_fax, 1, 3) != '966'
            THEN
                l_fax := '+966' || i_fax;
            
            ELSIF substr(i_fax, 1, 3) = '966'
            THEN
                l_fax := '+' || i_fax;
            END IF;
        END IF;
    
        IF i_mobile_phone IS NOT NULL
        THEN
            IF substr(i_mobile_phone, 1, 4) != '+966'
               AND substr(i_mobile_phone, 1, 3) != '966'
            THEN
                l_mobile_phone := '+966' || i_mobile_phone;
            
            ELSIF substr(i_mobile_phone, 1, 3) = '966'
            THEN
                l_mobile_phone := '+' || i_mobile_phone;
            END IF;
        END IF;
    
        IF i_birth_date IS NOT NULL
        THEN
            SELECT REPLACE(i_birth_date, '-') || '000000'
              INTO l_birth_date
              FROM dual;
        ELSE
            l_birth_date := NULL;
        END IF;
    
        IF i_document_expiration_date IS NOT NULL
        THEN
            SELECT REPLACE(i_document_expiration_date, '-') || '000000'
              INTO l_document_expiration_date
              FROM dual;
        ELSE
            l_document_expiration_date := NULL;
        END IF;
    
        IF i_display_name_over_photo IS NULL
        THEN
            l_nick_name := format_field_trim_first_upper(i_first_name) || ' ' ||
                           format_field_trim_first_upper(i_last_name);
        ELSE
            l_nick_name := i_display_name_over_photo;
        END IF;
    
        IF ((i_action = g_flg_create OR i_action = g_flg_update) AND l_already_associated = 0)
        THEN
        
            RESULT := pk_backoffice_api_ui.set_professional(i_lang                    => i_id_language,
                                                            i_id_institution          => i_id_institution,
                                                            i_id_prof                 => NULL,
                                                            i_title                   => l_title,
                                                            i_first_name              => format_field_trim_first_upper(i_first_name),
                                                            i_middle_name             => format_field_trim_first_upper(i_middle_name),
                                                            i_last_name               => format_field_trim_first_upper(i_last_name),
                                                            i_nick_name               => l_nick_name,
                                                            i_initials                => format_field_trim_all_upper(i_initials),
                                                            i_dt_birth                => l_birth_date,
                                                            i_gender                  => format_field_trim_all_upper(i_gender),
                                                            i_marital_status          => format_field_trim_all_upper(i_civil_status),
                                                            i_id_category             => i_prof_category,
                                                            i_id_speciality           => l_speciality,
                                                            i_num_order               => l_gmc,
                                                            i_upin                    => NULL,
                                                            i_dea                     => NULL,
                                                            i_id_cat_surgery          => format_field_trim(i_surgical_category),
                                                            i_num_mecan               => format_field_trim(i_id_number_in_institution),
                                                            i_id_lang                 => format_field_trim(i_language),
                                                            i_flg_state               => 'A',
                                                            i_address                 => format_field_trim(i_adress),
                                                            i_city                    => format_field_trim(i_city),
                                                            i_district                => format_field_trim(i_county),
                                                            i_zip_code                => format_field_trim(i_postcode),
                                                            i_id_country              => l_country,
                                                            i_work_phone              => l_work_phone,
                                                            i_num_contact             => l_home_phone,
                                                            i_cell_phone              => l_mobile_phone,
                                                            i_fax                     => l_fax,
                                                            i_email                   => format_field_trim_all_lower(i_e_mail),
                                                            i_adress_type             => NULL,
                                                            i_id_scholarship          => NULL,
                                                            i_agrupacion              => NULL,
                                                            i_id_road                 => NULL,
                                                            i_entity                  => NULL,
                                                            i_jurisdiction            => NULL,
                                                            i_municip                 => NULL,
                                                            i_localidad               => NULL,
                                                            i_id_postal_code_rb       => NULL,
                                                            i_bleep_num               => format_field_trim(i_bleep_number),
                                                            i_suffix                  => NULL,
                                                            i_contact_det             => '',
                                                            i_county                  => 'Saudi Arabia',
                                                            i_other_adress            => NULL,
                                                            i_commit_at_end           => FALSE,
                                                            i_parent_name             => format_field_trim_first_upper(i_father_name),
                                                            i_first_name_sa           => format_field_trim(i_first_name_arabic),
                                                            i_parent_name_sa          => format_field_trim(i_father_name_arabic),
                                                            i_middle_name_sa          => format_field_trim(i_middle_name_arabic),
                                                            i_last_name_sa            => format_field_trim(i_last_name_arabic),
                                                            i_doc_ident_type          => l_document_type,
                                                            i_doc_ident_num           => l_document_number_trimmed,
                                                            i_doc_ident_val           => l_document_expiration_date,
                                                            i_tin                     => NULL,
                                                            i_clinical_name           => NULL,
                                                            i_prof_spec_id            => table_number(),
                                                            i_prof_spec_ballot        => table_varchar(),
                                                            i_prof_spec_id_university => table_number(),
                                                            i_agrupacion_instit_id    => NULL,
                                                            o_id_prof                 => o_id_prof,
                                                            o_error                   => o_error);
        
            IF o_id_prof IS NOT NULL
            THEN
            
                /*                l_pass_hash := generate_pass_hash(l_username);
                
                insert_credential_reg_user(l_pass_hash, o_id_prof, l_username);*/
            
                IF i_prof_category = 20
                THEN
                    IF NOT pk_api_backoffice.set_admin_template_list(i_lang             => i_id_language,
                                                                     i_id_prof          => o_id_prof,
                                                                     i_inst             => table_number(i_id_institution),
                                                                     i_soft             => table_number(g_backoffice),
                                                                     i_id_dep_clin_serv => NULL,
                                                                     i_templ            => table_number(42),
                                                                     i_commit_at_end    => TRUE,
                                                                     o_error            => o_error)
                    THEN
                        l_error := 'PK_API_BACKOFFICE PROCESSING ERROR ' || o_error.log_id;
                    END IF;
                END IF;
            
            END IF;
        
            COMMIT;
        
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            raise_application_error(-20001, nvl(l_error, SQLERRM));
            pk_alert_exceptions.process_error(g_language,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
    END;

    FUNCTION generate_pass_hash(i_username VARCHAR) RETURN VARCHAR IS
        l_hash_value_sh1  RAW(100);
        l_varchar_key_sh1 VARCHAR2(1000 CHAR);
    BEGIN
    
        l_hash_value_sh1 := dbms_crypto.hash(src => utl_raw.cast_to_raw(i_username), typ => dbms_crypto.hash_sh1);
    
        -- convert into varchar2
        SELECT '{SHA}' || upper(to_char(rawtohex(l_hash_value_sh1)))
          INTO l_varchar_key_sh1
          FROM dual;
    
        RETURN l_varchar_key_sh1;
    
    END generate_pass_hash;

    PROCEDURE insert_credential_reg_user
    (
        i_pass_hash VARCHAR,
        i_id_prof   NUMBER,
        i_username  VARCHAR
        
    ) IS
    
        l_reg_user       NUMBER;
        l_full_name      VARCHAR2(200);
        l_first_name     VARCHAR2(200);
        l_cnt_reg_user   NUMBER;
        l_cnt_credential NUMBER;
        l_error          VARCHAR2(4000);
    
    BEGIN
    
        g_func_name := 'insert_credential_reg_user';
    
        SELECT a.full_name, a.first_name
          INTO l_full_name, l_first_name
          FROM ab_user_info a
         WHERE a.id_ab_user_info = i_id_prof;
    
        SELECT alert_idp.seq_reg_user.nextval
          INTO l_reg_user
          FROM dual;
    
        INSERT INTO reg_user
            (id_reg_user,
             id_role,
             name,
             email,
             secret_question,
             secret_answer,
             username,
             password,
             flg_status,
             user_first_name,
             user_middle_name,
             id_lang)
        VALUES
            (l_reg_user,
             1,
             l_full_name,
             NULL,
             'deprecated',
             'deprecated',
             lower(i_username),
             'deprecated',
             'A',
             l_first_name,
             NULL,
             2);
    
        INSERT INTO credential
            (id_credential,
             id_reg_user,
             flg_type,
             flg_status,
             passwd,
             serial_number,
             ca_issuer,
             certificate_base64,
             id_biometric_characteristic,
             id_biometric_format,
             biometric_template,
             expiration_date)
        VALUES
            (alert_idp.seq_credential.nextval,
             l_reg_user,
             'P',
             'T',
             i_pass_hash,
             NULL,
             NULL,
             NULL,
             NULL,
             NULL,
             NULL,
             NULL);
    
        UPDATE ab_user_info
           SET login = upper(i_username)
         WHERE id_ab_user_info = i_id_prof;
    
        SELECT COUNT(*)
          INTO l_cnt_reg_user
          FROM alert_idp.reg_user
         WHERE username = lower(i_username);
    
        SELECT COUNT(*)
          INTO l_cnt_credential
          FROM alert_idp.credential
         WHERE id_reg_user IN (SELECT id_reg_user
                                 FROM alert_idp.reg_user
                                WHERE username = lower(i_username));
    
        IF (l_cnt_reg_user = 0 OR l_cnt_credential = 0)
        THEN
            l_error := 'It was not possible to create the USERNAME and PASSWORD records! Please validate!';
            RAISE g_exception;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            raise_application_error(-20001, nvl(l_error, SQLERRM));
            pk_alert_exceptions.process_error(g_language,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
    END;

    PROCEDURE set_sr_procedure_freq
    (
        i_action              VARCHAR,
        i_id_cnt_sr_procedure VARCHAR,
        i_id_institution      NUMBER,
        i_id_software         NUMBER,
        i_id_dep_clin_serv    NUMBER
        
    ) IS
    
    BEGIN
        g_func_name := 'set_sr_procedure_freq';
    
        set_procedure_freq_core(i_action           => i_action,
                                i_id_cnt_procedure => i_id_cnt_sr_procedure,
                                i_id_institution   => i_id_institution,
                                i_id_software      => i_id_software,
                                i_id_dep_clin_serv => i_id_dep_clin_serv);
    
    EXCEPTION
        WHEN OTHERS THEN
            raise_application_error(-20001, SQLERRM);
            pk_alert_exceptions.process_error(g_language,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
    END;

    PROCEDURE set_procedure_freq
    (
        i_action           VARCHAR,
        i_id_cnt_procedure VARCHAR,
        i_id_institution   NUMBER,
        i_id_software      NUMBER,
        i_id_dep_clin_serv NUMBER
    ) IS
    
    BEGIN
        g_func_name := 'set_procedure_freq';
    
        set_procedure_freq_core(i_action           => i_action,
                                i_id_cnt_procedure => i_id_cnt_procedure,
                                i_id_institution   => i_id_institution,
                                i_id_software      => i_id_software,
                                i_id_dep_clin_serv => i_id_dep_clin_serv);
    EXCEPTION
        WHEN OTHERS THEN
            raise_application_error(-20001, SQLERRM);
            pk_alert_exceptions.process_error(g_language,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
    END;

    PROCEDURE set_map
    (
        action              VARCHAR,
        alert_system        VARCHAR,
        alert_definition    VARCHAR,
        alert_value         VARCHAR,
        external_system     VARCHAR,
        external_definition VARCHAR,
        external_value      VARCHAR,
        id_institution      VARCHAR,
        id_software         VARCHAR
    ) IS
    
        l_b_value_delete VARCHAR2(2000);
        l_error          VARCHAR2(3000);
        l_ret            BOOLEAN;
    BEGIN
        g_func_name := 'set_map';
        IF action = g_flg_delete
        THEN
            BEGIN
            
                FOR i IN (SELECT DISTINCT b_value
                            FROM inter_map.v_mapping a
                           WHERE a.a_system = alert_system
                             AND a.a_def = alert_definition
                             AND a.a_value = alert_value
                             AND a.b_system = external_system
                             AND a.b_def = external_definition
                             AND a.id_institution = id_institution
                             AND a.id_software = id_software)
                LOOP
                
                    l_ret := inter_map.pk_map.delete_map(i_a_system       => alert_system,
                                                         i_a_definition   => alert_definition,
                                                         i_a_value        => alert_value,
                                                         i_b_system       => external_system,
                                                         i_b_definition   => external_definition,
                                                         i_b_value        => i.b_value,
                                                         i_id_institution => id_institution,
                                                         i_id_software    => id_software,
                                                         o_error          => l_error);
                END LOOP;
            
            EXCEPTION
                WHEN no_data_found THEN
                    NULL;
                WHEN too_many_rows THEN
                    raise_application_error(-20001, SQLERRM);
            END;
        
        ELSIF action IN (g_flg_create, g_flg_update)
        THEN
        
            BEGIN
                FOR i IN (SELECT DISTINCT b_value
                            FROM inter_map.v_mapping a
                           WHERE a.a_system = alert_system
                             AND a.a_def = alert_definition
                             AND a.a_value = alert_value
                             AND a.b_system = external_system
                             AND a.b_def = external_definition
                             AND a.id_institution = id_institution
                             AND a.id_software = id_software)
                LOOP
                
                    l_ret := inter_map.pk_map.delete_map(i_a_system       => alert_system,
                                                         i_a_definition   => alert_definition,
                                                         i_a_value        => alert_value,
                                                         i_b_system       => external_system,
                                                         i_b_definition   => external_definition,
                                                         i_b_value        => i.b_value,
                                                         i_id_institution => id_institution,
                                                         i_id_software    => id_software,
                                                         o_error          => l_error);
                END LOOP;
            
            EXCEPTION
                WHEN no_data_found THEN
                    NULL;
                WHEN too_many_rows THEN
                    raise_application_error(-20001, SQLERRM);
            END;
        
            l_ret := inter_map.pk_map.set_map(i_a_system       => alert_system,
                                              i_a_definition   => alert_definition,
                                              i_a_value        => alert_value,
                                              i_b_system       => external_system,
                                              i_b_definition   => external_definition,
                                              i_b_value        => external_value,
                                              i_id_institution => id_institution,
                                              i_id_software    => id_software,
                                              o_error          => l_error);
        
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            raise_application_error(-20001, SQLERRM);
            pk_alert_exceptions.process_error(g_language,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
    END;

    PROCEDURE set_other_exam_room
    (
        i_action            VARCHAR,
        i_id_institution    NUMBER,
        i_id_language       VARCHAR,
        i_id_cnt_other_exam VARCHAR,
        i_id_room           VARCHAR,
        i_rank              NUMBER,
        i_flg_default       VARCHAR,
        i_id_record         NUMBER
    ) IS
        l_id_exam NUMBER;
        l_bool    BOOLEAN;
        l_ids     table_number;
        l_status  table_varchar;
    
    BEGIN
    
        g_func_name := 'set_other_exam_room';
    
        l_bool := validate_content(i_id_language,
                                   i_id_institution,
                                   table_varchar(i_id_cnt_other_exam, i_id_room),
                                   table_varchar('OTHER_EXAM', 'ROOM'),
                                   table_number(1, 1),
                                   l_ids,
                                   l_status);
    
        l_id_exam := l_ids(1);
    
        IF i_action = g_flg_create
        THEN
        
            INSERT INTO exam_room
                (id_exam_room,
                 id_exam,
                 id_room,
                 rank,
                 adw_last_update,
                 flg_available,
                 flg_default,
                 id_exam_dep_clin_serv)
            VALUES
                (seq_exam_room.nextval, l_id_exam, i_id_room, i_rank, SYSDATE, g_flg_available, i_flg_default, NULL);
        
            g_error := 'ALERT_INTER.exam_room_new FOR ID_EXAM = ' || l_id_exam || 'IN ID_ROOM = ' || i_id_room;
            alert_inter.pk_ia_event_backoffice.exam_room_new(i_id_exam_room   => seq_exam_room.currval,
                                                             i_id_institution => i_id_institution);
        
        ELSIF i_action = g_flg_update
        THEN
            UPDATE exam_room
               SET flg_default = i_flg_default, rank = i_rank, id_room = i_id_room
             WHERE id_exam = l_id_exam
               AND flg_available = g_flg_available
               AND id_exam_room = i_id_record;
        
            alert_inter.pk_ia_event_backoffice.exam_room_update(i_id_exam_room   => i_id_record,
                                                                i_id_institution => i_id_institution);
        
        ELSIF i_action = g_flg_delete
        THEN
        
            g_error := 'ALERT_INTER.exam_room_delete FOR ID_EXAM = ' || l_id_exam || 'IN ID_ROOM = ' || i_id_room;
            alert_inter.pk_ia_event_backoffice.exam_room_delete(i_id_exam_room   => i_id_record,
                                                                i_id_institution => i_id_institution,
                                                                id_exam          => l_id_exam,
                                                                id_room          => i_id_room);
        
            DELETE FROM exam_room a
             WHERE id_room = i_id_room
               AND id_exam = l_id_exam
               AND flg_available = g_flg_available
               AND id_exam_room = i_id_record;
        
        ELSIF i_action = g_flg_update_create
        THEN
        
            FOR i IN (SELECT a.id_exam, a.id_room, a.id_exam_room
                        FROM exam_room a
                        JOIN room b
                          ON a.id_room = b.id_room
                        JOIN department c
                          ON b.id_department = c.id_department
                         AND c.id_institution = i_id_institution
                       WHERE a.id_exam = l_id_exam
                         AND a.flg_default = g_flg_available
                         AND a.id_exam_dep_clin_serv IS NULL)
            LOOP
            
                g_error := 'ALERT_INTER.exam_room_delete FOR ID_EXAM = ' || i.id_exam || 'IN ID_ROOM = ' || i.id_room;
                alert_inter.pk_ia_event_backoffice.exam_room_delete(i_id_exam_room   => i.id_exam_room,
                                                                    i_id_institution => i_id_institution,
                                                                    id_exam          => i.id_exam,
                                                                    id_room          => i.id_room);
            
                DELETE FROM exam_room a
                 WHERE id_exam_room = i.id_exam_room;
            
            END LOOP;
        
            INSERT INTO exam_room
                (id_exam_room,
                 id_exam,
                 id_room,
                 rank,
                 adw_last_update,
                 flg_available,
                 flg_default,
                 id_exam_dep_clin_serv)
            VALUES
                (seq_exam_room.nextval, l_id_exam, i_id_room, i_rank, SYSDATE, g_flg_available, i_flg_default, NULL);
        
            g_error := 'ALERT_INTER.exam_room_new FOR ID_EXAM = ' || l_id_exam || 'IN ID_ROOM = ' || i_id_room;
            pk_alertlog.log_debug('PK_BACKOFFICE.set_inst_exam_new ' || g_error);
            alert_inter.pk_ia_event_backoffice.exam_room_new(i_id_exam_room   => seq_exam_room.currval,
                                                             i_id_institution => i_id_institution);
        
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            raise_application_error(-20001, SQLERRM);
            pk_alert_exceptions.process_error(i_id_language,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
        
    END set_other_exam_room;

    PROCEDURE set_complaint_freq
    (
        i_action                 VARCHAR,
        i_id_language            VARCHAR,
        i_id_institution         NUMBER,
        i_id_software            NUMBER,
        i_id_cnt_complaint       VARCHAR,
        i_id_cnt_complaint_alias VARCHAR,
        i_rank                   NUMBER DEFAULT 10,
        i_id_dep_clin_serv       VARCHAR
    ) IS
    
        l_dep_clin_serv      NUMBER;
        l_error              VARCHAR2(4000);
        l_bool               BOOLEAN;
        l_ids                table_number;
        l_status             table_varchar;
        l_id_complaint       NUMBER;
        l_id_complaint_alias NUMBER;
        l_complaint          NUMBER;
    
    BEGIN
        g_func_name := 'set_complaint_freq';
    
        BEGIN
            l_bool := validate_content(i_id_language,
                                       NULL,
                                       table_varchar(i_id_cnt_complaint),
                                       table_varchar('COMPLAINT'),
                                       table_number(1),
                                       l_ids,
                                       l_status);
        
            l_id_complaint := l_ids(1);
        END;
    
        IF i_id_cnt_complaint_alias IS NOT NULL
        THEN
        
            SELECT *
              INTO l_id_complaint_alias
              FROM (SELECT a.id_complaint_alias
                      FROM complaint_alias a
                     WHERE a.id_content = i_id_cnt_complaint_alias)
             WHERE rownum = 1;
        
        END IF;
    
        BEGIN
        
            SELECT id_complaint
              INTO l_complaint
              FROM complaint_inst_soft
             WHERE flg_available = g_flg_available
               AND id_complaint = l_id_complaint
               AND id_software = i_id_software
               AND id_institution = i_id_institution
               AND rownum = 1;
        
        EXCEPTION
            WHEN no_data_found THEN
                l_error := 'The complaint ' || l_id_complaint || ' is not available for your institution (' ||
                           i_id_institution || ') and/or software (' || i_id_software || '). Please validate.';
                RAISE g_exception;
        END;
    
        IF i_action = g_flg_create
        THEN
        
            INSERT /*+ ignore_row_on_dupkey_index(cdcs CDCS_UK) */
            INTO complaint_dep_clin_serv cdcs
                (id_complaint, id_complaint_alias, id_dep_clin_serv, rank, id_software, flg_available)
            VALUES
                (l_id_complaint,
                 l_id_complaint_alias,
                 to_number(i_id_dep_clin_serv),
                 i_rank,
                 i_id_software,
                 g_flg_available);
        
        ELSIF i_action = g_flg_update
        THEN
            UPDATE complaint_dep_clin_serv
               SET rank = i_rank, flg_available = g_flg_available
             WHERE id_complaint = l_id_complaint
               AND id_dep_clin_serv = to_number(i_id_dep_clin_serv)
               AND ((id_complaint_alias IS NULL AND i_id_cnt_complaint_alias IS NULL) OR
                   (id_complaint_alias = l_id_complaint_alias AND i_id_cnt_complaint_alias IS NOT NULL));
        
        ELSIF i_action = g_flg_delete
        THEN
            DELETE complaint_dep_clin_serv
             WHERE id_complaint = l_id_complaint
               AND id_dep_clin_serv = to_number(i_id_dep_clin_serv)
               AND ((id_complaint_alias IS NULL AND i_id_cnt_complaint_alias IS NULL) OR
                   (id_complaint_alias = l_id_complaint_alias AND i_id_cnt_complaint_alias IS NOT NULL));
        
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            raise_application_error(-20001, nvl(l_error, SQLERRM));
            pk_alert_exceptions.process_error(i_id_language,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
    END;

END pk_cmt_content_core;
/
