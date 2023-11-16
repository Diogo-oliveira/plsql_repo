/*-- Last Change Revision: $Rev: 2027608 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:42:46 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_rehab_api IS

    /* CAN'T TOUCH THIS */
    g_error   VARCHAR2(1000 CHAR);
    g_owner   VARCHAR2(30 CHAR);
    g_package VARCHAR2(30 CHAR);
    g_exception EXCEPTION;

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
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'CREATE_REHAB_PRESC';
    
        l_id_patient         rehab_plan.id_patient%TYPE;
        l_tbl_rehab_sch_need table_number := table_number();
        l_id_inst_exec       institution.id_institution%TYPE;
        l_tbl_inst_exec      table_number := table_number();
        l_tbl_session_type   table_varchar := table_varchar();
    
        l_id_rehab_area   table_number := table_number();
        l_id_intervention table_number := table_number();
    
    BEGIN
    
        g_error := 'Getting id_patient';
        pk_alertlog.log_debug(g_error, g_package, l_func_name);
        SELECT e.id_patient, e.id_institution
          INTO l_id_patient, l_id_inst_exec
          FROM episode e
         WHERE e.id_episode = i_id_episode;
    
        g_error := 'Getting i_id_rehab_area_interv';
        pk_alertlog.log_debug(g_error, g_package, l_func_name);
        FOR i IN i_id_rehab_area_interv.first .. i_id_rehab_area_interv.last
        LOOP
        
            l_id_rehab_area.extend();
            l_id_intervention.extend();
        
            SELECT rai.id_rehab_area, rai.id_intervention
              INTO l_id_rehab_area(i), l_id_intervention(i)
              FROM rehab_area_interv rai
             WHERE rai.id_rehab_area_interv = i_id_rehab_area_interv(i);
        
            l_tbl_rehab_sch_need.extend();
            l_tbl_rehab_sch_need(i) := NULL;
        
            l_tbl_inst_exec.extend();
            l_tbl_inst_exec(i) := l_id_inst_exec;
        
            l_tbl_session_type.extend();
        
            SELECT *
              INTO l_tbl_session_type(i)
              FROM (SELECT DISTINCT i.id_rehab_session_type
                      FROM TABLE(pk_rehab.find_inst_rehab_areas(i_prof.institution)) ra
                      JOIN TABLE(pk_rehab.find_rehab_interv(i_prof.institution, i_prof.software)) i
                        ON i.id_rehab_area = ra.id_rehab_area
                     WHERE ra.id_rehab_area = l_id_rehab_area(i)
                       AND i.id_intervention = l_id_intervention(i));
        
        END LOOP;
    
        g_error := 'before call';
        pk_alertlog.log_debug(g_error, g_package, l_func_name);
        IF NOT pk_rehab.create_rehab_presc_internal(i_lang                 => i_lang,
                                                    i_prof                 => i_prof,
                                                    i_id_patient           => l_id_patient,
                                                    i_id_episode           => i_id_episode,
                                                    i_id_rehab_area_interv => i_id_rehab_area_interv,
                                                    i_id_rehab_sch_need    => l_tbl_rehab_sch_need,
                                                    i_id_exec_institution  => l_tbl_inst_exec,
                                                    i_exec_per_session     => i_exec_per_session,
                                                    i_presc_notes          => i_presc_notes,
                                                    i_sessions             => i_sessions,
                                                    i_frequency            => i_frequency,
                                                    i_flg_frequency        => i_flg_frequency,
                                                    i_flg_priority         => i_flg_priority,
                                                    i_date_begin           => i_date_begin,
                                                    i_session_notes        => i_session_notes,
                                                    i_session_type         => l_tbl_session_type,
                                                    i_id_codification      => i_id_codification,
                                                    i_flg_laterality       => i_flg_laterality,
                                                    i_id_not_order_reason  => i_id_not_order_reason,
                                                    o_id_rehab_presc       => o_id_rehab_presc,
                                                    o_error                => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error('Parameters: i_id_episode=' || i_id_episode || ' @' || g_error,
                                  g_package,
                                  l_func_name);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END create_rehab_presc;

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
    ) RETURN BOOLEAN IS
    
        l_func_name CONSTANT VARCHAR2(30) := 'UPDATE_REHAB_PRESC';
        l_tbl_id_rehab_area_interv table_number := table_number();
        l_tbl_rehab_sch_need       table_number := table_number();
        l_id_patient               rehab_plan.id_patient%TYPE;
        l_id_inst_exec             institution.id_institution%TYPE;
        l_tbl_session_type         table_varchar := table_varchar();
    
        l_id_intervention rehab_area_interv.id_intervention%TYPE;
        l_id_rehab_area   rehab_area_interv.id_rehab_area%TYPE;
    
    BEGIN
    
        SELECT e.id_patient, e.id_institution
          INTO l_id_patient, l_id_inst_exec
          FROM episode e
         WHERE e.id_episode = i_id_episode;
    
        FOR i IN i_id_rehab_presc.first .. i_id_rehab_presc.last
        LOOP
        
            l_tbl_id_rehab_area_interv.extend;
        
            SELECT rp.id_rehab_area_interv
              INTO l_tbl_id_rehab_area_interv(i)
              FROM rehab_presc rp
             WHERE rp.id_rehab_presc = i_id_rehab_presc(i);
        
            SELECT rai.id_intervention, rai.id_rehab_area
              INTO l_id_intervention, l_id_rehab_area
              FROM rehab_area_interv rai
             WHERE rai.id_rehab_area_interv = l_tbl_id_rehab_area_interv(i);
        
            l_tbl_rehab_sch_need.extend();
            l_tbl_rehab_sch_need(i) := NULL;
        
            l_tbl_session_type.extend();
        
            SELECT *
              INTO l_tbl_session_type(i)
              FROM (SELECT DISTINCT i.id_rehab_session_type
                      FROM TABLE(pk_rehab.find_inst_rehab_areas(i_prof.institution)) ra
                      JOIN TABLE(pk_rehab.find_rehab_interv(i_prof.institution, i_prof.software)) i
                        ON i.id_rehab_area = ra.id_rehab_area
                     WHERE ra.id_rehab_area = l_id_rehab_area
                       AND i.id_intervention = l_id_intervention);
        
            IF NOT pk_rehab.set_rehab_presc_nocommit(i_lang                 => i_lang,
                                                     i_prof                 => i_prof,
                                                     i_id_patient           => l_id_patient,
                                                     i_id_episode           => i_id_episode,
                                                     i_id_rehab_presc       => i_id_rehab_presc(i),
                                                     i_id_rehab_area_interv => l_tbl_id_rehab_area_interv(i),
                                                     i_id_rehab_sch_need    => l_tbl_rehab_sch_need(i),
                                                     i_id_exec_institution  => l_id_inst_exec,
                                                     i_exec_per_session     => i_exec_per_session(i),
                                                     i_presc_notes          => i_presc_notes(i),
                                                     i_sessions             => i_sessions(i),
                                                     i_frequency            => i_frequency(i),
                                                     i_flg_frequency        => i_flg_frequency(i),
                                                     i_flg_priority         => i_flg_priority(i),
                                                     i_date_begin           => i_date_begin(i),
                                                     i_session_notes        => i_session_notes(i),
                                                     i_session_type         => l_tbl_session_type(i),
                                                     i_flg_laterality       => i_flg_laterality(i),
                                                     i_id_not_order_reason  => i_id_not_order_reason(i),
                                                     o_id_rehab_presc       => o_id_rehab_presc,
                                                     o_error                => o_error)
            THEN
                RETURN FALSE;
            END IF;
        
        END LOOP;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error('Parameters: i_id_episode=' || i_id_episode || ' @' || g_error,
                                  g_package,
                                  l_func_name);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END update_rehab_presc;

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
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'CANCEL_REHAB_PRESC';
    BEGIN
        g_error := 'before call';
        pk_alertlog.log_debug(g_error, g_package, l_func_name);
    
        FOR i IN i_id_rehab_presc.first .. i_id_rehab_presc.last
        LOOP
            IF NOT pk_rehab.cancel_rehab_presc_nocommit(i_lang             => i_lang,
                                                        i_prof             => i_prof,
                                                        i_id_rehab_presc   => i_id_rehab_presc(i),
                                                        i_id_cancel_reason => i_id_cancel_reason(i),
                                                        i_notes            => i_notes(i),
                                                        o_error            => o_error)
            THEN
                RETURN FALSE;
            END IF;
        
        END LOOP;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(g_error, g_package, l_func_name);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END cancel_rehab_presc;

BEGIN

    /* CAN'T TOUCH THIS */
    /* Who am I */
    alertlog.pk_alertlog.who_am_i(owner => g_owner, name => g_package);
    /* Log init */
    alertlog.pk_alertlog.log_init(object_name => g_package);
END pk_rehab_api;
/
