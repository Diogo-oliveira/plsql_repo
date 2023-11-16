/*-- Last Change Revision: $Rev: 2047816 $*/
/*-- Last Change by: $Author: ana.matos $*/
/*-- Date of last change: $Date: 2022-10-19 17:31:52 +0100 (qua, 19 out 2022) $*/
CREATE OR REPLACE PACKAGE BODY pk_api_ref_ws AS

    g_error         VARCHAR2(1000 CHAR);
    g_sysdate_tstz  TIMESTAMP(6) WITH LOCAL TIME ZONE;
    g_package_name  VARCHAR2(50 CHAR);
    g_package_owner VARCHAR2(50 CHAR);
    g_exception     EXCEPTION;
    g_exception_np  EXCEPTION;
    g_invalid_param EXCEPTION;
    g_retval        BOOLEAN;
    g_found         BOOLEAN;
    g_prof_int      profissional;

    -- error codes
    g_error_code ref_error.id_ref_error%TYPE;
    g_error_desc pk_translation.t_desc_translation;
    g_flg_action VARCHAR2(1 CHAR);

    PROCEDURE reset_vars IS
    BEGIN
    
        --g_sysdate_tstz := NULL;
    
        -- error codes
        g_error_code := NULL;
        g_error_desc := NULL;
        g_flg_action := NULL;
    
    EXCEPTION
        WHEN OTHERS THEN
            g_error := 'reset_vars';
            pk_alertlog.log_error(g_error);
    END reset_vars;

    /**
    * Returns operation date
    *
    * @param   i_lang                  Language associated to the professional executing the request
    * @param   i_prof                  Id professional, institution and software
    * @param   i_id_ref                Referral identifier
    *
    * @RETURN  referral dep_clin_serv identifier
    * @author  Ana Monteiro
    * @version 1.0
    * @since   26-10-2009
    */
    FUNCTION get_operation_date
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_dt_d    IN DATE,
        o_dt_tstz OUT TIMESTAMP WITH LOCAL TIME ZONE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_dt_date_v VARCHAR2(50 CHAR);
    BEGIN
        g_error := 'Init get_operation_date / DATE_D=' || i_dt_d;
    
        -- converting DATEs to VARCHARs
        --g_error     := 'Converting DATE to VARCHAR';
        l_dt_date_v := to_char(i_dt_d, pk_ref_constant.g_format_date_2);
    
        -- converting VARCHARs to TIMESTAMPS WITH LOCAL TIME ZONEs
        g_error   := 'Converting VARCHARs to TIMESTAMPS WITH LOCAL TIME ZONEs / DATE_V=' || l_dt_date_v;
        o_dt_tstz := pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                   i_prof      => i_prof,
                                                   i_timestamp => l_dt_date_v,
                                                   i_timezone  => NULL,
                                                   i_mask      => pk_ref_constant.g_format_date_2);
    
        o_dt_tstz := nvl(o_dt_tstz, pk_ref_utils.get_sysdate);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_OPERATION_DATE',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_operation_date;

    /**
    * Returns referral active appointment date
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Id professional, institution and software    
    * @param   i_id_ref         Referral identifier
    * @param   o_dt_schedule    Referral active appointment date 
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   02-10-2009
    */
    FUNCTION get_ref_schedule_date
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_ref      IN p1_external_request.id_external_request%TYPE,
        o_dt_schedule OUT schedule.dt_begin_tstz%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        -- getting active appointment date
        g_error       := 'Call pk_ref_module.get_ref_sch_generic / ID_REF=' || i_id_ref;
        o_dt_schedule := pk_ref_module.get_ref_sch_dt_generic(i_lang => i_lang, i_prof => i_prof, i_id_ref => i_id_ref);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_REF_SCHEDULE_DATE',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_ref_schedule_date;

    /**
    * Returns the professional to whom the referral is scheduled
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Id professional, institution and software    
    * @param   i_id_ref         Referral identifier
    * @param   o_id_prof        Scheduled professional identifier
    * @param   o_num_order      Scheduled professional num order
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   02-10-2009
    */
    FUNCTION get_ref_schedule_prof
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_ref    IN p1_external_request.id_external_request%TYPE,
        o_id_prof   OUT professional.id_professional%TYPE,
        o_num_order OUT professional.num_order%TYPE,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        SELECT spo.id_professional, p.num_order
          INTO o_id_prof, o_num_order
          FROM p1_external_request p1
          JOIN schedule s
            ON (s.id_schedule = p1.id_schedule AND s.flg_status != pk_ref_constant.g_cancelled)
          LEFT JOIN schedule_outp so
            ON (s.id_schedule = so.id_schedule)
          LEFT JOIN sch_prof_outp spo
            ON (so.id_schedule_outp = spo.id_schedule_outp)
          LEFT JOIN professional p
            ON (p.id_professional = spo.id_professional) -- return null if is null
         WHERE p1.id_external_request = i_id_ref;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_REF_SCHEDULE_PROF',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_ref_schedule_prof;

    /**
    * Returns the first id_doc_external of document id_doc_external (last id from table)
    *
    * @param   i_lang                  Language associated to the professional executing the request
    * @param   i_prof                  Id professional, institution and software
    * @param   i_id_doc                Active document identifier
    *
    * @RETURN  first doc_external identifier
    * @author  Ana Monteiro
    * @version 1.0
    * @since   20-10-2009
    */
    FUNCTION get_first_doc_external
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_id_doc IN doc_external.id_doc_external%TYPE
    ) RETURN doc_external.id_doc_external%TYPE IS
    
        l_id_doc doc_external.id_doc_external%TYPE;
    
        CURSOR c_doc_external IS
            SELECT id_doc_external
              FROM doc_external d
             WHERE d.id_grupo = (SELECT id_grupo
                                   FROM doc_external de
                                  WHERE de.id_doc_external = i_id_doc)
             ORDER BY d.dt_inserted ASC;
    BEGIN
        g_error := 'Init get_first_doc_external / ID_DOC=' || i_id_doc;
        OPEN c_doc_external;
        FETCH c_doc_external
            INTO l_id_doc;
        CLOSE c_doc_external;
    
        RETURN l_id_doc;
    
    EXCEPTION
        WHEN OTHERS THEN
            g_error := pk_message.get_message(i_lang      => i_lang,
                                              i_prof      => i_prof,
                                              i_code_mess => pk_ref_constant.g_sm_common_m001) || chr(10) ||
                       g_package_name || '.get_first_doc_external / ' || g_error || ' / ' || SQLERRM;
            pk_alertlog.log_warn(g_error);
            RETURN NULL;
    END get_first_doc_external;

    /**
    * Returns the last id_doc_external of document id_doc_external (first id from table)
    *
    * @param   i_lang                  Language associated to the professional executing the request
    * @param   i_prof                  Id professional, institution and software
    * @param   i_id_doc                First document identifier (outdated)
    *
    * @RETURN  last doc_external identifier
    * @author  Ana Monteiro
    * @version 1.0
    * @since   20-10-2009
    */
    FUNCTION get_last_doc_external
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_id_doc IN doc_external.id_doc_external%TYPE
    ) RETURN doc_external.id_doc_external%TYPE IS
    
        l_id_doc doc_external.id_doc_external%TYPE;
    
        CURSOR c_doc_external IS
            SELECT id_doc_external
              FROM doc_external d
             WHERE d.id_grupo = (SELECT id_grupo
                                   FROM doc_external de
                                  WHERE de.id_doc_external = i_id_doc)
               AND flg_status = pk_ref_constant.g_active
             ORDER BY d.dt_inserted DESC;
    BEGIN
        g_error := 'Init get_last_doc_external / ID_DOC=' || i_id_doc;
        OPEN c_doc_external;
        FETCH c_doc_external
            INTO l_id_doc;
        CLOSE c_doc_external;
    
        RETURN l_id_doc;
    
    EXCEPTION
        WHEN OTHERS THEN
            g_error := pk_message.get_message(i_lang      => i_lang,
                                              i_prof      => i_prof,
                                              i_code_mess => pk_ref_constant.g_sm_common_m001) || chr(10) ||
                       g_package_name || '.get_last_doc_external / ' || g_error || ' / ' || SQLERRM;
            pk_alertlog.log_warn(g_error);
            RETURN NULL;
    END get_last_doc_external;

    /**
    * Gets document information in order to update flg_received
    *
    * @param   i_lang                  Language associated to the professional executing the request
    * @param   i_prof                  Id professional, institution and software
    * @param   i_id_doc                Document identifier
    * @param   i_id_ref                Referral identifier
    * @param   o_doc_type              Document type
    * @param   o_desc_doc_type         Document type desc
    * @param   o_num_doc               Document number
    * @param   o_dt_emited             Document date
    * @param   o_dt_expire             Document expiration date
    * @param   o_orig_dest             
    * @param   o_desc_ori_dest              
    * @param   o_orig_type             Document type 
    * @param   o_desc_ori_doc_type              
    * @param   o_notes                 Document notes
    * @param   o_sent_by               Document sent by
    * @param   o_original              Document original type
    * @param   o_desc_original         Document original stays with
    * @param   o_title                 Document descriptive title
    * @param   o_prof_perf_by          Performed by  
    * @param   o_desc_perf_by                   
    * @param   o_error                 An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  João Almeida
    * @version 1.0
    * @since   07-10-2009
    */
    FUNCTION get_doc_upd_values
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_doc            IN doc_external.id_doc_external%TYPE,
        i_id_ref            IN doc_external.id_external_request%TYPE,
        o_doc_type          OUT doc_external.id_doc_type%TYPE,
        o_desc_doc_type     OUT doc_external.desc_doc_type%TYPE,
        o_num_doc           OUT doc_external.num_doc%TYPE,
        o_dt_emited         OUT doc_external.dt_emited%TYPE,
        o_dt_expire         OUT doc_external.dt_expire%TYPE,
        o_orig_dest         OUT doc_external.id_doc_destination%TYPE,
        o_desc_ori_dest     OUT doc_external.desc_doc_ori_type%TYPE,
        o_orig_type         OUT doc_external.id_doc_ori_type%TYPE,
        o_desc_ori_doc_type OUT doc_external.desc_doc_type%TYPE,
        o_notes             OUT doc_external.notes%TYPE,
        o_sent_by           OUT doc_external.flg_sent_by%TYPE,
        o_original          OUT doc_external.id_doc_original%TYPE,
        o_desc_original     OUT doc_external.desc_doc_original%TYPE,
        o_title             OUT doc_external.title%TYPE,
        o_prof_perf_by      OUT doc_external.id_prof_perf_by%TYPE,
        o_desc_perf_by      OUT doc_external.desc_perf_by%TYPE,
        o_error             OUT t_error_out
        
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_error := 'SELECT DOC_EXTERNAL / ID_EXT_REQ=' || i_id_ref || ' ID_DOC=' || i_id_doc;
        pk_alertlog.log_debug(g_error);
    
        SELECT de.id_doc_type,
               pk_translation.get_translation(1, dt.code_doc_type),
               de.num_doc,
               de.dt_emited,
               de.dt_expire,
               de.id_doc_destination,
               pk_translation.get_translation(1, dd.code_doc_destination),
               dot.id_doc_ori_type,
               pk_translation.get_translation(1, dot.code_doc_ori_type),
               de.notes,
               de.flg_sent_by,
               de.id_doc_original,
               pk_translation.get_translation(1, do.code_doc_original),
               de.title,
               de.id_prof_perf_by,
               de.desc_perf_by
          INTO o_doc_type,
               o_desc_doc_type,
               o_num_doc,
               o_dt_emited,
               o_dt_expire,
               o_orig_dest,
               o_desc_ori_dest,
               o_orig_type,
               o_desc_ori_doc_type,
               o_notes,
               o_sent_by,
               o_original,
               o_desc_original,
               o_title,
               o_prof_perf_by,
               o_desc_perf_by
          FROM doc_external de
          JOIN doc_type dt
            ON (dt.id_doc_type = de.id_doc_type)
          JOIN doc_ori_type dot
            ON (dot.id_doc_ori_type = de.id_doc_ori_type)
          JOIN doc_destination dd
            ON (dd.id_doc_destination = de.id_doc_destination)
          JOIN doc_original do
            ON (do.id_doc_original = de.id_doc_original)
         WHERE de.id_doc_external = i_id_doc
           AND de.id_external_request = i_id_ref;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_DOC_UPD_VALUES',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_doc_upd_values;

    /**
    * Gets document information and updates FLG_RECEIVED
    *
    * @param   i_lang                  Language associated to the professional executing the request
    * @param   i_prof                  Id professional, institution and software
    * @param   i_id_ref                Referral identifier
    * @param   i_id_doc                Document identifier    
    * @param   i_flg_received          Flag indicating if the document was received. {*} Y - yes {*} N - no
    * @param   o_error                 An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  João Almeida
    * @version 1.0
    * @since   07-10-2009
    */
    FUNCTION upd_doc_ext_flg_received
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_ref       IN doc_external.id_external_request%TYPE,
        i_id_doc       IN doc_external.id_doc_external%TYPE,
        i_flg_received IN doc_external.flg_received%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_doc_type          doc_external.id_doc_type%TYPE;
        l_desc_doc_type     doc_external.desc_doc_type%TYPE;
        l_num_doc           doc_external.num_doc%TYPE;
        l_dt_emited         doc_external.dt_emited%TYPE;
        l_dt_expire         doc_external.dt_expire%TYPE;
        l_orig_dest         doc_external.id_doc_destination%TYPE;
        l_desc_ori_dest     doc_external.desc_doc_ori_type%TYPE;
        l_orig_type         doc_external.id_doc_ori_type%TYPE;
        l_desc_ori_doc_type doc_external.desc_doc_type%TYPE;
        l_notes             doc_external.notes%TYPE;
        l_sent_by           doc_external.flg_sent_by%TYPE;
        l_original          doc_external.id_doc_original%TYPE;
        l_desc_original     doc_external.desc_doc_original%TYPE;
        l_title             doc_external.title%TYPE;
        l_prof_perf_by      doc_external.id_prof_perf_by%TYPE;
        l_desc_perf_by      doc_external.desc_perf_by%TYPE;
        l_id_doc_external   doc_external.id_doc_external%TYPE;
    
        l_prof_template profile_template.id_profile_template%TYPE;
        l_sys_butt      sys_button_prop.id_sys_button_prop%TYPE;
    
        CURSOR c_sys_butt IS
            SELECT id_sys_button_prop
              FROM doc_config dc
             WHERE dc.code_doc_config = 'DOC_REFERRAL'
               AND dc.id_software IN (i_prof.software, 0)
               AND dc.id_institution IN (i_prof.institution, 0)
               AND dc.id_profile_template IN (l_prof_template, 0)
               AND dc.value = pk_ref_constant.g_yes
               AND rownum = 1;
    
    BEGIN
        g_error         := 'Calling pk_tools.get_prof_profile_template';
        l_prof_template := pk_tools.get_prof_profile_template(i_prof => i_prof);
    
        g_error  := 'get_doc_upd_values / ID_DOC=' || i_id_doc || ' FLG_RECEIVED=' || i_flg_received;
        g_retval := get_doc_upd_values(i_lang              => i_lang,
                                       i_prof              => i_prof,
                                       i_id_doc            => i_id_doc,
                                       i_id_ref            => i_id_ref,
                                       o_doc_type          => l_doc_type,
                                       o_desc_doc_type     => l_desc_doc_type,
                                       o_num_doc           => l_num_doc,
                                       o_dt_emited         => l_dt_emited,
                                       o_dt_expire         => l_dt_expire,
                                       o_orig_dest         => l_orig_dest,
                                       o_desc_ori_dest     => l_desc_ori_dest,
                                       o_orig_type         => l_orig_type,
                                       o_desc_ori_doc_type => l_desc_ori_doc_type,
                                       o_notes             => l_notes,
                                       o_sent_by           => l_sent_by,
                                       o_original          => l_original,
                                       o_desc_original     => l_desc_original,
                                       o_title             => l_title,
                                       o_prof_perf_by      => l_prof_perf_by,
                                       o_desc_perf_by      => l_desc_perf_by,
                                       o_error             => o_error);
    
        IF NOT g_retval
        THEN
            g_error := 'ERROR: ' || g_error;
            RAISE g_exception_np;
        END IF;
    
        -- it will only update documents thas has FLG_SENT_BY not null
        IF l_sent_by IS NULL
        THEN
            g_error := 'FLG_SENT_BY is null / ID_DOC_EXTERNAL=' || i_id_doc || ' ID_REF=' || i_id_ref;
            RAISE g_exception;
        END IF;
    
        -- getting sys_button_prop
        g_error := 'OPEN c_sys_butt / PROFILE_TEMPLATE=' || l_prof_template || ' ID_SOFTWARE=' || i_prof.software ||
                   ' ID_INSTITUTION=' || i_prof.institution;
        OPEN c_sys_butt;
        FETCH c_sys_butt
            INTO l_sys_butt;
        CLOSE c_sys_butt;
    
        IF l_sys_butt IS NULL
        THEN
            -- sys_button_prop must be defined in order to update_doc_internal work properly          
            g_error := 'SYS_BUTTON_PROP IS NULL';
            RAISE g_exception;
        END IF;
    
        g_error  := 'PK_DOC.UPDATE_DOC_INTERNAL / ID_DOC=' || i_id_doc || ' FLG_RECEIVED=' || i_flg_received ||
                    ' DOC_TYPE= ' || l_doc_type || ' DESC_DOC_TYPE=' || l_desc_doc_type || ' NUM_DOC=' || l_num_doc ||
                    ' ORIG_DEST=' || l_orig_dest || ' DESC_ORIG_DEST=' || l_desc_ori_dest || ' ORI_TYPE=' ||
                    l_orig_type || ' DESC_ORI_TYPE=' || l_desc_ori_doc_type || ' SENT_BY=' || l_sent_by || ' ORIGINAL=' ||
                    l_original || ' PROF_PERF_BY=' || l_prof_perf_by;
        g_retval := pk_doc.update_doc_internal(i_lang               => i_lang,
                                               i_prof               => i_prof,
                                               i_id_doc             => i_id_doc,
                                               i_doc_type           => l_doc_type,
                                               i_desc_doc_type      => l_desc_doc_type,
                                               i_num_doc            => l_num_doc,
                                               i_dt_doc             => l_dt_emited,
                                               i_dt_expire          => l_dt_expire,
                                               i_orig_dest          => l_orig_dest,
                                               i_desc_ori_dest      => l_desc_ori_dest,
                                               i_orig_type          => l_orig_type,
                                               i_desc_ori_doc_type  => l_desc_ori_doc_type,
                                               i_notes              => l_notes,
                                               i_sent_by            => l_sent_by,
                                               i_received           => i_flg_received, -- only update provided by the interface
                                               i_original           => l_original,
                                               i_desc_original      => l_desc_original,
                                               i_btn                => l_sys_butt,
                                               i_title              => l_title,
                                               i_prof_perf_by       => l_prof_perf_by,
                                               i_desc_perf_by       => l_desc_perf_by,
                                               i_author             => NULL,
                                               i_specialty          => NULL,
                                               i_doc_language       => NULL,
                                               i_desc_language      => NULL,
                                               i_flg_publish        => NULL,
                                               i_conf_code          => table_varchar(),
                                               i_desc_conf_code     => table_varchar(),
                                               i_code_coding_schema => table_varchar(),
                                               i_conf_code_set      => table_varchar(),
                                               i_desc_conf_code_set => table_varchar(),
                                               i_notes_upd          => NULL,
                                               o_id_doc_external    => l_id_doc_external,
                                               o_error              => o_error);
    
        IF NOT g_retval
        THEN
            g_error := 'ERROR: ' || g_error;
            RAISE g_exception_np;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'UPD_DOC_EXT_FLG_RECEIVED',
                                              o_error    => o_error);
            RETURN FALSE;
    END upd_doc_ext_flg_received;

    /**
    * Gets professional identifier, given the num order
    *
    * @param   i_lang                  Language associated to the professional executing the request
    * @param   i_prof                  Id professional, institution and software    
    * @param   i_num_order             Professional num order    
    * @param   o_id_prof               Professional identifier
    * @param   o_error                 An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.6.0.5
    * @since   17-02-2011
    */
    FUNCTION get_prof_id
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_num_order    IN professional.num_order%TYPE,
        o_id_prof      OUT professional.id_professional%TYPE,
        o_id_prf_templ OUT profile_template.id_profile_template%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_prof IS
            SELECT p.id_professional, ppt.id_profile_template
              FROM professional p
              JOIN prof_soft_inst psi
                ON (p.id_professional = psi.id_professional)
              JOIN prof_institution pi
                ON (psi.id_professional = pi.id_professional AND psi.id_institution = pi.id_institution)
              JOIN prof_profile_template ppt
                ON (ppt.id_professional = psi.id_professional AND ppt.id_software = psi.id_software AND
                   ppt.id_institution = psi.id_institution)
              JOIN institution i
                ON (i.id_institution = ppt.id_institution)
             WHERE pi.flg_state = pk_ref_constant.g_active
               AND pi.dt_end_tstz IS NULL
               AND p.num_order = i_num_order
               AND psi.id_software = i_prof.software
               AND psi.id_institution = i_prof.institution
               AND i.flg_available = pk_ref_constant.g_yes;
    BEGIN
    
        g_error := 'Init get_prof_id';
        OPEN c_prof;
        FETCH c_prof
            INTO o_id_prof, o_id_prf_templ;
    
        IF c_prof%NOTFOUND
        THEN
            g_error_code := pk_ref_constant.g_ref_error_1009;
            g_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => g_error_code);
            RAISE g_exception;
        END IF;
    
        CLOSE c_prof;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            IF g_error_code IS NOT NULL
            THEN
                g_flg_action := pk_ref_constant.g_err_flg_action_u;
            ELSE
                g_error_code := SQLCODE;
                g_error_desc := SQLERRM;
                g_flg_action := pk_ref_constant.g_err_flg_action_s;
            END IF;
            pk_alert_exceptions.process_error(i_lang        => i_lang,
                                              i_sqlcode     => g_error_code,
                                              i_sqlerrm     => g_error_desc,
                                              i_message     => g_error,
                                              i_owner       => g_package_owner,
                                              i_package     => g_package_name,
                                              i_function    => 'GET_PROF_ID',
                                              i_action_type => g_flg_action,
                                              i_action_msg  => NULL,
                                              o_error       => o_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END get_prof_id;

    /**
    * Checks if operation date is correct
    *
    * @param   i_lang     Language associated to the professional executing the request
    * @param   i_prof     Id professional, institution and software    
    * @param   i_op_date  Operation date
    * @param   o_error    An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.6.0.5
    * @since   21-02-2011
    */
    FUNCTION check_op_date
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_op_date IN TIMESTAMP WITH LOCAL TIME ZONE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_error := 'Init check_op_date';
        IF i_op_date > current_timestamp
        THEN
            g_error      := 'INVALID OPERATION_DATE / OP_DATE=' ||
                            pk_date_utils.to_char_insttimezone(i_prof, i_op_date, pk_ref_constant.g_format_date_2) ||
                            ' CURRENT_DATE=' ||
                            pk_date_utils.to_char_insttimezone(i_prof,
                                                               current_timestamp,
                                                               pk_ref_constant.g_format_date_2);
            g_error_code := pk_ref_constant.g_ref_error_1005;
            g_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => g_error_code);
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            IF g_error_code IS NOT NULL
            THEN
                g_flg_action := pk_ref_constant.g_err_flg_action_u; -- user defined error
            ELSE
                g_error_code := SQLCODE;
                g_error_desc := SQLERRM;
                g_flg_action := pk_ref_constant.g_err_flg_action_s; -- system error
            END IF;
            pk_alert_exceptions.process_error(i_lang        => i_lang,
                                              i_sqlcode     => g_error_code,
                                              i_sqlerrm     => g_error_desc,
                                              i_message     => g_error,
                                              i_owner       => g_package_owner,
                                              i_package     => g_package_name,
                                              i_function    => 'CHECK_OP_DATE',
                                              i_action_type => g_flg_action,
                                              i_action_msg  => NULL,
                                              o_error       => o_error);
            RETURN FALSE;
    END check_op_date;

    /**
    * Checks if the professional is clinical director in this institution
    *
    * @param   i_lang                  Language associated to the professional executing the request
    * @param   i_prof                  Id professional, institution and software    
    * @param   i_id_institution        Institution identifier
    * @param   i_prof_name             Professional name
    * @param   o_error                 An error message, set when return=false
    *
    * @RETURN  TRUE if is clinical director, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.6.0.5
    * @since   10-03-2011
    */
    FUNCTION check_clinical_director
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_institution IN institution.id_institution%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_prof profissional;
    BEGIN
    
        g_error := 'Init check_clinical_director';
        l_prof  := profissional(i_prof.id, i_id_institution, i_prof.software);
        -- check if professional l_prof_req is clinical director
        g_error  := 'Call pk_ref_core.is_clinical_director';
        g_retval := pk_ref_core.is_clinical_director(i_lang => i_lang, i_prof => l_prof);
    
        IF NOT g_retval
        THEN
            g_error := 'Professional is not a clinical director in the institution ' || i_id_institution ||
                       ' / i_prof=' || pk_utils.to_string(l_prof);
            RAISE g_exception;
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
                                              i_function => 'CHECK_CLINICAL_DIRECTOR',
                                              o_error    => o_error);
            RETURN FALSE;
    END check_clinical_director;

    /**
    * Checks if the professional exists. If not, creates him.
    *
    * @param   i_lang                  Language associated to the professional executing the request
    * @param   i_prof                  Id professional, institution and software    
    * @param   i_num_order             Professional num order
    * @param   i_prof_name             Professional name
    * @param   i_profile_templ         Profile template of the professional being created (only if it is being created)
    * @param   i_func                  Functionality of the professional
    * @param   i_dcs                   Department + Clinical service    
    * @param   o_prof                  Professional data: id, institution and software
    * @param   o_error                 An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   30-09-2009
    */
    FUNCTION check_professional
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_num_order     IN professional.num_order%TYPE,
        i_prof_name     IN professional.name%TYPE,
        i_profile_templ IN profile_template.id_profile_template%TYPE DEFAULT NULL,
        i_func          IN sys_functionality.id_functionality%TYPE DEFAULT NULL,
        i_dcs           IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_prof          OUT profissional,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'Init check_professional / i_prof=' || pk_utils.to_string(i_prof) || ' i_num_order=' || i_num_order ||
                   ' i_dcs=' || i_dcs || ' i_profile_templ=' || i_profile_templ || ' i_func=' || i_func;
        o_prof  := profissional(NULL, i_prof.institution, i_prof.software);
    
        g_retval := pk_ref_interface.set_professional_num_ord(i_lang          => i_lang,
                                                              i_prof          => i_prof,
                                                              i_num_order     => i_num_order,
                                                              i_prof_name     => i_prof_name,
                                                              i_profile_templ => i_profile_templ,
                                                              i_func          => i_func,
                                                              i_dcs           => i_dcs,
                                                              o_id_prof       => o_prof.id,
                                                              o_error         => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'CHECK_PROFESSIONAL',
                                              o_error    => o_error);
            RETURN FALSE;
    END check_professional;

    /**
    * Checks if it is a valid dep_clin_serv for the referral dest institution
    *
    * @param   i_lang                  Language associated to the professional executing the request
    * @param   i_prof                  Id professional, institution and software    
    * @param   i_id_ref                Referral identifier
    * @param   i_dcs                   Department + Service            
    * @param   o_flg_available         Flag indicating if i_dcs is a valid dep_clin_serv
    * @param   o_error                 An error message, set when return=false
    *
    * @value   o_flg_available         {*} 'Y' - yes {*} 'N' - no
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   30-09-2009
    */
    FUNCTION check_dep_clin_serv
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_ref        IN p1_external_request.id_external_request%TYPE,
        i_dcs           IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_flg_available OUT VARCHAR,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_count PLS_INTEGER;
    
        CURSOR c_dcs IS
            SELECT COUNT(1)
              FROM dep_clin_serv dcs
              JOIN department d
                ON d.id_department = dcs.id_department
              JOIN p1_external_request p
                ON p.id_inst_dest = d.id_institution
             WHERE id_external_request = i_id_ref
               AND dcs.id_dep_clin_serv = i_dcs;
    BEGIN
        g_error         := 'Init check_dep_clin_serv / ID_REF=' || i_id_ref || ' DCS=' || i_dcs;
        o_flg_available := pk_ref_constant.g_no;
    
        g_error := 'OPEN c_dcs / ID_REFERRAL=' || i_id_ref || ' DCS=' || i_dcs;
        OPEN c_dcs;
        FETCH c_dcs
            INTO l_count;
        CLOSE c_dcs;
    
        IF l_count != 0
        THEN
            o_flg_available := pk_ref_constant.g_yes;
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
                                              i_function => 'CHECK_DEP_CLIN_SERV',
                                              o_error    => o_error);
            IF c_dcs%ISOPEN
            THEN
                CLOSE c_dcs;
            END IF;
            RETURN FALSE;
    END check_dep_clin_serv;

    /**
    * Checks if it is a valid dep_clin_serv for the dest institution
    *
    * @param   i_lang                  Language associated to the professional executing the request
    * @param   i_prof                  Id professional, institution and software    
    * @param   i_dcs                   Department + Service
    * @param   i_id_inst_dest          Institution dest identifier    
    * @param   o_flg_available         Flag indicating if i_dcs is a valid dep_clin_serv
    * @param   o_error                 An error message, set when return=false
    *
    * @value   o_flg_available         {*} 'Y' - yes {*} 'N' - no
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.6.0.5
    * @since   17-02-2011
    */
    FUNCTION check_dep_clin_serv
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_inst_dest  IN institution.id_institution%TYPE,
        i_dcs           IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_flg_available OUT VARCHAR,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_count PLS_INTEGER;
    
        CURSOR c_dcs IS
            SELECT COUNT(1)
              FROM dep_clin_serv dcs
              JOIN department d
                ON d.id_department = dcs.id_department
              JOIN institution i
                ON i.id_institution = d.id_institution
             WHERE d.id_institution = i_id_inst_dest
               AND dcs.id_dep_clin_serv = i_dcs
               AND i.flg_available = pk_ref_constant.g_yes;
    BEGIN
        g_error         := 'Init check_dep_clin_serv / ID_INST_DEST=' || i_id_inst_dest || ' DCS=' || i_dcs;
        o_flg_available := pk_ref_constant.g_no;
    
        g_error := 'OPEN c_dcs / ID_INST_DEST=' || i_id_inst_dest || ' DCS=' || i_dcs;
        OPEN c_dcs;
        FETCH c_dcs
            INTO l_count;
        CLOSE c_dcs;
    
        g_error := 'dcs count=' || l_count;
        IF l_count != 0
        THEN
            o_flg_available := pk_ref_constant.g_yes;
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
                                              i_function => 'CHECK_DEP_CLIN_SERV',
                                              o_error    => o_error);
            IF c_dcs%ISOPEN
            THEN
                CLOSE c_dcs;
            END IF;
            RETURN FALSE;
    END check_dep_clin_serv;

    /**
    * Checks if it is a valid reason_code
    *
    * @param   i_lang                  Language associated to the professional executing the request
    * @param   i_prof                  Id professional, institution and software    
    * @param   i_id_prof_templ         Profile template identifier of the professional
    * @param   i_reason_code           Referral reason code
    * @param   i_reason_type           Referral type of reason code   
    * @param   o_flg_available         if is a valid reason code    {*} 'Y' - valid reason code 
                                                                    {*} 'N' - otherwise 
    * @param   o_error                 An error message, set when return=false
    *
    * @value   i_reason_type           {*} 'C' - Cancellation {*} 'D' - Sent back by physician {*} 'R' - Refuse {*} 'B' - Sent back by registrar
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   01-10-2009
    */
    FUNCTION check_ref_reason_code
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_prof_templ IN profile_template.id_profile_template%TYPE DEFAULT NULL,
        i_reason_code   IN p1_reason_code.id_reason_code%TYPE,
        i_reason_type   IN p1_reason_code.flg_type%TYPE,
        o_flg_available OUT VARCHAR,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_ignore_reason_c_config sys_config.value%TYPE;
        l_count                  PLS_INTEGER;
    
        CURSOR c_rc IS
            SELECT COUNT(1)
              FROM p1_reason_code r
              LEFT JOIN p1_reason_code_soft_inst rsi
                ON (r.id_reason_code = rsi.id_reason_code)
             WHERE r.id_reason_code = i_reason_code
               AND r.flg_type = i_reason_type
               AND (l_ignore_reason_c_config = pk_ref_constant.g_yes OR
                   (l_ignore_reason_c_config = pk_ref_constant.g_no AND r.flg_available = pk_ref_constant.g_yes AND
                   rsi.flg_available = pk_ref_constant.g_yes
                   /*AND rsi.id_profile_template IN (i_id_prof_templ, 0) */ -- Glintt does not register the professionals in Alert
                   AND rsi.id_software IN (i_prof.software, 0) AND rsi.id_institution IN (i_prof.institution, 0)));
    BEGIN
    
        ----------------------
        -- INIT
        ----------------------
        g_error         := 'Init check_ref_reason_code  / ID_REASON_CODE=' || i_reason_code || ' REASON_TYPE=' ||
                           i_reason_type;
        o_flg_available := pk_ref_constant.g_no;
    
        ----------------------
        -- CONFIG
        ----------------------
    
        g_error                  := 'Call pk_sysconfig.get_config / ID_SYS_CONFIG=' ||
                                    pk_ref_constant.g_ref_ignore_reason_c_i;
        l_ignore_reason_c_config := nvl(pk_sysconfig.get_config(pk_ref_constant.g_ref_ignore_reason_c_i, i_prof),
                                        pk_ref_constant.g_no);
    
        ----------------------
        -- FUNC
        ----------------------
    
        g_error := 'OPEN c_rc / ID_REASON_CODE=' || i_reason_code;
        OPEN c_rc;
        FETCH c_rc
            INTO l_count;
        CLOSE c_rc;
    
        g_error := 'c_rc count=' || l_count;
        IF l_count != 0
        THEN
            o_flg_available := pk_ref_constant.g_yes;
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
                                              i_function => 'CHECK_REF_REASON_CODE',
                                              o_error    => o_error);
            IF c_rc%ISOPEN
            THEN
                CLOSE c_rc;
            END IF;
            RETURN FALSE;
        
    END check_ref_reason_code;

    /**
    * Validates input parameters
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Id professional, institution and software    
    * @param   i_id_ref         Referral identifier   
    * @param   i_id_inst        Referral institution identifier (orig or dest, depends on the operation being done)
    * @param   i_num_order      Professional num order            
    * @param   i_prof_name      Professional name that is triaging the referral   
    * @param   i_profile_templ  Profile template of the professional being created (only if it is being created)
    * @param   i_func           Functionality of the professional
    * @param   i_dcs            Department + Service
    * @param   i_level          Triage urgency level
    * @param   i_reason_code    Reason code identifier
    * @param   i_reason_type    Referral type of reason code {*} 'C' - Cancellation 
                                                             {*} 'D' - Sent back by physician 
                                                             {*} 'R' - Refuse 
                                                             {*} 'B' - Sent back by registrar   
    * @param   i_date           Operation date        
    * @param   o_flg_valid      {*} 'Y' - all parameters valid {*} 'N' - otherwise 
    * @param   o_prof           Professional data: id, institution and software (if i_num_order not null)
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   02-10-2009
    */
    FUNCTION check_requirements
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_ref        IN p1_external_request.id_external_request%TYPE,
        i_id_inst       IN institution.id_institution%TYPE DEFAULT NULL,
        i_num_order     IN professional.num_order%TYPE DEFAULT NULL,
        i_prof_name     IN professional.name%TYPE DEFAULT NULL,
        i_profile_templ IN profile_template.id_profile_template%TYPE DEFAULT NULL,
        i_func          IN sys_functionality.id_functionality%TYPE DEFAULT NULL,
        i_dcs           IN dep_clin_serv.id_dep_clin_serv%TYPE DEFAULT NULL,
        i_level         IN p1_external_request.decision_urg_level%TYPE DEFAULT NULL,
        i_reason_code   IN p1_reason_code.id_reason_code%TYPE DEFAULT NULL,
        i_reason_type   IN p1_reason_code.flg_type%TYPE DEFAULT NULL,
        i_date          IN p1_tracking.dt_tracking_tstz%TYPE,
        o_flg_valid     OUT VARCHAR2,
        o_prof          OUT profissional,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_params        VARCHAR2(1000 CHAR);
        l_count         PLS_INTEGER;
        l_flg_available VARCHAR2(1 CHAR);
    
        CURSOR c_level IS
            SELECT decode(c, NULL, 0, 1) --COUNT(1)
              FROM (SELECT pk_sysdomain.get_domain('P1_TRIAGE_LEVEL.MED_HS_1', i_level, i_lang) c
                      FROM dual);
        l_ppt profile_template.id_profile_template%TYPE;
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_id_ref=' || i_id_ref || ' i_num_order=' ||
                    i_num_order || ' i_dcs=' || i_dcs || ' i_level=' || i_level || ' i_reason_code=' || i_reason_code ||
                    ' i_reason_type=' || i_reason_type || ' i_profile_templ=' || i_profile_templ || ' i_func=' ||
                    i_func;
    
        g_error := 'Init check_requirements / ' || l_params;
        pk_alertlog.log_debug(g_error);
        reset_vars;
        o_flg_valid := pk_ref_constant.g_no;
    
        IF i_id_ref IS NULL
           OR i_date IS NULL
        THEN
            g_error      := 'Invalid parameters / ' || l_params;
            g_error_code := pk_ref_constant.g_ref_error_1005;
            g_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => g_error_code);
            RAISE g_exception;
        END IF;
    
        IF i_id_inst IS NOT NULL
           AND i_id_inst != i_prof.institution
        THEN
            g_error      := 'INVALID professional institution / i_id_inst=' || i_id_inst || ' / ' || l_params;
            g_error_code := pk_ref_constant.g_ref_error_1009;
            g_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => g_error_code);
            RAISE g_exception;
        END IF;
    
        --------------------------------------
        -- professional
        IF i_num_order IS NOT NULL
        THEN
            g_error  := 'Call check_professional / ' || l_params;
            g_retval := check_professional(i_lang          => i_lang,
                                           i_prof          => i_prof,
                                           i_num_order     => i_num_order,
                                           i_prof_name     => i_prof_name,
                                           i_profile_templ => i_profile_templ,
                                           i_func          => i_func,
                                           i_dcs           => i_dcs,
                                           o_prof          => o_prof,
                                           o_error         => o_error);
        
            IF NOT g_retval
            THEN
                RAISE g_exception_np;
            END IF;
        
        ELSE
            o_prof := i_prof; -- use this variable from now on (in this function)
        END IF;
    
        l_params := l_params || ' o_prof=' || pk_utils.to_string(o_prof);
    
        --------------------------------------
        -- dep_clin_serv
        IF i_dcs IS NOT NULL
        THEN
            g_error  := 'Calling check_dep_clin_serv / ' || l_params;
            g_retval := check_dep_clin_serv(i_lang          => i_lang,
                                            i_prof          => o_prof,
                                            i_id_ref        => i_id_ref,
                                            i_dcs           => i_dcs,
                                            o_flg_available => l_flg_available,
                                            o_error         => o_error);
        
            IF NOT g_retval
            THEN
                RAISE g_exception_np;
            END IF;
        
            IF l_flg_available = pk_ref_constant.g_no
            THEN
                g_error      := 'INVALID DEP_CLIN_SERV / ' || l_params;
                g_error_code := pk_ref_constant.g_ref_error_1005;
                g_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => g_error_code);
                RAISE g_exception;
            END IF;
        END IF;
    
        --------------------------------------
        -- level
        IF i_level IS NOT NULL
        THEN
            g_error := 'OPEN c_level / ' || l_params;
            OPEN c_level;
            FETCH c_level
                INTO l_count;
            CLOSE c_level;
        
            IF l_count = 0
            THEN
                g_error      := 'INVALID LEVEL / ' || l_params;
                g_error_code := pk_ref_constant.g_ref_error_1005;
                g_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => g_error_code);
                RAISE g_exception;
            END IF;
        END IF;
    
        --------------------------------------
        -- reason_code
        IF i_reason_code IS NOT NULL
        THEN
            g_error := 'Call pk_prof_utils.get_prof_profile_template / ' || l_params;
            l_ppt   := pk_prof_utils.get_prof_profile_template(i_prof => o_prof);
        
            l_params := l_params || ' i_id_prof_templ=' || l_ppt;
        
            g_error  := 'Calling check_ref_reason_code / ' || l_params;
            g_retval := check_ref_reason_code(i_lang          => i_lang,
                                              i_prof          => o_prof,
                                              i_reason_code   => i_reason_code,
                                              i_reason_type   => i_reason_type,
                                              i_id_prof_templ => l_ppt,
                                              o_flg_available => l_flg_available,
                                              o_error         => o_error);
        
            IF NOT g_retval
            THEN
                RAISE g_exception_np;
            END IF;
        
            IF l_flg_available = pk_ref_constant.g_no
            THEN
                g_error      := 'INVALID REASON_CODE / ' || l_params;
                g_error_code := pk_ref_constant.g_ref_error_1005;
                g_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => g_error_code);
                RAISE g_exception;
            END IF;
        END IF;
    
        --------------------------------------
        -- operation date
        g_error  := 'Call check_op_date / ' || l_params;
        g_retval := check_op_date(i_lang => i_lang, i_prof => o_prof, i_op_date => i_date, o_error => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        o_flg_valid := pk_ref_constant.g_yes;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            IF c_level%ISOPEN
            THEN
                CLOSE c_level;
            END IF;
            RETURN FALSE;
        WHEN OTHERS THEN
            IF g_error_code IS NOT NULL
            THEN
                g_flg_action := pk_ref_constant.g_err_flg_action_u;
            ELSE
                g_error_code := SQLCODE;
                g_error_desc := SQLERRM;
                g_flg_action := pk_ref_constant.g_err_flg_action_s;
            END IF;
            pk_alert_exceptions.process_error(i_lang        => i_lang,
                                              i_sqlcode     => g_error_code,
                                              i_sqlerrm     => g_error_desc,
                                              i_message     => g_error,
                                              i_owner       => g_package_owner,
                                              i_package     => g_package_name,
                                              i_function    => 'CHECK_REQUIREMENTS',
                                              i_action_type => g_flg_action,
                                              i_action_msg  => NULL,
                                              o_error       => o_error);
            IF c_level%ISOPEN
            THEN
                CLOSE c_level;
            END IF;
            RETURN FALSE;
    END check_requirements;

    /**
    * Gets the profile template related to this institution
    * Note: this function is used only to interface APIs... does not take into account view only profiles... 
    * should not be used for other purposes...    
    *
    * @param   i_lang                  Language associated to the professional executing the request
    * @param   i_prof                  Id professional, institution and software    
    * @param   i_id_institution        Institution identifier
    * @param   i_id_category           Professional category identifier
    * @param   o_profile_template      Profile template identifier
    * @param   o_error                 An error message, set when return=false
    *
    * @return  true if sucess, false otherwise
    * @author  Ana Monteiro
    * @version 2.6.1
    * @since   03-04-2014
    */
    FUNCTION get_profile_template_inst
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_institution   IN institution.id_institution%TYPE,
        i_id_category      IN category.id_category%TYPE,
        o_profile_template OUT profile_template.id_profile_template%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_params     VARCHAR2(1000 CHAR);
        l_flg_type   institution.flg_type%TYPE;
        l_id_market  institution.id_market%TYPE;
        l_inst_hosp  table_varchar;
        l_inst_cs    table_varchar;
        l_found_cs   PLS_INTEGER;
        l_found_hosp PLS_INTEGER;
    
        CURSOR c_inst IS
            SELECT i.flg_type, i.id_market
              FROM institution i
             WHERE i.id_institution = i_id_institution;
    
        CURSOR c_prof_templ_cat
        (
            x_id_cat  IN category.id_category%TYPE,
            x_prf_tab IN table_number
        ) IS
            SELECT ptc.id_profile_template
              FROM profile_template_category ptc
              JOIN TABLE(CAST(x_prf_tab AS table_number)) tt
                ON tt.column_value = ptc.id_profile_template
             WHERE ptc.id_category = x_id_cat;
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_id_institution=' || i_id_institution ||
                    ' i_id_category=' || i_id_category;
        g_error  := 'Init get_profile_template_inst / ' || l_params;
    
        -- todo: create relational table to relate profiles and institution types
        -- institution types
        l_inst_cs   := table_varchar(pk_alert_constant.g_inst_type_primary_care,
                                     pk_alert_constant.g_inst_type_outpatient,
                                     pk_alert_constant.g_inst_type_familiar_health,
                                     'ULS');
        l_inst_hosp := table_varchar(pk_alert_constant.g_inst_type_hospital,
                                     pk_alert_constant.g_inst_type_private_practice,
                                     'M');
    
        OPEN c_inst;
        FETCH c_inst
            INTO l_flg_type, l_id_market;
        CLOSE c_inst;
    
        l_params := l_params || ' l_flg_type=' || l_flg_type || ' l_id_market=' || l_id_market;
    
        l_found_cs   := pk_utils.search_table_varchar(i_table => l_inst_cs, i_search => l_flg_type);
        l_found_hosp := pk_utils.search_table_varchar(i_table => l_inst_hosp, i_search => l_flg_type);
    
        g_error := 'Init get_profile_template_inst / ' || l_params;
        CASE l_id_market
            WHEN pk_ref_constant.g_market_br THEN
            
                IF l_found_cs != -1
                THEN
                    -- cs
                    OPEN c_prof_templ_cat(x_id_cat  => i_id_category,
                                          x_prf_tab => table_number(pk_ref_constant.g_profile_adm_cs_br,
                                                                    pk_ref_constant.g_profile_med_cs_br));
                
                    FETCH c_prof_templ_cat
                        INTO o_profile_template;
                    CLOSE c_prof_templ_cat;
                
                ELSIF l_found_hosp != -1
                THEN
                    -- h
                    --OPEN c_prof_templ_cat(x_id_cat  => i_id_category,
                    --                      x_prf_tab => table_number(pk_ref_constant.g_profile_adm_hs_br,
                    --                                                pk_ref_constant.g_profile_med_hs_br));
                
                    --FETCH c_prof_templ_cat
                    --    INTO o_profile_template;
                    --CLOSE c_prof_templ_cat;                   
                    NULL;
                ELSE
                    NULL;
                END IF;
            WHEN pk_ref_constant.g_market_cl THEN
            
                IF l_found_cs != -1
                THEN
                    -- cs
                    OPEN c_prof_templ_cat(x_id_cat  => i_id_category,
                                          x_prf_tab => table_number(pk_ref_constant.g_profile_adm_cs_cl,
                                                                    pk_ref_constant.g_profile_med_cs_cl));
                
                    FETCH c_prof_templ_cat
                        INTO o_profile_template;
                    CLOSE c_prof_templ_cat;
                
                ELSIF l_found_hosp != -1
                THEN
                    -- h
                    OPEN c_prof_templ_cat(x_id_cat  => i_id_category,
                                          x_prf_tab => table_number(pk_ref_constant.g_profile_adm_hs_cl,
                                                                    pk_ref_constant.g_profile_med_hs_cl));
                
                    FETCH c_prof_templ_cat
                        INTO o_profile_template;
                    CLOSE c_prof_templ_cat;
                
                ELSE
                    NULL;
                END IF;
            ELSE
                -- PT (default) and others
                IF l_found_cs != -1
                THEN
                    -- cs
                    OPEN c_prof_templ_cat(x_id_cat  => i_id_category,
                                          x_prf_tab => table_number(pk_ref_constant.g_profile_adm_cs,
                                                                    pk_ref_constant.g_profile_med_cs));
                
                    FETCH c_prof_templ_cat
                        INTO o_profile_template;
                    CLOSE c_prof_templ_cat;
                
                ELSIF l_found_hosp != -1
                THEN
                    -- h
                    OPEN c_prof_templ_cat(x_id_cat  => i_id_category,
                                          x_prf_tab => table_number(pk_ref_constant.g_profile_adm_hs,
                                                                    pk_ref_constant.g_profile_med_hs));
                
                    FETCH c_prof_templ_cat
                        INTO o_profile_template;
                    CLOSE c_prof_templ_cat;
                
                ELSE
                    NULL;
                END IF;
            
        END CASE;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_PROFILE_TEMPLATE_INST',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_profile_template_inst;

    /**
    * Maps input data into an array of id_diagnosis (used to create/update referrals) 
    *
    * @param   i_lang             Language associated to the professional executing the request
    * @param   i_prof             Id professional, institution and software    
    * @param   i_flg_type         Problem array codification type: ICD9, ICD10, ICPC2...
    * @param   i_code_icd         Problem array code (code_icd)   
    * @param   o_diag_array       Array of diagnosis identifiers
    * @param   o_error            An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.6.0.5
    * @since   17-02-2011
    */
    FUNCTION map_to_diag_array
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_flg_type   IN table_varchar,
        i_code_icd   IN table_varchar,
        o_diag_array OUT table_number,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_diag
        (
            x_code_icd IN diagnosis.code_icd%TYPE,
            x_flg_type IN diagnosis.flg_type%TYPE
        ) IS
            SELECT DISTINCT id_diagnosis
              FROM diagnosis_content d
             WHERE d.code_icd = x_code_icd
               AND d.flg_type = x_flg_type;
    BEGIN
    
        g_error := 'Init map_to_diag_array / ' || i_flg_type.count;
        reset_vars;
        o_diag_array := table_number();
        o_diag_array.extend(i_flg_type.count);
    
        FOR i IN 1 .. i_flg_type.count
        LOOP
        
            OPEN c_diag(i_code_icd(i), i_flg_type(i));
            FETCH c_diag
                INTO o_diag_array(i);
            g_found := c_diag%FOUND;
            CLOSE c_diag;
        
            IF NOT g_found
            THEN
                -- diagnosis not configured in alert
                g_error      := 'Diagnosis CODE_ICD=' || i_code_icd(i) || ' FLG_TYPE=' || i_flg_type(i) ||
                                ' not configured';
                g_error_code := pk_ref_constant.g_ref_error_1009;
                g_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => g_error_code);
            
                RAISE g_exception;
            END IF;
        
        END LOOP;
    
        g_error := pk_utils.to_string(o_diag_array);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            BEGIN
                IF g_error_code IS NOT NULL
                THEN
                    g_flg_action := pk_ref_constant.g_err_flg_action_u;
                ELSE
                    g_error_code := SQLCODE;
                    g_error_desc := SQLERRM;
                    g_flg_action := pk_ref_constant.g_err_flg_action_s;
                END IF;
                pk_alert_exceptions.process_error(i_lang        => i_lang,
                                                  i_sqlcode     => g_error_code,
                                                  i_sqlerrm     => g_error_desc,
                                                  i_message     => g_error,
                                                  i_owner       => g_package_owner,
                                                  i_package     => g_package_name,
                                                  i_function    => 'MAP_TO_DIAG_ARRAY',
                                                  i_action_type => g_flg_action,
                                                  i_action_msg  => NULL,
                                                  o_error       => o_error);
                RETURN FALSE;
            END;
    END map_to_diag_array;

    /**
    * Checks if the array of diagnosis is valid 
    *
    * @param   i_lang                  Language associated to the professional executing the request
    * @param   i_prof                  Id professional, institution and software    
    * @param   i_diag_array            Array of diagnosis [i_diag_flg_type|i_diag_code|i_diag_desc|i_diag_notes]
    * @param   o_error                 An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   07-10-2009
    */
    FUNCTION check_diag_array
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_diag_array IN table_table_varchar,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_count PLS_INTEGER;
        l_var   PLS_INTEGER;
    
    BEGIN
    
        g_error := 'Init check_diag_array';
        l_count := i_diag_array.count;
    
        IF l_count > 0
        THEN
            <<loop_l_count>>
            FOR j IN 1 .. l_count
            LOOP
            
                IF i_diag_array(j) IS NOT NULL
                THEN
                    g_error := 'i_diag_array not null';
                    IF i_diag_array(j).exists(1) --IS NOT NULL
                        AND i_diag_array(j).exists(2) -- IS NOT NULL
                    -- AND i_diag_array(j).COUNT = 4
                    -- AND i_diag_array(j).EXISTS(3) -- ACM, 2009-10-16: diagnosis description ignored
                    THEN
                        g_error := 'SELECT COUNT(1) FROM diagnosis WHERE code_icd= ''' || i_diag_array(j)
                                   (2) || ''' AND flg_type=''' || i_diag_array(j) (1) || '''';
                    
                        SELECT COUNT(1)
                          INTO l_var
                          FROM (SELECT DISTINCT id_diagnosis
                                  FROM diagnosis_content d
                                 WHERE d.code_icd = i_diag_array(j) (2)
                                   AND d.flg_type = i_diag_array(j) (1));
                    
                        IF l_var != 1
                        THEN
                            g_error := 'ERROR: ' || g_error;
                            RAISE g_exception;
                        END IF;
                    
                        g_error := 'i_diag_array is null';
                    ELSIF i_diag_array(j) (1) IS NULL
                          OR i_diag_array(j) (2) IS NULL
                    -- OR i_diag_array(j) (3) IS NULL -- ACM, 2009-10-16: diagnosis description ignored
                    -- OR i_diag_array(j) (4) IS NULL -- ACM, 2009-10-16: diagnosis notes not supported
                    THEN
                        g_error := 'ERROR: ' || g_error;
                        RAISE g_exception;
                    END IF;
                
                END IF;
            END LOOP;
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
                                              i_function => 'CHECK_DIAG_ARRAY',
                                              o_error    => o_error);
            RETURN FALSE;
    END check_diag_array;

    /**
    * Checks if the array of answer is valid 
    *
    * @param   i_lang                  Language associated to the professional executing the request
    * @param   i_prof                  Id professional, institution and software    
    * @param   i_answer_array          Array of diagnosis (answer, notes) 
    * @param   o_error                 An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   07-10-2009
    */
    FUNCTION check_answer_array
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_answer_array IN table_table_varchar,
        o_error        OUT t_error_out
        
    ) RETURN BOOLEAN IS
        l_count PLS_INTEGER;
    BEGIN
    
        g_error := 'Init check_answer_array';
        l_count := i_answer_array.count;
    
        IF l_count > 0
        THEN
        
            <<loop_l_count>>
            FOR j IN 1 .. l_count
            LOOP
                IF i_answer_array(j) IS NOT NULL
                THEN
                
                    g_error := 'i_answer_array(' || j || ')(1)= ' || i_answer_array(j) (1);
                    IF i_answer_array(j).exists(1)
                        AND (i_answer_array(j) (1) IS NULL OR i_answer_array(j)
                             (1) NOT IN (pk_ref_constant.g_ref_answer_o,
                                         pk_ref_constant.g_ref_answer_t,
                                         pk_ref_constant.g_ref_answer_e,
                                         pk_ref_constant.g_ref_answer_c))
                    THEN
                        g_error := 'ERROR: ' || g_error;
                        RAISE g_exception;
                    END IF;
                
                    g_error := 'i_answer_array(' || j || ')(2) IS NULL';
                    IF i_answer_array(j).exists(2)
                        AND i_answer_array(j) (2) IS NULL
                    THEN
                        g_error := 'ERROR: ' || g_error;
                        RAISE g_exception;
                    END IF;
                
                END IF;
            
            END LOOP;
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
                                              i_function => 'CHECK_ANSWER_ARRAY',
                                              o_error    => o_error);
            RETURN FALSE;
    END check_answer_array;

    /**
    * Converting diagnosis information into an array of id_diagnosis
    *
    * @param   i_lang                  Language associated to the professional executing the request
    * @param   i_prof                  Id professional, institution and software    
    * @param   i_diag_array            Diagnosis information [i_diag_flg_type|i_diag_code|i_diag_desc|i_diag_notes]
    * @param   o_diag_array            Array of id_diagnosis  
    * @param   o_error                 An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   07-10-2009
    */
    FUNCTION create_diag_array
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_diag_array IN table_table_varchar,
        o_diag_array OUT table_number,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_count   PLS_INTEGER;
        l_diag_id PLS_INTEGER;
    BEGIN
    
        g_error      := 'Init create_diag_array';
        o_diag_array := table_number();
        l_count      := i_diag_array.count;
        o_diag_array.extend(l_count);
    
        <<loop_count>>
        FOR i IN 1 .. l_count
        LOOP
        
            g_error := 'i_diag_array(i).EXISTS()';
            IF i_diag_array(i).exists(1)
                AND i_diag_array(i).exists(2)
            THEN
                g_error := 'SELECT id_diagnosis FROM diagnosis  WHERE d.code_icd = ' || i_diag_array(i)
                           (2) || ' AND d.flg_available = ' || pk_ref_constant.g_yes || ' AND d.flg_type = ' ||
                           i_diag_array(i) (1);
                SELECT DISTINCT id_diagnosis
                  INTO l_diag_id -- bulk collect into l_diag_id
                  FROM diagnosis_content d
                -- join table (cast (l_icd_code as table_varchar)) tt on (d.code_icd = tt.column_value)
                -- join table (cast (l_flg as table_varchar)) tt on (d.flg_type = tt.column_value)
                 WHERE d.flg_type = i_diag_array(i) (1)
                   AND d.code_icd = i_diag_array(i) (2);
            
                o_diag_array(i) := l_diag_id;
            END IF;
        END LOOP;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'CREATE_DIAG_ARRAY',
                                              o_error    => o_error);
            RETURN FALSE;
    END create_diag_array;

    /**
    * Maps detail input data into an array of details expected by PK_REF_ORIG_PHY.create_referral 
    *
    * @param   i_lang             Language associated to the professional executing the request
    * @param   i_prof             Id professional, institution and software    
    * @param   i_id_ref           Referral identifier    
    * @param   i_detail           Input detail array [idx,[flg_type,text]]
    * @param   o_detail_array     Output detail array [idx,[id_detail,flg_type,text,flg_op,id_group]]
    * @param   o_error            An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.6.0.5
    * @since   17-02-2011
    */
    FUNCTION map_detail_array
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_ref       IN p1_external_request.id_external_request%TYPE,
        i_detail       IN table_table_varchar,
        o_detail_array OUT table_table_varchar,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_array table_varchar;
    
        l_id_group     p1_detail.id_group%TYPE;
        l_id_group_max p1_detail.id_group%TYPE;
        l_id_group_1   p1_detail.id_group%TYPE;
        l_id_group_2   p1_detail.id_group%TYPE;
    
    BEGIN
        g_error := 'map_detail_array / i_id_ref=' || i_id_ref || ' i_detail.count=' || i_detail.count;
        reset_vars;
        o_detail_array := table_table_varchar();
        o_detail_array.extend(i_detail.count);
    
        -- getting the last id_group
        IF i_id_ref IS NOT NULL
        THEN
            SELECT MAX(id_group)
              INTO l_id_group_max
              FROM p1_detail
             WHERE id_external_request = i_id_ref;
        
        END IF;
    
        l_id_group_max := nvl(l_id_group_max, 0);
    
        FOR i IN 1 .. i_detail.count
        LOOP
        
            -------------------------------
            -- getting id_group
            -- this algorithm is the same as used in flash (replicated!!!)
        
            l_id_group := NULL;
        
            CASE -- flg_type
                WHEN i_detail(i) (1) IN (pk_ref_constant.g_detail_type_sntm, pk_ref_constant.g_detail_type_evlt) THEN
                
                    -- this is done because types 'Signs and symptoms' and 'Progress' must have the same id_group
                    IF l_id_group_1 IS NOT NULL
                    THEN
                        l_id_group := l_id_group_1;
                    ELSE
                        l_id_group     := l_id_group_max + 1;
                        l_id_group_max := l_id_group;
                    END IF;
                
                    l_id_group_1 := l_id_group;
                
                WHEN i_detail(i) (1) IN (pk_ref_constant.g_detail_type_hstr, pk_ref_constant.g_detail_type_hstf) THEN
                
                    -- this is done because types 'History' and 'Family history' must have the same id_group
                    IF l_id_group_2 IS NOT NULL
                    THEN
                        l_id_group := l_id_group_2;
                    ELSE
                        l_id_group     := l_id_group_max + 1;
                        l_id_group_max := l_id_group;
                    END IF;
                
                    l_id_group_2 := l_id_group;
                ELSE
                    -- all other detail types must have a different id_group
                    l_id_group     := l_id_group_max + 1;
                    l_id_group_max := l_id_group;
            END CASE;
        
            -- getting id_group
            -------------------------------
        
            l_array := table_varchar(NULL, i_detail(i) (1), i_detail(i) (2), pk_ref_constant.g_detail_flg_i, l_id_group);
            o_detail_array(i) := l_array;
        
        END LOOP;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            BEGIN
                IF g_error_code IS NOT NULL
                THEN
                    g_flg_action := pk_ref_constant.g_err_flg_action_u; -- user defined error
                ELSE
                    g_error_code := SQLCODE;
                    g_error_desc := SQLERRM;
                    g_flg_action := pk_ref_constant.g_err_flg_action_s; -- system error
                END IF;
                pk_alert_exceptions.process_error(i_lang        => i_lang,
                                                  i_sqlcode     => g_error_code,
                                                  i_sqlerrm     => g_error_desc,
                                                  i_message     => g_error,
                                                  i_owner       => g_package_owner,
                                                  i_package     => g_package_name,
                                                  i_function    => 'MAP_DETAIL_ARRAY',
                                                  i_action_type => g_flg_action,
                                                  i_action_msg  => NULL,
                                                  o_error       => o_error);
                RETURN FALSE;
            END;
    END map_detail_array;

    /**
    * Set the referral status to 'T' (Waiting for triage)
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Id professional, institution and software    
    * @param   i_id_ref         Referral identifier
    * @param   i_clin_rec       Patient process number on the institution, if available.    
    * @param   i_notes          Notes to the triage physician    
    * @param   i_date           Operation date
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   30-09-2009
    */
    FUNCTION set_ref_sent_triage
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_ref   IN p1_external_request.id_external_request%TYPE,
        i_clin_rec IN clin_record.num_clin_record%TYPE,
        i_notes    IN p1_detail.text%TYPE,
        i_date     IN DATE,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_params       VARCHAR2(1000 CHAR);
        l_prof         profissional;
        l_flg_valid    VARCHAR2(1 CHAR);
        l_id_cr        clin_record.id_clin_record%TYPE;
        l_flg_show     VARCHAR2(1 CHAR);
        l_msg_title    VARCHAR2(1000 CHAR);
        l_msg          VARCHAR2(1000 CHAR);
        l_ref_row      p1_external_request%ROWTYPE;
        l_config       p1_workflow_config.value%TYPE;
        l_track        table_number;
        l_id_inst_dest p1_external_request.id_inst_dest%TYPE;
    BEGIN
    
        ----------------------
        -- INIT
        ----------------------
        -- referral status is changed from (I)ssued to waiting for (T)riage
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_id_ref=' || i_id_ref || ' i_clin_rec=' || i_clin_rec ||
                    ' i_date=' || i_date;
        g_error  := '->Init set_ref_sent_triage / ' || l_params;
        pk_alertlog.log_debug(g_error);
        reset_vars;
        g_prof_int := pk_p1_interface.set_prof_interface(i_prof);
        l_track    := table_number();
    
        -- sets the referral context
        pk_ref_utils.init_ref_context;
        pk_ref_utils.set_ref_context(i_id_external_request => i_id_ref, i_dt_system_date => current_timestamp);
    
        -- getting operation date
        g_error  := 'Call get_operation_date / ' || l_params;
        g_retval := get_operation_date(i_lang    => i_lang,
                                       i_prof    => i_prof,
                                       i_dt_d    => i_date,
                                       o_dt_tstz => g_sysdate_tstz,
                                       o_error   => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        ----------------------
        -- VAL
        ----------------------
        -- validating parameters
    
        -- check if professional is at dest institution
        g_error  := 'Call pk_p1_external_request.get_id_inst_dest / ' || l_params;
        g_retval := pk_p1_external_request.get_id_inst_dest(i_lang         => i_lang,
                                                            i_prof         => i_prof,
                                                            i_id_ref       => i_id_ref,
                                                            o_id_inst_dest => l_id_inst_dest,
                                                            o_error        => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        g_error  := 'Call check_requirements / ' || l_params;
        g_retval := check_requirements(i_lang      => i_lang,
                                       i_prof      => g_prof_int,
                                       i_id_ref    => i_id_ref,
                                       i_id_inst   => l_id_inst_dest,
                                       i_date      => g_sysdate_tstz,
                                       o_flg_valid => l_flg_valid,
                                       o_prof      => l_prof,
                                       o_error     => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        IF l_flg_valid = pk_ref_constant.g_no
        THEN
            g_error := 'INVALID PARAMETERS / ' || l_params;
            RAISE g_exception;
        END IF;
    
        ----------------------
        -- FUNC
        ----------------------         
        --  getting referral row 
        g_error  := 'Call pk_p1_external_request.get_ref_row / ' || l_params;
        g_retval := pk_p1_external_request.get_ref_row(i_lang   => i_lang,
                                                       i_prof   => g_prof_int,
                                                       i_id_ref => i_id_ref,
                                                       o_rec    => l_ref_row,
                                                       o_error  => o_error);
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        IF i_clin_rec IS NOT NULL
        THEN
            -- Inserting/updating patient clinical record        
            g_error  := 'Call pk_ref_dest_reg.set_clin_record / ID_PATIENT=' || l_ref_row.id_patient || ' / ' ||
                        l_params;
            g_retval := pk_ref_dest_reg.set_clin_record(i_lang         => i_lang,
                                                        i_prof         => g_prof_int,
                                                        i_pat          => l_ref_row.id_patient,
                                                        i_num_clin_rec => i_clin_rec,
                                                        i_epis         => NULL,
                                                        o_id_clin_rec  => l_id_cr,
                                                        o_error        => o_error);
        
            IF NOT g_retval
            THEN
                RAISE g_exception_np;
            END IF;
        END IF;
    
        -- setting referral status to 'T'         
        IF l_ref_row.id_workflow IS NULL
        THEN
            g_error  := 'Call pk_p1_adm_hs.set_status_internal / STATUS=' || pk_ref_constant.g_p1_status_t || ' / ' ||
                        l_params;
            g_retval := pk_p1_adm_hs.set_status_internal(i_lang        => i_lang,
                                                         i_prof        => g_prof_int,
                                                         i_ext_req     => i_id_ref,
                                                         i_status      => pk_ref_constant.g_p1_status_t,
                                                         i_notes       => i_notes,
                                                         i_reason_code => NULL,
                                                         i_dcs         => NULL,
                                                         i_date        => g_sysdate_tstz,
                                                         o_track       => l_track,
                                                         o_error       => o_error);
        
        ELSE
        
            g_error  := 'Call pk_ref_core.set_status / STATUS=' || pk_ref_constant.g_p1_status_t || ' ACTION=' ||
                        pk_ref_constant.g_ref_action_t || ' / ' || l_params;
            g_retval := pk_ref_core.set_status2(i_lang         => i_lang,
                                                i_prof         => g_prof_int,
                                                i_ext_req      => i_id_ref,
                                                i_status_begin => NULL, -- deprecated
                                                i_status_end   => pk_ref_constant.g_p1_status_t, -- deprecated
                                                i_action       => pk_ref_constant.g_ref_action_t, -- TRIAGE
                                                i_level        => NULL,
                                                i_prof_dest    => NULL,
                                                i_dcs          => NULL,
                                                i_notes        => i_notes,
                                                i_dt_modified  => NULL,
                                                i_mode         => NULL,
                                                i_reason_code  => NULL,
                                                i_subtype      => NULL,
                                                i_inst_dest    => NULL,
                                                i_date         => g_sysdate_tstz,
                                                o_track        => l_track,
                                                o_flg_show     => l_flg_show,
                                                o_msg_title    => l_msg_title,
                                                o_msg          => l_msg,
                                                o_error        => o_error);
        END IF;
    
        IF NOT g_retval
        THEN
            g_error  := 'Call pk_ref_core.get_workflow_config / CODE_PARAM=' || pk_ref_constant.g_adm_required ||
                        ' ID_SPECIALITY=' || l_ref_row.id_speciality || ' ID_INST_DEST=' || l_ref_row.id_inst_dest ||
                        ' ID_INST_ORIG=' || l_ref_row.id_inst_orig || ' ID_WORKFLOW=' || l_ref_row.id_workflow || ' / ' ||
                        l_params;
            l_config := pk_ref_core.get_workflow_config(i_prof       => g_prof_int,
                                                        i_code_param => pk_ref_constant.g_adm_required,
                                                        i_speciality => l_ref_row.id_speciality,
                                                        i_inst_dest  => l_ref_row.id_inst_dest,
                                                        i_inst_orig  => l_ref_row.id_inst_orig,
                                                        i_workflow   => l_ref_row.id_workflow);
            -- validate configuration and error returned
            IF o_error.ora_sqlcode = pk_ref_constant.g_ref_error_1008
               AND l_config = pk_ref_constant.g_no
               AND l_ref_row.flg_status = pk_ref_constant.g_p1_status_t -- initial referral status
            THEN
                -- If the patient has match in this institution then the referral has already gone to triage
                o_error := NULL; -- cleans error variable
            ELSE
                RAISE g_exception_np;
            END IF;
        END IF;
    
        -- resets the referral context
        pk_ref_utils.reset_ref_context;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'SET_REF_SENT_TRIAGE',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END set_ref_sent_triage;

    /**
    * Triages the referral request: set referral status to 'A' (Appointment to be scheduled)
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Id professional, institution and software    
    * @param   i_id_ref         Referral identifier
    * @param   i_clin_rec       Patient process number on the institution, if available.
    * @param   i_num_order      Professional order number that is triaging the referral
    * @param   i_prof_name      Professional name that is triaging the referral   
    * @param   i_level          Triage urgency level        
    * @param   i_notes          Triage decision notes    
    * @param   i_dcs            Department + Service            
    * @param   i_date           Operation date
    * @param   o_track          Tracking identifiers created due to the status change
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   01-10-2009
    */
    FUNCTION set_ref_triaged
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_ref    IN p1_external_request.id_external_request%TYPE,
        i_clin_rec  IN clin_record.num_clin_record%TYPE,
        i_num_order IN professional.num_order%TYPE,
        i_prof_name IN professional.name%TYPE,
        i_level     IN p1_external_request.decision_urg_level%TYPE,
        i_notes     IN p1_detail.text%TYPE,
        i_dcs       IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_date      IN DATE,
        o_track     OUT table_number,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_params              VARCHAR2(1000 CHAR);
        l_prof                profissional;
        l_flg_valid           VARCHAR2(1 CHAR);
        l_flg_show            VARCHAR2(1 CHAR);
        l_msg_title           VARCHAR2(1000 CHAR);
        l_msg                 VARCHAR2(1000 CHAR);
        l_id_cr               clin_record.id_clin_record%TYPE;
        l_id_patient          p1_external_request.id_patient%TYPE;
        l_id_workflow         p1_external_request.id_workflow%TYPE;
        l_id_profile_template profile_template.id_profile_template%TYPE;
        l_id_inst_dest        p1_external_request.id_inst_dest%TYPE;
    BEGIN
    
        ----------------------
        -- INIT
        ----------------------
        -- referral status is changed from (I)ssued to waiting for (T)riage        
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_id_ref=' || i_id_ref || ' i_clin_rec=' || i_clin_rec ||
                    ' i_num_order=' || i_num_order || ' substr(1,i_prof_name,100)=' || substr(i_prof_name, 1, 100) ||
                    ' i_level=' || i_level || ' i_dcs=' || i_dcs || ' i_date=' || i_date;
        g_error  := '->Init set_ref_triaged / ' || l_params;
        pk_alertlog.log_debug(g_error);
        reset_vars;
        g_prof_int := pk_p1_interface.set_prof_interface(i_prof);
        o_track    := table_number();
    
        -- sets the referral context
        pk_ref_utils.init_ref_context;
        pk_ref_utils.set_ref_context(i_id_external_request => i_id_ref, i_dt_system_date => current_timestamp);
    
        -- getting operation date
        g_error  := 'Call get_operation_date / ' || l_params;
        g_retval := get_operation_date(i_lang    => i_lang,
                                       i_prof    => i_prof,
                                       i_dt_d    => i_date,
                                       o_dt_tstz => g_sysdate_tstz,
                                       o_error   => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        ----------------------
        -- VAL
        ----------------------
        -- mandatory parameters
        g_error := 'Validating mandatory parameters / ' || l_params;
        IF i_level IS NULL
           OR i_num_order IS NULL
           OR i_dcs IS NULL
        THEN
            g_error := 'Invalid parameter / ' || l_params;
            RAISE g_exception;
        END IF;
    
        g_error  := 'Call get_profile_template_inst / ' || l_params;
        g_retval := get_profile_template_inst(i_lang             => i_lang,
                                              i_prof             => i_prof,
                                              i_id_institution   => g_prof_int.institution,
                                              i_id_category      => pk_ref_constant.g_cat_id_med,
                                              o_profile_template => l_id_profile_template,
                                              o_error            => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- check if professional is at dest institution
        g_error  := 'Call pk_p1_external_request.get_id_inst_dest / ' || l_params;
        g_retval := pk_p1_external_request.get_id_inst_dest(i_lang         => i_lang,
                                                            i_prof         => i_prof,
                                                            i_id_ref       => i_id_ref,
                                                            o_id_inst_dest => l_id_inst_dest,
                                                            o_error        => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- validating parameters
        g_error  := 'Call check_requirements / ' || l_params;
        g_retval := check_requirements(i_lang          => i_lang,
                                       i_prof          => g_prof_int,
                                       i_id_ref        => i_id_ref,
                                       i_id_inst       => l_id_inst_dest,
                                       i_num_order     => i_num_order,
                                       i_prof_name     => i_prof_name,
                                       i_profile_templ => l_id_profile_template,
                                       i_func          => pk_ref_constant.g_func_d,
                                       i_level         => i_level,
                                       i_dcs           => i_dcs,
                                       i_date          => g_sysdate_tstz,
                                       o_flg_valid     => l_flg_valid,
                                       o_prof          => l_prof, -- professional that has triaged the referral
                                       o_error         => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        IF l_flg_valid = pk_ref_constant.g_no
        THEN
            g_error := 'INVALID PARAMETERS / ' || l_params;
            RAISE g_exception;
        END IF;
    
        ----------------------
        -- FUNC
        ----------------------     
    
        IF i_clin_rec IS NOT NULL
        THEN
        
            -- Inserting/updating patient clinical record        
            g_error  := 'Call pk_p1_external_request.get_id_patient / ' || l_params;
            g_retval := pk_p1_external_request.get_id_patient(i_lang       => i_lang,
                                                              i_prof       => g_prof_int,
                                                              i_id_ref     => i_id_ref,
                                                              o_id_patient => l_id_patient,
                                                              o_error      => o_error);
        
            IF NOT g_retval
            THEN
                RAISE g_exception_np;
            END IF;
        
            g_error  := 'Call pk_ref_dest_reg.set_clin_record / ID_PATIENT=' || l_id_patient || ' / ' || l_params;
            g_retval := pk_ref_dest_reg.set_clin_record(i_lang         => i_lang,
                                                        i_prof         => g_prof_int,
                                                        i_pat          => l_id_patient,
                                                        i_num_clin_rec => i_clin_rec,
                                                        i_epis         => NULL,
                                                        o_id_clin_rec  => l_id_cr,
                                                        o_error        => o_error);
        
            IF NOT g_retval
            THEN
                RAISE g_exception_np;
            END IF;
        END IF;
    
        -- check for workflow id
        g_error  := 'Call pk_p1_external_request.get_id_workflow / ' || l_params;
        g_retval := pk_p1_external_request.get_id_workflow(i_lang        => i_lang,
                                                           i_prof        => i_prof,
                                                           i_id_ref      => i_id_ref,
                                                           o_id_workflow => l_id_workflow,
                                                           o_error       => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- setting referral status to 'A'
        IF l_id_workflow IS NULL
        THEN
            g_error  := 'Call pk_p1_med_hs.set_status_internal / ' || l_params;
            g_retval := pk_p1_med_hs.set_status_internal(i_lang          => i_lang,
                                                         i_prof          => l_prof, -- professional that triaged the referral
                                                         i_id_p1         => i_id_ref,
                                                         i_action        => pk_ref_constant.g_ref_action_a,
                                                         i_level         => i_level,
                                                         i_prof_dest     => NULL,
                                                         i_dep_clin_serv => i_dcs,
                                                         i_notes         => i_notes,
                                                         i_dt_modified   => NULL,
                                                         i_mode          => NULL,
                                                         i_reason_code   => NULL,
                                                         i_subtype       => NULL,
                                                         i_inst_dest     => NULL,
                                                         i_date          => g_sysdate_tstz,
                                                         o_track         => o_track,
                                                         o_flg_show      => l_flg_show,
                                                         o_msg_title     => l_msg_title,
                                                         o_msg           => l_msg,
                                                         o_error         => o_error);
        
        ELSE
        
            -- setting referral status to 'A' 
            g_error  := 'Call PK_REF_CORE.set_status / STATUS=' || pk_ref_constant.g_p1_status_a || ' ACTION=' ||
                        pk_ref_constant.g_ref_action_a || ' / ' || l_params;
            g_retval := pk_ref_core.set_status2(i_lang         => i_lang,
                                                i_prof         => l_prof, -- professional that triaged the referral
                                                i_ext_req      => i_id_ref,
                                                i_status_begin => NULL, -- deprecated
                                                i_status_end   => pk_ref_constant.g_p1_status_a, -- deprecated
                                                i_action       => pk_ref_constant.g_ref_action_a, -- ACCEPTED
                                                i_level        => i_level,
                                                i_prof_dest    => NULL,
                                                i_dcs          => i_dcs,
                                                i_notes        => i_notes,
                                                i_dt_modified  => NULL,
                                                i_mode         => NULL,
                                                i_reason_code  => NULL,
                                                i_subtype      => NULL,
                                                i_inst_dest    => NULL,
                                                i_date         => g_sysdate_tstz,
                                                o_track        => o_track,
                                                o_flg_show     => l_flg_show,
                                                o_msg_title    => l_msg_title,
                                                o_msg          => l_msg,
                                                o_error        => o_error);
        END IF;
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- resets the referral context
        pk_ref_utils.reset_ref_context;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
        
            IF g_error_code IS NOT NULL
            THEN
                g_flg_action := pk_ref_constant.g_err_flg_action_u; -- user defined error
            ELSE
                g_error_code := SQLCODE;
                g_error_desc := SQLERRM;
                g_flg_action := pk_ref_constant.g_err_flg_action_s; -- system error
            END IF;
            pk_alert_exceptions.process_error(i_lang        => i_lang,
                                              i_sqlcode     => g_error_code,
                                              i_sqlerrm     => g_error_desc,
                                              i_message     => g_error,
                                              i_owner       => g_package_owner,
                                              i_package     => g_package_name,
                                              i_function    => 'SET_REF_TRIAGED',
                                              i_action_type => g_flg_action,
                                              i_action_msg  => NULL,
                                              o_error       => o_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END set_ref_triaged;

    /**
    * Schedules a referral appointment. Set the referral status to 'S' (Scheduled, Patient to be notified)
    * Transaction identifier available to be defined.
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Id professional, institution and software    
    * @param   i_id_ref         Referral identifier
    * @param   i_num_order      Professional order number who will provide consultation
    * @param   i_prof_name      Professional name who will provide consultation   
    * @param   i_dt_appointment Appointment date    
    * @param   i_date           Operation date
    * @param   i_transaction_id SCH 3.0 Transaction id 
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   02-10-2009
    */
    FUNCTION set_ref_scheduled
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_ref         IN p1_external_request.id_external_request%TYPE,
        i_num_order      IN professional.num_order%TYPE,
        i_prof_name      IN professional.name%TYPE,
        i_dt_appointment IN DATE,
        i_date           IN DATE,
        i_transaction_id IN VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_params              VARCHAR2(1000 CHAR);
        l_dt_appointment_v    VARCHAR2(50 CHAR);
        l_flg_valid           VARCHAR2(1 CHAR);
        l_prof                profissional;
        l_num_order           professional.num_order%TYPE;
        l_dt_appointment_tstz schedule.dt_begin_tstz%TYPE;
        l_transaction_id      VARCHAR2(1000 CHAR);
        l_id_profile_template profile_template.id_profile_template%TYPE;
        l_id_prof             professional.id_professional%TYPE;
        l_dcs                 p1_external_request.id_dep_clin_serv%TYPE;
        l_id_inst_dest        p1_external_request.id_inst_dest%TYPE;
    BEGIN
        ----------------------
        -- INIT
        ----------------------
        reset_vars;
        -- sets the referral context
        pk_ref_utils.init_ref_context;
        pk_ref_utils.set_ref_context(i_id_external_request => i_id_ref, i_dt_system_date => current_timestamp);
    
        -- get remote transaction for the new scheduler
        g_error          := 'START REMOTE TRANSACTION';
        l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(i_transaction_id, i_prof);
    
        l_params   := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_id_ref=' || i_id_ref || ' i_num_order=' ||
                      i_num_order || ' substr(i_prof_name,1,100)=' || substr(i_prof_name, 1, 100) ||
                      ' i_dt_appointment=' || i_dt_appointment || ' i_date=' || i_date;
        g_error    := '->Init set_ref_scheduled / ' || l_params;
        g_prof_int := pk_p1_interface.set_prof_interface(i_prof);
    
        ----------------------
        -- VAL
        ----------------------
        -- mandatory parameters
        g_error := 'Validating mandatory parameters / ' || l_params;
        IF i_dt_appointment IS NULL
        THEN
            -- i_num_order is not mandatory! Referral can be scheduled for dep_clin_serv
            g_error      := 'Invalid parameter / ' || l_params;
            g_error_code := pk_ref_constant.g_ref_error_1005;
            g_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => g_error_code);
            RAISE g_exception;
        END IF;
    
        -- getting operation date
        g_error  := 'Call get_operation_date / ' || l_params;
        g_retval := get_operation_date(i_lang    => i_lang,
                                       i_prof    => i_prof,
                                       i_dt_d    => i_date,
                                       o_dt_tstz => g_sysdate_tstz,
                                       o_error   => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- converting DATEs to VARCHARs
        g_error            := 'Converting DATEs to VARCHARs / ' || l_params;
        l_dt_appointment_v := to_char(i_dt_appointment, pk_ref_constant.g_format_date_2);
    
        g_error := 'DT_APPOINTMENT=' || l_dt_appointment_v || ' / ' || l_params;
    
        -- converting VARCHARs to TIMESTAMPS WITH LOCAL TIME ZONEs
        g_error               := 'Converting VARCHARs to TIMESTAMPS WITH LOCAL TIME ZONEs / ' || l_params;
        l_dt_appointment_tstz := pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                               i_prof      => i_prof,
                                                               i_timestamp => l_dt_appointment_v,
                                                               i_timezone  => NULL,
                                                               i_mask      => pk_ref_constant.g_format_date_2);
    
        g_error := 'Validating l_dt_appointment_tstz / l_dt_appointment_v=' || l_dt_appointment_v ||
                   ' l_dt_appointment_tstz=' || l_dt_appointment_tstz || ' / ' || l_params;
        IF l_dt_appointment_tstz IS NULL
        THEN
            g_error := 'Invalid appointment timestamp / l_dt_appointment_v=' || l_dt_appointment_v ||
                       ' l_dt_appointment_tstz=' || l_dt_appointment_tstz || ' / ' || l_params;
            RAISE g_exception;
        END IF;
    
        -- check if professional is at dest institution
        g_error  := 'Call pk_p1_external_request.get_id_inst_dest / ' || l_params;
        g_retval := pk_p1_external_request.get_id_inst_dest(i_lang         => i_lang,
                                                            i_prof         => i_prof,
                                                            i_id_ref       => i_id_ref,
                                                            o_id_inst_dest => l_id_inst_dest,
                                                            o_error        => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- validating parameters
        -- validate professional i_num_order below
        g_error  := 'Call check_requirements / ' || l_params;
        g_retval := check_requirements(i_lang      => i_lang,
                                       i_prof      => g_prof_int,
                                       i_id_ref    => i_id_ref,
                                       i_id_inst   => l_id_inst_dest,
                                       i_date      => g_sysdate_tstz,
                                       o_flg_valid => l_flg_valid,
                                       o_prof      => l_prof,
                                       o_error     => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        IF l_flg_valid = pk_ref_constant.g_no
        THEN
            RAISE g_exception;
        END IF;
    
        -- if referral is to be scheduled for dep_clin_serv, then num_order must be '0'
        g_error := 'NUM_ORDER=' || i_num_order || ' / ' || l_params;
        IF i_num_order IS NULL
        THEN
            l_num_order := '0';
        ELSE
            l_num_order := i_num_order;
        
            -- validate professional
            g_error  := 'Call get_profile_template_inst / ' || l_params;
            g_retval := get_profile_template_inst(i_lang             => i_lang,
                                                  i_prof             => g_prof_int,
                                                  i_id_institution   => g_prof_int.institution,
                                                  i_id_category      => pk_ref_constant.g_cat_id_med,
                                                  o_profile_template => l_id_profile_template,
                                                  o_error            => o_error);
        
            IF NOT g_retval
            THEN
                RAISE g_exception_np;
            END IF;
        
            g_error  := 'Call pk_p1_external_request.get_dep_clin_serv / ' || l_params;
            g_retval := pk_p1_external_request.get_dep_clin_serv(i_lang          => i_lang,
                                                                 i_id_ref        => i_id_ref,
                                                                 o_dep_clin_serv => l_dcs,
                                                                 o_error         => o_error);
        
            IF NOT g_retval
            THEN
                RAISE g_exception_np;
            END IF;
        
            -- professional to whom the referral is begin scheduled
            g_error  := 'Call check_professional / l_id_profile_template=' || l_id_profile_template || ' l_dcs=' ||
                        l_dcs || ' / ' || l_params;
            g_retval := check_professional(i_lang          => i_lang,
                                           i_prof          => g_prof_int,
                                           i_num_order     => l_num_order,
                                           i_prof_name     => i_prof_name,
                                           i_profile_templ => l_id_profile_template,
                                           i_func          => pk_ref_constant.g_func_c,
                                           i_dcs           => l_dcs,
                                           o_prof          => l_prof,
                                           o_error         => o_error);
        
            IF NOT g_retval
            THEN
                RAISE g_exception_np;
            END IF;
        END IF;
    
        l_params := l_params || ' l_num_order=' || l_num_order || ' l_dt_appointment_v=' || l_dt_appointment_v ||
                    ' OPERATION_DATE=' ||
                    pk_date_utils.to_char_insttimezone(g_prof_int, g_sysdate_tstz, pk_ref_constant.g_format_date_2);
    
        ----------------------
        -- FUNC
        ----------------------        
        g_error  := 'Call pk_p1_interface.setscheduling / ' || l_params;
        g_retval := pk_p1_interface.setscheduling(i_lang           => i_lang,
                                                  i_prof           => g_prof_int,
                                                  i_ext_req        => i_id_ref,
                                                  i_num_order      => l_num_order,
                                                  i_prof_name      => i_prof_name,
                                                  i_dcs            => NULL,
                                                  i_date_tstz      => l_dt_appointment_v,
                                                  i_op_date_tstz   => g_sysdate_tstz,
                                                  i_transaction_id => l_transaction_id,
                                                  o_error          => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        --only  if not started from external interfaces
        IF i_transaction_id IS NULL
        THEN
            pk_schedule_api_upstream.do_commit(l_transaction_id, i_prof);
        END IF;
    
        -- resets the referral context
        pk_ref_utils.reset_ref_context;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
        
            IF g_error_code IS NOT NULL
            THEN
                g_flg_action := pk_ref_constant.g_err_flg_action_u;
            ELSE
                g_error_code := SQLCODE;
                g_error_desc := SQLERRM;
                g_flg_action := pk_ref_constant.g_err_flg_action_s;
            END IF;
            pk_alert_exceptions.process_error(i_lang        => i_lang,
                                              i_sqlcode     => g_error_code,
                                              i_sqlerrm     => g_error_desc,
                                              i_message     => g_error,
                                              i_owner       => g_package_owner,
                                              i_package     => g_package_name,
                                              i_function    => 'SET_REF_SCHEDULED',
                                              i_action_type => g_flg_action,
                                              i_action_msg  => NULL,
                                              o_error       => o_error);
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        
    END set_ref_scheduled;

    /**
    * Schedules a referral appointment. Set the referral status to 'S' (Scheduled, Patient to be notified)
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Id professional, institution and software    
    * @param   i_id_ref         Referral identifier
    * @param   i_num_order      Professional order number who will provide consultation
    * @param   i_prof_name      Professional name who will provide consultation   
    * @param   i_dt_appointment Appointment date    
    * @param   i_date           Operation date 
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   02-10-2009
    */
    FUNCTION set_ref_scheduled
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_ref         IN p1_external_request.id_external_request%TYPE,
        i_num_order      IN professional.num_order%TYPE,
        i_prof_name      IN professional.name%TYPE,
        i_dt_appointment IN DATE,
        i_date           IN DATE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'Init set_ref_scheduled 2';
        RETURN set_ref_scheduled(i_lang           => i_lang,
                                 i_prof           => i_prof,
                                 i_id_ref         => i_id_ref,
                                 i_num_order      => i_num_order,
                                 i_prof_name      => i_prof_name,
                                 i_dt_appointment => i_dt_appointment,
                                 i_date           => i_date,
                                 i_transaction_id => NULL,
                                 o_error          => o_error);
    END set_ref_scheduled;

    /**
    * Cancels an appointment. Set the referral status to 'A' (Appointment to be scheduled)
    * Transaction identifier available to be defined.
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Id professional, institution and software    
    * @param   i_id_ref         Referral identifier    
    * @param   i_dt_appointment Active appointment date to be cancelled
    * @param   i_notes          Notes
    * @param   i_date           Operation date
    * @param   i_transaction_id SCH 3.0 Transaction ID 
    * @param   i_reason_code           Referral reason code    
    * @param   i_reason_desc    Decline reason description. Parameter ignored.      
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   02-10-2009
    */
    FUNCTION set_ref_cancel_sch
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_ref         IN p1_external_request.id_external_request%TYPE,
        i_dt_appointment IN DATE,
        i_notes          IN p1_detail.text%TYPE,
        i_date           IN DATE,
        i_transaction_id IN VARCHAR2,
        i_reason_code    IN p1_reason_code.id_reason_code%TYPE DEFAULT NULL,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_params           VARCHAR2(1000 CHAR);
        l_flg_valid        VARCHAR2(1 CHAR);
        l_prof             profissional;
        l_dt_appointment_v VARCHAR2(50 CHAR);
        l_transaction_id   VARCHAR2(1000 CHAR);
        l_id_inst_dest     p1_external_request.id_inst_dest%TYPE;
    BEGIN
        ----------------------
        -- INIT
        ----------------------        
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_id_ref=' || i_id_ref || ' i_dt_appointment=' ||
                    i_dt_appointment || ' i_date=' || i_date || ' i_reason_code=' || i_reason_code;
        g_error  := '->Init set_ref_cancel_sch / ' || l_params;
        pk_alertlog.log_debug(g_error);
        reset_vars;
        g_prof_int := pk_p1_interface.set_prof_interface(i_prof);
        -- sets the referral context
        pk_ref_utils.init_ref_context;
        pk_ref_utils.set_ref_context(i_id_external_request => i_id_ref, i_dt_system_date => current_timestamp);
    
        ----------------------
        -- VAL
        ----------------------
        -- mandatory parameters
        g_error := 'Validating mandatory parameters / ' || l_params;
        IF i_dt_appointment IS NULL
        THEN
            g_error      := 'Invalid parameter / ID_REFERRAL=' || i_id_ref || ' DT_APPOINTMENT= NULL / ' || l_params;
            g_error_code := pk_ref_constant.g_ref_error_1005;
            g_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => g_error_code);
            RAISE g_exception;
        END IF;
    
        -- getting operation date
        g_error  := 'Call get_operation_date / ' || l_params;
        g_retval := get_operation_date(i_lang    => i_lang,
                                       i_prof    => i_prof,
                                       i_dt_d    => i_date,
                                       o_dt_tstz => g_sysdate_tstz,
                                       o_error   => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- converting DATEs to VARCHARs
        g_error            := 'Converting DATEs to VARCHARs / ' || l_params;
        l_dt_appointment_v := to_char(i_dt_appointment, pk_ref_constant.g_format_date_2);
    
        l_params := l_params || ' DT_APPOINTMENT=' || l_dt_appointment_v;
    
        -- check if professional is at dest institution
        g_error  := 'Call pk_p1_external_request.get_id_inst_dest / ' || l_params;
        g_retval := pk_p1_external_request.get_id_inst_dest(i_lang         => i_lang,
                                                            i_prof         => i_prof,
                                                            i_id_ref       => i_id_ref,
                                                            o_id_inst_dest => l_id_inst_dest,
                                                            o_error        => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- validating parameters
        g_error  := 'Call check_requirements / ' || l_params;
        g_retval := check_requirements(i_lang        => i_lang,
                                       i_prof        => g_prof_int,
                                       i_id_ref      => i_id_ref,
                                       i_id_inst     => l_id_inst_dest,
                                       i_date        => g_sysdate_tstz,
                                       o_flg_valid   => l_flg_valid,
                                       i_reason_code => i_reason_code,
                                       i_reason_type => pk_ref_constant.g_reason_code_a,
                                       o_prof        => l_prof, -- ignored
                                       o_error       => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        IF l_flg_valid = pk_ref_constant.g_no
        THEN
            RAISE g_exception;
        END IF;
    
        ----------------------
        -- FUNC
        ----------------------         
    
        -- get remote transaction
        g_error          := 'START REMOTE TRANSACTION / ' || l_params;
        l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(i_transaction_id, i_prof);
    
        -- cancel the appointment
        g_error  := 'Call pk_p1_interface.cancelschedule / ' || l_params;
        g_retval := pk_p1_interface.cancelschedule(i_lang           => i_lang,
                                                   i_prof           => g_prof_int,
                                                   i_ext_req        => i_id_ref,
                                                   i_date_tstz      => l_dt_appointment_v,
                                                   i_notes          => i_notes,
                                                   i_op_date_tstz   => g_sysdate_tstz,
                                                   i_transaction_id => l_transaction_id,
                                                   i_reason_code    => i_reason_code,
                                                   o_error          => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        IF i_transaction_id IS NULL
        THEN
            pk_schedule_api_upstream.do_commit(l_transaction_id, i_prof);
        END IF;
    
        -- resets the referral context
        pk_ref_utils.reset_ref_context;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
        
            IF g_error_code IS NOT NULL
            THEN
                g_flg_action := pk_ref_constant.g_err_flg_action_u; -- user defined error
            ELSE
                g_error_code := SQLCODE;
                g_error_desc := SQLERRM;
                g_flg_action := pk_ref_constant.g_err_flg_action_s; -- system error
            END IF;
            pk_alert_exceptions.process_error(i_lang        => i_lang,
                                              i_sqlcode     => g_error_code,
                                              i_sqlerrm     => g_error_desc,
                                              i_message     => g_error,
                                              i_owner       => g_package_owner,
                                              i_package     => g_package_name,
                                              i_function    => 'SET_REF_CANCEL_SCH',
                                              i_action_type => g_flg_action,
                                              i_action_msg  => NULL,
                                              o_error       => o_error);
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        
    END set_ref_cancel_sch;

    /**
    * Cancels an appointment. Set the referral status to 'A' (Appointment to be scheduled)
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Id professional, institution and software    
    * @param   i_id_ref         Referral identifier    
    * @param   i_notes          Decision notes
    * @param   i_dt_appointment Active appointment date to be cancelled
    * @param   i_date           Operation date
    * @param   i_reason_code    Referral reason code    
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   02-10-2009
    */
    FUNCTION set_ref_cancel_sch
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_ref         IN p1_external_request.id_external_request%TYPE,
        i_dt_appointment IN DATE,
        i_notes          IN p1_detail.text%TYPE,
        i_date           IN DATE,
        i_reason_code    IN p1_reason_code.id_reason_code%TYPE DEFAULT NULL,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_error := 'Init set_ref_cancel_sch 2';
        RETURN set_ref_cancel_sch(i_lang           => i_lang,
                                  i_prof           => i_prof,
                                  i_id_ref         => i_id_ref,
                                  i_dt_appointment => i_dt_appointment,
                                  i_notes          => i_notes,
                                  i_date           => i_date,
                                  i_transaction_id => NULL,
                                  i_reason_code    => i_reason_code,
                                  o_error          => o_error);
    END set_ref_cancel_sch;

    /**
    * Refuses the referral, setting status to 'X' (REFUSE)
    *
    * @param   i_lang                Language associated to the professional executing the request
    * @param   i_prof                Id professional, institution and software    
    * @param   i_id_ref              Referral identifier
    * @param   i_num_order           Professional order number that is refusing the referral
    * @param   i_prof_name           Professional name that is refusing the referral           
    * @param   i_notes               Refusal notes                
    * @param   i_id_reason_code      Refusal reason code identifier
    * @param   i_desc_code_reason    Refusal reason code description. Parameter ignored.   
    * @param   i_date                Operation date
    * @param   o_track               Tracking identifiers created due to the status change
    * @param   o_error               An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   01-10-2009
    */
    FUNCTION set_ref_refused
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_ref           IN p1_external_request.id_external_request%TYPE,
        i_num_order        IN professional.num_order%TYPE,
        i_prof_name        IN professional.name%TYPE,
        i_notes            IN p1_detail.text%TYPE,
        i_id_reason_code   IN p1_reason_code.id_reason_code%TYPE,
        i_desc_code_reason IN p1_reason_code.code_reason%TYPE, -- ignored
        i_date             IN DATE,
        o_track            OUT table_number,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_params              VARCHAR2(1000 CHAR);
        l_flg_available       VARCHAR2(1 CHAR);
        l_flg_show            VARCHAR2(1000 CHAR);
        l_msg_title           VARCHAR2(1000 CHAR);
        l_msg                 VARCHAR2(1000 CHAR);
        l_prof                profissional; -- professional that has refused the referral            
        l_dcs                 dep_clin_serv.id_dep_clin_serv%TYPE;
        l_id_workflow         p1_external_request.id_workflow%TYPE;
        l_id_profile_template profile_template.id_profile_template%TYPE;
        l_id_inst_dest        p1_external_request.id_inst_dest%TYPE;
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_id_ref=' || i_id_ref || ' i_num_order=' ||
                    i_num_order || ' substr(i_prof_name,1,100)=' || substr(i_prof_name, 1, 100) || ' i_id_reason_code=' ||
                    i_id_reason_code || ' i_date=' || i_date;
        g_error  := '->Init set_ref_refused / ' || l_params;
        pk_alertlog.log_debug(g_error);
        reset_vars;
        g_prof_int := pk_p1_interface.set_prof_interface(i_prof);
        o_track    := table_number();
    
        -- sets the referral context
        pk_ref_utils.init_ref_context;
        pk_ref_utils.set_ref_context(i_id_external_request => i_id_ref, i_dt_system_date => current_timestamp);
    
        -- mandatory parameters   
        g_error := 'Validating mandatory parameters / ' || l_params;
        IF i_num_order IS NULL
           OR i_id_reason_code IS NULL
        THEN
            g_error      := 'Invalid parameter / ' || l_params;
            g_error_code := pk_ref_constant.g_ref_error_1005;
            g_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => g_error_code);
            RAISE g_exception;
        END IF;
    
        -- getting operation date
        g_error  := 'Call get_operation_date / ' || l_params;
        g_retval := get_operation_date(i_lang    => i_lang,
                                       i_prof    => i_prof,
                                       i_dt_d    => i_date,
                                       o_dt_tstz => g_sysdate_tstz,
                                       o_error   => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        g_error  := 'Call pk_p1_external_request.get_dep_clin_serv / ' || l_params;
        g_retval := pk_p1_external_request.get_dep_clin_serv(i_lang          => i_lang,
                                                             i_id_ref        => i_id_ref,
                                                             o_dep_clin_serv => l_dcs,
                                                             o_error         => o_error);
    
        g_error  := 'Call get_profile_template_inst / ' || l_params;
        g_retval := get_profile_template_inst(i_lang             => i_lang,
                                              i_prof             => i_prof,
                                              i_id_institution   => g_prof_int.institution,
                                              i_id_category      => pk_ref_constant.g_cat_id_med,
                                              o_profile_template => l_id_profile_template,
                                              o_error            => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- check if professional is at dest institution
        g_error  := 'Call pk_p1_external_request.get_id_inst_dest / ' || l_params;
        g_retval := pk_p1_external_request.get_id_inst_dest(i_lang         => i_lang,
                                                            i_prof         => i_prof,
                                                            i_id_ref       => i_id_ref,
                                                            o_id_inst_dest => l_id_inst_dest,
                                                            o_error        => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- validating parameters
        g_error  := 'Call check_requirements / ' || l_params;
        g_retval := check_requirements(i_lang          => i_lang,
                                       i_prof          => g_prof_int,
                                       i_num_order     => i_num_order,
                                       i_prof_name     => i_prof_name,
                                       i_profile_templ => l_id_profile_template,
                                       i_func          => pk_ref_constant.g_func_d,
                                       i_dcs           => l_dcs, -- to update professional info
                                       i_id_ref        => i_id_ref,
                                       i_id_inst       => l_id_inst_dest,
                                       i_date          => g_sysdate_tstz,
                                       i_reason_code   => i_id_reason_code,
                                       i_reason_type   => pk_ref_constant.g_reason_code_x,
                                       o_flg_valid     => l_flg_available,
                                       o_prof          => l_prof,
                                       o_error         => o_error);
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        IF l_flg_available = pk_ref_constant.g_no
        THEN
            RAISE g_exception;
        END IF;
    
        -- check for workflow id
        g_error  := 'Call pk_p1_external_request.get_id_workflow / ' || l_params;
        g_retval := pk_p1_external_request.get_id_workflow(i_lang        => i_lang,
                                                           i_prof        => l_prof,
                                                           i_id_ref      => i_id_ref,
                                                           o_id_workflow => l_id_workflow,
                                                           o_error       => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- setting referral status to 'T'         
        IF l_id_workflow IS NULL
        THEN
            g_error  := 'Call PK_P1_MED_HS.SET_STATUS_INTERNAL / STATUS=' || pk_ref_constant.g_p1_status_x || ' / ' ||
                        l_params;
            g_retval := pk_p1_med_hs.set_status_internal(i_lang          => i_lang,
                                                         i_prof          => l_prof, -- professional that has refused the referral
                                                         i_id_p1         => i_id_ref,
                                                         i_action        => pk_ref_constant.g_ref_action_x,
                                                         i_level         => NULL,
                                                         i_prof_dest     => NULL,
                                                         i_dep_clin_serv => NULL,
                                                         i_notes         => i_notes,
                                                         i_dt_modified   => NULL,
                                                         i_mode          => NULL,
                                                         i_reason_code   => i_id_reason_code,
                                                         i_subtype       => NULL,
                                                         i_inst_dest     => NULL,
                                                         i_date          => g_sysdate_tstz,
                                                         o_track         => o_track,
                                                         o_flg_show      => l_flg_show,
                                                         o_msg_title     => l_msg_title,
                                                         o_msg           => l_msg,
                                                         o_error         => o_error);
        ELSE
        
            g_error  := 'Call pk_ref_core.set_status / STATUS=' || pk_ref_constant.g_p1_status_x || ' ACTION=' ||
                        pk_ref_constant.g_ref_action_x || ' / ' || l_params;
            g_retval := pk_ref_core.set_status2(i_lang         => i_lang,
                                                i_prof         => l_prof, -- professional that has refused the referral
                                                i_ext_req      => i_id_ref,
                                                i_status_begin => NULL, -- deprecated
                                                i_status_end   => pk_ref_constant.g_p1_status_x, -- deprecated
                                                i_action       => pk_ref_constant.g_ref_action_x, -- REFUSE
                                                i_level        => NULL,
                                                i_prof_dest    => NULL,
                                                i_dcs          => l_dcs,
                                                i_notes        => i_notes,
                                                i_dt_modified  => NULL,
                                                i_mode         => NULL,
                                                i_reason_code  => i_id_reason_code,
                                                i_subtype      => NULL,
                                                i_inst_dest    => NULL,
                                                i_date         => g_sysdate_tstz,
                                                o_track        => o_track,
                                                o_flg_show     => l_flg_show,
                                                o_msg_title    => l_msg_title,
                                                o_msg          => l_msg,
                                                o_error        => o_error);
        END IF;
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- resets the referral context
        pk_ref_utils.reset_ref_context;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
        
            IF g_error_code IS NOT NULL
            THEN
                g_flg_action := pk_ref_constant.g_err_flg_action_u; -- user defined error
            ELSE
                g_error_code := SQLCODE;
                g_error_desc := SQLERRM;
                g_flg_action := pk_ref_constant.g_err_flg_action_s; -- system error
            END IF;
            pk_alert_exceptions.process_error(i_lang        => i_lang,
                                              i_sqlcode     => g_error_code,
                                              i_sqlerrm     => g_error_desc,
                                              i_message     => g_error,
                                              i_owner       => g_package_owner,
                                              i_package     => g_package_name,
                                              i_function    => 'SET_REF_REFUSED',
                                              i_action_type => g_flg_action,
                                              i_action_msg  => NULL,
                                              o_error       => o_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END set_ref_refused;

    /**
    * Changes referral clinical service 
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Id professional, institution and software    
    * @param   i_id_ref         Referral identifier
    * @param   i_num_order      Professional order number that changed clinical service
    * @param   i_prof_name      Professional name that changed clinical service
    * @param   i_dcs            Dep_clin_serv           
    * @param   i_notes          Decision notes                
    * @param   i_date           Operation date
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   02-10-2009
    */
    FUNCTION set_ref_cs
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_ref    IN p1_external_request.id_external_request%TYPE,
        i_num_order IN professional.num_order%TYPE,
        i_prof_name IN professional.name%TYPE,
        i_dcs       IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_notes     IN p1_detail.text%TYPE,
        i_date      IN DATE,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_params              VARCHAR2(1000 CHAR);
        l_flg_available       VARCHAR2(1 CHAR);
        l_flg_show            VARCHAR2(1000 CHAR);
        l_msg_title           VARCHAR2(1000 CHAR);
        l_msg                 VARCHAR2(1000 CHAR);
        l_prof                profissional; -- professional changing referral clinical service
        l_id_workflow         p1_external_request.id_workflow%TYPE;
        l_track               table_number;
        l_id_profile_template profile_template.id_profile_template%TYPE;
        l_id_inst_dest        p1_external_request.id_inst_dest%TYPE;
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_id_ref=' || i_id_ref || ' i_num_order=' ||
                    i_num_order || ' substr(i_prof_name,1,100)=' || substr(i_prof_name, 1, 100) || ' i_dcs=' || i_dcs ||
                    ' i_date=' || i_date;
        g_error  := '->Init set_ref_cs / ' || l_params;
        pk_alertlog.log_debug(g_error);
        reset_vars;
        g_prof_int := pk_p1_interface.set_prof_interface(i_prof);
        l_track    := table_number();
    
        -- sets the referral context
        pk_ref_utils.init_ref_context;
        pk_ref_utils.set_ref_context(i_id_external_request => i_id_ref, i_dt_system_date => current_timestamp);
    
        -- mandatory parameters
        g_error := 'Validating mandatory parameters / ' || l_params;
        IF i_dcs IS NULL
           OR i_num_order IS NULL
        THEN
            g_error      := 'Invalid parameter / ' || l_params;
            g_error_code := pk_ref_constant.g_ref_error_1005;
            g_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => g_error_code);
            RAISE g_exception;
        END IF;
    
        -- getting operation date
        g_error  := 'Call get_operation_date / ' || l_params;
        g_retval := get_operation_date(i_lang    => i_lang,
                                       i_prof    => i_prof,
                                       i_dt_d    => i_date,
                                       o_dt_tstz => g_sysdate_tstz,
                                       o_error   => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        g_error  := 'Call get_profile_template_inst / ' || l_params;
        g_retval := get_profile_template_inst(i_lang             => i_lang,
                                              i_prof             => i_prof,
                                              i_id_institution   => g_prof_int.institution,
                                              i_id_category      => pk_ref_constant.g_cat_id_med,
                                              o_profile_template => l_id_profile_template,
                                              o_error            => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- validating parameters
        g_error := 'Call check_requirements / ' || l_params;
        IF NOT check_requirements(i_lang          => i_lang,
                                  i_prof          => g_prof_int,
                                  i_num_order     => i_num_order,
                                  i_prof_name     => i_prof_name,
                                  i_profile_templ => l_id_profile_template,
                                  i_func          => pk_ref_constant.g_func_d,
                                  i_id_ref        => i_id_ref,
                                  i_dcs           => i_dcs,
                                  i_date          => g_sysdate_tstz,
                                  o_flg_valid     => l_flg_available,
                                  o_prof          => l_prof,
                                  o_error         => o_error)
        THEN
            RAISE g_exception_np;
        END IF;
    
        IF l_flg_available = pk_ref_constant.g_no
        THEN
            RAISE g_exception;
        END IF;
    
        -- check for workflow id
        g_error  := 'Call pk_p1_external_request.get_id_workflow / ' || l_params;
        g_retval := pk_p1_external_request.get_id_workflow(i_lang        => i_lang,
                                                           i_prof        => l_prof,
                                                           i_id_ref      => i_id_ref,
                                                           o_id_workflow => l_id_workflow,
                                                           o_error       => o_error);
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- setting referral status to 'T'         
        IF l_id_workflow IS NULL
        THEN
        
            g_error  := 'Call PK_P1_MED_HS.set_status_internal / ACTION=CHANGE_CS ID_DEP_CLIN_SERV=' || i_dcs || ' / ' ||
                        l_params;
            g_retval := pk_p1_med_hs.set_status_internal(i_lang          => i_lang,
                                                         i_prof          => l_prof, -- professional changing referral clinical service
                                                         i_id_p1         => i_id_ref,
                                                         i_action        => pk_ref_constant.g_ref_action_cs,
                                                         i_level         => NULL,
                                                         i_prof_dest     => NULL,
                                                         i_dep_clin_serv => i_dcs,
                                                         i_notes         => i_notes,
                                                         i_dt_modified   => NULL,
                                                         i_mode          => NULL,
                                                         i_reason_code   => NULL,
                                                         i_subtype       => NULL,
                                                         i_inst_dest     => NULL,
                                                         i_date          => g_sysdate_tstz,
                                                         o_track         => l_track,
                                                         o_flg_show      => l_flg_show,
                                                         o_msg_title     => l_msg_title,
                                                         o_msg           => l_msg,
                                                         o_error         => o_error);
        
        ELSE
            g_error  := 'Call pk_ref_core.set_status / STATUS=' || pk_ref_constant.g_p1_status_t || ' ACTION=' ||
                        pk_ref_constant.g_ref_action_cs || ' / ' || l_params;
            g_retval := pk_ref_core.set_status2(i_lang         => i_lang,
                                                i_prof         => l_prof, -- professional changing referral clinical service
                                                i_ext_req      => i_id_ref,
                                                i_status_begin => NULL, -- deprecated
                                                i_status_end   => pk_ref_constant.g_p1_status_t, -- deprecated
                                                i_action       => pk_ref_constant.g_ref_action_cs, -- CHANGE_CS                                               
                                                i_level        => NULL,
                                                i_prof_dest    => NULL,
                                                i_dcs          => i_dcs,
                                                i_notes        => i_notes,
                                                i_dt_modified  => NULL,
                                                i_mode         => NULL,
                                                i_reason_code  => NULL,
                                                i_subtype      => NULL,
                                                i_inst_dest    => NULL,
                                                i_date         => g_sysdate_tstz,
                                                o_track        => l_track,
                                                o_flg_show     => l_flg_show,
                                                o_msg_title    => l_msg_title,
                                                o_msg          => l_msg,
                                                o_error        => o_error);
        END IF;
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- resets the referral context
        pk_ref_utils.reset_ref_context;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            IF g_error_code IS NOT NULL
            THEN
                g_flg_action := pk_ref_constant.g_err_flg_action_u; -- user defined error
            ELSE
                g_error_code := SQLCODE;
                g_error_desc := SQLERRM;
                g_flg_action := pk_ref_constant.g_err_flg_action_s; -- system error
            END IF;
            pk_alert_exceptions.process_error(i_lang        => i_lang,
                                              i_sqlcode     => g_error_code,
                                              i_sqlerrm     => g_error_desc,
                                              i_message     => g_error,
                                              i_owner       => g_package_owner,
                                              i_package     => g_package_name,
                                              i_function    => 'SET_REF_CS',
                                              i_action_type => g_flg_action,
                                              i_action_msg  => NULL,
                                              o_error       => o_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END set_ref_cs;

    /**
    * Changes referral dest institution
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Id professional, institution and software    
    * @param   i_id_ref         Referral identifier
    * @param   i_num_order      Professional order number that changed clinical service
    * @param   i_prof_name      Professional name that changed clinical service
    * @param   i_id_inst_dest   New dest institution
    * @param   i_dcs            New Dep_clin_serv belonging to the new dest institution
    * @param   i_date           Operation date
    * @param   o_track          Array of tracking identifiers created
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   11-07-2013
    */
    FUNCTION set_ref_change_inst
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_ref       IN p1_external_request.id_external_request%TYPE,
        i_num_order    IN professional.num_order%TYPE,
        i_prof_name    IN professional.name%TYPE,
        i_id_inst_dest IN p1_external_request.id_inst_dest%TYPE,
        i_dcs          IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_date         IN DATE,
        o_track        OUT table_number,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_params              VARCHAR2(1000 CHAR);
        l_flg_available       VARCHAR2(1 CHAR);
        l_flg_show            VARCHAR2(1000 CHAR);
        l_msg_title           VARCHAR2(1000 CHAR);
        l_msg                 VARCHAR2(1000 CHAR);
        l_prof                profissional; -- professional changing referral dest institution
        l_ref_row             p1_external_request%ROWTYPE;
        l_gender              patient.gender%TYPE;
        l_age                 patient.age%TYPE;
        l_count               PLS_INTEGER;
        l_id_profile_template profile_template.id_profile_template%TYPE;
        l_id_inst_dest        p1_external_request.id_inst_dest%TYPE;
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' ID_REF=' || i_id_ref || ' NUM_ORDER=' || i_num_order ||
                    ' i_id_inst_dest=' || i_id_inst_dest || ' i_dcs=' || i_dcs || ' i_dt_d=' || i_date;
        g_error  := '->Init set_ref_change_inst / ' || l_params;
        pk_alertlog.log_debug(g_error);
        reset_vars;
        g_prof_int := pk_p1_interface.set_prof_interface(i_prof);
        o_track    := table_number();
    
        -- sets the referral context
        pk_ref_utils.init_ref_context;
        pk_ref_utils.set_ref_context(i_id_external_request => i_id_ref, i_dt_system_date => current_timestamp);
    
        -- mandatory parameters
        g_error := 'Validating mandatory parameters / ' || l_params;
        IF i_id_inst_dest IS NULL
           OR i_dcs IS NULL
           OR i_num_order IS NULL
        THEN
            g_error      := 'Invalid parameter / ' || l_params;
            g_error_code := pk_ref_constant.g_ref_error_1005;
            g_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => g_error_code);
            RAISE g_exception;
        END IF;
    
        -- getting operation date
        g_error  := 'Call get_operation_date / i_dt_d=' || i_date;
        g_retval := get_operation_date(i_lang    => i_lang,
                                       i_prof    => i_prof,
                                       i_dt_d    => i_date,
                                       o_dt_tstz => g_sysdate_tstz,
                                       o_error   => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        g_error  := 'Call get_profile_template_inst / ID_INST=' || g_prof_int.institution;
        g_retval := get_profile_template_inst(i_lang             => i_lang,
                                              i_prof             => i_prof,
                                              i_id_institution   => g_prof_int.institution,
                                              i_id_category      => pk_ref_constant.g_cat_id_med,
                                              o_profile_template => l_id_profile_template,
                                              o_error            => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- check if professional is at dest institution
        g_error  := 'Call pk_p1_external_request.get_id_inst_dest / ' || l_params;
        g_retval := pk_p1_external_request.get_id_inst_dest(i_lang         => i_lang,
                                                            i_prof         => i_prof,
                                                            i_id_ref       => i_id_ref,
                                                            o_id_inst_dest => l_id_inst_dest,
                                                            o_error        => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- validating parameters
        g_error  := 'Call check_requirements / ' || l_params;
        g_retval := check_requirements(i_lang          => i_lang,
                                       i_prof          => g_prof_int,
                                       i_num_order     => i_num_order,
                                       i_prof_name     => i_prof_name,
                                       i_profile_templ => l_id_profile_template,
                                       i_func          => pk_ref_constant.g_func_d,
                                       i_id_ref        => i_id_ref,
                                       i_id_inst       => l_id_inst_dest,
                                       i_date          => g_sysdate_tstz,
                                       o_flg_valid     => l_flg_available,
                                       o_prof          => l_prof,
                                       o_error         => o_error);
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        IF l_flg_available = pk_ref_constant.g_no
        THEN
            g_error := 'INVALID PARAMETERS / ' || l_params;
            RAISE g_exception;
        END IF;
    
        l_params := l_params || ' l_prof.ID=' || l_prof.id;
    
        -- check new dep_clin_serv and id_inst_dest
        g_error  := 'Call check_dep_clin_serv / ' || l_params;
        g_retval := check_dep_clin_serv(i_lang          => i_lang,
                                        i_prof          => l_prof,
                                        i_id_inst_dest  => i_id_inst_dest,
                                        i_dcs           => i_dcs,
                                        o_flg_available => l_flg_available,
                                        o_error         => o_error);
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        IF l_flg_available = pk_ref_constant.g_no
        THEN
            g_error      := 'INVALID institution or dep_clin_serv / ' || l_params;
            g_error_code := pk_ref_constant.g_ref_error_1009;
            g_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => g_error_code);
            RAISE g_exception;
        END IF;
    
        -- getting referral data
        g_error  := 'Call pk_p1_external_request.get_ref_row / ' || l_params;
        g_retval := pk_p1_external_request.get_ref_row(i_lang   => i_lang,
                                                       i_prof   => l_prof,
                                                       i_id_ref => i_id_ref,
                                                       o_rec    => l_ref_row,
                                                       o_error  => o_error);
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        l_params := l_params || ' ID_WF=' || l_ref_row.id_workflow || ' ID_SPEC=' || l_ref_row.id_speciality ||
                    ' ID_INST_ORIG=' || l_ref_row.id_inst_orig || ' ID_INST_DEST=' || l_ref_row.id_inst_dest;
    
        -- it should be checked if professional is a triage physician (prof_func), but it is not being done 
        -- because Glintt professionals are not configured in alert database (they should be...)
    
        -- check referral conditions
        IF l_prof.institution != l_ref_row.id_inst_dest
        THEN
            g_error := 'Professional must be in dest institution / ID_INST_DEST=' || l_ref_row.id_inst_dest ||
                       ' PROF_INSTITUTTION=' || l_prof.institution;
            RAISE g_exception;
        END IF;
    
        IF l_ref_row.flg_status NOT IN
           (pk_ref_constant.g_p1_status_t, pk_ref_constant.g_p1_status_r, pk_ref_constant.g_p1_status_a)
        THEN
            g_error_code := pk_ref_constant.g_ref_error_1008;
            g_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => g_error_code);
            RAISE g_exception;
        END IF;
    
        -- check if dest institution is valid       
        g_error  := 'Call pk_ref_core.get_pat_age_gender / ' || l_params;
        g_retval := pk_ref_core.get_pat_age_gender(i_lang    => i_lang,
                                                   i_prof    => l_prof,
                                                   i_patient => l_ref_row.id_patient,
                                                   o_gender  => l_gender,
                                                   o_age     => l_age,
                                                   o_error   => o_error);
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        l_params := l_params || ' age=' || l_age || ' gender=' || l_gender;
    
        g_error := 'SELECT COUNT(1) / ' || l_params;
        SELECT COUNT(1)
          INTO l_count
          FROM TABLE(CAST(pk_ref_dest_phy.get_inst_dcs_forward_p(i_lang         => i_lang,
                                                                 i_prof         => l_prof,
                                                                 i_id_spec      => l_ref_row.id_speciality,
                                                                 i_id_workflow  => l_ref_row.id_workflow,
                                                                 i_id_inst_orig => l_ref_row.id_inst_orig,
                                                                 i_id_inst_dest => l_ref_row.id_inst_dest,
                                                                 i_pat_gender   => l_gender,
                                                                 i_pat_age      => l_age,
                                                                 i_external_sys => l_ref_row.id_external_sys) AS
                          t_coll_ref_inst_dcs_fwd)) t
         WHERE t.id_institution = i_id_inst_dest
           AND t.id_dep_clin_serv = i_dcs; -- any kind of forward type...             
    
        IF l_count = 0
        THEN
            -- no institutions available
            g_error      := 'Cannot change dest institution of referral ' || l_ref_row.id_external_request || ' to ' ||
                            i_id_inst_dest || ' / ' || l_params;
            g_error_code := pk_ref_constant.g_ref_error_1009;
            g_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => g_error_code);
            RAISE g_exception;
        END IF;
    
        -- changing referral dest institution         
        IF l_ref_row.id_workflow IS NULL
        THEN
            g_error  := 'Call PK_P1_MED_HS.set_status_internal / ' || l_params;
            g_retval := pk_p1_med_hs.set_status_internal(i_lang          => i_lang,
                                                         i_prof          => l_prof, -- professional changing referral clinical service
                                                         i_id_p1         => i_id_ref,
                                                         i_action        => pk_ref_constant.g_ref_action_di,
                                                         i_level         => NULL,
                                                         i_prof_dest     => NULL,
                                                         i_dep_clin_serv => i_dcs,
                                                         i_notes         => NULL,
                                                         i_dt_modified   => NULL,
                                                         i_mode          => NULL,
                                                         i_reason_code   => NULL,
                                                         i_subtype       => NULL,
                                                         i_inst_dest     => i_id_inst_dest,
                                                         i_date          => g_sysdate_tstz,
                                                         o_track         => o_track,
                                                         o_flg_show      => l_flg_show,
                                                         o_msg_title     => l_msg_title,
                                                         o_msg           => l_msg,
                                                         o_error         => o_error);
        
        ELSE
            g_error  := 'Call pk_ref_core.set_status ACTION=' || pk_ref_constant.g_ref_action_di || ' / ' || l_params;
            g_retval := pk_ref_core.set_status2(i_lang         => i_lang,
                                                i_prof         => l_prof, -- professional changing referral dest institution
                                                i_ext_req      => i_id_ref,
                                                i_status_begin => NULL, -- deprecated
                                                i_status_end   => pk_ref_constant.g_p1_status_i,
                                                i_action       => pk_ref_constant.g_ref_action_di, -- REF_CHANGE_INST                                               
                                                i_level        => NULL,
                                                i_prof_dest    => NULL,
                                                i_dcs          => i_dcs,
                                                i_notes        => NULL,
                                                i_dt_modified  => NULL,
                                                i_mode         => NULL,
                                                i_reason_code  => NULL,
                                                i_subtype      => NULL,
                                                i_inst_dest    => i_id_inst_dest,
                                                i_date         => g_sysdate_tstz,
                                                o_track        => o_track,
                                                o_flg_show     => l_flg_show,
                                                o_msg_title    => l_msg_title,
                                                o_msg          => l_msg,
                                                o_error        => o_error);
        END IF;
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- resets the referral context
        pk_ref_utils.reset_ref_context;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            IF g_error_code IS NOT NULL
            THEN
                g_flg_action := pk_ref_constant.g_err_flg_action_u; -- user defined error
            ELSE
                g_error_code := SQLCODE;
                g_error_desc := SQLERRM;
                g_flg_action := pk_ref_constant.g_err_flg_action_s; -- system error
            END IF;
            pk_alert_exceptions.process_error(i_lang        => i_lang,
                                              i_sqlcode     => g_error_code,
                                              i_sqlerrm     => g_error_desc,
                                              i_message     => g_error,
                                              i_owner       => g_package_owner,
                                              i_package     => g_package_name,
                                              i_function    => 'SET_REF_CHANGE_INST',
                                              i_action_type => g_flg_action,
                                              i_action_msg  => NULL,
                                              o_error       => o_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END set_ref_change_inst;

    /**
    * Efectives the patient and changes referral status to 'E' (Appointment took place)
    * Transaction identifier available to be defined.
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Id professional, institution and software    
    * @param   i_id_ref         Referral identifier           
    * @param   i_num_order      Professional order number that is triaging the referral
    * @param   i_prof_name      Professional name that is triaging the referral           
    * @param   i_date           Operation date
    * @param   i_transaction_id  SCH 3.0 transaction ID 
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   02-10-2009
    */
    FUNCTION set_ref_efectiv
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_ref         IN p1_external_request.id_external_request%TYPE,
        i_num_order      IN professional.num_order%TYPE,
        i_prof_name      IN professional.name%TYPE,
        i_date           IN DATE,
        i_transaction_id IN VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_params              VARCHAR2(1000 CHAR);
        l_flg_available       VARCHAR2(1 CHAR);
        l_dt_appointment_v    VARCHAR2(50 CHAR);
        l_dt_appointment_tstz schedule.dt_begin_tstz%TYPE;
        l_dt_appointment_d    DATE;
        l_prof                profissional; -- professional who will provide consultation
        l_dcs                 dep_clin_serv.id_dep_clin_serv%TYPE;
        l_transaction_id      VARCHAR2(1000 CHAR);
        l_id_prof_sch         professional.id_professional%TYPE;
        l_no_prof_sch         professional.num_order%TYPE;
        l_id_profile_template profile_template.id_profile_template%TYPE;
        l_id_inst_dest        p1_external_request.id_inst_dest%TYPE;
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_id_ref=' || i_id_ref || ' i_num_order=' ||
                    i_num_order || ' substr(i_prof_name,1,100)=' || substr(i_prof_name, 1, 100) || ' i_date=' || i_date;
        g_error  := '->Init set_ref_efectiv / ' || l_params;
        pk_alertlog.log_debug(g_error);
        reset_vars;
        g_prof_int := pk_p1_interface.set_prof_interface(i_prof);
        -- sets the referral context
        pk_ref_utils.init_ref_context;
        pk_ref_utils.set_ref_context(i_id_external_request => i_id_ref, i_dt_system_date => current_timestamp);
    
        -- get remote transaction
        g_error          := 'START REMOTE TRANSACTION / ' || l_params;
        l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(i_transaction_id, i_prof);
    
        -- getting operation date
        g_error  := 'Call get_operation_date / ' || l_params;
        g_retval := get_operation_date(i_lang    => i_lang,
                                       i_prof    => i_prof,
                                       i_dt_d    => i_date,
                                       o_dt_tstz => g_sysdate_tstz,
                                       o_error   => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- check if professional is at dest institution
        g_error  := 'Call pk_p1_external_request.get_id_inst_dest / ' || l_params;
        g_retval := pk_p1_external_request.get_id_inst_dest(i_lang         => i_lang,
                                                            i_prof         => i_prof,
                                                            i_id_ref       => i_id_ref,
                                                            o_id_inst_dest => l_id_inst_dest,
                                                            o_error        => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- validating parameters
        IF i_num_order IS NOT NULL
        THEN
        
            g_error  := 'Call get_profile_template_inst / ' || l_params;
            g_retval := get_profile_template_inst(i_lang             => i_lang,
                                                  i_prof             => g_prof_int,
                                                  i_id_institution   => g_prof_int.institution,
                                                  i_id_category      => pk_ref_constant.g_cat_id_med,
                                                  o_profile_template => l_id_profile_template,
                                                  o_error            => o_error);
        
            IF NOT g_retval
            THEN
                RAISE g_exception_np;
            END IF;
        
            g_error  := 'Call pk_p1_external_request.get_dep_clin_serv / ' || l_params;
            g_retval := pk_p1_external_request.get_dep_clin_serv(i_lang          => i_lang,
                                                                 i_id_ref        => i_id_ref,
                                                                 o_dep_clin_serv => l_dcs,
                                                                 o_error         => o_error);
        
            l_params := l_params || ' l_dcs=' || l_dcs;
        
            g_error  := 'Call check_requirements / ' || l_params;
            g_retval := check_requirements(i_lang          => i_lang,
                                           i_prof          => g_prof_int,
                                           i_num_order     => i_num_order,
                                           i_prof_name     => i_prof_name,
                                           i_profile_templ => l_id_profile_template,
                                           i_func          => pk_ref_constant.g_func_c,
                                           i_dcs           => l_dcs,
                                           i_id_ref        => i_id_ref,
                                           i_id_inst       => l_id_inst_dest,
                                           i_date          => g_sysdate_tstz,
                                           o_flg_valid     => l_flg_available,
                                           o_prof          => l_prof, -- professional who will provide consultation
                                           o_error         => o_error);
            IF NOT g_retval
            THEN
                RAISE g_exception_np;
            END IF;
        
            IF l_flg_available = pk_ref_constant.g_no
            THEN
                g_error := 'INVALID PARAMETERS / ' || l_params;
                RAISE g_exception;
            END IF;
        ELSE
            g_error  := 'Call check_requirements / ' || l_params;
            g_retval := check_requirements(i_lang      => i_lang,
                                           i_prof      => g_prof_int,
                                           i_id_ref    => i_id_ref,
                                           i_id_inst   => l_id_inst_dest,
                                           i_date      => g_sysdate_tstz,
                                           o_flg_valid => l_flg_available,
                                           o_prof      => l_prof,
                                           o_error     => o_error);
            IF NOT g_retval
            THEN
                RAISE g_exception_np;
            END IF;
        
            IF l_flg_available = pk_ref_constant.g_no
            THEN
                g_error := 'INVALID PARAMETERS / ' || l_params;
                RAISE g_exception;
            END IF;
        
        END IF;
    
        -- getting professional to whom the referral is scheduled
        g_error  := 'Call get_ref_schedule_prof / ' || l_params;
        g_retval := get_ref_schedule_prof(i_lang      => i_lang,
                                          i_prof      => g_prof_int,
                                          i_id_ref    => i_id_ref,
                                          o_id_prof   => l_id_prof_sch,
                                          o_num_order => l_no_prof_sch,
                                          o_error     => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        g_error := 'NUM_ORDER / l_no_prof_sch=' || l_no_prof_sch || ' / ' || l_params;
        IF i_num_order IS NULL
           OR i_num_order = l_no_prof_sch
        THEN
            -- just do referral efectivation (without scheduling)        
            g_error  := 'Call pk_p1_interface.setefectivation / ' || l_params;
            g_retval := pk_p1_interface.setefectivation(i_lang           => i_lang,
                                                        i_prof           => g_prof_int,
                                                        i_ext_req        => i_id_ref,
                                                        i_op_date_tstz   => g_sysdate_tstz,
                                                        i_transaction_id => l_transaction_id,
                                                        o_error          => o_error);
        
            IF NOT g_retval
            THEN
                RAISE g_exception_np;
            END IF;
        
        ELSE
            -- we have to reschedule appointment to the professional having i_num_order 
        
            -- getting appointment date
            g_error  := 'Call get_ref_schedule_date / ' || l_params;
            g_retval := get_ref_schedule_date(i_lang        => i_lang,
                                              i_prof        => g_prof_int,
                                              i_id_ref      => i_id_ref,
                                              o_dt_schedule => l_dt_appointment_tstz,
                                              o_error       => o_error);
        
            IF NOT g_retval
            THEN
                RAISE g_exception_np;
            END IF;
        
            g_error := 'DT_APPOINTMENT / ' || l_params;
            IF l_dt_appointment_tstz IS NULL
            THEN
                -- there is no active appointment for this referral
                g_error := 'There is no active appointment for referral: ' || i_id_ref || ' / ' || l_params;
                RAISE g_exception;
            END IF;
        
            -- convert l_dt_appointment_tstz to varchar2 and to date    
            l_dt_appointment_v := pk_date_utils.to_char_insttimezone(g_prof_int,
                                                                     l_dt_appointment_tstz,
                                                                     pk_ref_constant.g_format_date_2);
            l_dt_appointment_d := to_date(l_dt_appointment_v, pk_ref_constant.g_format_date_2);
        
            l_params := l_params || ' l_dt_appointment_v=' || l_dt_appointment_v;
        
            -- canceling appointment first
            g_error  := 'Call set_ref_cancel_sch / ' || l_params;
            g_retval := set_ref_cancel_sch(i_lang           => i_lang,
                                           i_prof           => g_prof_int,
                                           i_id_ref         => i_id_ref,
                                           i_dt_appointment => l_dt_appointment_d, -- DATE
                                           i_notes          => NULL,
                                           i_date           => g_sysdate_tstz,
                                           i_transaction_id => l_transaction_id,
                                           o_error          => o_error);
        
            IF NOT g_retval
            THEN
                RAISE g_exception_np;
            END IF;
        
            g_error  := 'Call PK_P1_INTERFACE.SETEFECTIVATION / ' || l_params;
            g_retval := pk_p1_interface.setefectivation(i_lang           => i_lang,
                                                        i_prof           => g_prof_int,
                                                        i_ext_req        => i_id_ref,
                                                        i_num_order      => i_num_order, -- professional who will provide consultation
                                                        i_prof_name      => i_prof_name,
                                                        i_dcs            => l_dcs,
                                                        i_date_tstz      => l_dt_appointment_v,
                                                        i_op_date_tstz   => g_sysdate_tstz + INTERVAL '1' SECOND,
                                                        i_transaction_id => l_transaction_id,
                                                        o_error          => o_error);
        
            IF NOT g_retval
            THEN
                RAISE g_exception_np;
            END IF;
        
        END IF;
    
        --only does a remote commit if api is not called from external interfaces
        g_error := 'COMMIT EVERYTHING / ' || l_params;
        IF i_transaction_id IS NULL
        THEN
            pk_schedule_api_upstream.do_commit(l_transaction_id, i_prof);
        END IF;
    
        -- resets the referral context
        pk_ref_utils.reset_ref_context;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'SET_EFECTIV',
                                              o_error    => o_error);
        
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END set_ref_efectiv;

    /**
    * Efectives the patient and changes referral status to 'E' (Appointment took place)
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Id professional, institution and software    
    * @param   i_id_ref         Referral identifier           
    * @param   i_num_order      Professional order number that is triaging the referral
    * @param   i_prof_name      Professional name that is triaging the referral           
    * @param   i_date           Operation date 
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   02-10-2009
    */
    FUNCTION set_ref_efectiv
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_ref    IN p1_external_request.id_external_request%TYPE,
        i_num_order IN professional.num_order%TYPE,
        i_prof_name IN professional.name%TYPE,
        i_date      IN DATE,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_error := 'Init set_ref_efectiv 2';
        reset_vars;
        RETURN set_ref_efectiv(i_lang           => i_lang,
                               i_prof           => i_prof,
                               i_id_ref         => i_id_ref,
                               i_num_order      => i_num_order,
                               i_prof_name      => i_prof_name,
                               i_date           => i_date,
                               i_transaction_id => NULL,
                               o_error          => o_error);
    
    END set_ref_efectiv;

    /**
    * Consultation physician answers the referral request
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Id professional, institution and software    
    * @param   i_id_ref         Referral identifier           
    * @param   i_num_order      Professional order number who will provide consultation
    * @param   i_prof_name      Professional name who will provide consultation
    * @param   i_diag_array     Diagnosis information. [i_diag_flg_type|i_diag_code|i_diag_desc|i_diag_notes]
    * @param   i_answer_array   Clinical information: Observation summary, Treatment proposal, New exams proposal and Conclusions
    * @param   i_date           Operation date
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   02-10-2009
    */
    FUNCTION set_ref_answer
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_ref       IN p1_external_request.id_external_request%TYPE,
        i_num_order    IN professional.num_order%TYPE,
        i_prof_name    IN professional.name%TYPE,
        i_diag_array   IN table_table_varchar,
        i_answer_array IN table_table_varchar,
        i_date         IN DATE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_params              VARCHAR2(1000 CHAR);
        l_diagnosis           table_number;
        l_prof                profissional; -- professional answering the referral
        l_flg_available       VARCHAR2(1 CHAR);
        l_dcs                 dep_clin_serv.id_dep_clin_serv%TYPE;
        l_diagnosis_desc      table_varchar;
        l_id_workflow         p1_external_request.id_workflow%TYPE;
        o_track               table_number;
        l_id_profile_template profile_template.id_profile_template%TYPE;
        l_id_inst_dest        p1_external_request.id_inst_dest%TYPE;
    BEGIN
        ----------------------
        -- INIT
        ----------------------
        l_params := 'ID_REF=' || i_id_ref || ' NUM_ORDER=' || i_num_order || ' PROF_NAME=' || i_prof_name ||
                    ' i_diag_array.count=' || i_diag_array.count || ' i_answer_array.count=' || i_answer_array.count ||
                    ' i_date=' || i_date;
        g_error  := '->Init set_ref_answer / ' || l_params;
        pk_alertlog.log_debug(g_error);
        reset_vars;
        g_prof_int := pk_p1_interface.set_prof_interface(i_prof);
        o_track    := table_number();
    
        -- sets the referral context
        pk_ref_utils.init_ref_context;
        pk_ref_utils.set_ref_context(i_id_external_request => i_id_ref, i_dt_system_date => current_timestamp);
    
        ----------------------
        -- VAL
        ----------------------    
        g_error := 'Validating mandatory parameters / ' || l_params;
        IF i_num_order IS NULL
           OR (i_diag_array IS NOT NULL AND i_diag_array.count = 0 AND i_answer_array IS NOT NULL AND
           i_answer_array.count = 0)
        THEN
            g_error := 'Invalid parameter / ID_REFERRAL=' || i_id_ref || ' NUM_ORDER=' || i_num_order || ' PROF_NAME=' ||
                       i_prof_name;
        
            IF i_diag_array IS NOT NULL
            THEN
                g_error := g_error || ' I_DIAG_ARRAY.COUNT= ' || i_diag_array.count;
            ELSE
                g_error := g_error || ' I_DIAG_ARRAY not initialized';
            END IF;
        
            IF i_answer_array IS NOT NULL
            THEN
                g_error := g_error || ' I_ANSWER_ARRAY.COUNT= ' || i_answer_array.count;
            ELSE
                g_error := g_error || ' I_ANSWER_ARRAY not initialized';
            END IF;
        
            g_error_code := pk_ref_constant.g_ref_error_1005;
            g_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => g_error_code);
            RAISE g_exception;
        END IF;
    
        -- getting operation date
        g_error  := 'Call get_operation_date / ' || l_params;
        g_retval := get_operation_date(i_lang    => i_lang,
                                       i_prof    => i_prof,
                                       i_dt_d    => i_date,
                                       o_dt_tstz => g_sysdate_tstz,
                                       o_error   => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        g_error  := 'Call pk_p1_external_request.get_dep_clin_serv / ' || l_params;
        g_retval := pk_p1_external_request.get_dep_clin_serv(i_lang          => i_lang,
                                                             i_id_ref        => i_id_ref,
                                                             o_dep_clin_serv => l_dcs,
                                                             o_error         => o_error);
    
        g_error  := 'Call get_profile_template_inst / ID_INST=' || g_prof_int.institution;
        g_retval := get_profile_template_inst(i_lang             => i_lang,
                                              i_prof             => i_prof,
                                              i_id_institution   => g_prof_int.institution,
                                              i_id_category      => pk_ref_constant.g_cat_id_med,
                                              o_profile_template => l_id_profile_template,
                                              o_error            => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- check if professional is at dest institution
        g_error  := 'Call pk_p1_external_request.get_id_inst_dest / ' || l_params;
        g_retval := pk_p1_external_request.get_id_inst_dest(i_lang         => i_lang,
                                                            i_prof         => i_prof,
                                                            i_id_ref       => i_id_ref,
                                                            o_id_inst_dest => l_id_inst_dest,
                                                            o_error        => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- validating parameters
        g_error := 'Call check_requirements / ' || l_params;
        IF NOT check_requirements(i_lang          => i_lang,
                                  i_prof          => g_prof_int,
                                  i_num_order     => i_num_order,
                                  i_prof_name     => i_prof_name,
                                  i_profile_templ => l_id_profile_template,
                                  i_func          => pk_ref_constant.g_func_c,
                                  i_dcs           => l_dcs, -- to update professional info
                                  i_id_ref        => i_id_ref,
                                  i_id_inst       => l_id_inst_dest,
                                  i_date          => g_sysdate_tstz,
                                  o_flg_valid     => l_flg_available,
                                  o_prof          => l_prof,
                                  o_error         => o_error)
        THEN
            RAISE g_exception_np;
        END IF;
    
        IF l_flg_available = pk_ref_constant.g_no
        THEN
            g_error := 'INVALID PARAMETERS / ' || l_params;
            RAISE g_exception;
        END IF;
    
        -- validating diagnosis info
        g_error  := 'Call check_diag_array / ' || l_params;
        g_retval := check_diag_array(i_lang       => i_lang,
                                     i_prof       => g_prof_int,
                                     i_diag_array => i_diag_array,
                                     o_error      => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- validating answer info
        g_error  := 'Call check_answer_array / ' || l_params;
        g_retval := check_answer_array(i_lang         => i_lang,
                                       i_prof         => g_prof_int,
                                       i_answer_array => i_answer_array,
                                       o_error        => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- converting diagnosis info from table_table_varchar into table_number
        g_error  := 'Call CREATE_DIAG_ARRAY / ' || l_params;
        g_retval := create_diag_array(i_lang       => i_lang,
                                      i_prof       => g_prof_int,
                                      i_diag_array => i_diag_array,
                                      o_diag_array => l_diagnosis,
                                      o_error      => o_error);
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        ----------------------
        -- FUNC
        ----------------------
        g_error          := 'l_diagnosis_desc / ' || l_params;
        l_diagnosis_desc := table_varchar();
        l_diagnosis_desc.extend(l_diagnosis.count);
    
        -- check for workflow id
        g_error  := 'Call pk_p1_external_request.get_id_workflow / ' || l_params;
        g_retval := pk_p1_external_request.get_id_workflow(i_lang        => i_lang,
                                                           i_prof        => l_prof,
                                                           i_id_ref      => i_id_ref,
                                                           o_id_workflow => l_id_workflow,
                                                           o_error       => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- answering the referral     
        IF l_id_workflow IS NULL
        THEN
        
            g_error  := 'Call PK_P1_MED_HS.set_request_answer_int / ' || l_params;
            g_retval := pk_p1_med_hs.set_request_answer_int(i_lang      => i_lang,
                                                            i_prof      => l_prof,
                                                            i_exr       => i_id_ref,
                                                            i_diagnosis => l_diagnosis,
                                                            i_diag_desc => l_diagnosis_desc,
                                                            i_answer    => i_answer_array,
                                                            i_date      => g_sysdate_tstz,
                                                            o_error     => o_error);
        ELSE
            g_error  := 'Calling PK_REF_DEST_PHY.set_ref_answer / ' || l_params;
            g_retval := pk_ref_dest_phy.set_ref_answer(i_lang      => i_lang,
                                                       i_prof      => l_prof,
                                                       i_exr       => i_id_ref,
                                                       i_diagnosis => l_diagnosis,
                                                       i_diag_desc => l_diagnosis_desc,
                                                       i_answer    => i_answer_array,
                                                       i_date      => g_sysdate_tstz,
                                                       o_track     => o_track,
                                                       o_error     => o_error);
        END IF;
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- resets the referral context
        pk_ref_utils.reset_ref_context;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            IF g_error_code IS NOT NULL
            THEN
                g_flg_action := pk_ref_constant.g_err_flg_action_u; -- user defined error
            ELSE
                g_error_code := SQLCODE;
                g_error_desc := SQLERRM;
                g_flg_action := pk_ref_constant.g_err_flg_action_s; -- system error
            END IF;
        
            pk_alert_exceptions.process_error(i_lang        => i_lang,
                                              i_sqlcode     => g_error_code,
                                              i_sqlerrm     => g_error_desc,
                                              i_message     => g_error,
                                              i_owner       => g_package_owner,
                                              i_package     => g_package_name,
                                              i_function    => 'SET_REF_ANSWER',
                                              i_action_type => g_flg_action,
                                              i_action_msg  => NULL,
                                              o_error       => o_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END set_ref_answer;

    /**
    * Sents referral back by administrative clerk, setting the referral status to 'B'
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Id professional, institution and software from the Interface
    * @param   i_id_ref         Referral identifier
    * @param   i_reason_code    Decline reason code identifier    
    * @param   i_reason_desc    Decline reason description. Parameter ignored.  
    * @param   i_notes          Administrative refusal notes
    * @param   i_date           Operation date
    * @param   o_track          Array of tracking identifiers created
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  João Almeida
    * @version 1.0
    * @since   30-09-2009
    */
    FUNCTION set_ref_bur_declined
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_ref      IN p1_external_request.id_external_request%TYPE,
        i_reason_code IN p1_reason_code.id_reason_code%TYPE,
        i_reason_desc IN translation.code_translation%TYPE,
        i_notes       IN p1_detail.text%TYPE,
        i_date        IN DATE,
        o_track       OUT table_number,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_params       VARCHAR2(1000 CHAR);
        l_flg_valid    VARCHAR2(1 CHAR);
        l_prof         profissional;
        l_flg_show     VARCHAR2(1000 CHAR);
        l_msg_title    VARCHAR2(1000 CHAR);
        l_msg          VARCHAR2(1000 CHAR);
        l_id_workflow  p1_external_request.id_workflow%TYPE;
        l_id_inst_dest p1_external_request.id_inst_dest%TYPE;
    BEGIN
        ----------------------
        -- INIT
        ----------------------
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_id_ref=' || i_id_ref || ' i_reason_code=' ||
                    i_reason_code || ' i_date=' || i_date;
        g_error  := '->Init set_ref_bur_declined / ' || l_params;
        pk_alertlog.log_debug(g_error);
        reset_vars;
        g_prof_int := pk_p1_interface.set_prof_interface(i_prof);
        o_track    := table_number();
    
        -- sets the referral context
        pk_ref_utils.init_ref_context;
        pk_ref_utils.set_ref_context(i_id_external_request => i_id_ref, i_dt_system_date => current_timestamp);
    
        ----------------------
        -- VAL
        ----------------------
        -- mandatory parameters
        g_error := 'Validating mandatory parameters / ' || l_params;
        IF i_reason_code IS NULL
        THEN
            g_error      := 'Invalid parameter / ' || l_params;
            g_error_code := pk_ref_constant.g_ref_error_1005;
            g_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => g_error_code);
            RAISE g_exception;
        END IF;
    
        -- getting operation date
        g_error  := 'Call get_operation_date / ' || l_params;
        g_retval := get_operation_date(i_lang    => i_lang,
                                       i_prof    => i_prof,
                                       i_dt_d    => i_date,
                                       o_dt_tstz => g_sysdate_tstz,
                                       o_error   => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- check if professional is at dest institution
        g_error  := 'Call pk_p1_external_request.get_id_inst_dest / ' || l_params;
        g_retval := pk_p1_external_request.get_id_inst_dest(i_lang         => i_lang,
                                                            i_prof         => i_prof,
                                                            i_id_ref       => i_id_ref,
                                                            o_id_inst_dest => l_id_inst_dest,
                                                            o_error        => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- validating parameters
        g_error  := 'Call check_requirements / ' || l_params;
        g_retval := check_requirements(i_lang        => i_lang,
                                       i_prof        => g_prof_int,
                                       i_id_ref      => i_id_ref,
                                       i_id_inst     => l_id_inst_dest,
                                       i_reason_code => i_reason_code,
                                       i_reason_type => pk_ref_constant.g_reason_code_b, -- Sent back by registrar
                                       i_date        => g_sysdate_tstz,
                                       o_flg_valid   => l_flg_valid,
                                       o_prof        => l_prof, -- ignored
                                       o_error       => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        IF l_flg_valid = pk_ref_constant.g_no
        THEN
            RAISE g_exception;
        END IF;
    
        ----------------------
        -- FUNC
        ----------------------
        -- check for workflow id
        g_error  := 'Call pk_p1_external_request.get_id_workflow / ' || l_params;
        g_retval := pk_p1_external_request.get_id_workflow(i_lang        => i_lang,
                                                           i_prof        => g_prof_int,
                                                           i_id_ref      => i_id_ref,
                                                           o_id_workflow => l_id_workflow,
                                                           o_error       => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        IF l_id_workflow IS NULL
        THEN
        
            g_error  := 'Call PK_P1_ADM_HS.set_status_internal / STATUS=' || pk_ref_constant.g_p1_status_b || ' / ' ||
                        l_params;
            g_retval := pk_p1_adm_hs.set_status_internal(i_lang        => i_lang,
                                                         i_prof        => g_prof_int, --external professional
                                                         i_ext_req     => i_id_ref,
                                                         i_status      => pk_ref_constant.g_p1_status_b, --status 'B' adm returned the ref
                                                         i_notes       => i_notes,
                                                         i_reason_code => i_reason_code,
                                                         i_dcs         => NULL,
                                                         i_date        => g_sysdate_tstz,
                                                         o_track       => o_track,
                                                         o_error       => o_error);
        
        ELSE
        
            g_error  := 'Call pk_ref_core.set_status / STATUS=' || pk_ref_constant.g_p1_status_b || ' ACTION=' ||
                        pk_ref_constant.g_ref_action_b || ' / ' || l_params;
            g_retval := pk_ref_core.set_status2(i_lang         => i_lang,
                                                i_prof         => g_prof_int,
                                                i_ext_req      => i_id_ref,
                                                i_status_begin => NULL, -- deprecated
                                                i_status_end   => pk_ref_constant.g_p1_status_b, -- deprecated
                                                i_action       => pk_ref_constant.g_ref_action_b, -- DECLINE_B
                                                i_level        => NULL,
                                                i_prof_dest    => NULL,
                                                i_dcs          => NULL,
                                                i_notes        => i_notes,
                                                i_dt_modified  => NULL,
                                                i_mode         => NULL,
                                                i_reason_code  => i_reason_code,
                                                i_subtype      => NULL,
                                                i_inst_dest    => NULL,
                                                i_date         => g_sysdate_tstz,
                                                o_track        => o_track,
                                                o_flg_show     => l_flg_show,
                                                o_msg_title    => l_msg_title,
                                                o_msg          => l_msg,
                                                o_error        => o_error);
        END IF;
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- resets the referral context
        pk_ref_utils.reset_ref_context;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            IF g_error_code IS NOT NULL
            THEN
                g_flg_action := pk_ref_constant.g_err_flg_action_u; -- user defined error
            ELSE
                g_error_code := SQLCODE;
                g_error_desc := SQLERRM;
                g_flg_action := pk_ref_constant.g_err_flg_action_s; -- system error
            END IF;
            pk_alert_exceptions.process_error(i_lang        => i_lang,
                                              i_sqlcode     => g_error_code,
                                              i_sqlerrm     => g_error_desc,
                                              i_message     => g_error,
                                              i_owner       => g_package_owner,
                                              i_package     => g_package_name,
                                              i_function    => 'SET_REF_BUR_DECLINED',
                                              i_action_type => g_flg_action,
                                              i_action_msg  => NULL,
                                              o_error       => o_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END set_ref_bur_declined;

    /**
    * Patient missed the appointment, setting the referral status to 'F'
    *
    * @param   i_lang         Language identifier associated to the professional executing the request
    * @param   i_prof         Professional id, institution and software
    * @param   i_id_ref       Referral identifier
    * @param   i_notes        Notes related to the missed appointment
    * @param   i_date         Operation date    
    * @param   i_REASON_CODE     Reason code 
    * @param   i_reason type     Reason code 
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.5
    * @since   13-05-2010
    */
    FUNCTION set_ref_failed
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_ref         IN p1_external_request.id_external_request%TYPE,
        i_notes          IN p1_detail.text%TYPE,
        i_date           IN DATE,
        i_id_reason_code IN p1_reason_code.id_reason_code%TYPE DEFAULT NULL,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_params       VARCHAR2(1000 CHAR);
        l_flg_valid    VARCHAR2(1 CHAR);
        l_prof         profissional;
        l_id_inst_dest p1_external_request.id_inst_dest%TYPE;
    BEGIN
        ----------------------
        -- INIT
        ----------------------
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_id_ref=' || i_id_ref || ' i_id_reason_code=' ||
                    i_id_reason_code || ' i_date=' || i_date;
        g_error  := '->Init set_ref_failed / ' || l_params;
        pk_alertlog.log_debug(g_error);
        reset_vars;
        g_prof_int := pk_p1_interface.set_prof_interface(i_prof);
        -- sets the referral context
        pk_ref_utils.init_ref_context;
        pk_ref_utils.set_ref_context(i_id_external_request => i_id_ref, i_dt_system_date => current_timestamp);
    
        -- getting operation date
        g_error  := 'Call get_operation_date / ' || l_params;
        g_retval := get_operation_date(i_lang    => i_lang,
                                       i_prof    => i_prof,
                                       i_dt_d    => i_date,
                                       o_dt_tstz => g_sysdate_tstz,
                                       o_error   => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        ----------------------
        -- VAL
        ----------------------
    
        -- validating parameters
        g_error  := 'Call check_requirements / ' || l_params;
        g_retval := check_requirements(i_lang        => i_lang,
                                       i_prof        => g_prof_int,
                                       i_id_ref      => i_id_ref,
                                       i_reason_code => i_id_reason_code,
                                       i_reason_type => pk_ref_constant.g_reason_code_f,
                                       i_date        => g_sysdate_tstz,
                                       o_flg_valid   => l_flg_valid,
                                       o_prof        => l_prof, -- ignored
                                       o_error       => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        IF l_flg_valid = pk_ref_constant.g_no
        THEN
            RAISE g_exception;
        END IF;
    
        ----------------------
        -- FUNC
        ----------------------
    
        -- does not need to get workflow because this function already does this
        g_error  := 'Call pk_p1_ext_sys.UPDATE STATUS / FLG_STATUS=' || pk_ref_constant.g_p1_status_f || ' / ' ||
                    l_params;
        g_retval := pk_p1_ext_sys.update_referral_status(i_lang           => i_lang,
                                                         i_prof           => g_prof_int,
                                                         i_ext_req        => i_id_ref,
                                                         i_id_sch         => NULL,
                                                         i_status         => pk_ref_constant.g_p1_status_f,
                                                         i_notes          => i_notes,
                                                         i_reschedule     => NULL,
                                                         i_id_reason_code => i_id_reason_code,
                                                         i_date           => g_sysdate_tstz,
                                                         o_error          => o_error);
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- resets the referral context
        pk_ref_utils.reset_ref_context;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'SET_REF_FAILED',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END set_ref_failed;

    /**
    * Cancels the referral
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Id professional, institution and software    
    * @param   i_id_ref         Referral identifier    
    * @param   i_num_order      Professional order number who is canceling the referral
    * @param   i_prof_name      Professional name who is canceling the referral
    * @param   i_reason_code    Cancel reason code identifier    
    * @param   i_reason_desc    Cancel reason description. Parameter ignored.   
    * @param   i_notes          Cancelation notes
    * @param   i_date           Operation date
    * @param   i_transaction_id SCH 3.0 Transaction id    
    * @param   o_track          Tracking identifiers created due to the status change
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.5
    * @since   30-04-2010
    */
    FUNCTION set_ref_cancel
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_ref         IN p1_external_request.id_external_request%TYPE,
        i_num_order      IN professional.num_order%TYPE,
        i_prof_name      IN professional.name%TYPE,
        i_reason_code    IN p1_reason_code.id_reason_code%TYPE,
        i_reason_desc    IN translation.code_translation%TYPE,
        i_notes          IN p1_detail.text%TYPE,
        i_date           IN DATE,
        i_transaction_id IN VARCHAR2,
        o_track          OUT table_number,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_params         VARCHAR2(1000 CHAR);
        l_flg_valid      VARCHAR2(1 CHAR);
        l_prof           profissional;
        l_id_workflow    p1_external_request.id_workflow%TYPE;
        l_id_inst_orig   p1_external_request.id_inst_orig%TYPE;
        l_id_inst_dest   p1_external_request.id_inst_dest%TYPE;
        l_transaction_id VARCHAR2(1000 CHAR);
        l_id_prof_req    p1_external_request.id_prof_requested%TYPE;
    
        CURSOR c_ref IS
            SELECT id_prof_requested, id_workflow, id_inst_orig, id_inst_dest
              FROM p1_external_request
             WHERE id_external_request = i_id_ref;
    BEGIN
        ----------------------
        -- INIT
        ----------------------        
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_id_ref=' || i_id_ref || ' i_num_order=' ||
                    i_num_order || ' substr(i_prof_name,1,100)=' || substr(i_prof_name, 1, 100) || ' i_reason_code=' ||
                    i_reason_code || ' i_date=' || i_date;
        g_error  := '->Init set_ref_cancel / ' || l_params;
        pk_alertlog.log_debug(g_error);
        reset_vars;
        g_prof_int := pk_p1_interface.set_prof_interface(i_prof);
        o_track    := table_number();
    
        -- sets the referral context
        pk_ref_utils.init_ref_context;
        pk_ref_utils.set_ref_context(i_id_external_request => i_id_ref, i_dt_system_date => current_timestamp);
    
        -- get remote transaction for the new scheduler
        g_error          := 'START REMOTE TRANSACTION / ' || l_params;
        l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(i_transaction_id, i_prof);
    
        -- getting operation date
        g_error  := 'Call get_operation_date / ' || l_params;
        g_retval := get_operation_date(i_lang    => i_lang,
                                       i_prof    => i_prof,
                                       i_dt_d    => i_date,
                                       o_dt_tstz => g_sysdate_tstz,
                                       o_error   => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        ----------------------
        -- VAL
        ----------------------
        -- mandatory parameters
        g_error := 'Validating mandatory parameters / ' || l_params;
        IF i_reason_code IS NULL -- i_num_order can be not null, the registrar can cancel referrals
        THEN
            g_error      := 'Invalid parameter / ' || l_params;
            g_error_code := pk_ref_constant.g_ref_error_1005;
            g_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => g_error_code);
            RAISE g_exception;
        END IF;
    
        -- validating parameters
        g_error  := 'Call check_requirements / ' || l_params;
        g_retval := check_requirements(i_lang        => i_lang,
                                       i_prof        => g_prof_int,
                                       i_id_ref      => i_id_ref,
                                       i_num_order   => i_num_order,
                                       i_prof_name   => i_prof_name,
                                       i_reason_code => i_reason_code,
                                       i_reason_type => pk_ref_constant.g_reason_code_c,
                                       i_date        => g_sysdate_tstz,
                                       o_flg_valid   => l_flg_valid,
                                       o_prof        => l_prof, -- professional that is canceling the referral
                                       o_error       => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        IF l_flg_valid = pk_ref_constant.g_no
        THEN
            RAISE g_exception;
        END IF;
    
        ----------------------
        -- FUNC
        ---------------------- 
        g_error := 'OPEN c_ref / ' || l_params;
        OPEN c_ref;
        FETCH c_ref
            INTO l_id_prof_req, l_id_workflow, l_id_inst_orig, l_id_inst_dest;
        CLOSE c_ref;
    
        IF l_id_prof_req IS NULL
        THEN
            g_error      := 'Professional requested is null / ' || l_params;
            g_error_code := pk_ref_constant.g_ref_error_1007;
            g_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => g_error_code);
            RAISE g_exception;
        END IF;
    
        IF i_num_order IS NULL
        THEN
            -- is the registrar that is cancelling the referral
            l_prof := pk_p1_interface.set_prof_interface(i_prof);
        
            -- he must be at dest institution
            IF l_prof.institution != l_id_inst_dest
            THEN
                g_error      := 'Professional must be at dest institution / inst=' || l_prof.institution ||
                                ' dest_institution=' || l_id_inst_dest || ' / ' || l_params;
                g_error_code := pk_ref_constant.g_ref_error_1009;
                g_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => g_error_code);
                RAISE g_exception;
            END IF;
        ELSE
            -- is the physician that is cancelling the referral
            IF l_prof.id != l_id_prof_req
            THEN
                g_error      := 'Professional with num order ' || i_num_order ||
                                ' is not the professional that requested the referral / ID_PROF_REQ=' || l_id_prof_req ||
                                ' ID_PROF=' || l_prof.id || ' / ' || l_params;
                g_error_code := pk_ref_constant.g_ref_error_1009;
                g_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => g_error_code);
                RAISE g_exception;
            END IF;
        
            -- he must be at orig institution
            IF l_prof.institution != l_id_inst_orig
            THEN
                g_error      := 'Professional must be at orig institution / inst=' || l_prof.institution ||
                                ' orig_institution=' || l_id_inst_orig || ' / ' || l_params;
                g_error_code := pk_ref_constant.g_ref_error_1009;
                g_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => g_error_code);
                RAISE g_exception;
            END IF;
        END IF;
    
        IF l_id_workflow IS NULL
        THEN
        
            -- cancel referral
            g_error  := 'Call pk_p1_med_cs.cancel_external_request_int / ID_PROFESSIONAL=' || l_prof.id || ' TRANS_ID=' ||
                        l_transaction_id || ' / ' || l_params;
            g_retval := pk_p1_med_cs.cancel_external_request_int(i_lang           => i_lang,
                                                                 i_prof           => l_prof,
                                                                 i_ext_req        => i_id_ref,
                                                                 i_mcdts          => NULL,
                                                                 i_id_patient     => NULL,
                                                                 i_id_episode     => NULL,
                                                                 i_notes          => i_notes,
                                                                 i_reason         => i_reason_code,
                                                                 i_transaction_id => l_transaction_id,
                                                                 o_track          => o_track,
                                                                 o_error          => o_error);
        ELSE
            -- cancel referral
            g_error  := 'Call pk_ref_orig_phy.cancel_referral / ID_PROFESSIONAL=' || l_prof.id || ' / ' || l_params;
            g_retval := pk_ref_orig_phy.cancel_referral(i_lang           => i_lang,
                                                        i_prof           => l_prof,
                                                        i_ext_req        => i_id_ref,
                                                        i_id_patient     => NULL,
                                                        i_id_episode     => NULL,
                                                        i_notes          => i_notes,
                                                        i_reason         => i_reason_code,
                                                        i_transaction_id => NULL,
                                                        o_track          => o_track,
                                                        o_error          => o_error);
        
        END IF;
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        --only if not started from external interfaces
        IF i_transaction_id IS NULL
        THEN
            pk_schedule_api_upstream.do_commit(l_transaction_id, i_prof);
        END IF;
    
        -- resets the referral context
        pk_ref_utils.reset_ref_context;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            IF g_error_code IS NOT NULL
            THEN
                g_flg_action := pk_ref_constant.g_err_flg_action_u; -- user defined error
            ELSE
                g_error_code := SQLCODE;
                g_error_desc := SQLERRM;
                g_flg_action := pk_ref_constant.g_err_flg_action_s; -- system error
            END IF;
            pk_alert_exceptions.process_error(i_lang        => i_lang,
                                              i_sqlcode     => g_error_code,
                                              i_sqlerrm     => g_error_desc,
                                              i_message     => g_error,
                                              i_owner       => g_package_owner,
                                              i_package     => g_package_name,
                                              i_function    => 'SET_REF_CANCEL',
                                              i_action_type => g_flg_action,
                                              i_action_msg  => NULL,
                                              o_error       => o_error);
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END set_ref_cancel;

    /**
    * Cancels the referral
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Id professional, institution and software    
    * @param   i_id_ref         Referral identifier    
    * @param   i_num_order      Professional order number who is canceling the referral
    * @param   i_prof_name      Professional name who is canceling the referral
    * @param   i_reason_code    Cancel reason code identifier    
    * @param   i_reason_desc    Cancel reason description. Parameter ignored.   
    * @param   i_notes          Cancelation notes
    * @param   i_date           Operation date
    * @param   o_track          Tracking identifiers created due to the status change
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.5
    * @since   30-04-2010
    */
    FUNCTION set_ref_cancel
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_ref      IN p1_external_request.id_external_request%TYPE,
        i_num_order   IN professional.num_order%TYPE,
        i_prof_name   IN professional.name%TYPE,
        i_reason_code IN p1_reason_code.id_reason_code%TYPE,
        i_reason_desc IN translation.code_translation%TYPE,
        i_notes       IN p1_detail.text%TYPE,
        i_date        IN DATE,
        o_track       OUT table_number,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_error := 'Init set_ref_cancel 2';
        reset_vars;
        RETURN set_ref_cancel(i_lang           => i_lang,
                              i_prof           => i_prof,
                              i_id_ref         => i_id_ref,
                              i_num_order      => i_num_order,
                              i_prof_name      => i_prof_name,
                              i_reason_code    => i_reason_code,
                              i_reason_desc    => i_reason_desc,
                              i_notes          => i_notes,
                              i_date           => i_date,
                              i_transaction_id => NULL,
                              o_track          => o_track,
                              o_error          => o_error);
    
    END set_ref_cancel;

    /**
    * Declines the referral setting status to 'D' (Sent back due to lack of data)
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Id professional, institution and software from the Interface
    * @param   i_id_ref         Referral identifier
    * @param   i_num_order      unique number for the physician that is returning the referral
    * @param   i_prof_name      name of the physician that is returning the referral
    * @param   i_reason_code    Decline reason code identifier    
    * @param   i_reason_desc    Decline reason description. Parameter ignored.
    * @param   i_notes          Decision notes
    * @param   i_date           Operation date
    * @param   o_track          Tracking identifiers created due to the status change
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  João Almeida
    * @version 1.0
    * @since   30-09-2009
    */
    FUNCTION set_ref_declined
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_ref      IN p1_external_request.id_external_request%TYPE,
        i_num_order   IN professional.num_order%TYPE,
        i_prof_name   IN professional.name%TYPE,
        i_reason_code IN p1_reason_code.id_reason_code%TYPE,
        i_reason_desc IN translation.code_translation%TYPE,
        i_notes       IN p1_detail.text%TYPE,
        i_date        IN DATE,
        o_track       OUT table_number,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_params              VARCHAR2(1000 CHAR);
        l_flg_show            VARCHAR2(1000 CHAR);
        l_msg_title           VARCHAR2(1000 CHAR);
        l_msg                 VARCHAR2(1000 CHAR);
        l_prof                profissional; -- professional declining the referral
        l_flg_valid           VARCHAR2(1 CHAR);
        l_dcs                 dep_clin_serv.id_dep_clin_serv%TYPE;
        l_id_workflow         p1_external_request.id_workflow%TYPE;
        l_id_profile_template profile_template.id_profile_template%TYPE;
        l_id_inst_dest        p1_external_request.id_inst_dest%TYPE;
    BEGIN
        ----------------------
        -- INIT
        ----------------------
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_id_ref=' || i_id_ref || ' i_num_order=' ||
                    i_num_order || ' substr(i_prof_name,1,100)=' || substr(i_prof_name, 1, 100) || ' i_reason_code=' ||
                    i_reason_code || ' i_date=' || i_date;
        g_error  := 'Init set_ref_declined / ' || l_params;
        pk_alertlog.log_debug(g_error);
        reset_vars;
        g_prof_int := pk_p1_interface.set_prof_interface(i_prof);
        o_track    := table_number();
    
        -- sets the referral context
        pk_ref_utils.init_ref_context;
        pk_ref_utils.set_ref_context(i_id_external_request => i_id_ref, i_dt_system_date => current_timestamp);
    
        ----------------------
        -- VAL
        ----------------------
        -- mandatory parameters
        g_error := 'Validating mandatory parameters / ' || l_params;
        IF i_reason_code IS NULL
           OR i_num_order IS NULL
        THEN
            g_error      := 'Invalid parameter / ' || l_params;
            g_error_code := pk_ref_constant.g_ref_error_1005;
            g_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => g_error_code);
            RAISE g_exception;
        END IF;
    
        -- getting operation date
        g_error  := 'Call get_operation_date / ' || l_params;
        g_retval := get_operation_date(i_lang    => i_lang,
                                       i_prof    => i_prof,
                                       i_dt_d    => i_date,
                                       o_dt_tstz => g_sysdate_tstz,
                                       o_error   => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        g_error  := 'Call pk_p1_external_request.get_dep_clin_serv / ' || l_params;
        g_retval := pk_p1_external_request.get_dep_clin_serv(i_lang          => i_lang,
                                                             i_id_ref        => i_id_ref,
                                                             o_dep_clin_serv => l_dcs,
                                                             o_error         => o_error);
    
        g_error  := 'Call get_profile_template_inst / ' || l_params;
        g_retval := get_profile_template_inst(i_lang             => i_lang,
                                              i_prof             => i_prof,
                                              i_id_institution   => g_prof_int.institution,
                                              i_id_category      => pk_ref_constant.g_cat_id_med,
                                              o_profile_template => l_id_profile_template,
                                              o_error            => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- validating parameters
        g_error  := 'Call check_requirements / ' || l_params;
        g_retval := check_requirements(i_lang          => i_lang,
                                       i_prof          => g_prof_int,
                                       i_id_ref        => i_id_ref,
                                       i_num_order     => i_num_order,
                                       i_prof_name     => i_prof_name,
                                       i_profile_templ => l_id_profile_template,
                                       i_func          => pk_ref_constant.g_func_d,
                                       i_dcs           => l_dcs, -- to update professional info
                                       i_reason_code   => i_reason_code,
                                       i_reason_type   => pk_ref_constant.g_reason_code_d, -- Sent back by physician 
                                       i_date          => g_sysdate_tstz,
                                       o_flg_valid     => l_flg_valid,
                                       o_prof          => l_prof,
                                       o_error         => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        IF l_flg_valid = pk_ref_constant.g_no
        THEN
            RAISE g_exception;
        END IF;
    
        ----------------------
        -- FUNC
        ----------------------
    
        -- check for workflow id
        g_error  := 'Call pk_p1_external_request.get_id_workflow / ' || l_params;
        g_retval := pk_p1_external_request.get_id_workflow(i_lang        => i_lang,
                                                           i_prof        => l_prof,
                                                           i_id_ref      => i_id_ref,
                                                           o_id_workflow => l_id_workflow,
                                                           o_error       => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        IF l_id_workflow IS NULL
        THEN
            g_error  := 'Call PK_P1_MED_HS.set_status_internal / STATUS=' || pk_ref_constant.g_p1_status_d || ' / ' ||
                        l_params;
            g_retval := pk_p1_med_hs.set_status_internal(i_lang          => i_lang,
                                                         i_prof          => l_prof, -- professional declining the referral
                                                         i_id_p1         => i_id_ref,
                                                         i_action        => pk_ref_constant.g_ref_action_d,
                                                         i_level         => NULL,
                                                         i_prof_dest     => NULL,
                                                         i_dep_clin_serv => NULL,
                                                         i_notes         => i_notes,
                                                         i_dt_modified   => NULL,
                                                         i_mode          => NULL,
                                                         i_reason_code   => i_reason_code,
                                                         i_subtype       => NULL,
                                                         i_inst_dest     => NULL,
                                                         i_date          => g_sysdate_tstz,
                                                         o_track         => o_track,
                                                         o_flg_show      => l_flg_show,
                                                         o_msg_title     => l_msg_title,
                                                         o_msg           => l_msg,
                                                         o_error         => o_error);
        ELSE
            g_error  := 'Call pk_ref_core.set_status / STATUS=' || pk_ref_constant.g_p1_status_d || ' ACTION=' ||
                        pk_ref_constant.g_ref_action_d || ' / ' || l_params;
            g_retval := pk_ref_core.set_status2(i_lang         => i_lang,
                                                i_prof         => l_prof, -- professional declining the referral
                                                i_ext_req      => i_id_ref,
                                                i_status_begin => NULL, -- deprecated
                                                i_status_end   => pk_ref_constant.g_p1_status_d, -- deprecated
                                                i_action       => pk_ref_constant.g_ref_action_d, -- DECLINE
                                                i_level        => NULL,
                                                i_prof_dest    => NULL,
                                                i_dcs          => NULL,
                                                i_notes        => i_notes,
                                                i_dt_modified  => NULL,
                                                i_mode         => NULL,
                                                i_reason_code  => i_reason_code,
                                                i_subtype      => NULL,
                                                i_inst_dest    => NULL,
                                                i_date         => g_sysdate_tstz,
                                                o_track        => o_track,
                                                o_flg_show     => l_flg_show,
                                                o_msg_title    => l_msg_title,
                                                o_msg          => l_msg,
                                                o_error        => o_error);
        END IF;
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- resets the referral context
        pk_ref_utils.reset_ref_context;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            IF g_error_code IS NOT NULL
            THEN
                g_flg_action := pk_ref_constant.g_err_flg_action_u; -- user defined error
            ELSE
                g_error_code := SQLCODE;
                g_error_desc := SQLERRM;
                g_flg_action := pk_ref_constant.g_err_flg_action_s; -- system error
            END IF;
            pk_alert_exceptions.process_error(i_lang        => i_lang,
                                              i_sqlcode     => g_error_code,
                                              i_sqlerrm     => g_error_desc,
                                              i_message     => g_error,
                                              i_owner       => g_package_owner,
                                              i_package     => g_package_name,
                                              i_function    => 'SET_REF_DECLINED',
                                              i_action_type => g_flg_action,
                                              i_action_msg  => NULL,
                                              o_error       => o_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END set_ref_declined;

    /**
    * Declines the referral setting status to 'Y' (Sent back  by clinical director due to lack of data)
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Id professional, institution and software from the Interface
    * @param   i_id_ref         Referral identifier
    * @param   i_num_order      unique number for the physician that is returning the referral
    * @param   i_prof_name      name of the physician that is returning the referral
    * @param   i_reason_code    Decline reason code identifier    
    * @param   i_reason_desc    Decline reason description. Parameter ignored.
    * @param   i_notes          Decision notes
    * @param   i_date           Operation date
    * @param   o_track          Tracking identifiers created due to the status change
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   28-03-2011
    */
    FUNCTION set_ref_declined_cd
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_ref      IN p1_external_request.id_external_request%TYPE,
        i_num_order   IN professional.num_order%TYPE,
        i_prof_name   IN professional.name%TYPE,
        i_reason_code IN p1_reason_code.id_reason_code%TYPE,
        i_reason_desc IN translation.code_translation%TYPE,
        i_notes       IN p1_detail.text%TYPE,
        i_date        IN DATE,
        o_track       OUT table_number,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_params              VARCHAR2(1000 CHAR);
        l_flg_show            VARCHAR2(1000 CHAR);
        l_msg_title           VARCHAR2(1000 CHAR);
        l_msg                 VARCHAR2(1000 CHAR);
        l_prof                profissional; -- professional declining the referral
        l_flg_valid           VARCHAR2(1 CHAR);
        l_dcs                 dep_clin_serv.id_dep_clin_serv%TYPE;
        l_id_workflow         p1_external_request.id_workflow%TYPE;
        l_id_profile_template profile_template.id_profile_template%TYPE;
    BEGIN
        ----------------------
        -- INIT
        ----------------------
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_id_ref=' || i_id_ref || ' i_num_order=' ||
                    i_num_order || ' substr(i_prof_name,1,100)=' || substr(i_prof_name, 1, 100) || ' i_reason_code=' ||
                    i_reason_code || ' i_date=' || i_date;
        g_error  := 'Init set_ref_declined / ' || l_params;
        pk_alertlog.log_debug(g_error);
        reset_vars;
        g_prof_int := pk_p1_interface.set_prof_interface(i_prof);
        o_track    := table_number();
    
        -- sets the referral context
        pk_ref_utils.init_ref_context;
        pk_ref_utils.set_ref_context(i_id_external_request => i_id_ref, i_dt_system_date => current_timestamp);
    
        ----------------------
        -- VAL
        ----------------------
        -- mandatory parameters
        g_error := 'Validating mandatory parameters / ' || l_params;
        IF i_reason_code IS NULL
           OR i_num_order IS NULL
        THEN
            g_error      := 'Invalid parameter / ' || l_params;
            g_error_code := pk_ref_constant.g_ref_error_1005;
            g_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => g_error_code);
            RAISE g_exception;
        END IF;
    
        -- getting operation date
        g_error  := 'Call pk_ref_utils.get_operation_date / ' || l_params;
        g_retval := pk_ref_utils.get_operation_date(i_lang    => i_lang,
                                                    i_prof    => i_prof,
                                                    i_dt_d    => i_date,
                                                    o_dt_tstz => g_sysdate_tstz,
                                                    o_error   => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        g_error  := 'Call pk_p1_external_request.get_dep_clin_serv / ' || l_params;
        g_retval := pk_p1_external_request.get_dep_clin_serv(i_lang          => i_lang,
                                                             i_id_ref        => i_id_ref,
                                                             o_dep_clin_serv => l_dcs,
                                                             o_error         => o_error);
    
        g_error  := 'Call get_profile_template_inst / ' || l_params;
        g_retval := get_profile_template_inst(i_lang             => i_lang,
                                              i_prof             => i_prof,
                                              i_id_institution   => g_prof_int.institution,
                                              i_id_category      => pk_ref_constant.g_cat_id_med,
                                              o_profile_template => l_id_profile_template,
                                              o_error            => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- validating parameters
        g_error  := 'Call check_requirements / ' || l_params;
        g_retval := check_requirements(i_lang          => i_lang,
                                       i_prof          => g_prof_int,
                                       i_id_ref        => i_id_ref,
                                       i_num_order     => i_num_order,
                                       i_prof_name     => i_prof_name,
                                       i_profile_templ => l_id_profile_template,
                                       i_func          => pk_ref_constant.g_ref_func_cd, -- clinical director
                                       i_dcs           => l_dcs, -- to update professional info
                                       i_reason_code   => i_reason_code,
                                       i_reason_type   => pk_ref_constant.g_reason_code_y, -- Sent back by physician 
                                       i_date          => g_sysdate_tstz,
                                       o_flg_valid     => l_flg_valid,
                                       o_prof          => l_prof,
                                       o_error         => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        IF l_flg_valid = pk_ref_constant.g_no
        THEN
            RAISE g_exception;
        END IF;
    
        ----------------------
        -- FUNC
        ----------------------
    
        -- check for workflow id
        g_error  := 'Call pk_p1_external_request.get_id_workflow / ' || l_params;
        g_retval := pk_p1_external_request.get_id_workflow(i_lang        => i_lang,
                                                           i_prof        => l_prof,
                                                           i_id_ref      => i_id_ref,
                                                           o_id_workflow => l_id_workflow,
                                                           o_error       => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        g_error  := 'Call pk_ref_core.set_status / STATUS=' || pk_ref_constant.g_p1_status_d || ' ACTION=' ||
                    pk_ref_constant.g_ref_action_y || ' / ' || l_params;
        g_retval := pk_ref_core.set_status2(i_lang         => i_lang,
                                            i_prof         => l_prof, -- professional declining the referral
                                            i_ext_req      => i_id_ref,
                                            i_status_begin => NULL, -- deprecated
                                            i_status_end   => pk_ref_constant.g_p1_status_y, -- deprecated
                                            i_action       => pk_ref_constant.g_ref_action_y, -- DECLINE
                                            i_level        => NULL,
                                            i_prof_dest    => NULL,
                                            i_dcs          => NULL,
                                            i_notes        => i_notes,
                                            i_dt_modified  => NULL,
                                            i_mode         => NULL,
                                            i_reason_code  => i_reason_code,
                                            i_subtype      => NULL,
                                            i_inst_dest    => NULL,
                                            i_date         => g_sysdate_tstz,
                                            o_track        => o_track,
                                            o_flg_show     => l_flg_show,
                                            o_msg_title    => l_msg_title,
                                            o_msg          => l_msg,
                                            o_error        => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- resets the referral context
        pk_ref_utils.reset_ref_context;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            IF g_error_code IS NOT NULL
            THEN
                g_flg_action := pk_ref_constant.g_err_flg_action_u; -- user defined error
            ELSE
                g_error_code := SQLCODE;
                g_error_desc := SQLERRM;
                g_flg_action := pk_ref_constant.g_err_flg_action_s; -- system error
            END IF;
            pk_alert_exceptions.process_error(i_lang        => i_lang,
                                              i_sqlcode     => g_error_code,
                                              i_sqlerrm     => g_error_desc,
                                              i_message     => g_error,
                                              i_owner       => g_package_owner,
                                              i_package     => g_package_name,
                                              i_function    => 'SET_REF_DECLINED_CD',
                                              i_action_type => g_flg_action,
                                              i_action_msg  => NULL,
                                              o_error       => o_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END set_ref_declined_cd;

    /**
    * Declines the referral to the registrar, setting status to 'I' (issued)
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Id professional, institution and software from the Interface
    * @param   i_id_ref         Referral identifier
    * @param   i_num_order      unique number for the physician that is returning the referral
    * @param   i_prof_name      name of the physician that is returning the referral
    * @param   i_reason_code    Decline reason code identifier    
    * @param   i_reason_desc    Decline reason description. Parameter ignored.
    * @param   i_notes          Decision notes
    * @param   i_date           Operation date
    * @param   o_track          Tracking identifiers created due to the status change
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.6.0.5
    * @since   18-03-2011
    */
    FUNCTION set_ref_declined_to_reg
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_ref      IN p1_external_request.id_external_request%TYPE,
        i_num_order   IN professional.num_order%TYPE,
        i_prof_name   IN professional.name%TYPE,
        i_reason_code IN p1_reason_code.id_reason_code%TYPE,
        i_reason_desc IN translation.code_translation%TYPE,
        i_notes       IN p1_detail.text%TYPE,
        i_date        IN DATE,
        o_track       OUT table_number,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_params              VARCHAR2(1000 CHAR);
        l_flg_show            VARCHAR2(1000 CHAR);
        l_msg_title           VARCHAR2(1000 CHAR);
        l_msg                 VARCHAR2(1000 CHAR);
        l_prof                profissional; -- professional declining the referral
        l_flg_valid           VARCHAR2(1 CHAR);
        l_dcs                 dep_clin_serv.id_dep_clin_serv%TYPE;
        l_id_workflow         p1_external_request.id_workflow%TYPE;
        l_id_profile_template profile_template.id_profile_template%TYPE;
        l_id_inst_dest        p1_external_request.id_inst_dest%TYPE;
    BEGIN
        ----------------------
        -- INIT
        ----------------------
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_id_ref=' || i_id_ref || ' i_num_order=' ||
                    i_num_order || ' substr(i_prof_name,1,100)=' || substr(i_prof_name, 1, 100) || ' i_reason_code=' ||
                    i_reason_code || ' i_date=' || i_date;
    
        g_error := 'Init set_ref_declined_to_reg / ' || l_params;
        pk_alertlog.log_debug(g_error);
        reset_vars;
        g_prof_int := pk_p1_interface.set_prof_interface(i_prof);
        o_track    := table_number();
    
        -- sets the referral context
        pk_ref_utils.init_ref_context;
        pk_ref_utils.set_ref_context(i_id_external_request => i_id_ref, i_dt_system_date => current_timestamp);
    
        ----------------------
        -- VAL
        ----------------------
        -- mandatory parameters
        g_error := 'Validating mandatory parameters / ' || l_params;
        IF i_reason_code IS NULL
           OR i_num_order IS NULL
        THEN
            g_error      := 'Invalid parameter / ' || l_params;
            g_error_code := pk_ref_constant.g_ref_error_1005;
            g_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => g_error_code);
            RAISE g_exception;
        END IF;
    
        -- getting operation date
        g_error  := 'Call pk_ref_utils.get_operation_date / ' || l_params;
        g_retval := pk_ref_utils.get_operation_date(i_lang    => i_lang,
                                                    i_prof    => i_prof,
                                                    i_dt_d    => i_date,
                                                    o_dt_tstz => g_sysdate_tstz,
                                                    o_error   => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        g_error  := 'Call pk_p1_external_request.get_dep_clin_serv / ' || l_params;
        g_retval := pk_p1_external_request.get_dep_clin_serv(i_lang          => i_lang,
                                                             i_id_ref        => i_id_ref,
                                                             o_dep_clin_serv => l_dcs,
                                                             o_error         => o_error);
    
        g_error  := 'Call get_profile_template_inst / ' || l_params;
        g_retval := get_profile_template_inst(i_lang             => i_lang,
                                              i_prof             => i_prof,
                                              i_id_institution   => g_prof_int.institution,
                                              i_id_category      => pk_ref_constant.g_cat_id_med,
                                              o_profile_template => l_id_profile_template,
                                              o_error            => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- check if professional is at dest institution
        g_error  := 'Call pk_p1_external_request.get_id_inst_dest / ' || l_params;
        g_retval := pk_p1_external_request.get_id_inst_dest(i_lang         => i_lang,
                                                            i_prof         => i_prof,
                                                            i_id_ref       => i_id_ref,
                                                            o_id_inst_dest => l_id_inst_dest,
                                                            o_error        => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- validating parameters
        g_error  := 'Call check_requirements / ' || l_params;
        g_retval := check_requirements(i_lang          => i_lang,
                                       i_prof          => g_prof_int,
                                       i_id_ref        => i_id_ref,
                                       i_id_inst       => l_id_inst_dest,
                                       i_num_order     => i_num_order,
                                       i_prof_name     => i_prof_name,
                                       i_profile_templ => l_id_profile_template,
                                       i_func          => pk_ref_constant.g_func_d,
                                       i_dcs           => l_dcs, -- to update professional info
                                       i_reason_code   => i_reason_code,
                                       i_reason_type   => pk_ref_constant.g_reason_code_i,
                                       i_date          => g_sysdate_tstz,
                                       o_flg_valid     => l_flg_valid,
                                       o_prof          => l_prof,
                                       o_error         => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        IF l_flg_valid = pk_ref_constant.g_no
        THEN
            RAISE g_exception;
        END IF;
    
        ----------------------
        -- FUNC
        ----------------------
    
        -- check for workflow id
        g_error  := 'Call pk_p1_external_request.get_id_workflow / ' || l_params;
        g_retval := pk_p1_external_request.get_id_workflow(i_lang        => i_lang,
                                                           i_prof        => l_prof,
                                                           i_id_ref      => i_id_ref,
                                                           o_id_workflow => l_id_workflow,
                                                           o_error       => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        IF l_id_workflow IS NULL
        THEN
            g_error  := 'Call PK_P1_MED_HS.set_status_internal / STATUS=' || pk_ref_constant.g_p1_status_d || ' / ' ||
                        l_params;
            g_retval := pk_p1_med_hs.set_status_internal(i_lang          => i_lang,
                                                         i_prof          => l_prof, -- professional declining the referral
                                                         i_id_p1         => i_id_ref,
                                                         i_action        => pk_ref_constant.g_ref_action_dcl_r, -- DECLINE_TO_REG
                                                         i_level         => NULL,
                                                         i_prof_dest     => NULL,
                                                         i_dep_clin_serv => NULL,
                                                         i_notes         => i_notes,
                                                         i_dt_modified   => NULL,
                                                         i_mode          => NULL,
                                                         i_reason_code   => i_reason_code,
                                                         i_subtype       => NULL,
                                                         i_inst_dest     => NULL,
                                                         i_date          => g_sysdate_tstz,
                                                         o_track         => o_track,
                                                         o_flg_show      => l_flg_show,
                                                         o_msg_title     => l_msg_title,
                                                         o_msg           => l_msg,
                                                         o_error         => o_error);
        ELSE
            g_error  := 'Call pk_ref_core.set_status / STATUS=' || pk_ref_constant.g_p1_status_d || ' ACTION=' ||
                        pk_ref_constant.g_ref_action_d || ' / ' || l_params;
            g_retval := pk_ref_core.set_status2(i_lang         => i_lang,
                                                i_prof         => l_prof, -- professional declining the referral
                                                i_ext_req      => i_id_ref,
                                                i_status_begin => NULL, -- deprecated
                                                i_status_end   => NULL, -- deprecated
                                                i_action       => pk_ref_constant.g_ref_action_dcl_r, -- DECLINE_TO_REG
                                                i_level        => NULL,
                                                i_prof_dest    => NULL,
                                                i_dcs          => NULL,
                                                i_notes        => i_notes,
                                                i_dt_modified  => NULL,
                                                i_mode         => NULL,
                                                i_reason_code  => i_reason_code,
                                                i_subtype      => NULL,
                                                i_inst_dest    => NULL,
                                                i_date         => g_sysdate_tstz,
                                                o_track        => o_track,
                                                o_flg_show     => l_flg_show,
                                                o_msg_title    => l_msg_title,
                                                o_msg          => l_msg,
                                                o_error        => o_error);
        END IF;
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- resets the referral context
        pk_ref_utils.reset_ref_context;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            IF g_error_code IS NOT NULL
            THEN
                g_flg_action := pk_ref_constant.g_err_flg_action_u; -- user defined error
            ELSE
                g_error_code := SQLCODE;
                g_error_desc := SQLERRM;
                g_flg_action := pk_ref_constant.g_err_flg_action_s; -- system error
            END IF;
            pk_alert_exceptions.process_error(i_lang        => i_lang,
                                              i_sqlcode     => g_error_code,
                                              i_sqlerrm     => g_error_desc,
                                              i_message     => g_error,
                                              i_owner       => g_package_owner,
                                              i_package     => g_package_name,
                                              i_function    => 'SET_REF_DECLINED_TO_REG',
                                              i_action_type => g_flg_action,
                                              i_action_msg  => NULL,
                                              o_error       => o_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END set_ref_declined_to_reg;

    /**
    * Editing a document to put it in a received state
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Id professional, institution and software from the Interface
    * @param   i_id_ref         Referral identifier
    * @param   i_id_doc         Document identifier (first id_doc_external)
    * @param   i_flg_received   the file was received or not: {*} Y - yes {*} N - no
    * @param   i_date           date of the operation
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  João Almeida
    * @version 1.0
    * @since   06-10-2009
    */
    FUNCTION set_ref_doc_edit
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_ref       IN p1_external_request.id_external_request%TYPE,
        i_id_doc       IN doc_external.id_doc_external%TYPE,
        i_flg_received IN doc_external.flg_received%TYPE,
        i_date         IN DATE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_flg_valid VARCHAR2(1 CHAR);
        l_prof      profissional;
        l_id_doc    doc_external.id_doc_external%TYPE;
    BEGIN
    
        ----------------------
        -- INIT
        ----------------------
        g_error := 'Init set_ref_doc_edit / ID_REF=' || i_id_ref || ' ID_DOC_EXTERNAL=' || i_id_doc || ' FLG_RECEIVED=' ||
                   i_flg_received;
        pk_alertlog.log_debug(g_error);
        reset_vars;
        g_prof_int := pk_p1_interface.set_prof_interface(i_prof);
        -- sets the referral context
        pk_ref_utils.init_ref_context;
        pk_ref_utils.set_ref_context(i_id_external_request => i_id_ref, i_dt_system_date => current_timestamp);
    
        ----------------------
        -- VAL
        ----------------------
        -- mandatory parameters
        g_error := 'Validating mandatory parameters';
        IF i_id_doc IS NULL
           OR i_flg_received IS NULL
           OR (i_flg_received NOT IN (pk_ref_constant.g_yes, pk_ref_constant.g_no))
        THEN
            g_error      := 'Invalid parameter / ID_REFERRAL=' || i_id_ref || ' ID_DOC=' || i_id_doc ||
                            ' FLG_RECEIVED=' || i_flg_received;
            g_error_code := pk_ref_constant.g_ref_error_1005;
            g_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => g_error_code);
            RAISE g_exception;
        END IF;
    
        -- getting operation date
        g_error  := 'Call get_operation_date / i_dt_d=' || i_date;
        g_retval := get_operation_date(i_lang    => i_lang,
                                       i_prof    => i_prof,
                                       i_dt_d    => i_date,
                                       o_dt_tstz => g_sysdate_tstz,
                                       o_error   => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- validating parameters
        g_error  := 'Call check_requirements';
        g_retval := check_requirements(i_lang      => i_lang,
                                       i_prof      => g_prof_int,
                                       i_id_ref    => i_id_ref,
                                       i_date      => g_sysdate_tstz,
                                       o_flg_valid => l_flg_valid,
                                       o_prof      => l_prof, -- ignored
                                       o_error     => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        IF l_flg_valid = pk_ref_constant.g_no
        THEN
            g_error := 'INVALID PARAMETERS';
            RAISE g_exception;
        END IF;
    
        ----------------------
        -- FUNC
        ----------------------
    
        -- getting the last id_doc_external
        g_error  := 'Calling get_last_doc_external';
        l_id_doc := get_last_doc_external(i_lang => i_lang, i_prof => i_prof, i_id_doc => i_id_doc);
    
        g_error  := 'Call upd_doc_ext_flg_received / ID_REF=' || i_id_ref || ' ID_DOC=' || l_id_doc || ' FLG_RECEIVED=' ||
                    i_flg_received;
        g_retval := upd_doc_ext_flg_received(i_lang         => i_lang,
                                             i_prof         => g_prof_int,
                                             i_id_doc       => l_id_doc, -- last id_doc_external
                                             i_id_ref       => i_id_ref,
                                             i_flg_received => i_flg_received,
                                             o_error        => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- resets the referral context
        pk_ref_utils.reset_ref_context;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            IF g_error_code IS NOT NULL
            THEN
                g_flg_action := pk_ref_constant.g_err_flg_action_u; -- user defined error
            ELSE
                g_error_code := SQLCODE;
                g_error_desc := SQLERRM;
                g_flg_action := pk_ref_constant.g_err_flg_action_s; -- system error
            END IF;
            pk_alert_exceptions.process_error(i_lang        => i_lang,
                                              i_sqlcode     => g_error_code,
                                              i_sqlerrm     => g_error_desc,
                                              i_message     => g_error,
                                              i_owner       => g_package_owner,
                                              i_package     => g_package_name,
                                              i_function    => 'SET_REF_DOC_EDIT',
                                              i_action_type => g_flg_action,
                                              i_action_msg  => NULL,
                                              o_error       => o_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END set_ref_doc_edit;

    /**
    * Gets the last referral notes related to the transition specified
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Professional, institution and software ids
    * @param   i_id_ref         Referral identifier
    * @param   i_notes_type     Type of referral notes
    * @param   o_notes_text     Notes description
    * @param   o_error          An error message, set when return=false
    *
    * @value   i_notes_type     {*} 'C' Cancelation notes 
                                                         {*} 'B' Notes when sending back by administrative clerk 
                                                         {*} 'D' Notes when sending back by the hosp. physician
                                                         {*} 'X' Notes when refusing referral
                                                         {*} 'A1' Notes when triaging referral
                                                         {*} 'A2' Notes when canceling referral schedule                                                         
                                                         {*} 'F' Notes when patient missed the appointment 
                                {*} 'T' Notes when registrar sents the referral to triage
                                {*} 'I1' Notes when orig registrar issues the referral
                                {*} 'I2' Notes when dest triage physician declines the referral to the registrar
                                {*} 'L' Notes when the referral is locked
                                {*} 'Z' Notes when the registrar requests the referral cancellation
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.5
    * @since   2010-04-15
    */
    FUNCTION get_last_notes
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_ref     IN p1_external_request.id_external_request%TYPE,
        i_notes_type IN VARCHAR2,
        o_notes_text OUT p1_detail.text%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        -- notes of a specific flg_status
        CURSOR c_tracking
        (
            x_id_ref     IN p1_external_request.id_external_request%TYPE,
            x_flg_status IN p1_tracking.ext_req_status%TYPE
        ) IS
            SELECT d.text notes_desc
              FROM p1_detail d
              JOIN p1_tracking t
                ON (d.id_external_request = t.id_external_request AND d.id_tracking = t.id_tracking)
             WHERE d.flg_status = pk_ref_constant.g_active
               AND d.id_external_request = x_id_ref
               AND t.flg_type = pk_ref_constant.g_tracking_type_s
               AND t.ext_req_status = x_flg_status
             ORDER BY dt_tracking_tstz DESC;
    
        -- notes 
        CURSOR c_tracking_a
        (
            x_id_ref         IN p1_external_request.id_external_request%TYPE,
            x_flg_sts_actual IN p1_external_request.flg_status%TYPE,
            x_flg_sts_prev   IN VARCHAR2
        ) IS
            SELECT id_tracking
              FROM (SELECT t.id_tracking,
                           ext_req_status actual_status,
                           lag(ext_req_status, 1) over(ORDER BY dt_tracking_tstz) previous_status,
                           t.dt_tracking_tstz
                      FROM p1_tracking t
                     WHERE id_external_request = x_id_ref
                       AND flg_type IN (pk_ref_constant.g_tracking_type_s,
                                        pk_ref_constant.g_tracking_type_p,
                                        pk_ref_constant.g_tracking_type_c))
             WHERE actual_status = x_flg_sts_actual -- actual status
               AND instr(x_flg_sts_prev, previous_status, 1) > 0 -- previous status in (l_status_considered)
             ORDER BY dt_tracking_tstz DESC;
    
        CURSOR c_detail
        (
            x_id_ref   IN p1_external_request.id_external_request%TYPE,
            x_id_track p1_tracking.id_tracking%TYPE
        ) IS
            SELECT d.text notes_desc
              FROM p1_detail d
             WHERE d.flg_status = pk_ref_constant.g_active
               AND d.id_external_request = x_id_ref
               AND d.id_tracking = x_id_track;
    
        CURSOR c_tracking_action
        (
            x_id_ref    IN p1_external_request.id_external_request%TYPE,
            x_id_action IN wf_workflow_action.id_workflow_action%TYPE
        ) IS
            SELECT d.text notes_desc
              FROM p1_detail d
              JOIN p1_tracking t
                ON (t.id_tracking = d.id_tracking AND t.id_external_request = d.id_external_request)
             WHERE d.flg_status = pk_ref_constant.g_active
               AND d.id_external_request = x_id_ref
               AND t.id_workflow_action = x_id_action;
    
        l_notes_type_triage     VARCHAR2(2 CHAR);
        l_notes_type_cancel_sch VARCHAR2(2 CHAR);
        l_notes_type_issue      VARCHAR2(2 CHAR);
        l_notes_type_decl_reg   VARCHAR2(2 CHAR);
    
        l_id_track      p1_tracking.id_tracking%TYPE;
        l_status_actual p1_external_request.flg_status%TYPE;
        l_status_prev   VARCHAR2(50 CHAR);
        l_id_action     wf_workflow_action.id_workflow_action%TYPE;
    BEGIN
        g_error := 'Init get_last_notes / ID_REF=' || i_id_ref || ' NOTES_TYPE=' || i_notes_type;
        pk_alertlog.log_debug(g_error);
        reset_vars;
        -- sets the referral context
        pk_ref_utils.init_ref_context;
        pk_ref_utils.set_ref_context(i_id_external_request => i_id_ref, i_dt_system_date => current_timestamp);
    
        l_notes_type_triage     := 'A1';
        l_notes_type_cancel_sch := 'A2';
    
        l_notes_type_issue    := 'I1'; -- Notes when orig registrar issues the referral
        l_notes_type_decl_reg := 'I2'; -- Notes when dest triage physician declines the referral to the registrar
    
        g_error := 'i_notes_type=' || i_notes_type;
        IF i_notes_type = l_notes_type_triage
        THEN
            l_status_prev   := pk_ref_constant.g_p1_status_t || pk_ref_constant.g_p1_status_r ||
                               pk_ref_constant.g_p1_status_a;
            l_status_actual := pk_ref_constant.g_p1_status_a;
        
        ELSIF i_notes_type = l_notes_type_cancel_sch
        THEN
            l_status_prev   := pk_ref_constant.g_p1_status_s;
            l_status_actual := pk_ref_constant.g_p1_status_a;
        
        ELSIF i_notes_type = l_notes_type_issue
        THEN
            l_status_prev   := pk_ref_constant.g_p1_status_n || pk_ref_constant.g_p1_status_b ||
                               pk_ref_constant.g_p1_status_v;
            l_status_actual := pk_ref_constant.g_p1_status_i;
        
        ELSIF i_notes_type = l_notes_type_decl_reg
        THEN
            l_id_action := pk_ref_constant.get_action_id(pk_ref_constant.g_ref_action_dcl_r);
        END IF;
    
        g_error := 'CASE / i_notes_type=' || i_notes_type;
        CASE
            WHEN i_notes_type IN (pk_ref_constant.g_p1_status_c,
                                  pk_ref_constant.g_p1_status_b,
                                  pk_ref_constant.g_p1_status_d,
                                  pk_ref_constant.g_p1_status_x,
                                  pk_ref_constant.g_p1_status_f,
                                  pk_ref_constant.g_p1_status_t,
                                  pk_ref_constant.g_p1_status_l,
                                  pk_ref_constant.g_p1_status_z) THEN
            
                OPEN c_tracking(i_id_ref, i_notes_type);
                FETCH c_tracking
                    INTO o_notes_text;
                CLOSE c_tracking;
            
            WHEN i_notes_type IN (l_notes_type_triage, l_notes_type_cancel_sch, l_notes_type_issue) THEN
            
                g_error := 'OPEN c_tracking_a / ID_REF=' || i_id_ref || ' NOTES_TYPE=' || i_notes_type ||
                           ' STATUS_ACTUAL=' || l_status_actual || ' STATUS_PREVIOUS=' || l_status_prev;
                OPEN c_tracking_a(x_id_ref         => i_id_ref,
                                  x_flg_sts_actual => l_status_actual,
                                  x_flg_sts_prev   => l_status_prev);
                FETCH c_tracking_a
                    INTO l_id_track;
                CLOSE c_tracking_a;
            
                g_error := 'OPEN c_detail / ID_REF=' || i_id_ref || ' NOTES_TYPE=' || i_notes_type || ' ID_TRACKING=' ||
                           l_id_track;
                OPEN c_detail(i_id_ref, l_id_track);
                FETCH c_detail
                    INTO o_notes_text;
                CLOSE c_detail;
            
            WHEN i_notes_type = l_notes_type_decl_reg THEN
            
                -- can search for id_workflow_action because this field is always set for this feature
                g_error := 'OPEN c_tracking_action / ID_REF=' || i_id_ref || ' NOTES_TYPE=' || i_notes_type ||
                           ' ID_ACTION=' || l_id_action;
                OPEN c_tracking_action(x_id_ref => i_id_ref, x_id_action => l_id_action);
                FETCH c_tracking_action
                    INTO o_notes_text;
                CLOSE c_tracking_action;
            
            ELSE
                g_error := 'INVALID NOTES TYPE / ID_REF=' || i_id_ref || ' NOTES_TYPE=' || i_notes_type;
                RAISE g_exception;
        END CASE;
    
        -- resets the referral context
        pk_ref_utils.reset_ref_context;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_LAST_NOTES',
                                              o_error    => o_error);
            IF c_tracking%ISOPEN
            THEN
                CLOSE c_tracking;
            END IF;
        
            IF c_detail%ISOPEN
            THEN
                CLOSE c_detail;
            END IF;
        
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END get_last_notes;

    ----------------------------------------------------------------------
    -- Integration With OUTPATIENT
    ----------------------------------------------------------------------    

    /**
    * Forwards the referral request to a triage physician: set referral status to 'R' (Re-sent)
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Id professional, institution and software    
    * @param   i_id_ref         Referral identifier
    * @param   i_num_order      Professional order number that is forwarding the referral
    * @param   i_prof_name      Professional name that is forwarding the referral   
    * @param   i_dest_num_order Professional order number to whom the referral is being forwarded
    * @param   i_dest_prof_name Professional name to whom the referral is being forwarded        
    * @param   i_notes          Triage decision notes            
    * @param   i_date           Operation date
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.6
    * @since   29-06-2010
    */
    FUNCTION set_ref_forward
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_ref         IN p1_external_request.id_external_request%TYPE,
        i_num_order      IN professional.num_order%TYPE,
        i_prof_name      IN professional.name%TYPE,
        i_dest_num_order IN professional.num_order%TYPE,
        i_dest_prof_name IN professional.name%TYPE,
        i_notes          IN p1_detail.text%TYPE,
        i_date           IN DATE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_params              VARCHAR2(1000 CHAR);
        l_prof                profissional;
        l_dest_prof           profissional;
        l_flg_valid           VARCHAR2(1 CHAR);
        l_flg_show            VARCHAR2(1 CHAR);
        l_msg_title           VARCHAR2(1000 CHAR);
        l_msg                 VARCHAR2(1000 CHAR);
        l_id_workflow         p1_external_request.id_workflow%TYPE;
        l_track               table_number;
        l_id_profile_template profile_template.id_profile_template%TYPE;
        l_id_inst_dest        p1_external_request.id_inst_dest%TYPE;
    BEGIN
    
        ----------------------
        -- INIT
        ----------------------
        -- referral status is changed from (T)riage to (R)e-sent
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_id_ref=' || i_id_ref || ' i_num_order=' ||
                    i_num_order || ' substr(i_prof_name,1,100)=' || substr(i_prof_name, 1, 100) || ' i_dest_num_order=' ||
                    i_dest_num_order || ' substr(i_dest_prof_name,1,100)=' || substr(i_dest_prof_name, 1, 100) ||
                    ' i_date=' || i_date;
        g_error  := '->Init set_ref_forward / ' || l_params;
        pk_alertlog.log_debug(g_error);
        reset_vars;
        g_prof_int := pk_p1_interface.set_prof_interface(i_prof);
        l_track    := table_number();
    
        -- sets the referral context
        pk_ref_utils.init_ref_context;
        pk_ref_utils.set_ref_context(i_id_external_request => i_id_ref, i_dt_system_date => current_timestamp);
    
        -- getting operation date
        g_error  := 'Call pk_ref_utils.get_operation_date / ' || l_params;
        g_retval := pk_ref_utils.get_operation_date(i_lang    => i_lang,
                                                    i_prof    => i_prof,
                                                    i_dt_d    => i_date,
                                                    o_dt_tstz => g_sysdate_tstz,
                                                    o_error   => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        ----------------------
        -- VAL
        ----------------------
        -- mandatory parameters
        g_error := 'Validating mandatory parameters / ' || l_params;
        IF i_num_order IS NULL
           OR i_dest_num_order IS NULL
        THEN
            g_error      := 'Invalid parameter / ' || l_params;
            g_error_code := pk_ref_constant.g_ref_error_1005;
            g_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => g_error_code);
            RAISE g_exception;
        END IF;
    
        g_error  := 'Call get_profile_template_inst / ' || l_params;
        g_retval := get_profile_template_inst(i_lang             => i_lang,
                                              i_prof             => i_prof,
                                              i_id_institution   => g_prof_int.institution,
                                              i_id_category      => pk_ref_constant.g_cat_id_med,
                                              o_profile_template => l_id_profile_template,
                                              o_error            => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- check if professional is at dest institution
        g_error  := 'Call pk_p1_external_request.get_id_inst_dest / ' || l_params;
        g_retval := pk_p1_external_request.get_id_inst_dest(i_lang         => i_lang,
                                                            i_prof         => i_prof,
                                                            i_id_ref       => i_id_ref,
                                                            o_id_inst_dest => l_id_inst_dest,
                                                            o_error        => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- validating parameters
        g_error  := 'Call check_requirements / ' || l_params;
        g_retval := check_requirements(i_lang          => i_lang,
                                       i_prof          => g_prof_int,
                                       i_id_ref        => i_id_ref,
                                       i_id_inst       => l_id_inst_dest,
                                       i_num_order     => i_num_order,
                                       i_prof_name     => i_prof_name,
                                       i_profile_templ => l_id_profile_template,
                                       i_func          => pk_ref_constant.g_func_d,
                                       i_date          => g_sysdate_tstz,
                                       o_flg_valid     => l_flg_valid,
                                       o_prof          => l_prof, -- professional that has forwarded the referral
                                       o_error         => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        IF l_flg_valid = pk_ref_constant.g_no
        THEN
            RAISE g_exception;
        END IF;
    
        -- dest professional validation        
        g_error  := 'Call check_professional / ' || l_params;
        g_retval := check_professional(i_lang          => i_lang,
                                       i_prof          => g_prof_int,
                                       i_num_order     => i_dest_num_order,
                                       i_prof_name     => i_dest_prof_name,
                                       i_profile_templ => l_id_profile_template,
                                       i_func          => pk_ref_constant.g_func_t,
                                       i_dcs           => NULL,
                                       o_prof          => l_dest_prof,
                                       o_error         => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        ----------------------
        -- FUNC
        ----------------------     
    
        -- check for workflow id
        g_error  := 'Call pk_p1_external_request.get_id_workflow / ' || l_params;
        g_retval := pk_p1_external_request.get_id_workflow(i_lang        => i_lang,
                                                           i_prof        => l_prof,
                                                           i_id_ref      => i_id_ref,
                                                           o_id_workflow => l_id_workflow,
                                                           o_error       => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- setting referral status to 'R'
        IF l_id_workflow IS NULL
        THEN
            g_error  := 'Call PK_P1_MED_HS.set_status_internal / ACTION=FORWARD / ' || l_params;
            g_retval := pk_p1_med_hs.set_status_internal(i_lang          => i_lang,
                                                         i_prof          => l_prof, -- professional that forwarded the referral
                                                         i_id_p1         => i_id_ref,
                                                         i_action        => pk_ref_constant.g_ref_action_r,
                                                         i_level         => NULL,
                                                         i_prof_dest     => l_dest_prof.id, -- professional to whom the referral is being forwarded
                                                         i_dep_clin_serv => NULL,
                                                         i_notes         => i_notes,
                                                         i_dt_modified   => NULL,
                                                         i_mode          => NULL,
                                                         i_reason_code   => NULL,
                                                         i_subtype       => NULL,
                                                         i_inst_dest     => NULL,
                                                         i_date          => g_sysdate_tstz,
                                                         o_track         => l_track,
                                                         o_flg_show      => l_flg_show,
                                                         o_msg_title     => l_msg_title,
                                                         o_msg           => l_msg,
                                                         o_error         => o_error);
        
        ELSE
        
            -- setting referral status to 'R' 
            g_error  := 'Call PK_REF_CORE.set_status / STATUS=' || pk_ref_constant.g_p1_status_r || ' ACTION=' ||
                        pk_ref_constant.g_ref_action_r || ' / ' || l_params;
            g_retval := pk_ref_core.set_status2(i_lang         => i_lang,
                                                i_prof         => l_prof, -- professional that triaged the referral
                                                i_ext_req      => i_id_ref,
                                                i_status_begin => NULL, -- deprecated
                                                i_status_end   => pk_ref_constant.g_p1_status_r, -- deprecated
                                                i_action       => pk_ref_constant.g_ref_action_r, -- FORWARD
                                                i_level        => NULL,
                                                i_prof_dest    => l_dest_prof.id, -- professional to whom the referral is being forwarded
                                                i_dcs          => NULL,
                                                i_notes        => i_notes,
                                                i_dt_modified  => NULL,
                                                i_mode         => NULL,
                                                i_reason_code  => NULL,
                                                i_subtype      => NULL,
                                                i_inst_dest    => NULL,
                                                i_date         => g_sysdate_tstz,
                                                o_track        => l_track,
                                                o_flg_show     => l_flg_show,
                                                o_msg_title    => l_msg_title,
                                                o_msg          => l_msg,
                                                o_error        => o_error);
        END IF;
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- resets the referral context
        pk_ref_utils.reset_ref_context;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            IF g_error_code IS NOT NULL
            THEN
                g_flg_action := pk_ref_constant.g_err_flg_action_u; -- user defined error
            ELSE
                g_error_code := SQLCODE;
                g_error_desc := SQLERRM;
                g_flg_action := pk_ref_constant.g_err_flg_action_s; -- system error
            END IF;
            pk_alert_exceptions.process_error(i_lang        => i_lang,
                                              i_sqlcode     => g_error_code,
                                              i_sqlerrm     => g_error_desc,
                                              i_message     => g_error,
                                              i_owner       => g_package_owner,
                                              i_package     => g_package_name,
                                              i_function    => 'SET_REF_FORWARD',
                                              i_action_type => g_flg_action,
                                              i_action_msg  => NULL,
                                              o_error       => o_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END set_ref_forward;

    /**
    * Notifies the patient of the referral appointment. Set the referral status to 'M' (Patient notified)
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Id professional, institution and software    
    * @param   i_id_ref         Referral identifier
    * @param   i_date           Operation date
    * @param   i_transaction_id SCH 3.0 Transaction id 
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.6
    * @since   29-06-2010
    */
    FUNCTION set_ref_notified
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_ref         IN p1_external_request.id_external_request%TYPE,
        i_date           IN DATE,
        i_transaction_id IN VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_params         VARCHAR2(1000 CHAR);
        l_flg_valid      VARCHAR2(1 CHAR);
        l_flg_show       VARCHAR2(1000 CHAR);
        l_msg_title      VARCHAR2(1000 CHAR);
        l_msg            VARCHAR2(1000 CHAR);
        l_prof           profissional;
        l_id_workflow    p1_external_request.id_workflow%TYPE;
        l_transaction_id VARCHAR2(1000 CHAR);
        l_track          table_number;
        l_id_inst_dest   p1_external_request.id_inst_dest%TYPE;
    BEGIN
    
        ----------------------
        -- INIT
        ----------------------
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_id_ref=' || i_id_ref || ' i_date=' || i_date;
        g_error  := '->Init set_ref_notified / ' || l_params;
        pk_alertlog.log_debug(g_error);
        g_prof_int := pk_p1_interface.set_prof_interface(i_prof);
        reset_vars;
        l_track := table_number();
    
        -- sets the referral context
        pk_ref_utils.init_ref_context;
        pk_ref_utils.set_ref_context(i_id_external_request => i_id_ref, i_dt_system_date => current_timestamp);
    
        ----------------------
        -- VAL
        ----------------------
    
        -- getting operation date
        g_error  := 'Call pk_ref_utils.get_operation_date / ' || l_params;
        g_retval := pk_ref_utils.get_operation_date(i_lang    => i_lang,
                                                    i_prof    => i_prof,
                                                    i_dt_d    => i_date,
                                                    o_dt_tstz => g_sysdate_tstz,
                                                    o_error   => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- validating parameters
        -- do not validate professional i_num_order. this is done inside pk_p1_interface.setscheduling (for now)
        g_error  := 'Call check_requirements / ' || l_params;
        g_retval := check_requirements(i_lang      => i_lang,
                                       i_prof      => g_prof_int,
                                       i_id_ref    => i_id_ref,
                                       i_date      => g_sysdate_tstz,
                                       o_flg_valid => l_flg_valid,
                                       o_prof      => l_prof,
                                       o_error     => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        IF l_flg_valid = pk_ref_constant.g_no
        THEN
            RAISE g_exception;
        END IF;
    
        ----------------------
        -- FUNC
        ----------------------        
        -- get remote transaction for the new scheduler
        g_error          := 'START REMOTE TRANSACTION / ' || l_params;
        l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(i_transaction_id, i_prof);
    
        -- check for workflow id
        g_error  := 'Call pk_p1_external_request.get_id_workflow / ' || l_params;
        g_retval := pk_p1_external_request.get_id_workflow(i_lang        => i_lang,
                                                           i_prof        => g_prof_int,
                                                           i_id_ref      => i_id_ref,
                                                           o_id_workflow => l_id_workflow,
                                                           o_error       => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- setting referral status to 'R'
        IF l_id_workflow IS NULL
        THEN
        
            g_error  := 'Call PK_P1_ADM_HS.set_status_internal / FLG_STATUS=' || pk_ref_constant.g_p1_status_m || ' / ' ||
                        l_params;
            g_retval := pk_p1_adm_hs.set_status_internal(i_lang        => i_lang,
                                                         i_prof        => g_prof_int,
                                                         i_ext_req     => i_id_ref,
                                                         i_status      => pk_ref_constant.g_p1_status_m,
                                                         i_notes       => NULL,
                                                         i_reason_code => NULL,
                                                         i_dcs         => NULL,
                                                         i_date        => g_sysdate_tstz,
                                                         o_track       => l_track,
                                                         o_error       => o_error);
        
        ELSE
            g_error  := 'Call PK_REF_CORE.set_status / FLG_STATUS=' || pk_ref_constant.g_p1_status_m || ' ACTION=' ||
                        pk_ref_constant.g_ref_action_m || ' / ' || l_params;
            g_retval := pk_ref_core.set_status2(i_lang           => i_lang,
                                                i_prof           => g_prof_int,
                                                i_ext_req        => i_id_ref,
                                                i_status_begin   => NULL, -- deprecated
                                                i_status_end     => pk_ref_constant.g_p1_status_m, -- deprecated
                                                i_action         => pk_ref_constant.g_ref_action_m, -- MAIL
                                                i_level          => NULL,
                                                i_prof_dest      => NULL,
                                                i_dcs            => NULL,
                                                i_notes          => NULL,
                                                i_dt_modified    => NULL,
                                                i_mode           => NULL,
                                                i_reason_code    => NULL,
                                                i_subtype        => NULL,
                                                i_inst_dest      => NULL,
                                                i_date           => g_sysdate_tstz,
                                                i_transaction_id => l_transaction_id,
                                                o_track          => l_track,
                                                o_flg_show       => l_flg_show,
                                                o_msg_title      => l_msg_title,
                                                o_msg            => l_msg,
                                                o_error          => o_error);
        END IF;
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        --only  if not started from external interfaces
        g_error := 'i_transaction_id=' || i_transaction_id || ' / ' || l_params;
        IF i_transaction_id IS NULL
        THEN
            pk_schedule_api_upstream.do_commit(l_transaction_id, i_prof);
        END IF;
    
        -- resets the referral context
        pk_ref_utils.reset_ref_context;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            IF g_error_code IS NOT NULL
            THEN
                g_flg_action := pk_ref_constant.g_err_flg_action_u; -- user defined error
            ELSE
                g_error_code := SQLCODE;
                g_error_desc := SQLERRM;
                g_flg_action := pk_ref_constant.g_err_flg_action_s; -- system error
            END IF;
            pk_alert_exceptions.process_error(i_lang        => i_lang,
                                              i_sqlcode     => g_error_code,
                                              i_sqlerrm     => g_error_desc,
                                              i_message     => g_error,
                                              i_owner       => g_package_owner,
                                              i_package     => g_package_name,
                                              i_function    => 'SET_REF_NOTIFIED',
                                              i_action_type => g_flg_action,
                                              i_action_msg  => NULL,
                                              o_error       => o_error);
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END set_ref_notified;

    /**
    * Notifies the patient of the referral appointment. Set the referral status to 'M' (Patient notified)
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Id professional, institution and software    
    * @param   i_id_ref         Referral identifier
    * @param   i_date           Operation date
    * @param   i_transaction_id SCH 3.0 Transaction id 
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.6
    * @since   29-06-2010
    */
    FUNCTION set_ref_notified
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_id_ref IN p1_external_request.id_external_request%TYPE,
        i_date   IN DATE,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_error := 'Init set_ref_notified 2';
        reset_vars;
        RETURN set_ref_notified(i_lang           => i_lang,
                                i_prof           => i_prof,
                                i_id_ref         => i_id_ref,
                                i_date           => i_date,
                                i_transaction_id => NULL,
                                o_error          => o_error);
    END set_ref_notified;

    /**
    * Sets referral status to 'K' (Reply read)
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Id professional, institution and software    
    * @param   i_id_ref         Referral identifier    
    * @param   i_num_order      Professional order number who is canceling the referral
    * @param   i_prof_name      Professional name who is canceling the referral
    * @param   i_date           Operation date    
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.6
    * @since   29-06-2010
    */
    FUNCTION set_ref_answer_read
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_ref    IN p1_external_request.id_external_request%TYPE,
        i_num_order IN professional.num_order%TYPE,
        i_prof_name IN professional.name%TYPE,
        i_date      IN DATE,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_params       VARCHAR2(1000 CHAR);
        l_flg_valid    VARCHAR2(1 CHAR);
        l_prof         profissional;
        l_is_prof_resp PLS_INTEGER;
        l_track_row    p1_tracking%ROWTYPE;
        l_id_workflow  p1_external_request.id_workflow%TYPE;
        l_flg_show     VARCHAR2(1000 CHAR);
        l_msg_title    VARCHAR2(1000 CHAR);
        l_msg          VARCHAR2(1000 CHAR);
        o_track        table_number;
    BEGIN
        ----------------------
        -- INIT
        ----------------------        
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_id_ref=' || i_id_ref || ' i_num_order=' ||
                    i_num_order || ' substr(i_prof_name,1,100)=' || substr(i_prof_name, 1, 100) || ' i_date=' || i_date;
        g_error  := '->Init set_ref_answer_read / ' || l_params;
        pk_alertlog.log_debug(g_error);
        reset_vars;
        g_prof_int := pk_p1_interface.set_prof_interface(i_prof);
        o_track    := table_number();
    
        -- sets the referral context
        pk_ref_utils.init_ref_context;
        pk_ref_utils.set_ref_context(i_id_external_request => i_id_ref, i_dt_system_date => current_timestamp);
    
        -- getting operation date
        g_error  := 'Call pk_ref_utils.get_operation_date / ' || l_params;
        g_retval := pk_ref_utils.get_operation_date(i_lang    => i_lang,
                                                    i_prof    => i_prof,
                                                    i_dt_d    => i_date,
                                                    o_dt_tstz => g_sysdate_tstz,
                                                    o_error   => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        ----------------------
        -- VAL
        ----------------------  
        -- mandatory parameters
        g_error := 'Validating mandatory parameters / ' || l_params;
        IF i_num_order IS NULL
        THEN
            g_error      := 'Invalid parameter / ' || l_params;
            g_error_code := pk_ref_constant.g_ref_error_1005;
            g_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => g_error_code);
            RAISE g_exception;
        END IF;
    
        -- validating parameters
        g_error  := 'Call check_requirements / ' || l_params;
        g_retval := check_requirements(i_lang      => i_lang,
                                       i_prof      => g_prof_int,
                                       i_id_ref    => i_id_ref,
                                       i_num_order => i_num_order,
                                       i_prof_name => i_prof_name,
                                       i_date      => g_sysdate_tstz,
                                       o_flg_valid => l_flg_valid,
                                       o_prof      => l_prof, -- professional that is reading the answer
                                       o_error     => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        IF l_flg_valid = pk_ref_constant.g_no
        THEN
            RAISE g_exception;
        END IF;
    
        ----------------------
        -- FUNC
        ---------------------- 
    
        -- check for workflow id
        g_error  := 'Call pk_p1_external_request.get_id_workflow / ' || l_params;
        g_retval := pk_p1_external_request.get_id_workflow(i_lang        => i_lang,
                                                           i_prof        => g_prof_int,
                                                           i_id_ref      => i_id_ref,
                                                           o_id_workflow => l_id_workflow,
                                                           o_error       => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        IF l_id_workflow IS NULL
        THEN
        
            -- this code is similar to the tail of function PK_P1_CORE.get_p1_detail_new
        
            -- professional can change referral status only if is the professional that requested the referral            
            g_error        := 'Call pk_p1_external_request.check_prof_resp / ID_PROF=' || l_prof.id || ' / ' ||
                              l_params;
            l_is_prof_resp := pk_p1_external_request.check_prof_resp(i_lang   => i_lang,
                                                                     i_prof   => l_prof,
                                                                     i_id_ref => i_id_ref);
        
            IF l_is_prof_resp = 1
            THEN
            
                -- Changing status
                g_error                         := 'UPDATE STATUS: ' || pk_ref_constant.g_p1_status_k || ' / ' ||
                                                   l_params;
                l_track_row.id_external_request := i_id_ref;
                l_track_row.ext_req_status      := pk_ref_constant.g_p1_status_k;
                l_track_row.flg_type            := pk_ref_constant.g_tracking_type_s;
                l_track_row.dt_tracking_tstz    := g_sysdate_tstz;
                l_track_row.id_workflow_action  := pk_ref_constant.get_action_id(pk_ref_constant.g_ref_action_k);
            
                g_error  := 'Call pk_p1_core.update_status / I_PROF=' || pk_utils.to_string(l_prof) || ' / ' ||
                            l_params;
                g_retval := pk_p1_core.update_status(i_lang        => i_lang,
                                                     i_prof        => l_prof,
                                                     i_track_row   => l_track_row,
                                                     i_old_status  => pk_ref_constant.g_p1_status_w,
                                                     i_flg_isencao => NULL,
                                                     i_mcdt_nature => NULL,
                                                     o_track       => o_track,
                                                     o_error       => o_error);
            
                IF NOT g_retval
                THEN
                    RAISE g_exception_np;
                END IF;
            
            ELSE
                -- this professional is not the one that is responsible for this referral
                g_error := 'Professional ID=' || l_prof.id || ' is not responsible for referral ID=' || i_id_ref ||
                           ' / ' || l_params;
                RAISE g_exception;
            END IF;
        
        ELSE
        
            -- changing referral status
            g_error  := 'Call PK_REF_CORE.set_status / FLG_STATUS=' || pk_ref_constant.g_p1_status_k || ' ACTION=' ||
                        pk_ref_constant.g_ref_action_k || ' / ' || l_params;
            g_retval := pk_ref_core.set_status2(i_lang         => i_lang,
                                                i_prof         => g_prof_int,
                                                i_ext_req      => i_id_ref,
                                                i_status_begin => NULL, -- deprecated
                                                i_status_end   => pk_ref_constant.g_p1_status_k, -- deprecated
                                                i_action       => pk_ref_constant.g_ref_action_k, -- ANSWER_READ
                                                i_level        => NULL,
                                                i_prof_dest    => NULL,
                                                i_dcs          => NULL,
                                                i_notes        => NULL,
                                                i_dt_modified  => NULL,
                                                i_mode         => NULL,
                                                i_reason_code  => NULL,
                                                i_subtype      => NULL,
                                                i_inst_dest    => NULL,
                                                i_date         => g_sysdate_tstz,
                                                o_track        => o_track,
                                                o_flg_show     => l_flg_show,
                                                o_msg_title    => l_msg_title,
                                                o_msg          => l_msg,
                                                o_error        => o_error);
        
            IF NOT g_retval
            THEN
                RAISE g_exception_np;
            END IF;
        
        END IF;
    
        -- resets the referral context
        pk_ref_utils.reset_ref_context;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            IF g_error_code IS NOT NULL
            THEN
                g_flg_action := pk_ref_constant.g_err_flg_action_u;
            ELSE
                g_error_code := SQLCODE;
                g_error_desc := SQLERRM;
                g_flg_action := pk_ref_constant.g_err_flg_action_s;
            END IF;
            pk_alert_exceptions.process_error(i_lang        => i_lang,
                                              i_sqlcode     => g_error_code,
                                              i_sqlerrm     => g_error_desc,
                                              i_message     => g_error,
                                              i_owner       => g_package_owner,
                                              i_package     => g_package_name,
                                              i_function    => 'SET_REF_ANSWER_READ',
                                              i_action_type => g_flg_action,
                                              i_action_msg  => NULL,
                                              o_error       => o_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END set_ref_answer_read;

    /**
    * Blocks the referral: set referral status to 'L' (bLocked)
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Id professional, institution and software    
    * @param   i_id_ref         Referral identifier
    * @param   i_date           Operation date
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.6
    * @since   29-06-2010
    */
    FUNCTION set_ref_blocked
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_id_ref IN p1_external_request.id_external_request%TYPE,
        i_notes  IN p1_detail.text%TYPE, -- parameter ignored
        i_date   IN DATE,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
        l_prof      profissional;
        l_flg_valid VARCHAR2(1 CHAR);
        l_prof_data t_rec_prof_data; -- professional data
        l_ref_row   p1_external_request%ROWTYPE;
    BEGIN
    
        ----------------------
        -- INIT
        ----------------------
        -- referral status is changed from (T)riage to (R)e-sent
        g_error := '->Init set_ref_blocked / ID_REF=' || i_id_ref || ' DATE=' || i_date;
        pk_alertlog.log_debug(g_error);
        reset_vars;
        g_prof_int := pk_p1_interface.set_prof_interface(i_prof);
        -- sets the referral context
        pk_ref_utils.init_ref_context;
        pk_ref_utils.set_ref_context(i_id_external_request => i_id_ref, i_dt_system_date => current_timestamp);
    
        -- getting operation date
        g_error  := 'Call pk_ref_utils.get_operation_date / i_dt_d=' || i_date;
        g_retval := pk_ref_utils.get_operation_date(i_lang    => i_lang,
                                                    i_prof    => i_prof,
                                                    i_dt_d    => i_date,
                                                    o_dt_tstz => g_sysdate_tstz,
                                                    o_error   => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        ----------------------
        -- VAL
        ----------------------
        -- validating parameters
        g_error  := 'Call check_requirements';
        g_retval := check_requirements(i_lang      => i_lang,
                                       i_prof      => g_prof_int,
                                       i_id_ref    => i_id_ref,
                                       i_date      => g_sysdate_tstz,
                                       o_flg_valid => l_flg_valid,
                                       o_prof      => l_prof, -- professional that has forwarded the referral
                                       o_error     => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        IF l_flg_valid = pk_ref_constant.g_no
        THEN
            g_error := 'INVALID PARAMETERS';
            RAISE g_exception;
        END IF;
    
        ----------------------
        -- FUNC
        ----------------------     
    
        -- getting professional data
        g_error  := 'Calling get_prof_data';
        g_retval := pk_ref_core.get_prof_data(i_lang      => i_lang,
                                              i_prof      => g_prof_int,
                                              i_dcs       => NULL,
                                              o_prof_data => l_prof_data,
                                              o_error     => o_error);
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        g_error  := 'Call pk_p1_external_request.get_ref_row / ID_REF=' || i_id_ref;
        g_retval := pk_p1_external_request.get_ref_row(i_lang   => i_lang,
                                                       i_prof   => g_prof_int,
                                                       i_id_ref => i_id_ref,
                                                       o_rec    => l_ref_row,
                                                       o_error  => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- setting referral status to 'L'
        g_error  := 'Call PK_REF_PIO.set_ref_blocked / ID_REF=' || i_id_ref;
        g_retval := pk_ref_pio.set_ref_blocked(i_lang      => i_lang,
                                               i_prof      => g_prof_int,
                                               i_prof_data => l_prof_data,
                                               i_ref_row   => l_ref_row,
                                               i_date      => g_sysdate_tstz,
                                               o_error     => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- resets the referral context
        pk_ref_utils.reset_ref_context;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            IF g_error_code IS NOT NULL
            THEN
                g_flg_action := pk_ref_constant.g_err_flg_action_u; -- user defined error
            ELSE
                g_error_code := SQLCODE;
                g_error_desc := SQLERRM;
                g_flg_action := pk_ref_constant.g_err_flg_action_s; -- system error
            END IF;
            pk_alert_exceptions.process_error(i_lang        => i_lang,
                                              i_sqlcode     => g_error_code,
                                              i_sqlerrm     => g_error_desc,
                                              i_message     => g_error,
                                              i_owner       => g_package_owner,
                                              i_package     => g_package_name,
                                              i_function    => 'SET_REF_BLOCKED',
                                              i_action_type => g_flg_action,
                                              i_action_msg  => NULL,
                                              o_error       => o_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END set_ref_blocked;

    /**
    * Unblocks the referral: set referral status to the previous status before b(L)ocked
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Id professional, institution and software    
    * @param   i_id_ref         Referral identifier
    * @param   i_notes          Triage decision notes            
    * @param   i_date           Operation date
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.6
    * @since   29-06-2010
    */
    FUNCTION set_ref_unblocked
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_id_ref IN p1_external_request.id_external_request%TYPE,
        i_notes  IN p1_detail.text%TYPE, -- parameter ignored
        i_date   IN DATE,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
        l_prof      profissional;
        l_flg_valid VARCHAR2(1 CHAR);
        l_prof_data t_rec_prof_data; -- professional data
        l_ref_row   p1_external_request%ROWTYPE;
    BEGIN
    
        ----------------------
        -- INIT
        ----------------------
        -- referral status is changed from (T)riage to (R)e-sent
        g_error := '->Init set_ref_unblocked / ID_REF=' || i_id_ref || ' DATE=' || i_date;
        pk_alertlog.log_debug(g_error);
        reset_vars;
        g_prof_int := pk_p1_interface.set_prof_interface(i_prof);
        -- sets the referral context
        pk_ref_utils.init_ref_context;
        pk_ref_utils.set_ref_context(i_id_external_request => i_id_ref, i_dt_system_date => current_timestamp);
    
        -- getting operation date
        g_error  := 'Call pk_ref_utils.get_operation_date / i_dt_d=' || i_date;
        g_retval := pk_ref_utils.get_operation_date(i_lang    => i_lang,
                                                    i_prof    => i_prof,
                                                    i_dt_d    => i_date,
                                                    o_dt_tstz => g_sysdate_tstz,
                                                    o_error   => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        ----------------------
        -- VAL
        ----------------------
        -- validating parameters
        g_error  := 'Call check_requirements';
        g_retval := check_requirements(i_lang      => i_lang,
                                       i_prof      => g_prof_int,
                                       i_id_ref    => i_id_ref,
                                       i_date      => g_sysdate_tstz,
                                       o_flg_valid => l_flg_valid,
                                       o_prof      => l_prof, -- professional that has forwarded the referral
                                       o_error     => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        IF l_flg_valid = pk_ref_constant.g_no
        THEN
            g_error := 'INVALID PARAMETERS';
            RAISE g_exception;
        END IF;
    
        ----------------------
        -- FUNC
        ----------------------     
    
        -- getting professional data
        g_error  := 'Calling get_prof_data';
        g_retval := pk_ref_core.get_prof_data(i_lang      => i_lang,
                                              i_prof      => g_prof_int,
                                              i_dcs       => NULL,
                                              o_prof_data => l_prof_data,
                                              o_error     => o_error);
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        g_error  := 'Call pk_p1_external_request.get_ref_row / ID_REF=' || i_id_ref;
        g_retval := pk_p1_external_request.get_ref_row(i_lang   => i_lang,
                                                       i_prof   => g_prof_int,
                                                       i_id_ref => i_id_ref,
                                                       o_rec    => l_ref_row,
                                                       o_error  => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- setting referral status to 'L'
        g_error  := 'Call PK_REF_PIO.set_ref_blocked / ID_REF=' || i_id_ref;
        g_retval := pk_ref_pio.set_ref_unblocked(i_lang      => i_lang,
                                                 i_prof      => g_prof_int,
                                                 i_prof_data => l_prof_data,
                                                 i_ref_row   => l_ref_row,
                                                 i_date      => g_sysdate_tstz,
                                                 o_error     => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- resets the referral context
        pk_ref_utils.reset_ref_context;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            IF g_error_code IS NOT NULL
            THEN
                g_flg_action := pk_ref_constant.g_err_flg_action_u; -- user defined error
            ELSE
                g_error_code := SQLCODE;
                g_error_desc := SQLERRM;
                g_flg_action := pk_ref_constant.g_err_flg_action_s; -- system error
            END IF;
            pk_alert_exceptions.process_error(i_lang        => i_lang,
                                              i_sqlcode     => g_error_code,
                                              i_sqlerrm     => g_error_desc,
                                              i_message     => g_error,
                                              i_owner       => g_package_owner,
                                              i_package     => g_package_name,
                                              i_function    => 'SET_REF_UNBLOCKED',
                                              i_action_type => g_flg_action,
                                              i_action_msg  => NULL,
                                              o_error       => o_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END set_ref_unblocked;

    /**
    * This function requests a referral cancellation.
    * Changes referral status to 'Z'.
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Id professional, institution and software    
    * @param   i_id_ref         Referral identifier
    * @param   i_id_reason_code Reason code identifier
    * @param   i_notes          Notes of the cancellation request
    * @param   i_date           Operation date
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.6
    * @since   17-09-2010
    */
    FUNCTION set_ref_req_cancel
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_ref         IN p1_external_request.id_external_request%TYPE,
        i_id_reason_code IN p1_reason_code.id_reason_code%TYPE,
        i_notes          IN p1_detail.text%TYPE,
        i_date           IN DATE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_prof        profissional;
        l_flg_valid   VARCHAR2(1 CHAR);
        l_id_workflow p1_external_request.id_workflow%TYPE;
    
        l_flg_show  VARCHAR2(1 CHAR);
        l_msg_title VARCHAR2(1000 CHAR);
        l_msg       VARCHAR2(1000 CHAR);
        l_track     table_number;
    BEGIN
    
        ----------------------
        -- INIT
        ----------------------
        g_error := '->Init set_ref_req_cancel / ID_REF=' || i_id_ref || ' ID_REASON_CODE=' || i_id_reason_code ||
                   ' DATE=' || i_date;
        pk_alertlog.log_debug(g_error);
        reset_vars;
        g_prof_int := pk_p1_interface.set_prof_interface(i_prof);
        l_track    := table_number();
    
        -- sets the referral context
        pk_ref_utils.init_ref_context;
        pk_ref_utils.set_ref_context(i_id_external_request => i_id_ref, i_dt_system_date => current_timestamp);
    
        -- mandatory parameters   
        g_error := 'Validating mandatory parameters';
        IF i_id_reason_code IS NULL
        THEN
            g_error      := 'Invalid parameter / ID_REFERRAL=' || i_id_ref || ' ID_REASON_CODE= ' || i_id_reason_code;
            g_error_code := pk_ref_constant.g_ref_error_1005;
            g_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => g_error_code);
            RAISE g_exception;
        END IF;
    
        -- getting operation date
        g_error  := 'Call pk_ref_utils.get_operation_date / i_dt_d=' || i_date;
        g_retval := pk_ref_utils.get_operation_date(i_lang    => i_lang,
                                                    i_prof    => i_prof,
                                                    i_dt_d    => i_date,
                                                    o_dt_tstz => g_sysdate_tstz,
                                                    o_error   => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        ----------------------
        -- VAL
        ----------------------
        -- validating parameters
        g_error  := 'Call check_requirements';
        g_retval := check_requirements(i_lang        => i_lang,
                                       i_prof        => g_prof_int,
                                       i_id_ref      => i_id_ref,
                                       i_date        => g_sysdate_tstz,
                                       i_reason_code => i_id_reason_code,
                                       i_reason_type => pk_ref_constant.g_reason_code_z,
                                       o_flg_valid   => l_flg_valid,
                                       o_prof        => l_prof, -- ignored
                                       o_error       => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        IF l_flg_valid = pk_ref_constant.g_no
        THEN
            g_error      := 'INVALID PARAMETERS';
            g_error_code := pk_ref_constant.g_ref_error_1005;
            g_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => g_error_code);
            RAISE g_exception;
        END IF;
    
        ----------------------
        -- FUNC
        ----------------------    
    
        -- check for workflow id
        g_error  := 'Call pk_p1_external_request.get_id_workflow / ID_REF=' || i_id_ref;
        g_retval := pk_p1_external_request.get_id_workflow(i_lang        => i_lang,
                                                           i_prof        => g_prof_int,
                                                           i_id_ref      => i_id_ref,
                                                           o_id_workflow => l_id_workflow,
                                                           o_error       => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        IF l_id_workflow IS NULL
        THEN
            -- only registrar from dest institution can do this action (in SOA)
            g_error  := 'Call pk_p1_adm_hs.set_status_internal / ID_REF=' || i_id_ref || ' REASON CODE= ' ||
                        i_id_reason_code || ' ACTION=' || pk_ref_constant.g_ref_action_z;
            g_retval := pk_p1_adm_hs.set_status_internal(i_lang        => i_lang,
                                                         i_prof        => g_prof_int,
                                                         i_ext_req     => i_id_ref,
                                                         i_status      => pk_ref_constant.g_ref_action_z, -- CANCEL_REQ
                                                         i_notes       => i_notes,
                                                         i_reason_code => i_id_reason_code,
                                                         i_dcs         => NULL,
                                                         i_date        => g_sysdate_tstz,
                                                         o_track       => l_track,
                                                         o_error       => o_error);
        
        ELSE
        
            g_error  := 'Call pk_ref_core.set_status / ID_REFERRAL=' || i_id_ref || ' STATUS=' ||
                        pk_ref_constant.g_p1_status_z || ' REASON CODE= ' || i_id_reason_code || ' ACTION=' ||
                        pk_ref_constant.g_ref_action_z;
            g_retval := pk_ref_core.set_status2(i_lang         => i_lang,
                                                i_prof         => g_prof_int,
                                                i_ext_req      => i_id_ref,
                                                i_status_begin => NULL, -- deprecated
                                                i_status_end   => pk_ref_constant.g_p1_status_z,
                                                i_action       => pk_ref_constant.g_ref_action_z, -- CANCEL_REQ
                                                i_level        => NULL,
                                                i_prof_dest    => NULL,
                                                i_dcs          => NULL,
                                                i_notes        => i_notes,
                                                i_dt_modified  => NULL,
                                                i_mode         => NULL,
                                                i_reason_code  => i_id_reason_code,
                                                i_subtype      => NULL,
                                                i_inst_dest    => NULL,
                                                i_date         => g_sysdate_tstz,
                                                o_track        => l_track,
                                                o_flg_show     => l_flg_show,
                                                o_msg_title    => l_msg_title,
                                                o_msg          => l_msg,
                                                o_error        => o_error);
        
        END IF;
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- resets the referral context
        pk_ref_utils.reset_ref_context;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            IF g_error_code IS NOT NULL
            THEN
                g_flg_action := pk_ref_constant.g_err_flg_action_u; -- user defined error
            ELSE
                g_error_code := SQLCODE;
                g_error_desc := SQLERRM;
                g_flg_action := pk_ref_constant.g_err_flg_action_s; -- system error
            END IF;
            pk_alert_exceptions.process_error(i_lang        => i_lang,
                                              i_sqlcode     => g_error_code,
                                              i_sqlerrm     => g_error_desc,
                                              i_message     => g_error,
                                              i_owner       => g_package_owner,
                                              i_package     => g_package_name,
                                              i_function    => 'SET_REF_REQ_CANCEL',
                                              i_action_type => g_flg_action,
                                              i_action_msg  => NULL,
                                              o_error       => o_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END set_ref_req_cancel;

    /**
    * This function denies a referral request cancellation.
    * This action can be done by the physician (answering to a registrar request) or can be done by the registrar (cancelling
    * his own cancellation request)
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Id professional, institution and software    
    * @param   i_id_ref         Referral identifier                      
    * @param   i_num_order      Professional order number who performing this action (in case of a physician)
    * @param   i_prof_name      Professional name who performing this action
    * @param   i_notes          Notes of the cancellation request
    * @param   i_date           Operation date
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.6
    * @since   17-09-2010
    */
    FUNCTION set_ref_req_cancel_deny
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_ref    IN p1_external_request.id_external_request%TYPE,
        i_num_order IN professional.num_order%TYPE,
        i_prof_name IN professional.name%TYPE,
        i_notes     IN p1_detail.text%TYPE,
        i_date      IN DATE,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_prof        profissional;
        l_flg_valid   VARCHAR2(1 CHAR);
        l_id_workflow p1_external_request.id_workflow%TYPE;
        l_id_prof_req p1_external_request.id_prof_requested%TYPE;
    
        l_flg_show  VARCHAR2(1 CHAR);
        l_msg_title VARCHAR2(1000 CHAR);
        l_msg       VARCHAR2(1000 CHAR);
        l_track     table_number;
    
        CURSOR c_ref IS
            SELECT id_prof_requested, id_workflow
              FROM p1_external_request
             WHERE id_external_request = i_id_ref;
    BEGIN
    
        ----------------------
        -- INIT
        ----------------------
        g_error := '->Init set_ref_req_cancel_deny / ID_REF=' || i_id_ref || ' NUM_ORDER=' || i_num_order || ' DATE=' ||
                   i_date;
        pk_alertlog.log_debug(g_error);
        reset_vars;
        g_prof_int := pk_p1_interface.set_prof_interface(i_prof);
        l_track    := table_number();
    
        -- sets the referral context
        pk_ref_utils.init_ref_context;
        pk_ref_utils.set_ref_context(i_id_external_request => i_id_ref, i_dt_system_date => current_timestamp);
    
        -- getting operation date
        g_error  := 'Call pk_ref_utils.get_operation_date / i_dt_d=' || i_date;
        g_retval := pk_ref_utils.get_operation_date(i_lang    => i_lang,
                                                    i_prof    => i_prof,
                                                    i_dt_d    => i_date,
                                                    o_dt_tstz => g_sysdate_tstz,
                                                    o_error   => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        ----------------------
        -- VAL
        ----------------------
        -- validating parameters
        g_error  := 'Call check_requirements';
        g_retval := check_requirements(i_lang      => i_lang,
                                       i_prof      => g_prof_int,
                                       i_num_order => i_num_order,
                                       i_prof_name => i_prof_name,
                                       i_id_ref    => i_id_ref,
                                       i_date      => g_sysdate_tstz,
                                       o_flg_valid => l_flg_valid,
                                       o_prof      => l_prof,
                                       o_error     => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        IF l_flg_valid = pk_ref_constant.g_no
        THEN
            g_error := 'INVALID PARAMETERS';
            RAISE g_exception;
        END IF;
    
        g_error := 'OPEN c_ref';
        OPEN c_ref;
        FETCH c_ref
            INTO l_id_prof_req, l_id_workflow;
        CLOSE c_ref;
    
        IF l_id_prof_req IS NULL
        THEN
            g_error      := 'Professional requested is null / ID_REF=' || i_id_ref;
            g_error_code := pk_ref_constant.g_ref_error_1007;
            g_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => g_error_code);
            RAISE g_exception;
        END IF;
    
        -- check if physician is the professional who requested the referral
        IF i_num_order IS NOT NULL
        THEN
            -- physician
            g_error := 'Physician';
            IF l_prof.id != l_id_prof_req
            THEN
                g_error      := 'Professional with num order ' || i_num_order ||
                                ' is not the professional that requested the referral / ID_PROF_REQ=' || l_id_prof_req ||
                                ' ID_PROF=' || l_prof.id;
                g_error_code := pk_ref_constant.g_ref_error_1009;
                g_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => g_error_code);
                RAISE g_exception;
            END IF;
        ELSE
            -- registrar
            g_error := 'Registrar';
            l_prof  := g_prof_int;
        END IF;
    
        ----------------------
        -- FUNC
        ----------------------    
        IF l_id_workflow IS NULL
        THEN
        
            IF i_num_order IS NULL
            THEN
                -- registrar
                g_error  := 'Call pk_p1_adm_hs.set_status_internal / ID_REF=' || i_id_ref || ' ACTION=' ||
                            pk_ref_constant.g_ref_action_zdn;
                g_retval := pk_p1_adm_hs.set_status_internal(i_lang        => i_lang,
                                                             i_prof        => l_prof,
                                                             i_ext_req     => i_id_ref,
                                                             i_status      => pk_ref_constant.g_ref_action_zdn, -- CANCEL_REQ_DENY
                                                             i_notes       => i_notes,
                                                             i_reason_code => NULL,
                                                             i_dcs         => NULL,
                                                             i_date        => g_sysdate_tstz,
                                                             o_track       => l_track,
                                                             o_error       => o_error);
            
            ELSE
                -- physician
            
                g_error  := 'Call pk_p1_med_cs.decline_req_cancellation / ID_REF=' || i_id_ref || ' ACTION=' ||
                            pk_ref_constant.g_ref_action_zdn;
                g_retval := pk_p1_med_cs.decline_req_cancellation(i_lang    => i_lang,
                                                                  i_prof    => l_prof,
                                                                  i_id_ref  => i_id_ref,
                                                                  i_notes   => i_notes,
                                                                  i_op_date => g_sysdate_tstz,
                                                                  o_error   => o_error);
            
            END IF;
        ELSE
        
            g_error  := 'Call pk_ref_core.set_status / ID_REFERRAL=' || i_id_ref || ' ACTION=' ||
                        pk_ref_constant.g_ref_action_zdn;
            g_retval := pk_ref_core.set_status2(i_lang         => i_lang,
                                                i_prof         => l_prof,
                                                i_ext_req      => i_id_ref,
                                                i_status_begin => NULL, -- deprecated
                                                i_status_end   => NULL,
                                                i_action       => pk_ref_constant.g_ref_action_zdn, -- CANCEL_REQ_DENY
                                                i_level        => NULL,
                                                i_prof_dest    => NULL,
                                                i_dcs          => NULL,
                                                i_notes        => i_notes,
                                                i_dt_modified  => NULL,
                                                i_mode         => NULL,
                                                i_reason_code  => NULL,
                                                i_subtype      => NULL,
                                                i_inst_dest    => NULL,
                                                i_date         => g_sysdate_tstz,
                                                o_track        => l_track,
                                                o_flg_show     => l_flg_show,
                                                o_msg_title    => l_msg_title,
                                                o_msg          => l_msg,
                                                o_error        => o_error);
        
        END IF;
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- resets the referral context
        pk_ref_utils.reset_ref_context;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            IF g_error_code IS NOT NULL
            THEN
                g_flg_action := pk_ref_constant.g_err_flg_action_u; -- user defined error
            ELSE
                g_error_code := SQLCODE;
                g_error_desc := SQLERRM;
                g_flg_action := pk_ref_constant.g_err_flg_action_s; -- system error
            END IF;
            pk_alert_exceptions.process_error(i_lang        => i_lang,
                                              i_sqlcode     => g_error_code,
                                              i_sqlerrm     => g_error_desc,
                                              i_message     => g_error,
                                              i_owner       => g_package_owner,
                                              i_package     => g_package_name,
                                              i_function    => 'SET_REF_REQ_CANCEL_DENY',
                                              i_action_type => g_flg_action,
                                              i_action_msg  => NULL,
                                              o_error       => o_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END set_ref_req_cancel_deny;

    /**
      * Changes the referral origin professional (hand off the referral)
      *
      * @param   i_lang           Language associated to the professional executing the request
      * @param   i_prof           Id professional, institution and software    
      * @param   i_id_ref         Referral identifier                      
      * @param   i_prof_req        Professional that is requesting referral hand off
      * @param   i_id_prof_dest    Professional to which the referral was handed off
    * @param   i_id_inst_dest_tr Insitution to where the referral was handed off
      * @param   i_id_reason_code  Reason code identifier
      * @param   i_notes          Notes
      * @param   i_date           Operation date
    * @param   o_track           Tracking identifiers created due to the status change
      * @param   o_error          An error message, set when return=false
      *
      * @RETURN  TRUE if sucess, FALSE otherwise
      * @author  Filipe Sousa
      * @version 2.6
      * @since   17-09-2010
      */
    FUNCTION transf_referral_responsibility
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_ref          IN p1_external_request.id_external_request%TYPE,
        i_prof_req        IN professional.num_order%TYPE,
        i_prof_dest       IN professional.num_order%TYPE,
        i_id_inst_dest_tr IN institution.id_institution%TYPE,
        i_id_reason_code  IN p1_reason_code.id_reason_code%TYPE,
        i_notes           IN p1_detail.text%TYPE,
        i_date            IN DATE,
        o_track           OUT table_number,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_params            VARCHAR2(1000 CHAR);
        l_flg_valid         VARCHAR2(1 CHAR);
        l_prof_dest         profissional;
        l_prof_req          profissional;
        l_id_workflow       p1_external_request.id_workflow%TYPE;
        l_id_inst_orig      p1_external_request.id_inst_orig%TYPE;
        l_id_prof_requested p1_external_request.id_prof_requested%TYPE;
        l_id_tr_workflow    ref_trans_responsibility.id_workflow%TYPE;
    
        CURSOR c_ref_orig IS
            SELECT id_inst_orig, id_workflow, id_prof_requested
              FROM p1_external_request
             WHERE id_external_request = i_id_ref;
    BEGIN
        ----------------------
        -- INIT
        ----------------------   
        l_params := 'ID_REF=' || i_id_ref || ' i_prof_dest=' || i_prof_dest || ' i_prof_req=' || i_prof_req ||
                    ' i_id_inst_dest_tr=' || i_id_inst_dest_tr || ' i_id_reason_code=' || i_id_reason_code ||
                    ' i_date=' || i_date;
        g_error  := '->Init transf_referral_responsibility / ' || l_params;
        pk_alertlog.log_debug(g_error);
        reset_vars;
        g_prof_int := pk_p1_interface.set_prof_interface(i_prof);
        o_track    := table_number();
    
        -- sets the referral context
        pk_ref_utils.init_ref_context;
        pk_ref_utils.set_ref_context(i_id_external_request => i_id_ref, i_dt_system_date => current_timestamp);
    
        g_retval := pk_ref_utils.get_operation_date(i_lang    => i_lang,
                                                    i_prof    => i_prof,
                                                    i_dt_d    => i_date,
                                                    o_dt_tstz => g_sysdate_tstz,
                                                    o_error   => o_error);
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        ----------------------
        -- VAL
        ----------------------
        -- mandatory parameters       
        g_error := 'Validating mandatory parameters / ' || l_params;
        IF i_prof_req IS NULL
          --OR i_prof_dest IS NULL -- checked below
           OR i_notes IS NULL
           OR i_id_reason_code IS NULL
        THEN
            g_error      := 'Invalid parameter / ' || l_params;
            g_error_code := pk_ref_constant.g_ref_error_1005;
            g_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => g_error_code);
            RAISE g_exception;
        END IF;
    
        g_error := 'OPEN c_ref_orig / ' || l_params;
        OPEN c_ref_orig;
        FETCH c_ref_orig
            INTO l_id_inst_orig, l_id_workflow, l_id_prof_requested;
        CLOSE c_ref_orig;
    
        IF l_id_inst_orig IS NULL
        THEN
            g_error      := 'Origin institution is null / ' || l_params;
            g_error_code := pk_ref_constant.g_ref_error_1007;
            g_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => g_error_code);
            RAISE g_exception;
        END IF;
    
        g_error  := 'Call check_requirements / ' || l_params;
        g_retval := check_requirements(i_lang        => i_lang,
                                       i_prof        => g_prof_int,
                                       i_num_order   => i_prof_dest,
                                       i_id_ref      => i_id_ref,
                                       i_date        => g_sysdate_tstz,
                                       i_reason_code => i_id_reason_code,
                                       i_reason_type => pk_ref_constant.g_reason_code_t,
                                       o_flg_valid   => l_flg_valid,
                                       o_prof        => l_prof_dest,
                                       o_error       => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        IF l_flg_valid = pk_ref_constant.g_no
        THEN
            RAISE g_exception;
        END IF;
    
        l_params := l_params || ' ID_PROF_DEST=' || l_prof_dest.id;
    
        g_error  := 'Call check_requirements / ' || l_params;
        g_retval := check_requirements(i_lang      => i_lang,
                                       i_prof      => g_prof_int,
                                       i_num_order => i_prof_req,
                                       i_id_ref    => i_id_ref,
                                       i_id_inst   => l_id_inst_orig, -- must be at origin institution
                                       i_date      => g_sysdate_tstz,
                                       o_flg_valid => l_flg_valid,
                                       o_prof      => l_prof_req,
                                       o_error     => o_error);
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        IF l_flg_valid = pk_ref_constant.g_no
        THEN
            RAISE g_exception;
        END IF;
    
        l_params := l_params || ' ID_PROF_REQ=' || l_prof_req.id;
    
        -- check if professional l_prof_req is clinical director
        g_error  := 'Call check_clinical_director / ' || l_params;
        g_retval := check_clinical_director(i_lang           => i_lang,
                                            i_prof           => l_prof_req,
                                            i_id_institution => l_id_inst_orig, -- referral orig institution
                                            o_error          => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        IF l_id_workflow = pk_ref_constant.g_wf_x_hosp
        THEN
            g_error      := 'Hand off not allowed for WF=' || l_id_workflow || ' / ' || l_params;
            g_error_code := pk_ref_constant.g_ref_error_1007;
            g_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => g_error_code);
            RAISE g_exception;
        END IF;
    
        -- check if can create hand off for this referral
        g_error     := 'Call pk_ref_change_resp.check_handoff_creation / ' || l_params;
        l_flg_valid := pk_ref_change_resp.check_handoff_creation(i_lang              => i_lang,
                                                                 i_prof              => l_prof_req,
                                                                 i_id_ref            => i_id_ref,
                                                                 i_id_inst_orig      => l_id_inst_orig,
                                                                 i_id_prof_requested => l_id_prof_requested);
    
        IF l_flg_valid = pk_ref_constant.g_no
        THEN
            g_error      := 'Hand off not allowed for referral ' || i_id_ref || '  / ' || l_params;
            g_error_code := pk_ref_constant.g_ref_error_1007;
            g_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => g_error_code);
            RAISE g_exception;
        END IF;
    
        g_error := 'l_id_inst_orig = ' || l_id_inst_orig || ' i_id_inst_dest_tr=' || i_id_inst_dest_tr || ' / ' ||
                   l_params;
        IF l_id_inst_orig != i_id_inst_dest_tr
        THEN
            l_id_tr_workflow := pk_ref_constant.g_wf_transfresp_inst;
        ELSE
            -- l_id_inst_orig = i_id_inst_dest_tr or i_id_inst_dest_tr is null
            l_id_tr_workflow := pk_ref_constant.g_wf_transfresp;
        END IF;
    
        g_error     := 'Call pk_reg_change_resp.check_handoff_creation_param / ' || l_params;
        l_flg_valid := pk_ref_change_resp.check_handoff_creation_param(i_lang            => i_lang,
                                                                       i_prof            => l_prof_req,
                                                                       i_id_workflow     => l_id_tr_workflow,
                                                                       i_id_prof_dest    => l_prof_dest.id,
                                                                       i_id_inst_dest_tr => i_id_inst_dest_tr);
    
        IF l_flg_valid = pk_ref_constant.g_no
        THEN
            g_error_code := pk_ref_constant.g_ref_error_1009;
            g_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => g_error_code);
            RAISE g_exception;
        END IF;
    
        ----------------------
        -- FUNC
        ----------------------
        g_error  := 'Call pk_ref_change_resp.change_responsibility / ' || l_params;
        g_retval := pk_ref_change_resp.change_responsibility(i_lang                => i_lang,
                                                             i_prof                => l_prof_req,
                                                             i_id_external_request => i_id_ref,
                                                             i_id_prof             => l_prof_dest.id,
                                                             i_id_prof_request     => l_prof_req.id,
                                                             i_id_reason_code      => i_id_reason_code,
                                                             i_notes               => i_notes,
                                                             i_id_inst_dest_tr     => i_id_inst_dest_tr,
                                                             i_date                => g_sysdate_tstz,
                                                             o_track               => o_track,
                                                             o_error               => o_error);
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- resets the referral context
        pk_ref_utils.reset_ref_context;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            IF g_error_code IS NOT NULL
            THEN
                g_flg_action := pk_ref_constant.g_err_flg_action_u; -- user defined error
            ELSE
                g_error_code := SQLCODE;
                g_error_desc := SQLERRM;
                g_flg_action := pk_ref_constant.g_err_flg_action_s; -- system error
            END IF;
            pk_alert_exceptions.process_error(i_lang        => i_lang,
                                              i_sqlcode     => g_error_code,
                                              i_sqlerrm     => g_error_desc,
                                              i_message     => g_error,
                                              i_owner       => g_package_owner,
                                              i_package     => g_package_name,
                                              i_function    => 'TRANSF_REFERRAL_RESPONSIBILITY',
                                              i_action_type => g_flg_action,
                                              i_action_msg  => NULL,
                                              o_error       => o_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END transf_referral_responsibility;

    /**
    * This function do Responsability Transf.
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Id professional, institution and software    
    * @param   i_id_ref         Referral identifier                      
    * @param   i_prof_req       Professional that is requesting referral transf resp
    * @param   i_id_prof_dest   Professional to which the referral was transferred to
    * @param   i_id_reason_code Reason code 
    * @param   i_notes          Notes
    * @param   i_date           Operation date
    * @param   o_track          Tracking identifiers created due to the status change
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Filipe Sousa
    * @version 2.6
    * @since   17-09-2010
    */
    FUNCTION transf_referral_responsability
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_ref         IN p1_external_request.id_external_request%TYPE,
        i_prof_req       IN professional.num_order%TYPE,
        i_prof_dest      IN professional.num_order%TYPE,
        i_id_reason_code IN p1_reason_code.id_reason_code%TYPE,
        i_notes          IN p1_detail.text%TYPE,
        i_date           IN DATE,
        o_track          OUT table_number,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        RETURN transf_referral_responsibility(i_lang            => i_lang,
                                              i_prof            => i_prof,
                                              i_id_ref          => i_id_ref,
                                              i_prof_req        => i_prof_req,
                                              i_prof_dest       => i_prof_dest,
                                              i_id_inst_dest_tr => NULL,
                                              i_id_reason_code  => i_id_reason_code,
                                              i_notes           => i_notes,
                                              i_date            => i_date,
                                              o_track           => o_track,
                                              o_error           => o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            IF g_error_code IS NOT NULL
            THEN
                g_flg_action := pk_ref_constant.g_err_flg_action_u; -- user defined error
            ELSE
                g_error_code := SQLCODE;
                g_error_desc := SQLERRM;
                g_flg_action := pk_ref_constant.g_err_flg_action_s; -- system error
            END IF;
            pk_alert_exceptions.process_error(i_lang        => i_lang,
                                              i_sqlcode     => g_error_code,
                                              i_sqlerrm     => g_error_desc,
                                              i_message     => g_error,
                                              i_owner       => g_package_owner,
                                              i_package     => g_package_name,
                                              i_function    => 'TRANSF_REFERRAL_RESPONSABILITY',
                                              i_action_type => g_flg_action,
                                              i_action_msg  => NULL,
                                              o_error       => o_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END transf_referral_responsability;

    ----------------------------------
    -- Functions to be performed at origin institution
    ----------------------------------

    /**
    * Called after updating patient data. This will trigger a status update of all referrals of this patient
    *
    * @param   i_lang       Language associated to the professional executing the request
    * @param   i_prof       Professional, institution and software ids
    * @param   i_id_patient Patient identifier
    * @param   i_date           Operation date
    * @param   o_error      An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.6.0.5
    * @since   16-02-2011
    */
    FUNCTION update_pat_ref
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        i_date       IN DATE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        ----------------------
        -- INIT
        ----------------------        
        g_error := '->Init update_pat_ref / ID_PATIENT=' || i_id_patient;
        pk_alertlog.log_debug(g_error);
        reset_vars;
        g_prof_int := pk_p1_interface.set_prof_interface(i_prof);
        -- sets the referral context
        pk_ref_utils.init_ref_context;
        pk_ref_utils.set_ref_context(i_dt_system_date => current_timestamp);
    
        -- getting operation date
        g_error  := 'Call pk_ref_utils.get_operation_date / i_dt_d=' || i_date;
        g_retval := pk_ref_utils.get_operation_date(i_lang    => i_lang,
                                                    i_prof    => i_prof,
                                                    i_dt_d    => i_date,
                                                    o_dt_tstz => g_sysdate_tstz,
                                                    o_error   => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        ----------------------
        -- VAL
        ----------------------
        -- mandatory parameters
        g_error := 'Validating mandatory parameters';
        IF i_id_patient IS NULL
        THEN
            g_error      := 'Invalid parameter / ID_PATIENT=' || i_id_patient;
            g_error_code := pk_ref_constant.g_ref_error_1005;
            g_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => g_error_code);
            RAISE g_exception;
        END IF;
    
        ----------------------
        -- FUNC
        ----------------------        
        g_error  := 'Call pk_ref_core.update_pat_ref / i_dt_d=' || i_date;
        g_retval := pk_p1_core.update_patient_requests(i_lang       => i_lang,
                                                       i_prof       => g_prof_int,
                                                       i_id_patient => i_id_patient,
                                                       i_date       => g_sysdate_tstz,
                                                       o_error      => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- resets the referral context
        pk_ref_utils.reset_ref_context;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            IF g_error_code IS NOT NULL
            THEN
                g_flg_action := pk_ref_constant.g_err_flg_action_u; -- user defined error
            ELSE
                g_error_code := SQLCODE;
                g_error_desc := SQLERRM;
                g_flg_action := pk_ref_constant.g_err_flg_action_s; -- system error
            END IF;
            pk_alert_exceptions.process_error(i_lang        => i_lang,
                                              i_sqlcode     => g_error_code,
                                              i_sqlerrm     => g_error_desc,
                                              i_message     => g_error,
                                              i_owner       => g_package_owner,
                                              i_package     => g_package_name,
                                              i_function    => 'UPDATE_PAT_REF',
                                              i_action_type => g_flg_action,
                                              i_action_msg  => NULL,
                                              o_error       => o_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END update_pat_ref;

    /**
    * Checks if this referral is the correct referral to be updated 
    *
    * @param   i_lang            Language identifier
    * @param   i_prof            Professional, institution and software ids
    * @param   i_id_ref          Referral identifier
    * @param   i_old_flg_type    Referral old type
    * @param   i_old_id_workflow Referral old workflow identifier
    * @param   i_old_id_pat      Referral old patient identifier
    * @param   i_old_inst_dest   Referral old data dest institution
    * @param   i_old_id_spec     Referral old speciality
    * @param   i_old_id_dcs      Referral old dep_clin_serv
    * @param   i_old_id_ext_sys  Referral old external sys
    * @param   i_old_flg_status  Referral status    
    * @param   i_new_flg_type    Referral new type
    * @param   i_new_id_workflow Referral new workflow identifier
    * @param   i_new_id_pat      Referral new patient identifier
    * @param   i_new_inst_dest   Referral new data dest institution
    * @param   i_new_id_spec     Referral new speciality
    * @param   i_new_id_dcs      Referral new dep_clin_serv
    * @param   i_new_id_ext_sys  Referral new external sys    
    * @param   o_flg_valid       Flag indicating if this referral is the correct referral to be updated
    * @param   o_error           An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.6.0.5
    * @since   18-02-2011
    */
    FUNCTION check_referral_update
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_ref          IN p1_external_request.id_external_request%TYPE,
        i_old_flg_type    IN p1_external_request.flg_type%TYPE,
        i_old_id_workflow IN p1_external_request.id_workflow%TYPE,
        i_old_id_pat      IN p1_external_request.id_patient%TYPE,
        i_old_inst_dest   IN p1_external_request.id_inst_dest%TYPE,
        i_old_id_spec     IN p1_external_request.id_speciality%TYPE,
        i_old_id_dcs      IN p1_external_request.id_dep_clin_serv%TYPE,
        i_old_id_ext_sys  IN p1_external_request.id_external_sys%TYPE,
        i_old_flg_status  IN p1_external_request.flg_status%TYPE,
        i_new_flg_type    IN p1_external_request.flg_type%TYPE,
        i_new_id_workflow IN p1_external_request.id_workflow%TYPE,
        i_new_id_pat      IN p1_external_request.id_patient%TYPE,
        i_new_inst_dest   IN p1_external_request.id_inst_dest%TYPE,
        i_new_id_spec     IN p1_external_request.id_speciality%TYPE,
        i_new_id_dcs      IN p1_external_request.id_dep_clin_serv%TYPE,
        i_new_id_ext_sys  IN p1_external_request.id_external_sys%TYPE,
        o_flg_valid       OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_var VARCHAR2(1 CHAR);
    BEGIN
    
        ----------------------
        -- INIT
        ----------------------    
        g_error := 'Init check_referral_update / i_id_ref=' || i_id_ref || ' i_old_flg_type=' || i_old_flg_type ||
                   ' i_old_id_workflow=' || i_old_id_workflow || ' i_old_id_pat=' || i_old_id_pat ||
                   ' i_old_inst_dest=' || i_old_inst_dest || ' i_old_id_spec=' || i_old_id_spec || ' i_old_id_dcs=' ||
                   i_old_id_dcs || ' i_old_id_ext_sys=' || i_old_id_ext_sys || ' i_new_flg_type=' || i_new_flg_type ||
                   ' i_new_id_workflow=' || i_new_id_workflow || ' i_new_id_pat=' || i_new_id_pat ||
                   ' i_new_inst_dest=' || i_new_inst_dest || ' i_new_id_spec=' || i_new_id_spec || ' i_new_id_dcs=' ||
                   i_new_id_dcs || ' i_new_id_ext_sys=' || i_new_id_ext_sys || ' i_old_flg_status=' || i_old_flg_status;
        pk_alertlog.log_debug(g_error);
        reset_vars;
        o_flg_valid := pk_ref_constant.g_no;
    
        ----------------------
        -- FUNC
        ----------------------
        -- flg_type
        IF (i_old_flg_type IS NOT NULL AND i_new_flg_type IS NOT NULL AND i_old_flg_type = i_new_flg_type)
        THEN
            NULL; -- continues with the next validation
        ELSE
            g_error     := 'i_old_flg_type=' || i_old_flg_type || ' i_new_flg_type=' || i_new_flg_type;
            o_flg_valid := pk_ref_constant.g_no;
            RETURN TRUE;
        END IF;
    
        -- id_workflow
        IF ((i_old_id_workflow IS NULL AND i_new_id_workflow IS NULL) OR
           (i_old_id_workflow IS NOT NULL AND i_new_id_workflow IS NOT NULL AND i_old_id_workflow = i_new_id_workflow))
        THEN
            NULL; -- continues with the next validation
        ELSE
            g_error     := 'i_old_id_workflow=' || i_old_id_workflow || ' i_new_id_workflow=' || i_new_id_workflow;
            o_flg_valid := pk_ref_constant.g_no;
            RETURN TRUE;
        END IF;
    
        -- id_patient
        IF (i_old_id_pat IS NOT NULL AND i_new_id_pat IS NOT NULL AND i_old_id_pat = i_new_id_pat)
        THEN
            NULL; -- continues with the next validation
        ELSE
            g_error     := 'i_old_id_pat=' || i_old_id_pat || ' i_new_id_pat=' || i_new_id_pat;
            o_flg_valid := pk_ref_constant.g_no;
            RETURN TRUE;
        END IF;
    
        -- id_speciality (ignored when WF=3)
        IF i_old_id_workflow = pk_ref_constant.g_wf_srv_srv
           OR ((i_old_id_workflow IS NULL OR i_old_id_workflow != pk_ref_constant.g_wf_srv_srv) AND
           i_old_id_spec IS NOT NULL AND i_new_id_spec IS NOT NULL AND i_old_id_spec = i_new_id_spec)
        THEN
            NULL; -- continues with the next validation
        ELSE
            g_error     := 'i_old_id_spec=' || i_old_id_spec || ' i_new_id_spec=' || i_new_id_spec ||
                           ' i_old_id_workflow=' || i_old_id_workflow;
            o_flg_valid := pk_ref_constant.g_no;
            RETURN TRUE;
        END IF;
    
        -- id_inst_dest and id_dep_clin_serv cannot be updated
        IF (i_old_inst_dest IS NOT NULL AND i_new_inst_dest IS NOT NULL AND i_old_inst_dest = i_new_inst_dest)
           AND (i_old_id_dcs IS NOT NULL AND i_new_id_dcs IS NOT NULL AND i_old_id_dcs = i_new_id_dcs)
        THEN
            NULL; -- continues with the next validation
        ELSE
            g_error     := 'i_old_inst_dest=' || i_old_inst_dest || ' i_new_inst_dest=' || i_new_inst_dest ||
                           ' i_old_id_dcs=' || i_old_id_dcs || ' i_new_id_dcs=' || i_new_id_dcs;
            o_flg_valid := pk_ref_constant.g_no;
            RETURN TRUE;
        END IF;
    
        -- id_external_sys
        IF ((i_old_id_ext_sys IS NULL AND i_new_id_ext_sys IS NULL) OR
           (i_old_id_ext_sys IS NOT NULL AND i_new_id_ext_sys IS NOT NULL AND i_old_id_ext_sys = i_new_id_ext_sys))
        THEN
            NULL; -- continues with the next validation
        ELSE
            g_error     := 'i_old_id_ext_sys=' || i_old_id_ext_sys || ' i_new_id_ext_sys=' || i_new_id_ext_sys;
            o_flg_valid := pk_ref_constant.g_no;
            RETURN TRUE;
        END IF;
    
        -- checking if referral can be updated
        g_error := 'Check status / ID_REF=' || i_id_ref || ' ID_PAT=' || i_old_id_pat || ' WF=' || i_old_id_workflow;
        l_var   := nvl(pk_ref_core.is_editable(i_lang => i_lang, i_prof => i_prof, i_ext_req => i_id_ref),
                       pk_ref_constant.g_no);
    
        g_error := 'Referral ID_REF=' || i_id_ref || ' editable=' || l_var;
        IF l_var = pk_ref_constant.g_no
        THEN
            o_flg_valid  := pk_ref_constant.g_no;
            g_error      := 'Invalid status / FLG_STATUS=' || i_old_flg_status;
            g_error_code := pk_ref_constant.g_ref_error_1006;
            g_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => g_error_code);
            RAISE g_exception;
        END IF;
    
        o_flg_valid := pk_ref_constant.g_yes;
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            IF g_error_code IS NOT NULL
            THEN
                g_flg_action := pk_ref_constant.g_err_flg_action_u; -- user defined error
            ELSE
                g_error_code := SQLCODE;
                g_error_desc := SQLERRM;
                g_flg_action := pk_ref_constant.g_err_flg_action_s; -- system error
            END IF;
            pk_alert_exceptions.process_error(i_lang        => i_lang,
                                              i_sqlcode     => g_error_code,
                                              i_sqlerrm     => g_error_desc,
                                              i_message     => g_error,
                                              i_owner       => g_package_owner,
                                              i_package     => g_package_name,
                                              i_function    => 'CHECK_REFERRAL_UPDATE',
                                              i_action_type => g_flg_action,
                                              i_action_msg  => NULL,
                                              o_error       => o_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END check_referral_update;

    /**
    * Validates referral input data (to create or update the referral)
    *
    * @param   i_lang               Language associated to the professional executing the request
    * @param   i_prof               Professional, institution and software ids
    * @param   i_workflow           Workflow identifier
    * @param   i_num_order          Professional num order that is creating the referral
    * @param   i_prof_name          Professional name that is creating the referral. If referral is at Hospital Entrance, this is the name considered
    * @param   i_id_patient         Patient identifier
    * @param   i_speciality         Referral speciality (P1_SPECIALITY)
    * @param   i_dcs                Id department/clinical_service (can be null)
    * @param   i_flg_priority       Urgent/not urgent
    * @param   i_flg_home           Home consultation?
    * @param   i_id_inst_orig       Institution origin identifier
    * @param   i_inst_orig_name     Institution origin name. If referral is at Hospital Entrance, this is the name considered
    * @param   i_id_inst_dest       Destination institution identifier
    * @param   i_p_flg_type         Problem array codification type: ICD9, ICD10, ICPC2...
    * @param   i_p_code_icd         Problem array code (code_icd)
    * @param   i_p_desc_problem     Problem array name
    * @param   i_p_year_begin       Problem array begin year. Format YYYY   
    * @param   i_p_month_begin      Problem array begin month. Format MM
    * @param   i_p_day_begin        Problem array begin day. Format DD   
    * @param   i_d_flg_type         Diagnosis array codification type: ICD9, ICD10, ICPC2...
    * @param   i_d_code_icd         Diagnosis array code (code_icd)
    * @param   i_d_desc_diagnosis   Diagnosis array name
    * @param   i_detail             Referral detail info. For each detail: [idx,[detail_type|text]]
    * @param   i_id_external_sys    External system identifier
    * @param   i_date               Operation date
    * @param   i_flg_op             Operation to be performed   
    * @param   o_id_prof            Professional identifier (related to i_num_order)
    * @param   o_id_prf_templ       Professional profile template identifier (related to i_num_order)
    * @param   o_error              An error message, set when return=false
    *
    * @value   i_flg_priority       {*} 'Y' - Urgent {*} 'N' - Not urgent
    * @value   i_flg_home           {*} 'Y' - Home consultation {*} 'N' - Hospital consultation
    * @param   i_flg_op             {*} 'C' - Referral creation {*} 'U' - Referral update
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.6.0.5
    * @since   17-02-2011
    */
    FUNCTION check_referral_data
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_workflow       IN p1_external_request.id_workflow%TYPE,
        i_num_order      IN professional.num_order%TYPE,
        i_prof_name      IN professional.name%TYPE,
        i_id_patient     IN p1_external_request.id_patient%TYPE,
        i_speciality     IN p1_external_request.id_speciality%TYPE,
        i_dcs            IN p1_external_request.id_dep_clin_serv%TYPE,
        i_flg_priority   IN p1_external_request.flg_priority%TYPE,
        i_flg_home       IN p1_external_request.flg_home%TYPE,
        i_id_inst_orig   IN p1_external_request.id_inst_orig%TYPE,
        i_inst_orig_name IN VARCHAR2,
        i_id_inst_dest   IN institution.id_institution%TYPE,
        -- problems data
        i_p_flg_type     IN table_varchar, -- ICD9, ICPC2, ICD10...
        i_p_code_icd     IN table_varchar,
        i_p_desc_problem IN table_varchar,
        --i_p_dt_begin     IN table_varchar,
        i_p_year_begin  IN table_number, -- YYYY
        i_p_month_begin IN table_number, -- MM
        i_p_day_begin   IN table_number, -- DD
        -- diagnosis data
        i_d_flg_type       IN table_varchar, -- ICD9, ICPC2, ICD10...
        i_d_code_icd       IN table_varchar,
        i_d_desc_diagnosis IN table_varchar,
        -- clinical info
        i_id_external_sys IN p1_external_request.id_external_sys%TYPE,
        io_detail         IN OUT NOCOPY table_table_varchar,
        o_id_prof         OUT professional.id_professional%TYPE,
        o_id_prf_templ    OUT profile_template.id_profile_template%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(24 CHAR) := 'check_referral_data';
        l_params           VARCHAR2(1000 CHAR);
        l_inst_diag_type   sys_config.value%TYPE;
        l_reason_mandatory VARCHAR2(1 CHAR);
        l_reason_found     PLS_INTEGER;
        l_count            PLS_INTEGER;
        l_gender           patient.gender%TYPE;
        l_age              PLS_INTEGER;
        l_ref_network_tab  t_coll_ref_network;
        l_ref_dcs_tab      t_coll_ref_dcs;
        l_ref_inst_orig    t_coll_ref_inst;
        l_config           VARCHAR2(1 CHAR);
    
        -- checking if diagnosis type input is the same configured in the institution
        FUNCTION check_diagnosis_type
        (
            i_diag_type      IN table_varchar,
            i_inst_diag_type IN sys_config.value%TYPE,
            o_error          OUT t_error_out
        ) RETURN BOOLEAN IS
            l_diag_type diagnosis.flg_type%TYPE;
        BEGIN
        
            g_error := 'Validating problems types / INST_TYPE=' || l_inst_diag_type;
            BEGIN
                SELECT DISTINCT column_value
                  INTO l_diag_type
                  FROM TABLE(CAST(i_diag_type AS table_varchar));
            EXCEPTION
                WHEN too_many_rows THEN
                    -- several types not allowed
                    g_error      := 'Invalid diagnosis type / Diagnosis type input=' ||
                                    pk_utils.to_string(i_p_flg_type) || ' Diagnosis type institution=' ||
                                    l_inst_diag_type;
                    g_error_code := pk_ref_constant.g_ref_error_1005;
                    g_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => g_error_code);
                    RAISE g_exception;
            END;
        
            IF l_diag_type != i_inst_diag_type
            THEN
                g_error := 'Invalid diagnosis type / Diagnosis type input=' || l_diag_type ||
                           ' Diagnosis type institution=' || l_inst_diag_type;
            
                g_error_code := pk_ref_constant.g_ref_error_1005;
                g_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => g_error_code);
                RAISE g_exception;
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
                                                  i_function => 'CHECK_DIAGNOSIS_TYPE',
                                                  o_error    => o_error);
                RETURN FALSE;
        END check_diagnosis_type;
    BEGIN
    
        ----------------------
        -- INIT
        ----------------------        
        l_params := 'WF=' || i_workflow || ' NUM_ORDER=' || i_num_order || ' PROF_NAME=' || substr(i_prof_name, 1, 200) ||
                    ' ID_PAT=' || i_id_patient || ' ID_SPEC=' || i_speciality || ' ID_DCS=' || i_dcs || ' FLG_PRI=' ||
                    i_flg_priority || ' FLG_H=' || i_flg_home || ' ID_INST_ORIG=' || i_id_inst_orig ||
                    ' INST_ORIG_NAME=' || substr(i_inst_orig_name, 1, 200) || ' ID_INST_DEST=' || i_id_inst_dest ||
                    ' ID_EXT_SYS=' || i_id_external_sys;
        g_error  := '->Init ' || l_func_name || ' / ' || l_params;
        pk_alertlog.log_debug(g_error);
        reset_vars;
    
        ----------------------
        -- CONFIG
        ----------------------        
        g_error          := 'Call pk_sysconfig.get_configs / ' || pk_ref_constant.g_ref_inst_diag_list || ' ' ||
                            pk_ref_constant.g_ref_inst_diag_list || ' / ' || l_params;
        l_inst_diag_type := pk_sysconfig.get_config(pk_ref_constant.g_ref_inst_diag_list, i_prof);
    
        g_error  := 'Call pk_ref_status.check_config_enabled / CONFIG=' || pk_ref_constant.g_ref_medication_enabled ||
                    ' / ' || l_params;
        l_config := pk_ref_status.check_config_enabled(i_lang   => i_lang,
                                                       i_prof   => i_prof,
                                                       i_config => pk_ref_constant.g_ref_medication_enabled);
        ----------------------
        -- VAL
        ----------------------        
        -- workflows validation
        IF i_workflow NOT IN (pk_ref_constant.g_wf_pcc_hosp,
                              pk_ref_constant.g_wf_hosp_hosp,
                              pk_ref_constant.g_wf_srv_srv,
                              pk_ref_constant.g_wf_x_hosp)
        THEN
            g_error      := 'Invalid parameter / ' || l_params;
            g_error_code := pk_ref_constant.g_ref_error_1005;
            g_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => g_error_code);
            RAISE g_exception;
        END IF;
    
        -- validating orig institution
        IF nvl(i_workflow, pk_ref_constant.g_wf_pcc_hosp) != pk_ref_constant.g_wf_x_hosp
        THEN
            -- professional must be at orig institution
            IF i_prof.institution != i_id_inst_orig
            THEN
                g_error      := 'Professional institution (' || i_prof.institution ||
                                ') must be the same as orig institution (' || i_id_inst_orig || ') / ' || l_params;
                g_error_code := pk_ref_constant.g_ref_error_1009;
                g_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => g_error_code);
                RAISE g_exception;
            END IF;
        
        ELSIF nvl(i_workflow, pk_ref_constant.g_wf_pcc_hosp) = pk_ref_constant.g_wf_x_hosp
        THEN
            -- professional must be at dest institution
            IF i_prof.institution != i_id_inst_dest
            THEN
                g_error      := 'Professional institution (' || i_prof.institution ||
                                ') must be the same as dest institution (' || i_id_inst_dest || ') / ' || l_params;
                g_error_code := pk_ref_constant.g_ref_error_1009;
                g_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => g_error_code);
                RAISE g_exception;
            END IF;
        END IF;
    
        -- external system validation
        IF i_id_external_sys IS NOT NULL
        THEN
            SELECT COUNT(1)
              INTO l_count
              FROM external_sys e
             WHERE e.id_external_sys = i_id_external_sys
               AND e.flg_available = pk_ref_constant.g_yes;
        
            IF l_count = 0
            THEN
                g_error      := 'Invalid parameter / ID_EXTERNAL_SYS / ' || i_id_external_sys;
                g_error_code := pk_ref_constant.g_ref_error_1005;
                g_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => g_error_code);
                RAISE g_exception;
            END IF;
        
        END IF;
    
        -- professional must be configured in Alert
        IF nvl(i_workflow, pk_ref_constant.g_wf_pcc_hosp) != pk_ref_constant.g_wf_x_hosp
        THEN
            -- professional is created in PK_REF_ORIG_PHY.create_referral for i_workflow=pk_ref_constant.g_wf_x_hosp
            g_error  := 'Call get_prof_id / ' || l_params;
            g_retval := get_prof_id(i_lang         => i_lang,
                                    i_prof         => i_prof,
                                    i_num_order    => i_num_order,
                                    o_id_prof      => o_id_prof,
                                    o_id_prf_templ => o_id_prf_templ,
                                    o_error        => o_error);
        
            IF NOT g_retval
            THEN
                RAISE g_exception_np;
            END IF;
        
            l_params := l_params || ' profissional(' || o_id_prof || ',' || i_prof.institution || ',' ||
                        i_prof.software || ')';
        
            IF o_id_prf_templ NOT IN (pk_ref_constant.g_profile_med_cs, pk_ref_constant.g_profile_med_hs)
            THEN
                g_error := g_error || ' / ID_PROFILE_TEMPLATE=' || o_id_prf_templ;
                RAISE g_exception;
            END IF;
        END IF;
    
        -- problems
        IF i_p_flg_type.count != i_p_code_icd.count
           OR i_p_flg_type.count != i_p_desc_problem.count
           OR i_p_flg_type.count != i_p_year_begin.count
           OR i_p_flg_type.count != i_p_month_begin.count
           OR i_p_flg_type.count != i_p_day_begin.count
        THEN
        
            g_error      := 'Invalid parameter / problems count / i_p_flg_type.COUNT=' || i_p_flg_type.count ||
                            ' i_p_code_icd.COUNT=' || i_p_code_icd.count || ' i_p_desc_problem.COUNT=' ||
                            i_p_desc_problem.count || ' i_p_year_begin.COUNT=' || i_p_year_begin.count ||
                            ' i_p_month_begin.COUNT=' || i_p_month_begin.count || ' i_p_day_begin.COUNT=' ||
                            i_p_day_begin.count || ' / ' || l_params;
            g_error_code := pk_ref_constant.g_ref_error_1005;
            g_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => g_error_code);
            RAISE g_exception;
        END IF;
    
        -- validating problems types
        IF i_p_flg_type.count > 0
        THEN
            g_error  := 'Call check_diagnosis_type P / ' || l_params;
            g_retval := check_diagnosis_type(i_diag_type      => i_p_flg_type,
                                             i_inst_diag_type => l_inst_diag_type,
                                             o_error          => o_error);
        
            IF NOT g_retval
            THEN
                RAISE g_exception_np;
            END IF;
        END IF;
    
        -- diagnosis
        IF i_d_flg_type.count != i_d_code_icd.count
           OR i_d_flg_type.count != i_d_desc_diagnosis.count
        THEN
        
            g_error := 'Invalid parameter / diagnosis count / i_d_flg_type.COUNT=' || i_d_flg_type.count ||
                       ' i_d_code_icd.COUNT=' || i_d_code_icd.count || ' i_d_desc_diagnosis.COUNT=' ||
                       i_d_desc_diagnosis.count || ' / ' || l_params;
        
            g_error_code := pk_ref_constant.g_ref_error_1005;
            g_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => g_error_code);
            RAISE g_exception;
        END IF;
    
        -- validating diagnosis types
        IF i_d_flg_type.count > 0
        THEN
            g_error  := 'Call check_diagnosis_type D / ' || l_params;
            g_retval := check_diagnosis_type(i_diag_type      => i_d_flg_type,
                                             i_inst_diag_type => l_inst_diag_type,
                                             o_error          => o_error);
        
            IF NOT g_retval
            THEN
                RAISE g_exception_np;
            END IF;
        END IF;
    
        g_error := 'i_workflow / ' || l_params;
        IF i_workflow = pk_ref_constant.g_wf_x_hosp
        THEN
            -- at hospital entrance workflow
            IF i_p_flg_type.count != 0
               OR i_d_flg_type.count != 0
            THEN
                -- there are no problems or diagnoses in this workflow
                g_error      := 'Problems or diagnosis not allowed for WF=' || i_workflow || ' / Problems count=' ||
                                i_p_flg_type.count || ' Diagnosis count=' || i_d_flg_type.count || ' / ' || l_params;
                g_error_code := pk_ref_constant.g_ref_error_1005;
                g_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => g_error_code);
                RAISE g_exception;
            END IF;
        
            -- the registrar can only register notes in this kind of referral
            -- so field "Reason" sent by external system is mapped into field "Notes" directly
            FOR i IN 1 .. io_detail.count
            LOOP
                g_error := 'io_detail(' || i || ') / ' || l_params;
            
                IF io_detail(i) (1) = to_char(pk_ref_constant.g_detail_type_jstf)
                THEN
                    io_detail(i)(1) := to_char(pk_ref_constant.g_detail_type_rrn);
                ELSIF io_detail(i) (1) != to_char(pk_ref_constant.g_detail_type_jstf)
                THEN
                    g_error      := 'Detail type ' || io_detail(i)
                                    (1) || ' not allowed for WF=' || i_workflow || ' / ' || l_params;
                    g_error_code := pk_ref_constant.g_ref_error_1005;
                    g_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => g_error_code);
                    RAISE g_exception;
                END IF;
            END LOOP;
        
        ELSE
        
            -- checking if referral reason is mandatory or not
            l_reason_found := 0;
            FOR i IN 1 .. io_detail.count
            LOOP
                g_error := 'io_detail(' || i || ') / ' || l_params;
            
                IF io_detail(i) (1) = to_char(pk_ref_constant.g_detail_type_jstf) -- detail_type
                   AND io_detail(i) (2) IS NOT NULL -- detail_text
                THEN
                    l_reason_found := 1;
                ELSIF io_detail(i) (1) = to_char(pk_ref_constant.g_detail_type_med) -- detail_type
                      AND l_config = pk_ref_constant.g_no -- configuration must be enabled
                THEN
                    g_error      := 'Detail Medication is disabled / ' || l_params;
                    g_error_code := pk_ref_constant.g_ref_error_1005;
                    g_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => g_error_code);
                    RAISE g_exception;
                END IF;
            END LOOP;
        
            g_error            := 'Call pk_ref_core.check_reason_mandatory_cfg / i_flg_type=' ||
                                  pk_ref_constant.g_p1_type_c || ' / ' || l_params;
            l_reason_mandatory := pk_ref_core.check_reason_mandatory_cfg(i_lang     => i_lang,
                                                                         i_prof     => i_prof,
                                                                         i_flg_type => pk_ref_constant.g_p1_type_c);
        
            g_error := 'l_reason_mandatory=' || l_reason_mandatory || ' l_reason_found=' || l_reason_found || ' / ' ||
                       l_params;
            IF l_reason_mandatory = pk_ref_constant.g_yes
               AND l_reason_found = 0
            THEN
                g_error      := 'Reason is mandatory / ' || l_params;
                g_error_code := pk_ref_constant.g_ref_error_1005;
                g_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => g_error_code);
                RAISE g_exception;
            END IF;
        
            -- dep_clin_serv validated below for all workflows
        END IF;
    
        -----------------
        -- validating referral network
        l_count := 0;
        IF i_workflow = pk_ref_constant.g_wf_srv_srv
        THEN
        
            g_error  := 'Call pk_ref_core.get_pat_age_gender / ' || l_params;
            g_retval := pk_ref_core.get_pat_age_gender(i_lang    => 1,
                                                       i_prof    => i_prof,
                                                       i_patient => i_id_patient,
                                                       o_gender  => l_gender,
                                                       o_age     => l_age,
                                                       o_error   => o_error);
        
            g_error  := 'Call get_referral_int_dcs / ' || l_params;
            g_retval := get_referral_int_dcs(i_lang            => i_lang,
                                             i_prof            => i_prof,
                                             i_id_external_sys => i_id_external_sys,
                                             i_id_inst_orig    => i_id_inst_orig,
                                             i_num_order       => i_num_order, -- this is the professional that is creating the referral
                                             i_pat_gender      => l_gender,
                                             i_pat_age         => l_age,
                                             o_ref_data        => l_ref_dcs_tab,
                                             o_error           => o_error);
        
            IF NOT g_retval
            THEN
                RAISE g_exception_np;
            END IF;
        
            g_error := '<<loop_ref_dcs>> / ' || l_params;
            <<loop_ref_dcs>>
            FOR i IN 1 .. l_ref_dcs_tab.count
            LOOP
                IF l_ref_dcs_tab(i).id_dep_clin_serv = i_dcs -- dcs validated for internal referrals
                THEN
                    l_count := 1;
                    EXIT loop_ref_dcs;
                END IF;
            END LOOP loop_ref_dcs;
        
            IF l_count = 0
            THEN
                g_error      := 'Clinical service ' || i_dcs || ' not available for referring / ' || l_params;
                g_error_code := pk_ref_constant.g_ref_error_1009;
                g_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => g_error_code);
                RAISE g_exception;
            END IF;
        ELSIF i_workflow = pk_ref_constant.g_wf_x_hosp
        THEN
        
            g_error  := 'Call get_referral_inst_orig / ' || l_params;
            g_retval := get_referral_inst_orig(i_lang             => i_lang,
                                               i_prof             => profissional(o_id_prof,
                                                                                  i_prof.institution,
                                                                                  i_prof.software), -- this is the professional that is creating the referral,
                                               i_id_external_sys  => i_id_external_sys,
                                               i_id_inst_dest     => i_id_inst_dest,
                                               i_id_speciality    => i_speciality,
                                               i_id_dep_clin_serv => i_dcs,
                                               o_ref_data         => l_ref_inst_orig,
                                               o_error            => o_error);
        
            IF NOT g_retval
            THEN
                RAISE g_exception_np;
            END IF;
        
            g_error := '<<loop_ref_orig>> / ' || l_params;
            <<loop_ref_orig>>
            FOR i IN 1 .. l_ref_inst_orig.count
            LOOP
                IF l_ref_inst_orig(i).id_institution = i_id_inst_orig
                THEN
                    l_count := 1;
                    EXIT loop_ref_orig;
                END IF;
            END LOOP loop_ref_orig;
        
            IF l_count = 0
            THEN
                g_error      := 'Speciality ' || i_speciality || ' not available for referring / ' || l_params;
                g_error_code := pk_ref_constant.g_ref_error_1009;
                g_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => g_error_code);
                RAISE g_exception;
            END IF;
        
            -- validating id_dep_clin_serv (if defined)
            IF i_dcs IS NOT NULL
            THEN
                l_count := 0;
            
                g_error  := 'Call get_referral_clinserv / ' || l_params;
                g_retval := get_referral_clinserv(i_lang            => i_lang,
                                                  i_prof            => profissional(o_id_prof,
                                                                                    i_prof.institution,
                                                                                    i_prof.software), -- this is the professional that is creating the referral
                                                  i_id_workflow     => i_workflow,
                                                  i_id_speciality   => i_speciality,
                                                  i_id_inst_dest    => i_id_inst_dest,
                                                  i_id_external_sys => i_id_external_sys,
                                                  o_ref_data        => l_ref_dcs_tab,
                                                  o_error           => o_error);
            
                IF NOT g_retval
                THEN
                    RAISE g_exception_np;
                END IF;
            
                g_error := '<<loop_ref_dcs2>> / ' || l_params;
                <<loop_ref_dcs2>>
                FOR i IN 1 .. l_ref_dcs_tab.count
                LOOP
                    IF l_ref_dcs_tab(i).id_dep_clin_serv = i_dcs -- dcs validated for internal referrals
                    THEN
                        l_count := 1;
                        EXIT loop_ref_dcs2;
                    END IF;
                END LOOP loop_ref_dcs2;
            
                IF l_count = 0
                THEN
                    g_error      := 'Clinical service ' || i_dcs || ' not available for referring / ' || l_params;
                    g_error_code := pk_ref_constant.g_ref_error_1009;
                    g_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => g_error_code);
                    RAISE g_exception;
                END IF;
            
            END IF;
        
        ELSE
            g_error  := 'Call get_referral_network / ' || l_params;
            g_retval := get_referral_network(i_lang            => i_lang,
                                             i_prof            => profissional(o_id_prof,
                                                                               i_prof.institution,
                                                                               i_prof.software), -- this is the professional that is creating the referral,
                                             i_id_external_sys => i_id_external_sys,
                                             i_id_workflow     => i_workflow,
                                             i_id_inst_orig    => i_id_inst_orig,
                                             i_id_speciality   => i_speciality,
                                             o_ref_data        => l_ref_network_tab,
                                             o_error           => o_error);
        
            IF NOT g_retval
            THEN
                RAISE g_exception_np;
            END IF;
        
            g_error := '<<loop_ref_net>> / ' || l_params;
            <<loop_ref_net>>
            FOR i IN 1 .. l_ref_network_tab.count
            LOOP
                IF l_ref_network_tab(i).id_institution = i_id_inst_dest
                THEN
                    l_count := 1;
                    EXIT loop_ref_net;
                END IF;
            END LOOP loop_ref_net;
        
            IF l_count = 0
            THEN
                g_error      := 'Speciality ' || i_speciality || ' not available for referring / ' || l_params;
                g_error_code := pk_ref_constant.g_ref_error_1009;
                g_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => g_error_code);
                RAISE g_exception;
            END IF;
        
            -- validating id_dep_clin_serv (if defined)
            IF i_dcs IS NOT NULL
            THEN
                l_count := 0;
            
                g_error  := 'Call get_referral_clinserv / ' || l_params;
                g_retval := get_referral_clinserv(i_lang            => i_lang,
                                                  i_prof            => profissional(o_id_prof,
                                                                                    i_prof.institution,
                                                                                    i_prof.software), -- this is the professional that is creating the referral
                                                  i_id_workflow     => i_workflow,
                                                  i_id_speciality   => i_speciality,
                                                  i_id_inst_dest    => i_id_inst_dest,
                                                  i_id_external_sys => i_id_external_sys,
                                                  o_ref_data        => l_ref_dcs_tab,
                                                  o_error           => o_error);
            
                IF NOT g_retval
                THEN
                    RAISE g_exception_np;
                END IF;
            
                g_error := '<<loop_ref_dcs3>> / ' || l_params;
                <<loop_ref_dcs3>>
                FOR i IN 1 .. l_ref_dcs_tab.count
                LOOP
                    IF l_ref_dcs_tab(i).id_dep_clin_serv = i_dcs -- dcs validated for internal referrals
                    THEN
                        l_count := 1;
                        EXIT loop_ref_dcs3;
                    END IF;
                END LOOP loop_ref_dcs3;
            
                IF l_count = 0
                THEN
                    g_error      := 'Clinical service ' || i_dcs || ' not available for referring / ' || l_params;
                    g_error_code := pk_ref_constant.g_ref_error_1009;
                    g_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => g_error_code);
                    RAISE g_exception;
                END IF;
            
            END IF;
        
        END IF;
    
        -- validate patient mandatory data, to issed the referral
        g_error  := 'Call pk_ref_core.check_mandatory_data / ' || l_params;
        g_retval := pk_ref_core.check_mandatory_data(i_lang  => i_lang,
                                                     i_prof  => i_prof,
                                                     i_pat   => i_id_patient,
                                                     o_error => o_error);
    
        IF NOT g_retval
        THEN
            g_error_code := pk_ref_constant.g_ref_error_1010;
            g_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => g_error_code);
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            IF g_error_code IS NOT NULL
            THEN
                g_flg_action := pk_ref_constant.g_err_flg_action_u;
            ELSE
                g_error_code := SQLCODE;
                g_error_desc := SQLERRM;
                g_flg_action := pk_ref_constant.g_err_flg_action_s;
            END IF;
            pk_alert_exceptions.process_error(i_lang        => i_lang,
                                              i_sqlcode     => g_error_code,
                                              i_sqlerrm     => g_error_desc,
                                              i_message     => g_error,
                                              i_owner       => g_package_owner,
                                              i_package     => g_package_name,
                                              i_function    => l_func_name,
                                              i_action_type => g_flg_action,
                                              i_action_msg  => NULL,
                                              o_error       => o_error);
            RETURN FALSE;
    END check_referral_data;

    /**
    * Validates referral workflow 
    *
    * @param   i_lang          Language associated to the professional executing the request
    * @param   i_prof          Professional, institution and software ids
    * @param   i_id_workflow   Referral workflow identifier
    * @param   i_id_ext_sys    Referral external system
    * @param   i_id_inst_orig  Origin institution identifier
    * @param   i_id_inst_dest  Dest institution identifier
    * @param   o_error         An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   20-07-2012
    */
    FUNCTION check_workflow
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_workflow  IN p1_external_request.id_workflow%TYPE,
        i_id_ext_sys   IN p1_external_request.id_external_sys%TYPE,
        i_id_inst_orig IN p1_external_request.id_inst_orig%TYPE,
        i_id_inst_dest IN p1_external_request.id_inst_dest%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id_workflow    p1_external_request.id_workflow%TYPE;
        l_inst_dest_type institution.flg_type%TYPE;
        l_params         VARCHAR2(1000 CHAR);
    BEGIN
        ----------------------
        -- INIT
        ----------------------        
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_id_workflow=' || i_id_workflow || ' i_id_inst_orig=' ||
                    i_id_inst_orig || ' i_id_ext_sys=' || i_id_ext_sys || ' i_id_inst_dest=' || i_id_inst_dest;
        g_error  := '->Init check_workflow / ' || l_params;
        pk_alertlog.log_debug(g_error);
        reset_vars;
    
        ----------------------
        -- FUNC
        ----------------------           
        IF i_id_workflow = pk_ref_constant.g_wf_x_hosp
        THEN
        
            -- dest
            g_error  := 'GET pk_ref_utils.get_inst_type / dest / ' || l_params;
            g_retval := pk_ref_utils.get_inst_type(i_lang      => i_lang,
                                                   i_prof      => i_prof,
                                                   i_id_inst   => i_id_inst_dest,
                                                   o_inst_type => l_inst_dest_type,
                                                   o_error     => o_error);
        
            IF l_inst_dest_type = pk_ref_constant.g_hospital
            THEN
                NULL;
            ELSE
                g_error      := 'Workflow and institution types does not match / ' || l_params;
                g_error_code := pk_ref_constant.g_ref_error_1009;
                g_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => g_error_code);
                RAISE g_exception;
            END IF;
        ELSE
        
            -- due to ALERT-271290, at hospital entrance workflow can have any hospital physician as origin institution, so function pk_ref_utils.get_workflow cannot validate this 
            g_error       := 'Call pk_ref_utils.get_workflow / ' || l_params;
            l_id_workflow := pk_ref_utils.get_workflow(i_prof         => i_prof,
                                                       i_lang         => i_lang,
                                                       i_id_ext_sys   => i_id_ext_sys,
                                                       i_id_inst_orig => i_id_inst_orig,
                                                       i_id_inst_dest => i_id_inst_dest,
                                                       i_detail       => table_table_varchar(table_varchar()));
        
            IF (l_id_workflow != i_id_workflow)
               OR (l_id_workflow IS NULL AND i_id_workflow IS NOT NULL)
               AND (l_id_workflow IS NOT NULL AND i_id_workflow IS NULL)
            THEN
                g_error      := 'Workflow and institution types does not match / ' || l_params;
                g_error_code := pk_ref_constant.g_ref_error_1009;
                g_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => g_error_code);
                RAISE g_exception;
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'CHECK_WORKFLOW',
                                              o_error    => o_error);
            RETURN FALSE;
    END check_workflow;

    /**
    * Fills io_detail in order to cancel all referral clinical detail
    *
    * @param   i_lang         Language associated to the professional executing the request
    * @param   i_prof         Professional, institution and software ids
    * @param   i_id_ref       Referral identifier
    * @param   i_id_workflow  Referral workflow identifier
    * @param   io_detail      Array with referral details
    * @param   o_error        An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.6.0.5
    * @since   21-02-2011
    */
    FUNCTION outdate_ref_detail
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_ref      IN p1_external_request.id_external_request%TYPE,
        i_id_workflow IN p1_external_request.id_workflow%TYPE,
        io_detail     IN OUT NOCOPY table_table_varchar,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        -- details of all workflows
        CURSOR c_detail IS
            SELECT d.id_detail
              FROM p1_detail d
             WHERE id_external_request = i_id_ref
               AND flg_status = pk_ref_constant.g_active
               AND flg_type IN (pk_ref_constant.g_detail_type_jstf,
                                pk_ref_constant.g_detail_type_sntm,
                                pk_ref_constant.g_detail_type_evlt,
                                pk_ref_constant.g_detail_type_hstr,
                                pk_ref_constant.g_detail_type_hstf,
                                pk_ref_constant.g_detail_type_obje,
                                pk_ref_constant.g_detail_type_obje,
                                pk_ref_constant.g_detail_type_cmpe,
                                pk_ref_constant.g_detail_type_item,
                                pk_ref_constant.g_detail_type_ubrn,
                                pk_ref_constant.g_detail_type_rrn,
                                pk_ref_constant.g_detail_type_med,
                                pk_ref_constant.g_detail_type_auge);
    
        -- details of "At hospital entrance" workflow
        CURSOR c_detail_x_hosp IS
            SELECT d.id_detail
              FROM p1_detail d
             WHERE id_external_request = i_id_ref
               AND flg_status = pk_ref_constant.g_active
               AND flg_type = pk_ref_constant.g_detail_type_rrn;
    
        l_detail_tab table_number;
        l_idx        PLS_INTEGER;
    BEGIN
    
        ----------------------
        -- INIT
        ----------------------        
        g_error := '->Init outdate_ref_detail / ID_REF=' || i_id_ref;
        pk_alertlog.log_debug(g_error);
        reset_vars;
    
        ----------------------
        -- FUNC
        ----------------------     
        -- getting all active referral details
        IF i_id_workflow = pk_ref_constant.g_wf_x_hosp
        THEN
            -- 'At hospital entrance' workflow
            g_error := 'OPEN c_detail_x_hosp';
            OPEN c_detail_x_hosp;
            FETCH c_detail_x_hosp BULK COLLECT
                INTO l_detail_tab;
            CLOSE c_detail_x_hosp;
        ELSE
            -- all other workflows
            g_error := 'OPEN c_detail';
            OPEN c_detail;
            FETCH c_detail BULK COLLECT
                INTO l_detail_tab;
            CLOSE c_detail;
        END IF;
    
        g_error := 'io_detail.EXTEND(' || l_detail_tab.count || ')';
        l_idx   := io_detail.count;
        io_detail.extend(l_detail_tab.count);
    
        g_error := 'l_detail_tab.COUNT=' || l_detail_tab.count;
        FOR i IN 1 .. l_detail_tab.count
        LOOP
            --[id_detail|flg_type|text|flg|id_group]
            -- id_detail not null, flg=O: updates detail_record id_detail (Outdated) 
        
            l_idx := l_idx + 1;
            io_detail(l_idx) := table_varchar(l_detail_tab(i), NULL, NULL, pk_ref_constant.g_detail_flg_o, NULL);
        
        END LOOP;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            IF c_detail%ISOPEN
            THEN
                CLOSE c_detail;
            END IF;
            IF c_detail_x_hosp%ISOPEN
            THEN
                CLOSE c_detail_x_hosp;
            END IF;
            RETURN FALSE;
        WHEN OTHERS THEN
            IF c_detail%ISOPEN
            THEN
                CLOSE c_detail;
            END IF;
            IF c_detail_x_hosp%ISOPEN
            THEN
                CLOSE c_detail_x_hosp;
            END IF;
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'OUTDATE_REF_DETAIL',
                                              o_error    => o_error);
            RETURN FALSE;
    END outdate_ref_detail;

    /**
    * Gets the oldest problem begin date
    *
    * @param   i_lang         Language associated to the professional executing the request
    * @param   i_prof         Professional, institution and software ids
    * @param   i_year_begin   Array of problem begin years associated to the referral
    * @param   i_month_begin  Array of problem begin months associated to the referral
    * @param   i_day_begin    Array of problem begin days associated to the referral
    * @param   o_probl_begin  The oldest problem begin string (flash format)
    * @param   o_error        An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.6.0.5
    * @since   18-02-2011
    */
    FUNCTION get_problem_begin
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        --i_probl_begin IN table_varchar,
        i_year_begin  IN table_number,
        i_month_begin IN table_number,
        i_day_begin   IN table_number,
        o_probl_begin OUT VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        --l_dt_probl_begin_str VARCHAR2(50 CHAR);
        l_year_begin  p1_exr_diagnosis.year_begin%TYPE;
        l_month_begin p1_exr_diagnosis.month_begin%TYPE;
        l_day_begin   p1_exr_diagnosis.day_begin%TYPE;
    
        l_year_begin_f  p1_exr_diagnosis.year_begin%TYPE;
        l_month_begin_f p1_exr_diagnosis.month_begin%TYPE;
        l_day_begin_f   p1_exr_diagnosis.day_begin%TYPE;
    
        l_result VARCHAR2(5 CHAR);
    BEGIN
    
        ----------------------
        -- INIT
        ----------------------        
        g_error := '->Init get_problem_begin / YEAR_BEGIN=' || pk_utils.to_string(i_year_begin) || ' MONTH_BEGIN=' ||
                   pk_utils.to_string(i_month_begin) || ' DAY_BEGIN=' || pk_utils.to_string(i_day_begin);
        pk_alertlog.log_debug(g_error);
        reset_vars;
    
        ----------------------
        -- FUNC
        ----------------------     
        -- ALERT-194568
        -- getting problem begin date (the oldest)
        FOR i IN 1 .. i_year_begin.count
        LOOP
            --l_dt_probl_begin_str := i_probl_begin(i);
        
            g_error       := 'BEGIN';
            l_year_begin  := i_year_begin(i); --substr(l_dt_probl_begin_str, 1, 4); -- problem begin year date
            l_month_begin := i_month_begin(i); --substr(l_dt_probl_begin_str, 5, 2); -- problem begin month date
            l_day_begin   := i_day_begin(i); --substr(l_dt_probl_begin_str, 7, 2); -- problem begin day date
        
            IF l_year_begin_f IS NULL
            THEN
                l_year_begin_f  := l_year_begin;
                l_month_begin_f := l_month_begin;
                l_day_begin_f   := l_day_begin;
            ELSE
            
                g_error  := 'Call pk_ref_utils.compare_dt / i_year_1=' || l_year_begin_f || ' i_month_1=' ||
                            l_month_begin_f || ' i_day_1=' || l_day_begin_f || ' i_year_2=' || l_year_begin ||
                            ' i_month_2=' || l_month_begin || ' i_day_2=' || l_day_begin;
                l_result := pk_ref_utils.compare_dt(i_lang    => i_lang,
                                                    i_prof    => i_prof,
                                                    i_year_1  => l_year_begin_f,
                                                    i_month_1 => l_month_begin_f,
                                                    i_day_1   => l_day_begin_f,
                                                    i_year_2  => l_year_begin,
                                                    i_month_2 => l_month_begin,
                                                    i_day_2   => l_day_begin);
            
                g_error := g_error || ' / result=' || l_result;
                IF l_result = pk_ref_constant.g_date_greater
                THEN
                    l_year_begin_f  := l_year_begin;
                    l_month_begin_f := l_month_begin;
                    l_day_begin_f   := l_day_begin;
                END IF;
            END IF;
        END LOOP;
    
        -- convert to flash format
        g_error       := 'Call pk_ref_utils.parse_dt_str_flash / i_year=' || l_year_begin_f || ' i_month=' ||
                         l_month_begin_f || ' i_day=' || l_day_begin_f;
        o_probl_begin := pk_ref_utils.parse_dt_str_flash(i_lang  => i_lang,
                                                         i_prof  => i_prof,
                                                         i_year  => l_year_begin_f,
                                                         i_month => l_month_begin_f,
                                                         i_day   => l_day_begin_f);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_PROBLEM_BEGIN',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_problem_begin;

    /**
    * Creates the referral
    *
    * @param   i_lang               Language associated to the professional executing the request
    * @param   i_prof               Professional, institution and software ids
    * @param   i_workflow           Workflow identifier
    * @param   i_num_order          Professional num order that is creating the referral
    * @param   i_prof_name          Professional name that is creating the referral. If referral is at Hospital Entrance, this is the name considered
    * @param   i_id_patient         Patient identifier
    * @param   i_speciality         Referral speciality (P1_SPECIALITY)
    * @param   i_dcs                Id department/clinical_service (can be null)
    * @param   i_flg_priority       Urgent/not urgent
    * @param   i_flg_home           Home consultation?
    * @param   i_id_inst_orig       Institution origin identifier
    * @param   i_inst_orig_name     Institution origin name. If referral is at Hospital Entrance, this is the name considered
    * @param   i_id_inst_dest       Destination institution identifier
    * @param   i_p_flg_type         Problem array codification type: ICD9, ICD10, ICPC2...
    * @param   i_p_code_icd         Problem array code (code_icd)
    * @param   i_p_desc_problem     Problem array name
    * @param   i_p_year_begin       Problem array begin year. Format YYYY   
    * @param   i_p_month_begin      Problem array begin month. Format MM
    * @param   i_p_day_begin        Problem array begin day. Format DD
    * @param   i_d_flg_type         Diagnosis array codification type: ICD9, ICD10, ICPC2...
    * @param   i_d_code_icd         Diagnosis array code (code_icd)
    * @param   i_d_desc_diagnosis   Diagnosis array name
    * @param   i_detail             Referral detail info. For each detail: [idx,[detail_type|text]]
    * @param   i_id_external_sys    External system identifier
    * @param   i_date               Operation date
    * @param   o_id_ref             Referral identifier
    * @param   o_error              An error message, set when return=false
    *
    * @value   i_flg_priority       {*} 'Y' - Urgent {*} 'N' - Not urgent
    * @value   i_flg_home           {*} 'Y' - Home consultation {*} 'N' - Hospital consultation
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.6.0.5
    * @since   17-02-2011
    */
    FUNCTION create_referral
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_workflow       IN p1_external_request.id_workflow%TYPE,
        i_num_order      IN professional.num_order%TYPE,
        i_prof_name      IN professional.name%TYPE,
        i_id_patient     IN p1_external_request.id_patient%TYPE,
        i_speciality     IN p1_external_request.id_speciality%TYPE,
        i_dcs            IN p1_external_request.id_dep_clin_serv%TYPE,
        i_flg_priority   IN p1_external_request.flg_priority%TYPE,
        i_flg_home       IN p1_external_request.flg_home%TYPE,
        i_id_inst_orig   IN p1_external_request.id_inst_orig%TYPE,
        i_inst_orig_name IN VARCHAR2,
        i_id_inst_dest   IN institution.id_institution%TYPE,
        -- problems data
        i_p_flg_type     IN table_varchar, -- ICD9, ICPC2, ICD10...
        i_p_code_icd     IN table_varchar,
        i_p_desc_problem IN table_varchar,
        --i_p_dt_begin     IN table_varchar,
        i_p_year_begin  IN table_number, -- YYYY
        i_p_month_begin IN table_number, -- MM
        i_p_day_begin   IN table_number, -- DD
        -- diagnosis data
        i_d_flg_type       IN table_varchar, -- ICD9, ICPC2, ICD10...
        i_d_code_icd       IN table_varchar,
        i_d_desc_diagnosis IN table_varchar,
        -- clinical info
        i_detail          IN table_table_varchar,
        i_id_external_sys IN p1_external_request.id_external_sys%TYPE,
        i_date            IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_comments        IN table_table_clob, -- ID ref comment, Flg Status, texto        
        o_id_ref          OUT p1_external_request.id_external_request%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        -- referral data
        l_id_prof_create        professional.id_professional%TYPE;
        l_id_prf_templ          profile_template.id_profile_template%TYPE;
        l_prof_create_name      professional.name%TYPE;
        l_prof_create_num_order professional.num_order%TYPE;
        l_prof                  profissional;
        l_flg_priority          p1_external_request.flg_priority%TYPE;
        l_flg_home              p1_external_request.flg_home%TYPE;
        l_inst_orig_name        VARCHAR2(1000 CHAR);
        l_id_inst_orig          p1_external_request.id_inst_orig%TYPE;
        l_id_workflow           p1_external_request.id_workflow%TYPE;
        l_problems              table_number;
        l_problems_desc         table_varchar;
        l_dt_problem_begin      VARCHAR2(50 CHAR);
        l_diagnosis             table_number;
        l_detail                table_table_varchar;
        l_detail_in             table_table_varchar;
        l_reason_text           sys_message.desc_message%TYPE;
        l_dcs                   p1_external_request.id_dep_clin_serv%TYPE;
        l_ref_external_inst     institution.id_institution%TYPE;
    
        l_flg_show  VARCHAR2(1 CHAR);
        l_msg_title VARCHAR2(1000 CHAR);
        l_msg       VARCHAR2(1000 CHAR);
        l_button    VARCHAR2(200 CHAR);
    BEGIN
        ----------------------
        -- INIT
        ----------------------        
        g_error := '->Init create_referral / WF=' || i_workflow || ' NUM_ORDER=' || i_num_order || ' PROF_NAME=' ||
                   i_prof_name || ' ID_PATIENT=' || i_id_patient || ' ID_SPECIALITY=' || i_speciality ||
                   ' ID_DEP_CLIN_SERV=' || i_dcs || ' FLG_PRIORITY=' || i_flg_priority || ' FLG_HOME=' || i_flg_home ||
                   ' ID_INST_ORIG=' || i_id_inst_orig || ' INST_ORIG_NAME=' || i_inst_orig_name || ' ID_INST_DEST=' ||
                   i_id_inst_dest || ' ID_EXT_SYS=' || i_id_external_sys;
        pk_alertlog.log_debug(g_error);
        g_error := 'Problems / ' || pk_utils.to_string(i_p_code_icd) || '/' || pk_utils.to_string(i_p_flg_type) || '] ' ||
                   pk_utils.to_string(i_p_year_begin) || '/' || pk_utils.to_string(i_p_month_begin) || '/' ||
                   pk_utils.to_string(i_p_day_begin);
        pk_alertlog.log_debug(g_error);
        g_error := 'Diagnosis / ' || pk_utils.to_string(i_d_code_icd) || '/' || pk_utils.to_string(i_d_flg_type);
        pk_alertlog.log_debug(g_error);
        reset_vars;
        -- sets the referral context
        pk_ref_utils.init_ref_context;
        pk_ref_utils.set_ref_context(i_dt_system_date => current_timestamp);
    
        -- getting operation date
        g_sysdate_tstz := i_date;
    
        ----------------------
        -- VAL
        ----------------------
    
        -- mandatory parameters
        -- i_num_order - this parameter can be null when the referral is at hospital entrance       
        g_error := 'Validating mandatory parameters';
        IF i_id_patient IS NULL
           OR (i_flg_priority IS NOT NULL AND i_flg_priority NOT IN (pk_ref_constant.g_no, pk_ref_constant.g_yes))
           OR (i_flg_home IS NOT NULL AND i_flg_home NOT IN (pk_ref_constant.g_no, pk_ref_constant.g_yes))
           OR i_id_inst_dest IS NULL
           OR i_num_order IS NULL -- this parameter is mandatory even when i_workflow=pk_ref_constant.g_wf_x_hosp
           OR (i_id_inst_orig IS NULL AND (i_workflow IS NULL OR i_workflow != pk_ref_constant.g_wf_x_hosp))
           OR (i_speciality IS NULL AND (i_workflow IS NULL OR i_workflow != pk_ref_constant.g_wf_srv_srv))
        THEN
            g_error := 'Invalid parameter / ID_PATIENT=' || i_id_patient || ' ID_SPECIALITY=' || i_speciality ||
                       ' FLG_PRIORITY=' || i_flg_priority || ' FLG_HOME=' || i_flg_home || ' ID_INST_ORIG=' ||
                       i_id_inst_orig || ' ID_INST_DEST=' || i_id_inst_dest || ' ID_WF=' || i_workflow || ' NUM_ORDER=' ||
                       i_num_order;
        
            g_error_code := pk_ref_constant.g_ref_error_1005;
            g_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => g_error_code);
            RAISE g_exception;
        END IF;
    
        g_error := 'Validating mandatory parameters for internal workflow';
        IF i_workflow = pk_ref_constant.g_wf_srv_srv
           AND (i_dcs IS NULL OR i_speciality IS NOT NULL OR i_id_inst_orig IS NULL OR i_id_inst_dest IS NULL OR
           i_id_inst_orig != i_id_inst_dest)
        THEN
            g_error := 'Invalid parameter / ID_WF=' || i_workflow || ' ID_PATIENT=' || i_id_patient ||
                       ' ID_SPECIALITY=' || i_speciality || ' FLG_PRIORITY=' || i_flg_priority || ' FLG_HOME=' ||
                       i_flg_home || ' ID_INST_ORIG=' || i_id_inst_orig || ' ID_INST_DEST=' || i_id_inst_dest ||
                       ' NUM_ORDER=' || i_num_order;
        
            g_error_code := pk_ref_constant.g_ref_error_1005;
            g_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => g_error_code);
            RAISE g_exception;
        END IF;
    
        -- operation date
        g_error  := 'Call check_op_date';
        g_retval := check_op_date(i_lang => i_lang, i_prof => i_prof, i_op_date => g_sysdate_tstz, o_error => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- check referral workflow
        g_error  := 'Call check_workflow / ID_WORKFLOW=' || i_workflow || ' ID_EXTERNAL_SYS=' || i_id_external_sys ||
                    ' ID_INST_ORIG=' || i_id_inst_orig || 'ID_INST_DEST=' || i_id_inst_dest;
        g_retval := check_workflow(i_lang         => i_lang,
                                   i_prof         => i_prof,
                                   i_id_workflow  => i_workflow,
                                   i_id_ext_sys   => i_id_external_sys,
                                   i_id_inst_orig => i_id_inst_orig,
                                   i_id_inst_dest => i_id_inst_dest,
                                   o_error        => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        g_error     := 'l_detail_in  / WF=' || i_workflow || ' NUM_ORDER=' || i_num_order || ' ID_PATIENT=' ||
                       i_id_patient || ' ID_SPECIALITY=' || i_speciality || ' ID_DEP_CLIN_SERV=' || i_dcs ||
                       ' FLG_PRIORITY=' || i_flg_priority || ' FLG_HOME=' || i_flg_home || ' ID_INST_ORIG=' ||
                       i_id_inst_orig || ' INST_ORIG_NAME=' || i_inst_orig_name || ' ID_INST_DEST=' || i_id_inst_dest ||
                       ' ID_EXT_SYS=' || i_id_external_sys;
        l_detail_in := i_detail;
    
        IF i_dcs IS NULL
        THEN
            -- getting default dep_clin_serv
            g_error  := 'Call pk_ref_core.get_default_dcs / i_id_ref=null i_id_speciality=' || i_speciality ||
                        ' i_id_inst_dest=' || i_id_inst_dest || ' i_id_ext_sys=' || i_id_external_sys;
            g_retval := pk_ref_core.get_default_dcs(i_lang          => i_lang,
                                                    i_prof          => i_prof,
                                                    i_id_ref        => NULL,
                                                    i_id_speciality => i_speciality,
                                                    i_id_inst_dest  => i_id_inst_dest,
                                                    i_id_ext_sys    => i_id_external_sys,
                                                    o_dcs           => l_dcs,
                                                    o_error         => o_error);
            IF NOT g_retval
            THEN
                RAISE g_exception_np;
            END IF;
        ELSE
            l_dcs := i_dcs;
        END IF;
    
        -- check referral input data
        g_error  := 'Call check_referral_data';
        g_retval := check_referral_data(i_lang           => i_lang,
                                        i_prof           => i_prof,
                                        i_workflow       => i_workflow,
                                        i_num_order      => i_num_order,
                                        i_prof_name      => i_prof_name,
                                        i_id_patient     => i_id_patient,
                                        i_speciality     => i_speciality,
                                        i_dcs            => l_dcs,
                                        i_flg_priority   => i_flg_priority,
                                        i_flg_home       => i_flg_home,
                                        i_id_inst_orig   => i_id_inst_orig,
                                        i_inst_orig_name => i_inst_orig_name,
                                        i_id_inst_dest   => i_id_inst_dest,
                                        -- problems data
                                        i_p_flg_type     => i_p_flg_type,
                                        i_p_code_icd     => i_p_code_icd,
                                        i_p_desc_problem => i_p_desc_problem,
                                        --i_p_dt_begin     => i_p_dt_begin,
                                        i_p_year_begin  => i_p_year_begin,
                                        i_p_month_begin => i_p_month_begin,
                                        i_p_day_begin   => i_p_day_begin,
                                        -- diagnosis data
                                        i_d_flg_type       => i_d_flg_type,
                                        i_d_code_icd       => i_d_code_icd,
                                        i_d_desc_diagnosis => i_d_desc_diagnosis,
                                        -- clinical info
                                        i_id_external_sys => i_id_external_sys,
                                        io_detail         => l_detail_in,
                                        o_id_prof         => l_id_prof_create,
                                        o_id_prf_templ    => l_id_prf_templ,
                                        o_error           => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        ----------------------
        -- FUNC
        ----------------------    
        g_error        := 'FLGs / i_flg_priority=' || i_flg_priority || ' i_flg_home=' || i_flg_home;
        l_flg_priority := nvl(i_flg_priority, pk_ref_constant.g_no);
        l_flg_home     := nvl(i_flg_home, pk_ref_constant.g_no);
    
        IF i_workflow = pk_ref_constant.g_wf_x_hosp
        THEN
        
            -- at hospital entrance
            g_error       := 'At hospital entrance / ID_WF=' || i_workflow;
            l_id_workflow := pk_ref_constant.g_wf_x_hosp;
        
            -- professional            
            l_prof    := profissional(NULL, i_id_inst_dest, pk_ref_constant.g_id_soft_referral);
            l_prof.id := to_number(pk_sysconfig.get_config(pk_ref_constant.g_sc_intf_prof_id, i_prof));
        
            -- l_id_prof_create is the professional that requested the referral (will be created in PK_REF_ORIG_PHY.create_referral)
            l_prof_create_name      := i_prof_name;
            l_prof_create_num_order := i_num_order;
        
            -- origin institution (configured in alert or not)
            g_error             := 'Orig institution / i_id_inst_orig=' || i_id_inst_orig;
            l_ref_external_inst := pk_sysconfig.get_config(i_code_cf => pk_ref_constant.g_ref_external_inst,
                                                           i_prof    => l_prof);
            l_id_inst_orig      := i_id_inst_orig;
            IF l_id_inst_orig = l_ref_external_inst
            THEN
                l_inst_orig_name := i_inst_orig_name;
                -- adding pre-defined text to reason field
                l_reason_text := pk_message.get_message(i_lang, pk_ref_constant.g_sm_ref_h_entrance);
            ELSE
                -- adding pre-defined text to reason field
                l_reason_text := pk_message.get_message(i_lang, pk_ref_constant.g_sm_ref_h_entrance_orig_inst);
            END IF;
        
            g_error := 'Adding Reason detail type to Referral WF=' || l_id_workflow || ' l_detail_in.LAST=' ||
                       l_detail_in.last;
            l_detail_in.extend;
            l_detail_in(l_detail_in.last) := table_varchar(to_char(pk_ref_constant.g_detail_type_jstf), l_reason_text);
        
        ELSE
            -- other workflows
            g_error        := 'Other workflows / ID_WF=' || i_workflow;
            l_prof         := profissional(l_id_prof_create, i_id_inst_orig, pk_ref_constant.g_id_soft_referral);
            l_id_inst_orig := i_id_inst_orig;
        
            g_error       := 'Call pk_ref_utils.get_workflow / ID_EXTERNAL_SYS=' || i_id_external_sys ||
                             ' ID_INST_ORIG=' || l_id_inst_orig || ' ID_INST_DEST=' || i_id_inst_dest;
            l_id_workflow := pk_ref_utils.get_workflow(i_lang         => i_lang,
                                                       i_prof         => l_prof,
                                                       i_id_ext_sys   => i_id_external_sys,
                                                       i_id_inst_orig => l_id_inst_orig,
                                                       i_id_inst_dest => i_id_inst_dest,
                                                       i_detail       => l_detail_in);
        
            IF NOT g_retval
            THEN
                RAISE g_exception_np;
            END IF;
        
        END IF;
    
        -- getting problems info
        g_error  := 'Call map_to_diag_array / PROBLEMS';
        g_retval := map_to_diag_array(i_lang       => i_lang,
                                      i_prof       => l_prof,
                                      i_flg_type   => i_p_flg_type,
                                      i_code_icd   => i_p_code_icd,
                                      o_diag_array => l_problems,
                                      o_error      => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        l_problems_desc := table_varchar();
        l_problems_desc.extend(l_problems.count);
    
        -- getting problem begin date (the oldest)
        g_error  := 'Call get_problem_begin';
        g_retval := get_problem_begin(i_lang => i_lang,
                                      i_prof => l_prof,
                                      --i_probl_begin => i_p_dt_begin,
                                      i_year_begin  => i_p_year_begin,
                                      i_month_begin => i_p_month_begin,
                                      i_day_begin   => i_p_day_begin,
                                      o_probl_begin => l_dt_problem_begin,
                                      o_error       => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- getting diagnosis info
        g_error  := 'Call map_to_diag_array / DIAGNOSIS';
        g_retval := map_to_diag_array(i_lang       => i_lang,
                                      i_prof       => l_prof,
                                      i_flg_type   => i_d_flg_type,
                                      i_code_icd   => i_d_code_icd,
                                      o_diag_array => l_diagnosis,
                                      o_error      => o_error);
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- getting referral detail
        g_error  := 'Call map_detail_array';
        g_retval := map_detail_array(i_lang         => i_lang,
                                     i_prof         => l_prof,
                                     i_id_ref       => NULL, -- creating referral
                                     i_detail       => l_detail_in,
                                     o_detail_array => l_detail,
                                     o_error        => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        g_error := 'ID_WF=' || l_id_workflow || ' ID_PATIENT=' || i_id_patient || ' ID_SPECIALITY=' || i_speciality ||
                   ' I_DCS=' || l_dcs || ' FLG_PRIORITY=' || l_flg_priority || ' FLG_HOME=' || l_flg_home ||
                   ' ID_INST_DEST=' || i_id_inst_dest || ' PROBLEMS.COUNT=' || l_problems.count || ' DIAGNOSIS.COUNT=' ||
                   l_diagnosis.count || ' i_id_external_sys=' || i_id_external_sys;
    
        IF l_id_workflow IS NULL
        THEN
            g_error  := 'Call pk_p1_med_cs.create_external_request / ' || g_error;
            g_retval := pk_p1_med_cs.create_external_request(i_lang             => i_lang,
                                                             i_prof             => l_prof,
                                                             i_id_patient       => i_id_patient,
                                                             i_speciality       => i_speciality,
                                                             i_id_dep_clin_serv => l_dcs,
                                                             i_req_type         => pk_ref_constant.g_p1_req_type_m,
                                                             i_flg_type         => pk_ref_constant.g_p1_type_c,
                                                             i_flg_priority     => l_flg_priority,
                                                             i_flg_home         => l_flg_home,
                                                             i_inst_dest        => i_id_inst_dest,
                                                             --i_id_sched            => NULL, -- not used
                                                             i_problems            => NULL,
                                                             i_dt_problem_begin    => l_dt_problem_begin,
                                                             i_detail              => l_detail,
                                                             i_diagnosis           => NULL,
                                                             i_completed           => pk_ref_constant.g_yes,
                                                             i_id_tasks            => table_table_number(), -- there are no tasks
                                                             i_id_info             => table_table_number(), -- there are no tasks
                                                             i_epis                => NULL,
                                                             i_external_sys        => i_id_external_sys,
                                                             i_date                => g_sysdate_tstz,
                                                             i_comments            => i_comments,
                                                             i_prof_cert           => NULL,
                                                             i_prof_first_name     => NULL,
                                                             i_prof_surname        => NULL,
                                                             i_prof_phone          => NULL,
                                                             i_id_fam_rel          => NULL,
                                                             i_name_first_rel      => NULL,
                                                             i_name_middle_rel     => NULL,
                                                             i_name_last_rel       => NULL,
                                                             o_id_external_request => o_id_ref,
                                                             o_flg_show            => l_flg_show,
                                                             o_msg                 => l_msg,
                                                             o_msg_title           => l_msg_title,
                                                             o_button              => l_button,
                                                             o_error               => o_error);
        ELSE
        
            g_error  := 'Call pk_ref_orig_phy.create_referral / ' || g_error;
            g_retval := pk_ref_orig_phy.create_referral(i_lang             => i_lang,
                                                        i_prof             => l_prof,
                                                        i_workflow         => l_id_workflow,
                                                        i_id_patient       => i_id_patient,
                                                        i_speciality       => i_speciality,
                                                        i_dcs              => l_dcs,
                                                        i_req_type         => pk_ref_constant.g_p1_req_type_m,
                                                        i_flg_type         => pk_ref_constant.g_p1_type_c,
                                                        i_flg_priority     => l_flg_priority,
                                                        i_flg_home         => l_flg_home,
                                                        i_id_inst_orig     => l_id_inst_orig,
                                                        i_inst_dest        => i_id_inst_dest,
                                                        i_problems         => NULL,
                                                        i_dt_problem_begin => l_dt_problem_begin,
                                                        i_detail           => l_detail,
                                                        i_diagnosis        => NULL,
                                                        i_completed        => pk_ref_constant.g_yes,
                                                        i_id_tasks         => table_table_number(), -- there are no tasks
                                                        i_id_info          => table_table_number(), -- there are no tasks
                                                        i_epis             => NULL,
                                                        i_num_order        => l_prof_create_num_order,
                                                        i_prof_name        => l_prof_create_name,
                                                        i_prof_id          => l_id_prof_create,
                                                        i_institution_name => l_inst_orig_name,
                                                        i_external_sys     => i_id_external_sys,
                                                        i_date             => g_sysdate_tstz,
                                                        i_comments         => i_comments,
                                                        i_prof_cert        => NULL,
                                                        i_prof_first_name  => NULL,
                                                        i_prof_surname     => NULL,
                                                        i_prof_phone       => NULL,
                                                        i_id_fam_rel       => NULL,
                                                        i_name_first_rel   => NULL,
                                                        i_name_middle_rel  => NULL,
                                                        i_name_last_rel    => NULL,
                                                        o_flg_show         => l_flg_show,
                                                        o_msg              => l_msg,
                                                        o_msg_title        => l_msg_title,
                                                        o_button           => l_button,
                                                        o_ext_req          => o_id_ref,
                                                        o_error            => o_error);
        
        END IF;
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- resets the referral context
        pk_ref_utils.reset_ref_context;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            IF g_error_code IS NOT NULL
            THEN
                g_flg_action := pk_ref_constant.g_err_flg_action_u;
            ELSE
                g_error_code := SQLCODE;
                g_error_desc := SQLERRM;
                g_flg_action := pk_ref_constant.g_err_flg_action_s;
            END IF;
            pk_alert_exceptions.process_error(i_lang        => i_lang,
                                              i_sqlcode     => g_error_code,
                                              i_sqlerrm     => g_error_desc,
                                              i_message     => g_error,
                                              i_owner       => g_package_owner,
                                              i_package     => g_package_name,
                                              i_function    => 'SET_REFERRAL',
                                              i_action_type => g_flg_action,
                                              i_action_msg  => NULL,
                                              o_error       => o_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END create_referral;

    /**
    * Updates the referral
    *
    * @param   i_lang               Language associated to the professional executing the request
    * @param   i_prof               Professional, institution and software ids
    * @param   i_id_ref             Referral identifier   
    * @param   i_workflow           Workflow identifier. Used to check if this is the correct referral to be updated.
    * @param   i_num_order          Professional num order that is updating the referral. Ignored when the referral is at Hospital Entrance.
    * @param   i_prof_name          Professional name that is updating the referral
    * @param   i_id_patient         Patient identifier. Used to check if this is the correct referral to be updated.
    * @param   i_speciality         Referral speciality (P1_SPECIALITY). Used to check if this is the correct referral to be updated.
    * @param   i_dcs                Id department/clinical_service. Defined when the referral is inside the Hospital. Used to check if this is the correct referral to be updated.
    * @param   i_flg_priority       Urgent/not urgent
    * @param   i_flg_home           Home consultation?
    * @param   i_id_inst_orig       Institution origin identifier. Used to check if this is the correct referral to be updated.
    * @param   i_inst_orig_name     Institution origin name. Used to check if this is the correct referral to be updated.
    * @param   i_id_inst_dest       Destination institution identifier. Used to check if this is the correct referral to be updated.
    * @param   i_p_flg_type         Problem array codification type: ICD9, ICD10, ICPC2...
    * @param   i_p_code_icd         Problem array code (code_icd)
    * @param   i_p_desc_problem     Problem array name
    * @param   i_p_year_begin       Problem array begin year. Format YYYY   
    * @param   i_p_month_begin      Problem array begin month. Format MM
    * @param   i_p_day_begin        Problem array begin day. Format DD
    * @param   i_d_flg_type         Diagnosis array codification type: ICD9, ICD10, ICPC2...
    * @param   i_d_code_icd         Diagnosis array code (code_icd)
    * @param   i_d_desc_diagnosis   Diagnosis array name
    * @param   i_detail             Referral detail info. For each detail: [idx,[detail_type|text]]
    * @param   i_id_external_sys    External system identifier. Used to check if this is the correct referral to be updated.
    * @param   i_date               Operation date
    * @param   o_id_ref             Referral identifier
    * @param   o_error              An error message, set when return=false
    *
    * @value   i_flg_priority       {*} 'Y' - Urgent {*} 'N' - Not urgent
    * @value   i_flg_home           {*} 'Y' - Home consultation {*} 'N' - Hospital consultation
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.6.0.5
    * @since   18-02-2011
    */
    FUNCTION update_referral
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_ref         IN p1_external_request.id_external_request%TYPE,
        i_workflow       IN p1_external_request.id_workflow%TYPE,
        i_num_order      IN professional.num_order%TYPE,
        i_prof_name      IN professional.name%TYPE,
        i_id_patient     IN p1_external_request.id_patient%TYPE,
        i_speciality     IN p1_external_request.id_speciality%TYPE,
        i_dcs            IN p1_external_request.id_dep_clin_serv%TYPE,
        i_flg_priority   IN p1_external_request.flg_priority%TYPE,
        i_flg_home       IN p1_external_request.flg_home%TYPE,
        i_id_inst_orig   IN p1_external_request.id_inst_orig%TYPE,
        i_inst_orig_name IN VARCHAR2,
        i_id_inst_dest   IN institution.id_institution%TYPE,
        -- problems data
        i_p_flg_type     IN table_varchar, -- ICD9, ICPC2, ICD10...
        i_p_code_icd     IN table_varchar,
        i_p_desc_problem IN table_varchar,
        --i_p_dt_begin     IN table_varchar,
        i_p_year_begin  IN table_number, -- YYYY
        i_p_month_begin IN table_number, -- MM
        i_p_day_begin   IN table_number, -- DD
        -- diagnosis data
        i_d_flg_type       IN table_varchar, -- ICD9, ICPC2, ICD10...
        i_d_code_icd       IN table_varchar,
        i_d_desc_diagnosis IN table_varchar,
        -- clinical info
        i_detail          IN table_table_varchar,
        i_id_external_sys IN p1_external_request.id_external_sys%TYPE,
        i_date            IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_comments        IN table_table_clob, -- ID ref comment, Flg Status, texto                
        o_id_ref          OUT p1_external_request.id_external_request%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        -- referral data
        l_ref_old_row           p1_external_request%ROWTYPE;
        l_id_prof_create        professional.id_professional%TYPE;
        l_id_prf_templ          profile_template.id_profile_template%TYPE;
        l_prof_create_name      professional.name%TYPE;
        l_prof_create_num_order professional.num_order%TYPE;
        l_prof                  profissional;
        l_flg_priority          p1_external_request.flg_priority%TYPE;
        l_flg_home              p1_external_request.flg_home%TYPE;
        l_id_inst_orig          p1_external_request.id_inst_orig%TYPE;
        l_id_workflow           p1_external_request.id_workflow%TYPE;
        l_dcs                   p1_external_request.id_dep_clin_serv%TYPE;
        l_problems              table_number;
        l_problems_desc         table_varchar;
        l_dt_problem_begin      VARCHAR2(50 CHAR);
        l_diagnosis             table_number;
        l_detail                table_table_varchar;
        l_detail_in             table_table_varchar;
        l_flg_show              VARCHAR2(1 CHAR);
        l_msg_title             VARCHAR2(1000 CHAR);
        l_msg                   VARCHAR2(1000 CHAR);
        l_button                VARCHAR2(200 CHAR);
        l_flg_valid             VARCHAR2(1 CHAR);
        l_check_date            VARCHAR2(1 CHAR);
    BEGIN
        ----------------------
        -- INIT
        ----------------------        
        g_error := '->Init update_referral / ID_REF=' || i_id_ref || ' WF=' || i_workflow || ' NUM_ORDER=' ||
                   i_num_order || ' PROF_NAME=' || i_prof_name || ' ID_PATIENT=' || i_id_patient || ' ID_SPECIALITY=' ||
                   i_speciality || ' ID_DEP_CLIN_SERV=' || i_dcs || ' FLG_PRIORITY=' || i_flg_priority || ' FLG_HOME=' ||
                   i_flg_home || ' ID_INST_ORIG=' || i_id_inst_orig || ' INST_ORIG_NAME=' || i_inst_orig_name ||
                   ' ID_INST_DEST=' || i_id_inst_dest || ' ID_EXT_SYS=' || i_id_external_sys;
        pk_alertlog.log_debug(g_error);
        g_error := 'Problems / ' || pk_utils.to_string(i_p_code_icd) || '/' || pk_utils.to_string(i_p_flg_type) || '] ' ||
                   pk_utils.to_string(i_p_year_begin) || '/' || pk_utils.to_string(i_p_month_begin) || '/' ||
                   pk_utils.to_string(i_p_day_begin);
        pk_alertlog.log_debug(g_error);
        g_error := 'Diagnosis / ' || pk_utils.to_string(i_d_code_icd) || '/' || pk_utils.to_string(i_d_flg_type);
        pk_alertlog.log_debug(g_error);
        reset_vars;
        -- sets the referral context
        pk_ref_utils.init_ref_context;
        pk_ref_utils.set_ref_context(i_id_external_request => i_id_ref, i_dt_system_date => current_timestamp);
    
        -- getting operation date
        g_sysdate_tstz := i_date;
    
        ----------------------
        -- VAL
        ----------------------
        -- mandatory parameters
        -- i_num_order - this parameter can be null when the referral is at hospital entrance       
        g_error := 'Validating mandatory parameters';
        IF i_id_ref IS NULL
           OR i_id_patient IS NULL
           OR (i_flg_priority IS NOT NULL AND i_flg_priority NOT IN (pk_ref_constant.g_no, pk_ref_constant.g_yes))
           OR (i_flg_home IS NOT NULL AND i_flg_home NOT IN (pk_ref_constant.g_no, pk_ref_constant.g_yes))
           OR i_id_inst_dest IS NULL
           OR (i_num_order IS NULL AND (i_workflow IS NULL OR i_workflow != pk_ref_constant.g_wf_x_hosp))
           OR (i_id_inst_orig IS NULL AND (i_workflow IS NULL OR i_workflow != pk_ref_constant.g_wf_x_hosp))
           OR (i_speciality IS NULL AND (i_workflow IS NULL OR i_workflow != pk_ref_constant.g_wf_srv_srv))
        THEN
        
            g_error := 'Invalid parameter / ID_REF=' || i_id_ref || ' ID_PATIENT=' || i_id_patient || ' ID_SPECIALITY=' ||
                       i_speciality || ' FLG_PRIORITY=' || i_flg_priority || ' FLG_HOME=' || i_flg_home ||
                       ' ID_INST_ORIG=' || i_id_inst_orig || ' ID_INST_DEST=' || i_id_inst_dest || ' ID_WF=' ||
                       i_workflow || ' NUM_ORDER=' || i_num_order;
        
            g_error_code := pk_ref_constant.g_ref_error_1005;
            g_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => g_error_code);
            RAISE g_exception;
        END IF;
    
        g_error := 'Validating mandatory parameters for internal workflow';
        IF i_workflow = pk_ref_constant.g_wf_srv_srv
           AND (i_dcs IS NULL OR i_speciality IS NOT NULL OR i_id_inst_orig IS NULL OR i_id_inst_dest IS NULL OR
           i_id_inst_orig != i_id_inst_dest)
        THEN
            g_error := 'Invalid parameter / ID_WF=' || i_workflow || ' ID_PATIENT=' || i_id_patient ||
                       ' ID_SPECIALITY=' || i_speciality || ' FLG_PRIORITY=' || i_flg_priority || ' FLG_HOME=' ||
                       i_flg_home || ' ID_INST_ORIG=' || i_id_inst_orig || ' ID_INST_DEST=' || i_id_inst_dest ||
                       ' NUM_ORDER=' || i_num_order;
        
            g_error_code := pk_ref_constant.g_ref_error_1005;
            g_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => g_error_code);
            RAISE g_exception;
        END IF;
    
        -- operation date
        g_error  := 'Call check_op_date';
        g_retval := check_op_date(i_lang => i_lang, i_prof => i_prof, i_op_date => g_sysdate_tstz, o_error => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        g_error     := 'l_detail_in  / ID_REF=' || i_id_ref || ' WF=' || i_workflow || ' NUM_ORDER=' || i_num_order ||
                       ' ID_PATIENT=' || i_id_patient || ' ID_SPECIALITY=' || i_speciality || ' ID_DEP_CLIN_SERV=' ||
                       i_dcs || ' FLG_PRIORITY=' || i_flg_priority || ' FLG_HOME=' || i_flg_home || ' ID_INST_ORIG=' ||
                       i_id_inst_orig || ' INST_ORIG_NAME=' || i_inst_orig_name || ' ID_INST_DEST=' || i_id_inst_dest ||
                       ' ID_EXT_SYS=' || i_id_external_sys;
        l_detail_in := i_detail;
    
        -- check referral input data
        g_error  := 'Call check_referral_data';
        g_retval := check_referral_data(i_lang           => i_lang,
                                        i_prof           => i_prof,
                                        i_workflow       => i_workflow,
                                        i_num_order      => i_num_order,
                                        i_prof_name      => i_prof_name,
                                        i_id_patient     => i_id_patient,
                                        i_speciality     => i_speciality,
                                        i_dcs            => i_dcs,
                                        i_flg_priority   => i_flg_priority,
                                        i_flg_home       => i_flg_home,
                                        i_id_inst_orig   => i_id_inst_orig,
                                        i_inst_orig_name => i_inst_orig_name,
                                        i_id_inst_dest   => i_id_inst_dest,
                                        -- problems data
                                        i_p_flg_type     => i_p_flg_type,
                                        i_p_code_icd     => i_p_code_icd,
                                        i_p_desc_problem => i_p_desc_problem,
                                        --i_p_dt_begin     => i_p_dt_begin,
                                        i_p_year_begin  => i_p_year_begin,
                                        i_p_month_begin => i_p_month_begin,
                                        i_p_day_begin   => i_p_day_begin,
                                        -- diagnosis data
                                        i_d_flg_type       => i_d_flg_type,
                                        i_d_code_icd       => i_d_code_icd,
                                        i_d_desc_diagnosis => i_d_desc_diagnosis,
                                        -- clinical info
                                        i_id_external_sys => i_id_external_sys,
                                        io_detail         => l_detail_in,
                                        o_id_prof         => l_id_prof_create,
                                        o_id_prf_templ    => l_id_prf_templ,
                                        o_error           => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        --------------
        -- getting referral data
        g_error  := 'Call pk_p1_external_request.get_ref_row / ID_REF=' || i_id_ref;
        g_retval := pk_p1_external_request.get_ref_row(i_lang   => i_lang,
                                                       i_prof   => i_prof,
                                                       i_id_ref => i_id_ref,
                                                       o_rec    => l_ref_old_row,
                                                       o_error  => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        g_error := 'i_dcs=' || i_dcs || ' l_ref_old_row.id_dep_clin_serv=' || l_ref_old_row.id_dep_clin_serv;
        IF i_dcs IS NULL
        THEN
            l_dcs := l_ref_old_row.id_dep_clin_serv;
        ELSE
            l_dcs := i_dcs;
        END IF;
    
        -- update date must be greater than requested date
        IF l_ref_old_row.dt_requested IS NOT NULL
           AND g_sysdate_tstz IS NOT NULL
        THEN
        
            g_error      := 'Call pk_date_utils.compare_dates_tsz';
            l_check_date := pk_date_utils.compare_dates_tsz(i_prof  => i_prof,
                                                            i_date1 => g_sysdate_tstz,
                                                            i_date2 => l_ref_old_row.dt_requested);
        
            IF l_check_date = pk_ref_constant.g_date_lower
            THEN
            
                -- g_sysdate_tstz < l_ref_old_row.dt_requested
                g_error      := 'INVALID OPERATION_DATE / OP_DATE=' ||
                                pk_date_utils.to_char_insttimezone(i_prof,
                                                                   g_sysdate_tstz,
                                                                   pk_ref_constant.g_format_date_2) ||
                                ' REQUESTED_DATE=' ||
                                pk_date_utils.to_char_insttimezone(i_prof,
                                                                   l_ref_old_row.dt_requested,
                                                                   pk_ref_constant.g_format_date_2);
                g_error_code := pk_ref_constant.g_ref_error_1005;
                g_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => g_error_code);
                RAISE g_exception;
            END IF;
        
        END IF;
    
        ----------------------
        -- FUNC
        ----------------------        
        IF i_workflow = pk_ref_constant.g_wf_x_hosp
        THEN
        
            -- at hospital entrance
            g_error       := 'At hospital entrance / ID_WF=' || i_workflow;
            l_id_workflow := pk_ref_constant.g_wf_x_hosp;
        
            -- professional            
            l_prof    := profissional(NULL, i_id_inst_dest, pk_ref_constant.g_id_soft_referral);
            l_prof.id := to_number(pk_sysconfig.get_config(pk_ref_constant.g_sc_intf_prof_id, i_prof));
        
            -- l_id_prof_create is the professional that requested the referral (if configured in Alert)
            l_prof_create_name      := i_prof_name;
            l_prof_create_num_order := i_num_order;
        
            -- origin institution (configured in alert or not)
            l_id_inst_orig := i_id_inst_orig;
        
            -- cannot add pre-defined text to reason field (this info is already there)
            -- inst_orig_name is not updatable (only on status O)
        ELSE
            -- other workflows
            g_error        := 'Other workflows / ID_WF=' || i_workflow;
            l_prof         := profissional(l_id_prof_create, i_id_inst_orig, pk_ref_constant.g_id_soft_referral);
            l_id_inst_orig := i_id_inst_orig;
        
            g_error       := 'Call pk_ref_utils.get_workflow / ID_EXTERNAL_SYS=' || i_id_external_sys ||
                             ' ID_INST_ORIG=' || l_id_inst_orig || ' ID_INST_DEST=' || i_id_inst_dest;
            l_id_workflow := pk_ref_utils.get_workflow(i_lang         => i_lang,
                                                       i_prof         => l_prof,
                                                       i_id_ext_sys   => i_id_external_sys,
                                                       i_id_inst_orig => l_id_inst_orig,
                                                       i_id_inst_dest => i_id_inst_dest,
                                                       i_detail       => l_detail_in);
        
            IF NOT g_retval
            THEN
                RAISE g_exception_np;
            END IF;
        
        END IF;
    
        --------------
        -- check if this professional can update the referral
        g_error := 'Professional can update referral?';
        IF l_ref_old_row.id_prof_requested != l_prof.id
        THEN
            g_error      := 'Professional ' || l_prof.id || ' cannot update the referral / Prof requested=' ||
                            l_ref_old_row.id_prof_requested;
            g_error_code := pk_ref_constant.g_ref_error_1009;
            g_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => g_error_code);
            RAISE g_exception;
        END IF;
    
        --------------
        -- check if is the correct referral to be updated
        g_error  := 'Call check_referral_update / ID_REF=' || l_ref_old_row.id_external_request;
        g_retval := check_referral_update(i_lang            => i_lang,
                                          i_prof            => l_prof,
                                          i_id_ref          => l_ref_old_row.id_external_request,
                                          i_old_flg_type    => pk_ref_constant.g_p1_type_c, -- considering only referral appointments for now
                                          i_old_id_workflow => l_ref_old_row.id_workflow,
                                          i_old_id_pat      => l_ref_old_row.id_patient,
                                          i_old_inst_dest   => l_ref_old_row.id_inst_dest,
                                          i_old_id_spec     => l_ref_old_row.id_speciality,
                                          i_old_id_dcs      => l_ref_old_row.id_dep_clin_serv,
                                          i_old_id_ext_sys  => l_ref_old_row.id_external_sys,
                                          i_old_flg_status  => l_ref_old_row.flg_status,
                                          i_new_flg_type    => pk_ref_constant.g_p1_type_c, -- considering only referral appointments for now
                                          i_new_id_workflow => l_id_workflow,
                                          i_new_id_pat      => i_id_patient,
                                          i_new_inst_dest   => i_id_inst_dest,
                                          i_new_id_spec     => i_speciality,
                                          i_new_id_dcs      => l_dcs,
                                          i_new_id_ext_sys  => i_id_external_sys,
                                          o_flg_valid       => l_flg_valid,
                                          o_error           => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        IF l_flg_valid = pk_ref_constant.g_no
        THEN
            g_error_code := pk_ref_constant.g_ref_error_1007;
            g_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => g_error_code);
            RAISE g_exception;
        END IF;
    
        --------------
        -- getting all the referral new data        
        g_error        := 'FLGs / i_flg_priority=' || i_flg_priority || ' i_flg_home=' || i_flg_home;
        l_flg_priority := nvl(i_flg_priority, pk_ref_constant.g_no);
        l_flg_home     := nvl(i_flg_home, pk_ref_constant.g_no);
    
        -- getting problems info
        g_error  := 'Call map_to_diag_array / PROBLEMS';
        g_retval := map_to_diag_array(i_lang       => i_lang,
                                      i_prof       => l_prof,
                                      i_flg_type   => i_p_flg_type,
                                      i_code_icd   => i_p_code_icd,
                                      o_diag_array => l_problems,
                                      o_error      => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        l_problems_desc := table_varchar();
        l_problems_desc.extend(l_problems.count);
    
        -- getting problem begin date (the oldest)
        g_error  := 'Call get_problem_begin';
        g_retval := get_problem_begin(i_lang => i_lang,
                                      i_prof => l_prof,
                                      --i_probl_begin => i_p_dt_begin,
                                      i_year_begin  => i_p_year_begin,
                                      i_month_begin => i_p_month_begin,
                                      i_day_begin   => i_p_day_begin,
                                      o_probl_begin => l_dt_problem_begin,
                                      o_error       => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- getting diagnosis info
        g_error  := 'Call map_to_diag_array / DIAGNOSIS';
        g_retval := map_to_diag_array(i_lang       => i_lang,
                                      i_prof       => l_prof,
                                      i_flg_type   => i_d_flg_type,
                                      i_code_icd   => i_d_code_icd,
                                      o_diag_array => l_diagnosis,
                                      o_error      => o_error);
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- getting referral detail
        g_error  := 'Call map_detail_array';
        g_retval := map_detail_array(i_lang         => i_lang,
                                     i_prof         => l_prof,
                                     i_id_ref       => i_id_ref,
                                     i_detail       => l_detail_in,
                                     o_detail_array => l_detail,
                                     o_error        => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        --------------
        -- Sets all existing clinical detail to outdated (all that can be updated)
        -- diagnosis and problems do not need to be cancelled, they already are when updating referral
        g_error  := 'Call outdate_ref_detail';
        g_retval := outdate_ref_detail(i_lang        => i_lang,
                                       i_prof        => l_prof,
                                       i_id_ref      => i_id_ref,
                                       i_id_workflow => l_ref_old_row.id_workflow,
                                       io_detail     => l_detail,
                                       o_error       => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        --------------
        -- updating the referral
        g_error := 'ID_WF=' || l_id_workflow || ' ID_REF=' || i_id_ref || ' ID_SPECIALITY=' || i_speciality || ' DCS=' ||
                   l_dcs || ' FLG_PRIORITY=' || l_flg_priority || ' FLG_HOME=' || l_flg_home || ' ID_INST_DEST=' ||
                   i_id_inst_dest || ' PROBLEMS.COUNT=' || l_problems.count || ' DIAGNOSIS.COUNT=' || l_diagnosis.count ||
                   ' PROF_CREATE_NUM_ORDER=' || l_prof_create_num_order || ' ID_PROF_CREATE=' || l_id_prof_create ||
                   ' ID_INST_ORIG=' || l_id_inst_orig;
    
        IF l_id_workflow IS NULL
        THEN
        
            g_error  := 'Call pk_p1_med_cs.update_external_request / ' || g_error;
            g_retval := pk_p1_med_cs.update_external_request(i_lang             => i_lang,
                                                             i_prof             => l_prof,
                                                             i_ext_req          => i_id_ref,
                                                             i_dt_modified      => NULL, -- validation not supported when updating referral by interface
                                                             i_speciality       => i_speciality,
                                                             i_id_dep_clin_serv => l_dcs,
                                                             i_req_type         => pk_ref_constant.g_p1_req_type_m,
                                                             i_flg_type         => pk_ref_constant.g_p1_type_c,
                                                             i_flg_priority     => l_flg_priority,
                                                             i_flg_home         => l_flg_home,
                                                             i_inst_dest        => i_id_inst_dest,
                                                             --i_id_sched            => NULL, -- not used
                                                             i_problems            => NULL,
                                                             i_dt_problem_begin    => l_dt_problem_begin,
                                                             i_detail              => l_detail,
                                                             i_diagnosis           => NULL,
                                                             i_completed           => pk_ref_constant.g_yes,
                                                             i_id_tasks            => table_table_number(), -- there are no tasks
                                                             i_id_info             => table_table_number(), -- there are no tasks
                                                             i_date                => g_sysdate_tstz,
                                                             i_comments            => i_comments,
                                                             i_prof_cert           => NULL,
                                                             i_prof_first_name     => NULL,
                                                             i_prof_surname        => NULL,
                                                             i_prof_phone          => NULL,
                                                             i_id_fam_rel          => NULL,
                                                             i_name_first_rel      => NULL,
                                                             i_name_middle_rel     => NULL,
                                                             i_name_last_rel       => NULL,
                                                             o_id_external_request => o_id_ref,
                                                             o_flg_show            => l_flg_show,
                                                             o_msg                 => l_msg,
                                                             o_msg_title           => l_msg_title,
                                                             o_button              => l_button,
                                                             o_error               => o_error);
        
        ELSE
        
            g_error  := 'Call pk_ref_orig_phy.update_referral / ' || g_error;
            g_retval := pk_ref_orig_phy.update_referral(i_lang             => i_lang,
                                                        i_prof             => l_prof,
                                                        i_ext_req          => i_id_ref,
                                                        i_dt_modified      => NULL, -- validation not supported when updating referral by interface
                                                        i_speciality       => i_speciality,
                                                        i_dcs              => l_dcs,
                                                        i_req_type         => pk_ref_constant.g_p1_req_type_m,
                                                        i_flg_type         => pk_ref_constant.g_p1_type_c,
                                                        i_flg_priority     => l_flg_priority,
                                                        i_flg_home         => l_flg_home,
                                                        i_id_inst_orig     => l_id_inst_orig,
                                                        i_inst_dest        => i_id_inst_dest,
                                                        i_problems         => NULL,
                                                        i_dt_problem_begin => l_dt_problem_begin,
                                                        i_detail           => l_detail,
                                                        i_diagnosis        => NULL,
                                                        i_completed        => pk_ref_constant.g_yes,
                                                        i_id_tasks         => table_table_number(), -- there are no tasks
                                                        i_id_info          => table_table_number(), -- there are no tasks
                                                        i_num_order        => l_prof_create_num_order,
                                                        i_prof_name        => l_prof_create_name,
                                                        i_prof_id          => l_id_prof_create,
                                                        i_institution_name => NULL,
                                                        i_date             => g_sysdate_tstz,
                                                        i_comments         => i_comments,
                                                        i_prof_cert        => NULL,
                                                        i_prof_first_name  => NULL,
                                                        i_prof_surname     => NULL,
                                                        i_prof_phone       => NULL,
                                                        i_id_fam_rel       => NULL,
                                                        i_name_first_rel   => NULL,
                                                        i_name_middle_rel  => NULL,
                                                        i_name_last_rel    => NULL,
                                                        o_ext_req          => o_id_ref,
                                                        o_flg_show         => l_flg_show,
                                                        o_msg              => l_msg,
                                                        o_msg_title        => l_msg_title,
                                                        o_button           => l_button,
                                                        o_error            => o_error);
        
        END IF;
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- resets the referral context
        pk_ref_utils.reset_ref_context;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            IF g_error_code IS NOT NULL
            THEN
                g_flg_action := pk_ref_constant.g_err_flg_action_u; -- user defined error
            ELSE
                g_error_code := SQLCODE;
                g_error_desc := SQLERRM;
                g_flg_action := pk_ref_constant.g_err_flg_action_s; -- system error
            END IF;
            pk_alert_exceptions.process_error(i_lang        => i_lang,
                                              i_sqlcode     => g_error_code,
                                              i_sqlerrm     => g_error_desc,
                                              i_message     => g_error,
                                              i_owner       => g_package_owner,
                                              i_package     => g_package_name,
                                              i_function    => 'UPDATE_REFERRAL',
                                              i_action_type => g_flg_action,
                                              i_action_msg  => NULL,
                                              o_error       => o_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END update_referral;

    /**
    * Origin registrar resends referral, after it has been sent back to the origin institution
    *
    * @param   i_lang               Language associated to the professional executing the request
    * @param   i_prof               Professional, institution and software ids
    * @param   i_id_ref             Referral identifier   
    * @param   i_date               Operation date
    * @param   o_track              Tracking identifiers created due to the status change
    * @param   o_error              An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.6.0.5
    * @since   21-02-2011
    */
    FUNCTION resend_referral
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_id_ref IN p1_external_request.id_external_request%TYPE,
        i_date   IN DATE,
        o_track  OUT table_number,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
        l_flg_valid VARCHAR2(1 CHAR);
        l_prof      profissional;
        l_ref_row   p1_external_request%ROWTYPE;
        l_flg_show  VARCHAR2(1 CHAR);
        l_msg_title VARCHAR2(1000 CHAR);
        l_msg       VARCHAR2(1000 CHAR);
    BEGIN
        ----------------------
        -- INIT
        ----------------------        
        g_error := '->Init resend_referral / ID_REF=' || i_id_ref;
        pk_alertlog.log_debug(g_error);
        reset_vars;
        g_prof_int := pk_p1_interface.set_prof_interface(i_prof);
        o_track    := table_number();
    
        -- sets the referral context
        pk_ref_utils.init_ref_context;
        pk_ref_utils.set_ref_context(i_id_external_request => i_id_ref, i_dt_system_date => current_timestamp);
    
        -- getting operation date
        g_error  := 'Call pk_ref_utils.get_operation_date / i_dt_d=' || i_date;
        g_retval := pk_ref_utils.get_operation_date(i_lang    => i_lang,
                                                    i_prof    => g_prof_int,
                                                    i_dt_d    => i_date,
                                                    o_dt_tstz => g_sysdate_tstz,
                                                    o_error   => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        ----------------------
        -- VAL
        ----------------------
        -- validating parameters
        g_error  := 'Call check_requirements';
        g_retval := check_requirements(i_lang      => i_lang,
                                       i_prof      => g_prof_int,
                                       i_id_ref    => i_id_ref,
                                       i_date      => g_sysdate_tstz,
                                       o_flg_valid => l_flg_valid,
                                       o_prof      => l_prof, -- ignored
                                       o_error     => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        IF l_flg_valid = pk_ref_constant.g_no
        THEN
            g_error := 'INVALID PARAMETERS';
            RAISE g_exception;
        END IF;
    
        ----------------------
        -- FUNC
        ----------------------
        -- get referral data
        g_error  := 'Call pk_p1_external_request.get_ref_row / ID_REF=' || i_id_ref;
        g_retval := pk_p1_external_request.get_ref_row(i_lang   => i_lang,
                                                       i_prof   => g_prof_int,
                                                       i_id_ref => i_id_ref,
                                                       o_rec    => l_ref_row,
                                                       o_error  => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- validating orig institution
        IF i_prof.institution != l_ref_row.id_inst_orig
        THEN
            g_error      := 'Professional institution (' || i_prof.institution ||
                            ') must be the same as orig institution (' || l_ref_row.id_inst_orig || ')';
            g_error_code := pk_ref_constant.g_ref_error_1009;
            g_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => g_error_code);
            RAISE g_exception;
        END IF;
    
        IF l_ref_row.id_workflow IS NULL
        THEN
            g_error  := 'Call pk_p1_adm_cs.set_status_internal / ID_REFERRAL=' || i_id_ref || ' STATUS=' ||
                        pk_ref_constant.g_p1_status_i;
            g_retval := pk_p1_adm_cs.set_status_internal(i_lang        => i_lang,
                                                         i_prof        => g_prof_int,
                                                         i_id_p1       => i_id_ref,
                                                         i_status      => pk_ref_constant.g_p1_status_i,
                                                         i_reason_code => NULL,
                                                         i_notes       => NULL,
                                                         i_date        => g_sysdate_tstz,
                                                         o_track       => o_track,
                                                         o_error       => o_error);
        
        ELSE
        
            g_error  := 'Call pk_ref_core.set_status / ID_REFERRAL=' || i_id_ref || ' ACTION=' ||
                        pk_ref_constant.g_ref_action_i;
            g_retval := pk_ref_core.set_status2(i_lang         => i_lang,
                                                i_prof         => g_prof_int,
                                                i_ext_req      => i_id_ref,
                                                i_status_begin => NULL, -- deprecated
                                                i_status_end   => NULL, -- deprecated
                                                i_action       => pk_ref_constant.g_ref_action_i, -- ISSUE
                                                i_level        => NULL,
                                                i_prof_dest    => NULL,
                                                i_dcs          => NULL,
                                                i_notes        => NULL,
                                                i_dt_modified  => NULL,
                                                i_mode         => NULL,
                                                i_reason_code  => NULL,
                                                i_subtype      => NULL,
                                                i_inst_dest    => NULL,
                                                i_date         => g_sysdate_tstz,
                                                o_track        => o_track,
                                                o_flg_show     => l_flg_show,
                                                o_msg_title    => l_msg_title,
                                                o_msg          => l_msg,
                                                o_error        => o_error);
        END IF;
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- resets the referral context
        pk_ref_utils.reset_ref_context;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            IF g_error_code IS NOT NULL
            THEN
                g_flg_action := pk_ref_constant.g_err_flg_action_u; -- user defined error
            ELSE
                g_error_code := SQLCODE;
                g_error_desc := SQLERRM;
                g_flg_action := pk_ref_constant.g_err_flg_action_s; -- system error
            END IF;
            pk_alert_exceptions.process_error(i_lang        => i_lang,
                                              i_sqlcode     => g_error_code,
                                              i_sqlerrm     => g_error_desc,
                                              i_message     => g_error,
                                              i_owner       => g_package_owner,
                                              i_package     => g_package_name,
                                              i_function    => 'RESEND_REFERRAL',
                                              i_action_type => g_flg_action,
                                              i_action_msg  => NULL,
                                              o_error       => o_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END resend_referral;

    /**
    * Clinical director approves the referral
    *
    * @param   i_lang               Language associated to the professional executing the request
    * @param   i_prof               Professional, institution and software ids
    * @param   i_id_ref             Referral identifier
    * @param   i_num_order          Professional num order that is approving the referral
    * @param   i_prof_name          Professional name that is approving the referral
    * @param   i_notes              Approval notes
    * @param   i_date               Operation date
    * @param   o_track              Tracking identifiers created due to the status change
    * @param   o_error              An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.6.0.5
    * @since   22-02-2011
    */
    FUNCTION set_ref_approved
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_ref    IN p1_external_request.id_external_request%TYPE,
        i_num_order IN professional.num_order%TYPE,
        i_prof_name IN professional.name%TYPE,
        i_notes     IN p1_detail.text%TYPE,
        i_date      IN DATE,
        o_track     OUT table_number,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_flg_valid           VARCHAR2(1 CHAR);
        l_prof                profissional;
        l_ref_row             p1_external_request%ROWTYPE;
        l_flg_show            VARCHAR2(1 CHAR);
        l_msg_title           VARCHAR2(1000 CHAR);
        l_msg                 VARCHAR2(1000 CHAR);
        l_id_profile_template profile_template.id_profile_template%TYPE;
    BEGIN
        ----------------------
        -- INIT
        ----------------------        
        g_error := '->Init set_ref_approved / ID_REF=' || i_id_ref;
        pk_alertlog.log_debug(g_error);
        reset_vars;
        g_prof_int := pk_p1_interface.set_prof_interface(i_prof);
        o_track    := table_number();
    
        -- sets the referral context
        pk_ref_utils.init_ref_context;
        pk_ref_utils.set_ref_context(i_id_external_request => i_id_ref, i_dt_system_date => current_timestamp);
    
        -- getting operation date
        g_error  := 'Call pk_ref_utils.get_operation_date / i_dt_d=' || i_date;
        g_retval := pk_ref_utils.get_operation_date(i_lang    => i_lang,
                                                    i_prof    => g_prof_int,
                                                    i_dt_d    => i_date,
                                                    o_dt_tstz => g_sysdate_tstz,
                                                    o_error   => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        ----------------------
        -- VAL
        ----------------------
        -- mandatory parameters
        g_error := 'Validating mandatory parameters';
        IF i_num_order IS NULL
        THEN
            g_error := 'Invalid parameter / ID_REFERRAL=' || i_id_ref || ' NUM_ORDER=' || i_num_order || ' PROF_NAME=' ||
                       i_prof_name;
        
            g_error_code := pk_ref_constant.g_ref_error_1005;
            g_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => g_error_code);
            RAISE g_exception;
        END IF;
    
        g_error  := 'Call get_profile_template_inst / ID_INST=' || g_prof_int.institution;
        g_retval := get_profile_template_inst(i_lang             => i_lang,
                                              i_prof             => i_prof,
                                              i_id_institution   => g_prof_int.institution,
                                              i_id_category      => pk_ref_constant.g_cat_id_med,
                                              o_profile_template => l_id_profile_template,
                                              o_error            => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- validating parameters
        g_error  := 'Call check_requirements';
        g_retval := check_requirements(i_lang          => i_lang,
                                       i_prof          => g_prof_int,
                                       i_id_ref        => i_id_ref,
                                       i_num_order     => i_num_order,
                                       i_prof_name     => i_prof_name,
                                       i_profile_templ => l_id_profile_template,
                                       i_func          => pk_ref_constant.g_ref_func_cd, -- clinical director
                                       i_date          => g_sysdate_tstz,
                                       o_flg_valid     => l_flg_valid,
                                       o_prof          => l_prof, -- clinical director that is approving the referral
                                       o_error         => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        IF l_flg_valid = pk_ref_constant.g_no
        THEN
            g_error := 'INVALID PARAMETERS';
            RAISE g_exception;
        END IF;
    
        -- get referral data
        g_error  := 'Call pk_p1_external_request.get_ref_row / ID_REF=' || i_id_ref;
        g_retval := pk_p1_external_request.get_ref_row(i_lang   => i_lang,
                                                       i_prof   => g_prof_int,
                                                       i_id_ref => i_id_ref,
                                                       o_rec    => l_ref_row,
                                                       o_error  => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- validating orig institution
        IF i_prof.institution != l_ref_row.id_inst_orig
        THEN
            g_error      := 'Professional institution (' || i_prof.institution ||
                            ') must be the same as orig institution (' || l_ref_row.id_inst_orig || ')';
            g_error_code := pk_ref_constant.g_ref_error_1009;
            g_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => g_error_code);
            RAISE g_exception;
        END IF;
    
        IF l_ref_row.id_inst_orig IS NULL
        THEN
            g_error      := 'Origin institution is null / ID_REF=' || i_id_ref;
            g_error_code := pk_ref_constant.g_ref_error_1007;
            g_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => g_error_code);
            RAISE g_exception;
        END IF;
    
        -- check if professional l_prof_req is clinical director
        g_error  := 'Call check_clinical_director';
        g_retval := check_clinical_director(i_lang           => i_lang,
                                            i_prof           => l_prof,
                                            i_id_institution => l_ref_row.id_inst_orig, -- referral orig institution
                                            o_error          => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        ----------------------
        -- FUNC
        ----------------------
        g_error  := 'Call pk_ref_core.set_status / ID_REFERRAL=' || i_id_ref || ' ACTION=' ||
                    pk_ref_constant.g_ref_action_v;
        g_retval := pk_ref_core.set_status2(i_lang         => i_lang,
                                            i_prof         => l_prof,
                                            i_ext_req      => i_id_ref,
                                            i_status_begin => NULL, -- deprecated
                                            i_status_end   => NULL, -- deprecated
                                            i_action       => pk_ref_constant.g_ref_action_v, -- APPROVED
                                            i_level        => NULL,
                                            i_prof_dest    => NULL,
                                            i_dcs          => NULL,
                                            i_notes        => i_notes,
                                            i_dt_modified  => NULL,
                                            i_mode         => NULL,
                                            i_reason_code  => NULL,
                                            i_subtype      => NULL,
                                            i_inst_dest    => NULL,
                                            i_date         => g_sysdate_tstz,
                                            o_track        => o_track,
                                            o_flg_show     => l_flg_show,
                                            o_msg_title    => l_msg_title,
                                            o_msg          => l_msg,
                                            o_error        => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- resets the referral context
        pk_ref_utils.reset_ref_context;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            IF g_error_code IS NOT NULL
            THEN
                g_flg_action := pk_ref_constant.g_err_flg_action_u; -- user defined error
            ELSE
                g_error_code := SQLCODE;
                g_error_desc := SQLERRM;
                g_flg_action := pk_ref_constant.g_err_flg_action_s; -- system error
            END IF;
            pk_alert_exceptions.process_error(i_lang        => i_lang,
                                              i_sqlcode     => g_error_code,
                                              i_sqlerrm     => g_error_desc,
                                              i_message     => g_error,
                                              i_owner       => g_package_owner,
                                              i_package     => g_package_name,
                                              i_function    => 'SET_REF_APPROVED',
                                              i_action_type => g_flg_action,
                                              i_action_msg  => NULL,
                                              o_error       => o_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END set_ref_approved;

    /**
    * Clinical director does not approves the referral
    *
    * @param   i_lang               Language associated to the professional executing the request
    * @param   i_prof               Professional, institution and software ids
    * @param   i_id_ref             Referral identifier
    * @param   i_num_order          Professional num order that is performing this operation
    * @param   i_prof_name          Professional name that is performing this operation
    * @param   i_notes              Rejection notes
    * @param   i_date               Operation date
    * @param   o_track              Tracking identifiers created due to the status change
    * @param   o_error              An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.6.0.5
    * @since   22-02-2011
    */
    FUNCTION set_ref_not_approved
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_ref    IN p1_external_request.id_external_request%TYPE,
        i_num_order IN professional.num_order%TYPE,
        i_prof_name IN professional.name%TYPE,
        i_notes     IN p1_detail.text%TYPE,
        i_date      IN DATE,
        o_track     OUT table_number,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_flg_valid           VARCHAR2(1 CHAR);
        l_prof                profissional;
        l_ref_row             p1_external_request%ROWTYPE;
        l_flg_show            VARCHAR2(1 CHAR);
        l_msg_title           VARCHAR2(1000 CHAR);
        l_msg                 VARCHAR2(1000 CHAR);
        l_id_profile_template profile_template.id_profile_template%TYPE;
    BEGIN
        ----------------------
        -- INIT
        ----------------------        
        g_error := '->Init set_ref_not_approved / ID_REF=' || i_id_ref;
        pk_alertlog.log_debug(g_error);
        reset_vars;
        g_prof_int := pk_p1_interface.set_prof_interface(i_prof);
        o_track    := table_number();
    
        -- sets the referral context
        pk_ref_utils.init_ref_context;
        pk_ref_utils.set_ref_context(i_id_external_request => i_id_ref, i_dt_system_date => current_timestamp);
    
        -- getting operation date
        g_error  := 'Call pk_ref_utils.get_operation_date / i_dt_d=' || i_date;
        g_retval := pk_ref_utils.get_operation_date(i_lang    => i_lang,
                                                    i_prof    => g_prof_int,
                                                    i_dt_d    => i_date,
                                                    o_dt_tstz => g_sysdate_tstz,
                                                    o_error   => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        ----------------------
        -- VAL
        ----------------------
        -- mandatory parameters
        g_error := 'Validating mandatory parameters';
        IF i_num_order IS NULL
        THEN
            g_error := 'Invalid parameter / ID_REFERRAL=' || i_id_ref || ' NUM_ORDER=' || i_num_order || ' PROF_NAME=' ||
                       i_prof_name;
        
            g_error_code := pk_ref_constant.g_ref_error_1005;
            g_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => g_error_code);
            RAISE g_exception;
        END IF;
    
        g_error  := 'Call get_profile_template_inst / ID_INST=' || g_prof_int.institution;
        g_retval := get_profile_template_inst(i_lang             => i_lang,
                                              i_prof             => i_prof,
                                              i_id_institution   => g_prof_int.institution,
                                              i_id_category      => pk_ref_constant.g_cat_id_med,
                                              o_profile_template => l_id_profile_template,
                                              o_error            => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- validating parameters
        g_error  := 'Call check_requirements';
        g_retval := check_requirements(i_lang          => i_lang,
                                       i_prof          => g_prof_int,
                                       i_id_ref        => i_id_ref,
                                       i_num_order     => i_num_order,
                                       i_prof_name     => i_prof_name,
                                       i_profile_templ => l_id_profile_template,
                                       i_func          => pk_ref_constant.g_ref_func_cd, -- clinical director
                                       i_date          => g_sysdate_tstz,
                                       o_flg_valid     => l_flg_valid,
                                       o_prof          => l_prof, -- clinical director that is rejecting the referral
                                       o_error         => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        IF l_flg_valid = pk_ref_constant.g_no
        THEN
            g_error := 'INVALID PARAMETERS';
            RAISE g_exception;
        END IF;
    
        -- get referral data
        g_error  := 'Call pk_p1_external_request.get_ref_row / ID_REF=' || i_id_ref;
        g_retval := pk_p1_external_request.get_ref_row(i_lang   => i_lang,
                                                       i_prof   => g_prof_int,
                                                       i_id_ref => i_id_ref,
                                                       o_rec    => l_ref_row,
                                                       o_error  => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- validating orig institution
        IF i_prof.institution != l_ref_row.id_inst_orig
        THEN
            g_error      := 'Professional institution (' || i_prof.institution ||
                            ') must be the same as orig institution (' || l_ref_row.id_inst_orig || ')';
            g_error_code := pk_ref_constant.g_ref_error_1009;
            g_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => g_error_code);
            RAISE g_exception;
        END IF;
    
        -- check if professional l_prof_req is clinical director
        IF l_ref_row.id_inst_orig IS NULL
        THEN
            g_error      := 'Origin institution is null / ID_REF=' || i_id_ref;
            g_error_code := pk_ref_constant.g_ref_error_1007;
            g_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => g_error_code);
            RAISE g_exception;
        END IF;
    
        -- check if professional l_prof_req is clinical director
        g_error  := 'Call check_clinical_director / ID_REF=' || i_id_ref;
        g_retval := check_clinical_director(i_lang           => i_lang,
                                            i_prof           => l_prof,
                                            i_id_institution => l_ref_row.id_inst_orig, -- referral orig institution
                                            o_error          => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        ----------------------
        -- FUNC
        ----------------------
        g_error  := 'Call pk_ref_core.set_status / PROF=' || pk_utils.to_string(l_prof) || ' ID_REFERRAL=' || i_id_ref ||
                    ' ACTION=' || pk_ref_constant.g_ref_action_v;
        g_retval := pk_ref_core.set_status2(i_lang         => i_lang,
                                            i_prof         => l_prof,
                                            i_ext_req      => i_id_ref,
                                            i_status_begin => NULL, -- deprecated
                                            i_status_end   => NULL, -- deprecated
                                            i_action       => pk_ref_constant.g_ref_action_h, -- NOT_APPROVED
                                            i_level        => NULL,
                                            i_prof_dest    => NULL,
                                            i_dcs          => NULL,
                                            i_notes        => i_notes,
                                            i_dt_modified  => NULL,
                                            i_mode         => NULL,
                                            i_reason_code  => NULL,
                                            i_subtype      => NULL,
                                            i_inst_dest    => NULL,
                                            i_date         => g_sysdate_tstz,
                                            o_track        => o_track,
                                            o_flg_show     => l_flg_show,
                                            o_msg_title    => l_msg_title,
                                            o_msg          => l_msg,
                                            o_error        => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- resets the referral context
        pk_ref_utils.reset_ref_context;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            IF g_error_code IS NOT NULL
            THEN
                g_flg_action := pk_ref_constant.g_err_flg_action_u; -- user defined error
            ELSE
                g_error_code := SQLCODE;
                g_error_desc := SQLERRM;
                g_flg_action := pk_ref_constant.g_err_flg_action_s; -- system error
            END IF;
            pk_alert_exceptions.process_error(i_lang        => i_lang,
                                              i_sqlcode     => g_error_code,
                                              i_sqlerrm     => g_error_desc,
                                              i_message     => g_error,
                                              i_owner       => g_package_owner,
                                              i_package     => g_package_name,
                                              i_function    => 'SET_REF_NOT_APPROVED',
                                              i_action_type => g_flg_action,
                                              i_action_msg  => NULL,
                                              o_error       => o_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END set_ref_not_approved;

    /** 
    * @param   i_lang               Language associated to the professional executing the request
    * @param   i_prof               Professional, institution and software ids
    * @param   i_id_ref             Referral identifier
    * @param   i_num_order          Professional num order that is performing this operation
    * @param   i_prof_name          Professional name that is performing this operation
    * @param   i_date               Operation date
    * @param   o_error              An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 2.6.1.3
    * @since   28-Sep-2011
    */
    FUNCTION set_ref_cancel_noshow
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_ref    IN p1_external_request.id_external_request%TYPE,
        i_num_order IN professional.num_order%TYPE,
        i_prof_name IN professional.name%TYPE,
        i_date      IN DATE,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_prof      profissional;
        l_flg_valid VARCHAR2(1 CHAR);
        l_prof_data t_rec_prof_data;
        l_ref_row   p1_external_request%ROWTYPE;
    BEGIN
        ----------------------
        -- INIT
        ----------------------
        -- referral status is changed from (T)riage to (R)e-sent
        g_error := '->Init set_ref_unblocked / ID_REF=' || i_id_ref || ' DATE=' || i_date;
        pk_alertlog.log_debug(g_error);
        reset_vars;
        g_prof_int := pk_p1_interface.set_prof_interface(i_prof);
        -- sets the referral context
        pk_ref_utils.init_ref_context;
        pk_ref_utils.set_ref_context(i_id_external_request => i_id_ref, i_dt_system_date => current_timestamp);
    
        -- getting operation date
        g_error  := 'Call pk_ref_utils.get_operation_date / i_dt_d=' || i_date;
        g_retval := pk_ref_utils.get_operation_date(i_lang    => i_lang,
                                                    i_prof    => i_prof,
                                                    i_dt_d    => i_date,
                                                    o_dt_tstz => g_sysdate_tstz,
                                                    o_error   => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        ----------------------
        -- VAL
        ----------------------
        -- validating parameters
        g_error  := 'Call check_requirements';
        g_retval := check_requirements(i_lang      => i_lang,
                                       i_prof      => g_prof_int,
                                       i_id_ref    => i_id_ref,
                                       i_date      => g_sysdate_tstz,
                                       o_flg_valid => l_flg_valid,
                                       o_prof      => l_prof, -- professional that has forwarded the referral
                                       o_error     => o_error);
    
        IF NOT g_retval
        THEN
            g_error := 'ERROR: ' || g_error;
            RAISE g_exception_np;
        END IF;
    
        IF l_flg_valid = pk_ref_constant.g_no
        THEN
            g_error := 'INVALID PARAMETERS';
            RAISE g_exception;
        END IF;
    
        ----------------------
        -- FUNC
        ----------------------     
        -- getting professional data
        g_error  := 'Calling get_prof_data';
        g_retval := pk_ref_core.get_prof_data(i_lang      => i_lang,
                                              i_prof      => g_prof_int,
                                              i_dcs       => NULL,
                                              o_prof_data => l_prof_data,
                                              o_error     => o_error);
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- get referral data
        g_error  := 'Call pk_p1_external_request.get_ref_row / ID_REF=' || i_id_ref;
        g_retval := pk_p1_external_request.get_ref_row(i_lang   => i_lang,
                                                       i_prof   => g_prof_int,
                                                       i_id_ref => i_id_ref,
                                                       o_rec    => l_ref_row,
                                                       o_error  => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- validating dest institution
        IF i_prof.institution != l_ref_row.id_inst_dest
        THEN
            g_error      := 'Professional institution (' || i_prof.institution ||
                            ') must be the same as dest institution (' || l_ref_row.id_inst_dest || ')';
            g_error_code := pk_ref_constant.g_ref_error_1009;
            g_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => g_error_code);
            RAISE g_exception;
        END IF;
    
        g_error := 'PK_API_REF_WS.SET_REF_CANCEL_NOSHOW / flg_status <> F / flg_status=' || l_ref_row.flg_status;
        IF l_ref_row.flg_status <> pk_ref_constant.g_p1_status_f
        THEN
            RAISE g_exception_np;
        END IF;
    
        g_error  := 'Call pk_ref_ext_sys.set_ref_cancel_noshow / ID_REF=' || i_id_ref;
        g_retval := pk_ref_ext_sys.set_ref_cancel_noshow(i_lang   => i_lang,
                                                         i_prof   => i_prof,
                                                         i_id_ref => i_id_ref,
                                                         i_date   => i_date,
                                                         o_error  => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- resets the referral context
        pk_ref_utils.reset_ref_context;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            IF g_error_code IS NOT NULL
            THEN
                g_flg_action := pk_ref_constant.g_err_flg_action_u; -- user defined error
            ELSE
                g_error_code := SQLCODE;
                g_error_desc := SQLERRM;
                g_flg_action := pk_ref_constant.g_err_flg_action_s; -- system error
            END IF;
            pk_alert_exceptions.process_error(i_lang        => i_lang,
                                              i_sqlcode     => g_error_code,
                                              i_sqlerrm     => g_error_desc,
                                              i_message     => g_error,
                                              i_owner       => g_package_owner,
                                              i_package     => g_package_name,
                                              i_function    => 'SET_REF_CANCEL_NOSHOW',
                                              i_action_type => g_flg_action,
                                              i_action_msg  => NULL,
                                              o_error       => o_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END set_ref_cancel_noshow;

    /**
    * Origin registrar attachs informed consent.    
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Id professional, institution and software from the Interface
    * @param   i_id_ref         Referral identifier  
    * @param   i_notes          Registrar notes
    * @param   i_date           Operation date
    * @param   o_track          Tracking identifiers created due to the status change
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.6.0.5
    * @since   23-02-2011
    */
    FUNCTION attach_informed_consent
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_id_ref IN p1_external_request.id_external_request%TYPE,
        i_notes  IN p1_detail.text%TYPE,
        i_date   IN DATE,
        o_track  OUT table_number,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
        l_flg_valid VARCHAR2(1 CHAR);
        l_prof      profissional;
        l_ref_row   p1_external_request%ROWTYPE;
    
        l_task_inf_consent p1_task.id_task%TYPE;
        l_id_task_done     p1_task_done.id_task_done%TYPE;
        l_flg_task_done    p1_task_done.flg_task_done%TYPE;
    
        CURSOR c_p1_task_done(x_id_task IN p1_task_done.id_task%TYPE) IS
            SELECT id_task_done, flg_task_done
              FROM p1_task_done t
             WHERE t.id_external_request = i_id_ref
               AND t.id_task = x_id_task
               AND t.flg_status = pk_ref_constant.g_active;
    BEGIN
        ----------------------
        -- INIT
        ----------------------
        g_error := '->Init attach_informed_consent / ID_REF=' || i_id_ref;
        pk_alertlog.log_debug(g_error);
        reset_vars;
        g_prof_int := pk_p1_interface.set_prof_interface(i_prof);
    
        -- sets the referral context
        pk_ref_utils.init_ref_context;
        pk_ref_utils.set_ref_context(i_id_external_request => i_id_ref, i_dt_system_date => current_timestamp);
    
        ----------------------
        -- VAL
        ----------------------    
        -- getting operation date
        g_error  := 'Call pk_ref_utils.get_operation_date / i_dt_d=' || i_date;
        g_retval := pk_ref_utils.get_operation_date(i_lang    => i_lang,
                                                    i_prof    => i_prof,
                                                    i_dt_d    => i_date,
                                                    o_dt_tstz => g_sysdate_tstz,
                                                    o_error   => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- validating parameters
        g_error  := 'Call check_requirements';
        g_retval := check_requirements(i_lang      => i_lang,
                                       i_prof      => g_prof_int,
                                       i_id_ref    => i_id_ref,
                                       i_date      => g_sysdate_tstz,
                                       o_flg_valid => l_flg_valid,
                                       o_prof      => l_prof, -- ignored
                                       o_error     => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        IF l_flg_valid = pk_ref_constant.g_no
        THEN
            g_error := 'INVALID PARAMETERS';
            RAISE g_exception;
        END IF;
    
        ----------------------
        -- CONFIG
        ----------------------  
        g_error            := 'Call pk_sysconfig.get_config / ID_SYS_CONFIG=' || pk_ref_constant.g_ref_task_inf_consent;
        l_task_inf_consent := to_number(pk_sysconfig.get_config(pk_ref_constant.g_ref_task_inf_consent, i_prof));
    
        ----------------------
        -- FUNC
        ----------------------
    
        -- get referral data
        g_error  := 'Call pk_p1_external_request.get_ref_row / ID_REF=' || i_id_ref;
        g_retval := pk_p1_external_request.get_ref_row(i_lang   => i_lang,
                                                       i_prof   => g_prof_int,
                                                       i_id_ref => i_id_ref,
                                                       o_rec    => l_ref_row,
                                                       o_error  => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- validating orig institution
        IF i_prof.institution != l_ref_row.id_inst_orig
        THEN
            g_error      := 'Professional institution (' || i_prof.institution ||
                            ') must be the same as orig institution (' || l_ref_row.id_inst_orig || ')';
            g_error_code := pk_ref_constant.g_ref_error_1009;
            g_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => g_error_code);
            RAISE g_exception;
        END IF;
    
        -- getting id_task_done of informed consent
        g_error := 'OPEN c_p1_task_done(' || l_task_inf_consent || ')';
        OPEN c_p1_task_done(l_task_inf_consent);
        FETCH c_p1_task_done
            INTO l_id_task_done, l_flg_task_done;
        CLOSE c_p1_task_done;
    
        g_error := 'l_id_task_done=' || l_id_task_done;
        IF l_id_task_done IS NULL
        THEN
            g_error      := 'No task to be done found / ID_TASK=' || l_task_inf_consent;
            g_error_code := pk_ref_constant.g_ref_error_1007;
            g_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => g_error_code);
            RAISE g_exception;
        END IF;
    
        g_error  := 'Call pk_ref_orig_reg.update_tasks_done / ID_REFERRAL=' || i_id_ref || ' ID_TASK_DONE=' ||
                    l_id_task_done || ' FLG_TASK_DONE=' || l_flg_task_done;
        g_retval := pk_ref_orig_reg.update_tasks_done(i_lang           => i_lang,
                                                      i_prof           => g_prof_int,
                                                      i_ext_req        => i_id_ref,
                                                      i_id_tasks       => table_number(l_id_task_done),
                                                      i_flg_status_ini => table_varchar(l_flg_task_done),
                                                      i_flg_status_fin => table_varchar(pk_ref_constant.g_yes), -- task completed
                                                      i_notes          => i_notes,
                                                      i_date           => g_sysdate_tstz,
                                                      o_track          => o_track,
                                                      o_error          => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- resets the referral context
        pk_ref_utils.reset_ref_context;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            IF g_error_code IS NOT NULL
            THEN
                g_flg_action := pk_ref_constant.g_err_flg_action_u; -- user defined error
            ELSE
                g_error_code := SQLCODE;
                g_error_desc := SQLERRM;
                g_flg_action := pk_ref_constant.g_err_flg_action_s; -- system error
            END IF;
            pk_alert_exceptions.process_error(i_lang        => i_lang,
                                              i_sqlcode     => g_error_code,
                                              i_sqlerrm     => g_error_desc,
                                              i_message     => g_error,
                                              i_owner       => g_package_owner,
                                              i_package     => g_package_name,
                                              i_function    => 'ATTACH_INFORMED_CONSENT',
                                              i_action_type => g_flg_action,
                                              i_action_msg  => NULL,
                                              o_error       => o_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END attach_informed_consent;

    /**
    * Gets flag availability based on id_workflow, origin institution and dest institution (if available)
    *
    * @param   i_id_workflow    Referral workflow identifier
    * @param   i_id_inst_orig   Referral origin institution identifier
    * @param   i_id_inst_dest   Referral dest institution identifier
    *
    * @RETURN  Flag availability
    * @author  Ana Monteiro
    * @version 1.0
    * @since   17-11-2011
    */
    FUNCTION get_flg_availability
    (
        i_id_workflow  IN p1_external_request.id_workflow%TYPE,
        i_id_inst_orig p1_external_request.id_inst_orig%TYPE DEFAULT NULL,
        i_id_inst_dest p1_external_request.id_inst_dest%TYPE DEFAULT NULL
    ) RETURN p1_spec_dep_clin_serv.flg_availability%TYPE IS
        l_result p1_spec_dep_clin_serv.flg_availability%TYPE;
    BEGIN
        ----------------------
        -- INIT
        ----------------------
        g_error := '->Init get_flg_availability / ID_WF=' || i_id_workflow || ' ID_INST_ORIG=' || i_id_inst_orig ||
                   ' ID_INST_DEST=' || i_id_inst_dest;
    
        ----------------------
        -- FUNC
        ----------------------
        CASE
            WHEN nvl(i_id_workflow, pk_ref_constant.g_wf_pcc_hosp) = pk_ref_constant.g_wf_pcc_hosp THEN
                -- 1
                l_result := pk_ref_constant.g_flg_availability_e;
            WHEN i_id_workflow = pk_ref_constant.g_wf_hosp_hosp THEN
                -- 2
                l_result := pk_ref_constant.g_flg_availability_e;
            WHEN i_id_workflow = pk_ref_constant.g_wf_srv_srv THEN
                -- 3
                l_result := pk_ref_constant.g_flg_availability_i;
            WHEN i_id_workflow = pk_ref_constant.g_wf_x_hosp THEN
                -- 4
                l_result := pk_ref_constant.g_flg_availability_p;
            WHEN i_id_workflow = pk_ref_constant.g_wf_fertis THEN
                -- 8
                IF i_id_inst_orig = i_id_inst_dest
                THEN
                    l_result := pk_ref_constant.g_flg_availability_i; -- FERTIS internal workflow
                ELSE
                    l_result := pk_ref_constant.g_flg_availability_e;
                END IF;
            ELSE
                g_error := 'Error: CASE NOT FOUND / ' || g_error;
                RAISE g_exception;
        END CASE;
    
        RETURN l_result;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(g_error);
            RETURN NULL;
    END get_flg_availability;
    /**
    * Returns referral specialities
    *
    * @param   i_lang              Language associated to the professional executing the request
    * @param   i_prof              Id professional, institution and software from the Interface
    * @param   i_id_external_sys   External system identifier
    * @param   i_id_workflow       Referral workflow
    * @param   i_id_inst_orig      Origin institution identifier
    * @param   i_pat_gender        Patient gender
    * @param   i_pat_age           Patient age
    * @param   o_ref_data          Referral specialities or dep_clin_servs data (depends on id_workflow): ID + DESC
    * @param   o_error             An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   18-11-2011
    */
    FUNCTION get_referral_specialities
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_external_sys IN p1_external_request.id_external_sys%TYPE,
        i_id_workflow     IN p1_external_request.id_workflow%TYPE,
        i_id_inst_orig    IN p1_external_request.id_inst_orig%TYPE,
        i_pat_gender      IN patient.gender%TYPE,
        i_pat_age         IN patient.age%TYPE,
        o_ref_data        OUT NOCOPY t_coll_ref_speciality,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_ref_spec_tab pk_ref_list.t_coll_ref_spec;
        l_ref_spec_cur pk_ref_list.t_cur_ref_spec;
    
        l_flg_availability p1_spec_dep_clin_serv.flg_availability%TYPE;
        l_params           VARCHAR2(1000 CHAR);
    BEGIN
        ----------------------
        -- INIT
        ----------------------
        l_params := 'i_id_external_sys=' || i_id_external_sys || ' i_id_workflow=' || i_id_workflow ||
                    ' i_id_inst_orig=' || i_id_inst_orig || ' i_pat_gender=' || i_pat_gender || ' i_pat_age=' ||
                    i_pat_age;
        g_error  := 'Init get_referral_specialities / ' || l_params;
        pk_alertlog.log_debug(g_error);
        o_ref_data := t_coll_ref_speciality();
    
        ----------------------
        -- VAL
        ----------------------
        -- does not need referral context    
        IF nvl(i_id_workflow, pk_ref_constant.g_wf_pcc_hosp) NOT IN
           (pk_ref_constant.g_wf_x_hosp, pk_ref_constant.g_wf_pcc_hosp, pk_ref_constant.g_wf_hosp_hosp)
        THEN
            g_error      := 'Invalid workflow / ' || l_params;
            g_error_code := pk_ref_constant.g_ref_error_1005;
            g_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => g_error_code);
            RAISE g_exception;
        END IF;
    
        IF nvl(i_id_workflow, pk_ref_constant.g_wf_pcc_hosp) != pk_ref_constant.g_wf_x_hosp
        THEN
            -- professional must be at orig institution
            IF i_prof.institution != i_id_inst_orig
               OR i_id_inst_orig IS NULL
            THEN
                g_error      := 'Professional institution (' || i_prof.institution ||
                                ') must be the same as orig institution (' || i_id_inst_orig || ')';
                g_error_code := pk_ref_constant.g_ref_error_1009;
                g_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => g_error_code);
                RAISE g_exception;
            END IF;
        END IF;
    
        ----------------------
        -- FUNC
        ----------------------    
        g_error            := 'Call get_flg_availability / ' || l_params;
        l_flg_availability := get_flg_availability(i_id_workflow => i_id_workflow);
    
        g_error  := 'Call pk_ref_list.get_net_spec / ' || l_params;
        g_retval := pk_ref_list.get_net_spec(i_lang         => i_lang,
                                             i_prof         => i_prof,
                                             i_pat_gender   => i_pat_gender,
                                             i_pat_age      => i_pat_age,
                                             i_ref_type     => l_flg_availability,
                                             i_external_sys => i_id_external_sys,
                                             o_sql          => l_ref_spec_cur,
                                             o_error        => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        g_error := 'FETCH l_ref_spec_cur BULK COLLECT into / ' || l_params;
        FETCH l_ref_spec_cur BULK COLLECT
            INTO l_ref_spec_tab;
        CLOSE l_ref_spec_cur;
    
        g_error := 'o_ref_data.extend(' || l_ref_spec_tab.count || ') / ' || l_params;
        o_ref_data.extend(l_ref_spec_tab.count);
    
        g_error := 'FOR i IN 1 .. ' || l_ref_spec_tab.count || ' / ' || l_params;
        FOR i IN 1 .. l_ref_spec_tab.count
        LOOP
            o_ref_data(i) := t_rec_ref_speciality();
            o_ref_data(i).id_dep_clin_serv := l_ref_spec_tab(i).id_speciality;
            o_ref_data(i).description := l_ref_spec_tab(i).desc_cls_srv;
        END LOOP;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            IF g_error_code IS NOT NULL
            THEN
                g_flg_action := pk_ref_constant.g_err_flg_action_u;
            ELSE
                g_error_code := SQLCODE;
                g_error_desc := SQLERRM;
                g_flg_action := pk_ref_constant.g_err_flg_action_s;
            END IF;
            pk_alert_exceptions.process_error(i_lang        => i_lang,
                                              i_sqlcode     => g_error_code,
                                              i_sqlerrm     => g_error_desc,
                                              i_message     => g_error,
                                              i_owner       => g_package_owner,
                                              i_package     => g_package_name,
                                              i_function    => 'GET_REFERRAL_SPECIALITIES',
                                              i_action_type => g_flg_action,
                                              i_action_msg  => NULL,
                                              o_error       => o_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END get_referral_specialities;

    /**
    * Returns referral dep_clin_servs (for internal workflows)
    *
    * @param   i_lang              Language associated to the professional executing the request
    * @param   i_prof              Id professional, institution and software from the Interface
    * @param   i_id_external_sys   External system identifier
    * @param   i_id_inst_orig      Origin institution identifier
    * @param   i_num_order         Professional num order
    * @param   i_pat_gender        Patient gender
    * @param   i_pat_age           Patient age
    * @param   o_ref_data          Referral dep_clin_servs data : ID + DESC
    * @param   o_error             An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   18-11-2011
    */
    FUNCTION get_referral_int_dcs
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_external_sys IN p1_external_request.id_external_sys%TYPE,
        i_id_inst_orig    IN p1_external_request.id_inst_orig%TYPE,
        i_num_order       IN professional.num_order%TYPE,
        i_pat_gender      IN patient.gender%TYPE,
        i_pat_age         IN patient.age%TYPE,
        o_ref_data        OUT NOCOPY t_coll_ref_dcs,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_prof      profissional;
        l_params    VARCHAR2(1000 CHAR);
        l_prf_templ profile_template.id_profile_template%TYPE;
    
        l_ref_dcs_tab pk_ref_list.t_coll_ref_dcs;
        l_ref_dcs_cur pk_ref_list.t_cur_ref_dcs;
    BEGIN
        ----------------------
        -- INIT
        ----------------------
        l_params := 'i_id_external_sys=' || i_id_external_sys || ' i_id_inst_orig=' || i_id_inst_orig ||
                    ' i_pat_gender=' || i_pat_gender || ' i_pat_age=' || i_pat_age;
        g_error  := 'Init get_referral_int_dcs / ' || l_params;
        pk_alertlog.log_debug(g_error);
        o_ref_data := t_coll_ref_dcs();
        l_prof     := i_prof;
    
        -- do not set the referral context: this function is called internally in this package
    
        IF l_prof.institution != i_id_inst_orig
        THEN
            g_error      := 'Professional institution (' || l_prof.institution ||
                            ') must be the same as orig institution (' || i_id_inst_orig || ') / ' || l_params;
            g_error_code := pk_ref_constant.g_ref_error_1009;
            g_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => g_error_code);
            RAISE g_exception;
        END IF;
    
        ----------------------
        -- FUNC
        ----------------------
        -- getting id_professional
        g_error  := 'Call get_prof_id / ' || l_params;
        g_retval := get_prof_id(i_lang         => i_lang,
                                i_prof         => i_prof, -- indicates the institution where num_order must be configured
                                i_num_order    => i_num_order,
                                o_id_prof      => l_prof.id,
                                o_id_prf_templ => l_prf_templ,
                                o_error        => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- getting id_dep_clin_serv for referring
        g_error  := 'Call pk_ref_list.get_internal_spec / ' || l_params;
        g_retval := pk_ref_list.get_internal_spec(i_lang         => i_lang,
                                                  i_prof         => l_prof,
                                                  i_dep          => NULL, -- all departments
                                                  i_pat_age      => i_pat_age,
                                                  i_pat_gender   => i_pat_gender,
                                                  i_external_sys => i_id_external_sys,
                                                  o_cs           => l_ref_dcs_cur,
                                                  o_error        => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        g_error := 'FETCH l_ref_dcs_cur BULK COLLECT INTO l_ref_dcs_tab / ' || l_params;
        FETCH l_ref_dcs_cur BULK COLLECT
            INTO l_ref_dcs_tab;
        CLOSE l_ref_dcs_cur;
    
        IF l_ref_dcs_tab.count > 0
        THEN
        
            o_ref_data.extend(l_ref_dcs_tab.count);
        
            g_error := 'FOR i IN 1 .. ' || l_ref_dcs_tab.count || ' / ' || l_params;
            FOR i IN 1 .. l_ref_dcs_tab.count
            LOOP
                o_ref_data(i) := t_rec_ref_dcs();
                o_ref_data(i).id_dep_clin_serv := l_ref_dcs_tab(i).id_dep_clin_serv;
                o_ref_data(i).desc_clin_serv := l_ref_dcs_tab(i).desc_cls_srv;
            END LOOP;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            IF g_error_code IS NOT NULL
            THEN
                g_flg_action := pk_ref_constant.g_err_flg_action_u;
            ELSE
                g_error_code := SQLCODE;
                g_error_desc := SQLERRM;
                g_flg_action := pk_ref_constant.g_err_flg_action_s;
            END IF;
            pk_alert_exceptions.process_error(i_lang        => i_lang,
                                              i_sqlcode     => g_error_code,
                                              i_sqlerrm     => g_error_desc,
                                              i_message     => g_error,
                                              i_owner       => g_package_owner,
                                              i_package     => g_package_name,
                                              i_function    => 'GET_REFERRAL_INT_DCS',
                                              i_action_type => g_flg_action,
                                              i_action_msg  => NULL,
                                              o_error       => o_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END get_referral_int_dcs;

    /**
    * Returns referral department and clinical services available for referring, of the Hospital complex from which i_id_inst_dest belongs
    *
    * @param   i_lang              Language associated to the professional executing the request
    * @param   i_prof              Id professional, institution and software from the Interface
    * @param   i_id_external_sys   External system identifier
    * @param   i_id_inst_dest      Institution belonging to the Hospital Complex
    * @param   o_ref_data          Referral departments and clinical services
    * @param   o_error             An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   23-05-2013
    */
    FUNCTION get_all_referral_int_dcs
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_external_sys IN p1_external_request.id_external_sys%TYPE,
        i_id_inst_dest    IN p1_external_request.id_inst_dest%TYPE,
        o_ref_data        OUT NOCOPY t_coll_ref_all_dcs,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_params   VARCHAR2(1000 CHAR);
        l_inst_tab table_number;
    
        CURSOR c_internal IS
            SELECT DISTINCT t_rec_ref_all_dcs(t.id_dep_clin_serv, -- distinct because there may be several id_specialities with the same dep_clin_serv
                                              t.id_institution,
                                              pk_translation.get_translation(i_lang, t.code_institution),
                                              t.id_department,
                                              pk_translation.get_translation(i_lang, t.code_department),
                                              t.id_clinical_service,
                                              pk_translation.get_translation(i_lang, t.code_clinical_service))
              FROM (SELECT v.id_dep_clin_serv,
                           v.id_clinical_service,
                           v.code_clinical_service,
                           v.id_department,
                           v.code_department,
                           v.id_institution,
                           v.code_institution
                      FROM v_ref_internal v
                      JOIN TABLE(CAST(l_inst_tab AS table_number)) t -- institutions belonging to the Hospital Complex
                        ON t.column_value = v.id_institution
                     WHERE v.flg_type = pk_ref_constant.g_p1_type_c
                       AND v.id_external_sys IN (nvl(i_id_external_sys, 0), 0)
                       AND v.inst_type = pk_ref_constant.g_hospital -- double checking...
                    ) t;
    
    BEGIN
        ----------------------
        -- INIT
        ----------------------
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_id_external_sys=' || i_id_external_sys ||
                    ' i_id_inst_dest=' || i_id_inst_dest;
    
        g_error := 'Init get_all_referral_int_dcs / ' || l_params;
        pk_alertlog.log_debug(g_error);
    
        ----------------------
        -- FUNC
        ----------------------                
        -- getting dest institutions of the CH
        l_inst_tab := pk_ref_core.get_sibling_inst(i_id_institution => i_id_inst_dest,
                                                   i_flg_slef       => pk_ref_constant.g_yes); -- institution brothers (including it self)
        l_inst_tab := l_inst_tab MULTISET UNION pk_ref_core.get_child_inst(i_id_institution => i_id_inst_dest);
    
        g_error := 'OPEN c_internal / l_inst_tab.count=' || l_inst_tab.count || ' / ' || l_params;
        OPEN c_internal;
        FETCH c_internal BULK COLLECT
            INTO o_ref_data;
        CLOSE c_internal;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            IF g_error_code IS NOT NULL
            THEN
                g_flg_action := pk_ref_constant.g_err_flg_action_u;
            ELSE
                g_error_code := SQLCODE;
                g_error_desc := SQLERRM;
                g_flg_action := pk_ref_constant.g_err_flg_action_s;
            END IF;
            pk_alert_exceptions.process_error(i_lang        => i_lang,
                                              i_sqlcode     => g_error_code,
                                              i_sqlerrm     => g_error_desc,
                                              i_message     => g_error,
                                              i_owner       => g_package_owner,
                                              i_package     => g_package_name,
                                              i_function    => 'GET_ALL_REFERRAL_INT_DCS',
                                              i_action_type => g_flg_action,
                                              i_action_msg  => NULL,
                                              o_error       => o_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END get_all_referral_int_dcs;

    /**
    * Returns referral institutions for the workflow and speciality defined
    * Note: not used for wf=g_wf_x_hosp (professional is already at dest institution)
    *
    * @param   i_lang              Language associated to the professional executing the request
    * @param   i_prof              Id professional, institution and software from the Interface
    * @param   i_id_external_sys   External system identifier
    * @param   i_id_workflow       Referral workflow
    * @param   i_id_inst_orig      Origin institution identifier. When "At hospital entrance" workflow this parameter is ignored.
    * @param   i_id_speciality     Speciality identifier
    * @param   o_ref_data          Referral specialities or dep_clin_servs data (depends on id_workflow): ID + DESC
    * @param   o_error             An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   18-11-2011
    */
    FUNCTION get_referral_network
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_external_sys IN p1_external_request.id_external_sys%TYPE,
        i_id_workflow     IN p1_external_request.id_workflow%TYPE,
        i_id_inst_orig    IN p1_external_request.id_inst_orig%TYPE,
        i_id_speciality   IN p1_external_request.id_speciality%TYPE,
        o_ref_data        OUT NOCOPY t_coll_ref_network,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_ref_inst_tab     pk_ref_list.t_coll_ref_institution;
        l_ref_inst_cur     pk_ref_list.t_cur_ref_institution;
        l_flg_availability p1_spec_dep_clin_serv.flg_availability%TYPE;
        l_params           VARCHAR2(1000 CHAR);
    BEGIN
        ----------------------
        -- INIT
        ----------------------    
        l_params := 'i_id_external_sys=' || i_id_external_sys || ' i_id_workflow=' || i_id_workflow ||
                    ' i_id_inst_orig=' || i_id_inst_orig || ' i_id_speciality=' || i_id_speciality;
        g_error  := 'Init get_referral_network / ' || l_params;
        pk_alertlog.log_debug(g_error);
        o_ref_data := t_coll_ref_network();
    
        -- do not set the referral context: this function is called internally in this package
    
        ----------------------
        -- VAL
        ----------------------        
        IF nvl(i_id_workflow, pk_ref_constant.g_wf_pcc_hosp) NOT IN
           (pk_ref_constant.g_wf_pcc_hosp, pk_ref_constant.g_wf_hosp_hosp)
        THEN
            g_error      := 'Invalid workflow / ' || l_params;
            g_error_code := pk_ref_constant.g_ref_error_1005;
            g_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => g_error_code);
            RAISE g_exception;
        END IF;
    
        -- professional must be at orig institution
        IF i_prof.institution != i_id_inst_orig
           OR i_id_inst_orig IS NULL
        THEN
            g_error      := 'Professional institution (' || i_prof.institution ||
                            ') must be the same as orig institution (' || i_id_inst_orig || ') / ' || l_params;
            g_error_code := pk_ref_constant.g_ref_error_1009;
            g_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => g_error_code);
            RAISE g_exception;
        END IF;
    
        ----------------------
        -- FUNC
        ----------------------    
        g_error            := 'Call get_flg_availability / ' || l_params;
        l_flg_availability := get_flg_availability(i_id_workflow => i_id_workflow);
    
        g_error  := 'Call pk_ref_list.get_net_inst / l_flg_availability=' || l_flg_availability || ' / ' || l_params;
        g_retval := pk_ref_list.get_net_inst(i_lang          => i_lang,
                                             i_prof          => i_prof,
                                             i_ref_type      => l_flg_availability,
                                             i_external_sys  => i_id_external_sys,
                                             i_id_speciality => i_id_speciality,
                                             i_flg_type      => pk_ref_constant.g_p1_type_c,
                                             o_sql           => l_ref_inst_cur,
                                             o_error         => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        g_error := 'FETCH l_ref_inst_cur BULK COLLECT into / ' || l_params;
        FETCH l_ref_inst_cur BULK COLLECT
            INTO l_ref_inst_tab;
        CLOSE l_ref_inst_cur;
    
        g_error := 'o_ref_data.extend(' || l_ref_inst_tab.count || ') / ' || l_params;
        o_ref_data.extend(l_ref_inst_tab.count);
    
        g_error := 'FOR i IN 1 .. ' || l_ref_inst_tab.count || ' / ' || l_params;
        FOR i IN 1 .. l_ref_inst_tab.count
        LOOP
        
            o_ref_data(i) := t_rec_ref_network();
        
            -- dest institution                 
            o_ref_data(i).id_institution := l_ref_inst_tab(i).id_institution;
            o_ref_data(i).description := l_ref_inst_tab(i).desc_institution;
            o_ref_data(i).ext_code := l_ref_inst_tab(i).ext_code;
            o_ref_data(i).institution_type_desc := l_ref_inst_tab(i).type_ins;
            -- referral network
            o_ref_data(i).flg_inside_ref_area := l_ref_inst_tab(i).flg_inside_ref_area;
            o_ref_data(i).flg_ref_line := l_ref_inst_tab(i).flg_ref_line;
            o_ref_data(i).wait_time_dd := l_ref_inst_tab(i).wait_days;
        
        END LOOP;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            IF g_error_code IS NOT NULL
            THEN
                g_flg_action := pk_ref_constant.g_err_flg_action_u;
            ELSE
                g_error_code := SQLCODE;
                g_error_desc := SQLERRM;
                g_flg_action := pk_ref_constant.g_err_flg_action_s;
            END IF;
            pk_alert_exceptions.process_error(i_lang        => i_lang,
                                              i_sqlcode     => g_error_code,
                                              i_sqlerrm     => g_error_desc,
                                              i_message     => g_error,
                                              i_owner       => g_package_owner,
                                              i_package     => g_package_name,
                                              i_function    => 'GET_REFERRAL_NETWORK',
                                              i_action_type => g_flg_action,
                                              i_action_msg  => NULL,
                                              o_error       => o_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END get_referral_network;

    /**
    * Returns referral institutions/specialities available for referring, of the Hospital complex from which i_id_inst_dest belongs
    *
    * @param   i_lang              Language associated to the professional executing the request
    * @param   i_prof              Id professional, institution and software from the Interface
    * @param   i_id_external_sys   External system identifier
    * @param   i_id_workflow       Referral workflow
    * @param   i_id_inst_dest      Institution belonging to the Hospital Complex
    * @param   o_ref_data          Referral specialities or dep_clin_servs data (depends on id_workflow): ID + DESC
    * @param   o_error             An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   18-11-2011
    */
    FUNCTION get_all_referral_network
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_external_sys IN p1_external_request.id_external_sys%TYPE,
        i_id_workflow     IN p1_external_request.id_workflow%TYPE,
        i_id_inst_dest    IN p1_external_request.id_inst_dest%TYPE,
        o_ref_data        OUT NOCOPY t_coll_ref_all_network,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_flg_availability p1_spec_dep_clin_serv.flg_availability%TYPE;
        l_params           VARCHAR2(1000 CHAR);
        l_inst_tab         table_number;
    
        l_ref_waiting_time sys_config.value%TYPE;
        l_ref_adw_column   sys_config.value%TYPE;
    
        CURSOR c_ref_network IS
            SELECT DISTINCT t_rec_ref_all_network(id_inst_orig, -- distinct because there may by several id_dep_clin_Servs
                                                  pk_translation.get_translation(i_lang, t.orig_code_institution),
                                                  t.orig_ext_code,
                                                  t.id_speciality,
                                                  pk_translation.get_translation(i_lang, t.code_speciality),
                                                  t.id_institution,
                                                  pk_translation.get_translation(i_lang, t.code_institution),
                                                  t.ext_code,
                                                  (SELECT pk_sysdomain.get_domain(pk_ref_constant.g_ref_flg_type_ins,
                                                                                  t.flg_type_ins,
                                                                                  i_lang)
                                                     FROM dual),
                                                  t.flg_inside_ref_area,
                                                  t.flg_ref_line,
                                                  decode(l_ref_waiting_time,
                                                         pk_ref_constant.g_no,
                                                         NULL,
                                                         pk_ref_constant.g_yes,
                                                         pk_ref_waiting_time.get_waiting_time(i_lang           => i_lang,
                                                                                              i_prof           => i_prof,
                                                                                              i_ref_adw_column => l_ref_adw_column,
                                                                                              i_id_institution => t.id_institution,
                                                                                              i_id_speciality  => t.id_speciality)))
              FROM ( -- pedidos externos
                    SELECT v.id_institution,
                            v.ext_code,
                            v.code_institution,
                            v.flg_default_inst,
                            v.flg_ref_line,
                            v.flg_type_ins,
                            v.flg_inside_ref_area,
                            v.id_speciality,
                            v.code_speciality,
                            v.id_inst_orig,
                            v.orig_ext_code,
                            v.orig_code_institution
                      FROM v_ref_network v
                      JOIN TABLE(CAST(l_inst_tab AS table_number)) t -- institutions belonging to the Hospital Complex
                        ON t.column_value = v.id_institution
                     WHERE l_flg_availability = pk_ref_constant.g_flg_availability_e -- to be used only for external referrals
                       AND v.id_external_sys IN (nvl(i_id_external_sys, 0), 0)
                       AND v.flg_type = pk_ref_constant.g_p1_type_c
                       AND v.flg_default_dcs = pk_ref_constant.g_yes
                    UNION ALL
                    -- pedidos a porta do hospital
                    SELECT vp.id_institution,
                            vp.ext_code,
                            vp.code_institution,
                            vp.flg_default_inst,
                            vp.flg_ref_line,
                            vp.flg_type_ins,
                            vp.flg_inside_ref_area,
                            vp.id_speciality,
                            vp.code_speciality,
                            NULL                   id_inst_orig,
                            NULL                   orig_ext_code,
                            NULL                   orig_code_institution
                      FROM v_ref_hosp_entrance vp
                      JOIN TABLE(CAST(l_inst_tab AS table_number)) t -- institutions belonging to the Hospital Complex
                        ON t.column_value = vp.id_institution
                     WHERE l_flg_availability = pk_ref_constant.g_flg_availability_p -- to be used only for at hospital entrance wf
                       AND vp.id_external_sys IN (nvl(i_id_external_sys, 0), 0)
                       AND vp.flg_type = pk_ref_constant.g_p1_type_c
                       AND vp.flg_default_dcs = pk_ref_constant.g_yes) t;
    BEGIN
        ----------------------
        -- INIT
        ----------------------
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_id_external_sys=' || i_id_external_sys ||
                    ' i_id_workflow=' || i_id_workflow || ' i_id_inst_dest=' || i_id_inst_dest;
    
        g_error := 'Init get_all_referral_network / ' || l_params;
        pk_alertlog.log_debug(g_error);
    
        ----------------------
        -- CONFIG
        ----------------------
        l_ref_waiting_time := nvl(pk_ref_utils.get_sys_config(i_prof          => i_prof,
                                                              i_id_sys_config => pk_ref_constant.g_ref_waiting_time),
                                  pk_ref_constant.g_no);
        l_ref_adw_column   := pk_ref_utils.get_sys_config(i_prof          => i_prof,
                                                          i_id_sys_config => pk_ref_constant.g_sc_ref_adw_column);
    
        ----------------------
        -- FUNC
        ----------------------
        -- getting dest institutions of the CH
        l_inst_tab := pk_ref_core.get_sibling_inst(i_id_institution => i_id_inst_dest,
                                                   i_flg_slef       => pk_ref_constant.g_yes); -- institution brothers (including it self)
        l_inst_tab := l_inst_tab MULTISET UNION pk_ref_core.get_child_inst(i_id_institution => i_id_inst_dest);
    
        g_error := 'IF ID_WORKFLOW / l_inst_tab.count=' || l_inst_tab.count || ' / ' || l_params;
        IF nvl(i_id_workflow, pk_ref_constant.g_wf_pcc_hosp) IN
           (pk_ref_constant.g_wf_pcc_hosp, pk_ref_constant.g_wf_hosp_hosp, pk_ref_constant.g_wf_x_hosp)
        THEN
        
            l_flg_availability := get_flg_availability(i_id_workflow => i_id_workflow);
        
            OPEN c_ref_network;
            FETCH c_ref_network BULK COLLECT
                INTO o_ref_data;
            CLOSE c_ref_network;
        
        ELSE
            g_error      := 'Invalid workflow / ' || l_params;
            g_error_code := pk_ref_constant.g_ref_error_1005;
            g_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => g_error_code);
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            IF g_error_code IS NOT NULL
            THEN
                g_flg_action := pk_ref_constant.g_err_flg_action_u;
            ELSE
                g_error_code := SQLCODE;
                g_error_desc := SQLERRM;
                g_flg_action := pk_ref_constant.g_err_flg_action_s;
            END IF;
            pk_alert_exceptions.process_error(i_lang        => i_lang,
                                              i_sqlcode     => g_error_code,
                                              i_sqlerrm     => g_error_desc,
                                              i_message     => g_error,
                                              i_owner       => g_package_owner,
                                              i_package     => g_package_name,
                                              i_function    => 'GET_ALL_REFERRAL_NETWORK',
                                              i_action_type => g_flg_action,
                                              i_action_msg  => NULL,
                                              o_error       => o_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END get_all_referral_network;

    /**
    * Gets available clinical services for referring in dest institution.
    * Available only for external and at hospital entrance workflows
    *
    * @param   i_lang              Language associated to the professional executing the request
    * @param   i_prof              Id professional, institution and software from the Interface
    * @param   i_id_workflow       Referral workflow
    * @param   i_id_speciality     Speciality identifier
    * @param   i_id_inst_dest      Dest institution identifier    
    * @param   o_ref_data          Referral dep_clin_servs data: ID + DESC
    * @param   o_error             An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   24-09-2012
    */
    FUNCTION get_referral_clinserv
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_workflow     IN p1_external_request.id_workflow%TYPE,
        i_id_speciality   IN p1_external_request.id_speciality%TYPE,
        i_id_inst_dest    IN p1_external_request.id_inst_dest%TYPE,
        i_id_external_sys IN p1_external_request.id_external_sys%TYPE,
        o_ref_data        OUT NOCOPY t_coll_ref_dcs,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_flg_availability p1_spec_dep_clin_serv.flg_availability%TYPE;
        l_ref_dcs_tab      pk_ref_list.t_coll_ref_dcs;
        l_ref_dcs_cur      pk_ref_list.t_cur_ref_dcs;
        l_params           VARCHAR2(1000 CHAR);
    BEGIN
        ----------------------
        -- INIT
        ----------------------    
        l_params := 'i_id_workflow=' || i_id_workflow || ' i_id_speciality=' || i_id_speciality || ' i_id_inst_dest=' ||
                    i_id_inst_dest || ' i_id_external_sys=' || i_id_external_sys || ' id_inst_orig=' ||
                    i_prof.institution;
        g_error  := 'Init get_referral_clinserv / ' || l_params;
        pk_alertlog.log_debug(g_error);
        o_ref_data := t_coll_ref_dcs();
    
        -- do not set the referral context: this function is called internally in this package
    
        ----------------------
        -- VAL
        ----------------------
        IF nvl(i_id_workflow, pk_ref_constant.g_wf_pcc_hosp) NOT IN
           (pk_ref_constant.g_wf_pcc_hosp, pk_ref_constant.g_wf_hosp_hosp, pk_ref_constant.g_wf_x_hosp)
        THEN
            g_error      := 'Invalid workflow / ' || l_params;
            g_error_code := pk_ref_constant.g_ref_error_1005;
            g_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => g_error_code);
            RAISE g_exception;
        END IF;
    
        IF i_id_inst_dest IS NULL
        THEN
            g_error      := 'Invalid parameter / ' || l_params;
            g_error_code := pk_ref_constant.g_ref_error_1005;
            g_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => g_error_code);
            RAISE g_exception;
        END IF;
    
        IF nvl(i_id_workflow, pk_ref_constant.g_wf_pcc_hosp) != pk_ref_constant.g_wf_x_hosp
        THEN
            -- professional must be at orig institution
            IF i_prof.institution = i_id_inst_dest
            THEN
                g_error      := 'Professional institution (' || i_prof.institution ||
                                ') must not be the same as dest institution (' || i_id_inst_dest || ')';
                g_error_code := pk_ref_constant.g_ref_error_1009;
                g_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => g_error_code);
                RAISE g_exception;
            END IF;
        
        ELSIF nvl(i_id_workflow, pk_ref_constant.g_wf_pcc_hosp) = pk_ref_constant.g_wf_x_hosp
        THEN
            -- professional must be at dest institution
            IF i_prof.institution != i_id_inst_dest
            THEN
                g_error      := 'Professional institution (' || i_prof.institution ||
                                ') must be the same as dest institution (' || i_id_inst_dest || ')';
                g_error_code := pk_ref_constant.g_ref_error_1009;
                g_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => g_error_code);
                RAISE g_exception;
            END IF;
        END IF;
    
        ----------------------
        -- FUNC
        ----------------------    
        l_flg_availability := get_flg_availability(i_id_workflow => i_id_workflow);
        l_params           := l_params || ' l_flg_availability=' || l_flg_availability;
    
        g_error  := 'Call pk_ref_list.get_net_clin_serv / ' || l_params;
        g_retval := pk_ref_list.get_net_clin_serv(i_lang         => i_lang,
                                                  i_prof         => i_prof,
                                                  i_ref_type     => l_flg_availability,
                                                  i_p1_spec      => i_id_speciality,
                                                  i_id_inst_dest => i_id_inst_dest,
                                                  i_external_sys => i_id_external_sys,
                                                  o_sql          => l_ref_dcs_cur,
                                                  o_error        => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        g_error := 'FETCH l_ref_dcs_cur BULK COLLECT INTO l_ref_dcs_tab / ' || l_params;
        FETCH l_ref_dcs_cur BULK COLLECT
            INTO l_ref_dcs_tab;
        CLOSE l_ref_dcs_cur;
    
        IF l_ref_dcs_tab.count > 0
        THEN
            o_ref_data.extend(l_ref_dcs_tab.count);
        
            g_error := 'FOR i IN 1 .. ' || l_ref_dcs_tab.count || ' LOOP / ' || l_params;
            FOR i IN 1 .. l_ref_dcs_tab.count
            LOOP
                o_ref_data(i) := t_rec_ref_dcs();
                o_ref_data(i).id_dep_clin_serv := l_ref_dcs_tab(i).id_dep_clin_serv;
                o_ref_data(i).desc_clin_serv := l_ref_dcs_tab(i).desc_cls_srv;
            END LOOP;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            IF g_error_code IS NOT NULL
            THEN
                g_flg_action := pk_ref_constant.g_err_flg_action_u;
            ELSE
                g_error_code := SQLCODE;
                g_error_desc := SQLERRM;
                g_flg_action := pk_ref_constant.g_err_flg_action_s;
            END IF;
            pk_alert_exceptions.process_error(i_lang        => i_lang,
                                              i_sqlcode     => g_error_code,
                                              i_sqlerrm     => g_error_desc,
                                              i_message     => g_error,
                                              i_owner       => g_package_owner,
                                              i_package     => g_package_name,
                                              i_function    => 'GET_REFERRAL_CLINSERV',
                                              i_action_type => g_flg_action,
                                              i_action_msg  => NULL,
                                              o_error       => o_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END get_referral_clinserv;

    /**
    * Returns origin institutions available to referring for the workflow 'At hospital entrance'
    * Note: only used for wf=4
    *
    * @param   i_lang              Language associated to the professional executing the request
    * @param   i_prof              Id professional, institution and software from the Interface
    * @param   i_id_external_sys   External system identifier
    * @param   i_id_inst_dest      Dest institution identifier
    * @param   i_id_speciality     Speciality identifier
    * @param   i_id_dep_clin_serv  Department and service identifier
    * @param   o_ref_data          Referral origin institutions available to referring
    * @param   o_error             An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   11-03-2014
    */
    FUNCTION get_referral_inst_orig
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_external_sys  IN p1_external_request.id_external_sys%TYPE,
        i_id_inst_dest     IN p1_external_request.id_inst_dest%TYPE,
        i_id_speciality    IN p1_external_request.id_speciality%TYPE,
        i_id_dep_clin_serv IN p1_external_request.id_dep_clin_serv%TYPE,
        o_ref_data         OUT NOCOPY t_coll_ref_inst,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(24 CHAR) := 'get_referral_inst_orig';
        l_params       VARCHAR2(1000 CHAR);
        l_ref_inst_tab pk_ref_list.t_coll_ref_net_inst_orig;
        l_ref_inst_cur pk_ref_list.t_cur_ref_net_inst_orig;
    BEGIN
        ----------------------
        -- INIT
        ----------------------    
        l_params := 'i_id_external_sys=' || i_id_external_sys || ' i_id_inst_dest=' || i_id_inst_dest ||
                    ' i_id_speciality=' || i_id_speciality;
        g_error  := 'Init ' || l_func_name || ' / ' || l_params;
        pk_alertlog.log_debug(g_error);
        o_ref_data := t_coll_ref_inst();
    
        -- do not set the referral context: this function is called internally in this package
    
        ----------------------
        -- VAL
        ----------------------  
        -- professional must be at dest institution
        IF i_prof.institution != i_id_inst_dest
           OR i_id_inst_dest IS NULL
        THEN
            g_error      := 'Professional institution (' || i_prof.institution ||
                            ') must be the same as dest institution (' || i_id_inst_dest || ') / ' || l_params;
            g_error_code := pk_ref_constant.g_ref_error_1009;
            g_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => g_error_code);
            RAISE g_exception;
        END IF;
    
        ----------------------
        -- FUNC
        ----------------------    
        g_error  := 'Call pk_ref_list.get_net_inst_orig / ' || l_params;
        g_retval := pk_ref_list.get_net_inst_orig(i_lang             => i_lang,
                                                  i_prof             => i_prof,
                                                  i_p1_spec          => i_id_speciality,
                                                  i_id_inst_dest     => i_id_inst_dest,
                                                  i_external_sys     => i_id_external_sys,
                                                  i_id_dep_clin_serv => i_id_dep_clin_serv,
                                                  i_flg_type_ref     => pk_ref_constant.g_p1_type_c,
                                                  o_sql              => l_ref_inst_cur,
                                                  o_error            => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        g_error := 'FETCH l_ref_inst_cur BULK COLLECT into / ' || l_params;
        FETCH l_ref_inst_cur BULK COLLECT
            INTO l_ref_inst_tab;
        CLOSE l_ref_inst_cur;
    
        g_error := 'o_ref_data.extend(' || l_ref_inst_tab.count || ') / ' || l_params;
        o_ref_data.extend(l_ref_inst_tab.count);
    
        g_error := 'FOR i IN 1 .. ' || l_ref_inst_tab.count || ' / ' || l_params;
        FOR i IN 1 .. l_ref_inst_tab.count
        LOOP
            o_ref_data(i) := t_rec_ref_inst();
            o_ref_data(i).id_institution := l_ref_inst_tab(i).id_inst_orig;
            o_ref_data(i).description := l_ref_inst_tab(i).orig_inst_desc;
            o_ref_data(i).ext_code := l_ref_inst_tab(i).ext_code;
        END LOOP;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            IF g_error_code IS NOT NULL
            THEN
                g_flg_action := pk_ref_constant.g_err_flg_action_u;
            ELSE
                g_error_code := SQLCODE;
                g_error_desc := SQLERRM;
                g_flg_action := pk_ref_constant.g_err_flg_action_s;
            END IF;
            pk_alert_exceptions.process_error(i_lang        => i_lang,
                                              i_sqlcode     => g_error_code,
                                              i_sqlerrm     => g_error_desc,
                                              i_message     => g_error,
                                              i_owner       => g_package_owner,
                                              i_package     => g_package_name,
                                              i_function    => l_func_name,
                                              i_action_type => g_flg_action,
                                              i_action_msg  => NULL,
                                              o_error       => o_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END get_referral_inst_orig;

    /**
    * Returns institutions and clinical services to forward the referral
    *
    * @param   i_lang              Language associated to the professional executing the request
    * @param   i_prof              Id professional, institution and software from the Interface
    * @param   i_id_ref            Referral identifier
    * @param   o_inst_data         Institutions and clinical services to forward the referral
    * @param   o_error             An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   15-07-2013
    */
    FUNCTION get_inst_to_forward_ref
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_ref    IN p1_external_request.id_external_request%TYPE,
        o_inst_data OUT t_coll_ref_all_dcs,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_params  VARCHAR2(1000 CHAR);
        l_ref_row p1_external_request%ROWTYPE;
        l_gender  patient.gender%TYPE;
        l_age     patient.age%TYPE;
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_id_ref=' || i_id_ref;
        g_error  := 'Init get_inst_to_forward_ref / ' || l_params;
        pk_alertlog.log_debug(g_error);
        o_inst_data := t_coll_ref_all_dcs();
    
        -- sets the referral context
        pk_ref_utils.init_ref_context;
        pk_ref_utils.set_ref_context(i_id_external_request => i_id_ref, i_dt_system_date => current_timestamp);
    
        -- getting referral data
        g_error  := 'Call pk_p1_external_request.get_ref_row / ' || l_params;
        g_retval := pk_p1_external_request.get_ref_row(i_lang   => i_lang,
                                                       i_prof   => i_prof,
                                                       i_id_ref => i_id_ref,
                                                       o_rec    => l_ref_row,
                                                       o_error  => o_error);
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        l_params := l_params || ' ID_SPEC=' || l_ref_row.id_speciality || ' ID_WF=' || l_ref_row.id_workflow ||
                    ' ID_PATIENT=' || l_ref_row.id_patient || ' FLG_STATUS=' || l_ref_row.flg_status ||
                    ' ID_INST_DEST=' || l_ref_row.id_inst_dest;
    
        IF i_prof.institution != l_ref_row.id_inst_dest
        THEN
            g_error      := 'Professional institution (' || i_prof.institution ||
                            ') must be the same as dest institution (' || l_ref_row.id_inst_dest || ') / ' || l_params;
            g_error_code := pk_ref_constant.g_ref_error_1009;
            g_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => g_error_code);
            RAISE g_exception;
        END IF;
    
        -- getting patient data
        g_error  := 'Call pk_ref_core.get_pat_age_gender / ' || l_params;
        g_retval := pk_ref_core.get_pat_age_gender(i_lang    => i_lang,
                                                   i_prof    => i_prof,
                                                   i_patient => l_ref_row.id_patient,
                                                   o_gender  => l_gender,
                                                   o_age     => l_age,
                                                   o_error   => o_error);
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        l_params := l_params || ' gender=' || l_gender || ' age=' || l_age;
    
        g_error := 'SELECT t_rec_ref_all_dcs / ' || l_params;
        SELECT t_rec_ref_all_dcs(t.id_dep_clin_serv,
                                 t.id_institution,
                                 pk_translation.get_translation(i_lang,
                                                                pk_ref_constant.g_institution_code || t.id_institution),
                                 t.id_department,
                                 pk_translation.get_translation(i_lang, t.code_department),
                                 t.id_clinical_service,
                                 pk_translation.get_translation(i_lang, t.code_clinical_service))
          BULK COLLECT
          INTO o_inst_data
          FROM TABLE(CAST(pk_ref_dest_phy.get_inst_dcs_forward_p(i_lang         => i_lang,
                                                                 i_prof         => i_prof,
                                                                 i_id_spec      => l_ref_row.id_speciality,
                                                                 i_id_workflow  => nvl(l_ref_row.id_workflow,
                                                                                       pk_ref_constant.g_wf_pcc_hosp),
                                                                 i_id_inst_orig => l_ref_row.id_inst_orig,
                                                                 i_id_inst_dest => l_ref_row.id_inst_dest,
                                                                 i_pat_gender   => l_gender,
                                                                 i_pat_age      => l_age,
                                                                 i_external_sys => l_ref_row.id_external_sys) AS
                          t_coll_ref_inst_dcs_fwd)) t;
    
        -- resets the referral context
        pk_ref_utils.reset_ref_context;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            IF g_error_code IS NOT NULL
            THEN
                g_flg_action := pk_ref_constant.g_err_flg_action_u;
            ELSE
                g_error_code := SQLCODE;
                g_error_desc := SQLERRM;
                g_flg_action := pk_ref_constant.g_err_flg_action_s;
            END IF;
            pk_alert_exceptions.process_error(i_lang        => i_lang,
                                              i_sqlcode     => g_error_code,
                                              i_sqlerrm     => g_error_desc,
                                              i_message     => g_error,
                                              i_owner       => g_package_owner,
                                              i_package     => g_package_name,
                                              i_function    => 'GET_INST_TO_FORWARD_REF',
                                              i_action_type => g_flg_action,
                                              i_action_msg  => NULL,
                                              o_error       => o_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END get_inst_to_forward_ref;

    /**
    * Migrate a referral to a different dest institution
    * This function has COMMITs/ROLLBACKs
    *
    * Fill in table REF_MIG_INST_DEST_DATA with data to be migrated
    *
    * @param   i_default_dcs       Indicates if dep_clin_serv is mapped or calculated by default
    * @param   i_notes             Notes associated to the migration
    * @param   o_error             An error message, set when return=false
    *
    * @value   i_default_dcs       {*} Y- calculated by default for the referral speciality {*} N- calculated from table MAP
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   14-06-2012
    */
    FUNCTION mig_ref_dest_institution
    (
        i_default_dcs IN VARCHAR2 DEFAULT pk_ref_constant.g_yes,
        i_notes       IN VARCHAR2 DEFAULT NULL,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_lang PLS_INTEGER := 1;
    BEGIN
        g_error := 'Init mig_ref_dest_institution / i_default_dcs=' || i_default_dcs;
        pk_alertlog.log_debug(g_error);
        RETURN pk_api_referral.mig_ref_dest_institution(i_default_dcs => i_default_dcs,
                                                        i_notes       => i_notes,
                                                        o_error       => o_error);
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            IF g_error_code IS NOT NULL
            THEN
                g_flg_action := pk_ref_constant.g_err_flg_action_u;
            ELSE
                g_error_code := SQLCODE;
                g_error_desc := SQLERRM;
                g_flg_action := pk_ref_constant.g_err_flg_action_s;
            END IF;
            pk_alert_exceptions.process_error(i_lang        => l_lang,
                                              i_sqlcode     => g_error_code,
                                              i_sqlerrm     => g_error_desc,
                                              i_message     => g_error,
                                              i_owner       => g_package_owner,
                                              i_package     => g_package_name,
                                              i_function    => 'MIG_REF_DEST_INSTITUTION',
                                              i_action_type => g_flg_action,
                                              i_action_msg  => NULL,
                                              o_error       => o_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END mig_ref_dest_institution;

    /**
    * Sets the connection between the patient id and the hospital process
    *
    * @param   i_lang          Language associated to the professional executing the request
    * @param   i_prof          Professional id, institution and software
    * @param   i_pat           Patient identifier
    * @param   i_seq_num       External system identifier
    * @param   i_clin_rec      Patient process number on the institution, if available.
    * @param   i_epis          Episode identifier
    * @param   o_id_match      Match identifier
    * @param   o_error         An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   14-11-2012
    */
    FUNCTION set_match
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_pat      IN patient.id_patient%TYPE,
        i_seq_num  IN p1_match.sequential_number%TYPE,
        i_clin_rec IN clin_record.num_clin_record%TYPE,
        i_epis     IN episode.id_episode%TYPE DEFAULT NULL,
        o_id_match OUT p1_match.id_match%TYPE,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_params VARCHAR2(1000 CHAR);
    BEGIN
        l_params   := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_pat=' || i_pat || ' i_seq_num=' || i_seq_num ||
                      ' i_clin_rec=' || i_clin_rec || ' i_epis=' || i_epis;
        g_error    := 'Init set_match / ' || l_params;
        g_prof_int := pk_p1_interface.set_prof_interface(i_prof);
        -- sets the referral context
        pk_ref_utils.init_ref_context;
        pk_ref_utils.set_ref_context(i_dt_system_date => current_timestamp);
    
        g_error  := 'Calling pk_ref_dest_reg.set_match / ' || l_params;
        g_retval := pk_ref_dest_reg.set_match(i_lang     => i_lang,
                                              i_prof     => g_prof_int,
                                              i_pat      => i_pat,
                                              i_seq_num  => i_seq_num,
                                              i_clin_rec => i_clin_rec,
                                              i_epis     => i_epis,
                                              o_id_match => o_id_match,
                                              o_error    => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- resets the referral context
        pk_ref_utils.reset_ref_context;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'SET_MATCH',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END set_match;

    /**
    * Search for referral identifiers according to the criteria specified
    * Used by inter-alert
    *
    * @param   i_lang          Language associated to the professional executing the request
    * @param   i_prof          Professional id, institution and software
    * @param   i_pat_name      Patient name
    * @param   i_pat_gender    Patient gender
    * @param   i_dt_birth      Patient date of birth
    * @param   i_sns           Patient national health plan (SNS)
    * @param   i_id_ref        Referral identifier
    * @param   i_id_inst       Referral institution (orig or dest)
    * @param   i_id_inst_orig         Referral orig institution identifier
    * @param   i_id_inst_dest         Referral dest institution identifier
    * @param   i_id_spec       Referral speciality
    * @param   i_dt_search_beg        Begin search timestamp
    * @param   i_dt_search_end        End search timestamp
    * @param   o_id_ref_tab    Array of referral identifiers
    * @param   o_error         An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   14-12-2012
    */
    FUNCTION get_search_referrals
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_pat_name      IN patient.name%TYPE,
        i_pat_gender    IN patient.gender%TYPE,
        i_dt_birth      IN patient.dt_birth%TYPE,
        i_sns           IN pat_health_plan.num_health_plan%TYPE,
        i_id_ref        IN p1_external_request.id_external_request%TYPE,
        i_id_inst       IN institution.id_institution%TYPE,
        i_id_inst_orig  IN p1_external_request.id_inst_orig%TYPE,
        i_id_inst_dest  IN p1_external_request.id_inst_dest%TYPE,
        i_id_spec       IN p1_speciality.id_speciality%TYPE,
        i_dt_search_beg IN TIMESTAMP WITH TIME ZONE,
        i_dt_search_end IN TIMESTAMP WITH TIME ZONE,
        o_id_ref_tab    OUT table_number,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_params       VARCHAR2(1000 CHAR);
        l_crit_id_tab  table_number;
        l_crit_val_tab table_varchar;
        l_sql          CLOB;
        l_prof         profissional;
    BEGIN
        l_params       := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_pat_name=' || i_pat_name || ' i_pat_gender=' ||
                          i_pat_gender || ' i_dt_birth=' || i_dt_birth || ' i_sns=' || i_sns || ' i_id_ref=' ||
                          i_id_ref || ' i_id_inst=' || i_id_inst || ' i_id_inst_orig=' || i_id_inst_orig ||
                          ' i_id_inst_dest=' || i_id_inst_dest || ' i_id_spec=' || i_id_spec || ' i_dt_search_beg=' ||
                          i_dt_search_beg || ' i_dt_search_end=' || i_dt_search_end;
        g_error        := 'Init get_search_referrals / ' || l_params;
        o_id_ref_tab   := table_number();
        l_crit_id_tab  := table_number();
        l_crit_val_tab := table_varchar();
        l_prof         := pk_ref_interface.set_prof_interface(i_prof => i_prof);
    
        -- sets the referral context
        pk_ref_utils.init_ref_context;
        pk_ref_utils.set_ref_context(i_dt_system_date => current_timestamp);
    
        g_error := 'i_pat_name / ' || l_params;
        IF i_pat_name IS NOT NULL
        THEN
            l_crit_id_tab.extend;
            l_crit_val_tab.extend;
        
            l_crit_id_tab(l_crit_id_tab.last) := pk_ref_constant.g_crit_pat_name;
            l_crit_val_tab(l_crit_val_tab.last) := i_pat_name;
        END IF;
    
        g_error := 'i_pat_gender / ' || l_params;
        IF i_pat_gender IS NOT NULL
        THEN
            l_crit_id_tab.extend;
            l_crit_val_tab.extend;
        
            l_crit_id_tab(l_crit_id_tab.last) := pk_ref_constant.g_crit_pat_gender;
            l_crit_val_tab(l_crit_val_tab.last) := i_pat_gender;
        END IF;
    
        g_error := 'i_dt_birth / ' || l_params;
        IF i_dt_birth IS NOT NULL
        THEN
            l_crit_id_tab.extend;
            l_crit_val_tab.extend;
        
            l_crit_id_tab(l_crit_id_tab.last) := pk_ref_constant.g_crit_pat_dt_birth;
            l_crit_val_tab(l_crit_val_tab.last) := to_char(i_dt_birth, pk_ref_constant.g_crit_pat_dt_birth_format);
        END IF;
    
        g_error := 'i_sns / ' || l_params;
        IF i_sns IS NOT NULL
        THEN
            l_crit_id_tab.extend;
            l_crit_val_tab.extend;
        
            l_crit_id_tab(l_crit_id_tab.last) := pk_ref_constant.g_crit_pat_sns;
            l_crit_val_tab(l_crit_val_tab.last) := i_sns;
        END IF;
    
        g_error := 'i_id_ref / ' || l_params;
        IF i_id_ref IS NOT NULL
        THEN
            l_crit_id_tab.extend;
            l_crit_val_tab.extend;
        
            l_crit_id_tab(l_crit_id_tab.last) := pk_ref_constant.g_crit_id_ref;
            l_crit_val_tab(l_crit_val_tab.last) := to_char(i_id_ref);
        END IF;
    
        g_error := 'i_id_inst / ' || l_params;
        IF i_id_inst IS NOT NULL
        THEN
            l_crit_id_tab.extend;
            l_crit_val_tab.extend;
        
            l_crit_id_tab(l_crit_id_tab.last) := pk_ref_constant.g_crit_id_inst;
            l_crit_val_tab(l_crit_val_tab.last) := to_char(i_id_inst);
        END IF;
    
        g_error := 'i_id_inst_orig / ' || l_params;
        IF i_id_inst_orig IS NOT NULL
        THEN
            l_crit_id_tab.extend;
            l_crit_val_tab.extend;
        
            l_crit_id_tab(l_crit_id_tab.last) := pk_ref_constant.g_crit_id_inst_orig;
            l_crit_val_tab(l_crit_val_tab.last) := to_char(i_id_inst_orig);
        END IF;
    
        g_error := 'i_id_inst_dest / ' || l_params;
        IF i_id_inst_dest IS NOT NULL
        THEN
            l_crit_id_tab.extend;
            l_crit_val_tab.extend;
        
            l_crit_id_tab(l_crit_id_tab.last) := pk_ref_constant.g_crit_id_inst_dest;
            l_crit_val_tab(l_crit_val_tab.last) := to_char(i_id_inst_dest);
        END IF;
    
        g_error := 'i_id_spec / ' || l_params;
        IF i_id_spec IS NOT NULL
        THEN
            l_crit_id_tab.extend;
            l_crit_val_tab.extend;
        
            l_crit_id_tab(l_crit_id_tab.last) := pk_ref_constant.g_crit_id_spec;
            l_crit_val_tab(l_crit_val_tab.last) := to_char(i_id_spec);
        END IF;
    
        g_error := 'i_dt_search_beg / ' || l_params;
        IF i_dt_search_beg IS NOT NULL
        THEN
            l_crit_id_tab.extend;
            l_crit_val_tab.extend;
        
            l_crit_id_tab(l_crit_id_tab.last) := pk_ref_constant.g_crit_dt_requested_tstz_sup;
            l_crit_val_tab(l_crit_val_tab.last) := to_char(i_dt_search_beg, pk_ref_constant.g_format_tstz);
        END IF;
    
        g_error := 'i_dt_search_end / ' || l_params;
        IF i_dt_search_end IS NOT NULL
        THEN
            l_crit_id_tab.extend;
            l_crit_val_tab.extend;
        
            l_crit_id_tab(l_crit_id_tab.last) := pk_ref_constant.g_crit_dt_requested_tstz_inf;
            l_crit_val_tab(l_crit_val_tab.last) := to_char(i_dt_search_end, pk_ref_constant.g_format_tstz);
        END IF;
    
        g_error := 'l_crit_id_tab.count=' || l_crit_id_tab.count || ' / ' || l_params;
        IF l_crit_id_tab.count = 0
        THEN
            -- no criteria specified
            g_error := 'No criteria specified / ' || l_params;
            RAISE g_exception;
        END IF;
    
        l_params := l_params || ' l_crit_id_tab.count=' || l_crit_id_tab.count;
    
        -- getting sql string
        g_error  := 'Call pk_ref_core_internal.get_search_ref_sql_base / ' || l_params;
        g_retval := pk_ref_core_internal.get_search_ref_sql_base(i_lang         => i_lang,
                                                                 i_prof         => l_prof,
                                                                 i_crit_id_tab  => l_crit_id_tab,
                                                                 i_crit_val_tab => l_crit_val_tab,
                                                                 o_sql          => l_sql,
                                                                 o_error        => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- getting data
        g_error := 'SELECT id_external_request / ' || l_params;
        SELECT id_external_request
          BULK COLLECT
          INTO o_id_ref_tab
          FROM TABLE(CAST(pk_ref_core_internal.get_search_ref_data(l_sql) AS t_coll_ref_search)) t;
    
        -- resets the referral context
        pk_ref_utils.reset_ref_context;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_SEARCH_REFERRALS',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END get_search_referrals;

    /**
    * Generate events for each issued referral of this patient in this institution
    * Used by inter-alert
    *
    * @param   i_lang          Language associated to the professional executing the request
    * @param   i_prof          Professional id, institution and software
    * @param   i_id_patient    Patient identifier
    * @param   o_error         An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   01-03-2013
    */
    FUNCTION set_event_patient_match
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_params VARCHAR2(1000 CHAR);
        CURSOR c_ref
        (
            x_id_patient   IN p1_external_request.id_patient%TYPE,
            x_id_inst_dest IN p1_external_request.id_inst_dest%TYPE
        ) IS
            SELECT p.id_external_request
              FROM p1_external_request p
             WHERE p.id_patient = x_id_patient
               AND p.id_inst_dest = x_id_inst_dest
               AND p.flg_status = pk_ref_constant.g_p1_status_i; -- referrals issued for this institution
    
        l_ref_tab table_number;
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_id_patient=' || i_id_patient;
        g_error  := 'Init set_event_patient_match / ' || l_params;
    
        g_error := 'OPEN c_ref(' || i_id_patient || ',' || i_prof.institution || ')';
        OPEN c_ref(x_id_patient => i_id_patient, x_id_inst_dest => i_prof.institution);
    
        FETCH c_ref BULK COLLECT
            INTO l_ref_tab;
        CLOSE c_ref;
    
        FOR i IN 1 .. l_ref_tab.count
        LOOP
            -- INTER-ALERT
            g_error := '---- CREATE REFERRAL';
            pk_ia_event_referral.referral_create(i_id_external_request => l_ref_tab(i),
                                                 i_id_institution      => i_prof.institution);
        END LOOP;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'SET_EVENT_PATIENT_MATCH',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END set_event_patient_match;

    /**
    * Validates input parameters for referral comments creation/Update
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Id professional, institution and software    
    * @param   i_id_ref         Referral identifier   
    * @param   i_id_ref_comment Referral comment identifier       
    * @param   o_flg_valid      {*} 'Y' - all parameters valid {*} 'N' - otherwise 
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   25-07-2013
    */
    FUNCTION check_comment_requirements
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_ref         IN p1_external_request.id_external_request%TYPE,
        i_id_ref_comment IN ref_comments.id_ref_comment%TYPE,
        o_flg_valid      OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        i_ref_row                 p1_external_request%ROWTYPE;
        l_comments_available_dest sys_config.value%TYPE;
        l_comments_available_orig sys_config.value%TYPE;
    
        CURSOR c_check_prof(x_ref_comment ref_comments.id_ref_comment%TYPE) IS
            SELECT id_professional
              FROM ref_comments
             WHERE id_ref_comment = x_ref_comment;
    
        l_prof professional.id_professional%TYPE;
    BEGIN
    
        -- check if can create comment    
        g_error  := 'Call pk_p1_external_request.get_ref_row / I_ID_REF=' || i_id_ref;
        g_retval := pk_p1_external_request.get_ref_row(i_lang   => i_lang,
                                                       i_prof   => i_prof,
                                                       i_id_ref => i_id_ref,
                                                       o_rec    => i_ref_row,
                                                       o_error  => o_error);
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        g_error := 'Call  pk_sysconfig.get_config ID_SYS_CONFIG=' || pk_ref_constant.g_ref_comments_available ||
                   ', ID_INST_DEST=' || i_ref_row.id_inst_dest;
    
        l_comments_available_dest := pk_sysconfig.get_config(pk_ref_constant.g_ref_comments_available,
                                                             profissional(i_prof.id,
                                                                          i_ref_row.id_inst_dest,
                                                                          i_prof.software));
        g_error                   := 'Call  pk_sysconfig.get_config ID_SYS_CONFIG=' ||
                                     pk_ref_constant.g_ref_comments_available || ', ID_INST_ORIG=' ||
                                     i_ref_row.id_inst_orig;
    
        l_comments_available_orig := pk_sysconfig.get_config(pk_ref_constant.g_ref_comments_available,
                                                             profissional(i_prof.id,
                                                                          i_ref_row.id_inst_orig,
                                                                          i_prof.software));
    
        IF l_comments_available_dest = l_comments_available_orig
           AND l_comments_available_orig = pk_ref_constant.g_yes
           AND i_prof.institution IN (i_ref_row.id_inst_dest, i_ref_row.id_inst_orig)
        THEN
            IF i_id_ref_comment IS NULL
            THEN
                o_flg_valid := pk_ref_constant.g_yes;
            ELSE
                g_error := 'Open cursor c_check_prof / I_ID_REF_COMMENT' || i_id_ref_comment;
                OPEN c_check_prof(i_id_ref_comment);
                FETCH c_check_prof
                    INTO l_prof;
                IF l_prof = i_prof.id
                THEN
                    o_flg_valid := pk_ref_constant.g_yes;
                ELSE
                    o_flg_valid := pk_ref_constant.g_no;
                END IF;
                CLOSE c_check_prof;
            END IF;
        ELSE
            o_flg_valid := pk_ref_constant.g_no;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception_np THEN
            IF g_error_code IS NOT NULL
            THEN
                g_flg_action := pk_ref_constant.g_err_flg_action_u;
            ELSE
                g_error_code := SQLCODE;
                g_error_desc := SQLERRM;
                g_flg_action := pk_ref_constant.g_err_flg_action_s;
            END IF;
            pk_alert_exceptions.process_error(i_lang        => i_lang,
                                              i_sqlcode     => g_error_code,
                                              i_sqlerrm     => g_error_desc,
                                              i_message     => g_error,
                                              i_owner       => g_package_owner,
                                              i_package     => g_package_name,
                                              i_function    => 'CHECK_COMMENT_REQUIREMENTS',
                                              i_action_type => g_flg_action,
                                              i_action_msg  => NULL,
                                              o_error       => o_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            IF g_error_code IS NOT NULL
            THEN
                g_flg_action := pk_ref_constant.g_err_flg_action_u;
            ELSE
                g_error_code := SQLCODE;
                g_error_desc := SQLERRM;
                g_flg_action := pk_ref_constant.g_err_flg_action_s;
            END IF;
            pk_alert_exceptions.process_error(i_lang        => i_lang,
                                              i_sqlcode     => g_error_code,
                                              i_sqlerrm     => g_error_desc,
                                              i_message     => g_error,
                                              i_owner       => g_package_owner,
                                              i_package     => g_package_name,
                                              i_function    => 'CHECK_COMMENT_REQUIREMENTS',
                                              i_action_type => g_flg_action,
                                              i_action_msg  => NULL,
                                              o_error       => o_error);
        
            RETURN FALSE;
        
    END check_comment_requirements;

    /**
    * Crate new Referral comment
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Professional id, institution and software
    * @param   i_id_ref         Referral identifier
    * @param   i_text           Text comment
    * @param   i_dt_comment     Comment date 
    
    * @param   o_id_ref_comment Referral comment ids
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   25-07-2013
    **/

    FUNCTION create_ref_comment
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_ref         IN p1_external_request.id_external_request%TYPE,
        i_text           IN CLOB,
        i_dt_comment     IN ref_comments.dt_comment%TYPE,
        o_id_ref_comment OUT ref_comments.id_ref_comment%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_comments_available VARCHAR2(1 CHAR);
    
    BEGIN
        -- check if can create comment    
        g_error  := 'Call check_comment_requirements / i_id_ref' || i_id_ref;
        g_retval := check_comment_requirements(i_lang           => i_lang,
                                               i_prof           => i_prof,
                                               i_id_ref         => i_id_ref,
                                               i_id_ref_comment => NULL,
                                               o_flg_valid      => l_comments_available,
                                               o_error          => o_error);
        IF NOT g_retval
        THEN
            pk_alertlog.log_error(g_error);
            RAISE g_exception_np;
        END IF;
    
        IF l_comments_available = pk_ref_constant.g_yes
        THEN
            g_error  := 'Call pk_ref_core.create_ref_comment / I_ID_REF=' || i_id_ref;
            g_retval := pk_ref_core.create_ref_comment(i_lang           => i_lang,
                                                       i_prof           => i_prof,
                                                       i_id_ref         => i_id_ref,
                                                       i_text           => i_text,
                                                       i_dt_comment     => i_dt_comment,
                                                       o_id_ref_comment => o_id_ref_comment,
                                                       o_error          => o_error);
        
            IF NOT g_retval
            THEN
                pk_alertlog.log_error(g_error);
                RAISE g_exception_np;
            END IF;
        ELSE
            g_error := 'Can''t create comments for I_ID_REF=' || i_id_ref;
            pk_alertlog.log_error(g_error);
            RAISE g_exception_np;
        END IF;
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'CREATE_REF_COMMENT',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'CREATE_REF_COMMENT',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END create_ref_comment;

    /**
    * Cancel Referral comments
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Professional id, institution and software
    * @param   i_id_ref         Referral identifier
    * @param   i_id_ref_comment Referral comment id
    * @param   i_dt_cancel      Cancel Comment date 
    
    * @param   o_id_ref_comment Referral comment ids
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   05-07-2013
    **/
    FUNCTION cancel_ref_comment
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_ref         IN p1_external_request.id_external_request%TYPE,
        i_id_ref_comment IN ref_comments.id_ref_comment%TYPE,
        i_dt_cancel      IN ref_comments.dt_comment%TYPE,
        o_id_ref_comment OUT ref_comments.id_ref_comment%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_comments_available VARCHAR2(1 CHAR);
    
    BEGIN
        -- check if can cancel comment    
        g_error  := 'Call check_comment_requirements / i_id_ref' || i_id_ref || ', I_ID_REF_COMMENT=' ||
                    i_id_ref_comment;
        g_retval := check_comment_requirements(i_lang           => i_lang,
                                               i_prof           => i_prof,
                                               i_id_ref         => i_id_ref,
                                               i_id_ref_comment => i_id_ref_comment,
                                               o_flg_valid      => l_comments_available,
                                               o_error          => o_error);
        IF NOT g_retval
        THEN
            pk_alertlog.log_error(g_error);
            RAISE g_exception_np;
        END IF;
    
        IF l_comments_available = pk_ref_constant.g_yes
        THEN
            g_error  := 'Call pk_ref_core.cancel_ref_comment / I_ID_REF=' || i_id_ref || ', I_ID_REF_COMMENT=' ||
                        i_id_ref_comment;
            g_retval := pk_ref_core.cancel_ref_comment(i_lang           => i_lang,
                                                       i_prof           => i_prof,
                                                       i_id_ref         => i_id_ref,
                                                       i_id_ref_comment => i_id_ref_comment,
                                                       i_dt_cancel      => i_dt_cancel,
                                                       o_id_ref_comment => o_id_ref_comment,
                                                       o_error          => o_error);
        
            IF NOT g_retval
            THEN
                pk_alertlog.log_error(g_error);
                RAISE g_exception_np;
            END IF;
        ELSE
            g_error := 'Can''t cancel comment / I_ID_REF=' || i_id_ref || ', I_ID_REF_COMMENT=' || i_id_ref_comment;
            pk_alertlog.log_error(g_error);
            RAISE g_exception_np;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'CREATE_REF_COMMENT',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'CANCEL_REF_COMMENT',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END cancel_ref_comment;

    /**
    * Edit Referral comments
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Professional id, institution and software
    * @param   i_id_ref         Referral identifier
    * @param   i_text           Text comment
    * @param   i_id_ref_comment Referral comment id
    * @param   i_dt_edit        Edit comment date 
    
    * @param   o_id_ref_comment New Referral comment id
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   05-07-2013
    **/
    FUNCTION edit_ref_comment
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_ref         IN p1_external_request.id_external_request%TYPE,
        i_text           IN CLOB,
        i_id_ref_comment IN ref_comments.id_ref_comment%TYPE,
        i_dt_edit        IN ref_comments.dt_comment%TYPE,
        o_id_ref_comment OUT ref_comments.id_ref_comment%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_comments_available VARCHAR2(1 CHAR);
        l_id_ref_comment     table_number;
    
    BEGIN
        -- check if can edit comment    
        g_error  := 'Call check_comment_requirements / i_id_ref' || i_id_ref || ', I_ID_REF_COMMENT=' ||
                    i_id_ref_comment;
        g_retval := check_comment_requirements(i_lang           => i_lang,
                                               i_prof           => i_prof,
                                               i_id_ref         => i_id_ref,
                                               i_id_ref_comment => i_id_ref_comment,
                                               o_flg_valid      => l_comments_available,
                                               o_error          => o_error);
        IF NOT g_retval
        THEN
            pk_alertlog.log_error(g_error);
            RAISE g_exception_np;
        END IF;
    
        IF l_comments_available = pk_ref_constant.g_yes
        THEN
            g_error  := 'Call pk_ref_core.edit_ref_comment / I_ID_REF=' || i_id_ref || ', I_ID_REF_COMMENT=' ||
                        i_id_ref_comment;
            g_retval := pk_ref_core.edit_ref_comment(i_lang           => i_lang,
                                                     i_prof           => i_prof,
                                                     i_id_ref         => i_id_ref,
                                                     i_text           => i_text,
                                                     i_id_ref_comment => i_id_ref_comment,
                                                     i_dt_edit        => i_dt_edit,
                                                     o_id_ref_comment => l_id_ref_comment,
                                                     o_error          => o_error);
        
            IF NOT g_retval
            THEN
                pk_alertlog.log_error(g_error);
                RAISE g_exception_np;
            END IF;
            o_id_ref_comment := l_id_ref_comment(2);
        
        ELSE
            g_error := 'Can''t edit comment / I_ID_REF=' || i_id_ref || ', I_ID_REF_COMMENT=' || i_id_ref_comment;
            pk_alertlog.log_error(g_error);
            RAISE g_exception_np;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'CREATE_REF_COMMENT',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'EDIT_REF_COMMENT',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END edit_ref_comment;

BEGIN
    -- Log initialization.    
    g_package_name := pk_alertlog.who_am_i;
    pk_alertlog.log_init(g_package_name);

END pk_api_ref_ws;
/
