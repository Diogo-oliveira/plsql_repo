/*-- Last Change Revision: $Rev: 2028921 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:48:45 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_rehab_api IS

    /********************************************************************************************
    *  Creates rehabilitation prescriptions 
    *             
    * @param    i_lang                Language ID
    * @param    i_prof                Logged professional structure    
    * @param    i_id_episode          Episode ID
    * @param    i_id_rehab_area       ARRAY of id_rehab_area
    * @param    i_id_intervention     ARRAY of id_intevention
    * @param    i_exec_per_session    Array of number of executions per session for each intervention   
    * @param    i_presc_notes         ARRAY of prescription Notes
    * @param    i_sessions            ARRAY of number of sessions for each intervention
    * @param    i_frequency           ARRAY of number of executions per Month/Week (According to i_flg_frequency)    
    * @param    i_flg_frequency       ARRAY of flg_frequency (W-Weekly, M-Monthly)  
    * @param    i_flg_priority        ARRAY of priority for each intervention
    * @param    i_date_begin          ARRAY of begin dates
    * @param    i_session_notes       ARRAY of session notes
    * @param    i_id_codification     ARRAY of codification
    * @param    i_flg_laterality      ARRAY of lateralities
    * @param    i_id_not_order_reason ARRAY of id_not_order_reason
    *                                                       
    * @return   BOOLEAN
    *  
    * @author   Diogo Oliveira                 
    * @version  2.7.2.0                
    * @since    02-Nov-2017                         
    **********************************************************************************************/

    FUNCTION create_rehab_presc
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_episode           IN episode.id_episode%TYPE,
        i_id_rehab_area_interv IN table_number,
        i_exec_per_session     IN table_number,
        i_presc_notes          IN table_varchar,
        i_sessions             IN table_number,
        i_frequency            IN table_number,
        i_flg_frequency        IN table_varchar,
        i_flg_priority         IN table_varchar,
        i_date_begin           IN table_varchar,
        i_session_notes        IN table_varchar,
        i_id_codification      IN table_number,
        i_flg_laterality       IN table_varchar,
        i_id_not_order_reason  IN table_number,
        o_id_rehab_presc       OUT table_number,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    *  Updates rehabilitation prescriptions 
    *             
    * @param    i_lang                Language ID
    * @param    i_prof                Logged professional structure    
    * @param    i_id_episode          Episode ID
    * @param    i_id_rehab_presc      ARRAY of id_rehab_presc (NULL => NEW RECORD)
    * @param    i_exec_per_session    Array of number of executions per session for each intervention   
    * @param    i_presc_notes         ARRAY of prescription Notes
    * @param    i_sessions            ARRAY of number of sessions for each intervention
    * @param    i_frequency           ARRAY of number of executions per Month/Week (According to i_flg_frequency)    
    * @param    i_flg_frequency       ARRAY of flg_frequency (W-Weekly, M-Monthly)  
    * @param    i_flg_priority        ARRAY of priority for each intervention
    * @param    i_date_begin          ARRAY of begin dates
    * @param    i_session_notes       ARRAY of session notes
    * @param    i_id_codification     ARRAY of codification
    * @param    i_flg_laterality      ARRAY of lateralities
    * @param    i_id_not_order_reason ARRAY of id_not_order_reason
    *                                                       
    * @return   BOOLEAN
    *  
    * @author   Diogo Oliveira                 
    * @version  2.7.2.0                
    * @since    02-Nov-2017                         
    **********************************************************************************************/

    FUNCTION update_rehab_presc
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_episode          IN episode.id_episode%TYPE,
        i_id_rehab_presc      IN table_number,
        i_exec_per_session    IN table_number,
        i_presc_notes         IN table_varchar,
        i_sessions            IN table_number,
        i_frequency           IN table_number,
        i_flg_frequency       IN table_varchar,
        i_flg_priority        IN table_varchar,
        i_date_begin          IN table_varchar,
        i_session_notes       IN table_varchar,
        i_id_codification     IN table_number,
        i_flg_laterality      IN table_varchar,
        i_id_not_order_reason IN table_number,
        o_id_rehab_presc      OUT table_number,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    *  Cancels rehabilitation prescriptions 
    *             
    * @param    i_lang                Language ID
    * @param    i_prof                Logged professional structure    
    * @param    i_id_rehab_presc      ARRAY of id_rehab_presc
    * @param    i_id_cancel_reason    ARRAY of cancel reasons
    * @param    i_notes               ARRAY of cancel notes
    *                                                       
    * @return   BOOLEAN
    *  
    * @author   Diogo Oliveira                 
    * @version  2.7.2.0                
    * @since    02-Nov-2017                         
    **********************************************************************************************/

    FUNCTION cancel_rehab_presc
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_rehab_presc   IN table_number,
        i_id_cancel_reason IN table_number,
        i_notes            IN table_varchar,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

END pk_rehab_api;
/
