/*-- Last Change Revision: $Rev: 2028969 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:49:02 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_service_transfer_rep AS

    /**************************************************************************
    * get the service transfer detail for reports
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID                         
    * @param i_id_episode             Episode ID
    * @param i_id_epis_prof_resp      Epis prof resp ID (service transfer ID)
    * @param i_scope                  Scope ID (Patient ID, Visit ID, Episode ID)    
    * @param i_scope_type             Scope type (by patient {P}, by visit {V}, by episode{E})
    * @param i_flg_report_type        Report type: C-complete report; D-forensic report
    * @param i_start_date             Start date to be considered
    * @param i_end_date               End date to be considered
    *
    * @param o_data                   Data cursor. Labels, format types and status
    * @param o_error                  Error message
    *                                                                         
    * @author                         Filipe Silva                            
    * @version                        2.6.1                                 
    * @since                          2011/05/24                                 
    **************************************************************************/

    FUNCTION get_rep_service_transfer
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_epis_prof_resp IN epis_prof_resp.id_epis_prof_resp%TYPE,
        i_scope             IN NUMBER,
        i_scope_type        IN VARCHAR2,
        i_flg_report_type   IN VARCHAR2,
        i_start_date        IN VARCHAR2,
        i_end_date          IN VARCHAR2,
        o_data              OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /**************************************************************************
    * get all transfer from given institution and patient.
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_id_episode             Episode ID
    * @param i_id_patient             Patient ID
    * @param i_prof                   Profissional ID         
    *
    * @param o_flag_my_service        
    * @param o_list                   Data cursor           
    * @param o_error                  Error message
    *                                                                         
    * @author                         CARLOS FERREIRA                            
    * @since                          2007/01/27                                 
    **************************************************************************/
    FUNCTION get_pat_transfer_list
    (
        i_lang            IN NUMBER,
        i_id_episode      IN NUMBER,
        i_id_patient      IN NUMBER,
        i_prof            IN profissional,
        o_flag_my_service OUT NUMBER,
        o_list            OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_transfer_detail
    (
        i_lang              IN NUMBER,
        i_area              IN VARCHAR2, --- A, B,C
        i_prof              IN profissional,
        i_id_epis_prof_resp IN NUMBER,
        o_title             OUT pk_types.cursor_type,
        o_data              OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    g_error   VARCHAR2(1000 CHAR);
    g_owner   VARCHAR2(30 CHAR);
    g_package VARCHAR2(30 CHAR);
    g_exception EXCEPTION;

    --reports 
    g_report_complete_c CONSTANT VARCHAR2(1 CHAR) := 'C';
    g_report_detailed_d CONSTANT VARCHAR2(1 CHAR) := 'D';

END pk_service_transfer_rep;
/
