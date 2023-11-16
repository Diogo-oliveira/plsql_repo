/*-- Last Change Revision: $Rev: 2028661 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:47:10 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_edis_hist AS

    -- Author  : ALEXANDRE.SANTOS
    -- Created : 05-08-2011 08:00:00
    -- Purpose : Manage history logic

    -- Public type declarations

    -- Public variable declarations

    -- type of content to be returned in the detail/history screens
    g_type_title          CONSTANT VARCHAR2(1 CHAR) := 'T';
    g_type_subtitle       CONSTANT VARCHAR2(2 CHAR) := 'ST';
    g_type_content        CONSTANT VARCHAR2(1 CHAR) := 'C';
    g_type_new_content    CONSTANT VARCHAR2(1 CHAR) := 'N';
    g_type_signature      CONSTANT VARCHAR2(1 CHAR) := 'S';
    g_type_empty_line     CONSTANT VARCHAR2(1 CHAR) := 'L';
    g_type_title_italic   CONSTANT VARCHAR2(2 CHAR) := 'TI';
    g_type_content_italic CONSTANT VARCHAR2(2 CHAR) := 'CI';
    g_type_white_line     CONSTANT VARCHAR2(2 CHAR) := 'WL';
    g_type_slash_line     CONSTANT VARCHAR2(2 CHAR) := 'LT';

    -- Information label
    g_info_lbl_rec_state_format CONSTANT VARCHAR2(30) := 'RECORD_STATE_TO_FORMAT';
    g_info_lbl_rec_action       CONSTANT VARCHAR2(30) := 'RECORD_ACTION';
    g_info_lbl_desc_rec_action  CONSTANT VARCHAR2(30) := 'RECORD_DESC_ACTION';
    g_info_lbl_change_date      CONSTANT VARCHAR2(30) := 'RECORD_CHANGE_DATE';
    g_info_lbl_change_prof      CONSTANT VARCHAR2(30) := 'RECORD_CHANGE_PROF';
    g_info_lbl_change_prof_spec CONSTANT VARCHAR2(30) := 'RECORD_CHANGE_PROF_SPEC';

    g_call_detail CONSTANT VARCHAR2(1 CHAR) := 'D';
    g_call_hist   CONSTANT VARCHAR2(1 CHAR) := 'H';

    -- Public function and procedure declarations

    PROCEDURE init_vars;

    PROCEDURE reset_vars;

    PROCEDURE add_line
    (
        i_history         IN NUMBER,
        i_dt_hist         IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_record_state    IN VARCHAR2,
        i_desc_rec_state  IN VARCHAR2,
        i_desc_cat_viewer IN VARCHAR2 DEFAULT '',
        i_professional    IN professional.id_professional%TYPE DEFAULT NULL,
        i_episode         IN episode.id_episode%TYPE DEFAULT NULL
    );

    PROCEDURE add_info_value
    (
        i_label IN VARCHAR2,
        i_value IN VARCHAR2
    );

    PROCEDURE add_value
    (
        i_lang        IN language.id_language%TYPE DEFAULT NULL,
        i_flg_call    IN VARCHAR2 DEFAULT g_call_detail,
        i_label       IN VARCHAR2,
        i_value       IN CLOB,
        i_type        IN VARCHAR2,
        i_code        IN VARCHAR2 DEFAULT '',
        i_title_code  IN VARCHAR2 DEFAULT '',
        i_title_desc  IN VARCHAR2 DEFAULT '',
        i_title_value IN VARCHAR2 DEFAULT '',
        i_title_type  IN VARCHAR2 DEFAULT g_type_subtitle,
        i_old_value   IN CLOB DEFAULT ''
    );

    PROCEDURE add_value
    (
        i_lang        IN language.id_language%TYPE DEFAULT NULL,
        i_flg_call    IN VARCHAR2 DEFAULT g_call_detail,
        i_label       IN VARCHAR2,
        i_value       IN CLOB,
        i_type        IN VARCHAR2,
        i_code        IN VARCHAR2 DEFAULT '',
        i_title_code  IN table_varchar,
        i_title_desc  IN table_varchar,
        i_title_value IN table_varchar,
        i_title_type  IN table_varchar,
        i_old_value   IN CLOB DEFAULT ''
    );

    PROCEDURE add_value_if_not_null
    (
        i_lang        IN language.id_language%TYPE DEFAULT NULL,
        i_flg_call    IN VARCHAR2 DEFAULT g_call_detail,
        i_label       IN VARCHAR2,
        i_value       IN CLOB,
        i_type        IN VARCHAR2,
        i_code        IN VARCHAR2 DEFAULT '',
        i_title_code  IN VARCHAR2 DEFAULT '',
        i_title_desc  IN VARCHAR2 DEFAULT '',
        i_title_value IN VARCHAR2 DEFAULT '',
        i_title_type  IN VARCHAR2 DEFAULT g_type_subtitle,
        i_old_value   IN CLOB DEFAULT ''
    );

    PROCEDURE add_value_if_not_null
    (
        i_lang        IN language.id_language%TYPE DEFAULT NULL,
        i_flg_call    IN VARCHAR2 DEFAULT g_call_detail,
        i_label       IN VARCHAR2,
        i_value       IN CLOB,
        i_type        IN VARCHAR2,
        i_code        IN VARCHAR2 DEFAULT '',
        i_title_code  IN table_varchar,
        i_title_desc  IN table_varchar,
        i_title_value IN table_varchar,
        i_title_type  IN table_varchar,
        i_old_value   IN CLOB DEFAULT ''
    );

    FUNCTION tf_hist RETURN t_table_edis_hist;

    /**
    * Get detail/history signature line
    * Based on PK_INP_HIDRICS.GET_SIGNATURE function
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_id_episode                Episode id
    * @param   i_date                      Date of the insertion/last change
    * @param   i_id_prof_last_change       Professional id that performed the insertion/ last change
    * @param   i_has_historical_changes    The record has historical of changes or not. Used to select the corresponding label ("Updated:" or "Documented:")
    *
    * @value  i_has_historical_changes      {*} 'Y'  Has historical data, use "Updated:" {*} 'N'  Has no historical data, use "Documented:"(Default)
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  Alexandre Santos
    * @version 2.6.2
    * @since   01-08-2011
    */
    FUNCTION get_signature
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_id_episode             IN episode.id_episode%TYPE,
        i_date                   IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_id_prof_last_change    professional.id_professional%TYPE,
        i_has_historical_changes IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_desc_signature         IN VARCHAR2 DEFAULT NULL
    ) RETURN VARCHAR2;
END;
/
