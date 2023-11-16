/*-- Last Change Revision: $Rev: 2026654 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:39:28 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_api_adm_request IS
    -- Private constants
    g_pck_owner CONSTANT VARCHAR2(5) := 'ALERT';
    g_pck_name  CONSTANT VARCHAR2(30) := 'PK_API_ADM_REQUEST';

    /**********************************************************************************************
    * Lists types of admission available for a given location
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids     
    * @param i_location               institution id  
    *
    * @param o_list                   Cursor with admission types 
    * @param o_error                  Error message
    *
    * @return                         TRUE if successful, FALSE otherwise
    *                        
    * @author                         Fábio Oliveira
    * @version                        1.0 
    * @since                          2009/06/09
    ***********************************************************************************************/
    FUNCTION get_admission_type_list
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_location IN institution.id_institution%TYPE,
        o_list     OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'PK_API_ADM_REQUEST.call_GET_ADMISSION_TYPE_LIST';
        IF NOT pk_admission_request.get_admission_type_list(i_lang     => i_lang,
                                                            i_prof     => i_prof,
                                                            i_location => i_location,
                                                            o_list     => o_list,
                                                            o_error    => o_error)
        THEN
            RETURN FALSE;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pck_owner,
                                              g_pck_name,
                                              'GET_ADMISSION_TYPE_LIST',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_list);
        
    END get_admission_type_list;

    /*******************************************************************************************************************************************
    * GET_ALL_DIAGNOSIS_STR           Returns all diagnosis of a patient
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_ID_EPISODE             Episode id that is soposed to retunr information
    * 
    * @return                         Returns STRING with all diagnosis if success, otherwise returns NULL
    * 
    * @author                         Luís Maia
    * @version                        1.0
    * @since                          2009/07/04
    *******************************************************************************************************************************************/
    FUNCTION get_all_diagnosis_str
    (
        i_lang       language.id_language%TYPE,
        i_id_episode episode.id_episode%TYPE
    ) RETURN VARCHAR2 IS
        l_error t_error_out;
    BEGIN
        g_error := 'PK_API_ADM_REQUEST.CALL_GET_ALL_DIAGNOSIS_STR';
        RETURN pk_admission_request.get_all_diagnosis_str(i_lang => i_lang, i_id_episode => i_id_episode);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pck_owner,
                                              g_pck_name,
                                              'GET_ALL_DIAGNOSIS_STR',
                                              l_error);
            pk_alert_exceptions.reset_error_state;
            RETURN '';
        
    END get_all_diagnosis_str;

    /******************************************************************************
    *  Given an id_waiting_list returns indication for admission description.
    *
    *  @param  i_lang              Language ID
    *  @param  i_prof              Professional ID/Institution ID/Software ID
    *  @param  i_id_waiting_list   ID of the waiting list request
    *
    *  @return                     varchar2
    *
    *  @author                     Fábio Oliveira
    *  @version                    2.5.0.3
    *  @since                      2009-05-29
    *
    ******************************************************************************/
    FUNCTION get_adm_indication_desc
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_waiting_list IN waiting_list.id_waiting_list%TYPE
    ) RETURN pk_translation.t_desc_translation IS
        l_error t_error_out;
    BEGIN
        RETURN pk_admission_request.get_adm_indication_desc(i_lang            => i_lang,
                                                            i_prof            => i_prof,
                                                            i_id_waiting_list => i_id_waiting_list);
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pck_owner,
                                              g_pck_name,
                                              'GET_ADM_INDICATION_DESC',
                                              l_error);
            pk_alert_exceptions.reset_error_state;
            RETURN '';
    END get_adm_indication_desc;

BEGIN
    -- Initialization
    NULL;
END pk_api_adm_request;
/
