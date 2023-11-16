/*-- Last Change Revision: $Rev: 2028458 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:45:53 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_api_adm_request IS

    --  API for pk_admission_request

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
    ) RETURN BOOLEAN;

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
    ) RETURN VARCHAR2;

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
    ) RETURN pk_translation.t_desc_translation;

    g_error VARCHAR2(32000); -- Stores log error messages
END pk_api_adm_request;
/
