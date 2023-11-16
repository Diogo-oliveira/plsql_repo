/*-- Last Change Revision: $Rev: 1983029 $*/
/*-- Last Change by: $Author: diogo.oliveira $*/
/*-- Date of last change: $Date: 2021-03-16 11:56:31 +0000 (ter, 16 mar 2021) $*/

CREATE OR REPLACE PACKAGE pk_ref_list IS

    --  type returned by function get_clinical_institution
    TYPE t_rec_ref_institution IS RECORD(
        id_institution        institution.id_institution%TYPE,
        abbreviation          institution.abbreviation%TYPE,
        desc_institution      pk_translation.t_desc_translation,
        ext_code              institution.ext_code%TYPE,
        flg_default           p1_dest_institution.flg_default%TYPE,
        help_count            p1_spec_help.id_spec_help%TYPE,
        date_field            VARCHAR2(50 CHAR),
        ref_line              sys_domain.desc_val%TYPE,
        type_ins              sys_domain.desc_val%TYPE,
        inside_ref_area       sys_domain.desc_val%TYPE,
        flg_ref_line          ref_dest_institution_spec.flg_ref_line%TYPE,
        flg_type_ins          p1_dest_institution.flg_type_ins%TYPE,
        flg_inside_ref_area   ref_dest_institution_spec.flg_inside_ref_area%TYPE,
        icon                  sys_config.value%TYPE,
        desc_day              sys_message.desc_message%TYPE,
        desc_days             sys_message.desc_message%TYPE,
        dt_server             VARCHAR2(50 CHAR),
        wait_days             NUMBER,
        id_speciality         p1_speciality.id_speciality%TYPE,
        desc_speciality       pk_translation.t_desc_translation,
        id_inst_orig          institution.id_institution%TYPE,
        orig_ext_code         institution.ext_code%TYPE,
        desc_orig_institution pk_translation.t_desc_translation);

    TYPE t_coll_ref_institution IS TABLE OF t_rec_ref_institution;
    TYPE t_cur_ref_institution IS REF CURSOR RETURN t_rec_ref_institution;

    --  type returned by function get_net_spec
    TYPE t_rec_ref_spec IS RECORD(
        id_speciality p1_speciality.id_speciality%TYPE,
        desc_cls_srv  pk_translation.t_desc_translation,
        flg_type      p1_dest_institution.flg_type%TYPE);

    TYPE t_coll_ref_spec IS TABLE OF t_rec_ref_spec;
    TYPE t_cur_ref_spec IS REF CURSOR RETURN t_rec_ref_spec;

    --  type returned by function get_net_clin_serv and get_internal_spec
    TYPE t_rec_ref_dcs IS RECORD(
        id_dep_clin_serv    dep_clin_serv.id_dep_clin_serv%TYPE,
        id_clinical_service clinical_service.id_clinical_service%TYPE,
        desc_cls_srv        pk_translation.t_desc_translation,
        flg_default_dcs     p1_spec_dep_clin_serv.flg_default%TYPE);

    TYPE t_coll_ref_dcs IS TABLE OF t_rec_ref_dcs;
    TYPE t_cur_ref_dcs IS REF CURSOR RETURN t_rec_ref_dcs;

    --  type returned by function get_handoff_detail_orig
    TYPE t_rec_handoff_orig IS RECORD(
        id_workflow       ref_trans_responsibility.id_workflow%TYPE,
        inst_orig_tr_desc pk_translation.t_desc_translation,
        prof_ref_owner    VARCHAR2(1000 CHAR),
        id_prof_dest      ref_trans_responsibility.id_prof_dest%TYPE,
        hand_off_to       VARCHAR2(1000 CHAR),
        reason_desc       pk_translation.t_desc_translation,
        notes             ref_trans_responsibility.notes%TYPE,
        dt_status         VARCHAR2(1000 CHAR),
        prof_status       VARCHAR2(1000 CHAR));

    TYPE t_coll_handoff_orig IS TABLE OF t_rec_handoff_orig;
    TYPE t_cur_handoff_orig IS REF CURSOR RETURN t_rec_handoff_orig;

    --  type returned by function get_handoff_detail_dest
    TYPE t_rec_handoff_dest IS RECORD(
        id_workflow    ref_trans_responsibility.id_workflow%TYPE,
        desc_status    pk_translation.t_desc_translation,
        prof_name_dest VARCHAR2(1000 CHAR),
        id_prof_dest   ref_trans_responsibility.id_prof_dest%TYPE,
        notes          ref_trans_responsibility.notes%TYPE,
        dt_status      VARCHAR2(1000 CHAR),
        prof_status    VARCHAR2(1000 CHAR));

    TYPE t_coll_handoff_dest IS TABLE OF t_rec_handoff_dest;
    TYPE t_cur_handoff_dest IS REF CURSOR RETURN t_rec_handoff_dest;

    --  type returned by function get_net_inst_orig
    TYPE t_rec_ref_net_inst_orig IS RECORD(
        id_inst_orig   institution.id_institution%TYPE,
        orig_inst_desc pk_translation.t_desc_translation,
        ext_code       institution.ext_code%TYPE);

    TYPE t_coll_ref_net_inst_orig IS TABLE OF t_rec_ref_net_inst_orig;
    TYPE t_cur_ref_net_inst_orig IS REF CURSOR RETURN t_rec_ref_net_inst_orig;

    --  type returned by function get_handoff_inst
    TYPE t_rec_ref_handoff_inst IS RECORD(
        id_institution   institution.id_institution%TYPE,
        institution_name pk_translation.t_desc_translation,
        inst_type_desc   sys_domain.desc_val%TYPE,
        flg_select       VARCHAR2(1 CHAR),
        flg_has_child    VARCHAR2(1 CHAR));

    TYPE t_coll_ref_handoff_inst IS TABLE OF t_rec_ref_handoff_inst;
    TYPE t_cur_ref_handoff_inst IS REF CURSOR RETURN t_rec_ref_handoff_inst;

    /**
    * Gets referral detail
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Professional, institution and software ids
    * @param   i_prof_data      Professional data
    * @param   i_ref_row        Referral data
    * @param   i_view_clin_data Flag indicating if professional can view clinical data
    * @param   o_mcdt           MCDTs information   
    * @param   o_error          An error message, set when return=false
    *
    * @value   i_view_clin_data {*} Y- can view clinical data {*} N- otherwise
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   02-10-2012
    */
    FUNCTION get_referral_detail
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_prof_data      IN t_rec_prof_data,
        i_ref_row        IN p1_external_request%ROWTYPE,
        i_view_clin_data IN VARCHAR2,
        --o_detail         OUT pk_types.cursor_type,
        o_detail OUT pk_ref_core.row_detail_cur,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets referral detail short
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Professional, institution and software ids
    * @param   i_prof_data      Professional data
    * @param   i_ref_row        Referral row data
    * @param   o_ref_data       Referral short detail data   
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   23-01-2013
    */
    FUNCTION get_referral_detail_short
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_prof_data IN t_rec_prof_data,
        i_ref_row   IN p1_external_request%ROWTYPE,
        i_param     IN table_varchar DEFAULT table_varchar(),
        o_ref_data  OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get Referral short detail 
    *
    * @param   i_lang                        Language associated to the professional executing the request
    * @param   i_prof                        Professional, institution and software ids
    * @param   i_id_external_request         Referral identifier 
    * @param   o_detail                      Referral details
    * @param   o_error                       An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   29-06-2010 
    */
    FUNCTION get_ref_detail
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_external_request IN table_number,
        o_detail              OUT pk_ref_core.ref_detail_cur,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets referral mcdt detail
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Professional, institution and software ids
    * @param   i_id_ref         Referral identifier
    * @param   i_ref_type       Referral type
    * @param   o_mcdt           MCDTs information   
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   28-09-2012
    */
    FUNCTION get_referral_mcdt
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_ref   IN p1_external_request.id_external_request%TYPE,
        i_ref_type IN p1_external_request.flg_type%TYPE,
        o_mcdt     OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets referral diagnosis data
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Professional, institution and software ids
    * @param   i_id_ref         Referral identifier
    * @param   i_flg_type       Diagnosis type    
    * @param   o_diagnosis      Referral diagnosis data   
    * @param   o_error          An error message, set when return=false
    *
    * @value   i_flg_type       {*} P- problems {*} D- diagnosis
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   02-10-2012
    */
    FUNCTION get_referral_diagnosis
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_ref    IN p1_external_request.id_external_request%TYPE,
        i_flg_type  IN p1_exr_diagnosis.flg_type%TYPE,
        o_diagnosis OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets the answer given by the consultation physician to the referral
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Professional, institution and software ids
    * @param   i_id_ref         Referral identifier    
    * @param   o_answer         Referral answer data   
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   02-10-2012
    */
    FUNCTION get_referral_answer
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_id_ref IN p1_external_request.id_external_request%TYPE,
        o_answer OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets referral tasks data
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Professional, institution and software ids
    * @param   i_id_ref         Referral identifier    
    * @param   i_flg_type       Referral type of task
    * @param   i_flg_status     Tasks status to retrieve
    * @param   o_task_done      Referral tasks data
    * @param   o_error          An error message, set when return=false
    *
    * @value   i_flg_type       {*} S- To schedule {*} C- To Consultation
    * @value   i_flg_status     {*} A- active {*} O- outdated {*} C- canceled
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   02-10-2012
    */
    FUNCTION get_referral_taskdone
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_ref     IN p1_external_request.id_external_request%TYPE,
        i_flg_type   IN VARCHAR2,
        i_flg_status IN VARCHAR2 DEFAULT NULL,
        o_task_done  OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets referral several details
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Professional, institution and software ids
    * @param   i_id_ref         Referral identifier    
    * @param   i_view_clin_data Flag indicating if professional can view clinical data
    * @param   i_flg_status     Tasks status to retrieve
    * @param   o_text           Referral details data
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   02-10-2012
    */
    FUNCTION get_referral_text
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_ref         IN p1_external_request.id_external_request%TYPE,
        i_view_clin_data IN VARCHAR2,
        i_flg_status     IN VARCHAR2 DEFAULT NULL,
        o_text           OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets referral patient data (to be shown in referral detail)
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Professional, institution and software ids
    * @param   i_id_patient     Referral patient identifier    
    * @param   i_id_inst_orig   Referral orig institution identifier
    * @param   o_patient        Referral patient data
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   24-05-2013
    */
    FUNCTION get_referral_patient
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_patient   IN p1_external_request.id_patient%TYPE,
        i_id_inst_orig IN p1_external_request.id_inst_orig%TYPE,
        o_patient      OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets referral orig data (used in 'at hospital entrance' workflow)
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Professional, institution and software ids
    * @param   i_id_ref         Referral identifier
    * @param   o_error          An error message, set when return=false
    *
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   26-06-2014
    */
    FUNCTION get_referral_orig_data
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_ref        IN p1_external_request.id_external_request%TYPE,
        o_ref_orig_data OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets referral comments (to be shown in referral detail)
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Professional, institution and software ids
    * @param   i_prof_data      Profile_template, functionality, category, flg_category and id_market  
    * @param   i_id_ref         Referral Id
    * @param   o_ref_comments   Referral comments data
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   02-07-2013
    */

    FUNCTION get_ref_comments
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_prof_data    IN t_rec_prof_data,
        i_ref_row      IN p1_external_request%ROWTYPE,
        o_ref_comments OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets referral field ranks (to order in flash and reports)
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Professional, institution and software ids
    * @param   i_id_ref         Referral identifier
    * @param   o_error          An error message, set when return=false
    *
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   27-06-2014
    */
    FUNCTION get_fields_rank
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        o_fields_rank OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get reason codes list
    *
    * @param   I_LANG         Language associated to the professional executing the request
    * @param   I_PROF         Professional, institution and software ids
    * @param   I_TYPE         Reason list type. {*} C - Cancelation; {*}  D - Medical Decline; {*}  R - Medical Refusal;
                                                {*} B - Administrative Decline; {*} T- transf. Resp.; {*} TR - transf resp decline
                                                {*} X - registrar cancellation/request cancellation.
    * @param   O_REASONS      Reasons data
    * @param   O_ERROR        An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Sa
    * @version 1.0
    * @since   17-10-2007
    */
    FUNCTION get_reason_list
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_type    IN p1_reason_code.flg_type%TYPE,
        i_mcdt    IN VARCHAR2 DEFAULT 'N',
        o_reasons OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_cancel_reason_list
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_mcdt    IN VARCHAR2 DEFAULT 'N',
        o_reasons OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns the options for the professional.
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Professional, institution and software ids
    * @param   i_id_ext_req     Referral id
    * @param   i_dt_modified    Last modified date as provided by get_referral
    * @param   o_status         Options list
    * @param   o_flg_show       Show message
    * @param   o_msg_title      Message title
    * @param   o_msg            Message text
    * @param   o_button         Type of button to show with message
    * @param   o_error          An error message, set when return=false
    *
    * @value   o_flg_show       {*} 'Y' - show message {*} 'N' - do not show message
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Luis Gaspar
    * @version 1.0
    * @since   25-10-2006
    */
    FUNCTION get_status_options
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_ext_req  IN p1_external_request.id_external_request%TYPE,
        i_dt_modified IN VARCHAR2,
        o_status      OUT pk_types.cursor_type,
        o_flg_show    OUT VARCHAR2,
        o_msg_title   OUT VARCHAR2,
        o_msg         OUT VARCHAR2,
        o_button      OUT VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get Referral list
    *
    * @param   I_LANG          Language associated to the professional executing the request
    * @param   I_PROF          Professional id, institution and software
    * @param   i_patient       Patient id. Null for all patients
    * @param   i_filter        Filter to apply. Depends on button selected.     
    * @param   i_type          Referral type
    * @param   o_ref_list      Referral data    
    * @param   o_error         An error message, set when return=false
    *
    * @value   i_type          {*} (C)onsultation {*} (A)nalysis {*} (I)mage {*} (E)xam  
    *                          {*} (P)rocedure {*} (M)fr {*} Null for all types
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   02-07-2009
    */
    FUNCTION get_referral_list
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN patient.id_patient%TYPE,
        i_filter   IN VARCHAR2,
        i_type     IN p1_external_request.flg_type%TYPE,
        o_ref_list OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get referral types: appointment, analysis, exam or intervention
    *
    * @param   I_LANG language associated to the professional executing the request
    * @param   O_TYPE avaible request types on REFERAL
    * @param   O_ERROR an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    *
    * @author  Joana Barroso
    * @version 2.4.3
    * @since   2008/02/11
    */
    FUNCTION get_referral_type
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_type  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get referal types: Internal or external
    *
    * @param   I_LANG language associated to the professional executing the request
    * @param   O_TYPE_ext avaible external REFERAL
    * @param   O_TYPE_int avaible REFERAL
    * @param   O_ERROR an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    *
    * @author  Joana Barroso
    * @version 2.5.0.6
    * @since   2009/08/17
    */
    FUNCTION get_referral_type
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        o_type_ext OUT pk_types.cursor_type,
        o_type_int OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get patient social attributes
    * Used by QueryFlashService.
    * @param   i_lang language associated to the professional executing the request
    * @param   i_id_pat Patient id
    * @param   i_prof professional, institution and software ids
    * @param   o_pat patient attributes
    * @param   o_sns "Sistema Nacional de Saude" data
    * @param   o_seq_num external system id for this patient (available if has match)    
    * @param   o_photo url for patient photo    
    * @param   o_id patient id document data (number, expiration date, etc)  
    * @param   O_ERROR an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Sa
    * @version 1.0
    * @since   19-10-2006
    */
    FUNCTION get_pat_soc_att
    (
        i_lang    IN language.id_language%TYPE,
        i_id_pat  IN patient.id_patient%TYPE,
        i_prof    IN profissional,
        o_pat     OUT pk_types.cursor_type,
        o_sns     OUT pk_types.cursor_type,
        o_seq_num OUT p1_match.sequential_number%TYPE,
        o_photo   OUT VARCHAR2,
        o_id      OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get country attributes
    * Used by QueryFlashService.java
    * @param   i_lang language associated to the professional executing the request
    * @param   i_prof professional, institution and software ids
    * @param   i_country country id
    * @param   o_country cursor
    * @param   o_error an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Sa
    * @version 1.0
    * @since   12-02-2008
    */
    FUNCTION get_country_data
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_country IN country.id_country%TYPE,
        o_country OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Return available tasks
    *
    * @param   i_lang language
    * @param   i_type task type. For (S)cheduling or (C)onsultation
    * @param   o_tasks returned tasks for type S
    * @param   o_info returned tasks for type C
    * @param   o_error error
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Jo∆o S†
    * @version 1.0
    * @since
    */
    FUNCTION get_tasks
    (
        i_lang  IN language.id_language%TYPE,
        i_type  IN VARCHAR2,
        o_tasks OUT pk_types.cursor_type,
        o_info  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets the clinical services that have at least one professional associated
    *
    * @param   I_LANG language associated to the professional executing the request
    * @param   I_PROF professional, institution and software ids
    * @param   o_clin_serv       Clinical services data
    * @param   O_ERROR an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Filipe Sousa
    * @version 1.0
    * @since   09-09-2010 
    */
    FUNCTION get_clin_serv
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        o_clin_serv OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets the professionals related to this clinical service
    *
    * @param   i_lang                Language associated to the professional executing the request
    * @param   i_prof                Professional, institution and software ids
    * @param   i_id_clinical_service Clinical service identifier 
    * @param   i_id_prof_except_tab  Array of professional identifiers that must not be returned (exceptions)
    * @param   o_prof                Professional data
    * @param   o_error               An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Filipe Sousa
    * @version 1.0
    * @since   09-09-2010 
    */
    FUNCTION get_prof_for_clin_serv
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_clinical_service IN clinical_service.id_clinical_service%TYPE,
        i_id_prof_except_tab  IN table_number,
        o_prof                OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets field 'Cobertura' 
    * This function will be rebuild or removed in the future.
    *
    * @param   i_lang     Language identifier
    * @param   i_prof     Professional, institution and software ids     
    * @param   o_value    Values to populate multichoice
    * @param   o_error    An error message, set when return=false 
    *    
    * @RETURN  Referral schedule identifier associated
    * @author  Ana Monteiro
    * @version 1.0
    * @since   28-10-2010
    */
    FUNCTION get_cover
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_value OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Return referral depatments (just for internal referrals!!)
    *
    * @param   I_LANG           Language associated to the professional executing the request
    * @param   I_PROF           Professional, institution and software ids 
    * @param   I_PAT           Patient id
    * @param   i_external_sys   External system identifier
    * @param   O_DEP            Department info    
    * @param   O_ERROR          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   01-07-2009 
    */
    FUNCTION get_internal_dep
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_pat          IN patient.id_patient%TYPE,
        i_external_sys IN external_sys.id_external_sys%TYPE,
        o_dep          OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Return referral clinical services (just for internal referrals)
    *
    * @param   I_LANG           Language associated to the professional executing the request
    * @param   i_prof           Id professional, institution and software from the Interface 
    * @param   i_pat            Patient id, to filter by gender and age
    * @param   i_external_sys   External system identifier
    * @param   O_CS             Clinical Service info    
    * @param   O_ERROR          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   01-07-2009 
    */

    FUNCTION get_internal_spec
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_pat          IN patient.id_patient%TYPE,
        i_dep          IN department.id_department%TYPE,
        i_external_sys IN external_sys.id_external_sys%TYPE,
        o_cs           OUT t_cur_ref_dcs,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Return referral clinical services (just for internal referrals)
    *
    * @param   i_lang              Language associated to the professional executing the request
    * @param   i_prof              Id professional, institution and software from the Interface 
    * @param   i_pat_age           Patient age
    * @param   i_pat_gender        Patient gender
    * @param   i_external_sys      External system identifier
    * @param   o_cs                Clinical Service info    
    * @param   o_error             An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   24-05-2013
    */
    FUNCTION get_internal_spec
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_dep          IN department.id_department%TYPE,
        i_pat_age      IN patient.age%TYPE,
        i_pat_gender   IN patient.gender%TYPE,
        i_external_sys IN external_sys.id_external_sys%TYPE,
        o_cs           OUT t_cur_ref_dcs,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Referral network: get available specialities for referring
    *
    * @param   I_LANG            language associated to the professional executing the request
    * @param   I_PROF            professional, institution and software ids
    * @param   i_pat             Patient identifier, to filter by gender and age   
    * @param   i_ref_type        Referral type   
    * @param   i_external_sys    External system identifier
    * @param   O_SQL             specialities INFO
    * @param   O_ERROR           An error message, set when return=false
    *
    * @value   i_ref_type        {*} 'E' external {*} 'P' at hospital entrance
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   02-07-2009
    */
    FUNCTION get_net_spec
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_pat          IN patient.id_patient%TYPE,
        i_ref_type     IN p1_spec_dep_clin_serv.flg_availability%TYPE,
        i_external_sys IN external_sys.id_external_sys%TYPE,
        o_sql          OUT t_cur_ref_spec,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Referral network: get available specialities for referring
    *
    * @param   i_lang            Language associated to the professional executing the request
    * @param   i_prof            Professional, institution and software ids
    * @param   i_pat_gender      Patient gender   
    * @param   i_pat_age         Patient age
    * @param   i_ref_type        Referral type   
    * @param   i_external_sys    External system identifier
    * @param   o_sql             specialities INFO
    * @param   o_error           An error message, set when return=false
    *
    * @value   i_ref_type        {*} 'E' external {*} 'P' at hospital entrance
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   02-07-2009
    */
    FUNCTION get_net_spec
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_pat_gender   IN patient.gender%TYPE,
        i_pat_age      IN patient.age%TYPE,
        i_ref_type     IN p1_spec_dep_clin_serv.flg_availability%TYPE,
        i_external_sys IN external_sys.id_external_sys%TYPE,
        o_sql          OUT t_cur_ref_spec,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Referral network: get available institutions for the selected referral speciality
    *
    * @param   i_lang                   Language associated to the professional executing the request
    * @param   i_prof                   Professional, institution and software ids
    * @param   i_ref_type               Referral type
    * @param   i_external_sys           External system that created the referral   
    * @param   i_id_speciality          Referral speciality identifier
    * @param   i_flg_ref_line           Referral line 1,2,3
    * @param   i_flg_type_ins           Referral network to which it belongs
    * @param   i_flg_inside_ref_area    Flag indicating if is inside referral area or not
    * @param   i_flg_type               Referral type
    * @param   o_sql                    Clinical institutions data
    * @param   o_error                  An error message, set when return=false
    *
    * @value   i_ref_type               {*} 'E' external
    * @value   i_flg_inside_ref_area    {*} 'Y' - inside ref area {*} 'N' - otherwise   
    * @value   i_flg_type               {*} 'C' - Appointments {*} 'A' - Lab tests {*} 'I' - Imaging exams 
    *                                   {*} 'E' - Other exams {*} 'P' - Procedures 
    *                                   {*} 'F' - Physical Medicine and Rehabilitation    
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   15-05-2013
    */
    FUNCTION get_net_inst
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_ref_type            IN p1_spec_dep_clin_serv.flg_availability%TYPE,
        i_external_sys        IN external_sys.id_external_sys%TYPE,
        i_id_speciality       IN p1_speciality.id_speciality%TYPE,
        i_flg_ref_line        IN ref_dest_institution_spec.flg_ref_line%TYPE DEFAULT NULL,
        i_flg_type_ins        IN p1_dest_institution.flg_type_ins%TYPE DEFAULT NULL,
        i_flg_inside_ref_area IN ref_dest_institution_spec.flg_inside_ref_area%TYPE DEFAULT NULL,
        i_flg_type            IN p1_dest_institution.flg_type%TYPE,
        o_sql                 OUT NOCOPY t_cur_ref_institution,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Referral network: get available institutions for the selected referral speciality
    *
    * @param   i_lang                   Language associated to the professional executing the request
    * @param   i_prof                   Professional, institution and software ids
    * @param   i_ref_type               Referral type
    * @param   i_external_sys           External system that created the referral   
    * @param   i_id_speciality          Referral speciality identifier
    * @param   i_flg_ref_line           Referral line 1,2,3
    * @param   i_flg_type_ins           Referral network to which it belongs
    * @param   i_flg_inside_ref_area    Flag indicating if is inside referral area or not
    * @param   i_flg_type               Referral type
    * @param   o_sql                    Clinical institutions data
    * @param   o_error                  An error message, set when return=false
    *
    * @value   i_ref_type               {*} 'E' external
    * @value   i_flg_inside_ref_area    {*} 'Y' - inside ref area {*} 'N' - otherwise   
    * @value   i_flg_type               {*} 'C' - Appointments {*} 'A' - Lab tests {*} 'I' - Imaging exams 
    *                                   {*} 'E' - Other exams {*} 'P' - Procedures 
    *                                   {*} 'F' - Physical Medicine and Rehabilitation    
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   15-09-2013
    */
    FUNCTION get_net_all_inst
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_ref_type            IN p1_spec_dep_clin_serv.flg_availability%TYPE,
        i_external_sys        IN external_sys.id_external_sys%TYPE,
        i_id_speciality       IN p1_speciality.id_speciality%TYPE,
        i_flg_ref_line        IN ref_dest_institution_spec.flg_ref_line%TYPE DEFAULT NULL,
        i_flg_type_ins        IN p1_dest_institution.flg_type_ins%TYPE DEFAULT NULL,
        i_flg_inside_ref_area IN ref_dest_institution_spec.flg_inside_ref_area%TYPE DEFAULT NULL,
        i_flg_type            IN p1_dest_institution.flg_type%TYPE,
        o_sql                 OUT NOCOPY t_cur_ref_institution,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Referral network: get available clinical services for referring in dest institution
    * Available only for external and at hospital entrance workflows    
    *
    * @param   i_lang            language associated to the professional executing the request
    * @param   i_prof            professional, institution and software ids
    * @param   i_ref_type        Referring type
    * @param   i_p1_spec         Referral speciality identifier
    * @param   i_id_inst_dest    DEst institution identifier   
    * @param   i_external_sys    External system identifier
    * @param   o_sql             Dest clinical services exposed to the origin institution
    * @param   o_error           An error message, set when return=false
    *
    * @value   i_ref_type        {*} 'E' external {*} 'P' at hospital entrance
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   21-09-2012
    */
    FUNCTION get_net_clin_serv
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_ref_type     IN VARCHAR2,
        i_p1_spec      IN p1_speciality.id_speciality%TYPE,
        i_id_inst_dest IN p1_dest_institution.id_inst_dest%TYPE,
        i_external_sys IN external_sys.id_external_sys%TYPE,
        o_sql          OUT t_cur_ref_dcs,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Referral network: gets available origin institutions that can possibly request the referral
    * Available only for at hospital entrance workflows
    * Any changes to this function must be done in filter_name=ReferralOrigInst
    *
    * @param   i_lang             Language associated to the professional executing the request
    * @param   i_prof             Professional, institution and software ids    
    * @param   i_p1_spec          Referral speciality identifier
    * @param   i_id_inst_dest     Dest institution identifier   
    * @param   i_external_sys     External system identifier
    * @param   i_id_dep_clin_serv Department/clinical_service identifier
    * @param   i_flg_type_ref     Referral type being requested
    * @param   o_sql              Orig institutions
    * @param   o_error            An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   05-12-2013
    */
    FUNCTION get_net_inst_orig
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_p1_spec          IN p1_spec_dep_clin_serv.id_speciality%TYPE,
        i_id_inst_dest     IN p1_dest_institution.id_inst_dest%TYPE,
        i_external_sys     IN p1_spec_dep_clin_serv.id_external_sys%TYPE,
        i_id_dep_clin_serv IN p1_spec_dep_clin_serv.id_dep_clin_serv%TYPE,
        i_flg_type_ref     IN p1_dest_institution.flg_type%TYPE,
        o_sql              OUT t_cur_ref_net_inst_orig,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Function used to search for patients
    *
    * @param   i_lang            Language associated to the professional executing the request
    * @param   i_prof            Professional, institution and software ids
    * @param   i_crit_id_tab     List of search criteria identifiers
    * @param   i_crit_val_tab    List of values for the criteria in i_crit_id_tab
    * @param   i_prof_cat_type   Professional category type
    * @param   o_flg_show        Show message (Y/N)
    * @param   o_msg             Message text
    * @param   o_msg_title       Message title
    * @param   o_button          Type of button to show with message
    * @param   o_pat             Patient data
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Sa
    * @version 1.0
    * @since   19-11-2006
    */
    FUNCTION get_search_pat
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_crit_id_tab   IN table_number,
        i_crit_val_tab  IN table_varchar,
        i_prof_cat_type IN category.flg_type%TYPE,
        o_flg_show      OUT VARCHAR2,
        o_msg           OUT VARCHAR2,
        o_msg_title     OUT VARCHAR2,
        o_button        OUT VARCHAR2,
        o_pat           OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Function used to search for referrals
    *
    * @param   i_lang            Language associated to the professional executing the request
    * @param   i_prof            Professional, institution and software ids
    * @param   i_crit_id_tab     List of search criteria identifiers
    * @param   i_crit_val_tab    List of values for the criteria in i_crit_id_tab
    * @param   i_prof_cat_type   Professional category type
    * @param   i_condition       Restriction to be applied
    * @param   o_flg_show        Show message (Y/N)
    * @param   o_msg             Message text
    * @param   o_msg_title       Message title
    * @param   o_button          Type of button to show with message
    * @param   o_pat             Referral data
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Sa
    * @version 2.0
    * @since   27-05-2008
    */
    FUNCTION get_search_ref
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_crit_id_tab   IN table_number,
        i_crit_val_tab  IN table_varchar,
        i_prof_cat_type IN category.flg_type%TYPE,
        o_flg_show      OUT VARCHAR2,
        o_msg           OUT VARCHAR2,
        o_msg_title     OUT VARCHAR2,
        o_button        OUT VARCHAR2,
        o_pat           OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Function used to search for my referrals
    *
    * @param   i_lang            Language associated to the professional executing the request
    * @param   i_prof            Professional, institution and software ids
    * @param   i_crit_id_tab     List of search criteria identifiers
    * @param   i_crit_val_tab    List of values for the criteria in i_crit_id_tab
    * @param   i_prof_cat_type   Professional category type
    * @param   o_flg_show        Show message (Y/N)
    * @param   o_msg             Message text
    * @param   o_msg_title       Message title
    * @param   o_button          Type of button to show with message
    * @param   o_pat             Patient data
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Sa
    * @version 1.0
    * @since   19-11-2006
    */
    FUNCTION get_search_my_ref
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_crit_id_tab   IN table_number,
        i_crit_val_tab  IN table_varchar,
        i_prof_cat_type IN category.flg_type%TYPE,
        o_flg_show      OUT VARCHAR2,
        o_msg           OUT VARCHAR2,
        o_msg_title     OUT VARCHAR2,
        o_button        OUT VARCHAR2,
        o_pat           OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns the priority referral list
    *
    * @param   i_lang      Language associated to the professional executing the request
    * @param   i_prof      Professional, institution and software ids
    * @param   o_list      Priority list   
    * @param   o_error     An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   22-10-2012
    */
    FUNCTION get_priority_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_priority_list
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN t_tbl_core_domain;

    /**
    * Returns the list of types of referral handoff
    *
    * @param   i_lang      Language associated to the professional executing the request
    * @param   i_prof      Professional, institution and software ids
    * @param   i_id_ref_tab     Array of referral identifiers
    * @param   o_list           Types of referral handoff   
    * @param   o_error     An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   18-03-2013
    */
    FUNCTION get_handoff_type
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_ref_tab IN table_number,
        o_list       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns the list of institutions to transfer the referral
    *
    * @param   i_lang                  Language associated to the professional executing the request
    * @param   i_prof                  Professional, institution and software ids
    * @param   i_id_inst_parent        Institution parent identifier
    * @param   i_id_ref_tab            array of referral identifiers
    * @param   o_list_inst             List of institutions to transfer the referral   
    * @param   o_error                 An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   18-03-2013
    */
    FUNCTION get_handoff_inst
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_inst_parent IN institution.id_institution%TYPE,
        i_id_ref_tab     IN table_number,
        o_list_inst      OUT t_cur_ref_handoff_inst,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns hand off data of origin institution
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Professional, institution and software ids
    * @param   i_id_tr_tab      Array of hand off identifiers
    * @param   o_tr_orig_det    Origin information of hand off referral   
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   18-03-2013
    */
    FUNCTION get_handoff_detail_orig
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_tr_tab   IN table_number,
        o_tr_orig_det OUT t_cur_handoff_orig,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns hand off data of dest institution
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Professional, institution and software ids
    * @param   i_prof_data      Professional data
    * @param   i_id_tr_tab      Array of hand off identifiers
    * @param   o_tr_orig_det    Origin information of hand off referral   
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   18-03-2013
    */
    FUNCTION get_handoff_detail_dest
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_prof_data   IN t_rec_prof_data,
        i_id_tr_tab   IN table_number,
        o_tr_dest_det OUT t_cur_handoff_dest,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns the list of transitions available from the action previously selected
    *
    * @param   i_lang                  Language associated to the professional executing the request
    * @param   i_prof                  Professional, institution and software ids
    * @param   i_prof_data             Professional data
    * @param   i_id_action             Action identifier
    * @param   i_id_workflow           Workflow identifier
    * @param   i_id_status_begin       Begin status identifier
    * @param   i_param                 Action identifier
    * @param   i_value_default         Value to be set as default
    * @param   o_transitions           Transition data available
    * @param   o_error                 An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   19-08-2013
    */
    FUNCTION get_trans_from_action
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_prof_data       IN t_rec_prof_data,
        i_id_action       IN wf_action.id_action%TYPE,
        i_id_workflow     IN wf_workflow.id_workflow%TYPE,
        i_id_status_begin IN wf_status.id_status%TYPE,
        i_param           IN table_varchar,
        i_value_default   IN VARCHAR2,
        o_transitions     OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns the professional name that is responsible for the referral 
    * Used by reports
    *
    * @param   i_lang          Language associated to the professional 
    * @param   i_prof          Professional, institution and software ids
    * @param   i_id_ref        Referral identifier
    * @param   o_prof_data     Professional data that is responsible for the referral
    * @param   o_error         An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.5
    * @since   16-04-2010   
    */
    FUNCTION get_prof_resp
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_ref    IN p1_external_request.id_external_request%TYPE,
        o_prof_data OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets field 'Come Back' 
    *
    * @param   i_lang     Language identifier
    * @param   i_prof     Professional, institution and software ids     
    * @param   o_value    Values to populate multichoice
    * @param   o_error    An error message, set when return=false 
    *    
    * @RETURN  Referral schedule identifier associated
    * @author  Joana Barroso
    * @version 1.0
    * @since   10-10-2010
    */
    FUNCTION get_come_back_vals
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_value OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns the rank to order by column of documents attached to the referral
    * Used in grids to sort column of documents attached to the referral
    *
    * @param   i_lang            Language associated to the professional 
    * @param   i_prof            Professional, institution and software ids
    * @param   i_doc_can_receive Can register receipt of the document?
    * @param   i_nr_clinical_doc Number of clinical documents attached to the referral
    * @param   i_flg_sent_by     Document sent by (E)mail; (F)ax; (M)ail
    * @param   i_flg_received    Document received: (Y)es; (N)o.    
    *
    * @value   i_doc_can_receive {*} Y-yes {*} N-no
    * @value   i_flg_sent_by {*} E-Email {*} F-Fax {*} M-Mail
    * @value   i_flg_received {*} Y- yes {*} N- no
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.5
    * @since   08-10-2013
    */
    FUNCTION get_flg_attach_to_sort
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_doc_can_receive IN VARCHAR2,
        i_nr_clinical_doc IN NUMBER,
        i_flg_sent_by     IN VARCHAR2,
        i_flg_received    IN VARCHAR2
    ) RETURN NUMBER;

    FUNCTION get_referral_med_dest_data
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_ref        IN p1_external_request.id_external_request%TYPE,
        o_med_dest_data OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

END pk_ref_list;
/
