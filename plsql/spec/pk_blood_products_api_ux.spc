/*-- Last Change Revision: $Rev: 2043880 $*/
/*-- Last Change by: $Author: pedro.henriques $*/
/*-- Date of last change: $Date: 2022-08-04 10:37:31 +0100 (qui, 04 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_blood_products_api_ux IS

    /*
    * Sets a blood transfusion request
    *
    * @param     i_lang                      Language id
    * @param     i_prof                      Professional          
    * @param     i_patient                   Patient id
    * @param     i_episode                   Episode id
    * @param     i_hemo_type                 Component id
    * @param     i_flg_time                  Flag that indicates when the transfusion is to be performed
    * @param     i_dt_begin                  Date for the transfusion to be performed
    * @param     i_episode_destination       Episode destination id (when flg_time = 'N')
    * @param     i_order_recurrence          Order recurrence id
    * @param     i_diagnosis                 Clinical indication
    * @param     i_clinical_purpose          Clinical purpose
    * @param     i_priority                  Priority
    * @param     i_transf_type               Transfusion type
    * @param     i_qty_exec                  Quantity 
    * @param     i_unit_qty_exec             Quantity unit measure
    * @param     i_exec_institution          Perform institution id
    * @param     i_not_order_reason          Reason for not ordering
    * @param     i_special_instr             Special instructions
    * @param     i_notes                     Notes
    * @param     i_prof_order                Professional that ordered the transfusion (co-sign)
    * @param     i_dt_order                  Date of the transfusion order (co-sign)
    * @param     i_order_type                Type of order (co-sign)  
    * @param     i_health_plan               Transfusion health plan id
    * @param     i_exemption                 Transfusion exemption id
    * @param     i_clinical_question         Clinical questions
    * @param     i_response                  Response id
    * @param     i_clinical_question_notes   Clincial question notes
    * @param     i_clinical_decision_rule    Clinical decision rule
    * @param     i_flg_origin_req            Flag that indicates the module from which the transfusion is being ordered: D - Default, O - Order Sets, I - Interfaces
    * @param     i_test                      Flag that indicates if the transfusion is really to be ordered
    * @param     o_flg_show                  Flag that indicates if there is a message to be shown
    * @param     o_msg_title                 Message title
    * @param     o_msg_req                   Message to be shown
    * @param     o_blood_prod_req_array      Cursor           
    * @param     o_blood_prod_det_array      Cursor         
    * @param     o_error                     Error message
    
    * @return    true or false on success or error
    *
    * @author    Pedro Henriques
    * @version   2.7.4.0
    * @since     2018/08/20
    */

    FUNCTION create_bp_order
    (
        i_lang                    IN language.id_language%TYPE, --1
        i_prof                    IN profissional,
        i_patient                 IN patient.id_patient%TYPE,
        i_episode                 IN episode.id_episode%TYPE,
        i_hemo_type               IN table_number, --5
        i_flg_time                IN table_varchar,
        i_dt_begin                IN table_varchar,
        i_episode_destination     IN table_number,
        i_order_recurrence        IN table_number,
        i_diagnosis               IN table_clob, --10
        i_clinical_purpose        IN table_number,
        i_clinical_purpose_notes  IN table_varchar,
        i_priority                IN table_varchar,
        i_special_type            IN table_number,
        i_screening               IN table_varchar,
        i_without_nat             IN table_varchar,
        i_not_send_unit           IN table_varchar,
        i_transf_type             IN table_varchar, --15
        i_qty_exec                IN table_number,
        i_unit_qty_exec           IN table_number,
        i_exec_institution        IN table_number,
        i_not_order_reason        IN table_number,
        i_special_instr           IN table_varchar, --20
        i_notes                   IN table_varchar,
        i_prof_order              IN table_number,
        i_dt_order                IN table_varchar,
        i_order_type              IN table_number,
        i_health_plan             IN table_number, --25
        i_exemption               IN table_number,
        i_clinical_question       IN table_table_number,
        i_response                IN table_table_varchar,
        i_clinical_question_notes IN table_table_varchar,
        i_clinical_decision_rule  IN table_number, --30
        i_flg_origin_req          IN VARCHAR2 DEFAULT 'D',
        i_test                    IN VARCHAR2,
        i_flg_mother_lab_tests    IN VARCHAR2 DEFAULT 'N',
        o_flg_show                OUT VARCHAR2,
        o_msg_title               OUT VARCHAR2, --35
        o_msg_req                 OUT VARCHAR2,
        o_blood_prod_req_array    OUT NOCOPY table_number,
        o_blood_prod_det_array    OUT NOCOPY table_number,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Sets the information given by the blood bank
    *
    * @param     i_lang                          Language id
    * @param     i_prof                          Professional
    * @param     i_blood_product_req             Transfusion requisition id
    * param      i_hemo_type                     Hemo type id
    * @param     i_barcode                       Barcode                      
    * @param     i_qty_rec                       Volume/Quantity sent by the blood bank
    * @param     i_unit_mea                      Volume/Quantity unit measure            
    * @param     i_expiration_date               Expiration date (YYYYMMDDhh24miss)
    * @param     i_blood_group                   Blood group
    * @param     i_blood_group_rh                Rh factor           
    * @param     o_error                         Error message
    *
    * @return    true or false on success or error
    *
    * @author    Pedro Henriques
    * @version   2.7.4.0
    * @since     2018/08/20
    */

    FUNCTION set_bp_preparation
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_blood_product_req  IN blood_product_req.id_blood_product_req%TYPE,
        i_hemo_type          IN hemo_type.id_hemo_type%TYPE,
        i_barcode            IN VARCHAR2,
        i_qty_rec            IN NUMBER,
        i_unit_mea           IN NUMBER,
        i_expiration_date    IN VARCHAR2,
        i_blood_group        IN VARCHAR2,
        i_blood_group_rh     IN VARCHAR2,
        i_desc_hemo_type_lab IN VARCHAR2,
        i_donation_code      IN VARCHAR2,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Sets the 'Begin transport' or the 'End transpor' state for a bag request.
    *
    * @param     i_lang                          Language id
    * @param     i_prof                          Professional
    * @param     i_blood_product_det             Blood product bag id
    * @param     i_to_state                      State
    * @param     i_barcode                       Barcode
    * @param     i_prof_match                   Professional id
    * @param     o_error                         Error message
    *
    * @return    true or false on success or error
    *
    * @author    Pedro Henriques
    * @version   2.7.4.0
    * @since     2018/08/20
    */

    FUNCTION set_bp_transport
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_blood_product_det IN blood_product_det.id_blood_product_det%TYPE,
        i_to_state          IN VARCHAR2,
        i_barcode           IN VARCHAR2,
        i_prof_match        IN NUMBER DEFAULT NULL,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_bp_compatibility
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_blood_product_det IN blood_product_det.id_blood_product_det%TYPE,
        i_flg_compatibility IN blood_product_execution.flg_compatibility%TYPE,
        i_notes             IN blood_product_execution.notes_compatibility%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_bp_transfusion
    (
        i_lang                  IN language.id_language%TYPE, --1
        i_prof                  IN profissional,
        i_episode               IN episode.id_episode%TYPE,
        i_blood_product_det     IN blood_product_det.id_blood_product_det%TYPE,
        i_from_state            IN action.to_state%TYPE DEFAULT NULL,
        i_to_state              IN action.to_state%TYPE DEFAULT NULL,
        i_performed_by          IN professional.id_professional%TYPE,
        i_start_date            IN VARCHAR2, --5
        i_duration              IN blood_product_execution.duration%TYPE,
        i_duration_unit_measure IN blood_product_execution.id_unit_mea_duration%TYPE,
        i_end_date              IN VARCHAR2,
        i_description           IN blood_product_execution.description%TYPE,
        i_prof_match            IN NUMBER DEFAULT NULL, --10
        i_documentation_notes   IN epis_interv.notes%TYPE,
        i_doc_template          IN doc_template.id_doc_template%TYPE,
        i_flg_type              IN doc_template_context.flg_type%TYPE,
        i_id_documentation      IN table_number, --15
        i_id_doc_element        IN table_number,
        i_id_doc_element_crit   IN table_number,
        i_value                 IN table_varchar,
        i_id_doc_element_qualif IN table_table_number,
        i_vs_element_list       IN table_number, --20
        i_vs_save_mode_list     IN table_varchar,
        i_vs_list               IN table_number,
        i_vs_value_list         IN table_number,
        i_vs_uom_list           IN table_number,
        i_vs_scales_list        IN table_number, --25
        i_vs_date_list          IN table_varchar,
        i_vs_read_list          IN table_number,
        i_amount_given          IN blood_product_det.qty_given%TYPE,
        i_amount_given_unit     IN blood_product_det.id_unit_mea_qty_given%TYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Sets the information regarding an adverse reaction to a bag transfusion. (Information 
    * stored via template)
    *
    * @param     i_lang                          Language id
    * @param     i_prof                          Professional
    * @param     i_episode                       Episode id
    * @param     i_blood_product_det             Blood product bag id
    * @param     i_documentation_notes           Documentation notes
    * @param     i_doc_template                  Touch-option template ID
    * @param     i_flg_type                      Operation that was applied to save this entry
    * @param     i_id_documentation              Array with id documentation
    * @param     i_id_doc_element                Array with doc elements
    * @param     i_id_doc_element_crit           Array with doc elements crit
    * @param     i_value                         Array with values
    * @param     i_id_doc_element_qualif         Array with element quantifications/qualifications 
    * @param     i_vs_element_list               List of template's elements ID (id_doc_element) filled with vital signs
    * @param     i_vs_save_mode_list             List of flags to indicate the applicable mode to save each vital signs measurement
    * @param     i_vs_list                       List of vital signs ID (id_vital_sign)
    * @param     i_vs_value_list                 List of vital signs values
    * @param     i_vs_uom_list                   List of units of measurement (id_unit_measure)
    * @param     i_vs_scales_list                List of scales (id_vs_scales_element)
    * @param     i_vs_date_list                  List of measurement date. Values are serialized as strings (YYYYMMDDhh24miss)
    * @param     i_vs_read_list                  List of saved vital sign measurement (id_vital_sign_read)       
    * @param     o_error                         Error message
    *
    * @return    true or false on success or error
    *
    * @author    Pedro Henriques
    * @version   2.7.4.0
    * @since     2018/08/20
    */

    FUNCTION set_bp_adverse_reaction
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_episode               IN episode.id_episode%TYPE,
        i_blood_product_det     IN blood_product_det.id_blood_product_det%TYPE,
        i_documentation_notes   IN epis_interv.notes%TYPE,
        i_doc_template          IN doc_template.id_doc_template%TYPE,
        i_flg_type              IN doc_template_context.flg_type%TYPE,
        i_id_documentation      IN table_number,
        i_id_doc_element        IN table_number,
        i_id_doc_element_crit   IN table_number,
        i_value                 IN table_varchar,
        i_id_doc_element_qualif IN table_table_number,
        i_vs_element_list       IN table_number,
        i_vs_save_mode_list     IN table_varchar,
        i_vs_list               IN table_number,
        i_vs_value_list         IN table_number,
        i_vs_uom_list           IN table_number,
        i_vs_scales_list        IN table_number,
        i_vs_date_list          IN table_varchar,
        i_vs_read_list          IN table_number,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Updates the transfusion requisition state. It will also update the its bags if the
    * bags are not yet finished nor canceled.
    *
    * @param     i_lang                          Language id
    * @param     i_prof                          Professional
    * @param     i_blood_product_req             Transfusion requisition id
    * @param     i_state                         State
    * @param     i_cancel_reason                 Reason id
    * @param     i_notes_cancel                  Reason notes
    * @param     o_error                         Error message
    *
    * @return    true or false on success or error
    *
    * @author    Pedro Henriques
    * @version   2.7.4.0
    * @since     2018/08/20
    */

    FUNCTION set_bp_req_status
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_blood_product_req IN blood_product_req.id_blood_product_req%TYPE,
        i_state             IN blood_product_req.flg_status%TYPE,
        i_cancel_reason     IN cancel_reason.id_cancel_reason%TYPE,
        i_notes_cancel      IN blood_product_req.notes%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Updates the bag state.
    *
    * @param     i_lang                          Language id
    * @param     i_prof                          Professional
    * @param     i_blood_product_det             Blood product bag id
    * @param     i_state                         State
    * @param     i_cancel_reason                 Reason id
    * @param     i_notes_cancel                  Reason notes
    * @param     o_error                         Error message
    *
    * @return    true or false on success or error
    *
    * @author    Pedro Henriques
    * @version   2.7.4.0
    * @since     2018/08/20
    */

    FUNCTION set_bp_status
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_blood_product_det IN blood_product_det.id_blood_product_det%TYPE,
        i_state             IN blood_product_det.flg_status%TYPE,
        i_cancel_reason     IN cancel_reason.id_cancel_reason%TYPE,
        i_notes_cancel      IN blood_product_req.notes%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_bp_compatibility_warning
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_flg_warning_type IN VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_bp_condition
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_blood_product_det IN blood_product_det.id_blood_product_det%TYPE,
        i_flg_condition     IN VARCHAR2,
        i_id_reason         IN blood_product_execution.id_action_reason%TYPE,
        i_notes             IN blood_product_execution.notes_reason%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_bp_crossmatch_credential
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_bp_transfusion_confirm
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_blood_product_det IN table_number,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION update_bp_order
    (
        i_lang                    IN language.id_language%TYPE, --1
        i_prof                    IN profissional,
        i_episode                 IN episode.id_episode%TYPE,
        i_blood_product_req       IN blood_product_req.id_blood_product_req%TYPE,
        i_blood_product_det       IN table_number, --5
        i_flg_time                IN table_varchar,
        i_dt_begin                IN table_varchar,
        i_order_recurrence        IN table_number,
        i_diagnosis               IN table_clob,
        i_clinical_purpose        IN table_number, --10
        i_clinical_purpose_notes  IN table_varchar,
        i_priority                IN table_varchar,
        i_special_type            IN table_number,
        i_screening               IN table_varchar,
        i_without_nat             IN table_varchar,
        i_not_send_unit           IN table_varchar,
        i_transf_type             IN table_varchar,
        i_qty_exec                IN table_number, --15
        i_unit_qty_exec           IN table_number,
        i_exec_institution        IN table_number,
        i_not_order_reason        IN table_number,
        i_special_instr           IN table_varchar,
        i_notes                   IN table_varchar, --20
        i_prof_order              IN table_number,
        i_dt_order                IN table_varchar,
        i_order_type              IN table_number,
        i_health_plan             IN table_number,
        i_exemption               IN table_number, --25
        i_clinical_question       IN table_table_number,
        i_response                IN table_table_varchar,
        i_clinical_question_notes IN table_table_varchar,
        i_clinical_decision_rule  IN table_number,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Cancels the transfusion request (Also cancels all the bags for the given request)
    *
    * @param     i_lang                          Language id
    * @param     i_prof                          Professional
    * @param     i_blood_product_req             Transfusion requisition id
    * @param     i_cancel_reason                 Cancel reason id
    * @param     i_notes_cancel                  Cancel notes        
    * @param     o_error                         Error message
    *
    * @return    true or false on success or error
    *
    * @author    Pedro Henriques
    * @version   2.7.4.0
    * @since     2018/08/20
    */

    FUNCTION cancel_bp_order
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_blood_product_req IN table_number,
        i_cancel_reason     IN cancel_reason.id_cancel_reason%TYPE,
        i_notes_cancel      IN blood_product_req.notes%TYPE,
        i_blood_product_det IN table_number DEFAULT NULL,
        i_qty_given         IN table_number DEFAULT NULL,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Cancels the bag request
    *
    * @param     i_lang                          Language id
    * @param     i_prof                          Professional
    * @param     i_blood_product_det             Blood product bag id
    * @param     i_cancel_reason                 Cancel reason id
    * @param     i_notes_cancel                  Cancel notes        
    * @param     o_error                         Error message
    *
    * @return    true or false on success or error
    *
    * @author    Pedro Henriques
    * @version   2.7.4.0
    * @since     2018/08/20
    */

    FUNCTION cancel_bp_request
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_blood_product_det     IN table_number,
        i_cancel_reason         IN cancel_reason.id_cancel_reason%TYPE,
        i_notes_cancel          IN blood_product_req.notes%TYPE,
        i_blood_product_det_qty IN table_number DEFAULT NULL,
        i_qty_given             IN table_number DEFAULT NULL,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Gets the list of available hemo types.
    *
    * @param     i_lang                          Language id
    * @param     i_prof                          Professional    
    * @param     o_list                          Cursor       
    *
    * @return    true or false on success or error
    *
    * @author    Pedro Henriques
    * @version   2.7.4.0
    * @since     2018/08/20
    */

    FUNCTION get_bp_selection_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns the status string of the transports for the ancillary 
    *
    * @param     i_lang                          Language id
    * @param     i_prof                          Professional
    * @param     i_episode                       Episode id
    * @param     o_list                          Cursor
    * @param     o_error                         Error message
    *
    * @return    true or false on success or error
    *
    * @author    Pedro Henriques
    * @version   2.7.4.0
    * @since     2018/08/20
    */

    FUNCTION get_bp_transport_listview
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_list    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_bp_compatibility
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_episode          IN episode.id_episode%TYPE,
        o_show_popup       OUT VARCHAR2,
        o_title            OUT VARCHAR2,
        o_msg              OUT VARCHAR2,
        o_shortcut         OUT sys_shortcut.id_sys_shortcut%TYPE,
        o_id_bp_det        OUT blood_product_det.id_blood_product_det%TYPE,
        o_flg_warning_type OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Gets the list of clinical questions for the chosen hemo type
    *
    * @param     i_lang                          Language id
    * @param     i_prof                          Professional
    * @param     i_patient                       Patient id             
    * param      i_episode                       Episode id
    * @param     i_hemo_type                     Hemo type id
    * @param     i_flg_time                      Time flag (O-Order)
    * @param     i_dep_clin_serv                 Dep_clin_serv id             
    * @param     o_list                          Cursor       
    * @param     o_error                         Error message
    *
    * @return    true or false on success or error
    *
    * @author    Pedro Henriques
    * @version   2.7.4.0
    * @since     2018/08/20
    */

    FUNCTION get_bp_questionnaire
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_episode       IN episode.id_episode%TYPE,
        i_hemo_type     IN hemo_type.id_hemo_type%TYPE,
        i_flg_time      IN VARCHAR2,
        i_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE DEFAULT NULL,
        o_list          OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Compares the information for a given barcode with the requested bag.
    *
    * @param     i_lang                          Language id
    * @param     i_prof                          Professional
    * @param     i_blood_product_det             Blood product bag id
    * @param     i_barcode                       Barcode
    * @param     o_list                          Cursor
    * @param     o_error                         Error message
    *
    * @return    true or false on success or error
    *
    * @author    Pedro Henriques
    * @version   2.7.4.0
    * @since     2018/08/20
    */

    FUNCTION get_bp_barcode
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_blood_product_det IN blood_product_det.id_blood_product_det%TYPE,
        i_barcode           IN blood_product_det.barcode_lab%TYPE,
        o_list              OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_bp_donation_code
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_blood_product_det IN blood_product_det.id_blood_product_det%TYPE,
        i_donation_code     IN blood_product_det.donation_code%TYPE,
        o_list              OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns the list of details for the given bag. The list will include all the details from all 
    * the performed actions, chronologically sorted from the most recent action to the first action
    *
    * @param     i_lang                          Language id
    * @param     i_prof                          Professional
    * @param     i_episode                       Episode id
    * @param     i_blood_product_det             Blood product bag id
    * @param     o_bp_detail                     Cursor
    * @param     o_bp_clinical_questions         Cursor     
    * @param     o_error                         Error message
    *
    * @return    true or false on success or error
    *
    * @author    Pedro Henriques
    * @version   2.7.4.0
    * @since     2018/08/20
    */

    FUNCTION get_bp_detail
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_episode               IN episode.id_episode%TYPE,
        i_blood_product_det     IN blood_product_det.id_blood_product_det%TYPE,
        o_bp_detail             OUT pk_types.cursor_type,
        o_bp_clinical_questions OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_bp_detail_html
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_blood_product_det IN blood_product_det.id_blood_product_det%TYPE,
        o_detail            OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_bp_detail_history_html
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_blood_product_det IN blood_product_det.id_blood_product_det%TYPE,
        o_detail            OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_bp_detail_history
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_episode               IN episode.id_episode%TYPE,
        i_blood_product_det     IN blood_product_det.id_blood_product_det%TYPE,
        o_bp_detail             OUT pk_types.cursor_type,
        o_bp_clinical_questions OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns a brief list of details for the given bag. The list will include details 
    * regarding the actions 'order/execution/monitoring/adverse_reactions'. It will also 
    * present the information given by the blood bank.
    *
    * @param     i_lang                          Language id
    * @param     i_prof                          Professional
    * @param     i_episode                       Episode id
    * @param     i_blood_product_det             Blood product bag id
    * @param     o_bp_order                      Cursor with info from Order
    * @param     o_bp_execution                  Cursor with info from Execution
    * @param     o_bp_adverse_reaction           Cursor with info from Adverse reactions
    * @param     o_bp_reevaluation               Cursor with info from Monitoring(s)    
    * @param     o_bp_blood_bank                 Cursor with info from the blood bank
    * @param     o_error                         Error message
    *
    * @return    true or false on success or error
    *
    * @author    Pedro Henriques
    * @version   2.7.4.0
    * @since     2018/08/20
    */

    FUNCTION get_bp_transfusion_summary
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_episode             IN episode.id_episode%TYPE,
        i_blood_product_det   IN blood_product_det.id_blood_product_det%TYPE,
        o_bp_order            OUT pk_types.cursor_type,
        o_bp_execution        OUT pk_types.cursor_type,
        o_bp_adverse_reaction OUT pk_types.cursor_type,
        o_bp_reevaluation     OUT pk_types.cursor_type,
        o_bp_blood_bank       OUT pk_types.cursor_type,
        o_bp_group            OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_bp_transfusions_summary
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_episode             IN episode.id_episode%TYPE,
        i_blood_product_det   IN table_number,
        o_bp_order            OUT pk_types.cursor_type,
        o_bp_execution        OUT pk_types.cursor_type,
        o_bp_adverse_reaction OUT pk_types.cursor_type,
        o_bp_reevaluation     OUT pk_types.cursor_type,
        o_bp_blood_bank       OUT pk_types.cursor_type,
        o_bp_group            OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_bp_to_edit
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_episode               IN episode.id_episode%TYPE,
        i_bp_req                IN table_number,
        i_bp_det                IN table_number,
        o_list                  OUT pk_types.cursor_type,
        o_bp_clinical_questions OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_bp_response_to_edit
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_blood_product_det    IN blood_product_det.id_blood_product_det%TYPE,
        i_flg_time             IN exam_question_response.flg_time%TYPE,
        o_bp_question_response OUT pk_types.cursor_type,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Checks on where the Match screen (o_list_match_screen) and the field 
    * 'Revised by' (o_list_revised) should be presented
    *
    * @param     i_lang                          Language id
    * @param     i_prof                          Professional
    * @param     i_episode                       Episode id
    * @param     o_list_match_screen             Cursor
    * @param     o_list_revised                  Cursor
    * @param     o_error                         Error message
    *
    * @return    true or false on success or error
    *
    * @author    Pedro Henriques
    * @version   2.7.4.0
    * @since     2018/08/20
    */

    FUNCTION get_bp_to_match_and_revise
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_episode           IN episode.id_episode%TYPE,
        o_list_match_screen OUT pk_types.cursor_type,
        o_list_revised      OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Checks which actions should be available for the requisition according to the bags statuses
    *
    * @param     i_lang                          Language id
    * @param     i_prof                          Professional
    * @param     i_episode                       Episode id
    * @param     i_subject                       Subject
    * @param     i_from_state                    State
    * @param     i_id_blood_product_req          Transfusion requisition id
    * @param     o_actions                       Cursor
    * @param     o_error                         Error message
    *
    * @return    true or false on success or error
    *
    * @author    Pedro Henriques
    * @version   2.7.4.0
    * @since     2018/08/20
    */

    FUNCTION get_bp_action_list
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_episode               IN episode.id_episode%TYPE,
        i_subject               IN action.subject%TYPE,
        i_from_state            IN action.from_state%TYPE,
        i_tbl_blood_product_req IN table_number,
        o_actions               OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_bp_cross_actions
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_episode           IN episode.id_episode%TYPE,
        i_subject           IN action.subject%TYPE,
        i_from_state        IN table_varchar,
        i_blood_product_det IN table_number,
        o_actions           OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns the list of sys_domain elements valid for a    
    * specific institution/software
    *
    * @param     i_lang                          Language id
    * @param     i_prof                          Professional
    * @param     i_domain                        Domain code
    * @param     o_list                          Cursor
    * @param     o_error                         Error message
    *
    * @return    true or false on success or error
    *
    * @author    Pedro Henriques
    * @version   2.7.4.0
    * @since     2018/08/20
    */

    FUNCTION get_bp_list
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_domain IN sys_domain.code_domain%TYPE,
        o_list   OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;

    /*    
    * Gets the list of options to be shown on the 'To execute' field.
    *
    * @param     i_lang                          Language id
    * @param     i_prof                          Professional    
    * @param     i_epis_type                     Episode type id  
    * @param     o_list                          Cursor       
    * @param     o_error                         Error message
    *
    * @return    true or false on success or error
    *
    * @author    Pedro Henriques
    * @version   2.7.4.0
    * @since     2018/08/20
    */

    FUNCTION get_bp_time_list
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_epis_type IN epis_type.id_epis_type%TYPE,
        o_list      OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Gets the list of diagnoses.
    *
    * @param     i_lang                          Language id
    * @param     i_prof                          Professional    
    * @param     i_episode                       Episode id       
    * @param     o_list                          Cursor       
    * @param     o_error                         Error message
    *
    * @return    true or false on success or error
    *
    * @author    Pedro Henriques
    * @version   2.7.4.0
    * @since     2018/08/20
    */

    FUNCTION get_bp_diagnosis_list
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_list    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_bp_special_type_list
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_hemo_type     IN hemo_type.id_hemo_type%TYPE,
        i_priority      IN blood_product_det.flg_priority%TYPE,
        o_flg_mandatory OUT VARCHAR2,
        o_list          OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Gets the list of transfusion types.
    *
    * @param     i_lang                          Language id
    * @param     i_prof                          Professional       
    * @param     o_list                          Cursor       
    * @param     o_error                         Error message
    *
    * @return    true or false on success or error
    *
    * @author    Pedro Henriques
    * @version   2.7.4.0
    * @since     2018/08/20
    */

    FUNCTION get_bp_transfusion_type_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Gets the list of special instructions.
    *
    * @param     i_lang                          Language id
    * @param     i_prof                          Professional       
    * @param     o_list                          Cursor       
    * @param     o_error                         Error message
    *
    * @return    true or false on success or error
    *
    * @author    Pedro Henriques
    * @version   2.7.4.0
    * @since     2018/08/20
    */

    FUNCTION get_bp_special_instr_list
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_hemo_type IN hemo_type.id_hemo_type%TYPE,
        i_priority  IN blood_product_det.flg_priority%TYPE,
        o_list      OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Gets the list of health plans.
    *
    * @param     i_lang                          Language id
    * @param     i_prof                          Professional    
    * @param     i_patient                       Patient id    
    * @param     o_list                          Cursor       
    * @param     o_error                         Error message
    *
    * @return    true or false on success or error
    *
    * @author    Pedro Henriques
    * @version   2.7.4.0
    * @since     2018/08/20
    */

    FUNCTION get_bp_health_plan_list
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        o_list    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /*    
    * Gets the list of professionals of the instiution to be shown on the 'Performed by' field.
    *
    * @param     i_lang                          Language id
    * @param     i_prof                          Professional       
    * @param     o_list                          Cursor       
    * @param     o_error                         Error message
    *
    * @return    true or false on success or error
    *
    * @author    Pedro Henriques
    * @version   2.7.4.0
    * @since     2018/08/20
    */

    FUNCTION get_bp_prof_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /*    
    * Gets the information of all the bags requested for a blood transfusion.
    * (used for the viewer on the 'Blood and blood products' grid)
    *
    * @param     i_lang                          Language id
    * @param     i_prof                          Professional    
    * @param     i_bp_req                        id blood_produc_req          
    * @param     o_det_info                      Cursor       
    * @param     o_error                         Error message
    *
    * @return    true or false on success or error
    *
    * @author    Diogo Oliveira
    * @version   2.8.1.0
    * @since     2020/01/30
    */
    FUNCTION get_bp_det_info
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_bp_req   blood_product_det.id_blood_product_req%TYPE,
        o_det_info OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_bp_newborn
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_tbl_hemo_type IN table_number,
        o_show_popup    OUT VARCHAR2,
        o_title         OUT VARCHAR2,
        o_msg           OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_bp_cancel_req_info
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_patient               IN patient.id_patient%TYPE,
        i_tbl_blood_product_req IN table_number,
        o_bp_req_info           OUT pk_types.cursor_type,
        o_bp_det_info           OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_bp_cancel_det_info
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_patient               IN patient.id_patient%TYPE,
        i_tbl_blood_product_det IN table_number,
        o_bp_det_info           OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION send_ref_to_bdnp
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_ref   IN p1_external_request.id_external_request%TYPE,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    g_package_owner VARCHAR2(50);
    g_package_name  VARCHAR2(50);

    g_other_exception EXCEPTION;
    g_user_exception  EXCEPTION;
    g_error      VARCHAR2(4000);
    g_error_code VARCHAR2(100);

END pk_blood_products_api_ux;
/
