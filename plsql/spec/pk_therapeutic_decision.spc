/*-- Last Change Revision: $Rev: 1850754 $*/
/*-- Last Change by: $Author: ana.matos $*/
/*-- Date of last change: $Date: 2018-07-05 15:20:59 +0100 (qui, 05 jul 2018) $*/

CREATE OR REPLACE PACKAGE pk_therapeutic_decision IS

    -- Author  : ELISABETE.BUGALHO
    -- Created : 19-06-2009 16:23:19
    -- Purpose : Therapeutic decision for join comission
    /**********************************************************************************************
    * Gets the summary of therapeutic decisions for a patient
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional's details
    * @param i_patient               ID Patient
    * @param i_episode               ID Episode
    *
    * @param o_thdecision            Cursor with the information of register and therapeutic decision
    * @param o_thdecision_prof       Cursor with the information of the professionals
    * @param o_error                 Error message
    *
    * @return                        True on success, false otherwise
    *                        
    * @author                        Elisabete Bugalho
    * @version                       2.5
    * @since                         2009/06/19
    **********************************************************************************************/

    FUNCTION get_th_dec_summary
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_patient         IN patient.id_patient%TYPE,
        i_episode         IN episode.id_episode%TYPE,
        o_thdecision      OUT pk_types.cursor_type,
        o_thdecision_prof OUT pk_types.cursor_type,
        o_flg_create      OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Gets the ID of professional that is the responsible for the consult
    *
    * @param i_episode               ID Episode
    *
    *
    * @return                        Returns the ID of the professional that is the responsible
    *                        
    * @author                        Elisabete Bugalho
    * @version                       2.5
    * @since                         2009/06/23
    **********************************************************************************************/
    FUNCTION get_prof_responsible(i_episode IN episode.id_episode%TYPE) RETURN NUMBER;

    /**********************************************************************************************
    * Verify if a specific profissional is part of the consultation team 
    *
    * @param i_professional          ID Professional
    * @param i_id_th_decision        ID therapeutic Decision
    *
    * @return                        Returns a flag that indicates if is missing one validation 
    *                                and the professional is part of the team
    *                        
    * @author                        Elisabete Bugalho
    * @version                       2.5
    * @since                         2009/06/23
    **********************************************************************************************/
    FUNCTION get_prof_in_consult
    (
        i_professional   IN professional.id_professional%TYPE,
        i_id_th_decision IN therapeutic_decision.id_therapeutic_decision%TYPE
    ) RETURN VARCHAR2;

    /**********************************************************************************************
    * Gets the detail of a therapeutic decisions
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional's details
    * @param i_patient               ID Patient   
    * @param i_episode               ID Episode
    * @param i_id_the_decision       ID therapeutic decision
    *
    * @param o_thdecision            Cursor with the information of register and therapeutic decision
    * @param o_thdecision_prof       Cursor with the information of the professionals
    * @param o_error                 Error message
    *
    * @return                        True on success, false otherwise
    *                        
    * @author                        Elisabete Bugalho
    * @version                       2.5
    * @since                         2009/06/22
    **********************************************************************************************/

    FUNCTION get_th_dec_summary_det
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_patient         IN patient.id_patient%TYPE,
        i_episode         IN episode.id_episode%TYPE,
        i_id_the_decision IN therapeutic_decision.id_therapeutic_decision%TYPE,
        o_thdecision      OUT pk_types.cursor_type,
        o_thdecision_prof OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Create / Edit a therapeutic decision
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional's details
    * @param i_patient               ID Patient   
    * @param i_episode               ID Episode
    * @param i_id_the_decision       ID therapeutic decision (in case of edit)
    * @param i_therapeutic_decision  Therapeutic decision
    * @param i_prof_list             List of professionals
    * @param i_status_list           List of status of witch professional
    * @param i_validation_list       List of validation of witch professional
    *
    * @param o_id_the_decision       ID of therapeutic decision created/edited
    * @param o_error                 Error message
    *
    * @return                        True on success, false otherwise
    *                        
    * @author                        Elisabete Bugalho
    * @version                       2.5
    * @since                         2009/06/23
    **********************************************************************************************/
    FUNCTION create_th_decision
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_patient              IN patient.id_patient%TYPE,
        i_episode              IN episode.id_episode%TYPE,
        i_id_the_decision      IN therapeutic_decision.id_therapeutic_decision%TYPE,
        i_therapeutic_decision IN therapeutic_decision.therapeutic_decision%TYPE,
        i_prof_list            IN table_number,
        i_status_list          IN table_varchar,
        i_validation_list      IN table_varchar,
        o_id_the_decision      OUT therapeutic_decision.id_therapeutic_decision%TYPE,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Gets the list of professional scheduled for the consult
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional's details
    * @param i_patient               ID Patient
    * @param i_episode               ID Episode
    *
    * @param o_list_professional     Cursor with the list of professionals for the consultation
    * @param o_error                 Error message
    *
    * @return                        True on success, false otherwise
    *                        
    * @author                        Elisabete Bugalho
    * @version                       2.5
    * @since                         2009/06/25
    **********************************************************************************************/
    FUNCTION get_professional_list
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_patient           IN patient.id_patient%TYPE,
        i_episode           IN episode.id_episode%TYPE,
        o_list_professional OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Gets the name of professional that is the responsible for the consult
    *
    * @param i_episode               ID Episode
    *
    *
    * @return                        Returns the name of the professional that is the responsible
    *                        
    * @author                        Elisabete Bugalho
    * @version                       2.5
    * @since                         2009/06/25
    **********************************************************************************************/
    FUNCTION get_prof_name_resp
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_episode  IN episode.id_episode%TYPE,
        i_schedule IN schedule.id_schedule%TYPE
    ) RETURN VARCHAR2;

    /**********************************************************************************************
    * Gets the information of a therapeutic decisions
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional's details
    * @param i_patient               ID Patient   
    * @param i_episode               ID Episode
    * @param i_id_the_decision       ID therapeutic decision
    *
    * @param o_thdecision            Cursor with the information of register and therapeutic decision
    * @param o_thdecision_prof       Cursor with the information of the professionals
    * @param o_error                 Error message
    *
    * @return                        True on success, false otherwise
    *                        
    * @author                        Elisabete Bugalho
    * @version                       2.5
    * @since                         2009/06/26
    **********************************************************************************************/
    FUNCTION get_therapeutic_decision
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_patient         IN patient.id_patient%TYPE,
        i_episode         IN episode.id_episode%TYPE,
        i_id_the_decision IN therapeutic_decision.id_therapeutic_decision%TYPE,
        o_thdecision      OUT pk_types.cursor_type,
        o_thdecision_prof OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * updates the validation of professionals
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional's details
    * @param i_patient               ID Patient   
    * @param i_episode               ID Episode
    * @param i_id_the_decision       ID therapeutic decision (in case of edit)
    * @param i_therapeutic_decision  Therapeutic decision
    * @param i_prof_list             List of professionals
    * @param i_status_list           List of status of witch professional
    * @param i_validation_list       List of validation of witch professional
    *
    * @param o_id_the_decision       ID of therapeutic decision created/edited
    * @param o_error                 Error message
    *
    * @return                        True on success, false otherwise
    *                        
    * @author                        Elisabete Bugalho
    * @version                       2.5
    * @since                         2009/06/26
    **********************************************************************************************/
    FUNCTION update_prof_opinion
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_patient         IN patient.id_patient%TYPE,
        i_episode         IN episode.id_episode%TYPE,
        i_id_the_decision IN therapeutic_decision.id_therapeutic_decision%TYPE,
        i_prof_list       IN table_number,
        i_status_list     IN table_varchar,
        i_validation_list IN table_varchar,
        o_id_the_decision OUT therapeutic_decision.id_therapeutic_decision%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Gets the possible values for the sys_domain table
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional's details
    *
    * @param o_value_opinion         Cursor with the information of the values
    * @param o_value_presence        Cursor with the information of the values    
    * @param o_error                 Error message
    *
    * @return                        True on success, false otherwise
    *                        
    * @author                        Rita Lopes
    * @version                       2.5
    * @since                         2009/07/01
    **********************************************************************************************/
    FUNCTION get_domain_values
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        o_value_opinion  OUT pk_types.cursor_type,
        o_value_presence OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    g_exception EXCEPTION;
    g_sysdate_tstz TIMESTAMP WITH TIME ZONE;
    g_error        VARCHAR2(2000);
    g_package_name VARCHAR2(30);

    g_flg_status_a   CONSTANT VARCHAR2(1) := 'A';
    g_flg_status_o   CONSTANT VARCHAR2(1) := 'O';
    g_yes            CONSTANT VARCHAR2(1) := 'Y';
    g_no             CONSTANT VARCHAR2(1) := 'N';
    g_flg_presence_r CONSTANT VARCHAR2(1) := 'R';
    g_flg_presence_f CONSTANT VARCHAR2(1) := 'F';
    g_flg_presence_p CONSTANT VARCHAR2(1) := 'P';
    g_flg_active     CONSTANT VARCHAR2(1) := 'A';
    g_flg_validation CONSTANT VARCHAR2(1) := 'V';
    g_flg_inactive   CONSTANT VARCHAR2(1) := 'I';
    g_flg_opinion_y  CONSTANT VARCHAR2(1) := 'Y';
    g_flg_opinion_n  CONSTANT VARCHAR2(1) := 'N';

    g_id_sch_event CONSTANT sch_event.id_sch_event%TYPE := 20;

    g_flg_presence sys_domain.code_domain%TYPE := 'THERAPEUTIC_DECISION.FLG_PRESENCE';
    g_flg_opinion  sys_domain.code_domain%TYPE := 'THERAPEUTIC_DECISION.FLG_OPINION';

END pk_therapeutic_decision;
/
