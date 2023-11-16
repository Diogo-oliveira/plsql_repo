/*-- Last Change Revision: $Rev: 2055614 $*/
/*-- Last Change by: $Author: pedro.henriques $*/
/*-- Date of last change: $Date: 2023-02-22 15:26:38 +0000 (qua, 22 fev 2023) $*/

CREATE OR REPLACE PACKAGE pk_mcdt IS

    -- Author  : JOAO.RIBEIRO
    -- Created : 22-12-2008 09:13:28
    -- Purpose : Gather common functions for the severall MCDT areas

    /*
    * Returns a list of tests for a patient within a visit
    *
    * @param     i_lang           Language id
    * @param     i_prof           Professional
    * @param     i_episode        Episode id
    * @param     i_start_record   Pagination start record
    * @param     i_num_records    Pagination number of records
    * @param     o_list           Cursor
    * @param     o_error          Error message
    
    * @return    true or false on success or error
    *
    * @author    Ana Matos
    * @version   2.5
    * @since     2009/10/21
    */

    FUNCTION get_mcdt_summary
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_start_record IN NUMBER DEFAULT NULL,
        i_num_records  IN NUMBER DEFAULT NULL,
        o_list         OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns the total count of tests for a patient within a visit
    *
    * @param     i_lang           Language id
    * @param     i_prof           Professional
    * @param     i_episode        Episode id
    * @param     o_list_count     Cursor
    * @param     o_error          Error message
    
    * @return    true or false on success or error
    *
    * @author    Ana Matos
    * @version   2.5
    * @since     2012/05/21
    */

    FUNCTION get_mcdt_summary_count
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_episode    IN episode.id_episode%TYPE,
        o_list_count OUT NUMBER,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_ordered_list
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_patient  IN patient.id_patient%TYPE,
        i_viewer_area IN VARCHAR2,
        i_episode     IN episode.id_episode%TYPE,
        o_list        OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Return the codification id and translation the codification if exists
    *
    * @param   i_lang           language
    * @param   i_prof           professional
    * @param   o_list           output cursor
    * @param   o_error          error message
    *
    *
    * @author  José Castro
    * @version 1.0
    * @since   2009/09/01
    */

    FUNCTION get_codification_list
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_mcdt_type IN p1_external_request.flg_type%TYPE,
        i_flg_type  IN VARCHAR2,
        i_flg_p1    IN VARCHAR2 DEFAULT 'N',
        o_list      OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /**************************************************************************
    * check dependent task cancel permission (checks if i_prof can cancel     *
    * this task in profile_templ_access data model)                           *
    *                                                                         *
    *@param  i_lang                    preferred language id                  *
    *@param  i_prof                    Professional struture                  *
    *@param  i_id_sys_button_prop      id_sys_button_prop                     *
    *                                                                         *  
    * @author                          Gustavo Serrano                        *
    * @version                         v2.6.0.3                               *   
    * @since                           2010/05/13                             *    
    **************************************************************************/

    FUNCTION check_prof_cancel_permissions
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_sys_button IN table_number
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Gets the selected code dep_clin_serv of a given professional when he made a record
    *
    * @param   I_PROF professional, institution and software ids        
    * @param   I_DT_REG                   record date
    * @param   I_EPISODE                  episode ID        
    *
    * @RETURN  professional dep_clin_serv (CODE)
    * @author  Teresa Coutinho
    * @version 1.0
    * @since   06/03/2012
    *
    **********************************************************************************************/
    FUNCTION get_reg_prof_dcs
    (
        i_prof_id IN professional.id_professional%TYPE,
        i_dt_reg  IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_mcdt_laterality
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_flg_type IN VARCHAR2,
        i_task     IN VARCHAR2,
        o_list     OUT VARCHAR2,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION check_mcdt_laterality
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_flg_type IN VARCHAR2,
        i_task     IN VARCHAR2
    ) RETURN VARCHAR2;

    FUNCTION get_laterality
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_flg_laterality IN VARCHAR2,
        o_list           OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_laterality
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_flg_laterality_mcdt IN table_varchar,
        o_list                OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_laterality_all
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_flg_laterality_mcdt IN table_varchar,
        i_flg_type            IN VARCHAR2,
        o_list                OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_laterality_all
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_flg_type  IN VARCHAR2,
        i_mcdt_type IN p1_external_request.flg_type%TYPE,
        i_mcdt      IN VARCHAR2
    ) RETURN t_tbl_core_domain;

    FUNCTION get_laterality_all
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_flg_laterality_mcdt IN table_varchar,
        i_flg_type            IN VARCHAR2
    ) RETURN t_tbl_core_domain;

    /**
    * Returns a message if the field "Laterality" is not set for those MCDTs that has laterality mandatory
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Professional, institution and software ids
    * @param   i_mcdt_type      Referral of MCDTs type
    * @param   i_mcdt           MCDTs identifiers
    * @param   o_flg_show       Flag indicating if the message is to be shown
    * @param   o_msg_title      Message title
    * @param   o_msg            Message text
    * @param   o_button         Type of button to show with message
    * @param   o_error          An error message, set when return=false
    *
    * @value   i_mcdt_type      {*} (A)nalysis {*} (I)mage {*} (E)xam {*} (P)rocedure {*} (M)fr
    * @value   o_flg_show       {*} 'Y' Message is to be shown {*} 'N' otherwise
    *    
    * @return    TRUE if sucess, FALSE otherwise
    *
    * @author    Ana Monteiro
    * @version   2.5
    * @since     30-08-2011
    */
    FUNCTION check_mandatory_lat
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_mcdt_type IN p1_external_request.flg_type%TYPE,
        i_mcdt      IN table_number,
        o_flg_show  OUT VARCHAR2,
        o_msg       OUT VARCHAR2,
        o_msg_title OUT VARCHAR2,
        o_button    OUT VARCHAR2,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Diagnosis / MCDTS
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids             
    * @param i_epis                   episode id
    * @param i_mcdt                   mcdt id 
    * @param i_flg_type               I - Interventions, A - Analysis, E - Exams, O - Other Exams                     
    * @param o_diagnosis              array with diagnosis
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Teresa Coutinho
    * @version                        1.0 
    * @since                          2012/02/15
    **********************************************************************************************/
    FUNCTION get_mcdt_diag_list
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_epis      IN episode.id_episode%TYPE,
        i_mcdt      IN table_number,
        i_flg_type  IN mcdt_diagnosis.flg_type%TYPE,
        o_diagnosis OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_questionnaire_response
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_questionnaire IN questionnaire_response.id_questionnaire%TYPE
    ) RETURN table_varchar;

    FUNCTION get_questionnaire_alias
    (
        i_lang               IN NUMBER,
        i_prof               IN profissional DEFAULT profissional(NULL, NULL, NULL),
        i_code_questionnaire IN questionnaire.code_questionnaire%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_response_alias
    (
        i_lang          IN NUMBER,
        i_prof          IN profissional DEFAULT profissional(NULL, NULL, NULL),
        i_code_response IN response.code_response%TYPE
    ) RETURN VARCHAR2;
    /**************************************************************************
    * Returns the responses for a specific Lab test (by sample_type) or an Exam by flg_time/id_questionnaire
    *
    * @param i_lang                       Id Language
    * @param i_prof                       Professional
    * @param i_patient                    Patient  Id
    * @param i_questionnaire              Questionnaire Id    
    * @param i_mcdt                       Mcdt  Id
    * @param i_sample_type                Sample Type  Id       
    * @param i_flg_time                   Flg_time ('O','BE','AE')
    * @param i_flg_type                   Flg Type  ('A','E')     
    *
    * @author  Teresa Coutinho
    * @version 2.6.3.11
    * @since   2014/02/27
    **************************************************************************/

    FUNCTION get_questionnaire_response
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_questionnaire IN questionnaire_response.id_questionnaire%TYPE,
        i_mcdt          IN NUMBER,
        i_sample_type   IN sample_type.id_sample_type%TYPE,
        i_flg_time      IN VARCHAR2,
        i_flg_type      IN VARCHAR2
    ) RETURN table_varchar;

    FUNCTION get_questionnaire_response
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_questionnaire IN questionnaire_response.id_questionnaire%TYPE,
        i_mcdt          IN NUMBER,
        i_sample_type   IN sample_type.id_sample_type%TYPE,
        i_flg_time      IN VARCHAR2,
        i_flg_type      IN VARCHAR2,
        i_inst_dest     IN institution.id_institution%TYPE
    ) RETURN table_varchar;

    /**************************************************************************
    * Initializes parameters for filter MCDT_Diagnoses
    *
    * @param i_context_ids            array with context ids
    * @param i_context_vals           array with context values
    * @param i_name                   parammeter name 
    * 
    * @param o_vc2                    varchar2 value
    * @param o_num                    number value
    * @param o_id                     number value
    * @param o_tstz                   timestamp value
    *
    * @author                         Sergio Dias
    * @version                        2.6.4.2.1
    * @since                          Oct-8-2014
    **************************************************************************/
    PROCEDURE init_params_mcdt_diagnosis
    (
        i_filter_name   IN VARCHAR2,
        i_custom_filter IN NUMBER,
        i_context_ids   IN table_number,
        i_context_vals  IN table_varchar,
        i_context_keys  IN table_varchar,
        i_name          IN VARCHAR2,
        o_vc2           OUT VARCHAR2,
        o_num           OUT NUMBER,
        o_id            OUT NUMBER,
        o_tstz          OUT TIMESTAMP WITH LOCAL TIME ZONE
    );

    /**************************************************************************************************************
    * Table function to return filter content
    *
    * @return                           Returns the diagnosis configured for a set of MCDT
    *                        
    * @author                           Sergio Dias
    * @version                          2.6.4.2.1
    * @since                            Oct-8-2014
    **************************************************************************************************************/
    FUNCTION tf_mcdt_diag_list RETURN t_coll_diagnosis_config;

    /** @headcom
    * Public Function. Cancelar associações de diagnósticos a MCDTs e de Medicação a Problemas
    *
    * @param    i_lang              Língua registada como preferência do profissional
    * @param    i_flg_type          Distingue o tipo de associação: 'M' para MCDTs, 'P' para prescrição
    * @param    i_ids               Array com um conjunto de associações a eliminar. 
    *                                Qd i_flg_type='M' então os Ids referen-se a MCDT_REQ_DET. 
    *                               Qd i_flg_type='P' então os Ids referen-se a PRESC_PAT_PROBLEM.
    * @param      I_PROF            Object (ID do profissional, ID da instituição, ID do software)
    * @param      I_PROF_CAT_TYPE   Categoria do profissional (flag)
    * @param      i_test            'Y' indica que é para pedir mensagem de confirmação. 'N' indica que para realizar ro pedido.
    * @param      O_FLG_SHOW         flag: Y - existe msg para mostrar; N - ñ existe  
    * @param      O_MSG              mensagem a mostrar
    * @param      O_MSG_TITLE        título da mensagem
    * @param      O_BUTTON           botões a mostrar: N - não, R - lido, C - confirmado 
    * @param      O_ERROR            erro
    *
    * @return     boolean
    * @author     Luís Gaspar
    * @version    0.1
    * @since      2007/08/10
    */

    FUNCTION cancel_associated_problem
    (
        i_lang          IN language.id_language%TYPE,
        i_flg_type      IN table_varchar,
        i_ids           IN table_number,
        i_prof          IN profissional,
        i_prof_cat_type IN category.flg_type%TYPE,
        i_test          IN VARCHAR2,
        o_flg_show      OUT VARCHAR2,
        o_msg           OUT VARCHAR2,
        o_msg_title     OUT VARCHAR2,
        o_button        OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_full_items_by_screen
    (
        i_lang        IN NUMBER,
        i_prof        IN profissional,
        i_patient     IN NUMBER,
        i_episode     IN NUMBER,
        i_screen_name IN VARCHAR2,
        i_action      IN NUMBER,
        o_components  OUT pk_types.cursor_type,
        o_ds_target   OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_multichoice_options
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN NUMBER,
        i_episode IN NUMBER,
        i_field   IN VARCHAR2
    ) RETURN t_tbl_core_domain;

    FUNCTION get_request_values
    (
        i_lang           IN NUMBER,
        i_prof           IN profissional,
        i_episode        IN NUMBER,
        i_patient        IN NUMBER,
        i_action         IN NUMBER, -- edit, new, submit
        i_root_name      IN VARCHAR2, -- root of dynamic screen
        i_curr_component IN NUMBER,
        i_tbl_int_name   IN table_varchar,
        i_tbl_id_pk      IN table_number, -- id necessary for identifying pk for editing
        i_tbl_mkt_rel    IN table_number, -- components needed for default/edit
        i_value          IN table_table_varchar,
        o_error          OUT t_error_out
    ) RETURN t_tbl_ds_get_value;

    FUNCTION get_docs_by_request
    (
        i_lang     IN NUMBER,
        i_prof     IN profissional,
        i_episode  IN NUMBER,
        i_flg_area IN VARCHAR2,
        i_request  IN NUMBER, -- edit, new, submit
        o_docs     OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    g_package_owner VARCHAR2(50);
    g_package_name  VARCHAR2(50);

    g_user_exception  EXCEPTION;
    g_other_exception EXCEPTION;
    g_error      VARCHAR2(4000);
    g_error_code VARCHAR2(100);

    g_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;
    g_sysdate_char VARCHAR2(50);
    g_found        BOOLEAN;

    g_retval BOOLEAN;

    g_lab_tests         VARCHAR2(2) := 'LT';
    g_exams             VARCHAR2(1) := 'E';
    g_patient_education VARCHAR2(2) := 'PE';
    g_other_procedures  VARCHAR2(2) := 'OP';

    -- MCDT's Origin req module (analysis_req_det.flg_req_origin_module and exam_req.flg_req_origin_module)
    g_mcdt_orig_req_intf       CONSTANT VARCHAR2(1) := 'I';
    g_mcdt_orig_req_order_sets CONSTANT VARCHAR2(1) := 'O';
    g_mcdt_orig_req_default    CONSTANT VARCHAR2(1) := 'D';

    g_mcdt_lat_any CONSTANT VARCHAR2(1) := 'A'; -- Any laterality
    g_mcdt_lat_all CONSTANT VARCHAR2(1) := 'O'; -- All Options
    g_mcdt_lat_na  CONSTANT VARCHAR2(1) := 'N'; -- Not aplicable

    g_mcdt_flg_type CONSTANT VARCHAR2(30 CHAR) := 'PK_MCDT.FLG_TYPE';
    g_mcdt_ids      CONSTANT VARCHAR2(30 CHAR) := 'PK_MCDT.IDS';
END pk_mcdt;
/
