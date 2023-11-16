/*-- Last Change Revision: $Rev: 1650634 $*/
/*-- Last Change by: $Author: rui.gomes $*/
/*-- Date of last change: $Date: 2014-10-22 15:56:46 +0100 (qua, 22 out 2014) $*/
CREATE OR REPLACE PACKAGE pk_backoffice_cda IS

    g_error VARCHAR2(1000);
    g_package_owner CONSTANT VARCHAR2(6 CHAR) := 'ALERT';
    g_package_name VARCHAR2(32 CHAR);
    g_exception EXCEPTION;

    -- PUBLIC METHODS
    FUNCTION get_id_from_rowid
    (
        i_rowid      IN VARCHAR2,
        i_table_name IN VARCHAR2
    ) RETURN NUMBER;
    FUNCTION get_cda_institution(i_id_cda_req IN cda_req.id_cda_req%TYPE) RETURN NUMBER;
    FUNCTION get_cda_desc
    (
        i_lang       IN language.id_language%TYPE,
        i_id_cda_req IN cda_req.id_cda_req%TYPE
    ) RETURN VARCHAR2;
    /********************************************************************************************
    * Get request Next rank status
    *
    * @param i_lang 
    * @param i_id_institution 
    * @param i_previous_status 
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        RMGM
    * @since                         2014/05/05
    * @version                       2.6.4.0
    ********************************************************************************************/
    FUNCTION get_next_ranked_status
    (
        i_lang            IN language.id_language%TYPE,
        i_id_institution  IN institution.id_institution%TYPE,
        i_previous_status IN cda_req.flg_status%TYPE DEFAULT NULL
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Get current request status
    *
    * @param i_id_cda_req 
    *
    * @return                        status value
    *
    * @author                        RMGM
    * @since                         2014/05/05
    * @version                       2.6.4.0
    ********************************************************************************************/
    FUNCTION get_cda_req_det_status(i_id_cda_req IN cda_req.id_cda_req%TYPE) RETURN VARCHAR2;
    /********************************************************************************************
    * Get status from request
    *
    * @param i_id_cda_req
    *
    * @return                        current status
    *
    * @author                        RMGM
    * @since                         2014/05/05
    * @version                       2.6.4.0
    ********************************************************************************************/
    FUNCTION get_cda_req_status(i_id_cda_req IN cda_req.id_cda_req%TYPE) RETURN VARCHAR2;
    /********************************************************************************************
    * Get Latest ID cda request history
    *
    * @param i_id_cda_req 
    *
    * @return                        history id
    *
    * @author                        RMGM
    * @since                         2014/05/05
    * @version                       2.6.4.0
    ********************************************************************************************/
    FUNCTION get_current_cda_req_det(i_id_cda_req IN cda_req.id_cda_req%TYPE) RETURN NUMBER;
    /********************************************************************************************
    * Get CDA Report ID 
    *
    * @param o_id_report 
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        RMGM
    * @since                         2014/05/05
    * @version                       2.6.4.0
    ********************************************************************************************/
    FUNCTION get_cda_report_id
    (
        i_id_software IN software.id_software%TYPE,
        o_id_report   OUT report_software.id_report%TYPE
    ) RETURN BOOLEAN;
    -- get search ids
    FUNCTION get_cda_search
    (
        i_lang       IN language.id_language%TYPE,
        i_search_val IN translation.desc_lang_1%TYPE
    ) RETURN table_number;
    /********************************************************************************************
    * Set next cda request history record
    *
    * @param i_id_cda_req_det 
    * @param i_id_cda_req 
    * @param i_flg_status 
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        RMGM
    * @since                         2014/05/05
    * @version                       2.6.4.0
    ********************************************************************************************/
    FUNCTION set_next_cda_req_det
    (
        i_id_cda_req_det IN cda_req_det.id_cda_req_det%TYPE,
        i_id_cda_req     IN cda_req.id_cda_req%TYPE,
        i_flg_status     IN cda_req_det.flg_status%TYPE
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Get detailed CDA request table
    *
    * @param i_lang 
    * @param i_id_institution 
    * @param o_results 
    * @param o_error 
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        RMGM
    * @since                         2014/05/05
    * @version                       2.6.4.0
    ********************************************************************************************/
    FUNCTION get_cda_req
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        o_results        OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Get detailed CDA request history
    *
    * @param i_lang 
    * @param i_id_cda_req 
    * @param o_results 
    * @param o_results_prof 
    * @param o_error 
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        RMGM
    * @since                         2014/05/05
    * @version                       2.6.4.0
    ********************************************************************************************/
    FUNCTION get_cda_req_det
    (
        i_lang         IN language.id_language%TYPE,
        i_id_cda_req   IN cda_req.id_cda_req%TYPE,
        o_results      OUT pk_types.cursor_type,
        o_results_prof OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set a Complete CDA request
    *
    * @param i_lang 
    * @param i_prof 
    * @param i_id_institution 
    * @param i_flg_type 
    * @param i_dt_start 
    * @param i_dt_end 
    * @param i_qrda_type 
    * @param i_qrda_stype 
    * @param i_sw_list 
    * @param o_cda_req 
    * @param o_cda_req_det 
    * @param o_error 
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        RMGM
    * @since                         2014/05/05
    * @version                       2.6.4.0
    ********************************************************************************************/
    FUNCTION insert_cda_req
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_institution IN institution.id_institution%TYPE,
        i_flg_type       IN cda_req.flg_type%TYPE,
        i_dt_start       IN VARCHAR2,
        i_dt_end         IN VARCHAR2,
        i_sw_list        IN cda_req.id_software%TYPE,
        o_cda_req        OUT cda_req.id_cda_req%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Insert a report generation request history
    *
    * @param i_lang 
    * @param i_id_cda_req 
    * @param i_id_institution 
    * @param i_flg_type 
    * @param i_flg_stype 
    * @param o_cda_req_det 
    * @param o_error  
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        RMGM
    * @since                         2014/05/05
    * @version                       2.6.4.0
    ********************************************************************************************/
    FUNCTION insert_cda_req_det
    (
        i_lang           IN language.id_language%TYPE,
        i_id_cda_req     IN cda_req.id_cda_req%TYPE,
        i_id_institution IN cda_req.id_institution%TYPE,
        i_flg_type       IN cda_req_det.id_report%TYPE,
        i_flg_stype      IN cda_req_det.qrda_type%TYPE,
        o_cda_req_det    OUT cda_req_det.id_cda_req_det%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set a Complete CDA request
    *
    * @param i_lang 
    * @param i_prof 
    * @param i_id_institution 
    * @param i_flg_type 
    * @param i_dt_start 
    * @param i_dt_end 
    * @param i_qrda_type 
    * @param i_qrda_stype 
    * @param i_sw_list 
    * @param o_cda_req 
    * @param o_cda_req_det 
    * @param o_error 
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        RMGM
    * @since                         2014/05/05
    * @version                       2.6.4.0
    ********************************************************************************************/
    FUNCTION set_cda_req
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_institution IN institution.id_institution%TYPE,
        i_flg_type       IN cda_req.flg_type%TYPE,
        i_dt_start       IN VARCHAR2,
        i_dt_end         IN VARCHAR2,
        i_qrda_type      IN cda_req_det.id_report%TYPE,
        i_qrda_stype     IN cda_req_det.qrda_type%TYPE,
        i_sw_list        IN cda_req.id_software%TYPE,
        o_cda_req        OUT cda_req.id_cda_req%TYPE,
        o_cda_req_det    OUT cda_req_det.id_cda_req_det%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set report next logical status
    *
    * @param i_lang 
    * @param i_id_cda_req 
    * @param i_id_institution 
    * @param o_error  
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        RMGM
    * @since                         2014/05/05
    * @version                       2.6.4.0
    ********************************************************************************************/
    PROCEDURE set_cda_next_status
    (
        i_lang           IN language.id_language%TYPE,
        i_id_cda_req     IN cda_req.id_cda_req%TYPE,
        i_id_institution IN cda_req.id_institution%TYPE
    );
    /********************************************************************************************
    * Get Measures list
    *
    * @param i_lang 
    * @param i_prof 
    * @param o_tab_emeasure 
    * @param o_error 
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        RMGM
    * @since                         2014/05/05
    * @version                       2.6.4.0
    ********************************************************************************************/
    FUNCTION get_qrda_measures
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        o_tab_emeasure OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Get software CDA request list
    *
    * @param i_lang 
    * @param i_flg_cda_req_type 
    * @param i_flg_type_qrda 
    * @param o_result_sw 
    * @param o_error 
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        RMGM
    * @since                         2014/05/05
    * @version                       2.6.4.0
    ********************************************************************************************/
    FUNCTION get_cda_software_list
    (
        i_lang             IN language.id_language%TYPE,
        i_flg_cda_req_type IN cda_req.flg_type%TYPE,
        i_flg_type_qrda    IN cda_req_det.qrda_type%TYPE,
        o_result_sw        OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Save zipped report file, go to next status and generate alert
    *
    * @param i_lang 
    * @param i_prof 
    * @param i_id_cda_req 
    * @param i_id_institution 
    * @param i_file 
    * @param o_error 
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        RMGM
    * @since                         2014/05/05
    * @version                       2.6.4.0
    ********************************************************************************************/
    FUNCTION save_req_report
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_cda_req     IN cda_req.id_cda_req%TYPE,
        i_id_institution IN cda_req.id_institution%TYPE,
        i_file           IN BLOB,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Retrieve file to servlet in order to be sent to ux for download
    *
    * @param i_cda_req 
    * @param o_file 
    * @param o_error  
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        RMGM
    * @since                         2014/05/05
    * @version                       2.6.4.0
    ********************************************************************************************/
    FUNCTION get_cda_req_file
    (
        i_cda_req IN cda_req.id_cda_req%TYPE,
        o_file    OUT BLOB,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Cancel CDA requests
    *
    * @param i_lang 
    * @param i_id_cda_req 
    * @param o_error 
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        RMGM
    * @since                         2014/05/05
    * @version                       2.6.4.0
    ********************************************************************************************/
    FUNCTION cancel_cda_req
    (
        i_lang       IN language.id_language%TYPE,
        i_id_cda_req IN cda_req.id_cda_req%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;
    /** @headcom
    * Public Function. Get certification identifiers
    *
    * @param      I_LANG                   Identificação do Idioma
    * @param      i_id_institution         Identificador da instituição
    * @param      io_id_software           Lista de modulos de identificadores de software
    * @param      o_cert_id                Valor do identificador de certificação
    * @param      o_error                  tipificação de Erro
    *
    * @return     boolean
    * @author     RMGM
    * @version    2.6.4.0.2
    * @since      2014/05/19
    */
    FUNCTION get_cms_ehr_id
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        io_id_software   IN OUT table_number,
        o_cert_id        OUT table_varchar,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Get CDA requests Detail or History
    *
    * @param i_lang                 Application current language
    * @param i_prof                 Professional Information array
    * @param i_id_cda_req           CDA request identified
    * @param i_screen_flg           Flg showing the screen request (H or D)
    * @param o_results              Cursor with returned information
    * @param o_error                Error information type
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        RMGM
    * @since                         2014/07/15
    * @version                       2.6.4.1
    ********************************************************************************************/
    FUNCTION get_cda_det
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_cda_req IN cda_req.id_cda_req%TYPE,
        i_screen_flg IN VARCHAR2,
        o_results    OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;
END;
/
