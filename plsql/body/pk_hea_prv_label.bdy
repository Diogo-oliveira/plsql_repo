/*-- Last Change Revision: $Rev: 1960064 $*/
/*-- Last Change by: $Author: elisabete.bugalho $*/
/*-- Date of last change: $Date: 2020-07-31 19:01:55 +0100 (sex, 31 jul 2020) $*/

CREATE OR REPLACE PACKAGE BODY pk_hea_prv_label IS

    /**
    * Returns the label for EDIS 'Admission date'
    *
    * @param i_lang                Language Id
    * @param i_prof                Professional Id
    *
    * @return                      The label
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_admission_date
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN VARCHAR IS
    BEGIN
        RETURN pk_message.get_message(i_lang, i_prof, 'EDIS_ID_T009');
    END;

    /**
    * Returns the label for 'Admission'
    *
    * @param i_lang                Language Id
    * @param i_prof                Professional Id
    *
    * @return                      The label
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_admission
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN VARCHAR IS
    BEGIN
        -- i_prof removed on purpose
        RETURN pk_message.get_message(i_lang, i_prof, 'INP_ID_T005');
    END;

    /**
    * Returns the label for 'Disposition date'
    *
    * @param i_lang                Language Id
    * @param i_prof                Professional Id
    *
    * @return                      The label
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_disposition_date
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN VARCHAR IS
    BEGIN
        RETURN pk_message.get_message(i_lang, i_prof, 'INP_ID_T005');
    END;

    /**
    * Returns the label for 'Encounter date'
    *
    * @param i_lang                Language Id
    * @param i_prof                Professional Id
    *
    * @return                      The label
    *
    * @author   Elisabete Bugalho
    * @version  2.5.0.7
    * @since    13-10-2009
    */
    FUNCTION get_epis_encounter_date
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN VARCHAR IS
    BEGIN
        RETURN pk_message.get_message(i_lang, i_prof, 'ID_M013');
    END;

    /**
    * Returns the label value for the tag given as parameter.
    *
    * @param i_lang                Language Id
    * @param i_prof                Professional Id
    * @param i_tag                 Tag to be replaced
    * @param o_data_rec            Tag's data    
    *
    * @return                      The value
    *
    * @author   Joao Sa
    * @version  2.7.1
    * @since    2017/03/08
    */
    FUNCTION get_value_html
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_tag      IN header_tag.internal_name%TYPE,
        o_data_rec OUT t_rec_header_data
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(64) := 'GET_VALUE';
        l_data_rec  t_rec_header_data := t_rec_header_data(NULL,
                                                           NULL,
                                                           NULL,
                                                           NULL,
                                                           NULL,
                                                           NULL,
                                                           NULL,
                                                           NULL,
                                                           NULL,
                                                           NULL,
                                                           NULL,
                                                           NULL);
    BEGIN
        g_error := g_package_name || ' ' || l_func_name || ' ' || i_tag;
        pk_alertlog.log_debug(g_error);
        CASE i_tag
            WHEN 'LABEL_PROCESS' THEN
                l_data_rec.text := pk_hea_prv_epis.get_process(i_lang, i_prof);
            WHEN 'LABEL_EPIS' THEN
                l_data_rec.text := pk_hea_prv_epis.get_epis(i_lang, i_prof);
            WHEN 'LABEL_LOCATION' THEN
                l_data_rec.text        := pk_hea_prv_epis.get_location(i_lang, i_prof);
                l_data_rec.description := l_data_rec.text;
            WHEN 'LABEL_ROOM_TIME' THEN
                l_data_rec.text := pk_hea_prv_epis.get_room_time(i_lang, i_prof);
            WHEN 'LABEL_TOTAL_TIME' THEN
                l_data_rec.text := pk_hea_prv_epis.get_total_time(i_lang, i_prof);
            WHEN 'LABEL_ADMISSION_DATE' THEN
                l_data_rec.text := get_admission_date(i_lang, i_prof);
            WHEN 'LABEL_LOCATION_SERVICE' THEN
                l_data_rec.text := pk_hea_prv_epis.get_location_service(i_lang, i_prof);
            WHEN 'LABEL_ADMISSION' THEN
                l_data_rec.text        := get_admission(i_lang, i_prof);
                l_data_rec.description := l_data_rec.text;
            WHEN 'LABEL_SCHEDULE' THEN
                l_data_rec.text := pk_hea_prv_epis.get_schedule(i_lang, i_prof);
            WHEN 'LABEL_REGISTER' THEN
                l_data_rec.text        := pk_hea_prv_epis.get_register(i_lang, i_prof);
                l_data_rec.description := l_data_rec.text;
            WHEN 'LABEL_WAITING' THEN
                l_data_rec.text        := pk_hea_prv_epis.get_waiting(i_lang, i_prof);
                l_data_rec.description := l_data_rec.text;
            WHEN 'LABEL_SCHEDULE_TIME' THEN
                l_data_rec.text := pk_hea_prv_epis.get_schedule(i_lang, i_prof);
            WHEN 'LABEL_SURG_EST_DUR' THEN
                l_data_rec.text := pk_hea_prv_epis.get_surg_est_dur(i_lang, i_prof);
            WHEN 'LABEL_REFERRAL_NUMBER' THEN
                l_data_rec.text := pk_hea_prv_ref.get_referral_number(i_lang, i_prof);
            WHEN 'LABEL_REFERRAL_DATE' THEN
                l_data_rec.text := pk_hea_prv_ref.get_referral_date(i_lang, i_prof);
            WHEN 'LABEL_REFERRAL_ORIGIN' THEN
                l_data_rec.text := pk_hea_prv_ref.get_referral_origin(i_lang, i_prof);
            WHEN 'LABEL_REFERRAL_DESTINY' THEN
                l_data_rec.text := pk_hea_prv_ref.get_referral_destiny(i_lang, i_prof);
            WHEN 'LABEL_REFERRAL_PROCESS' THEN
                l_data_rec.text := pk_hea_prv_ref.get_referral_process(i_lang, i_prof);
            WHEN 'LABEL_REFERRAL_SCHEDULE' THEN
                l_data_rec.text := pk_hea_prv_ref.get_referral_schedule(i_lang, i_prof);
            WHEN 'LABEL_PATIENT' THEN
                l_data_rec.text := pk_hea_prv_aud.get_audit_patient(i_lang, i_prof);
            WHEN 'LABEL_ENCOUNTER_DATE' THEN
                l_data_rec.text := pk_hea_prv_encounter.get_encounter_date(i_lang, i_prof);
            WHEN 'LABEL_ENCOUNTER_TIME_SPENT' THEN
                l_data_rec.text := pk_hea_prv_encounter.get_encounter_time_spent(i_lang, i_prof);
            WHEN 'LABEL_EPIS_ADMISSION' THEN
                l_data_rec.text        := get_epis_encounter_date(i_lang, i_prof);
                l_data_rec.description := l_data_rec.text;
                           
            ELSE
                RETURN FALSE;
        END CASE;
    
        o_data_rec := l_data_rec;
        RETURN TRUE;
    END;

    /**
    * Returns the label value for the tag given as parameter.
    *
    * @param i_lang                Language Id
    * @param i_prof                Professional Id
    * @param i_tag                 Tag to be replaced
    *
    * @return                      The value
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_value
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_tag  IN header_tag.internal_name%TYPE
    ) RETURN VARCHAR2 IS
        l_func_name VARCHAR2(64) := 'GET_VALUE';
        l_ret       BOOLEAN;
        l_data_rec  t_rec_header_data;
    BEGIN
        g_error := g_package_name || ' ' || l_func_name || ' ' || i_tag;
        pk_alertlog.log_debug(g_error);
    
        l_ret := get_value_html(i_lang, i_prof, i_tag, l_data_rec);
    
        CASE i_tag
            WHEN 'LABEL_PROCESS' THEN
                RETURN l_data_rec.text;
            WHEN 'LABEL_EPIS' THEN
                RETURN l_data_rec.text;
            WHEN 'LABEL_LOCATION' THEN
                RETURN l_data_rec.text;
            WHEN 'LABEL_ROOM_TIME' THEN
                RETURN l_data_rec.text;
            WHEN 'LABEL_TOTAL_TIME' THEN
                RETURN l_data_rec.text;
            WHEN 'LABEL_ADMISSION_DATE' THEN
                RETURN l_data_rec.text;
            WHEN 'LABEL_LOCATION_SERVICE' THEN
                RETURN l_data_rec.text;
            WHEN 'LABEL_ADMISSION' THEN
                RETURN l_data_rec.text;
            WHEN 'LABEL_SCHEDULE' THEN
                RETURN l_data_rec.text;
            WHEN 'LABEL_REGISTER' THEN
                RETURN l_data_rec.text;
            WHEN 'LABEL_WAITING' THEN
                RETURN l_data_rec.text;
            WHEN 'LABEL_SCHEDULE_TIME' THEN
                RETURN l_data_rec.text;
            WHEN 'LABEL_SURG_EST_DUR' THEN
                RETURN l_data_rec.text;
            WHEN 'LABEL_REFERRAL_NUMBER' THEN
                RETURN l_data_rec.text;
            WHEN 'LABEL_REFERRAL_DATE' THEN
                RETURN l_data_rec.text;
            WHEN 'LABEL_REFERRAL_ORIGIN' THEN
                RETURN l_data_rec.text;
            WHEN 'LABEL_REFERRAL_DESTINY' THEN
                RETURN l_data_rec.text;
            WHEN 'LABEL_REFERRAL_PROCESS' THEN
                RETURN l_data_rec.text;
            WHEN 'LABEL_REFERRAL_SCHEDULE' THEN
                RETURN l_data_rec.text;
            WHEN 'LABEL_PATIENT' THEN
                RETURN l_data_rec.text;
            WHEN 'LABEL_ENCOUNTER_DATE' THEN
                RETURN l_data_rec.text;
            WHEN 'LABEL_ENCOUNTER_TIME_SPENT' THEN
                RETURN l_data_rec.text;
            WHEN 'LABEL_EPIS_ADMISSION' THEN
                RETURN l_data_rec.text;
            ELSE
                NULL;
        END CASE;
    
        RETURN 'label_' || i_tag;
    END;

BEGIN
    g_package_name := pk_alertlog.who_am_i;
    pk_alertlog.log_init(g_package_name);
END;
/
