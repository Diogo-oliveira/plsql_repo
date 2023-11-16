/*-- Last Change Revision: $Rev: 2026686 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:39:35 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_api_manchester AS

    /********************************************************************************************
    * Gets the external system ID associated with Manchester Offline 
    *
    * @return                      true (sucess), false (error)
    *
    * @author                      José Silva
    * @since                       2009/10/22
    * @version                     1.0
    **********************************************************************************************/
    FUNCTION get_offline_ext_sys RETURN NUMBER IS
    
        l_id_external_sys external_sys.id_external_sys%TYPE;
    
    BEGIN
        --
    
        SELECT id_external_sys
          INTO l_id_external_sys
          FROM external_sys es
         WHERE es.intern_name_ext_sys = 'Manchester Offline';
    
        RETURN l_id_external_sys;
        --
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_offline_ext_sys;

    /********************************************************************************************
    * Gets the software ID to be used in Manchester Offline
    *
    * @param i_institution         external institution ID
    *
    * @return                      true (sucess), false (error)
    *
    * @author                      José Silva
    * @since                       2010/04/01
    * @version                     1.0
    **********************************************************************************************/
    FUNCTION get_id_software(i_institution IN NUMBER) RETURN software.id_software%TYPE IS
    
        l_id_software software.id_software%TYPE;
    
    BEGIN
        --
        SELECT si.id_software
          INTO l_id_software
          FROM software_institution si
         WHERE si.id_institution = i_institution
           AND si.id_software IN (8, 29);
    
        RETURN l_id_software;
        --
    EXCEPTION
        WHEN OTHERS THEN
            RETURN g_software_offline;
    END get_id_software;

    /********************************************************************************************
    * Gets the epis type ID to be used in Manchester Offline
    *
    * @param i_institution         external institution ID
    *
    * @return                      true (sucess), false (error)
    *
    * @author                      José Silva
    * @since                       2010/04/01
    * @version                     1.0
    **********************************************************************************************/
    FUNCTION get_id_epis_type(i_institution IN NUMBER) RETURN epis_type.id_epis_type%TYPE IS
    
        l_id_epis_type epis_type.id_epis_type%TYPE;
    
    BEGIN
        --
        l_id_epis_type := nvl(pk_sysconfig.get_config('EPIS_TYPE', i_institution, g_software_triage),
                              g_epis_type_offline);
    
        RETURN l_id_epis_type;
        --
    EXCEPTION
        WHEN OTHERS THEN
            RETURN g_epis_type_offline;
    END get_id_epis_type;

    /********************************************************************************************
    * Gets the episode ID associated with the Manchester Offline episode ID
    *
    * @param i_ext_episode         external episode ID
    * @param i_institution         external institution ID
    *
    * @return                      true (sucess), false (error)
    *
    * @author                      José Silva
    * @since                       2009/10/22
    * @version                     1.0
    **********************************************************************************************/
    FUNCTION get_id_episode
    (
        i_ext_episode IN NUMBER,
        i_institution IN NUMBER
    ) RETURN episode.id_episode%TYPE IS
    
        l_id_episode episode.id_episode%TYPE;
    
    BEGIN
        --
    
        SELECT id_episode
          INTO l_id_episode
          FROM epis_ext_sys es
         WHERE es.value = to_char(i_ext_episode)
           AND es.id_external_sys = get_offline_ext_sys
           AND es.id_institution = i_institution;
    
        RETURN l_id_episode;
        --
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_id_episode;

    /********************************************************************************************
    * Gets the patient ID associated with the Manchester Offline patient ID
    *
    * @param i_ext_patient         external patient ID
    * @param i_institution         external institution ID
    *
    * @return                      true (sucess), false (error)
    *
    * @author                      José Silva
    * @since                       2009/10/23
    * @version                     1.0
    **********************************************************************************************/
    FUNCTION get_id_patient
    (
        i_ext_patient IN NUMBER,
        i_institution IN NUMBER
    ) RETURN patient.id_patient%TYPE IS
    
        l_id_patient patient.id_patient%TYPE;
    
    BEGIN
        --
    
        SELECT id_patient
          INTO l_id_patient
          FROM pat_ext_sys ps
         WHERE ps.value = to_char(i_ext_patient)
           AND ps.id_external_sys = get_offline_ext_sys
           AND ps.id_institution = i_institution;
    
        RETURN l_id_patient;
        --
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_id_patient;

    /********************************************************************************************
    * Gets the triage ID associated with a Manchester Offline episode ID and date
    *
    * @param i_ext_episode         external episode ID
    * @param i_institution         external institution ID
    *
    * @return                      true (sucess), false (error)
    *
    * @author                      José Silva
    * @since                       2009/10/22
    * @version                     1.0
    **********************************************************************************************/
    FUNCTION get_id_epis_triage
    (
        i_lang        IN language.id_language%TYPE,
        i_episode     IN episode.id_episode%TYPE,
        i_ext_date    IN DATE,
        i_institution IN NUMBER
    ) RETURN epis_triage.id_epis_triage%TYPE IS
    
        l_id_epis_triage epis_triage.id_epis_triage%TYPE;
    
    BEGIN
        --
        SELECT id_epis_triage
          INTO l_id_epis_triage
          FROM epis_triage et
         WHERE et.id_episode = i_episode
           AND to_date(pk_date_utils.date_send_tsz(i_lang, et.dt_end_tstz, i_institution, g_software_triage),
                       g_dateformat) = i_ext_date;
    
        RETURN l_id_epis_triage;
        --
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_id_epis_triage;

    /********************************************************************************************
    * Gets the discharge ID associated with a Manchester Offline episode ID and date
    *
    * @param i_ext_episode         external episode ID
    * @param i_institution         external institution ID
    *
    * @return                      true (sucess), false (error)
    *
    * @author                      José Silva
    * @since                       2009/10/22
    * @version                     1.0
    **********************************************************************************************/
    FUNCTION get_id_discharge
    (
        i_lang        IN language.id_language%TYPE,
        i_episode     IN episode.id_episode%TYPE,
        i_ext_date    IN DATE,
        i_institution IN NUMBER
    ) RETURN discharge.id_discharge%TYPE IS
    
        l_id_discharge discharge.id_discharge%TYPE;
    
    BEGIN
        --
        SELECT id_discharge
          INTO l_id_discharge
          FROM discharge d
         WHERE d.id_episode = i_episode
           AND to_date(pk_date_utils.date_send_tsz(i_lang, d.dt_med_tstz, i_institution, g_software_triage),
                       g_dateformat) = i_ext_date;
    
        RETURN l_id_discharge;
        --
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_id_discharge;

    /********************************************************************************************
    * Gets the discharge ID associated with a Manchester Offline episode ID and date
    *
    * @param i_ext_episode         external episode ID
    * @param i_institution         external institution ID
    *
    * @return                      true (sucess), false (error)
    *
    * @author                      José Silva
    * @since                       2009/10/22
    * @version                     1.0
    **********************************************************************************************/
    FUNCTION get_prof_dcs
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN NUMBER,
        o_dcs         OUT table_number,
        o_flg         OUT table_varchar,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        --
        g_error := 'GET INSTITUTION DEP_CLIN_SERV';
        SELECT dcs.id_dep_clin_serv, g_dcs_selected BULK COLLECT
          INTO o_dcs, o_flg
          FROM dep_clin_serv dcs
          JOIN department d
            ON (d.id_department = dcs.id_department)
         WHERE d.id_institution = i_institution
           AND dcs.flg_available = g_yes
           AND d.flg_available = g_yes;
    
        RETURN TRUE;
        --
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_ret BOOLEAN;
            BEGIN
                l_ret := pk_alert_exceptions.process_error(i_lang,
                                                           SQLCODE,
                                                           SQLERRM,
                                                           g_error,
                                                           'ALERT',
                                                           'PK_API_MANCHESTER',
                                                           'GET_PROF_DCS',
                                                           o_error);
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
    END get_prof_dcs;

    /********************************************************************************************
    * Creates a new episode
    * Affected tables: VISIT, EPISODE, EPIS_INFO
    *
    * @param i_lang                language ID
    * @param i_institution         institution ID
    * @param i_episode             episode record from Offline DB
    * @param o_episode             New episode ID 
    * @param o_error               Error message
    *
    * @return                      true (sucess), false (error)
    *
    * @author                      José Silva
    * @since                       2009/10/22
    * @version                     1.0
    **********************************************************************************************/
    FUNCTION set_episode
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_episode     IN rec_episode,
        o_episode     OUT episode.id_episode%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_rec_episode      pk_api_visit.rec_episode;
        l_rec_epis_ext_sys pk_api_visit.rec_epis_ext_sys;
        l_id_episode       episode.id_episode%TYPE;
        l_dt_begin         VARCHAR2(50);
        l_dt_begin_tstz    episode.dt_begin_tstz%TYPE;
        l_dt_end           VARCHAR2(50);
        l_dt_end_tstz      episode.dt_end_tstz%TYPE;
        l_prof             profissional;
        --
        l_rowids table_varchar := table_varchar();
        -- SCH 3.0 variable
        l_transaction_id VARCHAR2(4000);
    
    BEGIN
    
        g_error         := 'GET ID_EPISODE';
        l_id_episode    := get_id_episode(i_episode.id_episode, i_institution);
        l_prof          := profissional(i_episode.id_professional, i_institution, g_software_triage);
        l_dt_begin      := pk_date_utils.date_send(i_lang, i_episode.dt_begin, l_prof);
        l_dt_begin_tstz := pk_date_utils.get_string_tstz(i_lang, l_prof, l_dt_begin, NULL);
        l_dt_end        := pk_date_utils.date_send(i_lang, i_episode.dt_end, l_prof);
        l_dt_end_tstz   := pk_date_utils.get_string_tstz(i_lang, l_prof, l_dt_end, NULL);
    
        IF l_id_episode IS NULL
        THEN
        
            g_error                            := 'SET REC_EPIS_EXT_SYS';
            l_rec_epis_ext_sys.id_external_sys := get_offline_ext_sys;
            l_rec_epis_ext_sys.id_ext_episode  := i_episode.id_episode;
        
            g_error                      := 'SET REC_EPISODE';
            l_rec_episode.id_epis_type   := get_id_epis_type(i_institution);
            l_rec_episode.id_institution := i_institution;
            l_rec_episode.id_software    := get_id_software(i_institution);
            l_rec_episode.id_patient     := get_id_patient(i_episode.id_patient, i_institution);
            l_rec_episode.id_room        := i_episode.id_room;
        
            -- gets a new transaction ID and begins the transaction (for the Scheduler 3.0 transactions)
            g_error          := 'CALL PK_SCHEDULE_API_UPSTREAM.BEGIN_NEW_TRANSACTION';
            l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(NULL, profissional(0, i_institution, 0));
        
            g_error := 'CALL TO PK_API_VISIT.SET_EPISODE_PFH';
            IF NOT pk_api_visit.set_episode_pfh(i_lang           => i_lang,
                                                i_rec_epis_ext   => l_rec_epis_ext_sys,
                                                i_rec_episode    => l_rec_episode,
                                                i_epis_type      => get_id_epis_type(i_institution),
                                                i_institution    => i_institution,
                                                i_transaction_id => l_transaction_id,
                                                o_episode        => l_id_episode,
                                                o_error          => o_error)
            THEN
                RAISE g_exception;
            END IF;
        
            g_error := 'UPDATE EPISODE';
            ts_episode.upd(id_episode_in => l_id_episode, dt_begin_tstz_in => l_dt_begin_tstz, rows_out => l_rowids);
        
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => l_prof,
                                          i_table_name => 'EPISODE',
                                          i_rowids     => l_rowids,
                                          o_error      => o_error);
        
            g_error := 'UPDATE VISIT';
            UPDATE visit v
               SET v.dt_begin_tstz = l_dt_begin_tstz
             WHERE v.id_visit = (SELECT id_visit
                                   FROM episode
                                  WHERE id_episode = l_id_episode);
        
            --remote scheduler commit. Doesn't affect PFH.
            pk_schedule_api_upstream.do_commit(l_transaction_id, profissional(0, i_institution, 0));
        
        ELSE
            g_error := 'UPDATE EPISODE';
            ts_episode.upd(id_episode_in   => l_id_episode,
                           dt_end_tstz_in  => l_dt_end_tstz,
                           dt_end_tstz_nin => FALSE,
                           flg_status_in   => i_episode.flg_status,
                           rows_out        => l_rowids);
        
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => l_prof,
                                          i_table_name => 'EPISODE',
                                          i_rowids     => l_rowids,
                                          o_error      => o_error);
        
            -- since we only have one episode per visit, we can bypass this validation
            g_error := 'UPDATE VISIT';
            l_rowids := table_varchar();
            ts_visit.upd(flg_status_in   => i_episode.flg_status,
                         flg_status_nin  => FALSE,
                         dt_end_tstz_in  => l_dt_end_tstz,
                         dt_end_tstz_nin => FALSE,
                         where_in        => 'id_visit = (SELECT epis.id_visit
																	FROM episode epis
																 WHERE epis.id_episode = ' || l_id_episode || ')',
                         rows_out        => l_rowids);
        
            t_data_gov_mnt.process_update(i_lang         => i_lang,
                                          i_prof         => l_prof,
                                          i_table_name   => 'VISIT',
                                          i_rowids       => l_rowids,
                                          o_error        => o_error,
                                          i_list_columns => table_varchar('FLG_STATUS', 'DT_END_TSTZ'));
                                          
            --g_error := 'UPDATE VISIT';            
            --UPDATE visit v
            --   SET v.dt_end_tstz = l_dt_end_tstz, v.flg_status = i_episode.flg_status
            -- WHERE v.id_visit = (SELECT id_visit
            --                       FROM episode
            --                      WHERE id_episode = l_id_episode);
        
            g_error  := 'UPDATE EPIS_INFO';
            l_rowids := table_varchar();
            ts_epis_info.upd(id_episode_in => l_id_episode, id_room_in => i_episode.id_room, rows_out => l_rowids);
        
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => l_prof,
                                          i_table_name => 'EPIS_INFO',
                                          i_rowids     => l_rowids,
                                          o_error      => o_error);
        END IF;
    
        --
        o_episode := l_id_episode;
        RETURN TRUE;
        --
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_ret BOOLEAN;
            BEGIN
                l_ret := pk_alert_exceptions.process_error(i_lang,
                                                           SQLCODE,
                                                           SQLERRM,
                                                           g_error,
                                                           'ALERT',
                                                           'PK_API_MANCHESTER',
                                                           'SET_EPISODE',
                                                           o_error);
            
                --remote scheduler rollback. Doesn't affect PFH.
                IF l_transaction_id IS NOT NULL
                THEN
                    pk_schedule_api_upstream.do_rollback(l_transaction_id, profissional(0, i_institution, 0));
                END IF;
                pk_utils.undo_changes;
            
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
    END set_episode;

    /********************************************************************************************
    * Creates a new triage
    * Affected tables: EPIS_TRIAGE, EPIS_ANAMNESIS
    *
    * @param i_lang                language ID
    * @param i_institution         institution ID
    * @param i_epis_triage         triage record from Offline DB
    * @param o_epis_triage         New triage ID 
    * @param o_error               Error message
    *
    * @return                      true (sucess), false (error)
    *
    * @author                      José Silva
    * @since                       2009/10/22
    * @version                     1.0
    **********************************************************************************************/
    FUNCTION set_epis_triage
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_epis_triage IN rec_epis_triage,
        o_epis_triage OUT epis_triage.id_epis_triage%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_prof       profissional;
        l_id_episode episode.id_episode%TYPE;
        l_id_patient patient.id_patient%TYPE;
        --
        l_shortcut sys_shortcut.id_sys_shortcut%TYPE;
        --
        l_epis_anamnesis epis_anamnesis.id_epis_anamnesis%TYPE;
        l_tab_status     table_varchar;
        --
        l_tbl_group_options pk_edis_types.table_group_options;
        l_rec_group_option  pk_edis_types.rec_group_option;
        l_needs             pk_edis_types.table_needs;
        l_rec_needs         pk_edis_types.rec_need;
        l_tbl_options       pk_edis_types.table_options;
        l_rec_option        pk_edis_types.rec_option;
        l_triage            pk_edis_types.rec_triage;
    
    BEGIN
        --
        g_error := 'GET PROFESSIONAL AND EPISODE';
        l_prof  := profissional(i_epis_triage.id_professional, i_institution, g_software_triage);
    
        l_id_episode := get_id_episode(i_epis_triage.id_episode, i_institution);
        l_id_patient := pk_episode.get_epis_patient(i_lang => i_lang, i_prof => l_prof, i_episode => l_id_episode);
    
        IF l_id_episode IS NULL
        THEN
            g_error := 'EPISODE DOES NOT EXIST';
            RAISE g_exception;
        END IF;
    
        g_error      := 'GET NECESS STATUS';
        l_tab_status := table_varchar();
    
        FOR i IN 1 .. i_epis_triage.id_necessity.count
        LOOP
            l_tab_status.extend;
            l_tab_status(i) := g_active;
        END LOOP;
    
        l_triage.id_patient             := l_id_patient;
        l_triage.id_episode             := l_id_episode;
        l_triage.id_triage              := i_epis_triage.id_triage;
        l_triage.flg_selected_option    := g_yes;
        l_triage.id_triage_color        := i_epis_triage.id_triage_color;
        l_triage.id_triage_white_reason := i_epis_triage.id_triage_white_reason;
        l_triage.flg_changed_color      := g_no;
        l_triage.dt_triage_begin        := i_epis_triage.dt_begin;
        l_triage.dt_triage_end          := i_epis_triage.dt_end;
        l_triage.notes                  := i_epis_triage.end_triage_notes;
        l_triage.chief_complaint        := i_epis_triage.notes;
        l_triage.flg_letter             := i_epis_triage.flg_letter;
        l_triage.id_transp_entity       := i_epis_triage.id_transp_entity;
        l_triage.emergency_contact      := i_epis_triage.emergency_contact;
        l_triage.origin.id_origin       := i_epis_triage.id_origin;
        l_triage.origin.desc_origin_ft  := i_epis_triage.desc_origin;
    
        l_rec_group_option.id_triage_color := i_epis_triage.id_triage_color;
        l_tbl_group_options                := pk_edis_types.table_group_options();
    
        l_tbl_options := pk_edis_types.table_options();
        FOR i IN i_epis_triage.tab_triage.first .. i_epis_triage.tab_triage.last
        LOOP
            l_rec_option.id_triage            := i_epis_triage.tab_triage(i);
            l_rec_option.id_triage_cons_value := i_epis_triage.tab_tri_disc_consent(i);
            l_rec_option.flg_selected_option  := g_yes;
        
            l_tbl_options.extend;
            l_tbl_options(l_tbl_options.count) := l_rec_option;
        END LOOP;
    
        l_rec_group_option.options := l_tbl_options;
    
        l_tbl_group_options.extend;
        l_tbl_group_options(l_tbl_group_options.count) := l_rec_group_option;
    
        l_triage.group_options := l_tbl_group_options;
    
        l_needs := pk_edis_types.table_needs();
        FOR i IN i_epis_triage.id_necessity.first .. i_epis_triage.id_necessity.last
        LOOP
            l_rec_needs.id_necessity := i_epis_triage.id_necessity(i);
            l_rec_needs.flg_status   := g_active;
        
            l_needs.extend;
            l_needs(l_needs.count) := l_rec_needs;
        END LOOP;
    
        l_triage.needs := l_needs;
    
        -- Call the function
        IF NOT pk_edis_triage.create_epis_triage(i_lang           => i_lang,
                                                 i_prof           => l_prof,
                                                 i_triage         => l_triage,
                                                 o_epis_triage    => o_epis_triage,
                                                 o_epis_anamnesis => l_epis_anamnesis,
                                                 o_shortcut       => l_shortcut,
                                                 o_error          => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
        --
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_API_MANCHESTER',
                                              'SET_EPIS_TRIAGE',
                                              o_error);
        
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END set_epis_triage;

    /********************************************************************************************
    * Creates a new vital sign read
    * Affected tables: VITAL_SIGN_READ
    *
    * @param i_lang                language ID
    * @param i_institution         institution ID
    * @param i_vs_read             vital sign record from Offline DB
    * @param o_vs_id               New vital sign read ID 
    * @param o_error               Error message
    *
    * @return                      true (sucess), false (error)
    *
    * @author                      José Silva
    * @since                       2009/10/22
    * @version                     1.0
    **********************************************************************************************/
    FUNCTION set_vital_sign_read
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_epis_triage IN rec_epis_triage,
        i_vs_read     IN rec_vital_sign_read,
        o_vs_id       OUT vital_sign_read.id_vital_sign_read%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_prof           profissional;
        l_id_episode     episode.id_episode%TYPE;
        l_id_epis_triage epis_triage.id_epis_triage%TYPE;
    
        l_dt_begin      VARCHAR2(50);
        l_dt_begin_tstz epis_triage.dt_begin_tstz%TYPE;
    
        l_vs_id             table_number := table_number();
        l_vs_val            table_number := table_number();
        l_unit_meas         table_number := table_number();
        l_vs_scales_element table_number := table_number();
    
    BEGIN
    
        g_error      := 'GET ID_EPIS_TRIAGE';
        l_id_episode := get_id_episode(i_epis_triage.id_episode, i_institution);
    
        IF l_id_episode IS NULL
        THEN
            g_error := 'EPISODE DOES NOT EXIST';
            RAISE g_exception;
        END IF;
    
        l_id_epis_triage := get_id_epis_triage(i_lang, l_id_episode, i_epis_triage.dt_end, i_institution);
    
        IF l_id_epis_triage IS NULL
        THEN
            g_error := 'TRIAGE RECORD DOES NOT EXIST';
            RAISE g_exception;
        END IF;
    
        l_prof          := profissional(i_epis_triage.id_professional, i_institution, g_software_triage);
        l_dt_begin      := pk_date_utils.date_send(i_lang, i_epis_triage.dt_begin, l_prof);
        l_dt_begin_tstz := pk_date_utils.get_string_tstz(i_lang, l_prof, l_dt_begin, NULL);
    
        l_vs_id.extend;
        l_vs_val.extend;
        l_unit_meas.extend;
        l_vs_scales_element.extend;
    
        l_vs_id(1) := i_vs_read.id_vital_sign;
        l_vs_val(1) := nvl(i_vs_read.id_vital_sign_desc, i_vs_read.valor);
        l_unit_meas(1) := i_vs_read.id_unit_measure;
        l_vs_scales_element(1) := i_vs_read.id_vs_scales_element;
    
        g_error := 'SET VS EPIS_TRIAGE';
        IF NOT pk_edis_triage.set_triage_vs(i_lang              => i_lang,
                                            i_prof              => l_prof,
                                            i_prof_cat_type     => pk_prof_utils.get_category(i_lang => i_lang,
                                                                                              i_prof => l_prof),
                                            i_id_epis           => l_id_episode,
                                            i_patient           => NULL,
                                            i_epis_triage       => l_id_epis_triage,
                                            i_dt_triage_begin   => l_dt_begin_tstz,
                                            i_vs_id             => l_vs_id,
                                            i_vs_val            => l_vs_val,
                                            i_unit_meas         => l_unit_meas,
                                            i_scales_element_id => l_vs_scales_element,
                                            o_error             => o_error)
        THEN
            ROLLBACK;
            RETURN FALSE;
        END IF;
    
        --
        g_error := 'CALL TO PK_VISIT.SET_FIRST_OBS';
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => l_id_episode,
                                      i_pat                 => NULL,
                                      i_prof                => l_prof,
                                      i_prof_cat_type       => NULL,
                                      i_dt_last_interaction => l_dt_begin_tstz,
                                      i_dt_first_obs        => l_dt_begin_tstz,
                                      o_error               => o_error)
        THEN
            RAISE g_exception;
        END IF;
        --
        o_vs_id := i_vs_read.id_vital_sign;
        RETURN TRUE;
        --
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_ret BOOLEAN;
            BEGIN
                l_ret := pk_alert_exceptions.process_error(i_lang,
                                                           SQLCODE,
                                                           SQLERRM,
                                                           g_error,
                                                           'ALERT',
                                                           'PK_API_MANCHESTER',
                                                           'SET_EPIS_TRIAGE',
                                                           o_error);
            
                pk_utils.undo_changes;
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
    END set_vital_sign_read;

    /********************************************************************************************
    * Creates a new movement
    * Affected tables: MOVEMENT
    *
    * @param i_lang                language ID
    * @param i_institution         institution ID
    * @param i_movement            movement record from Offline DB
    * @param o_movement            New movement ID
    * @param o_error               Error message
    *
    * @return                      true (sucess), false (error)
    *
    * @author                      José Silva
    * @since                       2009/10/22
    * @version                     1.0
    **********************************************************************************************/
    FUNCTION set_movement
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_movement    IN rec_movement,
        o_movement    OUT movement.id_movement%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_episode    episode.id_episode%TYPE;
        l_prof          profissional;
        l_dt_req        VARCHAR2(50);
        l_dt_begin      VARCHAR2(50);
        l_dt_end        VARCHAR2(50);
        l_dt_req_tstz   movement.dt_req_tstz%TYPE;
        l_dt_begin_tstz movement.dt_begin_tstz%TYPE;
        l_dt_end_tstz   movement.dt_end_tstz%TYPE;
        --
        l_rows        table_varchar := table_varchar();
        l_id_movement movement.id_movement%TYPE;
    
    BEGIN
    
        g_error      := 'GET ID_EPISODE';
        l_id_episode := get_id_episode(i_movement.id_episode, i_institution);
    
        IF l_id_episode IS NULL
        THEN
            g_error := 'EPISODE DOES NOT EXIST';
            RAISE g_exception;
        END IF;
    
        l_prof          := profissional(i_movement.id_prof_request, i_institution, g_software_triage);
        l_dt_req        := pk_date_utils.date_send(i_lang, i_movement.dt_req, l_prof);
        l_dt_req_tstz   := pk_date_utils.get_string_tstz(i_lang, l_prof, l_dt_req, NULL);
        l_dt_begin      := pk_date_utils.date_send(i_lang, i_movement.dt_begin, l_prof);
        l_dt_begin_tstz := pk_date_utils.get_string_tstz(i_lang, l_prof, l_dt_begin, NULL);
        l_dt_end        := pk_date_utils.date_send(i_lang, i_movement.dt_end, l_prof);
        l_dt_end_tstz   := pk_date_utils.get_string_tstz(i_lang, l_prof, l_dt_end, NULL);
    
        g_error       := 'INSERT INTO MOVEMENT';
        l_id_movement := ts_movement.next_key;
    
        ts_movement.ins(id_episode_in      => l_id_episode,
                        id_room_from_in    => i_movement.id_room_from,
                        id_room_to_in      => i_movement.id_room_to,
                        id_prof_request_in => i_movement.id_prof_request,
                        dt_req_tstz_in     => l_dt_req_tstz,
                        flg_status_in      => pk_alert_constant.g_mov_status_finish,
                        id_prof_move_in    => i_movement.id_prof_move,
                        dt_begin_tstz_in   => l_dt_begin_tstz,
                        id_prof_receive_in => i_movement.id_prof_move,
                        dt_end_tstz_in     => l_dt_end_tstz,
                        id_movement_out    => l_id_movement,
                        flg_mov_type_in    => g_mov_type_detour,
                        rows_out           => l_rows);
    
        t_data_gov_mnt.process_insert(i_lang, l_prof, 'MOVEMENT', l_rows, o_error => o_error);
        --
        o_movement := l_id_movement;
        RETURN TRUE;
        --
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_ret BOOLEAN;
            BEGIN
                l_ret := pk_alert_exceptions.process_error(i_lang,
                                                           SQLCODE,
                                                           SQLERRM,
                                                           g_error,
                                                           'ALERT',
                                                           'PK_API_MANCHESTER',
                                                           'SET_EPIS_TRIAGE',
                                                           o_error);
            
                pk_utils.undo_changes;
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
    END set_movement;

    /********************************************************************************************
    * Creates a new discharge
    * Affected tables: DISCHARGE, DISCHARGE_DETAIL
    *
    * @param i_lang                language ID
    * @param i_institution         institution ID
    * @param i_discharge           discharge record from Offline DB
    * @param o_discharge           New discharge ID 
    * @param o_error               Error message
    *
    * @return                      true (sucess), false (error)
    *
    * @author                      José Silva
    * @since                       2009/10/22
    * @version                     1.0
    **********************************************************************************************/
    FUNCTION set_discharge
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_discharge   IN rec_discharge,
        o_discharge   OUT discharge.id_discharge%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_episode     episode.id_episode%TYPE;
        l_id_discharge   discharge.id_discharge%TYPE;
        l_prof           profissional;
        l_dt_med         VARCHAR2(50);
        l_dt_med_tstz    discharge.dt_med_tstz%TYPE;
        l_dt_admin       VARCHAR2(50);
        l_dt_admin_tstz  discharge.dt_med_tstz%TYPE;
        l_dt_cancel      VARCHAR2(50);
        l_dt_cancel_tstz discharge.dt_med_tstz%TYPE;
        l_id_hist        discharge_hist.id_discharge_hist%TYPE;
    
        l_flg_status       discharge.flg_status%TYPE;
        l_discharge_status discharge.id_discharge_status%TYPE;
    
    BEGIN
    
        g_error      := 'GET ID_EPISODE';
        l_id_episode := get_id_episode(i_discharge.id_episode, i_institution);
    
        IF l_id_episode IS NULL
        THEN
            g_error := 'EPISODE DOES NOT EXIST';
            RAISE g_exception;
        END IF;
    
        l_prof          := profissional(i_discharge.id_prof_med, i_institution, g_software_triage);
        l_dt_med        := pk_date_utils.date_send(i_lang, i_discharge.dt_med, l_prof);
        l_dt_med_tstz   := pk_date_utils.get_string_tstz(i_lang, l_prof, l_dt_med, NULL);
        l_dt_admin      := pk_date_utils.date_send(i_lang, i_discharge.dt_admin, l_prof);
        l_dt_admin_tstz := pk_date_utils.get_string_tstz(i_lang, l_prof, l_dt_admin, NULL);
    
        l_id_discharge := get_id_discharge(i_lang, l_id_episode, i_discharge.dt_med, i_institution);
    
        g_error := 'GET ID_DISCHARGE_STATUS';
        IF NOT pk_discharge.get_disch_flg_status(i_lang         => i_lang,
                                                 i_prof         => l_prof,
                                                 i_flg_status   => i_discharge.flg_status,
                                                 i_disch_status => NULL,
                                                 o_flg_status   => l_flg_status,
                                                 o_disch_status => l_discharge_status,
                                                 o_error        => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        IF l_id_discharge IS NULL
        THEN
            INSERT INTO discharge
                (id_discharge,
                 id_disch_reas_dest,
                 id_episode,
                 id_prof_med,
                 dt_med_tstz,
                 notes_med,
                 id_prof_admin,
                 dt_admin_tstz,
                 notes_admin,
                 flg_status,
                 id_discharge_status,
                 flg_type,
                 id_transp_ent_med,
                 id_transp_ent_adm,
                 flg_type_disch,
                 flg_status_adm,
                 flg_market)
            
            VALUES
                (seq_discharge.nextval,
                 i_discharge.id_disch_reas_dest,
                 l_id_episode,
                 i_discharge.id_prof_med,
                 l_dt_med_tstz,
                 i_discharge.notes_med,
                 i_discharge.id_prof_admin,
                 l_dt_admin_tstz,
                 i_discharge.notes_admin,
                 i_discharge.flg_status,
                 l_discharge_status,
                 g_disch_type_f,
                 i_discharge.id_transp_ent_med,
                 i_discharge.id_transp_ent_adm,
                 g_disch_type_triage,
                 decode(l_dt_admin_tstz, NULL, NULL, pk_alert_constant.g_active),
                 pk_discharge_core.g_disch_type_pt)
            RETURNING id_discharge INTO l_id_discharge;
        
            INSERT INTO discharge_detail
                (id_discharge_detail, id_discharge, flg_pat_condition)
            VALUES
                (seq_discharge_detail.nextval, l_id_discharge, i_discharge.flg_pat_condition);
        
        ELSE
        
            l_dt_cancel      := pk_date_utils.date_send(i_lang, i_discharge.dt_cancel, l_prof);
            l_dt_cancel_tstz := pk_date_utils.get_string_tstz(i_lang, l_prof, l_dt_cancel, NULL);
        
            UPDATE discharge
               SET dt_cancel_tstz = l_dt_cancel_tstz,
                   id_prof_cancel = i_discharge.id_prof_cancel,
                   notes_cancel   = i_discharge.notes_cancel,
                   flg_status     = i_discharge.flg_status,
                   dt_admin_tstz  = l_dt_admin_tstz,
                   notes_admin    = i_discharge.notes_admin,
                   flg_status_adm = decode(l_dt_admin_tstz, NULL, NULL, pk_alert_constant.g_active)
             WHERE id_discharge = l_id_discharge;
        END IF;
        --
        g_error := 'SET DISCHARGE_HIST';
        pk_discharge_core.set_discharge_hist(i_prof       => l_prof,
                                             i_discharge  => l_id_discharge,
                                             i_outd_prev  => pk_alert_constant.g_no,
                                             o_disch_hist => l_id_hist);
        --
        g_error := 'CALL TO PK_VISIT.SET_FIRST_OBS';
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => l_id_episode,
                                      i_pat                 => NULL,
                                      i_prof                => l_prof,
                                      i_prof_cat_type       => NULL,
                                      i_dt_last_interaction => coalesce(l_dt_cancel_tstz, l_dt_admin_tstz, l_dt_med_tstz),
                                      i_dt_first_obs        => coalesce(l_dt_cancel_tstz, l_dt_admin_tstz, l_dt_med_tstz),
                                      o_error               => o_error)
        THEN
            RAISE g_exception;
        END IF;
        --
        o_discharge := l_id_discharge;
        RETURN TRUE;
        --
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_ret BOOLEAN;
            BEGIN
                l_ret := pk_alert_exceptions.process_error(i_lang,
                                                           SQLCODE,
                                                           SQLERRM,
                                                           g_error,
                                                           'ALERT',
                                                           'PK_API_MANCHESTER',
                                                           'SET_EPIS_TRIAGE',
                                                           o_error);
            
                pk_utils.undo_changes;
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
    END set_discharge;

--##########################################################################################################################
--
BEGIN
    pk_alertlog.log_init(pk_alertlog.who_am_i);
    g_owner   := 'ALERT';
    g_package := 'PK_API_MANCHESTER';
    --
END pk_api_manchester;
/
