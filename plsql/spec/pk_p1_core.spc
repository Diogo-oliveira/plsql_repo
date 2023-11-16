/*-- Last Change Revision: $Rev: 2028831 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:48:12 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_p1_core AS

    /****************************************************************************************
    PROJECT         : ALERT-P1
    PROJECT TEAM    : JOAO SA ( TEAM LEADER, PROJECT ANALYSIS, JAVA MAN ),
                      CARLOS FERREIRA ( PROJECT ANALYSIS, DB MAN ),
                      RUI DIAS ( PROJECT ANALYSIS, FLASH MAN ).
    
    PK CREATED BY   : CARLOS FERREIRA
    PK DATE CREATION: 07-2005
    PK GOAL         : THIS PACKAGE TAKES CARE OF ALL CORE FUNCTIONS, AND FUNCTIONS THAT ARE SHARED BY SEVERAL PROFILES.
    
    NOTES/ OBS      : ---
    ******************************************************************************************/

    /**
    * Updates request status and/or register changes in p1_tracking.
    * Only this function can update the request status.
    *
    * @param i_lang          professional language id
    * @param i_prof          professional, institution and software ids
    * @param i_track_row     p1_tracking rowtype. Includes all data to record the referral change.
    * @param i_old_status    valid status for this update. Single word formed by the letter of valid status.
    * @param o_track         Array of ID_TRACKING transitions
    * @param o_error         an error message, set when return=false
    *
    * @return true if success, false otherwise
    *
    * @author  Joao Sa
    * @version 1.0
    * @since   15-04-2008
    */

    FUNCTION update_status
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_track_row  IN p1_tracking%ROWTYPE,
        i_old_status IN VARCHAR2,
        o_track      OUT table_number,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;
    /**
    * Updates request status and/or register changes in p1_tracking.
    * Only this function can update the request status.
    *
    * @param i_lang          professional language id
    * @param i_prof          professional, institution and software ids
    * @param i_track_row     p1_tracking rowtype. Includes all data to record the referral change.
    * @param i_old_status    valid status for this update. Single word formed by the letter of valid status.
    * @param o_track         Array of ID_TRACKING transitions
    * @param o_error         an error message, set when return=false
    *
    * @return true if success, false otherwise
    *
    * @author  Joao Sa
    * @version 1.0
    * @since   15-04-2008
    */
    FUNCTION update_status
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_track_row   IN p1_tracking%ROWTYPE,
        i_old_status  IN VARCHAR2,
        i_flg_isencao IN VARCHAR2 DEFAULT NULL,
        i_mcdt_nature IN VARCHAR2 DEFAULT NULL,
        o_track       OUT table_number,
        o_error       OUT t_error_out
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
    * Actualizar estado dos pedidos apos actualização dos dados de identificação.
    *
    * @param   I_LANG language associated to the professional executing the request
    * @param   I_ID_PATIENT Patient id
    * @param   I_PROF professional, institution and software ids
    * @param   I_DATE       Operation date
    * @param   O_ERROR an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Sa
    * @version 1.0
    * @since   23-10-2007
    */
    FUNCTION update_patient_requests
    (
        i_lang       IN language.id_language%TYPE,
        i_id_patient IN patient.id_patient%TYPE,
        i_prof       IN profissional,
        i_date       IN p1_tracking.dt_tracking_tstz%TYPE DEFAULT NULL,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Pesquisar por pacientes
    *
    * @param I_LANG Lingua registada como preferencia do profissional
    * @param I_ID_SYS_BTN_CRIT Lista de ID'S de crit¨rios de pesquisa.
    * @param I_CRIT_VAL lista de valores dos crit¨rios de pesquisa
    * @param I_PROF profissional q regista
    * @param I_PROF_CAT_TYPE Tipo de categoria do profissional, tal como e retornada em PK_LOGIN.GET_PROF_PREF
    * @param o_flg_show flag que indica se am mensagem o_msg deve ser mostrada
    * @param o_msg mensagem a mostrar quando a pesquisa devolve mais que o no. max. de pedidos ou quando nao ha resultados
    * @param o_msg_title titulo a mostrar junto de o_msg
    * @param o_button tipo de botao disponivel no ecra que mostra a menasagem o_msg
    * @param O_PAT - resultados
    * @param O_ERROR - erro
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Sa
    * @version 1.0
    * @since   19-11-2006
    */
    FUNCTION get_search_pat
    (
        i_lang            IN language.id_language%TYPE,
        i_id_sys_btn_crit IN table_number,
        i_crit_val        IN table_varchar,
        i_prof            IN profissional,
        i_prof_cat_type   IN category.flg_type%TYPE,
        o_flg_show        OUT VARCHAR2,
        o_msg             OUT VARCHAR2,
        o_msg_title       OUT VARCHAR2,
        o_button          OUT VARCHAR2,
        o_pat             OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets number of available dcs for the request. 
    *
    * @param   i_lang professional id
    * @param   i_prof dep_clin_serv id
    * @param   i_ext_req referral id
    * @param   o_count number of available dcs    
    * @param   o_id dcs id, when there's only one.
    * @param   o_error error message    
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Sa
    * @version 1.0
    * @since   29-04-2008
    */
    FUNCTION get_clin_serv_forward_count
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_exr_row IN p1_external_request%ROWTYPE,
        o_count   OUT NUMBER,
        o_id      OUT dep_clin_serv.id_dep_clin_serv%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Issues request, i.e. updates request status
    * Must have mandatory data completed and all task must be completed.
    *
    * @param   I_LANG          Language associated to the professional executing the request
    * @param   i_prof          Professional, institution and software ids
    * @param   i_ext_req       Referral identifier
    * @param   I_DATE          Operation date
    * @param   o_track         Array of ID_TRACKING transitions
    * @param   O_ERROR         An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Sa
    * @version 1.0
    * @since   17-12-2007
    */
    FUNCTION issue_request
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_ext_req IN p1_external_request.id_external_request%TYPE,
        i_date    IN p1_tracking.dt_tracking_tstz%TYPE DEFAULT NULL,
        o_track   OUT table_number,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Return sequential_number for the request
    *
    * This function is used by the servlet of the report interface to confirm that the
    * request comes from a reliable source.
    *
    * @param   i_ext_req request id
    * @param   o_data return data
    * @param   O_ERROR an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Jo’o S
    * @version 1.0
    * @since   17-02-2007
    */
    FUNCTION get_req_data
    (
        --i_prof    IN profissional,
        --i_lang    IN LANGUAGE.id_language%TYPE,
        i_ext_req IN p1_external_request.id_external_request%TYPE,
        o_data    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Changes the destination institution 
    *
    * @param   i_lang            Language associated to the professional executing the request
    * @param   i_prof            Professional, institution and software ids
    * @param   i_ext_req         Referral identifier    
    * @param   i_inst_dest new   New dest institution identifier
    * @param   i_dep_clin_serv   Destination service/speciality
    * @param   i_notes           Notes             
    * @param   i_date            Date of status change   
    * @param   o_track           Array of ID_TRACKING transitions    
    * @param   O_ERROR           An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Sa
    * @version 1.0
    * @since   07-05-2008
    */
    FUNCTION set_dest_institution_int
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_ext_req   IN p1_external_request.id_external_request%TYPE,
        i_inst_dest IN institution.id_institution%TYPE,
        i_dcs_dest  IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_date      IN p1_tracking.dt_tracking_tstz%TYPE DEFAULT NULL,
        o_track     OUT table_number,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Changes the destination institution 
    *
    * @param   i_lang            Language associated to the professional executing the request
    * @param   i_prof            Professional, institution and software ids
    * @param   i_ext_req         Referral identifier    
    * @param   i_inst_dest new   New dest institution identifier
    * @param   i_dep_clin_serv   Destination service/speciality             
    * @param   i_date            Date of status change   
    * @param   o_track           Array of ID_TRACKING transitions    
    * @param   o_error           An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Sa
    * @version 1.0
    * @since   07-05-2008
    */
    FUNCTION set_dest_institution
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_ext_req   IN p1_external_request.id_external_request%TYPE,
        i_inst_dest IN institution.id_institution%TYPE,
        i_dcs_dest  IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_track     OUT table_number,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get descriptions for provided tables and ids.
    * Used by the interface to get Alert description of mapped ids.
    *
    * @param   i_lang language associated to the professional executing the request
    * @param   i_prof professional id, institution and software
    * @param   i_key  table names and ids, third field used only for sys_domain. (TABLE_NAME, ID[VAL], [CODE_DOMAIN])
    * @param   o_id   result id  description. (ID[VAL])
    * @param   o_desc result description. (Description)    
    * @param   o_error an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Sa
    * @version 1.0
    * @since   28-10-2008
    */
    FUNCTION get_description
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_key   IN table_table_varchar, -- (TABELA, ID[VAL], [CODE_DOMAIN])
        o_id    OUT table_varchar,
        o_desc  OUT table_varchar,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Issues request, i.e. updates request status
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Professional, institution and software ids
    * @param   i_ext_req        Referral identifier
    * @param   i_mode           Change (S)ame or (O)ther Institution
    * @param   i_date           Operation date    
    * @param   o_track          Array of ID_TRACKING transitions
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Sa 
    * @version 1.0
    * @since   30-04-2008
    */
    FUNCTION set_issue_status
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_exr_row  IN p1_external_request%ROWTYPE,
        i_mode     IN VARCHAR2,
        i_dcs_dest IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_date     IN p1_tracking.dt_tracking_tstz%TYPE DEFAULT NULL,
        o_track    OUT table_number,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns referral status from which the referral can be canceled
    *
    * @param   i_lang      Language associated to the professional executing the request
    * @param   i_prof      Professional id, institution and software
    *
    * @RETURN  table_varchar containing referral status from which it can be canceled
    * @author  Ana Monteiro
    * @version 1.0
    * @since   14-09-2009
    */
    FUNCTION get_cancel_prev_status
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN table_varchar;

    CURSOR c_sns
    (
        x_lang NUMBER,
        x_pat  patient.id_patient%TYPE,
        x_prof profissional
    ) IS
        SELECT hp.id_health_plan,
               php.num_health_plan num,
               pk_translation.get_translation(x_lang, hp.code_health_plan) name,
               pk_sysconfig.get_config('P1_SNS_CODE_SONHO', x_prof) sns_code_sonho
          FROM pat_health_plan php
          JOIN health_plan hp
            ON (php.id_health_plan = hp.id_health_plan)
         WHERE php.id_patient = x_pat
           AND php.id_institution = 0
           AND php.flg_status = pk_ref_constant.g_active
           AND hp.id_content = pk_sysconfig.get_config('ADT_NATIONAL_HEALTH_PLAN_ID', x_prof)
           AND hp.flg_available = pk_alert_constant.get_available;

END pk_p1_core;
/
