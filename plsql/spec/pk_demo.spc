/*-- Last Change Revision: $Rev: 2028595 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:46:45 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_demo AS

    /********************************************************************************************
    *
    * Contrary to all previous verions of the WR demo, this function aims to use only patients that are loaded 
    * on the grids. This way we make sure that WR will not display patients that have nothing to do with those 
    * visible in the grid.
    *
    * @param i_lang          ID language
    * @param i_prof          Registar's ID 
    * @param i_episode       Episode ID
    * @param o_error         Error output
    * 
    * @return                         true or false 
    *
    * @author                          Ricardo Nuno Almeida
    * @version                         0.1
    * @since                           2009/02/20
    *
    **********************************************************************************************/
    FUNCTION create_context_wps
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
     * Contrary to all previous verions of the WR demo, this function aims to use only patients that are loaded 
     * on the grids. This way we make sure that WR will not display patients that have nothing to do with those 
     * visible in the grid.
     *
     * @param i_lang      ID language
     * @param i_prof      Registar's ID 
     * @param o_error     Error output
     *
     * @return                         true or false 
     *
     * @author                          Ricardo Nuno Almeida
     * @version                         0.1
     * @since                           2009/02/20
    **********************************************************************************************/
    FUNCTION create_context_wps
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION create_wl_waiting_line
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_id_mach IN wl_machine.id_wl_machine%TYPE,
        i_queues  IN table_number,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    -- JC 09/03/2009 ALERT-17261 
    g_package_name  VARCHAR2(32);
    g_package_owner VARCHAR2(32);

    g_counter      NUMBER;
    g_num          NUMBER;
    g_language_num NUMBER;
    l_ret          BOOLEAN;

    pk_adm_mode                NUMBER;
    pk_med_mode                NUMBER;
    pk_nur_mode                NUMBER;
    pk_id_software             software.id_software%TYPE;
    g_flg_epis_type_nurse_care epis_type.id_epis_type%TYPE;
    g_flg_epis_type_nurse_outp epis_type.id_epis_type%TYPE;
    g_flg_epis_type_nurse_pp   epis_type.id_epis_type%TYPE;
    pk_nur_flg_type            VARCHAR2(0050);
    pk_e_status                VARCHAR2(0050);
    pk_a_status                VARCHAR2(0050);
    pk_x_status                VARCHAR2(0050);
    xsp                        VARCHAR2(0050);
    xpl                        VARCHAR2(0050);
    pk_wl_id_sonho             VARCHAR2(0050);
    pk_nurse_queue             VARCHAR2(0050);
    pk_id_department           VARCHAR2(0050);
    pk_wl_lang                 VARCHAR2(0050);
    g_error                    VARCHAR2(4000);
    g_flg_ehr                  VARCHAR2(1);
    g_flg_status_c             VARCHAR2(1);
    g_flg_status_a             VARCHAR2(1);
    g_flg_select_s             VARCHAR2(1);
    g_flg_state_m              VARCHAR2(1);
    g_flg_state_d              VARCHAR2(1);
    g_yes                      VARCHAR2(1);

    g_flg_type_queue_doctor   VARCHAR2(1);
    g_flg_type_queue_nurse    VARCHAR2(1);
    g_flg_type_queue_registar VARCHAR2(1);
    g_flg_type_queue_nur_cons VARCHAR2(1);

    g_rownum         NUMBER;
    g_error_msg_code VARCHAR2(200);
END;
/
