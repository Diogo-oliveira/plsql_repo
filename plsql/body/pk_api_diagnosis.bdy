/*-- Last Change Revision: $Rev: 1850754 $*/
/*-- Last Change by: $Author: ana.matos $*/
/*-- Date of last change: $Date: 2018-07-05 15:20:59 +0100 (qui, 05 jul 2018) $*/

CREATE OR REPLACE PACKAGE BODY pk_api_diagnosis IS
    e_call_exception EXCEPTION;
    /** @headcom
    * Public Function. Obter o descritivo dos diagnósticos associados a uma requisição.
    * Não é chamada pelo Flash.
    *
    * @param      I_LANG               Língua registada como preferência do profissional
    * @param      I_EXAM_REQ     ID da requisição de exames.
    * @param      I_ANALYSIS_REQ   ID da requisição de análises.
    * @param      I_INTERV_PRESC   ID da requisição de procedimentos.
    * @param      I_DRUG_PRESC     ID da requisição de medicamentos.
    * @param      I_DRUG_REQ     ID da requisição de medicamentos à farmácia.
    * @param      I_PRESCRIPTION   ID da prescrição de medicamentos para o exterior.
    * @param      I_PRESCRIPTION_USA   ID da prescrição de medicamentos para o exterior (versão USA).
    * @param      I_PROF         object (ID do profissional, ID da instituição, ID do software)
    *
    * @return     boolean
    * @author     SS
    * @version    0.1
    * @since      2007/02/06
    */

    FUNCTION intf_concat_diag
    (
        i_lang             IN language.id_language%TYPE,
        i_exam_req_det     IN exam_req_det.id_exam_req_det%TYPE,
        i_analysis_req_det IN analysis_req_det.id_analysis_req_det%TYPE,
        i_interv_presc_det IN interv_presc_det.id_interv_presc_det%TYPE,
        i_drug_presc       IN NUMBER, -- filed not used in pk_diagnosis.concat_diag
        i_drug_req         IN NUMBER, -- filed not used in pk_diagnosis.concat_diag
        i_prescription     IN NUMBER, -- filed not used in pk_diagnosis.concat_diag
        i_prescription_usa IN NUMBER, -- filed not used in pk_diagnosis.concat_diag
        i_prof             IN profissional
    ) RETURN VARCHAR2 IS
    
    BEGIN
        RETURN pk_diagnosis.concat_diag(i_lang             => i_lang,
                                        i_exam_req_det     => i_exam_req_det,
                                        i_analysis_req_det => i_analysis_req_det,
                                        i_interv_presc_det => i_interv_presc_det,
                                        i_prof             => i_prof);
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_err_num NUMBER;
            BEGIN
                pk_alert_exceptions.register_error(SQLCODE, l_err_num, SQLERRM);
                RETURN NULL;
            END;
    END;

    /********************************************************************************************
    * Returns the diagnosis associated with a request.
    *
    * @param i_lang              Língua registada como preferência do profissional
    * @param i_exam_req_det      ID da requisição de exames.
    * @param i_analysis_req_det  ID da requisição de análises.
    * @param i_interv_presc_det  ID da requisição de procedimentos.
    * @param i_drug_presc        ID da requisição de medicamentos.
    * @param i_drug_req          ID da requisição de medicamentos à farmácia.
    * @param i_prescription      ID da prescrição de medicamentos para o exterior.
    * @param o_id_diagnosis      Lista dos identificadores do diagnosis
    * @param o_desc_diagnosis    Lista da descricao dos diagnostico
    * @param o_error             Error message    
    *
    * @return                    True if everything was ok. False otherwise.
    * 
    * @author                    Rui Salgado
    * @version                   1.0
    * @since                     2007/06/21
    ********************************************************************************************/
    FUNCTION get_mcdts_diagnosis_intf
    (
        i_lang             IN language.id_language%TYPE,
        i_exam_req_det     IN exam_req_det.id_exam_req_det%TYPE,
        i_analysis_req_det IN analysis_req_det.id_analysis_req_det%TYPE,
        i_interv_presc_det IN interv_presc_det.id_interv_presc_det%TYPE,
        i_drug_presc       IN NUMBER, -- field not used
        i_drug_req         IN NUMBER, -- field not used
        i_prescription     IN NUMBER, -- field not used
        i_prof             IN profissional,
        o_diagnosis        OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'Open o_diagnosis';
        OPEN o_diagnosis FOR
            SELECT d.code_icd,
                   mrd.flg_status,
                   pk_date_utils.date_send_tsz(i_lang, ed.dt_epis_diagnosis_tstz, i_prof) dt_epis_diagnosis,
                   pk_diagnosis.std_diag_desc(i_lang                => i_lang,
                                              i_prof                => i_prof,
                                              i_id_alert_diagnosis  => ed.id_alert_diagnosis,
                                              i_desc_epis_diagnosis => ed.desc_epis_diagnosis,
                                              i_code                => d.code_icd,
                                              i_flg_other           => d.flg_other,
                                              i_flg_std_diag        => pk_alert_constant.g_yes) desc_diag
              FROM mcdt_req_diagnosis mrd, epis_diagnosis ed, diagnosis d
             WHERE (mrd.id_exam_req_det = i_exam_req_det OR mrd.id_analysis_req_det = i_analysis_req_det OR
                   mrd.id_interv_presc_det = i_interv_presc_det)
               AND nvl(mrd.flg_status, 'z') != 'C'
               AND mrd.id_diagnosis = d.id_diagnosis(+)
               AND mrd.id_epis_diagnosis = ed.id_epis_diagnosis;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_API_DIAGNOSIS',
                                              'GET_MCDTS_DIAGNOSIS_INTF',
                                              o_error);
            pk_types.open_my_cursor(o_diagnosis);
            RETURN FALSE;
    END;
    --

    /**********************************************************************************************
    * Registar os diagnósticos diferenciais(provisórios) ou finais de um episódio
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids             
    * @param i_prof_cat_type          category of professional
    * @param i_epis                   episode id
    * @param i_id_diag                diagnosis id
    * @param i_diag_status            Array com estados dos diagnósticos
    * @param i_spec_notes             Array com as notas especificas de cada diagnóstico
    * @param i_flg_type               Tipo de registo: P - Provisório; D - Definitivo
    * @param i_desc_diagnosis         descrição do diagnóstico quando é seleccionado a opção OUTRO
    * @param i_flg_final_type         Tipo de diagnóstico de saída: primário ou secondário
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Emilia Taborda
    * @version                        1.0 
    * @since                          2006/10/05
    **********************************************************************************************/
    FUNCTION intf_create_diag
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_prof_cat_type  IN category.flg_type%TYPE,
        i_epis           IN episode.id_episode%TYPE,
        i_id_diag        IN table_number,
        i_diag_status    IN table_varchar,
        i_spec_notes     IN table_varchar,
        i_flg_type       IN table_varchar,
        i_desc_diagnosis IN table_varchar,
        i_id_alert_diag  IN table_number,
        i_flg_final_type IN table_varchar,
        i_epis_diag_date IN table_varchar,
        o_epis_diagnosis OUT table_number,
        o_epis_diag_hist OUT table_number,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_rec_epis_diagnoses pk_edis_types.rec_in_epis_diagnoses;
        l_rec_epis_diag      pk_edis_types.rec_in_epis_diagnosis;
        l_created_diag       pk_edis_types.table_out_epis_diags;
    
    BEGIN
        l_rec_epis_diag := pk_diagnosis_core.get_diag_rec(i_lang            => i_lang,
                                                          i_prof            => i_prof,
                                                          i_patient         => NULL,
                                                          i_episode         => i_epis,
                                                          i_diagnosis       => i_id_diag,
                                                          i_alert_diagnosis => i_id_alert_diag,
                                                          i_desc_diag       => i_desc_diagnosis,
                                                          i_flg_status      => i_diag_status,
                                                          i_spec_notes      => i_spec_notes,
                                                          i_dt_diag         => i_epis_diag_date);
    
        l_rec_epis_diag.prof_cat_type := i_prof_cat_type;
    
        l_rec_epis_diagnoses.epis_diagnosis := l_rec_epis_diag;
    
        IF NOT pk_diagnosis.set_epis_diagnosis(i_lang           => i_lang,
                                               i_prof           => i_prof,
                                               i_epis_diagnoses => l_rec_epis_diagnoses,
                                               o_params         => l_created_diag,
                                               o_error          => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        o_epis_diagnosis := table_number();
        o_epis_diag_hist := table_number();
    
        FOR i IN l_created_diag.first .. l_created_diag.last
        LOOP
            o_epis_diagnosis.extend;
            o_epis_diagnosis(i) := l_created_diag(i).id_epis_diagnosis;
        END LOOP;
    
        FOR i IN l_created_diag.first .. l_created_diag.last
        LOOP
            o_epis_diag_hist.extend;
            o_epis_diag_hist(i) := l_created_diag(i).id_epis_diagnosis_hist;
        END LOOP;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_API_DIAGNOSIS',
                                              'INTF_CREATE_DIAG_NO_COMMIT',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END intf_create_diag;

    /**********************************************************************************************
    * API used by the referral to register a diagnosis
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids             
    * @param i_prof_cat_type          category of professional
    * @param i_epis                   episode id
    * @param i_id_diag                diagnosis id
    * @param i_diag_status            Diagnosis status array
    * @param i_spec_notes             Specific notes array for each diagnosis
    * @param i_desc_diagnosis         Diagnosis description when registered in free text
    * @param i_notes                  General notes associated to all the diagnosis
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         José Silva
    * @version                        2.6.1.2
    * @since                          2011/09/20
    **********************************************************************************************/
    FUNCTION ref_create_diag_no_commit
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_prof_cat_type  IN category.flg_type%TYPE,
        i_epis           IN episode.id_episode%TYPE,
        i_id_diag        IN table_number,
        i_diag_status    IN table_varchar,
        i_spec_notes     IN table_varchar,
        i_desc_diagnosis IN table_varchar,
        i_notes          IN epis_diagnosis_notes.notes%TYPE,
        i_id_alert_diag  IN table_number,
        i_sysdate        IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        o_epis_diagnosis OUT table_number,
        o_epis_diag_hist OUT table_number,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_rec_epis_diagnoses pk_edis_types.rec_in_epis_diagnoses;
        l_rec_epis_diag      pk_edis_types.rec_in_epis_diagnosis;
        l_created_diag       pk_edis_types.table_out_epis_diags;
    BEGIN
        l_rec_epis_diag := pk_diagnosis_core.get_diag_rec(i_lang            => i_lang,
                                                          i_prof            => i_prof,
                                                          i_patient         => NULL,
                                                          i_episode         => i_epis,
                                                          i_diagnosis       => i_id_diag,
                                                          i_alert_diagnosis => i_id_alert_diag,
                                                          i_desc_diag       => i_desc_diagnosis,
                                                          i_flg_status      => i_diag_status,
                                                          i_spec_notes      => i_spec_notes);
    
        l_rec_epis_diag.prof_cat_type := i_prof_cat_type;
        l_rec_epis_diag.dt_record     := i_sysdate;
    
        l_rec_epis_diagnoses.epis_diagnosis := l_rec_epis_diag;
        IF NOT pk_diagnosis.set_epis_diagnosis(i_lang           => i_lang,
                                               i_prof           => i_prof,
                                               i_epis_diagnoses => l_rec_epis_diagnoses,
                                               o_params         => l_created_diag,
                                               o_error          => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        o_epis_diagnosis := table_number();
        o_epis_diag_hist := table_number();
    
        FOR i IN l_created_diag.first .. l_created_diag.last
        LOOP
            o_epis_diagnosis.extend;
            o_epis_diagnosis(i) := l_created_diag(i).id_epis_diagnosis;
        END LOOP;
    
        FOR i IN l_created_diag.first .. l_created_diag.last
        LOOP
            o_epis_diag_hist.extend;
            o_epis_diag_hist(i) := l_created_diag(i).id_epis_diagnosis_hist;
        END LOOP;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_API_DIAGNOSIS',
                                              'REF_CREATE_DIAG_NO_COMMIT',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END ref_create_diag_no_commit;

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
    * @author                         José Silva
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
    
        IF NOT pk_diagnosis_core.get_epis_diag(i_lang           => i_lang,
                                               i_prof           => i_prof,
                                               i_id_episode     => table_number(i_episode),
                                               i_show_cancelled => pk_alert_constant.g_yes,
                                               o_diag           => o_diag,
                                               o_error          => o_error)
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
                                              'PK_API_DIAGNOSIS',
                                              'GET_EPIS_DIAG',
                                              o_error);
            pk_types.open_my_cursor(o_diag);
            RETURN FALSE;
    END get_epis_diag;

    /********************************************************************************************
    * Function that returns diagnosis based on an record of Episode diagnosis records
    *
    * @param i_lang                   language ID
    * @param i_prof                   Object (professional, Institution and Software)
    * @param i_epis_diag              Array of episode diagnosis ID
    * @param i_epis_diag_hist         Show cancelled/rulled out records: (Y)es or (N)o
    *
    * @return                         Diagnosis list (pipelined)
    *
    * @author                         José Silva
    * @version                        2.6.1.2  
    * @since                          2011/09/20
    **********************************************************************************************/
    FUNCTION get_ref_epis_diag
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_epis_diag      IN table_number,
        i_epis_diag_hist IN table_number
    ) RETURN t_coll_epis_diagnosis
        PIPELINED IS
    
        l_rec_out       t_rec_epis_diagnosis;
        l_epis_diag     pk_edis_types.p_epis_diagnosis_cur;
        l_rec_epis_diag pk_edis_types.p_epis_diagnosis_rec;
        l_error         t_error_out;
    
    BEGIN
    
        g_error := 'GET o_epis_diag';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_diagnosis_core.get_epis_diag_list(i_lang           => i_lang,
                                                    i_prof           => i_prof,
                                                    i_epis_diag      => i_epis_diag,
                                                    i_epis_diag_hist => i_epis_diag_hist,
                                                    o_epis_diag      => l_epis_diag,
                                                    o_error          => l_error)
        THEN
            RETURN;
        END IF;
    
        g_error := 'GET DIAGNOSIS';
        pk_alertlog.log_debug(g_error);
        LOOP
        
            FETCH l_epis_diag
                INTO l_rec_epis_diag;
        
            EXIT WHEN l_epis_diag%NOTFOUND;
        
            l_rec_out := t_rec_epis_diagnosis(l_rec_epis_diag.id_epis_diagnosis,
                                              l_rec_epis_diag.id_epis_diagnosis_hist,
                                              l_rec_epis_diag.id_diagnosis,
                                              l_rec_epis_diag.diag_desc,
                                              l_rec_epis_diag.flg_type,
                                              l_rec_epis_diag.type_desc,
                                              l_rec_epis_diag.flg_status,
                                              l_rec_epis_diag.status_desc,
                                              l_rec_epis_diag.problem_status,
                                              l_rec_epis_diag.notes,
                                              l_rec_epis_diag.general_notes,
                                              l_rec_epis_diag.notes_cancel,
                                              l_rec_epis_diag.flg_has_recent_data);
        
            PIPE ROW(l_rec_out);
        
        END LOOP;
    
        RETURN;
    
    END get_ref_epis_diag;

    /**********************************************************************************************
    * Get the most recent note registered in the episode 
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids             
    * @param i_episode                episode ID
    * @param i_epis_diag              episode diagnosis ID
    * @param i_epis_diag_hist         episode diagnosis ID (history record)
    *
    * @return                         diagnosis note
    *                        
    * @author                         José Silva
    * @version                        2.6.2
    * @since                          29-02-2012
    **********************************************************************************************/
    FUNCTION get_epis_diag_note
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        i_epis_diag      IN epis_diagnosis.id_epis_diagnosis%TYPE,
        i_epis_diag_hist IN epis_diagnosis_hist.id_epis_diagnosis_hist%TYPE
    ) RETURN epis_diagnosis.notes%TYPE IS
    
    BEGIN
    
        RETURN pk_diagnosis_core.get_epis_diag_note(i_lang           => i_lang,
                                                    i_prof           => i_prof,
                                                    i_episode        => i_episode,
                                                    i_epis_diag      => i_epis_diag,
                                                    i_epis_diag_hist => i_epis_diag_hist);
    END get_epis_diag_note;

    /**
    * Get the concept version ids associated with a concept
    *
    * @param   i_concept          Concept ID
    *
    * @return  Concept version IDs
    *
    * @author  José Silva
    * @version v2.6.2
    * @since   04/Jun/2012
    */
    FUNCTION get_id_concept_version(i_concept IN diagnosis.id_concept%TYPE) RETURN table_number IS
    BEGIN
        RETURN pk_api_pfh_diagnosis_in.get_id_concept_version(i_concept => i_concept);
    END get_id_concept_version;

    /**
    * Get the concept id associated with a concept version
    *
    * @param   i_concept_version          Concept version ID
    *
    * @return  Concept ID
    *
    * @author  José Silva
    * @version v2.6.2
    * @since   04/Jun/2012
    */
    FUNCTION get_id_concept(i_concept_version IN diagnosis.id_diagnosis%TYPE) RETURN diagnosis.id_concept%TYPE IS
        l_ret concept.id_concept%TYPE;
    
    BEGIN
        RETURN pk_api_pfh_diagnosis_in.get_id_concept(i_concept_version => i_concept_version);
    END get_id_concept;

    /**
    * This procedure performs error handling and is used internally by other functions in this package,
    * especially by those that are used inside SELECT statements.
    * Private procedure.
    *
    * @param i_func_proc_name      Function or procedure name.
    * @param i_error               Error message to log.
    * @param i_sqlerror            SQLERRM
    *
    * @author   Nuno Guerreiro
    * @version  alpha
    * @since    2007/04/23
    */
    PROCEDURE error_handling
    (
        i_func_proc_name IN VARCHAR2,
        i_error          IN VARCHAR2,
        i_sqlerror       IN VARCHAR2
    ) IS
    BEGIN
        pk_alertlog.log_error(i_func_proc_name || ': ' || i_error || ' -- ' || i_sqlerror, g_package_name);
    END error_handling;

    /**
    * This function performs error handling and is used internally by other functions in this package.
    * Private function.
    *
    * @param i_lang                Language identifier.
    * @param i_func_proc_name      Function or procedure name.
    * @param i_error               Error message to log.
    * @param i_sqlerror            SQLERRM.
    * @param o_error               Message to be shown to the user.
    *
    * @return  FALSE (in any case, in order to allow a RETURN error_handling statement in exception
    * handling blocks).
    *
    * @author   Nuno Guerreiro
    * @version  alpha
    * @since    2007/04/23
    */
    FUNCTION error_handling
    (
        i_lang           IN language.id_language%TYPE,
        i_func_proc_name IN VARCHAR2,
        i_error          IN VARCHAR2,
        i_sqlerror       IN VARCHAR2,
        o_error          OUT VARCHAR2
    ) RETURN BOOLEAN IS
    BEGIN
        o_error := pk_message.get_message(i_lang => i_lang, i_code_mess => g_msg_common_m001) || chr(10) ||
                   g_package_name || '.' || i_func_proc_name;
        pk_alertlog.log_error(i_func_proc_name || ': ' || i_error || ' -- ' || i_sqlerror, g_package_name);
        RETURN FALSE;
    END error_handling;

BEGIN
    -- Log initialization.
    g_package_name := pk_alertlog.who_am_i;
    pk_alertlog.log_init(g_package_name);

END pk_api_diagnosis;
/
