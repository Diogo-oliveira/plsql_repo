/*-- Last Change Revision: $Rev: 2028495 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:46:08 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_api_sisprenatal_out IS

    -- Author  : JOSE.SILVA
    -- Created : 10-11-2011 17:41:54
    TYPE p_map_lab_tests_rec IS RECORD(
        id_contents  table_varchar,
        export_value VARCHAR2(1 CHAR));
        
    TYPE table_map_lab_tests IS TABLE OF p_map_lab_tests_rec INDEX BY VARCHAR2(200);

    /**
    * Get the list of patients that will be exported to the archive (both ALERT and SAIS)
    *
    * @param   i_institution               Institution ID
    * @param   i_name_archive              Archive that will use this patient universe: available values are list in the globals g_arch_*
    *
    * @return  patient mapping list
    *
    * @author  JOSE.SILVA
    * @version 2.5.1.9
    * @since   15-11-2011
    */
    FUNCTION get_patient_list
    (
        i_institution    IN institution.id_institution%TYPE,
        i_name_archive   IN VARCHAR2
    ) RETURN t_tab_sisprenatal_pat_list;
    
    /**
    * Get the information to save in the CADGES record
    *
    * @return  CADGES information (pipelined)
    *
    * @author  JOSE.SILVA
    * @version 2.5.1.9
    * @since   18-11-2011
    */
    FUNCTION get_cadges RETURN pk_types_sisprenatal.tb_rec_cadges
        PIPELINED;
        
    /**
    * Get the information to save in the REGINCO record
    *
    * @return  REGINCO information (pipelined)
    *
    * @author  JOSE.SILVA
    * @version 2.5.1.9
    * @since   18-11-2011
    */
    FUNCTION get_reginco RETURN pk_types_sisprenatal.tb_rec_reginco
      PIPELINED;
        
    /**
    * Get the information to save in the REGCONS record
    *
    * @return  REGCONS information (pipelined)
    *
    * @author  JOSE.SILVA
    * @version 2.5.1.9
    * @since   21-11-2011
    */
    FUNCTION get_regcons RETURN pk_types_sisprenatal.tb_rec_regcons
      PIPELINED;
        
    /**
    * Get the information to save in the REGVAC record
    *
    * @return  REGVAC information (pipelined)
    *
    * @author  JOSE.SILVA
    * @version 2.5.1.9
    * @since   22-11-2011
    */
    FUNCTION get_regvac RETURN pk_types_sisprenatal.tb_rec_regvac
      PIPELINED;
        
    /**
    * Get the information to save in the REGEXA record
    *
    * @return  REGEXA information (pipelined)
    *
    * @author  JOSE.SILVA
    * @version 2.5.1.9
    * @since   22-11-2011
    */
    FUNCTION get_regexa RETURN pk_types_sisprenatal.tb_rec_regexa
      PIPELINED;
      
    /**
    * Get the information to save in the REGINT record
    *
    * @return  REGINT information (pipelined)
    *
    * @author  JOSE.SILVA
    * @version 2.5.1.9
    * @since   22-11-2011
    */
    FUNCTION get_regint RETURN pk_types_sisprenatal.tb_rec_regint
      PIPELINED;

    g_lang             CONSTANT language.id_language%TYPE := 11;
    g_prof             profissional;
    g_soft_sisprenatal CONSTANT software.id_software%TYPE := 3;

    ----------- GLOBAL VARIABLES TO BE USED DURING DATA EXTRACTION
    g_pat_list_cadgest t_tab_sisprenatal_pat_list;
    g_pat_list_regcons t_tab_sisprenatal_pat_list;
    g_pat_list_regvac  t_tab_sisprenatal_pat_list;
    g_pat_list_regexa  t_tab_sisprenatal_pat_list;
    g_pat_list_reginco t_tab_sisprenatal_pat_list;
    g_pat_list_regint  t_tab_sisprenatal_pat_list;
    
    g_institution institution.id_institution%TYPE;
    -----------
    
    g_ext_sys_sais CONSTANT external_sys.id_external_sys%TYPE := 15000;
    
    g_sisprenatal_out  CONSTANT VARCHAR2(1 CHAR) := 'O';
    g_sisprenatal_in   CONSTANT VARCHAR2(1 CHAR) := 'I';
    g_sisprenatal_int  CONSTANT VARCHAR2(1 CHAR) := 'A';
    
    g_system_alert       CONSTANT VARCHAR2(20 CHAR) := 'ALERT';
    g_system_sisprenatal CONSTANT VARCHAR2(20 CHAR) := 'SISPRENATAL';
    
    g_vacc_id_code   CONSTANT VARCHAR2(1 CHAR) := 'V';
    g_vacc_dose_code CONSTANT VARCHAR2(1 CHAR) := 'D';

END pk_api_sisprenatal_out;
/
