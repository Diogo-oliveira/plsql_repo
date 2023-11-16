/*-- Last Change Revision: $Rev: 2028931 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:48:49 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_reports_medication_api IS

    -- Author  : PEDRO.MORAIS
    -- Created : 27-05-2010 16:10:00
    -- Purpose : Package with functions called by Reports

    -- Public variable declarations
    g_error VARCHAR2(4000);

    -- Public function and procedure declarations
    /********************************************************************************************
    * Get prescription details
    * This function calls pk_medication_current.get_drug_details but ignores the unused cursors 
    * in order to optimize the response time.
    *
    * @param i_lang                     Language
    * @param i_prof                     Professional
    * @param i_id_patient               Patient
    * @param i_subject                  Prescription type
    * @param i_id_presc                 Prescription ID
    *
    * @param o_drug_detail              
    * @param o_drug_detail_hist         
    * @param o_drug_hold_detail         
    * @param o_drug_cancel_detail       
    * @param o_drug_report_detail       
    * @param o_drug_local_presc_detail  
    * @param o_drug_activate_detail     
    * @param o_drug_administer_detail   
    * @param o_drug_continued_detail    
    * @param o_drug_discontinued_detail 
    * @param o_drug_ext_presc_emb_detail 
    * @param o_drug_refills_detail      
    * @param o_drug_int_presc_detail    
    * @param o_drug_warnings_detail     
    * @param o_error                    Error message
    *
    * @return                            TRUE if success and FALSE otherwise
    *
    * @author                Tiago Lourenço
    * @version               v2.6.0.5
    * @since                 28-Jan-2011
    ********************************************************************************************/
    FUNCTION get_drug_details
    (
        i_lang                      IN language.id_language%TYPE,
        i_prof                      IN profissional,
        i_id_patient                IN patient.id_patient%TYPE,
        i_subject                   IN VARCHAR2,
        i_id_presc                  IN NUMBER,
        i_flg_direction_config      IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        o_drug_detail               OUT pk_types.cursor_type,
        o_drug_detail_hist          OUT pk_types.cursor_type,
        o_drug_hold_detail          OUT pk_types.cursor_type,
        o_drug_cancel_detail        OUT pk_types.cursor_type,
        o_drug_report_detail        OUT pk_types.cursor_type,
        o_drug_local_presc_detail   OUT pk_types.cursor_type,
        o_drug_activate_detail      OUT pk_types.cursor_type,
        o_drug_administer_detail    OUT pk_types.cursor_type,
        o_drug_continued_detail     OUT pk_types.cursor_type,
        o_drug_discontinued_detail  OUT pk_types.cursor_type,
        o_drug_ext_presc_emb_detail OUT pk_types.cursor_type,
        o_drug_refills_detail       OUT pk_types.cursor_type,
        o_drug_int_presc_detail     OUT pk_types.cursor_type,
        o_drug_warnings_detail      OUT pk_types.cursor_type,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * pk_reports_medication_api.get_medication_reconciliation  
    *
    * @param    I_LANG                          IN        NUMBER(6)
    * @param    I_PROF                          IN        PROFISSIONAL
    * @param    I_ID_EPISODE                    IN        NUMBER(24)
    * @param    O_MED_RECONCILIATION            OUT       REF CURSOR
    * @param    O_LABEL_RECONCILIATION          OUT       VARCHAR2
    * @param    O_LABEL_LAST_UPDATE             OUT       VARCHAR2
    * @param    O_MSG_NO_RECONCILIATION         OUT       VARCHAR2
    * @param    O_ERROR                         OUT       T_ERROR_OUT
    *
    * @return   BOOLEAN
    *
    * @author   Rui Marante
    * @version    
    * @since    2011-09-29
    *
    * @notes    
    *
    * @ext_refs   --
    *
    * @status   
    *
    ********************************************************************************************/
    FUNCTION get_medication_reconciliation
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_episode            IN episode.id_episode%TYPE,
        o_med_reconciliation    OUT pk_types.cursor_type,
        o_label_reconciliation  OUT VARCHAR2,
        o_label_last_update     OUT VARCHAR2,
        o_msg_no_reconciliation OUT VARCHAR2,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
      * Get id of the report for a specific market, institution, software and type of prescription and drug
      *
      * @param  i_lang                    Language
      * @param  i_prof                    Professional
    * @param  i_task_type               Drug type
      * @param  i_id_product            Product (if applicable)
      * @param  i_id_product_supplier     Product supplier (if applicable)
      * @param  o_id_reports              Identification of the reports that should be generated    
      * @param  o_error                   Error message
      *
      * @return  Return TRUE if sucess, FALSE otherwise 
      *
      * @author  Ricardo Pires
      * @version  v2.6.2
      * @since  2011-12-19
      *
      ********************************************************************************************/
    FUNCTION get_rep_prescription_match
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_task_type           IN table_number,
        i_id_product          IN table_varchar,
        i_id_product_supplier IN table_varchar,
        o_id_reports          OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Invokation of pk_medication_current.get_current_medication_int
    
    * @author                                  Gonçalo Almeida
    * @version                                 0.1
    * @since                                   2011/Mar/02
    ********************************************************************************************/
    FUNCTION get_hm_review
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_review     OUT pk_types.cursor_type,
        o_review_pnt OUT pk_types.cursor_type,
        o_review_is  OUT pk_types.cursor_type,
        o_review_pt  OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Update table presc_duplicate_report with information
    * relating prescription and duplicata of id_epis_report 
    *
    * @author Pedro Teixeira
    * @since  12/12/2013
    *
    ********************************************************************************************/
    FUNCTION set_presc_duplicate_report
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_presc     IN table_number,
        id_epis_report IN NUMBER,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get the presc_type for a specific report
    *
    * @author Ricardo Pires
    * @since  21/10/2014
    *
    ********************************************************************************************/
    FUNCTION get_report_presc_type
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_reports      IN reports.id_reports%TYPE,
        i_id_reports_list IN table_number,
        i_presc_type      IN table_varchar
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Get the task_type for a specific report
    *
    * @author Ricardo Pires
    * @since  21/10/2014
    *
    ********************************************************************************************/
    FUNCTION get_report_task_type
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_reports      IN reports.id_reports%TYPE,
        i_id_reports_list IN table_number,
        i_task_type       IN table_number
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Gets the external prescription directions
    *
    * @param  i_lang              Language ID
    * @param  i_prof              Professional info array
    * @param  i_id_episode        Episode ID
    * @param  i_id_visit          Visit ID
    * @param  i_id_patient        Patient ID
    * @param  o_local_presc_dirs  Cursor with data
    * @param  o_error             Error object
    *
    * @return true/false
    *
    * @author Tiago Pereira
    * @since  12/12/2014
    *
    ********************************************************************************************/
    FUNCTION get_list_ext_presc_dirs
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        i_id_visit   IN episode.id_visit%TYPE,
        i_id_patient IN episode.id_patient%TYPE,
        i_id_presc   IN presc.id_presc%TYPE,
        o_presc_dirs OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;
    FUNCTION get_med_reconciliation_info
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_visit         IN visit.id_visit%TYPE,
        i_id_episode       IN episode.id_episode%TYPE,
        i_id_patient       IN presc.id_patient%TYPE,
        o_new_presc        OUT pk_types.cursor_type,
        o_stopped_presc    OUT pk_types.cursor_type,
        o_changes_home_med OUT pk_types.cursor_type,
        o_home_med         OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    **********************************************************************************************/
    FUNCTION get_epis_reports_presc
    (
        i_lang                     IN language.id_language%TYPE,
        i_prof                     IN profissional,
        i_id_epis_report_duplicate IN NUMBER,
        o_id_presc                 OUT pk_types.cursor_type,
        o_error                    OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    **********************************************************************************************/
    FUNCTION get_presc_info
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN NUMBER,
        i_id_visit   IN NUMBER,
        i_id_episode IN NUMBER,
        i_id_presc   IN table_number,
        o_info       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    **********************************************************************************************/
    FUNCTION get_presc_print_report
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_patient        IN NUMBER,
        i_id_episode        IN NUMBER,
        i_id_presc          IN table_number,
        o_info              OUT pk_types.cursor_type,
        o_prof_data         OUT pk_types.cursor_type,
        o_presc_diags_tasks OUT pk_types.cursor_type,
        o_version           OUT VARCHAR2,
        o_service_info      OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Gets the prescription information regarding the narcotic and controlled drug medications 
     *
     * @param  i_lang                        The language ID
     * @param  i_prof                        The professional array
     * @param  i_id_presc                    Prescription Ids
     
     * @param  o_info                        Output cursor with medication description, dosage, frequency
     *
     * @author   Sofia Mendes
     * @since    2018-08-30
     ********************************************************************************************/
    FUNCTION get_presc_narcotic_info
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_presc IN table_number,
        o_info     OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Gets the prescription information regarding the Medication, Narrative and Patient instruction (EN/ARABIC)
    *
    * @param  i_lang                        The language ID
    * @param  i_prof                        The professional array
    * @param  i_id_presc                    Prescription Ids
    
    * @param  o_info                        Output cursor with medication description, Narrative and Patient instruction (EN/ARABIC)
    *
    * @author   Adriana Ramos
    * @since    2018-09-05
    ********************************************************************************************/
    FUNCTION get_presc_med_narrative_info
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_presc IN table_number,
        o_info     OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Function to return the prescriptions info to the treatment guide, institution and patient information.
    *
    * @param  i_lang            The language ID
    * @param  i_prof            The professional array
    * @param  i_id_patient      Patient Id
    * @param  i_id_episode      Episode Id
    * @param  i_id_presc        Prescriptions list Id
    * @param  i_print_type      'D' - Receipt Dematerialized, '1' - Materialized Normal, '2' - Materialized renewable 2 vias, '2' - Materialized renewable 3 vias
    *
    * @param  o_presc           Output cursor with prescriptions info to the treatment guide.
    * @param  o_institution     Output cursor with institution info.
    * @param  o_patient         Output cursor with patient info.
    * @param  o_error           error
    *
    * @author Adriana Ramos
    * @since  2019-03-11
    ********************************************************************************************/
    FUNCTION get_treatment_guide_presc_data
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_patient  IN patient.id_patient%TYPE,
        i_id_episode  IN episode.id_episode%TYPE,
        i_id_presc    IN table_number,
        i_print_type  IN VARCHAR2,
        o_presc       OUT pk_types.cursor_type,
        o_institution OUT pk_types.cursor_type,
        o_patient     OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Insert the data to be used to send xml in the materialized and dematerialized recipe
    *
    * @param  i_lang                   The language ID
    * @param  i_prof                   The professional array
    * @param  i_id_patient             Patient Id
    * @param  i_id_episode             Episode Id
    * @param  i_print_type             'D' - Receipt Dematerialized, '1' - Materialized Normal, '2' - Materialized renewable 2 vias, '3' - Materialized renewable 3 vias
    * @param  i_id_presc               Prescriptions list Id
    * @param  i_local_prescricao       Local da prescrição
    * @param  i_prescritor             Prescritor
    * @param  i_recm                   RECM
    * @param  i_sexo_utente            Sexo Utente 
    * @param  i_data_nascimento_utente Data Nascimento Utente 
    * @param  i_localidade_utente      Localidade Utente     
    * @param  i_num_beneficiario       Numero benefeciário Utente     
    * @param  i_numero_vias            1 - Materialized Normal, 2 - Materialized renewable 2 vias, 3 - Materialized renewable 3 vias
    * @param  o_id_presc_xml           List of prescriptions XML Id
    * @param  o_error                  Error object
    *
    * @return boolean
    *
    * @author CRISTINA.OLIVEIRA
    * @since  2019-03-12
    ********************************************************************************************/

    FUNCTION ins_presc_xml_group
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_id_patient             IN patient.id_patient%TYPE,
        i_id_episode             IN episode.id_episode%TYPE,
        i_print_type             IN table_varchar,
        i_id_presc               IN table_table_number,
        i_local_prescricao       IN table_varchar,
        i_prescritor             IN table_varchar,
        i_receita_renovavel      IN table_number,
        i_recm                   IN table_varchar,
        i_sexo_utente            IN table_varchar,
        i_data_nascimento_utente IN table_varchar,
        i_localidade_utente      IN table_varchar,
        i_num_beneficiario       IN table_varchar,
        i_numero_vias            IN table_number,
        i_ent_resp               IN table_varchar,
        i_numero_registo         IN table_table_varchar,
        i_quantidade             IN table_table_number,
        i_descricao              IN table_table_varchar,
        i_numero_despacho        IN table_table_number,
        i_autorizacao_genericos  IN table_table_number,
        i_posologia              IN table_table_varchar,
        i_line_num               IN table_table_number,
        i_cn_pem                 IN table_table_varchar,
        i_id_inn                 IN table_table_varchar,
        i_id_pharm_form          IN table_table_varchar,
        i_emb_desc               IN table_table_varchar,
        i_dosage                 IN table_table_varchar,
        i_regulation_desc        IN table_table_varchar,
        i_line_type              IN table_table_varchar,
        i_duration_value         IN table_table_number,
        i_duration_unit          IN table_table_varchar,
        i_id_pesc_group          IN table_number,
        i_id_reports             IN NUMBER,
        i_flg_cancel             IN VARCHAR2,
        o_id_presc_xml           OUT table_number,
        o_id_presc_xml_group     OUT NUMBER,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Update the data in the dematerialized and materialized recipe about the web service response
    *
    * @param  i_lang             The language ID
    * @param  i_prof             The professional array
    * @param  i_id_presc_xml     List of prescriptions XML Id
    * @param  i_nr_receipt       List of receipts number
    * @param  i_error_msg        Log error request / response by web service
    * @param  i_flg_xml          O - Receipt created from an ONLINE event. 
                                 N - Receipt created from an OFFLINE event and has not yet been reported to ACSS. 
                                 Y - Receipt created from an OFFLINE event and ACSS was reported. 
                                 C - The user cancel after the preview.
    * @param  i_xml_request      Request in format xml by report if Receipt Dematerialized
    * @param  i_xml_response     Response in format xml by services SPMS if Receipt Dematerialized
    * @param  o_error            Error object
    *
    * @return boolean
    *
    * @author CRISTINA.OLIVEIRA
    * @since  2019-03-12
    ********************************************************************************************/
    FUNCTION upd_presc_xml
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_presc_xml      IN NUMBER,
        i_nr_receipt        IN VARCHAR2 DEFAULT NULL,
        i_error_msg         IN VARCHAR2 DEFAULT NULL,
        i_flg_xml           IN VARCHAR2 DEFAULT NULL,
        i_xml_request       IN CLOB DEFAULT NULL,
        i_xml_response      IN CLOB DEFAULT NULL,
        i_flg_print         IN VARCHAR2,
        i_contact           IN VARCHAR2,
        i_email             IN VARCHAR2,
        o_id_presc_xml_goup OUT NUMBER,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Function to return the prescriptions info to the treatment guide 
    *
    * @param      i_lang                Língua registada como preferência do profissional
    * @param      I_PROF                Profissional que acede
    * @param      i_id_episode          Episode Id
    * @param      i_id_presc_xml        Prescription XML id
    * @param      o_presc               Aditional information
    * @param      O_ERROR               erro
    *
    * @return     boolean
    * @author     CRISTINA.OLIVEIRA
    * @since      2019-04-11
    ********************************************************************************************/
    FUNCTION get_rx_prescr_data_aditional
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN alert.profissional,
        i_id_episode   IN episode.id_episode%TYPE,
        i_id_presc_xml IN NUMBER,
        o_presc        OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_migrant_doc
    (
        i_lang                IN NUMBER,
        i_prof                IN profissional,
        i_id_patient          IN patient.id_patient%TYPE,
        o_num_doc             OUT doc_external.num_doc%TYPE,
        o_exist_doc           OUT VARCHAR2,
        o_dt_expire           OUT doc_external.dt_expire%TYPE,
        o_doc_type            OUT doc_external.id_doc_type%TYPE,
        o_id_content_doc_type OUT doc_type.id_content%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Gets info about out on pass per id.
    *
    * @param   i_lang          Professional preferred language
    * @param   i_prof          Professional identification and its context (institution and software)        
    * @param   i_id_epis_out_on_pass    Epis out on pass detail record identifier
    * @param   o_info          Output cursor with out on pass info.
    * @param   o_error         error
    *
    * @return  true (sucess), false (error)
    *
    * @author  CRISTINA.OLIVEIRA
    * @since   21/05/2019
    **********************************************************************************************/
    FUNCTION get_epis_out_on_pass_info
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_epis_out_on_pass IN epis_out_on_pass.id_epis_out_on_pass%TYPE,
        o_info                OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    ********************************************************************************************/
    FUNCTION get_epis_out_on_pass_rep
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN epis_out_on_pass.id_episode%TYPE,
        i_flg_hist   IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        o_detail     OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Gets the the list of prescriptions to be administered for the patients until the end date 
    *
    * @param  i_lang                        The language ID
    * @param  i_prof                        The professional array
    * @param  i_lst_id_patient              The list of Patient ID
    * @param  i_dt_end                      The end date 
    * @param  o_info_pat                    Output cursor with information about patients
    * @param  o_info_med                    Output cursor with the information about prescriptions to be administered 
    *
    * @author   CRISTINA.OLIVEIRA
    * @since    2020-10-08
    ********************************************************************************************/
    FUNCTION get_admin_info_by_patient
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_lst_id_patient IN table_number,
        i_dt_end         IN VARCHAR2 DEFAULT NULL,
        o_info_pat       OUT pk_types.cursor_type,
        o_info_med       OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Gets the list of services with prescriptions to be administered
    *
    * @param  i_lang                        The language ID
    * @param  i_prof                        The professional array
    * @param  o_info_services               Output cursor with the information about services
    *
    * @author   CRISTINA.OLIVEIRA
    * @since    2020-10-08
    ********************************************************************************************/
    FUNCTION get_admin_services
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        o_info_services OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Gets the list of patients with prescriptions to be administered by service
    *
    * @param  i_lang                        The language ID
    * @param  i_prof                        The professional array
    * @param  i_id_department               Department ID
    * @param  o_info_patients               Output cursor with the information about patients
    *
    * @author   CRISTINA.OLIVEIRA
    * @since    2020-10-08
    ********************************************************************************************/
    FUNCTION get_admin_patients
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_department IN table_number,
        o_info_patients OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get report information from returns medications (i_id_pha_return) or all medications returned of 
    * an episode to the pharmacy 
    *
    * @param   i_lang                    language.id_language%TYPE
    * @param   i_prof                    profissional
    * @param   i_id_episode              Episode ID
    * @param   i_pha_return              Pha return list Ids
    * @param   o_info                    Cursor with return to the pharmacy info
    * @param   o_error                   Standard Error
    *
    * @return  boolean
    *
    * @author          Cristina Oliveira
    * @version         2.8.4
    * @since           23/09/2021
    ********************************************************************************************/
    FUNCTION get_pharm_return_report
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_episode    IN episode.id_episode%TYPE,
        i_id_pha_return IN table_number DEFAULT NULL,
        o_info          OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;
END pk_reports_medication_api;
/
