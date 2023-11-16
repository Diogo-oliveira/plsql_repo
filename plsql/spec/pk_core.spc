/*-- Last Change Revision: $Rev: 2028577 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:46:37 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_core IS

    /** @headcom
    * Public Function. Returns default code for epis_type not known.
    *
    * @return     varchar2
    * @author     Carlos Ferreira
    * @version    1.0
    * @since      2010/04/16
    */
    FUNCTION get_default_code_epis_ext RETURN VARCHAR2;

    /** @headcom
    * Public Function. Returns market for given institution.
    *
    * @param      I_institution              ID of instituition
    *
    * @return     number
    * @author     Carlos Ferreira
    * @version    1.0
    * @since      2006/11/04
    */
    FUNCTION get_inst_mkt(i_id_institution IN institution.id_institution%TYPE) RETURN market.id_market%TYPE result_cache;

    -- Author  : SUSANA SEIXAS
    -- Created : 17-07-2008 09:49:39
    -- Purpose : Contains CORE functions

    /********************************************************************************************
     * Get status in specific format: id_shortcut|next execution date|type|color|icon name or text
     *
     * @param i_lang                    Preferred language ID for this professional
     * @param i_prof                    Object (professional ID, institution ID, software ID)
     * @param i_epis_status             Episode status
     * @param i_flg_time                Execution type
     * @param i_flg_status              Request status
     * @param i_dt_begin                Begin date
     * @param i_dt_req                  Request date
     * @param i_icon_name               Status' icon name
     * @param o_error                   Error
     *
     * @return                          true or false on success or error
     *
     * @author                           SS
     * @version                          0.1
     * @since                            2008/07/17
    **********************************************************************************************/

    FUNCTION get_string_task
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_flg_type    IN VARCHAR2,
        i_epis_status IN episode.flg_status%TYPE,
        i_flg_time    IN VARCHAR2,
        i_flg_status  IN VARCHAR2,
        i_dt_begin    IN TIMESTAMP,
        i_dt_req      IN TIMESTAMP,
        i_icon_name   IN VARCHAR2,
        o_error       OUT VARCHAR2
    ) RETURN VARCHAR2;

    /** @headcom
    * Public Function. Returns disclaimer for given market.
    *
    * @param      I_LANG              language configured
    * @param      I_PROF              object (ID of professional, ID of instituition, ID of software)
    * @param      O_txt_disclaimer    disclaimer text returned
    * @param      O_ERROR             erro
    *
    * @return     boolean
    * @author     Carlos Ferreira
    * @version    1.0
    * @since      2006/10/16
    */

    FUNCTION get_disclaimer
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        o_txt_disclaimer      OUT VARCHAR2,
        o_copyright           OUT VARCHAR2,
        o_version             OUT VARCHAR2,
        o_version_label       OUT VARCHAR2,
        o_disclaimer_duration OUT NUMBER,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /** @headcom
    * Public Function. Returns interface code of given epis_type.
    *
    * @param      I_LANG              language configured
    * @param      I_ID_EPIS_TYPE      Given epis_type
    *
    * @return     varchar2            Code of type
    * @author     Carlos Ferreira
    * @version    1.0
    * @since      2006/10/16
    */
    FUNCTION get_code_epis_ext
    (
        i_lang         IN language.id_language%TYPE,
        i_id_epis_type IN epis_type.id_epis_type%TYPE
    ) RETURN VARCHAR2;

    /** 
    * Public Function. Returns error text for debugging purposes.
    *
    * @param      I_PROF              professional info (  )
    * @param      i_lcall             id of log rows to return
    *
    * @return     o_log               debugging information
    * @author     Carlos Ferreira
    * @version    1.0
    * @since      2012/10/24
    */
    FUNCTION get_logtext
    (
        i_prof  IN profissional,
        i_lcall IN NUMBER,
        o_log   OUT pk_types.cursor_type
    ) RETURN BOOLEAN;

    g_error        VARCHAR2(4000);
    g_found        BOOLEAN;
    g_sysdate_tstz TIMESTAMP WITH TIME ZONE;
    g_icon         VARCHAR2(1);
    g_message      VARCHAR2(1);
    g_color_red    VARCHAR2(1);
    g_color_green  VARCHAR2(1);
    g_no_color     VARCHAR2(1);

    g_text VARCHAR2(1);
    g_date VARCHAR2(1);

    g_package_owner CONSTANT VARCHAR2(50 CHAR) := 'ALERT';
    g_package_name VARCHAR2(50 CHAR);

END pk_core;
/
