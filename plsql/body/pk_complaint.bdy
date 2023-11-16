/*-- Last Change Revision: $Rev: 2026889 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:40:19 +0100 (ter, 02 ago 2022) $*/
CREATE OR REPLACE PACKAGE BODY pk_complaint IS
    k_package_owner CONSTANT VARCHAR2(50 CHAR) := 'ALERT';
    FUNCTION error_handling
    (
        i_lang           IN language.id_language%TYPE,
        i_func_proc_name IN VARCHAR2,
        i_error          IN VARCHAR2,
        i_sqlerror       IN VARCHAR2,
        i_rollback       IN BOOLEAN,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_error_in t_error_in := t_error_in();
        l_ret      BOOLEAN;
    
    BEGIN
        l_error_in.set_all(i_lang, SQLCODE, i_sqlerror, i_error, 'ALERT', g_package_name, i_func_proc_name);
        l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
    
        IF i_rollback = TRUE
        THEN
            pk_utils.undo_changes;
        END IF;
    
        RETURN FALSE;
    END error_handling;

    /********************************************************************************************
    * Devolve a lista de queixa possiveis, que se podem associar ao episódio.
      Esta lista é devolvida em 2 contextos: registo de nova queixa e alteração
      de queixa anterior. No segundo caso, apresenta-se ao utilizador qual a queixa
      registada anteriormente. Para se discriminar o 1º cenário do 2º, o parametro
      i_epis_complaint tem valor NULL, ou o id da queixa que se quer alterar, respectivamente
    *
    * @param i_lang                id da lingua
    * @param i_prof                objecto com info do utilizador
    * @param i_episode             id do episódio, para discriminação de template, dado um serviço clinico.
    *                              este parametro pode ser ignorado em certos casos (quais?)
    * @param i_epis_complaint      id da queixa que se quer alterar, ou NULL em caso de novo registo
    * @param o_complaints          cursor com queixas
    * @param o_error               Error message
    *    
    * @return                      true (sucess), false (error)
    *
    * @author                      João Eiras
    * @version                     1.0
    * @since                       24-05-2007
    **********************************************************************************************/
    FUNCTION get_complaint_list
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        i_patient        IN patient.id_patient%TYPE,
        i_epis_complaint IN epis_complaint.id_epis_complaint%TYPE,
        o_complaints     OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(32 CHAR) := 'GET_COMPLAINT_LIST';
        --
        l_comp_filter       VARCHAR2(100);
        l_tbl_complaint_ids table_number;
        --
        FUNCTION get_complaints_ids(i_comp_filter IN VARCHAR2) RETURN table_number IS
            l_sub_func_name CONSTANT VARCHAR2(32 CHAR) := 'GET_COMPLAINTS_IDS';
            --
            l_pat_age    NUMBER;
            l_pat_genger patient.gender%TYPE;
            --
            l_dep_clin_serv    dep_clin_serv.id_dep_clin_serv%TYPE;
            l_profile_template profile_template.id_profile_template%TYPE;
            l_tbl_dtc_types    table_varchar;
            --
            l_filter_inst      institution.id_institution%TYPE;
            l_filter_soft      software.id_software%TYPE;
            l_filter_prof_temp profile_template.id_profile_template%TYPE;
            l_filter_dcs       dep_clin_serv.id_dep_clin_serv%TYPE;
            --
            l_tbl_complaints table_number;
        BEGIN
            g_error := 'SET DTC_TYPES';
            pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_sub_func_name);
            IF i_comp_filter = pk_complaint.g_comp_filter_prf
            THEN
                l_tbl_dtc_types := table_varchar(pk_complaint.g_flg_type_c, pk_complaint.g_flg_type_dc);
            ELSIF l_comp_filter = pk_complaint.g_comp_filter_dcs
            THEN
                l_tbl_dtc_types := table_varchar(pk_complaint.g_flg_type_ct);
            ELSE
                g_error := 'NO COMPLAINT_FILTER(' || i_prof.institution || ',' || i_prof.software ||
                           ') SET TYPE_TBL TO EMPTY';
                pk_alertlog.log_debug(text            => g_error,
                                      object_name     => g_package_name,
                                      sub_object_name => l_sub_func_name);
                l_tbl_dtc_types := table_varchar();
            END IF;
        
            g_error := 'CALL PK_PATIENT.GET_PAT_AGE';
            pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_sub_func_name);
            l_pat_age := pk_patient.get_pat_age(i_lang        => i_lang,
                                                i_dt_birth    => NULL,
                                                i_dt_deceased => NULL,
                                                i_age         => NULL,
                                                i_age_format  => 'YEARS',
                                                i_patient     => i_patient);
            g_error   := 'CALL PK_PATIENT.GET_PAT_AGE';
            pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_sub_func_name);
            l_pat_genger := pk_patient.get_pat_gender(i_id_patient => i_patient);
        
            g_error := 'GET PROFILE TEMPLATE';
            pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_sub_func_name);
            l_profile_template := pk_prof_utils.get_prof_profile_template(i_prof);
            --
            IF i_prof.software IN (pk_alert_constant.g_soft_outpatient, pk_alert_constant.g_soft_primary_care)
            THEN
                g_error := 'FIND DCS';
                pk_alertlog.log_debug(text            => g_error,
                                      object_name     => g_package_name,
                                      sub_object_name => l_sub_func_name);
                SELECT s.id_dcs_requested
                  INTO l_dep_clin_serv
                  FROM epis_info ei
                  JOIN schedule s
                    ON ei.id_schedule = s.id_schedule
                 WHERE ei.id_episode = i_episode;
            ELSE
                g_error := 'CALL PK_PROF_UTILS.GET_PROF_DCS - GET PROF PREFERRED DEP_CLIN_SERV';
                pk_alertlog.log_debug(text            => g_error,
                                      object_name     => g_package_name,
                                      sub_object_name => l_sub_func_name);
                l_dep_clin_serv := pk_prof_utils.get_prof_dcs(i_prof => i_prof);
            END IF;
        
            g_error := 'GET FILTER VARS';
            BEGIN
                SELECT a.id_institution, a.id_software, nvl(a.id_profile_template, 0), a.id_dep_clin_serv
                  INTO l_filter_inst, l_filter_soft, l_filter_prof_temp, l_filter_dcs
                  FROM (SELECT dtc.id_institution,
                               dtc.id_software,
                               dtc.id_profile_template,
                               dtc.id_dep_clin_serv,
                               row_number() over(ORDER BY dtc.id_institution DESC NULLS LAST, dtc.id_software DESC NULLS LAST, dtc.id_profile_template DESC NULLS LAST, dtc.id_dep_clin_serv DESC NULLS LAST) line_number
                          FROM doc_template_context dtc
                         INNER JOIN doc_template dt
                            ON dtc.id_doc_template = dt.id_doc_template
                         WHERE dtc.flg_type IN (SELECT /*+OPT_ESTIMATE (table t rows=1)*/
                                                 column_value flg_type
                                                  FROM TABLE(l_tbl_dtc_types) t)
                           AND dt.flg_available = pk_alert_constant.g_available
                           AND nvl(dtc.id_institution, pk_alert_constant.g_inst_all) IN
                               (i_prof.institution, pk_alert_constant.g_inst_all)
                           AND nvl(dtc.id_software, pk_alert_constant.g_soft_all) IN
                               (i_prof.software, pk_alert_constant.g_soft_all)
                           AND nvl(dtc.id_profile_template, pk_alert_constant.g_profile_template_all) IN
                               (l_profile_template, pk_alert_constant.g_profile_template_all)
                           AND (dtc.id_dep_clin_serv = l_dep_clin_serv OR dtc.id_dep_clin_serv IS NULL)) a
                 WHERE a.line_number = 1;
            EXCEPTION
                WHEN no_data_found THEN
                    l_filter_inst      := pk_alert_constant.g_inst_all;
                    l_filter_soft      := pk_alert_constant.g_soft_all;
                    l_filter_prof_temp := pk_alert_constant.g_profile_template_all;
                    l_filter_dcs       := -1;
            END;
        
            SELECT DISTINCT c.id_complaint
              BULK COLLECT
              INTO l_tbl_complaints
              FROM complaint c
             INNER JOIN doc_template_context dtc
                ON (c.id_complaint = dtc.id_context AND
                   dtc.flg_type IN (pk_complaint.g_flg_type_c, pk_complaint.g_flg_type_ct))
                OR (c.id_complaint = dtc.id_context_2 AND dtc.flg_type = pk_complaint.g_flg_type_dc)
             INNER JOIN doc_template dt
                ON dtc.id_doc_template = dt.id_doc_template
             WHERE c.flg_available = pk_alert_constant.g_available
               AND dt.flg_available = pk_alert_constant.g_available
               AND nvl(dtc.id_institution, pk_alert_constant.g_inst_all) = l_filter_inst
               AND nvl(dtc.id_software, pk_alert_constant.g_soft_all) = l_filter_soft
               AND nvl(dtc.id_profile_template, pk_alert_constant.g_profile_template_all) = l_filter_prof_temp
               AND (l_filter_dcs IS NULL OR dtc.id_dep_clin_serv = l_filter_dcs)
               AND (c.flg_gender = l_pat_genger OR c.flg_gender IS NULL)
               AND (c.age_min <= l_pat_age OR c.age_min IS NULL OR l_pat_age IS NULL)
               AND (c.age_max >= l_pat_age OR c.age_max IS NULL OR l_pat_age IS NULL)
                  --    AND nvl(l_pat_age, 0) BETWEEN nvl(c.age_min, 0) AND nvl(c.age_max, 999)
               AND dtc.flg_type IN (SELECT /*+OPT_ESTIMATE (table t rows=1)*/
                                     column_value flg_type
                                      FROM TABLE(l_tbl_dtc_types) t);
        
            RETURN l_tbl_complaints;
        END get_complaints_ids;
    BEGIN
        g_error := 'GET CONFIG';
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        l_comp_filter := pk_sysconfig.get_config('COMPLAINT_FILTER', i_prof);
    
        g_error := 'CALL GET_COMPLAINTS_IDS';
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        l_tbl_complaint_ids := get_complaints_ids(i_comp_filter => l_comp_filter);
    
        IF l_comp_filter IN (pk_complaint.g_comp_filter_prf, pk_complaint.g_comp_filter_dcs)
        THEN
            g_error := 'OPEN O_COMPLAINTS PRF';
            pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
            OPEN o_complaints FOR
                SELECT c.id_complaint,
                       pk_translation.get_translation(i_lang, c.code_complaint) desc_complaint,
                       decode(ec.id_epis_complaint, NULL, pk_alert_constant.g_no, pk_alert_constant.g_yes) flg_chosen,
                       decode(ec.id_epis_complaint, NULL, NULL, ec.patient_complaint) patient_complaint,
                       decode(ec.id_epis_complaint, NULL, NULL, ec.patient_complaint_arabic) patient_complaint_arabic,
                       c.rank
                  FROM (SELECT c1.id_complaint, c1.code_complaint, c1.rank
                          FROM complaint c1
                         WHERE c1.id_complaint IN (SELECT /*+OPT_ESTIMATE (table t rows=1)*/
                                                    column_value id_complaint
                                                     FROM TABLE(l_tbl_complaint_ids) t)) c
                  LEFT JOIN epis_complaint ec
                    ON c.id_complaint = ec.id_complaint
                   AND ec.id_episode = i_episode
                   AND ec.id_epis_complaint = i_epis_complaint
                 ORDER BY rank NULLS FIRST, desc_complaint;
        ELSE
            g_error := 'NO COMPLAINT_FILTER(' || i_prof.institution || ',' || i_prof.software || ')';
            pk_alertlog.log_error(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_complaints);
            RETURN error_handling(i_lang, l_func_name, g_error, SQLERRM, FALSE, o_error);
    END get_complaint_list;
    --
    /********************************************************************************************
    * Checks if an episode has complaint template
    *
    * @param i_lang                language id
    * @param i_prof                professional, software and institution ids
    * @param i_episode             episode id
    * @param o_flg_data            Y if there are data, F when no date found
    * @param o_error               Error message
    *
    * @return                      true (sucess), false (error)
    *    
    * @author                      Luís Gaspar
    * @version                     1.0
    * @since                       24-05-2007
    **********************************************************************************************/
    FUNCTION get_complaint_template_exists
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_episode  IN episode.id_episode%TYPE,
        o_flg_data OUT VARCHAR2,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_count NUMBER;
    BEGIN
        g_error := 'COUNT REGISTRIES epis_complaint';
        SELECT COUNT(1)
          INTO l_count
          FROM epis_complaint ec
         WHERE ec.id_episode = i_episode
           AND ec.flg_status = g_active;
        --
        IF l_count > 0
        THEN
            o_flg_data := g_yes;
        ELSE
            SELECT COUNT(1)
              INTO l_count
              FROM epis_triage et
             WHERE et.id_episode = i_episode
               AND (et.dt_begin_tstz = (SELECT MAX(et1.dt_begin_tstz)
                                          FROM epis_triage et1
                                         WHERE et1.id_episode = i_episode) OR et.dt_begin_tstz IS NULL)
               AND et.id_triage_white_reason IS NOT NULL;
        
            IF l_count > 0
            THEN
                o_flg_data := g_yes;
            ELSE
                o_flg_data := g_no;
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN error_handling(i_lang, 'GET_COMPLAINT_TEMPLATE_EXISTS', g_error, SQLERRM, FALSE, o_error);
    END get_complaint_template_exists;
    --
    /********************************************************************************************
    * Registers an episode complaint. 
    *  It is allowed to register complaints only in active episodes.
    *  When a new complaint is registered, any previous complaint and related documentation becomes inactive.
    *
    * @param i_lang                    language id
    * @param i_prof                    professional, software and institution ids
    * @param i_prof_cat_type           professional category
    * @param i_epis                    the episode id
    * @param i_complaint               the complaint id
    * @param i_patient_complaint       the patient complaint
    * @param i_flg_type                type of edition
    * @param i_epis_complaint_parent   the patient complaint
    * @param o_error                   Error message
    *
    * @value i_flg_type                {*} 'N'  New {*} 'E' Edit {*} 'A' Agree {*} 'U' Update from previous assessment {*} 'O' No changes
    *
    * @return                          true (sucess), false (error)
    *
    * @author                          Luís Gaspar & Luís Oliveira, based on pk_documentation.set_epis_complaint
    * @version                         1.0
    * @since                           26-05-2007, 28-08-2007 (multiple template support)
    *
    * Changes:
    *                             Ariel Machado
    *                             1.1   
    *                             2008/05/08
    *                             Added new edit options: Update from previous assessment; No changes;
    **********************************************************************************************/
    FUNCTION set_epis_complaint
    (
        i_lang                     IN language.id_language%TYPE,
        i_prof                     IN profissional,
        i_prof_cat_type            IN category.flg_type%TYPE,
        i_epis                     IN episode.id_episode%TYPE,
        i_complaint                IN complaint.id_complaint%TYPE,
        i_patient_complaint        IN epis_complaint.patient_complaint%TYPE,
        i_patient_complaint_arabic IN epis_complaint.patient_complaint_arabic%TYPE DEFAULT NULL,
        i_flg_reported_by          IN epis_complaint.flg_reported_by%TYPE DEFAULT NULL,
        i_flg_type                 IN VARCHAR2,
        i_epis_complaint_parent    IN epis_complaint.id_epis_complaint%TYPE,
        o_id_epis_complaint        OUT epis_complaint.id_epis_complaint%TYPE,
        o_error                    OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_exception EXCEPTION;
        l_error                    t_error_out;
        l_next                     epis_complaint.id_epis_complaint%TYPE;
        l_act_epis_complaint       epis_complaint.id_epis_complaint%TYPE;
        c_active_complaint         pk_types.cursor_type;
        l_complaint                complaint.id_complaint%TYPE;
        l_patient_complaint        epis_complaint.patient_complaint%TYPE;
        l_patient_complaint_arabic epis_complaint.patient_complaint_arabic%TYPE;
        l_dep_clin_serv            epis_info.id_dep_clin_serv%TYPE;
        l_id_patient               epis_info.id_patient%TYPE;
    
        CURSOR c_prev_epis_complaint IS
            SELECT id_complaint, patient_complaint, patient_complaint_arabic
              FROM epis_complaint
             WHERE id_epis_complaint = i_epis_complaint_parent;
    
        l_rows table_varchar := table_varchar();
    BEGIN
        SELECT ei.id_dcs_requested
          INTO l_dep_clin_serv
          FROM epis_info ei
         INNER JOIN episode e
            ON ei.id_episode = e.id_episode
         WHERE e.id_episode = i_epis;
    
        g_sysdate      := SYSDATE;
        g_sysdate_tstz := current_timestamp;
        --
        g_error := 'GET SEQ_EPIS_COMPLAINT.NEXTVAL';
        l_next  := ts_epis_complaint.next_key;
        --
        g_error := 'GET ACTIVE EPIS_COMPLAINT';
        OPEN c_active_complaint FOR
            SELECT id_epis_complaint
              FROM epis_complaint ec
             WHERE ec.id_episode = i_epis
               AND ec.flg_status = g_complaint_act
               AND ec.id_complaint = i_complaint;
        --    
        FETCH c_active_complaint
            INTO l_act_epis_complaint;
        CLOSE c_active_complaint;
        --
        IF (i_epis_complaint_parent IS NOT NULL AND i_flg_type = g_flg_edition_type_edit)
        THEN
            -- only when editing the previous complaint became inactive
            g_error := 'UPDATE EPIS_COMPLAINT - EDIT';
            l_rows  := table_varchar();
            ts_epis_complaint.upd(flg_status_in => g_complaint_out,
                                  where_in      => 'id_episode = ' || i_epis || ' and id_epis_complaint = ' ||
                                                   i_epis_complaint_parent,
                                  rows_out      => l_rows);
        
            g_error := 't_data_gov_mnt.process_update ts_epis_complaint';
            t_data_gov_mnt.process_update(i_lang         => i_lang,
                                          i_prof         => i_prof,
                                          i_table_name   => 'EPIS_COMPLAINT',
                                          i_rowids       => l_rows,
                                          o_error        => o_error,
                                          i_list_columns => table_varchar('FLG_STATUS'));
        END IF;
        --
    
        IF (i_flg_type = g_flg_edition_type_nochanges)
        THEN
            --No changes edition. 
            --Copies the values from previous record and creates a new record using current professional
            IF (i_epis_complaint_parent IS NULL)
            THEN
                -- Checking: flg_type = no changes, but previous record was not defined
                g_error := 'NO CHANGES WITHOUT ID_EPIS_COMPLAINT PARAMETER';
                RAISE g_exception;
            END IF;
        
            g_error := 'GET EPIS_OBSERVATION';
            OPEN c_prev_epis_complaint;
            FETCH c_prev_epis_complaint
                INTO l_complaint, l_patient_complaint, l_patient_complaint_arabic;
            CLOSE c_prev_epis_complaint;
        ELSE
            --Editions of type New,Edit,Agree,Update. 
            --Creates a new record using the arguments passed to function
            l_complaint                := i_complaint;
            l_patient_complaint        := i_patient_complaint;
            l_patient_complaint_arabic := i_patient_complaint_arabic;
        END IF;
    
        g_error := 'INSERT EPIS_COMPLAINT';
        l_rows  := table_varchar();
        ts_epis_complaint.ins(id_epis_complaint_in        => l_next,
                              id_episode_in               => i_epis,
                              id_professional_in          => i_prof.id,
                              id_complaint_in             => l_complaint,
                              adw_last_update_tstz_in     => g_sysdate_tstz,
                              patient_complaint_in        => l_patient_complaint,
                              flg_status_in               => g_complaint_act,
                              id_epis_complaint_parent_in => i_epis_complaint_parent,
                              flg_edition_type_in         => i_flg_type,
                              flg_reported_by_in          => i_flg_reported_by,
                              patient_complaint_arabic_in => l_patient_complaint_arabic,
                              id_dep_clin_serv_in         => l_dep_clin_serv,
                              rows_out                    => l_rows);
    
        g_error := 'PROCESS INSERT WITH ID_EPIS_COMPLAINT ' || l_next;
        pk_alertlog.log_debug(g_error);
        t_data_gov_mnt.process_insert(i_lang, i_prof, 'EPIS_COMPLAINT', l_rows, o_error);
    
        --
        IF (l_act_epis_complaint IS NOT NULL)
        THEN
            -- because we need to keep patient complaint changes/history and only one epis_complaint with (episodeXcomplaint) 
            -- record may be active
            g_error := 'UPDATING EPIS_DOCUMENTATION';
            l_rows  := NULL;
            ts_epis_documentation.upd(id_epis_complaint_in => l_next,
                                      where_in             => ' id_epis_complaint = ' || l_act_epis_complaint,
                                      rows_out             => l_rows);
        
            t_data_gov_mnt.process_update(i_lang         => i_lang,
                                          i_prof         => i_prof,
                                          i_table_name   => 'EPIS_DOCUMENTATION',
                                          i_rowids       => l_rows,
                                          o_error        => o_error,
                                          i_list_columns => table_varchar('ID_EPIS_COMPLAINT'));
        END IF;
        --
        -- if new complaint is diferent from previous active complaint, previous active complaint records at epis_documentation
        -- do not became inactive
        --
        IF i_prof.software = pk_alert_constant.g_soft_outpatient
        THEN
            SELECT ei.id_patient
              INTO l_id_patient
              FROM epis_info ei
             INNER JOIN episode e
                ON ei.id_episode = e.id_episode
             WHERE e.id_episode = i_epis;
    
            pk_progress_notes.set_templates(i_lang    => i_lang,
                                            i_prof    => i_prof,
                                            i_episode => i_epis,
                                            i_patient => l_id_patient,
                                            i_id_ec   => l_next,
                                            o_error   => o_error);
        ELSE
        --Update episode's templates by complaint
        IF NOT pk_touch_option.update_epis_tmplt_by_complaint(i_lang           => i_lang,
                                                              i_prof           => i_prof,
                                                              i_episode        => i_epis,
                                                              i_epis_complaint => l_next,
                                                              i_do_commit      => pk_alert_constant.g_no,
                                                              o_error          => l_error)
        THEN
            RAISE l_exception;
        END IF;
        END IF;
    
        g_error := 'CALL TO SET_FIRST_OBS';
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => i_epis,
                                      i_pat                 => NULL,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => i_prof_cat_type,
                                      i_dt_last_interaction => g_sysdate_tstz,
                                      i_dt_first_obs        => g_sysdate_tstz,
                                      o_error               => l_error)
        THEN
            RAISE l_exception;
        END IF;
    
        o_id_epis_complaint := l_next;
    
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_exception THEN
            RETURN error_handling(i_lang,
                                  'SET_EPIS_COMPLAINT',
                                  g_error || ' / ' || l_error.err_desc,
                                  SQLERRM,
                                  TRUE,
                                  o_error);
        WHEN OTHERS THEN
            RETURN error_handling(i_lang, 'SET_EPIS_COMPLAINT', g_error, SQLERRM, TRUE, o_error);
    END set_epis_complaint;

    /********************************************************************************************
    * Registers an episode set of complaints.
    * It is allowed to register complaints only in active episodes.
    * When a new complaint is registered, any previous complaint and related documentation becomes inactive.
    *
    * @param i_lang                    language id
    * @param i_prof                    professional, software and institution ids
    * @param i_prof_cat_type           professional category
    * @param i_epis                    the episode id
    * @param i_complaint               the array of complaint ids
    * @param i_patient_complaint       the array of patient complaints
    * @param i_flg_type                array of types of edition
    * @param i_epis_complaint_parent   array of ids for the complaint parents
    * @param o_error                   Error message
    *
    * @value i_flg_type                {*} 'N'  New {*} 'E' Edit {*} 'A' Agree {*} 'U' Update from previous assessment {*} 'O' No changes
    *
    * @return                          true (sucess), false (error)
    **********************************************************************************************/
    FUNCTION set_epis_complaints
    (
        i_lang                     IN language.id_language%TYPE,
        i_prof                     IN profissional,
        i_prof_cat_type            IN category.flg_type%TYPE,
        i_epis                     IN episode.id_episode%TYPE,
        i_complaint                IN table_number,
        i_patient_complaint        IN table_varchar,
        i_patient_complaint_arabic IN table_varchar DEFAULT NULL,
        i_flg_type                 IN table_varchar,
        i_epis_complaint_parent    IN table_number,
        o_id_epis_complaint        OUT table_number,
        o_error                    OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_exception EXCEPTION;
        l_id_epis_complaint     epis_complaint.id_epis_complaint%TYPE;
        l_tbl_id_epis_complaint table_number := table_number();
    
    BEGIN
    
        FOR i IN i_complaint.first .. i_complaint.last
        LOOP
        
            IF NOT set_epis_complaint(i_lang                     => i_lang,
                                      i_prof                     => i_prof,
                                      i_prof_cat_type            => i_prof_cat_type,
                                      i_epis                     => i_epis,
                                      i_complaint                => i_complaint(i),
                                      i_patient_complaint        => i_patient_complaint(i),
                                      i_patient_complaint_arabic => i_patient_complaint_arabic(i),
                                      i_flg_reported_by          => NULL,
                                      i_flg_type                 => i_flg_type(i),
                                      i_epis_complaint_parent    => i_epis_complaint_parent(i),
                                      o_id_epis_complaint        => l_id_epis_complaint,
                                      o_error                    => o_error)
            THEN
                RAISE l_exception;
            END IF;
        
            l_tbl_id_epis_complaint.extend();
            l_tbl_id_epis_complaint(i) := l_id_epis_complaint;
        
        END LOOP;
    
        o_id_epis_complaint := l_tbl_id_epis_complaint;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_exception THEN
            RETURN error_handling(i_lang,
                                  'SET_EPIS_COMPLAINTS',
                                  g_error || ' / ' || o_error.err_desc,
                                  SQLERRM,
                                  TRUE,
                                  o_error);
        WHEN OTHERS THEN
            RETURN error_handling(i_lang, 'SET_EPIS_COMPLAINTS', g_error, SQLERRM, TRUE, o_error);
    END set_epis_complaints;

    /********************************************************************************************
    * Registers an episode set of complaints.
    * It is allowed to register complaints only in active episodes.
    * When a new complaint is registered, any previous complaint and related documentation becomes inactive.
    *
    * @param i_lang                    language id
    * @param i_prof                    professional, software and institution ids
    * @param i_prof_cat_type           professional category
    * @param i_epis                    the episode id
    * @param i_complaint               the array of complaint ids
    * @param i_patient_complaint       the array of patient complaints
    * @param i_flg_type                array of types of edition
    * @param i_id_epis_complaint_root  array of ids for the complaint parents
    * @param o_error                   Error message
    *
    * @value i_flg_type                {*} 'N'  New {*} 'E' Edit {*} 'A' Agree {*} 'U' Update from previous assessment {*} 'O' No changes
    *
    * @return                          true (sucess), false (error)
    **********************************************************************************************/
    /********************************************************************************************
    * Gets doc_template from the complaint. 
    *
    * @param i_lang              language id
    * @param i_prof              professional, software and institution ids
    * @param i_episode           the episode id
    * @param i_complaint         the complaint id
    * @param o_doc_template      the doc template id
    * @param o_error             Error message
    *
    * @return                    true (sucess), false (error)
    *
    * @author                    Luís Gaspar & Luís Oliveira, based on pk_documentation.set_epis_complaint
    * @version                   1.0
    * @since                     26-05-2007
    **********************************************************************************************/
    FUNCTION get_complaint_template
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_patient      IN patient.id_patient%TYPE,
        o_doc_template OUT doc_template.id_doc_template%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        CURSOR c_complaint IS
            SELECT ec.id_complaint
              FROM epis_complaint ec
             WHERE ec.id_episode = i_episode
               AND ec.flg_status = g_complaint_act;
    
        CURSOR c_patient_info IS
            SELECT p.gender, nvl(p.age, trunc(months_between(SYSDATE, p.dt_birth) / 12, 0)) age
              FROM patient p
             WHERE p.id_patient = i_patient;
    
        l_id_complaint complaint.id_complaint%TYPE;
        l_gender       VARCHAR2(1);
        l_age          VARCHAR2(20);
        o_cursor       pk_types.cursor_type;
        l_comp_filter  VARCHAR2(100);
    BEGIN
        g_error := 'GET CURSOR C_PATIENT_INFO';
        OPEN c_patient_info;
        FETCH c_patient_info
            INTO l_gender, l_age;
        CLOSE c_patient_info;
        --
        g_error       := 'GET CONFIG';
        l_comp_filter := pk_sysconfig.get_config('COMPLAINT_FILTER', i_prof);
        --    
        g_error := 'GET_COMPLAINT';
        OPEN c_complaint;
        FETCH c_complaint
            INTO l_id_complaint;
        CLOSE c_complaint;
        --
        IF (l_id_complaint IS NOT NULL)
        THEN
            IF l_comp_filter = g_comp_filter_prf
            THEN
                -- Touch Option em função do PROF_PROFILE_TEMPLATE
                g_error := 'OPEN O_COMPLAINTS PRF';
                pk_utils.put_line(g_error);
                OPEN o_cursor FOR
                    SELECT dtc.id_doc_template
                      FROM complaint c, doc_template dt, doc_template_context dtc, prof_profile_template ppt
                     WHERE c.id_complaint = l_id_complaint
                       AND c.id_complaint = dtc.id_context
                       AND dtc.flg_type = g_flg_type_c
                       AND c.flg_available = g_available
                          --filtar templates adequados ao paciente
                       AND dt.id_doc_template = dtc.id_doc_template
                       AND pk_patient.validate_pat_gender(l_gender, dt.flg_gender) = 1
                       AND (dt.age_min <= l_age OR dt.age_min IS NULL OR l_age IS NULL)
                       AND (dt.age_max >= l_age OR dt.age_max IS NULL OR l_age IS NULL)
                       AND dt.flg_available = g_available
                          --ler prefs gerais
                       AND ppt.id_profile_template = dtc.id_profile_template
                          --ler prefs pessoais
                       AND ppt.id_professional = i_prof.id
                       AND ppt.id_institution = i_prof.institution
                       AND ppt.id_software = i_prof.software
                       AND dtc.id_software = i_prof.software
                       AND dtc.id_institution IN (0, i_prof.institution)
                     ORDER BY dtc.id_institution DESC, dt.age_min DESC NULLS LAST, dt.age_max DESC NULLS LAST;
            
            ELSIF l_comp_filter = g_comp_filter_dcs
            THEN
                -- Touch Option em função do ID_DEP_CLIN_SERV
                g_error := 'OPEN O_COMPLAINTS DCS';
                pk_utils.put_line(g_error);
                OPEN o_cursor FOR
                    SELECT dtc.id_doc_template
                      FROM complaint             c,
                           doc_template          dt,
                           doc_template_context  dtc,
                           profile_template      pt,
                           epis_info             ei,
                           prof_profile_template ppt
                     WHERE c.id_complaint = l_id_complaint
                       AND c.id_complaint = dtc.id_context
                       AND dtc.flg_type = g_flg_type_c
                       AND c.flg_available = g_available
                          --filtar templates adequados ao paciente
                       AND dt.id_doc_template = dtc.id_doc_template
                       AND pk_patient.validate_pat_gender(l_gender, dt.flg_gender) = 1
                       AND (dt.age_min <= l_age OR dt.age_min IS NULL OR l_age IS NULL)
                       AND (dt.age_max >= l_age OR dt.age_max IS NULL OR l_age IS NULL)
                       AND dt.flg_available = g_available
                       AND dtc.id_dep_clin_serv = ei.id_dcs_requested
                       AND ei.id_episode = i_episode
                       AND dtc.id_software = i_prof.software
                       AND dtc.id_institution IN (0, i_prof.institution)
                       AND ppt.id_professional = i_prof.id
                       AND ppt.id_software = i_prof.software
                       AND ppt.id_institution = i_prof.institution
                       AND ppt.id_profile_template = dtc.id_profile_template
                     ORDER BY dtc.id_institution DESC, dt.age_min DESC NULLS LAST, dt.age_max DESC NULLS LAST;
            ELSE
                g_error := 'NO COMPLAINT_FILTER(' || i_prof.institution || ',' || i_prof.software || ')';
                RAISE g_exception;
            END IF;
        ELSE
            g_error := 'NO ACTIVE COMPLAINT IN EPISODE';
            RAISE g_exception;
        END IF;
        --
        FETCH o_cursor
            INTO o_doc_template;
        CLOSE o_cursor;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN error_handling(i_lang, 'GET_COMPLAINT_TEMPLATE', g_error, SQLERRM, FALSE, o_error);
    END;
    --
    /**************************************************************************************************************************************************************************************
    * Devolver a queixas selecionadas para o episódio
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_episode                the id episode
    * @param o_complaint_register     cursor with the complaint info register
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Emília Taborda
    * @version                        1.0
    * @since                          2007/05/29
    *
    * @author                         José Silva
    * @version                        1.1
    * @since                          2007/10/15
    *
    * QUANDO SE ALTERAR ESSA FUNÇÃO NÃO SE ESQUECER DE TAMBÉM ALTERAR A FUNÇÃO DOS REPORTS
    **********************************************************************************************/
    FUNCTION get_summ_page_complaint_value
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_episode            IN episode.id_episode%TYPE,
        o_complaint_register OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        IF NOT get_all_complaint_value(i_lang               => i_lang,
                                       i_prof               => i_prof,
                                       i_episode            => table_number(i_episode),
                                       o_complaint_register => o_complaint_register,
                                       o_error              => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_complaint_register);
            RETURN error_handling(i_lang, 'GET_SUMM_PAGE_COMPLAINT_VALUE', g_error, SQLERRM, FALSE, o_error);
    END;

    /**************************************************************************************************************************************************************************************
    * Devolver a queixas selecionadas pelos os episódios introduzidos
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_episode                the id episode table number
    * @param o_complaint_register     cursor with the complaint info register
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Jorge Silva
    * @version                        1.0
    * @since                          2013/09/25
    **********************************************************************************************/
    FUNCTION get_all_complaint_value
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_episode            IN table_number,
        o_complaint_register OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        flg_table_temp table_varchar := table_varchar();
        l_order_by     sys_config.value%TYPE;
    
    BEGIN
        -- determinar ordenação parametrizada para a instituição
        l_order_by := pk_sysconfig.get_config('HISTORY_ORDER_BY', i_prof);
        l_order_by := nvl(l_order_by, 'DESC');
        --
    
        g_error := 'GET CURSOR O_COMPLAINT_REGISTER';
        OPEN o_complaint_register FOR
            SELECT decode(l_order_by, 'DESC', 1, 'ASC', -1) * (SYSDATE - ec.adw_last_update_tstz) order_by_default,
                   ec.id_epis_complaint,
                   ec.id_epis_complaint_root,
                   pk_date_utils.date_send_tsz(i_lang, ec.adw_last_update_tstz, i_prof) dt_creation,
                   pk_date_utils.date_char_tsz(i_lang, ec.adw_last_update_tstz, i_prof.institution, i_prof.software) dt_complaint_register,
                   ec.id_professional,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, ec.id_professional) nick_name,
                   pk_prof_utils.get_spec_signature(i_lang,
                                                    i_prof,
                                                    ec.id_professional,
                                                    ec.adw_last_update_tstz,
                                                    ec.id_episode) desc_speciality,
                   ec.id_complaint,
                   (SELECT pk_complaint.get_multi_complaint_desc(i_lang, i_prof, ec.id_epis_complaint)
                      FROM dual) desc_complaint,
                   --  pk_translation.get_translation(i_lang, 'COMPLAINT.CODE_COMPLAINT.' || ec.id_complaint) desc_complaint,
                   g_doc_area_complaint id_doc_area,
                   ec.flg_status,
                   decode(ec.flg_status,
                          g_active,
                          NULL,
                          pk_sysdomain.get_domain('EPIS_COMPLAINT.FLG_STATUS', ec.flg_status, i_lang)) desc_status,
                   ec.patient_complaint,
                   ec.id_epis_complaint_parent PARENT,
                   ec.flg_reported_by,
                   (SELECT pk_sysdomain.get_domain('EPIS_COMPLAINT.FLG_REPORTED_BY', ec.flg_reported_by, i_lang)
                      FROM dual) desc_reported_by,
                   ec.id_dep_clin_serv,
                   (SELECT pk_translation.get_translation(i_lang, cs.code_clinical_service)
                      FROM dep_clin_serv dcs, clinical_service cs
                     WHERE dcs.id_clinical_service = cs.id_clinical_service
                       AND dcs.id_dep_clin_serv = ec.id_dep_clin_serv) desc_appoint_type,
                   -- template(s) seleccionado(s) para documentação do episodio
                   pk_utils.concatenate_list(CURSOR (SELECT pk_translation.get_translation(i_lang,
                                                                                    'DOC_TEMPLATE.CODE_DOC_TEMPLATE.' ||
                                                                                    edoc.id_doc_template) desc_t
                                                FROM epis_doc_template edoc
                                               WHERE edoc.id_epis_complaint = ec.id_epis_complaint),
                                             '; ') desc_doc_template,
                   pk_utils.concatenate_list(CURSOR (SELECT edoc.id_doc_template
                                                FROM epis_doc_template edoc
                                               WHERE edoc.id_epis_complaint = ec.id_epis_complaint),
                                             ';') id_doc_template,
                   g_touch_option flg_type_register,
                   CASE
                        WHEN ec.id_cancel_info_det IS NULL THEN
                         NULL
                        ELSE
                         pk_paramedical_prof_core.get_notes_desc(i_lang, i_prof, ec.id_cancel_info_det)
                    END notes_cancel,
                   CASE
                        WHEN ec.id_cancel_info_det IS NULL THEN
                         NULL
                        ELSE
                         pk_paramedical_prof_core.get_cancel_reason_desc(i_lang, i_prof, ec.id_cancel_info_det)
                    END cancel_reason_desc
              FROM epis_complaint ec
             WHERE ec.id_episode IN (SELECT /*+OPT_ESTIMATE (TABLE j ROWS=0.00000000001)*/
                                      j.column_value
                                       FROM TABLE(i_episode) j)
               AND ec.id_epis_complaint_root IS NULL
            UNION ALL
            --Queixa / História -Free text
            SELECT decode(l_order_by, 'DESC', 1, 'ASC', -1) * (SYSDATE - ea.dt_epis_anamnesis_tstz) order_by_default,
                   ea.id_epis_anamnesis id_epis_complaint,
                   NULL id_epis_complaint_root,
                   pk_date_utils.date_send_tsz(i_lang, ea.dt_epis_anamnesis_tstz, i_prof) dt_creation,
                   pk_date_utils.date_char_tsz(i_lang, ea.dt_epis_anamnesis_tstz, i_prof.institution, i_prof.software) dt_register,
                   ea.id_professional,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, ea.id_professional) nick_name,
                   pk_prof_utils.get_spec_signature(i_lang,
                                                    i_prof,
                                                    ea.id_professional,
                                                    ea.dt_epis_anamnesis_tstz,
                                                    ea.id_episode) desc_speciality,
                   NULL id_complaint,
                   NULL desc_complaint,
                   g_doc_area_complaint id_doc_area,
                   ea.flg_status flg_status,
                   decode(ea.flg_status,
                          g_active,
                          NULL,
                          pk_sysdomain.get_domain('EPIS_ANAMNESIS.FLG_STATUS', ea.flg_status, i_lang)) desc_status,
                   pk_string_utils.clob_to_sqlvarchar2(ea.desc_epis_anamnesis) patient_complaint,
                   ea.id_epis_anamnesis_parent PARENT,
                   NULL flg_reported_by,
                   NULL desc_reported_by,
                   NULL id_dep_clin_serv,
                   NULL desc_appoint_type,
                   NULL desc_doc_template,
                   NULL id_doc_template,
                   g_free_text flg_type_register,
                   CASE
                       WHEN ea.id_cancel_info_det IS NULL THEN
                        NULL
                       ELSE
                        pk_paramedical_prof_core.get_notes_desc(i_lang, i_prof, ea.id_cancel_info_det)
                   END notes_cancel,
                   CASE
                       WHEN ea.id_cancel_info_det IS NULL THEN
                        NULL
                       ELSE
                        pk_paramedical_prof_core.get_cancel_reason_desc(i_lang, i_prof, ea.id_cancel_info_det)
                   END cancel_reason_desc
              FROM epis_anamnesis ea
             WHERE ea.id_episode IN (SELECT /*+OPT_ESTIMATE (TABLE j ROWS=0.00000000001)*/
                                      j.column_value
                                       FROM TABLE(i_episode) j)
               AND ea.flg_type = g_epis_anam_flg_type_c
               AND ea.dt_epis_anamnesis_tstz = decode(ea.flg_temp,
                                                      g_flg_temp_t,
                                                      (SELECT MAX(dt_epis_anamnesis_tstz)
                                                         FROM epis_anamnesis ea1
                                                        WHERE ea1.id_episode = ea.id_episode
                                                          AND ea1.flg_type = g_epis_anam_flg_type_c
                                                          AND ea1.flg_temp = ea.flg_temp),
                                                      ea.dt_epis_anamnesis_tstz)
            UNION ALL
            SELECT decode(l_order_by, 'DESC', 1, 'ASC', -1) * (SYSDATE - et.dt_begin_tstz) order_by_default,
                   NULL id_epis_complaint,
                   NULL id_epis_complaint_root,
                   pk_date_utils.date_send_tsz(i_lang, et.dt_begin_tstz, i_prof) dt_creation,
                   pk_date_utils.date_char_tsz(i_lang, et.dt_begin_tstz, i_prof.institution, i_prof.software) dt_register,
                   et.id_professional,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, et.id_professional) nick_name,
                   pk_prof_utils.get_spec_signature(i_lang, i_prof, et.id_professional, et.dt_begin_tstz, et.id_episode) desc_speciality,
                   NULL id_complaint,
                   NULL desc_complaint,
                   g_doc_area_complaint id_doc_area,
                   'A' flg_status,
                   NULL desc_status,
                   decode(et.id_triage_white_reason,
                          NULL,
                          NULL,
                          nvl2(et.notes,
                               pk_message.get_message(i_lang, 'TRIAGE_T013') || ' - ' ||
                               pk_translation.get_translation(i_lang,
                                                              'TRIAGE_WHITE_REASON.CODE_TRIAGE_WHITE_REASON.' ||
                                                              et.id_triage_white_reason) || ': ' || et.notes,
                               pk_message.get_message(i_lang, 'TRIAGE_T013') || ' - ' ||
                               pk_translation.get_translation(i_lang,
                                                              'TRIAGE_WHITE_REASON.CODE_TRIAGE_WHITE_REASON.' ||
                                                              et.id_triage_white_reason))) patient_complaint,
                   NULL PARENT,
                   NULL flg_reported_by,
                   NULL desc_reported_by,
                   NULL id_dep_clin_serv,
                   NULL desc_appoint_type,
                   NULL desc_doc_template,
                   NULL id_doc_template,
                   g_free_text flg_type_register,
                   NULL notes_cancel,
                   NULL cancel_reason_desc
              FROM epis_triage et
             WHERE et.id_episode IN (SELECT /*+OPT_ESTIMATE (TABLE j ROWS=0.00000000001)*/
                                      j.column_value
                                       FROM TABLE(i_episode) j)
               AND (et.dt_begin_tstz = (SELECT MAX(et1.dt_begin_tstz)
                                          FROM epis_triage et1
                                         WHERE et1.id_episode IN (SELECT /*+OPT_ESTIMATE (TABLE j ROWS=0.00000000001)*/
                                                                   j.column_value
                                                                    FROM TABLE(i_episode) j)) OR
                   et.dt_begin_tstz IS NULL)
               AND et.id_triage_white_reason IS NOT NULL
             ORDER BY order_by_default, desc_complaint;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_complaint_register);
            RETURN error_handling(i_lang, 'GET_SUMM_PAGE_COMPLAINT_VALUE', g_error, SQLERRM, FALSE, o_error);
    END;
    /**************************************************************************************************************************************************************************************
    * Devolver a queixas selecionadas para o episódio para os reports
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_patient                patient id
    * @param i_episode                the id episode
    * @param i_flg_scope              Scope(P-Patient, E-Episode)
    * @param o_complaint_register     cursor with the complaint info register
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Jorge Silva
    * @version                        1.0
    * @since                          2013/09/25
    **********************************************************************************************/
    FUNCTION get_complaint_report
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_patient            IN patient.id_patient%TYPE,
        i_episode            IN episode.id_episode%TYPE,
        i_flg_scope          IN VARCHAR2,
        o_complaint_register OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_episode table_number := table_number();
    BEGIN
        --find list of episodes
        l_episode := pk_patient.get_episode_list(i_lang              => i_lang,
                                                 i_prof              => i_prof,
                                                 i_id_patient        => i_patient,
                                                 i_id_episode        => i_episode,
                                                 i_flg_visit_or_epis => i_flg_scope);
    
        IF NOT get_all_complaint_value(i_lang               => i_lang,
                                       i_prof               => i_prof,
                                       i_episode            => l_episode,
                                       o_complaint_register => o_complaint_register,
                                       o_error              => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    END get_complaint_report;

    /********************************************************************************************
    * Devolver o profissional que efectou a última alteração e respectiva data. 
    *
    * @param i_lang                   The language ID
    * @param i_prof_id                professional ID
    * @param i_prof_inst              institution ID, 
    * @param i_prof_sw                software ID)
    * @param i_episode                the episode ID
    * @param i_doc_area               Array with the doc area ID
    * @param o_last_update            Containing the ID of last update register
                                          
    * @param o_error                  Error message
                        
    * @return                         true or false on success or error
    * 
    * @author                         Rui Spratley
    * @since                          2007/10/12
    **********************************************************************************************/

    FUNCTION get_summ_pg_comp_value_reports
    (
        i_lang               IN language.id_language%TYPE,
        i_prof_id            IN professional.id_professional%TYPE,
        i_prof_inst          IN institution.id_institution%TYPE,
        i_prof_sw            IN software.id_software%TYPE,
        i_episode            IN episode.id_episode%TYPE,
        o_complaint_register OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
        i_prof profissional := profissional(i_prof_id, i_prof_inst, i_prof_sw);
    
    BEGIN
    
        RETURN get_summ_page_complaint_value(i_lang, i_prof, i_episode, o_complaint_register, o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_complaint_register);
            RETURN error_handling(i_lang, 'GET_SUMM_PG_COMP_VALUE_REPORTS', g_error, SQLERRM, FALSE, o_error);
        
    END;
    --
    /**************************************************************************************************************************************************************************************
    * Devolver o profissional que efectou a última alteração e respectiva data. 
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_episode                the episode ID
    * @param i_doc_area               Array with the doc area ID
    * @param o_last_update            Cursor containing the last update register
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Emília Taborda
    * @version                        1.0
    * @since                          2007/06/01
    **********************************************************************************************/
    FUNCTION get_epis_complaint_last_update
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_episode     IN episode.id_episode%TYPE,
        i_doc_area    IN table_number,
        o_last_update OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        OPEN o_last_update FOR
            SELECT pk_date_utils.date_send_tsz(i_lang, ec.adw_last_update_tstz, i_prof) adw_last_update,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, ec.id_professional) nick_name,
                   pk_prof_utils.get_spec_signature(i_lang,
                                                    i_prof,
                                                    ec.id_professional,
                                                    ec.adw_last_update_tstz,
                                                    ec.id_episode) desc_speciality,
                   pk_date_utils.date_chr_short_read_tsz(i_lang, ec.adw_last_update_tstz, i_prof) date_target,
                   pk_date_utils.date_char_hour_tsz(i_lang,
                                                    ec.adw_last_update_tstz,
                                                    i_prof.institution,
                                                    i_prof.software) hour_target,
                   pk_date_utils.date_char_tsz(i_lang, ec.adw_last_update_tstz, i_prof.institution, i_prof.software) date_hour_target
              FROM epis_complaint ec
             WHERE ec.id_episode = i_episode
               AND g_doc_area_complaint IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                             t.column_value
                                              FROM TABLE(i_doc_area) t)
               AND ec.adw_last_update_tstz =
                   (SELECT MAX(ec1.adw_last_update_tstz)
                      FROM epis_complaint ec1
                     WHERE ec1.id_episode = i_episode
                       AND g_doc_area_complaint IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                     t.column_value
                                                      FROM TABLE(i_doc_area) t));
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_last_update);
            RETURN error_handling(i_lang, 'GET_EPIS_COMPLAINT_LAST_UPDATE', g_error, SQLERRM, FALSE, o_error);
    END;
    --
    /********************************************************************************************
    * Get the complaint description associated to an episode complaint record
    *
    * @param i_lang                language id
    * @param i_prof                professional, software and institution ids
    * @param i_scope_complaint     Scope of the chief complaint
    * @param i_chief_complaint     Chief/Patient complaint
    * @param i_flg_hide_scope      Chief complaint can replace the scope in the description: (Y)es, (N)o
    *
    * @return                      complaint description
    *     
    * @author                      José Silva
    * @version                     2.5.1.2
    * @since                       2010/10/26
    **********************************************************************************************/
    FUNCTION get_epis_complaint_desc
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_scope_complaint IN VARCHAR2,
        i_chief_complaint IN epis_complaint.patient_complaint%TYPE,
        i_flg_hide_scope  IN VARCHAR2 DEFAULT 'Y'
    ) RETURN VARCHAR2 IS
    
        l_ret pk_translation.t_desc_translation;
    
    BEGIN
    
        IF i_flg_hide_scope = pk_alert_constant.g_yes
           AND (i_scope_complaint IS NULL OR i_scope_complaint = '--')
        THEN
            l_ret := i_chief_complaint;
        ELSIF i_flg_hide_scope = pk_alert_constant.g_yes
              AND (i_chief_complaint IS NULL OR i_chief_complaint = '--')
        THEN
            l_ret := i_scope_complaint;
        ELSIF i_chief_complaint IS NOT NULL
              OR i_scope_complaint IS NOT NULL
        THEN
            l_ret := nvl(i_chief_complaint, '--') || ' (' || nvl(i_scope_complaint, '--') || ')';
        END IF;
    
        RETURN l_ret;
    
    END get_epis_complaint_desc;

    FUNCTION get_epis_complaint_desc_full
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_scope_complaint IN VARCHAR2,
        i_chief_complaint IN CLOB,
        i_flg_hide_scope  IN VARCHAR2 DEFAULT 'Y'
    ) RETURN CLOB IS
    
        l_ret CLOB;
    
    BEGIN
    
        IF i_flg_hide_scope = pk_alert_constant.g_yes
           AND (i_scope_complaint IS NULL OR i_scope_complaint = '--')
        THEN
            l_ret := i_chief_complaint;
        ELSIF i_flg_hide_scope = pk_alert_constant.g_yes
              AND (dbms_lob.compare(i_chief_complaint, empty_clob()) = 0 OR i_chief_complaint = '--')
        THEN
            l_ret := i_scope_complaint;
        ELSIF dbms_lob.compare(i_chief_complaint, empty_clob()) <> 0
              OR i_scope_complaint IS NOT NULL
        THEN
            l_ret := nvl(i_chief_complaint, '--') || ' (' || nvl(i_scope_complaint, '--') || ')';
        END IF;
    
        RETURN l_ret;
    
    END get_epis_complaint_desc_full;
    --
    FUNCTION get_epis_complaint
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        i_epis_docum     IN epis_documentation.id_epis_documentation%TYPE,
        o_epis_complaint OUT epis_complaint_cur,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_exception EXCEPTION;
    BEGIN
    
        IF NOT get_epis_complaint(i_lang           => i_lang,
                                  i_prof           => i_prof,
                                  i_episode        => i_episode,
                                  i_epis_docum     => i_epis_docum,
                                  i_flg_only_scope => pk_alert_constant.g_no,
                                  o_epis_complaint => o_epis_complaint,
                                  o_error          => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        RETURN TRUE;
        --        
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_epis_complaint);
            RETURN error_handling(i_lang, 'GET_EPIS_COMPLAINT', g_error, SQLERRM, FALSE, o_error);
    END;
    --
    /********************************************************************************************
    * Devolver a queixa activa do episódio
    *
    * @param i_lang                language id
    * @param i_prof                professional, software and institution ids
    * @param i_episode             episode id
    * @param i_epis_docum          epis_documentation id   
    * @param i_flg_only_scope      Returns only the scope of chief complaint: Y - yes, N - No
    * @param i_flg_single_row      Returns only the first row
    * @param o_epis_complaint      array with values of complaint episode            
    * @param o_error               Error message
    *
    * @return                      true (sucess), false (error)
    *     
    * @author                      Emília Taborda
    * @version                     1.0
    * @since                       2007/06/04
    **********************************************************************************************/
    FUNCTION get_epis_complaint
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        i_epis_docum     IN epis_documentation.id_epis_documentation%TYPE,
        i_flg_only_scope IN VARCHAR2,
        i_flg_single_row IN VARCHAR2 DEFAULT 'Y',
        o_epis_complaint OUT epis_complaint_cur,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        IF i_epis_docum IS NULL
        THEN
            g_error := 'OPEN O_EPIS_COMPLAINT - new';
            OPEN o_epis_complaint FOR
                SELECT compl.id,
                       compl.id_epis_complaint,
                       compl.desc_complaint,
                       compl.patient_complaint,
                       compl.patient_complaint_full,
                       compl.desc_doc_template,
                       compl.dt_reg,
                       compl.id_professional,
                       compl.reg_type,
                       compl.patient_complaint_arabic
                  FROM (SELECT ec.id_epis_complaint id,
                               ec.id_epis_complaint,
                               pk_translation.get_translation(i_lang, c.code_complaint) desc_complaint,
                               decode(i_flg_only_scope,
                                      pk_alert_constant.g_no,
                                      nvl(ec.patient_complaint,
                                          (SELECT desc_anamnesis
                                             FROM (SELECT pk_string_utils.clob_to_sqlvarchar2(ea.desc_epis_anamnesis) desc_anamnesis
                                                     FROM epis_anamnesis ea
                                                    WHERE ea.id_episode = i_episode
                                                      AND ea.flg_status = g_active
                                                      AND ea.flg_type = 'C'
                                                      AND ea.flg_temp = 'D'
                                                    ORDER BY ea.dt_epis_anamnesis_tstz DESC)
                                            WHERE rownum = 1))) patient_complaint,
                               decode(i_flg_only_scope,
                                       pk_alert_constant.g_no,
                                       CASE
                                           WHEN ec.patient_complaint IS NULL THEN
                                            (SELECT desc_anamnesis
                                               FROM (SELECT ea.desc_epis_anamnesis desc_anamnesis
                                                       FROM epis_anamnesis ea
                                                      WHERE ea.id_episode = i_episode
                                                        AND ea.flg_status = g_active
                                                        AND ea.flg_type = 'C'
                                                        AND ea.flg_temp = 'D'
                                                      ORDER BY ea.dt_epis_anamnesis_tstz DESC)
                                              WHERE rownum = 1)
                                           ELSE
                                            to_clob(ec.patient_complaint)
                                       END) patient_complaint_full,
/*                               pk_utils.concatenate_list(CURSOR (SELECT pk_translation.get_translation(i_lang,
                                                                                                'DOC_TEMPLATE.CODE_DOC_TEMPLATE.' ||
                                                                                                edoc.id_doc_template) desc_t
                                                            FROM epis_doc_template edoc
                                                           WHERE edoc.id_epis_complaint = ec.id_epis_complaint),
                                                         '; ') desc_doc_template,*/
                                                         NULL desc_doc_template,
                               ec.adw_last_update_tstz dt_reg,
                               ec.id_professional,
                               g_reg_type_complaint reg_type, -- Used for debug
                               ec.patient_complaint_arabic patient_complaint_arabic
                          FROM epis_complaint ec, complaint c
                         WHERE ec.id_episode = i_episode
                           AND ec.id_complaint = c.id_complaint
                           AND ec.flg_status = g_active
                        UNION ALL
                        -- José Brito 28/07/2009 ALERT-36311 Show complaint when registered in free text
                        SELECT NULL id, -- Send as NULL (for the touch option functions)
                               e.id_epis_anamnesis id_epis_complaint,
                               nvl((SELECT pk_translation.get_translation_dtchk(i_lang,
                                                                               'COMPLAINT.CODE_COMPLAINT.' ||
                                                                               ec.id_complaint)
                                     FROM epis_complaint ec
                                    WHERE ec.id_episode = i_episode
                                      AND ec.flg_status = g_active
                                      AND rownum = 1),
                                   '--') desc_complaint,
                               pk_string_utils.clob_to_sqlvarchar2(e.desc_epis_anamnesis) patient_complaint,
                               e.desc_epis_anamnesis patient_complaint_full,
                               NULL desc_doc_template,
                               e.dt_epis_anamnesis_tstz dt_reg,
                               e.id_professional,
                               g_reg_type_anamnesis reg_type, -- Used for debug
                               NULL patient_complaint_arabic
                          FROM epis_anamnesis e
                         WHERE e.id_episode = i_episode
                           AND e.flg_status = g_active
                           AND i_flg_only_scope = pk_alert_constant.g_no -- do not return these records when we only want the scope
                           AND e.flg_type = 'C'
                           AND e.flg_temp = 'D'
                         ORDER BY dt_reg DESC) compl
                 WHERE rownum = 1
                    OR i_flg_single_row = pk_alert_constant.g_no;
        
        ELSE
            g_error := 'OPEN O_EPIS_COMPLAINT - edit';
            OPEN o_epis_complaint FOR
                SELECT ec.id_epis_complaint id, -- not used in this case
                       ec.id_epis_complaint,
                       pk_translation.get_translation(i_lang, c.code_complaint) desc_complaint,
                       ec.patient_complaint,
                       NULL patient_complaint_full,
                       NULL desc_doc_template, -- not used in this case
                       ec.adw_last_update_tstz dt_reg,
                       ec.id_professional,
                       NULL reg_type,
                       ec.patient_complaint_arabic patient_complaint_arabic
                  FROM epis_documentation ed, epis_complaint ec, complaint c
                 WHERE ed.id_epis_complaint = ec.id_epis_complaint
                   AND ed.id_epis_documentation = i_epis_docum
                   AND ec.id_complaint = c.id_complaint;
        END IF;
    
        RETURN TRUE;
        --        
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_epis_complaint);
            RETURN error_handling(i_lang, 'GET_EPIS_COMPLAINT', g_error, SQLERRM, FALSE, o_error);
    END;
    --
    /********************************************************************************************
    * Sets documentation values associated with an area (doc_area) of a template (doc_template). 
      Allows for new, edit and agree epis documentation.
    *
    * @param i_lang                        language id
    * @param i_prof                        professional, software and institution ids
    * @param i_prof_cat_type               professional category
    * @param i_doc_area                    doc_area id
    * @param i_doc_template                doc_template id
    * @param i_epis_documentation          epis documentation id
    * @param i_flg_type                    A Agree, E edit, N - new 
    * @param i_id_documentation            array with id documentation,
    * @param i_id_doc_element              array with doc elements
    * @param i_id_doc_element_crit         array with doc elements crit
    * @param i_value                       array with values,
    * @param i_notes                       note
    * @param i_id_doc_element_qualif       array with doc elements qualif
    * @param i_vs_element_list             List of template's elements ID (id_doc_element) filled with vital signs
    * @param i_vs_save_mode_list           List of flags to indicate the applicable mode to save each vital signs measurement
    * @param i_vs_list                     List of vital signs ID (id_vital_sign)
    * @param i_vs_value_list               List of vital signs values
    * @param i_vs_uom_list                 List of units of measurement (id_unit_measure)
    * @param i_vs_scales_list              List of scales (id_vs_scales_element)
    * @param i_vs_date_list                List of measurement date. Values are serialized as strings (YYYYMMDDhh24miss)
    * @param i_vs_read_list                List of saved vital sign measurement (id_vital_sign_read)    
    * @param o_error                       Error message
    *
    * @value i_flg_type                    {*} 'N'  New {*} 'E' Edit/Correct {*} 'A' Agree(deprecated) {*} 'U' Update/Copy&Edit {*} 'O' No changes
    * @value i_flg_table_origin            {*} 'D'  EPIS_DOCUMENTATION {*} 'A'  EPIS_ANAMNESIS {*} 'S'  EPIS_REVIEW_SYSTEMS {*} 'O'  EPIS_OBS
    * @value i_save_mode_list              {*} 'N' Creates a new measurement and associates it with element. {*} 'E' Edits the measurement and associates it with element. {*} 'R' Reviews the measurement and associates it with element. {*} 'A' Associates the measurement with the element but does not perform any operation in referred vital sign
    *                        
    * @return                              true or false on success or error
    *
    * @author                              Luís Gaspar & Luís Oliveira, based on pk_documentation.set_epis_bartchart
                                           Emilia Taborda
    * @version                             1.0                                       
    * @since                               26-05-2007
                                           2007/08/27
    **********************************************************************************************/
    FUNCTION set_epis_documentation
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_prof_cat_type         IN category.flg_type%TYPE,
        i_epis                  IN episode.id_episode%TYPE,
        i_doc_area              IN doc_area.id_doc_area%TYPE,
        i_doc_template          IN doc_template.id_doc_template%TYPE,
        i_epis_documentation    IN epis_documentation.id_epis_documentation%TYPE,
        i_flg_type              IN VARCHAR2,
        i_id_documentation      IN table_number,
        i_id_doc_element        IN table_number,
        i_id_doc_element_crit   IN table_number,
        i_value                 IN table_varchar,
        i_notes                 IN epis_documentation.notes%TYPE,
        i_id_doc_element_qualif IN table_table_number,
        i_epis_context          IN epis_documentation.id_epis_context%TYPE,
        i_flg_table_origin      IN VARCHAR2 DEFAULT 'D',
        i_vs_element_list       IN table_number,
        i_vs_save_mode_list     IN table_varchar,
        i_vs_list               IN table_number,
        i_vs_value_list         IN table_number,
        i_vs_uom_list           IN table_number,
        i_vs_scales_list        IN table_number,
        i_vs_date_list          IN table_varchar,
        i_vs_read_list          IN table_number,
        i_dt_clinical           IN VARCHAR2 DEFAULT NULL,
        o_epis_documentation    OUT epis_documentation.id_epis_documentation%TYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_exception EXCEPTION;
        l_error              t_error_out;
        l_epis_complaint     epis_complaint_cur;
        l_row_epis_complaint epis_complaint_rec;
    
    BEGIN
        IF NOT get_epis_complaint(i_lang           => i_lang,
                                  i_prof           => i_prof,
                                  i_episode        => i_epis,
                                  i_epis_docum     => i_epis_documentation,
                                  i_flg_only_scope => pk_alert_constant.g_yes,
                                  o_epis_complaint => l_epis_complaint,
                                  o_error          => l_error)
        THEN
            RAISE l_exception;
        END IF;
        --
        g_error := 'FETCH l_epis_complaint';
        FETCH l_epis_complaint
            INTO l_row_epis_complaint;
        CLOSE l_epis_complaint;
    
        IF NOT pk_touch_option.set_epis_document_internal(i_lang                  => i_lang,
                                                          i_prof                  => i_prof,
                                                          i_prof_cat_type         => i_prof_cat_type,
                                                          i_epis                  => i_epis,
                                                          i_doc_area              => i_doc_area,
                                                          i_doc_template          => i_doc_template,
                                                          i_epis_documentation    => i_epis_documentation,
                                                          i_flg_type              => i_flg_type,
                                                          i_id_documentation      => i_id_documentation,
                                                          i_id_doc_element        => i_id_doc_element,
                                                          i_id_doc_element_crit   => i_id_doc_element_crit,
                                                          i_value                 => i_value,
                                                          i_notes                 => i_notes,
                                                          i_id_epis_complaint     => l_row_epis_complaint.id,
                                                          i_id_doc_element_qualif => i_id_doc_element_qualif,
                                                          i_epis_context          => i_epis_context,
                                                          i_flg_table_origin      => i_flg_table_origin,
                                                          i_vs_element_list       => i_vs_element_list,
                                                          i_vs_save_mode_list     => i_vs_save_mode_list,
                                                          i_vs_list               => i_vs_list,
                                                          i_vs_value_list         => i_vs_value_list,
                                                          i_vs_uom_list           => i_vs_uom_list,
                                                          i_vs_scales_list        => i_vs_scales_list,
                                                          i_vs_date_list          => i_vs_date_list,
                                                          i_vs_read_list          => i_vs_read_list,
                                                          i_dt_clinical           => i_dt_clinical,
                                                          o_epis_documentation    => o_epis_documentation,
                                                          o_error                 => l_error)
        THEN
            RAISE l_exception;
        END IF;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_exception THEN
            RETURN error_handling(i_lang,
                                  'SET_EPIS_DOCUMENTATION',
                                  g_error || ' / ' || l_error.err_desc,
                                  SQLERRM,
                                  TRUE,
                                  o_error);
        WHEN OTHERS THEN
            RETURN error_handling(i_lang, 'SET_EPIS_DOCUMENTATION', g_error, SQLERRM, TRUE, o_error);
    END;
    --
    --
    /********************************************************************************************
    * Detalhe de uma queixa de um episódio. 
    *
    * @param i_lang               language id
    * @param i_prof               professional, software and institution ids
    * @param i_epis_complaint     the complaint episode id
    * @param i_epis_doc_register  array with the detail info register
    * @param o_epis_document_val  array with detail of documentation
    
    * @param o_error              Error message
                        
    * @return                     true or false on success or error
    *
    * @author                     Emília Taborda
    * @since                      2007/06/15
    ********************************************************************************************/
    FUNCTION get_epis_complaint_det
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_epis_complaint      IN epis_complaint.id_epis_complaint%TYPE,
        o_epis_compl_register OUT pk_types.cursor_type,
        o_epis_complaint_val  OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_epis_compl table_number;
        --
        CURSOR c_epis_compl IS
            SELECT ec.id_epis_complaint
              FROM epis_complaint ec
            CONNECT BY PRIOR ec.id_epis_complaint = ec.id_epis_complaint_parent
             START WITH ec.id_epis_complaint = i_epis_complaint
            UNION ALL
            SELECT ec.id_epis_complaint
              FROM epis_complaint ec
             WHERE ec.id_epis_complaint <> i_epis_complaint
            CONNECT BY PRIOR ec.id_epis_complaint_parent = ec.id_epis_complaint
             START WITH ec.id_epis_complaint = i_epis_complaint
            UNION ALL
            SELECT ec.id_epis_complaint
              FROM epis_complaint ec
             WHERE ec.id_epis_complaint_root = i_epis_complaint;
    BEGIN
        g_error := 'OPEN C_EPIS_COMPL';
        OPEN c_epis_compl;
        FETCH c_epis_compl BULK COLLECT
            INTO l_epis_compl;
        CLOSE c_epis_compl;
        --
        g_error := 'GET CURSOR O_EPIS_COMPL_REGISTER';
        OPEN o_epis_compl_register FOR
            SELECT ec.id_epis_complaint,
                   ec.id_epis_complaint_root,
                   pk_date_utils.date_send_tsz(i_lang, ec.adw_last_update_tstz, i_prof) dt_creation,
                   pk_date_utils.date_char_tsz(i_lang, ec.adw_last_update_tstz, i_prof.institution, i_prof.software) dt_register,
                   ec.id_professional,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, ec.id_professional) nick_name,
                   pk_prof_utils.get_spec_signature(i_lang,
                                                    i_prof,
                                                    ec.id_professional,
                                                    ec.adw_last_update_tstz,
                                                    ec.id_episode) desc_speciality,
                   g_doc_area_complaint id_doc_area,
                   ec.flg_status,
                   decode(ec.flg_status,
                          g_active,
                          NULL,
                          pk_sysdomain.get_domain('EPIS_COMPLAINT.FLG_STATUS', ec.flg_status, i_lang)) desc_status,
                   ec.patient_complaint,
                   (SELECT pk_translation.get_translation(i_lang, cs.code_clinical_service)
                      FROM dep_clin_serv dcs, clinical_service cs
                     WHERE dcs.id_clinical_service = cs.id_clinical_service
                       AND dcs.id_dep_clin_serv = ec.id_dep_clin_serv) desc_appoint_type,
                   -- template(s) seleccionado(s) para documentação do episodio
                   pk_utils.concatenate_list(CURSOR (SELECT pk_translation.get_translation(i_lang,
                                                                                    'DOC_TEMPLATE.CODE_DOC_TEMPLATE.' ||
                                                                                    edoc.id_doc_template) desc_t
                                                FROM epis_doc_template edoc
                                               WHERE edoc.id_epis_complaint = ec.id_epis_complaint),
                                             ';') desc_doc_template,
                   pk_sysdomain.get_domain('EPIS_COMPLAINT.FLG_REPORTED_BY', ec.flg_reported_by, i_lang) desc_reported_by
              FROM epis_complaint ec
             WHERE ec.id_epis_complaint IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                             t.column_value
                                              FROM TABLE(l_epis_compl) t)
             ORDER BY ec.adw_last_update_tstz DESC;
        --
        g_error := 'GET CURSOR O_EPIS_COMPLAINT_VAL';
        OPEN o_epis_complaint_val FOR
            SELECT ec.id_epis_complaint,
                   ec.id_epis_complaint_root,
                   pk_translation.get_translation(i_lang, c.code_complaint) desc_complaint,
                   g_doc_area_complaint id_doc_area
              FROM epis_complaint ec, complaint c
             WHERE ec.id_complaint = c.id_complaint
               AND ec.id_epis_complaint IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                             t.column_value
                                              FROM TABLE(l_epis_compl) t)
             ORDER BY ec.adw_last_update_tstz DESC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_epis_compl_register);
            pk_types.open_my_cursor(o_epis_complaint_val);
            RETURN error_handling(i_lang, 'GET_EPIS_COMPLAINT_DET', g_error, SQLERRM, FALSE, o_error);
    END;
    --
    /********************************************************************************************
    * Devolve a lista de queixa possiveis, que se podem associar ao episódio e as que já estão associadas.
    * A lista das queixas é obtida da configuração dos templates
    *
    * @param i_lang                id da lingua
    * @param i_prof                objecto com info do utilizador
    * @param i_episode             id do episódio
    * @param o_complaints          cursor com queixas
    
    * @param o_error               Error message
    
    * @return                      true (sucess), false (error)
    *
    * @author                      Luís Gaspar
    * @version                     1.0
    * @since                       28-Ago-2007
    **********************************************************************************************/
    FUNCTION get_complaint_list_pp
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_episode    IN episode.id_episode%TYPE,
        i_patient    IN patient.id_patient%TYPE,
        o_complaints OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_dep_clin_serv dep_clin_serv.id_dep_clin_serv%TYPE;
    BEGIN
        g_error := 'FIND EPISODE DCS';
        SELECT s.id_dcs_requested
          INTO l_dep_clin_serv
          FROM epis_info ei
          JOIN schedule s
            ON ei.id_schedule = s.id_schedule
         WHERE ei.id_episode = i_episode;
        --
        g_error := 'OPEN O_COMPLAINTS DCS';
        OPEN o_complaints FOR
            SELECT DISTINCT c.id_complaint, -- distinct used because two/more complaints migth be associated with different templates
                            pk_translation.get_translation(i_lang, c.code_complaint) desc_complaint,
                            decode(ec.id_epis_complaint, --
                                   NULL,
                                   g_no,
                                   g_yes) flg_chosen, --
                            decode(ec.id_epis_complaint, NULL, NULL, ec.patient_complaint) patient_complaint
              FROM complaint             c, --
                   prof_profile_template ppt,
                   --esta subquery é necessária para filtrar opções com
                   --institution =i_prof.institution e institution=0, para evitar repetidos
                   (SELECT d.id_context, --
                           MAX(d.id_institution) id_institution,
                           d.id_software,
                           d.id_dep_clin_serv,
                           d.id_profile_template
                      FROM doc_template_context d
                     WHERE d.id_institution IN (i_prof.institution, 0)
                       AND d.id_software = i_prof.software
                       AND d.id_dep_clin_serv = l_dep_clin_serv
                       AND d.flg_type = g_flg_type_c
                     GROUP BY id_context, id_software, d.id_dep_clin_serv, d.id_profile_template) dtc2,
                   doc_template_context dtc,
                   
                   (SELECT floor((SYSDATE - dt_birth) / 365) age, --
                           decode(gender, g_gender_f, g_gender_f, g_gender_m, g_gender_m, 'G') gender
                      FROM patient
                     WHERE id_patient = i_patient) pat_attr,
                   epis_complaint ec
             WHERE c.id_complaint = dtc.id_context
               AND c.flg_available = g_available
               AND (c.flg_gender = pat_attr.gender OR c.flg_gender IS NULL)
                  --as validações por idade serão feitas mais tarde
                  --AND (c.age_min <= pat_attr.age OR c.age_min IS NULL or pat_attr.age is null)
                  --AND (c.age_max >= pat_attr.age OR c.age_max IS NULL or pat_attr.age is null)
               AND dtc.id_context = dtc2.id_context
               AND dtc.id_institution = dtc2.id_institution
               AND dtc.id_software = dtc2.id_software
               AND dtc.id_dep_clin_serv = dtc2.id_dep_clin_serv
               AND dtc.id_profile_template = dtc2.id_profile_template
               AND dtc.flg_type = g_flg_type_c
                  -- ligação ao profile_template
               AND ppt.id_profile_template = dtc.id_profile_template
               AND ppt.id_professional = i_prof.id
               AND ppt.id_institution = i_prof.institution
               AND ppt.id_software = i_prof.software
                  --ver se há queixa 
               AND ec.id_episode(+) = i_episode
               AND ec.id_complaint(+) = c.id_complaint
             ORDER BY desc_complaint;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_complaints);
            RETURN error_handling(i_lang, 'GET_COMPLAINT_LIST_PP', g_error, SQLERRM, FALSE, o_error);
    END get_complaint_list_pp;
    --
    /********************************************************************************************
    * Devolve a lista de templates disponíveis, para associação ao episódio.
    *
    * @param i_lang                id da lingua
    * @param i_prof                objecto com info do utilizador
    * @param i_episode             id do episódio
    * @param o_templates           cursor com templates    
    * @param o_error               Error message
    *
    * @return                      true (sucess), false (error)
    *
    * @author                      Luís Gaspar
    * @version                     1.0
    * @since                       28-Ago-2007
    **********************************************************************************************/
    FUNCTION get_template_list_pp
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_episode   IN episode.id_episode%TYPE,
        i_patient   IN patient.id_patient%TYPE,
        o_templates OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_dep_clin_serv dep_clin_serv.id_dep_clin_serv%TYPE;
    BEGIN
        g_error := 'FIND EPISODE DCS';
        SELECT s.id_dcs_requested
          INTO l_dep_clin_serv
          FROM epis_info ei
          JOIN schedule s
            ON ei.id_schedule = s.id_schedule
         WHERE ei.id_episode = i_episode;
        --
        g_error := 'OPEN O_TEMPLATES DCS';
        OPEN o_templates FOR
            SELECT DISTINCT dt.id_doc_template, -- distinct used because two/more complaints migth be associated with the same template
                            dt.internal_name desc_template, -- TODO criar campo para descrição do template
                            decode(ec.id_complaint, --
                                   NULL,
                                   g_no,
                                   g_yes) flg_chosen -- TODO
              FROM doc_template          dt, --
                   prof_profile_template ppt,
                   --esta subquery é necessária para filtrar opções com
                   --institution =i_prof.institution e institution=0, para evitar repetidos
                   (SELECT d.id_context, --
                           MAX(d.id_institution) id_institution,
                           d.id_software,
                           d.id_dep_clin_serv,
                           d.id_profile_template
                      FROM doc_template_context d
                     WHERE d.id_institution IN (i_prof.institution, 0)
                       AND d.id_software = i_prof.software
                       AND d.id_dep_clin_serv = l_dep_clin_serv
                       AND d.flg_type = g_flg_type_c
                     GROUP BY id_context, id_software, d.id_dep_clin_serv, d.id_profile_template) dtc2,
                   doc_template_context dtc,
                   -- patient info
                   (SELECT floor((SYSDATE - dt_birth) / 365) age, --
                           decode(gender, g_gender_f, g_gender_f, g_gender_m, g_gender_m, 'G') gender
                      FROM patient
                     WHERE id_patient = i_patient) pat_attr,
                   (SELECT DISTINCT ec.id_complaint
                      FROM epis_complaint ec
                     WHERE ec.id_episode = i_episode) ec
             WHERE dt.flg_available = g_available
               AND (dt.flg_gender = pat_attr.gender OR dt.flg_gender IS NULL)
                  --as validações por idade serão feitas mais tarde
                  --AND (dt.age_min <= pat_attr.age OR dt.age_min IS NULL or pat_attr.age is null)
                  --AND (dt.age_max >= pat_attr.age OR dt.age_max IS NULL or pat_attr.age is null)
               AND dtc.id_context = dtc2.id_context
               AND dtc.id_institution = dtc2.id_institution
               AND dtc.id_software = dtc2.id_software
               AND dtc.id_dep_clin_serv = dtc2.id_dep_clin_serv
               AND dtc.id_profile_template = dtc2.id_profile_template
               AND dtc.flg_type = g_flg_type_c
                  -- ligação ao profile_template
               AND ppt.id_profile_template = dtc.id_profile_template
               AND ppt.id_professional = i_prof.id
               AND ppt.id_institution = i_prof.institution
               AND ppt.id_software = i_prof.software
                  --ver se há queixa 
               AND ec.id_complaint(+) = dtc.id_context
             ORDER BY desc_template;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_templates);
            RETURN error_handling(i_lang, 'GET_TEMPLATE_LIST_PP', g_error, SQLERRM, FALSE, o_error);
    END get_template_list_pp;
    --
    /********************************************************************************************
    * Indica se o profissional actual registou uma queixa no episódio pretendido
    *
    * @param i_lang            id da lingua
    * @param i_prof            utilizador autenticado
    * @param i_episode         id do episódio
    * @param o_epis_complaint  id do registo da queixa. Se não houver registos este parametro vale null
    * @param o_date_last_epis  Data do último episódio
    * @param o_flg_data        Y if there are data, F when no date found    
    * @param o_error           Error message
    *                        
    * @return                  true or false on success or error
    *
    * @author                  João Eiras, Luís Gaspar
    * @version                 1.0    
    * @since
    ********************************************************************************************/
    FUNCTION get_prof_compl_templ_exists
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        o_epis_complaint OUT epis_documentation.id_epis_documentation%TYPE,
        o_date_last_epis OUT epis_complaint.adw_last_update_tstz%TYPE,
        o_flg_data       OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        -- Registo mais recente porque com multiplos templates podem existir vários registos de queixa activos
        CURSOR c_last_epis_compl IS
            SELECT ec.id_epis_complaint, ec.adw_last_update_tstz
              FROM epis_complaint ec
             WHERE ec.id_episode = i_episode
               AND ec.flg_status = g_complaint_act
               AND ec.id_professional = i_prof.id
             ORDER BY ec.adw_last_update_tstz DESC;
    
    BEGIN
        g_error := 'OPEN C_LAST_EPIS_COMPL';
        OPEN c_last_epis_compl;
        FETCH c_last_epis_compl
            INTO o_epis_complaint, o_date_last_epis;
    
        IF c_last_epis_compl%FOUND
        THEN
            o_flg_data := g_yes;
        ELSE
            o_flg_data := g_no;
        END IF;
        CLOSE c_last_epis_compl;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN error_handling(i_lang, 'GET_PROF_COMPL_TEMPL_EXISTS', g_error, SQLERRM, FALSE, o_error);
    END get_prof_compl_templ_exists;
    --
    /********************************************************************************************
    * Returns the active episode complaint. If there is no active complaint null is returned.
    *
    * @param i_lang                language id
    * @param i_prof                professional, software and institution ids
    * @param i_episode             episode id
    * @param o_id_complaint        The complaint id
    *
    * @param o_error               Error message
    *
    * @return                      true (sucess), false (error)
    *
    * @author                      Luís Gaspar
    * @since                       17-Set-2007
    * @version                     1.0
    **********************************************************************************************/
    FUNCTION get_epis_act_complaint
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        o_id_complaint OUT table_number,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'GET COMPLAINT';
        SELECT ec.id_complaint
          BULK COLLECT
          INTO o_id_complaint
          FROM epis_complaint ec
         WHERE ec.id_episode = i_episode
           AND ec.flg_status = g_active;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN error_handling(i_lang, 'GET_EPIS_ACT_COMPLAINT', g_error, SQLERRM, FALSE, o_error);
    END get_epis_act_complaint;
    --
    /********************************************************************************************
    * Devolve a última queixa e respectiva data de um episódio
    *
    * @param i_lang                  id da lingua
    * @param i_prof                  utilizador autenticado
    * @param i_episode               id do episódio 
    * @param o_last_epis_compl       Last complaint episode ID 
    * @param o_last_date_epis_compl  Data do último episódio
    * @param o_error                 Error message
    *                        
    * @return                        true or false on success or error
    *
    * @autor                         Emilia Taborda
    * @version                       1.0
    * @since                         2007/10/01
    **********************************************************************************************/
    FUNCTION get_last_complaint_templ
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_episode              IN episode.id_episode%TYPE,
        o_last_epis_compl      OUT epis_complaint.id_epis_complaint%TYPE,
        o_last_date_epis_compl OUT epis_complaint.adw_last_update_tstz%TYPE,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
        CURSOR c_last_epis_compl IS
            SELECT id_epis_complaint, adw_last_update_tstz
              FROM (SELECT ec.id_epis_complaint, ec.adw_last_update_tstz
                      FROM epis_complaint ec
                     WHERE ec.id_episode = i_episode
                       AND ec.flg_status = g_complaint_act
                     ORDER BY ec.adw_last_update_tstz DESC) t
             WHERE rownum < 2;
    BEGIN
        g_error := 'OPEN C_LAST_EPIS_COMPL';
        OPEN c_last_epis_compl;
        FETCH c_last_epis_compl
            INTO o_last_epis_compl, o_last_date_epis_compl;
        CLOSE c_last_epis_compl;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN error_handling(i_lang, 'GET_LAST_COMPLAINT_TEMPL', g_error, SQLERRM, FALSE, o_error);
    END get_last_complaint_templ;
    --
    /********************************************************************************************
    * GETS THE COMPLAINT(S) ASSOCIATED TO THE REASON FOR VISIT. 
    *
    * @param i_lang                language ID
    * @param i_prof                professional info
    * @param i_episode             episode ID
    * @param i_patient             patient ID
    * @param i_flg_type            register type: E - edit, N - new
    * @param i_dep_clin_serv       selected dep_clin_serv for complaint filter    
    * @param o_complaints          complaints cursor
    * @param o_compl_template      complaint associated with the chosen template
    * @param o_compl_root          epis_complaint ID containing the main info
    * @param o_doc_template        previous selected templates
    * @param o_appoint_type        Appointment type
    * @param o_error               Error message
    *    
    * @return                      true (sucess), false (error)
    *
    * @author                      José Silva (based on get_complaint_list)
    * @version                     1.0
    * @since                       09-10-2007
    **********************************************************************************************/
    FUNCTION get_reason_complaint_list
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        i_patient        IN patient.id_patient%TYPE,
        i_flg_type       IN VARCHAR2,
        i_dep_clin_serv  IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_complaints     OUT pk_types.cursor_type,
        o_compl_template OUT pk_types.cursor_type,
        o_compl_root     OUT epis_complaint.id_epis_complaint%TYPE,
        o_doc_template   OUT pk_types.cursor_type,
        o_appoint_type   OUT pk_types.cursor_type,
        o_flg_dcs_filter OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_comp_filter      VARCHAR2(100);
        l_dep_clin_serv    dep_clin_serv.id_dep_clin_serv%TYPE;
        l_sch_event        sch_event.id_sch_event%TYPE;
        l_i_compl_schedule complaint.id_complaint%TYPE;
    
        l_exception EXCEPTION;
        l_error t_error_out;
    
    BEGIN
        g_error       := 'GET CONFIG';
        l_comp_filter := pk_sysconfig.get_config('COMPLAINT_FILTER', i_prof);
        --
        g_error := 'FIND DCS';
        SELECT sh.id_dcs_requested, sh.id_sch_event, decode(sh.flg_reason_type, 'C', sh.id_reason, NULL) id_complaint
          INTO l_dep_clin_serv, l_sch_event, l_i_compl_schedule
          FROM epis_info ei
          JOIN schedule sh
            ON ei.id_schedule = sh.id_schedule
         WHERE ei.id_episode = i_episode;
    
        IF l_comp_filter = g_comp_filter_prf
        THEN
            g_error := 'OPEN O_COMPLAINTS PRF';
            OPEN o_complaints FOR
                SELECT DISTINCT c.id_complaint,
                                pk_translation.get_translation(i_lang, c.code_complaint) desc_complaint,
                                decode(ec.id_epis_complaint,
                                       NULL,
                                       decode(c.id_complaint, l_i_compl_schedule, g_yes, g_no),
                                       decode(i_flg_type, g_flg_edit, g_yes, g_no)) flg_chosen,
                                decode(ec.id_epis_complaint, NULL, NULL, ec.patient_complaint) patient_complaint,
                                ec.flg_reported_by,
                                ec.id_epis_complaint
                  FROM complaint c,
                       prof_profile_template ppt,
                       (SELECT id_context,
                               MAX(id_institution) id_institution,
                               id_software,
                               id_profile_template,
                               flg_type
                          FROM doc_template_context d
                         WHERE id_institution IN (i_prof.institution, 0)
                           AND id_software = i_prof.software
                           AND d.flg_type = g_flg_type_ct
                           AND d.id_sch_event = (SELECT MAX(d.id_sch_event)
                                                   FROM doc_template_context d
                                                  WHERE d.id_institution IN (i_prof.institution, 0)
                                                    AND id_software = i_prof.software
                                                    AND d.flg_type = g_flg_type_ct
                                                    AND d.id_sch_event IN (l_sch_event, 0))
                         GROUP BY id_context, id_software, id_profile_template, flg_type) dtc2,
                       epis_complaint ec
                 WHERE c.id_complaint = dtc2.id_context
                   AND c.flg_available = g_available
                      --ler profile pessoal
                   AND ppt.id_profile_template = dtc2.id_profile_template
                   AND ppt.id_professional = i_prof.id
                   AND ppt.id_institution = i_prof.institution
                   AND ppt.id_software = i_prof.software
                      --ver se há queixa 
                   AND ec.id_complaint(+) = c.id_complaint
                   AND ec.id_episode(+) = i_episode
                   AND ec.flg_status(+) = g_active
                 ORDER BY desc_complaint;
        
            g_error := 'OPEN O_COMPL_TEMPLATE PRF';
            OPEN o_compl_template FOR
                SELECT dt.id_doc_template,
                       dtc2.id_context id_complaint,
                       pk_translation.get_translation(i_lang, dt.code_doc_template) desc_template
                  FROM complaint c,
                       doc_template dt,
                       prof_profile_template ppt,
                       (SELECT id_context,
                               MAX(id_institution) id_institution,
                               id_software,
                               id_profile_template,
                               flg_type,
                               id_doc_template
                          FROM doc_template_context d
                         WHERE id_institution IN (i_prof.institution, 0)
                           AND id_software = i_prof.software
                           AND d.flg_type = g_flg_type_ct
                           AND d.id_sch_event = (SELECT MAX(d.id_sch_event)
                                                   FROM doc_template_context d
                                                  WHERE d.id_institution IN (i_prof.institution, 0)
                                                    AND id_software = i_prof.software
                                                    AND d.flg_type = g_flg_type_ct
                                                    AND d.id_sch_event IN (l_sch_event, 0))
                         GROUP BY id_context, id_software, id_profile_template, flg_type, id_doc_template) dtc2,
                       (SELECT floor((SYSDATE - dt_birth) / 365) age,
                               decode(gender, g_gender_f, g_gender_f, g_gender_m, g_gender_m, 'G') gender
                          FROM patient
                         WHERE id_patient = i_patient) pat_attr
                 WHERE c.id_complaint = dtc2.id_context
                   AND c.flg_available = g_available
                      --filtar templates adequados ao paciente
                   AND dt.id_doc_template = dtc2.id_doc_template
                   AND (dt.flg_gender = pat_attr.gender OR dt.flg_gender IS NULL)
                   AND dt.flg_available = g_available
                      --ler profile pessoal
                   AND ppt.id_profile_template = dtc2.id_profile_template
                   AND ppt.id_professional = i_prof.id
                   AND ppt.id_institution = i_prof.institution
                   AND ppt.id_software = i_prof.software
                UNION ALL
                SELECT dt.id_doc_template,
                       NULL id_complaint,
                       pk_translation.get_translation(i_lang, dt.code_doc_template) desc_template
                  FROM epis_doc_template edoc
                 INNER JOIN doc_template dt
                    ON edoc.id_doc_template = dt.id_doc_template
                 INNER JOIN epis_complaint ec
                    ON ec.id_epis_complaint = edoc.id_epis_complaint
                 WHERE edoc.id_episode = i_episode
                   AND ec.flg_status = g_active
                   AND i_flg_type = g_flg_edit
                 ORDER BY id_complaint, desc_template;
        
            o_flg_dcs_filter := g_no;
        
        ELSIF l_comp_filter = g_comp_filter_dcs
        THEN
            --
            g_error := 'OPEN O_COMPLAINTS DCS';
            OPEN o_complaints FOR
                SELECT DISTINCT c.id_complaint, --
                                pk_translation.get_translation(i_lang, c.code_complaint) desc_complaint,
                                decode(ec.id_epis_complaint,
                                       NULL,
                                       decode(c.id_complaint, l_i_compl_schedule, g_yes, g_no),
                                       decode(i_flg_type, g_flg_edit, g_yes, g_no)) flg_chosen,
                                decode(ec.id_epis_complaint, NULL, NULL, ec.patient_complaint) patient_complaint,
                                ec.flg_reported_by,
                                ec.id_epis_complaint
                  FROM complaint c, --
                       prof_profile_template ppt,
                       (SELECT d.id_context, --
                               MAX(d.id_institution) id_institution,
                               d.id_software,
                               d.id_dep_clin_serv,
                               d.id_profile_template,
                               d.flg_type
                          FROM doc_template_context d
                         WHERE d.id_institution IN (i_prof.institution, 0)
                           AND d.id_software = i_prof.software
                           AND d.id_dep_clin_serv = nvl(i_dep_clin_serv, l_dep_clin_serv)
                           AND d.id_sch_event =
                               (SELECT MAX(d.id_sch_event)
                                  FROM doc_template_context d
                                 WHERE d.id_institution IN (i_prof.institution, 0)
                                   AND id_software = i_prof.software
                                   AND d.flg_type = g_flg_type_ct
                                   AND d.id_sch_event IN (l_sch_event, 0)
                                   AND d.id_dep_clin_serv = nvl(i_dep_clin_serv, l_dep_clin_serv))
                           AND d.flg_type = g_flg_type_ct
                         GROUP BY id_context, id_software, d.id_dep_clin_serv, d.id_profile_template, flg_type) dtc2,
                       epis_complaint ec
                 WHERE c.id_complaint = dtc2.id_context
                   AND c.flg_available = g_available
                      -- ligação ao profile_template
                   AND ppt.id_profile_template = dtc2.id_profile_template
                   AND ppt.id_professional = i_prof.id
                   AND ppt.id_institution = i_prof.institution
                   AND ppt.id_software = i_prof.software
                      --ver se há queixa 
                   AND ec.id_complaint(+) = c.id_complaint
                   AND ec.id_episode(+) = i_episode
                   AND ec.flg_status(+) = g_active
                 ORDER BY desc_complaint;
        
            g_error := 'OPEN O_COMPL_TEMPLATE DCS';
            OPEN o_compl_template FOR
                SELECT DISTINCT dt.id_doc_template,
                                c.id_complaint, --
                                pk_translation.get_translation(i_lang, dt.code_doc_template) desc_template
                  FROM complaint c, --
                       doc_template dt,
                       prof_profile_template ppt,
                       (SELECT dtc.id_context, --
                               MAX(dtc.id_institution) id_institution,
                               dtc.id_software,
                               dtc.id_dep_clin_serv,
                               dtc.id_profile_template,
                               dtc.id_doc_template,
                               dtc.flg_type
                          FROM doc_template_context dtc
                         WHERE dtc.id_institution IN (i_prof.institution, 0)
                           AND dtc.id_software = i_prof.software
                           AND dtc.id_dep_clin_serv = nvl(i_dep_clin_serv, l_dep_clin_serv)
                           AND dtc.id_sch_event = (SELECT MAX(dtc.id_sch_event)
                                                     FROM doc_template_context dtc
                                                    WHERE dtc.id_institution IN (i_prof.institution, 0)
                                                      AND dtc.id_software = i_prof.software
                                                      AND dtc.flg_type = g_flg_type_ct
                                                      AND dtc.id_dep_clin_serv = nvl(i_dep_clin_serv, l_dep_clin_serv)
                                                      AND dtc.id_sch_event IN (l_sch_event, 0))
                           AND dtc.flg_type = g_flg_type_ct
                         GROUP BY dtc.id_context,
                                  dtc.id_software,
                                  dtc.id_dep_clin_serv,
                                  dtc.id_profile_template,
                                  dtc.id_doc_template,
                                  dtc.flg_type) dtc2,
                       (SELECT floor((SYSDATE - dt_birth) / 365) age, --
                               decode(gender, g_gender_f, g_gender_f, g_gender_m, g_gender_m, 'G') gender
                          FROM patient
                         WHERE id_patient = i_patient) pat_attr
                 WHERE c.id_complaint = dtc2.id_context
                   AND c.flg_available = g_available
                      --filtar templates adequados ao paciente
                   AND dt.id_doc_template = dtc2.id_doc_template
                   AND (dt.flg_gender = pat_attr.gender OR dt.flg_gender IS NULL)
                   AND dt.flg_available = g_available
                      -- ligação ao profile_template
                   AND ppt.id_profile_template = dtc2.id_profile_template
                   AND ppt.id_professional = i_prof.id
                   AND ppt.id_institution = i_prof.institution
                   AND ppt.id_software = i_prof.software
                UNION ALL
                SELECT dt.id_doc_template,
                       NULL id_complaint,
                       pk_translation.get_translation(i_lang, dt.code_doc_template) desc_template
                  FROM epis_doc_template edoc
                 INNER JOIN doc_template dt
                    ON edoc.id_doc_template = dt.id_doc_template
                 INNER JOIN epis_complaint ec
                    ON ec.id_epis_complaint = edoc.id_epis_complaint
                 WHERE edoc.id_episode = i_episode
                   AND ec.flg_status = g_active
                   AND i_flg_type = g_flg_edit
                 ORDER BY id_complaint, desc_template;
        
            o_flg_dcs_filter := g_yes;
        ELSE
            g_error := 'NO COMPLAINT_FILTER(' || i_prof.institution || ',' || i_prof.software || ')';
            RAISE g_exception;
        END IF;
    
        IF i_dep_clin_serv IS NULL
        THEN
        
            g_error := 'GET EPIS_DOC_TEMPLATE';
            OPEN o_doc_template FOR
                SELECT dt.id_doc_template,
                       NULL id_complaint,
                       pk_translation.get_translation(i_lang, dt.code_doc_template) desc_template
                  FROM epis_doc_template edoc
                 INNER JOIN doc_template dt
                    ON edoc.id_doc_template = dt.id_doc_template
                 INNER JOIN epis_complaint ec
                    ON ec.id_epis_complaint = edoc.id_epis_complaint
                 WHERE edoc.id_episode = i_episode
                   AND ec.flg_status = g_active
                   AND i_flg_type = g_flg_edit
                 ORDER BY id_complaint, desc_template;
        
            g_error := 'GET EPIS COMPLAINT ROOT';
            BEGIN
                SELECT ec.id_epis_complaint
                  INTO o_compl_root
                  FROM epis_complaint ec
                 WHERE ec.id_episode = i_episode
                   AND ec.flg_status = g_active
                   AND ec.id_epis_complaint_root IS NULL
                   AND i_flg_type = g_flg_edit;
            EXCEPTION
                WHEN no_data_found THEN
                    o_compl_root := NULL;
            END;
        
            g_error := 'GET SELECTED DEP_CLIN_SERV';
            IF NOT pk_list.get_selected_dcs(i_lang, i_prof, i_episode, NULL, o_appoint_type, o_error)
            THEN
                RAISE l_exception;
            END IF;
        ELSE
            pk_types.open_my_cursor(o_appoint_type);
            pk_types.open_my_cursor(o_doc_template);
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_exception THEN
            pk_types.open_my_cursor(o_complaints);
            pk_types.open_my_cursor(o_compl_template);
            pk_types.open_my_cursor(o_appoint_type);
            pk_types.open_my_cursor(o_doc_template);
            RETURN error_handling(i_lang,
                                  'GET_REASON_COMPLAINT_LIST',
                                  g_error || ' / ' || l_error.err_desc,
                                  SQLERRM,
                                  FALSE,
                                  o_error);
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_complaints);
            pk_types.open_my_cursor(o_compl_template);
            pk_types.open_my_cursor(o_appoint_type);
            pk_types.open_my_cursor(o_doc_template);
            RETURN error_handling(i_lang, 'GET_REASON_COMPLAINT_LIST', g_error, SQLERRM, FALSE, o_error);
    END get_reason_complaint_list;

    /*******************
    * get list of complaints for an episode. This code was transferred from get_reason_complaint_list_all because 
    * it is needed elsewhere. Now the get_reason_complaint_list_all calls this function to fill it's own o_complaints
    *
    * @param i_lang                language ID
    * @param i_prof                professional info
    * @param i_episode             episode ID
    * @param i_flg_type            register type: E - edit, N - new
    * @param o_complaints          complaints cursor
    * @param o_dcs_list            needed in get_reason_complaint_list_all
    * @param o_id_event            needed in get_reason_complaint_list_all
    * @param o_error               Error message
    *    
    * @return                      true (sucess), false (error)
    *
    * @author                      Telmo Castro
    * @version                     2.4.3
    * @date                        02-09-2008
    */
    FUNCTION get_reason_complaint_epis
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_episode    IN episode.id_episode%TYPE,
        i_flg_type   IN VARCHAR2,
        o_complaints OUT pk_types.cursor_type,
        o_dcs_list   OUT table_number,
        o_id_event   OUT sch_event.id_sch_event%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_i_compl_schedule complaint.id_complaint%TYPE;
        l_max_sch_event    NUMBER;
    
    BEGIN
        g_error := 'FIND DCS from schedule';
        BEGIN
            SELECT sh.id_sch_event, decode(sh.flg_reason_type, 'C', sh.id_reason, NULL) id_complaint
              INTO o_id_event, l_i_compl_schedule
              FROM epis_info ei
              JOIN schedule sh
                ON ei.id_schedule = sh.id_schedule
             WHERE ei.id_episode = i_episode;
        EXCEPTION
            WHEN no_data_found THEN
                g_error            := 'FIND DCS from episode';
                o_id_event         := NULL;
                l_i_compl_schedule := NULL;
        END;
    
        SELECT dcs.id_dep_clin_serv
          BULK COLLECT
          INTO o_dcs_list
          FROM dep_clin_serv dcs, clinical_service cli, prof_dep_clin_serv pdc, department dpt
         WHERE dcs.id_dep_clin_serv = pdc.id_dep_clin_serv
           AND pdc.id_professional = i_prof.id
           AND dcs.id_clinical_service = cli.id_clinical_service
           AND dcs.id_department = dcs.id_department
           AND cli.flg_available = g_available
           AND dpt.id_department = dcs.id_department
           AND dpt.flg_available = g_available
           AND dpt.id_institution = i_prof.institution
           AND pdc.flg_status = g_selected;
    
        SELECT MAX(d.id_sch_event)
          INTO l_max_sch_event
          FROM doc_template_context d
         WHERE d.id_institution IN (i_prof.institution, 0)
           AND id_software = i_prof.software
           AND d.flg_type = g_flg_type_ct
           AND (o_id_event IS NULL OR d.id_sch_event IN (o_id_event, 0))
           AND d.id_dep_clin_serv IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                       t.column_value
                                        FROM TABLE(o_dcs_list) t);
    
        g_error := 'OPEN O_COMPLAINTS DCS';
        OPEN o_complaints FOR
            SELECT tbl.id_complaint,
                   tbl.desc_complaint,
                   tbl.flg_chosen,
                   tbl.patient_complaint,
                   tbl.flg_reported_by,
                   tbl.id_epis_complaint,
                   substr(concatenate(tbl.id_clinical_service || ';'),
                          1,
                          length(concatenate(tbl.id_clinical_service || ';')) - 1) clin_serv_list
              FROM (SELECT c.id_complaint, --
                           pk_translation.get_translation(i_lang, c.code_complaint) desc_complaint,
                           decode(ec.id_epis_complaint,
                                  NULL,
                                  decode(c.id_complaint, l_i_compl_schedule, g_yes, g_no),
                                  decode(i_flg_type, g_flg_edit, g_yes, g_no)) flg_chosen,
                           decode(ec.id_epis_complaint, NULL, NULL, ec.patient_complaint) patient_complaint,
                           ec.flg_reported_by,
                           ec.id_epis_complaint,
                           dtc2.id_clinical_service,
                           0 rank
                      FROM complaint c,
                           prof_profile_template ppt,
                           epis_complaint ec,
                           (SELECT d.id_context,
                                   MAX(d.id_institution) id_institution,
                                   d.id_software,
                                   d.id_dep_clin_serv,
                                   d.id_profile_template,
                                   d.flg_type,
                                   dcs.id_clinical_service
                              FROM doc_template_context d, dep_clin_serv dcs
                             WHERE d.id_institution IN (i_prof.institution, 0)
                               AND dcs.id_dep_clin_serv = d.id_dep_clin_serv
                               AND d.id_software = i_prof.software
                               AND d.id_dep_clin_serv IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                           t.column_value
                                                            FROM TABLE(o_dcs_list) t)
                               AND (d.id_sch_event IS NULL OR d.id_sch_event = l_max_sch_event)
                               AND d.flg_type = g_flg_type_ct
                             GROUP BY id_context,
                                      id_software,
                                      d.id_dep_clin_serv,
                                      d.id_profile_template,
                                      d.flg_type,
                                      dcs.id_clinical_service) dtc2
                     WHERE c.id_complaint = dtc2.id_context
                       AND c.flg_available = g_available
                          -- ligação ao profile_template
                       AND ppt.id_profile_template = dtc2.id_profile_template
                       AND ppt.id_professional = i_prof.id
                       AND ppt.id_institution = i_prof.institution
                       AND ppt.id_software = i_prof.software
                          --ver se há queixa 
                       AND ec.id_complaint(+) = dtc2.id_context
                       AND ec.id_episode(+) = i_episode
                       AND ec.flg_status(+) = g_active
                    UNION ALL
                    SELECT -1,
                           pk_message.get_message(i_lang, 'COMPLAINTDOCTOR_T012'),
                           NULL,
                           NULL,
                           NULL,
                           NULL,
                           NULL,
                           10 rank
                      FROM dual
                     ORDER BY rank, desc_complaint) tbl
             GROUP BY tbl.id_complaint,
                      tbl.desc_complaint,
                      tbl.flg_chosen,
                      tbl.patient_complaint,
                      tbl.flg_reported_by,
                      tbl.id_epis_complaint,
                      tbl.rank
             ORDER BY rank, desc_complaint;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_complaints);
            RETURN error_handling(i_lang, 'GET_REASON_COMPLAINT_EPIS', g_error, SQLERRM, FALSE, o_error);
    END get_reason_complaint_epis;

    /********************************************************************************************
    * GETS THE COMPLAINT(S) ASSOCIATED TO THE REASON FOR VISIT. 
    *
    * @param i_lang                language ID
    * @param i_prof                professional info
    * @param i_episode             episode ID
    * @param i_patient             patient ID
    * @param i_flg_type            register type: E - edit, N - new
    * @param o_complaints          complaints cursor
    * @param o_compl_template      complaint associated with the chosen template
    * @param o_compl_root          epis_complaint ID containing the main info
    * @param o_doc_template        previous selected templates
    * @param o_appoint_type        Appointment type
    * @param o_error               Error message
    *    
    * @return                      true (sucess), false (error)
    *
    * @author                      Sérgio Santos (based on get_reason_complaint_list)
    * @version                     1.0
    * @since                       09-10-2007
    *
    * UPDATED 
    * o_complaints output parameter now comes from function get_reason_complaint_prv
    * @author   Telmo Castro
    * @version  2.4.3
    * @date     02-09-2008
    **********************************************************************************************/
    FUNCTION get_reason_complaint_list_all
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        i_patient        IN patient.id_patient%TYPE,
        i_flg_type       IN VARCHAR2,
        o_complaints     OUT pk_types.cursor_type,
        o_compl_template OUT pk_types.cursor_type,
        o_compl_root     OUT epis_complaint.id_epis_complaint%TYPE,
        o_doc_template   OUT pk_types.cursor_type,
        o_appoint_type   OUT pk_types.cursor_type,
        o_flg_dcs_filter OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_comp_filter        VARCHAR2(100);
        l_sch_event          sch_event.id_sch_event%TYPE;
        l_dep_clin_serv_list table_number;
    
        l_exception EXCEPTION;
        l_error t_error_out;
    
    BEGIN
        g_error       := 'GET CONFIG';
        l_comp_filter := pk_sysconfig.get_config('COMPLAINT_FILTER', i_prof);
    
        g_error := 'OPEN O_COMPLAINTS';
        IF NOT get_reason_complaint_epis(i_lang       => i_lang,
                                         i_prof       => i_prof,
                                         i_episode    => i_episode,
                                         i_flg_type   => i_flg_type,
                                         o_complaints => o_complaints,
                                         o_dcs_list   => l_dep_clin_serv_list,
                                         o_id_event   => l_sch_event,
                                         o_error      => l_error)
        THEN
            RAISE l_exception;
        END IF;
    
        g_error := 'OPEN O_COMPL_TEMPLATE DCS';
        OPEN o_compl_template FOR
            SELECT tbl.id_doc_template,
                   pk_string_utils.remove_repeated(substr(concatenate(tbl.id_dep_clin_serv || ';'),
                                                          1,
                                                          length(concatenate(tbl.id_dep_clin_serv || ';')) - 1),
                                                   ';') id_dep_clin_serv_list,
                   pk_string_utils.remove_repeated(substr(concatenate(tbl.id_complaint || ';'),
                                                          1,
                                                          length(concatenate(tbl.id_complaint || ';')) - 1),
                                                   ';') id_complaint_list,
                   tbl.desc_template
              FROM (SELECT DISTINCT dt.id_doc_template,
                                    c.id_complaint,
                                    dtc2.id_dep_clin_serv,
                                    pk_translation.get_translation(i_lang, dt.code_doc_template) desc_template
                      FROM complaint c, --
                           doc_template dt,
                           prof_profile_template ppt,
                           (SELECT dtc.id_context, --
                                   MAX(dtc.id_institution) id_institution,
                                   dtc.id_software,
                                   dtc.id_dep_clin_serv,
                                   dtc.id_profile_template,
                                   dtc.id_doc_template,
                                   dtc.flg_type
                              FROM doc_template_context dtc
                             WHERE dtc.id_institution IN (i_prof.institution, 0)
                               AND dtc.id_software = i_prof.software
                               AND dtc.id_dep_clin_serv IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                             t.column_value
                                                              FROM TABLE(l_dep_clin_serv_list) t)
                               AND dtc.id_sch_event = (SELECT MAX(dtc2.id_sch_event)
                                                         FROM doc_template_context dtc2
                                                        WHERE dtc2.id_institution IN (i_prof.institution, 0)
                                                          AND dtc2.id_software = i_prof.software
                                                          AND dtc2.flg_type = g_flg_type_ct
                                                          AND dtc2.id_dep_clin_serv = dtc.id_dep_clin_serv
                                                          AND dtc2.id_sch_event IN (l_sch_event, 0))
                               AND dtc.flg_type = g_flg_type_ct
                             GROUP BY dtc.id_context,
                                      dtc.id_software,
                                      dtc.id_dep_clin_serv,
                                      dtc.id_profile_template,
                                      dtc.id_doc_template,
                                      dtc.flg_type) dtc2,
                           (SELECT floor((SYSDATE - dt_birth) / 365) age, --
                                   decode(gender, g_gender_f, g_gender_f, g_gender_m, g_gender_m, 'G') gender
                              FROM patient
                             WHERE id_patient = i_patient) pat_attr
                     WHERE c.id_complaint = dtc2.id_context
                       AND c.flg_available = g_available
                          --filtar templates adequados ao paciente
                       AND dt.id_doc_template = dtc2.id_doc_template
                       AND (dt.flg_gender = pat_attr.gender OR dt.flg_gender IS NULL)
                       AND dt.flg_available = g_available
                          -- ligação ao profile_template
                       AND ppt.id_profile_template = dtc2.id_profile_template
                       AND ppt.id_professional = i_prof.id
                       AND ppt.id_institution = i_prof.institution
                       AND ppt.id_software = i_prof.software
                    UNION ALL
                    SELECT dt.id_doc_template,
                           NULL id_complaint,
                           ec.id_dep_clin_serv,
                           pk_translation.get_translation(i_lang, dt.code_doc_template) desc_template
                      FROM epis_doc_template edoc
                     INNER JOIN doc_template dt
                        ON edoc.id_doc_template = dt.id_doc_template
                     INNER JOIN epis_complaint ec
                        ON ec.id_epis_complaint = edoc.id_epis_complaint
                     WHERE edoc.id_episode = i_episode
                       AND ec.flg_status = g_active
                       AND i_flg_type = g_flg_edit
                     ORDER BY id_complaint, desc_template) tbl
            
             GROUP BY tbl.id_doc_template, tbl.desc_template
             ORDER BY tbl.desc_template;
    
        o_flg_dcs_filter := g_yes;
    
        g_error := 'GET EPIS_DOC_TEMPLATE';
        OPEN o_doc_template FOR
            SELECT dt.id_doc_template,
                   NULL id_complaint,
                   pk_translation.get_translation(i_lang, dt.code_doc_template) desc_template
              FROM epis_doc_template edoc
             INNER JOIN doc_template dt
                ON edoc.id_doc_template = dt.id_doc_template
             INNER JOIN epis_complaint ec
                ON ec.id_epis_complaint = edoc.id_epis_complaint
             WHERE edoc.id_episode = i_episode
               AND ec.flg_status = g_active
               AND i_flg_type = g_flg_edit
             ORDER BY id_complaint, desc_template;
    
        g_error := 'GET EPIS COMPLAINT ROOT';
        BEGIN
            SELECT ec.id_epis_complaint
              INTO o_compl_root
              FROM epis_complaint ec
             WHERE ec.id_episode = i_episode
               AND ec.flg_status = g_active
               AND ec.id_epis_complaint_root IS NULL
               AND i_flg_type = g_flg_edit;
        EXCEPTION
            WHEN no_data_found THEN
                o_compl_root := NULL;
        END;
    
        g_error := 'GET SELECTED DEP_CLIN_SERV';
        IF NOT pk_list.get_selected_dcs(i_lang, i_prof, i_episode, NULL, o_appoint_type, l_error)
        THEN
            RAISE l_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_exception THEN
            pk_types.open_my_cursor(o_complaints);
            pk_types.open_my_cursor(o_compl_template);
            pk_types.open_my_cursor(o_appoint_type);
            pk_types.open_my_cursor(o_doc_template);
            RETURN error_handling(i_lang,
                                  'GET_REASON_COMPLAINT_LIST_ALL',
                                  g_error || ' / ' || l_error.err_desc,
                                  SQLERRM,
                                  FALSE,
                                  o_error);
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_complaints);
            pk_types.open_my_cursor(o_compl_template);
            pk_types.open_my_cursor(o_appoint_type);
            pk_types.open_my_cursor(o_doc_template);
            RETURN error_handling(i_lang, 'GET_REASON_COMPLAINT_LIST_ALL', g_error, SQLERRM, FALSE, o_error);
    END get_reason_complaint_list_all;
    --
    /********************************************************************************************
    * Registers complaints for episode. Internal function (does not commit).
    *
    * @param i_lang                    language id
    * @param i_prof                    professional, software and institution ids
    * @param i_epis                    the episode id
    * @param i_complaint               the complaint id
    * @param i_pat_complaint           the patient complaint
    * @param i_flg_type                register type: E - edit, N - new 
    * @param i_flg_reported_by         who reported the complaint
    * @param i_dep_clin_serv           chosen appointment type to be associated with the scheduled episode    
    * @param i_parent                  the complaint id root from the group of complaints
    * @param o_epis_complaint          created record identifer
    * @param o_error                   Error message
    * @return                          true (sucess), false (error)
    *
    * @author                          José Silva
    * @version                         1.0
    * @since                           09-10-2007
    * Changes:
    *
    * @author                          Elisabete Bugalho
    * @version                         2.4.3-Denormalized
    * @since                           2008/09/25
    * reason                           DB Denormalization - Updates to EPIS_INFO uses framework   
    **********************************************************************************************/
    FUNCTION set_reason_epis_complaint_int
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_epis            IN episode.id_episode%TYPE,
        i_complaint       IN table_number,
        i_pat_complaint   IN epis_complaint.patient_complaint%TYPE,
        i_flg_type        IN epis_complaint.flg_edition_type%TYPE,
        i_flg_reported_by IN epis_complaint.flg_reported_by%TYPE,
        i_dep_clin_serv   IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_parent          IN epis_complaint.id_epis_complaint_parent%TYPE,
        o_epis_complaint  OUT epis_complaint.id_epis_complaint%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_root        epis_complaint.id_epis_complaint%TYPE;
        l_ec_row_coll ts_epis_complaint.epis_complaint_tc;
        l_ec_row      epis_complaint%ROWTYPE;
        l_rowids      table_varchar := table_varchar();
    BEGIN
        g_sysdate_tstz := current_timestamp;
    
        -- check input parameter
        IF i_complaint IS NULL
           OR i_complaint.count < 1
        THEN
            g_error := 'No complaints were specified!';
            RAISE g_exception;
        END IF;
    
        -- outdate previous records
        g_error := 'CALL ts_epis_complaint.upd';
        ts_epis_complaint.upd(flg_status_in  => g_complaint_out,
                              flg_status_nin => FALSE,
                              where_in       => ' id_episode = ' || i_epis || ' AND flg_status = ''' || g_complaint_act || '''',
                              rows_out       => l_rowids);
        g_error := 'CALL t_data_gov_mnt.process_update';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'EPIS_COMPLAINT',
                                      i_rowids       => l_rowids,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('FLG_STATUS'));
    
        -- set first row
        l_root := ts_epis_complaint.next_key;
    
        l_ec_row.id_epis_complaint        := l_root;
        l_ec_row.id_episode               := i_epis;
        l_ec_row.id_professional          := i_prof.id;
        l_ec_row.id_complaint             := i_complaint(1);
        l_ec_row.adw_last_update_tstz     := g_sysdate_tstz;
        l_ec_row.patient_complaint        := i_pat_complaint;
        l_ec_row.flg_status               := g_complaint_act;
        l_ec_row.id_epis_complaint_parent := i_parent;
        l_ec_row.flg_reported_by          := i_flg_reported_by;
        l_ec_row.id_dep_clin_serv         := i_dep_clin_serv;
        l_ec_row.flg_edition_type         := i_flg_type;
    
        l_ec_row_coll(1) := l_ec_row;
    
        -- set following rows
        IF i_complaint.count > 1
        THEN
            l_ec_row.patient_complaint        := NULL;
            l_ec_row.id_epis_complaint_parent := NULL;
            l_ec_row.flg_reported_by          := NULL;
            l_ec_row.id_epis_complaint_root   := l_root;
            l_ec_row.id_dep_clin_serv         := NULL;
        
            FOR i IN 2 .. i_complaint.count
            LOOP
                l_ec_row.id_epis_complaint := ts_epis_complaint.next_key;
                l_ec_row.id_complaint      := i_complaint(i);
            
                l_ec_row_coll(i) := l_ec_row;
            END LOOP;
        END IF;
    
        l_rowids := table_varchar();
        g_error  := 'CALL ts_epis_complaint.ins';
        ts_epis_complaint.ins(rows_in => l_ec_row_coll, rows_out => l_rowids);
        g_error := 'CALL t_data_gov_mnt.process_insert';
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'EPIS_COMPLAINT',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        o_epis_complaint := l_root;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN error_handling(i_lang           => i_lang,
                                  i_func_proc_name => 'SET_REASON_EPIS_COMPLAINT_INT',
                                  i_error          => g_error,
                                  i_sqlerror       => SQLERRM,
                                  i_rollback       => TRUE,
                                  o_error          => o_error);
    END set_reason_epis_complaint_int;

    /********************************************************************************************
    *  Registers a reason for visit and related complaints. 
    *
    * @param i_lang                    language id
    * @param i_prof                    professional, software and institution ids
    * @param i_prof_cat_type           professional category
    * @param i_epis                    the episode id
    * @param i_complaint               the complaint id
    * @param i_patient_complaint       the patient complaint
    * @param i_flg_type                register type: E - edit, N - new 
    * @param i_flg_reported_by         who reported the complaint
    * @param i_template_chosen         chosen template to be used on the episode documentation
    * @param i_dep_clin_serv           chosen appointment type to be associated with the scheduled episode    
    * @param i_epis_complaint_parent   the complaint id root from the group of complaints
    * @param o_error                   Error message
    * @return                          true (sucess), false (error)
    *
    * @author                          José Silva
    * @version                         1.0
    * @since                           09-10-2007
    * Changes:
    *
    * @author                          Elisabete Bugalho
    * @version                         2.4.3-Denormalized
    * @since                           2008/09/25
    * reason                           DB Denormalization - Updates to EPIS_INFO uses framework   
    **********************************************************************************************/
    FUNCTION set_reason_epis_complaint
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_prof_cat_type         IN category.flg_type%TYPE,
        i_epis                  IN episode.id_episode%TYPE,
        i_complaint             IN table_number,
        i_patient_complaint     IN epis_complaint.patient_complaint%TYPE,
        i_flg_type              IN VARCHAR2,
        i_flg_reported_by       IN epis_complaint.flg_reported_by%TYPE,
        i_template_chosen       IN table_number,
        i_dep_clin_serv         IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_epis_complaint_parent IN epis_complaint.id_epis_complaint%TYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
        l_root                  epis_complaint.id_epis_complaint%TYPE;
        l_epis_doc_template     table_number;
        l_epis_doc_template_out table_number;
        l_rowids                table_varchar;
        l_id_cs_requested       clinical_service.id_clinical_service%TYPE;
        l_id_department_req     department.id_department%TYPE;
        l_id_dept_req           dept.id_dept%TYPE;
    
        CURSOR c_epis_doc_template IS
            SELECT edoc.id_epis_doc_template
              FROM epis_doc_template edoc
             WHERE edoc.dt_cancel IS NULL
               AND edoc.id_episode = i_epis;
    
        l_exception EXCEPTION;
        l_error t_error_out;
    
    BEGIN
        g_error := 'CALL set_reason_epis_complaint_int';
        IF NOT set_reason_epis_complaint_int(i_lang            => i_lang,
                                             i_prof            => i_prof,
                                             i_epis            => i_epis,
                                             i_complaint       => i_complaint,
                                             i_pat_complaint   => i_patient_complaint,
                                             i_flg_type        => i_flg_type,
                                             i_flg_reported_by => i_flg_reported_by,
                                             i_dep_clin_serv   => i_dep_clin_serv,
                                             i_parent          => i_epis_complaint_parent,
                                             o_epis_complaint  => l_root,
                                             o_error           => o_error)
        THEN
            pk_utils.undo_changes;
            RETURN FALSE;
        END IF;
    
        g_error := 'OPEN C_EPIS_DOC_TEMPLATE';
        OPEN c_epis_doc_template;
        FETCH c_epis_doc_template BULK COLLECT
            INTO l_epis_doc_template_out;
        CLOSE c_epis_doc_template;
    
        g_error := 'SET EPIS_DOC_TEMPLATE';
        IF NOT pk_touch_option.set_epis_doc_templ_no_commit(i_lang,
                                                            i_prof,
                                                            i_epis,
                                                            i_template_chosen,
                                                            l_epis_doc_template_out,
                                                            NULL,
                                                            l_epis_doc_template,
                                                            l_error)
        THEN
            RAISE l_exception;
        END IF;
    
        g_error := 'UPDATE EPIS DOC TEMPLATE';
        FORALL i IN 1 .. l_epis_doc_template.count
            UPDATE epis_doc_template edoc
               SET edoc.id_epis_complaint = l_root, edoc.id_profile_template = NULL
             WHERE edoc.id_epis_doc_template = l_epis_doc_template(i);
    
        g_error := 'GET ID_CS_REQUESTED';
        IF i_dep_clin_serv IS NOT NULL
        THEN
            SELECT dcs.id_clinical_service, dcs.id_department, dpt.id_dept
              INTO l_id_cs_requested, l_id_department_req, l_id_dept_req
              FROM dep_clin_serv dcs, department dpt
             WHERE dcs.id_dep_clin_serv = i_dep_clin_serv
               AND dcs.id_department = dpt.id_department;
        END IF;
    
        g_error := 'SET SCHEDULED DEP_CLIN_SERV';
        UPDATE schedule sch
           SET sch.id_dcs_requested = i_dep_clin_serv
         WHERE sch.id_schedule = (SELECT ei.id_schedule
                                    FROM epis_info ei
                                   WHERE ei.id_episode = i_epis)
           AND sch.id_schedule > 0;
    
        g_error := 'UPDATE EPIS_INFO';
        ts_epis_info.upd(id_episode_in        => i_epis,
                         id_dcs_requested_in  => i_dep_clin_serv,
                         id_dcs_requested_nin => FALSE,
                         rows_out             => l_rowids);
    
        --Process the events associated to an update on epis_info                        
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'EPIS_INFO',
                                      i_rowids     => l_rowids,
                                      o_error      => l_error);
    
        l_rowids := table_varchar();
    
        g_error := 'UPDATE EPISODE';
        ts_episode.upd(id_cs_requested_in          => l_id_cs_requested,
                       id_cs_requested_nin         => FALSE,
                       id_department_requested_in  => l_id_department_req,
                       id_department_requested_nin => FALSE,
                       id_dept_requested_in        => l_id_dept_req,
                       id_dept_requested_nin       => FALSE,
                       id_episode_in               => i_epis,
                       rows_out                    => l_rowids);
    
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'EPISODE',
                                      i_rowids     => l_rowids,
                                      o_error      => l_error);
    
        g_error := 'CALL TO SET_FIRST_OBS';
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => i_epis,
                                      i_pat                 => NULL,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => i_prof_cat_type,
                                      i_dt_last_interaction => g_sysdate_tstz,
                                      i_dt_first_obs        => g_sysdate_tstz,
                                      o_error               => l_error)
        THEN
            RAISE l_exception;
        END IF;
    
        COMMIT;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN error_handling(i_lang, 'SET_REASON_EPIS_COMPLAINT', g_error, SQLERRM, TRUE, o_error);
    END set_reason_epis_complaint;

    --
    /********************************************************************************************
    * Gets all templates matching the given search name
    *
    * @param i_lang                language ID
    * @param i_prof                professional info
    * @param i_episode             episode ID
    * @param i_flg_type            flg_type in DOC_TEMPLATE_CONTEXT
    * @param i_search_name         name used for template search
    * @param o_doc_templates       matching templates
    * @param o_error               Error message
    *    
    * @return                      true (sucess), false (error)
    *
    * @author                      José Silva
    * @version                     1.0
    * @since                       16-10-2007
    **********************************************************************************************/
    FUNCTION get_template_by_name
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        i_flg_type      IN doc_template_context.flg_type%TYPE,
        i_search_name   IN VARCHAR2,
        o_doc_templates OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'OPEN O_COMPL_TEMPLATE PRF';
        OPEN o_doc_templates FOR
            SELECT DISTINCT dt.id_doc_template,
                            pk_translation.get_translation(i_lang, dt.code_doc_template) desc_template
              FROM complaint c,
                   doc_template dt,
                   prof_profile_template ppt,
                   (SELECT id_context,
                           MAX(id_institution) id_institution,
                           id_software,
                           id_profile_template,
                           flg_type,
                           id_doc_template
                      FROM doc_template_context d
                     WHERE id_institution IN (i_prof.institution, 0)
                       AND id_software = i_prof.software
                       AND d.flg_type = i_flg_type
                     GROUP BY id_context, id_software, id_profile_template, flg_type, id_doc_template) dtc2
             WHERE c.id_complaint = dtc2.id_context
               AND c.flg_available = g_available
               AND ((translate(upper(pk_translation.get_translation(i_lang, dt.code_doc_template)),
                               'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ- ',
                               'AEIOUAEIOUAEIOUAOCAEIOUN') LIKE
                   '%' || translate(upper(i_search_name), 'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ- ', 'AEIOUAEIOUAEIOUAOCAEIOUN') || '%' AND
                   i_search_name IS NOT NULL) OR i_search_name IS NULL)
                  --filtar templates adequados ao paciente
               AND dt.id_doc_template = dtc2.id_doc_template
               AND dt.flg_available = g_available
                  --ler profile pessoal
               AND ppt.id_profile_template = dtc2.id_profile_template
               AND ppt.id_professional = i_prof.id
               AND ppt.id_institution = i_prof.institution
               AND ppt.id_software = i_prof.software
             ORDER BY desc_template;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_doc_templates);
            RETURN error_handling(i_lang, 'GET_TEMPLATE_BY_NAME', g_error, SQLERRM, FALSE, o_error);
    END get_template_by_name;

    /********************************************************************************************
    *  Registers a reason for visit and related complaints. 
    *
    * @param i_lang                    language id
    * @param i_prof                    professional, software and institution ids
    * @param i_prof_cat_type           professional category
    * @param i_epis                    the episode id
    * @param i_complaint               the complaint id
    * @param i_patient_complaint       the patient complaint
    * @param i_flg_type                register type: E - edit, N - new 
    * @param i_flg_reported_by         who reported the complaint
    * @param i_template_chosen         chosen template to be used on the episode documentation
    * @param i_dep_clin_serv           chosen appointment type to be associated with the scheduled episode    
    * @param i_epis_complaint_parent   the complaint id root from the group of complaints
    * @param i_dt_init                 data de início de consulta
    * @param o_error                   Error message
    * @return                          true (sucess), false (error)
    *
    * @author                          Teresa Coutinho
    * @version                         1.0
    * @since                           09-05-2008
    **********************************************************************************************/
    FUNCTION set_reason_epis_complaint
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_prof_cat_type         IN category.flg_type%TYPE,
        i_epis                  IN episode.id_episode%TYPE,
        i_complaint             IN table_number,
        i_patient_complaint     IN epis_complaint.patient_complaint%TYPE,
        i_flg_type              IN VARCHAR2,
        i_flg_reported_by       IN epis_complaint.flg_reported_by%TYPE,
        i_template_chosen       IN table_number,
        i_dep_clin_serv         IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_epis_complaint_parent IN epis_complaint.id_epis_complaint%TYPE,
        i_dt_init               IN VARCHAR2,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
        --     
        l_error t_error_out;
        l_exception EXCEPTION;
    
    BEGIN
        g_error := 'CALL PK_VISIT.SET_VISIT_INIT';
        IF NOT pk_visit.set_visit_init(i_lang => i_lang, i_id_episode => i_epis, i_prof => i_prof, o_error => l_error)
        
        THEN
            RAISE l_exception;
        END IF;
    
        g_error := 'CALL PK_COMPLAINT.SET_REASON_EPIS_COMPLAINT';
        IF NOT pk_complaint.set_reason_epis_complaint(i_lang                  => i_lang,
                                                      i_prof                  => i_prof,
                                                      i_prof_cat_type         => i_prof_cat_type,
                                                      i_epis                  => i_epis,
                                                      i_complaint             => i_complaint,
                                                      i_patient_complaint     => i_patient_complaint,
                                                      i_flg_type              => i_flg_type,
                                                      i_flg_reported_by       => i_flg_reported_by,
                                                      i_template_chosen       => i_template_chosen,
                                                      i_dep_clin_serv         => i_dep_clin_serv,
                                                      i_epis_complaint_parent => i_epis_complaint_parent,
                                                      o_error                 => l_error)
        
        THEN
            RAISE l_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_exception THEN
            RETURN error_handling(i_lang,
                                  'SET_REASON_EPIS_COMPLAINT',
                                  g_error || ' / ' || l_error.err_desc,
                                  SQLERRM,
                                  TRUE,
                                  o_error);
        WHEN OTHERS THEN
            RETURN error_handling(i_lang, 'SET_REASON_EPIS_COMPLAINT', g_error, SQLERRM, TRUE, o_error);
    END;

    /********************************************************************************************
    * gets the list of all complaints that can be used in the hospital group environment
    *
    * @param      i_lang                       preferred language id for this professional
    * @param      i_prof                       object (id of professional, id of institution, id of software)
    * @param      o_filters                    cursor with all comnplaints
    * @param      o_error                      error message
    *
    * @return     boolean                      true or false on success or error
    *
    * @author                                  Carlos Loureiro
    * @since                                   02-Dec-2010
    ********************************************************************************************/
    FUNCTION get_all_complaints_list
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        o_complaints OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_institutions  table_number;
        l_market        market.id_market%TYPE;
        l_comp_filter   VARCHAR2(100);
        l_tbl_dtc_types table_varchar;
    BEGIN
        -- get all institutions belonging to the same hospital group
        g_error        := 'call pk_list.tf_get_all_inst_group function';
        l_institutions := pk_list.tf_get_all_inst_group(i_prof.institution, pk_search.g_inst_grp_flg_rel_adt);
    
        -- get institution market
        l_market := pk_utils.get_institution_market(i_lang, i_prof.institution);
    
        --get the filter configuration for EDIS software
        g_error       := 'GET CONFIG';
        l_comp_filter := pk_sysconfig.get_config('COMPLAINT_FILTER',
                                                 profissional(i_prof.id,
                                                              i_prof.institution,
                                                              pk_alert_constant.g_soft_edis));
    
        IF l_comp_filter = pk_complaint.g_comp_filter_prf
        THEN
            l_tbl_dtc_types := table_varchar(pk_complaint.g_flg_type_c, pk_complaint.g_flg_type_dc);
        ELSIF l_comp_filter = pk_complaint.g_comp_filter_dcs
        THEN
            l_tbl_dtc_types := table_varchar(pk_complaint.g_flg_type_ct);
        ELSE
            g_error := 'NO COMPLAINT_FILTER(' || i_prof.institution || ',' || i_prof.software ||
                       ') SET TYPE_TBL TO EMPTY';
            pk_alertlog.log_debug(text            => g_error,
                                  object_name     => g_package_name,
                                  sub_object_name => 'get_all_complaints_list');
            l_tbl_dtc_types := table_varchar();
        END IF;
    
        -- open cursor with all complaints list
        g_error := 'open cursor o_complaints';
        OPEN o_complaints FOR
            SELECT *
              FROM (SELECT DISTINCT c.id_complaint,
                                    pk_translation.get_translation(i_lang, c.code_complaint) desc_complaint
                      FROM complaint c
                      JOIN (SELECT dtc.id_context,
                                  row_number() over(PARTITION BY dtc.id_context ORDER BY dtc.id_institution DESC) rn
                             FROM doc_template_context dtc
                             JOIN doc_template dt
                               ON dt.id_doc_template = dtc.id_doc_template
                            WHERE dt.flg_available = g_available
                              AND dtc.id_institution IN (SELECT /*+OPT_ESTIMATE (table t rows=1)*/
                                                          column_value
                                                           FROM TABLE(l_institutions) inst)
                              AND (dtc.id_profile_template IN
                                  (SELECT ptm.id_profile_template
                                      FROM profile_template_market ptm
                                     WHERE ptm.id_market IN (l_market)) OR
                                  nvl(dtc.id_profile_template, pk_alert_constant.g_profile_template_all) =
                                  pk_alert_constant.g_profile_template_all)
                              AND dtc.flg_type IN (SELECT /*+OPT_ESTIMATE (table t rows=1)*/
                                                    column_value flg_type
                                                     FROM TABLE(l_tbl_dtc_types) t)
                              AND dtc.id_software = pk_alert_constant.g_soft_edis) t
                        ON c.id_complaint = t.id_context
                     WHERE c.flg_available = g_available
                       AND t.rn = 1)
             WHERE desc_complaint IS NOT NULL
             ORDER BY desc_complaint;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              'GET_ALL_COMPLAINTS_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_complaints);
            RETURN FALSE;
    END get_all_complaints_list;

    /********************************************************************************************
    * Devolve a descrição do motivo de consulta (usado nas grelhas)
    *
    * @param i_lang                id da lingua
    * @param i_prof                objecto com info do utilizador
    * @param i_episode             id do episódio
    * @param i_episode             id do agendamento
    *
    * @return                      razao da consulta
    **********************************************************************************************/
    FUNCTION get_reason_desc
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_episode     IN episode.id_episode%TYPE,
        i_id_schedule IN schedule.id_schedule%TYPE
    ) RETURN VARCHAR2 IS
        l_desc VARCHAR2(4000 CHAR);
    
        l_last_ec_tstz epis_complaint.adw_last_update_tstz%TYPE;
    BEGIN
    
        g_error := 'GET LAST EC TSTZ';
        BEGIN
            SELECT MAX(ec.adw_last_update_tstz)
              INTO l_last_ec_tstz
              FROM epis_complaint ec
             WHERE ec.id_episode = i_episode;
        EXCEPTION
            WHEN no_data_found THEN
                l_last_ec_tstz := NULL;
        END;
    
        g_error := 'GET REASON';
        SELECT substr(concatenate(decode(nvl(ec.id_complaint, decode(s2.flg_reason_type, 'C', s2.id_reason, NULL)),
                                         NULL,
                                         ec.patient_complaint,
                                         pk_translation.get_translation(i_lang,
                                                                        'COMPLAINT.CODE_COMPLAINT.' ||
                                                                        nvl(ec.id_complaint,
                                                                            decode(s2.flg_reason_type,
                                                                                   'C',
                                                                                   s2.id_reason,
                                                                                   NULL)))) || '; '),
                      1,
                      length(concatenate(decode(nvl(ec.id_complaint, decode(s2.flg_reason_type, 'C', s2.id_reason, NULL)),
                                                NULL,
                                                ec.patient_complaint,
                                                pk_translation.get_translation(i_lang,
                                                                               'COMPLAINT.CODE_COMPLAINT.' ||
                                                                               nvl(ec.id_complaint,
                                                                                   decode(s2.flg_reason_type,
                                                                                          'C',
                                                                                          s2.id_reason,
                                                                                          NULL))) || '; '))) -
                      length('; '))
          INTO l_desc
          FROM schedule s2
          LEFT JOIN epis_info ei2
            ON ei2.id_schedule = s2.id_schedule
          LEFT JOIN epis_complaint ec
            ON ec.id_episode = ei2.id_episode
           AND ec.adw_last_update_tstz = l_last_ec_tstz
         WHERE s2.id_schedule = i_id_schedule
           AND nvl(ec.flg_status, pk_alert_constant.g_active) = pk_alert_constant.g_active;
    
        RETURN l_desc;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_reason_desc;

    /********************************************************************************************
    * Gets the professional that registered a complaint.
    *
    * @param      i_lang                       preferred language id for this professional
    * @param      i_prof                       object (id of professional, id of institution, id of software)
    * @param      i_id_epis_complaint          Epis_complaint ID
    * @param      o_id_professional            Professional ID
    * @param      o_error                      error message
    *
    * @return     boolean                      true or false on success or error
    *
    * @author                                  Sofia Mendes
    * @since                                   21-Mar-2012
    ********************************************************************************************/
    FUNCTION get_complaint_prof
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_epis_complaint IN epis_complaint.id_epis_complaint%TYPE,
        o_id_professional   OUT epis_complaint.id_professional%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_error := 'GET complaint professional. i_id_epis_complaint: ' || i_id_epis_complaint;
        pk_alertlog.log_debug(g_error);
        SELECT ec.id_professional
          INTO o_id_professional
          FROM epis_complaint ec
         WHERE ec.id_epis_complaint = i_id_epis_complaint;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              'GET_COMPLAINT_PROF',
                                              o_error);
            RETURN FALSE;
    END get_complaint_prof;

    /********************************************************************************************
    * Gets the professional that registered a chief complaint in free text.
    *
    * @param      i_lang                       preferred language id for this professional
    * @param      i_prof                       object (id of professional, id of institution, id of software)
    * @param      i_id_epis_anamnesis          Epis_anamnesis ID
    * @param      o_id_professional            Professional ID
    * @param      o_error                      error message
    *
    * @return     boolean                      true or false on success or error
    *
    * @author                                  Sofia Mendes
    * @since                                   21-Mar-2012
    ********************************************************************************************/
    FUNCTION get_anamnesis_prof
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_epis_anamnesis IN epis_anamnesis.id_epis_anamnesis%TYPE,
        o_id_professional   OUT epis_anamnesis.id_professional%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_error := 'GET epis_anamnesis professional. i_id_epis_anamnesis: ' || i_id_epis_anamnesis;
        pk_alertlog.log_debug(g_error);
        SELECT ea.id_professional
          INTO o_id_professional
          FROM epis_anamnesis ea
         WHERE ea.id_epis_anamnesis = i_id_epis_anamnesis;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              'GET_ANAMNESIS_PROF',
                                              o_error);
            RETURN FALSE;
    END get_anamnesis_prof;

    /********************************************************************************************
    * gets the actions available in chief complaint
    *
    * @param      i_lang                       preferred language id for this professional
    * @param      i_prof                       object (id of professional, id of institution, id of software)
    * @param      i_id_epis_complaint          epis complaint ID
    * @param      i_id_epis_anamnesis          epis anamnesis ID
    * @param      o_actions                    cursor with all actions
    * @param      o_error                      error message
    *
    * @return     boolean                      true or false on success or error
    *
    * @author                                  Sofia Mendes
    * @since                                   21-Mar-2012
    ********************************************************************************************/
    FUNCTION get_actions
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_epis_complaint IN epis_complaint.id_epis_complaint%TYPE,
        i_id_epis_anamnesis IN epis_anamnesis.id_epis_anamnesis%TYPE,
        o_actions           OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id_professional  epis_complaint.id_professional%TYPE;
        l_flg_status       epis_complaint.flg_status%TYPE;
        l_available_action VARCHAR2(1 CHAR);
        l_exception EXCEPTION;
        l_coll_acttions    t_coll_action := t_coll_action();
        l_profile_template profile_template.id_profile_template%TYPE;
        l_flg_no_changes   summary_page_access.flg_no_changes%TYPE;
    
        l_summary_page CONSTANT summary_page.id_summary_page%TYPE := 1;
        l_doc_area     CONSTANT doc_area.id_doc_area%TYPE := 20;
    
        l_multiple_selection sys_config.value%TYPE := pk_sysconfig.get_config('CHIEF_COMPLAINT_MULTIPLE_SELECTION',
                                                                              i_prof);
    BEGIN
        IF (i_id_epis_complaint IS NOT NULL)
        THEN
            g_error := 'CALL get_complaint_prof';
            pk_alertlog.log_debug(g_error);
            IF NOT get_complaint_prof(i_lang              => i_lang,
                                      i_prof              => i_prof,
                                      i_id_epis_complaint => i_id_epis_complaint,
                                      o_id_professional   => l_id_professional,
                                      o_error             => o_error)
            THEN
                RAISE l_exception;
            END IF;
        
            g_error := 'CALL get_complaint_status';
            IF NOT get_complaint_status(i_lang              => i_lang,
                                        i_prof              => i_prof,
                                        i_id_epis_complaint => i_id_epis_complaint,
                                        o_status            => l_flg_status,
                                        o_error             => o_error)
            THEN
                RAISE l_exception;
            END IF;
        
        ELSIF (i_id_epis_anamnesis IS NOT NULL)
        THEN
            g_error := 'CALL get_anamnesis_prof';
            pk_alertlog.log_debug(g_error);
            IF NOT get_anamnesis_prof(i_lang              => i_lang,
                                      i_prof              => i_prof,
                                      i_id_epis_anamnesis => i_id_epis_anamnesis,
                                      o_id_professional   => l_id_professional,
                                      o_error             => o_error)
            THEN
                RAISE l_exception;
            END IF;
        
            g_error := 'CALL get_anamnesis_status';
            IF NOT get_anamnesis_status(i_lang              => i_lang,
                                        i_prof              => i_prof,
                                        i_id_epis_anamnesis => i_id_epis_anamnesis,
                                        o_status            => l_flg_status,
                                        o_error             => o_error)
            THEN
                RAISE l_exception;
            END IF;
        
        END IF;
    
        --options are available if complaint/anamnesis status is active
        IF l_flg_status = pk_alert_constant.g_active
        THEN
            l_available_action := pk_alert_constant.g_active;
        ELSE
            l_available_action := pk_alert_constant.g_inactive;
        END IF;
    
        --edit action is available if the professional that registered the complaint is the logged professional
        IF (i_prof.id = l_id_professional)
        THEN
            g_error := 'CONSTRUCTING EDIT ACTION';
            pk_alertlog.log_debug(g_error);
            l_coll_acttions.extend;
            l_coll_acttions(l_coll_acttions.last) := t_rec_action(id_action   => g_action_edit,
                                                                  id_parent   => NULL,
                                                                  level_nr    => 1,
                                                                  from_state  => NULL,
                                                                  to_state    => NULL,
                                                                  desc_action => pk_message.get_message(i_lang      => i_lang,
                                                                                                        i_code_mess => 'DOCUMENTATION_M021'),
                                                                  icon        => NULL,
                                                                  flg_default => pk_alert_constant.g_no,
                                                                  action      => 'EDIT',
                                                                  flg_active  => l_available_action);
        END IF;
    
        --Copy and Edit option is always available except when multiple chief complaint selection is enabled        
        /*        g_error := 'CONSTRUCTING COPY AND EDIT ACTION';
        IF l_multiple_selection = pk_alert_constant.g_no
        THEN
            pk_alertlog.log_debug(g_error);
            l_coll_acttions.extend;
            l_coll_acttions(l_coll_acttions.last) := t_rec_action(id_action   => g_action_copy_edit,
                                                                  id_parent   => NULL,
                                                                  level_nr    => 1,
                                                                  from_state  => NULL,
                                                                  to_state    => NULL,
                                                                  desc_action => pk_message.get_message(i_lang      => i_lang,
                                                                                                        i_code_mess => 'DOCUMENTATION_M030'),
                                                                  icon        => NULL,
                                                                  flg_default => pk_alert_constant.g_no,
                                                                  action      => 'COPY_AND_EDIT',
                                                                  flg_active  => l_available_action);
        END IF;*/
        --Copy option is available if flg_no_changes = 'Y'    
        l_profile_template := pk_prof_utils.get_prof_profile_template(i_prof);
    
        BEGIN
            g_error := 'GET FLG_NO_CHANGES. l_profile_template: ' || l_profile_template;
            pk_alertlog.log_debug(g_error);
            SELECT spa.flg_no_changes
              INTO l_flg_no_changes
              FROM summary_page sp
             INNER JOIN summary_page_section sps
                ON sp.id_summary_page = sps.id_summary_page
             INNER JOIN summary_page_access spa
                ON sps.id_summary_page_section = spa.id_summary_page_section
             WHERE sp.id_summary_page = l_summary_page
               AND spa.id_profile_template = l_profile_template
               AND sps.id_doc_area = l_doc_area;
        EXCEPTION
            WHEN no_data_found THEN
                l_flg_no_changes := pk_alert_constant.g_no;
        END;
    
        IF (l_flg_no_changes = pk_alert_constant.g_yes)
        THEN
            g_error := 'CONSTRUCTING COPY ACTION';
            pk_alertlog.log_debug(g_error);
            l_coll_acttions.extend;
            l_coll_acttions(l_coll_acttions.last) := t_rec_action(id_action   => g_action_copy,
                                                                  id_parent   => NULL,
                                                                  level_nr    => 1,
                                                                  from_state  => NULL,
                                                                  to_state    => NULL,
                                                                  desc_action => pk_message.get_message(i_lang      => i_lang,
                                                                                                        i_code_mess => 'DOCUMENTATION_M031'),
                                                                  icon        => NULL,
                                                                  flg_default => pk_alert_constant.g_no,
                                                                  action      => 'COPY',
                                                                  flg_active  => l_available_action);
        END IF;
    
        --Cancel option is is always available
        g_error := 'CONSTRUCTING CANCEL ACTION';
        pk_alertlog.log_debug(g_error);
        l_coll_acttions.extend;
        l_coll_acttions(l_coll_acttions.last) := t_rec_action(id_action   => g_action_cancel,
                                                              id_parent   => NULL,
                                                              level_nr    => 1,
                                                              from_state  => NULL,
                                                              to_state    => g_canceled,
                                                              desc_action => pk_message.get_message(i_lang      => i_lang,
                                                                                                    i_code_mess => 'DOCUMENTATION_M053'),
                                                              icon        => NULL,
                                                              flg_default => pk_alert_constant.g_no,
                                                              action      => 'CANCEL',
                                                              flg_active  => l_available_action);
    
        g_error := 'Open o_action cursor';
        OPEN o_actions FOR
            SELECT id_action,
                   id_parent,
                   level_nr,
                   from_state,
                   to_state,
                   desc_action,
                   icon,
                   flg_default,
                   flg_active,
                   action
              FROM TABLE(l_coll_acttions);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              'GET_ACTIONS',
                                              o_error);
            pk_types.open_my_cursor(o_actions);
            RETURN FALSE;
    END get_actions;
    /********************************************************************************************
    * gets the actions available in chief complaint
    *
    * @param      i_lang                       preferred language id for this professional
    * @param      i_prof                       object (id of professional, id of institution, id of software)
    * @param      i_id_pn_epis_reason                    ID
     * @param      o_actions                    cursor with all actions
    * @param      o_error                      error message
    *
    * @return     boolean                      true or false on success or error
    *
    * @author                                  Sofia Mendes
    * @since                                   21-Mar-2012
    ********************************************************************************************/
    FUNCTION get_actions_epis_reason
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_pn_epis_reason IN pn_epis_reason.id_pn_epis_reason%TYPE,
        o_actions           OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id_professional  epis_complaint.id_professional%TYPE;
        l_flg_status       epis_complaint.flg_status%TYPE;
        l_available_action VARCHAR2(1 CHAR);
        l_exception EXCEPTION;
        l_coll_acttions    t_coll_action := t_coll_action();
        l_profile_template profile_template.id_profile_template%TYPE;
        l_flg_no_changes   summary_page_access.flg_no_changes%TYPE;
    
        l_summary_page CONSTANT summary_page.id_summary_page%TYPE := 1;
        l_doc_area     CONSTANT doc_area.id_doc_area%TYPE := 20;
    BEGIN
        BEGIN
            SELECT per.flg_status
              INTO l_flg_status
              FROM pn_epis_reason per
             WHERE per.id_pn_epis_reason = i_id_pn_epis_reason;
        EXCEPTION
            WHEN no_data_found THEN
                l_flg_status := NULL;
        END;
    
        --options are available if complaint/anamnesis status is active
        IF l_flg_status = pk_alert_constant.g_active
        THEN
            l_available_action := pk_alert_constant.g_active;
        ELSE
            l_available_action := pk_alert_constant.g_inactive;
        END IF;
    
        --edit action is available if the professional that registered the complaint is the logged professional
        g_error := 'CONSTRUCTING EDIT ACTION';
        pk_alertlog.log_debug(g_error);
        l_coll_acttions.extend;
        l_coll_acttions(l_coll_acttions.last) := t_rec_action(id_action   => g_action_edit,
                                                              id_parent   => NULL,
                                                              level_nr    => 1,
                                                              from_state  => NULL,
                                                              to_state    => NULL,
                                                              desc_action => pk_message.get_message(i_lang      => i_lang,
                                                                                                    i_code_mess => 'DOCUMENTATION_M021'),
                                                              icon        => NULL,
                                                              flg_default => pk_alert_constant.g_no,
                                                              action      => 'EDIT',
                                                              flg_active  => l_available_action);
    
        --Cancel option is is always available
        g_error := 'CONSTRUCTING CANCEL ACTION';
        pk_alertlog.log_debug(g_error);
        l_coll_acttions.extend;
        l_coll_acttions(l_coll_acttions.last) := t_rec_action(id_action   => g_action_cancel,
                                                              id_parent   => NULL,
                                                              level_nr    => 1,
                                                              from_state  => NULL,
                                                              to_state    => g_canceled,
                                                              desc_action => pk_message.get_message(i_lang      => i_lang,
                                                                                                    i_code_mess => 'DOCUMENTATION_M053'),
                                                              icon        => NULL,
                                                              flg_default => pk_alert_constant.g_no,
                                                              action      => 'CANCEL',
                                                              flg_active  => l_available_action);
    
        g_error := 'Open o_action cursor';
        OPEN o_actions FOR
            SELECT id_action,
                   id_parent,
                   level_nr,
                   from_state,
                   to_state,
                   desc_action,
                   icon,
                   flg_default,
                   flg_active,
                   action
              FROM TABLE(l_coll_acttions);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              'get_actions_epis_reason',
                                              o_error);
            pk_types.open_my_cursor(o_actions);
            RETURN FALSE;
    END get_actions_epis_reason;
    /**********************************************************************************************
    * Get complaint for CDA section: Chief Complaint and Reason for Visit
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional ID
    * @param i_scope                 ID for scope type
    * @param i_scope_type            Scope type (E)pisode/(V)isit/(P)atient
    * @param o_complaint             Cursor with all complaints for the given scope
    * @param o_error                 Error message
    *
    * @return                        True on success, false otherwise
    *                        
    * @author                        Vanessa Barsottelli
    * @version                       2.6.3
    * @since                         2013/12/23 
    ***********************************************************************************************/
    FUNCTION get_epis_complaint_cda
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope      IN NUMBER,
        i_scope_type IN VARCHAR2,
        o_complaint  OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id_patient patient.id_patient%TYPE;
        l_id_episode episode.id_episode%TYPE;
        l_id_visit   visit.id_visit%TYPE;
        l_function_name CONSTANT VARCHAR2(32 CHAR) := 'GET_EPIS_COMPLAINT_CDA';
    BEGIN
        IF i_scope IS NULL
           OR i_scope_type IS NULL
        THEN
            g_error := 'SCOPE ID OR TYPE IS NULL';
            RAISE g_exception;
        END IF;
    
        g_error := 'ANALYSING SCOPE TYPE';
        IF NOT pk_touch_option.get_scope_vars(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_scope      => i_scope,
                                              i_scope_type => i_scope_type,
                                              o_patient    => l_id_patient,
                                              o_visit      => l_id_visit,
                                              o_episode    => l_id_episode,
                                              o_error      => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        OPEN o_complaint FOR
            SELECT t.id, t.desc_complaint
              FROM (SELECT *
                      FROM (SELECT ec.id_epis_complaint id, to_clob(ec.patient_complaint) desc_complaint, ec.id_episode
                              FROM epis_complaint ec
                             WHERE ec.flg_status = g_complaint_act
                               AND ec.patient_complaint IS NOT NULL
                            UNION ALL
                            SELECT ec.id_epis_complaint id,
                                   to_clob(pk_translation.get_translation(i_lang, c.code_complaint)) desc_complaint,
                                   ec.id_episode
                              FROM epis_complaint ec
                              JOIN complaint c
                                ON c.id_complaint = ec.id_complaint
                             WHERE ec.flg_status = g_complaint_act
                            UNION ALL
                            SELECT ea.id_epis_anamnesis id, ea.desc_epis_anamnesis desc_complaint, ea.id_episode
                              FROM epis_anamnesis ea
                             WHERE ea.flg_status = g_complaint_act
                               AND ea.flg_type = g_flg_type_c) comp
                     INNER JOIN (SELECT e.id_episode
                                  FROM episode e
                                 WHERE e.id_episode = l_id_episode
                                   AND e.id_patient = l_id_patient
                                   AND i_scope_type = pk_alert_constant.g_scope_type_episode
                                UNION ALL
                                SELECT e.id_episode
                                  FROM episode e
                                 WHERE e.id_patient = l_id_patient
                                   AND i_scope_type = pk_alert_constant.g_scope_type_patient
                                UNION ALL
                                SELECT e.id_episode
                                  FROM episode e
                                 WHERE e.id_visit = l_id_visit
                                   AND e.id_patient = l_id_patient
                                   AND i_scope_type = pk_alert_constant.g_scope_type_visit) epi
                        ON epi.id_episode = comp.id_episode) t
             WHERE dbms_lob.compare(t.desc_complaint, empty_clob()) > 0;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => g_package_name,
                                              i_function => l_function_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_complaint);
            RETURN FALSE;
    END get_epis_complaint_cda;
    /**********************************************************************************************
    * get_complaint_detail_hist
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional ID
    * @param i_id_episode            id episode
    *
    * @return                        True on success, false otherwise
    *                        
    * @author                        Paulo Teixeira
    * @version                       2.6.3
    * @since                         2014/07/02 
    ***********************************************************************************************/
    FUNCTION get_complaint_detail_hist
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_history    OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_function_name CONSTANT VARCHAR2(30 CHAR) := 'GET_COMPLAINT_DETAIL_HIST';
        tb_ids                  table_number;
        tb_tree_ids             table_number;
        tb_source               table_varchar;
        l_cancellation          sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                                        i_prof      => i_prof,
                                                                                        i_code_mess => 'COMMON_T032');
        l_creation              sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                                        i_prof      => i_prof,
                                                                                        i_code_mess => 'COMMON_T030');
        l_edition               sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                                        i_prof      => i_prof,
                                                                                        i_code_mess => 'COMMON_T029');
        l_cancel_reason         sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                                        i_prof      => i_prof,
                                                                                        i_code_mess => 'COMMON_M072');
        l_cancel_notes          sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                                        i_prof      => i_prof,
                                                                                        i_code_mess => 'COMMON_M073');
        l_new_record            sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                                        i_prof      => i_prof,
                                                                                        i_code_mess => 'COMMON_T031');
        l_chief_complaint       sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                                        i_prof      => i_prof,
                                                                                        i_code_mess => 'EDIS_CHIEF_COMPLAINT_M001');
        l_scope_chief_complaint sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                                        i_prof      => i_prof,
                                                                                        i_code_mess => 'COMPLAINTDOCTOR_T014');
        l_documented            sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                                        i_prof      => i_prof,
                                                                                        i_code_mess => 'EDIS_CHIEF_COMPLAINT_T008');
    
        CURSOR c_history_compl(l_id_epis_complaint table_number) IS
            SELECT ec.id_epis_complaint,
                   ec.flg_status,
                   pk_sysdomain.get_domain(i_code_dom => g_complaint_status_domain,
                                           i_val      => ec.flg_status,
                                           i_lang     => i_lang) status_desc,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, ec.id_professional) create_user_desc,
                   ec.adw_last_update_tstz create_time,
                   pk_date_utils.date_char_tsz(i_lang => i_lang,
                                               i_date => ec.adw_last_update_tstz,
                                               i_inst => i_prof.institution,
                                               i_soft => i_prof.software) create_time_ux,
                   pk_translation.get_translation(i_lang, c.code_complaint) scoupe_desc,
                   ec.patient_complaint complaint_desc,
                   pk_translation.get_translation(i_lang, c_old.code_complaint) scoupe_desc_old,
                   ec_old.patient_complaint complaint_desc_old,
                   CASE
                        WHEN ec.id_cancel_info_det IS NULL THEN
                         NULL
                        ELSE
                         pk_paramedical_prof_core.get_notes_desc(i_lang, i_prof, ec.id_cancel_info_det)
                    END notes_cancel,
                   CASE
                        WHEN ec.id_cancel_info_det IS NULL THEN
                         NULL
                        ELSE
                         pk_paramedical_prof_core.get_cancel_reason_desc(i_lang, i_prof, ec.id_cancel_info_det)
                    END cancel_reason_desc
              FROM epis_complaint ec
              LEFT JOIN complaint c
                ON ec.id_complaint = c.id_complaint
              LEFT JOIN epis_complaint ec_old
                ON ec.id_epis_complaint_parent = ec_old.id_epis_complaint
              LEFT JOIN complaint c_old
                ON ec_old.id_complaint = c_old.id_complaint
             WHERE ec.id_epis_complaint IN (SELECT /*+opt_estimate(table aux rows=1)*/
                                             column_value
                                              FROM TABLE(l_id_epis_complaint) aux)
             ORDER BY ec.adw_last_update_tstz DESC;
    
        CURSOR c_history_anamn(l_id_epis_anamnesis table_number) IS
            SELECT ea.id_epis_anamnesis,
                   ea.flg_status,
                   pk_sysdomain.get_domain(i_code_dom => g_complaint_status_domain,
                                           i_val      => ea.flg_status,
                                           i_lang     => i_lang) status_desc,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, ea.id_professional) create_user_desc,
                   ea.dt_epis_anamnesis_tstz create_time,
                   pk_date_utils.date_char_tsz(i_lang => i_lang,
                                               i_date => ea.dt_epis_anamnesis_tstz,
                                               i_inst => i_prof.institution,
                                               i_soft => i_prof.software) create_time_ux,
                   ea.desc_epis_anamnesis anamnesis_desc,
                   ea_old.desc_epis_anamnesis anamnesis_desc_old,
                   CASE
                        WHEN ea.id_cancel_info_det IS NULL THEN
                         NULL
                        ELSE
                         pk_paramedical_prof_core.get_notes_desc(i_lang, i_prof, ea.id_cancel_info_det)
                    END notes_cancel,
                   CASE
                        WHEN ea.id_cancel_info_det IS NULL THEN
                         NULL
                        ELSE
                         pk_paramedical_prof_core.get_cancel_reason_desc(i_lang, i_prof, ea.id_cancel_info_det)
                    END cancel_reason_desc
              FROM epis_anamnesis ea
              LEFT JOIN epis_anamnesis ea_old
                ON ea.id_epis_anamnesis_parent = ea_old.id_epis_anamnesis
             WHERE ea.id_epis_anamnesis IN (SELECT /*+opt_estimate(table aux rows=1)*/
                                             column_value
                                              FROM TABLE(l_id_epis_anamnesis) aux)
             ORDER BY ea.dt_epis_anamnesis_tstz DESC;
    BEGIN
        g_error := 'GET complaint leafs';
        BEGIN
            SELECT aux.ids, aux.l_source
              BULK COLLECT
              INTO tb_ids, tb_source
              FROM (SELECT ec.id_epis_complaint ids, ec.adw_last_update_tstz dt_reg, g_epis_complaint l_source
                      FROM epis_complaint ec
                     WHERE ec.id_episode = i_id_episode
                       AND ec.flg_status IN (pk_alert_constant.g_active, pk_alert_constant.g_cancelled)
                    UNION ALL
                    SELECT ea.id_epis_anamnesis ids, ea.dt_epis_anamnesis_tstz dt_reg, g_epis_anamnesis l_source
                      FROM epis_anamnesis ea
                     WHERE ea.id_episode = i_id_episode
                       AND ea.flg_status IN (pk_alert_constant.g_active, pk_alert_constant.g_cancelled)) aux
             ORDER BY aux.dt_reg DESC;
        EXCEPTION
            WHEN no_data_found THEN
                tb_ids    := table_number();
                tb_source := table_varchar();
        END;
    
        g_error := 'Initialize history table';
        pk_edis_hist.init_vars;
    
        g_error := 'loop tb_id_epis_complaint';
        FOR i IN 1 .. tb_ids.count
        LOOP
        
            IF tb_source(i) = g_epis_complaint
            THEN
            
                tb_tree_ids := table_number();
                BEGIN
                    SELECT aux.tb_ids
                      INTO tb_tree_ids
                      FROM (SELECT pk_utils.str_split_n(substr(sys_connect_by_path(ec.id_epis_complaint, ','), 2), ',') tb_ids,
                                   connect_by_isleaf isleaf
                              FROM epis_complaint ec
                             WHERE ec.id_episode = i_id_episode
                            CONNECT BY ec.id_epis_complaint = PRIOR ec.id_epis_complaint_parent
                             START WITH ec.id_epis_complaint = tb_ids(i)) aux
                     WHERE aux.isleaf = 1
                       AND rownum = 1;
                EXCEPTION
                    WHEN no_data_found THEN
                        tb_tree_ids := table_number();
                END;
            
                FOR r_history IN c_history_compl(tb_tree_ids)
                LOOP
                    g_error := 'Create a new line in history table with current history record ';
                    pk_edis_hist.add_line(i_history        => r_history.id_epis_complaint,
                                          i_dt_hist        => r_history.create_time,
                                          i_record_state   => r_history.flg_status,
                                          i_desc_rec_state => r_history.status_desc);
                
                    g_error := 'Add title';
                    pk_edis_hist.add_value(i_label => CASE
                                                          WHEN r_history.flg_status = pk_alert_constant.g_cancelled THEN
                                                           l_cancellation
                                                          WHEN r_history.id_epis_complaint = tb_tree_ids(tb_tree_ids.count) THEN
                                                           l_creation
                                                          ELSE
                                                           l_edition
                                                      END,
                                           i_value => ' ',
                                           i_type  => pk_edis_hist.g_type_title);
                
                    IF r_history.flg_status = pk_alert_constant.g_cancelled
                    THEN
                        g_error := 'call pk_edis_hist.add_value_if_not_null';
                        pk_edis_hist.add_value_if_not_null(i_label => l_cancel_reason || ' ' || l_new_record,
                                                           i_value => r_history.cancel_reason_desc,
                                                           i_type  => pk_edis_hist.g_type_new_content);
                    
                        g_error := 'call pk_edis_hist.add_value_if_not_null';
                        pk_edis_hist.add_value_if_not_null(i_label => l_cancel_notes || ' ' || l_new_record,
                                                           i_value => r_history.notes_cancel,
                                                           i_type  => pk_edis_hist.g_type_new_content);
                    ELSE
                        IF r_history.id_epis_complaint = tb_tree_ids(tb_tree_ids.count) -- fisrt record, creation record,
                        THEN
                            g_error := 'call pk_edis_hist.add_value_if_not_null';
                            pk_edis_hist.add_value_if_not_null(i_label => l_chief_complaint,
                                                               i_value => r_history.complaint_desc,
                                                               i_type  => pk_edis_hist.g_type_content);
                        
                            g_error := 'call pk_edis_hist.add_value_if_not_null';
                            pk_edis_hist.add_value_if_not_null(i_label => l_scope_chief_complaint,
                                                               i_value => r_history.scoupe_desc,
                                                               i_type  => pk_edis_hist.g_type_content);
                        ELSE
                            IF (r_history.complaint_desc <> r_history.complaint_desc_old)
                               OR (r_history.complaint_desc IS NOT NULL AND r_history.complaint_desc_old IS NULL)
                               OR (r_history.complaint_desc IS NULL AND r_history.complaint_desc_old IS NOT NULL)
                            THEN
                                g_error := 'call pk_edis_hist.add_value_if_not_null';
                                pk_edis_hist.add_value_if_not_null(i_label => l_chief_complaint || ' ' || l_new_record,
                                                                   i_value => r_history.complaint_desc,
                                                                   i_type  => pk_edis_hist.g_type_new_content);
                            
                                g_error := 'call pk_edis_hist.add_value_if_not_null';
                                pk_edis_hist.add_value_if_not_null(i_label => l_chief_complaint,
                                                                   i_value => r_history.complaint_desc_old,
                                                                   i_type  => pk_edis_hist.g_type_content);
                            END IF;
                        
                            IF (r_history.scoupe_desc <> r_history.scoupe_desc_old)
                               OR (r_history.scoupe_desc IS NOT NULL AND r_history.scoupe_desc_old IS NULL)
                               OR (r_history.scoupe_desc IS NULL AND r_history.scoupe_desc_old IS NOT NULL)
                            THEN
                                g_error := 'call pk_edis_hist.add_value_if_not_null';
                                pk_edis_hist.add_value_if_not_null(i_label => l_scope_chief_complaint || ' ' ||
                                                                              l_new_record,
                                                                   i_value => r_history.scoupe_desc,
                                                                   i_type  => pk_edis_hist.g_type_new_content);
                            
                                g_error := 'call pk_edis_hist.add_value_if_not_null';
                                pk_edis_hist.add_value_if_not_null(i_label => l_scope_chief_complaint,
                                                                   i_value => r_history.scoupe_desc_old,
                                                                   i_type  => pk_edis_hist.g_type_content);
                            END IF;
                        
                        END IF;
                    END IF;
                
                    g_error := 'Add signature';
                    pk_edis_hist.add_value(i_label => l_documented,
                                           i_value => r_history.create_user_desc || '; ' || r_history.create_time_ux,
                                           i_type  => pk_edis_hist.g_type_signature);
                
                    g_error := 'Add empty line';
                    pk_edis_hist.add_value(i_label => NULL, i_value => NULL, i_type => pk_edis_hist.g_type_empty_line);
                
                    IF r_history.id_epis_complaint <> tb_tree_ids(tb_tree_ids.count) -- fisrt record, creation record, no slash line
                    THEN
                        g_error := 'Add slash line';
                        pk_edis_hist.add_value(i_label => NULL,
                                               i_value => NULL,
                                               i_type  => pk_edis_hist.g_type_slash_line);
                    END IF;
                
                END LOOP;
            ELSE
                tb_tree_ids := table_number();
                BEGIN
                    SELECT aux.tb_ids
                      INTO tb_tree_ids
                      FROM (SELECT pk_utils.str_split_n(substr(sys_connect_by_path(ea.id_epis_anamnesis, ','), 2), ',') tb_ids,
                                   connect_by_isleaf isleaf
                              FROM epis_anamnesis ea
                             WHERE ea.id_episode = i_id_episode
                            CONNECT BY ea.id_epis_anamnesis = PRIOR ea.id_epis_anamnesis_parent
                             START WITH ea.id_epis_anamnesis = tb_ids(i)) aux
                     WHERE aux.isleaf = 1
                       AND rownum = 1;
                EXCEPTION
                    WHEN no_data_found THEN
                        tb_tree_ids := table_number();
                END;
            
                FOR r_history IN c_history_anamn(tb_tree_ids)
                LOOP
                    g_error := 'Create a new line in history table with current history record ';
                    pk_edis_hist.add_line(i_history        => r_history.id_epis_anamnesis,
                                          i_dt_hist        => r_history.create_time,
                                          i_record_state   => r_history.flg_status,
                                          i_desc_rec_state => r_history.status_desc);
                
                    g_error := 'Add title';
                    pk_edis_hist.add_value(i_label => CASE
                                                          WHEN r_history.flg_status = pk_alert_constant.g_cancelled THEN
                                                           l_cancellation
                                                          WHEN r_history.id_epis_anamnesis = tb_tree_ids(tb_tree_ids.count) THEN
                                                           l_creation
                                                          ELSE
                                                           l_edition
                                                      END,
                                           i_value => ' ',
                                           i_type  => pk_edis_hist.g_type_title);
                
                    IF r_history.flg_status = pk_alert_constant.g_cancelled
                    THEN
                        g_error := 'call pk_edis_hist.add_value_if_not_null';
                        pk_edis_hist.add_value_if_not_null(i_label => l_cancel_reason || ' ' || l_new_record,
                                                           i_value => r_history.cancel_reason_desc,
                                                           i_type  => pk_edis_hist.g_type_new_content);
                    
                        g_error := 'call pk_edis_hist.add_value_if_not_null';
                        pk_edis_hist.add_value_if_not_null(i_label => l_cancel_notes || ' ' || l_new_record,
                                                           i_value => r_history.notes_cancel,
                                                           i_type  => pk_edis_hist.g_type_new_content);
                    ELSE
                        IF r_history.id_epis_anamnesis = tb_tree_ids(tb_tree_ids.count) -- fisrt record, creation record,
                        THEN
                            g_error := 'call pk_edis_hist.add_value_if_not_null';
                            pk_edis_hist.add_value_if_not_null(i_label => l_chief_complaint,
                                                               i_value => r_history.anamnesis_desc,
                                                               i_type  => pk_edis_hist.g_type_content);
                        ELSE
                            IF (r_history.anamnesis_desc <> r_history.anamnesis_desc_old)
                               OR (r_history.anamnesis_desc IS NOT NULL AND r_history.anamnesis_desc_old IS NULL)
                               OR (r_history.anamnesis_desc IS NULL AND r_history.anamnesis_desc_old IS NOT NULL)
                            THEN
                                g_error := 'call pk_edis_hist.add_value_if_not_null';
                                pk_edis_hist.add_value_if_not_null(i_label => l_chief_complaint || ' ' || l_new_record,
                                                                   i_value => r_history.anamnesis_desc,
                                                                   i_type  => pk_edis_hist.g_type_new_content);
                            
                                g_error := 'call pk_edis_hist.add_value_if_not_null';
                                pk_edis_hist.add_value_if_not_null(i_label => l_chief_complaint,
                                                                   i_value => r_history.anamnesis_desc_old,
                                                                   i_type  => pk_edis_hist.g_type_content);
                            END IF;
                        
                        END IF;
                    END IF;
                
                    g_error := 'Add signature';
                    pk_edis_hist.add_value(i_label => l_documented,
                                           i_value => r_history.create_user_desc || '; ' || r_history.create_time_ux,
                                           i_type  => pk_edis_hist.g_type_signature);
                
                    g_error := 'Add empty line';
                    pk_edis_hist.add_value(i_label => NULL, i_value => NULL, i_type => pk_edis_hist.g_type_empty_line);
                
                    IF r_history.id_epis_anamnesis <> tb_tree_ids(tb_tree_ids.count) -- fisrt record, creation record, no slash line
                    THEN
                        g_error := 'Add slash line';
                        pk_edis_hist.add_value(i_label => NULL,
                                               i_value => NULL,
                                               i_type  => pk_edis_hist.g_type_slash_line);
                    END IF;
                
                END LOOP;
            END IF;
        
            IF i <> tb_ids.count -- last record no white line
            THEN
                g_error := 'Add white line';
                pk_edis_hist.add_value(i_label => NULL, i_value => NULL, i_type => pk_edis_hist.g_type_white_line);
            END IF;
        END LOOP;
    
        g_error := 'open o_history';
        OPEN o_history FOR
            SELECT t.id_history,
                   t.tbl_labels,
                   t.tbl_values,
                   t.tbl_types,
                   t.tbl_info_labels,
                   t.tbl_info_values,
                   t.tbl_codes,
                   t.dt_history,
                   (SELECT COUNT(*)
                      FROM TABLE(t.tbl_types)) count_elems
              FROM TABLE(pk_edis_hist.tf_hist) t;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => g_package_name,
                                              i_function => l_function_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_history);
            RETURN FALSE;
    END get_complaint_detail_hist;

    /**********************************************************************************************
    * get_complaint_detail
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional ID
    * @param i_id_episode            id episode
    *
    * @return                        True on success, false otherwise
    *                        
    * @author                        Paulo Teixeira
    * @version                       2.6.3
    * @since                         2014/07/02 
    ***********************************************************************************************/
    FUNCTION get_complaint_detail
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_history    OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_function_name CONSTANT VARCHAR2(30 CHAR) := 'GET_COMPLAINT_DETAIL';
        tb_ids                  table_number;
        tb_level                table_number;
        tb_source               table_varchar;
        l_cancel_reason         sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                                        i_prof      => i_prof,
                                                                                        i_code_mess => 'COMMON_M072');
        l_cancel_notes          sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                                        i_prof      => i_prof,
                                                                                        i_code_mess => 'COMMON_M073');
        l_chief_complaint       sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                                        i_prof      => i_prof,
                                                                                        i_code_mess => 'EDIS_CHIEF_COMPLAINT_M001');
        l_scope_chief_complaint sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                                        i_prof      => i_prof,
                                                                                        i_code_mess => 'COMPLAINTDOCTOR_T014');
        l_documented            sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                                        i_prof      => i_prof,
                                                                                        i_code_mess => 'EDIS_CHIEF_COMPLAINT_T008');
        l_updated               sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                                        i_prof      => i_prof,
                                                                                        i_code_mess => 'EDIS_CHIEF_COMPLAINT_T009');
    
        CURSOR c_history_compl(l_id_epis_complaint epis_complaint.id_epis_complaint%TYPE) IS
            SELECT ec.id_epis_complaint,
                   ec.flg_status,
                   pk_sysdomain.get_domain(i_code_dom => g_complaint_status_domain,
                                           i_val      => ec.flg_status,
                                           i_lang     => i_lang) status_desc,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, ec.id_professional) create_user_desc,
                   ec.adw_last_update_tstz create_time,
                   pk_date_utils.date_char_tsz(i_lang => i_lang,
                                               i_date => ec.adw_last_update_tstz,
                                               i_inst => i_prof.institution,
                                               i_soft => i_prof.software) create_time_ux,
                   pk_translation.get_translation(i_lang, c.code_complaint) scoupe_desc,
                   ec.patient_complaint complaint_desc,
                   CASE
                        WHEN ec.id_cancel_info_det IS NULL THEN
                         NULL
                        ELSE
                         pk_paramedical_prof_core.get_notes_desc(i_lang, i_prof, ec.id_cancel_info_det)
                    END notes_cancel,
                   CASE
                        WHEN ec.id_cancel_info_det IS NULL THEN
                         NULL
                        ELSE
                         pk_paramedical_prof_core.get_cancel_reason_desc(i_lang, i_prof, ec.id_cancel_info_det)
                    END cancel_reason_desc
              FROM epis_complaint ec
              LEFT JOIN complaint c
                ON ec.id_complaint = c.id_complaint
             WHERE ec.id_epis_complaint = l_id_epis_complaint;
    
        CURSOR c_history_anamn(l_id_epis_anamnesis epis_anamnesis.id_epis_anamnesis%TYPE) IS
            SELECT ea.id_epis_anamnesis,
                   ea.flg_status,
                   pk_sysdomain.get_domain(i_code_dom => g_complaint_status_domain,
                                           i_val      => ea.flg_status,
                                           i_lang     => i_lang) status_desc,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, ea.id_professional) create_user_desc,
                   ea.dt_epis_anamnesis_tstz create_time,
                   pk_date_utils.date_char_tsz(i_lang => i_lang,
                                               i_date => ea.dt_epis_anamnesis_tstz,
                                               i_inst => i_prof.institution,
                                               i_soft => i_prof.software) create_time_ux,
                   ea.desc_epis_anamnesis anamnesis_desc,
                   CASE
                        WHEN ea.id_cancel_info_det IS NULL THEN
                         NULL
                        ELSE
                         pk_paramedical_prof_core.get_notes_desc(i_lang, i_prof, ea.id_cancel_info_det)
                    END notes_cancel,
                   CASE
                        WHEN ea.id_cancel_info_det IS NULL THEN
                         NULL
                        ELSE
                         pk_paramedical_prof_core.get_cancel_reason_desc(i_lang, i_prof, ea.id_cancel_info_det)
                    END cancel_reason_desc
              FROM epis_anamnesis ea
             WHERE ea.id_epis_anamnesis = l_id_epis_anamnesis;
    
    BEGIN
        g_error := 'GET complaint leafs';
        BEGIN
            SELECT aux.ids, aux.l_level, aux.l_source
              BULK COLLECT
              INTO tb_ids, tb_level, tb_source
              FROM (SELECT ec.id_epis_complaint ids,
                           CASE
                                WHEN ec.id_epis_complaint_parent IS NULL THEN
                                 1
                                ELSE
                                 0
                            END l_level,
                           ec.adw_last_update_tstz dt_reg,
                           g_epis_complaint l_source
                      FROM epis_complaint ec
                     WHERE ec.id_episode = i_id_episode
                       AND ec.flg_status IN (pk_alert_constant.g_active, pk_alert_constant.g_cancelled)
                    UNION ALL
                    SELECT ea.id_epis_anamnesis ids,
                           CASE
                               WHEN ea.id_epis_anamnesis_parent IS NULL THEN
                                1
                               ELSE
                                0
                           END l_level,
                           ea.dt_epis_anamnesis_tstz dt_reg,
                           g_epis_anamnesis l_source
                      FROM epis_anamnesis ea
                     WHERE ea.id_episode = i_id_episode
                       AND ea.flg_status IN (pk_alert_constant.g_active, pk_alert_constant.g_cancelled)) aux
             ORDER BY aux.dt_reg DESC;
        EXCEPTION
            WHEN no_data_found THEN
                tb_ids    := table_number();
                tb_level  := table_number();
                tb_source := table_varchar();
        END;
    
        g_error := 'Initialize history table';
        pk_edis_hist.init_vars;
    
        FOR i IN 1 .. tb_ids.count
        LOOP
            IF tb_source(i) = g_epis_complaint
            THEN
                g_error := 'LOOP EPIS_COMPLAINT RECORDS';
                FOR r_history IN c_history_compl(tb_ids(i))
                LOOP
                    g_error := 'Create a new line in history table with current history record ';
                    pk_edis_hist.add_line(i_history        => r_history.id_epis_complaint,
                                          i_dt_hist        => r_history.create_time,
                                          i_record_state   => r_history.flg_status,
                                          i_desc_rec_state => r_history.status_desc);
                
                    g_error := 'Add title';
                    pk_edis_hist.add_value(i_label => l_chief_complaint,
                                           i_value => CASE
                                                          WHEN r_history.flg_status = pk_alert_constant.g_cancelled THEN
                                                           ' (' || r_history.status_desc || ')'
                                                          ELSE
                                                           ' '
                                                      END,
                                           i_type  => pk_edis_hist.g_type_title);
                
                    g_error := 'call pk_edis_hist.add_value_if_not_null';
                    pk_edis_hist.add_value_if_not_null(i_label => l_chief_complaint,
                                                       i_value => r_history.complaint_desc,
                                                       i_type  => pk_edis_hist.g_type_content);
                
                    g_error := 'call pk_edis_hist.add_value_if_not_null';
                    pk_edis_hist.add_value_if_not_null(i_label => l_scope_chief_complaint,
                                                       i_value => r_history.scoupe_desc,
                                                       i_type  => pk_edis_hist.g_type_content);
                
                    g_error := 'call pk_edis_hist.add_value_if_not_null';
                    pk_edis_hist.add_value_if_not_null(i_label => l_cancel_reason,
                                                       i_value => r_history.cancel_reason_desc,
                                                       i_type  => pk_edis_hist.g_type_content);
                
                    g_error := 'call pk_edis_hist.add_value_if_not_null';
                    pk_edis_hist.add_value_if_not_null(i_label => l_cancel_notes,
                                                       i_value => r_history.notes_cancel,
                                                       i_type  => pk_edis_hist.g_type_content);
                
                    g_error := 'Add signature';
                    pk_edis_hist.add_value(i_label => CASE
                                                          WHEN tb_level(i) = 1 THEN
                                                           l_documented
                                                          ELSE
                                                           l_updated
                                                      END,
                                           i_value => r_history.create_user_desc || '; ' || r_history.create_time_ux,
                                           i_type  => pk_edis_hist.g_type_signature);
                END LOOP;
            
            ELSE
                g_error := 'LOOP EPIS_ANAMNESIS RECORDS   ';
                FOR r_history IN c_history_anamn(tb_ids(i))
                LOOP
                    g_error := 'Create a new line in history table with current history record ';
                    pk_edis_hist.add_line(i_history        => r_history.id_epis_anamnesis,
                                          i_dt_hist        => r_history.create_time,
                                          i_record_state   => r_history.flg_status,
                                          i_desc_rec_state => r_history.status_desc);
                
                    g_error := 'Add title';
                    pk_edis_hist.add_value(i_label => l_chief_complaint,
                                           i_value => CASE
                                                          WHEN r_history.flg_status = pk_alert_constant.g_cancelled THEN
                                                           ' (' || r_history.status_desc || ')'
                                                          ELSE
                                                           ' '
                                                      END,
                                           i_type  => pk_edis_hist.g_type_title);
                
                    g_error := 'call pk_edis_hist.add_value_if_not_null';
                    pk_edis_hist.add_value_if_not_null(i_label => l_chief_complaint,
                                                       i_value => r_history.anamnesis_desc,
                                                       i_type  => pk_edis_hist.g_type_content);
                
                    g_error := 'call pk_edis_hist.add_value_if_not_null';
                    pk_edis_hist.add_value_if_not_null(i_label => l_cancel_reason,
                                                       i_value => r_history.cancel_reason_desc,
                                                       i_type  => pk_edis_hist.g_type_content);
                
                    g_error := 'call pk_edis_hist.add_value_if_not_null';
                    pk_edis_hist.add_value_if_not_null(i_label => l_cancel_notes,
                                                       i_value => r_history.notes_cancel,
                                                       i_type  => pk_edis_hist.g_type_content);
                
                    g_error := 'Add signature';
                    pk_edis_hist.add_value(i_label => CASE
                                                          WHEN tb_level(i) = 1 THEN
                                                           l_documented
                                                          ELSE
                                                           l_updated
                                                      END,
                                           i_value => r_history.create_user_desc || '; ' || r_history.create_time_ux,
                                           i_type  => pk_edis_hist.g_type_signature);
                END LOOP;
            END IF;
        
            IF i <> tb_ids.count
            THEN
                g_error := ' Add white line';
                pk_edis_hist.add_value(i_label => NULL, i_value => NULL, i_type => pk_edis_hist.g_type_empty_line);
                pk_edis_hist.add_value(i_label => NULL, i_value => NULL, i_type => pk_edis_hist.g_type_white_line);
            END IF;
        
        END LOOP;
    
        g_error := 'OPEN o_history';
        OPEN o_history FOR
            SELECT t.id_history,
                   t.tbl_labels,
                   t.tbl_values,
                   t.tbl_types,
                   t.tbl_info_labels,
                   t.tbl_info_values,
                   t.tbl_codes,
                   t.dt_history,
                   (SELECT COUNT(*)
                      FROM TABLE(t.tbl_types)) count_elems
              FROM TABLE(pk_edis_hist.tf_hist) t;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => g_package_name,
                                              i_function => l_function_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_history);
            RETURN FALSE;
    END get_complaint_detail;

    /**********************************************************************************************
    * Cancel epis_complaint
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional ID
    * @param i_id_epis_complaint     Epis Complaint ID
    * @param i_id_cancel_reason      Cancel Reason ID
    * @param i_notes_cancel          Notes cancel
    *
    * @param o_error                 error information
    *
    * @return                        True on success, false otherwise
    *                        
    * @author                        Vanessa Barsottelli
    * @version                       2.6.4
    * @since                         07-07-2014
    ***********************************************************************************************/
    FUNCTION cancel_compaint
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_epis_complaint IN epis_complaint.id_epis_complaint%TYPE,
        i_id_cancel_reason  IN cancel_info_det.id_cancel_info_det%TYPE,
        i_notes_cancel      IN cancel_info_det.notes_cancel_long%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_func_name CONSTANT VARCHAR2(15 CHAR) := 'CANCEL_COMPAINT';
    
        l_id_episode        episode.id_episode%TYPE;
        l_id_complaint      complaint.id_complaint%TYPE;
        l_patient_complaint epis_complaint.patient_complaint%TYPE;
        l_id_dep_clin_serv  dep_clin_serv.id_dep_clin_serv%TYPE;
        l_flg_reported_by   epis_complaint.flg_reported_by%TYPE;
        l_id_next           epis_complaint.id_epis_complaint%TYPE;
        l_id_cid            cancel_info_det.id_cancel_info_det%TYPE;
        l_rows              table_varchar := table_varchar();
    
    BEGIN
    
        IF i_id_epis_complaint IS NOT NULL
           AND i_id_cancel_reason IS NOT NULL
        THEN
        
            g_sysdate_tstz := current_timestamp;
        
            g_error := 'GET ID_EPISODE, ID_COMPLAINT, PATIENT_COMPLAINT';
            SELECT ec.id_episode, ec.id_complaint, ec.patient_complaint, ec.id_dep_clin_serv, ec.flg_reported_by
              INTO l_id_episode, l_id_complaint, l_patient_complaint, l_id_dep_clin_serv, l_flg_reported_by
              FROM epis_complaint ec
             WHERE ec.id_epis_complaint = i_id_epis_complaint;
        
            --INSERT NEW RECORD WITH FLG_STATUS = C AS COMPLAINT CHILD
            g_error := 'INSERT CANCEL_INFO_DET';
            ts_cancel_info_det.ins(id_prof_cancel_in        => i_prof.id,
                                   id_cancel_reason_in      => i_id_cancel_reason,
                                   dt_cancel_in             => g_sysdate_tstz,
                                   notes_cancel_long_in     => i_notes_cancel,
                                   flg_notes_cancel_type_in => CASE
                                                                   WHEN i_notes_cancel IS NULL THEN
                                                                    NULL
                                                                   ELSE
                                                                    g_long_notes
                                                               END,
                                   id_cancel_info_det_out   => l_id_cid,
                                   rows_out                 => l_rows);
        
            g_error := 'CALL PROCESS INSERT WITH CANCEL_INFO_DET ' || l_id_cid;
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'CANCEL_INFO_DET',
                                          i_rowids     => l_rows,
                                          o_error      => o_error);
        
            g_error   := 'GET SEQ_EPIS_COMPLAINT.NEXTVAL';
            l_id_next := ts_epis_complaint.next_key;
        
            g_error := 'INSERT EPIS_COMPLAINT';
            l_rows  := table_varchar();
            ts_epis_complaint.ins(id_epis_complaint_in        => l_id_next,
                                  id_episode_in               => l_id_episode,
                                  id_professional_in          => i_prof.id,
                                  id_complaint_in             => l_id_complaint,
                                  adw_last_update_tstz_in     => g_sysdate_tstz,
                                  patient_complaint_in        => l_patient_complaint,
                                  flg_status_in               => g_canceled,
                                  id_epis_complaint_parent_in => i_id_epis_complaint,
                                  flg_edition_type_in         => g_flg_edition_type_edit,
                                  flg_reported_by_in          => l_flg_reported_by,
                                  id_dep_clin_serv_in         => l_id_dep_clin_serv,
                                  id_cancel_info_det_in       => l_id_cid,
                                  rows_out                    => l_rows);
        
            g_error := 'PROCESS INSERT WITH ID_EPIS_COMPLAINT ' || l_id_next;
            pk_alertlog.log_debug(g_error);
            t_data_gov_mnt.process_insert(i_lang, i_prof, g_epis_complaint, l_rows, o_error);
        
            --UPDATE COMPLAINT AS OUTDADED
            g_error := 'UPDATE EPIS_COMPLAINT';
            l_rows  := table_varchar();
            ts_epis_complaint.upd(id_epis_complaint_in => i_id_epis_complaint,
                                  flg_status_in        => g_complaint_out,
                                  rows_out             => l_rows);
        
            ts_epis_complaint.upd(flg_status_in => g_complaint_out,
                                  where_in      => 'ID_EPIS_COMPLAINT_ROOT = ' || i_id_epis_complaint,
                                  rows_out      => l_rows);
            g_error := 'CALL PROCESS UPDATE WITH ID_EPIS_COMPLAINT ' || i_id_epis_complaint;
            t_data_gov_mnt.process_update(i_lang         => i_lang,
                                          i_prof         => i_prof,
                                          i_table_name   => g_epis_complaint,
                                          i_rowids       => l_rows,
                                          o_error        => o_error,
                                          i_list_columns => table_varchar('FLG_STATUS'));
        
            g_error := 'CALL PK_VISIT.SET_FIRST_OBS';
            IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                          i_id_episode          => l_id_episode,
                                          i_pat                 => pk_episode.get_id_patient(i_episode => l_id_episode),
                                          i_prof                => i_prof,
                                          i_prof_cat_type       => pk_prof_utils.get_category(i_lang, i_prof),
                                          i_dt_last_interaction => g_sysdate_tstz,
                                          i_dt_first_obs        => g_sysdate_tstz,
                                          o_error               => o_error)
            THEN
                RAISE g_exception;
            END IF;
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
        
    END cancel_compaint;

    /**********************************************************************************************
    * Cancel cancel_anamnesis
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional ID
    * @param id_epis_anamnesis       Epis Anamnesis ID
    * @param i_id_cancel_reason      Cancel Reason ID
    * @param i_notes_cancel          Notes cancel
    *
    * @param o_error                 error information
    *
    * @return                        True on success, false otherwise
    *                        
    * @author                        Vanessa Barsottelli
    * @version                       2.6.4
    * @since                         07-07-2014
    ***********************************************************************************************/
    FUNCTION cancel_anamnesis
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_epis_anamnesis IN epis_anamnesis.id_epis_anamnesis%TYPE,
        i_id_cancel_reason  IN cancel_info_det.id_cancel_info_det%TYPE,
        i_notes_cancel      IN cancel_info_det.notes_cancel_long%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_func_name CONSTANT VARCHAR2(20 CHAR) := 'CANCEL_ANAMNESIS';
    
        l_id_episode          episode.id_episode%TYPE;
        l_id_patient          patient.id_patient%TYPE;
        l_flg_type            epis_anamnesis.flg_type%TYPE;
        l_id_diagnosis        epis_anamnesis.id_diagnosis%TYPE;
        l_flg_class           epis_anamnesis.flg_class%TYPE;
        l_desc_epis_anamnesis epis_anamnesis.desc_epis_anamnesis%TYPE;
        l_flg_reported_by     epis_anamnesis.flg_reported_by%TYPE;
    
        l_id_next epis_complaint.id_epis_complaint%TYPE;
        l_id_cid  cancel_info_det.id_cancel_info_det%TYPE;
        l_rows    table_varchar := table_varchar();
    
    BEGIN
    
        IF i_id_epis_anamnesis IS NOT NULL
           AND i_id_cancel_reason IS NOT NULL
        THEN
        
            g_sysdate_tstz := current_timestamp;
        
            g_error := 'GET EPIS_ANAMNESIS INFO';
            SELECT ea.id_episode,
                   ea.flg_type,
                   ea.id_diagnosis,
                   ea.flg_class,
                   ea.id_patient,
                   ea.desc_epis_anamnesis,
                   ea.flg_reported_by
              INTO l_id_episode,
                   l_flg_type,
                   l_id_diagnosis,
                   l_flg_class,
                   l_id_patient,
                   l_desc_epis_anamnesis,
                   l_flg_reported_by
              FROM epis_anamnesis ea
             WHERE ea.id_epis_anamnesis = i_id_epis_anamnesis;
        
            --INSERT NEW RECORD WITH FLG_STATUS = C AS A COMPLAINT CHILD
            g_error := 'INSERT CANCEL_INFO_DET';
            ts_cancel_info_det.ins(id_prof_cancel_in        => i_prof.id,
                                   id_cancel_reason_in      => i_id_cancel_reason,
                                   dt_cancel_in             => g_sysdate_tstz,
                                   notes_cancel_long_in     => i_notes_cancel,
                                   flg_notes_cancel_type_in => CASE
                                                                   WHEN i_notes_cancel IS NULL THEN
                                                                    NULL
                                                                   ELSE
                                                                    g_long_notes
                                                               END,
                                   id_cancel_info_det_out   => l_id_cid,
                                   rows_out                 => l_rows);
        
            g_error := 'CALL PROCESS INSERT WITH CANCEL_INFO_DET ' || l_id_cid;
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'CANCEL_INFO_DET',
                                          i_rowids     => l_rows,
                                          o_error      => o_error);
        
            g_error   := 'GET SEQ_EPIS_ANAMNESIS.NEXT_KEY';
            l_id_next := ts_epis_anamnesis.next_key;
        
            g_error := 'INSERT EPIS_ANAMNESIS';
            l_rows  := table_varchar();
            ts_epis_anamnesis.ins(id_epis_anamnesis_in        => l_id_next,
                                  id_episode_in               => l_id_episode,
                                  id_professional_in          => i_prof.id,
                                  flg_type_in                 => l_flg_type,
                                  flg_temp_in                 => g_flg_temp_d,
                                  id_institution_in           => i_prof.institution,
                                  id_software_in              => i_prof.software,
                                  id_diagnosis_in             => l_id_diagnosis,
                                  flg_class_in                => l_flg_class,
                                  id_patient_in               => l_id_patient,
                                  dt_epis_anamnesis_tstz_in   => g_sysdate_tstz,
                                  id_epis_anamnesis_parent_in => i_id_epis_anamnesis,
                                  flg_status_in               => g_canceled,
                                  flg_edition_type_in         => g_flg_edition_type_edit,
                                  desc_epis_anamnesis_in      => l_desc_epis_anamnesis,
                                  id_cancel_info_det_in       => l_id_cid,
                                  flg_reported_by_in          => l_flg_reported_by,
                                  rows_out                    => l_rows);
        
            g_error := 'PROCESS INSERT WITH ID_EPIS_ANAMNESIS ' || l_id_next;
            pk_alertlog.log_debug(g_error);
            t_data_gov_mnt.process_insert(i_lang, i_prof, g_epis_anamnesis, l_rows, o_error);
        
            --UPDATE ANAMNESIS AS OUTDADED
            g_error := 'UPDATE EPIS_ANAMNESIS';
            l_rows  := table_varchar();
            ts_epis_anamnesis.upd(id_epis_anamnesis_in => i_id_epis_anamnesis,
                                  flg_temp_in          => g_flg_temp_h,
                                  flg_status_in        => g_outdated,
                                  rows_out             => l_rows);
        
            g_error := 'CALL PROCESS UPDATE WITH ID_EPIS_ANAMNESIS ' || i_id_epis_anamnesis;
            t_data_gov_mnt.process_update(i_lang         => i_lang,
                                          i_prof         => i_prof,
                                          i_table_name   => g_epis_anamnesis,
                                          i_rowids       => l_rows,
                                          o_error        => o_error,
                                          i_list_columns => table_varchar('FLG_TEMP', 'FLG_STATUS'));
        
            g_error := 'CALL PK_VISIT.SET_FIRST_OBS';
            IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                          i_id_episode          => l_id_episode,
                                          i_pat                 => pk_episode.get_id_patient(i_episode => l_id_episode),
                                          i_prof                => i_prof,
                                          i_prof_cat_type       => pk_prof_utils.get_category(i_lang, i_prof),
                                          i_dt_last_interaction => g_sysdate_tstz,
                                          i_dt_first_obs        => g_sysdate_tstz,
                                          o_error               => o_error)
            THEN
                RAISE g_exception;
            END IF;
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
        
    END cancel_anamnesis;

    /********************************************************************************************
    * Get complaint status.
    *
    * @param      i_lang                       preferred language id for this professional
    * @param      i_prof                       Professional ID
    * @param      i_id_epis_complaint          Epis_complaint ID
    * @param      o_status                     Complaint status
    * @param      o_error                      error message
    *
    * @return     boolean                      true or false on success or error
    *
    * @author                                  Vanessa Barsottelli
    * @version                                 2.6.4
    * @since                                   09-07-2014
    ********************************************************************************************/
    FUNCTION get_complaint_status
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_epis_complaint IN epis_complaint.id_epis_complaint%TYPE,
        o_status            OUT epis_complaint.flg_status%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_error := 'GET COMPLAINT STATUS i_id_epis_complaint: ' || i_id_epis_complaint;
        pk_alertlog.log_debug(g_error);
        SELECT ec.flg_status
          INTO o_status
          FROM epis_complaint ec
         WHERE ec.id_epis_complaint = i_id_epis_complaint;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => g_package_name,
                                              i_function => 'GET_COMPLAINT_STATUS',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_complaint_status;

    /********************************************************************************************
    * Get anamnesis status.
    *
    * @param      i_lang                       preferred language id for this professional
    * @param      i_prof                       Professional ID
    * @param      i_id_epis_anamnesis          Epis_anamnesis ID
    * @param      o_status                     Complaint status
    * @param      o_error                      error message
    *
    * @return     boolean                      true or false on success or error
    *
    * @author                                  Vanessa Barsottelli
    * @version                                 2.6.4
    * @since                                   09-07-2014
    ********************************************************************************************/
    FUNCTION get_anamnesis_status
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_epis_anamnesis IN epis_anamnesis.id_epis_anamnesis%TYPE,
        o_status            OUT epis_complaint.flg_status%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_error := 'GET ANAMNESIS STATUS i_id_epis_anamnesis: ' || i_id_epis_anamnesis;
        pk_alertlog.log_debug(g_error);
        SELECT ea.flg_status
          INTO o_status
          FROM epis_anamnesis ea
         WHERE ea.id_epis_anamnesis = i_id_epis_anamnesis;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => g_package_name,
                                              i_function => 'GET_ANAMNESIS_STATUS',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_anamnesis_status;
    --
    /********************************************************************************************
    * Returns the active episode complaint. If there is no active complaint null is returned.
    *
    * @param i_lang                language id
    * @param i_prof                professional, software and institution ids
    * @param i_episode             episode id
    * @param o_error               Error message
    *
    * @return                      Episode complaint
    *
    * @author                      Sergio Dias
    * @since                       17/07/2014
    * @version                     2.6.4.1
    **********************************************************************************************/
    FUNCTION get_epis_act_complaint
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN table_number IS
    
        l_id_complaint table_number;
        l_error        t_error_out;
    
    BEGIN
        g_error := 'GET_EPIS_ACT_COMPLAINT';
        IF NOT get_epis_act_complaint(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_episode      => i_episode,
                                      o_id_complaint => l_id_complaint,
                                      o_error        => l_error)
        THEN
            RETURN NULL;
        END IF;
    
        RETURN l_id_complaint;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_epis_act_complaint;

    /********************************************************************************************
    * Returns a structured description of a chief complaint. 
    * Used in the Outpatient Single Page (Physician Progress Notes).
    *
    * @param i_lang                language id
    * @param i_prof                professional, software and institution ids
    * @param i_episode             episode id
    * @param o_description         Description
    * @param o_error               Error message
    *
    * @return boolean              true or false on success or error
    *
    * @author                      Vanessa Barsotelli
    * @since                       31/07/2014
    * @version                     2.6.4.1
    **********************************************************************************************/
    FUNCTION get_complaint_amb_description
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_episode     IN episode.id_episode%TYPE,
        o_description OUT CLOB,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_all_chief_complaint         table_clob;
        l_all_reason_for_visit_coding table_varchar;
    
        l_chief_complaints        CLOB;
        l_chief_complaint_ft      epis_anamnesis.desc_epis_anamnesis%TYPE;
        l_reported_by             sys_domain.desc_val%TYPE;
        l_reason_for_visit_coding CLOB;
    
        l_sm_chief_complaint sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                                     i_prof      => i_prof,
                                                                                     i_code_mess => 'EDIS_CHIEF_COMPLAINT_M001');
    
        l_sm_reported_by sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                                 i_prof      => i_prof,
                                                                                 i_code_mess => 'COMPLAINTDOCTOR_T006');
    
        l_sm_reason_for_visit_coding sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                                             i_prof      => i_prof,
                                                                                             i_code_mess => 'PN_T112');
    
        l_sm_scope_chief_complaint sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                                           i_prof      => i_prof,
                                                                                           i_code_mess => 'COMPLAINTDOCTOR_T014');
    
        l_description CLOB;
    BEGIN
        g_error := 'get chief complaint free text';
        BEGIN
            SELECT ea.desc_epis_anamnesis
              INTO l_chief_complaint_ft
              FROM epis_anamnesis ea
             WHERE ea.id_episode = i_episode
               AND ea.flg_type = g_flg_type_c
               AND ea.flg_status = g_active;
        EXCEPTION
            WHEN no_data_found THEN
                l_chief_complaint_ft := NULL;
        END;
    
        g_error := 'get chief conplaints';
        BEGIN
            SELECT pk_translation.get_translation(i_lang, c.code_complaint) desc_complaint
              BULK COLLECT
              INTO l_all_chief_complaint
              FROM epis_complaint ec
             INNER JOIN complaint c
                ON c.id_complaint = ec.id_complaint
             WHERE ec.id_episode = i_episode
               AND ec.flg_status = g_active;
        
            l_chief_complaints := pk_utils.concat_table(l_all_chief_complaint, ', ');
        EXCEPTION
            WHEN no_data_found THEN
                l_chief_complaints := NULL;
        END;
    
        g_error := 'get reported by';
        BEGIN
            SELECT pk_sysdomain.get_domain('EPIS_COMPLAINT.FLG_REPORTED_BY', ec.flg_reported_by, i_lang)
              INTO l_reported_by
              FROM epis_complaint ec
             WHERE ec.id_episode = i_episode
               AND ec.flg_status = g_active
               AND ec.id_epis_complaint_root IS NULL;
        EXCEPTION
            WHEN no_data_found THEN
            
                BEGIN
                    SELECT pk_sysdomain.get_domain('EPIS_COMPLAINT.FLG_REPORTED_BY', ea.flg_reported_by, i_lang)
                      INTO l_reported_by
                      FROM epis_anamnesis ea
                     WHERE ea.id_episode = i_episode
                       AND ea.flg_status = g_active
                       AND rownum = 1;
                EXCEPTION
                    WHEN no_data_found THEN
                        l_reported_by := NULL;
                END;
        END;
    
        g_error := 'get diagnoses coding';
        BEGIN
            SELECT pk_progress_notes.get_info_desc(ft.coding) desc_diagnosis
              INTO l_all_reason_for_visit_coding
              FROM (SELECT nvl(ec.flg_status, ea.flg_status) flg_status,
                           nvl(ec.adw_last_update_tstz, ea.dt_epis_anamnesis_tstz) dt_record,
                           decode(ec.id_epis_complaint,
                                  NULL,
                                  pk_progress_notes.get_coding_ea(i_lang, i_prof, ea.id_epis_anamnesis),
                                  pk_progress_notes.get_coding_ec(i_lang, i_prof, ec.id_epis_complaint)) coding
                      FROM pn_epis_reason per
                      LEFT JOIN epis_complaint ec
                        ON per.id_epis_complaint = ec.id_epis_complaint
                      LEFT JOIN epis_anamnesis ea
                        ON per.id_epis_anamnesis = ea.id_epis_anamnesis
                     WHERE per.id_episode = i_episode
                       AND per.flg_status = pk_alert_constant.g_active) ft
             ORDER BY ft.flg_status, ft.dt_record DESC;
        
            l_reason_for_visit_coding := pk_utils.concat_table(l_all_reason_for_visit_coding, ', ');
        EXCEPTION
            WHEN no_data_found THEN
                l_reason_for_visit_coding := NULL;
        END;
    
        IF l_chief_complaint_ft IS NOT NULL
        THEN
            l_description := l_sm_chief_complaint || ': ' || l_chief_complaint_ft;
        END IF;
    
        IF dbms_lob.compare(l_chief_complaints, empty_clob()) <> 0
        THEN
            l_description := l_description || chr(10) || l_sm_scope_chief_complaint || ': ' || l_chief_complaints;
        END IF;
    
        IF l_reported_by IS NOT NULL
        THEN
            l_description := l_description || chr(10) || l_sm_reported_by || ': ' || l_reported_by;
        END IF;
    
        IF dbms_lob.compare(l_reason_for_visit_coding, empty_clob()) <> 0
        THEN
            l_description := l_description || chr(10) || l_sm_reason_for_visit_coding || ': ' ||
                             l_reason_for_visit_coding;
        END IF;
    
        o_description := l_description;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => g_package_name,
                                              i_function => 'GET_COMPLAINT_AMB_DESCRIPTION',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_complaint_amb_description;

    /********************************************************************************************
    * get_reported_by values
    *
    * @param i_lang                language id
    * @param i_prof                professional, software and institution ids
    * @param o_list                cursor values out
    * @param o_error               Error message
    *
    * @return boolean              true or false on success or error
    *
    * @author                      Paulo Teixeira
    * @since                       14/7/2016
    * @version                     2.6.5
    **********************************************************************************************/
    FUNCTION get_reported_by
    (
        i_code_domain IN sys_domain.code_domain%TYPE,
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        o_list        OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_flg_default sys_config.value%TYPE := pk_sysconfig.get_config(i_prof    => i_prof,
                                                                       i_code_cf => 'DEFAULT_FLG_REPORTED_BY');
    BEGIN
        g_error := 'GET CURSOR';
        OPEN o_list FOR
            SELECT /*+opt_estimate (table t rows=1)*/
             t.desc_val,
             t.val,
             t.img_name,
             t.rank,
             decode(t.val, l_flg_default, pk_alert_constant.g_yes, pk_alert_constant.g_no) flg_default
              FROM TABLE(pk_sysdomain.get_values_domain_pipelined(i_lang          => i_lang,
                                                                  i_prof          => i_prof,
                                                                  i_code_dom      => i_code_domain,
                                                                  i_dep_clin_serv => NULL)) t;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              'GET_REPORTED_BY',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_reported_by;

    /********************************************************************************************
    * get_arabic_complaint
    *
    * @param i_lang                language id
    * @param i_prof                professional, software and institution ids
    * @param i_id_epis_complaint   i_id_epis_complaint
    *
    * @author                      Vítor Sá
    * @since                       23/04/2019
    * @version                     2.7.5.3
    **********************************************************************************************/
    FUNCTION get_arabic_complaint
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_epis_complaint IN epis_complaint.patient_complaint_arabic%TYPE
    ) RETURN VARCHAR2 IS
        l_arabic_complaint VARCHAR2(4000);
    BEGIN
    
        SELECT e.patient_complaint_arabic
          INTO l_arabic_complaint
          FROM epis_complaint e
         WHERE e.id_epis_complaint = i_id_epis_complaint;
    
        RETURN l_arabic_complaint;
    EXCEPTION
        WHEN no_data_found THEN
            l_arabic_complaint := NULL;
    END get_arabic_complaint;

    FUNCTION set_epis_chief_complaint
    (
        i_lang                     IN language.id_language%TYPE,
        i_prof                     IN profissional,
        i_prof_cat_type            IN category.flg_type%TYPE,
        i_episode                  IN episode.id_episode%TYPE,
        i_complaint                IN table_number,
        i_complaint_alias          IN table_number,
        i_patient_complaint        IN VARCHAR2,
        i_patient_complaint_arabic IN VARCHAR2,
        i_flg_reported_by          IN epis_complaint.flg_reported_by%TYPE,
        i_flg_type                 IN VARCHAR2,
        i_id_epis_complaint_root   IN epis_complaint.id_epis_complaint_root%TYPE,
        o_id_epis_complaint        OUT table_number,
        o_error                    OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_exception EXCEPTION;
        l_id_epis_complaint     epis_complaint.id_epis_complaint%TYPE;
        l_tbl_id_epis_complaint table_number := table_number();
        l_id_dcs                dep_clin_serv.id_dep_clin_serv%TYPE;
        FUNCTION set_epis_complaint_int
        (
            i_lang                     IN language.id_language%TYPE,
            i_prof                     IN profissional,
            i_epis                     IN episode.id_episode%TYPE,
            i_complaint                IN table_number,
            i_complaint_alias          IN table_number,
            i_patient_complaint        IN epis_complaint.patient_complaint%TYPE,
            i_patient_complaint_arabic IN epis_complaint.patient_complaint_arabic%TYPE,
            i_flg_type                 IN epis_complaint.flg_edition_type%TYPE,
            i_flg_reported_by          IN epis_complaint.flg_reported_by%TYPE,
            i_dep_clin_serv            IN dep_clin_serv.id_dep_clin_serv%TYPE,
            --    i_parent          IN epis_complaint.id_epis_complaint_parent%TYPE,
            i_id_epis_complaint_root IN epis_complaint.id_epis_complaint_root%TYPE,
            o_epis_complaint         OUT epis_complaint.id_epis_complaint%TYPE,
            o_error                  OUT t_error_out
        ) RETURN BOOLEAN IS
            l_root        epis_complaint.id_epis_complaint%TYPE;
            l_ec_row_coll ts_epis_complaint.epis_complaint_tc;
            l_ec_row      epis_complaint%ROWTYPE;
            l_rowids      table_varchar := table_varchar();
            l_id_patient  patient.id_patient%TYPE;
        BEGIN
            g_sysdate_tstz := current_timestamp;
        
            -- check input parameter
            IF i_complaint IS NULL
               OR i_complaint.count < 1
            THEN
                g_error := 'No complaints were specified!';
                RAISE g_exception;
            END IF;
        
            IF (i_id_epis_complaint_root IS NOT NULL AND i_flg_type = g_flg_edition_type_edit)
            THEN
                -- only when editing the previous complaint became inactive
                g_error  := 'UPDATE EPIS_COMPLAINT - EDIT';
                l_rowids := table_varchar();
                ts_epis_complaint.upd(flg_status_in => g_complaint_out,
                                      where_in      => 'id_episode = ' || i_epis || ' and id_epis_complaint = ' ||
                                                       i_id_epis_complaint_root || ' OR id_epis_complaint_root = ' ||
                                                       i_id_epis_complaint_root,
                                      rows_out      => l_rowids);
            
                g_error := 't_data_gov_mnt.process_update ts_epis_complaint';
                t_data_gov_mnt.process_update(i_lang         => i_lang,
                                              i_prof         => i_prof,
                                              i_table_name   => 'EPIS_COMPLAINT',
                                              i_rowids       => l_rowids,
                                              o_error        => o_error,
                                              i_list_columns => table_varchar('FLG_STATUS'));
            END IF;
        
            /*            -- outdate previous records
            g_error := 'CALL ts_epis_complaint.upd';
            ts_epis_complaint.upd(flg_status_in  => g_complaint_out,
                                  flg_status_nin => FALSE,
                                  where_in       => ' id_episode = ' || i_epis || ' AND flg_status = ''' ||
                                                    g_complaint_act || '''',
                                  rows_out       => l_rowids);
            g_error := 'CALL t_data_gov_mnt.process_update';
            t_data_gov_mnt.process_update(i_lang         => i_lang,
                                          i_prof         => i_prof,
                                          i_table_name   => 'EPIS_COMPLAINT',
                                          i_rowids       => l_rowids,
                                          o_error        => o_error,
                                          i_list_columns => table_varchar('FLG_STATUS'));*/
        
            -- set first row
            l_root := ts_epis_complaint.next_key;
        
            l_ec_row.id_epis_complaint := l_root;
            l_ec_row.id_episode := i_epis;
            l_ec_row.id_professional := i_prof.id;
            l_ec_row.id_complaint := i_complaint(1);
            l_ec_row.adw_last_update_tstz := g_sysdate_tstz;
            l_ec_row.patient_complaint := i_patient_complaint;
            l_ec_row.patient_complaint_arabic := i_patient_complaint_arabic;
            l_ec_row.flg_status := g_complaint_act;
            l_ec_row.id_epis_complaint_parent := i_id_epis_complaint_root;
            l_ec_row.flg_reported_by := i_flg_reported_by;
            l_ec_row.id_dep_clin_serv := i_dep_clin_serv;
            l_ec_row.flg_edition_type := i_flg_type;
            l_ec_row.id_complaint_alias := i_complaint_alias(1);
            l_ec_row_coll(1) := l_ec_row;
        
            -- set following rows
            IF i_complaint.count > 1
            THEN
                l_ec_row.patient_complaint        := NULL;
                l_ec_row.id_epis_complaint_parent := NULL;
                l_ec_row.flg_reported_by          := NULL;
                l_ec_row.id_epis_complaint_root   := l_root;
                l_ec_row.id_dep_clin_serv         := NULL;
            
                FOR i IN 2 .. i_complaint.count
                LOOP
                    l_ec_row.id_epis_complaint  := ts_epis_complaint.next_key;
                    l_ec_row.id_complaint       := i_complaint(i);
                    l_ec_row.id_complaint_alias := i_complaint_alias(i);
                
                    l_ec_row_coll(i) := l_ec_row;
                END LOOP;
            END IF;
        
            l_rowids := table_varchar();
            g_error  := 'CALL ts_epis_complaint.ins';
            ts_epis_complaint.ins(rows_in => l_ec_row_coll, rows_out => l_rowids);
            g_error := 'CALL t_data_gov_mnt.process_insert';
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'EPIS_COMPLAINT',
                                          i_rowids     => l_rowids,
                                          o_error      => o_error);
        
            IF i_prof.software = pk_alert_constant.g_soft_outpatient
            THEN
                SELECT ei.id_patient
                  INTO l_id_patient
                  FROM epis_info ei
                 INNER JOIN episode e
                    ON ei.id_episode = e.id_episode
                 WHERE e.id_episode = i_epis;
            
                pk_progress_notes.set_templates(i_lang    => i_lang,
                                                i_prof    => i_prof,
                                                i_episode => i_epis,
                                                i_patient => l_id_patient,
                                                i_id_ec   => l_root,
                                                o_error   => o_error);
            ELSE
                --Update episode's templates by complaint
                IF NOT pk_touch_option.update_epis_tmplt_by_complaint(i_lang           => i_lang,
                                                                      i_prof           => i_prof,
                                                                      i_episode        => i_epis,
                                                                      i_epis_complaint => l_root,
                                                                      i_do_commit      => pk_alert_constant.g_no,
                                                                      o_error          => o_error)
                THEN
                    RAISE l_exception;
                END IF;
            END IF;
        
            g_error := 'CALL TO SET_FIRST_OBS';
            IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                          i_id_episode          => i_epis,
                                          i_pat                 => NULL,
                                          i_prof                => i_prof,
                                          i_prof_cat_type       => i_prof_cat_type,
                                          i_dt_last_interaction => g_sysdate_tstz,
                                          i_dt_first_obs        => g_sysdate_tstz,
                                          o_error               => o_error)
            THEN
                RAISE l_exception;
            END IF;
            o_epis_complaint := l_root;
            RETURN TRUE;
        EXCEPTION
            WHEN OTHERS THEN
                RETURN error_handling(i_lang           => i_lang,
                                      i_func_proc_name => 'SET_REASON_EPIS_COMPLAINT_INT',
                                      i_error          => g_error,
                                      i_sqlerror       => SQLERRM,
                                      i_rollback       => TRUE,
                                      o_error          => o_error);
        END set_epis_complaint_int;
    
    BEGIN
        -- predefined reasons for visit were set:
        -- insert on epis_complaint
        g_error  := 'CALL get_dep_clin_serv';
        l_id_dcs := pk_episode.get_dep_clin_serv(i_lang => i_lang, i_prof => i_prof, i_episode => i_episode);
        /*        FOR i IN i_complaint.first .. i_complaint.last
        LOOP
        
            IF NOT set_epis_complaint(i_lang                     => i_lang,
                                      i_prof                     => i_prof,
                                      i_prof_cat_type            => i_prof_cat_type,
                                      i_epis                     => i_episode,
                                      i_complaint                => i_complaint(i),
                                      i_patient_complaint        => i_patient_complaint,
                                      i_patient_complaint_arabic => i_patient_complaint_arabic,
                                      i_flg_reported_by          => i_flg_reported_by,
                                      i_flg_type                 => i_flg_type,
                                      i_epis_complaint_parent    => i_id_epis_complaint_root,
                                      o_id_epis_complaint        => l_id_epis_complaint,
                                      o_error                    => o_error)
            THEN
                RAISE l_exception;
            END IF;
        
            l_tbl_id_epis_complaint.extend();
            l_tbl_id_epis_complaint(i) := l_id_epis_complaint;
        
        END LOOP;*/
    
        IF NOT set_epis_complaint_int(i_lang                     => i_lang,
                                      i_prof                     => i_prof,
                                      i_epis                     => i_episode,
                                      i_complaint                => i_complaint,
                                      i_complaint_alias          => i_complaint_alias,
                                      i_patient_complaint        => i_patient_complaint,
                                      i_patient_complaint_arabic => i_patient_complaint_arabic,
                                      i_flg_type                 => i_flg_type,
                                      i_flg_reported_by          => i_flg_reported_by,
                                      i_dep_clin_serv            => l_id_dcs,
                                      i_id_epis_complaint_root   => i_id_epis_complaint_root,
                                      o_epis_complaint           => l_id_epis_complaint,
                                      o_error                    => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        o_id_epis_complaint := table_number(l_id_epis_complaint);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_exception THEN
            RETURN error_handling(i_lang,
                                  'SET_EPIS_CHIEF_COMPLAINT',
                                  g_error || ' / ' || o_error.err_desc,
                                  SQLERRM,
                                  TRUE,
                                  o_error);
        WHEN OTHERS THEN
            RETURN error_handling(i_lang, 'SET_EPIS_CHIEF_COMPLAINT', g_error, SQLERRM, TRUE, o_error);
    END set_epis_chief_complaint;

    FUNCTION get_clinical_service
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN NUMBER IS
        k_config_cs           sys_config.desc_sys_config%TYPE := pk_sysconfig.get_config('COMPLAINT_CS_FILTER', i_prof);
        l_id_department       dep_clin_serv.id_department%TYPE;
        l_id_dep_clin_serv    dep_clin_serv.id_dep_clin_serv%TYPE;
        l_clinical_service    dep_clin_serv.id_clinical_service%TYPE;
        l_error               t_error_out;
        tbl_clinical_services table_number;
    BEGIN
    
        IF k_config_cs = pk_complaint.g_comp_filter_e
        THEN
        
            IF NOT pk_episode.get_epis_clin_serv(i_lang      => i_lang,
                                                 i_prof      => i_prof,
                                                 i_episode   => i_episode,
                                                 o_clin_serv => l_clinical_service,
                                                 o_error     => l_error)
            THEN
                RETURN NULL;
            END IF;
        ELSIF k_config_cs = pk_complaint.g_comp_filter_pp --professional preferences
        THEN
            IF NOT pk_prof_utils.get_prof_default_dcs(i_lang             => i_lang,
                                                      i_prof             => i_prof,
                                                      i_software         => i_prof.software,
                                                      o_id_dep_clin_serv => l_id_dep_clin_serv,
                                                      o_department       => l_id_department,
                                                      o_clinical_service => l_clinical_service,
                                                      o_error            => l_error)
            THEN
                RETURN NULL;
            END IF;
        
        ELSE
            SELECT q.id_clinical_service
              BULK COLLECT
              INTO tbl_clinical_services
              FROM (SELECT subq.id_clinical_service,
                           pk_translation.get_translation(i_lang => i_lang, i_code_mess => subq.code_clinical_service) desc_clicnical_service,
                           subq.rank_all
                      FROM (SELECT DISTINCT cs.id_clinical_service, cs.code_clinical_service, cs.rank rank_all
                              FROM prof_dep_clin_serv pdcs
                              JOIN dep_clin_serv dcs
                                ON pdcs.id_dep_clin_serv = dcs.id_dep_clin_serv
                              JOIN department d
                                ON dcs.id_department = d.id_department
                              JOIN clinical_service cs
                                ON dcs.id_clinical_service = cs.id_clinical_service
                              JOIN software_dept sdt
                                ON sdt.id_dept = d.id_dept
                             WHERE pdcs.id_professional = i_prof.id
                               AND pdcs.flg_status = pk_alert_constant.g_status_selected
                               AND d.id_institution = i_prof.institution
                               AND pdcs.id_institution = i_prof.institution
                               AND sdt.id_software = i_prof.software
                               AND cs.flg_available = pk_alert_constant.g_yes
                               AND d.flg_available = pk_alert_constant.g_yes
                               AND dcs.flg_available = pk_alert_constant.g_yes) subq) q
             ORDER BY q.rank_all, q.desc_clicnical_service;
        
            IF tbl_clinical_services.count > 0
            THEN
                l_clinical_service := tbl_clinical_services(1);
            END IF;
        END IF;
        RETURN l_clinical_service;
    END get_clinical_service;

    /**
    * Initialize parameters to be used in the grid query of complaints
    *
    * @param i_context_ids  identifier used in array of context
    * @param i_context_keys Content of the array context
    * @param i_context_vals Values  of the array context
    * @param i_name         variable for bind in the query
    * @param o_vc2          returned value if varchar
    * @param o_num          returned value if number
    * @param o_id           returned value if ID
    * @param o_tstz         returned value if date
    *
    * @author               Elisabete Bugalho
    * @version              2.8.2.0
    * @since                2020/07/22
    */
    PROCEDURE init_params_complaint
    (
        i_filter_name   IN VARCHAR2,
        i_custom_filter IN NUMBER,
        i_context_ids   IN table_number,
        i_context_keys  IN table_varchar DEFAULT NULL,
        i_context_vals  IN table_varchar,
        i_name          IN VARCHAR2,
        o_vc2           OUT VARCHAR2,
        o_num           OUT NUMBER,
        o_id            OUT NUMBER,
        o_tstz          OUT TIMESTAMP WITH LOCAL TIME ZONE
    ) IS
        g_lang             CONSTANT NUMBER(24) := 1;
        g_prof_id          CONSTANT NUMBER(24) := 2;
        g_prof_institution CONSTANT NUMBER(24) := 3;
        g_prof_software    CONSTANT NUMBER(24) := 4;
        g_episode          CONSTANT NUMBER(24) := 5;
        g_patient          CONSTANT NUMBER(24) := 6;
    
        l_lang CONSTANT language.id_language%TYPE := i_context_ids(g_lang);
        l_prof CONSTANT profissional := profissional(i_context_ids(g_prof_id),
                                                     i_context_ids(g_prof_institution),
                                                     i_context_ids(g_prof_software));
    
        l_patient CONSTANT NUMBER := i_context_ids(g_patient);
        l_episode CONSTANT NUMBER := i_context_ids(g_episode);
    
        l_value VARCHAR2(1000 CHAR);
    
        -- ***************************************************
        PROCEDURE set_context IS
        BEGIN
        
            pk_context_api.set_parameter('l_lang', l_lang);
            pk_context_api.set_parameter('l_prof_id', l_prof.id);
            pk_context_api.set_parameter('l_prof_institution', l_prof.institution);
            pk_context_api.set_parameter('l_prof_software', l_prof.software);
        
        END set_context;
    BEGIN
    
        set_context();
    
        CASE lower(i_name)
            WHEN 'i_lang' THEN
                o_id := l_lang;
            WHEN 'i_id_institution' THEN
                o_id := l_prof.institution;
            WHEN 'i_software' THEN
                o_id := l_prof.software;
            WHEN 'i_prof_id' THEN
                o_id := l_prof.id;
            WHEN 'l_pat_gender' THEN
                o_vc2 := pk_patient.get_pat_gender(i_id_patient => l_patient);
            WHEN 'l_pat_age' THEN
                o_id := pk_patient.get_pat_age(i_lang        => l_lang,
                                               i_dt_birth    => NULL,
                                               i_dt_deceased => NULL,
                                               i_age         => NULL,
                                               i_age_format  => 'YEARS',
                                               i_patient     => l_patient);
            WHEN 'id_episode' THEN
                o_id := l_episode;
            WHEN 'id_patient' THEN
                o_id := l_patient;
            WHEN 'l_clinical_service' THEN
                IF i_context_vals.count > 0
                THEN
                    o_id := i_context_vals(1);
                ELSE
                    o_id := get_clinical_service(l_lang, l_prof, l_episode);
                END IF;
                /*         ELSE
                o_vc2  := NULL;
                o_num  := NULL;
                o_id   := NULL;
                o_tstz := NULL;*/
        END CASE;
    
    END init_params_complaint;

    FUNCTION get_id_department
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN table_number IS
        l_department_list  table_number;
        l_id_department    dep_clin_serv.id_department%TYPE;
        l_id_dep_clin_serv dep_clin_serv.id_dep_clin_serv%TYPE;
        l_clinical_service dep_clin_serv.id_clinical_service%TYPE;
    
        l_cs_filter sys_config.desc_sys_config%TYPE := pk_sysconfig.get_config(g_scfg_complaint_cs_filter, i_prof);
    
        l_error t_error_out;
    BEGIN
        -- episode
        IF l_cs_filter = g_comp_filter_e
        THEN
        
            l_id_department   := pk_episode.get_epis_department(i_lang    => i_lang,
                                                                i_prof    => i_prof,
                                                                i_episode => i_episode);
            l_department_list := table_number(l_id_department);
        ELSIF l_cs_filter = g_comp_filter_pp --professional preferences
        THEN
            IF NOT pk_prof_utils.get_prof_default_dcs(i_lang             => i_lang,
                                                      i_prof             => i_prof,
                                                      i_software         => i_prof.software,
                                                      o_id_dep_clin_serv => l_id_dep_clin_serv,
                                                      o_department       => l_id_department,
                                                      o_clinical_service => l_clinical_service,
                                                      o_error            => l_error)
            THEN
                RETURN NULL;
            END IF;
            IF l_id_department IS NOT NULL
            THEN
                l_department_list := table_number(l_id_department);
            END IF;
        ELSIF l_cs_filter = g_comp_filter_pa
        THEN
            -- professional alocation
            l_department_list := pk_prof_utils.get_prof_dept_ids(i_lang => i_lang, i_prof => i_prof);
        END IF;
    
        RETURN l_department_list;
    
    END get_id_department;

    FUNCTION get_previous_complaints
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        o_list    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        k_func_name VARCHAR2(200 CHAR) := 'GET_PREVIOUS_COMPLAINTS';
        k_last      sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'COMPLAINT_T001');
    BEGIN
        /*        OPEN o_list FOR
        SELECT c.id_complaint,
               pk_translation.get_translation(i_lang, c.code_complaint) desc_complaint,
               pk_date_utils.date_chr_short_read_tsz(i_lang, ec.adw_last_update_tstz, i_prof) date_complaint,
               decode(ec.id_episode, i_episode, pk_alert_constant.g_yes, pk_alert_constant.g_no) flg_this_episode,
               COUNT(*) over(PARTITION BY ec.id_complaint) register_num
          FROM epis_complaint ec
          JOIN complaint c
            ON ec.id_complaint = c.id_complaint
          JOIN episode e
            ON ec.id_episode = e.id_episode
         WHERE e.id_patient = i_patient
           AND ec.flg_status = g_active
         ORDER BY ec.adw_last_update_tstz DESC;*/
    
        OPEN o_list FOR
            SELECT id_complaint,
                   pk_translation.get_translation(i_lang, code_complaint) desc_complaint,
                   k_last || pk_date_utils.date_chr_short_read_tsz(i_lang, adw_last_update_tstz, i_prof) date_complaint,
                   flg_this_episode,
                   register_num
              FROM (SELECT c.id_complaint,
                           decode(ec.id_episode, i_episode, pk_alert_constant.g_yes, pk_alert_constant.g_no) flg_this_episode,
                           ec.adw_last_update_tstz,
                           c.code_complaint,
                           COUNT(*) over(PARTITION BY ec.id_complaint) register_num,
                           row_number() over(PARTITION BY ec.id_complaint ORDER BY ec.adw_last_update_tstz DESC) rn
                      FROM epis_complaint ec
                      JOIN episode e
                        ON ec.id_episode = e.id_episode
                      JOIN epis_info ei
                        ON e.id_episode = ei.id_episode
                      JOIN complaint c
                        ON ec.id_complaint = c.id_complaint
                     WHERE e.id_patient = i_patient
                       AND ec.flg_status = g_active
                       AND ei.id_software = i_prof.software)
             WHERE rn = 1
             ORDER BY adw_last_update_tstz DESC;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              k_package_owner,
                                              g_package_name,
                                              k_func_name,
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
        
    END get_previous_complaints;

    FUNCTION get_epis_complaint
    (
        i_lang                     IN language.id_language%TYPE,
        i_prof                     IN profissional,
        i_episode                  IN episode.id_episode%TYPE,
        i_id_epis_complaint        IN epis_complaint.id_epis_complaint%TYPE,
        o_complaint_list           OUT pk_types.cursor_type,
        o_patient_complaint        OUT epis_complaint.patient_complaint%TYPE,
        o_patient_complaint_arabic OUT epis_complaint.patient_complaint_arabic%TYPE,
        o_flg_reported_by          OUT epis_complaint.flg_reported_by%TYPE,
        o_error                    OUT t_error_out
    ) RETURN BOOLEAN IS
        k_func_name    VARCHAR2(200 CHAR) := 'GET_EPIS_COMPLAINT';
        k_label        sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'COMMON_T014');
        l_dt_triage    epis_triage.dt_end_tstz%TYPE;
        l_dt_complaint epis_complaint.adw_last_update_tstz%TYPE;
    BEGIN
        IF i_id_epis_complaint IS NOT NULL
        THEN
            OPEN o_complaint_list FOR
                SELECT c.id_complaint,
                       decode(ec.id_complaint_alias,
                              NULL,
                              pk_translation.get_translation(i_lang, c.code_complaint),
                              pk_translation.get_translation(i_lang, ca.code_complaint_alias) || ' ' || k_label) desc_complaint,
                       ec.id_complaint_alias,
                       CASE
                            WHEN ec.id_complaint_alias IS NOT NULL THEN
                             c.id_complaint || '|' || ec.id_complaint_alias
                            WHEN ec.id_complaint_alias IS NULL THEN
                             c.id_complaint || ''
                        END id
                  FROM epis_complaint ec
                  JOIN complaint c
                    ON ec.id_complaint = c.id_complaint
                  LEFT JOIN complaint_alias ca
                    ON ca.id_complaint_alias = ec.id_complaint_alias
                 WHERE (ec.id_epis_complaint = i_id_epis_complaint OR ec.id_epis_complaint_root = i_id_epis_complaint)
                   AND ec.flg_status = g_complaint_act;
        
            SELECT ec.patient_complaint, ec.patient_complaint_arabic, ec.flg_reported_by
              INTO o_patient_complaint, o_patient_complaint_arabic, o_flg_reported_by
              FROM epis_complaint ec
             WHERE ec.id_epis_complaint = i_id_epis_complaint;
        
        ELSE
            IF i_prof.software IN
               (pk_alert_constant.g_soft_edis, pk_alert_constant.g_soft_triage, pk_alert_constant.g_soft_ubu)
            THEN
                BEGIN
                    SELECT adw_last_update_tstz
                      INTO l_dt_complaint
                      FROM (SELECT ec.adw_last_update_tstz, rank() over(ORDER BY ec.adw_last_update_tstz DESC) AS rn
                              FROM epis_complaint ec
                             WHERE ec.id_episode = i_episode
                               AND ec.flg_status IN (pk_alert_constant.g_active)
                               AND ec.id_epis_complaint_root IS NULL)
                     WHERE rn = 1;
                EXCEPTION
                    WHEN OTHERS THEN
                        NULL;
                END;
                BEGIN
                    SELECT dt_end_tstz
                      INTO l_dt_triage
                      FROM (SELECT et.dt_end_tstz, rank() over(ORDER BY et.dt_end_tstz DESC) AS rn
                              FROM epis_triage et
                             WHERE et.id_episode = id_episode)
                     WHERE rn = 1;
                EXCEPTION
                    WHEN OTHERS THEN
                        NULL;
                END;
                IF l_dt_complaint < l_dt_triage
                   OR l_dt_complaint IS NULL
                THEN
                
                    OPEN o_complaint_list FOR
                        SELECT c.id_complaint,
                               pk_translation.get_translation(i_lang, c.code_complaint) desc_complaint,
                               NULL id_complaint_alias,
                               c.id_complaint id
                          FROM complaint_triage_board ctb
                          JOIN complaint c
                            ON ctb.id_complaint = c.id_complaint
                          JOIN triage t
                            ON ctb.id_triage_board = t.id_triage_board
                          JOIN epis_info ei
                            ON ei.id_triage = t.id_triage
                          JOIN complaint_inst_soft cis
                            ON c.id_complaint = cis.id_complaint
                         WHERE ei.id_episode = i_episode
                           AND c.flg_available = pk_alert_constant.g_yes
                           AND ctb.flg_available = pk_alert_constant.g_yes
                           AND cis.flg_available = 'Y'
                           AND cis.id_institution = i_prof.institution
                           AND cis.id_software = i_prof.software
                           AND cis.id_complaint_alias IS NULL;
                ELSE
                    pk_types.open_my_cursor(o_complaint_list);
                END IF;
            ELSE
                pk_types.open_my_cursor(o_complaint_list);
            END IF;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              k_package_owner,
                                              g_package_name,
                                              k_func_name,
                                              o_error);
            pk_types.open_my_cursor(o_complaint_list);
            RETURN FALSE;
    END get_epis_complaint;

    --função para devolver o texto a colocar como assinatura da alteração
    FUNCTION get_prof_signature
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_prof_sign IN epis_hhc_req_det_h.id_prof_creation%TYPE,
        i_date         IN epis_hhc_req_det_h.dt_creation%TYPE
    ) RETURN VARCHAR2 IS
        l_signature VARCHAR2(200);
    BEGIN
    
        l_signature := pk_prof_utils.get_detail_signature(i_lang                => i_lang,
                                                          i_prof                => i_prof,
                                                          i_id_episode          => NULL,
                                                          i_date_last_change    => NULL,
                                                          i_id_prof_last_change => i_id_prof_sign) || '; ' ||
                       pk_date_utils.date_char_tsz(i_lang, i_date, i_prof.institution, i_prof.software);
    
        RETURN l_signature;
    
    END get_prof_signature;

    FUNCTION get_multi_complaint_desc
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_epis_complaint IN epis_complaint.id_epis_complaint_root%TYPE,
        i_sep               IN VARCHAR2 DEFAULT ', '
    ) RETURN VARCHAR2 IS
        l_complaints VARCHAR2(4000);
        l_sep        VARCHAR2(0010 CHAR) := i_sep || chr(32);
    BEGIN
    
        IF i_id_epis_complaint IS NOT NULL
        THEN
        
            SELECT listagg(t.complaint_desc, l_sep) within GROUP(ORDER BY t.complaint_desc) complaint_list
              INTO l_complaints
              FROM (SELECT pk_complaint.get_complaint_description(i_lang,
                                                                  i_prof,
                                                                  ec.id_complaint,
                                                                  c.code_complaint,
                                                                  ec.id_complaint_alias,
                                                                  ca.code_complaint_alias) complaint_desc
                      FROM epis_complaint ec
                      JOIN complaint c
                        ON ec.id_complaint = c.id_complaint
                      LEFT JOIN complaint_alias ca
                        ON ca.id_complaint_alias = ec.id_complaint_alias
                     WHERE ec.id_epis_complaint_root = i_id_epis_complaint
                        OR ec.id_epis_complaint = i_id_epis_complaint) t;
        
        END IF;
    
        RETURN l_complaints;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_multi_complaint_desc;

    FUNCTION get_epis_complaint_detail
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_detail     OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_function_name CONSTANT VARCHAR2(30 CHAR) := 'GET_COMPLAINT_DETAIL';
        tb_ids            table_number;
        tb_level          table_number;
        tb_source         table_varchar;
        l_cancel_reason   sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                                  i_prof      => i_prof,
                                                                                  i_code_mess => 'COMMON_M072');
        l_cancel_notes    sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                                  i_prof      => i_prof,
                                                                                  i_code_mess => 'COMMON_M073');
        l_chief_complaint sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                                  i_prof      => i_prof,
                                                                                  i_code_mess => 'COMPLAINT_T004');
        l_documented      sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                                  i_prof      => i_prof,
                                                                                  i_code_mess => 'EDIS_CHIEF_COMPLAINT_T008');
        l_updated         sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                                  i_prof      => i_prof,
                                                                                  i_code_mess => 'EDIS_CHIEF_COMPLAINT_T009');
    
        CURSOR c_history_compl(l_id_epis_complaint epis_complaint.id_epis_complaint%TYPE) IS
            SELECT ec.id_epis_complaint,
                   ec.flg_status,
                   (SELECT pk_sysdomain.get_domain('EPIS_COMPLAINT.FLG_REPORTED_BY', ec.flg_reported_by, i_lang)
                      FROM dual) reported_by,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, ec.id_professional) create_user_desc,
                   ec.adw_last_update_tstz dt_last,
                   (SELECT pk_complaint.get_multi_complaint_desc(i_lang, i_prof, ec.id_epis_complaint)
                      FROM dual) scoupe_desc,
                   ec.patient_complaint complaint_desc,
                   ec.patient_complaint_arabic complaint_desc_arabic,
                   ec.id_professional
              FROM epis_complaint ec
              LEFT JOIN complaint c
                ON ec.id_complaint = c.id_complaint
             WHERE ec.id_epis_complaint = l_id_epis_complaint;
    
        CURSOR c_history_anamn(l_id_epis_anamnesis epis_anamnesis.id_epis_anamnesis%TYPE) IS
            SELECT ea.id_epis_anamnesis,
                   ea.flg_status,
                   pk_sysdomain.get_domain(i_code_dom => g_complaint_status_domain,
                                           i_val      => ea.flg_status,
                                           i_lang     => i_lang) status_desc,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, ea.id_professional) create_user_desc,
                   ea.dt_epis_anamnesis_tstz dt_last,
                   pk_date_utils.date_char_tsz(i_lang => i_lang,
                                               i_date => ea.dt_epis_anamnesis_tstz,
                                               i_inst => i_prof.institution,
                                               i_soft => i_prof.software) create_time_ux,
                   ea.desc_epis_anamnesis anamnesis_desc,
                   CASE
                        WHEN ea.id_cancel_info_det IS NULL THEN
                         NULL
                        ELSE
                         pk_paramedical_prof_core.get_notes_desc(i_lang, i_prof, ea.id_cancel_info_det)
                    END notes_cancel,
                   CASE
                        WHEN ea.id_cancel_info_det IS NULL THEN
                         NULL
                        ELSE
                         pk_paramedical_prof_core.get_cancel_reason_desc(i_lang, i_prof, ea.id_cancel_info_det)
                    END cancel_reason_desc,
                   ea.id_professional
              FROM epis_anamnesis ea
             WHERE ea.id_epis_anamnesis = l_id_epis_anamnesis;
    
        l_tab_dd_data        t_tab_dd_data := t_tab_dd_data();
        k_title_complaint    sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'COMPLAINT_T006');
        k_complaint_reported sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'COMPLAINT_T002');
        k_complaint_en       sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'COMPLAINT_T003');
        k_complaint_arabic   sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'COMPLAINT_T005');
        l_signature          VARCHAR2(200 CHAR);
    BEGIN
        g_error := 'GET complaint leafs';
        BEGIN
            SELECT aux.ids, aux.l_level, aux.l_source
              BULK COLLECT
              INTO tb_ids, tb_level, tb_source
              FROM (SELECT ec.id_epis_complaint ids,
                           CASE
                                WHEN ec.id_epis_complaint_parent IS NULL THEN
                                 1
                                ELSE
                                 0
                            END l_level,
                           ec.adw_last_update_tstz dt_reg,
                           g_epis_complaint l_source
                      FROM epis_complaint ec
                     WHERE ec.id_episode = i_id_episode
                       AND ec.flg_status IN (pk_alert_constant.g_active)
                       AND ec.id_epis_complaint_root IS NULL
                    UNION ALL
                    SELECT ea.id_epis_anamnesis ids,
                           CASE
                               WHEN ea.id_epis_anamnesis_parent IS NULL THEN
                                1
                               ELSE
                                0
                           END l_level,
                           ea.dt_epis_anamnesis_tstz dt_reg,
                           g_epis_anamnesis l_source
                      FROM epis_anamnesis ea
                     WHERE ea.id_episode = i_id_episode
                       AND ea.flg_status IN (pk_alert_constant.g_active)) aux
             ORDER BY aux.dt_reg DESC;
        EXCEPTION
            WHEN no_data_found THEN
                tb_ids    := table_number();
                tb_level  := table_number();
                tb_source := table_varchar();
        END;
    
        FOR i IN 1 .. tb_ids.count
        LOOP
            IF tb_source(i) = g_epis_complaint
            THEN
                g_error := 'LOOP EPIS_COMPLAINT RECORDS';
                FOR r_history IN c_history_compl(tb_ids(i))
                LOOP
                    l_tab_dd_data.extend;
                    l_tab_dd_data(l_tab_dd_data.last) := t_rec_dd_data(k_title_complaint,
                                                                       '',
                                                                       pk_alert_constant.g_flg_screen_l1,
                                                                       pk_alert_constant.g_no,
                                                                       NULL,
                                                                       pk_alert_constant.g_no);
                
                    IF r_history.reported_by IS NOT NULL
                    THEN
                        l_tab_dd_data.extend;
                        l_tab_dd_data(l_tab_dd_data.last) := t_rec_dd_data(k_complaint_reported,
                                                                           r_history.reported_by,
                                                                           pk_alert_constant.g_flg_screen_l2,
                                                                           pk_alert_constant.g_no,
                                                                           NULL,
                                                                           pk_alert_constant.g_no);
                    END IF;
                    IF r_history.complaint_desc IS NOT NULL
                    THEN
                        l_tab_dd_data.extend;
                        l_tab_dd_data(l_tab_dd_data.last) := t_rec_dd_data(k_complaint_en,
                                                                           r_history.complaint_desc,
                                                                           pk_alert_constant.g_flg_screen_l2,
                                                                           pk_alert_constant.g_no,
                                                                           NULL,
                                                                           pk_alert_constant.g_no);
                    END IF;
                    IF r_history.complaint_desc_arabic IS NOT NULL
                    THEN
                        l_tab_dd_data.extend;
                        l_tab_dd_data(l_tab_dd_data.last) := t_rec_dd_data(k_complaint_arabic,
                                                                           r_history.complaint_desc_arabic,
                                                                           pk_alert_constant.g_flg_screen_l2,
                                                                           pk_alert_constant.g_no,
                                                                           NULL,
                                                                           pk_alert_constant.g_no);
                    END IF;
                    l_tab_dd_data.extend;
                    l_tab_dd_data(l_tab_dd_data.last) := t_rec_dd_data(l_chief_complaint,
                                                                       r_history.scoupe_desc,
                                                                       pk_alert_constant.g_flg_screen_l2,
                                                                       pk_alert_constant.g_no,
                                                                       NULL,
                                                                       pk_alert_constant.g_no);
                
                    --  scoupe_desc
                    l_signature := get_prof_signature(i_lang, i_prof, r_history.id_professional, r_history.dt_last);
                    l_tab_dd_data.extend;
                    l_tab_dd_data(l_tab_dd_data.last()) := t_rec_dd_data(pk_message.get_message(i_lang, 'COMMON_M107'),
                                                                         l_signature,
                                                                         pk_alert_constant.g_flg_screen_lp,
                                                                         pk_alert_constant.g_no,
                                                                         NULL,
                                                                         pk_alert_constant.g_no);
                
                    l_tab_dd_data.extend;
                    l_tab_dd_data(l_tab_dd_data.last()) := t_rec_dd_data(NULL,
                                                                         NULL,
                                                                         pk_alert_constant.g_flg_screen_wl,
                                                                         pk_alert_constant.g_no,
                                                                         NULL,
                                                                         pk_alert_constant.g_no);
                
                    l_tab_dd_data.extend;
                    l_tab_dd_data(l_tab_dd_data.last()) := t_rec_dd_data(NULL,
                                                                         NULL,
                                                                         pk_alert_constant.g_flg_screen_wl,
                                                                         pk_alert_constant.g_no,
                                                                         NULL,
                                                                         pk_alert_constant.g_no);
                END LOOP;
            
            ELSE
                g_error := 'LOOP EPIS_ANAMNESIS RECORDS   ';
                FOR r_history IN c_history_anamn(tb_ids(i))
                LOOP
                    g_error := 'Create a new line in history table with current history record ';
                    l_tab_dd_data.extend;
                    l_tab_dd_data(l_tab_dd_data.last) := t_rec_dd_data(k_title_complaint,
                                                                       '',
                                                                       pk_alert_constant.g_flg_screen_l1,
                                                                       pk_alert_constant.g_no,
                                                                       NULL,
                                                                       pk_alert_constant.g_no);
                
                    l_tab_dd_data.extend;
                
                    l_tab_dd_data(l_tab_dd_data.last) := t_rec_dd_data(k_complaint_en,
                                                                       r_history.anamnesis_desc,
                                                                       pk_alert_constant.g_flg_screen_l2,
                                                                       pk_alert_constant.g_no,
                                                                       NULL,
                                                                       pk_alert_constant.g_no);
                
                    --  scoupe_desc
                    l_signature := get_prof_signature(i_lang, i_prof, r_history.id_professional, r_history.dt_last);
                    l_tab_dd_data.extend;
                    l_tab_dd_data(l_tab_dd_data.last()) := t_rec_dd_data(pk_message.get_message(i_lang, 'COMMON_M107'),
                                                                         l_signature,
                                                                         pk_alert_constant.g_flg_screen_lp,
                                                                         pk_alert_constant.g_no,
                                                                         NULL,
                                                                         pk_alert_constant.g_no);
                    l_tab_dd_data.extend;
                    l_tab_dd_data(l_tab_dd_data.last()) := t_rec_dd_data(NULL,
                                                                         NULL,
                                                                         pk_alert_constant.g_flg_screen_wl,
                                                                         pk_alert_constant.g_no,
                                                                         NULL,
                                                                         pk_alert_constant.g_no);
                
                END LOOP;
            END IF;
        
        END LOOP;
    
        g_error := 'OPEN o_detail';
    
        OPEN o_detail FOR
            SELECT t.descr, t.val, t.flg_type, flg_html, val_clob, flg_clob
              FROM TABLE(l_tab_dd_data) t;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => g_package_name,
                                              i_function => l_function_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_detail);
            RETURN FALSE;
    END get_epis_complaint_detail;

    FUNCTION get_complaint_description
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_complaint          IN complaint.id_complaint%TYPE,
        code_complaint       IN complaint.code_complaint%TYPE,
        i_complaint_alias    IN complaint_alias.id_complaint_alias%TYPE,
        code_complaint_alias IN complaint_alias.code_complaint_alias%TYPE
    ) RETURN VARCHAR2 IS
        k_comp_show_alias       sys_config.value%TYPE := pk_sysconfig.get_config('COMPLAINT_SYNONYM_TAG', i_prof);
        l_complaint_description pk_translation.t_desc_translation;
    BEGIN
        IF i_complaint_alias IS NOT NULL
        THEN
            l_complaint_description := pk_translation.get_translation(i_lang      => i_lang,
                                                                      i_code_mess => code_complaint_alias);
            IF k_comp_show_alias = pk_alert_constant.g_yes
            THEN
                l_complaint_description := l_complaint_description || ' ' ||
                                           pk_message.get_message(i_lang, i_prof, 'COMMON_T014');
            END IF;
        ELSE
            l_complaint_description := pk_translation.get_translation(i_lang => i_lang, i_code_mess => code_complaint);
        END IF;
        RETURN l_complaint_description;
    
    END get_complaint_description;

    FUNCTION get_complaint_search
    (
        i_lang   IN language.id_language%TYPE,
        i_search IN VARCHAR2
    ) RETURN table_t_search IS
        -- table_varchar2 IS
        l_code       table_varchar2;
        l_code_compl table_varchar2;
        l_out_rec     table_t_search := table_t_search(NULL);
        l_out_rec_aux table_t_search := table_t_search(NULL);
    BEGIN
        SELECT t_search(a.code_translation, desc_translation, position, relevance)
          BULK COLLECT
          INTO l_out_rec_aux
          FROM TABLE(pk_translation.get_search_translation(i_lang, i_search, g_complaint_search_term)) a;
    
        SELECT t_search(code_translation => a.code,
                        desc_translation => a.description,
                        position         => a.position,
                        relevance        => a.relevance)
        
          BULK COLLECT
          INTO l_out_rec
          FROM (SELECT code,
                       description,
                       position,
                       relevance,
                       row_number() over(PARTITION BY code ORDER BY position DESC NULLS LAST) rn
                  FROM (SELECT c.code_complaint code, NULL description, NULL position, NULL relevance
                  FROM complaint c
                  JOIN complaint_alias ca
                    ON c.id_complaint = ca.id_complaint
                 WHERE ca.code_complaint_alias IN (SELECT /*+OPT_ESTIMATE (table t rows=1)*/
                                                            code_translation
                                                             FROM TABLE(l_out_rec_aux) t)
                UNION
                        SELECT ca.code_complaint_alias code, NULL description, NULL position, NULL relevance
                  FROM complaint c
                  JOIN complaint_alias ca
                    ON c.id_complaint = ca.id_complaint
                 WHERE c.code_complaint IN (SELECT /*+OPT_ESTIMATE (table t rows=1)*/
                                                     code_translation
                                                      FROM TABLE(l_out_rec_aux) t)
                UNION
                SELECT /*+OPT_ESTIMATE (table t rows=1)*/
                         code_translation, desc_translation, position, relevance
                          FROM TABLE(l_out_rec_aux) t) tf) a
         WHERE rn = 1;
        RETURN l_out_rec;
    END get_complaint_search;

    FUNCTION tf_epis_complaint_hist
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_epis_complaint IN epis_complaint.id_epis_complaint%TYPE
        
    ) RETURN t_tbl_complaints_hist AS
        l_ret t_tbl_complaints_hist := t_tbl_complaints_hist();
    
        l_cancellation sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                               i_prof      => i_prof,
                                                                               i_code_mess => 'COMMON_T032');
        l_creation     sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                               i_prof      => i_prof,
                                                                               i_code_mess => 'COMMON_T030');
        l_edition      sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                               i_prof      => i_prof,
                                                                               i_code_mess => 'COMMON_T029');
    
    BEGIN
    
        SELECT t_complaints_hist(id_epis_complaint => id_epis_complaint,
                                  action            => CASE
                                                           WHEN rn = cnt THEN
                                                            l_creation
                                                           WHEN rn <> cnt
                                                               
                                                                AND flg_status <> 'C' THEN
                                                            l_edition
                                                           WHEN flg_status = 'C' THEN
                                                            l_cancellation
                                                           ELSE
                                                            NULL
                                                       END,
                                  reported_by       => decode(cnt,
                                                              rn,
                                                              decode(reported_by, NULL, NULL, reported_by),
                                                              decode(reported_by,
                                                                     reported_by_prev,
                                                                     NULL,
                                                                     decode(reported_by, NULL, NULL, reported_by_prev))),
                                  reported_by_new   => decode(reported_by,
                                                              reported_by_prev,
                                                              NULL,
                                                              NULL,
                                                              'DEL',
                                                              reported_by),
                                  
                                  patient_complaint            => decode(cnt,
                                                                         rn,
                                                                         decode(patient_complaint,
                                                                                NULL,
                                                                                NULL,
                                                                                patient_complaint),
                                                                         decode(patient_complaint,
                                                                                patient_complaint_prev,
                                                                                NULL,
                                                                                decode(patient_complaint,
                                                                                       NULL,
                                                                                       NULL,
                                                                                       patient_complaint_prev))),
                                  patient_complaint_new        => decode(patient_complaint,
                                                                         patient_complaint_prev,
                                                                         NULL,
                                                                         NULL,
                                                                         'DEL',
                                                                         patient_complaint),
                                  patient_complaint_arabic     => decode(cnt,
                                                                         rn,
                                                                         decode(patient_complaint_arabic,
                                                                                NULL,
                                                                                NULL,
                                                                                patient_complaint_arabic),
                                                                         decode(patient_complaint_arabic,
                                                                                patient_complaint_arabic_prev,
                                                                                NULL,
                                                                                decode(patient_complaint_arabic,
                                                                                       NULL,
                                                                                       NULL,
                                                                                       patient_complaint_arabic_prev))),
                                  patient_complaint_arabic_new => decode(patient_complaint_arabic,
                                                                         patient_complaint_arabic_prev,
                                                                         NULL,
                                                                         NULL,
                                                                         'DEL',
                                                                         patient_complaint_arabic),
                                  complaint                    => decode(cnt,
                                                                         rn,
                                                                         decode(complaint, NULL, NULL, complaint),
                                                                         decode(complaint,
                                                                                complaint_prev,
                                                                                NULL,
                                                                                decode(complaint, NULL, NULL, complaint_prev))),
                                  complaint_new                => decode(complaint,
                                                                         complaint_prev,
                                                                         NULL,
                                                                         NULL,
                                                                         'DEL',
                                                                         complaint),
                                  status                       => flg_status,
                                  cancel_reason_new            => cancel_reason,
                                  cancel_notes_new             => cancel_notes,
                                  registry                     => registry,
                                  white_line                   => NULL)
          BULK COLLECT
          INTO l_ret
          FROM (SELECT id_epis_complaint,
                       row_number() over(ORDER BY adw_last_update_tstz DESC) rn,
                       MAX(rownum) over() cnt,
                       (SELECT pk_sysdomain.get_domain('EPIS_COMPLAINT.FLG_REPORTED_BY', flg_reported_by, i_lang)
                          FROM dual) reported_by,
                       (SELECT pk_sysdomain.get_domain('EPIS_COMPLAINT.FLG_REPORTED_BY', flg_reported_by_prev, i_lang)
                          FROM dual) reported_by_prev,
                       (SELECT pk_complaint.get_multi_complaint_desc(i_lang, i_prof, id_epis_complaint)
                          FROM dual) complaint,
                       (SELECT pk_complaint.get_multi_complaint_desc(i_lang, i_prof, id_epis_complaint_prev)
                          FROM dual) complaint_prev,
                       patient_complaint,
                       patient_complaint_prev,
                       patient_complaint_arabic,
                       patient_complaint_arabic_prev,
                       flg_status flg_status_prev,
                       flg_status,
                       decode(id_cancel_info_det,
                              NULL,
                              NULL,
                              pk_paramedical_prof_core.get_notes_desc(i_lang, i_prof, id_cancel_info_det)) cancel_notes,
                       decode(id_cancel_info_det,
                              NULL,
                              NULL,
                              pk_paramedical_prof_core.get_cancel_reason_desc(i_lang, i_prof, id_cancel_info_det)) cancel_reason,
                       registry
                  FROM (SELECT ec.id_epis_complaint,
                               
                               ec.flg_reported_by,
                               first_value(flg_reported_by) over(ORDER BY ec.adw_last_update_tstz rows BETWEEN 1 preceding AND CURRENT ROW) flg_reported_by_prev,
                               first_value(ec.id_epis_complaint) over(ORDER BY ec.adw_last_update_tstz rows BETWEEN 1 preceding AND CURRENT ROW) id_epis_complaint_prev,
                               ec.patient_complaint patient_complaint,
                               first_value(ec.patient_complaint) over(ORDER BY ec.adw_last_update_tstz rows BETWEEN 1 preceding AND CURRENT ROW) patient_complaint_prev,
                               ec.patient_complaint_arabic patient_complaint_arabic,
                               first_value(ec.patient_complaint_arabic) over(ORDER BY ec.adw_last_update_tstz rows BETWEEN 1 preceding AND CURRENT ROW) patient_complaint_arabic_prev,
                               ec.id_professional,
                               ec.flg_status,
                               first_value(ec.flg_status) over(ORDER BY ec.adw_last_update_tstz rows BETWEEN 1 preceding AND CURRENT ROW) flg_status_prev,
                               ec.flg_status flg_status_current,
                               pk_complaint.get_prof_signature(i_lang,
                                                               i_prof,
                                                               ec.id_professional,
                                                               ec.adw_last_update_tstz) registry,
                               adw_last_update_tstz,
                               ec.id_cancel_info_det
                          FROM epis_complaint ec
                        CONNECT BY PRIOR ec.id_epis_complaint_parent = ec.id_epis_complaint
                         START WITH ec.id_epis_complaint = i_id_epis_complaint));
    
        RETURN l_ret;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN t_tbl_complaints_hist();
    END tf_epis_complaint_hist;

    FUNCTION tf_epis_anamnesis_hist
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_epis_anamnesis IN epis_anamnesis.id_epis_anamnesis%TYPE
        
    ) RETURN t_tbl_complaints_hist AS
        l_ret t_tbl_complaints_hist := t_tbl_complaints_hist();
    
        l_cancellation sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                               i_prof      => i_prof,
                                                                               i_code_mess => 'COMMON_T032');
        l_creation     sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                               i_prof      => i_prof,
                                                                               i_code_mess => 'COMMON_T030');
        l_edition      sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                               i_prof      => i_prof,
                                                                               i_code_mess => 'COMMON_T029');
    
    BEGIN
    
        SELECT t_complaints_hist(id_epis_complaint => id_epis_anamnesis,
                                  action            => CASE
                                                           WHEN rn = cnt THEN
                                                            l_creation
                                                           WHEN rn <> cnt
                                                                AND flg_status <> 'C' THEN
                                                            l_edition
                                                           WHEN flg_status = 'C' THEN
                                                            l_cancellation
                                                           ELSE
                                                            NULL
                                                       END,
                                  reported_by       => NULL,
                                  reported_by_new   => NULL,
                                  
                                  patient_complaint            => decode(cnt,
                                                                         rn,
                                                                         decode(patient_complaint,
                                                                                NULL,
                                                                                NULL,
                                                                                patient_complaint),
                                                                         decode(patient_complaint,
                                                                                patient_complaint_prev,
                                                                                NULL,
                                                                                decode(patient_complaint,
                                                                                       NULL,
                                                                                       NULL,
                                                                                       patient_complaint_prev))),
                                  patient_complaint_new        => decode(patient_complaint,
                                                                         patient_complaint_prev,
                                                                         NULL,
                                                                         NULL,
                                                                         'DEL',
                                                                         patient_complaint),
                                  patient_complaint_arabic     => NULL,
                                  patient_complaint_arabic_new => NULL,
                                  complaint                    => NULL,
                                  complaint_new                => NULL,
                                  status                       => flg_status,
                                  cancel_reason_new            => NULL,
                                  cancel_notes_new             => NULL,
                                  
                                  registry   => registry,
                                  white_line => NULL)
          BULK COLLECT
          INTO l_ret
          FROM (SELECT id_epis_anamnesis,
                       row_number() over(ORDER BY dt_epis_anamnesis_tstz DESC) rn,
                       MAX(rownum) over() cnt,
                       patient_complaint,
                       patient_complaint_prev,
                       flg_status flg_status_prev,
                       flg_status,
                       registry
                  FROM (SELECT ec.id_epis_anamnesis,
                               -- ec.flg_reported_by,
                               to_char(ec.desc_epis_anamnesis) patient_complaint,
                               first_value(to_char(desc_epis_anamnesis)) over(ORDER BY ec.dt_epis_anamnesis_tstz rows BETWEEN 1 preceding AND CURRENT ROW) patient_complaint_prev,
                               ec.id_professional,
                               ec.flg_status,
                               first_value(ec.flg_status) over(ORDER BY ec.dt_epis_anamnesis_tstz rows BETWEEN 1 preceding AND CURRENT ROW) flg_status_prev,
                               ec.flg_status flg_status_current,
                               pk_complaint.get_prof_signature(i_lang,
                                                               i_prof,
                                                               ec.id_professional,
                                                               ec.dt_epis_anamnesis_tstz) registry,
                               ec.dt_epis_anamnesis_tstz,
                               ec.id_cancel_info_det
                          FROM epis_anamnesis ec
                        CONNECT BY PRIOR ec.id_epis_anamnesis_parent = ec.id_epis_anamnesis
                         START WITH ec.id_epis_anamnesis = i_id_epis_anamnesis));
    
        RETURN l_ret;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN t_tbl_complaints_hist();
    END tf_epis_anamnesis_hist;

    FUNCTION get_epis_complaint_hist
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_detail     OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_function_name CONSTANT VARCHAR2(30 CHAR) := 'GET_COMPLAINT_HIST';
        tb_ids          table_number;
        tb_level        table_number;
        tb_source       table_varchar;
        l_cancel_reason sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                                i_prof      => i_prof,
                                                                                i_code_mess => 'COMMON_M072');
        l_cancel_notes  sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                                i_prof      => i_prof,
                                                                                i_code_mess => 'COMMON_M073');
    
        l_signature                VARCHAR2(200 CHAR);
        l_tbl_complaint_hist       t_tbl_complaints_hist;
        l_tbl_complaint_hist_total t_tbl_complaints_hist := t_tbl_complaints_hist();
        l_tab_dd_block_data        t_tab_dd_block_data := t_tab_dd_block_data();
        l_tab_dd_data              t_tab_dd_data := t_tab_dd_data();
        l_data_source_list         table_varchar := table_varchar();
    
        l_cancellation sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                               i_prof      => i_prof,
                                                                               i_code_mess => 'COMMON_T032');
        l_creation     sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                               i_prof      => i_prof,
                                                                               i_code_mess => 'COMMON_T030');
        l_edition      sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                               i_prof      => i_prof,
                                                                               i_code_mess => 'COMMON_T029');
    
    BEGIN
        g_error := 'GET complaint leafs';
        BEGIN
            SELECT aux.ids, aux.l_level, aux.l_source
              BULK COLLECT
              INTO tb_ids, tb_level, tb_source
              FROM (SELECT ec.id_epis_complaint ids,
                           CASE
                                WHEN ec.id_epis_complaint_parent IS NULL THEN
                                 1
                                ELSE
                                 0
                            END l_level,
                           ec.adw_last_update_tstz dt_reg,
                           g_epis_complaint l_source
                      FROM epis_complaint ec
                     WHERE ec.id_episode = i_id_episode
                       AND ec.flg_status IN (pk_alert_constant.g_active, pk_alert_constant.g_cancelled)
                       AND ec.id_epis_complaint_root IS NULL
                    UNION ALL
                    SELECT ea.id_epis_anamnesis ids,
                           CASE
                               WHEN ea.id_epis_anamnesis_parent IS NULL THEN
                                1
                               ELSE
                                0
                           END l_level,
                           ea.dt_epis_anamnesis_tstz dt_reg,
                           g_epis_anamnesis l_source
                      FROM epis_anamnesis ea
                     WHERE ea.id_episode = i_id_episode
                       AND ea.flg_status IN (pk_alert_constant.g_active, pk_alert_constant.g_cancelled)) aux
             ORDER BY aux.dt_reg DESC;
        EXCEPTION
            WHEN no_data_found THEN
                tb_ids    := table_number();
                tb_level  := table_number();
                tb_source := table_varchar();
        END;
    
        FOR i IN 1 .. tb_ids.count
        LOOP
            IF tb_source(i) = g_epis_complaint
            THEN
                g_error                    := 'LOOP EPIS_COMPLAINT RECORDS';
                l_tbl_complaint_hist       := tf_epis_complaint_hist(i_lang              => i_lang,
                                                                     i_prof              => i_prof,
                                                                     i_id_epis_complaint => tb_ids(i));
                l_tbl_complaint_hist_total := l_tbl_complaint_hist_total MULTISET UNION l_tbl_complaint_hist;
            ELSE
                g_error                    := 'LOOP EPIS_ANAMNESIS RECORDS   ';
                l_tbl_complaint_hist       := tf_epis_anamnesis_hist(i_lang              => i_lang,
                                                                     i_prof              => i_prof,
                                                                     i_id_epis_anamnesis => tb_ids(i));
                l_tbl_complaint_hist_total := l_tbl_complaint_hist_total MULTISET UNION l_tbl_complaint_hist;
            
            END IF;
        
        END LOOP;
    
        SELECT t_rec_dd_block_data(ddb.id_dd_block,
                                   (ddb.rank) * rn,
                                   NULL,
                                   NULL,
                                   ddb.condition_val,
                                   NULL,
                                   status,
                                   dd.data_source,
                                   dd.data_source_val,
                                   NULL)
          BULK COLLECT
          INTO l_tab_dd_block_data
          FROM (SELECT id_epis_complaint,
                       status,
                       data_source,
                       data_source_val,
                       row_number() over(PARTITION BY data_source ORDER BY rownum) AS rn
                  FROM (SELECT *
                          FROM (SELECT t.id_epis_complaint,
                                       t.status,
                                       t.action,
                                       t.reported_by,
                                       t.reported_by_new,
                                       t.patient_complaint,
                                       t.patient_complaint_new,
                                       t.patient_complaint_arabic,
                                       t.patient_complaint_arabic_new,
                                       t.complaint,
                                       t.complaint_new,
                                       t.cancel_reason_new,
                                       t.cancel_notes_new,
                                       t.registry,
                                       t.white_line
                                  FROM TABLE(l_tbl_complaint_hist_total) t) unpivot include NULLS(data_source_val FOR data_source IN(action,
                                                                                                                                     reported_by,
                                                                                                                                     reported_by_new,
                                                                                                                                     patient_complaint,
                                                                                                                                     patient_complaint_new,
                                                                                                                                     patient_complaint_arabic,
                                                                                                                                     patient_complaint_arabic_new,
                                                                                                                                     complaint,
                                                                                                                                     complaint_new,
                                                                                                                                     cancel_reason_new,
                                                                                                                                     cancel_notes_new,
                                                                                                                                     registry,
                                                                                                                                     white_line)))) dd
          JOIN dd_block ddb
            ON ddb.area = 'COMPLAINTS'
           AND ddb.internal_name = 'CREATE'
           AND ddb.flg_available = pk_alert_constant.g_yes
         ORDER BY rn, ddb.rank;
    
        g_error := 'OPEN o_detail';
        SELECT t_rec_dd_data(CASE
                                  WHEN data_code_message IS NOT NULL THEN
                                   CASE
                                       WHEN flg_type = 'L1' THEN
                                        data_source_val
                                       ELSE
                                        pk_message.get_message(i_lang => i_lang, i_prof => i_prof, i_code_mess => data_code_message)
                                   END
                                  ELSE
                                   NULL
                              END, --DESCR
                              CASE
                                  WHEN flg_type = 'L1' THEN
                                   NULL
                                  ELSE
                                   data_source_val
                              END, --VAL
                              flg_type,
                              pk_alert_constant.g_no,
                              NULL,
                              pk_alert_constant.g_no), --TYPE
               data_source
          BULK COLLECT
          INTO l_tab_dd_data, l_data_source_list
          FROM (SELECT ddc.data_code_message,
                       flg_type,
                       data_source_val,
                       ddc.data_source,
                       db.rnk,
                       ddc.rank,
                       db.id_dd_block,
                       0 AS rank_cq,
                       c_n
                  FROM TABLE(l_tab_dd_block_data) db
                  JOIN dd_content ddc
                    ON ddc.data_source = db.data_source
                   AND ddc.flg_available = pk_alert_constant.g_yes
                   AND ddc.area = 'COMPLAINTS'
                 WHERE ddc.id_dd_block = db.id_dd_block
                   AND (db.data_source_val IS NOT NULL OR flg_type IN ('L1', 'L2B', 'WL')))
         ORDER BY rnk, rank;
    
        OPEN o_detail FOR
            SELECT t.descr, t.val, t.flg_type, flg_html, val_clob, flg_clob
              FROM TABLE(l_tab_dd_data) t;
        /*        OPEN o_detail FOR        
           SELECT xx.descr, xx.val, xx.flg_type, xx.flg_html, xx.val_clob, xx.flg_clob, rn
             FROM (SELECT CASE
                               WHEN d.descr IS NULL THEN
                                NULL
                               ELSE
                                d.descr
                           END descr,
                          d.val,
                          d.flg_type,
                          flg_html,
                          val_clob,
                          flg_clob,
                          d.rn
                     FROM (SELECT rownum rn, descr, val, flg_type, flg_html, val_clob, flg_clob
                             FROM TABLE(l_tab_dd_data)) d
                     JOIN (SELECT rownum rn, column_value data_source
                            FROM TABLE(l_data_source_list)) ds
                       ON ds.rn = d.rn) xx            
        --    ORDER BY xx.rn
            ;     */
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => g_package_name,
                                              i_function => l_function_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_detail);
            RETURN FALSE;
    END get_epis_complaint_hist;

    FUNCTION get_complaint_desc_sp
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_epis_complaint IN epis_complaint.id_epis_complaint%TYPE
    ) RETURN CLOB IS
        l_complaint         CLOB;
        l_reported          epis_complaint.flg_reported_by%TYPE;
        l_patient_complaint epis_complaint.patient_complaint%TYPE;
        l_id_complaint      epis_complaint.id_complaint%TYPE;
        k_space CONSTANT VARCHAR2(1 CHAR) := ' ';
    BEGIN
        SELECT ec.flg_reported_by, ec.patient_complaint, ec.id_complaint
          INTO l_reported, l_patient_complaint, l_id_complaint
          FROM epis_complaint ec
         WHERE ec.id_epis_complaint = i_id_epis_complaint;
    
        IF l_reported IS NOT NULL
        THEN
        
            l_complaint := pk_message.get_message(i_lang => i_lang, i_prof => i_prof, i_code_mess => 'COMPLAINT_T002');
            l_complaint := l_complaint || k_space ||
                           pk_sysdomain.get_domain('EPIS_COMPLAINT.FLG_REPORTED_BY', l_reported, i_lang);
        
        END IF;
        IF l_patient_complaint IS NOT NULL
        THEN
            IF l_complaint IS NOT NULL
            THEN
                l_complaint := l_complaint || chr(13);
            END IF;
            l_complaint := l_complaint ||
                           pk_message.get_message(i_lang => i_lang, i_prof => i_prof, i_code_mess => 'COMPLAINT_T003');
            l_complaint := l_complaint || k_space || l_patient_complaint;
        
        END IF;
        IF l_complaint IS NOT NULL
        THEN
            l_complaint := l_complaint || chr(13);
        END IF;
        l_complaint := l_complaint ||
                       pk_message.get_message(i_lang => i_lang, i_prof => i_prof, i_code_mess => 'COMPLAINT_T004');
        l_complaint := l_complaint || k_space || get_multi_complaint_desc(i_lang, i_prof, i_id_epis_complaint);
        RETURN l_complaint;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_complaint_desc_sp;

    FUNCTION get_complaint_header
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        i_sep            IN VARCHAR2 DEFAULT ', ',
        o_last_complaint OUT VARCHAR2,
        o_complaints     OUT VARCHAR2,
        o_professional   OUT NUMBER,
        o_dt_register    OUT epis_complaint.adw_last_update_tstz%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id_complaints  table_number;
        l_epis_anamnesis VARCHAR2(2000);
        l_complaint      VARCHAR2(2000);
    BEGIN
    
        SELECT ec.id_epis_complaint
          BULK COLLECT
          INTO l_id_complaints
          FROM epis_complaint ec
         WHERE ec.id_episode = i_episode
           AND ec.flg_status IN (pk_alert_constant.g_active)
           AND ec.id_epis_complaint_root IS NULL
         ORDER BY ec.adw_last_update_tstz DESC;
    
        IF l_id_complaints.count > 0
        THEN
            SELECT patient_complaint, ec.id_professional, ec.adw_last_update_tstz
              INTO l_epis_anamnesis, o_professional, o_dt_register
              FROM epis_complaint ec
             WHERE ec.id_epis_complaint = l_id_complaints(1);
        
            l_complaint := get_multi_complaint_desc(i_lang              => i_lang,
                                                    i_prof              => i_prof,
                                                    i_id_epis_complaint => l_id_complaints(1),
                                                    i_sep               => i_sep);
        
            IF l_epis_anamnesis IS NOT NULL
            THEN
                o_last_complaint := l_epis_anamnesis;
                o_last_complaint := o_last_complaint || ' (' || l_complaint || ')';
            ELSE
                o_last_complaint := l_complaint;
                o_complaints     := l_complaint;
            END IF;
            SELECT listagg(t.complaint_desc, chr(10)) within GROUP(ORDER BY t.dt_complaint_tstz) complaint_list
              INTO o_complaints
              FROM (SELECT CASE
                                WHEN ec.patient_complaint IS NULL THEN
                                 get_multi_complaint_desc(i_lang              => i_lang,
                                                          i_prof              => i_prof,
                                                          i_id_epis_complaint => ec.id_epis_complaint,
                                                          i_sep               => i_sep)
                                ELSE
                                 ec.patient_complaint || ' (' ||
                                 get_multi_complaint_desc(i_lang              => i_lang,
                                                          i_prof              => i_prof,
                                                          i_id_epis_complaint => ec.id_epis_complaint,
                                                          i_sep               => i_sep) || ')'
                            END complaint_desc,
                           ec.adw_last_update_tstz dt_complaint_tstz
                      FROM epis_complaint ec
                      JOIN (SELECT column_value id_epis_complaint
                             FROM TABLE(l_id_complaints)) l
                        ON ec.id_epis_complaint = l.id_epis_complaint
                    UNION
                    SELECT pk_string_utils.clob_to_sqlvarchar2(ea.desc_epis_anamnesis) desc_anamnesis,
                           dt_epis_anamnesis_tstz
                      FROM epis_anamnesis ea
                     WHERE ea.id_episode = i_episode
                       AND ea.flg_status = g_active
                       AND ea.flg_type = 'C'
                       AND ea.flg_temp = 'D') t
             ORDER BY dt_complaint_tstz ASC;
        ELSE
        
            SELECT desc_anamnesis, id_professional, dt_epis_anamnesis_tstz
              INTO o_last_complaint, o_professional, o_dt_register
              FROM (SELECT pk_string_utils.clob_to_sqlvarchar2(ea.desc_epis_anamnesis) desc_anamnesis,
                           ea.id_professional,
                           dt_epis_anamnesis_tstz
                      FROM epis_anamnesis ea
                     WHERE ea.id_episode = i_episode
                       AND ea.flg_status = g_active
                       AND ea.flg_type = 'C'
                       AND ea.flg_temp = 'D'
                     ORDER BY ea.dt_epis_anamnesis_tstz DESC)
             WHERE rownum = 1;
        
            SELECT listagg(t.desc_anamnesis, chr(10)) within GROUP(ORDER BY t.dt_epis_anamnesis_tstz) complaint_list
              INTO o_complaints
              FROM (SELECT pk_string_utils.clob_to_sqlvarchar2(ea.desc_epis_anamnesis) desc_anamnesis,
                           dt_epis_anamnesis_tstz
                      FROM epis_anamnesis ea
                     WHERE ea.id_episode = i_episode
                       AND ea.flg_status = g_active
                       AND ea.flg_type = 'C'
                       AND ea.flg_temp = 'D') t
             ORDER BY dt_epis_anamnesis_tstz ASC;
        
            --   o_last_complaint := o_complaints;
        END IF;
        RETURN TRUE;
    EXCEPTION
    
        WHEN OTHERS THEN
            RETURN TRUE;
    END get_complaint_header;
BEGIN
    -- Log initialization.
    g_package_name := pk_alertlog.who_am_i;

    pk_alertlog.log_init(g_package_name);
    -- Message stack.
    g_msg_stack := table_varchar(NULL);

END pk_complaint;
/
