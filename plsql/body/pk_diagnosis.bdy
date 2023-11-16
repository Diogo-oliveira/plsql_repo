/*-- Last Change Revision: $Rev: 2047266 $*/
/*-- Last Change by: $Author: diogo.oliveira $*/
/*-- Date of last change: $Date: 2022-10-12 14:45:10 +0100 (qua, 12 out 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_diagnosis AS

    --PRIVATE PCK VARS
    g_code_msg_diag_final_t050 CONSTANT sys_message.code_message%TYPE := 'DIAGNOSIS_FINAL_T050';

    -- the code TABLE.COLUMN used for translations 
    diagnosis_domain_name         CONSTANT VARCHAR2(50) := 'DIAGNOSIS.CODE_DIAGNOSIS';
    diagnosis_domain_name_syn     CONSTANT VARCHAR2(50) := 'ALERT_DIAGNOSIS.CODE_ALERT_DIAGNOSIS';
    diagnosis_domain_name_concept CONSTANT VARCHAR2(50) := 'CONCEPT_TERM.CODE_CONCEPT_TERM';

    g_pck_owner VARCHAR2(32) := 'ALERT';
    g_pck_name  VARCHAR2(32) := 'PK_DIAGNOSIS';

    g_diagnosis_cause diagnosis.id_diagnosis%TYPE;
    g_desc_cause      pk_translation.t_desc_translation;
    g_code_cause      diagnosis.code_icd%TYPE;

    -- Private exceptions
    e_call_error EXCEPTION;

    /**********************************************************************************************
    * Get diagnosis description from an episode diagnosis
    *
    * @param i_lang                   the id language
    * @param i_epis_diagnosis         epis diagnosis to get diagnosis description
    *
    * @return                         diagnosis description
    *                        
    * @author                         Daniel Ferreira
    * @version                        1.0 
    * @since                          2014/10/09
    **********************************************************************************************/
    FUNCTION coding_get_diag_desc
    (
        i_lang            IN language.id_language%TYPE,
        i_diagnosis       IN diagnosis.id_diagnosis%TYPE,
        i_alert_diagnosis IN alert_diagnosis.id_alert_diagnosis%TYPE,
        i_desc_epis_diag  IN epis_diagnosis.desc_epis_diagnosis%TYPE
    ) RETURN VARCHAR2 IS
        l_desc VARCHAR2(1000 CHAR);
    BEGIN
        IF i_desc_epis_diag IS NOT NULL
        THEN
            l_desc := i_desc_epis_diag;
        ELSIF i_alert_diagnosis IS NOT NULL
        THEN
            SELECT pk_translation.get_translation(i_lang, ad.code_alert_diagnosis)
              INTO l_desc
              FROM alert_diagnosis ad
             WHERE ad.id_alert_diagnosis = i_alert_diagnosis;
        ELSIF i_diagnosis IS NOT NULL
        THEN
            SELECT pk_translation.get_translation(i_lang, d.code_diagnosis)
              INTO l_desc
              FROM diagnosis d
             WHERE d.id_diagnosis = i_diagnosis;
        END IF;
    
        RETURN l_desc;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END coding_get_diag_desc;

    FUNCTION coding_get_diag_desc
    (
        i_lang           IN language.id_language%TYPE,
        i_epis_diagnosis IN epis_diagnosis.id_epis_diagnosis%TYPE
    ) RETURN VARCHAR2 IS
        l_diagnosis       diagnosis.id_diagnosis%TYPE;
        l_alert_diagnosis alert_diagnosis.id_alert_diagnosis%TYPE;
        l_desc_epis_diag  epis_diagnosis.desc_epis_diagnosis%TYPE;
    BEGIN
        SELECT ed.id_diagnosis, ed.id_alert_diagnosis, ed.desc_epis_diagnosis
          INTO l_diagnosis, l_alert_diagnosis, l_desc_epis_diag
          FROM epis_diagnosis ed
         WHERE ed.id_epis_diagnosis = i_epis_diagnosis;
    
        RETURN coding_get_diag_desc(i_lang            => i_lang,
                                    i_diagnosis       => l_diagnosis,
                                    i_alert_diagnosis => l_alert_diagnosis,
                                    i_desc_epis_diag  => l_desc_epis_diag);
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END coding_get_diag_desc;

    /**********************************************************************************************
    * Obter os diagn�sticos +  frequentes de um prof. e do dep. + serv cl�nico a que est?associado (DIFERENCIAIS)
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids             
    * @param i_patient                patient id
    * @param i_epis                   episode id
    * @param o_diagnosis              array with diagnosis
    * @param o_epis_diagnosis         array with diagnosis of episode
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Emilia Taborda
    * @version                        1.0 
    * @since                          2006/10/10
    **********************************************************************************************/
    FUNCTION get_freq_diag_diff
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_patient        IN patient.id_patient%TYPE,
        i_epis           IN episode.id_episode%TYPE,
        o_diagnosis      OUT pk_types.cursor_type,
        o_epis_diagnosis OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_tbl_diags t_coll_diagnosis_config;
    BEGIN
        --
        IF g_diagnosis_type = pk_diagnosis.g_diag_type_x
        THEN
            g_error := 'OPEN o_diagnosis for uncoded diagnosis';
            IF NOT pk_diagnosis_core.get_freq_diag_cat(i_lang      => i_lang,
                                                       i_prof      => i_prof,
                                                       i_patient   => i_patient,
                                                       i_episode   => i_epis,
                                                       o_diagnosis => o_diagnosis,
                                                       o_error     => o_error)
            THEN
                RAISE e_call_error;
            END IF;
        ELSE
            g_error     := 'CALL PK_DIAGNOSIS_CORE.TF_GET_DIAG_CONFIGURATIONS';
            l_tbl_diags := pk_diagnosis_core.tf_get_diag_configurations(i_lang,
                                                                        i_prof,
                                                                        pk_diagnosis_core.g_filter_freq,
                                                                        i_patient,
                                                                        i_epis,
                                                                        g_diag_type_p);
        
            g_error := 'OPEN o_diagnosis for coded diagnosis';
            OPEN o_diagnosis FOR
                SELECT *
                  FROM TABLE(l_tbl_diags);
        END IF;
        --
        g_error := 'OPEN o_epis_diagnosis';
        OPEN o_epis_diagnosis FOR
            SELECT *
              FROM (SELECT d.id_diagnosis,
                           std_diag_desc(i_lang                => i_lang,
                                         i_prof                => i_prof,
                                         i_id_alert_diagnosis  => ad.id_alert_diagnosis,
                                         i_id_diagnosis        => d.id_diagnosis,
                                         i_desc_epis_diagnosis => ed.desc_epis_diagnosis,
                                         i_code                => d.code_icd,
                                         i_flg_other           => d.flg_other,
                                         i_flg_std_diag        => ad.flg_icd9,
                                         i_epis_diag           => ed.id_epis_diagnosis,
                                         i_show_aditional_info => pk_alert_constant.get_no) desc_diagnosis,
                           d.code_icd,
                           d.flg_other,
                           sd.rank,
                           ed.flg_status status_diagnosis,
                           sd.img_name icon_status,
                           ed.id_alert_diagnosis,
                           ed.id_epis_diagnosis,
                           pk_diagnosis_core.get_diag_type(i_lang         => i_lang,
                                                           i_prof         => i_prof,
                                                           i_concept_type => NULL,
                                                           i_diagnosis    => d.id_diagnosis) flg_diag_type
                      FROM epis_diagnosis ed, diagnosis d, sys_domain sd, alert_diagnosis ad
                     WHERE ed.id_diagnosis = d.id_diagnosis
                       AND ed.id_episode = i_epis
                       AND ed.id_alert_diagnosis = ad.id_alert_diagnosis(+)
                       AND ed.flg_type IN (g_diag_type_p, g_diag_type_b)
                       AND sd.val = ed.flg_status
                       AND sd.code_domain = g_epis_diag_status
                       AND sd.domain_owner = pk_sysdomain.k_default_schema
                       AND sd.id_language = i_lang
                       AND d.flg_type IN (SELECT dcea.flg_terminology
                                            FROM diagnosis_conf_ea dcea
                                           WHERE dcea.id_institution = i_prof.institution
                                             AND dcea.id_software = i_prof.software
                                             AND dcea.id_task_type = pk_alert_constant.g_task_diagnosis)
                       AND rownum > 0) -- dummy condition in order to prevent performance issues 
             WHERE desc_diagnosis IS NOT NULL
             ORDER BY rank NULLS LAST, desc_diagnosis;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_DIAGNOSIS',
                                              'GET_FREQ_DIAG_DIFF',
                                              o_error);
            pk_types.open_my_cursor(o_diagnosis);
            pk_types.open_my_cursor(o_epis_diagnosis);
            RETURN FALSE;
    END;
    --
    /**********************************************************************************************
    * Obter os diagn�sticos +  frequentes de um prof. e do dep. + serv cl�nico a que est?associado (FINAIS)
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids             
    * @param i_patient                patient id
    * @param i_epis                   episode id
    * @param o_diagnosis              array with diagnosis
    * @param o_epis_diagnosis         array with diagnosis of episode
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Emilia Taborda
    * @version                        1.0 
    * @since                          2006/10/10
    **********************************************************************************************/
    FUNCTION get_freq_diag_final
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_patient        IN patient.id_patient%TYPE,
        i_epis           IN episode.id_episode%TYPE,
        o_diagnosis      OUT pk_types.cursor_type,
        o_epis_diagnosis OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_tbl_diags t_coll_diagnosis_config;
    BEGIN
        g_error     := 'CALL PK_DIAGNOSIS_CORE.TF_GET_DIAG_CONFIGURATIONS';
        l_tbl_diags := pk_diagnosis_core.tf_get_diag_configurations(i_lang,
                                                                    i_prof,
                                                                    pk_diagnosis_core.g_filter_freq,
                                                                    i_patient,
                                                                    i_epis,
                                                                    g_diag_type_d);
        --        
        g_error := 'OPEN O_DIAGNOSIS';
        OPEN o_diagnosis FOR
            SELECT *
              FROM TABLE(l_tbl_diags);
    
        --
        g_error := 'OPEN O_EPIS_DIAGNOSIS';
        OPEN o_epis_diagnosis FOR
            SELECT *
              FROM (SELECT DISTINCT d.id_diagnosis,
                                    std_diag_desc(i_lang                => i_lang,
                                                  i_prof                => i_prof,
                                                  i_id_alert_diagnosis  => ad.id_alert_diagnosis,
                                                  i_id_diagnosis        => d.id_diagnosis,
                                                  i_desc_epis_diagnosis => ed.desc_epis_diagnosis,
                                                  i_code                => d.code_icd,
                                                  i_flg_other           => d.flg_other,
                                                  i_flg_std_diag        => ad.flg_icd9,
                                                  i_epis_diag           => ed.id_epis_diagnosis,
                                                  i_show_aditional_info => g_no) desc_diagnosis,
                                    d.code_icd,
                                    d.flg_other,
                                    sd.rank,
                                    ed.flg_status status_diagnosis,
                                    sd.img_name icon_status,
                                    ed.id_alert_diagnosis,
                                    ed.id_epis_diagnosis,
                                    pk_diagnosis_core.get_diag_type(i_lang         => i_lang,
                                                                    i_prof         => i_prof,
                                                                    i_concept_type => NULL,
                                                                    i_diagnosis    => d.id_diagnosis) flg_diag_type
                      FROM epis_diagnosis ed, diagnosis d, sys_domain sd, alert_diagnosis ad
                     WHERE ed.id_diagnosis = d.id_diagnosis
                       AND ed.id_episode = i_epis
                       AND ed.id_alert_diagnosis = ad.id_alert_diagnosis(+)
                       AND ed.flg_status = sd.val
                       AND ed.flg_type IN (g_diag_type_d, g_diag_type_b)
                       AND ed.flg_status IN (g_ed_flg_status_d, g_ed_flg_status_co, g_ed_flg_status_b)
                       AND sd.code_domain = g_epis_diag_status
                       AND sd.domain_owner = pk_sysdomain.k_default_schema
                       AND sd.id_language = i_lang
                       AND rownum > 0) -- dummy condition in order to prevent performance issues
             WHERE desc_diagnosis IS NOT NULL
             ORDER BY rank, desc_diagnosis;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_DIAGNOSIS',
                                              'GET_FREQ_DIAG_FINAL',
                                              o_error);
            pk_types.open_my_cursor(o_diagnosis);
            pk_types.open_my_cursor(o_epis_diagnosis);
            RETURN FALSE;
    END;
    --
    /**********************************************************************************************
    * Obter os diagn�sticos diferenciais(provis�rios) associados ao template da queixa(activa) do epis�dio
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids             
    * @param i_epis                   episode id
    * @param o_title                  Descri��o da queixa seleccionada                  
    * @param o_diagnosis              array with diagnosis
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Emilia Taborda
    * @version                        1.0 
    * @since                          2006/10/02
    **********************************************************************************************/
    FUNCTION get_complaint_diag_diff_list
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_epis      IN episode.id_episode%TYPE,
        o_title     OUT pk_types.cursor_type,
        o_diagnosis OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_complaint table_number;
        l_id_patient   patient.id_patient%TYPE;
        l_tbl_diags    t_coll_diagnosis_config;
    BEGIN
    
        g_error := 'GET_ACTIVE COMPLAINT';
        IF NOT pk_complaint.get_epis_act_complaint(i_lang         => i_lang,
                                                   i_prof         => i_prof,
                                                   i_episode      => i_epis,
                                                   o_id_complaint => l_id_complaint,
                                                   o_error        => o_error)
        THEN
            RAISE e_call_error;
        END IF;
    
        g_error      := 'GET PATIENT ID';
        l_id_patient := pk_episode.get_epis_patient(i_lang, i_prof, i_epis);
    
        --
        g_error := 'GET CURSOR O_TITLE(1)';
        OPEN o_title FOR
            SELECT pk_translation.get_translation(i_lang, code_complaint) desc_complaint
              FROM complaint
             WHERE id_complaint IN (SELECT /*+opt_estimate(table t rows=1)*/
                                     *
                                      FROM TABLE(l_id_complaint) t);
        -- 
        g_error     := 'CALL PK_DIAGNOSIS_CORE.TF_GET_DIAG_CONFIGURATIONS';
        l_tbl_diags := pk_diagnosis_core.tf_get_diag_configurations(i_lang,
                                                                    i_prof,
                                                                    pk_diagnosis_core.g_filter_complaint,
                                                                    l_id_patient,
                                                                    i_epis,
                                                                    g_diag_type_p,
                                                                    l_id_complaint);
    
        g_error := 'OPEN O_DIAGNOSIS (1)';
        OPEN o_diagnosis FOR
            SELECT *
              FROM TABLE(l_tbl_diags);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_DIAGNOSIS',
                                              'GET_COMPLAINT_DIAG_DIFF_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_diagnosis);
            pk_types.open_my_cursor(o_title);
            RETURN FALSE;
    END;
    --
    /**********************************************************************************************
    * Returns multichoice values for associated problem field
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids             
    * @param o_assoc_prob             Associated problem list
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Alexandre Santos
    * @version                        2.5.1.2
    * @since                          2010-10-27
    **********************************************************************************************/
    FUNCTION get_assoc_prob_lst_int
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        o_assoc_prob OUT pk_edis_types.cursor_assoc_prob,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'GET_ASSOC_PROB_LST_INT';
        --
        l_sys_cfg_assoc_prob CONSTANT sys_config.id_sys_config%TYPE := 'DIAGNOSIS_ASSOC_PROB_DEF_VAL';
        l_val_cfg_assoc_prob sys_config.value%TYPE;
    BEGIN
        g_error := 'GET CFG - ' || l_sys_cfg_assoc_prob;
        pk_alertlog.log_info(g_error);
        l_val_cfg_assoc_prob := pk_sysconfig.get_config(i_code_cf => l_sys_cfg_assoc_prob, i_prof => i_prof);
    
        g_error := 'GET CURSOR O_ASSOC_PROB';
        pk_alertlog.log_info(g_error);
        OPEN o_assoc_prob FOR
            SELECT sd.val data,
                   sd.desc_val label,
                   decode(sd.val, l_val_cfg_assoc_prob, pk_alert_constant.g_yes, pk_alert_constant.g_no) flg_default,
                   sd.val flg_default_diag_cancer
              FROM sys_domain sd
             WHERE id_language = i_lang
               AND sd.domain_owner = pk_sysdomain.k_default_schema
               AND code_domain = pk_diagnosis.g_code_domain_yes_no
             ORDER BY sd.rank, sd.desc_val;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_DIAGNOSIS',
                                              l_func_name,
                                              o_error);
            pk_edis_types.open_my_cursor(o_assoc_prob);
            RETURN FALSE;
    END get_assoc_prob_lst_int;
    --
    /**********************************************************************************************
    * Listar todos os estados / icones de cada estado dos diagn�sticos diferenciais
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids             
    * @param o_status                 array with status of differencial diagnosis
    * @param o_assoc_prob             Associated problem list
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Emilia Taborda
    * @version                        1.0 
    * @since                          2006/10/02
    **********************************************************************************************/
    FUNCTION get_epis_diag_status_list
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        o_status     OUT pk_types.cursor_type,
        o_assoc_prob OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_flg_type_diag sys_config.value%TYPE;
    BEGIN
        g_error         := 'GET CONFIGURATIONS';
        l_flg_type_diag := pk_sysconfig.get_config('FLG_TYPE_DIAG', i_prof);
        --
        IF l_flg_type_diag = g_diag_type_b
        THEN
            g_error := 'OPEN O_STATUS(1)';
            OPEN o_status FOR
                SELECT val, desc_val, img_name
                  FROM sys_domain
                 WHERE id_language = i_lang
                   AND code_domain = g_epis_diag_status
                   AND domain_owner = pk_sysdomain.k_default_schema
                   AND img_name IS NOT NULL
                   AND val <> g_ed_flg_status_ca
                 ORDER BY rank, desc_val;
        ELSE
            g_error := 'OPEN O_STATUS(2)';
            OPEN o_status FOR
                SELECT val, desc_val, img_name
                  FROM sys_domain
                 WHERE id_language = i_lang
                   AND code_domain = g_epis_diag_status
                   AND domain_owner = pk_sysdomain.k_default_schema
                   AND img_name IS NOT NULL
                   AND val NOT IN (g_diag_type_b, g_ed_flg_status_ca)
                 ORDER BY rank, desc_val;
        END IF;
    
        g_error := 'GET CURSOR O_ASSOC_PROB';
        pk_alertlog.log_info(g_error);
        IF NOT
            get_assoc_prob_lst_int(i_lang => i_lang, i_prof => i_prof, o_assoc_prob => o_assoc_prob, o_error => o_error)
        THEN
            RAISE e_call_exception;
        END IF;
    
        pk_backoffice_translation.set_read_translation(g_epis_diag_status, 'SYS_DOMAIN');
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_DIAGNOSIS',
                                              'GET_EPIS_DIAG_STATUS_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_status);
            RETURN FALSE;
    END;

    /**********************************************************************************************
    * Listar todos os diagn�sticos diferenciais provis�rios do epis�dio
    * Nota: Invocada exclusivamente pelo JAVA
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids             
    * @param i_epis                   episode id
    * @param i_prof_cat_type          categoty of professional
    * @param o_list                   Listar todos os diagn�sticos diferenciais provis�rios do epis�dio
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Emilia Taborda
    * @version                        1.0 
    * @since                          2006/10/05
    **********************************************************************************************/
    FUNCTION get_diag_diff_list
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_epis          IN episode.id_episode%TYPE,
        i_prof_cat_type IN category.flg_type%TYPE,
        o_list          OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'CALL get_diag_diff_list_internal';
        IF NOT pk_diagnosis_core.get_epis_diagnosis_list(i_lang     => i_lang,
                                                         i_prof     => i_prof,
                                                         i_episode  => i_epis,
                                                         i_flg_type => g_diag_type_p,
                                                         o_list     => o_list,
                                                         o_error    => o_error)
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
                                              'ALERT',
                                              'PK_DIAGNOSIS',
                                              'GET_DIAG_DIFF_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_diag_diff_list;

    /**********************************************************************************************
    * Listar todos os diagn�sticos diferenciais do paciente
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids             
    * @param i_patient                Patient ID
    * @param i_prof_cat_type          categoty of professional
    * @param o_list                   Listar todos os diagn�sticos diferenciais provis�rios do epis�dio
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Emilia Taborda
    * @version                        1.0 
    * @since                          2006/10/05
    **********************************************************************************************/
    FUNCTION get_diag_diff_pat_list
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_prof_cat_type IN category.flg_type%TYPE,
        o_list          OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_diag_diff_t016 sys_message.desc_message%TYPE;
    BEGIN
        g_error          := 'GET CONFIGURATIONS';
        l_diag_diff_t016 := pk_message.get_message(i_lang, 'DIAGNOSIS_DIFF_T016');
        --
        g_error := 'OPEN O_DIFFER';
        OPEN o_list FOR
            SELECT ed.id_epis_diagnosis,
                   d.id_diagnosis,
                   std_diag_desc(i_lang                => i_lang,
                                 i_prof                => i_prof,
                                 i_id_alert_diagnosis  => ad.id_alert_diagnosis,
                                 i_id_diagnosis        => d.id_diagnosis,
                                 i_desc_epis_diagnosis => ed.desc_epis_diagnosis,
                                 i_code                => d.code_icd,
                                 i_flg_other           => d.flg_other,
                                 i_flg_std_diag        => ad.flg_icd9) desc_diagnosis,
                   decode(ed.flg_status,
                          g_ed_flg_status_ca,
                          decode(ed.notes_cancel,
                                 NULL,
                                 decode(ed.id_epis_diagnosis_notes, NULL, NULL, l_diag_diff_t016),
                                 l_diag_diff_t016),
                          decode(ed.notes,
                                 NULL,
                                 decode(ed.id_epis_diagnosis_notes, NULL, NULL, l_diag_diff_t016),
                                 l_diag_diff_t016)) see_notes,
                   ed.flg_status status_diagnosis,
                   ed.id_professional_diag, --ampulheta
                   pk_prof_utils.get_name_signature(i_lang, i_prof, ed.id_professional_diag) prof_name_diag,
                   pk_date_utils.date_send_tsz(i_lang, ed.dt_epis_diagnosis_tstz, i_prof) date_diag,
                   pk_date_utils.dt_chr_tsz(i_lang, ed.dt_epis_diagnosis_tstz, i_prof) date_target_diag,
                   pk_date_utils.date_char_hour_tsz(i_lang,
                                                    ed.dt_epis_diagnosis_tstz,
                                                    i_prof.institution,
                                                    i_prof.software) hour_target_diag,
                   ed.id_prof_confirmed, --confirmado
                   pk_prof_utils.get_name_signature(i_lang, i_prof, ed.id_prof_confirmed) prof_name_conf,
                   pk_date_utils.date_send_tsz(i_lang, ed.dt_confirmed_tstz, i_prof) date_conf,
                   pk_date_utils.dt_chr_tsz(i_lang, ed.dt_confirmed_tstz, i_prof) date_target_conf,
                   pk_date_utils.date_char_hour_tsz(i_lang, ed.dt_confirmed_tstz, i_prof.institution, i_prof.software) hour_target_conf,
                   ed.id_professional_cancel, --cancelou
                   pk_prof_utils.get_name_signature(i_lang, i_prof, ed.id_professional_cancel) prof_name_cancel,
                   pk_date_utils.date_send_tsz(i_lang, ed.dt_cancel_tstz, i_prof) date_cancel,
                   pk_date_utils.dt_chr_tsz(i_lang, ed.dt_cancel_tstz, i_prof) date_target_cancel,
                   pk_date_utils.date_char_hour_tsz(i_lang, ed.dt_cancel_tstz, i_prof.institution, i_prof.software) hour_target_cancel,
                   ed.id_prof_rulled_out, -- declinou
                   pk_prof_utils.get_name_signature(i_lang, i_prof, ed.id_prof_rulled_out) prof_name_rulled_out,
                   pk_date_utils.date_send_tsz(i_lang, ed.dt_rulled_out_tstz, i_prof) date_rulled_out,
                   pk_date_utils.dt_chr_tsz(i_lang, ed.dt_rulled_out_tstz, i_prof) date_target_rulled,
                   pk_date_utils.date_char_hour_tsz(i_lang, ed.dt_rulled_out_tstz, i_prof.institution, i_prof.software) hour_target_rulled,
                   ed.id_prof_base, -- base
                   pk_prof_utils.get_name_signature(i_lang, i_prof, ed.id_prof_base) prof_name_base,
                   pk_date_utils.date_send_tsz(i_lang, ed.dt_base_tstz, i_prof) date_base,
                   pk_date_utils.dt_chr_tsz(i_lang, ed.dt_base_tstz, i_prof) date_target_base,
                   pk_date_utils.date_char_hour_tsz(i_lang, ed.dt_base_tstz, i_prof.institution, i_prof.software) hour_target_base,
                   sd.img_name icon_status,
                   sd.desc_val desc_status,
                   pk_date_utils.date_send_tsz(i_lang,
                                               pk_diagnosis_core.get_dt_diagnosis(i_lang,
                                                                                  i_prof,
                                                                                  ed.flg_status,
                                                                                  ed.dt_epis_diagnosis_tstz,
                                                                                  ed.dt_confirmed_tstz,
                                                                                  ed.dt_cancel_tstz,
                                                                                  ed.dt_base_tstz,
                                                                                  ed.dt_rulled_out_tstz),
                                               i_prof) date_order,
                   ed.notes,
                   ed.notes_cancel,
                   ed.id_cancel_reason, -- CMS:20090326:CCHIT;
                   pk_diagnosis_core.get_epis_diag_note(i_lang           => i_lang,
                                                        i_prof           => i_prof,
                                                        i_episode        => ed.id_episode,
                                                        i_epis_diag      => ed.id_epis_diagnosis,
                                                        i_epis_diag_hist => NULL) general_notes,
                   decode(ed.flg_status, g_ed_flg_status_ca, g_no, g_yes) avail_butt_cancel -- Bot�o cancelar(activo ou n�o)
              FROM epis_diagnosis ed, diagnosis d, sys_domain sd, episode e, alert_diagnosis ad
             WHERE e.id_patient = i_patient
               AND ed.id_episode = e.id_episode
               AND d.id_diagnosis = ed.id_diagnosis
               AND ad.id_alert_diagnosis(+) = ed.id_alert_diagnosis
               AND sd.id_language = i_lang
               AND sd.domain_owner = pk_sysdomain.k_default_schema
               AND sd.code_domain = g_epis_diag_status
               AND sd.val = ed.flg_status
             ORDER BY pk_sysdomain.get_rank(i_lang, g_epis_diag_status, ed.flg_status), date_order DESC;
    
        pk_backoffice_translation.set_read_translation(g_epis_diag_status, 'SYS_DOMAIN');
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_DIAGNOSIS',
                                              'GET_DIAG_DIFF_PAT_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END;

    --
    /**********************************************************************************************
    * Listar os diagn�sticos definitivos do epis�dio
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids             
    * @param i_epis                   episode id
    * @param i_prof_cat_type          categoty of professional
    * @param o_final                   Listar todos os diagn�sticos definitivos do epis�dio
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Emilia Taborda
    * @version                        1.0 
    * @since                          2006/10/06
    **********************************************************************************************/
    FUNCTION get_final_diagnosis
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_epis          IN episode.id_episode%TYPE,
        i_prof_cat_type IN category.flg_type%TYPE,
        o_final         OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_DIAGNOSIS.GET_FINAL_DIAGNOSIS_INTERNAL FUNCTION FOR ID_EPISODE: ' || i_epis;
        pk_alertlog.log_debug(g_error);
        IF NOT pk_diagnosis_core.get_epis_diagnosis_list(i_lang     => i_lang,
                                                         i_prof     => i_prof,
                                                         i_episode  => i_epis,
                                                         i_flg_type => g_diag_type_d,
                                                         o_list     => o_final,
                                                         o_error    => o_error)
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
                                              'ALERT',
                                              'PK_DIAGNOSIS',
                                              'GET_FINAL_DIAGNOSIS',
                                              o_error);
            pk_types.open_my_cursor(o_final);
            RETURN FALSE;
    END;

    FUNCTION get_count_final_diagnosis
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_epis          IN episode.id_episode%TYPE,
        i_prof_cat_type IN category.flg_type%TYPE,
        o_count         OUT NUMBER,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_DIAGNOSIS.GET_FINAL_DIAGNOSIS_INTERNAL FUNCTION FOR ID_EPISODE: ' || i_epis;
        pk_alertlog.log_debug(g_error);
        IF NOT pk_diagnosis_core.get_count_epis_diagnosis_list(i_lang     => i_lang,
                                                               i_prof     => i_prof,
                                                               i_episode  => i_epis,
                                                               i_flg_type => g_diag_type_d,
                                                               o_count    => o_count,
                                                               o_error    => o_error)
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
                                              'ALERT',
                                              'PK_DIAGNOSIS',
                                              'GET_FINAL_DIAGNOSIS',
                                              o_error);
            RETURN FALSE;
    END get_count_final_diagnosis;

    --
    /**********************************************************************************************
    * Listar os diagn�sticos diferenciais(provis�rios) confirmados e em despiste do epis�dio
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids             
    * @param i_epis                   episode id
    * @param o_title                  T�tulo com a queixa do epis�dio
    * @param o_differ                 Listar os diagn�sticos diferenciais(provis�rios) confirmados e em despiste do epis�dio
    * @param o_diag_complaint         Diagnosis associated with the current complaint                 
    * @param o_past_med_hist          Past medical history
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Emilia Taborda
    * @version                        1.0 
    * @since                          2006/10/06
    **********************************************************************************************/
    FUNCTION get_diag_differential
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_epis           IN episode.id_episode%TYPE,
        o_title          OUT pk_types.cursor_type,
        o_differ         OUT pk_types.cursor_type,
        o_diag_complaint OUT pk_types.cursor_type,
        o_past_med_hist  OUT pk_summary_page.doc_area_val_past_med_cur,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_complaint table_number;
        l_char      VARCHAR2(1);
        --    
        CURSOR c_epis_diag IS
            SELECT 'X'
              FROM epis_diagnosis ed1
             WHERE ed1.flg_type = g_diag_type_p
               AND ed1.flg_status IN (g_ed_flg_status_co, g_ed_flg_status_d, g_ed_flg_status_b)
               AND ed1.id_episode = i_epis;
    
        l_doc_area_register pk_types.cursor_type;
        l_id_patient        patient.id_patient%TYPE;
        l_tbl_diags         t_coll_diagnosis_config;
    BEGIN
        --
        g_error := 'GET CURSOR C_EPIS_DIAG';
        OPEN c_epis_diag;
        FETCH c_epis_diag
            INTO l_char;
        g_found := c_epis_diag%FOUND;
        CLOSE c_epis_diag;
        --
        IF g_found
        THEN
            g_error := 'OPEN O_DIFFER(1)';
            OPEN o_differ FOR
                SELECT *
                  FROM (SELECT DISTINCT d.id_diagnosis,
                                        std_diag_desc(i_lang                => i_lang,
                                                      i_prof                => i_prof,
                                                      i_id_alert_diagnosis  => ad.id_alert_diagnosis,
                                                      i_id_diagnosis        => d.id_diagnosis,
                                                      i_desc_epis_diagnosis => ed.desc_epis_diagnosis,
                                                      i_code                => d.code_icd,
                                                      i_flg_other           => d.flg_other,
                                                      i_flg_std_diag        => ad.flg_icd9,
                                                      i_epis_diag           => ed.id_epis_diagnosis,
                                                      i_show_aditional_info => g_no) desc_diagnosis,
                                        d.code_icd,
                                        d.flg_other,
                                        sd.rank,
                                        ed.flg_status status_diagnosis,
                                        sd.img_name icon_status,
                                        g_yes avail_for_select,
                                        ed.flg_status default_new_status,
                                        sd.desc_val default_new_status_desc,
                                        ed.id_alert_diagnosis,
                                        ed.id_epis_diagnosis,
                                        pk_diagnosis_core.get_diag_type(i_lang         => i_lang,
                                                                        i_prof         => i_prof,
                                                                        i_concept_type => NULL,
                                                                        i_diagnosis    => d.id_diagnosis) flg_diag_type
                          FROM diagnosis d
                          JOIN epis_diagnosis ed
                            ON ed.id_diagnosis = d.id_diagnosis
                           AND ed.flg_type = g_diag_type_p
                           AND ed.flg_status IN (g_ed_flg_status_co, g_ed_flg_status_d)
                          JOIN sys_domain sd
                            ON sd.val = ed.flg_status
                           AND sd.id_language = i_lang
                           AND sd.domain_owner = pk_sysdomain.k_default_schema
                           AND sd.code_domain = g_epis_diag_status
                          LEFT JOIN alert_diagnosis ad
                            ON ad.id_alert_diagnosis = ed.id_alert_diagnosis
                         WHERE ed.id_episode = i_epis
                           AND (ed.id_diagnosis, ed.id_diagnosis_condition, ed.id_sub_analysis, ed.id_anatomical_area,
                                ed.id_anatomical_side) NOT IN
                               (SELECT ed1.id_diagnosis,
                                       ed1.id_diagnosis_condition,
                                       ed1.id_sub_analysis,
                                       ed1.id_anatomical_area,
                                       ed1.id_anatomical_side
                                  FROM epis_diagnosis ed1
                                 WHERE ed1.flg_type = g_diag_type_d
                                   AND ed1.flg_status IN (g_ed_flg_status_co, g_ed_flg_status_d)
                                   AND ed1.id_episode = i_epis)
                           AND d.flg_type IN
                               (SELECT dcea.flg_terminology
                                  FROM diagnosis_conf_ea dcea
                                 WHERE dcea.id_institution = i_prof.institution
                                   AND dcea.id_software = i_prof.software
                                   AND dcea.id_task_type = pk_alert_constant.g_task_diagnosis)
                           AND rownum > 0) -- dummy condition in order to prevent performance issues
                 WHERE desc_diagnosis IS NOT NULL
                 ORDER BY rank, desc_diagnosis;
            pk_backoffice_translation.set_read_translation(g_epis_diag_status, 'SYS_DOMAIN');
        ELSE
            pk_types.open_my_cursor(o_differ);
        END IF;
    
        g_error := 'GET_ACTIVE COMPLAINT';
        IF NOT pk_complaint.get_epis_act_complaint(i_lang         => i_lang,
                                                   i_prof         => i_prof,
                                                   i_episode      => i_epis,
                                                   o_id_complaint => l_complaint,
                                                   o_error        => o_error)
        THEN
            RAISE e_call_error;
        END IF;
    
        g_error      := 'GET PATIENT ID';
        l_id_patient := pk_episode.get_epis_patient(i_lang, i_prof, i_epis);
    
        g_error     := 'CALL PK_DIAGNOSIS_CORE.TF_GET_DIAG_CONFIGURATIONS';
        l_tbl_diags := pk_diagnosis_core.tf_get_diag_configurations(i_lang,
                                                                    i_prof,
                                                                    pk_diagnosis_core.g_filter_complaint,
                                                                    l_id_patient,
                                                                    i_epis,
                                                                    NULL,
                                                                    l_complaint);
    
        g_error := 'OPEN O_DIFFER(2)';
        OPEN o_diag_complaint FOR
            SELECT *
              FROM TABLE(l_tbl_diags)
             WHERE id_epis_diagnosis IS NOT NULL
                OR id_diagnosis NOT IN (SELECT id_diagnosis
                                          FROM epis_diagnosis ed1
                                         WHERE ed1.flg_type = g_diag_type_d
                                           AND ed1.flg_status != g_ed_flg_status_ca
                                           AND ed1.id_episode = i_epis);
        --
        g_error := 'OPEN O_TITLE';
        OPEN o_title FOR
            SELECT pk_translation.get_translation(i_lang, code_complaint) desc_complaint
              FROM complaint
             WHERE id_complaint IN (SELECT /*+opt_estimate(table t rows=1)*/
                                     *
                                      FROM TABLE(l_complaint) t);
    
        g_error := 'GET_PAST_HIST_MEDICAL';
        alertlog.pk_alertlog.log_info(text => g_error);
        IF NOT pk_past_history_api.get_past_hist_medical(i_lang              => i_lang,
                                                         i_prof              => i_prof,
                                                         i_current_episode   => i_epis,
                                                         i_scope             => l_id_patient,
                                                         i_scope_type        => pk_alert_constant.g_scope_type_patient,
                                                         i_flg_diag_call     => pk_alert_constant.g_yes,
                                                         o_doc_area_register => l_doc_area_register,
                                                         o_doc_area_val      => o_past_med_hist,
                                                         o_error             => o_error)
        THEN
            RAISE e_call_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_DIAGNOSIS',
                                              'GET_DIAG_DIFFERENTIAL',
                                              o_error);
            pk_types.open_my_cursor(o_title);
            pk_types.open_my_cursor(o_differ);
            pk_types.open_my_cursor(o_diag_complaint);
            pk_types.open_my_cursor(o_past_med_hist);
            RETURN FALSE;
    END;
    --
    /********************************************************************************************
    * Get home table function 
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_epis                 episode identifier
    *
    * @return                         pipelined table
    *                        
    * @author                          Paulo teixeira
    * @version                         0.1
    * @since                           2011/08/30
    **********************************************************************************************/
    FUNCTION get_associated_diagnosis_tf
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_epis                   IN episode.id_episode%TYPE,
        i_flg_terminology_server IN VARCHAR2 DEFAULT pk_alert_constant.g_no
    ) RETURN t_coll_diagnosis_config IS
        l_diag_config     sys_config.id_sys_config%TYPE := pk_sysconfig.get_config('SHOW_PAST_DIAGNOSES', i_prof);
        l_other_diagnosis sys_config.value%TYPE := pk_sysconfig.get_config('PERMISSION_FOR_OTHER_DIAGNOSIS', i_prof);
        --
        l_tbl_current_diags_cnt t_coll_diagnosis_config;
        l_tbl_diags             table_number;
        l_tbl_adiags            table_number;
        l_patient               patient.id_patient%TYPE;
        --
        l_tbl_ret t_coll_diagnosis_config;
    BEGIN
        g_error := 'GET TBL DIAGS AND ALERT_DIAGS';
        pk_alertlog.log_debug(g_error);
        l_patient := pk_episode.get_id_patient(i_epis);
    
        g_error := 'GET TBL DIAGS AND ALERT_DIAGS';
        pk_alertlog.log_debug(g_error);
        SELECT id_diagnosis, id_alert_diagnosis
          BULK COLLECT
          INTO l_tbl_diags, l_tbl_adiags
          FROM (SELECT d.id_diagnosis,
                       nvl(ed.id_alert_diagnosis,
                           pk_api_pfh_diagnosis_in.get_diag_preferred_term_id(i_concept_version => d.id_diagnosis)) id_alert_diagnosis
                  FROM epis_diagnosis ed
                  JOIN diagnosis d
                    ON d.id_diagnosis = ed.id_diagnosis
                 WHERE ed.id_episode = i_epis
                   AND ed.flg_status NOT IN
                       (pk_alert_constant.g_epis_diag_flg_status_c, pk_alert_constant.g_epis_diag_flg_status_r)
                   AND ((l_other_diagnosis = g_yes) OR
                       ((l_other_diagnosis = g_no) AND (nvl(d.flg_other, g_yes) != g_yes)))
                   AND (ed.flg_type = pk_alert_constant.g_epis_diag_flg_type_d OR NOT EXISTS
                        (SELECT 1
                           FROM epis_diagnosis ed1
                          WHERE ed1.id_episode = i_epis
                            AND ed1.id_diagnosis = ed.id_diagnosis
                            AND ed1.flg_type = pk_alert_constant.g_epis_diag_flg_type_d))
                UNION
                SELECT d.id_diagnosis,
                       nvl(ad.id_alert_diagnosis,
                           pk_api_pfh_diagnosis_in.get_diag_preferred_term_id(i_concept_version => d.id_diagnosis)) id_alert_diagnosis
                  FROM pat_history_diagnosis phd
                  LEFT JOIN alert_diagnosis ad
                    ON ad.id_alert_diagnosis = phd.id_alert_diagnosis
                  LEFT JOIN diagnosis d
                    ON d.id_diagnosis = ad.id_diagnosis
                 WHERE l_diag_config = g_yes
                   AND phd.id_patient = l_patient
                   AND phd.id_alert_diagnosis NOT IN
                       (pk_summary_page.g_diag_unknown, pk_summary_page.g_diag_none, pk_past_history.g_diag_non_remark)
                   AND phd.flg_type = pk_summary_page.g_alert_diag_type_med
                   AND phd.flg_status != pk_alert_constant.g_cancelled
                   AND phd.id_pat_history_diagnosis_new IS NULL -- GS 09022011 - Condition to exclude outdated records
                ) x;
    
        IF l_tbl_diags.count > 0
           OR l_tbl_adiags.count > 0
        THEN
            g_error := 'CALL PK_DIAGNOSIS_CORE.TF_DIAGNOSES_LIST';
            pk_alertlog.log_debug(g_error);
            l_tbl_current_diags_cnt := pk_terminology_search.tf_diagnoses_list(i_lang                     => i_lang,
                                                                               i_prof                     => i_prof,
                                                                               i_patient                  => l_patient,
                                                                               i_terminologies_task_types => table_number(pk_alert_constant.g_task_diagnosis),
                                                                               i_term_task_type           => pk_alert_constant.g_task_diagnosis,
                                                                               i_list_type                => pk_diagnosis_core.g_diag_list_searchable,
                                                                               i_include_other_diagnosis  => l_other_diagnosis,
                                                                               i_tbl_diagnosis            => l_tbl_diags,
                                                                               i_tbl_alert_diagnosis      => l_tbl_adiags);
        ELSE
            l_tbl_current_diags_cnt := t_coll_diagnosis_config();
        END IF;
    
        SELECT t_rec_diagnosis_config(id_diagnosis            => t.id_diagnosis,
                                       id_diagnosis_parent     => NULL,
                                       id_epis_diagnosis       => NULL,
                                       desc_diagnosis          => CASE
                                                                      WHEN i_flg_terminology_server = pk_alert_constant.g_no
                                                                           OR t.flg_other = pk_alert_constant.g_yes THEN
                                                                       coalesce(t.desc_epis_diagnosis,
                                                                                t.desc_diagnosis,
                                                                                pk_diagnosis.std_diag_desc(i_lang                => i_lang,
                                                                                                           i_prof                => i_prof,
                                                                                                           i_id_alert_diagnosis  => t.id_alert_diagnosis,
                                                                                                           i_id_diagnosis        => t.id_diagnosis,
                                                                                                           i_desc_epis_diagnosis => t.desc_epis_diagnosis,
                                                                                                           i_code                => t.code_icd,
                                                                                                           i_flg_other           => t.flg_other,
                                                                                                           i_flg_std_diag        => t.flg_std_diag))
                                                                      ELSE
                                                                       coalesce(pk_ts3_search.get_term_description(i_id_language     => i_lang,
                                                                                                                   i_id_institution  => i_prof.institution,
                                                                                                                   i_id_software     => i_prof.software,
                                                                                                                   i_id_concept_term => t.id_alert_diagnosis,
                                                                                                                   i_concept_type    => 'DIAGNOSIS',
                                                                                                                   i_id_task_type    => pk_alert_constant.g_task_diagnosis),
                                                                                
                                                                                t.desc_epis_diagnosis,
                                                                                t.desc_diagnosis)
                                                                  END,
                                       code_icd                => t.code_icd,
                                       flg_other               => t.flg_other,
                                       status_diagnosis        => NULL,
                                       icon_status             => NULL,
                                       avail_for_select        => NULL,
                                       default_new_status      => NULL,
                                       default_new_status_desc => NULL,
                                       id_alert_diagnosis      => t.id_alert_diagnosis,
                                       desc_epis_diagnosis     => NULL,
                                       flg_terminology         => NULL)
          BULK COLLECT
          INTO l_tbl_ret
          FROM (SELECT ed.id_diagnosis,
                       ed.desc_epis_diagnosis,
                       d.desc_diagnosis,
                       ad.flg_icd9 flg_std_diag,
                       d.code_icd,
                       d.flg_other,
                       d.id_alert_diagnosis,
                       ed.id_epis_diagnosis
                  FROM epis_diagnosis ed
                  JOIN TABLE(l_tbl_current_diags_cnt) d
                    ON (d.id_diagnosis = ed.id_diagnosis OR d.id_diagnosis IS NULL)
                   AND d.id_alert_diagnosis =
                       nvl(ed.id_alert_diagnosis,
                           pk_api_pfh_diagnosis_in.get_diag_preferred_term_id(i_concept_version => ed.id_diagnosis))
                  JOIN alert_diagnosis ad
                    ON ad.id_alert_diagnosis = d.id_alert_diagnosis
                 WHERE ed.id_episode = i_epis
                   AND ed.flg_status NOT IN
                       (pk_alert_constant.g_epis_diag_flg_status_c, pk_alert_constant.g_epis_diag_flg_status_r)
                   AND ((l_other_diagnosis = g_yes) OR
                       ((l_other_diagnosis = g_no) AND (nvl(d.flg_other, g_yes) != g_yes)))
                   AND (ed.flg_type = pk_alert_constant.g_epis_diag_flg_type_d OR NOT EXISTS
                        (SELECT 1
                           FROM epis_diagnosis ed1
                          WHERE ed1.id_episode = i_epis
                            AND ed1.id_diagnosis = ed.id_diagnosis
                            AND ed1.flg_type = pk_alert_constant.g_epis_diag_flg_type_d))
                UNION
                SELECT phd.id_diagnosis,
                       NULL                 desc_epis_diagnosis,
                       d.desc_diagnosis,
                       ad.flg_icd9          flg_std_diag,
                       d.code_icd,
                       d.flg_other,
                       d.id_alert_diagnosis,
                       NULL                 id_epis_diagnosis
                  FROM pat_history_diagnosis phd
                  JOIN TABLE(l_tbl_current_diags_cnt) d
                    ON (d.id_diagnosis = phd.id_diagnosis OR d.id_diagnosis IS NULL)
                   AND d.id_alert_diagnosis =
                       nvl(phd.id_alert_diagnosis,
                           pk_api_pfh_diagnosis_in.get_diag_preferred_term_id(i_concept_version => phd.id_diagnosis))
                  JOIN alert_diagnosis ad
                    ON ad.id_alert_diagnosis = d.id_alert_diagnosis
                 WHERE l_diag_config = g_yes
                   AND phd.id_patient = l_patient
                   AND phd.id_alert_diagnosis NOT IN
                       (pk_summary_page.g_diag_unknown, pk_summary_page.g_diag_none, pk_past_history.g_diag_non_remark)
                   AND phd.flg_type = pk_summary_page.g_alert_diag_type_med
                   AND phd.flg_status != pk_alert_constant.g_cancelled
                   AND phd.id_pat_history_diagnosis_new IS NULL -- GS 09022011 - Condition to exclude outdated records
                   AND NOT EXISTS
                 (SELECT 1
                          FROM epis_diagnosis ed1
                         WHERE ed1.id_episode = i_epis
                           AND ed1.id_diagnosis = phd.id_diagnosis
                           AND ed1.id_alert_diagnosis = phd.id_alert_diagnosis
                           AND ed1.flg_status NOT IN
                               (pk_alert_constant.g_epis_diag_flg_status_c, pk_alert_constant.g_epis_diag_flg_status_r)
                           AND ((l_other_diagnosis = g_yes) OR
                               ((l_other_diagnosis = g_no) AND (nvl(d.flg_other, g_yes) != g_yes))))) t
         ORDER BY desc_diagnosis;
    
        RETURN l_tbl_ret;
    END get_associated_diagnosis_tf;
    --
    FUNCTION get_associated_diagnosis
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_epis   IN episode.id_episode%TYPE,
        o_differ OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:
           PARAMETROS:  Entrada: I_LANG - L�ngua registada como prefer�ncia DO profissional
                   I_PROF - ID DO profissional
                                 I_EPIS - ID DO epis�dio
        
                  Saida: O_DIFFER - Listar os diagn�sticos diferenciais (provis�rios) confirmados e em despiste do epis�dio
                 O_ERROR - erro
        
          CRIA��O: ASM 2007/01/19
        *********************************************************************************/
        l_tbl t_coll_diagnosis_config;
    BEGIN
        l_tbl := pk_diagnosis.get_associated_diagnosis_tf(i_lang, i_prof, i_epis);
    
        g_error := 'GET CURSOR O_DIFFER';
        OPEN o_differ FOR
            SELECT /*+opt_estimate (table t rows=0.000001)*/
             t.id_diagnosis, t.desc_diagnosis, t.code_icd, t.id_alert_diagnosis
              FROM TABLE(l_tbl) t;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_DIAGNOSIS',
                                              'GET_ASSOCIATED_DIAGNOSIS',
                                              o_error);
            pk_types.open_my_cursor(o_differ);
            RETURN FALSE;
    END;

    FUNCTION set_mcdt_req_diagnosis
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_epis             IN episode.id_episode%TYPE,
        i_diag             IN table_number,
        i_desc_diagnosis   IN table_varchar, --ET 2007/04/20
        i_exam_req         IN exam_req.id_exam_req%TYPE,
        i_analysis_req     IN analysis_req.id_analysis_req%TYPE,
        i_interv_presc     IN interv_prescription.id_interv_prescription%TYPE,
        i_exam_req_det     IN exam_req_det.id_exam_req_det%TYPE,
        i_analysis_req_det IN analysis_req_det.id_analysis_req_det%TYPE,
        i_interv_presc_det IN interv_presc_det.id_interv_presc_det%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Registar as associa��es de diagn�sticos a an�lises, exames, procedimentos, etc...
           PARAMETROS:  Entrada: I_LANG - L�ngua registada como prefer�ncia DO profissional
                   I_PROF - ID do profissional
                                 I_EPIS - ID do epis�dio
                                 I_DIAG - ID do diagn�stico
                                 I_EXAM_REQ - ID da requisi��o do exame
                                 I_ANALYSIS_REQ - ID da requisi��o de an�lise
                                 I_INTERV_PRESC - ID da requisi��o de procedimento
                                 I_DRUG_PRESC - ID da prescri��o do medicamento
                                 I_DRUG_REQ - ID da prescri��o do medicamento
                                 I_PRESCRIPTION - ID da prescri��o do medicamento
                                 I_PRESCRIPTION_USA - ID da prescri��o do medicamento (AINDA N EST?A SER TRATADO)
        
                  Saida: O_ERROR - erro
        
          CRIA��O: ASM 2007/01/19
          ALTERA��O: SS 2007/02/08 - Altera��o dos par�metros de entrada; em vez de ser o ID do detalhe ?o ID da requisi��o
          NOTAS:
        *********************************************************************************/
    BEGIN
    
        IF NOT set_mcdt_req_diag_no_commit(i_lang             => i_lang,
                                           i_prof             => i_prof,
                                           i_epis             => i_epis,
                                           i_diag             => i_diag,
                                           i_desc_diagnosis   => i_desc_diagnosis,
                                           i_exam_req         => i_exam_req,
                                           i_analysis_req     => i_analysis_req,
                                           i_interv_presc     => i_interv_presc,
                                           i_exam_req_det     => i_exam_req_det,
                                           i_analysis_req_det => i_analysis_req_det,
                                           i_interv_presc_det => i_interv_presc_det,
                                           o_error            => o_error)
        THEN
            RAISE e_call_exception;
        END IF;
    
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_DIAGNOSIS',
                                              'SET_MCDT_REQ_DIAGNOSIS',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END;

    FUNCTION set_mcdt_req_diag_no_commit
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_epis              IN episode.id_episode%TYPE,
        i_diag              IN table_number,
        i_desc_diagnosis    IN table_varchar, --ET 2007/04/20
        i_exam_req          IN exam_req.id_exam_req%TYPE,
        i_analysis_req      IN analysis_req.id_analysis_req%TYPE,
        i_interv_presc      IN interv_prescription.id_interv_prescription%TYPE,
        i_exam_req_det      IN exam_req_det.id_exam_req_det%TYPE,
        i_analysis_req_det  IN analysis_req_det.id_analysis_req_det%TYPE,
        i_interv_presc_det  IN interv_presc_det.id_interv_presc_det%TYPE,
        i_epis_complication IN epis_complication.id_epis_complication%TYPE DEFAULT NULL,
        i_epis_comp_hist    IN epis_comp_hist.id_epis_comp_hist%TYPE DEFAULT NULL,
        i_nurse_tea_req     IN nurse_tea_req.id_nurse_tea_req%TYPE DEFAULT NULL,
        i_exam_result       IN mcdt_req_diagnosis.id_exam_result%TYPE DEFAULT NULL,
        i_epis_diag_status  IN epis_diagnosis.flg_status%TYPE DEFAULT g_ed_flg_status_d,
        i_rehab_presc       IN rehab_presc.id_rehab_presc%TYPE DEFAULT NULL,
        i_rehab_presc_hist  IN rehab_presc_hist.id_rehab_presc_hist%TYPE DEFAULT NULL,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Registar as associa��es de diagn�sticos a an�lises, exames, procedimentos, etc...
           PARAMETROS:  Entrada: I_LANG - L�ngua registada como prefer�ncia DO profissional
                   I_PROF - ID do profissional
                                 I_EPIS - ID do epis�dio
                                 I_DIAG - ID do diagn�stico
                                 I_EXAM_REQ - ID da requisi��o do exame
                                 I_ANALYSIS_REQ - ID da requisi��o de an�lise
                                 I_INTERV_PRESC - ID da requisi��o de procedimento
                                 I_DRUG_PRESC - ID da prescri��o do medicamento
                                 I_DRUG_REQ - ID da prescri��o do medicamento
                                 I_PRESCRIPTION - ID da prescri��o do medicamento
                                 I_PRESCRIPTION_USA - ID da prescri��o do medicamento (AINDA N EST?A SER TRATADO)
        
                  Saida: O_ERROR - erro
        
          CRIA��O: ASM 2007/01/19
          ALTERA��O: SS 2007/02/08 - Altera��o dos par�metros de entrada; em vez de ser o ID do detalhe ?o ID da requisi��o
          NOTAS:
        *********************************************************************************/
    
        l_diag pk_edis_types.rec_in_epis_diagnosis;
    
        l_ex_create_diag EXCEPTION;
    BEGIN
        l_diag := pk_diagnosis.get_diag_rec(i_lang      => i_lang,
                                            i_prof      => i_prof,
                                            i_patient   => NULL,
                                            i_episode   => i_epis,
                                            i_diagnosis => i_diag,
                                            i_desc_diag => i_desc_diagnosis);
    
        IF NOT pk_diagnosis.set_mcdt_req_diag_no_commit(i_lang              => i_lang,
                                                        i_prof              => i_prof,
                                                        i_epis              => i_epis,
                                                        i_diag              => l_diag,
                                                        i_exam_req          => i_exam_req,
                                                        i_analysis_req      => i_analysis_req,
                                                        i_interv_presc      => i_interv_presc,
                                                        i_exam_req_det      => i_exam_req_det,
                                                        i_analysis_req_det  => i_analysis_req_det,
                                                        i_interv_presc_det  => i_interv_presc_det,
                                                        i_epis_complication => i_epis_complication,
                                                        i_epis_comp_hist    => i_epis_comp_hist,
                                                        i_nurse_tea_req     => i_nurse_tea_req,
                                                        i_exam_result       => i_exam_result,
                                                        i_epis_diag_status  => i_epis_diag_status,
                                                        i_rehab_presc       => i_rehab_presc,
                                                        i_rehab_presc_hist  => i_rehab_presc_hist,
                                                        o_error             => o_error)
        THEN
            RAISE l_ex_create_diag;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_ex_create_diag THEN
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_DIAGNOSIS',
                                              'SET_MCDT_REQ_DIAG_NO_COMMIT',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END;

    FUNCTION set_mcdt_req_diag_no_commit
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_epis              IN episode.id_episode%TYPE,
        i_diag              IN CLOB,
        i_exam_req          IN exam_req.id_exam_req%TYPE,
        i_analysis_req      IN analysis_req.id_analysis_req%TYPE,
        i_interv_presc      IN interv_prescription.id_interv_prescription%TYPE,
        i_exam_req_det      IN exam_req_det.id_exam_req_det%TYPE,
        i_analysis_req_det  IN analysis_req_det.id_analysis_req_det%TYPE,
        i_interv_presc_det  IN interv_presc_det.id_interv_presc_det%TYPE,
        i_epis_complication IN epis_complication.id_epis_complication%TYPE DEFAULT NULL,
        i_epis_comp_hist    IN epis_comp_hist.id_epis_comp_hist%TYPE DEFAULT NULL,
        i_nurse_tea_req     IN nurse_tea_req.id_nurse_tea_req%TYPE DEFAULT NULL,
        i_exam_result       IN mcdt_req_diagnosis.id_exam_result%TYPE DEFAULT NULL,
        i_epis_diag_status  IN epis_diagnosis.flg_status%TYPE DEFAULT g_ed_flg_status_d,
        i_rehab_presc       IN rehab_presc.id_rehab_presc%TYPE DEFAULT NULL,
        i_rehab_presc_hist  IN rehab_presc_hist.id_rehab_presc_hist%TYPE DEFAULT NULL,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_diagnoses pk_edis_types.rec_in_epis_diagnoses;
        --
        l_exception EXCEPTION;
    BEGIN
        IF NOT pk_diagnosis_form.get_save_parameters(i_lang                  => i_lang,
                                                     i_prof                  => i_prof,
                                                     i_params                => i_diag,
                                                     o_rec_in_epis_diagnoses => l_diagnoses,
                                                     o_error                 => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        RETURN set_mcdt_req_diag_no_commit(i_lang              => i_lang,
                                           i_prof              => i_prof,
                                           i_epis              => i_epis,
                                           i_diag              => l_diagnoses.epis_diagnosis,
                                           i_exam_req          => i_exam_req,
                                           i_analysis_req      => i_analysis_req,
                                           i_interv_presc      => i_interv_presc,
                                           i_exam_req_det      => i_exam_req_det,
                                           i_analysis_req_det  => i_analysis_req_det,
                                           i_interv_presc_det  => i_interv_presc_det,
                                           i_epis_complication => NULL,
                                           i_epis_comp_hist    => NULL,
                                           i_nurse_tea_req     => i_nurse_tea_req,
                                           i_exam_result       => i_exam_result,
                                           i_epis_diag_status  => i_epis_diag_status,
                                           i_rehab_presc       => i_rehab_presc,
                                           i_rehab_presc_hist  => i_rehab_presc_hist,
                                           o_error             => o_error);
    
    EXCEPTION
        WHEN l_exception THEN
            RETURN FALSE;
    END set_mcdt_req_diag_no_commit;

    FUNCTION set_mcdt_req_diag_no_commit
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_epis              IN episode.id_episode%TYPE,
        i_diag              IN pk_edis_types.rec_in_epis_diagnosis,
        i_exam_req          IN exam_req.id_exam_req%TYPE,
        i_analysis_req      IN analysis_req.id_analysis_req%TYPE,
        i_interv_presc      IN interv_prescription.id_interv_prescription%TYPE,
        i_exam_req_det      IN exam_req_det.id_exam_req_det%TYPE,
        i_analysis_req_det  IN analysis_req_det.id_analysis_req_det%TYPE,
        i_interv_presc_det  IN interv_presc_det.id_interv_presc_det%TYPE,
        i_epis_complication IN epis_complication.id_epis_complication%TYPE DEFAULT NULL,
        i_epis_comp_hist    IN epis_comp_hist.id_epis_comp_hist%TYPE DEFAULT NULL,
        i_nurse_tea_req     IN nurse_tea_req.id_nurse_tea_req%TYPE DEFAULT NULL,
        i_exam_result       IN mcdt_req_diagnosis.id_exam_result%TYPE DEFAULT NULL,
        i_epis_diag_status  IN epis_diagnosis.flg_status%TYPE DEFAULT g_ed_flg_status_d,
        i_blood_product_req IN blood_product_req.id_blood_product_req%TYPE DEFAULT NULL,
        i_blood_product_det IN blood_product_det.id_blood_product_det%TYPE DEFAULT NULL,
        i_rehab_presc       IN rehab_presc.id_rehab_presc%TYPE DEFAULT NULL,
        i_rehab_presc_hist  IN rehab_presc_hist.id_rehab_presc_hist%TYPE DEFAULT NULL,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_epis_diag       epis_diagnosis.id_epis_diagnosis%TYPE;
        l_flg_add_problem epis_diagnosis.flg_add_problem%TYPE;
        l_next            mcdt_req_diagnosis.id_epis_diagnosis%TYPE;
        l_flg_active      mcdt_req_diagnosis.flg_status%TYPE;
        l_flg_canc        mcdt_req_diagnosis.flg_status%TYPE;
        l_ex_create_diag EXCEPTION;
        l_output              pk_edis_types.table_out_epis_diags;
        l_diag                pk_edis_types.rec_in_epis_diagnoses;
        l_tbl_diagnoses       t_coll_diagnosis_config;
        l_patient             patient.id_patient%TYPE;
        l_count               PLS_INTEGER;
        l_tbl_alert_diagnosis table_number := table_number();
        --
        CURSOR c_epis_diag
        (
            l_diagnosis      IN NUMBER,
            l_desc_diagnosis IN VARCHAR2
        ) IS
            SELECT ed.id_epis_diagnosis, ed.flg_add_problem
              FROM epis_diagnosis ed, diagnosis d
             WHERE ed.id_episode = i_epis
               AND ed.id_diagnosis = l_diagnosis
               AND d.id_diagnosis = ed.id_diagnosis
               AND ((nvl(d.flg_other, 'N') = g_yes AND nvl(ed.desc_epis_diagnosis, '#') = nvl(l_desc_diagnosis, '#')) OR
                   (nvl(d.flg_other, 'N') = g_no))
               AND ed.flg_status != pk_diagnosis.g_ed_flg_status_ca;
    
    BEGIN
        g_sysdate_tstz := current_timestamp;
    
        l_flg_active := 'A';
        l_flg_canc   := 'C';
        --
        g_error := 'SET EPIS_COMP HIST';
        IF i_epis_complication IS NOT NULL
           AND i_epis_comp_hist IS NOT NULL
        THEN
            UPDATE mcdt_req_diagnosis mrd
               SET mrd.id_epis_comp_hist = i_epis_comp_hist,
                   mrd.flg_status        = l_flg_canc,
                   mrd.dt_cancel_tstz    = g_sysdate_tstz,
                   mrd.id_prof_cancel    = i_prof.id
             WHERE mrd.id_epis_complication = i_epis_complication
               AND mrd.id_epis_comp_hist IS NULL;
        END IF;
        --
        g_error := 'TESTING DIAGNOSES CURSOR';
        IF i_diag.tbl_diagnosis IS NOT NULL
           AND i_diag.tbl_diagnosis.count > 0
        THEN
            FOR i IN 1 .. i_diag.tbl_diagnosis.count
            LOOP
                IF i_diag.tbl_diagnosis(i).id_diagnosis IS NOT NULL
                THEN
                    --
                    g_error := 'GET SEQ_MCDT_REQ_DIAGNOSIS.NEXTVAL';
                    SELECT seq_mcdt_req_diagnosis.nextval
                      INTO l_next
                      FROM dual;
                    --
                    g_error := 'GET CURSOR C_EPIS_DIAG';
                    OPEN c_epis_diag(i_diag.tbl_diagnosis(i).id_diagnosis, i_diag.tbl_diagnosis(i).desc_diagnosis);
                    FETCH c_epis_diag
                        INTO l_epis_diag, l_flg_add_problem;
                    g_found := c_epis_diag%FOUND;
                    CLOSE c_epis_diag;
                    --             
                
                    IF g_found
                    THEN
                        SELECT COUNT(1)
                          INTO l_count
                          FROM mcdt_req_diagnosis mrd
                         WHERE mrd.id_epis_diagnosis = l_epis_diag
                           AND ((i_exam_req_det IS NOT NULL AND mrd.id_exam_req_det = i_exam_req_det) OR
                               (i_analysis_req_det IS NOT NULL AND mrd.id_analysis_req_det = i_analysis_req_det) OR
                               (i_interv_presc_det IS NOT NULL AND mrd.id_interv_presc_det = i_interv_presc_det) OR
                               (i_nurse_tea_req IS NOT NULL AND mrd.id_nurse_tea_req = i_nurse_tea_req) OR
                               (i_blood_product_det IS NOT NULL AND mrd.id_blood_product_det = i_blood_product_det) OR
                               (i_rehab_presc IS NOT NULL AND mrd.id_rehab_presc = i_rehab_presc))
                           AND mrd.flg_status <> pk_alert_constant.g_cancelled;
                    
                        l_tbl_alert_diagnosis.extend();
                        l_tbl_alert_diagnosis(l_tbl_alert_diagnosis.count) := i_diag.tbl_diagnosis(i).id_alert_diagnosis;
                    
                        IF l_count = 0
                        THEN
                            g_error := 'GET INSERT MCDT_REQ_DIAGNOSIS 1';
                            INSERT INTO mcdt_req_diagnosis
                                (id_mcdt_req_diagnosis,
                                 id_diagnosis,
                                 id_epis_diagnosis,
                                 id_exam_req,
                                 id_analysis_req,
                                 id_interv_prescription,
                                 flg_status,
                                 id_exam_req_det,
                                 id_analysis_req_det,
                                 id_interv_presc_det,
                                 id_epis_complication,
                                 id_alert_diagnosis,
                                 id_adiag_inst_owner,
                                 id_nurse_tea_req,
                                 id_exam_result,
                                 id_blood_product_req,
                                 id_blood_product_det,
                                 id_rehab_presc,
                                 id_rehab_presc_hist)
                            VALUES
                                (l_next,
                                 i_diag.tbl_diagnosis(i).id_diagnosis,
                                 l_epis_diag,
                                 i_exam_req,
                                 i_analysis_req,
                                 i_interv_presc,
                                 l_flg_active,
                                 i_exam_req_det,
                                 i_analysis_req_det,
                                 i_interv_presc_det,
                                 i_epis_complication,
                                 i_diag.tbl_diagnosis(i).id_alert_diagnosis,
                                 0,
                                 i_nurse_tea_req,
                                 i_exam_result,
                                 i_blood_product_req,
                                 i_blood_product_det,
                                 i_rehab_presc,
                                 i_rehab_presc_hist);
                        END IF;
                    ELSE
                        g_error := 'VERIFY IF ID_DIAGNOSIS: ' || i_diag.tbl_diagnosis(i).id_diagnosis ||
                                   ' IS AVAILABLE IN THE CURRENT INST/SOFT CONFIGURATION';
                        pk_alertlog.log_debug(text => g_error);
                        l_patient := pk_episode.get_id_patient(i_episode => i_epis);
                    
                        g_error := 'VERIFY IF ID_DIAGNOSIS: ' || i_diag.tbl_diagnosis(i).id_diagnosis ||
                                   ' IS AVAILABLE IN THE CURRENT INST/SOFT CONFIGURATION';
                        pk_alertlog.log_debug(text => g_error);
                        l_tbl_diagnoses := pk_terminology_search.tf_diagnoses_list(i_lang                     => i_lang,
                                                                                   i_prof                     => i_prof,
                                                                                   i_patient                  => l_patient,
                                                                                   i_terminologies_task_types => table_number(pk_alert_constant.g_task_diagnosis),
                                                                                   i_term_task_type           => pk_alert_constant.g_task_diagnosis,
                                                                                   i_list_type                => pk_diagnosis_core.g_diag_list_searchable,
                                                                                   i_tbl_diagnosis            => table_number(i_diag.tbl_diagnosis(i).id_diagnosis),
                                                                                   i_tbl_alert_diagnosis      => table_number(i_diag.tbl_diagnosis(i).id_alert_diagnosis));
                    
                        --ALERT-288698 - Only diagnoses available in the current inst/soft configuration can be created in diagnoses area
                        IF l_tbl_diagnoses.exists(1)
                        THEN
                            l_diag.epis_diagnosis := i_diag;
                            --To mantain the old logic we are going to treat one diagnosis at a time
                            l_diag.epis_diagnosis.tbl_diagnosis := pk_edis_types.table_in_diagnosis(i_diag.tbl_diagnosis(i));
                        
                            l_diag.epis_diagnosis.flg_edit_mode := pk_diagnosis_core.g_diag_create_mode;
                            l_diag.epis_diagnosis.flg_type := g_diag_type_p;
                            l_diag.epis_diagnosis.tbl_diagnosis(1).flg_status := nvl(i_epis_diag_status,
                                                                                     g_ed_flg_status_d);
                            l_diag.epis_diagnosis.tbl_diagnosis(1).flg_add_problem := l_flg_add_problem;
                        
                            g_error := 'CREATE_DIAGNOSIS ' || i_diag.tbl_diagnosis(i).id_diagnosis;
                            IF NOT pk_diagnosis_core.set_epis_diagnosis(i_lang           => i_lang,
                                                                        i_prof           => i_prof,
                                                                        i_epis_diagnoses => l_diag,
                                                                        o_params         => l_output,
                                                                        o_error          => o_error)
                            
                            THEN
                                RAISE l_ex_create_diag;
                            END IF;
                        
                            g_error := 'GET CURSOR C_EPIS_DIAG 2';
                            OPEN c_epis_diag(i_diag.tbl_diagnosis(i).id_diagnosis,
                                             i_diag.tbl_diagnosis(i).desc_diagnosis);
                            FETCH c_epis_diag
                                INTO l_epis_diag, l_flg_add_problem;
                            CLOSE c_epis_diag;
                        ELSE
                            l_epis_diag       := NULL;
                            l_flg_add_problem := NULL;
                        END IF;
                    
                        --
                        g_error := 'GET INSERT MCDT_REQ_DIAGNOSIS 2';
                        INSERT INTO mcdt_req_diagnosis
                            (id_mcdt_req_diagnosis,
                             id_diagnosis,
                             id_epis_diagnosis,
                             id_exam_req,
                             id_analysis_req,
                             id_interv_prescription,
                             flg_status,
                             id_exam_req_det,
                             id_analysis_req_det,
                             id_interv_presc_det,
                             id_epis_complication,
                             id_alert_diagnosis,
                             id_adiag_inst_owner,
                             id_nurse_tea_req,
                             id_exam_result,
                             id_blood_product_req,
                             id_blood_product_det,
                             id_rehab_presc,
                             id_rehab_presc_hist)
                        VALUES
                            (l_next,
                             i_diag.tbl_diagnosis(i).id_diagnosis,
                             l_epis_diag,
                             i_exam_req,
                             i_analysis_req,
                             i_interv_presc,
                             l_flg_active,
                             i_exam_req_det,
                             i_analysis_req_det,
                             i_interv_presc_det,
                             i_epis_complication,
                             i_diag.tbl_diagnosis(i).id_alert_diagnosis,
                             0,
                             i_nurse_tea_req,
                             i_exam_result,
                             i_blood_product_req,
                             i_blood_product_det,
                             i_rehab_presc,
                             i_rehab_presc_hist);
                    
                        l_tbl_alert_diagnosis.extend();
                        l_tbl_alert_diagnosis(l_tbl_alert_diagnosis.count) := i_diag.tbl_diagnosis(i).id_alert_diagnosis;
                    END IF;
                END IF;
            END LOOP;
        END IF;
    
        g_error := 'CALL TO PK_VISIT.SET_FIRST_OBS';
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => i_epis,
                                      i_pat                 => NULL,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => NULL,
                                      i_dt_last_interaction => g_sysdate_tstz,
                                      i_dt_first_obs        => g_sysdate_tstz,
                                      o_error               => o_error)
        THEN
            RAISE e_call_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_ex_create_diag THEN
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_DIAGNOSIS',
                                              'SET_MCDT_REQ_DIAG_NO_COMMIT',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_mcdt_req_diag_no_commit;

    --TODO: Implement this function to all areas. Currently it is only working for rehab_presc
    FUNCTION update_mcdt_req_diag_no_commit
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_epis              IN episode.id_episode%TYPE,
        i_diagnosis         IN pk_edis_types.rec_in_epis_diagnosis,
        i_exam_req          IN exam_req.id_exam_req%TYPE,
        i_analysis_req      IN analysis_req.id_analysis_req%TYPE,
        i_interv_presc      IN interv_prescription.id_interv_prescription%TYPE,
        i_exam_req_det      IN exam_req_det.id_exam_req_det%TYPE,
        i_analysis_req_det  IN analysis_req_det.id_analysis_req_det%TYPE,
        i_interv_presc_det  IN interv_presc_det.id_interv_presc_det%TYPE,
        i_epis_complication IN epis_complication.id_epis_complication%TYPE DEFAULT NULL,
        i_epis_comp_hist    IN epis_comp_hist.id_epis_comp_hist%TYPE DEFAULT NULL,
        i_nurse_tea_req     IN nurse_tea_req.id_nurse_tea_req%TYPE DEFAULT NULL,
        i_exam_result       IN mcdt_req_diagnosis.id_exam_result%TYPE DEFAULT NULL,
        i_epis_diag_status  IN epis_diagnosis.flg_status%TYPE DEFAULT g_ed_flg_status_d,
        i_blood_product_req IN blood_product_req.id_blood_product_req%TYPE DEFAULT NULL,
        i_blood_product_det IN blood_product_det.id_blood_product_det%TYPE DEFAULT NULL,
        i_rehab_presc       IN rehab_presc.id_rehab_presc%TYPE DEFAULT NULL,
        i_rehab_presc_hist  IN rehab_presc_hist.id_rehab_presc_hist%TYPE DEFAULT NULL,
        i_dt_tstz           IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT current_timestamp,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_diagnosis           table_number;
        l_tbl_alert_diagnosis table_number := table_number();
        l_tbl_diag_desc       table_varchar := table_varchar();
        l_epis_diagnosis      table_varchar := table_varchar();
        l_diagnosis_new       table_number := table_number();
        l_count               PLS_INTEGER := 0;
    
        FUNCTION get_sub_diag_table
        (
            i_tbl_diagnosis IN pk_edis_types.rec_in_epis_diagnosis,
            i_sub_diag_list IN table_number
        ) RETURN pk_edis_types.rec_in_epis_diagnosis IS
            l_ret      pk_edis_types.rec_in_epis_diagnosis;
            l_tbl_diag pk_edis_types.table_in_diagnosis;
        BEGIN
            l_ret := i_tbl_diagnosis;
        
            IF i_sub_diag_list.exists(1)
            THEN
                l_tbl_diag          := l_ret.tbl_diagnosis;
                l_ret.tbl_diagnosis := pk_edis_types.table_in_diagnosis();
            
                IF l_tbl_diag.exists(1)
                THEN
                    FOR j IN i_sub_diag_list.first .. i_sub_diag_list.last
                    LOOP
                        FOR i IN l_tbl_diag.first .. l_tbl_diag.last
                        LOOP
                            IF l_tbl_diag(i).id_diagnosis = i_sub_diag_list(j)
                            THEN
                                l_ret.tbl_diagnosis.extend;
                                l_ret.tbl_diagnosis(l_ret.tbl_diagnosis.count) := l_tbl_diag(i);
                                EXIT;
                            END IF;
                        END LOOP;
                    END LOOP;
                END IF;
            END IF;
        
            RETURN l_ret;
        END get_sub_diag_table;
    
    BEGIN
        g_sysdate_tstz := coalesce(i_dt_tstz, current_timestamp);
    
        g_error     := 'VALIDATE DIAGNOSIS';
        l_diagnosis := table_number();
        IF i_diagnosis.tbl_diagnosis.exists(1)
        THEN
            IF i_diagnosis.tbl_diagnosis.count > 0
            THEN
                FOR j IN i_diagnosis.tbl_diagnosis.first .. i_diagnosis.tbl_diagnosis.last
                LOOP
                    IF i_diagnosis.tbl_diagnosis(j).id_diagnosis IS NOT NULL
                        OR i_diagnosis.tbl_diagnosis(j).id_diagnosis != -1
                    THEN
                        l_diagnosis.extend;
                        l_diagnosis(l_diagnosis.count) := i_diagnosis.tbl_diagnosis(j).id_diagnosis;
                    
                        l_tbl_alert_diagnosis.extend;
                        l_tbl_alert_diagnosis(l_tbl_alert_diagnosis.count) := i_diagnosis.tbl_diagnosis(j).id_alert_diagnosis;
                    
                        l_tbl_diag_desc.extend();
                        l_tbl_diag_desc(l_tbl_diag_desc.count) := i_diagnosis.tbl_diagnosis(j).desc_diagnosis;
                    END IF;
                END LOOP;
            END IF;
        END IF;
    
        --Counts not null records
        g_error := 'COUNT EPIS_DIAGNOSIS';
        SELECT COUNT(*)
          INTO l_count
          FROM (SELECT /*+opt_estimate(table t rows=1)*/
                 *
                  FROM TABLE(l_diagnosis) t);
    
        --Cancels previously associated diagnosis that don't apply
        g_error := 'CANCEL MCTD_REQ_DIAGNOSIS';
        UPDATE mcdt_req_diagnosis
           SET flg_status = pk_alert_constant.g_cancelled, id_prof_cancel = i_prof.id, dt_cancel_tstz = g_sysdate_tstz
         WHERE (id_mcdt_req_diagnosis IN
               (SELECT mrd.id_mcdt_req_diagnosis
                   FROM mcdt_req_diagnosis mrd
                   JOIN epis_diagnosis ed
                     ON ed.id_epis_diagnosis = mrd.id_epis_diagnosis
                   LEFT JOIN (SELECT /*+opt_estimate(table t rows=1)*/
                              column_value, rownum AS rn
                               FROM TABLE(l_tbl_diag_desc) t) t_desc
                     ON t_desc.column_value = ed.desc_epis_diagnosis
                  WHERE ((mrd.id_rehab_presc = i_rehab_presc AND i_rehab_presc IS NOT NULL)) --TODO: IMPLEMENT OTHER AREAS
                    AND mrd.flg_status != pk_alert_constant.g_cancelled
                    AND ((t_desc.column_value IS NULL AND ed.desc_epis_diagnosis IS NOT NULL) OR
                        (mrd.id_alert_diagnosis NOT IN
                        (SELECT /*+opt_estimate(table t rows=1)*/
                            *
                             FROM TABLE(l_tbl_alert_diagnosis)) AND ed.desc_epis_diagnosis IS NULL))
                    AND l_count > 0))
            OR ((id_rehab_presc = i_rehab_presc AND i_rehab_presc IS NOT NULL) AND --TODO: IMPLEMENT OTHER AREAS
               flg_status != pk_alert_constant.g_cancelled AND l_count = 0);
    
        g_error := 'I_DIAGNOSIS LOOP';
        IF i_diagnosis.tbl_diagnosis IS NOT NULL
        THEN
            IF i_diagnosis.tbl_diagnosis.count > 0
            THEN
                g_error := 'CALL PK_DIAGNOSIS.CONCAT_DIAG_ID';
                l_epis_diagnosis.extend;
                l_epis_diagnosis := pk_diagnosis.concat_diag_id(i_lang              => i_lang,
                                                                i_prof              => i_prof,
                                                                i_exam_req_det      => i_exam_req_det,
                                                                i_analysis_req_det  => i_analysis_req_det,
                                                                i_interv_presc_det  => i_interv_presc_det,
                                                                i_type              => 'E',
                                                                i_nurse_tea_req     => i_nurse_tea_req,
                                                                i_exam_result       => i_exam_result,
                                                                i_blood_product_det => i_blood_product_det,
                                                                i_rehab_presc       => i_rehab_presc);
            
                l_count := 0;
                IF l_epis_diagnosis IS NOT NULL
                   AND l_epis_diagnosis.count > 0
                THEN
                    --Verifies if diagnosis exist
                    g_error := 'SELECT COUNT(*)';
                    SELECT COUNT(*)
                      INTO l_count
                      FROM mcdt_req_diagnosis mrd
                     WHERE ((mrd.id_rehab_presc = i_rehab_presc AND i_rehab_presc IS NOT NULL)) --TODO: IMPLEMENT OTHER AREAS
                       AND nvl(mrd.flg_status, '@') != pk_alert_constant.g_cancelled
                       AND mrd.id_diagnosis IN (SELECT /*+opt_estimate(table t rows=1)*/
                                                 *
                                                  FROM TABLE(l_diagnosis) t)
                       AND mrd.id_epis_diagnosis IN (SELECT /*+opt_estimate (table t rows=1)*/
                                                      *
                                                       FROM TABLE(l_epis_diagnosis) t);
                END IF;
            
                IF l_count = 0
                THEN
                    --Inserts new diagnosis code
                    g_error := 'CALL TO PK_DIAGNOSIS.SET_MCDT_REQ_DIAGNOSIS';
                    IF NOT pk_diagnosis.set_mcdt_req_diag_no_commit(i_lang              => i_lang,
                                                                    i_prof              => i_prof,
                                                                    i_epis              => i_epis,
                                                                    i_diag              => i_diagnosis,
                                                                    i_exam_req          => i_exam_req,
                                                                    i_analysis_req      => i_analysis_req,
                                                                    i_interv_presc      => i_interv_presc,
                                                                    i_exam_req_det      => i_exam_req_det,
                                                                    i_analysis_req_det  => i_analysis_req_det,
                                                                    i_interv_presc_det  => i_interv_presc_det,
                                                                    i_blood_product_req => i_blood_product_req,
                                                                    i_blood_product_det => i_blood_product_det,
                                                                    i_rehab_presc       => i_rehab_presc,
                                                                    i_rehab_presc_hist  => i_rehab_presc_hist,
                                                                    o_error             => o_error)
                    THEN
                        RAISE e_call_exception;
                    END IF;
                ELSIF l_count > 0
                      AND l_count < i_diagnosis.tbl_diagnosis.count
                THEN
                    SELECT DISTINCT t.column_value
                      BULK COLLECT
                      INTO l_diagnosis_new
                      FROM (SELECT /*+opt_estimate(table t rows=1)*/
                             *
                              FROM TABLE(l_diagnosis) t) t
                     WHERE t.column_value NOT IN
                           (SELECT mrd.id_diagnosis
                              FROM mcdt_req_diagnosis mrd
                             WHERE ((mrd.id_rehab_presc = i_rehab_presc AND i_rehab_presc IS NOT NULL)) --TODO: IMPLEMENT OTHER AREAS
                               AND mrd.id_epis_diagnosis IN (SELECT /*+opt_estimate (table t rows=1)*/
                                                              *
                                                               FROM TABLE(l_epis_diagnosis) t)
                               AND nvl(mrd.flg_status, '@') != pk_alert_constant.g_cancelled);
                
                    --Inserts new diagnosis code
                    g_error := 'CALL TO PK_DIAGNOSIS.SET_MCDT_REQ_DIAGNOSIS';
                    IF NOT pk_diagnosis.set_mcdt_req_diag_no_commit(i_lang              => i_lang,
                                                                    i_prof              => i_prof,
                                                                    i_epis              => i_epis,
                                                                    i_diag              => get_sub_diag_table(i_tbl_diagnosis => i_diagnosis,
                                                                                                              i_sub_diag_list => l_diagnosis_new),
                                                                    i_exam_req          => i_exam_req,
                                                                    i_analysis_req      => i_analysis_req,
                                                                    i_interv_presc      => i_interv_presc,
                                                                    i_exam_req_det      => i_exam_req_det,
                                                                    i_analysis_req_det  => i_analysis_req_det,
                                                                    i_interv_presc_det  => i_interv_presc_det,
                                                                    i_blood_product_req => i_blood_product_req,
                                                                    i_blood_product_det => i_blood_product_det,
                                                                    i_rehab_presc       => i_rehab_presc,
                                                                    i_rehab_presc_hist  => i_rehab_presc_hist,
                                                                    o_error             => o_error)
                    THEN
                        RAISE e_call_exception;
                    END IF;
                END IF;
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_DIAGNOSIS',
                                              'UPDATE_MCDT_REQ_DIAG_NO_COMMIT',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END update_mcdt_req_diag_no_commit;

    FUNCTION concat_diag
    (
        i_lang                   IN language.id_language%TYPE,
        i_exam_req_det           IN exam_req_det.id_exam_req_det%TYPE,
        i_analysis_req_det       IN analysis_req_det.id_analysis_req_det%TYPE,
        i_interv_presc_det       IN interv_presc_det.id_interv_presc_det%TYPE,
        i_prof                   IN profissional,
        i_nurse_tea_req          IN nurse_tea_req.id_nurse_tea_req%TYPE DEFAULT NULL,
        i_exam_result            IN exam_result.id_exam_result%TYPE DEFAULT NULL,
        i_blood_product_det      IN blood_product_det.id_blood_product_det%TYPE DEFAULT NULL,
        i_rehab_presc            IN rehab_presc.id_rehab_presc%TYPE DEFAULT NULL,
        i_flg_terminology_server IN VARCHAR2 DEFAULT pk_alert_constant.g_no
    ) RETURN VARCHAR2 IS
    
        /** @headcom
        * Public Function. Obter o descritivo dos diagn�sticos associados a uma requisi��o.
        * N�o ?chamada pelo Flash.
        *
        * @param      I_LANG               L�ngua registada como prefer�ncia do profissional
        * @param      I_EXAM_REQ     ID da requisi��o de exames.
        * @param      I_ANALYSIS_REQ   ID da requisi��o de an�lises.
        * @param      I_INTERV_PRESC   ID da requisi��o de procedimentos.
        * @param      I_DRUG_PRESC     ID da requisi��o de medicamentos.
        * @param      I_DRUG_REQ     ID da requisi��o de medicamentos ?farm�cia.
        * @param      I_PRESCRIPTION   ID da prescri��o de medicamentos para o exterior.
        * @param      I_PRESCRIPTION_USA   ID da prescri��o de medicamentos para o exterior (vers�o USA).
        * @param      I_PROF         object (ID do profissional, ID da institui��o, ID do software)
        *
        * @return     boolean
        * @author     SS
        * @version    0.1
        * @since      2007/02/06
        */
    BEGIN
        RETURN concat_diag_id_str(i_lang                   => i_lang,
                                  i_exam_req_det           => i_exam_req_det,
                                  i_analysis_req_det       => i_analysis_req_det,
                                  i_interv_presc_det       => i_interv_presc_det,
                                  i_prof                   => i_prof,
                                  i_type                   => 'T', --T - DESCRIPTION COLUMN
                                  i_nurse_tea_req          => i_nurse_tea_req,
                                  i_exam_result            => i_exam_result,
                                  i_blood_product_det      => i_blood_product_det,
                                  i_rehab_presc            => i_rehab_presc,
                                  i_flg_terminology_server => i_flg_terminology_server);
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.reset_error_state;
            RETURN NULL;
    END;
    --
    /**********************************************************************************************
    * Listar os estados / icones disponiveis no momento da cria��o
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids             
    * @param i_flg_type               Tipo de diagn�stico (diferencial ou final)
    * @param o_status                 Lista dos estados dos diagn�sticos diferenciais
    * @param o_assoc_prob             Associated problem list
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Emilia Taborda e Luis Oliveira
    * @version                        1.0 
    * @since                          2007/02/11
    **********************************************************************************************/
    FUNCTION get_epis_diag_stat_new_list
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_flg_type   IN epis_diagnosis.flg_type%TYPE,
        o_status     OUT pk_edis_types.cursor_status,
        o_assoc_prob OUT pk_edis_types.cursor_assoc_prob,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_epis_diag_status sys_domain.code_domain%TYPE := '';
        l_default_status   sys_config.value%TYPE;
    
    BEGIN
    
        IF i_flg_type = g_diag_type_p
        THEN
            l_epis_diag_status := g_epis_diag_status_p;
        END IF;
        --
        IF i_flg_type = g_diag_type_d
        THEN
            l_epis_diag_status := g_epis_diag_status_d;
        END IF;
    
        g_error          := 'GET CONFIG';
        l_default_status := pk_sysconfig.get_config(l_epis_diag_status, i_prof);
        --
        OPEN o_status FOR
            SELECT val,
                   desc_val,
                   img_name,
                   decode(val, l_default_status, pk_alert_constant.g_yes, pk_alert_constant.g_no) flg_default
              FROM TABLE(pk_sysdomain.get_values_domain_pipelined(i_lang          => i_lang,
                                                                  i_prof          => i_prof,
                                                                  i_code_dom      => l_epis_diag_status,
                                                                  i_dep_clin_serv => NULL));
    
        pk_backoffice_translation.set_read_translation(l_epis_diag_status, 'SYS_DOMAIN');
    
        g_error := 'GET CURSOR O_ASSOC_PROB';
        pk_alertlog.log_info(g_error);
        IF NOT
            get_assoc_prob_lst_int(i_lang => i_lang, i_prof => i_prof, o_assoc_prob => o_assoc_prob, o_error => o_error)
        THEN
            RAISE e_call_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_DIAGNOSIS',
                                              'GET_EPIS_DIAG_STAT_NEW_LIST',
                                              o_error);
            pk_edis_types.open_my_cursor(o_status);
            pk_edis_types.open_my_cursor(o_assoc_prob);
            RETURN FALSE;
    END;
    --
    /**********************************************************************************************
    * Obter os diagn�sticos diferenciais do epis�dio que ainda n�o s�o diagn�sticos finais
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids             
    * @param i_epis                   episode id
    * @param i_epis_diag              diagnosis episode id    
    * @param o_epis_diag_det          Lista dos diagn�sticos diferenciais ou finais de um epis�dio
    * @param o_lab_tests              Lista de analises  associadas ao diagn�stico
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Emilia Taborda
    * @version                        1.0 
    * @since                          2007/02/16
    **********************************************************************************************/
    FUNCTION get_epis_diagnosis_det
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_epis          IN episode.id_episode%TYPE,
        i_epis_diag     IN epis_diagnosis.id_epis_diagnosis%TYPE,
        o_epis_diag_det OUT pk_types.cursor_type,
        o_lab_tests     OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_msg_diag_final_t050 sys_message.desc_message%TYPE;
    BEGIN
        g_error               := 'GET SYS_MESSAGE';
        l_msg_diag_final_t050 := pk_message.get_message(i_lang, g_code_msg_diag_final_t050);
    
        g_error := 'OPEN O_EPIS_DIAG_DET';
        OPEN o_epis_diag_det FOR
            SELECT decode(ed.flg_status,
                          g_ed_flg_status_ca,
                          pk_message.get_message(i_lang, 'DIAGNOSIS_DIFF_M017'),
                          decode((SELECT COUNT(1)
                                   FROM epis_diagnosis_hist edh
                                  WHERE edh.id_epis_diagnosis = ed.id_epis_diagnosis),
                                 0,
                                 pk_message.get_message(i_lang, 'DIAGNOSIS_DIFF_M018'),
                                 pk_message.get_message(i_lang, 'DIAGNOSIS_DIFF_M016'))) desc_detail,
                   pk_message.get_message(i_lang, 'DIAGNOSIS_FINAL_T025') || ':' diag_type_title,
                   ed.flg_status,
                   sd.desc_val desc_status,
                   sd.img_name icon_status,
                   pk_prof_utils.get_name_signature(i_lang,
                                                    i_prof,
                                                    pk_diagnosis_core.get_prof_diagnosis(i_lang,
                                                                                         i_prof,
                                                                                         ed.flg_status,
                                                                                         ed.id_professional_diag,
                                                                                         ed.id_prof_confirmed,
                                                                                         ed.id_professional_cancel,
                                                                                         ed.id_prof_base,
                                                                                         ed.id_prof_rulled_out)) nick_name,
                   pk_date_utils.date_send_tsz(i_lang,
                                               pk_diagnosis_core.get_dt_diagnosis(i_lang,
                                                                                  i_prof,
                                                                                  flg_status,
                                                                                  dt_epis_diagnosis_tstz,
                                                                                  dt_confirmed_tstz,
                                                                                  dt_cancel_tstz,
                                                                                  dt_base_tstz,
                                                                                  dt_rulled_out_tstz),
                                               i_prof) date_target,
                   pk_date_utils.date_char_tsz(i_lang,
                                               pk_diagnosis_core.get_dt_diagnosis(i_lang,
                                                                                  i_prof,
                                                                                  flg_status,
                                                                                  dt_epis_diagnosis_tstz,
                                                                                  dt_confirmed_tstz,
                                                                                  dt_cancel_tstz,
                                                                                  dt_base_tstz,
                                                                                  dt_rulled_out_tstz),
                                               i_prof.institution,
                                               i_prof.software) date_target_desc,
                   pk_message.get_message(i_lang, 'DIAGNOSIS_DIFF_M006') general_notes_title,
                   pk_diagnosis_core.get_epis_diag_note(i_lang           => i_lang,
                                                        i_prof           => i_prof,
                                                        i_episode        => ed.id_episode,
                                                        i_epis_diag      => ed.id_epis_diagnosis,
                                                        i_epis_diag_hist => NULL) general_notes,
                   pk_message.get_message(i_lang, 'DIAGNOSIS_DIFF_M007') specific_notes_title,
                   ed.notes specific_notes,
                   pk_message.get_message(i_lang, 'DIAGNOSIS_DIFF_M005') cancel_notes_title,
                   ed.notes_cancel cancel_notes,
                   pk_message.get_message(i_lang, 'DIAGNOSIS_DIFF_M008') cancel_reason_title,
                   (SELECT pk_translation.get_translation(i_lang, cr.code_cancel_reason)
                      FROM cancel_reason cr
                     WHERE cr.id_cancel_reason = ed.id_cancel_reason) cancel_reason,
                   pk_message.get_message(i_lang, 'DIAGNOSIS_FINAL_M001') diag_final_type,
                   sd1.desc_val desc_diag_final_type,
                   pk_prof_utils.get_name_signature(i_lang,
                                                    i_prof,
                                                    pk_diagnosis_core.get_prof_diagnosis(i_lang,
                                                                                         i_prof,
                                                                                         ed.flg_status,
                                                                                         ed.id_professional_diag,
                                                                                         ed.id_prof_confirmed,
                                                                                         ed.id_professional_cancel,
                                                                                         ed.id_prof_base,
                                                                                         ed.id_prof_rulled_out)) prof_name,
                   pk_prof_utils.get_spec_signature(i_lang,
                                                    i_prof,
                                                    pk_diagnosis_core.get_prof_diagnosis(i_lang,
                                                                                         i_prof,
                                                                                         ed.flg_status,
                                                                                         ed.id_professional_diag,
                                                                                         ed.id_prof_confirmed,
                                                                                         ed.id_professional_cancel,
                                                                                         ed.id_prof_base,
                                                                                         ed.id_prof_rulled_out),
                                                    pk_diagnosis_core.get_dt_diagnosis(i_lang,
                                                                                       i_prof,
                                                                                       flg_status,
                                                                                       dt_epis_diagnosis_tstz,
                                                                                       dt_confirmed_tstz,
                                                                                       dt_cancel_tstz,
                                                                                       dt_base_tstz,
                                                                                       dt_rulled_out_tstz),
                                                    ed.id_episode) prof_spec,
                   ed.flg_add_problem,
                   l_msg_diag_final_t050 title_flg_add_problem,
                   pk_sysdomain.get_domain(pk_diagnosis.g_code_domain_yes_no, ed.flg_add_problem, i_lang) desc_flg_add_problem
              FROM epis_diagnosis ed, sys_domain sd, sys_domain sd1
             WHERE ed.id_epis_diagnosis = i_epis_diag
               AND sd.val = ed.flg_status
               AND sd.code_domain = g_epis_diag_status
               AND sd.domain_owner = pk_sysdomain.k_default_schema
               AND sd.id_language = i_lang
               AND sd1.val(+) = ed.flg_final_type
               AND sd1.domain_owner(+) = pk_sysdomain.k_default_schema
               AND sd1.code_domain(+) = g_epis_diag_type_d
               AND sd1.id_language(+) = i_lang
            UNION
            SELECT decode(edh.flg_status,
                          g_ed_flg_status_ca,
                          pk_message.get_message(i_lang, 'DIAGNOSIS_DIFF_M017'),
                          decode(row_number() over(ORDER BY edh.dt_creation_tstz),
                                 1,
                                 pk_message.get_message(i_lang, 'DIAGNOSIS_DIFF_M018'),
                                 pk_message.get_message(i_lang, 'DIAGNOSIS_DIFF_M016'))) desc_detail,
                   pk_message.get_message(i_lang, 'DIAGNOSIS_FINAL_T025') || ':' diag_type_title,
                   edh.flg_status,
                   sd.desc_val desc_status,
                   sd.img_name icon_status,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, edh.id_professional) nick_name,
                   pk_date_utils.date_send_tsz(i_lang, edh.dt_creation_tstz, i_prof) date_target,
                   pk_date_utils.date_char_tsz(i_lang, edh.dt_creation_tstz, i_prof.institution, i_prof.software) date_target_desc,
                   pk_message.get_message(i_lang, 'DIAGNOSIS_DIFF_M006') general_notes_title,
                   pk_diagnosis_core.get_epis_diag_note(i_lang           => i_lang,
                                                        i_prof           => i_prof,
                                                        i_episode        => i_epis,
                                                        i_epis_diag      => NULL,
                                                        i_epis_diag_hist => edh.id_epis_diagnosis_hist) general_notes,
                   pk_message.get_message(i_lang, 'DIAGNOSIS_DIFF_M007') specific_notes_title,
                   pk_diagnosis_core.get_hist_specific_notes(i_lang,
                                                             i_prof,
                                                             i_epis_diag,
                                                             edh.dt_creation_tstz,
                                                             edh.flg_status,
                                                             edh.notes) specific_notes,
                   pk_message.get_message(i_lang, 'DIAGNOSIS_DIFF_M005') cancel_notes_title,
                   decode(edh.flg_status, g_ed_flg_status_ca, edh.notes, NULL) cancel_notes,
                   pk_message.get_message(i_lang, 'DIAGNOSIS_DIFF_M008') cancel_reason_title,
                   (SELECT pk_translation.get_translation(i_lang, cr.code_cancel_reason)
                      FROM cancel_reason cr
                     WHERE cr.id_cancel_reason = edh.id_cancel_reason) cancel_reason,
                   pk_message.get_message(i_lang, 'DIAGNOSIS_FINAL_M001') diag_final_type,
                   sd1.desc_val desc_diag_final_type,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, edh.id_professional) prof_name,
                   pk_prof_utils.get_spec_signature(i_lang, i_prof, edh.id_professional, edh.dt_creation_tstz, i_epis) prof_spec,
                   edh.flg_add_problem,
                   l_msg_diag_final_t050 title_flg_add_problem,
                   pk_sysdomain.get_domain(pk_diagnosis.g_code_domain_yes_no, edh.flg_add_problem, i_lang) desc_flg_add_problem
              FROM epis_diagnosis_hist edh, sys_domain sd, sys_domain sd1
             WHERE edh.id_epis_diagnosis = i_epis_diag
               AND sd.val = edh.flg_status
               AND sd.code_domain = g_epis_diag_status
               AND sd.domain_owner = pk_sysdomain.k_default_schema
               AND sd.id_language = i_lang
               AND sd1.val(+) = edh.flg_final_type
               AND sd1.code_domain(+) = g_epis_diag_type_d
               AND sd1.domain_owner(+) = pk_sysdomain.k_default_schema
               AND sd1.id_language(+) = i_lang
             ORDER BY date_target;
        pk_backoffice_translation.set_read_translation(g_epis_diag_status, 'SYS_DOMAIN');
        pk_backoffice_translation.set_read_translation(g_epis_diag_type_d, 'SYS_DOMAIN');
        --
        g_error := 'OPEN O_LAB_TESTS';
        OPEN o_lab_tests FOR
            SELECT pk_message.get_message(i_lang, 'DIAGNOSIS_DIFF_M002') analysis_title,
                   pk_diagnosis.concat_mcdts(i_lang, i_prof, i_epis_diag, 'A') analysis_desc,
                   pk_message.get_message(i_lang, 'DIAGNOSIS_DIFF_M003') exam_title,
                   pk_diagnosis.concat_mcdts(i_lang, i_prof, i_epis_diag, 'E') exams_desc,
                   pk_message.get_message(i_lang, 'DIAGNOSIS_DIFF_M004') intervention_title,
                   pk_diagnosis.concat_mcdts(i_lang, i_prof, i_epis_diag, 'I') interv_desc
              FROM dual;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_DIAGNOSIS',
                                              'GET_EPIS_DIAGNOSIS_DET',
                                              o_error);
            pk_types.open_my_cursor(o_epis_diag_det);
            pk_types.open_my_cursor(o_lab_tests);
            RETURN FALSE;
    END;
    --

    /**********************************************************************************************
    * Obter o �ltimo diagn�sticos diferencial do epis�dio que ainda n�o s�o diagn�sticos finais
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids             
    * @param i_epis                   episode id
    * @param i_epis_diag              diagnosis episode id    
    * @param o_epis_diag_det_last     �ltimo diagn�sticos diferencial de um epis�dio
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Filipe Machado
    * @version                        1.0 
    * @since                          2009/04/30
    **********************************************************************************************/
    FUNCTION get_epis_diagnosis_det_last
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_epis               IN episode.id_episode%TYPE,
        i_epis_diag          IN epis_diagnosis.id_epis_diagnosis%TYPE,
        o_epis_diag_det_last OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_msg_diag_final_t050 sys_message.desc_message%TYPE;
    BEGIN
        g_error               := 'GET SYS_MESSAGE';
        l_msg_diag_final_t050 := pk_message.get_message(i_lang, g_code_msg_diag_final_t050);
    
        g_error := 'OPEN O_EPIS_DIAG_DET_LAST';
        OPEN o_epis_diag_det_last FOR
            SELECT pk_message.get_message(1, 'DIAGNOSIS_DIFF_M006') general_notes_title,
                   pk_diagnosis_core.get_epis_diag_note(i_lang           => i_lang,
                                                        i_prof           => i_prof,
                                                        i_episode        => ed.id_episode,
                                                        i_epis_diag      => ed.id_epis_diagnosis,
                                                        i_epis_diag_hist => NULL) general_notes,
                   pk_message.get_message(1, 'DIAGNOSIS_DIFF_M007') specific_notes_title,
                   ed.notes specific_notes,
                   ed.flg_add_problem,
                   l_msg_diag_final_t050 title_flg_add_problem,
                   pk_sysdomain.get_domain(pk_diagnosis.g_code_domain_yes_no, ed.flg_add_problem, i_lang) desc_flg_add_problem
              FROM epis_diagnosis ed, sys_domain sd, sys_domain sd1
             WHERE ed.id_epis_diagnosis = i_epis_diag
               AND sd.val = ed.flg_status
               AND sd.code_domain = g_epis_diag_status
               AND sd.id_language = i_lang
               AND sd.domain_owner = pk_sysdomain.k_default_schema
               AND sd1.val(+) = ed.flg_final_type
               AND sd1.domain_owner(+) = pk_sysdomain.k_default_schema
               AND sd1.code_domain(+) = g_epis_diag_type_d
               AND sd1.id_language(+) = i_lang;
    
        pk_backoffice_translation.set_read_translation(g_epis_diag_status, 'SYS_DOMAIN');
        pk_backoffice_translation.set_read_translation(g_epis_diag_type_d, 'SYS_DOMAIN');
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_DIAGNOSIS',
                                              'GET_EPIS_DIAGNOSIS_DET_LAST',
                                              o_error);
            pk_types.open_my_cursor(o_epis_diag_det_last);
            RETURN FALSE;
    END get_epis_diagnosis_det_last;
    --
    /**********************************************************************************************
    * Obter os descritivos dos MCDTs associados a um diagn�stico
    *
    * @param i_lang                   the id language
    * @param i_code                   ID do MCDT    
    * @param i_flag_type              Tipo de MCDT: A - An�lises; E - Exames; I - Interven��es
    * @param i_epis_diag              diagnosis episode id
    *
    * @return                         Lista de MCDTs concatenados com ponto e virgula
    *                        
    * @author                         Emilia Taborda
    * @version                        1.0 
    * @since                          2007/02/16
    **********************************************************************************************/
    FUNCTION concat_mcdts
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_code      IN epis_diagnosis.id_epis_diagnosis%TYPE,
        i_flag_type IN VARCHAR2,
        i_epis_diag IN epis_diagnosis.id_epis_diagnosis%TYPE
    ) RETURN VARCHAR2 IS
        l_desc  VARCHAR2(4000);
        l_first BOOLEAN := TRUE;
        --
        -- < DESNORM LMAIA 16-10-2008 >
        CURSOR c_analysis IS
            SELECT DISTINCT lte.id_analysis,
                            pk_lab_tests_api_db.get_alias_translation(i_lang,
                                                                      i_prof,
                                                                      'A',
                                                                      'ANALYSIS.CODE_ANALYSIS.' || lte.id_analysis,
                                                                      NULL) analysis_desc
              FROM mcdt_req_diagnosis mrd, lab_tests_ea lte --analysis_req ar, analysis_req_det ard, analysis a
             WHERE mrd.id_analysis_req = lte.id_analysis_req
                  --AND ar.id_analysis_req = ard.id_analysis_req
                  --AND ard.id_analysis = a.id_analysis
               AND mrd.id_analysis_req_det = i_code
               AND mrd.id_epis_diagnosis = i_epis_diag
             ORDER BY analysis_desc;
        r_analysis c_analysis%ROWTYPE;
        -- < END DESNORM >
    
        /*<DESNORM Jos?Vilas Boas 2008-10-10>*/
        CURSOR c_exams IS
            SELECT DISTINCT eea.id_exam,
                            pk_exams_api_db.get_alias_translation(i_lang,
                                                                  i_prof,
                                                                  'EXAM.CODE_EXAM.' || eea.id_exam,
                                                                  NULL) exam_desc
              FROM exams_ea eea, mcdt_req_diagnosis mrd
             WHERE mrd.id_exam_req_det = i_code
               AND mrd.id_epis_diagnosis = i_epis_diag
               AND eea.id_exam_req_det = mrd.id_exam_req_det
             ORDER BY exam_desc;
        r_exam c_exams%ROWTYPE;
        /*<DESNORM>*/
    
        CURSOR c_interv IS
            SELECT DISTINCT i.id_intervention,
                            pk_procedures_api_db.get_alias_translation(i_lang, i_prof, i.code_intervention, NULL) interv_desc
              FROM mcdt_req_diagnosis mrd, procedures_ea pea, intervention i
             WHERE mrd.id_interv_prescription = pea.id_interv_prescription
               AND pea.id_intervention = i.id_intervention
               AND mrd.id_interv_presc_det = i_code
               AND mrd.id_epis_diagnosis = i_epis_diag
             ORDER BY interv_desc;
        r_exam c_exams%ROWTYPE;
    BEGIN
        -- An�lises
        IF i_flag_type = 'A'
        THEN
            g_error := 'LOOP ANALYSIS';
            FOR r_analysis IN c_analysis
            LOOP
                IF l_first
                THEN
                    l_first := FALSE;
                ELSE
                    l_desc := l_desc || '; ';
                END IF;
                l_desc := l_desc || r_analysis.analysis_desc;
            END LOOP;
            --
            RETURN l_desc;
        
            -- Exames
        ELSIF i_flag_type = 'E'
        THEN
            g_error := 'LOOP EXAMS';
            FOR r_exams IN c_exams
            LOOP
                IF l_first
                THEN
                    l_first := FALSE;
                ELSE
                    l_desc := l_desc || '; ';
                END IF;
                l_desc := l_desc || r_exams.exam_desc;
            END LOOP;
            --
            RETURN l_desc;
        
            -- Interven��es
        ELSIF i_flag_type = 'I'
        THEN
            g_error := 'LOOP INTERV';
            FOR r_interv IN c_interv
            LOOP
                IF l_first
                THEN
                    l_first := FALSE;
                ELSE
                    l_desc := l_desc || '; ';
                END IF;
                l_desc := l_desc || r_interv.interv_desc;
            END LOOP;
        
            RETURN l_desc;
        ELSE
            RETURN '';
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.reset_error_state;
            RETURN '';
    END;
    --
    /**********************************************************************************************
    * Lista de diagn�sticos definitivos de epis�dios anteriores do paciente
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids             
    * @param i_patient                patient id
    * @param i_episode                episode id
    * @param i_flag_filter            Filtro a aplicar: A - (all) mostrar todos os diagn�sticos anteriores
                                                        L - (last) mostrar apenas o �ltimo diagn�stico anterior
                                                        MA - (my all) mostrar todos os diagn�sticos anteriores criados por um determinado profissional
                                                        ML - (my last) mostrar apenas o �ltimo diagn�stico anterior criado por um determinado profissional
    * @param o_epis_diag_prev         Lista de diagn�sticos definitivos de epis�dios anteriores do paciente
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Emilia Taborda
    * @version                        1.0 
    * @since                          2007/02/16
    **********************************************************************************************/
    FUNCTION get_epis_diagnosis_prev
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_patient        IN patient.id_patient%TYPE,
        i_episode        IN episode.id_episode%TYPE,
        i_flag_filter    IN VARCHAR2,
        o_epis_diag_prev OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        -- Mostrar todos os diagn�sticos anteriores
        IF i_flag_filter = 'A'
        THEN
            g_error := 'OPEN O_EPIS_DIAG_PREV A';
            OPEN o_epis_diag_prev FOR
                SELECT std_diag_desc(i_lang                => i_lang,
                                     i_prof                => i_prof,
                                     i_id_alert_diagnosis  => ad.id_alert_diagnosis,
                                     i_id_diagnosis        => d.id_diagnosis,
                                     i_desc_epis_diagnosis => ed.desc_epis_diagnosis,
                                     i_code                => d.code_icd,
                                     i_flg_other           => d.flg_other,
                                     i_flg_std_diag        => ad.flg_icd9) desc_diagnosis,
                       ed.flg_status status_diagnosis,
                       sd.img_name icon_status,
                       sd.desc_val desc_status,
                       pk_date_utils.date_send_tsz(i_lang,
                                                   decode(ed.flg_status,
                                                          g_ed_flg_status_d,
                                                          ed.dt_epis_diagnosis_tstz,
                                                          g_ed_flg_status_co,
                                                          nvl(ed.dt_confirmed_tstz, ed.dt_epis_diagnosis_tstz)),
                                                   i_prof) date_last_update,
                       pk_date_utils.date_char_tsz(i_lang,
                                                   decode(ed.flg_status,
                                                          g_ed_flg_status_d,
                                                          ed.dt_epis_diagnosis_tstz,
                                                          g_ed_flg_status_co,
                                                          nvl(ed.dt_confirmed_tstz, ed.dt_epis_diagnosis_tstz),
                                                          NULL),
                                                   i_prof.institution,
                                                   i_prof.software) date_last_update_desc
                  FROM epis_diagnosis ed, diagnosis d, episode e, sys_domain sd, alert_diagnosis ad
                 WHERE ed.id_diagnosis = d.id_diagnosis
                   AND ed.id_episode = e.id_episode
                   AND ad.id_alert_diagnosis(+) = ed.id_alert_diagnosis
                   AND sd.code_domain = g_epis_diag_status
                   AND sd.val = ed.flg_status
                   AND sd.domain_owner = pk_sysdomain.k_default_schema
                   AND sd.id_language = i_lang
                   AND e.id_patient = i_patient
                   AND ed.flg_status IN (g_ed_flg_status_d, g_ed_flg_status_co)
                   AND ed.flg_type = g_diag_type_d
                   AND e.dt_begin_tstz < (SELECT dt_begin_tstz
                                            FROM episode
                                           WHERE id_episode = i_episode)
                UNION
                SELECT std_diag_desc(i_lang                => i_lang,
                                     i_prof                => i_prof,
                                     i_id_alert_diagnosis  => ad.id_alert_diagnosis,
                                     i_id_diagnosis        => d.id_diagnosis,
                                     i_desc_epis_diagnosis => ed.desc_epis_diagnosis,
                                     i_code                => d.code_icd,
                                     i_flg_other           => d.flg_other,
                                     i_flg_std_diag        => ad.flg_icd9) desc_diagnosis,
                       ed.flg_status status_diagnosis,
                       sd.img_name icon_status,
                       sd.desc_val desc_status,
                       pk_date_utils.date_send_tsz(i_lang,
                                                   decode(ed.flg_status,
                                                          g_ed_flg_status_d,
                                                          ed.dt_epis_diagnosis_tstz,
                                                          g_ed_flg_status_co,
                                                          nvl(ed.dt_confirmed_tstz, ed.dt_epis_diagnosis_tstz)),
                                                   i_prof) date_last_update,
                       pk_date_utils.date_char_tsz(i_lang,
                                                   decode(ed.flg_status,
                                                          g_ed_flg_status_d,
                                                          ed.dt_epis_diagnosis_tstz,
                                                          g_ed_flg_status_co,
                                                          nvl(ed.dt_confirmed_tstz, ed.dt_epis_diagnosis_tstz),
                                                          NULL),
                                                   i_prof.institution,
                                                   i_prof.software) date_last_update_desc
                  FROM epis_diagnosis ed, diagnosis d, episode e, sys_domain sd, alert_diagnosis ad
                 WHERE ed.id_diagnosis = d.id_diagnosis
                   AND ed.id_episode = e.id_episode
                   AND ad.id_alert_diagnosis(+) = ed.id_alert_diagnosis
                   AND sd.code_domain = g_epis_diag_status
                   AND sd.val = ed.flg_status
                   AND sd.domain_owner = pk_sysdomain.k_default_schema
                   AND sd.id_language = i_lang
                   AND e.id_patient = i_patient
                   AND ed.flg_status IN (g_ed_flg_status_d, g_ed_flg_status_co)
                   AND e.dt_begin_tstz < (SELECT dt_begin_tstz
                                            FROM episode
                                           WHERE id_episode = i_episode)
                   AND ed.flg_type = g_diag_type_p
                   AND ed.id_diagnosis NOT IN (SELECT id_diagnosis
                                                 FROM epis_diagnosis ed1
                                                WHERE ed1.flg_type = g_diag_type_d
                                                  AND ed1.flg_status IN (g_ed_flg_status_co, g_ed_flg_status_d)
                                                  AND ed1.id_episode = ed.id_episode)
                 ORDER BY date_last_update DESC;
        
            pk_backoffice_translation.set_read_translation(g_epis_diag_status, 'SYS_DOMAIN');
            --
            -- Mostrar apenas o �ltimo diagn�stico anterior
        ELSIF i_flag_filter = 'L'
        THEN
            g_error := 'OPEN O_EPIS_DIAG_PREV L';
            OPEN o_epis_diag_prev FOR
                SELECT *
                  FROM (SELECT std_diag_desc(i_lang                => i_lang,
                                             i_prof                => i_prof,
                                             i_id_alert_diagnosis  => ad.id_alert_diagnosis,
                                             i_id_diagnosis        => d.id_diagnosis,
                                             i_desc_epis_diagnosis => ed.desc_epis_diagnosis,
                                             i_code                => d.code_icd,
                                             i_flg_other           => d.flg_other,
                                             i_flg_std_diag        => ad.flg_icd9) desc_diagnosis,
                               ed.flg_status status_diagnosis,
                               sd.img_name icon_status,
                               sd.desc_val desc_status,
                               pk_date_utils.date_send_tsz(i_lang,
                                                           decode(ed.flg_status,
                                                                  g_ed_flg_status_d,
                                                                  ed.dt_epis_diagnosis_tstz,
                                                                  g_ed_flg_status_co,
                                                                  nvl(ed.dt_confirmed_tstz, ed.dt_epis_diagnosis_tstz)),
                                                           i_prof) date_last_update,
                               pk_date_utils.date_char_hour_tsz(i_lang,
                                                                decode(ed.flg_status,
                                                                       g_ed_flg_status_d,
                                                                       ed.dt_epis_diagnosis_tstz,
                                                                       g_ed_flg_status_co,
                                                                       nvl(ed.dt_confirmed_tstz, ed.dt_epis_diagnosis_tstz)),
                                                                i_prof.institution,
                                                                i_prof.software) || ' / ' ||
                               pk_date_utils.dt_chr_tsz(i_lang,
                                                        decode(ed.flg_status,
                                                               g_ed_flg_status_d,
                                                               ed.dt_epis_diagnosis_tstz,
                                                               g_ed_flg_status_co,
                                                               nvl(ed.dt_confirmed_tstz, ed.dt_epis_diagnosis_tstz)),
                                                        i_prof) date_last_update_desc
                          FROM epis_diagnosis ed, diagnosis d, episode e, sys_domain sd, alert_diagnosis ad
                         WHERE ed.id_diagnosis = d.id_diagnosis
                           AND ed.id_episode = e.id_episode
                           AND ad.id_alert_diagnosis(+) = ed.id_alert_diagnosis
                           AND sd.code_domain = g_epis_diag_status
                           AND sd.val = ed.flg_status
                           AND sd.domain_owner = pk_sysdomain.k_default_schema
                           AND sd.id_language = i_lang
                           AND e.id_patient = i_patient
                           AND ed.flg_status IN (g_ed_flg_status_d, g_ed_flg_status_co)
                           AND e.dt_begin_tstz < (SELECT dt_begin_tstz
                                                    FROM episode
                                                   WHERE id_episode = i_episode)
                         ORDER BY date_last_update DESC)
                 WHERE rownum < 2;
            pk_backoffice_translation.set_read_translation(g_epis_diag_status, 'SYS_DOMAIN');
            --
            -- Mostrar todos os diagn�sticos anteriores criados por um determinado profissional
        ELSIF i_flag_filter = 'MA'
        THEN
            g_error := 'OPEN O_EPIS_DIAG_PREV MA';
            OPEN o_epis_diag_prev FOR
                SELECT std_diag_desc(i_lang                => i_lang,
                                     i_prof                => i_prof,
                                     i_id_alert_diagnosis  => ad.id_alert_diagnosis,
                                     i_id_diagnosis        => d.id_diagnosis,
                                     i_desc_epis_diagnosis => ed.desc_epis_diagnosis,
                                     i_code                => d.code_icd,
                                     i_flg_other           => d.flg_other,
                                     i_flg_std_diag        => ad.flg_icd9) desc_diagnosis,
                       ed.flg_status status_diagnosis,
                       sd.img_name icon_status,
                       sd.desc_val desc_status,
                       pk_date_utils.date_send_tsz(i_lang,
                                                   decode(ed.flg_status,
                                                          g_ed_flg_status_d,
                                                          ed.dt_epis_diagnosis_tstz,
                                                          g_ed_flg_status_co,
                                                          nvl(ed.dt_confirmed_tstz, ed.dt_epis_diagnosis_tstz)),
                                                   i_prof) date_last_update,
                       pk_date_utils.date_char_hour_tsz(i_lang,
                                                        decode(ed.flg_status,
                                                               g_ed_flg_status_d,
                                                               ed.dt_epis_diagnosis_tstz,
                                                               g_ed_flg_status_co,
                                                               nvl(ed.dt_confirmed_tstz, ed.dt_epis_diagnosis_tstz)),
                                                        i_prof.institution,
                                                        i_prof.software) || ' / ' ||
                       pk_date_utils.dt_chr_tsz(i_lang,
                                                decode(ed.flg_status,
                                                       g_ed_flg_status_d,
                                                       ed.dt_epis_diagnosis_tstz,
                                                       g_ed_flg_status_co,
                                                       nvl(ed.dt_confirmed_tstz, ed.dt_epis_diagnosis_tstz)),
                                                i_prof) date_last_update_desc
                  FROM epis_diagnosis ed, diagnosis d, episode e, sys_domain sd, alert_diagnosis ad
                 WHERE ed.id_diagnosis = d.id_diagnosis
                   AND ed.id_episode = e.id_episode
                   AND ad.id_alert_diagnosis(+) = ed.id_alert_diagnosis
                   AND sd.code_domain = g_epis_diag_status
                   AND sd.val = ed.flg_status
                   AND sd.domain_owner = pk_sysdomain.k_default_schema
                   AND sd.id_language = i_lang
                   AND e.id_patient = i_patient
                   AND ed.flg_status IN (g_ed_flg_status_d, g_ed_flg_status_co)
                   AND ed.flg_type = g_diag_type_d
                   AND e.dt_begin_tstz < (SELECT dt_begin_tstz
                                            FROM episode
                                           WHERE id_episode = i_episode)
                   AND (ed.id_professional_diag = i_prof.id OR ed.id_prof_confirmed = i_prof.id OR
                       (SELECT COUNT(*)
                           FROM epis_diagnosis_hist
                          WHERE id_epis_diagnosis = ed.id_epis_diagnosis
                            AND id_professional = i_prof.id
                            AND flg_status IN (g_ed_flg_status_d, g_ed_flg_status_co)) > 0)
                UNION
                SELECT std_diag_desc(i_lang                => i_lang,
                                     i_prof                => i_prof,
                                     i_id_alert_diagnosis  => ad.id_alert_diagnosis,
                                     i_id_diagnosis        => d.id_diagnosis,
                                     i_desc_epis_diagnosis => ed.desc_epis_diagnosis,
                                     i_code                => d.code_icd,
                                     i_flg_other           => d.flg_other,
                                     i_flg_std_diag        => ad.flg_icd9) desc_diagnosis,
                       ed.flg_status status_diagnosis,
                       sd.img_name icon_status,
                       sd.desc_val desc_status,
                       pk_date_utils.date_send_tsz(i_lang,
                                                   decode(ed.flg_status,
                                                          g_ed_flg_status_d,
                                                          ed.dt_epis_diagnosis_tstz,
                                                          g_ed_flg_status_co,
                                                          nvl(ed.dt_confirmed_tstz, ed.dt_epis_diagnosis_tstz)),
                                                   i_prof) date_last_update,
                       pk_date_utils.date_char_hour_tsz(i_lang,
                                                        decode(ed.flg_status,
                                                               g_ed_flg_status_d,
                                                               ed.dt_epis_diagnosis_tstz,
                                                               g_ed_flg_status_co,
                                                               nvl(ed.dt_confirmed_tstz, ed.dt_epis_diagnosis_tstz)),
                                                        i_prof.institution,
                                                        i_prof.software) || ' / ' ||
                       pk_date_utils.dt_chr_tsz(i_lang,
                                                decode(ed.flg_status,
                                                       g_ed_flg_status_d,
                                                       ed.dt_epis_diagnosis_tstz,
                                                       g_ed_flg_status_co,
                                                       nvl(ed.dt_confirmed_tstz, ed.dt_epis_diagnosis_tstz)),
                                                i_prof) date_last_update_desc
                  FROM epis_diagnosis ed, diagnosis d, episode e, sys_domain sd, alert_diagnosis ad
                 WHERE ed.id_diagnosis = d.id_diagnosis
                   AND ed.id_episode = e.id_episode
                   AND ad.id_alert_diagnosis(+) = ed.id_alert_diagnosis
                   AND sd.code_domain = g_epis_diag_status
                   AND sd.val = ed.flg_status
                   AND sd.domain_owner = pk_sysdomain.k_default_schema
                   AND sd.id_language = i_lang
                   AND e.id_patient = i_patient
                   AND ed.flg_status IN (g_ed_flg_status_d, g_ed_flg_status_co)
                   AND ed.flg_type = g_diag_type_p
                   AND e.dt_begin_tstz < (SELECT dt_begin_tstz
                                            FROM episode
                                           WHERE id_episode = i_episode)
                   AND (ed.id_professional_diag = i_prof.id OR ed.id_prof_confirmed = i_prof.id OR
                       (SELECT COUNT(*)
                           FROM epis_diagnosis_hist
                          WHERE id_epis_diagnosis = ed.id_epis_diagnosis
                            AND id_professional = i_prof.id
                            AND flg_status IN (g_ed_flg_status_d, g_ed_flg_status_co)) > 0)
                   AND ed.id_diagnosis NOT IN (SELECT id_diagnosis
                                                 FROM epis_diagnosis ed1
                                                WHERE ed1.flg_type = g_diag_type_d
                                                  AND ed1.flg_status IN (g_ed_flg_status_co, g_ed_flg_status_d)
                                                  AND ed1.id_episode = ed.id_episode)
                 ORDER BY date_last_update DESC;
            pk_backoffice_translation.set_read_translation(g_epis_diag_status, 'SYS_DOMAIN');
            --
            -- Mostrar apenas o �ltimo diagn�stico anterior criado por um determinado profissional
        ELSIF i_flag_filter = 'ML'
        THEN
            g_error := 'OPEN O_EPIS_DIAG_PREV ML';
            OPEN o_epis_diag_prev FOR
                SELECT *
                  FROM (SELECT std_diag_desc(i_lang                => i_lang,
                                             i_prof                => i_prof,
                                             i_id_alert_diagnosis  => ad.id_alert_diagnosis,
                                             i_id_diagnosis        => d.id_diagnosis,
                                             i_desc_epis_diagnosis => ed.desc_epis_diagnosis,
                                             i_code                => d.code_icd,
                                             i_flg_other           => d.flg_other,
                                             i_flg_std_diag        => ad.flg_icd9) desc_diagnosis,
                               ed.flg_status status_diagnosis,
                               sd.img_name icon_status,
                               sd.desc_val desc_status,
                               pk_date_utils.date_send_tsz(i_lang,
                                                           decode(ed.flg_status,
                                                                  g_ed_flg_status_d,
                                                                  ed.dt_epis_diagnosis_tstz,
                                                                  g_ed_flg_status_co,
                                                                  nvl(ed.dt_confirmed_tstz, ed.dt_epis_diagnosis_tstz)),
                                                           i_prof) date_last_update,
                               pk_date_utils.date_char_hour_tsz(i_lang,
                                                                decode(ed.flg_status,
                                                                       g_ed_flg_status_d,
                                                                       ed.dt_epis_diagnosis_tstz,
                                                                       g_ed_flg_status_co,
                                                                       ed.dt_confirmed_tstz),
                                                                i_prof.institution,
                                                                i_prof.software) || ' / ' ||
                               pk_date_utils.dt_chr_tsz(i_lang,
                                                        decode(ed.flg_status,
                                                               g_ed_flg_status_d,
                                                               ed.dt_epis_diagnosis_tstz,
                                                               g_ed_flg_status_co,
                                                               nvl(ed.dt_confirmed_tstz, ed.dt_epis_diagnosis_tstz)),
                                                        i_prof) date_last_update_desc
                          FROM epis_diagnosis ed, diagnosis d, episode e, sys_domain sd, alert_diagnosis ad
                         WHERE ed.id_diagnosis = d.id_diagnosis
                           AND ed.id_episode = e.id_episode
                           AND ad.id_alert_diagnosis(+) = ed.id_alert_diagnosis
                           AND sd.code_domain = g_epis_diag_status
                           AND sd.val = ed.flg_status
                           AND sd.domain_owner = pk_sysdomain.k_default_schema
                           AND sd.id_language = i_lang
                           AND e.id_patient = i_patient
                           AND ed.flg_status IN (g_ed_flg_status_d, g_ed_flg_status_co)
                           AND (ed.id_professional_diag = i_prof.id OR ed.id_prof_confirmed = i_prof.id)
                           AND e.dt_begin_tstz < (SELECT dt_begin_tstz
                                                    FROM episode
                                                   WHERE id_episode = i_episode)
                        UNION
                        SELECT std_diag_desc(i_lang                => i_lang,
                                             i_prof                => i_prof,
                                             i_id_alert_diagnosis  => ad.id_alert_diagnosis,
                                             i_id_diagnosis        => d.id_diagnosis,
                                             i_desc_epis_diagnosis => ed.desc_epis_diagnosis,
                                             i_code                => d.code_icd,
                                             i_flg_other           => d.flg_other,
                                             i_flg_std_diag        => ad.flg_icd9) desc_diagnosis,
                               edh.flg_status status_diagnosis,
                               sd.img_name icon_status,
                               sd.desc_val desc_status,
                               pk_date_utils.date_send_tsz(i_lang, edh.dt_creation_tstz, i_prof) date_last_update,
                               pk_date_utils.date_char_hour_tsz(i_lang,
                                                                edh.dt_creation_tstz,
                                                                i_prof.institution,
                                                                i_prof.software) || ' / ' ||
                               pk_date_utils.dt_chr_tsz(i_lang, edh.dt_creation_tstz, i_prof) date_last_update_desc
                          FROM epis_diagnosis_hist edh,
                               epis_diagnosis      ed,
                               diagnosis           d,
                               episode             e,
                               sys_domain          sd,
                               alert_diagnosis     ad
                         WHERE edh.id_epis_diagnosis = ed.id_epis_diagnosis
                           AND ed.id_diagnosis = d.id_diagnosis
                           AND ed.id_episode = e.id_episode
                           AND ad.id_alert_diagnosis(+) = ed.id_alert_diagnosis
                           AND sd.code_domain = g_epis_diag_status
                           AND sd.domain_owner = pk_sysdomain.k_default_schema
                           AND sd.val = edh.flg_status
                           AND sd.id_language = i_lang
                           AND e.id_patient = i_patient
                           AND edh.flg_status IN (g_ed_flg_status_d, g_ed_flg_status_co)
                           AND edh.id_professional = i_prof.id
                           AND e.dt_begin_tstz < (SELECT dt_begin_tstz
                                                    FROM episode
                                                   WHERE id_episode = i_episode)
                         ORDER BY date_last_update DESC)
                 WHERE rownum < 2;
            pk_backoffice_translation.set_read_translation(g_epis_diag_status, 'SYS_DOMAIN');
        
        ELSE
            pk_types.open_my_cursor(o_epis_diag_prev);
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_DIAGNOSIS',
                                              'GET_EPIS_DIAGNOSIS_PREV',
                                              o_error);
            pk_types.open_my_cursor(o_epis_diag_prev);
            RETURN FALSE;
    END;
    --
    /**********************************************************************************************
    * Obter os descritivos dos MCDTs associados a um diagn�stico
    *
    * @param i_lang                   the id language
    * @param i_code                   ID do MCDT    
    * @param i_flag_type              Tipo de MCDT: A - An�lises; E - Exames; I - Interven��es
    *
    * @return                         Lista de MCDTs concatenados com ponto e virgula
    *                        
    * @author                         Emilia Taborda
    * @version                        1.0 
    * @since                          2007/02/16
    **********************************************************************************************/
    FUNCTION concat_mcdts
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_epis_diag IN epis_diagnosis.id_epis_diagnosis%TYPE,
        i_flag_type IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_desc  VARCHAR2(4000);
        l_first BOOLEAN := TRUE;
        --
        -- < DESNORM LMAIA 16-10-2008 >
        CURSOR c_analysis IS
            SELECT DISTINCT lte.id_analysis,
                            pk_lab_tests_api_db.get_alias_translation(i_lang,
                                                                      i_prof,
                                                                      'A',
                                                                      'ANALYSIS.CODE_ANALYSIS.' || lte.id_analysis,
                                                                      NULL) analysis_desc
              FROM mcdt_req_diagnosis mrd, lab_tests_ea lte --analysis_req ar, analysis_req_det ard, analysis a
             WHERE mrd.id_analysis_req = lte.id_analysis_req
                  --AND ar.id_analysis_req = ard.id_analysis_req
                  --AND ard.id_analysis = a.id_analysis
               AND mrd.id_epis_diagnosis = i_epis_diag
             ORDER BY analysis_desc;
        r_analysis c_analysis%ROWTYPE;
        -- < END DESNORM >
    
        /*<DESNORM Jos?Vilas Boas 2008-10-10>*/
        CURSOR c_exams IS
            SELECT DISTINCT eea.id_exam,
                            pk_exams_api_db.get_alias_translation(i_lang,
                                                                  i_prof,
                                                                  'EXAM.CODE_EXAM.' || eea.id_exam,
                                                                  NULL) exam_desc
              FROM exams_ea eea, mcdt_req_diagnosis mrd
             WHERE mrd.id_epis_diagnosis = i_epis_diag
               AND eea.id_exam_req_det = mrd.id_exam_req_det
             ORDER BY exam_desc;
        r_exam c_exams%ROWTYPE;
        /*<DESNORM Jos?Vilas Boas 2008-10-10>*/
    
        CURSOR c_interv IS
            SELECT DISTINCT i.id_intervention,
                            pk_procedures_api_db.get_alias_translation(i_lang, i_prof, i.code_intervention, NULL) interv_desc
              FROM mcdt_req_diagnosis mrd, procedures_ea pea, intervention i
             WHERE mrd.id_interv_prescription = pea.id_interv_prescription
               AND pea.id_intervention = i.id_intervention
               AND mrd.id_epis_diagnosis = i_epis_diag
             ORDER BY interv_desc;
        r_exam c_exams%ROWTYPE;
    BEGIN
        -- An�lises
        IF i_flag_type = 'A'
        THEN
            g_error := 'LOOP ANALYSIS';
            FOR r_analysis IN c_analysis
            LOOP
                IF l_first
                THEN
                    l_first := FALSE;
                ELSE
                    l_desc := l_desc || '; ';
                END IF;
                l_desc := l_desc || r_analysis.analysis_desc;
            END LOOP;
        
            RETURN l_desc;
        
            -- Exames
        ELSIF i_flag_type = 'E'
        THEN
            g_error := 'LOOP EXAMS';
            FOR r_exams IN c_exams
            LOOP
                IF l_first
                THEN
                    l_first := FALSE;
                ELSE
                    l_desc := l_desc || '; ';
                END IF;
                l_desc := l_desc || r_exams.exam_desc;
            END LOOP;
        
            RETURN l_desc;
        
            -- Interven��es
        ELSIF i_flag_type = 'I'
        THEN
            g_error := 'LOOP INTERV';
            FOR r_interv IN c_interv
            LOOP
                IF l_first
                THEN
                    l_first := FALSE;
                ELSE
                    l_desc := l_desc || '; ';
                END IF;
                l_desc := l_desc || r_interv.interv_desc;
            END LOOP;
        
            RETURN l_desc;
        ELSE
            RETURN '';
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.reset_error_state;
            RETURN '';
    END;
    --
    /**********************************************************************************************
    * Lista o estados de um diagn�stico associado a um epis�dio
    *
    * @param i_epis                   episode id    
    * @param i_diagnosis              diagnosis id
    *
    * @return                         diagnosis status 
    *                        
    * @author                         Emilia Taborda
    * @version                        1.0 
    * @since                          2007/02/16
    **********************************************************************************************/
    FUNCTION get_status_diag
    (
        i_epis      IN epis_diagnosis.id_episode%TYPE,
        i_diagnosis IN epis_diagnosis.id_diagnosis%TYPE,
        i_diag_type IN epis_diagnosis.flg_type%TYPE DEFAULT NULL
    ) RETURN VARCHAR2 IS
        l_final_status epis_diagnosis.flg_status%TYPE;
        l_diff_status  epis_diagnosis.flg_status%TYPE;
        --
        CURSOR c_epis_diag_final IS
            SELECT ed.flg_status
              FROM epis_diagnosis ed
             WHERE ed.id_episode = i_epis
               AND ed.id_diagnosis = i_diagnosis
               AND ed.flg_type IN (g_diag_type_d, g_diag_type_b)
               AND ed.flg_status IN (g_ed_flg_status_co, g_ed_flg_status_d, g_ed_flg_status_b);
    
        CURSOR c_epis_diag_diff IS
            SELECT ed.flg_status
              FROM epis_diagnosis ed
             WHERE ed.id_episode = i_epis
               AND ed.id_diagnosis = i_diagnosis
               AND ed.flg_type IN (g_diag_type_p, g_diag_type_b)
               AND ed.flg_status IN (g_ed_flg_status_co, g_ed_flg_status_d, g_ed_flg_status_b);
    BEGIN
        -- Verificar se o diagn�stico existe como definitivo
        g_error := 'OPEN C_EPIS_DIAG_FINAL';
        OPEN c_epis_diag_final;
        FETCH c_epis_diag_final
            INTO l_final_status;
        CLOSE c_epis_diag_final;
        --
        IF nvl(i_diag_type, g_diag_type_d) = g_diag_type_d
           AND l_final_status IS NOT NULL
        THEN
            RETURN l_final_status;
        END IF;
        --
        -- Verificar se o diagn�stico existe como provis�rio
        g_error := 'OPEN C_EPIS_DIAG_FINAL';
        OPEN c_epis_diag_diff;
        FETCH c_epis_diag_diff
            INTO l_diff_status;
        CLOSE c_epis_diag_diff;
        --
        IF nvl(i_diag_type, g_diag_type_p) = g_diag_type_p
           AND l_diff_status IS NOT NULL
        THEN
            RETURN l_diff_status;
        END IF;
    
        RETURN NULL;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.reset_error_state;
            RETURN NULL;
    END;
    --
    /**********************************************************************************************
    * Lista dos tipos dos diagn�sticos diferenciais
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids             
    * @param o_type                   Lista dos tipos dos diagn�sticos diferenciais
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Emilia Taborda
    * @version                        1.0 
    * @since                          2007/02/19
    **********************************************************************************************/
    FUNCTION get_epis_diag_type
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_type  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'OPEN O_TYPE';
        RETURN pk_sysdomain.get_values_domain(g_epis_diag_type_d, i_lang, o_type, o_error);
        --
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_DIAGNOSIS',
                                              'GET_EPIS_DIAG_TYPE',
                                              o_error);
            pk_types.open_my_cursor(o_type);
            RETURN FALSE;
    END;
    --
    /********************************************************************************************
    * builds a standard formatted diagnosis description that is displayed to the user (with or without code and synonym indication)
    *
    * @param i_lang                    language id
    * @param i_prof                    professional id (type: professional id, institution id and software id)
    * @param i_id_alert_diagnosis      Alert Diagnosis ID
    * @param i_id_diagnosis            Diagnosis ID
    * @param i_code_diagnosis          Diagnosis Code
    * @param i_diagnosis_language      Diagnosis Language
    * @param i_id_task_type            Functional area from where the translation was requested. 
    * @param i_desc_epis_diagnosis     Diagnosis Free-text description
    * @param i_code                    Diagnosis code
    * @param i_flg_other               flag which indicates if the diagnosis is "Other" or an official one
    * @param i_flg_std_diag            flag which indicates if the diagnosis is the standard one or one of the synonyms
    * @param i_epis_diag               When filled adds additional information to diagnosis, for instance, the state description and date (ALERT-81543)
    * @param i_flg_past_hist           Flag used to include past history info
    * @param i_flg_search_mode         Flag to indicate if this is a search mode query
    * @param i_flg_add_cause           Add diagnosis cause info (ALERT-261232)
    * @param i_flg_show_ae_diag_info   Is to concatenate all AE diagnoses info?
    * @param i_ed_rowtype              Row type sent in Global search trigger
    * @param i_flg_show_if_principal   Show 'Principal diagnosis' when aplicable, i_show_aditional_info as to be 'Y'
    * @param i_flg_status              For show Active,Inactive... status
    * @param i_flg_type                For show problem-P,past hisotry medical-H
    *
    * @return                 formatted text containing the diagnosis description
    *
    * @author                 Sergio Dias
    * @version                2.0
    * @since                  7/Fev/2012
    **********************************************************************************************/
    FUNCTION std_diag_desc
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_alert_diagnosis    IN alert_diagnosis.id_alert_diagnosis%TYPE DEFAULT NULL,
        i_id_diagnosis          IN diagnosis.id_diagnosis%TYPE DEFAULT NULL,
        i_code_diagnosis        IN diagnosis.code_diagnosis%TYPE DEFAULT NULL,
        i_diagnosis_language    IN language.id_language%TYPE DEFAULT NULL,
        i_id_task_type          IN task_type.id_task_type%TYPE DEFAULT pk_alert_constant.g_task_diagnosis,
        i_desc_epis_diagnosis   IN epis_diagnosis.desc_epis_diagnosis%TYPE DEFAULT NULL,
        i_code                  IN diagnosis.code_icd%TYPE,
        i_flg_other             IN diagnosis.flg_other%TYPE,
        i_flg_std_diag          IN alert_diagnosis.flg_icd9%TYPE,
        i_epis_diag             IN epis_diagnosis.id_epis_diagnosis%TYPE DEFAULT NULL,
        i_show_aditional_info   IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        i_flg_past_hist         IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_flg_search_mode       IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_flg_show_term_code    IN VARCHAR2 DEFAULT NULL,
        i_flg_add_cause         IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_flg_show_ae_diag_info IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        i_ed_rowtype            IN epis_diagnosis%ROWTYPE DEFAULT NULL,
        i_flg_show_if_principal IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_flg_show_dt_initial   IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_flg_status            IN VARCHAR2 DEFAULT NULL,
        i_flg_type              IN VARCHAR2 DEFAULT NULL
    ) RETURN VARCHAR2 IS
        l_description        pk_translation.t_desc_translation;
        l_id_alert_diagnosis diagnosis.id_diagnosis%TYPE;
        l_flg_show_term_code VARCHAR2(1 CHAR);
        l_desc_causes        pk_translation.t_desc_translation;
    BEGIN
        -- If a custom description was received use it
        IF i_desc_epis_diagnosis IS NOT NULL
        THEN
            l_description := i_desc_epis_diagnosis;
        ELSE
            -- check if an id_alert_diagnosis exists
            IF i_id_alert_diagnosis IS NULL
            THEN
                -- call function to obtain id_alert_diagnosis
                l_id_alert_diagnosis := pk_api_pfh_diagnosis_in.get_diag_preferred_term_id(i_concept_version => i_id_diagnosis,
                                                                                           i_task_type       => i_id_task_type);
            ELSE
                l_id_alert_diagnosis := i_id_alert_diagnosis;
            END IF;
        
            IF l_id_alert_diagnosis IS NOT NULL
               OR i_code_diagnosis IS NOT NULL
            THEN
                l_description := pk_diagnosis_core.get_alert_diag_desc(i_lang               => i_lang,
                                                                       i_prof               => i_prof,
                                                                       i_id_alert_diagnosis => l_id_alert_diagnosis,
                                                                       i_code_diagnosis     => i_code_diagnosis,
                                                                       i_diagnosis_language => i_diagnosis_language,
                                                                       i_id_task_type       => i_id_task_type);
            END IF;
        END IF;
    
        IF i_flg_show_term_code IS NOT NULL
        THEN
            -- if the parameter is sent, use it
            l_flg_show_term_code := i_flg_show_term_code;
        ELSE
            -- if the parameter wasn't sent, check configuration for the value
            BEGIN
                SELECT pk_sysconfig.get_config(i_code_cf => decode(i_id_task_type,
                                                                   pk_alert_constant.g_task_diagnosis,
                                                                   g_sys_config_show_term_diagnos,
                                                                   pk_alert_constant.g_task_problems,
                                                                   g_sys_config_show_term_problem,
                                                                   pk_alert_constant.g_task_surgical_history,
                                                                   g_sys_config_show_term_surg,
                                                                   pk_alert_constant.g_task_medical_history,
                                                                   g_sys_config_show_term_medical,
                                                                   pk_alert_constant.g_task_congenital_anomalies,
                                                                   g_sys_config_show_term_cong,
                                                                   g_sys_config_show_term_diagnos),
                                               i_prof    => i_prof)
                  INTO l_flg_show_term_code
                  FROM dual;
            EXCEPTION
                WHEN OTHERS THEN
                    l_flg_show_term_code := pk_alert_constant.g_no;
            END;
        END IF;
    
        IF l_description IS NOT NULL
        THEN
        
            l_description := pk_diagnosis_core.std_diag_desc(i_lang                  => i_lang,
                                                             i_prof                  => i_prof,
                                                             i_id_diagnosis          => i_id_diagnosis,
                                                             i_desc                  => l_description,
                                                             i_code                  => i_code,
                                                             i_flg_other             => i_flg_other,
                                                             i_flg_std_diag          => i_flg_std_diag,
                                                             i_epis_diag             => i_epis_diag,
                                                             i_show_aditional_info   => i_show_aditional_info,
                                                             i_flg_past_hist         => i_flg_past_hist,
                                                             i_flg_search_mode       => i_flg_search_mode,
                                                             i_flg_show_ae_diag_info => i_flg_show_ae_diag_info,
                                                             i_flg_show_term_code    => l_flg_show_term_code,
                                                             i_ed_rowtype            => i_ed_rowtype,
                                                             i_flg_show_if_principal => i_flg_show_if_principal,
                                                             i_flg_show_dt_initial   => i_flg_show_dt_initial,
                                                             i_flg_status            => i_flg_status,
                                                             i_flg_type              => i_flg_type);
        
            IF i_flg_add_cause = pk_alert_constant.g_yes
            THEN
                l_desc_causes := pk_diagnosis.get_diag_cause_desc(i_lang      => i_lang,
                                                                  i_prof      => i_prof,
                                                                  i_diagnosis => i_id_diagnosis);
            
                IF l_desc_causes IS NOT NULL
                THEN
                    l_description := l_description || ' (' || l_desc_causes || ')';
                END IF;
            END IF;
        
            RETURN l_description;
        ELSE
            RETURN '';
        END IF;
    END std_diag_desc;
    --
    /********************************************************************************************
    * builds a standard formatted description for the staging basis
    *
    * @param i_lang                    language id
    * @param i_prof                    professional id (type: professional id, institution id and software id)
    * @param i_id_alert_diagnosis      Alert Diagnosis ID
    * @param i_id_diagnosis            Diagnosis ID
    * @param i_code_diagnosis          Diagnosis Code
    * @param i_diagnosis_language      Diagnosis Language
    * @param i_id_task_type            Functional area from where the translation was requested. 
    * @param i_desc_epis_diagnosis     Diagnosis Free-text description
    * @param i_code                    Diagnosis code
    * @param i_flg_other               flag which indicates if the diagnosis is "Other" or an official one
    * @param i_flg_std_diag            flag which indicates if the diagnosis is the standard one or one of the synonyms
    * @param i_epis_diag               When filled adds additional information to diagnosis, for instance, the state description and date (ALERT-81543)
    * @param i_flg_past_hist           Flag used to include past history info
    * @param i_flg_search_mode         Flag to indicate if this is a search mode query
    * @param i_format_bold             Formats the staging description to bold: (Y)es or (N)o
    * @param i_staging_basis_type      Checks the type of staging in order to show the staging index
    * @param i_num_staging_basis       Staging index
    * @param i_show_full_desc          Shows the staging fully specified name: (Y)es or (N)o
    *
    * @return                 formatted text containing the staging basis description
    * 
    * @author                 Jos?Silva
    * @version                2.6.2.1
    * @since                  18/Mar/2012
    **********************************************************************************************/
    FUNCTION std_staging_basis_desc
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_alert_diagnosis  IN alert_diagnosis.id_alert_diagnosis%TYPE DEFAULT NULL,
        i_id_diagnosis        IN diagnosis.id_diagnosis%TYPE DEFAULT NULL,
        i_code_diagnosis      IN diagnosis.code_diagnosis%TYPE DEFAULT NULL,
        i_diagnosis_language  IN language.id_language%TYPE DEFAULT NULL,
        i_id_task_type        IN task_type.id_task_type%TYPE DEFAULT pk_alert_constant.g_task_diagnosis,
        i_desc_epis_diagnosis IN epis_diagnosis.desc_epis_diagnosis%TYPE DEFAULT NULL,
        i_code                IN diagnosis.code_icd%TYPE,
        i_flg_other           IN diagnosis.flg_other%TYPE,
        i_flg_std_diag        IN alert_diagnosis.flg_icd9%TYPE,
        i_epis_diag           IN epis_diagnosis.id_epis_diagnosis%TYPE DEFAULT NULL,
        i_flg_past_hist       IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_flg_search_mode     IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_format_bold         IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_staging_basis_type  IN VARCHAR2 DEFAULT NULL,
        i_num_staging_basis   IN epis_diag_stag.num_staging_basis%TYPE DEFAULT NULL,
        i_show_full_desc      IN VARCHAR2 DEFAULT pk_alert_constant.g_no
    ) RETURN VARCHAR2 IS
        l_description pk_translation.t_desc_translation;
        l_diag_code   diagnosis.code_icd%TYPE;
    
    BEGIN
    
        IF i_show_full_desc = pk_alert_constant.g_yes
        THEN
            l_description := pk_api_pfh_diagnosis_in.get_concept_fsn_term(i_lang            => i_lang,
                                                                          i_concept_version => i_id_diagnosis,
                                                                          i_lang_termin     => i_diagnosis_language);
        ELSE
            l_diag_code := i_code || ' - ';
        END IF;
    
        IF l_description IS NULL
        THEN
            l_description := pk_diagnosis.std_diag_desc(i_lang                => i_lang,
                                                        i_prof                => i_prof,
                                                        i_id_alert_diagnosis  => i_id_alert_diagnosis,
                                                        i_id_diagnosis        => i_id_diagnosis,
                                                        i_code_diagnosis      => i_code_diagnosis,
                                                        i_diagnosis_language  => i_diagnosis_language,
                                                        i_id_task_type        => i_id_task_type,
                                                        i_desc_epis_diagnosis => i_desc_epis_diagnosis,
                                                        i_code                => NULL,
                                                        i_flg_other           => i_flg_other,
                                                        i_flg_std_diag        => i_flg_std_diag,
                                                        i_epis_diag           => i_epis_diag,
                                                        i_flg_past_hist       => i_flg_past_hist,
                                                        i_flg_search_mode     => i_flg_search_mode);
        END IF;
    
        l_description := l_diag_code || l_description;
    
        IF i_staging_basis_type = pk_diagnosis_core.g_staging_retreatment_type
           AND i_num_staging_basis > 1
        THEN
            l_description := l_description || ' (' || i_num_staging_basis || ')';
        END IF;
    
        IF i_format_bold = pk_alert_constant.g_yes
        THEN
            l_description := pk_utils.to_bold(l_description);
        END IF;
    
        IF i_show_full_desc = pk_alert_constant.g_no
        THEN
            l_description := l_description || ' (' ||
                             pk_api_pfh_diagnosis_in.get_concept_definition_term(i_lang,
                                                                                 i_id_diagnosis,
                                                                                 i_diagnosis_language) || ')';
        END IF;
    
        RETURN l_description;
    
    END std_staging_basis_desc;
    --
    /********************************************************************************************
    * builds a standard formatted description for the tnm fields
    *
    * @param i_lang                    language id
    * @param i_prof                    professional id (type: professional id, institution id and software id)
    * @param i_id_alert_diagnosis      Alert Diagnosis ID
    * @param i_id_diagnosis            Diagnosis ID
    * @param i_code_diagnosis          Diagnosis Code
    * @param i_diagnosis_language      Diagnosis Language
    * @param i_id_task_type            Functional area from where the translation was requested. 
    * @param i_desc_epis_diagnosis     Diagnosis Free-text description
    * @param i_code                    Diagnosis code
    * @param i_flg_other               flag which indicates if the diagnosis is "Other" or an official one
    * @param i_flg_std_diag            flag which indicates if the diagnosis is the standard one or one of the synonyms
    * @param i_epis_diag               When filled adds additional information to diagnosis, for instance, the state description and date (ALERT-81543)
    * @param i_flg_past_hist           Flag used to include past history info
    * @param i_flg_search_mode         Flag to indicate if this is a search mode query
    * @param i_format_bold             Formats the staging description to bold: (Y)es or (N)o
    * @param i_code_staging            Staging code
    *
    * @return                 formatted text containing the tnm description
    * 
    * @author                 Jos?Silva
    * @version                2.6.2.1
    * @since                  18/Mar/2012
    **********************************************************************************************/
    FUNCTION std_tnm_desc
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_alert_diagnosis  IN alert_diagnosis.id_alert_diagnosis%TYPE DEFAULT NULL,
        i_id_diagnosis        IN diagnosis.id_diagnosis%TYPE DEFAULT NULL,
        i_code_diagnosis      IN diagnosis.code_diagnosis%TYPE DEFAULT NULL,
        i_diagnosis_language  IN language.id_language%TYPE DEFAULT NULL,
        i_id_task_type        IN task_type.id_task_type%TYPE DEFAULT pk_alert_constant.g_task_diagnosis,
        i_desc_epis_diagnosis IN epis_diagnosis.desc_epis_diagnosis%TYPE DEFAULT NULL,
        i_code                IN diagnosis.code_icd%TYPE,
        i_flg_other           IN diagnosis.flg_other%TYPE,
        i_flg_std_diag        IN alert_diagnosis.flg_icd9%TYPE,
        i_epis_diag           IN epis_diagnosis.id_epis_diagnosis%TYPE DEFAULT NULL,
        i_flg_past_hist       IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_flg_search_mode     IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_format_bold         IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_code_staging        IN diagnosis.code_icd%TYPE DEFAULT NULL
    ) RETURN VARCHAR2 IS
        l_description pk_translation.t_desc_translation;
        l_descr       pk_translation.t_desc_translation;
        l_code        diagnosis.code_icd%TYPE;
    BEGIN
        l_code := i_code_staging || i_code;
    
        IF i_format_bold = pk_alert_constant.g_yes
        THEN
            l_description := pk_utils.to_bold(l_code);
        ELSE
            l_description := l_code;
        END IF;
    
        l_descr := pk_diagnosis.std_diag_desc(i_lang                => i_lang,
                                              i_prof                => i_prof,
                                              i_id_alert_diagnosis  => i_id_alert_diagnosis,
                                              i_id_diagnosis        => i_id_diagnosis,
                                              i_code_diagnosis      => i_code_diagnosis,
                                              i_diagnosis_language  => i_diagnosis_language,
                                              i_id_task_type        => i_id_task_type,
                                              i_desc_epis_diagnosis => i_desc_epis_diagnosis,
                                              i_code                => NULL,
                                              i_flg_other           => i_flg_other,
                                              i_flg_std_diag        => i_flg_std_diag,
                                              i_epis_diag           => i_epis_diag,
                                              i_flg_past_hist       => i_flg_past_hist,
                                              i_flg_search_mode     => i_flg_search_mode);
    
        l_description := l_description || CASE
                             WHEN l_descr IS NOT NULL THEN
                              ' - ' || l_descr
                             ELSE
                              NULL
                         END;
    
        RETURN l_description;
    
    END std_tnm_desc;
    --
    /********************************************************************************************
    * builds a standard formatted description for the staging basis field
    *
    * @param i_lang                    language id
    * @param i_prof                    professional id (type: professional id, institution id and software id)
    * @param i_id_alert_diagnosis      Alert Diagnosis ID
    * @param i_id_diagnosis            Diagnosis ID
    * @param i_code_diagnosis          Diagnosis Code
    * @param i_diagnosis_language      Diagnosis Language
    * @param i_id_task_type            Functional area from where the translation was requested. 
    * @param i_desc_epis_diagnosis     Diagnosis Free-text description
    * @param i_code                    Diagnosis code
    * @param i_flg_other               flag which indicates if the diagnosis is "Other" or an official one
    * @param i_flg_std_diag            flag which indicates if the diagnosis is the standard one or one of the synonyms
    * @param i_epis_diag               When filled adds additional information to diagnosis, for instance, the state description and date (ALERT-81543)
    * @param i_flg_past_hist           Flag used to include past history info
    * @param i_flg_search_mode         Flag to indicate if this is a search mode query
    *
    * @return                 formatted text containing the tnm description
    * 
    * @author                 Jos?Silva
    * @version                2.6.2.1
    * @since                  27/Mar/2012
    **********************************************************************************************/
    FUNCTION std_diag_basis_desc
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_alert_diagnosis  IN alert_diagnosis.id_alert_diagnosis%TYPE DEFAULT NULL,
        i_id_diagnosis        IN diagnosis.id_diagnosis%TYPE,
        i_code_diagnosis      IN diagnosis.code_diagnosis%TYPE DEFAULT NULL,
        i_diagnosis_language  IN language.id_language%TYPE DEFAULT NULL,
        i_id_task_type        IN task_type.id_task_type%TYPE DEFAULT pk_alert_constant.g_task_diagnosis,
        i_desc_epis_diagnosis IN epis_diagnosis.desc_epis_diagnosis%TYPE DEFAULT NULL,
        i_code                IN diagnosis.code_icd%TYPE,
        i_flg_other           IN diagnosis.flg_other%TYPE,
        i_flg_std_diag        IN alert_diagnosis.flg_icd9%TYPE,
        i_epis_diag           IN epis_diagnosis.id_epis_diagnosis%TYPE DEFAULT NULL,
        i_flg_past_hist       IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_flg_search_mode     IN VARCHAR2 DEFAULT pk_alert_constant.g_no
    ) RETURN VARCHAR2 IS
        l_description pk_translation.t_desc_translation;
        l_parent      diagnosis.id_diagnosis%TYPE;
    
    BEGIN
        l_parent := pk_diagnosis.get_diagnosis_parent(i_diagnosis   => i_id_diagnosis,
                                                      i_institution => i_prof.institution,
                                                      i_software    => i_prof.software);
    
        IF l_parent IS NOT NULL
        THEN
            l_description := pk_diagnosis.std_diag_desc(i_lang               => i_lang,
                                                        i_prof               => i_prof,
                                                        i_id_diagnosis       => l_parent,
                                                        i_diagnosis_language => i_diagnosis_language,
                                                        i_code               => NULL,
                                                        i_flg_other          => pk_alert_constant.g_no,
                                                        i_flg_std_diag       => pk_alert_constant.g_yes,
                                                        i_flg_search_mode    => pk_alert_constant.g_yes) || ' - ';
        END IF;
    
        l_description := l_description ||
                         pk_diagnosis.std_diag_desc(i_lang                => i_lang,
                                                    i_prof                => i_prof,
                                                    i_id_alert_diagnosis  => i_id_alert_diagnosis,
                                                    i_id_diagnosis        => i_id_diagnosis,
                                                    i_code_diagnosis      => i_code_diagnosis,
                                                    i_diagnosis_language  => i_diagnosis_language,
                                                    i_id_task_type        => i_id_task_type,
                                                    i_desc_epis_diagnosis => i_desc_epis_diagnosis,
                                                    i_code                => i_code,
                                                    i_flg_other           => i_flg_other,
                                                    i_flg_std_diag        => i_flg_std_diag,
                                                    i_epis_diag           => i_epis_diag,
                                                    i_flg_past_hist       => i_flg_past_hist,
                                                    i_flg_search_mode     => i_flg_search_mode);
    
        RETURN l_description;
    
    END std_diag_basis_desc;
    --
    /********************************************************************************************
    * Altera o estado de um problema que est?associado a um diagn�stico
      Esta fun��o deixou de ser usada, agora elimina-se o problema em vez de alterar o seu estado
    *
    * @param i_lang                   ID da l�ngua
    * @param i_prof                   Objecto (id do profissional, id da institui��o, id do software)
    * @param i_epis                   ID do epis�dio
    * @param i_epis_diag              ID do diagn�stico associado ao epis�dio
    * @param i_flg_status             Novo estado do problema
    * @param o_error                  Error message
    * 
    * @return                         true or false para sucesso ou erro
    * 
    * @author                         Luis Oliveira
    * @version                        1.0   
    * @since                          2007/06/20
    **********************************************************************************************/
    FUNCTION set_prob_assoc_diag_status_int
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_epis       IN episode.id_episode%TYPE,
        i_epis_diag  IN epis_diagnosis.id_epis_diagnosis%TYPE,
        i_flg_status IN pat_problem.flg_status%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id_patient     patient.id_patient%TYPE;
        l_prof_cat_type  category.flg_type%TYPE;
        l_id_problem     pat_problem.id_pat_problem%TYPE;
        l_id_pat_problem table_number;
        l_flg_status_pp  table_varchar;
        l_notes_pp       table_varchar;
        l_type_pp        table_varchar;
        l_flg_nature_pp  table_varchar;
    
        -- Determinar o id do problema associado ao diagn�stico
        CURSOR c_problem IS
            SELECT pp.id_pat_problem
              FROM pat_problem pp
             WHERE pp.id_epis_diagnosis = i_epis_diag;
    
    BEGIN
        g_sysdate_tstz := current_timestamp;
        --    
        g_error := 'GET CURSOR C_PROBLEM';
        OPEN c_problem;
        FETCH c_problem
            INTO l_id_problem;
        CLOSE c_problem;
        --
        IF l_id_problem IS NOT NULL
        THEN
        
            g_error := 'GET ID_PATIENT';
            SELECT e.id_patient
              INTO l_id_patient
              FROM episode e
              JOIN epis_diagnosis ed
                ON ed.id_episode = e.id_episode
             WHERE ed.id_epis_diagnosis = i_epis_diag;
            --
            -- Constroi os table para fazer poder alterar o estado do problema
            l_id_pat_problem := table_number();
            l_id_pat_problem.extend;
            l_id_pat_problem(1) := l_id_problem;
        
            l_flg_status_pp := table_varchar();
            l_flg_status_pp.extend;
            l_flg_status_pp(1) := i_flg_status;
        
            l_notes_pp := table_varchar();
            l_notes_pp.extend;
            l_notes_pp(1) := NULL;
        
            l_type_pp := table_varchar();
            l_type_pp.extend;
            l_type_pp(1) := 'P';
        
            l_prof_cat_type := NULL;
        
            l_flg_nature_pp := table_varchar();
            l_flg_nature_pp.extend;
            l_flg_nature_pp(1) := NULL;
            --
            g_error := 'CALL pk_problems.set_pat_problem_array_internal';
            IF NOT pk_problems.set_pat_problem_array_internal(i_lang,
                                                              i_epis,
                                                              l_id_patient,
                                                              i_prof,
                                                              l_id_pat_problem,
                                                              l_flg_status_pp,
                                                              l_notes_pp,
                                                              l_type_pp,
                                                              l_prof_cat_type,
                                                              l_flg_nature_pp,
                                                              NULL,
                                                              NULL,
                                                              o_error)
            THEN
                RAISE e_call_exception;
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_DIAGNOSIS',
                                              'SET_PROB_ASSOC_DIAG_STATUS_INT',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_prob_assoc_diag_status_int;
    --
    /** @headcom
    * Public Function. Obter os id's dos diagn�sticos associados a uma requisi��o.
    * N�o ?chamada pelo Flash.
    *
    * @param      I_LANG               L�ngua registada como prefer�ncia do profissional
    * @param      I_EXAM_REQ     ID da requisi��o de exames.
    * @param      I_ANALYSIS_REQ   ID da requisi��o de an�lises.
    * @param      I_INTERV_PRESC   ID da requisi��o de procedimentos.
    * @param      I_DRUG_PRESC     ID da requisi��o de medicamentos.
    * @param      I_DRUG_REQ     ID da requisi��o de medicamentos ?farm�cia.
    * @param      I_PRESCRIPTION   ID da prescri��o de medicamentos para o exterior.
    * @param      I_PRESCRIPTION_USA   ID da prescri��o de medicamentos para o exterior (vers�o USA).
    * @param      I_PROF         object (ID do profissional, ID da institui��o, ID do software)
    *
    * @return     boolean
    * @author     Gustavo Serrano
    * @version    0.1
    * @since      2008/05/27
    */
    FUNCTION concat_diag_id_str
    (
        i_lang                   IN language.id_language%TYPE,
        i_exam_req_det           IN exam_req_det.id_exam_req_det%TYPE,
        i_analysis_req_det       IN analysis_req_det.id_analysis_req_det%TYPE,
        i_interv_presc_det       IN interv_presc_det.id_interv_presc_det%TYPE,
        i_prof                   IN profissional,
        i_type                   IN VARCHAR2,
        i_nurse_tea_req          IN nurse_tea_req.id_nurse_tea_req%TYPE DEFAULT NULL,
        i_exam_result            IN exam_result.id_exam_result%TYPE DEFAULT NULL,
        i_blood_product_det      IN blood_product_det.id_blood_product_det%TYPE DEFAULT NULL,
        i_rehab_presc            IN rehab_presc.id_rehab_presc%TYPE DEFAULT NULL,
        i_flg_terminology_server IN VARCHAR2 DEFAULT pk_alert_constant.g_no
    ) RETURN VARCHAR2 IS
        l_desc  VARCHAR2(4000);
        l_first BOOLEAN := TRUE;
    
        l_tbl_diag table_varchar;
    BEGIN
        l_tbl_diag := pk_diagnosis.concat_diag_id(i_lang                   => i_lang,
                                                  i_exam_req_det           => i_exam_req_det,
                                                  i_analysis_req_det       => i_analysis_req_det,
                                                  i_interv_presc_det       => i_interv_presc_det,
                                                  i_prof                   => i_prof,
                                                  i_type                   => i_type,
                                                  i_nurse_tea_req          => i_nurse_tea_req,
                                                  i_exam_result            => i_exam_result,
                                                  i_blood_product_det      => i_blood_product_det,
                                                  i_rehab_presc            => i_rehab_presc,
                                                  i_show_aditional_info    => pk_alert_constant.g_no,
                                                  i_flg_terminology_server => i_flg_terminology_server);
    
        IF l_tbl_diag IS NOT NULL
           AND l_tbl_diag.count > 0
        THEN
            FOR i IN l_tbl_diag.first .. l_tbl_diag.last
            LOOP
                IF l_first
                THEN
                    l_first := FALSE;
                ELSE
                    l_desc := l_desc || '; ';
                END IF;
                l_desc := l_desc || l_tbl_diag(i);
            END LOOP;
        END IF;
    
        RETURN l_desc;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.reset_error_state;
            RETURN NULL;
    END concat_diag_id_str;

    FUNCTION concat_diag_hist_id_str
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_type               IN VARCHAR2,
        i_nurse_tea_req_hist IN nurse_tea_req.id_nurse_tea_req%TYPE DEFAULT NULL
    ) RETURN VARCHAR2 IS
        l_desc  VARCHAR2(4000);
        l_first BOOLEAN := TRUE;
    
        l_tbl_diag table_varchar;
    BEGIN
        l_tbl_diag := pk_diagnosis.concat_diag_hist_id(i_lang               => i_lang,
                                                       i_prof               => i_prof,
                                                       i_type               => i_type,
                                                       i_nurse_tea_req_hist => i_nurse_tea_req_hist);
    
        IF l_tbl_diag IS NOT NULL
           AND l_tbl_diag.count > 0
        THEN
            FOR i IN l_tbl_diag.first .. l_tbl_diag.last
            LOOP
                IF l_first
                THEN
                    l_first := FALSE;
                ELSE
                    l_desc := l_desc || '; ';
                END IF;
                l_desc := l_desc || l_tbl_diag(i);
            END LOOP;
        END IF;
    
        RETURN l_desc;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.reset_error_state;
            RETURN NULL;
    END concat_diag_hist_id_str;

    /** @headcom
    * Public Function. Obter os id's dos diagn�sticos associados a uma requisi��o.
    * N�o ?chamada pelo Flash.
    *
    * @param      I_LANG               L�ngua registada como prefer�ncia do profissional
    * @param      I_EXAM_REQ     ID da requisi��o de exames.
    * @param      I_ANALYSIS_REQ   ID da requisi��o de an�lises.
    * @param      I_INTERV_PRESC   ID da requisi��o de procedimentos.
    * @param      I_PROF         object (ID do profissional, ID da institui��o, ID do software)
    *
    * @return     boolean
    * @author     Gustavo Serrano
    * @version    0.1
    * @since      2008/05/27
    */
    FUNCTION concat_diag_id
    (
        i_lang                   IN language.id_language%TYPE,
        i_exam_req_det           IN exam_req_det.id_exam_req_det%TYPE,
        i_analysis_req_det       IN analysis_req_det.id_analysis_req_det%TYPE,
        i_interv_presc_det       IN interv_presc_det.id_interv_presc_det%TYPE,
        i_prof                   IN profissional,
        i_type                   IN VARCHAR2,
        i_nurse_tea_req          IN nurse_tea_req.id_nurse_tea_req%TYPE DEFAULT NULL,
        i_exam_result            IN exam_result.id_exam_result%TYPE DEFAULT NULL,
        i_blood_product_det      IN blood_product_det.id_blood_product_det%TYPE DEFAULT NULL,
        i_rehab_presc            IN rehab_presc.id_rehab_presc%TYPE DEFAULT NULL,
        i_show_aditional_info    IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        i_flg_terminology_server IN VARCHAR2 DEFAULT pk_alert_constant.g_no
    ) RETURN table_varchar IS
        --
        CURSOR c_desc IS
        
            SELECT mrd.id_diagnosis,
                   d.code_icd,
                   CASE i_flg_terminology_server
                        WHEN pk_alert_constant.g_no THEN
                         (SELECT std_diag_desc(i_lang                => i_lang,
                                               i_prof                => i_prof,
                                               i_id_alert_diagnosis  => nvl(ed.id_alert_diagnosis, mrd.id_alert_diagnosis),
                                               i_id_diagnosis        => d.id_diagnosis,
                                               i_desc_epis_diagnosis => ed.desc_epis_diagnosis,
                                               i_code                => d.code_icd,
                                               i_flg_other           => d.flg_other,
                                               i_flg_std_diag        => g_yes,
                                               i_epis_diag           => ed.id_epis_diagnosis,
                                               i_show_aditional_info => i_show_aditional_info)
                            FROM dual)
                        ELSE
                         coalesce(ed.desc_epis_diagnosis,
                                  pk_ts3_search.get_term_description(i_id_language     => i_lang,
                                                                     i_id_institution  => i_prof.institution,
                                                                     i_id_software     => i_prof.software,
                                                                     i_id_concept_term => nvl(ed.id_alert_diagnosis,
                                                                                              mrd.id_alert_diagnosis),
                                                                     i_concept_type    => CASE
                                                                                              WHEN ed.desc_epis_diagnosis IS NULL THEN
                                                                                               'DIAGNOSIS'
                                                                                              ELSE
                                                                                               'OTHER_DIAGNOSIS'
                                                                                          END,
                                                                     i_id_task_type    => 63,
                                                                     i_context_type    => 'SEARCHABLE',
                                                                     i_free_text_desc  => ed.desc_epis_diagnosis))
                    END desc_diagnosis,
                   ed.id_epis_diagnosis,
                   ed.id_alert_diagnosis
              FROM (SELECT *
                      FROM mcdt_req_diagnosis mrd
                     WHERE mrd.id_exam_req_det = i_exam_req_det
                       AND i_exam_req_det IS NOT NULL
                    UNION ALL
                    SELECT *
                      FROM mcdt_req_diagnosis mrd
                     WHERE mrd.id_analysis_req_det = i_analysis_req_det
                       AND i_analysis_req_det IS NOT NULL
                    UNION ALL
                    SELECT *
                      FROM mcdt_req_diagnosis mrd
                     WHERE mrd.id_interv_presc_det = i_interv_presc_det
                       AND i_interv_presc_det IS NOT NULL
                    UNION ALL
                    SELECT *
                      FROM mcdt_req_diagnosis mrd
                     WHERE mrd.id_nurse_tea_req = i_nurse_tea_req
                       AND i_nurse_tea_req IS NOT NULL
                    UNION ALL
                    SELECT *
                      FROM mcdt_req_diagnosis mrd
                     WHERE mrd.id_exam_result = i_exam_result
                       AND i_exam_result IS NOT NULL
                    UNION ALL
                    SELECT *
                      FROM mcdt_req_diagnosis mrd
                     WHERE mrd.id_blood_product_det = i_blood_product_det
                       AND i_blood_product_det IS NOT NULL
                    UNION ALL
                    SELECT *
                      FROM mcdt_req_diagnosis mrd
                     WHERE mrd.id_rehab_presc = i_rehab_presc
                       AND i_rehab_presc IS NOT NULL) mrd
              LEFT JOIN epis_diagnosis ed
                ON ed.id_epis_diagnosis = mrd.id_epis_diagnosis
              JOIN diagnosis d
                ON d.id_diagnosis = mrd.id_diagnosis
             WHERE (nvl(mrd.flg_status, 'z') != g_mcdt_cancel)
             ORDER BY 3;
    
        r_desc c_desc%ROWTYPE;
    
        l_desc table_varchar;
    BEGIN
        l_desc  := table_varchar();
        g_error := 'LOOP';
        FOR r_desc IN c_desc
        LOOP
            IF (i_type = 'C')
            THEN
                l_desc.extend;
                l_desc(l_desc.count) := r_desc.code_icd;
            ELSIF (i_type = 'D')
            THEN
                l_desc.extend;
                l_desc(l_desc.count) := r_desc.id_diagnosis;
            ELSIF (i_type = 'T')
            THEN
                l_desc.extend;
                l_desc(l_desc.count) := r_desc.desc_diagnosis;
            ELSIF (i_type = 'E')
            THEN
                l_desc.extend;
                l_desc(l_desc.count) := r_desc.id_epis_diagnosis;
            ELSIF (i_type = 'S')
            THEN
                l_desc.extend;
                l_desc(l_desc.count) := r_desc.id_alert_diagnosis;
            END IF;
        END LOOP;
        --
        RETURN l_desc;
        --
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.reset_error_state;
            RETURN NULL;
    END concat_diag_id;

    FUNCTION concat_diag_hist_id
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_type               IN VARCHAR2,
        i_nurse_tea_req_hist IN nurse_tea_req.id_nurse_tea_req%TYPE DEFAULT NULL
    ) RETURN table_varchar IS
    
        CURSOR c_desc IS
            SELECT id_diagnosis, code_icd, desc_diagnosis, id_epis_diagnosis, id_alert_diagnosis
              FROM (SELECT ntd.id_diagnosis,
                           d.code_icd,
                           pk_diagnosis.std_diag_desc(i_lang                => i_lang,
                                                      i_prof                => i_prof,
                                                      i_id_alert_diagnosis  => ed.id_alert_diagnosis,
                                                      i_id_diagnosis        => d.id_diagnosis,
                                                      i_desc_epis_diagnosis => ed.desc_epis_diagnosis,
                                                      i_code                => d.code_icd,
                                                      i_flg_other           => d.flg_other,
                                                      i_flg_std_diag        => 'Y',
                                                      i_epis_diag           => ed.id_epis_diagnosis) desc_diagnosis,
                           ed.id_epis_diagnosis,
                           ed.id_alert_diagnosis,
                           row_number() over(PARTITION BY ntd.id_diagnosis, d.code_icd ORDER BY ed.id_epis_diagnosis DESC) AS rn
                      FROM nurse_tea_req_diag_hist ntd
                      JOIN diagnosis d
                        ON d.id_diagnosis = ntd.id_diagnosis
                      JOIN epis_diagnosis ed
                        ON ed.id_diagnosis = d.id_diagnosis
                       AND ed.id_episode = (SELECT DISTINCT nr.id_episode
                                              FROM nurse_tea_req_hist nrh
                                              JOIN nurse_tea_req nr
                                                ON nr.id_nurse_tea_req = nrh.id_nurse_tea_req
                                             WHERE nrh.id_nurse_tea_req_hist = i_nurse_tea_req_hist)
                     WHERE ntd.id_nurse_tea_req_hist = i_nurse_tea_req_hist
                     ORDER BY ed.id_epis_diagnosis DESC)
             WHERE rn = 1
             ORDER BY 3;
    
        r_desc          c_desc%ROWTYPE;
        l_desc          table_varchar;
        l_nurse_tea_req nurse_tea_req.id_nurse_tea_req%TYPE;
    
    BEGIN
        l_desc  := table_varchar();
        g_error := 'LOOP';
    
        FOR r_desc IN c_desc
        LOOP
            IF (i_type = 'C')
            THEN
                l_desc.extend;
                l_desc(l_desc.count) := r_desc.code_icd;
            ELSIF (i_type = 'D')
            THEN
                l_desc.extend;
                l_desc(l_desc.count) := r_desc.id_diagnosis;
            ELSIF (i_type = 'T')
            THEN
                l_desc.extend;
                l_desc(l_desc.count) := r_desc.desc_diagnosis;
            ELSIF (i_type = 'E')
            THEN
                l_desc.extend;
                l_desc(l_desc.count) := r_desc.id_epis_diagnosis;
            ELSIF (i_type = 'S')
            THEN
                l_desc.extend;
                l_desc(l_desc.count) := r_desc.id_alert_diagnosis;
            END IF;
        END LOOP;
    
        RETURN l_desc;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.reset_error_state;
            RETURN NULL;
    END concat_diag_hist_id;

    /** @headcom
    * Public Function. Obter os id's dos diagn�sticos associados a uma requisi��o.
    * N�o ?chamada pelo Flash.
    *
    * @param      I_LANG               L�ngua registada como prefer�ncia do profissional
    * @param      I_EXAM_REQ     table_number of ID da requisi��o de exames.
    * @param      I_ANALYSIS_REQ   table_number of ID da requisi��o de an�lises.
    * @param      I_INTERV_PRESC   table_number of ID da requisi��o de procedimentos.
    * @param      I_PROF         object (ID do profissional, ID da institui��o, ID do software)
    *
    * @return     boolean
    * @author     Gustavo Serrano
    * @version    0.1
    * @since      2009/04/26
    */
    FUNCTION concat_diag_id
    (
        i_lang              IN language.id_language%TYPE,
        i_exam_req_det      IN table_number,
        i_analysis_req_det  IN table_number,
        i_interv_presc_det  IN table_number,
        i_prof              IN profissional,
        i_type              IN VARCHAR2,
        i_nurse_tea_req     IN table_number DEFAULT NULL,
        i_exam_result       IN table_number DEFAULT NULL,
        i_blood_product_det IN table_number DEFAULT NULL,
        i_rehab_presc       IN table_number DEFAULT NULL
    ) RETURN table_varchar IS
        l_desc table_varchar := table_varchar();
        --
        l_exception EXCEPTION;
    BEGIN
        IF i_exam_req_det IS NOT NULL
           AND i_exam_req_det.count > 0
        THEN
            FOR i IN i_exam_req_det.first .. i_exam_req_det.last
            LOOP
                l_desc := l_desc MULTISET UNION ALL
                          pk_diagnosis.concat_diag_id(i_lang             => i_lang,
                                                      i_exam_req_det     => i_exam_req_det(i),
                                                      i_analysis_req_det => NULL,
                                                      i_interv_presc_det => NULL,
                                                      i_prof             => i_prof,
                                                      i_type             => i_type);
            END LOOP;
        END IF;
    
        IF i_analysis_req_det IS NOT NULL
           AND i_analysis_req_det.count > 0
        THEN
            FOR i IN i_analysis_req_det.first .. i_analysis_req_det.last
            LOOP
                l_desc := l_desc MULTISET UNION ALL
                          pk_diagnosis.concat_diag_id(i_lang             => i_lang,
                                                      i_exam_req_det     => NULL,
                                                      i_analysis_req_det => i_analysis_req_det(i),
                                                      i_interv_presc_det => NULL,
                                                      i_prof             => i_prof,
                                                      i_type             => i_type);
            END LOOP;
        END IF;
    
        IF i_interv_presc_det IS NOT NULL
           AND i_interv_presc_det.count > 0
        THEN
            FOR i IN i_interv_presc_det.first .. i_interv_presc_det.last
            LOOP
                l_desc := l_desc MULTISET UNION ALL
                          pk_diagnosis.concat_diag_id(i_lang             => i_lang,
                                                      i_exam_req_det     => NULL,
                                                      i_analysis_req_det => NULL,
                                                      i_interv_presc_det => i_interv_presc_det(i),
                                                      i_prof             => i_prof,
                                                      i_type             => i_type);
            END LOOP;
        END IF;
    
        IF i_nurse_tea_req IS NOT NULL
           AND i_nurse_tea_req.count > 0
        THEN
            FOR i IN i_nurse_tea_req.first .. i_nurse_tea_req.last
            LOOP
                l_desc := l_desc MULTISET UNION ALL
                          pk_diagnosis.concat_diag_id(i_lang             => i_lang,
                                                      i_exam_req_det     => NULL,
                                                      i_analysis_req_det => NULL,
                                                      i_interv_presc_det => NULL,
                                                      i_prof             => i_prof,
                                                      i_type             => i_type,
                                                      i_nurse_tea_req    => i_nurse_tea_req(i));
            END LOOP;
        END IF;
    
        IF i_exam_result IS NOT NULL
           AND i_exam_result.count > 0
        THEN
            FOR i IN i_exam_result.first .. i_exam_result.last
            LOOP
                l_desc := l_desc MULTISET UNION ALL
                          pk_diagnosis.concat_diag_id(i_lang             => i_lang,
                                                      i_exam_req_det     => NULL,
                                                      i_analysis_req_det => NULL,
                                                      i_interv_presc_det => NULL,
                                                      i_prof             => i_prof,
                                                      i_type             => i_type,
                                                      i_nurse_tea_req    => NULL,
                                                      i_exam_result      => i_exam_result(i));
            END LOOP;
        
        END IF;
    
        IF i_blood_product_det IS NOT NULL
           AND i_blood_product_det.count > 0
        THEN
            FOR i IN i_blood_product_det.first .. i_blood_product_det.last
            LOOP
                l_desc := l_desc MULTISET UNION ALL
                          pk_diagnosis.concat_diag_id(i_lang              => i_lang,
                                                      i_exam_req_det      => NULL,
                                                      i_analysis_req_det  => NULL,
                                                      i_interv_presc_det  => NULL,
                                                      i_prof              => i_prof,
                                                      i_type              => i_type,
                                                      i_nurse_tea_req     => NULL,
                                                      i_exam_result       => NULL,
                                                      i_blood_product_det => i_blood_product_det(i));
            END LOOP;
        
        END IF;
    
        IF i_rehab_presc IS NOT NULL
           AND i_rehab_presc.count > 0
        THEN
            FOR i IN i_rehab_presc.first .. i_rehab_presc.last
            LOOP
                l_desc := l_desc MULTISET UNION ALL
                          pk_diagnosis.concat_diag_id(i_lang              => i_lang,
                                                      i_exam_req_det      => NULL,
                                                      i_analysis_req_det  => NULL,
                                                      i_interv_presc_det  => NULL,
                                                      i_prof              => i_prof,
                                                      i_type              => i_type,
                                                      i_nurse_tea_req     => NULL,
                                                      i_exam_result       => NULL,
                                                      i_blood_product_det => NULL,
                                                      i_rehab_presc       => i_rehab_presc(i));
            END LOOP;
        
        END IF;
    
        RETURN l_desc;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.reset_error_state;
            RETURN NULL;
    END concat_diag_id;

    /********************************************************************************************
    * Function that returns diagnosis for an episode
    *
    * @param i_lang                   language ID
    * @param i_prof                   Object (professional, Institution and Software)
    * @param i_id_episode             episode ID
    *
    * @param o_diag                   Cursor with diagnoses' information
    * @param o_error                  Error message
    *
    * @return                         true or false para sucesso ou erro
    *
    * @author                         Jos?Silva
    * @version                        2.6.1.2
    * @since                          2011/08/16
    **********************************************************************************************/
    FUNCTION get_epis_diag
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_diag    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        RETURN pk_diagnosis_core.get_epis_diag(i_lang           => i_lang,
                                               i_prof           => i_prof,
                                               i_id_episode     => table_number(i_episode),
                                               i_show_cancelled => pk_alert_constant.g_no,
                                               o_diag           => o_diag,
                                               o_error          => o_error);
    END get_epis_diag;

    /********************************************************************************************
    * Function that returns diagnosis for an episode array
    * Note : used in admission surgery request functionality
    * Based in get_epis_diag function
    *
    * @param i_lang                   language ID
    * @param i_prof                   Object (professional, Institution and Software)
    * @param i_id_episode             Array of episode ID
    *
    * @param o_diag                   Cursor with diagnoses' information
    * @param o_error                  Error message
    *
    * @return                         true or false para sucesso ou erro
    *
    * @author                         Filipe Silva
    * @version                        2.5.1.5  
    * @since                          2011/03/31
    **********************************************************************************************/
    FUNCTION get_epis_diag
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN table_number,
        o_diag       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        RETURN pk_diagnosis_core.get_epis_diag(i_lang           => i_lang,
                                               i_prof           => i_prof,
                                               i_id_episode     => i_id_episode,
                                               i_show_cancelled => pk_alert_constant.g_no,
                                               o_diag           => o_diag,
                                               o_error          => o_error);
    END get_epis_diag;
    --

    /********************************************************************************************
    * Get diagnosis description (having in consideration that it can be an episode diagnosis)
    * (only used by the order sets tool)
    *
    * @param    i_lang             preferred language ID
    * @param    i_prof             object (id of professional, id of institution, id of software)
    * @param    i_episode          episode ID
    * @param    i_diagnosis        diagnosis ID
    * @param    i_alert_diagnosis  alert diagnosis ID      
    *
    * @return   varchar2       diagnosis description
    *
    * @author   Tiago Silva
    * @since    2010/08/06
    ********************************************************************************************/
    FUNCTION get_epis_diag_desc
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_episode         IN episode.id_episode%TYPE,
        i_diagnosis       IN diagnosis.id_diagnosis%TYPE,
        i_alert_diagnosis IN alert_diagnosis.id_alert_diagnosis%TYPE DEFAULT NULL
    ) RETURN pk_translation.t_desc_translation IS
        l_epis_diag_desc pk_translation.t_desc_translation;
    BEGIN
    
        g_error := 'GET EPIS DIAGNOSIS DESCRIPTION';
    
        SELECT std_diag_desc(i_lang                => i_lang,
                              i_prof                => i_prof,
                              i_id_alert_diagnosis  => (CASE
                                                           WHEN ad.id_alert_diagnosis IS NULL THEN
                                                            i_alert_diagnosis
                                                           ELSE
                                                            ad.id_alert_diagnosis
                                                       END),
                              i_id_diagnosis        => d.id_diagnosis,
                              i_desc_epis_diagnosis => ed.desc_epis_diagnosis,
                              i_code                => d.code_icd,
                              i_flg_other           => d.flg_other,
                              i_flg_std_diag        => ad.flg_icd9) diag_desc
          INTO l_epis_diag_desc
          FROM diagnosis d
          LEFT OUTER JOIN (SELECT ed.id_diagnosis,
                                  ed.flg_type,
                                  ed.flg_status,
                                  ed.id_alert_diagnosis,
                                  ed.desc_epis_diagnosis,
                                  row_number() over(PARTITION BY ed.id_diagnosis ORDER BY ed.flg_type) rn,
                                  ed.id_epis_diagnosis
                             FROM epis_diagnosis ed
                            WHERE ed.id_episode = i_episode
                              AND ed.flg_status NOT IN (g_epis_status_c, g_ed_flg_status_r)) ed
            ON (d.id_diagnosis = ed.id_diagnosis AND ed.rn = 1)
          LEFT OUTER JOIN alert_diagnosis ad
            ON (ad.id_alert_diagnosis = ed.id_alert_diagnosis)
         WHERE d.id_diagnosis = i_diagnosis;
    
        RETURN l_epis_diag_desc;
    
    END get_epis_diag_desc;

    /********************************************************************************************
    * Get diagnosis description (only used by the order sets tool)
    *
    * @param    i_lang             preferred language ID
    * @param    i_prof             object (id of professional, id of institution, id of software)
    * @param    i_episode          episode ID
    * @param    i_rec_diagnosis    diagnosis record
    *
    * @return   varchar2           diagnosis description
    *
    * @author   Tiago Silva
    * @since    2012/10/16
    ********************************************************************************************/
    FUNCTION get_diag_desc
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_rec_diagnosis IN pk_edis_types.rec_in_diagnosis
    ) RETURN pk_translation.t_desc_translation IS
        l_epis_diag_desc     pk_translation.t_desc_translation;
        l_id_diagnosis       diagnosis.id_diagnosis%TYPE;
        l_id_alert_diagnosis alert_diagnosis.id_alert_diagnosis%TYPE;
    BEGIN
    
        -- get diagnosis ids    
        l_id_diagnosis       := i_rec_diagnosis.id_diagnosis;
        l_id_alert_diagnosis := i_rec_diagnosis.id_alert_diagnosis;
    
        l_epis_diag_desc := get_diag_desc(i_lang               => i_lang,
                                          i_prof               => i_prof,
                                          i_id_diagnosis       => l_id_diagnosis,
                                          i_id_alert_diagnosis => l_id_alert_diagnosis);
    
        RETURN l_epis_diag_desc;
    
    END get_diag_desc;
    --
    /********************************************************************************************
    * Get diagnosis description (only used by the order sets tool)
    *
    * @param    i_lang                 preferred language ID
    * @param    i_prof                 object (id of professional, id of institution, id of software)
    * @param    i_episode              episode ID
    * @param    i_id_diagnosis         diagnosis ID
    * @param    i_id_alert_diagnosis   alert diagnosis ID    
    *
    * @return   varchar2           diagnosis description
    *
    * @author   Tiago Silva
    * @since    2012/10/16
    ********************************************************************************************/
    FUNCTION get_diag_desc
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_diagnosis       IN diagnosis.id_diagnosis%TYPE,
        i_id_alert_diagnosis IN alert_diagnosis.id_alert_diagnosis%TYPE
    ) RETURN pk_translation.t_desc_translation IS
        l_epis_diag_desc pk_translation.t_desc_translation;
    BEGIN
    
        g_error := 'GET DIAGNOSIS DESCRIPTION';
    
        SELECT std_diag_desc(i_lang               => i_lang,
                             i_prof               => i_prof,
                             i_id_alert_diagnosis => ad.id_alert_diagnosis,
                             i_id_diagnosis       => d.id_diagnosis,
                             i_code               => d.code_icd,
                             i_flg_other          => d.flg_other,
                             i_flg_std_diag       => ad.flg_icd9) diag_desc
          INTO l_epis_diag_desc
          FROM diagnosis d
          LEFT OUTER JOIN alert_diagnosis ad
            ON (ad.id_diagnosis = d.id_diagnosis)
         WHERE d.id_diagnosis = i_id_diagnosis
           AND ad.id_alert_diagnosis = i_id_alert_diagnosis;
    
        RETURN l_epis_diag_desc;
    
    END get_diag_desc;
    --
    /********************************************************************************************
    * Function that includes all business rules related to diagnosis episode match
    *
    * @param i_lang                   language ID
    * @param i_prof                   Object (professional, Institution and Software)
    * @param i_new_epis               New episode ID
    * @param i_old_epis               Old episode ID
    * @param o_error                  Error message
    *
    * @return                         true or false para sucesso ou erro
    *
    * @author                         Jos?Silva
    * @version                        1.0   
    * @since                          2009/07/09
    **********************************************************************************************/
    FUNCTION set_match_diagnosis
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_new_epis IN episode.id_episode%TYPE,
        i_old_epis IN episode.id_episode%TYPE,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_rowids            table_varchar := table_varchar();
        l_id_epis_diagnosis epis_diagnosis.id_epis_diagnosis%TYPE;
    
        l_count NUMBER;
    
        l_tbl_dup_ediag  table_number;
        l_tbl_diag_notes table_number;
    
        TYPE table_map_pk IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;
        l_tbl_dup_ediag_map table_map_pk;
    
        PROCEDURE get_duplicated_diags
        (
            o_tbl_dup_ediag     OUT table_number,
            o_tbl_map_epis_diag OUT table_map_pk
        ) IS
            g_null_replace_value CONSTANT PLS_INTEGER := -999;
            --
            l_tbl_duplicated table_number := table_number();
            l_tbl_map        table_map_pk;
        BEGIN
            g_error := 'LOOP DUPLICATED DIAGS AND FILL OUTPUT TABLES';
            pk_alertlog.log_debug(text => g_error);
            FOR r_diag IN (SELECT ed_old.id_epis_diagnosis old_epis_diag, ed_new.id_epis_diagnosis new_epis_diag
                             FROM epis_diagnosis ed_old
                             JOIN diagnosis d
                               ON d.id_diagnosis = ed_old.id_diagnosis
                             JOIN epis_diagnosis ed_new
                               ON ed_new.id_episode = i_new_epis
                              AND ed_new.id_diagnosis = ed_old.id_diagnosis
                              AND ed_new.flg_type = ed_old.flg_type
                                 --Other diagnosis
                              AND ((ed_new.desc_epis_diagnosis = ed_old.desc_epis_diagnosis AND
                                  nvl(d.flg_other, pk_alert_constant.g_no) = pk_alert_constant.g_yes) OR
                                  (nvl(d.flg_other, pk_alert_constant.g_no) != pk_alert_constant.g_yes))
                                 --AE_Diagnosis
                              AND nvl(ed_new.id_diagnosis_condition, g_null_replace_value) =
                                  nvl(ed_old.id_diagnosis_condition, g_null_replace_value)
                              AND nvl(ed_new.id_sub_analysis, g_null_replace_value) =
                                  nvl(ed_old.id_sub_analysis, g_null_replace_value)
                              AND nvl(ed_new.id_anatomical_area, g_null_replace_value) =
                                  nvl(ed_old.id_anatomical_area, g_null_replace_value)
                              AND nvl(ed_new.id_anatomical_side, g_null_replace_value) =
                                  nvl(ed_old.id_anatomical_side, g_null_replace_value)
                            WHERE ed_old.id_episode = i_old_epis)
            LOOP
                l_tbl_duplicated.extend;
                l_tbl_duplicated(l_tbl_duplicated.count) := r_diag.old_epis_diag;
            
                l_tbl_map(r_diag.old_epis_diag) := r_diag.new_epis_diag;
            END LOOP;
        
            o_tbl_dup_ediag     := l_tbl_duplicated;
            o_tbl_map_epis_diag := l_tbl_map;
        END get_duplicated_diags;
    
        PROCEDURE update_ed_fk_references(i_tbl_map IN table_map_pk) IS
            l_old_epis_diag PLS_INTEGER;
            l_aux_sql       VARCHAR2(32767);
        BEGIN
            l_old_epis_diag := i_tbl_map.first;
            WHILE l_old_epis_diag IS NOT NULL
            LOOP
                IF i_tbl_map(l_old_epis_diag) IS NOT NULL
                THEN
                    FOR r_table IN (SELECT a.table_name,
                                           a.column_name,
                                           c.column_name ref_column,
                                           b.constraint_name,
                                           b.status
                                      FROM dba_cons_columns a
                                      JOIN dba_constraints b
                                        ON b.constraint_name = a.constraint_name
                                       AND b.table_name = a.table_name
                                       AND b.constraint_type = 'R'
                                      JOIN dba_cons_columns c
                                        ON c.constraint_name = b.r_constraint_name
                                     WHERE c.table_name = 'EPIS_DIAGNOSIS'
                                       AND a.table_name NOT IN ('PAT_PROBLEM',
                                                                'PAT_PROBLEM_HIST',
                                                                'EPIS_DIAGNOSIS_HIST',
                                                                'EPIS_DIAG_TUMORS_HIST',
                                                                'EPIS_DIAG_TUMORS',
                                                                'EPIS_DSTAG_PFACT_HIST',
                                                                'EPIS_DIAG_STAG_PFACT',
                                                                'EPIS_DIAG_STAG_HIST',
                                                                'EPIS_DIAG_STAG',
                                                                'EPIS_DIAGNOSIS_HIST'))
                    LOOP
                        DECLARE
                            l_insufficient_privileges EXCEPTION;
                            PRAGMA EXCEPTION_INIT(l_insufficient_privileges, -01031);
                        BEGIN
                            l_aux_sql := 'UPDATE ' || r_table.table_name || ' ' || --
                                         '   SET ' || r_table.column_name || ' = ' || i_tbl_map(l_old_epis_diag) || ' ' || --
                                         ' WHERE ' || r_table.column_name || ' = ' || l_old_epis_diag;
                        
                            EXECUTE IMMEDIATE l_aux_sql;
                        EXCEPTION
                            WHEN l_insufficient_privileges THEN
                                pk_alertlog.log_error('INSUFFICIENT PRIVILEGES: ' || l_aux_sql);
                        END;
                    END LOOP;
                END IF;
            
                l_old_epis_diag := i_tbl_map.next(l_old_epis_diag);
            END LOOP;
        END update_ed_fk_references;
    BEGIN
        g_error := 'COUNT PRIMARY DIAGNOSIS';
        pk_alertlog.log_debug(text => g_error);
        SELECT COUNT(*)
          INTO l_count
          FROM (SELECT ed.id_diagnosis
                  FROM epis_diagnosis ed
                 WHERE ed.id_episode IN (i_new_epis, i_old_epis)
                   AND ed.flg_status NOT IN (g_ed_flg_status_ca, g_ed_flg_status_r)
                   AND ed.flg_type = g_diag_type_d
                   AND ed.flg_final_type = g_flg_final_type_p
                 GROUP BY ed.id_diagnosis);
    
        IF l_count > 1
           AND nvl(pk_sysconfig.get_config('SINGLE_PRIMARY_DIAGNOSIS', i_prof), pk_alert_constant.g_yes) =
           pk_alert_constant.g_yes
        THEN
            RAISE e_primary_diag_exception;
        END IF;
    
        g_error := 'GET DUPLICATED EPIS_DIAGNOSIS';
        pk_alertlog.log_debug(text => g_error);
        get_duplicated_diags(o_tbl_dup_ediag => l_tbl_dup_ediag, o_tbl_map_epis_diag => l_tbl_dup_ediag_map);
    
        IF l_tbl_dup_ediag_map IS NOT NULL
        THEN
            g_error := 'UPDATE EPIS_DIAGNOSES FK REFERENCES';
            pk_alertlog.log_debug(text => g_error);
            update_ed_fk_references(i_tbl_map => l_tbl_dup_ediag_map);
        END IF;
    
        IF l_tbl_dup_ediag IS NOT NULL
        THEN
        
            g_error := 'GET DUPLICATED EPIS_DIAGNOSIS_NOTES';
            pk_alertlog.log_debug(text => g_error);
            SELECT a.id_epis_diagnosis_notes
              BULK COLLECT
              INTO l_tbl_diag_notes
              FROM (SELECT ed.id_epis_diagnosis_notes
                      FROM epis_diagnosis ed
                     WHERE ed.id_epis_diagnosis IN (SELECT column_value
                                                      FROM TABLE(l_tbl_dup_ediag))
                    UNION
                    SELECT edh.id_epis_diagnosis_notes
                      FROM epis_diagnosis_hist edh
                     WHERE edh.id_epis_diagnosis IN (SELECT column_value
                                                       FROM TABLE(l_tbl_dup_ediag))) a;
        
            g_error := 'ELIMINATE PAT_PROB_HIST DIAGS FROM OLD_EPIS';
            pk_alertlog.log_debug(text => g_error);
            DELETE FROM pat_problem_hist pt
             WHERE pt.id_epis_diagnosis IN (SELECT column_value
                                              FROM TABLE(l_tbl_dup_ediag));
        
            g_error := 'ELIMINATE PAT_PROB DIAGS FROM OLD_EPIS';
            pk_alertlog.log_debug(text => g_error);
            DELETE FROM pat_problem pt
             WHERE pt.id_epis_diagnosis IN (SELECT column_value
                                              FROM TABLE(l_tbl_dup_ediag));
        
            g_error := 'ELIMINATE EPIS_DIAG_TUMORS_HIST DIAGS FROM OLD_EPIS';
            pk_alertlog.log_debug(text => g_error);
            DELETE FROM epis_diag_tumors_hist e
             WHERE e.id_epis_diagnosis IN (SELECT column_value
                                             FROM TABLE(l_tbl_dup_ediag));
        
            g_error := 'ELIMINATE EPIS_DIAG_TUMORS DIAGS FROM OLD_EPIS';
            pk_alertlog.log_debug(text => g_error);
            DELETE FROM epis_diag_tumors e
             WHERE e.id_epis_diagnosis IN (SELECT column_value
                                             FROM TABLE(l_tbl_dup_ediag));
        
            g_error := 'ELIMINATE EPIS_DSTAG_PFACT_HIST DIAGS FROM OLD_EPIS';
            pk_alertlog.log_debug(text => g_error);
            DELETE FROM epis_dstag_pfact_hist e
             WHERE e.id_epis_diagnosis IN (SELECT column_value
                                             FROM TABLE(l_tbl_dup_ediag));
        
            g_error := 'ELIMINATE EPIS_DIAG_STAG_PFACT DIAGS FROM OLD_EPIS';
            pk_alertlog.log_debug(text => g_error);
            DELETE FROM epis_diag_stag_pfact e
             WHERE e.id_epis_diagnosis IN (SELECT column_value
                                             FROM TABLE(l_tbl_dup_ediag));
        
            g_error := 'ELIMINATE EPIS_DIAG_STAG_HIST DIAGS FROM OLD_EPIS';
            pk_alertlog.log_debug(text => g_error);
            DELETE FROM epis_diag_stag_hist e
             WHERE e.id_epis_diagnosis IN (SELECT column_value
                                             FROM TABLE(l_tbl_dup_ediag));
        
            g_error := 'ELIMINATE EPIS_DIAG_STAG DIAGS FROM OLD_EPIS';
            pk_alertlog.log_debug(text => g_error);
            DELETE FROM epis_diag_stag e
             WHERE e.id_epis_diagnosis IN (SELECT column_value
                                             FROM TABLE(l_tbl_dup_ediag));
        
            g_error := 'ELIMINATE DUP EDH FROM OLD_EPIS';
            pk_alertlog.log_debug(text => g_error);
            DELETE FROM epis_diagnosis_hist edh
             WHERE edh.id_epis_diagnosis IN (SELECT column_value
                                               FROM TABLE(l_tbl_dup_ediag));
        
            g_error := 'GET ED ROWIDs';
            pk_alertlog.log_debug(text => g_error);
            l_rowids := table_varchar();
            SELECT ROWID
              BULK COLLECT
              INTO l_rowids
              FROM epis_diagnosis ed
             WHERE ed.id_epis_diagnosis IN (SELECT column_value
                                              FROM TABLE(l_tbl_dup_ediag));
        
            g_error := 'ELIMINATE DUP ED FROM OLD_EPIS';
            pk_alertlog.log_debug(text => g_error);
            DELETE FROM epis_diagnosis ed
             WHERE ed.id_epis_diagnosis IN (SELECT column_value
                                              FROM TABLE(l_tbl_dup_ediag));
        
            g_error := 'PROCESS DELETE EPIS_DIAGNOSIS';
            pk_alertlog.log_debug(text => g_error);
            t_data_gov_mnt.process_delete(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'EPIS_DIAGNOSIS',
                                          i_rowids     => l_rowids,
                                          o_error      => o_error);
        
        END IF;
    
        g_error := 'ELIMINATE DUP EDN FROM OLD_EPIS';
        pk_alertlog.log_debug(text => g_error);
        DELETE FROM epis_diagnosis_notes edn
         WHERE edn.id_epis_diagnosis_notes IN (SELECT column_value
                                                 FROM TABLE(l_tbl_diag_notes));
    
        g_error := 'EPIS_DIAGNOSIS EPISODE';
        pk_alertlog.log_debug(text => g_error);
        l_rowids := table_varchar();
        ts_epis_diagnosis.upd(id_episode_in => i_new_epis,
                              where_in      => 'id_episode = ' || i_old_epis,
                              rows_out      => l_rowids);
    
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'EPIS_DIAGNOSIS',
                                      i_list_columns => table_varchar('id_episode'),
                                      i_rowids       => l_rowids,
                                      o_error        => o_error);
    
        g_error := 'EPIS_DIAGNOSIS_NOTES EPISODE';
        pk_alertlog.log_debug(text => g_error);
        l_rowids := table_varchar();
        ts_epis_diagnosis_notes.upd(id_episode_in => i_new_epis,
                                    where_in      => 'id_episode = ' || i_old_epis,
                                    rows_out      => l_rowids);
    
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'EPIS_DIAGNOSIS_NOTES',
                                      i_list_columns => table_varchar('id_episode'),
                                      i_rowids       => l_rowids,
                                      o_error        => o_error);
    
        g_error := 'EPIS_DIAGNOSIS EPISODE_ORIGIN';
        pk_alertlog.log_debug(text => g_error);
        l_rowids := table_varchar();
        ts_epis_diagnosis.upd(id_episode_origin_in => i_new_epis,
                              where_in             => 'id_episode_origin = ' || i_old_epis,
                              rows_out             => l_rowids);
    
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'EPIS_DIAGNOSIS',
                                      i_list_columns => table_varchar('id_episode_origin'),
                                      i_rowids       => l_rowids,
                                      o_error        => o_error);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN e_primary_diag_exception THEN
            pk_utils.undo_changes;
            RAISE e_primary_diag_exception;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_DIAGNOSIS',
                                              'SET_MATCH_DIAGNOSIS',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_match_diagnosis;

    /********************************************************************************************
    * Checks if the user must be warned about the current diagnosis creation/edition
    *
    * @param i_lang                   language ID
    * @param i_prof                   Object (professional, Institution and Software)
    * @param i_episode                episode ID
    * @param i_epis_diagnosis         diagnosis record associated to the episode (when editing a diagnosis)
    * @param i_check_type             type of check: P - primary, A - all
    * @param i_flg_final_type         diagnosis type: P - primary, S - secondary
    * @param i_sub_analysis           sub analysis id
    * @param i_anatomical_area        anatomical area id
    * @param i_anatomical_side        anatomical side id
    * @param o_flg_show               The warning screen should appear? Y - yes, N - No
    * @param o_msg                    Warning message
    * @param o_error                  Error message
    *
    * @return                         true or false para sucesso ou erro
    *
    * @author                         Jos?Silva
    * @version                        1.0   
    * @since                          2009/09/07
    **********************************************************************************************/
    FUNCTION check_primary_diagnosis
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_episode         IN episode.id_episode%TYPE,
        i_epis_diagnosis  IN epis_diagnosis.id_epis_diagnosis%TYPE,
        i_check_type      IN VARCHAR2 DEFAULT g_check_type_prim_diag,
        i_flg_final_type  IN table_varchar,
        i_diagnosis       IN table_number,
        i_sub_analysis    IN table_number,
        i_anatomical_area IN table_number,
        i_anatomical_side IN table_number,
        i_rank            IN table_number DEFAULT NULL,
        o_flg_show        OUT VARCHAR2,
        o_msg             OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_flg_val_final sys_config.value%TYPE;
        l_flg_val_popup sys_config.value%TYPE;
        l_count         NUMBER;
        l_val           BOOLEAN := FALSE;
    
        l_popup_yes      CONSTANT sys_config.value%TYPE := 'Y';
        l_popup_transfer CONSTANT sys_config.value%TYPE := 'T';
    
        l_invalid_array_size EXCEPTION;
    
        l_preg_out_type pat_pregnancy.flg_preg_out_type%TYPE;
        l_exists_abort  VARCHAR2(1 CHAR);
        l_exists_deliv  VARCHAR2(1 CHAR);
        l_exception EXCEPTION;
        l_flg_type    VARCHAR2(2 CHAR);
        l_count_abort NUMBER;
        l_count_deliv NUMBER;
    
        l_diagnosis_type_ahp sys_config.value%TYPE := pk_sysconfig.get_config('DISCHARGE_DIAG_NO_APH_T', i_prof);
        l_no_ahp             VARCHAR2(10 CHAR);
    
        --DISCHARGE DIAGNOSIS MANAGE BY RANK OR PRINCIPAL
        g_manage_principal CONSTANT VARCHAR2(1 CHAR) := 'P';
        g_manage_rank      CONSTANT VARCHAR2(1 CHAR) := 'R';
        l_diag_manage_type VARCHAR2(100 CHAR) := nvl(pk_sysconfig.get_config('DISCHARGE_DIAGNOSIS_MANAGE_BY_RANK_OR_PRINCIPAL',
                                                                             i_prof),
                                                     g_manage_principal);
    
        l_diag_abort_deliv VARCHAR2(100 CHAR) := pk_sysconfig.get_config('DIAGNOSIS_ABORT_DELIV_VALIDATION', i_prof);
    
        l_val_yes VARCHAR2(2 CHAR) := 'SI';
    BEGIN
    
        IF l_diag_abort_deliv = pk_alert_constant.g_yes
        THEN
            -- GET PREGNANCY TYPE OUT    
            IF NOT pk_pregnancy.get_flg_pregn_out_type(i_lang      => i_lang,
                                                       i_prof      => i_prof,
                                                       i_episode   => i_episode,
                                                       o_flg_pregn => l_preg_out_type,
                                                       o_error     => o_error)
            THEN
                RAISE l_exception;
            END IF;
        
            -- EXISTS diag abortion
            IF NOT get_final_diag_abort_deliv(i_lang          => i_lang,
                                              i_prof          => i_prof,
                                              i_epis          => i_episode,
                                              i_preg_out_type => pk_diagnosis_core.g_preg_out_type_a,
                                              i_diagnosis     => i_diagnosis,
                                              o_exists        => l_exists_abort,
                                              o_count         => l_count_abort,
                                              o_error         => o_error)
            THEN
                RAISE l_exception;
            END IF;
        
            -- EXISTS diag devlivary
            IF NOT get_final_diag_abort_deliv(i_lang          => i_lang,
                                              i_prof          => i_prof,
                                              i_epis          => i_episode,
                                              i_preg_out_type => pk_diagnosis_core.g_preg_out_type_d,
                                              i_diagnosis     => i_diagnosis,
                                              o_exists        => l_exists_deliv,
                                              o_count         => l_count_deliv,
                                              o_error         => o_error)
            THEN
                RAISE l_exception;
            END IF;
        
            -- Check if array i_diagnosis contain abortion or delivery diagnosis
            IF NOT pk_diagnosis_core.check_diag_abort_or_deliv(i_lang      => i_lang,
                                                               i_prof      => i_prof,
                                                               i_diagnosis => i_diagnosis,
                                                               o_flg_type  => l_flg_type,
                                                               o_error     => o_error)
            THEN
                RAISE l_exception;
            END IF;
        
            -- Ponto 5
            IF l_flg_type IN (pk_diagnosis_core.g_preg_out_type_b, pk_diagnosis_core.g_preg_out_type_d)
               AND l_preg_out_type IS NULL
            THEN
            
                o_flg_show := g_warning_popup_ok;
                o_msg      := pk_message.get_message(i_lang      => i_lang,
                                                     i_prof      => i_prof,
                                                     i_code_mess => 'DIAGNOSIS_FINAL_M014');
                RETURN TRUE;
            END IF;
        
            -- Ponto 5
            IF l_flg_type IN (pk_diagnosis_core.g_preg_out_type_b, pk_diagnosis_core.g_preg_out_type_a)
               AND l_preg_out_type IS NULL
            THEN
                o_flg_show := g_warning_popup_ok;
                o_msg      := pk_message.get_message(i_lang      => i_lang,
                                                     i_prof      => i_prof,
                                                     i_code_mess => 'DIAGNOSIS_FINAL_M015');
                RETURN TRUE;
            END IF;
        
            -- Ponto 1
            IF l_flg_type IN (pk_diagnosis_core.g_preg_out_type_b, pk_diagnosis_core.g_preg_out_type_d)
               AND l_preg_out_type = pk_diagnosis_core.g_preg_out_type_a
            THEN
            
                o_flg_show := g_warning_popup_ok;
                o_msg      := pk_message.get_message(i_lang      => i_lang,
                                                     i_prof      => i_prof,
                                                     i_code_mess => 'DISCHARGE_M045');
                RETURN TRUE;
            END IF;
        
            --Ponto 1
            IF l_flg_type IN (pk_diagnosis_core.g_preg_out_type_b, pk_diagnosis_core.g_preg_out_type_a)
               AND l_preg_out_type = pk_diagnosis_core.g_preg_out_type_d
            THEN
                o_flg_show := g_warning_popup_ok;
                o_msg      := pk_message.get_message(i_lang      => i_lang,
                                                     i_prof      => i_prof,
                                                     i_code_mess => 'DISCHARGE_M046');
                RETURN TRUE;
            END IF;
        
            IF l_flg_type IN (pk_diagnosis_core.g_preg_out_type_b, pk_diagnosis_core.g_preg_out_type_d)
               AND l_exists_abort = pk_alert_constant.g_yes
            
            THEN
                o_flg_show := g_warning_popup_ok;
                o_msg      := pk_message.get_message(i_lang      => i_lang,
                                                     i_prof      => i_prof,
                                                     i_code_mess => 'DIAGNOSIS_FINAL_M013');
                RETURN TRUE;
            END IF;
        
            --Ponto 2    
            -- If already exists a delivery diagnosis and i_diagnosis contains a abortion diagnosis, then return message    
            IF l_flg_type IN (pk_diagnosis_core.g_preg_out_type_b, pk_diagnosis_core.g_preg_out_type_a)
               AND l_exists_deliv = pk_alert_constant.g_yes
            
            THEN
                o_flg_show := g_warning_popup_ok;
                o_msg      := pk_message.get_message(i_lang      => i_lang,
                                                     i_prof      => i_prof,
                                                     i_code_mess => 'DIAGNOSIS_FINAL_M012');
                RETURN TRUE;
            END IF;
        
            --Ponto 2
            -- If already exists a abortion diagnosis and i_diagnosis contains a delivery diagnosis, then return message
            IF /*l_flg_type IN (pk_diagnosis_core.g_preg_out_type_b, pk_diagnosis_core.g_preg_out_type_d)
                                                                                                                                                                                                                                                                                                                                                                               AND*/
             l_exists_abort = pk_alert_constant.g_yes
             OR l_count_abort > 1
            THEN
                o_flg_show := g_warning_popup_ok;
                o_msg      := pk_message.get_message(i_lang      => i_lang,
                                                     i_prof      => i_prof,
                                                     i_code_mess => 'DIAGNOSIS_FINAL_M023');
                RETURN TRUE;
            END IF;
        
            --Ponto 2    
            -- If already exists a delivery diagnosis and i_diagnosis contains a abortion diagnosis, then return message    
            IF /*l_flg_type IN (pk_diagnosis_core.g_preg_out_type_b, pk_diagnosis_core.g_preg_out_type_a)
                                                                                                                                                                                                                                                                                                                                                                               AND */
             l_exists_deliv = pk_alert_constant.g_yes
             OR l_count_deliv > 1
            
            THEN
                o_flg_show := g_warning_popup_ok;
                o_msg      := pk_message.get_message(i_lang      => i_lang,
                                                     i_prof      => i_prof,
                                                     i_code_mess => 'DIAGNOSIS_FINAL_M024');
                RETURN TRUE;
            END IF;
        END IF;
    
        IF l_diagnosis_type_ahp = pk_alert_constant.g_yes
           AND i_diagnosis IS NOT NULL
        THEN
            FOR i IN 1 .. i_diagnosis.count
            LOOP
            
                IF i_flg_final_type(i) = pk_diagnosis.g_diag_type_p
                THEN
                
                    BEGIN
                        SELECT cd.no_aph
                          INTO l_no_ahp
                          FROM diagnosis d
                         INNER JOIN alert_diagnosis ad
                            ON d.id_diagnosis = ad.id_diagnosis
                         INNER JOIN cat_diagnosis cd
                            ON cd.id_concept_term = ad.id_alert_diagnosis
                         WHERE d.id_diagnosis = i_diagnosis(i);
                    EXCEPTION
                        WHEN no_data_found THEN
                            l_no_ahp := NULL;
                    END;
                
                    IF upper(l_no_ahp) = l_val_yes
                    THEN
                        o_flg_show := g_warning_popup_ok;
                        o_msg      := pk_message.get_message(i_lang      => i_lang,
                                                             i_prof      => i_prof,
                                                             i_code_mess => 'DIAGNOSIS_FINAL_M016');
                        RETURN TRUE;
                    END IF;
                
                END IF;
            
            END LOOP;
        
        END IF;
    
        IF i_flg_final_type.count != i_diagnosis.count
           OR (i_check_type = pk_diagnosis.g_check_type_all AND
           (i_flg_final_type.count != i_sub_analysis.count OR i_flg_final_type.count != i_anatomical_area.count OR
           i_flg_final_type.count != i_anatomical_side.count))
        THEN
            g_error := 'INVALID ARRAY SIZE';
            RAISE l_invalid_array_size;
        END IF;
    
        o_flg_show := g_no;
        o_msg      := '';
    
        ---------------------------------------------------------------------
        IF l_diag_manage_type = g_manage_principal
        THEN
            g_error         := 'GET CONFIG';
            l_flg_val_final := nvl(pk_sysconfig.get_config('SINGLE_PRIMARY_DIAGNOSIS', i_prof), pk_alert_constant.g_yes);
        
            IF l_flg_val_final = pk_alert_constant.g_yes
            THEN
                g_error := 'LOOP FINAL TYPE';
                FOR i IN 1 .. i_flg_final_type.count
                LOOP
                    IF i_flg_final_type(i) = g_flg_final_type_p
                    THEN
                        l_val := TRUE;
                    END IF;
                END LOOP;
            
                IF l_val
                THEN
                    g_error := 'COUNT PRIMARY DIAGNOSIS';
                    SELECT COUNT(*)
                      INTO l_count
                      FROM epis_diagnosis ed
                     WHERE ed.id_episode = i_episode
                       AND ed.id_epis_diagnosis <> nvl(i_epis_diagnosis, -1)
                       AND ed.flg_status NOT IN (g_ed_flg_status_ca, g_ed_flg_status_r)
                       AND ed.flg_final_type = g_flg_final_type_p
                       AND (ed.flg_is_complication = pk_alert_constant.g_no OR ed.flg_is_complication IS NULL);
                
                    IF l_count > 0
                    THEN
                        o_flg_show := g_yes;
                        o_msg      := pk_message.get_message(i_lang      => i_lang,
                                                             i_prof      => i_prof,
                                                             i_code_mess => 'DIAGNOSIS_FINAL_M009');
                    END IF;
                END IF;
            END IF;
        ELSIF l_diag_manage_type = g_manage_rank
        THEN
            IF nvl(cardinality(i_rank), 0) = nvl(cardinality(i_diagnosis), 0)
               AND nvl(cardinality(i_rank), 0) != 0
            THEN
                g_error := 'COUNT DIAGNOSIS WITH SAME RANK';
                --new diagnosis
                IF i_epis_diagnosis IS NULL
                THEN
                    SELECT COUNT(*)
                      INTO l_count
                      FROM epis_diagnosis ed
                     WHERE ed.id_episode = i_episode
                       AND ed.flg_status NOT IN (g_ed_flg_status_ca, g_ed_flg_status_r)
                       AND ed.rank IN (SELECT /*+ opt_estimate(table t1 rows=1)*/
                                        column_value rank
                                         FROM TABLE(i_rank))
                       AND (ed.flg_is_complication = pk_alert_constant.g_no OR ed.flg_is_complication IS NULL);
                ELSE
                    --update diagnosis
                    SELECT COUNT(*)
                      INTO l_count
                      FROM epis_diagnosis ed
                     WHERE ed.id_episode = i_episode
                       AND ed.flg_status NOT IN (g_ed_flg_status_ca, g_ed_flg_status_r)
                       AND ed.id_epis_diagnosis = i_epis_diagnosis
                       AND ed.id_diagnosis IN (SELECT /*+ opt_estimate(table t1 rows=1)*/
                                                column_value id_diagnosis
                                                 FROM TABLE(i_diagnosis))
                       AND (ed.rank NOT IN (SELECT /*+ opt_estimate(table t1 rows=1)*/
                                             column_value rank
                                              FROM TABLE(i_rank)) AND ed.rank IS NOT NULL)
                       AND (ed.flg_is_complication = pk_alert_constant.g_no OR ed.flg_is_complication IS NULL);
                END IF;
            
                IF l_count > 0
                THEN
                    o_flg_show := g_yes;
                    o_msg      := pk_message.get_message(i_lang      => i_lang,
                                                         i_prof      => i_prof,
                                                         i_code_mess => 'DIAGNOSIS_FINAL_M020');
                END IF;
            END IF;
        END IF;
    
        IF i_diagnosis.count > 0
        THEN
            l_flg_val_popup := nvl(pk_sysconfig.get_config('DIAG_SHOW_POP_UP_FINAL_TO_DIFF', i_prof),
                                   pk_alert_constant.g_yes);
        ELSE
            l_flg_val_popup := NULL;
        END IF;
    
        IF l_flg_val_popup IN (l_popup_yes, l_popup_transfer)
           AND i_check_type = pk_diagnosis.g_check_type_all
        THEN
        
            SELECT COUNT(*)
              INTO l_count
              FROM epis_diagnosis ed
              JOIN TABLE(i_diagnosis) t
                ON ed.id_diagnosis = t.column_value
               AND nvl(ed.id_diagnosis_condition, -999) =
                   nvl(pk_diagnosis_core.get_id_diag_condition(i_prof => i_prof, i_diagnosis => t.column_value), -999)
              JOIN TABLE(i_sub_analysis) t
                ON nvl(ed.id_sub_analysis, -999) = nvl(t.column_value, -999)
              JOIN TABLE(i_anatomical_area) t
                ON nvl(ed.id_anatomical_area, -999) = nvl(t.column_value, -999)
              JOIN TABLE(i_anatomical_side) t
                ON nvl(ed.id_anatomical_side, -999) = nvl(t.column_value, -999)
             WHERE ed.id_episode = i_episode
               AND ed.flg_type IN (g_diag_type_p, g_diag_type_b)
               AND ed.flg_status IN (g_ed_flg_status_co, g_ed_flg_status_d, g_ed_flg_status_b);
        
            IF l_count = i_diagnosis.count
            THEN
                l_flg_val_popup := pk_alert_constant.g_no;
            END IF;
        
        END IF;
    
        IF i_check_type = g_check_type_prim_diag
        THEN
            o_flg_show := o_flg_show;
        ELSE
            o_flg_show := o_flg_show || l_flg_val_popup;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_invalid_array_size THEN
            pk_alert_exceptions.process_error(i_lang,
                                              NULL,
                                              g_error,
                                              '',
                                              'ALERT',
                                              'PK_DIAGNOSIS',
                                              'CHECK_PRIMARY_DIAGNOSIS',
                                              'U',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_DIAGNOSIS',
                                              'CHECK_PRIMARY_DIAGNOSIS',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END check_primary_diagnosis;

    /********************************************************************************************
    -- verifies if selected diagnosis is a complication of another diagnosis
    **********************************************************************************************/
    FUNCTION check_diag_is_complication
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        i_flg_type       IN epis_diagnosis.flg_type%TYPE,
        i_id_diagnosis   IN table_number,
        i_desc_diagnosis IN table_varchar,
        o_flg_show       OUT VARCHAR2,
        o_msg            OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_counter NUMBER := 0;
    BEGIN
        IF i_id_diagnosis.exists(1)
           AND i_episode IS NOT NULL
           AND i_flg_type IS NOT NULL
        THEN
        
            SELECT COUNT(1)
              INTO l_counter
              FROM epis_diag_complications edc
             WHERE edc.id_epis_diagnosis IN
                   (SELECT ed.id_epis_diagnosis
                      FROM epis_diagnosis ed
                     WHERE ed.id_episode = i_episode
                       AND ed.flg_type = i_flg_type
                       AND ed.flg_status NOT IN (pk_diagnosis.g_ed_flg_status_ca, pk_diagnosis.g_ed_flg_status_r)
                       AND (ed.flg_is_complication = pk_alert_constant.g_no OR ed.flg_is_complication IS NULL))
               AND edc.id_complication IN
                   (SELECT d.id_diagnosis
                      FROM diagnosis d
                      JOIN (SELECT /*+ opt_estimate(table t1 rows=1)*/
                            column_value id_diagnosis
                             FROM TABLE(i_id_diagnosis) t1) xpto
                        ON xpto.id_diagnosis = d.id_diagnosis
                     WHERE (nvl(d.flg_other, pk_alert_constant.g_no) = pk_alert_constant.g_no OR
                           (nvl(d.flg_other, pk_alert_constant.g_no) = pk_alert_constant.g_yes AND
                           edc.desc_complication IN (SELECT /*+ opt_estimate(table t2 rows=1)*/
                                                        column_value
                                                         FROM TABLE(i_desc_diagnosis) t2))))
               AND edc.flg_status = pk_complication.g_complication_active;
        
            IF l_counter = 0
            THEN
                o_flg_show := NULL;
            ELSE
                o_flg_show := 'RCYN'; -- RankComplication + Y + N
                o_msg      := pk_message.get_message(i_lang      => i_lang,
                                                     i_prof      => i_prof,
                                                     i_code_mess => 'DIAGNOSIS_FINAL_M021');
            END IF;
        ELSE
            o_flg_show := NULL;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_DIAGNOSIS',
                                              'CHECK_DIAG_IS_COMPLICATION',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END check_diag_is_complication;

    /********************************************************************************************
    **********************************************************************************************/
    FUNCTION check_dup_diag_complication
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_id_diagnosis_list      IN table_number,
        i_desc_diagnosis_list    IN table_varchar,
        i_id_complications_list  IN table_number,
        i_desc_complication_list IN table_varchar,
        o_flg_show               OUT VARCHAR2,
        o_msg                    OUT VARCHAR2,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_counter NUMBER := 0;
    BEGIN
        IF i_id_diagnosis_list.exists(1)
           AND i_id_complications_list.exists(1)
        THEN
            SELECT COUNT(1)
              INTO l_counter
              FROM (SELECT t.id_diagnosis id_diagnosis,
                           decode(d.flg_other, pk_alert_constant.get_yes, t.desc_diagnosis, '') desc_diagnosis
                      FROM (SELECT c1 id_diagnosis, c2 desc_diagnosis
                              FROM (SELECT /*+ opt_estimate(table t1 rows=1)*/
                                     column_value c1, rownum rn1
                                      FROM TABLE(i_id_diagnosis_list) t1)
                              JOIN (SELECT /*+ opt_estimate(table t2 rows=1)*/
                                    column_value c2, rownum rn2
                                     FROM TABLE(i_desc_diagnosis_list) t2)
                                ON rn1 = rn2) t
                      JOIN diagnosis d
                        ON d.id_diagnosis = t.id_diagnosis
                    MINUS
                    SELECT t.id_diagnosis id_diagnosis,
                           decode(d.flg_other, pk_alert_constant.get_yes, t.desc_diagnosis, '') desc_diagnosis
                      FROM (SELECT c1 id_diagnosis, c2 desc_diagnosis
                              FROM (SELECT /*+ opt_estimate(table t1 rows=1)*/
                                     column_value c1, rownum rn1
                                      FROM TABLE(i_id_complications_list) t1)
                              JOIN (SELECT /*+ opt_estimate(table t2 rows=1)*/
                                    column_value c2, rownum rn2
                                     FROM TABLE(i_desc_complication_list) t2)
                                ON rn1 = rn2) t
                      JOIN diagnosis d
                        ON d.id_diagnosis = t.id_diagnosis);
        
            IF l_counter = i_id_diagnosis_list.count
            THEN
                o_flg_show := NULL;
            ELSE
                o_flg_show := 'RCR'; -- RankComplication + R(read) = RCR
                o_msg      := pk_message.get_message(i_lang      => i_lang,
                                                     i_prof      => i_prof,
                                                     i_code_mess => 'DIAGNOSIS_FINAL_M022');
            END IF;
        ELSE
            o_flg_show := NULL;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_DIAGNOSIS',
                                              'CHECK_DUP_DIAG_COMPLICATION',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END check_dup_diag_complication;

    FUNCTION check_dup_icd_diag
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_episode            IN episode.id_episode%TYPE,
        i_flg_type           IN epis_diagnosis.flg_type%TYPE,
        i_id_diagnosis_list  IN table_number,
        i_id_alert_diag_list IN table_number DEFAULT NULL,
        o_flg_show           OUT VARCHAR2,
        o_msg                OUT VARCHAR2,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_count                    NUMBER := 0;
        l_allow_diagnoses_same_icd sys_config.value%TYPE := pk_alert_constant.g_no;
    BEGIN
        o_flg_show := pk_alert_constant.g_no;
        o_msg      := NULL;
    
        IF i_flg_type = pk_diagnosis.g_diag_type_p
        THEN
            l_allow_diagnoses_same_icd := pk_sysconfig.get_config('ALLOW_DIFF_DIAGNOSIS_SAME_ICD', i_prof);
        ELSIF i_flg_type = pk_diagnosis.g_diag_type_d
        THEN
            l_allow_diagnoses_same_icd := pk_sysconfig.get_config('ALLOW_DISCH_DIAGNOSIS_SAME_ICD', i_prof);
        END IF;
    
        SELECT COUNT(*)
          INTO l_count
          FROM epis_diagnosis ed
          JOIN diagnosis d
            ON d.id_diagnosis = ed.id_diagnosis
         WHERE ed.id_episode = i_episode
           AND ed.id_diagnosis IN (SELECT *
                                     FROM TABLE(i_id_diagnosis_list))
           AND ed.id_alert_diagnosis NOT IN (SELECT *
                                               FROM TABLE(i_id_alert_diag_list))
           AND ((ed.flg_type = i_flg_type AND ed.flg_status != pk_diagnosis.g_diag_type_b) OR
               ed.flg_status = pk_diagnosis.g_diag_type_b)
           AND ed.flg_status != pk_diagnosis.g_ed_flg_status_ca
           AND (l_allow_diagnoses_same_icd = pk_alert_constant.g_no OR
               nvl(pk_ts1_api.get_allow_duplicate(i_lang               => i_lang,
                                                   i_id_concept_term    => ed.id_alert_diagnosis,
                                                   i_id_concept_version => ed.id_diagnosis,
                                                   i_id_task_type       => pk_alert_constant.g_task_diagnosis,
                                                   i_id_institution     => i_prof.institution,
                                                   i_id_software        => i_prof.software),
                    pk_alert_constant.g_no) = pk_alert_constant.g_no);
    
        IF l_count > 0
        THEN
            IF i_flg_type = pk_diagnosis.g_diag_type_d
            THEN
                o_flg_show := g_warning_popup_ok;
                o_msg      := pk_message.get_message(i_lang => i_lang, i_code_mess => 'DISCHARGE_M048');
            ELSIF i_flg_type = pk_diagnosis.g_diag_type_p
            THEN
                o_flg_show := g_warning_popup_ok;
                o_msg      := pk_message.get_message(i_lang => i_lang, i_code_mess => 'DISCHARGE_M047');
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_DIAGNOSIS',
                                              'CHECK_DUP_ICD_DIAG',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END check_dup_icd_diag;

    /********************************************************************************************
    **********************************************************************************************/
    FUNCTION check_dup_rank
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_rank_list IN table_number,
        o_flg_show  OUT VARCHAR2,
        o_msg       OUT VARCHAR2,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_union_distinct table_number := table_number();
        l_count_null     NUMBER := 0;
    BEGIN
    
        IF i_rank_list.exists(1)
        THEN
            FOR i IN 1 .. i_rank_list.count
            LOOP
                IF i_rank_list(i) IS NULL
                THEN
                    l_count_null := l_count_null + 1;
                END IF;
            END LOOP;
        END IF;
    
        IF i_rank_list.exists(1)
           AND l_count_null < i_rank_list.count
        THEN
            l_union_distinct := i_rank_list MULTISET UNION DISTINCT table_number();
        
            IF nvl(cardinality(l_union_distinct), 0) = nvl(cardinality(i_rank_list), 0)
            THEN
                o_flg_show := NULL;
            ELSE
                o_flg_show := 'RCR'; -- RankComplication + R(read) = RCR
                o_msg      := pk_message.get_message(i_lang      => i_lang,
                                                     i_prof      => i_prof,
                                                     i_code_mess => 'DIAGNOSIS_FINAL_M019');
            END IF;
        ELSE
            o_flg_show := NULL;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_DIAGNOSIS',
                                              'CHECK_DUP_RANK',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END check_dup_rank;

    /********************************************************************************************
    * Returns the information of diagnoses of the provided episode.
    *
    * @param i_lang                   language ID
    * @param i_prof                   Object (professional, Institution and Software)
    * @param i_episode                episode ID    
    *
    * @return                         BOOLEAN for success. 
    *
    * @author                         RicardoNunoAlmeida
    * @version                        2.5.0.7.7   
    * @since                          2010/02/07
    **********************************************************************************************/
    FUNCTION get_epis_diagnosis
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_epis  IN episode.id_episode%TYPE,
        o_diag  OUT VARCHAR2,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        SELECT pk_admission_request.concatenate_list(CURSOR (SELECT std_diag_desc(i_lang                => i_lang,
                                                                           i_prof                => i_prof,
                                                                           i_id_alert_diagnosis  => ad.id_alert_diagnosis,
                                                                           i_id_diagnosis        => d.id_diagnosis,
                                                                           i_desc_epis_diagnosis => ed2.desc_epis_diagnosis,
                                                                           i_code                => d.code_icd,
                                                                           i_flg_other           => d.flg_other,
                                                                           i_flg_std_diag        => ad.flg_icd9) desc_diagnosis
                                                        FROM ( -- SELECTS THE DIAGNOSES TO SHOW
                                                              SELECT ed.*,
                                                                      row_number() over(PARTITION BY ed.id_diagnosis ORDER BY decode(ed.flg_type, pk_edis_proc.g_epis_diag_type_definitive, 0, 1) ASC, decode(ed.flg_status, pk_edis_proc.g_epis_diag_confirmed, 0, 1) ASC, decode(ed.flg_status, pk_edis_proc.g_epis_diag_despiste, ed.dt_epis_diagnosis_tstz, ed.dt_confirmed_tstz) DESC) rn
                                                                FROM epis_diagnosis ed
                                                               WHERE ed.id_episode = i_epis
                                                                 AND ed.flg_status IN
                                                                     (pk_edis_proc.g_epis_diag_confirmed,
                                                                      pk_edis_proc.g_epis_diag_despiste)) ed2
                                                        JOIN diagnosis d
                                                          ON (d.id_diagnosis = ed2.id_diagnosis)
                                                        LEFT JOIN alert_diagnosis ad
                                                          ON ad.id_alert_diagnosis = ed2.id_alert_diagnosis
                                                       WHERE ed2.rn = 1
                                                       ORDER BY decode(ed2.flg_type,
                                                                       pk_edis_proc.g_epis_diag_type_definitive,
                                                                       0,
                                                                       1) ASC,
                                                                decode(ed2.flg_final_type,
                                                                       pk_edis_proc.g_epis_diag_final_type_primary,
                                                                       0,
                                                                       pk_edis_proc.g_epis_diag_final_type_sec,
                                                                       1,
                                                                       2),
                                                                decode(ed2.flg_status,
                                                                       pk_edis_proc.g_epis_diag_confirmed,
                                                                       0,
                                                                       1) ASC))
          INTO o_diag
          FROM dual;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_DIAGNOSIS',
                                              'GET_EPIS_DIAGNOSIS',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_epis_diagnosis;

    FUNCTION get_epis_diagnosis
    (
        i_lang IN language.id_language%TYPE,
        i_epis IN episode.id_episode%TYPE
    ) RETURN VARCHAR2 IS
        l_err   t_error_out;
        l_diags VARCHAR2(32767);
        l_prof  profissional := profissional(0, 0, 0);
    BEGIN
    
        IF NOT pk_diagnosis.get_epis_diagnosis(i_lang  => i_lang,
                                               i_prof  => l_prof,
                                               i_epis  => i_epis,
                                               o_diag  => l_diags,
                                               o_error => l_err)
        THEN
            RETURN NULL;
        END IF;
    
        RETURN l_diags;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_DIAGNOSIS',
                                              'GET_EPIS_DIAGNOSIS',
                                              l_err);
            pk_alert_exceptions.reset_error_state;
            RETURN NULL;
    END get_epis_diagnosis;

    /********************************************************************************************
    * Gets the episode description in which the diagnosis was registered
    *
    * @param i_lang           language id
    * @param i_prof           professional id (type: professional id, institution id and software id)
    * @param i_episode        episode ID
    * @param i_epis_origin    episode ID where the diagnosis was registered
    * 
    * @return                 formatted text containing the episode description
    * 
    * @author                 Jos?Silva
    * @version                2.6.0.1  
    * @since                  2010/03/29
    **********************************************************************************************/
    FUNCTION get_origin_diagnosis
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_episode     IN episode.id_episode%TYPE,
        i_epis_origin IN episode.id_episode%TYPE
    ) RETURN VARCHAR2 IS
    
        l_desc      VARCHAR2(4000);
        l_epis_type episode.id_epis_type%TYPE;
        l_err       t_error_out;
    
    BEGIN
    
        IF i_episode = nvl(i_epis_origin, i_episode)
        THEN
            l_desc := '';
        ELSE
        
            g_error := 'GET EPIS_TYPE';
            SELECT id_epis_type
              INTO l_epis_type
              FROM episode e
             WHERE id_episode = i_epis_origin;
        
            g_error := 'GET EPIS_TYPE DESC';
            l_desc  := ' - (' || pk_message.get_message(i_lang,
                                                        profissional(i_prof.id,
                                                                     i_prof.institution,
                                                                     pk_episode.get_soft_by_epis_type(l_epis_type,
                                                                                                      i_prof.institution)),
                                                        'DIAGNOSIS_DIFF_T030') || ')';
        END IF;
    
        RETURN l_desc;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_DIAGNOSIS',
                                              'GET_ORIGIN_DIAGNOSIS',
                                              l_err);
            pk_alert_exceptions.reset_error_state;
            RETURN NULL;
    END get_origin_diagnosis;

    /********************************************************************************************
    * Gets the options available in the diagnosis filter
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_flg_type               Diagnosis type: P - differential, D - final
    * @param o_options                Filter options
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Jos?Silva
    * @version                        1.0   
    * @since                          2011/01/26
    **********************************************************************************************/
    FUNCTION get_diag_filter_options
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_flg_type IN VARCHAR2,
        o_options  OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        RETURN pk_diagnosis_core.get_diag_filter_options(i_lang     => i_lang,
                                                         i_prof     => i_prof,
                                                         i_patient  => NULL,
                                                         i_episode  => NULL,
                                                         i_flg_type => i_flg_type,
                                                         o_options  => o_options,
                                                         o_error    => o_error);
    
    END get_diag_filter_options;
    --
    /**************************************************************************
    * get profissional with diagnosis state logic
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID  
    * @param i_id_epis_diagnosis      Epis_diagnosis ID
    * 
    * Return diagnosis date 
    *                                                                         
    * @author                         Filipe Silva                            
    * @version                        2.6.0.5                                 
    * @since                          2011/02/14                              
    **************************************************************************/
    FUNCTION get_epis_diagnosis_prof
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_epis_diagnosis IN epis_diagnosis.id_epis_diagnosis%TYPE
    ) RETURN epis_diagnosis.id_professional_diag%TYPE IS
    
        l_epis_diagnosis_row epis_diagnosis%ROWTYPE;
        l_id_professional    epis_diagnosis.id_professional_diag%TYPE;
        l_exception EXCEPTION;
    
    BEGIN
    
        g_error := 'GET DIAGNOSIS RECORD FOR ID_EPIS_DIAGNOSIS: ' || i_id_epis_diagnosis;
        pk_alertlog.log_debug(g_error);
        BEGIN
            SELECT ed.*
              INTO l_epis_diagnosis_row
              FROM epis_diagnosis ed
             WHERE ed.id_epis_diagnosis = i_id_epis_diagnosis;
        EXCEPTION
            WHEN no_data_found THEN
                RAISE l_exception;
        END;
    
        g_error := 'GET PROFESSIONAL';
        pk_alertlog.log_debug(g_error);
        l_id_professional := pk_diagnosis_core.get_prof_diagnosis(i_lang,
                                                                  i_prof,
                                                                  l_epis_diagnosis_row.flg_status,
                                                                  l_epis_diagnosis_row.id_professional_diag,
                                                                  l_epis_diagnosis_row.id_prof_confirmed,
                                                                  l_epis_diagnosis_row.id_professional_cancel,
                                                                  l_epis_diagnosis_row.id_prof_base,
                                                                  l_epis_diagnosis_row.id_prof_rulled_out);
    
        RETURN l_id_professional;
    
    EXCEPTION
        WHEN l_exception THEN
            RETURN NULL;
        WHEN OTHERS THEN
            RETURN NULL;
    END get_epis_diagnosis_prof;

    /**************************************************************************
    * get diagnosis date with state logic
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID  
    * @param i_id_epis_diagnosis      Epis_diagnosis ID
    * 
    * Return diagnosis date 
    *                                                                         
    * @author                         Filipe Silva                            
    * @version                        2.6.0.5                                 
    * @since                          2011/02/14                              
    **************************************************************************/
    FUNCTION get_epis_diagnosis_date
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_epis_diagnosis IN epis_diagnosis.id_epis_diagnosis%TYPE
    ) RETURN epis_diagnosis.dt_epis_diagnosis_tstz%TYPE IS
    
        l_epis_diagnosis_row epis_diagnosis%ROWTYPE;
        l_date_diagnosis     epis_diagnosis.dt_epis_diagnosis_tstz%TYPE;
        l_exception EXCEPTION;
    
    BEGIN
    
        g_error := 'GET DIAGNOSIS RECORD FOR ID_EPIS_DIAGNOSIS: ' || i_id_epis_diagnosis;
        pk_alertlog.log_debug(g_error);
        BEGIN
            SELECT ed.*
              INTO l_epis_diagnosis_row
              FROM epis_diagnosis ed
             WHERE ed.id_epis_diagnosis = i_id_epis_diagnosis;
        EXCEPTION
            WHEN no_data_found THEN
                RAISE l_exception;
        END;
    
        g_error := 'GET DIAGNOSIS DATE';
        pk_alertlog.log_debug(g_error);
        l_date_diagnosis := pk_diagnosis_core.get_dt_diagnosis(i_lang,
                                                               i_prof,
                                                               l_epis_diagnosis_row.flg_status,
                                                               l_epis_diagnosis_row.dt_epis_diagnosis_tstz,
                                                               l_epis_diagnosis_row.dt_confirmed_tstz,
                                                               l_epis_diagnosis_row.dt_cancel_tstz,
                                                               l_epis_diagnosis_row.dt_base_tstz,
                                                               l_epis_diagnosis_row.dt_rulled_out_tstz);
    
        RETURN l_date_diagnosis;
    
    EXCEPTION
        WHEN l_exception THEN
            RETURN NULL;
        WHEN OTHERS THEN
            RETURN NULL;
    END get_epis_diagnosis_date;
    /********************************************************************************************
    * Get episode diagnosis
    *
    * @param i_lang                          Preferred language ID for this professional
    * @param i_prof                          Object (professional ID, institution ID, software ID)
    * @param i_epis                          episode identifier
    * @param i_diag                          diagnosis identifier
    * @param i_desc_diag                     diagnosis description
    * @param o_epis_diag                     epis diagnosis identfier
    * @param o_flg_add_problem               flg_add_problem
    
    *
    * @return                         true or false
    *
    * @author                          Paulo teixeira
    * @version                         0.1
    * @since                           2011/08/30
    **********************************************************************************************/
    FUNCTION get_epis_diagnosis
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_epis            IN episode.id_episode%TYPE,
        i_diag            IN diagnosis.id_diagnosis%TYPE,
        i_desc_diag       IN sys_message.desc_message%TYPE,
        o_epis_diag       OUT epis_diagnosis.id_epis_diagnosis%TYPE,
        o_flg_add_problem OUT epis_diagnosis.flg_add_problem%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        BEGIN
            SELECT ed.id_epis_diagnosis, ed.flg_add_problem
              INTO o_epis_diag, o_flg_add_problem
              FROM epis_diagnosis ed, diagnosis d
             WHERE ed.id_episode = i_epis
               AND ed.id_diagnosis = i_diag
               AND d.id_diagnosis = ed.id_diagnosis
                  --Changed because the cases where l_desc_diagnosis was null were not being caught
                  --AND ((nvl(d.flg_other, 'N') = g_yes AND ed.desc_epis_diagnosis = l_desc_diagnosis) OR
               AND ((nvl(d.flg_other, 'N') = g_yes AND nvl(ed.desc_epis_diagnosis, '#') = nvl(i_desc_diag, '#')) OR
                   (nvl(d.flg_other, 'N') = g_no))
               AND rownum = 1;
        EXCEPTION
            WHEN no_data_found THEN
                o_epis_diag       := NULL;
                o_flg_add_problem := NULL;
        END;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_DIAGNOSIS',
                                              'GET_EPIS_DIAGNOSIS',
                                              o_error);
            RETURN FALSE;
    END get_epis_diagnosis;

    /********************************************************************************************
    * Get episode diagnosis
    *
    * @param i_lang                          Preferred language ID for this professional
    * @param i_prof                          Object (professional ID, institution ID, software ID)    
    * @param i_id_diagnosis                  Diagnosis identifier
    * @param o_flg_other                     Diagnosis flg other
    * @param o_error                         Error info
    
    *
    * @return                         true or false
    *
    * @author                          Sofia Mendes
    * @version                         2.6.2
    * @since                           16-Dec-2011
    **********************************************************************************************/
    FUNCTION get_diag_flg_other
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_diagnosis IN diagnosis.id_diagnosis%TYPE,
        o_flg_other    OUT diagnosis.flg_other%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        BEGIN
            SELECT d.flg_other
              INTO o_flg_other
              FROM diagnosis d
             WHERE d.id_diagnosis = i_id_diagnosis
               AND d.flg_available = pk_alert_constant.g_yes;
        EXCEPTION
            WHEN no_data_found THEN
                o_flg_other := NULL;
        END;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_DIAGNOSIS',
                                              'GET_DIAG_FLG_OTHER',
                                              o_error);
            RETURN FALSE;
    END get_diag_flg_other;

    /********************************************************************************************
    * Get diagnosis code domain (and synonims)
    * 
    * @return                          Code domain for diagnosis and synonims
    *
    * @author                          Miguel Moreira
    * @version                         2.6.1.6
    * @since                           27-Feb-2012
    **********************************************************************************************/
    FUNCTION get_diagnosis_domain RETURN table_varchar IS
    
        l_code_diag table_varchar;
    BEGIN
        l_code_diag := table_varchar();
        l_code_diag.extend;
        l_code_diag(l_code_diag.last) := diagnosis_domain_name;
        l_code_diag.extend;
        l_code_diag(l_code_diag.last) := diagnosis_domain_name_syn;
        l_code_diag.extend;
        l_code_diag(l_code_diag.last) := diagnosis_domain_name_concept;
        RETURN l_code_diag;
    END;

    /**
    * Get diagnosis path based on its hierarchy
    *
    * @param   i_diagnosis          Diagnosis identifier
    *
    * @return  The diagnosis path
    *
    * @author  S�rgio Santos
    * @version v2.5.2
    * @since   08/03/2012
    */
    FUNCTION get_diagnosis_path(i_diagnosis IN diagnosis.id_diagnosis%TYPE) RETURN VARCHAR2 IS
    
        l_error t_error_out;
        l_ret   VARCHAR2(4000);
        l_sep   VARCHAR2(10 CHAR);
    
        CURSOR c_diagnosis_parent IS
            SELECT d.id_diagnosis, d.id_diagnosis_parent, LEVEL
              FROM diagnosis d
             WHERE LEVEL <> 1
            CONNECT BY PRIOR d.id_diagnosis_parent = d.id_diagnosis
             START WITH d.id_diagnosis = i_diagnosis
             ORDER BY LEVEL DESC;
    BEGIN
        FOR r_diag IN c_diagnosis_parent
        LOOP
            l_ret := l_ret || l_sep || r_diag.id_diagnosis;
        
            l_sep := ' > ';
        END LOOP;
    
        RETURN l_ret;
    END get_diagnosis_path;

    /**
    * Get diagnosis path based on its hierarchy
    *
    * @param   i_lang          Language ID
    * @param   i_prof          Professional data
    * @param   i_diagnosis     Diagnosis ID
    * @param   o_path          Diagnosis path cursor
    * @param   o_error         Error information
    *
    * @return  TRUE/FALSE
    *
    * @author  Sergio Dias
    * @version v2.6.3.9.1
    * @since   Jan-10-2014
    */
    FUNCTION get_diagnosis_path
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_diagnosis IN diagnosis.id_diagnosis%TYPE,
        o_path      OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        c_all_diagnosis CONSTANT VARCHAR2(1 CHAR) := 'A';
        --    
        l_tbl_diags t_coll_diagnosis_config;
    BEGIN
        l_tbl_diags := pk_terminology_search.tf_diagnoses_list(i_lang                     => i_lang,
                                                               i_prof                     => i_prof,
                                                               i_patient                  => NULL,
                                                               i_text_search              => NULL,
                                                               i_format_text              => pk_alert_constant.g_no,
                                                               i_terminologies_task_types => table_number(pk_alert_constant.g_task_diagnosis),
                                                               i_term_task_type           => pk_alert_constant.g_task_diagnosis,
                                                               i_list_type                => pk_diagnosis_core.g_diag_list_searchable,
                                                               i_only_diag_filter_by_prt  => c_all_diagnosis);
    
        OPEN o_path FOR
            SELECT d.id_diagnosis, d.id_diagnosis_parent, LEVEL
              FROM TABLE(l_tbl_diags) d
            CONNECT BY PRIOR d.id_diagnosis_parent = d.id_diagnosis
             START WITH d.id_diagnosis = i_diagnosis
             ORDER BY LEVEL DESC;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_DIAGNOSIS',
                                              'GET_DIAGNOSIS_PATH',
                                              o_error);
            RETURN FALSE;
    END get_diagnosis_path;

    /**********************************************************************************************
    * List all diagnosis registered in an episode
    *
    * @param i_lang                   Id language
    * @param i_prof                   Professional, software and institution ids
    * @param i_episode                Episode id
    * @param i_flg_type               Diagnosis type: P - differential, D - final
    * @param o_list                   Diagnoses list
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Jos?Silva
    * @version                        1.0
    * @since                          2012/02/29
    **********************************************************************************************/
    FUNCTION get_epis_diagnosis_list
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_episode  IN episode.id_episode%TYPE,
        i_flg_type IN epis_diagnosis.flg_type%TYPE,
        o_list     OUT pk_edis_types.diagnosis_cur,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN pk_diagnosis_core.get_epis_diagnosis_list(i_lang     => i_lang,
                                                         i_prof     => i_prof,
                                                         i_episode  => i_episode,
                                                         i_flg_type => i_flg_type,
                                                         o_list     => o_list,
                                                         o_error    => o_error);
    END get_epis_diagnosis_list;

    /**********************************************************************************************
    * Get the parent diagnosis (to be used in the views that simultate the old column DIAGNOSIS.ID_DIAGNOSIS_PARENT)
    *
    * @param i_diagnosis              diagnosis ID (corresponding to ID_CONCEPT_VERSION in the new model)
    * @param i_institution            institution ID
    * @param i_software               software ID
    *
    * @return                         diagnosis parent ID
    *
    * @author                         Jos?Silva
    * @version                        1.0
    * @since                          2012/03/07
    **********************************************************************************************/
    FUNCTION get_diagnosis_parent
    (
        i_diagnosis   IN diagnosis.id_diagnosis%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN software.id_software%TYPE
    ) RETURN diagnosis.id_diagnosis%TYPE IS
    BEGIN
        --
        RETURN pk_diagnosis_core.get_diagnosis_parent(i_diagnosis   => i_diagnosis,
                                                      i_institution => i_institution,
                                                      i_software    => i_software);
    END get_diagnosis_parent;
    --
    /**
    * Encapsulates the logic of saving (create/update/cancel) a diagnosis
    * (CALLED BY: FLASH)
    *
    * @param   i_lang                  Professional preferred language
    * @param   i_prof                  Professional identification and its context (institution and software)
    * @param   i_params                XML with all input parameters
    * @param   o_params                XML with all output parameters
    * @param   o_error                 Error information
    *
    * @example i_params                Example of the possible XML passed in this variable
    *
    * <EPIS_DIAGNOSES ID_PATIENT="" ID_EPISODE="" PROF_CAT_TYPE="" FLG_TYPE="" FLG_EDIT_MODE="" ID_CDR_CALL="">
    *   <!-- 
    *   FLG_TYPE: P - Working diag; D - Final diag
    *   FLG_EDIT_MODE: Flag to diferentiate which fields are being updated
    *       S - Diagnosis Status edit
    *       T - Diagnosis Type edit
    *       N - Diagnosis screen edition (multiple values editable)
    *   --> 
    *   <EPIS_DIAGNOSIS ID_EPIS_DIAGNOSIS="" ID_EPIS_DIAGNOSIS_HIST=""  FLG_TRANSF_FINAL="" ID_CANCEL_REASON="" CANCEL_NOTES="" FLG_CANCEL_DIFF_DIAG="" >
    *     <!-- 
    *     ID_EPIS_DIAGNOSIS OR ID_EPIS_DIAGNOSIS_HIST mandatory when editing
    *     ID_EPIS_DIAGNOSIS is needed when editing the current episode diagnosis, in the case of cancer diagnosis also means editing the current staging diagnosis
    *     ID_EPIS_DIAGNOSIS_HIST is needed for cancer diagnosis when editing a past staging diagnosis
    *     --> 
    *     <!-- 
    *        In case of association only ID is needed for diagnosis
    *     --> 
    *     
    *     <DIAGNOSIS ID="" ID_ALERT_DIAG="" DESC_DIAGNOSIS="" FLG_FINAL_TYPE="" FLG_STATUS="" FLG_ADD_PROBLEM="" NOTES="" >
    *       <CHARACTERIZATION DT_INIT_DIAG="" BASIS_DIAG_MS="" BASIS_DIAG_SPEC= "" NUM_PRIM_TUMORS_MS_YN="" NUM_PRIM_TUMORS_NUM="" RECURRENCE="" />
    *       <!-- 
    *       DESC_DIAGNOSIS only available when creating a new diagnosis
    *       ID_ALERT_DIAG only necessary when creating
    *       -->
    *       <TUMORS>
    *         <TUMOR NUM="" TOPOGRAPHY="" LATERALITY="" HISTOLOGY="" BEHAVIOR="" HISTOLOGIC_GRADE="" OTHER_GRADING_SYSTEM=""
    *              PRIMARY_TUMOR_SIZE_UNKNOWN="" PRIMARY_TUMOR_SIZE_NUMERIC="" PRIMARY_TUMOR_SIZE_DESCRIPTIVE="" ADDITIONAL_PATH_INFO="" />
    *       </TUMORS>
    *       <STAGING STAGING_BASIS="" TNM_T="" TNM_N="" TNM_M="" METASTATIC_SITES="" RESIDUAL_TUMOR="" SURGICAL_MARGINS="" LYMPH_VASCULAR_INVASION="" OTHER_STAGING_SYSTEM="">
    *         <PROG_FACTORS>
    *           <PROG_FACTOR ID_LABEL="" ID_VALUE="" FT=""  />
    *         </PROG_FACTORS>
    *       </STAGING>
    *     </DIAGNOSIS>
    *     <!--
    *     FLG_CANCEL_DIFF_DIAG: Flag that indicates if differencial diagnoses should also be cancelled (This flag is only necessary when cancelling a final diagnosis)
    *     -->
    *   </EPIS_DIAGNOSIS>
    *   <GENERAL_NOTES ID="" VALUE="" ID_CANCEL_REASON="" />
    *   <!--
    *   ID: is equal to ID_EPIS_DIAGNOSIS_NOTES, this is only used when editing the general note
    *   ID_CANCEL_REASON: Only mandatory when cancelling the general notes
    *   -->
    * 
    * </EPIS_DIAGNOSES>
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    *
    * @author  Sergio Dias
    * @version 1.0
    * @since   14/Fev/2012
    */
    FUNCTION set_epis_diagnosis
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_params IN CLOB,
        o_params OUT CLOB,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN pk_diagnosis_form.set_epis_diagnosis(i_lang   => i_lang,
                                                    i_prof   => i_prof,
                                                    i_params => i_params,
                                                    o_params => o_params,
                                                    o_error  => o_error);
    END set_epis_diagnosis;
    /**
    * Encapsulates the logic of saving (create/update/cancel) a diagnosis
    * (CALLED BY: PL/SQL)
    *
    * @param   i_lang                  Professional preferred language
    * @param   i_prof                  Professional identification and its context (institution and software)
    * @param   i_params                XML with all input parameters
    * @param   o_params                XML with all output parameters
    * @param   o_error                 Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    *
    * @author  Alexandre Santos
    * @version 1.0
    * @since   24-03-2012
    */
    FUNCTION set_epis_diagnosis
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_params IN CLOB,
        o_params OUT pk_edis_types.table_out_epis_diags,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
        l_epis_diagnoses pk_edis_types.rec_in_epis_diagnoses;
        --
        l_exception EXCEPTION;
    BEGIN
        IF NOT pk_diagnosis_form.get_save_parameters(i_lang                  => i_lang,
                                                     i_prof                  => i_prof,
                                                     i_params                => i_params,
                                                     o_rec_in_epis_diagnoses => l_epis_diagnoses,
                                                     o_error                 => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        RETURN pk_diagnosis_core.set_epis_diagnosis(i_lang           => i_lang,
                                                    i_prof           => i_prof,
                                                    i_epis_diagnoses => l_epis_diagnoses,
                                                    o_params         => o_params,
                                                    o_error          => o_error);
    EXCEPTION
        WHEN l_exception THEN
            RETURN FALSE;
    END set_epis_diagnosis;
    --
    /**
    * Encapsulates the logic of saving (create/update/cancel) a diagnosis
    * (CALLED BY: PL/SQL)
    *
    * @param   i_lang                  Professional preferred language
    * @param   i_prof                  Professional identification and its context (institution and software)
    * @param   i_epis_diagnoses        Epis diagnoses record
    * @param   o_params                Output parameters record
    * @param   o_error                 Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    *
    * @author  Sergio Dias
    * @version 2.6.2.1
    * @since   22-03-2012
    */
    FUNCTION set_epis_diagnosis
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_epis_diagnoses IN pk_edis_types.rec_in_epis_diagnoses,
        o_params         OUT pk_edis_types.table_out_epis_diags,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN pk_diagnosis_core.set_epis_diagnosis(i_lang           => i_lang,
                                                    i_prof           => i_prof,
                                                    i_epis_diagnoses => i_epis_diagnoses,
                                                    o_params         => o_params,
                                                    o_error          => o_error);
    END set_epis_diagnosis;
    --
    /**
    * Encapsulates the logic of saving (create/update/cancel) a diagnosis
    * (CALLED BY: PL/SQL)
    *
    * @param   i_lang                  Professional preferred language
    * @param   i_prof                  Professional identification and its context (institution and software)
    * @param   i_patient               patient ID
    * @param   i_episode               episode ID
    * @param   i_diagnosis             Table with diagnosis ID
    * @param   i_alert_diagnosis       Table with alert diagnosis ID
    * @param   i_desc_diag             Table with diagnosis descriptions
    * @param   i_task_type             task type ID
    * @param   i_cdr_call              cdr call ID
    * @param   o_params                Output parameters record
    * @param   o_error                 Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    *
    * @author  Alexandre Santos
    * @version 2.6.2.1
    * @since   22-03-2012
    */
    FUNCTION set_epis_diagnosis
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_patient         IN patient.id_patient%TYPE,
        i_episode         IN episode.id_episode%TYPE,
        i_diagnosis       IN table_number,
        i_alert_diagnosis IN table_number DEFAULT NULL,
        i_desc_diag       IN table_varchar DEFAULT NULL,
        i_task_type       IN NUMBER DEFAULT pk_alert_constant.g_task_diagnosis,
        i_cdr_call        IN cdr_call.id_cdr_call%TYPE DEFAULT NULL,
        o_params          OUT pk_edis_types.table_out_epis_diags,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_rec_epis_diagnosis pk_edis_types.rec_in_epis_diagnosis;
        l_rec_epis_diagnoses pk_edis_types.rec_in_epis_diagnoses;
    BEGIN
        l_rec_epis_diagnosis := pk_diagnosis.get_diag_rec(i_lang            => i_lang,
                                                          i_prof            => i_prof,
                                                          i_patient         => i_patient,
                                                          i_episode         => i_episode,
                                                          i_diagnosis       => i_diagnosis,
                                                          i_alert_diagnosis => i_alert_diagnosis,
                                                          i_desc_diag       => i_desc_diag,
                                                          i_task_type       => i_task_type,
                                                          i_cdr_call        => i_cdr_call);
    
        l_rec_epis_diagnoses.epis_diagnosis := l_rec_epis_diagnosis;
    
        RETURN pk_diagnosis_core.set_epis_diagnosis(i_lang           => i_lang,
                                                    i_prof           => i_prof,
                                                    i_epis_diagnoses => l_rec_epis_diagnoses,
                                                    o_params         => o_params,
                                                    o_error          => o_error);
    END set_epis_diagnosis;
    --
    /**
    * Encapsulates the logic of saving (create/update/cancel) a diagnosis
    * (CALLED BY: PL/SQL)
    *
    * @param   i_lang                  Professional preferred language
    * @param   i_prof                  Professional identification and its context (institution and software)
    * @param   i_patient               patient ID
    * @param   i_episode               episode ID
    * @param   i_diagnosis             diagnosis ID
    * @param   i_alert_diagnosis       alert diagnosis ID
    * @param   i_desc_diag             diagnosis descriptions
    * @param   i_task_type             task type ID
    * @param   i_cdr_call              cdr call ID
    * @param   o_params                Output parameters record
    * @param   o_error                 Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    *
    * @author  Alexandre Santos
    * @version 2.6.2.1
    * @since   22-03-2012
    */
    FUNCTION set_epis_diagnosis
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_patient         IN patient.id_patient%TYPE,
        i_episode         IN episode.id_episode%TYPE,
        i_diagnosis       IN diagnosis.id_diagnosis%TYPE,
        i_alert_diagnosis IN alert_diagnosis.id_alert_diagnosis%TYPE DEFAULT NULL,
        i_desc_diag       IN epis_diagnosis.desc_epis_diagnosis%TYPE DEFAULT NULL,
        i_task_type       IN NUMBER DEFAULT pk_alert_constant.g_task_diagnosis,
        i_cdr_call        IN cdr_call.id_cdr_call%TYPE DEFAULT NULL,
        o_params          OUT pk_edis_types.table_out_epis_diags,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_rec_epis_diagnosis pk_edis_types.rec_in_epis_diagnosis;
        l_rec_epis_diagnoses pk_edis_types.rec_in_epis_diagnoses;
    BEGIN
        l_rec_epis_diagnosis := pk_diagnosis.get_diag_rec(i_lang            => i_lang,
                                                          i_prof            => i_prof,
                                                          i_patient         => i_patient,
                                                          i_episode         => i_episode,
                                                          i_diagnosis       => i_diagnosis,
                                                          i_alert_diagnosis => i_alert_diagnosis,
                                                          i_desc_diag       => i_desc_diag,
                                                          i_task_type       => i_task_type,
                                                          i_cdr_call        => i_cdr_call);
    
        l_rec_epis_diagnoses.epis_diagnosis := l_rec_epis_diagnosis;
    
        RETURN pk_diagnosis_core.set_epis_diagnosis(i_lang           => i_lang,
                                                    i_prof           => i_prof,
                                                    i_epis_diagnoses => l_rec_epis_diagnoses,
                                                    o_params         => o_params,
                                                    o_error          => o_error);
    END set_epis_diagnosis;
    --
    /********************************************************************************************
    * Returns the epis diagnosis record used as input parameter in save functions with the default values
    * for the given diagnosis
    * ATTENTION: This function shouldn't be used by default, please consult EDIS team before using it
    *
    * @param i_lang                   language ID
    * @param i_prof                   Object (professional, Institution and Software)
    * @param i_params                 XML with all input parameters
    *
    * @return                         Epis diagnosis record used as input parameter in save functions
    *
    * @author                         Alexandre Santos
    * @version                        2.6.2
    * @since                          2012/03/21
    **********************************************************************************************/
    FUNCTION get_diag_rec
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_params IN CLOB
    ) RETURN pk_edis_types.rec_in_epis_diagnosis IS
        l_rec_in_epis_diagnoses pk_edis_types.rec_in_epis_diagnoses;
        l_error                 t_error_out;
    BEGIN
        IF pk_diagnosis_form.get_save_parameters(i_lang                  => i_lang,
                                                 i_prof                  => i_prof,
                                                 i_params                => i_params,
                                                 o_rec_in_epis_diagnoses => l_rec_in_epis_diagnoses,
                                                 o_error                 => l_error)
        THEN
            RETURN l_rec_in_epis_diagnoses.epis_diagnosis;
        ELSE
            RETURN NULL;
        END IF;
    END get_diag_rec;
    --
    /********************************************************************************************
    * Returns the epis diagnosis record used as input parameter in save functions with the default values
    * for the given diagnosis
    * ATTENTION: This function shouldn't be used by default, please consult EDIS team before using it
    *
    * @param i_lang                   language ID
    * @param i_prof                   Object (professional, Institution and Software)
    * @param i_params                 Table of XML with all input parameters
    *
    * @return                         Epis diagnosis record used as input parameter in save functions
    *
    * @author                         Alexandre Santos
    * @version                        2.6.2
    * @since                          2012/03/21
    **********************************************************************************************/
    FUNCTION get_diag_rec
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_params IN table_clob
    ) RETURN pk_edis_types.table_in_epis_diagnosis IS
    BEGIN
        RETURN pk_diagnosis_core.get_diag_rec(i_lang => i_lang, i_prof => i_prof, i_params => i_params);
    END get_diag_rec;
    --
    /********************************************************************************************
    * Returns the epis diagnosis record used as input parameter in save functions with the default values
    * for the given diagnosis
    * ATTENTION: This function shouldn't be used by default, please consult EDIS team before using it
    *
    * @param i_lang                   language ID
    * @param i_prof                   Object (professional, Institution and Software)
    * @param i_patient                patient ID
    * @param i_episode                episode ID
    * @param i_diagnosis              Table with diagnosis ID
    * @param i_task_type              task type ID
    * @param i_cdr_call               cdr call ID
    *
    * @return                         Epis diagnosis record used as input parameter in save functions
    *
    * @author                         Alexandre Santos
    * @version                        2.6.2
    * @since                          2012/03/21
    **********************************************************************************************/
    FUNCTION get_diag_rec
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_patient         IN patient.id_patient%TYPE,
        i_episode         IN episode.id_episode%TYPE,
        i_diagnosis       IN table_table_number,
        i_alert_diagnosis IN table_table_number DEFAULT NULL,
        i_desc_diag       IN table_table_varchar DEFAULT NULL,
        i_task_type       IN NUMBER DEFAULT pk_alert_constant.g_task_diagnosis,
        i_cdr_call        IN cdr_call.id_cdr_call%TYPE DEFAULT NULL
    ) RETURN pk_edis_types.table_in_epis_diagnosis IS
    BEGIN
        RETURN pk_diagnosis_core.get_diag_rec(i_lang            => i_lang,
                                              i_prof            => i_prof,
                                              i_patient         => i_patient,
                                              i_episode         => i_episode,
                                              i_diagnosis       => i_diagnosis,
                                              i_alert_diagnosis => i_alert_diagnosis,
                                              i_desc_diag       => i_desc_diag,
                                              i_task_type       => i_task_type,
                                              i_cdr_call        => i_cdr_call);
    END get_diag_rec;

    /********************************************************************************************
    * Returns the epis diagnosis record used as input parameter in save functions with the default values
    * for the given diagnosis
    * ATTENTION: This function shouldn't be used by default, please consult EDIS team before using it
    *
    * @param i_lang                   language ID
    * @param i_prof                   Object (professional, Institution and Software)
    * @param i_patient                patient ID
    * @param i_episode                episode ID
    * @param i_diagnosis              Table with diagnosis ID
    * @param i_task_type              task type ID
    * @param i_cdr_call               cdr call ID
    *
    * @return                         Epis diagnosis record used as input parameter in save functions
    *
    * @author                         Alexandre Santos
    * @version                        2.6.2
    * @since                          2012/03/21
    **********************************************************************************************/
    FUNCTION get_diag_rec
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_patient         IN patient.id_patient%TYPE,
        i_episode         IN episode.id_episode%TYPE,
        i_diagnosis       IN table_number,
        i_alert_diagnosis IN table_number DEFAULT NULL,
        i_desc_diag       IN table_varchar DEFAULT NULL,
        i_task_type       IN NUMBER DEFAULT pk_alert_constant.g_task_diagnosis,
        i_cdr_call        IN cdr_call.id_cdr_call%TYPE DEFAULT NULL
    ) RETURN pk_edis_types.rec_in_epis_diagnosis IS
    BEGIN
        RETURN pk_diagnosis_core.get_diag_rec(i_lang            => i_lang,
                                              i_prof            => i_prof,
                                              i_patient         => i_patient,
                                              i_episode         => i_episode,
                                              i_diagnosis       => i_diagnosis,
                                              i_alert_diagnosis => i_alert_diagnosis,
                                              i_desc_diag       => i_desc_diag,
                                              i_task_type       => i_task_type,
                                              i_cdr_call        => i_cdr_call);
    END get_diag_rec;

    /********************************************************************************************
    * Returns the epis diagnosis record used as input parameter in save functions with the default values
    * for the given diagnosis
    * ATTENTION: This function shouldn't be used by default, please consult EDIS team before using it
    *
    * @param i_lang                   language ID
    * @param i_prof                   Object (professional, Institution and Software)
    * @param i_patient                patient ID
    * @param i_episode                episode ID
    * @param i_diagnosis              diagnosis ID
    * @param i_task_type              task type ID
    * @param i_cdr_call               cdr call ID
    * @param i_id_epis_diagnosis      epis_diagnosis ID
    * @param i_flg_status             Diagnosis status
    * @param i_spec_notes             Diagnosis notes
    *
    * @return                         Epis diagnosis record used as input parameter in save functions
    *
    * @author                         Alexandre Santos
    * @version                        2.6.2
    * @since                          2012/03/21
    **********************************************************************************************/
    FUNCTION get_diag_rec
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_patient           IN patient.id_patient%TYPE,
        i_episode           IN episode.id_episode%TYPE,
        i_diagnosis         IN diagnosis.id_diagnosis%TYPE,
        i_alert_diagnosis   IN alert_diagnosis.id_alert_diagnosis%TYPE DEFAULT NULL,
        i_desc_diag         IN epis_diagnosis.desc_epis_diagnosis%TYPE DEFAULT NULL,
        i_task_type         IN NUMBER DEFAULT pk_alert_constant.g_task_diagnosis,
        i_cdr_call          IN cdr_call.id_cdr_call%TYPE DEFAULT NULL,
        i_id_epis_diagnosis IN epis_diagnosis.id_epis_diagnosis%TYPE DEFAULT NULL,
        i_flg_status        IN epis_diagnosis.flg_status%TYPE DEFAULT NULL,
        i_spec_notes        IN epis_diagnosis.notes%TYPE DEFAULT NULL
    ) RETURN pk_edis_types.rec_in_epis_diagnosis IS
    BEGIN
        RETURN pk_diagnosis_core.get_diag_rec(i_lang            => i_lang,
                                              i_prof            => i_prof,
                                              i_patient         => i_patient,
                                              i_episode         => i_episode,
                                              i_diagnosis       => i_diagnosis,
                                              i_alert_diagnosis => i_alert_diagnosis,
                                              i_desc_diag       => i_desc_diag,
                                              i_task_type       => i_task_type,
                                              i_cdr_call        => i_cdr_call);
    END get_diag_rec;
    --
    /**********************************************************************************************
    * Sets the diagnosis notes  
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids             
    * @param i_episode                episode ID
    * @param i_epis_diag_notes        previous diagnosis notes ID (if it is an edition)
    * @param i_notes                  registered notes
    * @param o_epis_diag_notes        diagnosis notes ID that was saved
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Jos?Silva
    * @version                        2.6.2
    * @since                          28-02-2012
    **********************************************************************************************/
    FUNCTION set_epis_diag_notes
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_episode         IN episode.id_episode%TYPE,
        i_epis_diag_notes IN epis_diagnosis_notes.id_epis_diagnosis_notes%TYPE,
        i_notes           IN epis_diagnosis_notes.notes%TYPE,
        o_epis_diag_notes OUT epis_diagnosis_notes.id_epis_diagnosis_notes%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN pk_diagnosis_core.set_epis_diag_notes(i_lang            => i_lang,
                                                     i_prof            => i_prof,
                                                     i_episode         => i_episode,
                                                     i_epis_diag_notes => i_epis_diag_notes,
                                                     i_notes           => i_notes,
                                                     o_epis_diag_notes => o_epis_diag_notes,
                                                     o_error           => o_error);
    END set_epis_diag_notes;
    --
    /********************************************************************************************
    * Function that gives all the information registered in a diagnosis record
    *
    * @param i_lang                   language ID
    * @param i_prof                   Object (professional, Institution and Software)
    * @param i_episode                episode ID
    * @param i_epis_diag              episode diagnosis ID
    * @param i_epis_diag_hist         episode diagnosis ID (history record)
    *
    * @return                         diagnosis general info
    *
    * @author                         Jos?Silva
    * @version                        2.6.2
    * @since                          2012/02/27
    **********************************************************************************************/
    FUNCTION get_epis_diag
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        i_epis_diag      IN epis_diagnosis.id_epis_diagnosis%TYPE,
        i_epis_diag_hist IN epis_diagnosis_hist.id_epis_diagnosis_hist%TYPE
    ) RETURN pk_edis_types.rec_epis_diagnosis IS
    
    BEGIN
    
        RETURN pk_diagnosis_core.get_epis_diag(i_lang           => i_lang,
                                               i_prof           => i_prof,
                                               i_episode        => i_episode,
                                               i_epis_diag      => i_epis_diag,
                                               i_epis_diag_hist => i_epis_diag_hist);
    END get_epis_diag;

    /**********************************************************************************************
    * List all cancer diagnosis registered in a patient
    *
    * @param i_lang                   Id language
    * @param i_prof                   Professional, software and institution ids
    * @param i_id_patient             Patient id
    * @param o_cursor                 Diagnoses list
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Jos?Silva
    * @version                        2.6.2.1
    * @since                          2012/Mar/29
    **********************************************************************************************/
    FUNCTION get_cancer_diagnosis_list
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        o_cursor     OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        RETURN pk_diagnosis_core.get_pat_diagnosis_list(i_lang                => i_lang,
                                                        i_prof                => i_prof,
                                                        i_id_patient          => i_id_patient,
                                                        i_show_only_cancer    => pk_alert_constant.g_yes,
                                                        i_order_by_final_type => pk_alert_constant.g_yes,
                                                        i_order_by_status     => pk_alert_constant.g_yes,
                                                        o_cursor              => o_cursor,
                                                        o_error               => o_error);
    END get_cancer_diagnosis_list;

    /**********************************************************************************************
    * Get all the cancer diagnoses registered previously in a patient
    *
    * @param i_lang                   Id language
    * @param i_prof                   Professional, software and institution ids
    * @param i_episode                Episode id
    * @param i_patient                Patient id
    * @param o_diags                  Diagnoses description list
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Jos?Silva
    * @version                        2.6.2.1
    * @since                          2012/Apr/12
    **********************************************************************************************/
    FUNCTION get_pat_prev_cancer_diag
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        i_patient IN patient.id_patient%TYPE,
        o_diags   OUT table_varchar,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        RETURN pk_diagnosis_core.get_pat_prev_cancer_diag(i_lang    => i_lang,
                                                          i_prof    => i_prof,
                                                          i_episode => i_episode,
                                                          i_patient => i_patient,
                                                          o_diags   => o_diags,
                                                          o_error   => o_error);
    
    END get_pat_prev_cancer_diag;

    /**********************************************************************************************
    * get actions of the diagnosis general notes
    *
    * @param       i_lang                   preferred language id for this professional
    * @param       i_prof                   professional type
    * @param       i_task_request           task request id (monitorization id)
    * @param       o_actions                actions cursor info 
    * @param       o_error                  error message
    *
    * @return      boolean                  true on success, otherwise false
    *
    * @author                               Sofia Mendes
    * @version                              2.6.2
    * @since                                26-Mar-2012
    **********************************************************************************************/
    FUNCTION get_actions
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_task_request IN epis_diagnosis_notes.id_epis_diagnosis_notes%TYPE,
        o_actions      OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        RETURN pk_diagnosis_core.get_actions(i_lang         => i_lang,
                                             i_prof         => i_prof,
                                             i_task_request => i_task_request,
                                             o_actions      => o_actions,
                                             o_error        => o_error);
    END get_actions;

    /**********************************************************************************************
    * get actions of the final diagnosis 
    *
    * @param       i_lang                   preferred language id for this professional
    * @param       i_prof                   professional type
    * @param       i_task_request           task request id (epis_diagnosis)
    * @param       o_actions                actions cursor info 
    * @param       o_error                  error message
    *
    * @return      boolean                  true on success, otherwise false
    *
    * @author                               Sofia Mendes
    * @version                              2.6.3
    * @since                                29-Nov-2012
    **********************************************************************************************/
    FUNCTION get_actions_final_diags
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_task_request IN epis_diagnosis_notes.id_epis_diagnosis_notes%TYPE,
        o_actions      OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        RETURN pk_diagnosis_core.get_actions_final_diags(i_lang         => i_lang,
                                                         i_prof         => i_prof,
                                                         i_task_request => i_task_request,
                                                         o_actions      => o_actions,
                                                         o_error        => o_error);
    END get_actions_final_diags;

    /**
    * Get diagnosis medical assossiated synonyms
    *
    * @param   i_lang               Language identifier
    * @param   i_diagnosis          Diagnosis identifier
    *
    * @return  BOOLEAN for success. 
    *
    * @author  S�rgio Santos
    * @version v2.5.2
    * @since   08/03/2012
    */
    FUNCTION get_diagnosis_synonyms
    (
        i_lang      IN language.id_language%TYPE,
        i_diagnosis IN diagnosis.id_diagnosis%TYPE,
        o_diag_syn  OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        OPEN o_diag_syn FOR
            SELECT ad.id_alert_diagnosis
              FROM alert_diagnosis ad
              JOIN diagnosis d
                ON d.id_diagnosis = ad.id_diagnosis
             WHERE d.id_diagnosis = i_diagnosis
               AND ad.flg_icd9 = pk_alert_constant.g_no
               AND ad.flg_type = pk_problems.g_medical_diagnosis_type;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_DIAGNOSIS',
                                              'GET_DIAGNOSIS_SYNONYMS',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_diag_syn);
            RETURN FALSE;
    END get_diagnosis_synonyms;

    --
    /**********************************************************************************************
    * Return record diagnosis
    *
    * @param       i_rec_epis_diag          Epis diagnosis record
    *
    * @return      t_table_diagnosis        Diagnosis table
    *
    * @author                               Alexandre Santos
    * @version                              2.6.2.1
    * @since                                03-04-2012
    **********************************************************************************************/
    FUNCTION tf_diagnosis(i_rec_epis_diag IN pk_edis_types.rec_in_epis_diagnosis) RETURN t_table_diagnoses IS
    BEGIN
        RETURN pk_diagnosis_core.tf_diagnosis(i_rec_epis_diag => i_rec_epis_diag);
    END tf_diagnosis;

    /**************************************************************************
    * Get the diagnosis creation date
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID    
    * @param i_id_epis_diagnosis      Epis diagnosis ID
    *                                                                         
    * @author                         Sofia Mendes                        
    * @version                        2.6.1.2                            
    * @since                          19-Sep-2012                            
    **************************************************************************/
    FUNCTION get_diag_hist_creation_dt
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_epis_diagnosis IN epis_diagnosis.id_epis_diagnosis%TYPE
    ) RETURN epis_diagnosis_hist.dt_creation_tstz%TYPE IS
        l_func_name CONSTANT VARCHAR2(25 CHAR) := 'GET_DIAG_HIST_CREATION_DT';
        l_error       t_error_out;
        l_dt_creation epis_diagnosis_hist.dt_creation_tstz%TYPE;
    BEGIN
        g_error := 'get_diag_hist_creation_dt. i_id_epis_diagnosis: ' || i_id_epis_diagnosis;
        pk_alertlog.log_debug(g_error);
        SELECT dt_creation_tstz
          INTO l_dt_creation
          FROM (SELECT row_number() over(PARTITION BY e.id_epis_diagnosis ORDER BY e.dt_creation_tstz DESC) rn,
                       e.dt_creation_tstz
                  FROM epis_diagnosis_hist e
                 WHERE e.id_epis_diagnosis = i_id_epis_diagnosis)
         WHERE rn = 1;
    
        RETURN l_dt_creation;
    EXCEPTION
        WHEN no_data_found THEN
            RETURN NULL;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_DIAGNOSIS',
                                              l_func_name,
                                              l_error);
            RETURN NULL;
    END get_diag_hist_creation_dt;
    --
    /**********************************************************************************************
    * Listar os diagn�sticos definitivos do epis�dio
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids             
    * @param i_id_episode             episode id
    *
    * @param o_error                  Error message
    *
    * @return                         Final Diagnosis
    *                        
    * @author                         Sergio Dias
    * @version                        2.6.3.8.1
    * @since                          20-Sept-2013
    **********************************************************************************************/
    FUNCTION get_final_diagnosis
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_error      OUT t_error_out
    ) RETURN VARCHAR2 IS
        l_func_name            VARCHAR2(200) := 'GET_FINAL_DIAGNOSIS';
        o_final_diagnosis      pk_types.cursor_type;
        l_return               VARCHAR2(200 CHAR);
        l_show_all_diag_states sys_config.value%TYPE;
        l_tbl_final_diagnosis  table_varchar;
    
        CURSOR c_final_diagnosis IS
            SELECT pk_diagnosis.std_diag_desc(i_lang                => i_lang,
                                              i_prof                => i_prof,
                                              i_id_alert_diagnosis  => ad.id_alert_diagnosis,
                                              i_id_diagnosis        => d.id_diagnosis,
                                              i_desc_epis_diagnosis => ed.desc_epis_diagnosis,
                                              i_code                => d.code_icd,
                                              i_flg_other           => d.flg_other,
                                              i_flg_std_diag        => ad.flg_icd9,
                                              i_epis_diag           => ed.id_epis_diagnosis,
                                              i_show_aditional_info => pk_alert_constant.g_no) ||
                   pk_diagnosis.get_origin_diagnosis(i_lang, i_prof, ed.id_episode, ed.id_episode_origin) desc_diagnosis
              FROM epis_diagnosis ed
              JOIN diagnosis d
                ON d.id_diagnosis = ed.id_diagnosis
              LEFT JOIN alert_diagnosis ad
                ON ad.id_alert_diagnosis = ed.id_alert_diagnosis
             WHERE ed.id_episode = i_id_episode
               AND ed.flg_type = pk_diagnosis.g_diag_type_d
               AND ((l_show_all_diag_states = pk_alert_constant.g_no AND
                   ed.flg_status IN
                   (pk_diagnosis.g_ed_flg_status_d, pk_diagnosis.g_ed_flg_status_co, pk_diagnosis.g_ed_flg_status_b)) OR
                   l_show_all_diag_states = pk_alert_constant.g_yes)
             ORDER BY ed.flg_final_type, ed.dt_epis_diagnosis_tstz DESC;
    BEGIN
    
        g_error := 'GET CFG - ' || g_sys_cfg_show_all_diag_states;
        pk_alertlog.log_debug(g_error);
        l_show_all_diag_states := nvl(pk_sysconfig.get_config(i_code_cf => g_sys_cfg_show_all_diag_states,
                                                              i_prof    => i_prof),
                                      pk_alert_constant.g_no);
    
        FOR r_final_diagnosis IN c_final_diagnosis
        LOOP
            l_return := l_return || r_final_diagnosis.desc_diagnosis || '; ';
        END LOOP;
        RETURN l_return;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_DIAGNOSIS',
                                              'GET_FINAL_DIAGNOSIS',
                                              o_error);
            RETURN NULL;
    END;
    --
    /**********************************************************************************************
    * Get the diagnosis cause (ALERT-261232)
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids             
    * @param i_diagnosis              diagnosis id
    * @param o_desc_cause             Cause description
    * @param o_code_cause             Cause code
    * @param o_error                  Error message
    *
    * @return                         BOOLEAN for success. 
    *                        
    * @author                         Alexandre Santos
    * @version                        2.6.3.8.2
    * @since                          08-10-2013
    **********************************************************************************************/
    FUNCTION get_diagnosis_cause
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_diagnosis  IN diagnosis.id_diagnosis%TYPE,
        o_desc_cause OUT pk_translation.t_desc_translation,
        o_code_cause OUT diagnosis.code_icd%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        r_cause pk_diagnosis_form.c_causes%ROWTYPE;
    BEGIN
        IF g_diagnosis_cause IS NOT NULL
           AND i_diagnosis = g_diagnosis_cause
        THEN
            o_desc_cause := g_desc_cause;
            o_code_cause := g_code_cause;
        ELSE
            OPEN pk_diagnosis_form.c_causes(i_lang => i_lang, i_prof => i_prof, i_diagnosis => i_diagnosis);
            FETCH pk_diagnosis_form.c_causes
                INTO r_cause;
            CLOSE pk_diagnosis_form.c_causes;
        
            g_diagnosis_cause := i_diagnosis;
            g_desc_cause      := r_cause.desc_cause;
            g_code_cause      := r_cause.code_cause;
        
            o_desc_cause := g_desc_cause;
            o_code_cause := g_code_cause;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_DIAGNOSIS',
                                              'GET_DIAGNOSIS_CAUSE',
                                              o_error);
            RETURN FALSE;
    END get_diagnosis_cause;
    --
    /**********************************************************************************************
    * Get the diagnosis cause description (ALERT-261232)
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids             
    * @param i_diagnosis              diagnosis id
    *
    * @return                         Cause description. 
    *                        
    * @author                         Alexandre Santos
    * @version                        2.6.3.8.2
    * @since                          08-10-2013
    **********************************************************************************************/
    FUNCTION get_diag_cause_desc
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_diagnosis IN diagnosis.id_diagnosis%TYPE
    ) RETURN VARCHAR2 IS
        l_desc_cause pk_translation.t_desc_translation;
        l_code_cause diagnosis.code_icd%TYPE;
        l_error      t_error_out;
    BEGIN
        IF NOT pk_diagnosis.get_diagnosis_cause(i_lang       => i_lang,
                                                i_prof       => i_prof,
                                                i_diagnosis  => i_diagnosis,
                                                o_desc_cause => l_desc_cause,
                                                o_code_cause => l_code_cause,
                                                o_error      => l_error)
        THEN
            l_desc_cause := NULL;
        END IF;
    
        RETURN l_desc_cause;
    END get_diag_cause_desc;
    --
    /**********************************************************************************************
    * Get the diagnosis cause code (ALERT-261232)
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids             
    * @param i_diagnosis              diagnosis id
    *
    * @return                         Cause code. 
    *                        
    * @author                         Alexandre Santos
    * @version                        2.6.3.8.2
    * @since                          08-10-2013
    **********************************************************************************************/
    FUNCTION get_diag_cause_code
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_diagnosis IN diagnosis.id_diagnosis%TYPE
    ) RETURN VARCHAR2 IS
        l_desc_cause pk_translation.t_desc_translation;
        l_code_cause diagnosis.code_icd%TYPE;
        l_error      t_error_out;
    BEGIN
        IF NOT pk_diagnosis.get_diagnosis_cause(i_lang       => i_lang,
                                                i_prof       => i_prof,
                                                i_diagnosis  => i_diagnosis,
                                                o_desc_cause => l_desc_cause,
                                                o_code_cause => l_code_cause,
                                                o_error      => l_error)
        THEN
            l_code_cause := NULL;
        END IF;
    
        RETURN l_code_cause;
    END get_diag_cause_code;

    /**************************************************************************
    * Get the diagnosis creation date
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID    
    * @param i_mcdt_req_diagnosis     MCDT REQ DIAGNOSIS ID
    *                                                                         
    * @author                         Alexandre Santos                 
    * @version                        2.6.4                            
    * @since                          29-Sep-2014
    **************************************************************************/
    FUNCTION get_mcdt_description
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_mcdt_req_diagnosis     IN mcdt_req_diagnosis.id_mcdt_req_diagnosis%TYPE,
        i_flg_terminology_server IN VARCHAR2 DEFAULT pk_alert_constant.g_no
    ) RETURN VARCHAR2 IS
        l_func_name CONSTANT VARCHAR2(50 CHAR) := 'GET_MCDT_DESCRIPTION';
        --
        l_error t_error_out;
        --
        l_ret pk_translation.t_desc_translation;
    BEGIN
        g_error := 'i_mcdt_req_diagnosis: ' || i_mcdt_req_diagnosis;
        pk_alertlog.log_debug(text => g_error, sub_object_name => l_func_name);
        SELECT CASE
                    WHEN i_flg_terminology_server = pk_alert_constant.g_no THEN
                     pk_diagnosis.std_diag_desc(i_lang                => i_lang,
                                                i_prof                => i_prof,
                                                i_id_alert_diagnosis  => nvl(ed.id_alert_diagnosis, mrd.id_alert_diagnosis),
                                                i_id_diagnosis        => d.id_diagnosis,
                                                i_desc_epis_diagnosis => ed.desc_epis_diagnosis,
                                                i_code                => d.code_icd,
                                                i_flg_other           => d.flg_other,
                                                i_flg_std_diag        => pk_alert_constant.g_yes,
                                                i_epis_diag           => ed.id_epis_diagnosis)
                    ELSE
                     coalesce(ed.desc_epis_diagnosis,
                              pk_ts3_search.get_term_description(i_id_language     => i_lang,
                                                                 i_id_institution  => i_prof.institution,
                                                                 i_id_software     => i_prof.software,
                                                                 i_id_concept_term => nvl(ed.id_alert_diagnosis,
                                                                                          mrd.id_alert_diagnosis),
                                                                 i_concept_type    => CASE
                                                                                          WHEN ed.desc_epis_diagnosis IS NULL THEN
                                                                                           'DIAGNOSIS'
                                                                                          ELSE
                                                                                           'OTHER_DIAGNOSIS'
                                                                                      END,
                                                                 i_id_task_type    => 63,
                                                                 i_context_type    => 'SEARCHABLE',
                                                                 i_free_text_desc  => ed.desc_epis_diagnosis))
                END desc_diagnosis
          INTO l_ret
          FROM mcdt_req_diagnosis mrd
          LEFT JOIN epis_diagnosis ed
            ON ed.id_epis_diagnosis = mrd.id_epis_diagnosis
          JOIN diagnosis d
            ON d.id_diagnosis = mrd.id_diagnosis
         WHERE mrd.id_mcdt_req_diagnosis = i_mcdt_req_diagnosis
         ORDER BY 1;
    
        RETURN l_ret;
    EXCEPTION
        WHEN no_data_found THEN
            RETURN NULL;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_DIAGNOSIS',
                                              l_func_name,
                                              l_error);
            RETURN NULL;
    END get_mcdt_description;

    /********************************************************************************************
     * Get all diagnosis with std_diag_desc and the notes that were documented in given episode list
     *
     * @param i_lang                   The user language id
     * @param i_prof                   The Professional, software and institution executing the request
     * @param i_tbl_episode            Episodes array
     * @param o_diag                   A cursor with the DESC_INFO as 'diag description, notes'
     * @param o_error                  Error message
     *
     * @return                         true or false on success or error
     * 
     * @author                         Nuno Alves
     * @version                        2.6.3.8.2
     * @since                          2015/05/06
     *
     * Notes: For use on previous visits and current encounter
     *        Diagnosis description (code) (Principal diagnosis (only if Yes), status, date of initial diagnosis), Specific notes 
     *        Sorted by:  Type of diagnosis (principal listed first) and then status (confirmed, under investigation, ruled out)
    **********************************************************************************************/
    FUNCTION get_epis_diag_with_notes
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_tbl_episode IN table_number,
        o_diag        OUT pk_types.cursor_type,
        o_impressions OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_impressions     pk_edis_types.t_cur_diag_notes;
        l_impressions_tab pk_edis_types.t_coll_diag_notes;
    
    BEGIN
        g_error := 'OPEN CURSOR o_diag';
        pk_alertlog.log_debug(g_error);
        OPEN o_diag FOR
            SELECT std_diag_desc(i_lang                  => i_lang,
                                 i_prof                  => i_prof,
                                 i_id_alert_diagnosis    => t.id_alert_diagnosis,
                                 i_id_diagnosis          => t.id_diagnosis,
                                 i_desc_epis_diagnosis   => t.desc_epis_diagnosis,
                                 i_code                  => t.code_icd,
                                 i_flg_other             => t.flg_other,
                                 i_flg_std_diag          => t.flg_icd9,
                                 i_epis_diag             => t.id_epis_diagnosis,
                                 i_flg_show_if_principal => pk_alert_constant.g_yes,
                                 i_flg_show_dt_initial   => pk_alert_constant.g_yes) ||
                   nvl2(t.notes, ', ' || t.notes, NULL) desc_info,
                   pk_date_utils.date_send_tsz(i_lang,
                                               coalesce(t.dt_epis_diagnosis_tstz,
                                                        t.dt_rulled_out_tstz,
                                                        t.dt_confirmed_tstz),
                                               i_prof.institution,
                                               i_prof.software) dt_epis_diagnosis,
                   t.id_episode,
                   1 rank,
                   pk_prof_utils.get_detail_signature(i_lang,
                                                      i_prof,
                                                      t.id_episode,
                                                      t.dt_epis_diagnosis_tstz,
                                                      t.id_professional_diag) signature
              FROM (SELECT ad.id_alert_diagnosis,
                           d.id_diagnosis,
                           e.desc_epis_diagnosis,
                           d.code_icd,
                           d.flg_other,
                           ad.flg_icd9,
                           e.id_epis_diagnosis,
                           e.notes,
                           e.dt_epis_diagnosis_tstz,
                           e.dt_rulled_out_tstz,
                           e.dt_confirmed_tstz,
                           e.id_episode,
                           row_number() over(PARTITION BY e.id_diagnosis ORDER BY e.flg_type ASC) rn,
                           decode(e.flg_final_type,
                                  pk_diagnosis.g_flg_final_type_p,
                                  1,
                                  pk_diagnosis.g_flg_final_type_s,
                                  2,
                                  3) rank_flg_final_type,
                           pk_sysdomain.get_rank(i_lang     => i_lang,
                                                 i_code_dom => g_epis_diag_status,
                                                 i_val      => e.flg_status) rank_flg_status,
                           e.id_professional_diag
                      FROM epis_diagnosis e
                      JOIN diagnosis d
                        ON d.id_diagnosis = e.id_diagnosis
                      LEFT JOIN alert_diagnosis ad
                        ON ad.id_alert_diagnosis = e.id_alert_diagnosis
                     WHERE e.id_episode IN (SELECT /*+opt_estimate(TABLE, t, rows = 1)*/
                                             column_value
                                              FROM TABLE(i_tbl_episode) t)
                       AND e.flg_status IN (pk_alert_constant.g_epis_diag_flg_status_d,
                                            pk_alert_constant.g_epis_diag_flg_status_f,
                                            pk_alert_constant.g_epis_diag_flg_status_r,
                                            pk_alert_constant.g_epis_diag_flg_status_p)
                       AND e.flg_type IN
                           (pk_alert_constant.g_epis_diag_flg_type_d, pk_alert_constant.g_epis_diag_flg_type_p)) t
             WHERE t.rn = 1
             ORDER BY t.rank_flg_final_type NULLS LAST, t.rank_flg_status NULLS LAST, dt_epis_diagnosis DESC;
    
        -- GET IMPRESSIONS INFO
        -- Make sure there is nothing on the tbl_temp
        DELETE FROM tbl_temp;
        FOR epis IN (SELECT /*+opt_estimate(TABLE, t, rows = 1)*/
                      column_value
                       FROM TABLE(i_tbl_episode) t)
        LOOP
            -- Get impressions
            g_error := 'CALL pk_diagnosis_core.get_epis_diag_notes';
            pk_alertlog.log_debug(g_error);
            IF NOT pk_diagnosis_core.get_epis_diag_notes(i_lang       => i_lang,
                                                         i_prof       => i_prof,
                                                         i_episode    => epis.column_value,
                                                         o_diag_notes => l_impressions,
                                                         o_error      => o_error)
            THEN
                RAISE e_call_exception;
            END IF;
        
            FETCH l_impressions BULK COLLECT
                INTO l_impressions_tab;
        
            -- Populate tbl_temp with impressions info
            g_error := 'FORALL INSERT into tbl_temp';
            pk_alertlog.log_debug(g_error);
            FORALL i IN 1 .. l_impressions_tab.count
                INSERT INTO tbl_temp
                    (num_1, vc_1, vc_2, vc_3, vc_4)
                VALUES
                    (epis.column_value,
                     l_impressions_tab(i).notes,
                     l_impressions_tab(i).dt_register,
                     l_impressions_tab(i).flg_status,
                     l_impressions_tab(i).signature);
        END LOOP;
    
        g_error := 'OPEN CURSOR o_impressions';
        pk_alertlog.log_debug(g_error);
        OPEN o_impressions FOR
            SELECT tt.vc_1 desc_info, tt.vc_2 dt_impression, tt.num_1 id_episode, tt.vc_4 signature
              FROM tbl_temp tt
             WHERE tt.vc_3 = pk_alert_constant.g_active;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_diag);
            pk_types.open_my_cursor(o_impressions);
            g_error := pk_message.get_message(i_lang, 'COMMON_M001') || chr(10) || g_error;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_DIAGNOSIS',
                                              'GET_EPIS_DIAG_WITH_NOTES',
                                              o_error);
            RETURN FALSE;
    END get_epis_diag_with_notes;

    /********************************************************************************************
     * Get congenital anomalies (1st, 2nd ...) for NOM024
     *
     * @param i_lang                  The user language id
     * @param i_prof                  The Professional, software and institution executing the request
     * @param i_id_episode            Episode ID
     * @param i_nr_anomalie           Anomalie number (first or second)
     *
     * @return                        Anomalie description
     * 
     * @author                        Vanessa Basottelli
     * @version                       2.7.0
     * @since                         06/02/2017
     *
    **********************************************************************************************/
    FUNCTION get_congenital_anomalies
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_episode  IN episode.id_episode%TYPE,
        i_nr_anomalie IN NUMBER
    ) RETURN VARCHAR2 IS
        l_anomalie   VARCHAR2(4000 CHAR);
        tbl_anomalie table_varchar;
    BEGIN
        SELECT pk_diagnosis_core.get_diagnosis_code(i_diagnosis   => t.id_diagnosis,
                                                    i_institution => t.id_institution,
                                                    i_software    => pk_episode.get_episode_software(i_lang       => i_lang,
                                                                                                     i_prof       => i_prof,
                                                                                                     i_id_episode => i_id_episode))
          BULK COLLECT
          INTO tbl_anomalie
          FROM (SELECT row_number() over(PARTITION BY phd.id_episode ORDER BY phd.dt_pat_history_diagnosis_tstz ASC) rn,
                       phd.id_diagnosis,
                       phd.id_institution
                  FROM pat_history_diagnosis phd
                 WHERE phd.id_episode = i_id_episode
                   AND phd.flg_status <> pk_alert_constant.g_epis_diag_flg_status_c
                   AND phd.flg_type = pk_past_history.g_alert_diag_type_cong_anom
                   AND phd.id_pat_history_diagnosis_new IS NULL
                   AND phd.flg_recent_diag = g_yes) t
         WHERE (rn = i_nr_anomalie);
    
        IF tbl_anomalie.count > 0
        THEN
            l_anomalie := tbl_anomalie(1);
        END IF;
    
        RETURN l_anomalie;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_congenital_anomalies;

    --- VWR
    /********************************************************************************************
    * Get DIAGNOSIS viewer checklist 
    *             
    * @param i_lang       language idenfier
    * @param i_scope_type scope flag | 'P' - Patient, 'E' - Episode, 'V' - Visit 
    * @param i_id_patient patient idenfier
    * @param i_id_episode episode idenfier
    * @param o_flg_out    flag out 
    * @param o_error      t_error_out type error
    *
    * @return VARCHAR2  Viewer checklist status | 'N' - Not started , 'C' - Complete, 'O' - On going
    * 
    * @author                         Elisabete Bugalho
    * @version                        2.6.5
    * @since                          2016-10-25
    **********************************************************************************************/
    FUNCTION get_diagnosis_viewer_checklist
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope_type IN VARCHAR2,
        i_id_episode IN episode.id_episode%TYPE,
        i_id_patient IN patient.id_patient%TYPE,
        i_flg_type   IN epis_diagnosis.flg_type%TYPE
    ) RETURN VARCHAR2 IS
        l_episodes table_number;
        l_count    NUMBER(12) := 0;
        l_status   VARCHAR2(1 CHAR) := pk_viewer_checklist.g_checklist_not_started;
    
    BEGIN
        SELECT *
          BULK COLLECT
          INTO l_episodes
          FROM TABLE(pk_episode.get_scope(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_patient    => i_id_patient,
                                          i_episode    => i_id_episode,
                                          i_flg_filter => i_scope_type));
    
        SELECT COUNT(1)
          INTO l_count
          FROM (SELECT en.id_epis_diagnosis_notes id
                  FROM epis_diagnosis_notes en
                 WHERE en.id_episode IN (SELECT column_value /*+opt_estimate (table t rows=0.00000000001)*/
                                           FROM TABLE(l_episodes) t)
                   AND nvl2(id_cancel_reason, pk_alert_constant.g_cancelled, pk_alert_constant.g_active) =
                       pk_alert_constant.g_active
                UNION
                SELECT ed.id_epis_diagnosis
                  FROM epis_diagnosis ed
                 WHERE ed.id_episode IN (SELECT /*+opt_estimate(table,t1,scale_rows=0.0000001))*/
                                          t1.column_value
                                           FROM TABLE(l_episodes) t1)
                   AND ed.flg_status NOT IN (pk_diagnosis.g_ed_flg_status_ca)
                   AND ((ed.flg_status <> pk_diagnosis.g_ed_flg_status_r AND i_flg_type = pk_diagnosis.g_diag_type_d) OR
                       i_flg_type = pk_diagnosis.g_diag_type_p)
                   AND ed.flg_type = i_flg_type);
        IF l_count > 0
        THEN
            l_status := pk_viewer_checklist.g_checklist_completed;
        END IF;
        RETURN l_status;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN l_status;
    END get_diagnosis_viewer_checklist;

    /********************************************************************************************
    * Get DIFF DIAGNOSIS viewer checklist 
    *             
    * @param i_lang       language idenfier
    * @param i_scope_type scope flag | 'P' - Patient, 'E' - Episode, 'V' - Visit 
    * @param i_id_patient patient idenfier
    * @param i_id_episode episode idenfier
    * @param o_flg_out    flag out 
    * @param o_error      t_error_out type error
    *
    * @return VARCHAR2  Viewer checklist status | 'N' - Not started , 'C' - Complete, 'O' - On going
    * 
    * @author                         Elisabete Bugalho
    * @version                        2.6.5
    * @since                          2016-10-25
    **********************************************************************************************/
    FUNCTION get_diag_diff_viewer_check
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope_type IN VARCHAR2,
        i_id_episode IN episode.id_episode%TYPE,
        i_id_patient IN patient.id_patient%TYPE
    ) RETURN VARCHAR2 IS
        l_status VARCHAR2(1 CHAR) := pk_viewer_checklist.g_checklist_not_started;
    
    BEGIN
        RETURN get_diagnosis_viewer_checklist(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_scope_type => i_scope_type,
                                              i_id_episode => i_id_episode,
                                              i_id_patient => i_id_patient,
                                              i_flg_type   => pk_diagnosis.g_diag_type_p);
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN l_status;
    END get_diag_diff_viewer_check;

    /********************************************************************************************
    * Get FINAL DIAGNOSIS viewer checklist 
    *             
    * @param i_lang       language idenfier
    * @param i_scope_type scope flag | 'P' - Patient, 'E' - Episode, 'V' - Visit 
    * @param i_id_patient patient idenfier
    * @param i_id_episode episode idenfier
    * @param o_flg_out    flag out 
    * @param o_error      t_error_out type error
    *
    * @return VARCHAR2  Viewer checklist status | 'N' - Not started , 'C' - Complete, 'O' - On going
    * 
    * @author                         Elisabete Bugalho
    * @version                        2.6.5
    * @since                          2016-10-25
    **********************************************************************************************/
    FUNCTION get_diag_final_viewer_check
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope_type IN VARCHAR2,
        i_id_episode IN episode.id_episode%TYPE,
        i_id_patient IN patient.id_patient%TYPE
    ) RETURN VARCHAR2 IS
        l_status VARCHAR2(1 CHAR) := pk_viewer_checklist.g_checklist_not_started;
    
    BEGIN
        RETURN get_diagnosis_viewer_checklist(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_scope_type => i_scope_type,
                                              i_id_episode => i_id_episode,
                                              i_id_patient => i_id_patient,
                                              i_flg_type   => pk_diagnosis.g_diag_type_d);
    EXCEPTION
        WHEN OTHERS THEN
            RETURN l_status;
    END get_diag_final_viewer_check;

    /********************************************************************************************
    * Get social DIAGNOSIS viewer checklist 
    *             
    * @param i_lang       language idenfier
    * @param i_scope_type scope flag | 'P' - Patient, 'E' - Episode, 'V' - Visit 
    * @param i_id_patient patient idenfier
    * @param i_id_episode episode idenfier
    * @param o_flg_out    flag out 
    * @param o_error      t_error_out type error
    *
    * @return VARCHAR2  Viewer checklist status | 'N' - Not started , 'C' - Complete, 'O' - On going
    * 
    * @author                         Elisabete Bugalho
    * @version                        2.6.5
    * @since                          2016-10-25
    **********************************************************************************************/
    FUNCTION get_diag_social_viewer_check
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope_type IN VARCHAR2,
        i_id_episode IN episode.id_episode%TYPE,
        i_id_patient IN patient.id_patient%TYPE
    ) RETURN VARCHAR2 IS
        l_status VARCHAR2(1 CHAR) := pk_viewer_checklist.g_checklist_not_started;
    
    BEGIN
        RETURN get_diagnosis_viewer_checklist(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_scope_type => i_scope_type,
                                              i_id_episode => i_id_episode,
                                              i_id_patient => i_id_patient,
                                              i_flg_type   => pk_diagnosis.g_diag_type_p);
    EXCEPTION
        WHEN OTHERS THEN
            RETURN l_status;
    END get_diag_social_viewer_check;

    /********************************************************************************************
    * Get DIAGNOSIS viewer checklist 
    *             
    * @param i_lang       language idenfier
    * @param i_scope_type scope flag | 'P' - Patient, 'E' - Episode, 'V' - Visit 
    * @param i_id_patient patient idenfier
    * @param i_id_episode episode idenfier
    * @param o_flg_out    flag out 
    * @param o_error      t_error_out type error
    *
    * @return VARCHAR2  Viewer checklist status | 'N' - Not started , 'C' - Complete, 'O' - On going
    * 
    * @author                         Carlos Ferreira
    * @version                        2.6.5
    * @since                          2017-02-23
    **********************************************************************************************/
    FUNCTION get_diagnoses_viewer_check
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope_type IN VARCHAR2,
        i_id_episode IN episode.id_episode%TYPE,
        i_id_patient IN patient.id_patient%TYPE
    ) RETURN VARCHAR2 IS
        l_status VARCHAR2(1 CHAR) := pk_viewer_checklist.g_checklist_not_started;
    BEGIN
        l_status := get_diag_diff_viewer_check(i_lang       => i_lang,
                                               i_prof       => i_prof,
                                               i_scope_type => i_scope_type,
                                               i_id_episode => i_id_episode,
                                               i_id_patient => i_id_patient);
    
        IF l_status = pk_viewer_checklist.g_checklist_not_started
        THEN
            l_status := get_diag_final_viewer_check(i_lang       => i_lang,
                                                    i_prof       => i_prof,
                                                    i_scope_type => i_scope_type,
                                                    i_id_episode => i_id_episode,
                                                    i_id_patient => i_id_patient);
        END IF;
    
        RETURN l_status;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN l_status;
    END get_diagnoses_viewer_check;

    /* *******************************************************************************************
    * Get DIAGNOSIS viewer checklist depending of type of episode and status
    *             
    * @param i_lang       language idenfier
    * @param i_scope_type scope flag | 'P' - Patient, 'E' - Episode, 'V' - Visit 
    * @param i_id_patient patient idenfier
    * @param i_id_episode episode idenfier
    * @param o_flg_out    flag out 
    * @param o_error      t_error_out type error
    *
    * @return VARCHAR2  Viewer checklist status | 'N' - Not started , 'C' - Complete, 'O' - On going
    * 
    * @author                         Carlos Ferreira
    * @version                        2.6.5
    * @since                          2017-02-27
    **********************************************************************************************/
    FUNCTION get_vwr_diag_type_epis
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope_type IN VARCHAR2,
        i_id_episode IN episode.id_episode%TYPE,
        i_id_patient IN patient.id_patient%TYPE,
        i_epis_type  IN NUMBER,
        i_tbl_status IN table_varchar
    ) RETURN VARCHAR2 IS
        l_status   VARCHAR2(1 CHAR) := pk_viewer_checklist.g_checklist_not_started;
        l_episodes table_number;
        l_count    NUMBER;
        l_prof_cat VARCHAR2(5 CHAR) := pk_prof_utils.get_category(i_lang => i_lang, i_prof => i_prof);
    BEGIN
    
        SELECT /*+ OPT_ESTIMATE(TABLE tblx ROWS=1) */
         e.id_episode
          BULK COLLECT
          INTO l_episodes
          FROM (SELECT column_value id_episode
                  FROM TABLE(pk_episode.get_scope(i_lang       => i_lang,
                                                  i_prof       => i_prof,
                                                  i_patient    => i_id_patient,
                                                  i_episode    => i_id_episode,
                                                  i_flg_filter => i_scope_type))) tblx
          JOIN episode e
            ON e.id_episode = tblx.id_episode;
        --WHERE e.id_epis_type = i_epis_type;
    
        SELECT COUNT(*)
          INTO l_count
          FROM v_episode_all_diagnoses t
         WHERE t.id_episode IN (SELECT column_value /*+ OPT_ESTIMATE(TABLE xx ROWS=1) */
                                  FROM TABLE(l_episodes) xx)
           AND t.flg_status IN (SELECT column_value /*+ OPT_ESTIMATE(TABLE yy ROWS=1) */
                                  FROM TABLE(i_tbl_status) yy)
           AND ((t.flg_status IN (pk_diagnosis.g_ed_flg_status_p, pk_diagnosis.g_ed_flg_status_d) AND
               pk_prof_utils.get_category(i_lang => i_lang,
                                            i_prof => profissional(t.id_professional_diag,
                                                                   i_prof.institution,
                                                                   i_prof.software)) = l_prof_cat) OR
               (t.flg_status = pk_diagnosis.g_ed_flg_status_co AND
               pk_prof_utils.get_category(i_lang => i_lang,
                                            i_prof => profissional(t.id_prof_confirmed,
                                                                   i_prof.institution,
                                                                   i_prof.software)) = l_prof_cat));
    
        IF l_count = 0
        THEN
            SELECT COUNT(*)
              INTO l_count
              FROM epis_diagnosis_notes a
             WHERE a.id_episode = i_id_episode
               AND pk_prof_utils.get_category(i_lang => i_lang,
                                              i_prof => profissional(a.id_prof_create,
                                                                     i_prof.institution,
                                                                     i_prof.software)) = l_prof_cat;
        END IF;
    
        IF l_count > 0
        THEN
            l_status := pk_viewer_checklist.g_checklist_completed;
        END IF;
    
        RETURN l_status;
    
    END get_vwr_diag_type_epis;

    --
    /**********************************************************************************************
    * Listar os diagn�sticos definitivos do epis�dio
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids             
    * @param i_epis                   episode id
    * @param i_preg_out_type          type Abortion (A) or Delivery(D)
    * @param o_exists                 IF exists, return 'Y', otherwise, return 'N'
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Pedro Henriques
    * @version                        1.0 
    * @since                          2017/07/27
    **********************************************************************************************/
    FUNCTION get_final_diag_abort_deliv
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_epis          IN episode.id_episode%TYPE,
        i_preg_out_type IN pat_pregnancy.flg_preg_out_type%TYPE,
        i_diagnosis     IN table_number,
        o_exists        OUT VARCHAR2,
        o_count         OUT NUMBER,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_DIAGNOSIS.GET_FINAL_DIAGNOSIS_INTERNAL FUNCTION FOR ID_EPISODE: ' || i_epis;
        pk_alertlog.log_debug(g_error);
        IF NOT pk_diagnosis_core.get_final_diag_abort_deliv(i_lang          => i_lang,
                                                            i_prof          => i_prof,
                                                            i_epis          => i_epis,
                                                            i_preg_out_type => i_preg_out_type,
                                                            i_diagnosis     => i_diagnosis,
                                                            o_exists        => o_exists,
                                                            o_count         => o_count,
                                                            o_error         => o_error)
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
                                              'ALERT',
                                              'PK_DIAGNOSIS',
                                              'GET_FINAL_DIAG_ABORT_DELIV',
                                              o_error);
            RETURN FALSE;
    END get_final_diag_abort_deliv;

BEGIN
    pk_alertlog.log_init(pk_alertlog.who_am_i);
END pk_diagnosis;
/
