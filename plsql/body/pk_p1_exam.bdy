/*-- Last Change Revision: $Rev: 2027429 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:42:12 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_p1_exam AS

    /********************************************************************************************
    * Returns a list with the most frequent exams for a given professional
    *
    * @param i_lang          Language ID
    * @param i_prof          Professional info: id, institution and software
    * @param i_patient       Patient ID
    * @param i_exam_type     Exam type {*} 'I' Image {*} 'E' Other Exams
    * @param i_codification  Exam codification id
    * @param o_list          Exam list
    * @param o_error         Error message
    *
    * @return                TRUE if sucess, FALSE otherwise
    *
    * @author                Ana Monteiro
    * @version               1.0
    * @since                 2009-09-08
    ********************************************************************************************/
    FUNCTION get_exam_selection_list
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_exam_type    IN exam.flg_type%TYPE,
        i_codification IN codification.id_codification%TYPE,
        o_list         OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'pk_exam_api_db.get_exam_selection_list / ID_PAT=' || i_patient || '|EXAM_TYPE=' || i_exam_type ||
                   '|ID_CODIFICATION=' || i_codification;
        OPEN o_list FOR
            SELECT *
              FROM TABLE(pk_exams_api_db.get_exam_selection_list(i_lang         => i_lang,
                                                                 i_prof         => i_prof,
                                                                 i_patient      => i_patient,
                                                                 i_episode      => NULL,
                                                                 i_exam_type    => i_exam_type,
                                                                 i_codification => i_codification));
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_alertlog.log_warn(g_error);
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_EXAM_SELECTION_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_exam_selection_list;

    /********************************************************************************************
    * Returns a list with the exams' categories
    *
    * @param i_lang          Language ID
    * @param i_prof          Professional info: id, institution and software
    * @param i_patient       Patient ID
    * @param i_exam_type     Exam type {*} 'I' Image {*} 'E' Other Exams
    * @param i_codification  Exam codification id
    * @param o_list          Exam list
    * @param o_error         Error message
    *
    * @return                TRUE if sucess, FALSE otherwise
    *
    * @author                Ana Monteiro
    * @version               1.0
    * @since                 2009-09-08
    ********************************************************************************************/
    FUNCTION get_exam_category_search
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_exam_type    IN exam.flg_type%TYPE,
        i_codification IN codification.id_codification%TYPE,
        o_list         OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error  := 'pk_exam_api_db.get_exam_search / ID_PAT=' || i_patient || '|EXAM_TYPE=' || i_exam_type ||
                    '|ID_CODIFICATION=' || i_codification;
        g_retval := pk_exams_api_db.get_exam_category_search(i_lang         => i_lang,
                                                             i_prof         => i_prof,
                                                             i_patient      => i_patient,
                                                             i_exam_type    => i_exam_type,
                                                             i_codification => i_codification,
                                                             o_list         => o_list,
                                                             o_error        => o_error);
        IF NOT g_retval
        THEN
            g_error := 'ERROR: ' || g_error;
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_alertlog.log_warn(g_error);
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_EXAM_CATEGORY_SEARCH',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_exam_category_search;

    /********************************************************************************************
    * Returns a list with the exams' within a given category
    *
    * @param i_lang          Language ID
    * @param i_prof          Professional info: id, institution and software
    * @param i_patient       Patient ID
    * @param i_exam_cat      Exam category ID
    * @param i_exam_type     Exam type {*} 'I' Image {*} 'E' Other Exams        
    * @param i_codification  Exam codification id
    * @param o_list          Exam list
    * @param o_error         Error message
    *
    * @return                TRUE if sucess, FALSE otherwise
    *
    * @author                Ana Monteiro
    * @version               1.0
    * @since                 2009-09-08
    ********************************************************************************************/
    FUNCTION get_exam_in_category
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_exam_cat     IN exam_cat.id_exam_cat%TYPE,
        i_exam_type    IN exam.flg_type%TYPE,
        i_codification IN codification.id_codification%TYPE,
        o_list         OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_error  := 'pk_exam_api_db.get_exam_in_category / ID_PAT=' || i_patient || '|EXAM_CAT=' || i_exam_cat ||
                    '|EXAM_TYPE=' || i_exam_type || '|ID_CODIFICATION=' || i_codification;
        g_retval := pk_exams_api_db.get_exam_in_category(i_lang         => i_lang,
                                                         i_prof         => i_prof,
                                                         i_patient      => i_patient,
                                                         i_exam_cat     => i_exam_cat,
                                                         i_exam_type    => i_exam_type,
                                                         i_codification => i_codification,
                                                         o_list         => o_list,
                                                         o_error        => o_error);
        IF NOT g_retval
        THEN
            g_error := 'ERROR: ' || g_error;
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_alertlog.log_warn(g_error);
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_EXAM_IN_CATEGORY',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_exam_in_category;

    /********************************************************************************************
    * Returns a list with the results of the user search
    *
    * @param i_lang          Language ID
    * @param i_prof          Professional info: id, institution and software
    * @param i_patient       Patient ID
    * @param i_exam_type     Exam type {*} 'I' Image {*} 'E' Other Exams
    * @param i_value         Search string        
    * @param i_codification  Exam codification id
    * @param o_flg_show      If exist message to show {*} 'Y' Yes {*} 'N' No
    * @param o_msg           Message indicating that exceeded the limit of records
    * @param o_msg_title     Title of the message to the user, if o_flg_show is 'Y'
    * @param o_list          Exam list
    * @param o_error         Error message
    *
    * @return                TRUE if sucess, FALSE otherwise
    *
    * @author                Ana Monteiro
    * @version               1.0
    * @since                 2009-09-08
    ********************************************************************************************/

    FUNCTION get_exam_search
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_exam_type    IN exam.flg_type%TYPE,
        i_value        IN VARCHAR2,
        i_codification IN codification.id_codification%TYPE,
        o_flg_show     OUT VARCHAR2,
        o_msg          OUT VARCHAR2,
        o_msg_title    OUT VARCHAR2,
        o_list         OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error  := 'pk_exam_api_db.get_exam_search / ID_PAT=' || i_patient || '|EXAM_TYPE=' || i_exam_type ||
                    '|ID_CODIFICATION=' || i_codification || '|VALUE=' || substr(i_value, 1, 500);
        g_retval := pk_exams_api_db.get_exam_search(i_lang         => i_lang,
                                                    i_prof         => i_prof,
                                                    i_patient      => i_patient,
                                                    i_exam_type    => i_exam_type,
                                                    i_codification => i_codification,
                                                    i_value        => i_value,
                                                    o_flg_show     => o_flg_show,
                                                    o_msg          => o_msg,
                                                    o_msg_title    => o_msg_title,
                                                    o_list         => o_list,
                                                    o_error        => o_error);
        IF NOT g_retval
        THEN
            g_error := 'ERROR: ' || g_error;
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_alertlog.log_warn(g_error);
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_EXAM_SEARCH',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_exam_search;

    /********************************************************************************************
    * Get institutions for the selected exam
    *
    * @param   I_LANG      language associated to the professional executing the request
    * @param   I_PROF      professional, institution and software ids
    * @value   i_exam_     type Exam type {*} 'I' Image {*} 'E' Other Exams
    * @param   I_EXAM      selected exam
    * @param   O_INST_DEST destination institution
    * @param   O_REF_AREA  flag to reference area
    * @param   O_ERROR     an error message, set when return=false
    *
    * @value   O_REF_AREA  {*} 'Y' in reference area {*} 'N' out of reference area
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author              Joana Barroso
    * @version             2.4.3
    * @since               19/03/2008
    *
    * @modify              Joana Barroso 21/04/2008 New param i_exam_type
    * @modify              Joana Barroso 22/04/2008 Elimination of 
    *                            (eis.flg_type = g_exam_exec OR eis.flg_type = g_exam_freq)
    * @modify              Joana Barroso 08/05/2008 JOIN
    * @modify              Ana Monteiro 12/12/2008 ALERT-11933
    ********************************************************************************************/
    FUNCTION get_exam_institutions
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_exam_type    IN exam.flg_type%TYPE,
        i_exam         IN exam.id_exam%TYPE,
        o_institutions OUT pk_types.cursor_type,
        o_ref_area     OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        --CURSOR c_ref_area IS
        --    SELECT decode(COUNT(1), 0, pk_ref_constant.g_no, pk_ref_constant.g_yes)
        --      FROM p1_dest_institution pdi
        --      --JOIN ref_dest_institution_spec rdis ON (pdi.id_dest_institution = rdis.id_dest_institution AND
        --      --                                            rdis.id_speciality = s.id_speciality AND
        --      --                                            rdis.flg_available = pk_ref_constant.g_yes)
        --     WHERE pdi.id_dest_institution = i_prof.institution
        --       AND pdi.flg_inside_ref_area = pk_ref_constant.g_yes;
    
    BEGIN
    
        g_error := 'Init get_exam_institutions';
        pk_alertlog.log_debug(g_error);
    
        -- cursor o_ref_area is not in use. If this information is needed, we have to configure it for each MCDT 
        -- (ref_dest_institution_spec.id_speciality does not make sense for MCDTs)
    
        --OPEN c_ref_area;
        --FETCH c_ref_area
        --   INTO o_ref_area;
        -- CLOSE c_ref_area;
    
        g_error := 'OPEN o_institutions';
        OPEN o_institutions FOR
            SELECT DISTINCT pdi.id_inst_dest id_institution,
                            ist.abbreviation abbreviation,
                            --t.desc_translation desc_institution
                            pk_translation.get_translation(i_lang, ist.code_institution) desc_institution
              FROM p1_dest_institution pdi
              JOIN exam_dep_clin_serv eis
                ON (pdi.id_inst_dest = eis.id_institution)
              JOIN institution ist
                ON (ist.id_institution = pdi.id_inst_dest)
             WHERE pdi.id_inst_orig = i_prof.institution
                  -- executable exams at dest institution
               AND eis.id_exam = i_exam
               AND eis.flg_execute = pk_ref_constant.g_yes
                  --AND eis.flg_type IN (g_exam_exec, g_exam_freq)
               AND eis.id_software = pk_alert_constant.g_soft_referral
               AND eis.flg_type = pk_exam_constant.g_exam_can_req
               AND pdi.flg_type = i_exam_type
               AND ist.flg_available = pk_ref_constant.g_yes;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_EXAM_INSTITUTIONS',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state();
            pk_types.open_cursor_if_closed(o_institutions);
            RETURN FALSE;
    END get_exam_institutions;

    /********************************************************************************************
    * Get default institutions for the selected exam
    *
    * @param   I_LANG          language associated to the professional executing the request
    * @param   I_PROF          professional, institution and software ids
    * @value   i_exam_type     Exam type {*} 'I' Image {*} 'E' Other Exams
    * @param   I_EXAM          selected exam
    * @param   O_INST_DEST     default destination institution
    * @param   O_REF_AREA      flag to reference area
    * @param   O_ERROR an      error message, set when return=false
    *
    * @value   O_REF_AREA      {*} 'Y' in reference area {*} 'N' out of reference area
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author                  Joana Barroso
    * @version                 2.4.3
    * @since                   19/03/2008
    * @modify                  Joana Barroso 21/04/2008 New param i_exam_type
    * @modify                  Joana Barroso 22/04/2008 Elimination of 
    *                                (dcs.flg_type = g_exam_exec OR dcs.flg_type = g_exam_freq)
    * @modify                  Joana Barroso 08/05/2008 JOIN
    * @modify                  Ana Monteiro 12/12/2008 ALERT-11933
    ********************************************************************************************/
    FUNCTION get_exam_default_insts
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_exam_type    IN exam.flg_type%TYPE,
        i_exam         IN table_number,
        o_institutions OUT pk_types.cursor_type,
        o_ref_area     OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        --CURSOR c_ref_area IS
        --    SELECT decode(COUNT(1), 0, pk_ref_constant.g_no, pk_ref_constant.g_yes)
        --      FROM p1_dest_institution pdi
        --    --JOIN ref_dest_institution_spec rdis ON (pdi.id_dest_institution = rdis.id_dest_institution AND
        --      --                                            rdis.id_speciality = s.id_speciality AND
        --      --                                            rdis.flg_available = pk_ref_constant.g_yes)
        --     WHERE pdi.id_dest_institution = i_prof.institution
        --       AND pdi.flg_inside_ref_area = pk_ref_constant.g_yes;
    
    BEGIN
    
        g_error := 'Init get_exam_default_insts';
        pk_alertlog.log_debug(g_error);
    
        -- cursor o_ref_area is not in use. If this information is needed, we have to configure it for each MCDT 
        -- (ref_dest_institution_spec.id_speciality does not make sense for MCDTs)
    
        --OPEN c_ref_area;
        --FETCH c_ref_area
        --   INTO o_ref_area;
        -- CLOSE c_ref_area;        
    
        g_error := 'OPEN o_institutions';
        OPEN o_institutions FOR
        -- records in p1_exam_default_dest
            SELECT edi.id_exam id_exam,
                   pdi.id_inst_dest id_institution,
                   ist.abbreviation abbreviation,
                   pk_translation.get_translation(i_lang, ist.code_institution) desc_institution
              FROM p1_exam_default_dest edi
              JOIN p1_dest_institution pdi
                ON (edi.id_dest_institution = pdi.id_dest_institution)
              JOIN institution ist
                ON (ist.id_institution = pdi.id_inst_dest)
              JOIN TABLE(CAST(i_exam AS table_number)) tt
                ON (edi.id_exam = tt.column_value)
             WHERE pdi.flg_type = i_exam_type
               AND pdi.id_inst_orig = i_prof.institution
            UNION ALL
            -- records in p1_dest_institution (as default) and not in p1_exam_default_dest
            SELECT dcs.id_exam id_exam,
                   pdi.id_inst_dest id_institution,
                   ist.abbreviation abbreviation,
                   pk_translation.get_translation(i_lang, ist.code_institution) desc_institution
              FROM p1_dest_institution pdi
              JOIN exam_dep_clin_serv dcs
                ON (pdi.id_inst_dest = dcs.id_institution)
              JOIN institution ist
                ON (ist.id_institution = pdi.id_inst_dest)
              JOIN TABLE(CAST(i_exam AS table_number)) tt
                ON (dcs.id_exam = tt.column_value)
             WHERE pdi.id_inst_orig = i_prof.institution
               AND pdi.flg_type = i_exam_type
               AND dcs.flg_execute = pk_ref_constant.g_yes
                  --dcs.flg_type IN (g_exam_exec, g_exam_freq)
               AND dcs.id_software = pk_alert_constant.g_soft_referral
               AND dcs.flg_type = pk_exam_constant.g_exam_can_req
               AND pdi.flg_default = pk_ref_constant.g_yes
               AND tt.column_value NOT IN (SELECT edi.id_exam
                                             FROM p1_exam_default_dest edi
                                             JOIN p1_dest_institution p
                                               ON (edi.id_dest_institution = p.id_dest_institution)
                                            WHERE p.id_inst_orig = i_prof.institution
                                              AND p.flg_type = i_exam_type)
            UNION ALL
            -- records in p1_dest_institution (**not** default) and not in p1_dest_institution (as default) and not in p1_exam_default_dest
            SELECT dcs.id_exam id_exam,
                   pdi.id_inst_dest id_institution,
                   ist.abbreviation abbreviation,
                   pk_translation.get_translation(i_lang, ist.code_institution) desc_institution
              FROM p1_dest_institution pdi
              JOIN exam_dep_clin_serv dcs
                ON (pdi.id_inst_dest = dcs.id_institution)
              JOIN institution ist
                ON (ist.id_institution = pdi.id_inst_dest)
              JOIN TABLE(CAST(i_exam AS table_number)) tt
                ON (dcs.id_exam = tt.column_value)
             WHERE pdi.id_inst_orig = i_prof.institution
               AND pdi.flg_type = i_exam_type
               AND dcs.flg_execute = pk_ref_constant.g_yes
               AND dcs.id_software = pk_alert_constant.g_soft_referral
               AND dcs.flg_type = pk_exam_constant.g_exam_can_req
               AND pdi.flg_default = pk_ref_constant.g_no -- not default
                  -- not in p1_dest_institution (as default)
               AND dcs.id_exam NOT IN (SELECT dcsi.id_exam id_exam
                                         FROM p1_dest_institution pdii
                                         JOIN exam_dep_clin_serv dcsi
                                           ON (pdii.id_inst_dest = dcsi.id_institution)
                                         JOIN TABLE(CAST(i_exam AS table_number)) tt
                                           ON (dcsi.id_exam = tt.column_value)
                                        WHERE pdii.id_inst_orig = i_prof.institution
                                          AND pdii.flg_type = i_exam_type
                                          AND dcsi.flg_execute = pk_ref_constant.g_yes
                                          AND dcsi.id_software = i_prof.software
                                          AND dcsi.flg_type = pk_exam_constant.g_exam_can_req
                                          AND pdii.flg_default = pk_ref_constant.g_yes)
                  -- not in p1_exam_default_dest
               AND tt.column_value NOT IN (SELECT edi.id_exam
                                             FROM p1_exam_default_dest edi
                                             JOIN p1_dest_institution p
                                               ON (edi.id_dest_institution = p.id_dest_institution)
                                            WHERE p.id_inst_orig = i_prof.institution
                                              AND p.flg_type = i_exam_type)
             ORDER BY abbreviation, desc_institution;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_EXAM_DEFAULT_INSTS',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state();
            pk_types.open_cursor_if_closed(o_institutions);
            RETURN FALSE;
    END get_exam_default_insts;

    /********************************************************************************************
    * get common institution based on all required exams
    *
    * @param    i_lang            preferred language id
    * @param    i_prof            object (id of professional, id of institution, id of software)
    * @param    i_exams           array of requested exams
    * ######    i_flg_type        (is not required here because the id_exam itself is enough to 
    * ######                      identify image exams from other exams)
    * @param    o_inst            cursor with institution information
    * @param    o_error           error message structure
    *
    * @return   boolean           false in case of error, otherwise true
    *
    * @author   Carlos Loureiro
    * @version  1.0
    * @since    2009/08/28
    ********************************************************************************************/
    FUNCTION get_exam_inst
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_exams IN table_number,
        o_inst  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id_institution institution.id_institution%TYPE;
    BEGIN
    
        ----------------------
        -- CONFIG
        ----------------------
        g_error          := 'pk_sysconfig.get_config ' || g_ref_external_inst;
        l_id_institution := to_number(pk_sysconfig.get_config(g_ref_external_inst, i_prof));
    
        ----------------------
        -- FUNC
        ----------------------        
        g_error := 'GET CURSOR WITH COMMON INSTITUTIONS';
        OPEN o_inst FOR
            SELECT edcs_dest.id_institution,
                   pk_translation.get_translation(i_lang, inst.code_institution) AS institution_name,
                   inst.abbreviation AS institution_abbreviation
              FROM exam_dep_clin_serv edcs_dest
              JOIN exam e
                ON e.id_exam = edcs_dest.id_exam
              JOIN institution inst
                ON inst.id_institution = edcs_dest.id_institution
             WHERE e.flg_available = pk_ref_constant.g_yes
               AND edcs_dest.flg_execute = pk_ref_constant.g_yes
               AND edcs_dest.id_software = pk_alert_constant.g_soft_referral
               AND edcs_dest.flg_type = pk_exam_constant.g_exam_can_req
               AND edcs_dest.id_exam_dep_clin_serv IN
                   (SELECT reod.id_exam_dcs_dest
                      FROM (SELECT column_value id_exam
                              FROM TABLE(i_exams)) table_id_exams
                      JOIN exam_dep_clin_serv edcs_orig
                        ON edcs_orig.id_exam = table_id_exams.id_exam
                      JOIN ref_exam_orig_dest reod
                        ON reod.id_exam_dcs_orig = edcs_orig.id_exam_dep_clin_serv
                     WHERE reod.flg_available = pk_ref_constant.g_yes
                       AND edcs_orig.flg_type = pk_exam_constant.g_exam_can_req
                       AND edcs_orig.id_institution = i_prof.institution
                       AND edcs_orig.id_software = i_prof.software)
             GROUP BY edcs_dest.id_institution,
                      pk_translation.get_translation(i_lang, inst.code_institution),
                      inst.abbreviation
            HAVING COUNT(edcs_dest.id_exam) >= (SELECT COUNT(*)
                                                  FROM TABLE(i_exams))
            UNION ALL
            SELECT i.id_institution,
                   pk_translation.get_translation(i_lang, i.code_institution) AS institution_name,
                   i.abbreviation AS institution_abbreviation
              FROM institution i
             WHERE i.id_institution = l_id_institution;
    
        RETURN TRUE;
    
    EXCEPTION
        -- unexpected error
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_EXAM_INST',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_inst);
            RETURN FALSE;
        
    END get_exam_inst;

    FUNCTION get_exam_inst
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_exams IN VARCHAR2
    ) RETURN t_tbl_core_domain IS
        l_id_institution institution.id_institution%TYPE;
    
        l_tbl_exams table_number;
    
        l_ret   t_tbl_core_domain;
        l_error t_error_out;
    BEGIN
    
        ----------------------
        -- CONFIG
        ----------------------
        g_error          := 'pk_sysconfig.get_config ' || g_ref_external_inst;
        l_id_institution := to_number(pk_sysconfig.get_config(g_ref_external_inst, i_prof));
    
        l_tbl_exams := pk_utils.str_split_n(i_list => i_exams, i_delim => '|');
        ----------------------
        -- FUNC
        ----------------------        
        g_error := 'OPEN L_RET';
        SELECT *
          BULK COLLECT
          INTO l_ret
          FROM (SELECT t_row_core_domain(internal_name => NULL,
                                         desc_domain   => institution_name,
                                         domain_value  => id_institution,
                                         order_rank    => NULL,
                                         img_name      => NULL)
                  FROM (SELECT edcs_dest.id_institution,
                               pk_translation.get_translation(i_lang, inst.code_institution) AS institution_name
                          FROM exam_dep_clin_serv edcs_dest
                          JOIN exam e
                            ON e.id_exam = edcs_dest.id_exam
                          JOIN institution inst
                            ON inst.id_institution = edcs_dest.id_institution
                         WHERE e.flg_available = pk_ref_constant.g_yes
                           AND edcs_dest.flg_execute = pk_ref_constant.g_yes
                           AND edcs_dest.id_software = pk_alert_constant.g_soft_referral
                           AND edcs_dest.flg_type = pk_exam_constant.g_exam_can_req
                           AND edcs_dest.id_exam_dep_clin_serv IN
                               (SELECT reod.id_exam_dcs_dest
                                  FROM (SELECT column_value id_exam /*+opt_estimate(table t rows=1)*/
                                          FROM TABLE(l_tbl_exams) t) table_id_exams
                                  JOIN exam_dep_clin_serv edcs_orig
                                    ON edcs_orig.id_exam = table_id_exams.id_exam
                                  JOIN ref_exam_orig_dest reod
                                    ON reod.id_exam_dcs_orig = edcs_orig.id_exam_dep_clin_serv
                                 WHERE reod.flg_available = pk_ref_constant.g_yes
                                   AND edcs_orig.flg_type = pk_exam_constant.g_exam_can_req
                                   AND edcs_orig.id_institution = i_prof.institution
                                   AND edcs_orig.id_software = i_prof.software)
                         GROUP BY edcs_dest.id_institution,
                                  pk_translation.get_translation(i_lang, inst.code_institution),
                                  inst.abbreviation
                        HAVING COUNT(edcs_dest.id_exam) >= (SELECT COUNT(*)
                                                             FROM TABLE(l_tbl_exams))
                        UNION ALL
                        SELECT i.id_institution,
                               pk_translation.get_translation(i_lang, i.code_institution) AS institution_name
                          FROM institution i
                         WHERE i.id_institution = l_id_institution));
    
        RETURN l_ret;
    
    EXCEPTION
        -- unexpected error
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_EXAM_INST',
                                              o_error    => l_error);
            RETURN t_tbl_core_domain();
        
    END get_exam_inst;

BEGIN
    -- Log initialization.    
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);
END;
/
