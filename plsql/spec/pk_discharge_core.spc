/*-- Last Change Revision: $Rev: 2028609 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:46:52 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_discharge_core IS

    -- Author  : JOSE.SILVA
    -- Created : 20-08-2010 17:04:13
    -- Purpose : Core discharge functions

    /*
    * Set discharge history.
    *
    * @param i_prof           logged professional structure
    * @param i_discharge      discharge identifier
    * @param i_outd_prev      outdate previous history record: Y - yes, N - No
    * @param o_disch_hist     created discharge_hist identifier
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/03/09
    */
    PROCEDURE set_discharge_hist
    (
        i_prof       IN profissional,
        i_discharge  IN discharge.id_discharge%TYPE,
        i_outd_prev  IN VARCHAR2 DEFAULT 'Y',
        o_disch_hist OUT discharge_hist.id_discharge_hist%TYPE
    );

    /*
    * Set discharge detail history.
    *
    * @param i_prof           logged professional structure
    * @param i_disch_detail   discharge detail identifier
    * @param o_disch_det_hist created discharge_detail_hist identifier
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/03/10
    */
    PROCEDURE set_discharge_detail_hist
    (
        i_prof           IN profissional,
        i_disch_detail   IN discharge_detail.id_discharge_detail%TYPE,
        i_disch_hist     IN discharge_hist.id_discharge_hist%TYPE,
        o_disch_det_hist OUT discharge_detail_hist.id_discharge_detail_hist%TYPE
    );

    /**********************************************************************************************
    * Gets the discharge type: PT - PT discharge
    *                          US - US discharge (also used in NL and UK)
    * 
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_discharge              discharge ID      
    * @param o_flg_market             discharge type 
    * @param o_error                  Error message
    *
    * @return                         true or false on success or error
    *
    * @author                         José Silva
    * @version                        1.0 
    * @since                          2010/08/20
    **********************************************************************************************/
    FUNCTION get_flg_market
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_discharge  IN discharge.id_discharge%TYPE,
        o_flg_market OUT discharge.flg_market%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Gets the discharge status
    * 
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_discharge              discharge ID      
    * @param o_flg_status             discharge status
    * @param o_error                  Error message
    *
    * @return                         true or false on success or error
    *
    * @author                         José Silva
    * @version                        1.0 
    * @since                          2011/01/13
    **********************************************************************************************/
    FUNCTION get_flg_status
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_discharge  IN discharge.id_discharge%TYPE,
        o_flg_status OUT discharge.flg_status%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Gets the administrative discharge date (only when the administrative discharge is active)
    * 
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_discharge              discharge ID
    * @param i_flg_status_adm         administrative discharge status
    * @param i_dt_admin               administrative discharge date
    *
    * @return                         administrative discharge date
    *
    * @author                         José Silva
    * @version                        1.0 
    * @since                          2010/08/20
    **********************************************************************************************/
    FUNCTION get_dt_admin
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_discharge      IN discharge.id_discharge%TYPE,
        i_flg_status_adm IN discharge.flg_status_adm%TYPE DEFAULT NULL,
        i_dt_admin       IN discharge.dt_admin_tstz%TYPE DEFAULT NULL
    ) RETURN discharge.dt_admin_tstz%TYPE;

    /**********************************************************************************************
    * Checks if the episode already have administrative discharge
    * 
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_discharge              discharge ID
    * @param i_flg_status_adm         administrative discharge status
    *
    * @return                         Has administrative discharge: Y - Yes, N - No
    *
    * @author                         José Silva
    * @version                        1.0 
    * @since                          2010/08/20
    **********************************************************************************************/
    FUNCTION check_admin_discharge
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_discharge      IN discharge.id_discharge%TYPE,
        i_flg_status_adm IN discharge.flg_status_adm%TYPE DEFAULT NULL
    ) RETURN VARCHAR2;

    /**********************************************************************************************
    * Gets the discharge type description
    *
    * @param i_lang      the id language
    * @param i_prof      professional ID, SOFTWARE and INSTITUTION 
    * @param i_episode   episode ID
    * @param i_flg_type  discharge type
    *                        
    * @return            Discharge type description
    *
    * @author            José Silva
    * @version           1.0  
    * @since             2010/05/25
    **********************************************************************************************/
    FUNCTION get_disch_dest_type
    (
        i_lang     IN NUMBER,
        i_prof     IN profissional,
        i_episode  IN episode.id_episode%TYPE,
        i_flg_type IN discharge.flg_type%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Checks if the current discharge record shows the MyAlert purchase form
    *
    * @param i_lang                  language identifier
    * @param i_prof                  logged professional structure
    * @param i_id_episode            episode ID
    * @param o_flg_has_trans_model   has transactional model: Y - yes, N - No
    * @param o_error                 error message
    *
    * @return                        false if errors occur, true otherwise
    *
    * @author                        José Silva
    * @version                       2.6.0.5
    * @since                         13-01-2011
    ********************************************************************************************/
    FUNCTION check_transactional_model
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_episode          IN episode.id_episode%TYPE,
        o_flg_has_trans_model OUT VARCHAR2,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Gets discharge screen name for a given discharge reason and profile template
    * 
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_discharge              discharge ID
    *
    * @return                         discharge screen name
    *
    * @author                         Alexandre Santos
    * @version                        1.0 
    * @since                          2011/01/21
    **********************************************************************************************/
    FUNCTION get_disch_screen_name
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_discharge IN discharge.id_discharge%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Get the administrative discharge record
    *
    * @param   i_lang                language associated to the professional executing the request
    * @param   i_episode             episode id
    * @param   i_prof                professional, institution and software ids
    *
    * @param   o_disch               Discharge records
    * @param   o_error               error message
             
    * @RETURN  TRUE if sucess, FALSE otherwise
    *
    * @version 1.0
    * @since   13-12-2005
    *
    ********************************************************************************************/
    FUNCTION get_admin_discharge
    (
        i_lang            IN language.id_language%TYPE,
        i_episode         IN discharge.id_episode%TYPE,
        i_prof            IN profissional,
        i_fltr_start_date IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_fltr_end_date   IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        o_disch           OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Get all discharge notes (medical or administrative).
    *
    * @param i_lang               Language ID
    * @param i_prof               Professional info
    * @param i_id_episode         Episode ID
    * @param i_id_discharge       Discharge ID
    * @param i_flg_type           (A) Administrative or (D) Medical discharge notes
    * @param o_notes              The notes
    * @param o_error              Error message
    *
    * @return            TRUE if sucessful, FALSE otherwise
    *
    * @author            José Brito
    * @version           1.0
    * @since             2009/02/10
    **********************************************************************************************/
    FUNCTION get_disch_prof_notes
    (
        i_lang            IN NUMBER,
        i_prof            IN profissional,
        i_id_episode      IN episode.id_episode%TYPE,
        i_id_discharge    IN discharge.id_discharge%TYPE,
        i_flg_type        IN VARCHAR2,
        i_fltr_start_date IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_fltr_end_date   IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        o_notes           OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Retrieves a discharge record history of operations, in ambulatory products.
    *
    * @param i_lang                  language identifier
    * @param i_prof                  logged professional structure
    * @param i_disch                 discharge identifier
    * @param o_hist                  cursor
    * @param o_error                 error message
    *
    * @return                        false if errors occur, true otherwise
    *
    * @author                        Pedro Carneiro
    * @version                       1.0
    * @since                         28/05/2009
    ********************************************************************************************/
    FUNCTION get_disch_hist_amb
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_disch           IN discharge.id_discharge%TYPE,
        i_fltr_start_date IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_fltr_end_date   IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        o_hist            OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Retrieve discharges, in ambulatory products. Adapted from GET_DISCHARGE.
    *
    * @param i_lang                  language identifier
    * @param i_prof                  logged professional structure
    * @param i_episode               episode identifier
    * @param o_disch                 cursor
    * @param o_error                 error message
    *
    * @return                        false if errors occur, true otherwise
    *
    * @author                        Pedro Carneiro
    * @version                       1.0
    * @since                         28/05/2009
    ********************************************************************************************/
    FUNCTION get_discharges_amb
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_episode         IN episode.id_episode%TYPE,
        i_fltr_start_date IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_fltr_end_date   IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        o_disch           OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns discharge detail (admission)
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_id_discharge           discharge id
    * @param o_sql                    cursor with detail of discharge
    * @param o_error                  Error message
    *
    * @return                        false if errors occur, true otherwise
    *
    * @author                        Alexandre Santos
    * @version                       2.5.0.7.1
    * @since                         27/01/2009
    ********************************************************************************************/
    FUNCTION get_disch_detail_admit
    (
        i_lang            IN NUMBER,
        i_prof            IN profissional,
        i_id_discharge    IN NUMBER,
        i_fltr_start_date IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_fltr_end_date   IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        o_sql             OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns discharge detail (transfer)
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_id_discharge           discharge id
    * @param o_sql                    cursor with detail of discharge
    * @param o_error                  Error message
    *
    * @return                        false if errors occur, true otherwise
    *
    * @author                        Alexandre Santos
    * @version                       2.5.0.7.1
    * @since                         27/01/2009
    ********************************************************************************************/
    FUNCTION get_disch_detail_transf
    (
        i_lang            IN NUMBER,
        i_prof            IN profissional,
        i_id_discharge    IN NUMBER,
        i_fltr_start_date IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_fltr_end_date   IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        o_sql             OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns discharge detail (expired)
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_id_discharge           discharge id
    * @param o_sql                    cursor with detail of discharge
    * @param o_error                  Error message
    *
    * @return                        false if errors occur, true otherwise
    *
    * @author                        Alexandre Santos
    * @version                       2.5.0.7.1
    * @since                         27/01/2009
    ********************************************************************************************/
    FUNCTION get_disch_detail_expir
    (
        i_lang            IN NUMBER,
        i_prof            IN profissional,
        i_id_discharge    IN NUMBER,
        i_fltr_start_date IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_fltr_end_date   IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        o_sql             OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns discharge detail (against medical advice)
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_id_discharge           discharge id
    * @param o_sql                    cursor with detail of discharge
    * @param o_error                  Error message
    *
    * @return                        false if errors occur, true otherwise
    *
    * @author                        Alexandre Santos
    * @version                       2.5.0.7.1
    * @since                         27/01/2009
    ********************************************************************************************/
    FUNCTION get_disch_detail_ama
    (
        i_lang            IN NUMBER,
        i_prof            IN profissional,
        i_id_discharge    IN NUMBER,
        i_fltr_start_date IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_fltr_end_date   IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        o_sql             OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Devolve o detalhe da alta
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_id_discharge           discharge id
    * @param o_sql                    cursor with detail of discharge
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author
    * @version                        1.0
    * @changed                        Emília Taborda
    * @since                          2007/06/18
    **********************************************************************************************/
    FUNCTION get_disch_detail_disch
    (
        i_lang            IN NUMBER,
        i_prof            IN profissional,
        i_id_discharge    IN NUMBER,
        i_fltr_start_date IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_fltr_end_date   IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        o_sql             OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns discharge detail (left without being seen)
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_id_discharge           discharge id
    * @param o_sql                    cursor with detail of discharge
    * @param o_error                  Error message
    *
    * @return                        false if errors occur, true otherwise
    *
    * @author                        Alexandre Santos
    * @version                       2.5.0.7.1
    * @since                         27/01/2009
    ********************************************************************************************/
    FUNCTION get_disch_detail_lwbs
    (
        i_lang            IN NUMBER,
        i_prof            IN profissional,
        i_id_discharge    IN NUMBER,
        i_fltr_start_date IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_fltr_end_date   IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        o_sql             OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;
    -- 
    /********************************************************************************************
    * Returns discharge detail
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_id_discharge           discharge id
    * @param o_sql                    cursor with detail of discharge
    * @param o_error                  Error message
    *
    * @return                        false if errors occur, true otherwise
    *
    * @author                        Alexandre Santos
    * @version                       2.5.0.7.1
    * @since                         27/01/2009
    ********************************************************************************************/
    FUNCTION get_disch_detail
    (
        i_lang            IN NUMBER,
        i_prof            IN profissional,
        i_id_discharge    IN NUMBER,
        i_fltr_start_date IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_fltr_end_date   IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        o_sql             OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get the episode discharge records
    *
    * @param   i_lang                language associated to the professional executing the request
    * @param   i_episode             episode id
    * @param   i_prof                professional, institution and software ids
    * @param   i_category_type       Professional category/discharge type
    *
    * @param   o_disch               Discharge records
    * @param   o_error               error message
             
    * @RETURN  TRUE if sucess, FALSE otherwise
    *
    * @version 1.0
    * @since   11-04-2005
    ********************************************************************************************/
    FUNCTION get_discharge
    (
        i_lang            IN language.id_language%TYPE,
        i_episode         IN discharge.id_episode%TYPE,
        i_prof            IN profissional,
        i_category_type   IN category.flg_type%TYPE,
        i_fltr_start_date IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_fltr_end_date   IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_flg_type        IN VARCHAR2 DEFAULT NULL,
        o_disch           OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get the detail of a discharge record
    *
    * @param   i_lang                language associated to the professional executing the request
    * @param   i_disch               discharge ID
    * @param   i_prof                professional, institution and software ids
    *
    * @param   o_disch               Discharge record
    * @param   o_error               error message
             
    * @RETURN  TRUE if sucess, FALSE otherwise
    *
    * @version 1.0
    * @since   16-07-2005
    ********************************************************************************************/
    FUNCTION get_discharge_detail
    (
        i_lang            IN language.id_language%TYPE,
        i_disch           IN discharge.id_discharge%TYPE,
        i_prof            IN profissional,
        i_fltr_start_date IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_fltr_end_date   IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        o_disch           OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * get_prof_last_med
    *
    * @param   i_lang                language associated to the professional executing the request
    * @param   i_prof                professional, institution and software ids
    * @param   i_id_episode          episode identifier
    *             
    * @RETURN  get_prof_last_med
    *
    * @version 1.0
    * @since   20160225
    ********************************************************************************************/
    FUNCTION get_prof_last_med
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN professional.id_professional%TYPE;

    FUNCTION get_prof_cat_discharge
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN category.flg_type%TYPE;

    FUNCTION get_discharge_destination_spec
    (
        i_lang                      IN language.id_language%TYPE,
        i_prof                      IN profissional,
        i_disch_type                IN v_disch_reas_dest.tipo%TYPE,
        i_file_to_execute           IN discharge_reason.file_to_execute%TYPE,
        i_file                      IN discharge_reason.file_to_execute%TYPE,
        i_id_dep_clin_serv_admiting IN discharge_detail.id_dep_clin_serv_admiting%TYPE
    ) RETURN VARCHAR2 ; 
    
    g_disch_type_pt CONSTANT discharge.flg_market%TYPE := 'PT';
    g_disch_type_us CONSTANT discharge.flg_market%TYPE := 'US';

    g_disch_status_active CONSTANT discharge.flg_status%TYPE := 'A';
    g_disch_status_reopen CONSTANT discharge.flg_status%TYPE := 'R';
    g_disch_status_cancel CONSTANT discharge.flg_status%TYPE := 'C';
    g_disch_status_pend   CONSTANT discharge.flg_status%TYPE := 'P';

    g_domain_disch_flg_pay    CONSTANT sys_domain.code_domain%TYPE := 'DISCHARGE.FLG_PAYMENT';
    g_currency_unit_format_db CONSTANT sys_config.id_sys_config%TYPE := 'CURRENCY_UNIT_FORMAT_DB';
    g_flg_print_report_domain CONSTANT sys_domain.code_domain%TYPE := 'DISCHARGE_DETAIL_HIST.FLG_PRINT_REPORT';
    g_domain_bill_type        CONSTANT sys_domain.code_domain%TYPE := 'DISCHARGE.FLG_BILL_TYPE';

    g_flg_bill_type_normal CONSTANT discharge.flg_bill_type%TYPE := 'N'; -- Consulta normal
    g_flg_bill_type_return CONSTANT discharge.flg_bill_type%TYPE := 'R'; -- Consulta não facturável

END pk_discharge_core;
/
