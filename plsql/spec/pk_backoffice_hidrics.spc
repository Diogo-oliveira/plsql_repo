/*-- Last Change Revision: $Rev: 2028518 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:46:16 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_backoffice_hidrics IS

    -- Author  : TERCIO.SOARES
    -- Created : 05-02-2009 10:57:00
    -- Purpose : Backoffice de Registos Hídricos
    /********************************************************************************************
    * Returns Number of records to display in each page
    *
    * @return                        Number of records
    *
    * @author                        Tércio Soares
    * @since                         2010/06/04
    * @version                       2.6.0.3
    ********************************************************************************************/
    FUNCTION get_num_records RETURN NUMBER;

    /********************************************************************************************
    * Get Institution Searchable List
    *
    * @param i_lang                  Prefered language ID
    * @param i_id_institution        Institution ID
    * @param i_software              Software ID's
    * @param o_inst_pesq_list        List
    * @param o_error                 Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2009/02/05
    ********************************************************************************************/
    FUNCTION get_inst_hidrics_list
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN analysis_instit_soft.id_institution%TYPE,
        i_software       IN table_number,
        o_inst_pesq_list OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

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
    * @author                      JTS
    * @version                     1.0
    * @since                       2009/02/05
    ********************************************************************************************/
    FUNCTION get_state_list
    (
        i_lang        IN language.id_language%TYPE,
        i_code_domain sys_domain.code_domain%TYPE,
        o_list        OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Set Hidric state in different softwares
    *
    * @param i_lang            Prefered language ID
    * @param i_institution     Institution ID
    * @param i_software        Software ID
    * @param i_id_hidrics      Hidric ID
    * @param i_state           New hidric state
    * @param i_id_hidrics_type Hidric Type ID
    * @param o_error           Error
    *
    *
    * @return                  true or false on success or error
    *
    * @author                  JTS
    * @version                 1.0
    * @since                   2009/02/06
    ********************************************************************************************/
    FUNCTION set_inst_soft_hidric_state
    (
        i_lang            IN language.id_language%TYPE,
        i_institution     IN institution.id_institution%TYPE,
        i_software        IN software.id_software%TYPE,
        i_id_hidrics      IN hidrics.id_hidrics%TYPE,
        i_state           IN VARCHAR2,
        i_id_hidrics_type IN hidrics_type.id_hidrics_type%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get the state of hidric in the institution and software
    *
    * @param i_lang            Prefered language ID
    * @param i_institution     Institution ID
    * @param i_software        Software ID
    * @param i_id              Hidric ID
    * @param i_hidric_type     New hidric state
    *
    *
    * @return                  true or false on success or error
    *
    * @author                  JTS
    * @version                 1.0
    * @since                   2009/02/06
    ********************************************************************************************/

    FUNCTION get_inst_hidrics_list_state
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN analysis_instit_soft.id_institution%TYPE,
        i_software       IN table_number,
        i_id             IN hidrics.id_hidrics%TYPE,
        i_hidric_type    IN hidrics_type.id_hidrics_type%TYPE
    ) RETURN table_varchar;
    /********************************************************************************************
    * Get Institution Searchable List
    *
    * @param i_lang                Prefered language ID
    * @param i_id_institution      Institution ID
    * @param i_software            Software ID's
    * @param i_search              search string filter   
    * @param o_count               Number of records
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     0.1
    * @since                       2011/07/06
    ********************************************************************************************/
    FUNCTION get_inst_hidrics_count
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN analysis_instit_soft.id_institution%TYPE,
        i_software       IN table_number,
        i_search         IN VARCHAR2,
        o_count          OUT NUMBER,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Get Institution Searchable List
    *
    * @param i_lang                Prefered language ID
    * @param i_id_institution      Institution ID
    * @param i_software            Software ID's
    * @param i_search              search string filter   
    * @param i_start_record          start record
    * @param i_num_records           number of records to show   
    * @param o_count               List
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     0.1
    * @since                       2011/07/06
    ********************************************************************************************/
    FUNCTION get_inst_hidrics_data
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN analysis_instit_soft.id_institution%TYPE,
        i_software       IN table_number,
        i_search         IN VARCHAR2,
        i_start_record   IN NUMBER DEFAULT 1,
        i_num_records    IN NUMBER DEFAULT get_num_records,
        o_inst_pesq_list OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    g_error VARCHAR2(2000);

END pk_backoffice_hidrics;
/
