CREATE OR REPLACE PACKAGE pk_dynamic_detail IS

    -- Author  : PEDRO.TEIXEIRA
    -- Created : 02/10/2019 15:21:46
    -- Purpose : Handle Dynamic Detail processing

    -- Public type declarations
    g_area_med_error         dd_area.area%TYPE := 'MED_ERROR';
    g_area_out_on_pass       dd_area.area%TYPE := 'OUT_ON_PASS';
    g_area_presc             dd_area.area%TYPE := 'PRESC';
    g_area_presc_dispense    dd_area.area%TYPE := 'PRESC_DISPENSE';
    g_area_presc_det         dd_area.area%TYPE := 'PRESC_DET';
    g_area_opinion           dd_area.area%TYPE := 'OPINION';
    g_area_pha_car           dd_area.area%TYPE := 'PHA_CAR';
    g_area_pha_car_model     dd_area.area%TYPE := 'PHA_CAR_CONFIGS';
    g_area_hhc_discharge     dd_area.area%TYPE := 'HHC_DISCHARGE';
    g_area_positioning       dd_area.area%TYPE := 'POSITIONING';
    g_area_positioning_plan  dd_area.area%TYPE := 'POSITIONING_PLAN';
    g_area_blood_products    dd_area.area%TYPE := 'BLOOD_PRODUCTS';
    g_area_presc_task        dd_area.area%TYPE := 'PRESC_TASK';
    g_area_presc_hm_review   dd_area.area%TYPE := 'HM_REVIEW';
    g_area_blood_type        dd_area.area%TYPE := 'BLOOD_TYPE';
    g_area_exam_order        dd_area.area%TYPE := 'EXAM_ORDER';
    g_area_presc_med_recon   dd_area.area%TYPE := 'MED_RECON';
    g_area_complaint         dd_area.area%TYPE := 'COMPLAINT';
    g_area_health_education  dd_area.area%TYPE := 'HEALTH_EDUCATION';
    g_area_external_referral dd_area.area%TYPE := 'EXTERNALREFERRAL';
    g_area_hand_off          dd_area.area%TYPE := 'HAND_OFF';
    g_area_event             dd_area.area%TYPE := 'EVENT';
    g_area_consults          dd_area.area%TYPE := 'CONSULTS';
    g_rehab_treatment        dd_area.area%TYPE := 'REHAB_TREATMENT';
    g_rehab_session          dd_area.area%TYPE := 'REHAB_SESSION';
    g_area_exam_order_tech   dd_area.area%TYPE := 'EXAM_ORDER_TECHNICIAN';
    g_scheduled_mcdt         dd_area.area%TYPE := 'SCHEDULED_MCDT';
    g_scheduled_lab_test     dd_area.area%TYPE := 'SCHEDULED_LAB_TEST';
    g_exams                  dd_area.area%TYPE := 'EXAMS';
    g_lab_test_order         dd_area.area%TYPE := 'LAB_TEST_ORDER';
    g_follow_up_notes        dd_area.area%TYPE := 'FOLLOW_UP_NOTES';
    g_procedures             dd_area.area%TYPE := 'PROCEDURES';
    g_order_set_bo           dd_area.area%TYPE := 'ORDER_SET_BO';
    g_order_set_group        dd_area.area%TYPE := 'ORDER_SET_GROUP';

    --
    g_area_hhc_request ds_component.internal_name%TYPE := 'DS_HHC_REQUEST';
    /********************************************************************************************
    * Get Detail
    *
    * @param   i_lang                   Professional preferred language
    * @param   i_prof                   Professional identification and its context (institution and software)        
    * @param   i_area                   Detail Area
    * @param   i_id                     Detail identifier (can be any identifier, it depends on the detail area)
    * @param   o_detail                 Output cursor with detail data
    * @param   o_table_detail           Output cursor with detail table data (data that constructs tables inside detail)
    * @param   o_error                  Error
    *
    * @return   true (sucess), false (error)
    *
    * @author  Pedro Teixeira
    * @since   02/10/2019
    ********************************************************************************************/
    FUNCTION get_detail
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_area         IN VARCHAR2,
        i_id           IN NUMBER,
        o_detail       OUT pk_types.cursor_type,
        o_table_detail OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get Detail history
    *
    * @param   i_lang                   Professional preferred language
    * @param   i_prof                   Professional identification and its context (institution and software)        
    * @param   i_area                   Detail Area
    * @param   i_id                     Detail identifier (can be any identifier, it depends on the detail area)
    * @param   o_detail                 Output cursor with detail data
    * @param   o_error                  Error
    *
    * @return   true (sucess), false (error)
    *
    * @author  Pedro Teixeira
    * @since   02/10/2019
    ********************************************************************************************/
    FUNCTION get_detail_hist
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_area   IN VARCHAR2,
        i_id     IN NUMBER,
        o_detail OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;

END pk_dynamic_detail;
/
