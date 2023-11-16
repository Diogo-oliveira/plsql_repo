/*-- Last Change Revision: $Rev: 2028741 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:47:39 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_inp_detail IS

    -- Author  : Filipe Silva
    -- Created : 11-04-2011 
    -- Purpose : Aggregate all functions to build a detail/history task for a detail screen

    /**
    * get_signature_text                    Get the signature text given the professional and date
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_id_episode                Episode id
    * @param   i_id_prof                   Professional 
    * @param   i_date                      Date
    * @param   i_code_desc                 Signature code message    
    * @param   i_flg_show_sw               Y-the software should be shown in the signature. N - otherwise
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  Sofia Mendes
    * @version v2.6.0.5
    * @since   18-Jan-2011
    */
    FUNCTION get_signature
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_episode  IN episode.id_episode%TYPE,
        i_date                IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_id_prof_last_change IN professional.id_professional%TYPE,        
        i_code_desc           IN sys_message.code_message%TYPE DEFAULT pk_prog_notes_constants.g_sm_registered,
        i_flg_show_sw         IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        i_id_software         IN software.id_software%TYPE DEFAULT NULL
    ) RETURN VARCHAR2;

    /**
    * Adds a new value to a table_number object
    *
    * @param   io_table_1                    Table that will have the new value
    * @param   i_value_1                     New value
    * @param   io_table_2                    Table that will have the new value
    * @param   i_value_2                     New value
    * @param   io_table_3                    Table that will have the new value
    * @param   i_value_3                     New value
    *
    * @author  Sofia Mendes
    * @version v2.6.0.5
    * @since   13-Jan-2011
    */
    PROCEDURE add_3_values
    (
        io_table_1 IN OUT table_varchar,
        i_value_1  IN VARCHAR2,
        io_table_2 IN OUT table_varchar,
        i_value_2  IN VARCHAR2,
        io_table_3 IN OUT table_varchar,
        i_value_3  IN VARCHAR2
    );

    /**
    * Adds a new value to a table_varchar object
    *
    * @param   io_table                    Table that will have the new value
    * @param   i_value                     New value
    *
    * @author  Alexandre Santos
    * @version v2.6.0.3
    * @since   11-06-2010
    */
    PROCEDURE add_value
    (
        io_table IN OUT table_varchar,
        i_value  IN VARCHAR2
    );

    /**
    * Calcule record state
    *
    * @param   io_table                    Table that will have the new value
    * @param   i_value                     New value
    *
    * @author  Filipe Silva
    * @version v2.6.1
    * @since   11-04-2011
    */
    FUNCTION get_info_values(i_row_flg_status IN VARCHAR2) RETURN table_varchar;

    /**
    * Send identifier for flash to format the text.
    *
    * @param   io_table                    Table that will have the new value
    * @param   i_value                     New value
    *
    * @author  Filipe Silva
    * @version v2.6.1
    * @since   11-04-2011
    */
    FUNCTION get_info_labels RETURN table_varchar;

    /**********************************************************************************************
    * Adds a new item to the table of INPATIENT Detail
    *
    * @param   i_id_detail                   Identifier of the new item
    * @param   i_label_descr                 Label value to show
    * @param   i_value_descr                 Description of the value to show
    * @param   i_flg_type                    Type of item to insert
    * @param   i_flg_status                  Status of the item
    * @param   io_tab_det                    Structure type where the items will be added
    *
    * @author                                António Neto
    * @version                               v2.6.1
    * @since                                 17-May-2011
    **********************************************************************************************/
    PROCEDURE add_new_item
    (
        i_id_detail   IN NUMBER,
        i_label_descr IN VARCHAR2,
        i_value_descr IN CLOB,
        i_flg_type    IN VARCHAR2,
        i_flg_status  IN VARCHAR2,
        io_tab_det    IN OUT t_table_inp_detail
    );

    -- Local Variables
    g_package_owner VARCHAR2(50);
    g_package_name  VARCHAR2(50);
    --
    g_error VARCHAR2(2000);

    g_detail_d     CONSTANT VARCHAR2(1 CHAR) := 'D';
    g_history_h    CONSTANT VARCHAR2(1 CHAR) := 'H';
    g_det_active_a CONSTANT VARCHAR2(1 CHAR) := 'A';

    -- type of content to be returned in the detail/history screens
    g_title_t       CONSTANT VARCHAR2(1) := 'T';
    g_content_c     CONSTANT VARCHAR2(1) := 'C';
    g_signature_s   CONSTANT VARCHAR2(1) := 'S';
    g_new_content_n CONSTANT VARCHAR2(1) := 'N';
    g_line_l        CONSTANT VARCHAR2(1) := 'L';
    --a content under other content
    g_content_sc      CONSTANT VARCHAR2(2) := 'SC';
    g_new_content_nsc CONSTANT VARCHAR2(3) := 'NSC';		
    --detail null value
    g_detail_empty CONSTANT VARCHAR2(3) := '---';

END pk_inp_detail;
/
