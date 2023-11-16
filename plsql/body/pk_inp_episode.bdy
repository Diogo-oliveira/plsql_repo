/*-- Last Change Revision: $Rev: 2027250 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:41:38 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_inp_episode IS

    /*******************************************************************************************************************************************
    * CREATE_EPISODE                  Function that creates one new INPATIENT episode (episode and visit) and return new episode identifier.
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_PROF                   Professional vector of information (professional ID, institution ID, software ID)
    * @param I_ID_PATIENT             PATIENT identifier that should be associated with this new episode
    * @param I_ID_DEP_CLIN_SERV       DEP_CLIN_SERV identifier that should be associated with this new episode
    * @param I_ID_ROOM                ROOM identifier that should be associated with this new episode
    * @param I_ID_BED                 BED identifier that should be associated with this new episode
    * @param I_DT_BEGIN               Episode start date (begin date) that should be associated with this new episode
    * @param I_DT_DISCHARGE           Episode discharge date that should be associated with this new episode
    * @param I_ANAMNESIS              Anamnesis information that should be associated with this new episode
    * @param I_FLG_SURGERY            Information if new episode should be associated with an cirurgical episode
    * @param I_TYPE                   EPIS_TYPE identifier that should be associated with this new episode
    * @param I_DT_SURGERY             Surgery date that should be associated with ORIS episode associated with this new episode
    * @param I_ID_PREV_EPISODE        EPISODE identifier that represents the parent episode that should be associated with this new episode
    * @param I_ID_EXTERNAL_SYS        EXTERNAL_SYS identifier that should be associated with this new episode
    * @param i_transaction_id         remote transaction identifier
    * @param O_ID_INP_EPISODE         INPATIENT episode identifier created for this new patient
    * @param O_ERROR                  If an error accurs, this parameter will have information about the error
    * 
    * @return                         Returns TRUE if success, otherwise returns FALSE
    * 
    * @raises                         PL/SQL generic erro "OTHERS"
    * 
    * @author                         Carlos Ferreira
    * @version                        1.0
    * @since                          N.A.
    *
    * @author                         Luís Maia
    * @version                        2.0
    * @since                          2009/05/08
    *
    *******************************************************************************************************************************************/
    FUNCTION create_episode
    (
        i_lang             IN NUMBER,
        i_prof             IN profissional,
        i_id_patient       IN NUMBER,
        i_id_dep_clin_serv IN NUMBER,
        i_id_room          IN NUMBER,
        i_id_bed           IN NUMBER,
        i_dt_begin         IN VARCHAR2,
        i_dt_discharge     IN VARCHAR2,
        i_flg_hour_origin  IN VARCHAR2 DEFAULT pk_discharge.g_disch_flg_hour_dh,
        i_anamnesis        IN VARCHAR2,
        i_flg_surgery      IN VARCHAR2,
        i_type             IN NUMBER,
        i_dt_surgery       IN VARCHAR2,
        i_id_prev_episode  IN episode.id_prev_episode%TYPE,
        i_id_external_sys  IN epis_ext_sys.id_external_sys%TYPE DEFAULT NULL,
        i_transaction_id   IN VARCHAR2,
        o_id_inp_episode   OUT NUMBER,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        --Scheduler 3.0 variables
        l_transaction_id VARCHAR2(4000);
    BEGIN
        -- gets a new transaction ID and begins the transaction (for the Scheduler 3.0 transactions)
        g_error          := 'CALL PK_SCHEDULE_API_UPSTREAM.BEGIN_NEW_TRANSACTION';
        l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(i_transaction_id, i_prof);
    
        --
        g_error := 'CALL TO CREATE_EPISODE_NO_COMMIT';
        IF NOT pk_inp_episode.create_episode_no_commit(i_lang                   => i_lang,
                                                       i_prof                   => i_prof,
                                                       i_id_patient             => i_id_patient,
                                                       i_id_dep_clin_serv       => i_id_dep_clin_serv,
                                                       i_id_room                => i_id_room,
                                                       i_id_bed                 => i_id_bed,
                                                       i_dt_begin               => i_dt_begin,
                                                       i_flg_dt_begin_with_tstz => pk_alert_constant.g_yes,
                                                       i_dt_discharge           => i_dt_discharge,
                                                       i_flg_hour_origin        => i_flg_hour_origin,
                                                       i_anamnesis              => i_anamnesis,
                                                       i_flg_surgery            => i_flg_surgery,
                                                       i_type                   => i_type,
                                                       i_dt_surgery             => i_dt_surgery,
                                                       i_id_prev_episode        => i_id_prev_episode,
                                                       i_id_external_sys        => i_id_external_sys,
                                                       i_transaction_id         => l_transaction_id,
                                                       i_id_visit               => NULL,
                                                       o_id_inp_episode         => o_id_inp_episode,
                                                       o_error                  => o_error)
        THEN
            RAISE e_call_error;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CREATE_EPISODE',
                                              o_error);
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            RETURN FALSE;
    END create_episode;

    /*******************************************************************************************************************************************
    * GET_EPIS_DIAGNOSIS              Function that returns diagnosis associated with one episode
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_ID_PROF                Professional vector of information (professional ID, institution ID, software ID)
    * @param I_ID_EPISODE             EPISODE identifier that should be searched
    * @param O_DIAGNOSIS              Diagnosis associated with episode identifier
    * @param O_ERROR                  If an error accurs, this parameter will have information about the error
    * 
    * @return                         Returns TRUE if success, otherwise returns FALSE
    * 
    * @raises                         PL/SQL generic erro "OTHERS"
    * 
    * @author                         Carlos Ferreira
    * @version                        1.0
    * @since                          N.A.
    *
    * @author                         Luís Maia
    * @version                        2.0
    * @since                          2009/05/11
    *
    *******************************************************************************************************************************************/
    FUNCTION get_epis_diagnosis
    (
        i_lang       IN NUMBER,
        i_id_prof    IN profissional,
        i_id_episode IN NUMBER,
        o_diagnosis  OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        --
        g_error := 'OPEN CURSOR DIAGNOSIS';
        OPEN o_diagnosis FOR
            SELECT ed.flg_status,
                   pk_diagnosis.std_diag_desc(i_lang                => i_lang,
                                              i_prof                => i_id_prof,
                                              i_id_alert_diagnosis  => ad.id_alert_diagnosis,
                                              i_id_diagnosis        => d.id_diagnosis,
                                              i_desc_epis_diagnosis => ed.desc_epis_diagnosis,
                                              i_code                => d.code_icd,
                                              i_flg_other           => d.flg_other,
                                              i_flg_std_diag        => ad.flg_icd9,
                                              i_epis_diag           => ed.id_epis_diagnosis) desc_diagnosis,
                   pk_date_utils.date_send_tsz(i_lang, dt_epis_diagnosis_tstz, i_id_prof) dt_diagnosis
              FROM epis_diagnosis ed, diagnosis d, alert_diagnosis ad
             WHERE ed.id_episode = i_id_episode
               AND ed.id_diagnosis = d.id_diagnosis
               AND ed.id_alert_diagnosis = ad.id_alert_diagnosis(+)
               AND ed.flg_type = pk_alert_constant.g_epis_diag_flg_status_d
               AND ed.flg_status IN
                   (pk_alert_constant.g_epis_diag_flg_status_f, pk_alert_constant.g_epis_diag_flg_status_d)
            UNION ALL
            SELECT ed.flg_status,
                   pk_diagnosis.std_diag_desc(i_lang                => i_lang,
                                              i_prof                => i_id_prof,
                                              i_id_alert_diagnosis  => ad.id_alert_diagnosis,
                                              i_id_diagnosis        => d.id_diagnosis,
                                              i_desc_epis_diagnosis => ed.desc_epis_diagnosis,
                                              i_code                => d.code_icd,
                                              i_flg_other           => d.flg_other,
                                              i_flg_std_diag        => ad.flg_icd9,
                                              i_epis_diag           => ed.id_epis_diagnosis) desc_diagnosis,
                   pk_date_utils.date_send_tsz(i_lang, dt_epis_diagnosis_tstz, i_id_prof) dt_diagnosis
              FROM epis_diagnosis ed, diagnosis d, alert_diagnosis ad
             WHERE ed.id_episode = i_id_episode
               AND ed.id_diagnosis = d.id_diagnosis
               AND ed.id_alert_diagnosis = ad.id_alert_diagnosis(+)
               AND ed.flg_type = 'P'
               AND ed.flg_status IN
                   (pk_alert_constant.g_epis_diag_flg_status_f, pk_alert_constant.g_epis_diag_flg_status_d)
               AND ed.id_diagnosis NOT IN
                   (SELECT ed2.id_diagnosis
                      FROM epis_diagnosis ed2
                     WHERE ed2.id_episode = i_id_episode
                       AND ed2.flg_type = pk_alert_constant.g_epis_diag_flg_status_d
                       AND ed2.flg_status IN
                           (pk_alert_constant.g_epis_diag_flg_status_f, pk_alert_constant.g_epis_diag_flg_status_d))
             ORDER BY dt_diagnosis DESC, desc_diagnosis DESC;
    
        --
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.reset_error_state;
            g_ret := pk_alert_exceptions.process_error(i_lang,
                                                       SQLCODE,
                                                       SQLERRM,
                                                       g_error,
                                                       g_package_owner,
                                                       g_package_name,
                                                       'GET_EPIS_DIAGNOSIS',
                                                       o_error);
            pk_types.open_my_cursor(o_diagnosis);
            RETURN FALSE;
    END get_epis_diagnosis;

    /*******************************************************************************************************************************************
    * CALL_INS_EPISODE_INT            Create an episode for an patient with send parameters (including dates) and returns id_visit created
    * 
    * @param IN I_LANG                   Language ID for translations
    * @param IN I_PROF                   Professional vector of information (professional ID, institution ID, software ID)
    * @param IN I_ID_EPISODE             EPISODE identifier that should be associated with new episode
    * @param IN I_ID_PREV_EPISODE        EPISODE identifier that should be associated with new episode parent episode
    * @param IN I_ID_EPIS_TYPE           EPIS_TYPE identifier that should be associated with new episode
    * @param IN I_ID_EPIS_TYPE_PREV      EPIS_TYPE identifier that should be associated with new episode parent episode
    * @param IN I_ID_EPISODE_EXT         EPISODE_EXT identifier that should be associated with new episode
    * @param IN I_ID_EXTERNAL_SYS        EXTERNAL_SYS identifier that should be associated with new episode
    * @param IN OUT I_FLG_UNKNOW         Episode is unknow ('Y' - Yes, 'N' - No)
    * @param OUT O_ERROR                 If an error accurs, this parameter will have information about the error
    *
    * @author                            Luís Maia
    * @version                           2.6.0.1
    * @since                             2010/May/01
    *
    *******************************************************************************************************************************************/
    FUNCTION set_epis_ext_sys
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_episode        IN episode.id_episode%TYPE,
        i_id_prev_episode   IN episode.id_prev_episode%TYPE,
        i_id_epis_type      IN epis_type.id_epis_type%TYPE,
        i_id_epis_type_prev IN epis_type.id_epis_type%TYPE,
        i_id_episode_ext    IN VARCHAR2,
        i_id_external_sys   IN epis_ext_sys.id_external_sys%TYPE,
        i_flg_unknow        IN OUT epis_info.flg_unknown%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_cod_epis_type_ext epis_ext_sys.cod_epis_type_ext%TYPE;
        l_id_ext_sys        VARCHAR2(50) := pk_sysconfig.get_config('ID_EXTERNAL_SYS', i_prof);
        l_id_epis_ext       NUMBER;
        l_id_external_sys   NUMBER;
        l_count             NUMBER;
        l_ext_value         VARCHAR2(0050);
        no_value            VARCHAR2(0050);
    BEGIN
        l_id_external_sys := nvl(i_id_external_sys, l_id_ext_sys);
        no_value          := 'XXX';
    
        -- if it is not an inpatient episode -> create mapping
        -- IF l_id_epis_type_prev != l_id_epis_type   23-11-2007 Correction proposed after interface confirmation
        IF i_id_epis_type_prev != i_id_epis_type
           OR i_id_epis_type_prev IS NULL
        THEN
            IF i_id_prev_episode IS NOT NULL
            THEN
                /*g_error := 'GET FLG_UNKNOWN 1';
                SELECT flg_unknown
                  INTO i_flg_unknow
                  FROM epis_info
                 WHERE id_episode = i_id_prev_episode;*/
            
                SELECT COUNT(1)
                  INTO l_count
                  FROM epis_ext_sys
                 WHERE id_episode = i_id_prev_episode
                   AND id_institution = i_prof.institution;
            
                IF l_count > 0
                THEN
                    g_error := 'GET EXTERNAL SYSTEM VALUE  OF PREV EPISODE';
                    SELECT VALUE, nvl(cod_epis_type_ext, no_value)
                      INTO l_ext_value, l_cod_epis_type_ext
                      FROM epis_ext_sys
                     WHERE id_episode = i_id_prev_episode
                       AND id_institution = i_prof.institution;
                ELSE
                    l_ext_value         := NULL;
                    l_cod_epis_type_ext := pk_core.get_code_epis_ext(i_lang         => i_lang,
                                                                     i_id_epis_type => i_id_epis_type_prev);
                END IF;
            
                -- 17-12-2010: Removed because it is supposed add the same value till automatic match...
                -- Situation discovered and reported on HES by Alexandre Inácio
                --IF trunc(nvl(i_dt_begin, g_sysdate_tstz)) = trunc(current_timestamp)
                --THEN
                --    l_ext_value := i_id_episode_ext; -- Can be NULL
                --END IF;
            ELSE
            
                g_error := 'GET FLG_UNKNOWN 2';
                --i_flg_unknow        := 'Y';
                l_cod_epis_type_ext := pk_core.get_code_epis_ext(i_lang => i_lang, i_id_epis_type => i_id_epis_type);
                l_ext_value         := i_id_episode_ext;
            END IF;
        
            g_error := 'GET NEXTVAL FOR EPIS_EXT_SYS';
            SELECT seq_epis_ext_sys.nextval
              INTO l_id_epis_ext
              FROM dual;
        
            g_error := 'INSERTING INTO EPIS_EXT_SYS [ALERT_ID_EPISODE:' || i_id_episode || ' EXT_ID_EPISODE:' ||
                       i_id_episode_ext || ']';
        
            INSERT INTO epis_ext_sys
                (id_epis_ext_sys, id_external_sys, id_episode, VALUE, id_institution, id_epis_type, cod_epis_type_ext)
            VALUES
                (l_id_epis_ext,
                 l_id_external_sys,
                 i_id_episode,
                 l_ext_value,
                 i_prof.institution,
                 i_id_epis_type,
                 l_cod_epis_type_ext);
        
        END IF;
    
        --
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_EPIS_EXT_SYS',
                                              o_error);
            RETURN FALSE;
    END set_epis_ext_sys;

    /*******************************************************************************************************************************************
    * VALIDATE_INP_CREATION           Function that validates if one new INPATIENT episode can be created
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_PROF                   Professional vector of information (professional ID, institution ID, software ID)
    * @param I_ID_PREV_EPISODE        Episode where current inpatient episode is being created             
    * @param I_ID_PATIENT             PATIENT identifier that should be associated with new episode
    * @param I_ID_VISIT               Visit identifier that should be associated with new episode
    * @param O_ERROR                  If an error accurs, this parameter will have information about the error
    * 
    * @return                         Returns '1' if success, otherwise returns '0'
    * 
    * @raises err_duplicate_prev_episode      Error when checking previous episode
    * @raises err_multi_inp_in_visit          Error when checking if visit hasn't inpatient episodes
    * @raises                                 PL/SQL generic erro "OTHERS"
    * 
    * @author                         Luís Maia
    * @version                        2.6.0.1
    * @since                          2010/May/12
    *
    *******************************************************************************************************************************************/
    FUNCTION validate_inp_creation
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_prev_episode IN episode.id_prev_episode%TYPE,
        i_id_visit        IN episode.id_visit%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id_epis_type             PLS_INTEGER;
        l_count_prv                PLS_INTEGER := 0;
        l_count_vis                PLS_INTEGER := 0;
        err_duplicate_prev_episode EXCEPTION;
        err_multi_inp_in_visit     EXCEPTION;
    
    BEGIN
        g_error        := 'GET CONFIGURATIONS';
        l_id_epis_type := pk_sysconfig.get_config('ID_EPIS_TYPE_INPATIENT', i_prof);
    
        --g_error := 'VALIDATE IF ALREADY EXISTS ONE INPATIENT EPISODE WITH SAME ID_PREV_EPISODE THAT OTHER NON INPATIENT EPISODE';
        g_error := pk_message.get_message(i_lang => i_lang, i_code_mess => 'CHECK_INPATIENTS_M001');
        SELECT COUNT(1)
          INTO l_count_prv
          FROM episode inp_epi
         INNER JOIN episode prv_epi
            ON (inp_epi.id_prev_episode = prv_epi.id_episode AND inp_epi.id_visit = prv_epi.id_visit)
         WHERE inp_epi.id_epis_type = l_id_epis_type
           AND inp_epi.id_prev_episode = i_id_prev_episode
           AND prv_epi.id_epis_type != l_id_epis_type
           AND prv_epi.id_visit = i_id_visit
           AND inp_epi.flg_status != g_episode_flg_status_canceled;
    
        IF l_count_prv > 0
        THEN
            RAISE err_duplicate_prev_episode;
        END IF;
    
        g_error := 'VALIDATE IF VISIT HAS NO INPATIENT EPISODES';
        SELECT COUNT(*)
          INTO l_count_vis
          FROM episode epi
         WHERE epi.id_epis_type = l_id_epis_type
           AND epi.flg_status = g_episode_flg_status_active
           AND epi.id_visit = i_id_visit;
    
        IF l_count_vis > 0
        THEN
            RAISE err_multi_inp_in_visit;
        END IF;
    
        --
        RETURN TRUE;
    EXCEPTION
        WHEN err_duplicate_prev_episode THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
                --l_error_message VARCHAR2(4000) := pk_message.get_message(i_lang, 'COMMON_M001');
                l_error_message VARCHAR2(2) := '';
            BEGIN
                l_error_in.set_all(i_lang,
                                   NULL,
                                   l_error_message,
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   NULL,
                                   NULL,
                                   'U');
                g_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            END;
            RETURN FALSE;
            --
        WHEN err_multi_inp_in_visit THEN
            DECLARE
                l_error_in      t_error_in := t_error_in();
                l_error_message VARCHAR2(4000) := pk_message.get_message(i_lang, 'COMMON_M001');
            
            BEGIN
                l_error_in.set_all(i_lang,
                                   'ERR_MULTI_INP_IN_VISIT',
                                   l_error_message,
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   'VALIDATE_INP_CREATION');
                l_error_in.set_action('Error when checking if visit hasn''t inpatient episodes', 'S');
                g_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            END;
            RETURN FALSE;
            --
        WHEN OTHERS THEN
            pk_alert_exceptions.reset_error_state;
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_package_owner,
                                                     g_package_name,
                                                     'VALIDATE_INP_CREATION',
                                                     o_error);
    END validate_inp_creation;

    /**********************************************************************************************
    * SET_SCHEDULE_INP_BED     Insert a record in schedule_inp_bed if no ALERT scheduler is being
    * used in the institution       
    * 
    * @param i_lang                   the id language
    * @param i_id_episode             Episode Id    
    * @param i_id_room                room identifier
    * @param i_id_bed                 bed identifier
    * @param i_dt_begin               Episode start date
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Sofia Mendes
    * @version                        2.6.3.2
    * @since                          06/Sep/2010
    **********************************************************************************************/
    FUNCTION set_schedule_inp_bed
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        i_id_room    IN epis_prof_resp.id_room%TYPE,
        i_id_bed     IN epis_prof_resp.id_bed%TYPE,
        i_dt_begin   IN TIMESTAMP WITH LOCAL TIME ZONE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_has_scheduler sys_config.value%TYPE;
        l_rows          table_varchar;
    BEGIN
        g_error := 'CALL pk_sysconfig.get_config for id: ' || g_has_scheduler;
        pk_alertlog.log_debug(g_error);
        l_has_scheduler := pk_sysconfig.get_config(g_has_scheduler, i_prof);
    
        IF (l_has_scheduler = pk_alert_constant.g_no)
        THEN
            l_rows  := table_varchar();
            g_error := 'CALL TS_SCHEDULE_INP_BED.INS WITH ID_EPISODE:' || i_id_episode;
            pk_alertlog.log_debug(g_error);
            ts_schedule_inp_bed.ins(id_episode_in  => i_id_episode,
                                    id_bed_in      => i_id_bed,
                                    id_room_in     => i_id_room,
                                    dt_schedule_in => i_dt_begin,
                                    rows_out       => l_rows);
        
            g_error := 'PROCESS INSERT - SCHEDULE_INP_BED';
            pk_alertlog.log_debug(g_error);
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'SCHEDULE_INP_BED',
                                          i_rowids     => l_rows,
                                          o_error      => o_error);
        END IF;
        --        
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_SCHEDULE_INP_BED',
                                              o_error);
            RETURN FALSE;
    END set_schedule_inp_bed;

    /*******************************************************************************************************************************************
    * Creates an H&P Note for this episode to fill the Expected Discharge Date
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_PROF                   Interface professional vector of information
    * @param I_ID_EPISODE             EPISODE identifier that should be associated with new episode
    * @param I_ADMISSION_NOTES        Admission notes for Expected Discharge Note
    * @param I_DT_ADMISSION_NOTES     Admission notes Date/Time for Expected Discharge Date (If null sets with Current Date/Time)
    * @param O_ERROR                  If an error accurs, this parameter will have information about the error
    * 
    * @return                         Returns TRUE if success, otherwise returns FALSE
    * 
    * @author                         António Neto
    * @version                        2.6.1.2
    * @since                          12-Aug-2011
    *
    *******************************************************************************************************************************************/
    FUNCTION create_handp_note_int
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_episode         IN episode.id_episode%TYPE,
        i_admission_notes    IN epis_anamnesis.desc_epis_anamnesis%TYPE,
        i_dt_admission_notes IN epis_anamnesis.dt_epis_anamnesis_tstz%TYPE DEFAULT NULL,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_epis_pn epis_pn.id_epis_pn%TYPE;
    
        l_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE := current_timestamp;
    
    BEGIN
    
        g_error := 'CALL PK_PROG_NOTES_CORE.SET_SAVE_DEF_NOTE FOR id_episode = ' || i_id_episode;
        pk_alertlog.log_debug(g_error);
        IF NOT pk_prog_notes_core.set_save_def_note(i_lang                => i_lang,
                                                    i_prof                => i_prof,
                                                    i_epis_pn             => NULL,
                                                    i_id_dictation_report => NULL,
                                                    i_id_episode          => i_id_episode,
                                                    i_pn_flg_status       => pk_prog_notes_constants.g_epis_pn_flg_status_d,
                                                    i_id_pn_note_type     => pk_prog_notes_constants.g_note_type_id_handp_2,
                                                    i_dt_pn_date          => l_sysdate_tstz,
                                                    i_id_dep_clin_serv    => NULL,
                                                    i_id_pn_data_block    => table_number(pk_prog_notes_constants.g_dblock_eddate_93,
                                                                                          pk_prog_notes_constants.g_dblock_chiefcomplaint_48),
                                                    i_id_pn_soap_block    => table_number(pk_prog_notes_constants.g_sblock_eddate_18,
                                                                                          pk_prog_notes_constants.g_sblock_chiefcomplaint_7),
                                                    i_id_task             => table_number(NULL, NULL),
                                                    i_id_task_type        => table_number(NULL, NULL),
                                                    i_pn_note             => table_clob(pk_date_utils.date_char_tsz(i_lang,
                                                                                                                    nvl(i_dt_admission_notes,
                                                                                                                        l_sysdate_tstz),
                                                                                                                    i_prof.institution,
                                                                                                                    i_prof.software),
                                                                                        i_admission_notes),
                                                    i_id_professional     => i_prof.id,
                                                    i_dt_create           => l_sysdate_tstz,
                                                    i_dt_last_update      => l_sysdate_tstz,
                                                    i_dt_sent_to_hist     => l_sysdate_tstz,
                                                    i_id_prof_sign_off    => NULL,
                                                    i_dt_sign_off         => NULL,
                                                    o_id_epis_pn          => l_id_epis_pn,
                                                    o_error               => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CREATE_HANDP_NOTE_INT',
                                              o_error);
            RETURN FALSE;
    END create_handp_note_int;

    /*******************************************************************************************************************************************
    * CALL_INS_EPISODE_INT            Create an episode for an patient with send parameters (including dates) and returns id_visit created
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_ID_VISIT               VISIT identifier that should be associated with new episode
    * @param I_PROF_RESP              Professional responsable for new inpatient episode
    * @param I_PROF_INTF              Professional that insert current registries (and inpatient episode creation)
    * @param I_ID_SCHED               SCHEDULE identifier that should be associated with new episode
    * @param I_ID_EPISODE             EPISODE identifier that should be associated with new episode
    * @param I_HEALTH_PLAN            HEALTH_PLAN identifier that should be associated with new episode
    * @param I_ID_DEP_CLIN_SERV       DEP_CLIN_SERV identifier that should be associated with new episode
    * @param I_ID_ROOM                ROOM identifier that should be associated with new episode
    * @param I_DT_BEGIN               Episode begin date
    * @param I_DT_CREATION            Episode creation date
    * @param I_ID_EPISODE_EXT         EPISODE_EXT identifier that should be associated with new episode
    * @param I_FLG_TYPE               Episode type ('T' - TEMPORARY, 'D' - DEFINITIVE)
    * @param I_FLG_EHR                Type of EHR episode ('N' - Normal episode, 'E' - EHR event, 'S' - Episode preparation of a scheduled event)
    * @param I_TYPE                   Type of surgery ('A' - Ambulatory)
    * @param I_DT_SURGERY             Episode SURGERY date
    * @param I_FLG_SURGERY            Indicates if this episode has an SURGERY episode associated: ('Y' - Yes, 'N' - No)
    * @param I_ADMITION_NOTES         Admition notes
    * @param I_DT_ADMITION_NOTES      Admition notes Date/Time
    * @param I_ID_PREV_EPISODE        EPISODE identifier that should be associated with new episode (PREV_EPISODE identifier)
    * @param I_ID_EXTERNAL_SYS        EXTERNAL_SYS identifier that should be associated with new episode
    * @param I_FLG_MIGRATION          Shows type of visit ('A' for ALERT visits, 'M' for migrated records, 'T' for test records)
    * @param i_transaction_id         remote transaction identifier
    * @param O_ID_EPISODE             EPISODE identifier corresponding to created episode
    * @param O_BED_ALLOCATION         Indicates if bed allocation was succeceful ('Y' - Yes; 'N' - No)
    * @param O_EXCEPTION_INFO         Error message to be displayed to the user. 
    * @param O_ERROR                  If an error accurs, this parameter will have information about the error
    * 
    * @value  I_FLG_MIGRATION         {*} 'A'- ALERT visits {*} 'M'- Migrated records {*} 'T'- Test records 
    *
    * @return                         Returns TRUE if success, otherwise returns FALSE
    * 
    * @raises err_default_template            Error when checking templates
    * @raises err_duplicate_prev_episode      Error when checking previous episode
    * @raises err_create_sr_episode           Error when reating an surgery episode
    * @raises no_data_found                   No data found
    * @raises                                 PL/SQL generic erro "OTHERS"
    * 
    * @author                         Carlos Ferreira
    * @version                        1.0
    * @since                          2006/11/11
    *
    * @author                         Luís Maia
    * @version                        2.0
    * @since                          2009/05/11
    *
    *******************************************************************************************************************************************/
    FUNCTION call_ins_episode_int
    (
        i_lang                   IN language.id_language%TYPE,
        i_id_visit               IN visit.id_visit%TYPE,
        i_id_prof_resp           IN profissional,
        i_id_prof_intf           IN profissional,
        i_id_sched               IN epis_info.id_schedule%TYPE,
        i_id_episode             IN episode.id_episode%TYPE,
        i_health_plan            IN health_plan.id_health_plan%TYPE,
        i_id_dep_clin_serv       IN NUMBER,
        i_id_room                IN NUMBER,
        i_id_bed                 IN epis_info.id_bed%TYPE DEFAULT NULL,
        i_dt_begin               IN episode.dt_begin_tstz%TYPE,
        i_dt_creation            IN episode.dt_creation%TYPE,
        i_id_episode_ext         IN VARCHAR2,
        i_flg_type               IN VARCHAR2,
        i_flg_ehr                IN episode.flg_ehr%TYPE DEFAULT 'N',
        i_type                   IN VARCHAR2 DEFAULT NULL,
        i_dt_surgery             IN VARCHAR2,
        i_flg_surgery            IN VARCHAR2,
        i_admition_notes         IN epis_anamnesis.desc_epis_anamnesis%TYPE,
        i_dt_admition_notes      IN epis_anamnesis.dt_epis_anamnesis_tstz%TYPE DEFAULT NULL,
        i_id_prev_episode        IN episode.id_prev_episode%TYPE,
        i_id_external_sys        IN epis_ext_sys.id_external_sys%TYPE,
        i_flg_migration          IN visit.flg_migration%TYPE,
        i_transaction_id         IN VARCHAR2,
        i_dt_creation_allocation IN bmng_allocation_bed.dt_creation%TYPE DEFAULT NULL,
        i_dt_creation_resp       IN epis_prof_resp.dt_execute_tstz%TYPE DEFAULT NULL,
        i_dt_disch_sched         IN discharge_schedule.dt_discharge_schedule%TYPE,
        i_order_set              IN VARCHAR2 DEFAULT 'N',
        i_flg_compulsory         IN episode.flg_compulsory%TYPE DEFAULT NULL,
        i_id_compulsory_reason   IN episode.id_compulsory_reason%TYPE DEFAULT NULL,
        i_compulsory_reason      IN episode.compulsory_reason%TYPE DEFAULT NULL,
        o_id_episode             OUT NUMBER,
        o_id_patient             OUT patient.id_patient%TYPE,
        o_bed_allocation         OUT VARCHAR2,
        o_exception_info         OUT sys_message.desc_message%TYPE,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(20 CHAR) := 'CALL_INS_EPISODE_INT';
    
        l_seq_epis      episode.id_episode%TYPE;
        l_seq_epis_inst NUMBER;
    
        l_pat                    NUMBER;
        l_room                   NUMBER;
        l_visit_status           VARCHAR2(0050);
        l_id_visit               NUMBER;
        l_instit                 NUMBER;
        l_pat_hplan              NUMBER;
        l_instit_type            VARCHAR2(0050);
        l_rank                   NUMBER;
        l_id_room_allocation     bed.id_room%TYPE;
        l_id_dep_allocation      room.id_department%TYPE;
        l_id_bmng_allocation_bed bmng_allocation_bed.id_bmng_allocation_bed%TYPE;
        l_id_epis_anamnesis      epis_anamnesis.id_epis_anamnesis%TYPE;
        l_transaction_id         VARCHAR2(4000);
    
        CURSOR c_epis_room
        (
            l_epis_type     IN epis_type.id_epis_type%TYPE,
            l_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE
        ) IS
            SELECT er.id_room, 0 rank
              FROM epis_type_room er
             WHERE er.id_epis_type = l_epis_type
               AND er.id_institution = i_id_prof_intf.institution
               AND nvl(er.id_dep_clin_serv, 0) = 0
            UNION
            SELECT er.id_room, 1 rank
              FROM epis_type_room er
             WHERE er.id_epis_type = l_epis_type
               AND er.id_institution = i_id_prof_intf.institution
               AND er.id_dep_clin_serv = l_dep_clin_serv
             ORDER BY rank DESC;
    
        CURSOR c_visit IS
            SELECT v.id_patient, v.flg_status, v.id_institution, i.flg_type
              FROM visit v, institution i
             WHERE id_visit = l_id_visit
               AND i.id_institution = v.id_institution;
    
        CURSOR c_pat_hplan IS
            SELECT id_pat_health_plan
              FROM pat_health_plan
             WHERE id_patient = l_pat
               AND id_health_plan = i_health_plan;
    
        l_id_clinical_service NUMBER;
        l_id_department       department.id_department%TYPE;
        l_id_dept             dept.id_dept%TYPE;
        l_rowids              table_varchar;
    
        l_id_epis_type      NUMBER;
        l_id_epis_type_prev NUMBER;
    
        l_o_sr_episode      NUMBER;
        l_schedule          NUMBER;
        l_id_epis_type_edis NUMBER;
        l_id_epis_type_ce   NUMBER;
        l_flg_unknow        VARCHAR2(0050);
        l_barcode           VARCHAR2(0050);
    
        l_other_id_episode  episode.id_episode%TYPE;
        l_other_id_patient  patient.id_patient%TYPE;
        l_other_id_visit    visit.id_visit%TYPE;
        l_id_prev_epis_type episode.id_prev_epis_type%TYPE;
        l_tab_other_epis    table_number := table_number();
    
        l_epis_doc_template table_number;
    
        err_create_sr_episode EXCEPTION;
        err_default_template  EXCEPTION;
        err_create_bmng_alloc EXCEPTION;
        l_internal_error      EXCEPTION;
        no_data_found         EXCEPTION;
        OTHERS                EXCEPTION;
        l_rowid_ei            table_varchar;
        l_id_bed              bed.id_bed%TYPE;
    
        l_sys_alert_event sys_alert_event%ROWTYPE;
    
        l_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE := current_timestamp;
    
        l_no_triage_color triage_color.id_triage_color%TYPE;
    
        l_vte_reassessment sys_config.value%TYPE := pk_sysconfig.get_config('VTE_REASSEMENT', i_id_prof_intf);
    
    BEGIN
    
        -- gets a new transaction ID and begins the transaction (for the Scheduler 3.0 transactions)
        g_error          := 'CALL PK_SCHEDULE_API_UPSTREAM.BEGIN_NEW_TRANSACTION';
        l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(i_transaction_id, i_id_prof_intf);
    
        g_error             := 'GET CONFIGURATIONS';
        l_flg_unknow := CASE
                            WHEN i_flg_type = pk_episode.g_flg_def THEN
                             pk_alert_constant.g_no
                            ELSE
                             pk_alert_constant.g_yes
                        END;
        l_id_visit          := nvl(i_id_visit, 0);
        l_id_epis_type      := pk_sysconfig.get_config('ID_EPIS_TYPE_INPATIENT', i_id_prof_intf);
        l_id_epis_type_edis := pk_sysconfig.get_config('ID_EPIS_TYPE_EDIS', i_id_prof_intf);
        l_id_epis_type_ce   := pk_sysconfig.get_config('ID_EPIS_TYPE_CONSULT', i_id_prof_intf);
    
        g_error := 'CALL PK_INP_EPISODE.VALIDATE_INP_CREATION';
        IF NOT validate_inp_creation(i_lang            => i_lang,
                                     i_prof            => i_id_prof_intf,
                                     i_id_prev_episode => i_id_prev_episode,
                                     i_id_visit        => i_id_visit,
                                     o_error           => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        IF i_id_prev_episode IS NOT NULL
        THEN
            SELECT id_epis_type
              INTO l_id_epis_type_prev
              FROM episode
             WHERE id_episode = i_id_prev_episode;
        END IF;
    
        g_error := 'GET CURSOR C_VISIT';
        OPEN c_visit;
        FETCH c_visit
            INTO l_pat, l_visit_status, l_instit, l_instit_type;
        CLOSE c_visit;
    
        ---------------------------------------------------------------------------------------------------------
        -- Manage episodes created through INTER-ALERT
        ---------------------------------------------------------------------------------------------------------
        IF i_id_episode_ext IS NOT NULL
           AND i_id_prev_episode IS NOT NULL
        THEN
        
            -- Search for any INP episode that has the same value, but no id_prev_episode and a different visit.
            BEGIN
                g_error := 'SEARCH OTHER INP EPIS';
                SELECT e.id_episode, e.id_patient, e.id_visit
                  INTO l_other_id_episode, l_other_id_patient, l_other_id_visit
                  FROM epis_ext_sys ees
                  JOIN episode e
                    ON e.id_episode = ees.id_episode
                 WHERE ees.value = i_id_episode_ext -- Same value
                   AND ees.id_institution = i_id_prof_intf.institution
                   AND ees.id_epis_type = pk_alert_constant.g_epis_type_inpatient
                   AND e.id_prev_episode IS NULL -- No data for previous episode
                   AND e.id_visit <> l_id_visit -- A different visit
                   AND e.flg_status IN (pk_alert_constant.g_active, pk_alert_constant.g_inactive)
                   AND rownum = 1;
            EXCEPTION
                WHEN OTHERS THEN
                    l_other_id_episode := NULL;
                    l_other_id_patient := NULL;
                    l_other_id_visit   := NULL;
            END;
        
            IF l_other_id_episode IS NOT NULL -- Found another episode. This episode's data must be merged
            THEN
                IF l_pat <> nvl(l_other_id_patient, 0)
                THEN
                    -- If patient ID does not match, raise an error.
                    g_error := 'ERROR: ID_PATIENT DOES NOT MATCH';
                    RAISE OTHERS;
                END IF;
            
                -- Search for episodes other than the INP episode
                g_error := 'SEARCH OTHER EPIS';
                SELECT e.id_episode
                  BULK COLLECT
                  INTO l_tab_other_epis
                  FROM episode e
                 WHERE e.id_visit = l_other_id_visit
                   AND e.id_prev_episode = l_other_id_episode;
            
                IF l_tab_other_epis.exists(1)
                THEN
                    -- Update visit of the related episodes
                    g_error := 'LOOP UPDATE ID_VISIT';
                    pk_alertlog.log_info(text            => g_error,
                                         object_name     => g_package_name,
                                         sub_object_name => l_func_name);
                    FOR i IN l_tab_other_epis.first .. l_tab_other_epis.last
                    LOOP
                        ts_episode.upd(id_episode_in => l_tab_other_epis(i),
                                       id_visit_in   => l_id_visit,
                                       id_visit_nin  => FALSE,
                                       rows_out      => l_rowids);
                    END LOOP;
                END IF;
            
                g_error := 'GET ID_PREV_EPIS_TYPE';
                SELECT epis.id_epis_type
                  INTO l_id_prev_epis_type
                  FROM episode epis
                 WHERE epis.id_episode = i_id_prev_episode;
            
                -- Update visit and previous episode of the previously created inpatient episode
                g_error := 'UPDATE EPISODE';
                ts_episode.upd(id_episode_in         => l_other_id_episode,
                               id_visit_in           => l_id_visit,
                               id_visit_nin          => FALSE,
                               id_prev_episode_in    => i_id_prev_episode,
                               id_prev_episode_nin   => FALSE,
                               id_prev_epis_type_in  => l_id_prev_epis_type,
                               id_prev_epis_type_nin => FALSE,
                               rows_out              => l_rowids);
            
                t_data_gov_mnt.process_update(i_lang         => i_lang,
                                              i_prof         => i_id_prof_intf,
                                              i_table_name   => 'EPISODE',
                                              i_rowids       => l_rowids,
                                              i_list_columns => table_varchar('ID_VISIT',
                                                                              'ID_PREV_EPISODE',
                                                                              'ID_PREV_EPIS_TYPE'),
                                              o_error        => o_error);
            
                l_rowids := table_varchar();
            
                -- Replace INP episode ADT data and verify connetction with the previous episode.
                g_error := 'UPDATE INP EPISODE ADT DATA';
                IF NOT pk_adt.replace_visit_adt(i_lang              => i_lang,
                                                i_prof              => i_id_prof_intf,
                                                i_id_episode        => l_other_id_episode,
                                                i_prev_id_visit     => l_id_visit,
                                                i_prev_id_epis_type => pk_alert_constant.g_epis_type_emergency,
                                                o_error             => o_error)
                THEN
                    RAISE l_internal_error;
                END IF;
            
                -- Delete visit in ADT specific tables
                g_error := 'CALL TO PK_ADT.DELETE_ADT_VISIT';
                IF NOT pk_adt.delete_adt_visit(i_lang       => i_lang,
                                               i_prof       => i_id_prof_intf,
                                               i_visit_temp => l_other_id_visit,
                                               i_visit      => l_id_visit,
                                               o_error      => o_error)
                THEN
                    RAISE OTHERS;
                END IF;
            
                g_error := 'CALL pk_vital_sign.merge_vs_visit_ea_dup';
                IF NOT pk_vital_sign.merge_vs_visit_ea_dup(i_lang           => i_lang,
                                                           i_prof           => i_id_prof_intf,
                                                           i_patient        => l_pat,
                                                           i_id_visit       => l_id_visit,
                                                           i_other_id_visit => l_other_id_visit,
                                                           o_error          => o_error)
                THEN
                    RAISE l_internal_error;
                END IF;
            
                -- Update all VISIT child tables before deleting record
                g_error := 'UPDATE CHILD TABLES - ID_VISIT';
                FOR all_tbs IN (SELECT DISTINCT 'update ' || m1.table_name || ' set ' || mc1.column_name ||
                                                ' = :i_id_visit where ' || mc1.column_name || ' = :i_id_visit_temp' query
                                  FROM all_constraints m1
                                  JOIN all_cons_columns mc1
                                    ON mc1.constraint_name = m1.constraint_name
                                   AND m1.table_name = mc1.table_name
                                  JOIN all_cons_columns rc1
                                    ON rc1.constraint_name = m1.r_constraint_name
                                 WHERE rc1.table_name = 'VISIT'
                                   AND m1.table_name <> 'VISIT_ADT')
                LOOP
                    g_error := 'EXEC ' || all_tbs.query;
                    EXECUTE IMMEDIATE all_tbs.query
                        USING l_id_visit, l_other_id_visit;
                END LOOP;
            
                -- Permanently delete previous visit record
                g_error := 'DELETE OLD VISIT';
                ts_visit.del(id_visit_in => l_other_id_visit, rows_out => l_rowids);
            
                t_data_gov_mnt.process_delete(i_lang       => i_lang,
                                              i_prof       => i_id_prof_intf,
                                              i_table_name => 'VISIT',
                                              i_rowids     => l_rowids,
                                              o_error      => o_error);
            
                -- Exit method, previously created inpatient episode (and subsequent episides) was updated.
                o_id_episode := l_other_id_episode;
                o_id_patient := l_pat;
            
                RETURN TRUE;
            
            END IF;
        END IF;
    
        IF i_id_episode IS NULL
        THEN
            g_error    := 'GET CURSOR C_EPIS_SEQ (1)';
            l_seq_epis := ts_episode.next_key;
        ELSE
            g_error    := 'GET CURSOR C_EPIS_SEQ (2)';
            l_seq_epis := i_id_episode;
        END IF;
    
        g_error := 'GET ID_CLINICAL_SERVICE WITH ID_DEP_CLIN_SERV: ' || i_id_dep_clin_serv;
        BEGIN
            SELECT dcs.id_clinical_service, d.id_department, d.id_dept
              INTO l_id_clinical_service, l_id_department, l_id_dept
              FROM dep_clin_serv dcs, department d
             WHERE dcs.id_dep_clin_serv = i_id_dep_clin_serv
               AND dcs.id_department = d.id_department;
        EXCEPTION
            WHEN OTHERS THEN
                l_id_clinical_service := -1;
                l_id_department       := -1;
                l_id_dept             := -1;
        END;
    
        IF i_id_dep_clin_serv IS NOT NULL
        THEN
            -- Sala por defeito
            g_error := 'GET CURSOR C_EPIS_ROOM';
            OPEN c_epis_room(l_id_epis_type, i_id_dep_clin_serv);
            FETCH c_epis_room
                INTO l_room, l_rank;
            CLOSE c_epis_room;
        END IF;
    
        g_error := 'CALL TO PK_BARCODE.GENERATE_BARCODE';
        IF NOT pk_barcode.generate_barcode(i_lang         => i_lang,
                                           i_barcode_type => 'P',
                                           i_institution  => i_id_prof_intf.institution,
                                           i_software     => i_id_prof_intf.software,
                                           o_barcode      => l_barcode,
                                           o_error        => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        g_error := 'INSERT INTO EPISODE';
        ts_episode.ins(id_episode_in              => l_seq_epis,
                       id_visit_in                => i_id_visit,
                       id_patient_in              => l_pat,
                       id_clinical_service_in     => l_id_clinical_service,
                       id_department_in           => l_id_department,
                       id_dept_in                 => l_id_dept,
                       dt_begin_tstz_in           => nvl(i_dt_begin, l_sysdate_tstz),
                       id_epis_type_in            => l_id_epis_type,
                       flg_status_in              => CASE
                                                         WHEN i_order_set = pk_alert_constant.g_yes THEN
                                                          pk_admission_request.g_flg_status_pd
                                                         ELSE
                                                          g_episode_flg_status_active
                                                     END,
                       flg_type_in                => nvl(i_flg_type, g_epis_temporary),
                       id_prev_episode_in         => i_id_prev_episode,
                       id_prev_epis_type_in       => l_id_epis_type_prev,
                       flg_ehr_in                 => nvl(i_flg_ehr, pk_alert_constant.g_no),
                       id_cs_requested_in         => -1,
                       id_department_requested_in => -1,
                       id_dept_requested_in       => -1,
                       barcode_in                 => l_barcode,
                       dt_creation_in             => nvl(i_dt_creation, l_sysdate_tstz),
                       id_institution_in          => l_instit,
                       flg_migration_in           => nvl(i_flg_migration, 'A'),
                       flg_compulsory_in          => i_flg_compulsory,
                       id_compulsory_reason_in    => i_id_compulsory_reason,
                       compulsory_reason_in       => i_compulsory_reason,
                       rows_out                   => l_rowids);
    
        g_error := 'PROCESS INSERT';
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => i_id_prof_intf,
                                      i_table_name => 'EPISODE',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        g_error  := 'UPDATE VISIT'; -- Visit needs to be activated
        l_rowids := table_varchar();
        ts_visit.upd(flg_status_in   => CASE
                                            WHEN i_order_set = pk_alert_constant.g_yes THEN
                                             pk_admission_request.g_flg_status_pd
                                            ELSE
                                             pk_visit.g_visit_active
                                        END,
                     flg_status_nin  => FALSE,
                     dt_end_tstz_in  => NULL,
                     dt_end_tstz_nin => FALSE,
                     where_in        => 'id_visit = ' || i_id_visit || ' AND flg_status != ''' || pk_visit.g_visit_active ||
                                        ''' ',
                     rows_out        => l_rowids);
    
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_id_prof_intf,
                                      i_table_name   => 'VISIT',
                                      i_rowids       => l_rowids,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('FLG_STATUS', 'DT_END_TSTZ'));
    
        -- ALERT-41412: AS (03-06-2011)
        g_error := 'CALL PK_ADVANCED_DIRECTIVES.SET_RECURR_PLAN';
        IF NOT pk_advanced_directives.set_recurr_plan(i_lang        => i_lang,
                                                      i_prof        => i_id_prof_intf,
                                                      i_patient     => l_pat,
                                                      i_new_episode => l_seq_epis,
                                                      o_error       => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
        -- END ALERT-41412
    
        o_id_episode := l_seq_epis;
        o_id_patient := l_pat;
    
        g_error := 'CALL TO SET_EPIS_EXT_SYS';
        IF NOT set_epis_ext_sys(i_lang              => i_lang,
                                i_prof              => i_id_prof_intf,
                                i_id_episode        => l_seq_epis,
                                i_id_episode_ext    => i_id_episode_ext,
                                i_id_prev_episode   => i_id_prev_episode,
                                i_id_epis_type      => l_id_epis_type,
                                i_id_epis_type_prev => l_id_epis_type_prev,
                                i_id_external_sys   => i_id_external_sys,
                                i_flg_unknow        => l_flg_unknow,
                                o_error             => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        g_error := 'GET SEQ_EPIS_INSTITUTION.NEXTVAL';
        SELECT seq_epis_institution.nextval
          INTO l_seq_epis_inst
          FROM dual;
    
        g_error := 'INSERT INTO EPIS_INSTITUTION';
        INSERT INTO epis_institution
            (id_epis_institution, id_institution, id_episode)
        VALUES
            (l_seq_epis_inst, l_instit, o_id_episode);
    
        -- José Brito 04/11/2008 Fill EPIS_INFO.ID_TRIAGE_COLOR with generic color
        -- Type of tirage used in current institution
        g_error := 'GET NO TRIAGE COLOR';
        BEGIN
            SELECT tco.id_triage_color
              INTO l_no_triage_color
              FROM triage_color tco, triage_type tt
             WHERE tco.id_triage_type = tt.id_triage_type
               AND tt.id_triage_type = pk_edis_triage.get_triage_type(i_lang, i_id_prof_intf, o_id_episode)
               AND tco.flg_type = 'S'
               AND rownum < 2;
        EXCEPTION
            WHEN no_data_found THEN
                RAISE no_data_found;
            WHEN OTHERS THEN
                RAISE OTHERS;
        END;
    
        g_error := 'INSERT INTO EPIS_INFO';
        ts_epis_info.ins(id_episode_in => l_seq_epis,
                         -- Bed can only be updated if allocation happens with success, this cannot be done in this place!
                         --id_bed_in               => i_id_bed, --Where episode should be allocated
                         -- This update happens inside BMNG function.
                         id_schedule_in            => nvl(i_id_sched, -1),
                         id_room_in                => nvl(i_id_room, l_room), --Physical location of the patient
                         flg_unknown_in            => l_flg_unknow,
                         flg_status_in             => g_epis_info_efectiv,
                         id_dep_clin_serv_in       => i_id_dep_clin_serv, --Information correspondent with responsable service
                         id_first_dep_clin_serv_in => i_id_dep_clin_serv,
                         id_patient_in             => l_pat,
                         id_software_in            => g_soft_inp,
                         triage_acuity_in          => pk_alert_constant.g_color_gray,
                         triage_color_text_in      => pk_alert_constant.g_color_white,
                         triage_rank_acuity_in     => pk_alert_constant.g_rank_acuity,
                         id_triage_color_in        => l_no_triage_color,
                         rows_out                  => l_rowid_ei);
    
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => i_id_prof_intf,
                                      i_table_name => 'EPIS_INFO',
                                      i_rowids     => l_rowid_ei,
                                      o_error      => o_error);
    
        g_error := 'CALL pk_hand_off_api.set_overall_responsability. i_id_prof_resp: ' || i_id_prof_resp.id;
        IF i_id_prof_resp.id IS NOT NULL
           AND NOT pk_hand_off_api.set_overall_responsability(i_lang              => i_lang,
                                                              i_prof              => i_id_prof_intf,
                                                              i_id_prof_admitting => i_id_prof_resp,
                                                              i_id_dep_clin_serv  => i_id_dep_clin_serv,
                                                              i_id_episode        => l_seq_epis,
                                                              i_dt_reg            => i_dt_creation_resp,
                                                              o_error             => o_error)
        THEN
            RETURN FALSE; -- direct return in order to keep possible user error messages
        END IF;
    
        --if no Alert scheduler is being used simulate the schedule
        g_error := 'CALL set_schedule_inp_bed for id_episode: ' || o_id_episode;
        IF NOT set_schedule_inp_bed(i_lang       => i_lang,
                                    i_prof       => i_id_prof_intf,
                                    i_id_episode => o_id_episode,
                                    i_id_room    => nvl(i_id_room, l_room),
                                    i_id_bed     => i_id_bed,
                                    i_dt_begin   => nvl(i_dt_begin, l_sysdate_tstz),
                                    o_error      => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        IF i_admition_notes IS NOT NULL
        THEN
            --only for US markets create H&P Note
            IF pk_alert_constant.g_id_market_usa = pk_prof_utils.get_prof_market(i_prof => i_id_prof_intf)
            THEN
            
                g_error := 'CALL create_handp_note_int FOR id_episode = ' || l_seq_epis;
                IF NOT create_handp_note_int(i_lang               => i_lang,
                                             i_prof               => i_id_prof_intf,
                                             i_id_episode         => l_seq_epis,
                                             i_dt_admission_notes => i_dt_admition_notes,
                                             i_admission_notes    => i_admition_notes,
                                             o_error              => o_error)
                THEN
                    RETURN FALSE;
                END IF;
            ELSE
                --all the others markets
                g_error := 'CALL PK_CLINICAL_INFO.SET_EPIS_ANAMNESIS_INT FOR ID_EPISODE = ' || l_seq_epis;
                IF NOT pk_clinical_info.set_epis_anamnesis_int(i_lang                   => i_lang,
                                                               i_episode                => l_seq_epis,
                                                               i_prof                   => i_id_prof_intf,
                                                               i_desc                   => i_admition_notes,
                                                               i_flg_type               => pk_clinical_info.g_complaint,
                                                               i_flg_type_mode          => pk_clinical_info.g_flg_edition_type_new,
                                                               i_id_epis_anamnesis      => NULL,
                                                               i_id_diag                => NULL,
                                                               i_flg_class              => NULL,
                                                               i_prof_cat_type          => 'D',
                                                               i_flg_rep_by             => NULL,
                                                               i_dt_epis_anamnesis_tstz => i_dt_admition_notes,
                                                               o_id_epis_anamnesis      => l_id_epis_anamnesis,
                                                               o_error                  => o_error)
                THEN
                    RETURN FALSE;
                END IF;
            END IF;
        END IF;
    
        -- Insert bed management information
        -- LMAIA 12-11-2009
        g_error := 'BEFORE ID_BED USAGE: ID_BED = ' || i_id_bed;
        IF i_id_bed IS NOT NULL
        THEN
            BEGIN
                g_error := 'GET BED ROOM AND DEPARTMENT: ID_BED = ' || i_id_bed;
                SELECT b.id_room, r.id_department
                  INTO l_id_room_allocation, l_id_dep_allocation
                  FROM bed b
                 INNER JOIN room r
                    ON (r.id_room = b.id_room)
                 WHERE b.id_bed = i_id_bed;
            EXCEPTION
                WHEN OTHERS THEN
                    RAISE err_create_bmng_alloc;
            END;
        
            -- Call Bed management functions
            g_error := 'CALL PK_BMNG_PBL.SET_BED_MANAGEMENT FOR ID_EPISODE = ' || l_seq_epis;
            IF NOT pk_bmng_pbl.set_bed_management(i_lang                   => i_lang,
                                                  i_prof                   => i_id_prof_intf,
                                                  i_id_bmng_action         => table_number(NULL),
                                                  i_id_department          => table_number(l_id_dep_allocation),
                                                  i_id_room                => table_number(l_id_room_allocation),
                                                  i_id_bed                 => table_number(i_id_bed),
                                                  i_id_bmng_reason         => table_number(NULL),
                                                  i_id_bmng_allocation_bed => table_number(NULL),
                                                  i_flg_target_action      => pk_bmng_constant.g_bmng_act_flg_target_b,
                                                  i_flg_status             => pk_bmng_constant.g_bmng_act_flg_status_a,
                                                  i_nch_capacity           => table_number(NULL),
                                                  i_action_notes           => table_varchar(NULL),
                                                  i_dt_begin_action        => table_varchar(pk_date_utils.date_send_tsz(i_lang,
                                                                                                                        nvl(i_dt_begin,
                                                                                                                            l_sysdate_tstz),
                                                                                                                        i_id_prof_resp)),
                                                  i_dt_end_action          => table_varchar(pk_date_utils.date_send_tsz(i_lang,
                                                                                                                        nvl(i_dt_disch_sched,
                                                                                                                            l_sysdate_tstz),
                                                                                                                        i_id_prof_resp)),
                                                  i_id_episode             => table_number(l_seq_epis),
                                                  i_id_patient             => table_number(l_pat),
                                                  i_nch_hours              => NULL,
                                                  i_flg_allocation_nch     => NULL,
                                                  i_desc_bed               => NULL,
                                                  i_id_bed_type            => table_number(NULL),
                                                  i_dt_discharge_schedule  => NULL,
                                                  i_bed_dep_clin_serv      => NULL,
                                                  i_flg_origin_action_ux   => pk_bmng_constant.g_bmng_flg_origin_ux_p, --It is only possible allocate to existing beds
                                                  i_reason_notes           => NULL,
                                                  i_transaction_id         => l_transaction_id,
                                                  i_dt_creation            => i_dt_creation_allocation,
                                                  o_id_bmng_allocation_bed => l_id_bmng_allocation_bed,
                                                  o_id_bed                 => l_id_bed,
                                                  o_bed_allocation         => o_bed_allocation,
                                                  o_exception_info         => o_exception_info,
                                                  o_error                  => o_error)
            
            THEN
                IF o_bed_allocation = pk_alert_constant.g_no
                THEN
                    g_error := 'o_bed_allocation = ''N''';
                    NULL; -- Continue... (because it is supposed to ignore this error when doing allocation inside an episode creation)
                ELSE
                    g_error := 'o_bed_allocation = ' || o_bed_allocation;
                    RETURN FALSE;
                END IF;
            END IF;
        END IF;
    
        -- Luis Maia 04-04-2008
        -- set the default episode touch option templates (INP: g_flg_type_clin_serv_type=‘S’; OUTP, CARE e PP: g_flg_type_clin_serv_type=‘A’)
        g_error := 'CALL PK_TOUCH_OPTION.SET_DEFAULT_EPIS_DOC_TEMPLATES = ' || l_seq_epis;
        IF NOT pk_touch_option.set_default_epis_doc_templates(i_lang => i_lang,
                                                              --here we have to send the inp software because it is necessary to copy to the new created episode the templates configures to the inp software,
                                                              --even thought when the episode is being created in another software (for instance: discharge edis-inp)
                                                              i_prof               => profissional(i_id_prof_intf.id,
                                                                                                   i_id_prof_intf.institution,
                                                                                                   g_soft_inp),
                                                              i_episode            => l_seq_epis,
                                                              i_flg_type           => g_flg_template_type,
                                                              o_epis_doc_templates => l_epis_doc_template,
                                                              o_error              => o_error)
        THEN
            RAISE err_default_template;
        END IF;
    
        -- CRS 2006/07/18
        g_error := 'BEFORE ID_HEALTH_PLAN USAGE: ID_HEALTH_PLAN = ' || i_health_plan;
        IF i_health_plan IS NOT NULL
        THEN
        
            g_error := 'OPEN C_PAT_HPLAN';
            OPEN c_pat_hplan;
            FETCH c_pat_hplan
                INTO l_pat_hplan;
            g_found := c_pat_hplan%FOUND;
            CLOSE c_pat_hplan;
        
            IF g_found
            THEN
                g_error := 'INSERT INTO EPIS_HEALTH_PLAN';
                INSERT INTO epis_health_plan
                    (id_epis_health_plan, id_episode, id_pat_health_plan)
                VALUES
                    (seq_epis_health_plan.nextval, l_seq_epis, l_pat_hplan);
            END IF;
        END IF;
    
        --ALERT-70086, ASantos 27-01-2010
        g_error := 'SET_VISIT_DIAGNOSIS - INP EPISODE';
        IF NOT pk_diagnosis_core.set_visit_diagnosis(i_lang               => i_lang,
                                                     i_prof               => i_id_prof_intf,
                                                     i_episode            => o_id_episode,
                                                     i_tbl_epis_diagnosis => NULL,
                                                     o_error              => o_error)
        THEN
            g_error := 'SET_VISIT_DIAGNOSIS ERROR - INP - ID_EPISODE: ' || o_id_episode || '; LOG_ID: ' ||
                       o_error.log_id;
            pk_alertlog.log_error(text            => g_error,
                                  object_name     => g_package_name,
                                  sub_object_name => 'CALL_INS_EPISODE_INT');
            RAISE OTHERS;
        END IF;
    
        l_sys_alert_event.id_sys_alert   := 337;
        l_sys_alert_event.id_software    := pk_alert_constant.g_soft_inpatient;
        l_sys_alert_event.id_institution := i_id_prof_intf.institution;
        l_sys_alert_event.id_episode     := o_id_episode;
        l_sys_alert_event.id_record      := o_id_episode;
        l_sys_alert_event.dt_record      := l_sysdate_tstz;
    
        --Insere evento na tabela de alertas
        g_error := 'INSERT INTO SYS_ALERT_EVENT';
        IF NOT pk_alerts.insert_sys_alert_event(i_lang            => i_lang,
                                                i_prof            => profissional(i_id_prof_intf.id,
                                                                                  i_id_prof_intf.institution,
                                                                                  pk_alert_constant.g_soft_inpatient),
                                                i_sys_alert_event => l_sys_alert_event,
                                                i_flg_type_dest   => 'C',
                                                o_error           => o_error)
        THEN
            RAISE OTHERS;
        END IF;
    
        IF l_vte_reassessment != 0
        THEN
            l_sys_alert_event.id_sys_alert := 338;
            l_sys_alert_event.dt_record    := pk_date_utils.add_days_to_tstz(l_sysdate_tstz, l_vte_reassessment);
        
            --Insere evento na tabela de alertas
            g_error := 'INSERT INTO SYS_ALERT_EVENT';
            IF NOT pk_alerts.insert_sys_alert_event(i_lang            => i_lang,
                                                    i_prof            => profissional(i_id_prof_intf.id,
                                                                                      i_id_prof_intf.institution,
                                                                                      pk_alert_constant.g_soft_inpatient),
                                                    i_sys_alert_event => l_sys_alert_event,
                                                    i_flg_type_dest   => 'C',
                                                    o_error           => o_error)
            THEN
                RAISE OTHERS;
            END IF;
        END IF;
    
        IF i_flg_surgery = pk_alert_constant.g_yes
        THEN
            g_error := 'INSERT SURGERY EPISODE';
            IF NOT pk_sr_visit.create_all_surgery(i_lang         => i_lang,
                                                  i_patient      => l_pat,
                                                  i_prof         => i_id_prof_intf,
                                                  i_prev_episode => l_seq_epis,
                                                  i_type         => i_type,
                                                  i_dt_surg      => i_dt_surgery,
                                                  i_room         => NULL,
                                                  i_duration     => NULL,
                                                  i_flg_ehr      => g_flg_ehr_n,
                                                  o_episode_new  => l_o_sr_episode,
                                                  o_schedule     => l_schedule,
                                                  o_error        => o_error)
            THEN
                RAISE err_create_sr_episode;
            END IF;
        END IF;
    
        IF o_id_episode IS NOT NULL
        THEN
            g_error := 'CALL PK_PROCEDURES_EXTERNAL_API_DB.SET_GRID_TASK_PROCEDURES';
            IF NOT pk_procedures_external_api_db.set_grid_task_procedures(i_lang    => i_lang,
                                                                          i_prof    => NULL,
                                                                          i_episode => o_id_episode,
                                                                          o_error   => o_error)
            THEN
                RAISE OTHERS;
            END IF;
        END IF;
    
        IF i_transaction_id IS NULL
        THEN
            pk_schedule_api_upstream.do_commit(l_transaction_id, i_id_prof_resp);
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN err_default_template THEN
            DECLARE
                l_error_in      t_error_in := t_error_in();
                l_error_message VARCHAR2(4000) := pk_message.get_message(i_lang, 'COMMON_M001');
            BEGIN
                l_error_in.set_all(i_lang,
                                   'ERR_DEFAULT_TEMPLATE',
                                   l_error_message,
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   'CALL_INS_EPISODE_INT');
                l_error_in.set_action('Error when checking templates', 'S');
                g_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            END;
            RETURN FALSE;
        
        WHEN err_create_sr_episode THEN
            DECLARE
                l_error_in      t_error_in := t_error_in();
                l_error_message VARCHAR2(4000) := pk_message.get_message(i_lang, 'COMMON_M001');
            BEGIN
                l_error_in.set_all(i_lang,
                                   'ERR_CREATE_SR_EPISODE',
                                   l_error_message,
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   'CALL_INS_EPISODE_INT');
                l_error_in.set_action('Error when reating an surgery episode', 'S');
                g_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            END;
            RETURN FALSE;
        
        WHEN err_create_bmng_alloc THEN
            DECLARE
                l_error_in      t_error_in := t_error_in();
                l_error_message VARCHAR2(4000) := pk_message.get_message(i_lang, 'COMMON_M001');
            BEGIN
                l_error_in.set_all(i_lang,
                                   'ERR_CREATE_BMNG_ALLOC',
                                   l_error_message,
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   'CALL_INS_EPISODE_INT');
                l_error_in.set_action('Error: Bed not correctly parametrized', 'S');
                g_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            END;
            RETURN FALSE;
        
        WHEN no_data_found THEN
            DECLARE
                l_error_in      t_error_in := t_error_in();
                l_error_message VARCHAR2(4000) := pk_message.get_message(i_lang, 'COMMON_M001');
            BEGIN
                l_error_in.set_all(i_lang,
                                   'NO_DATA_FOUND',
                                   l_error_message,
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   'CALL_INS_EPISODE_INT');
                l_error_in.set_action('No data found', 'S');
                g_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            END;
            RETURN FALSE;
        
        WHEN l_internal_error THEN
            pk_alert_exceptions.process_error(i_lang,
                                              o_error.ora_sqlcode,
                                              o_error.ora_sqlerrm,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CALL_INS_EPISODE_INT',
                                              o_error);
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CALL_INS_EPISODE_INT',
                                              o_error);
            RETURN FALSE;
    END call_ins_episode_int;

    /*******************************************************************************************************************************************
    * CALL_UPD_EPISODE_INT            Update an episode for an episode with send parameters.
    * 
    * @param I_LANG                   Language ID for translations    
    * @param I_PROFESSIONAL           New responsable professional vector of information
    * @param I_PROF_INTF              Interface professional vector of information
    * @param I_ID_EPISODE             EPISODE identifier that should be associated with new episode    
    * @param I_ID_DEP_CLIN_SERV       DEP_CLIN_SERV identifier that should be associated with the episode
    * @param I_ID_FIRST_DEP_CLIN_SERV DEP_CLIN_SERV first identifier that should be associated with the episode
    * @param I_ID_ROOM                ROOM identifier that should be associated with new episode
    * @param I_ID_BED                 BED identifier that shoul be associated with new episode
    * @param I_FLG_BED_TYPE           BED type ('P'-permanent; 'T'-temporary)
    * @param I_DESC_BED               Description associated with this bed
    * @param I_DT_BEGIN               Episode begin date    
    * @param I_FLG_EHR                Type of EHR episode ('N' - Normal episode, 'E' - EHR event, 'S' - Episode preparation of a scheduled event)    
    * @param I_ADMITION_NOTES         Admition notes
    * @param I_DT_ADMISSION_NOTES     Admition notes Date/Time
    * @param I_ID_PREV_EPISODE        EPISODE identifier that should be associated with new episode (PREV_EPISODE identifier)
    * @param i_transaction_id         remote transaction identifier
    * @param i_allocation_commit      Indicates if bed allocation should sent information to scheduler 3.0 ('Y' - Yes; 'N' - No)
    * @param i_dt_creation_allocation Date in which the bed allocation was done
    * @param i_dt_creation_resp       Hand-off date
    * @param I_FLG_RESP_TYPE          Check if flag main overall responsability is to be set ((E - default) Episode (O) overall - patient responsability)
    * @param O_ID_EPISODE             EPISODE identifier corresponding to created episode
    * @param O_BED_ALLOCATION         Indicates if bed allocation was succeceful ('Y' - Yes; 'N' - No)
    * @param O_EXCEPTION_INFO         Error message to be displayed to the user.
    * @param O_ERROR                  If an error accurs, this parameter will have information about the error
    * 
    * @return                         Returns TRUE if success, otherwise returns FALSE
    *     
    * @raises err_duplicate_prev_episode      Error when checking previous episode    
    * @raises err_null_episode                Error when the inputed id episode is null
    * @raises no_data_found                   No data found
    * @raises err_temporary_bed               Null i_id_bed with permanent bed type.
    * @raises err_permanent_bed               Permanent bed not found
    * @raises                                 PL/SQL generic erro "OTHERS"
    * 
    * @author                                 Sofia Mendes
    * @version                                2.5.0.7
    * @since                                  2009/10/01
    *
    *******************************************************************************************************************************************/
    FUNCTION call_upd_episode_int
    (
        i_lang                         IN language.id_language%TYPE,
        i_id_professional              IN profissional,
        i_prof_intf                    IN profissional,
        i_id_episode                   IN episode.id_episode%TYPE,
        i_id_dep_clin_serv             IN epis_info.id_dep_clin_serv%TYPE,
        i_id_first_dep_clin_serv       IN epis_info.id_first_dep_clin_serv%TYPE,
        i_id_room                      IN epis_info.id_room%TYPE,
        i_id_bed                       IN epis_info.id_bed%TYPE DEFAULT NULL,
        i_flg_type                     IN bed.flg_type%TYPE DEFAULT pk_bmng_constant.g_bmng_bed_flg_type_p,
        i_desc_bed                     IN bed.desc_bed%TYPE DEFAULT NULL,
        i_dt_begin                     IN episode.dt_begin_tstz%TYPE,
        i_flg_ehr                      IN episode.flg_ehr%TYPE DEFAULT 'N',
        i_admition_notes               IN epis_anamnesis.desc_epis_anamnesis%TYPE,
        i_dt_admission_notes           IN epis_anamnesis.dt_epis_anamnesis_tstz%TYPE DEFAULT NULL,
        i_id_prev_episode              IN episode.id_prev_episode%TYPE,
        i_transaction_id               IN VARCHAR2,
        i_allocation_commit            IN VARCHAR2,
        i_dt_disch_sched               IN discharge_schedule.dt_discharge_schedule%TYPE,
        i_dt_creation_allocation       IN bmng_allocation_bed.dt_creation%TYPE,
        i_dt_creation_resp             IN epis_prof_resp.dt_execute_tstz%TYPE,
        i_flg_resp_type                IN epis_multi_prof_resp.flg_resp_type%TYPE DEFAULT NULL,
        i_epis_flg_type                IN episode.flg_type%TYPE DEFAULT NULL,
        i_flg_allow_bed_alloc_inactive IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        o_bed_allocation               OUT VARCHAR2,
        o_exception_info               OUT sys_message.desc_message%TYPE,
        o_error                        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_rowids table_varchar;
    
        l_id_epis_type NUMBER;
        l_count        NUMBER;
        l_rowid_ei     table_varchar;
        l_bed          PLS_INTEGER;
        l_id_room      room.id_room%TYPE;
        l_id_rank      room.rank%TYPE;
    
        l_id_prev_episode     episode.id_prev_episode%TYPE;
        l_dt_begin_tstz       episode.dt_begin_tstz%TYPE;
        l_flg_ehr             episode.flg_ehr%TYPE;
        l_flg_type            episode.flg_type%TYPE;
        l_flg_bed_type        bed.flg_type%TYPE;
        l_transaction_id      VARCHAR2(4000);
        l_id_profile_template profile_template.id_profile_template%TYPE;
        l_flg_profile         profile_template.flg_profile%TYPE;
    
        err_duplicate_prev_episode EXCEPTION;
        err_null_episode           EXCEPTION;
        err_permanent_bed          EXCEPTION;
        err_temporary_bed          EXCEPTION;
        no_data_found              EXCEPTION;
        OTHERS                     EXCEPTION;
        err_default_template       EXCEPTION;
    
        l_id_epis_anamnesis epis_anamnesis.id_epis_anamnesis%TYPE;
    
        l_epis_doc_template table_number;
        l_id_bed            epis_info.id_bed%TYPE;
        l_flg_unknow        epis_info.flg_unknown%TYPE;
        CURSOR c_epis_room
        (
            l_epis_type     IN epis_type.id_epis_type%TYPE,
            l_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE
        ) IS
            SELECT er.id_room, 0 rank
              FROM epis_type_room er
             WHERE er.id_epis_type = l_epis_type
               AND er.id_institution = i_id_professional.institution
               AND nvl(er.id_dep_clin_serv, 0) = 0
            UNION
            SELECT er.id_room, 1 rank
              FROM epis_type_room er
             WHERE er.id_epis_type = l_epis_type
               AND er.id_institution = i_id_professional.institution
               AND er.id_dep_clin_serv = l_dep_clin_serv
             ORDER BY rank DESC;
    
    BEGIN
        -- gets a new transaction ID and begins the transaction (for the Scheduler 3.0 transactions)
        g_error          := 'CALL PK_SCHEDULE_API_UPSTREAM.BEGIN_NEW_TRANSACTION';
        l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(i_transaction_id, i_id_professional);
    
        --
        IF (i_id_episode IS NULL)
        THEN
            RAISE err_null_episode;
        END IF;
    
        IF (i_id_bed IS NOT NULL AND i_flg_type <> pk_bmng_constant.g_bmng_bed_flg_type_p OR
           i_id_bed IS NULL AND i_flg_type = pk_bmng_constant.g_bmng_bed_flg_type_p)
        THEN
            RAISE err_temporary_bed;
        END IF;
    
        IF (i_id_bed IS NOT NULL)
        THEN
            BEGIN
                SELECT 1
                  INTO l_bed
                  FROM bed b
                 WHERE b.id_bed = i_id_bed;
            EXCEPTION
                WHEN no_data_found THEN
                    RAISE err_permanent_bed;
            END;
        END IF;
    
        --
        g_error := 'GET SYS_CONFIG: ID_EPIS_TYPE_INPATIENT';
        pk_alertlog.log_debug(g_error);
    
        l_id_epis_type := pk_sysconfig.get_config('ID_EPIS_TYPE_INPATIENT', i_id_professional);
    
        g_error := 'VALIDATE IF ALREADY EXISTS ONE INPATIENT EPISODE WITH SAME ID_PREV_EPISODE THAT OTHER NON INPATIENT EPISODE';
        pk_alertlog.log_debug(g_error);
        SELECT COUNT(1)
          INTO l_count
          FROM episode inp, episode prv
         WHERE inp.id_epis_type = l_id_epis_type
           AND inp.id_prev_episode = i_id_prev_episode
           AND inp.id_prev_episode = prv.id_episode
           AND inp.id_visit = prv.id_visit
           AND prv.id_epis_type != l_id_epis_type
           AND inp.flg_status != g_episode_flg_status_canceled;
    
        IF l_count > 0
        THEN
            RAISE err_duplicate_prev_episode;
        END IF;
    
        IF (i_id_episode IS NOT NULL AND
           (i_id_prev_episode IS NOT NULL OR i_flg_ehr IS NOT NULL OR i_dt_begin IS NOT NULL))
        THEN
            g_error := 'SELECT EPISODE DATA FOR ID_EPISODE: ' || i_id_episode;
            pk_alertlog.log_debug(g_error);
            SELECT epi.id_prev_episode, epi.dt_begin_tstz, epi.flg_ehr, epi.flg_type
              INTO l_id_prev_episode, l_dt_begin_tstz, l_flg_ehr, l_flg_type
              FROM episode epi
             WHERE epi.id_episode = i_id_episode;
        
            l_flg_unknow := CASE
                                WHEN i_epis_flg_type = pk_episode.g_flg_def THEN
                                 pk_alert_constant.g_no
                                ELSE
                                 pk_alert_constant.g_yes
                            END;
            g_error      := 'UPDATE EPISODE';
            pk_alertlog.log_debug(g_error);
            ts_episode.upd(id_episode_in       => i_id_episode,
                           id_prev_episode_nin => FALSE,
                           id_prev_episode_in  => nvl(i_id_prev_episode, l_id_prev_episode),
                           dt_begin_tstz_nin   => FALSE,
                           dt_begin_tstz_in    => nvl(i_dt_begin, l_dt_begin_tstz),
                           flg_ehr_nin         => FALSE,
                           flg_ehr_in          => nvl(i_flg_ehr, l_flg_ehr),
                           flg_type_in         => nvl(i_epis_flg_type, l_flg_type),
                           flg_type_nin        => FALSE,
                           rows_out            => l_rowids);
        
            g_error := 'PROCESS UPDATE';
            pk_alertlog.log_debug(g_error);
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof_intf,
                                          i_table_name => 'EPISODE',
                                          i_rowids     => l_rowids,
                                          o_error      => o_error);
        END IF;
    
        IF (i_id_episode IS NOT NULL AND (i_id_dep_clin_serv IS NOT NULL OR i_id_first_dep_clin_serv IS NOT NULL OR
           i_id_room IS NOT NULL OR i_id_professional IS NOT NULL))
        THEN
        
            IF i_id_room IS NULL
               AND i_id_dep_clin_serv IS NOT NULL
            THEN
                OPEN c_epis_room(l_id_epis_type, i_id_dep_clin_serv);
                FETCH c_epis_room
                    INTO l_id_room, l_id_rank;
                CLOSE c_epis_room;
            END IF;
        
            g_error := 'UPDATE EPIS_INFO';
            pk_alertlog.log_debug(g_error);
            ts_epis_info.upd(id_episode_in             => i_id_episode,
                             id_dep_clin_serv_in       => i_id_dep_clin_serv,
                             id_first_dep_clin_serv_in => i_id_first_dep_clin_serv,
                             id_room_in                => nvl(i_id_room, l_id_room),
                             flg_unknown_in            => l_flg_unknow,
                             rows_out                  => l_rowid_ei);
        
            g_error := 'EPIS_INFO PROCESS_UPDATE';
            pk_alertlog.log_debug(g_error);
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof_intf,
                                          i_table_name => 'EPIS_INFO',
                                          i_rowids     => l_rowid_ei,
                                          o_error      => o_error);
        
            -- set the default episode touch option templates (INP: g_flg_type_clin_serv_type=‘S’; OUTP, CARE e PP: g_flg_type_clin_serv_type=‘A’)
            g_error := 'CALL PK_TOUCH_OPTION.SET_DEFAULT_EPIS_DOC_TEMPLATES i_id_episode = ' || i_id_episode;
            pk_alertlog.log_debug(g_error);
            IF NOT pk_touch_option.set_default_epis_doc_templates(i_lang               => i_lang,
                                                                  i_prof               => i_prof_intf,
                                                                  i_episode            => i_id_episode,
                                                                  i_flg_type           => g_flg_template_type,
                                                                  o_epis_doc_templates => l_epis_doc_template,
                                                                  o_error              => o_error)
            THEN
                RAISE err_default_template;
            END IF;
        
            IF i_id_professional.id IS NOT NULL
            THEN
                g_error := 'CALL pk_prof_utils.get_prof_profile_template';
                pk_alertlog.log_debug(g_error);
                l_id_profile_template := pk_prof_utils.get_prof_profile_template(i_id_professional);
            
                g_error := 'GET KIND OF PROFILE. l_id_profile_template: ' || l_id_profile_template;
                pk_alertlog.log_debug(g_error);
                IF NOT pk_hand_off_core.get_flg_profile(i_lang             => i_lang,
                                                        i_prof             => i_id_professional,
                                                        i_profile_template => l_id_profile_template,
                                                        o_flg_profile      => l_flg_profile,
                                                        o_error            => o_error)
                THEN
                    RETURN FALSE;
                END IF;
            
                g_error := 'CALL pk_hand_off_api.set_overall_responsability. l_flg_profile: ' || l_flg_profile;
                pk_alertlog.log_debug(g_error);
                IF l_flg_profile IS NOT NULL
                   AND NOT pk_hand_off_api.set_overall_responsability(i_lang              => i_lang,
                                                                      i_prof              => i_prof_intf,
                                                                      i_id_prof_admitting => i_id_professional,
                                                                      i_id_dep_clin_serv  => i_id_dep_clin_serv,
                                                                      i_id_episode        => i_id_episode,
                                                                      i_dt_reg            => i_dt_creation_resp,
                                                                      i_flg_resp_type     => i_flg_resp_type,
                                                                      o_error             => o_error)
                THEN
                    RETURN FALSE; -- direct return in order to keep possible user error messages
                END IF;
            END IF;
        END IF;
    
        IF (i_admition_notes IS NOT NULL)
        THEN
        
            --only for US markets create H&P Note
            IF pk_alert_constant.g_id_market_usa = pk_prof_utils.get_prof_market(i_prof => i_prof_intf)
            THEN
            
                g_error := 'CALL create_handp_note_int FOR id_episode = ' || i_id_episode;
                IF NOT create_handp_note_int(i_lang               => i_lang,
                                             i_prof               => i_prof_intf,
                                             i_id_episode         => i_id_episode,
                                             i_dt_admission_notes => i_dt_admission_notes,
                                             i_admission_notes    => i_admition_notes,
                                             o_error              => o_error)
                THEN
                    RETURN FALSE;
                END IF;
            ELSE
                --all the others markets
                g_error := 'CALL PK_CLINICAL_INFO.SET_EPIS_ANAMNESIS FOR id_episode = ' || i_id_episode;
                pk_alertlog.log_debug(g_error);
                IF NOT pk_clinical_info.set_epis_anamnesis_int(i_lang                   => i_lang,
                                                               i_episode                => i_id_episode,
                                                               i_prof                   => i_prof_intf,
                                                               i_desc                   => i_admition_notes,
                                                               i_dt_epis_anamnesis_tstz => i_dt_admission_notes,
                                                               i_flg_type               => pk_clinical_info.g_complaint,
                                                               i_flg_type_mode          => pk_clinical_info.g_flg_edition_type_new,
                                                               i_id_epis_anamnesis      => NULL,
                                                               i_id_diag                => NULL,
                                                               i_flg_class              => NULL,
                                                               i_prof_cat_type          => 'D',
                                                               i_flg_rep_by             => NULL,
                                                               o_id_epis_anamnesis      => l_id_epis_anamnesis,
                                                               o_error                  => o_error)
                THEN
                    RETURN FALSE;
                END IF;
            END IF;
        END IF;
    
        IF (i_flg_type IS NULL AND i_id_bed IS NOT NULL)
        THEN
            BEGIN
                SELECT b.flg_type
                  INTO l_flg_bed_type
                  FROM bed b
                 WHERE b.id_bed = i_id_bed;
            EXCEPTION
                WHEN no_data_found THEN
                    l_flg_bed_type := pk_bmng_constant.g_bmng_bed_flg_type_t;
            END;
        ELSE
            l_flg_bed_type := i_flg_type;
        END IF;
    
        IF (i_id_bed IS NOT NULL AND l_flg_bed_type = pk_bmng_constant.g_bmng_bed_flg_type_p OR
           i_id_bed IS NULL AND l_flg_bed_type = pk_bmng_constant.g_bmng_bed_flg_type_t)
        THEN
            g_error := 'CALL PK_BMNG.SET_BMNG_ALLOCATION FOR i_id_bed: ' || i_id_bed || '; i_flg_type: ' ||
                       l_flg_bed_type;
            pk_alertlog.log_debug(g_error);
        
            SELECT ei.id_bed
              INTO l_id_bed
              FROM epis_info ei
             WHERE ei.id_episode = i_id_episode;
        
            IF nvl(l_id_bed, -1) <> i_id_bed
            THEN
                IF NOT pk_bmng.set_bmng_allocation(i_lang                         => i_lang,
                                                   i_prof                         => i_prof_intf,
                                                   i_epis                         => i_id_episode,
                                                   i_id_bed                       => i_id_bed,
                                                   i_id_room                      => i_id_room,
                                                   i_flg_type                     => l_flg_bed_type,
                                                   i_desc_bed                     => i_desc_bed,
                                                   i_transaction_id               => l_transaction_id,
                                                   i_allocation_commit            => i_allocation_commit,
                                                   i_dt_disch_sched               => i_dt_disch_sched,
                                                   i_dt_creation                  => i_dt_creation_allocation,
                                                   i_flg_allow_bed_alloc_inactive => i_flg_allow_bed_alloc_inactive,
                                                   o_bed_allocation               => o_bed_allocation,
                                                   o_exception_info               => o_exception_info,
                                                   o_error                        => o_error)
                THEN
                    IF o_bed_allocation = pk_alert_constant.g_no
                    THEN
                        g_error := 'o_bed_allocation = ''N''';
                        pk_alertlog.log_debug(g_error);
                        NULL; -- Continue... (because it is supposed to ignore this error when doing allocation inside an episode creation)
                    ELSE
                        g_error := 'o_bed_allocation = ' || o_bed_allocation;
                        pk_alertlog.log_debug(g_error);
                        RETURN FALSE;
                    END IF;
                END IF;
            END IF;
        END IF;
    
        IF (i_transaction_id IS NULL)
        THEN
            pk_schedule_api_upstream.do_commit(l_transaction_id, i_id_professional);
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        --
        WHEN err_duplicate_prev_episode THEN
            DECLARE
                l_error_in      t_error_in := t_error_in();
                l_error_message VARCHAR2(4000) := pk_message.get_message(i_lang, 'COMMON_M001');
            BEGIN
                l_error_in.set_all(i_lang,
                                   'ERR_DUPLICATE_PREV_EPISODE',
                                   l_error_message,
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   'CALL_UPD_EPISODE_INT');
                l_error_in.set_action('Error when checking previous episode', 'S');
                g_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            END;
            RETURN FALSE;
            --
        WHEN no_data_found THEN
            DECLARE
                l_error_in      t_error_in := t_error_in();
                l_error_message VARCHAR2(4000) := pk_message.get_message(i_lang, 'COMMON_M001');
            BEGIN
                l_error_in.set_all(i_lang,
                                   'NO_DATA_FOUND',
                                   l_error_message,
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   'CALL_UPD_EPISODE_INT');
                l_error_in.set_action('NULL EPISODE NOT ALLOWED', 'S');
                g_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            END;
            RETURN FALSE;
            --
        WHEN err_null_episode THEN
            DECLARE
                l_error_in      t_error_in := t_error_in();
                l_error_message VARCHAR2(4000) := pk_message.get_message(i_lang, 'COMMON_M001');
            BEGIN
                l_error_in.set_all(i_lang,
                                   'NULL EPISODE',
                                   l_error_message,
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   'CALL_UPD_EPISODE_INT');
                l_error_in.set_action('No data found', 'S');
                g_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            END;
            RETURN FALSE;
            --
        WHEN err_permanent_bed THEN
            DECLARE
                l_error_in      t_error_in := t_error_in();
                l_error_message VARCHAR2(4000) := pk_message.get_message(i_lang, 'COMMON_M001');
            BEGIN
                l_error_in.set_all(i_lang,
                                   'Permanent bed not found - id_bed: ' || i_id_bed,
                                   l_error_message,
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   'CALL_UPD_EPISODE_INT');
                l_error_in.set_action('Permanent bed not found - id_bed: ' || i_id_bed, 'S');
                g_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            END;
            RETURN FALSE;
            --
        WHEN err_temporary_bed THEN
            DECLARE
                l_error_in      t_error_in := t_error_in();
                l_error_message VARCHAR2(4000) := pk_message.get_message(i_lang, 'COMMON_M001');
            BEGIN
                l_error_in.set_all(i_lang,
                                   'Temporary bed - id_bed: ' || i_id_bed || ' i_flg_bed_type: ' || i_flg_type,
                                   l_error_message,
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   'CALL_UPD_EPISODE_INT');
                l_error_in.set_action('Permanent bed not found - id_bed: ' || i_id_bed, 'S');
                g_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            END;
            RETURN FALSE;
            --
        WHEN OTHERS THEN
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CALL_UPD_EPISODE_INT',
                                              o_error);
            RETURN FALSE;
    END call_upd_episode_int;

    /*******************************************************************************************************************************************
    * CALL_INS_EPISODE_DISCH          Create an episode for an patient with send parameters (including dates) and returns id_visit created
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_ID_VISIT               VISIT identifier that should be associated with new episode
    * @param I_PROFESSIONAL           Professional vector of information (professional ID, institution ID, software ID)
    * @param I_EPIS_TYPE              EPIS_TYPE identifier that should be associated with new episode
    * @param I_ID_DEP_CLIN_SERV       DEP_CLIN_SERV identifier that should be associated with new episode
    * @param I_ID_ROOM                ROOM identifier that should be associated with new episode
    * @param I_DT_BEGIN               Episode begin date in (Format: TIMESTAMP WITH LOCAL TIME ZONE)
    * @param I_ID_EPISODE_EXT         EPISODE_EXT identifier that should be associated with new episode
    * @param I_FLG_TYPE               Episode type ('T' - TEMPORARY, 'D' - DEFINITIVE)
    * @param I_TYPE                   Type of surgery ('A' - Ambulatory)
    * @param I_DT_SURGERY             Episode SURGERY date
    * @param I_FLG_SURGERY            Indicates if this episode has an SURGERY episode associated: ('Y' - Yes, 'N' - No)
    * @param I_ID_PREV_EPISODE        EPISODE identifier that should be associated with new episode (PREV_EPISODE identifier)
    * @param i_transaction_id         remote transaction identifier
    * @param O_ID_EPISODE             EPISODE identifier corresponding to created episode
    * @param O_ERROR                  If an error accurs, this parameter will have information about the error
    * 
    * @return                         Returns TRUE if success, otherwise returns FALSE
    * 
    * @raises                         PL/SQL generic erro "OTHERS"
    * 
    * @author                         Luís Maia
    * @version                        2.5.0.5
    * @since                          2009/09/09
    *
    *******************************************************************************************************************************************/
    FUNCTION call_ins_episode_disch
    (
        i_lang                 IN language.id_language%TYPE,
        i_id_visit             IN visit.id_visit%TYPE,
        i_id_professional      IN profissional,
        i_epis_type            IN episode.id_epis_type%TYPE,
        i_id_dep_clin_serv     IN NUMBER,
        i_id_room              IN NUMBER,
        i_dt_begin             IN episode.dt_begin_tstz%TYPE,
        i_id_episode_ext       IN VARCHAR2,
        i_flg_type             IN VARCHAR2,
        i_type                 IN VARCHAR2,
        i_dt_surgery           IN VARCHAR2,
        i_flg_surgery          IN VARCHAR2,
        i_id_prev_episode      IN episode.id_prev_episode%TYPE,
        i_transaction_id       IN VARCHAR2,
        i_flg_compulsory       IN episode.flg_compulsory%TYPE DEFAULT NULL,
        i_id_compulsory_reason IN episode.id_compulsory_reason%TYPE DEFAULT NULL,
        i_compulsory_reason    IN episode.compulsory_reason%TYPE DEFAULT NULL,
        o_id_episode           OUT NUMBER,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id_patient     patient.id_patient%TYPE;
        l_internal_error EXCEPTION;
        l_bed_allocation VARCHAR2(1);
        l_exception_info sys_message.desc_message%TYPE;
        --
        l_transaction_id VARCHAR2(4000);
        l_id_department  department.id_department%TYPE;
    
        l_id_clinical_service clinical_service.id_clinical_service%TYPE;
        l_id_dep_clin_serv    dep_clin_serv.id_dep_clin_serv%TYPE;
        l_id_dept             department.id_dept%TYPE;
        l_rows                table_varchar;
    
        PROCEDURE get_requested_department
        (
            i_id_episode          IN NUMBER,
            o_id_department       OUT NUMBER,
            o_id_clinical_service OUT NUMBER,
            o_id_dep_clin_serv    OUT NUMBER,
            o_id_dept             OUT NUMBER
        ) IS
        
        BEGIN
            BEGIN
                SELECT ei. id_dep_clin_serv, dcs.id_department, id_clinical_service, d.id_dept
                  INTO o_id_dep_clin_serv, o_id_department, o_id_clinical_service, o_id_dept
                  FROM epis_info ei
                  JOIN dep_clin_serv dcs
                    ON ei.id_dep_clin_serv = dcs.id_dep_clin_serv
                  JOIN department d
                    ON dcs.id_department = d.id_department
                 WHERE id_episode = i_id_episode;
            EXCEPTION
                WHEN OTHERS THEN
                    o_id_dep_clin_serv    := -1;
                    o_id_department       := -1;
                    o_id_clinical_service := -1;
                    o_id_dept             := -1;
            END;
        END get_requested_department;
    
    BEGIN
        -- gets a new transaction ID and begins the transaction (for the Scheduler 3.0 transactions)
        g_error          := 'CALL PK_SCHEDULE_API_UPSTREAM.BEGIN_NEW_TRANSACTION';
        l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(i_transaction_id, i_id_professional);
    
        --
        g_error := 'CALL PK_INP_EPISODE.CALL_INS_EPISODE_INT WITH ID_VISIT ' || i_id_visit;
        pk_alertlog.log_debug(g_error);
        IF NOT call_ins_episode_int(i_lang                 => i_lang,
                                    i_id_visit             => i_id_visit,
                                    i_id_prof_resp         => NULL,
                                    i_id_prof_intf         => i_id_professional,
                                    i_id_sched             => NULL,
                                    i_id_episode           => NULL,
                                    i_health_plan          => NULL,
                                    i_id_dep_clin_serv     => i_id_dep_clin_serv,
                                    i_id_room              => i_id_room,
                                    i_dt_begin             => i_dt_begin,
                                    i_dt_creation          => i_dt_begin, --This is the same because dt_creation is the same dt_begin
                                    i_id_episode_ext       => i_id_episode_ext,
                                    i_flg_type             => i_flg_type,
                                    i_flg_ehr              => NULL,
                                    i_type                 => i_type,
                                    i_dt_surgery           => i_dt_surgery,
                                    i_flg_surgery          => i_flg_surgery,
                                    i_admition_notes       => NULL,
                                    i_id_prev_episode      => i_id_prev_episode,
                                    i_id_external_sys      => NULL,
                                    i_flg_migration        => NULL,
                                    i_transaction_id       => l_transaction_id,
                                    i_dt_disch_sched       => NULL,
                                    i_flg_compulsory       => i_flg_compulsory,
                                    i_id_compulsory_reason => i_id_compulsory_reason,
                                    i_compulsory_reason    => i_compulsory_reason,
                                    o_id_episode           => o_id_episode,
                                    o_id_patient           => l_id_patient,
                                    o_bed_allocation       => l_bed_allocation,
                                    o_exception_info       => l_exception_info,
                                    o_error                => o_error)
        THEN
            IF l_bed_allocation = pk_alert_constant.g_no
            THEN
                g_error := 'o_bed_allocation = ''N''';
                pk_alertlog.log_debug(g_error);
                NULL; -- Continue... (because it is supposed to ignore this error when doing allocation inside an episode creation)
            ELSE
                g_error := 'l_bed_allocation = ' || l_bed_allocation;
                pk_alertlog.log_debug(g_error);
                RETURN FALSE; -- direct return in order to keep possible user error messages
            END IF;
        END IF;
        get_requested_department(i_id_prev_episode,
                                 l_id_department,
                                 l_id_clinical_service,
                                 l_id_dep_clin_serv,
                                 l_id_dept);
        ts_episode.upd(id_episode_in              => o_id_episode,
                       id_department_requested_in => l_id_department,
                       id_cs_requested_in         => l_id_clinical_service,
                       id_dept_requested_in       => l_id_dept,
                       rows_out                   => l_rows);
    
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_id_professional,
                                      i_table_name   => 'EPISODE',
                                      i_rowids       => l_rows,
                                      i_list_columns => table_varchar('ID_DEPARTMENT_REQUESTED',
                                                                      'ID_CS_REQUESTED',
                                                                      'ID_DEPT_REQUESTED'),
                                      o_error        => o_error);
        -- SUCCESS
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_internal_error THEN
            pk_alert_exceptions.process_error(i_lang,
                                              o_error.ora_sqlcode,
                                              o_error.err_desc,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CALL_INS_EPISODE_DISCH',
                                              o_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CALL_INS_EPISODE_DISCH',
                                              o_error);
            RETURN FALSE;
    END call_ins_episode_disch;

    /*******************************************************************************************************************************************
    * CALL_INS_EPISODE                Create an episode for an patient with send parameters (including dates) and returns id_visit created
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_ID_VISIT               VISIT identifier that should be associated with new episode
    * @param I_PROF_RESP              Professional that should be responsable for this episode
    * @param I_PROF_INTF              Professional of interfaces that should be associated with current creation registries
    * @param I_ID_SCHED               SCHEDULE identifier that should be associated with new episode
    * @param I_ID_EPISODE             EPISODE identifier that should be associated with new episode
    * @param I_HEALTH_PLAN            HEALTH_PLAN identifier that should be associated with new episode
    * @param I_EPIS_TYPE              EPIS_TYPE identifier that should be associated with new episode
    * @param I_ID_DEP_CLIN_SERV       DEP_CLIN_SERV identifier that should be associated with new episode
    * @param I_ID_ROOM                ROOM identifier that should be associated with new episode
    * @param I_ID_BED                 BED identifier that shoul be associated with new episode
    * @param I_DT_BEGIN               Episode begin date in (Format: TIMESTAMP WITH LOCAL TIME ZONE)
    * @param I_DT_CREATION            Episode creation date in (Format: TIMESTAMP WITH LOCAL TIME ZONE)
    * @param I_ID_EPISODE_EXT         EPISODE_EXT identifier that should be associated with new episode
    * @param I_FLG_TYPE               Episode type ('T' - TEMPORARY, 'D' - DEFINITIVE)
    * @param I_FLG_EHR                Type of EHR episode ('N' - Normal episode, 'E' - EHR event, 'S' - Episode preparation of a scheduled event)
    * @param I_DT_DISCH_SCHED         Espected date for current episode discharge
    * @param I_DT_SURGERY             Episode SURGERY date
    * @param I_FLG_SURGERY            Indicates if this episode has an SURGERY episode associated: ('Y' - Yes, 'N' - No)
    * @param I_ADMITION_NOTES         Admition notes
    * @param I_DT_ADMITION_NOTES      Admition notes Date/Time
    * @param I_ID_PREV_EPISODE        EPISODE identifier that should be associated with new episode (PREV_EPISODE identifier)
    * @param I_ID_EXTERNAL_SYS        EXTERNAL_SYS identifier that should be associated with new episode
    * @param I_FLG_MIGRATION          Shows type of visit ('A' for ALERT visits, 'M' for migrated records, 'T' for test records)
    * @param i_transaction_id         remote transaction identifier
    * @param O_ID_EPISODE             EPISODE identifier corresponding to created episode
    * @param O_BED_ALLOCATION         Indicates if bed allocation was succeceful ('Y' - Yes; 'N' - No)
    * @param O_EXCEPTION_INFO         Error message to be displayed to the user. 
    * @param O_ERROR                  If an error accurs, this parameter will have information about the error
    * 
    * @return                         Returns TRUE if success, otherwise returns FALSE
    * 
    * @value  I_FLG_MIGRATION         {*} 'A'- ALERT visits {*} 'M'- Migrated records {*} 'T'- Test records 
    *
    * @raises                         PL/SQL generic erro "OTHERS"
    * 
    * @author                         Luís Maia
    * @version                        2.5.0.5
    * @since                          2009/09/09
    *
    *******************************************************************************************************************************************/
    FUNCTION call_ins_episode
    (
        i_lang                   IN language.id_language%TYPE,
        i_id_visit               IN visit.id_visit%TYPE,
        i_prof_resp              IN profissional,
        i_prof_intf              IN profissional,
        i_id_sched               IN epis_info.id_schedule%TYPE,
        i_id_episode             IN episode.id_episode%TYPE,
        i_health_plan            IN health_plan.id_health_plan%TYPE,
        i_epis_type              IN episode.id_epis_type%TYPE,
        i_id_dep_clin_serv       IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_id_room                IN room.id_room%TYPE,
        i_id_bed                 IN epis_info.id_bed%TYPE,
        i_dt_begin               IN episode.dt_begin_tstz%TYPE,
        i_dt_creation            IN episode.dt_creation%TYPE,
        i_id_episode_ext         IN epis_ext_sys.value%TYPE,
        i_flg_type               IN episode.flg_type%TYPE,
        i_flg_ehr                IN episode.flg_ehr%TYPE,
        i_dt_disch_sched         IN discharge_schedule.dt_discharge_schedule%TYPE,
        i_dt_surgery             IN VARCHAR2,
        i_flg_surgery            IN VARCHAR2,
        i_admition_notes         IN epis_anamnesis.desc_epis_anamnesis%TYPE,
        i_dt_admition_notes      IN epis_anamnesis.dt_epis_anamnesis_tstz%TYPE DEFAULT NULL,
        i_id_prev_episode        IN episode.id_prev_episode%TYPE,
        i_id_external_sys        IN epis_ext_sys.id_external_sys%TYPE,
        i_flg_migration          IN visit.flg_migration%TYPE,
        i_transaction_id         IN VARCHAR2,
        i_dt_creation_allocation IN bmng_allocation_bed.dt_creation%TYPE DEFAULT NULL,
        i_dt_creation_resp       IN epis_prof_resp.dt_execute_tstz%TYPE DEFAULT NULL,
        o_id_episode             OUT episode.id_episode%TYPE,
        o_bed_allocation         OUT VARCHAR2,
        o_exception_info         OUT sys_message.desc_message%TYPE,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id_patient            patient.id_patient%TYPE;
        l_id_episode            episode.id_episode%TYPE;
        l_id_discharge_schedule discharge_schedule.id_discharge_schedule%TYPE;
        l_transaction_id        VARCHAR2(4000);
        --
        l_internal_error EXCEPTION;
    BEGIN
        -- gets a new transaction ID and begins the transaction (for the Scheduler 3.0 transactions)
        g_error          := 'CALL PK_SCHEDULE_API_UPSTREAM.BEGIN_NEW_TRANSACTION';
        l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(i_transaction_id, i_prof_intf);
    
        -- Creation of new episode
        g_error := 'CALL PK_INP_EPISODE.CALL_INS_EPISODE_INT WITH ID_EPISODE ' || i_id_episode;
        pk_alertlog.log_debug(g_error);
        IF NOT call_ins_episode_int(i_lang                   => i_lang,
                                    i_id_visit               => i_id_visit,
                                    i_id_prof_resp           => i_prof_resp,
                                    i_id_prof_intf           => i_prof_intf,
                                    i_id_sched               => i_id_sched,
                                    i_id_episode             => i_id_episode,
                                    i_health_plan            => i_health_plan,
                                    i_id_dep_clin_serv       => i_id_dep_clin_serv,
                                    i_id_room                => i_id_room,
                                    i_id_bed                 => i_id_bed,
                                    i_dt_begin               => i_dt_begin,
                                    i_dt_creation            => i_dt_creation,
                                    i_id_episode_ext         => i_id_episode_ext,
                                    i_flg_type               => i_flg_type,
                                    i_flg_ehr                => i_flg_ehr,
                                    i_dt_surgery             => i_dt_surgery,
                                    i_flg_surgery            => i_flg_surgery,
                                    i_admition_notes         => i_admition_notes,
                                    i_dt_admition_notes      => i_dt_admition_notes,
                                    i_id_prev_episode        => i_id_prev_episode,
                                    i_id_external_sys        => i_id_external_sys,
                                    i_flg_migration          => i_flg_migration,
                                    i_transaction_id         => l_transaction_id,
                                    i_dt_creation_allocation => i_dt_creation_allocation,
                                    i_dt_creation_resp       => i_dt_creation_resp,
                                    i_dt_disch_sched         => i_dt_disch_sched,
                                    o_id_episode             => l_id_episode,
                                    o_id_patient             => l_id_patient,
                                    o_bed_allocation         => o_bed_allocation,
                                    o_exception_info         => o_exception_info,
                                    o_error                  => o_error)
        THEN
            IF o_bed_allocation = pk_alert_constant.g_no
            THEN
                g_error := 'o_bed_allocation = ''N''';
                pk_alertlog.log_debug(g_error);
                NULL; -- Continue... (because it is supposed to ignore this error when doing allocation inside an episode creation)
            ELSE
                g_error := 'o_bed_allocation = ' || o_bed_allocation;
                pk_alertlog.log_debug(g_error);
                RETURN FALSE; -- direct return in order to keep possible user error messages
            END IF;
        END IF;
    
        -- Creation of schedule discharge
        g_error := 'IF i_dt_disch_sched and i_prof_intf ARE NOT NULL ';
        pk_alertlog.log_debug(g_error);
        IF i_dt_disch_sched IS NOT NULL
           AND i_prof_intf IS NOT NULL
        THEN
            g_error := 'CALL PK_DISCHARGE.SET_DISCHARGE_SCH_DT_INT WITH ID_EPISODE ' || l_id_episode;
            pk_alertlog.log_debug(g_error);
            IF NOT pk_discharge.set_discharge_sch_dt_int(i_lang                  => i_lang,
                                                         i_episode               => l_id_episode,
                                                         i_patient               => l_id_patient,
                                                         i_prof                  => i_prof_intf,
                                                         i_dt_discharge_schedule => pk_date_utils.date_send_tsz(i_lang,
                                                                                                                i_dt_disch_sched,
                                                                                                                i_prof_intf),
                                                         i_transaction_id        => l_transaction_id,
                                                         i_allocation_commit     => CASE o_bed_allocation
                                                                                        WHEN pk_alert_constant.g_yes THEN
                                                                                         pk_alert_constant.g_no
                                                                                        ELSE
                                                                                         pk_alert_constant.g_yes
                                                                                    END,
                                                         o_id_discharge_schedule => l_id_discharge_schedule,
                                                         o_error                 => o_error)
            THEN
                RAISE l_internal_error;
            END IF;
        END IF;
    
        o_id_episode := l_id_episode;
    
        -- SUCCESS
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_internal_error THEN
            pk_alert_exceptions.process_error(i_lang,
                                              o_error.ora_sqlcode,
                                              o_error.err_desc,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CALL_INS_EPISODE',
                                              o_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CALL_INS_EPISODE',
                                              o_error);
            RETURN FALSE;
    END call_ins_episode;

    /*******************************************************************************************************************************************
    * CALL_UPD_EPISODE                update an episode for an episode with send parameters (including dates) 
    * 
    * @param I_LANG                   Language ID for translations    
    * @param I_PROF_RESP              Professional that should be responsable for this episode
    * @param I_PROF_INTF              Professional of interfaces that should be associated with current creation registries   
    * @param I_ID_EPISODE             EPISODE identifier that should be associated with new episode        
    * @param I_ID_DEP_CLIN_SERV       DEP_CLIN_SERV identifier that should be associated with the episode
    * @param I_ID_FIRST_DEP_CLIN_SERV first DEP_CLIN_SERV identifier that should be associated with the episode
    * @param I_ID_ROOM                ROOM identifier that should be associated with new episode
    * @param I_ID_BED                 BED identifier that shoul be associated with new episode
    * @param I_FLG_BED_TYPE           BED type ('P'-permanent; 'T'-temporary)
    * @param I_DESC_BED               Description associated with this bed
    * @param I_DT_BEGIN               Episode begin date in (Format: TIMESTAMP WITH LOCAL TIME ZONE)        
    * @param I_FLG_EHR                Type of EHR episode ('N' - Normal episode, 'E' - EHR event, 'S' - Episode preparation of a scheduled event)
    * @param I_DT_DISCH_SCHED         Espected date for current episode discharge    
    * @param I_ADMITION_NOTES         Admition notes
    * @param I_DT_ADMISSION_NOTES     Admition notes Date/Time
    * @param I_ID_PREV_EPISODE        EPISODE identifier that should be associated with new episode (PREV_EPISODE identifier)
    * @param i_transaction_id         remote transaction identifier
    * @param i_allocation_commit      Indicates if bed allocation should sent information to scheduler 3.0 ('Y' - Yes; 'N' - No)
    * @param i_dt_creation_allocation Date in which the bed allocation was done
    * @param i_dt_creation_resp       Hand-off date
    * @param O_ID_EPISODE             EPISODE identifier corresponding to created episode
    * @param I_FLG_RESP_TYPE          Check if flag main overall responsability is to be set ((E - default) Episode (O) overall - patient responsability)
    * @param O_BED_ALLOCATION         Indicates if bed allocation was succeceful ('Y' - Yes; 'N' - No)
    * @param O_EXCEPTION_INFO         Error message to be displayed to the user.
    * @param O_ERROR                  If an error accurs, this parameter will have information about the error
    * 
    * @return                         Returns TRUE if success, otherwise returns FALSE
    * 
    * @raises                         PL/SQL generic erro "OTHERS"
    * @raises   l_internal_error      Internal error on call_upd_episode
    * 
    * @author                         Sofia Mendes
    * @version                        2.5.0.7
    * @since                          2009/10/01
    *
    *******************************************************************************************************************************************/
    FUNCTION call_upd_episode
    (
        i_lang                         IN language.id_language%TYPE,
        i_prof_resp                    IN profissional,
        i_prof_intf                    IN profissional,
        i_id_episode                   IN episode.id_episode%TYPE,
        i_id_dep_clin_serv             IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_id_first_dep_clin_serv       IN epis_info.id_first_dep_clin_serv%TYPE,
        i_id_room                      IN room.id_room%TYPE,
        i_id_bed                       IN epis_info.id_bed%TYPE,
        i_flg_type                     IN bed.flg_type%TYPE,
        i_desc_bed                     IN bed.desc_bed%TYPE,
        i_dt_begin                     IN episode.dt_begin_tstz%TYPE,
        i_flg_ehr                      IN episode.flg_ehr%TYPE,
        i_dt_disch_sched               IN discharge_schedule.dt_discharge_schedule%TYPE,
        i_admition_notes               IN epis_anamnesis.desc_epis_anamnesis%TYPE,
        i_dt_admission_notes           IN epis_anamnesis.dt_epis_anamnesis_tstz%TYPE DEFAULT NULL,
        i_id_prev_episode              IN episode.id_prev_episode%TYPE,
        i_transaction_id               IN VARCHAR2,
        i_allocation_commit            IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        i_dt_creation_allocation       IN bmng_allocation_bed.dt_creation%TYPE DEFAULT NULL,
        i_dt_creation_resp             IN epis_prof_resp.dt_execute_tstz%TYPE DEFAULT NULL,
        i_flg_resp_type                IN epis_multi_prof_resp.flg_resp_type%TYPE DEFAULT NULL,
        i_epis_flg_type                IN episode.flg_type%TYPE DEFAULT NULL,
        i_flg_allow_bed_alloc_inactive IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        o_bed_allocation               OUT VARCHAR2,
        o_exception_info               OUT sys_message.desc_message%TYPE,
        o_error                        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id_patient            patient.id_patient%TYPE;
        l_id_discharge_schedule discharge_schedule.id_discharge_schedule%TYPE;
        l_transaction_id        VARCHAR2(4000);
        --
        l_internal_error     EXCEPTION;
        l_no_prof_intf_error EXCEPTION;
    BEGIN
        -- gets a new transaction ID and begins the transaction (for the Scheduler 3.0 transactions)
        g_error          := 'CALL PK_SCHEDULE_API_UPSTREAM.BEGIN_NEW_TRANSACTION';
        l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(i_transaction_id, i_prof_intf);
    
        --
        IF i_prof_intf IS NULL
        THEN
            RAISE l_no_prof_intf_error;
        END IF;
    
        -- Creation of new episode
        g_error := 'CALL PK_INP_EPISODE.CALL_UPD_EPISODE_INT WITH ID_EPISODE ' || i_id_episode;
        pk_alertlog.log_debug(g_error);
        IF NOT call_upd_episode_int(i_lang                         => i_lang,
                                    i_id_professional              => i_prof_resp,
                                    i_prof_intf                    => i_prof_intf,
                                    i_id_episode                   => i_id_episode,
                                    i_id_dep_clin_serv             => i_id_dep_clin_serv,
                                    i_id_first_dep_clin_serv       => i_id_first_dep_clin_serv,
                                    i_id_room                      => i_id_room,
                                    i_id_bed                       => i_id_bed,
                                    i_flg_type                     => i_flg_type,
                                    i_desc_bed                     => i_desc_bed,
                                    i_dt_begin                     => i_dt_begin,
                                    i_flg_ehr                      => i_flg_ehr,
                                    i_admition_notes               => i_admition_notes,
                                    i_dt_admission_notes           => i_dt_admission_notes,
                                    i_id_prev_episode              => i_id_prev_episode,
                                    i_transaction_id               => l_transaction_id,
                                    i_allocation_commit            => i_allocation_commit,
                                    i_dt_disch_sched               => i_dt_disch_sched,
                                    i_dt_creation_allocation       => i_dt_creation_allocation,
                                    i_dt_creation_resp             => i_dt_creation_resp,
                                    i_flg_resp_type                => i_flg_resp_type,
                                    i_epis_flg_type                => i_epis_flg_type,
                                    i_flg_allow_bed_alloc_inactive => i_flg_allow_bed_alloc_inactive,
                                    o_bed_allocation               => o_bed_allocation,
                                    o_exception_info               => o_exception_info,
                                    o_error                        => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        -- Creation of schedule discharge
        IF i_dt_disch_sched IS NOT NULL
           AND i_prof_intf IS NOT NULL
        THEN
            g_error := 'SELECT ID_PATIENT ';
            pk_alertlog.log_debug(g_error);
            SELECT epi.id_patient
              INTO l_id_patient
              FROM episode epi
             WHERE epi.id_episode = i_id_episode;
        
            g_error := 'CALL PK_DISCHARGE.SET_DISCHARGE_SCH_DT_INT WITH ID_EPISODE ' || i_id_episode;
            pk_alertlog.log_debug(g_error);
            IF NOT pk_discharge.set_discharge_sch_dt_int(i_lang                  => i_lang,
                                                         i_episode               => i_id_episode,
                                                         i_patient               => l_id_patient,
                                                         i_prof                  => i_prof_intf,
                                                         i_dt_discharge_schedule => pk_date_utils.date_send_tsz(i_lang,
                                                                                                                i_dt_disch_sched,
                                                                                                                i_prof_intf),
                                                         i_transaction_id        => l_transaction_id,
                                                         i_allocation_commit     => CASE o_bed_allocation
                                                                                        WHEN pk_alert_constant.g_yes THEN
                                                                                         pk_alert_constant.g_no
                                                                                        ELSE
                                                                                         pk_alert_constant.g_yes
                                                                                    END,
                                                         o_id_discharge_schedule => l_id_discharge_schedule,
                                                         o_error                 => o_error)
            THEN
                RAISE l_internal_error;
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_internal_error THEN
            pk_alert_exceptions.process_error(i_lang,
                                              o_error.ora_sqlcode,
                                              o_error.err_desc,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CALL_UPD_EPISODE',
                                              o_error);
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof_intf);
            RETURN FALSE;
        WHEN l_no_prof_intf_error THEN
            DECLARE
                l_error_in      t_error_in := t_error_in();
                l_error_message VARCHAR2(4000) := pk_message.get_message(i_lang, 'COMMON_M001');
            BEGIN
                l_error_in.set_all(i_lang,
                                   'ERR_NO_PROF_INTF',
                                   l_error_message,
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   'CALL_UPD_EPISODE');
                l_error_in.set_action('NULL parameter i_prof_intf', 'S');
                g_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof_intf);
            END;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CALL_UPD_EPISODE',
                                              o_error);
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof_intf);
            RETURN FALSE;
    END call_upd_episode;

    /*******************************************************************************************************************************************
    * CALL_INS_SCHED_EPISODE          Create an episode for an patient with send parameters (including dates) and returns id_visit created
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_ID_VISIT               VISIT identifier that should be associated with new episode
    * @param I_PROFESSIONAL           Professional vector of information (professional ID, institution ID, software ID)
    * @param I_ID_SCHED               SCHEDULE identifier that should be associated with new episode
    * @param I_ID_EPISODE             EPISODE identifier that should be associated with new episode
    * @param I_HEALTH_PLAN            HEALTH_PLAN identifier that should be associated with new episode
    * @param I_EPIS_TYPE              EPIS_TYPE identifier that should be associated with new episode
    * @param I_ID_DEP_CLIN_SERV       DEP_CLIN_SERV identifier that should be associated with new episode
    * @param I_ID_ROOM                ROOM identifier that should be associated with new episode
    * @param I_DT_BEGIN               Episode begin date
    * @param I_DT_CREATION            Episode creation date
    * @param I_ID_EPISODE_EXT         EPISODE_EXT identifier that should be associated with new episode
    * @param I_FLG_TYPE               Episode type ('T' - TEMPORARY, 'D' - DEFINITIVE)
    * @param I_TYPE                   Type of surgery ('A' - Ambulatory)
    * @param I_DT_SURGERY             Episode SURGERY date
    * @param I_FLG_SURGERY            Indicates if this episode has an SURGERY episode associated: ('Y' - Yes, 'N' - No)
    * @param I_ID_PREV_EPISODE        EPISODE identifier that should be associated with new episode (PREV_EPISODE identifier)
    * @param I_ID_EXTERNAL_SYS        EXTERNAL_SYS identifier that should be associated with new episode
    * @param i_transaction_id         remote transaction identifier
    * @param O_ID_EPISODE             EPISODE identifier corresponding to created episode
    * @param O_ERROR                  If an error accurs, this parameter will have information about the error
    * 
    * @return                         Returns TRUE if success, otherwise returns FALSE
    * 
    * @raises err_default_template            Error when checking templates
    * @raises err_duplicate_prev_episode      Error when checking previous episode
    * @raises err_create_sr_episode           Error when reating an surgery episode
    * @raises no_data_found                   No data found
    * @raises                                 PL/SQL generic erro "OTHERS"
    *
    * @author                         Luís Maia
    * @version                        2.5.0.5
    * @since                          2009/09/09
    *
    *******************************************************************************************************************************************/
    FUNCTION call_ins_sched_episode
    (
        i_lang                 IN language.id_language%TYPE,
        i_id_visit             IN visit.id_visit%TYPE,
        i_id_professional      IN profissional,
        i_id_sched             IN epis_info.id_schedule%TYPE,
        i_id_episode           IN episode.id_episode%TYPE,
        i_health_plan          IN health_plan.id_health_plan%TYPE,
        i_epis_type            IN episode.id_epis_type%TYPE,
        i_id_dep_clin_serv     IN NUMBER,
        i_id_room              IN NUMBER,
        i_dt_begin             IN VARCHAR2,
        i_dt_creation          IN VARCHAR2,
        i_id_episode_ext       IN VARCHAR2,
        i_flg_type             IN VARCHAR2,
        i_type                 IN VARCHAR2,
        i_dt_surgery           IN VARCHAR2,
        i_flg_surgery          IN VARCHAR2,
        i_id_prev_episode      IN episode.id_prev_episode%TYPE,
        i_id_external_sys      IN epis_ext_sys.id_external_sys%TYPE,
        i_transaction_id       IN VARCHAR2,
        i_flg_ehr              IN episode.flg_ehr%TYPE DEFAULT NULL,
        i_order_set            IN VARCHAR2 DEFAULT 'N',
        i_flg_compulsory       IN episode.flg_compulsory%TYPE DEFAULT NULL,
        i_id_compulsory_reason IN episode.id_compulsory_reason%TYPE DEFAULT NULL,
        i_compulsory_reason    IN episode.compulsory_reason%TYPE DEFAULT NULL,
        o_id_episode           OUT NUMBER,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
        --
        l_dt_begin       TIMESTAMP WITH LOCAL TIME ZONE;
        l_id_patient     patient.id_patient%TYPE;
        l_bed_allocation VARCHAR2(1);
        l_exception_info sys_message.desc_message%TYPE;
        l_transaction_id VARCHAR2(4000);
    BEGIN
        -- gets a new transaction ID and begins the transaction (for the Scheduler 3.0 transactions)
        g_error          := 'CALL PK_SCHEDULE_API_UPSTREAM.BEGIN_NEW_TRANSACTION';
        l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(i_transaction_id, i_id_professional);
    
        --
        l_dt_begin := pk_date_utils.get_string_tstz(i_lang, i_id_professional, i_dt_begin, NULL);
    
        --
        g_error := 'CALL PK_INP_EPISODE.CALL_INS_EPISODE_INT';
        IF NOT call_ins_episode_int(i_lang                 => i_lang,
                                    i_id_visit             => i_id_visit,
                                    i_id_prof_resp         => NULL,
                                    i_id_prof_intf         => i_id_professional,
                                    i_id_sched             => i_id_sched,
                                    i_id_episode           => i_id_episode,
                                    i_health_plan          => i_health_plan,
                                    i_id_dep_clin_serv     => i_id_dep_clin_serv,
                                    i_id_room              => i_id_room,
                                    i_dt_begin             => l_dt_begin,
                                    i_dt_creation          => i_dt_creation,
                                    i_id_episode_ext       => i_id_episode_ext,
                                    i_flg_type             => i_flg_type,
                                    i_flg_ehr              => i_flg_ehr,
                                    i_type                 => i_type,
                                    i_dt_surgery           => i_dt_surgery,
                                    i_flg_surgery          => i_flg_surgery,
                                    i_admition_notes       => NULL,
                                    i_id_prev_episode      => i_id_prev_episode,
                                    i_id_external_sys      => i_id_external_sys,
                                    i_flg_migration        => NULL,
                                    i_transaction_id       => l_transaction_id,
                                    i_dt_disch_sched       => NULL,
                                    i_order_set            => i_order_set,
                                    i_flg_compulsory       => i_flg_compulsory,
                                    i_id_compulsory_reason => i_id_compulsory_reason,
                                    i_compulsory_reason    => i_compulsory_reason,
                                    o_id_episode           => o_id_episode,
                                    o_id_patient           => l_id_patient,
                                    o_bed_allocation       => l_bed_allocation,
                                    o_exception_info       => l_exception_info,
                                    o_error                => o_error)
        THEN
            IF l_bed_allocation = pk_alert_constant.g_no
            THEN
                g_error := 'o_bed_allocation = ''N''';
                pk_alertlog.log_debug(g_error);
                NULL; -- Continue... (because it is supposed to ignore this error when doing allocation inside an episode creation)
            ELSE
                --g_error := 'l_bed_allocation = ' || l_bed_allocation;
                pk_alertlog.log_debug(g_error);
                RETURN FALSE; -- direct return in order to keep possible user error messages
            END IF;
        END IF;
    
        --
        RETURN TRUE;
    END call_ins_sched_episode;

    /*******************************************************************************************************************************************
    * CREATE_EPISODE_NO_COMMIT        Function that creates one new INPATIENT episode (episode and visit) and return new episode identifier.
    *                                 NOTE: - This function hasn't transactional control (COMMIT)
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_PROF                   Professional vector of information (professional ID, institution ID, software ID)
    * @param I_ID_PATIENT             PATIENT identifier that should be associated with this new episode
    * @param I_ID_DEP_CLIN_SERV       DEP_CLIN_SERV identifier that should be associated with this new episode
    * @param I_ID_ROOM                ROOM identifier that should be associated with this new episode
    * @param I_ID_BED                 BED identifier that should be associated with this new episode
    * @param I_DT_BEGIN               Episode start date (begin date) that should be associated with this new episode
    * @param I_FLG_DT_BEGIN_WITH_TSTZ Indicates if is necessary consider current timezone of dt_begin ('Y' - Yes; 'N' - No)
    * @param I_DT_DISCHARGE           Episode discharge date that should be associated with this new episode
    * @param I_ANAMNESIS              Anamnesis information that should be associated with this new episode
    * @param I_FLG_SURGERY            Information if new episode should be associated with an cirurgical episode
    * @param I_TYPE                   EPIS_TYPE identifier that should be associated with this new episode
    * @param I_DT_SURGERY             Surgery date that should be associated with ORIS episode associated with this new episode
    * @param I_ID_PREV_EPISODE        EPISODE identifier that represents the parent episode that should be associated with this new episode
    * @param I_ID_EXTERNAL_SYS        EXTERNAL_SYS identifier that should be associated with this new episode
    * @param I_TRANSACTION_ID         Scheduler 3.0 transaction ID
    * @param O_ID_INP_EPISODE         INPATIENT episode identifier created for this new patient
    * @param O_ERROR                  If an error accurs, this parameter will have information about the error
    * 
    * @return                         Returns TRUE if success, otherwise returns FALSE
    * 
    * @raises err_create_all_surgery  Error in surgery creation
    * @raises err_set_epis_anamnesis  Error creating anamnesis
    * @raises err_ins_episode         Error creating episode
    * @raises                         PL/SQL generic erro "OTHERS"
    * 
    * @author                         Carlos Ferreira
    * @version                        1.0
    * @since                          N.A.
    *
    * @author                         Luís Maia
    * @version                        2.0
    * @since                          2009/05/08
    *
    *******************************************************************************************************************************************/
    FUNCTION create_episode_no_commit
    (
        i_lang                   IN NUMBER,
        i_prof                   IN profissional,
        i_id_patient             IN NUMBER,
        i_id_dep_clin_serv       IN NUMBER,
        i_id_room                IN NUMBER,
        i_id_bed                 IN NUMBER,
        i_dt_begin               IN VARCHAR2,
        i_flg_dt_begin_with_tstz IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        i_dt_discharge           IN VARCHAR2,
        i_flg_hour_origin        IN VARCHAR2 DEFAULT pk_discharge.g_disch_flg_hour_dh,
        i_anamnesis              IN VARCHAR2,
        i_flg_surgery            IN VARCHAR2,
        i_type                   IN NUMBER,
        i_dt_surgery             IN VARCHAR2,
        i_id_prev_episode        IN episode.id_prev_episode%TYPE,
        i_id_external_sys        IN epis_ext_sys.id_external_sys%TYPE DEFAULT NULL,
        i_transaction_id         IN VARCHAR2,
        i_id_visit               IN visit.id_visit%TYPE,
        i_inst_dest              IN institution.id_institution%TYPE DEFAULT NULL,
        i_order_set              IN VARCHAR2 DEFAULT 'N',
        i_flg_compulsory         IN episode.flg_compulsory%TYPE DEFAULT NULL,
        i_id_compulsory_reason   IN episode.id_compulsory_reason%TYPE DEFAULT NULL,
        i_compulsory_reason      IN episode.compulsory_reason%TYPE DEFAULT NULL,
        o_id_inp_episode         OUT NUMBER,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_schedule           NUMBER;
        l_id_episode            NUMBER;
        l_health_plan           NUMBER;
        l_ext_cause             NUMBER;
        l_id_epis_anamnesis     NUMBER;
        l_id_visit              visit.id_visit%TYPE := i_id_visit;
        l_o_id_episode          NUMBER;
        l_id_discharge_schedule NUMBER;
    
        err_set_epis_anamnesis    EXCEPTION;
        err_ins_episode           EXCEPTION;
        err_create_all_surgery    EXCEPTION;
        err_set_disch_sched_date  EXCEPTION;
        err_get_inst_market       EXCEPTION;
        err_bad_instituion_market EXCEPTION;
    
        l_flg_type_mod   VARCHAR2(0050) := pk_clinical_info.g_flg_edition_type_new;
        l_dt_begin       TIMESTAMP WITH LOCAL TIME ZONE;
        l_dt_begin_trunc TIMESTAMP WITH LOCAL TIME ZONE;
        l_dt_begin_str   VARCHAR2(20);
        l_ret            BOOLEAN;
    
        l_transaction_id VARCHAR2(4000);
    
    BEGIN
        -- gets a new transaction ID and begins the transaction (for the Scheduler 3.0 transactions)
        g_error          := 'CALL PK_SCHEDULE_API_UPSTREAM.BEGIN_NEW_TRANSACTION';
        l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(i_transaction_id, i_prof);
    
        g_sysdate_tstz := current_timestamp;
        l_id_schedule  := NULL;
        l_id_episode   := NULL;
        l_health_plan  := NULL;
        l_ext_cause    := NULL;
    
        -- 
        pk_alertlog.log_debug('i_flg_dt_begin_with_tstz = ' || i_dt_begin);
        IF i_flg_dt_begin_with_tstz = pk_alert_constant.g_yes
        THEN
            -- In this case, when an inpatient episode is created, it is created for instant use, so timezone is relevant.
            l_dt_begin     := pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_begin, NULL);
            l_dt_begin_str := i_dt_begin;
        ELSE
            -- In this case I want schedule an inpatient episode for an given day, independently from timezone
            l_dt_begin     := to_timestamp(i_dt_begin, pk_alert_constant.g_dt_yyyymmddhh24miss);
            l_dt_begin_str := to_char(l_dt_begin, pk_alert_constant.g_dt_yyyymmddhh24miss);
        END IF;
    
        --
        pk_alertlog.log_debug('l_dt_begin = ' || l_dt_begin);
        pk_alertlog.log_debug('l_dt_begin_str = ' || l_dt_begin_str);
        l_dt_begin_trunc := pk_date_utils.get_string_tstz(i_lang, i_prof, l_dt_begin_str, NULL);
    
        --
        IF l_id_visit IS NULL
        THEN
            g_error := 'CALL PK_VISIT.INS_VISIT FOR ID_PATIENT ' || i_id_patient;
            pk_alertlog.log_debug(g_error);
            IF NOT pk_visit.ins_visit(i_lang           => i_lang,
                                      i_prof           => i_prof,
                                      i_id_patient     => i_id_patient,
                                      i_external_cause => l_ext_cause,
                                      i_dt_begin       => l_dt_begin_trunc,
                                      i_dt_creation    => g_sysdate_tstz,
                                      i_id_origin      => NULL,
                                      i_flg_migration  => NULL,
                                      i_inst_dest      => i_inst_dest,
                                      i_order_set      => i_order_set,
                                      o_id_visit       => l_id_visit,
                                      o_error          => o_error)
            THEN
                RETURN FALSE;
            END IF;
        END IF;
    
        --
        g_error := 'CALL CALL_INS_SCHED_EPISODE WITH ID_VISIT:' || l_id_visit;
        pk_alertlog.log_debug(g_error);
        IF NOT call_ins_sched_episode(i_lang                 => i_lang,
                                 i_id_visit             => l_id_visit,
                                 i_id_professional      => i_prof,
                                 i_id_sched             => l_id_schedule,
                                 i_id_episode           => l_id_episode,
                                 i_health_plan          => l_health_plan,
                                 i_epis_type            => g_id_epis_type,
                                 i_id_dep_clin_serv     => CASE
                                                               WHEN i_order_set = pk_alert_constant.g_no
                                                                    OR i_order_set IS NULL THEN
                                                                i_id_dep_clin_serv
                                                               ELSE
                                                                -1
                                                           END,
                                 i_id_room              => i_id_room,
                                 i_dt_begin             => l_dt_begin_str,
                                 i_dt_creation          => g_sysdate_tstz, -- This function register current_timestamp
                                 i_id_episode_ext       => NULL,
                                 i_flg_type             => g_epis_definitive,
                                 i_type                 => i_type,
                                 i_dt_surgery           => i_dt_surgery,
                                 i_flg_surgery          => i_flg_surgery,
                                 i_id_prev_episode      => i_id_prev_episode,
                                 i_id_external_sys      => i_id_external_sys,
                                 i_transaction_id       => l_transaction_id,
                                 i_flg_ehr              => g_scheduled_episode,
                                 i_order_set            => i_order_set,
                                 i_flg_compulsory       => i_flg_compulsory,
                                 i_id_compulsory_reason => i_id_compulsory_reason,
                                 i_compulsory_reason    => i_compulsory_reason,
                                 o_id_episode           => l_o_id_episode,
                                 o_error                => o_error)
        THEN
            RETURN FALSE;
        END IF;
        --
        o_id_inp_episode := l_o_id_episode;
    
        -- IF exists anamnesis
        IF i_anamnesis IS NOT NULL
        THEN
            g_error := 'CALL PK_CLINICAL_INFO.SET_EPIS_ANAMNESIS_INT WITH ID_EPISODE = ' || o_id_inp_episode;
            pk_alertlog.log_debug(g_error);
            IF NOT pk_clinical_info.set_epis_anamnesis_int(i_lang              => i_lang,
                                                           i_episode           => o_id_inp_episode,
                                                           i_prof              => i_prof,
                                                           i_desc              => i_anamnesis,
                                                           i_flg_type          => g_anamnesis_flg_type,
                                                           i_flg_type_mode     => l_flg_type_mod,
                                                           i_id_epis_anamnesis => NULL,
                                                           i_id_diag           => NULL,
                                                           i_flg_class         => NULL,
                                                           i_prof_cat_type     => NULL,
                                                           i_flg_rep_by        => NULL,
                                                           o_id_epis_anamnesis => l_id_epis_anamnesis,
                                                           o_error             => o_error)
            THEN
                RAISE err_set_epis_anamnesis;
            END IF;
        END IF;
        --
        -- Alexandre Santos 01-04-2009 
        -- Added field "expected discharge date"
        IF i_dt_discharge IS NOT NULL
        THEN
            g_error := 'CREATE DISCHARGE SCHEDULE:' || l_o_id_episode;
            l_ret   := pk_discharge.set_discharge_schedule_date(i_lang                  => i_lang,
                                                                i_episode               => o_id_inp_episode,
                                                                i_patient               => i_id_patient,
                                                                i_prof                  => i_prof,
                                                                i_dt_discharge_schedule => i_dt_discharge,
                                                                i_flg_hour_origin       => i_flg_hour_origin,
                                                                --i_transaction_id        => l_transaction_id, -- SCH3.0 DO NOT REMOVE
                                                                o_id_discharge_schedule => l_id_discharge_schedule,
                                                                o_error                 => o_error);
        
            IF l_ret = FALSE
            THEN
                RAISE err_set_disch_sched_date;
            END IF;
        END IF;
    
        --
        RETURN TRUE;
    EXCEPTION
        --
        WHEN err_create_all_surgery THEN
            DECLARE
                l_error_in      t_error_in := t_error_in();
                l_error_message VARCHAR2(4000) := pk_message.get_message(i_lang, 'COMMON_M001');
            BEGIN
                l_error_in.set_all(i_lang,
                                   'ERR_CREATE_ALL_SURGERY',
                                   l_error_message,
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   'CREATE_EPISODE');
                l_error_in.set_action('Error in surgery creation', 'S');
                g_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            END;
            RETURN FALSE;
            --
        WHEN err_set_epis_anamnesis THEN
            DECLARE
                l_error_in      t_error_in := t_error_in();
                l_error_message VARCHAR2(4000) := pk_message.get_message(i_lang, 'COMMON_M001');
            BEGIN
                l_error_in.set_all(i_lang,
                                   'ERR_SET_EPIS_ANAMNESIS',
                                   l_error_message,
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   'CREATE_EPISODE');
                l_error_in.set_action('Error creating anamnesis', 'S');
                g_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            END;
            RETURN FALSE;
            --
        WHEN err_ins_episode THEN
            DECLARE
                l_error_in      t_error_in := t_error_in();
                l_error_message VARCHAR2(4000) := pk_message.get_message(i_lang, 'COMMON_M001');
            BEGIN
                l_error_in.set_all(i_lang,
                                   'ERR_INS_EPISODE',
                                   l_error_message,
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   'CREATE_EPISODE');
                l_error_in.set_action('Error creating episode', 'U');
                g_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            END;
            RETURN FALSE;
            --
        WHEN OTHERS THEN
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CREATE_EPISODE',
                                              o_error);
            RETURN FALSE;
    END create_episode_no_commit;

    /*******************************************************************************************************************************************
    * CHECK_INPATIENTS                Function that validates if one new INPATIENT episode can be created
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_ID_PATIENT             PATIENT identifier that should be associated with new episode
    * @param I_PROF                   Professional vector of information (professional ID, institution ID, software ID)
    * @param I_ID_DEP_CLIN_SERV       DEP_CLIN_SERV identifier that should be associated with new episode
    * @param I_DT_BEGIN               Episode begin date
    * @param O_ERROR                  If an error accurs, this parameter will have information about the error
    * 
    * @return                         Returns '1' if success, otherwise returns '0'
    * 
    * @raises l_my_exception          Error when is not possible create an new INPATIENT episode
    * @raises                         PL/SQL generic erro "OTHERS"
    * 
    * @author                         JSILVA
    * @version                        1.0
    * @since                          2007/04/17
    * 
    * @author                         Luís Maia
    * @version                        2.0
    * @since                          2009/05/11
    *
    *******************************************************************************************************************************************/
    FUNCTION check_inpatients
    (
        i_lang             IN language.id_language%TYPE,
        i_id_patient       IN patient.id_patient%TYPE,
        i_prof             IN profissional,
        i_id_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_dt_begin         IN VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_epis_type        epis_type.id_epis_type%TYPE;
        l_count_episodes   NUMBER;
        l_clinical_service clinical_service.id_clinical_service%TYPE;
        l_dt_begin         TIMESTAMP WITH LOCAL TIME ZONE;
        l_my_exception     EXCEPTION;
    
    BEGIN
    
        g_error     := 'GET EPIS TYPE';
        l_epis_type := pk_sysconfig.get_config('ID_EPIS_TYPE_INPATIENT', i_prof);
        l_dt_begin  := pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_begin, NULL);
    
        g_error := 'GET CLINICAL SERVICE';
        SELECT id_clinical_service
          INTO l_clinical_service
          FROM dep_clin_serv
         WHERE id_dep_clin_serv = i_id_dep_clin_serv;
    
        g_error := 'COUNT INP EPISODES';
        SELECT COUNT(*)
          INTO l_count_episodes
          FROM episode epis
         WHERE epis.id_patient = i_id_patient
           AND epis.id_institution = i_prof.institution
           AND epis.id_epis_type = l_epis_type
           AND epis.flg_status = g_episode_flg_status_active
           AND epis.id_clinical_service = l_clinical_service;
        --
        g_error := 'GET EPISODE DATES';
        IF l_count_episodes > 0
           AND pk_date_utils.trunc_insttimezone(i_prof, l_dt_begin, NULL) BETWEEN
           pk_date_utils.trunc_insttimezone(i_prof, current_timestamp, NULL) AND
           pk_date_utils.add_days_to_tstz(pk_date_utils.trunc_insttimezone(i_prof, current_timestamp, NULL), .99999)
        THEN
            RAISE l_my_exception;
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_my_exception THEN
            DECLARE
                l_error_in      t_error_in := t_error_in();
                l_error_message VARCHAR2(4000) := pk_message.get_message(i_lang, 'CHECK_INPATIENTS_M001');
            BEGIN
                l_error_in.set_all(i_lang,
                                   'CHECK_INPATIENTS_M001',
                                   l_error_message,
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   'CHECK_INPATIENTS');
                l_error_in.set_action(l_error_message, 'S');
                g_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                RETURN FALSE;
            END;
            --
        WHEN OTHERS THEN
            pk_alert_exceptions.reset_error_state;
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_package_owner,
                                                     g_package_name,
                                                     'CHECK_INPATIENTS',
                                                     o_error);
    END check_inpatients;

    /******************************************************************************
    * CHECK_OBS_EPISODE        Checks if 'i_id_episode' is an OBS episode.
    *
    * @param i_lang            Professional preferred language
    * @param i_prof            Professional info.
    * @param i_id_episode      Episode ID
    * @param o_error           Error message
    *
    * @return                  TRUE if it's an OBS episode, FALSE otherwise
    *
    * @author                  José Brito
    * @version                 0.1
    * @since                   2008-Jun-04
    *
    ******************************************************************************/
    FUNCTION check_obs_episode
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN NUMBER IS
        l_count NUMBER(6);
    
    BEGIN
    
        g_error := 'GET DEP_CLIN_SERV COUNT 1';
        SELECT COUNT(*)
          INTO l_count
          FROM dep_clin_serv dcs, department dpt, epis_info ei
         WHERE dpt.id_department = dcs.id_department
           AND ei.id_dep_clin_serv = dcs.id_dep_clin_serv
           AND ei.id_episode = i_id_episode
           AND dpt.id_institution = i_prof.institution
           AND instr(dpt.flg_type, 'I') > 0
           AND instr(dpt.flg_type, 'O') > 0;
    
        RETURN l_count;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN 0;
    END check_obs_episode;

    /***************************************************************************************************************
    * REGISTER_ALLOCATION             Patient efectivation through an existing admission schedule
    * 
    * @param      i_lang              language ID
    * @param      i_prof              ALERT profissional 
    * @param      i_prof_resp         responsable professional identifier
    * @param      i_episode           ID_EPISODE to register
    * @param      i_id_patient        Patient identifier
    * @param      i_id_schedule       Schedule identifier
    * @param      i_transaction_id    remote transaction identifier
    * @param      i_id_cancel_reason  Cancel_reason identifier
    * @param      i_bed_allocation    Indicates if bed allocation was succeceful ('Y' - Yes; 'N' - No)
    * @param      o_error             If an error accurs, this parameter will have information about the error
    *
    * @value      O_BED_ALLOCATION    Y - Yes; N - No
    *
    * @return     TRUE or FALSE
    * @raises     l_ext_exception     Error that happens when scheduler 3.0 returns error
    * @raises                         PL/SQL generic erro "OTHERS"
    *
    * @author                         Sofia Mendes
    * @version                        2.5.0.7
    * @since                          12-10-2009
    *
    ****************************************************************************************************/
    FUNCTION register_allocation
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_episode          IN episode.id_episode%TYPE,
        i_id_patient       IN patient.id_patient%TYPE,
        i_id_schedule      IN schedule.id_schedule%TYPE,
        i_transaction_id   IN VARCHAR2,
        i_id_cancel_reason IN cancel_reason.id_cancel_reason%TYPE,
        i_bed_allocation   IN VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id_bmng_allocation_bed bmng_allocation_bed.id_bmng_allocation_bed%TYPE;
        l_id_bed                 bed.id_bed%TYPE;
        l_bmng_action            bmng_action.id_bmng_action%TYPE;
        l_transaction_id         VARCHAR2(4000);
        l_func_name              VARCHAR2(200) := 'REGISTER_ALLOCATION';
        l_warning_info           sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                         'INP_BED_ALLOCATION_T114');
        l_ext_exception          EXCEPTION;
        l_internal_exception     EXCEPTION;
    
        --
        PROCEDURE cancel_sch_alloc
        (
            i_notes              sys_message.desc_message%TYPE,
            i_transaction_id_int VARCHAR2
        ) IS
        BEGIN
            g_error := 'CALL TO PK_SCHEDULE_API_UPSTREAM.CANCEL_SCHEDULE';
            IF NOT pk_schedule_api_upstream.cancel_schedule(i_lang             => i_lang,
                                                            i_prof             => i_prof,
                                                            i_id_schedule      => i_id_schedule,
                                                            i_id_cancel_reason => i_id_cancel_reason,
                                                            i_cancel_notes     => i_notes,
                                                            i_transaction_id   => i_transaction_id_int,
                                                            o_error            => o_error)
            THEN
                pk_alertlog.log_error('ERROR: Function pk_schedule_api_upstream.cancel_schedule return false. i_id_schedule=' ||
                                      i_id_schedule || ' i_cancel_notes=' || i_notes || 'i_id_cancel_reason = ' ||
                                      i_id_cancel_reason || ' i_transaction_id_int=' || i_transaction_id_int);
                RAISE l_internal_exception;
            END IF;
        END cancel_sch_alloc;
        --
    BEGIN
        -- gets a new transaction ID and begins the transaction (for the Scheduler 3.0 transactions)
        g_error          := 'CALL PK_SCHEDULE_API_UPSTREAM.BEGIN_NEW_TRANSACTION';
        l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(i_transaction_id, i_prof);
    
        -- Validate if the allocation was one success
        IF i_bed_allocation = pk_alert_constant.g_yes
        THEN
            -- if a schedule exists associates the schedule and the allocation
            IF i_id_schedule IS NOT NULL
            THEN
                g_error := 'CALL PK_BMNG_CORE.GET_BMNG_ACTION WITH ID_EPISODE: ' || i_episode;
                pk_alertlog.log_debug(g_error);
                IF NOT pk_bmng_core.get_bmng_action(i_lang                => i_lang,
                                                    i_prof                => i_prof,
                                                    i_id_episode          => i_episode,
                                                    o_bmng_action         => l_bmng_action,
                                                    o_bmng_allocation_bed => l_id_bmng_allocation_bed,
                                                    o_id_bed              => l_id_bed,
                                                    o_error               => o_error)
                THEN
                    RETURN FALSE;
                END IF;
            
                g_error := 'CALL PK_SCHEDULE_INP.INS_SCH_ALLOCATION';
                pk_alertlog.log_debug(g_error);
                IF NOT pk_schedule_inp.ins_sch_allocation(i_lang                   => i_lang,
                                                          i_prof                   => i_prof,
                                                          i_id_schedule            => i_id_schedule,
                                                          i_id_bmng_allocation_bed => l_id_bmng_allocation_bed,
                                                          o_error                  => o_error)
                THEN
                    RETURN FALSE;
                END IF;
            END IF;
        
            -- register schedule in scheduler 3
            g_error := 'CALL PK_SCHEDULE_API_UPSTREAM.REGISTER_SCHEDULE. i_id_schedule: ' || i_id_schedule ||
                       ' i_id_patient: ' || i_id_patient;
            pk_alertlog.log_debug(g_error);
            IF NOT pk_schedule_api_upstream.register_schedule(i_lang           => i_lang,
                                                              i_prof           => i_prof,
                                                              i_id_schedule    => i_id_schedule,
                                                              i_id_patient     => i_id_patient,
                                                              i_transaction_id => l_transaction_id,
                                                              o_error          => o_error)
            THEN
                RAISE l_ext_exception;
            END IF;
        
            -- scheduler 3 commit if the remote transaction was created in this function
            g_error := 'CALL PK_SCHEDULE_API_UPSTREAM.DO_COMMIT';
            IF i_transaction_id IS NULL
               AND l_transaction_id IS NOT NULL
            THEN
                pk_schedule_api_upstream.do_commit(l_transaction_id, i_prof);
            END IF;
        
        ELSE
            --Sent error information to scheduler 3.0
            cancel_sch_alloc(l_warning_info, l_transaction_id);
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_ext_exception THEN
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            RETURN FALSE;
    END register_allocation;

    /***************************************************************************************************************
    * Patient efectivation through an existing admission schedule
    *  
    * @param      i_lang              language ID
    * @param      i_prof              ALERT profissional
    * @param      i_prof_resp         Responsable professional
    * @param      i_episode           ID_EPISODE to register
    * @param      i_id_patient        Patient identifier
    * @param      i_id_schedule       Schedule identifier
    * @param      i_transaction_id    remote transaction identifier
    * @param      i_id_cancel_reason  Cancel_reason identifier
    * @param      I_BED_ALLOCATION    Indicates if bed allocation was succeceful ('Y' - Yes; 'N' - No)
    * @param      o_error             If an error accurs, this parameter will have information about the error
    *
    * @RETURN  TRUE or FALSE
    * @author  Sofia Mendes
    * @version 2.5.0.7
    * @since   12-10-2009
    *
    ****************************************************************************************************/
    FUNCTION register_admission
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_episode          IN episode.id_episode%TYPE,
        i_id_patient       IN patient.id_patient%TYPE,
        i_id_schedule      IN schedule.id_schedule%TYPE,
        i_transaction_id   IN VARCHAR2,
        i_id_cancel_reason IN cancel_reason.id_cancel_reason%TYPE,
        i_bed_allocation   IN VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id_visit       episode.id_visit%TYPE;
        l_rowids_epis    table_varchar;
        l_rowids         table_varchar;
        l_transaction_id VARCHAR2(4000);
        --
        l_internal_error EXCEPTION;
    BEGIN
        -- gets a new transaction ID and begins the transaction (for the Scheduler 3.0 transactions)
        g_error          := 'CALL PK_SCHEDULE_API_UPSTREAM.BEGIN_NEW_TRANSACTION';
        l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(i_transaction_id, i_prof);
    
        g_sysdate_tstz := current_timestamp;
    
        IF i_id_schedule IS NOT NULL
           AND i_bed_allocation IS NOT NULL
        THEN
            g_error := 'CALL REGISTER_ADMISSION_NL';
            pk_alertlog.log_debug(g_error);
            IF NOT register_allocation(i_lang             => i_lang,
                                       i_prof             => i_prof,
                                       i_episode          => i_episode,
                                       i_id_patient       => i_id_patient,
                                       i_id_schedule      => i_id_schedule,
                                       i_transaction_id   => l_transaction_id,
                                       i_id_cancel_reason => i_id_cancel_reason,
                                       i_bed_allocation   => i_bed_allocation,
                                       o_error            => o_error)
            THEN
                RAISE l_internal_error;
            END IF;
        END IF;
    
        g_error := 'CALL TS_EPISODE.UPD; I_ID_EPISODE: ' || i_episode;
        pk_alertlog.log_debug(g_error);
        ts_episode.upd(flg_ehr_in => pk_alert_constant.g_flg_ehr_n, dt_begin_tstz_in => g_sysdate_tstz, dt_begin_tstz_nin => FALSE, dt_cancel_tstz_in => CAST(NULL AS TIMESTAMP WITH LOCAL TIME ZONE), dt_cancel_tstz_nin => FALSE, id_prof_cancel_in => CAST(NULL AS NUMBER), id_prof_cancel_nin => FALSE, id_episode_in => i_episode, rows_out => l_rowids_epis);
    
        -- UPDATE VISIT INFORMATION
        BEGIN
            -- Verify if current episode is the first episode of it's visit.
            SELECT x.id_visit
              INTO l_id_visit
              FROM (SELECT id_visit, COUNT(1) num
                      FROM episode
                     START WITH id_episode = i_episode
                    CONNECT BY PRIOR id_episode = id_prev_episode
                           AND id_prev_episode IS NOT NULL
                     GROUP BY id_visit) x
             WHERE x.num = (SELECT (COUNT(1)) num
                              FROM episode epi
                             WHERE epi.id_visit IN (SELECT epi.id_visit
                                                      FROM episode epi
                                                     WHERE epi.id_episode = i_episode));
        
            g_error := 'CALL TS_VISIT.UPD WITH ID_VISIT = ' || l_id_visit;
            pk_alertlog.log_debug(g_error);
            l_rowids := table_varchar();
            ts_visit.upd(dt_begin_tstz_in  => g_sysdate_tstz,
                         dt_begin_tstz_nin => FALSE,
                         --
                         id_visit_in => l_id_visit,
                         rows_out    => l_rowids);
        
            t_data_gov_mnt.process_update(i_lang         => i_lang,
                                          i_prof         => i_prof,
                                          i_table_name   => 'VISIT',
                                          i_rowids       => l_rowids,
                                          o_error        => o_error,
                                          i_list_columns => table_varchar('DT_BEGIN_TSTZ'));
        EXCEPTION
            WHEN no_data_found THEN
                NULL;
        END;
    
        g_error := 'CALL T t_data_gov_mnt.process_update';
        pk_alertlog.log_debug(g_error);
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'EPISODE',
                                      i_rowids       => l_rowids_epis,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('FLG_EHR',
                                                                      'DT_BEGIN_TSTZ',
                                                                      'DT_CANCEL_TSTZ',
                                                                      'ID_PROF_CANCEL'));
    
        --
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'REGISTER_ADMISSION',
                                              o_error);
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            RETURN FALSE;
    END register_admission;

    /***************************************************************************************************************
    * REGISTER_PATIENT                Patient efectivation through an existing admission schedule
    *  
    * 
    * @param      i_lang              language ID
    * @param      i_prof              ALERT profissional 
    * @param      i_episode           ID_EPISODE to register
    * @param      i_id_patient        Patient identifier
    * @param      i_id_schedule       Schedule identifier
    * @param      o_error            If an error accurs, this parameter will have information about the error
    *
    *
    * @RETURN  TRUE or FALSE
    * @author  Sofia Mendes
    * @version 2.5.0.7
    * @since   12-10-2009
    *
    ****************************************************************************************************/
    FUNCTION cancel_allocation
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        i_id_patient     IN patient.id_patient%TYPE,
        i_id_schedule    IN schedule.id_schedule%TYPE,
        i_transaction_id IN VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_bmng_allocation_bed bmng_allocation_bed.id_bmng_allocation_bed%TYPE;
        l_result              VARCHAR2(1);
        l_transaction_id      VARCHAR2(4000);
    BEGIN
        -- gets a new transaction ID and begins the transaction (for the Scheduler 3.0 transactions)
        g_error          := 'CALL PK_SCHEDULE_API_UPSTREAM.BEGIN_NEW_TRANSACTION';
        l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(i_transaction_id, i_prof);
    
        g_error := 'CALL PK_BMNG.CHECK_EPIS_BED_ALLOCATION WITH ID_EPISODE: ' || i_episode;
        pk_alertlog.log_debug(g_error);
        --cancell allocation if patient was allocated
        IF NOT pk_bmng.check_epis_bed_allocation(i_lang    => i_lang,
                                                 i_prof    => i_prof,
                                                 i_episode => i_episode,
                                                 o_result  => l_result,
                                                 o_error   => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        IF l_result = pk_alert_constant.g_yes
        THEN
            -- outdates the existing allocation
            --cancels the action 
            -- updates bed status
            g_error := 'CALL PK_BMNG.SET_BMNG_ALLOCATION_BED';
            pk_alertlog.log_debug(g_error);
        
            IF NOT pk_bmng.set_bmng_discharge(i_lang => i_lang,
                                              i_prof => i_prof,
                                              i_epis => i_episode,
                                              --i_id_cancel_reason => g_alloc_cancel_reason,
                                              i_transaction_id => l_transaction_id,
                                              o_error          => o_error)
            THEN
                RETURN FALSE;
            END IF;
        
            -- if a schedule exists remove the association schedule-allocation
            IF i_id_schedule IS NOT NULL
            THEN
                g_error := 'CALL PK_SCHEDULE_INP.INS_SCH_ALLOCATION';
                pk_alertlog.log_debug(g_error);
                IF NOT pk_schedule_inp.del_sch_allocation(i_lang                   => i_lang,
                                                          i_prof                   => i_prof,
                                                          i_id_schedule            => i_id_schedule,
                                                          i_id_bmng_allocation_bed => l_bmng_allocation_bed,
                                                          o_error                  => o_error)
                THEN
                    RETURN FALSE;
                END IF;
            END IF;
        END IF;
    
        IF (i_transaction_id IS NULL)
        THEN
            pk_schedule_api_upstream.do_commit(l_transaction_id, i_prof);
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
                                              'REGISTER_ALLOCATION',
                                              o_error);
            RETURN FALSE;
    END cancel_allocation;

    /***************************************************************************************************************
    * Cancel an efectivation (the inverse operation of register_admission)
    *  
    * 
    * @param      i_lang              language ID
    * @param      i_prof              ALERT profissional 
    * @param      i_episode           ID_EPISODE to register
    * @param      i_id_patient        Patient identifier
    * @param      i_id_schedule       Schedule identifier
    * @param      i_transaction_id    remote transaction identifier
    * @param      o_error            If an error accurs, this parameter will have information about the error
    *
    *
    * @RETURN  TRUE or FALSE
    * @author  Sofia Mendes
    * @version 2.5.0.7
    * @since   20-10-2009
    *
    ****************************************************************************************************/
    FUNCTION cancel_registration
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        i_id_patient     IN patient.id_patient%TYPE,
        i_id_schedule    IN schedule.id_schedule%TYPE,
        i_transaction_id IN VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_dt_creation     episode.dt_begin_tstz%TYPE;
        l_dt_creation_str VARCHAR2(200);
        l_id_visit        episode.id_visit%TYPE;
        l_rowids          table_varchar;
        l_internal_error  EXCEPTION;
        l_transaction_id  VARCHAR2(4000);
    BEGIN
        -- gets a new transaction ID and begins the transaction (for the Scheduler 3.0 transactions)
        g_error          := 'CALL PK_SCHEDULE_API_UPSTREAM.BEGIN_NEW_TRANSACTION';
        l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(i_transaction_id, i_prof);
    
        g_error := 'CALL CANCEL_REGISTRATION_NL';
        pk_alertlog.log_debug(g_error);
        --outdates the existing allocation
        IF NOT cancel_allocation(i_lang           => i_lang,
                                 i_prof           => i_prof,
                                 i_episode        => i_episode,
                                 i_id_patient     => i_id_patient,
                                 i_id_schedule    => i_id_schedule,
                                 i_transaction_id => l_transaction_id,
                                 o_error          => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        g_error := 'CALL PK_EPISODE.GET_EPIS_DT_CREATION with id_episode: ' || i_episode;
        pk_alertlog.log_debug(g_error);
        IF NOT pk_episode.get_epis_dt_creation(i_lang        => i_lang,
                                               i_prof        => i_prof,
                                               i_id_episode  => i_episode,
                                               o_dt_creation => l_dt_creation_str,
                                               o_error       => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        g_error := 'Convert VARCHAR2 dt_creation_str to TIMESTAMP WITH LOCAL TIME ZONE l_dt_creation';
        pk_alertlog.log_debug(g_error);
        l_dt_creation := pk_date_utils.get_string_tstz(i_lang, i_prof, l_dt_creation_str, NULL);
    
        g_error := 'CALL TS_EPISODE.UPD; I_ID_EPISODE: ' || i_episode;
        pk_alertlog.log_debug(g_error);
        --update episode.flg_ehr, dt_begin
        ts_episode.upd(flg_ehr_in        => pk_visit.g_flg_ehr_s,
                       dt_begin_tstz_in  => l_dt_creation,
                       dt_begin_tstz_nin => FALSE,
                       id_episode_in     => i_episode,
                       rows_out          => l_rowids);
    
        g_error := 'CALL T t_data_gov_mnt.process_update';
        pk_alertlog.log_debug(g_error);
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'EPISODE',
                                      i_rowids       => l_rowids,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('FLG_EHR',
                                                                      'DT_BEGIN_TSTZ',
                                                                      'DT_CANCEL_TSTZ',
                                                                      'ID_PROF_CANCEL'));
    
        -- UPDATE VISIT INFORMATION
        BEGIN
            -- Verify if current episode is the first episode of it's visit.
            SELECT x.id_visit
              INTO l_id_visit
              FROM (SELECT id_visit, COUNT(1) num
                      FROM episode
                     START WITH id_episode = i_episode
                    CONNECT BY PRIOR id_episode = id_prev_episode
                           AND id_prev_episode IS NOT NULL
                     GROUP BY id_visit) x
             WHERE x.num = (SELECT (COUNT(1)) num
                              FROM episode epi
                             WHERE epi.id_visit IN (SELECT epi.id_visit
                                                      FROM episode epi
                                                     WHERE epi.id_episode = i_episode));
        
            --
            g_error := 'CALL TS_VISIT.UPD WITH ID_VISIT = ' || l_id_visit;
            pk_alertlog.log_debug(g_error);
            l_rowids := table_varchar();
            ts_visit.upd(dt_begin_tstz_in  => l_dt_creation,
                         dt_begin_tstz_nin => FALSE,
                         --
                         id_visit_in => l_id_visit,
                         rows_out    => l_rowids);
        
            t_data_gov_mnt.process_update(i_lang         => i_lang,
                                          i_prof         => i_prof,
                                          i_table_name   => 'VISIT',
                                          i_rowids       => l_rowids,
                                          o_error        => o_error,
                                          i_list_columns => table_varchar('DT_BEGIN_TSTZ'));
        EXCEPTION
            WHEN no_data_found THEN
                NULL;
        END;
    
        IF (i_transaction_id IS NULL)
        THEN
            pk_schedule_api_upstream.do_commit(l_transaction_id, i_prof);
        END IF;
    
        --
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CANCEL_REGISTRATION',
                                              o_error);
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            RETURN FALSE;
    END cancel_registration;

    /***************************************************************************************************************
    * Cancels an admission schedule with cancelation reason: Patient did not show.
    *  
    * 
    * @param      i_lang              language ID
    * @param      i_prof              ALERT profissional     
    * @param      i_id_schedule       Schedule identifier
    * @param      i_transaction_id    Scheduler 3.0 transaction ID
    * @param      i_id_cancel_reason  Cancel_reason identifier
    * @param      o_error             If an error accurs, this parameter will have information about the error
    *
    *
    * @RETURN  TRUE or FALSE
    * @author  Sofia Mendes
    * @version 2.5.0.7
    * @since   22-10-2009
    *
    ****************************************************************************************************/
    FUNCTION cancel_schedule_no_show
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_schedule      IN schedule.id_schedule%TYPE,
        i_transaction_id   IN VARCHAR2,
        i_id_cancel_reason IN cancel_reason.id_cancel_reason%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_ext_exception EXCEPTION;
        l_rowids        table_varchar;
    
        --Scheduler 3.0 transaction ID
        l_transaction_id VARCHAR2(4000);
    BEGIN
        -- gets a new transaction ID and begins the transaction (for the Scheduler 3.0 transactions)
        g_error          := 'CALL PK_SCHEDULE_API_UPSTREAM.BEGIN_NEW_TRANSACTION';
        l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(i_transaction_id, i_prof);
    
        g_error := 'CALL PK_SCHEDULE_INP.CANCEL_SCHEDULES WITH ID_SCHEDULE: ' || i_id_schedule;
        pk_alertlog.log_debug(g_error);
        IF NOT pk_schedule_api_upstream.cancel_schedule(i_lang             => i_lang,
                                                        i_prof             => i_prof,
                                                        i_id_schedule      => i_id_schedule,
                                                        i_id_cancel_reason => i_id_cancel_reason,
                                                        i_transaction_id   => l_transaction_id,
                                                        o_error            => o_error)
        THEN
            RAISE l_ext_exception;
        END IF;
    
        --updates the wtl_epis flg_status to: cancelled schedule because patient did not show
        g_error := 'CALL set_wtl_epis_hist. i_id_schedule: ' || i_id_schedule;
        pk_alertlog.log_debug(g_error);
        IF NOT pk_wtl_prv_core.set_wtl_epis_hist(i_lang             => i_lang,
                                                 i_prof             => i_prof,
                                                 i_id_schedule      => i_id_schedule,
                                                 i_dt_wtl_epis_hist => current_timestamp,
                                                 o_error            => o_error)
        THEN
            RAISE l_ext_exception;
        END IF;
    
        g_error := 'UPDATE EPIS_WAITING_LIST. i_id_schedule: ' || i_id_schedule;
        pk_alertlog.log_debug(g_error);
        ts_wtl_epis.upd(flg_status_in => pk_wtl_prv_core.g_wtl_epis_st_no_show,
                        where_in      => 'id_schedule =' || i_id_schedule,
                        rows_out      => l_rowids);
    
        IF i_transaction_id IS NULL
           AND l_transaction_id IS NOT NULL
        THEN
            pk_schedule_api_upstream.do_commit(l_transaction_id, i_prof);
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_ext_exception THEN
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CANCEL_SCHEDULE_NO_SHOW',
                                              o_error);
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            RETURN FALSE;
    END cancel_schedule_no_show;

    /**********************************************************************************************
    * SET_MATCH_SCHEDULE_INP                upates tables: schedule_inp_bed. To be used on match functionality
    *
    * @param i_lang                          Language ID
    * @param i_prof                          Profissional array
    * @param i_episode_temp                  Temporary episode
    * @param i_episode                       Episode identifier 
    * @param o_error                         Error object
    *
    * @return                                Success / fail
    *
    * @author                                Sofia Mendes
    * @version                               2.5.0.7
    * @since                                 2009/11/03
    **********************************************************************************************/
    FUNCTION set_match_schedule_inp
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode_temp IN episode.id_episode%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_rowids    table_varchar;
        l_sib       schedule_inp_bed%ROWTYPE;
        l_count_def PLS_INTEGER := 0;
    BEGIN
        g_error := 'SELECT SCHEDULE_INP_BED with episode_temp = ' || i_episode_temp;
        pk_alertlog.log_debug(g_error);
        BEGIN
            SELECT sib.id_episode, sib.id_room, sib.dt_schedule, sib.id_bed
              INTO l_sib.id_episode, l_sib.id_room, l_sib.dt_schedule, l_sib.id_bed
              FROM schedule_inp_bed sib
             WHERE sib.id_episode = i_episode_temp;
        EXCEPTION
            WHEN no_data_found THEN
                l_sib.id_episode := NULL;
        END;
    
        IF (l_sib.id_episode IS NOT NULL)
        THEN
            g_error := 'CALL TS_SCHEDULE_INP_BED.DEL with episode_temp = ' || i_episode_temp;
            pk_alertlog.log_debug(g_error);
            ts_schedule_inp_bed.del(id_episode_in => i_episode_temp, rows_out => l_rowids);
            t_data_gov_mnt.process_delete(i_lang, i_prof, 'SCHEDULE_INP_BED', l_rowids, o_error);
        
            --check if exists a registry to the definitive episode
            g_error := 'SELECT SCHEDULE_INP_BED with episode = ' || i_episode;
            pk_alertlog.log_debug(g_error);
            BEGIN
                SELECT COUNT(1)
                  INTO l_count_def
                  FROM schedule_inp_bed sib
                 WHERE sib.id_episode = i_episode;
            EXCEPTION
                WHEN no_data_found THEN
                    l_count_def := 0;
            END;
        
            IF (l_count_def = 0)
            THEN
                l_sib.id_episode := i_episode;
            
                g_error := 'CALL TS_SCHEDULE_INP_BED.INS';
                pk_alertlog.log_debug(g_error);
                ts_schedule_inp_bed.ins(rec_in => l_sib, rows_out => l_rowids);
                t_data_gov_mnt.process_insert(i_lang, i_prof, 'SCHEDULE_INP_BED', l_rowids, o_error);
                --on PT market the scheduled bed is on table schedule_inp_bed
            END IF;
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
                                              'SET_MATCH_SCHEDULE_INP',
                                              o_error);
            RETURN FALSE;
    END set_match_schedule_inp;

    /**********************************************************************************************
    * Returns the current value of the scheduled discharge date for the provided episode
    *
    * @param i_lang                ID language
    * @param i_prof                Object with user info
    * @param i_episode             ID of episode
    *    
    *
    * @return                      Timestamp with the current value of the scheduled discharge date 
    *                        
    * @author                      RicardoNunoAlmeida
    * @version                     2.5.0.7
    * @since                       2009/12/16
    **********************************************************************************************/
    FUNCTION get_disch_schedule_curr
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN discharge_schedule.dt_discharge_schedule%TYPE IS
        l_discharge_date discharge_schedule.dt_discharge_schedule%TYPE;
        l_error          t_error_out;
    BEGIN
    
        g_error := 'SELECT DISCHARGE SCHEDULE with id_episode: ' || i_episode;
        pk_alertlog.log_debug(g_error);
        SELECT MAX(ds.dt_discharge_schedule)
          INTO l_discharge_date
          FROM discharge_schedule ds
         WHERE ds.id_episode = i_episode
           AND ds.flg_status = pk_alert_constant.g_yes;
    
        RETURN l_discharge_date;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_DISCHARGE_SCHEDULE_CURRENT',
                                              l_error);
            RETURN NULL;
        
    END get_disch_schedule_curr;

    /**********************************************************************************************
    * Checks if a given episode has already been registered
    *
    * @param i_lang                ID language   
    * @param i_episode             ID of episode      
    *
    * @return                      Y-registered episode; N-not registered episode
    *                        
    * @author                      Sofia Mendes
    * @version                     2.5.0.7.8
    * @since                       2010/03/24
    **********************************************************************************************/
    FUNCTION is_epis_registered
    (
        i_lang       IN language.id_language%TYPE,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2 IS
        l_is_registered VARCHAR2(1 CHAR);
        l_error         t_error_out;
    BEGIN
        BEGIN
            g_error := 'IS_EPIS_REGISTERED';
            SELECT pk_alert_constant.g_yes
              INTO l_is_registered
              FROM episode epis
             WHERE epis.id_episode = i_id_episode
               AND epis.flg_ehr = pk_alert_constant.g_flg_ehr_n;
        EXCEPTION
            WHEN no_data_found THEN
                l_is_registered := pk_alert_constant.g_no;
        END;
    
        RETURN l_is_registered;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'IS_EPIS_REGISTERED',
                                              o_error    => l_error);
            RETURN NULL;
    END is_epis_registered;

    /**********************************************************************************************
    * Returns the actions to be shown in the scheduled grid, according to the configuration 
    * that indicates if it is being used the ALERT SCHEDULER in the intitution.
    *
    * @param i_lang                ID language   
    * @param i_prof                Professional
    * @param o_actions             Output cursor
    * @param o_error                         Error object
    *
    * @return                      Y-registered episode; N-not registered episode
    *                        
    * @author                      Sofia Mendes
    * @version                     2.6.0.3
    * @since                       25-Aug-2010
    **********************************************************************************************/
    FUNCTION get_sch_grid_actions
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        o_actions OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        IF NOT get_sch_grid_actions(i_lang        => i_lang,
                                    i_prof        => i_prof,
                                    i_prof_follow => pk_alert_constant.g_no,
                                    o_actions     => o_actions,
                                    o_error       => o_error)
        THEN
            RAISE e_call_error;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_SCH_GRID_ACTIONS',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_actions);
            RETURN FALSE;
    END get_sch_grid_actions;

    /**********************************************************************************************
    * Returns the actions to be shown in the scheduled grid, according to the configuration 
    * that indicates if it is being used the ALERT SCHEDULER in the intitution.
    *
    * @param i_lang                ID language   
    * @param i_prof                Professional
    * @param i_prof_follow         'Y' if the PROF_FOLLOW subject actions will be returned
    * @param o_actions             Output cursor
    * @param o_error                         Error object
    *
    * @return                      Y-registered episode; N-not registered episode
    *                        
    * @author                      Sofia Mendes
    * @version                     2.6.0.3
    * @since                       25-Aug-2010
    **********************************************************************************************/
    FUNCTION get_sch_grid_actions
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_prof_follow IN VARCHAR2,
        o_actions     OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_has_scheduler  sys_config.value%TYPE;
        l_internal_error EXCEPTION;
        l_tbl_subject    table_varchar;
    BEGIN
        g_error := 'CALL pk_sysconfig.get_config for id: ' || g_has_scheduler;
        pk_alertlog.log_debug(g_error);
        l_has_scheduler := pk_sysconfig.get_config(g_has_scheduler, i_prof);
    
        IF i_prof_follow = pk_alert_constant.g_yes
        THEN
            l_tbl_subject := table_varchar(g_sch_grid_actions, g_sch_grid_actions_follow);
        ELSE
            l_tbl_subject := table_varchar(g_sch_grid_actions);
        END IF;
    
        IF (l_has_scheduler = pk_alert_constant.g_yes)
        THEN
            g_error := 'CALL pk_action.get_actions. l_has_scheduler: ' || l_has_scheduler;
            pk_alertlog.log_debug(g_error);
            IF NOT pk_action.get_actions(i_lang       => i_lang,
                                         i_prof       => i_prof,
                                         i_subject    => l_tbl_subject,
                                         i_from_state => table_varchar(g_from_state_a,
                                                                       g_from_state_s,
                                                                       g_from_state_y,
                                                                       g_from_state_n,
                                                                       g_from_state_m),
                                         o_actions    => o_actions,
                                         o_error      => o_error)
            THEN
                RAISE l_internal_error;
            END IF;
        ELSE
            g_error := 'CALL pk_action.get_actions. l_has_scheduler: ' || l_has_scheduler;
            pk_alertlog.log_debug(g_error);
            IF NOT pk_action.get_actions(i_lang       => i_lang,
                                         i_prof       => i_prof,
                                         i_subject    => l_tbl_subject,
                                         i_from_state => table_varchar(g_from_state_a,
                                                                       g_from_state_y,
                                                                       g_from_state_n,
                                                                       g_from_state_m),
                                         o_actions    => o_actions,
                                         o_error      => o_error)
            THEN
                RAISE l_internal_error;
            END IF;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_SCH_GRID_ACTIONS',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_actions);
            RETURN FALSE;
    END get_sch_grid_actions;

    FUNCTION get_admission_discharge
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        o_episode_info OUT pk_types.cursor_type,
        o_diag         OUT pk_types.cursor_type,
        o_surgical     OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_begin_date episode.dt_begin_tstz%TYPE;
        l_id_patient episode.id_patient%TYPE;
        l_end_date   episode.dt_end_tstz%TYPE;
    
        l_internal_error EXCEPTION;
        l_consultant     professional.name%TYPE;
        l_attending      professional.name%TYPE;
        l_dummy          VARCHAR2(20 CHAR);
        l_id             epis_prof_resp.id_epis_prof_resp%TYPE;
    
    BEGIN
    
        SELECT e.dt_begin_tstz, e.id_patient, nvl(e.dt_end_tstz, current_timestamp)
          INTO l_begin_date, l_id_patient, l_end_date
          FROM episode e
         WHERE id_episode = i_episode;
        IF NOT pk_hand_off_core.get_prof_resp_by_type(i_lang              => i_lang,
                                                      i_prof              => i_prof,
                                                      i_id_episode        => i_episode,
                                                      i_prof_cat          => 'D',
                                                      i_flg_profile       => 'S',
                                                      i_hand_off_type     => NULL,
                                                      i_flg_resp_type     => 'O',
                                                      i_id_speciality     => NULL,
                                                      i_only_main_overall => 'Y',
                                                      o_epis_status       => l_dummy,
                                                      o_id_prof_resp      => l_id,
                                                      o_prof_name         => l_consultant,
                                                      o_error             => o_error)
        THEN
            l_consultant := NULL;
        END IF;
        IF NOT pk_hand_off_core.get_prof_resp_by_type(i_lang          => i_lang,
                                                      i_prof          => i_prof,
                                                      i_id_episode    => i_episode,
                                                      i_prof_cat      => 'D',
                                                      i_flg_profile   => 'R',
                                                      i_hand_off_type => NULL,
                                                      i_flg_resp_type => 'E',
                                                      i_id_speciality => NULL,
                                                      o_epis_status   => l_dummy,
                                                      o_id_prof_resp  => l_id,
                                                      o_prof_name     => l_attending,
                                                      o_error         => o_error)
        THEN
            l_attending := NULL;
        END IF;
        OPEN o_episode_info FOR
            SELECT e.id_patient,
                   (SELECT pk_adt.get_admission_origin_desc(i_lang, i_prof, e.id_episode)
                      FROM dual) source_origin,
                   (CASE
                        WHEN e.id_prev_episode IS NOT NULL THEN
                         pk_episode.get_epis_dep_cs_desc(i_lang, i_prof, e.id_prev_episode)
                        ELSE
                         NULL
                    END) internal,
                   (SELECT pk_date_utils.dt_chr_tsz(i_lang, e.dt_begin_tstz, i_prof.institution, i_prof.software)
                      FROM dual) dt_admission,
                   (SELECT pk_date_utils.dt_chr_hour_tsz(i_lang, e.dt_begin_tstz, i_prof.institution, i_prof.software)
                      FROM dual) hour_admission,
                   (SELECT pk_sysdomain.get_domain('DISCHARGE_DETAIL.FLG_PAT_CONDITION', dd.flg_pat_condition, i_lang)
                      FROM discharge d
                      JOIN discharge_detail dd
                        ON d.id_discharge = dd.id_discharge
                     WHERE d.id_episode = prev_e.id_episode
                       AND flg_status = pk_discharge.g_disch_flg_status_active) patient_condition,
                   (SELECT pk_date_utils.dt_chr_tsz(i_lang,
                                                    nvl(d.dt_med_tstz, d.dt_admin_tstz),
                                                    i_prof.institution,
                                                    i_prof.software)
                      FROM dual) dt_discharge,
                   (SELECT pk_date_utils.dt_chr_hour_tsz(i_lang,
                                                         nvl(d.dt_med_tstz, d.dt_admin_tstz),
                                                         i_prof.institution,
                                                         i_prof.software)
                      FROM dual) hour_discharge,
                   (SELECT pk_edis_proc.get_los_duration(i_lang       => i_lang,
                                                         i_prof       => i_prof,
                                                         i_id_episode => e.id_episode)
                      FROM dual) length_of_stay,
                   (SELECT pk_sysdomain.get_domain('DISCHARGE_DETAIL.FLG_PAT_CONDITION', dd.flg_pat_condition, i_lang)
                      FROM dual) condition_on_discharge,
                   (SELECT pk_translation.get_translation(i_lang, dr.code_discharge_reason)
                      FROM disch_reas_dest drd
                      JOIN discharge_reason dr
                        ON dr.id_discharge_reason = drd.id_discharge_reason
                     WHERE drd.id_disch_reas_dest = d.id_disch_reas_dest) discharge_destination,
                   l_consultant consultant,
                   l_attending attending
              FROM episode e
              JOIN visit v
                ON e.id_visit = v.id_visit
              LEFT JOIN episode prev_e
                ON e.id_prev_episode = prev_e.id_episode
              LEFT JOIN origin o
                ON o.id_origin = v.id_visit
              LEFT JOIN discharge d
                ON d.id_episode = e.id_episode
               AND d.flg_status IN (pk_discharge.g_disch_flg_status_active, pk_discharge.g_disch_flg_status_pend)
              LEFT JOIN discharge_detail dd
                ON dd.id_discharge = d.id_discharge
             WHERE e.id_episode = i_episode;
    
        IF NOT pk_diagnosis_core.get_epis_diag_list(i_lang      => i_lang,
                                                    i_prof      => i_prof,
                                                    i_episode   => i_episode,
                                                    i_flg_type  => NULL,
                                                    i_epis_diag => NULL,
                                                    o_epis_diag => o_diag,
                                                    o_error     => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        OPEN o_surgical FOR
            SELECT pk_translation.get_translation(i_lang, 'INTERVENTION.CODE_INTERVENTION.' || sei.id_sr_intervention) desc_interv,
                   pk_touch_option.get_template_value(i_lang               => i_lang,
                                                      i_prof               => i_prof,
                                                      i_patient            => e.id_patient,
                                                      i_episode            => e.id_episode,
                                                      i_doc_area           => 9,
                                                      i_epis_documentation => NULL,
                                                      i_doc_int_name       => 'anesthesia.1',
                                                      i_show_internal      => 'N',
                                                      i_scope_type         => 'E',
                                                      i_show_id_content    => 'N',
                                                      i_show_doc_title     => 'N') anesthesia
              FROM schedule_sr ss
              JOIN schedule s
                ON s.id_schedule = ss.id_schedule
              JOIN sr_surgery_record srsr
                ON ss.id_schedule_sr = srsr.id_schedule_sr
              JOIN episode e
                ON e.id_episode = ss.id_episode
              JOIN sr_epis_interv sei
                ON sei.id_episode_context = e.id_episode
             WHERE e.id_patient = l_id_patient
               AND sei.flg_status = 'F'
               AND sei.flg_type = 'P'
               AND sei.dt_interv_start_tstz BETWEEN l_begin_date AND l_end_date;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_ADMISSION_DISCHARGE',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_episode_info);
            pk_types.open_my_cursor(o_diag);
            RETURN FALSE;
        
    END get_admission_discharge;

-- ********************************************************************************
-- *********************************** GLOBALS ************************************
-- ********************************************************************************
BEGIN
    -- Log initialization.
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

    g_software_intern_name := 'INP';

    g_cat_flg_available := 'Y';
    g_cat_flg_prof      := 'Y';
    g_max_length        := 15;

    g_pat_allergy_cancel := 'C';
    g_pat_blood_active   := 'A';
    g_pat_habit_cancel   := 'C';
    g_pat_problem_cancel := 'C';
    g_pat_notes_cancel   := 'C';

    g_epis_stat_inactive := 'I';

    g_episode_flg_status_active   := 'A';
    g_episode_flg_status_temp     := 'T';
    g_episode_flg_status_canceled := 'C';
    g_episode_flg_status_inactive := 'I';
    g_epis_info_efectiv           := 'E';

    g_anamnesis_flg_type := 'C';

    g_id_epis_type := 5;
    g_visit_active := 'A';

    g_epis_temporary  := 'T';
    g_epis_definitive := 'D';

    -- JS, 2007-09-21: New model of problems and relevant diseases
    g_pat_history_diagnosis_y := 'Y';
    g_pat_history_diagnosis_n := 'N';

END;
/
