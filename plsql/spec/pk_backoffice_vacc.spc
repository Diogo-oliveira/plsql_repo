/*-- Last Change Revision: $Rev: 2028530 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:46:20 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_backoffice_vacc IS

    -- Author  : BRUNO.MARTINS
    -- Created : 21-11-2008 11:42:32
    -- Purpose : BackOffice Vaccine Management
    /********************************************************************************************
    * Returns Number of records to display in each page
    *
    * @return                        Number of records
    *
    * @author                        RMGM
    * @since                         2011/06/28
    * @version                       2.6.1.2
    ********************************************************************************************/
    FUNCTION get_num_records RETURN NUMBER;
    /********************************************************************************************
    * Get State List
    *
    * @param i_lang                Prefered language ID
    * @param i_code_domain         Code to obtain Options
    * @param o_list                List od states
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      BM
    * @version                     1.0
    * @since                       2008/12/05
    ********************************************************************************************/
    FUNCTION get_state_list
    (
        i_lang        IN language.id_language%TYPE,
        i_code_domain sys_domain.code_domain%TYPE,
        o_list        OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Set (Vaccine) Group in different softwares
    *
    * @param i_lang            Prefered language ID
    * @param i_institution     Institution ID
    * @param i_software        Software ID
    * @param i_vacc_group      Vaccine Group ID
    * @param i_flg_type        Operation to perform on database
    * @param o_error           Error
    *
    *
    * @return                  true or false on success or error
    *
    * @author                  BM
    * @version                 1.0
    * @since                   2008/11/21
    ********************************************************************************************/
    FUNCTION set_group_state
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN software.id_software%TYPE,
        i_group       IN NUMBER,
        i_flg_type    IN VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get (Vaccine) Group List
    *
    * @param i_lang                  Prefered language ID
    * @param i_institution           Institution ID
    * @param i_software_t            Table of Software ID's
    * @param i_context               Context
    * @param i_search                Search filter
    * @param o_g_list                Vaccine Group List
    * @param o_error                 Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      BM
    * @version                     1.0
    * @since                       2008/11/24
    ********************************************************************************************/
    FUNCTION get_group_list
    (
        i_lang           IN language.id_language%TYPE,
        i_institution    IN vacc_type_group_soft_inst.id_institution%TYPE,
        i_software_t     IN table_number,
        i_context        IN VARCHAR2,
        i_search         IN VARCHAR2,
        o_inst_pesq_list OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get (Vaccine) Group Type List
    *
    * @param i_lang                  Prefered language ID
    * @param i_institution           Institution ID
    * @param o_gt_list               Vaccine Group Type List
    * @param o_error                 Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      BM
    * @version                     1.0
    * @since                       2008/11/24
    ********************************************************************************************/
    FUNCTION get_group_type_list
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN vacc_type_group_soft_inst.id_institution%TYPE,
        o_gt_list     OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get Vaccine List
    *
    * @param i_lang                  Prefered language ID
    * @param i_group                 Group Id
    * @param o_vacc_list             Vaccine List
    * @param o_error                 Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      BM
    * @version                     1.0
    * @since                       2008/11/24
    ********************************************************************************************/
    FUNCTION get_vacc_list
    (
        i_lang      IN language.id_language%TYPE,
        i_group     IN vacc_type_group.id_vacc_type_group%TYPE,
        o_vacc_list OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get Vaccine Details
    *
    * @param i_prof                  Object Profissional (professional ID, institution ID, software ID)
    * @param i_lang                  Prefered language ID
    * @param i_vacc                  Vaccine Id
    * @param o_vacc_details          Vaccine Details
    * @param o_error                 Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      BM
    * @version                     1.0
    * @since                       2008/11/24
    ********************************************************************************************/
    FUNCTION get_vacc_details
    (
        i_prof         IN profissional,
        i_lang         IN language.id_language%TYPE,
        i_vacc         IN vacc.id_vacc%TYPE,
        o_vacc_details OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get Vaccine CI 
    *
    * @param i_lang                  Prefered language ID
    * @param i_vacc                  Vaccine Id
    * @param o_vacc_ci               CI
    * @param o_error                 Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      BM
    * @version                     1.0
    * @since                       2008/11/24
    ********************************************************************************************/
    FUNCTION get_vacc_ci
    (
        i_lang    IN language.id_language%TYPE,
        i_vacc    IN vacc.id_vacc%TYPE,
        o_vacc_ci OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get Vaccine Doses 
    *
    * @param i_lang                  Prefered language ID
    * @param i_vacc                  Vaccine Id
    * @param o_vacc_dose             Doses
    * @param o_error                 Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      BM
    * @version                     1.0
    * @since                       2008/11/24
    ********************************************************************************************/
    FUNCTION get_vacc_dose
    (
        i_lang      IN language.id_language%TYPE,
        i_vacc      IN vacc.id_vacc%TYPE,
        o_vacc_dose OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_vacc_type_group_state
    (
        i_lang        IN language.id_language%TYPE,
        i_group       IN vacc_type_group_soft_inst.id_vacc_type_group%TYPE,
        i_institution IN vacc_type_group_soft_inst.id_institution%TYPE,
        i_software    IN vacc_type_group_soft_inst.id_software%TYPE
    ) RETURN VARCHAR2;
    /********************************************************************************************
    * Get (Vaccine) Group List state
    *
    * @param i_lang                  Prefered language ID
    * @param i_institution           Institution ID
    * @param i_software              array of Software
    * @param i_vacc_tg               Vacinnes type group
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     2.6.1.2
    * @since                       2011/07/07
    ********************************************************************************************/
    FUNCTION get_group_list_state
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software_t  IN table_number,
        i_vacc_tg     IN vacc_type_group.id_vacc_type_group%TYPE
    ) RETURN table_varchar;
    /********************************************************************************************
    * Get (Vaccine) Group List
    *
    * @param i_lang                  Prefered language ID
    * @param i_institution           Institution ID
    * @param i_software_t            Table of Software ID's
    * @param i_search                Search filter
    * @param o_count                 number of total records
    * @param o_error                 Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     1.0
    * @since                       2011/07/07
    ********************************************************************************************/
    FUNCTION get_vacc_group_count
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN vacc_type_group_soft_inst.id_institution%TYPE,
        i_software_t  IN table_number,
        i_search      IN VARCHAR2,
        o_count       OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Get (Vaccine) Group List
    *
    * @param i_lang                  Prefered language ID
    * @param i_institution           Institution ID
    * @param i_software_t            Table of Software ID's
    * @param i_search                Search filter
    * @param i_start_record          start record
    * @param i_num_records           number of records to show   
    * @param o_inst_pesq_list        total records info
    * @param o_error                 Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     1.0
    * @since                       2011/07/07
    ********************************************************************************************/
    FUNCTION get_vacc_group_data
    (
        i_lang           IN language.id_language%TYPE,
        i_institution    IN vacc_type_group_soft_inst.id_institution%TYPE,
        i_software_t     IN table_number,
        i_search         IN VARCHAR2,
        i_start_record   IN NUMBER DEFAULT 1,
        i_num_records    IN NUMBER DEFAULT get_num_records,
        o_inst_pesq_list OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    g_error VARCHAR2(2000);

    g_who_am_i CONSTANT VARCHAR2(30) := 'PK_BACKOFFICE_VACC';

    g_all CONSTANT NUMBER(1) := 0;

END pk_backoffice_vacc;
/
