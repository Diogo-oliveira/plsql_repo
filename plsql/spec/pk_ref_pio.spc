/*-- Last Change Revision: $Rev: 1481073 $*/
/*-- Last Change by: $Author: joana.barroso $*/
/*-- Date of last change: $Date: 2013-06-20 15:06:32 +0100 (qui, 20 jun 2013) $*/

CREATE OR REPLACE PACKAGE pk_ref_pio AS

    /**
    *
    * Checks if referral is ready to be sent to SIGLIC
    *
    * @param   i_lang             Language
    * @param   i_prof             Profissional, institution, software
    * @param   i_flg_status       Referral status
    * @param   i_dt_schedule_tstz Referral appointment date
    * @param   i_dt_requested     Referral requested date
    *
    * @return  {*} 'Y' referral can be sent to SIGLIC {*} 'N' otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   15-05-2009
    */
    FUNCTION check_pio_cond
    (
        i_lang             IN LANGUAGE.id_language%TYPE,
        i_prof             IN profissional,
        i_flg_status       IN p1_external_request.flg_status%TYPE,
        i_dt_schedule_tstz IN schedule.dt_begin_tstz%TYPE,
        i_dt_requested     IN p1_external_request.dt_requested%TYPE
    ) RETURN VARCHAR2;

    /**
    *
    * Checks if referral is ready to be sent to SIGLIC
    *
    * @param   i_lang             Language
    * @param   i_prof             Profissional, institution, software
    * @param   i_ext_req          Referral identification
    *
    * @return  {*} 'Y' referral can be sent to SIGLIC {*} 'N' otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   15-05-2009
    */
    FUNCTION check_pio_cond
    (
        i_lang    IN LANGUAGE.id_language%TYPE,
        i_prof    IN profissional,
        i_ext_req IN p1_external_request.id_external_request%TYPE
    ) RETURN VARCHAR2;

    /**
    *
    * Collect referrals to be sent to SIGLIC
    *
    * @param   i_lang             Language
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   15-05-2009
    */
    PROCEDURE set_ref_pio(i_lang IN LANGUAGE.id_language%TYPE);

    /**
    *
    * Changes referral pio status from (W)aiting for approval to (R)ead, blocking referral status in CTH
    *
    * @param   i_lang             Language
    * @param   i_prof             Profissional, institution, software
    * @param   i_ext_req          Referrals identification
    * @param   o_error            An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   18-05-2009
    */
    FUNCTION set_ref_read
    (
        i_lang    IN LANGUAGE.id_language%TYPE,
        i_prof    IN profissional,
        i_ext_req IN table_number,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    *
    * Changes referral pio status from (R)ead to (W)aiting for approval, unblocking referral status in CTH
    *
    * @param   i_lang             Language
    * @param   i_prof             Profissional, institution, software
    * @param   i_ext_req          Referrals identification
    * @param   o_error            An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   18-05-2009
    */
    FUNCTION set_ref_unread
    (
        i_lang    IN LANGUAGE.id_language%TYPE,
        i_prof    IN profissional,
        i_ext_req IN table_number,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    *
    * SIGLIC has acknowledge referral receipt. Changes referral pio status from (R)ead to (P)rocessing
    *
    * @param   i_lang             Language
    * @param   i_prof             Profissional, institution, software
    * @param   i_ext_req          Referrals identification
    * @param   o_error            An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   18-05-2009
    */
    FUNCTION set_ref_ack
    (
        i_lang    IN LANGUAGE.id_language%TYPE,
        i_prof    IN profissional,
        i_ext_req IN table_number,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    *
    * SIGLIC has responded. Removes referral from the application or changes referral pio status (from (P)rocessing to
    * (W)aiting for approval or (S)tand by), depending on i_action
    *
    * @param   i_lang             Language
    * @param   i_prof             Profissional, institution, software
    * @param   i_ext_req          Referral identification
    * @param   i_action           SIGLIC action: {*} (N)o action {*} (C)ancel referral {*} (T)ransfer {*} (U)ntransferable
    * @param   i_id_dep_clin_serv New referral dep_clin_serv
    * @param   i_id_institution   New dest institution
    * @param   i_id_reason_code   Cancelation reason
    * @param   o_error            An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   18-05-2009
    */
    FUNCTION set_ref_response
    (
        i_lang             IN LANGUAGE.id_language%TYPE,
        i_prof             IN profissional,
        i_ext_req          IN p1_external_request.id_external_request%TYPE,
        i_action           IN ref_pio_tracking.action%TYPE,
        i_id_dep_clin_serv IN p1_external_request.id_dep_clin_serv%TYPE,
        i_id_institution   IN p1_external_request.id_inst_dest%TYPE,
        i_id_reason_code   IN p1_reason_code.id_reason_code%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    ----------------------------------------------------------------------
    -- Integration With OUTPATIENT
    ----------------------------------------------------------------------    

    /**
    * Changes referral status to b(L)ocked in CTH
    *
    * @param   i_lang             Language
    * @param   i_prof             Profissional id, institution, software
    * @param   i_prof_data        Profissional profile template, category and functionality 
    * @param   i_ref_row          P1_EXTERNAL_REQUEST rowtype   
    * @param   i_date             Blocking date
    * @param   o_error            An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   19-11-2009
    */
    FUNCTION set_ref_blocked
    (
        i_lang      IN LANGUAGE.id_language%TYPE,
        i_prof      IN profissional,
        i_prof_data IN t_rec_prof_data,
        i_ref_row   IN p1_external_request%ROWTYPE,
        i_date      IN p1_tracking.dt_tracking_tstz%TYPE,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /**    
    * Changes referral status to previous status before b(L)ocked in CTH
    *
    * @param   i_lang             Language
    * @param   i_prof             Profissional, institution, software
    * @param   i_prof_data        Profissional profile template, category and functionality 
    * @param   i_ref_row          P1_EXTERNAL_REQUEST rowtype   
    * @param   i_date             Blocking date
    * @param   o_error            An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   19-11-2009
    */
    FUNCTION set_ref_unblocked
    (
        i_lang      IN LANGUAGE.id_language%TYPE,
        i_prof      IN profissional,
        i_prof_data IN t_rec_prof_data,
        i_ref_row   IN p1_external_request%ROWTYPE,
        i_date      IN p1_tracking.dt_tracking_tstz%TYPE,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

END pk_ref_pio;
/
