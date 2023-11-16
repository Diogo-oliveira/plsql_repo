/*-- Last Change Revision: $Rev: 2027563 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:42:36 +0100 (ter, 02 ago 2022) $*/
CREATE OR REPLACE PACKAGE BODY pk_recommendation AS

    ---------------------------------- PRIVATE CONSTANTS ------------------------------
    g_flg_read    CONSTANT VARCHAR2(1) := 'Y';
    g_flg_unread  CONSTANT VARCHAR2(1) := 'N';
    g_flg_success CONSTANT VARCHAR2(1) := 'Y';
    g_flg_fail    CONSTANT VARCHAR2(1) := 'N';
    g_code_domain CONSTANT VARCHAR2(35) := 'PAT_RECOMMENDATION_DET.FLG_READ';

    /********************************************************************************************
    * Inserts a new patient recommendation
    *
    * @param i_lang                  Language id
    * @param i_prof                  Professional id
    * @param i_id_patient            Patient id
    * @param i_id_episode            Episode id
    * @param i_id_recommendation     Recommendation id array
    * @param i_id_cdr_instance       CDR instance id
    * @param o_id_pat_rec            Patient Recommendations
    * @param o_error                 Error
    *
    * @return                        true or false on success or error
    *
    * @author                        Álvaro Vasconcelos
    * @version                       2.6.1.0.1
    * @since                         2011/05/04
    ********************************************************************************************/
    FUNCTION set_pat_recommendation
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_patient        IN alert_adtcod.patient.id_patient%TYPE,
        i_id_episode        IN episode.id_episode%TYPE,
        i_id_recommendation IN table_number,
        i_id_cdr_instance   IN cdr_instance.id_cdr_instance%TYPE,
        o_id_pat_rec        OUT table_number,
        o_error             OUT t_error_out
    ) RETURN VARCHAR2 IS
        l_op_timestamp   TIMESTAMP(6) WITH LOCAL TIME ZONE := current_timestamp;
        l_id_pat_rec     pat_recommendation.id_pat_recommendation%TYPE;
        l_ids_pat_rec    table_number := table_number();
        l_id_pat_rec_det pat_recommendation_det.id_pat_recommendation_det%TYPE;
        l_alert_msg      sys_message.desc_message%TYPE;
    BEGIN
        g_error := 'SET PAT RECOMMENDATION';
        FOR i IN i_id_recommendation.first .. i_id_recommendation.last
        LOOP
            BEGIN
                SELECT pr.id_pat_recommendation
                  INTO l_id_pat_rec
                  FROM pat_recommendation pr
                 WHERE pr.id_recommendation = i_id_recommendation(i)
                   AND pr.id_patient = i_id_patient;
            EXCEPTION
                WHEN no_data_found THEN
                    l_id_pat_rec := seq_pat_recommendation.nextval;
                    INSERT INTO pat_recommendation
                        (id_pat_recommendation, id_recommendation, id_patient)
                    VALUES
                        (l_id_pat_rec, i_id_recommendation(i), i_id_patient);
            END;
        
            l_ids_pat_rec.extend;
            l_ids_pat_rec(i) := l_id_pat_rec;
            l_id_pat_rec_det := seq_pat_recommendation_det.nextval;
        
            g_error := 'INSERT PAT_RECOMMENDATION_DET';
            INSERT INTO pat_recommendation_det prd
                (prd.id_pat_recommendation_det,
                 prd.id_pat_recommendation,
                 prd.id_cdr_instance,
                 prd.dt_recommendation,
                 prd.flg_read,
                 prd.dt_update)
            VALUES
                (l_id_pat_rec_det, l_id_pat_rec, i_id_cdr_instance, l_op_timestamp, g_flg_unread, l_op_timestamp);
        
        END LOOP;
    
        g_error     := 'CREATING SYS_ALERT DATA';
        l_alert_msg := pk_message.get_message(i_lang, 'RECOMMENDATION_M001');
    
        IF NOT pk_alerts.insert_sys_alert_event(i_lang,
                                                i_prof,
                                                108,
                                                i_id_episode,
                                                i_id_patient,
                                                current_timestamp,
                                                NULL,
                                                NULL,
                                                NULL,
                                                NULL,
                                                l_alert_msg,
                                                NULL,
                                                NULL,
                                                o_error)
        THEN
            RETURN g_flg_fail;
        END IF;
    
        g_error      := 'Assigning o_id_pat_rec';
        o_id_pat_rec := l_ids_pat_rec;
    
        COMMIT;
        RETURN g_flg_success;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_PAT_RECOMMENDATION',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN g_flg_fail;
    END set_pat_recommendation;

    /********************************************************************************************
    * Gets patient recommendations
    *
    * @param i_lang                  Language id
    * @param i_prof                  Professional id
    * @param i_id_patient            Patient id
    * @param o_list                  Recommendations cursor
    * @param o_error                 Error
    *
    * @return                        true or false on success or error
    *
    * @author                        Álvaro Vasconcelos
    * @version                       2.6.1.0.1
    * @since                         2011/05/04
    ********************************************************************************************/
    FUNCTION get_pat_recommendation
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN alert_adtcod.patient.id_patient%TYPE,
        o_list       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'GET PAT RECOMMENDATION';
        OPEN o_list FOR
            SELECT r.id_recommendation,
                   pk_translation.get_translation(i_lang, r.code_recommendation_summ) recommendation_summ,
                   pk_translation.get_translation(i_lang, r.code_recommendation_desc) recommendation_desc,
                   (SELECT pk_date_utils.date_time_chr_tsz(i_lang, MAX(prd.dt_recommendation), i_prof)
                      FROM pat_recommendation_det prd
                     WHERE prd.id_pat_recommendation = pr.id_pat_recommendation) dt_recommendation,
                   nvl((SELECT g_flg_unread
                         FROM pat_recommendation_det prd
                        WHERE prd.id_pat_recommendation = pr.id_pat_recommendation
                          AND prd.flg_read = g_flg_unread
                          AND rownum = 1),
                       g_flg_read) flg_read,
                   decode((SELECT g_flg_unread
                            FROM pat_recommendation_det prd
                           WHERE prd.id_pat_recommendation = pr.id_pat_recommendation
                             AND prd.flg_read = g_flg_unread
                             AND rownum = 1),
                          g_flg_unread,
                          NULL,
                          (SELECT pk_date_utils.dt_chr_year_short_tsz(i_lang,
                                                                      MAX(prd.dt_read),
                                                                      i_prof.institution,
                                                                      i_prof.software)
                             FROM pat_recommendation_det prd
                            WHERE prd.id_pat_recommendation = pr.id_pat_recommendation)) dt_read,
                   (SELECT sd.img_name
                      FROM sys_domain sd
                     WHERE sd.code_domain = g_code_domain
                       AND sd.domain_owner = pk_sysdomain.k_default_schema
                       AND sd.val = nvl((SELECT g_flg_unread
                                          FROM pat_recommendation_det prd
                                         WHERE prd.id_pat_recommendation = pr.id_pat_recommendation
                                           AND prd.flg_read = g_flg_unread
                                           AND rownum = 1),
                                        g_flg_read)
                       AND sd.id_language = i_lang) icon_name
              FROM recommendation r
              JOIN pat_recommendation pr
                ON pr.id_recommendation = r.id_recommendation
             WHERE pr.id_patient = i_id_patient
             ORDER BY flg_read, dt_recommendation DESC;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PAT_RECOMMENDATION',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_pat_recommendation;

    /********************************************************************************************
    * Gets patient recommendations conditions
    *
    * @param i_lang                  Language id
    * @param i_prof                  Professional id
    * @param i_id_patient            Patient id
    * @param o_conditions            Recommendations conditions
    * @param o_error                 Error
    *
    * @return                        true or false on success or error
    *
    * @author                        Álvaro Vasconcelos
    * @version                       2.6.1.0.1
    * @since                         2011/05/04
    ********************************************************************************************/
    FUNCTION get_pat_recommendation_cond
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_patient     IN alert_adtcod.patient.id_patient%TYPE,
        i_recommendation IN recommendation.id_recommendation%TYPE,
        o_conditions     OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_cdr_insts table_number := table_number();
    BEGIN
        g_error := 'GETTING CDR_INSTANCES';
        SELECT prd.id_cdr_instance BULK COLLECT
          INTO l_cdr_insts
          FROM pat_recommendation_det prd
         WHERE prd.id_pat_recommendation IN (SELECT pr.id_pat_recommendation
                                               FROM pat_recommendation pr
                                              WHERE pr.id_recommendation = i_recommendation
                                                AND pr.id_patient = i_id_patient);
    
        g_error := 'INVOKING PK_CDR_FO_CORE.GET_INST_ELEMS';
        IF NOT pk_cdr_fo_core.get_inst_elems(i_lang, i_prof, l_cdr_insts, o_conditions, o_error)
        THEN
            RETURN FALSE;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PAT_RECOMMENDATION_COND',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_pat_recommendation_cond;

    /********************************************************************************************
    * Gets patient recommendations
    *
    * @param i_lang                  Language id
    * @param i_prof                  Professional id
    * @param i_id_patient            Patient id
    * @param i_id_episode            Episode id
    * @param i_id_recommendation     Recommendation id
    * @param o_list                  Recommendations cursor
    * @param o_error                 Error
    *
    * @return                        true or false on success or error
    *
    * @author                        Álvaro Vasconcelos
    * @version                       2.6.1.0.1
    * @since                         2011/05/04
    ********************************************************************************************/
    FUNCTION set_pat_recommendation_read
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_patient        IN alert_adtcod.patient.id_patient%TYPE,
        i_id_episode        IN episode.id_episode%TYPE,
        i_id_recommendation IN recommendation.id_recommendation%TYPE,
        i_flg_read          IN pat_recommendation_det.flg_read%TYPE,
        o_icon_name         OUT sys_domain.img_name%TYPE,
        o_dt_read           OUT VARCHAR2,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id_pat_rec    pat_recommendation_det.id_pat_recommendation_det%TYPE;
        l_op_timestamp  TIMESTAMP(6) WITH LOCAL TIME ZONE := current_timestamp;
        l_id_unread_rec recommendation.id_recommendation%TYPE;
        l_alert_msg     sys_message.desc_message%TYPE;
    BEGIN
        g_error := 'GETTING PATIENT RECOMMENDATION';
        SELECT pr.id_pat_recommendation
          INTO l_id_pat_rec
          FROM pat_recommendation pr
         WHERE pr.id_recommendation = i_id_recommendation
           AND pr.id_patient = i_id_patient;
    
        IF i_flg_read = g_flg_read
        THEN
            g_error := 'SETTING REC READED';
            INSERT INTO pat_recommendation_hist
                (id_pat_recommendation_hist,
                 id_pat_recommendation_det,
                 id_pat_recommendation,
                 id_cdr_instance,
                 dt_recommendation,
                 flg_read,
                 id_professional,
                 dt_read,
                 dt_update)
                (SELECT seq_pat_recommendation_hist.nextval,
                        prd.id_pat_recommendation_det,
                        prd.id_pat_recommendation,
                        prd.id_cdr_instance,
                        prd.dt_recommendation,
                        prd.flg_read,
                        prd.id_professional,
                        prd.dt_read,
                        prd.dt_update
                   FROM pat_recommendation_det prd
                  WHERE prd.id_pat_recommendation = l_id_pat_rec
                    AND prd.flg_read = g_flg_unread);
        
            UPDATE pat_recommendation_det prd
               SET prd.flg_read        = i_flg_read,
                   prd.id_professional = i_prof.id,
                   prd.dt_read         = l_op_timestamp,
                   prd.dt_update       = l_op_timestamp
             WHERE prd.id_pat_recommendation = l_id_pat_rec;
        
            g_error := 'VALIDATING EXISTENCE OF UNRED RECOMMENDATIONS';
            BEGIN
                SELECT pr.id_recommendation
                  INTO l_id_unread_rec
                  FROM pat_recommendation pr
                  JOIN pat_recommendation_det prd
                    ON prd.id_pat_recommendation = pr.id_pat_recommendation
                 WHERE pr.id_patient = i_id_patient
                   AND prd.flg_read = g_flg_unread
                   AND rownum = 1;
            EXCEPTION
                WHEN no_data_found THEN
                    IF NOT pk_alerts.delete_sys_alert_event(i_lang, i_prof, 108, i_id_patient, o_error)
                    THEN
                        RETURN FALSE;
                    END IF;
            END;
        
        ELSE
            g_error := 'SETTING REC UNREADED';
            INSERT INTO pat_recommendation_hist
                (id_pat_recommendation_hist,
                 id_pat_recommendation_det,
                 id_pat_recommendation,
                 id_cdr_instance,
                 dt_recommendation,
                 flg_read,
                 id_professional,
                 dt_read,
                 dt_update)
                (SELECT seq_pat_recommendation_hist.nextval,
                        prd.id_pat_recommendation_det,
                        prd.id_pat_recommendation,
                        prd.id_cdr_instance,
                        prd.dt_recommendation,
                        prd.flg_read,
                        prd.id_professional,
                        prd.dt_read,
                        prd.dt_update
                   FROM pat_recommendation_det prd
                  WHERE prd.id_pat_recommendation = l_id_pat_rec
                    AND prd.dt_read =
                        (SELECT MAX(prd.dt_read)
                           FROM pat_recommendation_det prd1
                          WHERE prd1.id_pat_recommendation_det = prd.id_pat_recommendation_det));
        
            UPDATE pat_recommendation_det prd
               SET prd.flg_read        = i_flg_read,
                   prd.id_professional = NULL,
                   prd.dt_read         = NULL,
                   prd.dt_update       = l_op_timestamp
             WHERE prd.id_pat_recommendation = l_id_pat_rec
               AND prd.dt_read = (SELECT MAX(prd.dt_read)
                                    FROM pat_recommendation_det prd1
                                   WHERE prd1.id_pat_recommendation_det = prd.id_pat_recommendation_det);
        
            g_error     := 'CREATING SYS_ALERT DATA';
            l_alert_msg := pk_message.get_message(i_lang, 'RECOMMENDATION_M001');
        
            IF NOT pk_alerts.insert_sys_alert_event(i_lang,
                                                    i_prof,
                                                    108,
                                                    i_id_episode,
                                                    i_id_patient,
                                                    current_timestamp,
                                                    NULL,
                                                    NULL,
                                                    NULL,
                                                    NULL,
                                                    l_alert_msg,
                                                    NULL,
                                                    NULL,
                                                    o_error)
            THEN
                RETURN FALSE;
            END IF;
        
        END IF;
    
        SELECT sd.img_name,
               decode(i_flg_read,
                      g_flg_read,
                      pk_date_utils.dt_chr_year_short_tsz(i_lang, l_op_timestamp, i_prof.institution, i_prof.software),
                      NULL)
          INTO o_icon_name, o_dt_read
          FROM sys_domain sd
         WHERE sd.code_domain = g_code_domain
           AND sd.domain_owner = pk_sysdomain.k_default_schema
           AND sd.val = i_flg_read
           AND sd.id_language = i_lang;
    
        COMMIT;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_PAT_RECOMMENDATION_READ',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_pat_recommendation_read;

BEGIN
    -- Log initialization.
    pk_alertlog.log_init(g_package_name);

END pk_recommendation;
/
