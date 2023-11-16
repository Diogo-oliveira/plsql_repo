/*-- Last Change Revision: $Rev: 2028561 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:46:31 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_cit IS

    -- Author  : PEDRO.TEIXEIRA
    -- Created : 03-04-2009 08:44:03
    -- Purpose : Pacote de gestão de certificados de incapacidade temporária

    FUNCTION get_cit_list
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        o_cits    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_cit_report
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        o_cits    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_cit_new_social
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        i_cit     IN pat_cit.id_pat_cit%TYPE,
        o_cits    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_cit_new_public
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        i_cit     IN pat_cit.id_pat_cit%TYPE,
        o_cits    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Função que retorna dados de CIT já existente (no caso de i_cit não ser null) ou então
    * os dados básicos e necessários para a criação de uma nova - Certificado médico de paragem de trabalho
    *
    * @param IN   i_lang        Language ID
    * @param IN   i_prof        Professional ID
    * @param IN   i_patient     Patient ID
    * @param OUT  o_cits        CIT list cursor   
    * @param OUT  o_error       Error structure
    *
    * @return                   Nome do icone
    *
    * @author                   Jorge Silva
    * @since                    11/12/2012
    ********************************************************************************************/
    FUNCTION get_cit_new_sick_leave
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        i_cit     IN pat_cit.id_pat_cit%TYPE,
        o_cits    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_cit_social
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        
        i_cit                       IN pat_cit.id_pat_cit%TYPE,
        i_flg_pat_disease_state     IN pat_cit.flg_pat_disease_state%TYPE,
        i_beneficiary_number        IN pat_cit.beneficiary_number%TYPE,
        i_ill_parent_name           IN pat_cit.ill_parent_name%TYPE,
        i_flg_ill_affinity          IN pat_cit.flg_ill_affinity%TYPE,
        i_ill_id_card               IN pat_cit.ill_id_card%TYPE,
        i_flg_cit_classification_ss IN pat_cit.flg_cit_classification_ss%TYPE,
        i_flg_internment            IN pat_cit.flg_internment%TYPE,
        i_flg_incapacity_period     IN pat_cit.flg_incapacity_period%TYPE,
        i_dt_start_period_tstz      IN VARCHAR2,
        i_dt_end_period_tstz        IN VARCHAR2,
        i_home_authorization        IN pat_cit.home_authorization%TYPE,
        
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_cit_public
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        
        i_cit                       IN pat_cit.id_pat_cit%TYPE,
        i_flg_pat_disease_state     IN pat_cit.flg_pat_disease_state%TYPE,
        i_flg_prof_health_subsys    IN pat_cit.flg_prof_health_subsys%TYPE,
        i_beneficiary_number        IN pat_cit.beneficiary_number%TYPE,
        i_ill_parent_name           IN pat_cit.ill_parent_name%TYPE,
        i_flg_ill_affinity          IN pat_cit.flg_ill_affinity%TYPE,
        i_ill_id_card               IN pat_cit.ill_id_card%TYPE,
        i_flg_benef_health_subsys   IN pat_cit.flg_benef_health_subsys%TYPE,
        i_flg_cit_classification_fp IN pat_cit.flg_cit_classification_fp%TYPE,
        i_flg_internment            IN pat_cit.flg_internment%TYPE,
        i_dt_start_period_tstz      IN VARCHAR2,
        i_dt_end_period_tstz        IN VARCHAR2,
        i_flg_home_absence          IN pat_cit.flg_home_absence%TYPE,
        
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Create or update Work disability document - INAIL's 
    * (at the moment this feature is specific for IT market)
    * IMPORTANT: This function will be used directly be the ADT layer, and for that reason it cannot 
    * commit the transaction.
    *
    * @param IN   i_lang        Language ID
    * @param IN   i_prof        Professional ID
    * @param IN   i_patient     Patient ID
    * @param IN   i_episode     Episode ID
    *
    * @param IN   i_cit                 CIT ID
    * @param IN   i_accident_cause      Accident causes and circumstances
    * @param IN   i_flg_cit_type        Type of certificate
    * @param IN   i_flg_prognosis_type  Type of prognosis
    * @param IN   i_flg_permanent_disability Work disability
    * @param IN   i_flg_life_danger          Life danger
    * @param IN   i_dt_start_period_tstz 
    * @param IN   i_dt_end_period_tstz
    * @param IN   i_dt_event_tstz            Date of event that caused the work the disability
    * @param IN   i_dt_stop_work_tstz        Last day of work due to work disability
    * @param IN   i_id_county_accident       City code where the accident occurred
    * @param IN   i_flg_accident_type        Type of Acident       
    * @param IN   i_landline_prefix        
    * @param IN   i_landline_number        
    * @param IN   i_mobile_prefix          
    * @param IN   i_mobile_number     
    *
    * @return                   true on success and false if error occurs
    *
    * @author                   Orlando Antunes
    * @since                    24/12/2010
    ********************************************************************************************/
    FUNCTION set_cit_inail
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        
        i_cit                      IN pat_cit.id_pat_cit%TYPE,
        i_accident_cause           IN pat_cit.accident_cause%TYPE,
        i_flg_cit_type             IN pat_cit.flg_cit_type%TYPE,
        i_flg_prognosis_type       IN pat_cit.flg_prognosis_type%TYPE,
        i_flg_permanent_disability IN pat_cit.flg_permanent_disability%TYPE,
        i_flg_life_danger          IN pat_cit.flg_life_danger%TYPE,
        i_dt_start_period_tstz     IN VARCHAR2,
        i_dt_end_period_tstz       IN VARCHAR2,
        i_dt_event_tstz            IN VARCHAR2,
        i_dt_stop_work_tstz        IN VARCHAR2,
        i_id_county_accident       IN pat_cit.id_county_accident%TYPE,
        i_flg_accident_type        IN pat_cit.flg_accident_type%TYPE,
        i_landline_prefix          IN pat_cit.landline_prefix%TYPE,
        i_landline_number          IN pat_cit.landline_number%TYPE,
        i_mobile_prefix            IN pat_cit.mobile_prefix%TYPE,
        i_mobile_number            IN pat_cit.mobile_number%TYPE,
        o_id_pat_cit               OUT pat_cit.id_pat_cit%TYPE,
        o_id_pat_cit_hist          OUT pat_cit_hist.id_pat_cit_hist%TYPE,
        o_error                    OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Função de actualização/criação de CIT  - Sick leave (dependendo da passagem ou não da i_cit)
    *
    * @param IN   i_lang        Language ID
    * @param IN   i_prof        Professional ID
    * @param IN   i_patient     Patient ID
    * @param IN   i_episode     Episode ID
    *
    * @param IN   i_cit                            CIT ID
    * @param IN   i_dt_start_period_tstz           Inicial date (working capacity 0%)
    * @param IN   i_dt_end_period_tstz             End date (working capacity 100%)
    * @param IN   i_flg_work_zero_capac_end        Flg Duration (working capacity 0%) value(D,P,I)
    * @param IN   i_dt_work_zero_capac_end         Duration date (working capacity 0%)
    * @param IN   i_num_work_zero_capac_end        Duration value (working capacity 0%)
    * @param IN   i_num_work_zero_capac_end_unit   Duration unit (working capacity 0%)
    * @param IN   i_num_work_other_percentage      Percentage of intermediate work capacity
    * @param IN   i_dt_work_other_capac_start      Intermediate work capacity start
    * @param IN   i_flg_work_other_capac_end       Flg Duration (intermediate work capacity) value(D,P,I)
    * @param IN   i_dt_work_other_capac_end        Duration date (intermediate working capacity)
    * @param IN   i_num_work_other_capac_end       Duration value (intermediate working capacity)
    * @param IN   i_num_work_other_capac_end_unit  Duration unit (intermediate working capacity)
    * @param IN   i_reason                         Reason       
    * @param IN   i_notes                          Notes       
    * @param IN   i_dt_internment_begin            Internment begin
    * @param IN   i_dt_internment_end              Internment end
    * @param IN   i_dt_treatment_end               Treatmend end
    * @param IN   i_dt_renew                       Renew Date
    *
    * @author                   Jorge Silva
    * @since                    11/12/2012
    ********************************************************************************************/
    FUNCTION set_cit_sick_leave
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        
        i_cit                          IN pat_cit.id_pat_cit%TYPE,
        i_dt_start_period_tstz         IN VARCHAR2,
        i_dt_end_period_tstz           IN VARCHAR2,
        i_flg_work_zero_capac_end      IN pat_cit.flg_zero_capac_end%TYPE,
        i_dt_work_zero_capac_end       IN VARCHAR2,
        i_num_work_zero_capac_end      IN pat_cit.zero_capac_end_num%TYPE,
        i_num_work_zero_capac_end_unit IN pat_cit.zero_capac_end_unit%TYPE,
        i_num_work_other_percentage    IN pat_cit.other_percentage_num%TYPE,
        i_dt_work_other_capac_start    IN VARCHAR2,
        i_flg_work_other_capac_end     IN pat_cit.flg_other_capac%TYPE,
        i_dt_work_other_capac_end      IN VARCHAR2,
        i_num_work_other_capac_end     IN pat_cit.other_capac_end_num%TYPE,
        i_work_other_capac_end_unit    IN pat_cit.other_capac_end_unit%TYPE,
        i_reason                       IN pat_cit.flg_reason%TYPE,
        i_notes                        IN pat_cit.notes_desc%TYPE,
        i_dt_internment_begin          IN VARCHAR2,
        i_dt_internment_end            IN VARCHAR2,
        i_dt_treatment_end             IN VARCHAR2,
        i_dt_renew                     IN VARCHAR2,
        
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Function to update the INAIL state, after the data has been sent and correctly received 
    * by the external system.
    *
    * @param IN   i_lang        Language ID
    * @param IN   i_prof        Professional ID
    * @param IN   i_patient     Patient ID
    * @param IN   i_episode     Episode ID
    * @param IN   i_cit         CIT ID    
    *
    * @param OUT  o_error       Error structure
    *
    * @return                   true on success and false if error occurs                   
    *
    * @author                   Orlando Antunes
    * @since                    11/01/2011
    ********************************************************************************************/
    FUNCTION set_cit_inail_received
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        i_cit     IN pat_cit.id_pat_cit%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION print_cit
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        i_cit     IN pat_cit.id_pat_cit%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION cancel_cit
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_patient          IN patient.id_patient%TYPE,
        i_episode          IN episode.id_episode%TYPE,
        i_cit              IN pat_cit.id_pat_cit%TYPE,
        i_id_cancel_reason IN pat_cit.id_cancel_reason%TYPE,
        i_cancel_notes     IN pat_cit.cancel_notes%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    PROCEDURE set_cit_hist
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_cit             IN pat_cit.id_pat_cit%TYPE,
        o_id_pat_cit_hist OUT pat_cit_hist.id_pat_cit_hist%TYPE
    );

    FUNCTION get_cit_det_social
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_cit     IN pat_cit.id_pat_cit%TYPE,
        o_cit_det OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_cit_det_public
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_cit     IN pat_cit.id_pat_cit%TYPE,
        o_cit_det OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Função que retorna detalhe do CIT seleccionado - Sick leave
    *
    * @param IN   i_lang        Language ID
    * @param IN   i_prof        Professional ID
    * @param IN   i_patient     Patient ID
    * @param IN   i_history     Boolean que indica se queremos que devolve o histórico 
    * @param OUT  o_cits        CIT list cursor   
    * @param OUT  o_error       Error structure
    *
    * @return    Boolean
    *
    * @author                   Jorge Silva
    * @since                    13-12-2012
    ********************************************************************************************/
    FUNCTION get_cit_det_sick_leave
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_cit     IN pat_cit.id_pat_cit%TYPE,
        i_history IN BOOLEAN,
        o_cit_det OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_cit_message_array
    (
        i_lang         IN language.id_language%TYPE,
        i_code_msg_arr IN table_varchar,
        o_desc_msg_arr OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * This function validates if it is possible to edit a given CI. The only information needed to
    * perform this validation is the episode ID in which the CI was created, to check if the 
    * patient was discharged from the episode or not.
    *
    * @param IN   i_lang        Language ID
    * @param IN   i_prof        Professional ID
    * @param IN   i_id_episode  Episode ID
    *
    * @return                   Y if the CIT can be edited or N otherwise
    *
    * @author                   Orlando Antunes
    * @since                    06/01/2011
    ********************************************************************************************/
    FUNCTION get_cit_edit_mode
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2;

    /**
    * Prints existing INAIL typed CIs.
    * To be called on medical discharges.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_episode      episode identifier
    * @param i_patient      patient identifier
    *
    * @author               Pedro Carneiro
    * @version               2.6.1
    * @since                2012/06/20
    */
    PROCEDURE print_inail
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE
    );

    /********************************************************************************************
    * Função de registo que a CIT foi concluída - Seack Leave
    *
    * @param IN   i_lang        Language ID
    * @param IN   i_prof        Professional ID
    * @param IN   i_patient     Patient ID
    * @param IN   i_episode     Episode ID
    * @param IN   i_cit         CIT identifier
    *
    * @param OUT  o_error       Error structure
    *
    * @author                   Jorge Silva
    * @since                    12/12/2012
    ********************************************************************************************/
    FUNCTION conclude_cit
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        i_cit     IN pat_cit.id_pat_cit%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Actualizar o estado do cit - Seack Leave
    *
    * @param IN   i_lang        Language ID
    * @param IN   i_prof        Professional ID
    * @param IN   i_patient     Patient ID
    * @param IN   i_episode     Episode ID
    *
    * @author                   Jorge Silva
    * @since                    14/12/2012
    ********************************************************************************************/
    PROCEDURE update_status_cit_int
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE
    );

    /********************************************************************************************
    * Returns a description with all the relevant info of the sick leave certificate
    *
    * @param IN   i_lang        Language ID
    * @param IN   i_prof        Professional ID
    * @param IN   i_cit         CIT ID
    * @param   i_use_html_format Use HTML tags to format output. Default: No
    *
    * @return    cits detailed description
    *
    * @author                   Sofia Mendes
    * @since                    10-Jul-2013
    ********************************************************************************************/
    FUNCTION get_cit_det_description
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_cit             IN pat_cit.id_pat_cit%TYPE,
        i_use_html_format IN VARCHAR2 DEFAULT pk_alert_constant.g_no
    ) RETURN CLOB;

    /********************************************************************************************
    * Returns a description with sick leave certificate info: cit desctiption, start and end date
    *
    * @param IN   i_lang        Language ID
    * @param IN   i_prof        Professional ID
    * @param IN   i_cit         CIT ID
    *
    * @return    cits detailed description
    *
    * @author                   Sofia Mendes
    * @since                    15-Jul-2013
    ********************************************************************************************/
    FUNCTION get_cit_short_desc
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_cit  IN pat_cit.id_pat_cit%TYPE
    ) RETURN CLOB;

    /********************************************************************************************
    * Return the detailed descriptions of all the CITS of the patient, except the cancelled ones.
    *
    * @param IN   i_lang         Language ID
    * @param IN   i_prof         Professional ID
    * @param IN   i_patient      Patient ID
    * @param IN   i_id_episode   Episode ID
    * @param IN   i_excluded_status Status to be excluded
    * @param   i_use_html_format Use HTML tags to format output. Default: No
    * @param OUT  o_cit_desc      CIT list descriptions   
    * @param OUT  o_cit_title     CIT type description
    * @param OUT  o_error       Error structure
    *
    * @return    Boolean
    *
    * @author                   Sofia Mendes
    * @since                    10-Jul-2013
    ********************************************************************************************/
    FUNCTION get_cits_by_patient
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_patient      IN patient.id_patient%TYPE,
        i_id_episode      IN episode.id_episode%TYPE,
        i_excluded_status IN table_varchar,
        i_use_html_format IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        o_cit_desc        OUT table_varchar,
        o_cit_title       OUT table_varchar,
        o_signature       OUT table_varchar,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Return a set of id previous episode.
    *
    * @param IN   i_lang         Language ID
    * @param IN   i_prof         Professional ID
    * @param IN   i_patient      Patient ID
    * @param IN   i_id_episode   Episode ID
    * 
    *
    * @return    table_number
    *
    * @author                   Jorge Silva
    * @since                    27-Ago-2013
    ********************************************************************************************/
    FUNCTION get_prev_pat_episode
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_pat     IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE
    ) RETURN table_number;

    /********************************************************************************************
    * Return if a create button is active
    *
    * @param IN   i_lang         Language ID
    * @param IN   i_prof         Professional ID
    * @param IN   i_patient      Patient ID
    * @param IN   i_id_episode   Episode ID
    * 
    *
    * @return    table_number
    *
    * @author                   Jorge Silva
    * @since                    24-10-2013
    ********************************************************************************************/
    FUNCTION get_create_permission
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_pat     IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        o_create  OUT VARCHAR2,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Return a list of reason
    *
    * @param IN   i_lang         Language ID
    * @param IN   i_prof         Professional ID
    * @param IN   i_patient      Patient ID
    * @param IN   i_id_episode   Episode ID
    * 
    *
    * @return    table_number
    *
    * @author                   Jorge Silva
    * @since                    24-10-2013
    ********************************************************************************************/
    FUNCTION get_reasons_list
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_pat     IN patient.id_patient%TYPE,
        i_pat_cit IN pat_cit.id_pat_cit%TYPE,
        o_reasons OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    TYPE t_rec_cit_info IS RECORD(
        desc_val VARCHAR2(200),
        val      VARCHAR2(30),
        img_name VARCHAR2(200),
        rank     NUMBER(6));

    TYPE t_coll_cit_info IS TABLE OF t_rec_cit_info;

    /********************************************************************************************
    * Return a table function list of reason
    *
    * @param IN   i_lang         Language ID
    * @param IN   i_prof         Professional ID
    * @param IN   i_patient      Patient ID
    * @param IN   i_id_episode   Episode ID
    * 
    *
    * @return    table_number
    *
    * @author                   Jorge Silva
    * @since                    24-10-2013
    ********************************************************************************************/
    FUNCTION tf_reasons_list
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_pat     IN patient.id_patient%TYPE,
        i_pat_cit IN pat_cit.id_pat_cit%TYPE
    ) RETURN t_coll_cit_info DETERMINISTIC
        PIPELINED;

    ---------------------------------------- GLOBAL VALUES ----------------------------------------------
    g_cit_report_domain CONSTANT sys_domain.code_domain%TYPE := 'PAT_CIT.FLG_STATUS';

    -- flg definition for sys_domain
    g_cit_flg_status              CONSTANT sys_domain.code_domain%TYPE := 'PAT_CIT.FLG_STATUS';
    g_cit_flg_type                CONSTANT sys_domain.code_domain%TYPE := 'PAT_CIT.FLG_TYPE';
    g_cit_flg_pat_disease_state   CONSTANT sys_domain.code_domain%TYPE := 'PAT_CIT.FLG_PAT_DISEASE_STATE';
    g_cit_flg_cit_ss              CONSTANT sys_domain.code_domain%TYPE := 'PAT_CIT.FLG_CIT_CLASSIFICATION_SS';
    g_cit_flg_cit_fp              CONSTANT sys_domain.code_domain%TYPE := 'PAT_CIT.FLG_CIT_CLASSIFICATION_FP';
    g_cit_flg_internment          CONSTANT sys_domain.code_domain%TYPE := 'PAT_CIT.FLG_INTERNMENT';
    g_cit_flg_incapacity_period   CONSTANT sys_domain.code_domain%TYPE := 'PAT_CIT.FLG_INCAPACITY_PERIOD';
    g_cit_flg_prof_health_subsys  CONSTANT sys_domain.code_domain%TYPE := 'PAT_CIT.FLG_PROF_HEALTH_SUBSYS';
    g_cit_flg_benef_health_subsys CONSTANT sys_domain.code_domain%TYPE := 'PAT_CIT.FLG_BENEF_HEALTH_SUBSYS';
    g_cit_flg_home_absence        CONSTANT sys_domain.code_domain%TYPE := 'PAT_CIT.FLG_HOME_ABSENCE';
    g_cit_flg_ill_affinity        CONSTANT sys_domain.code_domain%TYPE := 'PAT_CIT.FLG_ILL_AFFINITY';
    g_cit_flg_reason              CONSTANT sys_domain.code_domain%TYPE := 'PAT_CIT.REASON';
    g_cit_flg_without_period      CONSTANT sys_domain.code_domain%TYPE := 'PAT_CIT.TIME_WITHOUT_PERIOD';
    g_cit_flg_with_period         CONSTANT sys_domain.code_domain%TYPE := 'PAT_CIT.TIME_WITH_PERIOD';

    g_cit_action    CONSTANT action.internal_name%TYPE := 'CIT_ACTION';
    g_cit_renew     CONSTANT action.internal_name%TYPE := 'CIT_RENEW';
    g_cit_concluded CONSTANT action.internal_name%TYPE := 'CIT_CONCLUDED';
    g_cit_canceled  CONSTANT action.internal_name%TYPE := 'CIT_CANCELED';
    g_cit_edit      CONSTANT action.internal_name%TYPE := 'CIT_EDIT';

    -- definitions for FLG_STATUS: 'P'-Impresso, 'I'-Construção, 'O'-OnGoing, 'F'-Concluded, 'E'-Edited, 'C'-Cancelado, 'X'-Expired,  'R'-Renew
    g_flg_status_printed      CONSTANT pat_cit.flg_status%TYPE := 'P';
    g_flg_status_construction CONSTANT pat_cit.flg_status%TYPE := 'I';
    g_flg_status_ongoing      CONSTANT pat_cit.flg_status%TYPE := 'O';
    g_flg_status_concluded    CONSTANT pat_cit.flg_status%TYPE := 'F';
    g_flg_status_edited       CONSTANT pat_cit.flg_status%TYPE := 'E';
    g_flg_status_expired      CONSTANT pat_cit.flg_status%TYPE := 'X';
    g_flg_status_canceled     CONSTANT pat_cit.flg_status%TYPE := 'C';
    g_flg_status_renew        CONSTANT pat_cit.flg_status%TYPE := 'R';

    -- definitions for FLG_TYPE: 'S'-Segurança social, 'P'-Função pública
    g_flg_type_social     CONSTANT pat_cit.flg_type%TYPE := 'S';
    g_flg_type_public     CONSTANT pat_cit.flg_type%TYPE := 'P';
    g_flg_type_sick_leave CONSTANT pat_cit.flg_type%TYPE := 'M';
    g_flg_type_inail      CONSTANT pat_cit.flg_type%TYPE := 'I';

    --inail_edit_mode configuration
    g_ci_inail_edit_mode_a CONSTANT sys_domain.val%TYPE := 'A';
    g_ci_inail_edit_mode_n CONSTANT sys_domain.val%TYPE := 'N';
    g_ci_inail_edit_mode_d CONSTANT sys_domain.val%TYPE := 'D';

    g_capacity_indefinite CONSTANT sys_domain.val%TYPE := 'I';
    g_capacity_date       CONSTANT sys_domain.val%TYPE := 'D';
    g_capacity_periode    CONSTANT sys_domain.val%TYPE := 'P';

END pk_cit;
/