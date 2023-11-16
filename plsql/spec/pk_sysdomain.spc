/*-- Last Change Revision: $Rev: 2029003 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:49:14 +0100 (ter, 02 ago 2022) $*/
CREATE OR REPLACE PACKAGE pk_sysdomain IS

    k_default_schema CONSTANT VARCHAR2(0010 CHAR) := 'ALERT';
    g_error VARCHAR2(4000); -- Localização do erro
    g_none_option     CONSTANT sys_message.code_message%TYPE := 'COMMON_M002';
    g_na_option       CONSTANT sys_message.code_message%TYPE := 'COMMON_M036';
    g_flg_available_y CONSTANT VARCHAR2(1) := 'Y';

    g_package_owner VARCHAR2(30);
    g_package_name  VARCHAR2(30);

    FUNCTION get_domain_cached
    (
        i_lang        LANGUAGE.id_language%TYPE,
        i_value       VARCHAR2,
        i_code_domain  sys_domain.code_domain%TYPE,
        i_domain_owner sys_domain.domain_owner%TYPE DEFAULT k_default_schema
    ) RETURN sys_domain.desc_val%TYPE;

    FUNCTION get_domain
    (
        i_code_dom IN sys_domain.code_domain%TYPE,
        i_val      IN sys_domain.val%TYPE,
        i_lang         IN sys_domain.id_language%TYPE,
        i_domain_owner sys_domain.domain_owner%TYPE DEFAULT k_default_schema
    ) RETURN VARCHAR2;

    /************************************************************************************************************ 
    * Same as get_domain but ignores flg_available
    *
    * @param      i_code_dom                        domain code
    * @param      i_val                             domain value
    * @param      i_lang                            language ID
    *
    * @return     domain description
    * @author     José Silva
    * @version    0.1
    * @since      2008/06/12
    ***********************************************************************************************************/
    FUNCTION get_domain_no_avail
    (
        i_code_dom IN sys_domain.code_domain%TYPE,
        i_val      IN sys_domain.val%TYPE,
        i_lang         IN sys_domain.id_language%TYPE,
        i_domain_owner sys_domain.domain_owner%TYPE DEFAULT k_default_schema
    ) RETURN VARCHAR2;

    FUNCTION get_values_domain
    (
        i_code_dom        IN sys_domain.code_domain%TYPE,
        i_lang            IN sys_domain.id_language%TYPE,
        o_data_grid_color OUT pk_types.cursor_type,
        i_domain_owner    sys_domain.domain_owner%TYPE DEFAULT k_default_schema
    ) RETURN BOOLEAN;

    FUNCTION get_values_domain
    (
        i_code_dom        IN sys_domain.code_domain%TYPE,
        i_lang            IN sys_domain.id_language%TYPE,
        o_data_grid_color OUT pk_types.cursor_type,
        o_error           OUT t_error_out,
        i_domain_owner    sys_domain.domain_owner%TYPE DEFAULT k_default_schema
    ) RETURN BOOLEAN;

    FUNCTION get_values_domain
    (
        i_code_dom      IN sys_domain.code_domain%TYPE,
        i_lang          IN sys_domain.id_language%TYPE,
        o_data          OUT pk_types.cursor_type,
        i_vals_included IN table_varchar,
        i_vals_excluded IN table_varchar DEFAULT NULL,
        i_domain_owner  sys_domain.domain_owner%TYPE DEFAULT k_default_schema
    ) RETURN BOOLEAN;

    FUNCTION get_values_domain
    (
        i_code_dom      IN sys_domain.code_domain%TYPE,
        i_lang          IN sys_domain.id_language%TYPE,
        o_data          OUT pk_types.cursor_type,
        o_error         OUT t_error_out,
        i_vals_included IN table_varchar,
        i_vals_excluded IN table_varchar DEFAULT NULL,
        i_domain_owner  sys_domain.domain_owner%TYPE DEFAULT k_default_schema
		,i_order         IN NUMBER DEFAULT 1
    ) RETURN BOOLEAN;

    FUNCTION get_rank
    (
        i_lang     IN sys_domain.id_language%TYPE,
        i_code_dom IN sys_domain.code_domain%TYPE,
        i_val          IN sys_domain.val%TYPE,
        i_domain_owner sys_domain.domain_owner%TYPE DEFAULT k_default_schema
    ) RETURN sys_domain.rank%TYPE;

    FUNCTION get_value
    (
        i_lang     IN sys_domain.id_language%TYPE,
        i_code_dom IN sys_domain.code_domain%TYPE,
        i_desc     IN sys_domain.desc_val%TYPE,
        o_error        OUT t_error_out,
        i_domain_owner sys_domain.domain_owner%TYPE DEFAULT k_default_schema
    ) RETURN sys_domain.val%TYPE;

    FUNCTION get_img
    (
        i_lang     IN sys_domain.id_language%TYPE,
        i_code_dom IN sys_domain.code_domain%TYPE,
        i_val          IN sys_domain.val%TYPE,
        i_domain_owner sys_domain.domain_owner%TYPE DEFAULT k_default_schema
    ) RETURN sys_domain.img_name%TYPE;

    FUNCTION get_ranked_img
    (
        i_code_dom IN sys_domain.code_domain%TYPE,
        i_val      IN sys_domain.val%TYPE,
        i_lang         IN sys_domain.id_language%TYPE,
        i_domain_owner sys_domain.domain_owner%TYPE DEFAULT k_default_schema
    ) RETURN VARCHAR2;

    /**
    * Gets sys_domains info about a code domain. 
    *
    * @param   I_LANG language associated to the professional executing the request 
    * @param   I_CODE_DOMAIN  a string identifying the domain  
    * @param   I_PROF  professional, institution and software ids 
    * @param   O_DOMAINS the cursur with the domains info  
    * @param   O_ERROR an error message, set when return=false 
    *
    * @RETURN  TRUE if sucess, FALSE otherwise 
    * @author  Luís Gaspar 
    * @version 1.0 
    * @since   19-09-2006 
    */
    FUNCTION get_domains
    (
        i_lang        IN sys_domain.id_language%TYPE,
        i_code_domain IN sys_domain.code_domain%TYPE,
        i_prof         IN profissional,
        o_domains     OUT pk_types.cursor_type,
        o_error        OUT t_error_out,
        i_domain_owner sys_domain.domain_owner%TYPE DEFAULT k_default_schema
    ) RETURN BOOLEAN;

    /**
    * Gets sys_domains info about a code domain and includes a none option on top. 
    *
    * @param   I_LANG language associated to the professional executing the request 
    * @param   I_CODE_DOMAIN  a string identifying the domain  
    * @param   I_PROF  professional, institution and software ids 
    * @param   O_DOMAINS the cursur with the domains info  
    * @param   O_ERROR an error message, set when return=false 
    *
    * @RETURN  TRUE if sucess, FALSE otherwise 
    * @author  Luís Gaspar 
    * @version 1.0 
    * @since   24-jan-2007 
    */
    FUNCTION get_domains_none_option
    (
        i_lang        IN sys_domain.id_language%TYPE,
        i_code_domain IN sys_domain.code_domain%TYPE,
        i_prof         IN profissional,
        o_domains     OUT pk_types.cursor_type,
        o_error        OUT t_error_out,
        i_domain_owner sys_domain.domain_owner%TYPE DEFAULT k_default_schema
    ) RETURN BOOLEAN;
    --
    /**
    * Gets sys_domain info about a code domain and value, but returns n.a. option if the value is null. 
    *
    * @param   I_CODE_DOMAIN  a string identifying the domain  
    * @param   I_VAL  the domain value 
    * @param   I_LANG language associated to the request 
    *
    * @RETURN  The domain description ou the n.a. option if value is null 
    * @author  Luís Gaspar 
    * @version 1.0 
    * @since   24-jan-2007 
    */
    FUNCTION get_domain_na_option
    (
        i_code_dom IN sys_domain.code_domain%TYPE,
        i_val      IN sys_domain.val%TYPE,
        i_lang         IN sys_domain.id_language%TYPE,
        i_domain_owner sys_domain.domain_owner%TYPE DEFAULT k_default_schema
    ) RETURN VARCHAR2;

    /**
    * Checks if a value is part of a domain.
    * Useful for server-side parameter validation
    *
    * @param i_code_domain the domain
    * @param i_val the value
    * @return true if ok, false otherwise
    */
    FUNCTION check_val_in_domain
    (
        i_code_domain  IN sys_domain.code_domain%TYPE,
        i_val          IN sys_domain.val%TYPE,
        i_domain_owner sys_domain.domain_owner%TYPE DEFAULT k_default_schema
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns concatenate descriptions about a set of values separated by delimiter for code_domain                                                                                                
    *                                                                                                                                          
    * @param i_lang                   Language ID                                                                                              
    * @param i_code_element_domain    Element domain ID                                                                                        
    * @param i_vals                   Element domain values separated by pipe (e.g. 1|2|3)                                                                                       
    * @param i_delim_in               Input delimiter(e.g. '|')                                                                                       
    * @param i_delim_out              Output delimiter(e.g. ';')                                                                                       
    * 
    *                                                                                                                                         
    * @return                         Returns value description                                                        
    *                                                                                                                                          
    * @author                         Ariel Geraldo Machado                                                                                    
    * @version                         1.0 (2.4.3)                                                                                                     
    * @since                          2008/05/19                                                                                               
    ********************************************************************************************/
    FUNCTION get_desc_domain_set
    (
        i_lang        IN LANGUAGE.id_language%TYPE,
        i_code_domain IN sys_domain.code_domain%TYPE,
        i_vals        IN VARCHAR2,
        i_delim_in    IN VARCHAR2 DEFAULT '|',
        i_delim_out    IN VARCHAR2 DEFAULT '; ',
        i_domain_owner sys_domain.domain_owner%TYPE DEFAULT k_default_schema
    ) RETURN VARCHAR2;

    /**************************************************************************
    * Returns a cursor of sys_domain elements valid for a                     *
    * specific institution/software/dep_clin_serv                             *                                                                  
    *                                                                         *                                                                
    * @param i_lang                   Language ID                             *                                                                
    * @param i_prof                   Profissional ID                         *                                                                    
    * @param i_code_dom               Element domain                          *
    * @param i_dep_clin_serv          Dep_clin_serv ID                        *                                                              
    * @param o_data_mkt               Output cursor                           *                                                           
    * @param o_error                  Error object                            *                                                          
    *                                                                         *
    *                                                                         *                                                               
    * @return                         Returns boolean value                   *                                     
    *                                                                         *                                                                
    * @author                         Gustavo Serrano                         *                                                          
    * @version                        1.0                                     *                                                                
    * @since                          2009/04/06                              *                                                                
    **************************************************************************/
    FUNCTION get_values_domain
    (
        i_lang          IN sys_domain.id_language%TYPE,
        i_prof          IN profissional,
        i_code_dom      IN sys_domain.code_domain%TYPE,
        i_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_data_mkt      OUT pk_types.cursor_type,
        o_error         OUT t_error_out,
        i_domain_owner  sys_domain.domain_owner%TYPE DEFAULT k_default_schema
    ) RETURN BOOLEAN;

    /**************************************************************************
    * Returns a cursor of sys_domain elements valid for a                     *
    * specific institution/software/dep_clin_serv                             *                                                                  
    *                                                                         *                                                                
    * @param i_lang                   Language ID                             *                                                                
    * @param i_prof                   Profissional ID                         *                                                                    
    * @param i_code_dom               Element domain                          *
    * @param i_dep_clin_serv          Dep_clin_serv ID                        *                                                              
    *                                                                         *                                                               
    * @return                         Returns Output cursor                   *                                     
    *                                                                         *                                                                
    * @author                         Gustavo Serrano                         *                                                          
    * @version                        1.0                                     *                                                                
    * @since                          2009/04/25                              *                                                                
    **************************************************************************/
    FUNCTION get_values_domain_pipelined
    (
        i_lang          IN sys_domain.id_language%TYPE,
        i_prof          IN profissional,
        i_code_dom      IN sys_domain.code_domain%TYPE,
        i_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_domain_owner  sys_domain.domain_owner%TYPE DEFAULT k_default_schema
    ) RETURN t_coll_values_domain_mkt
        PIPELINED;

    /**************************************************************************
    * Returns a sys_domain description for a specific val                     *
    * by institution/software/dep_clin_serv                                   *                                                                  
    *                                                                         *                                                                
    * @param i_lang                   Language ID                             *                                                                
    * @param i_prof                   Profissional ID                         *                                                                    
    * @param i_code_dom               Element domain                          *
    * @param i_val                    Element domain value                    *
    * @param i_dep_clin_serv          Dep_clin_serv ID                        *                                                              
    *                                                                         *                                                               
    * @return                         Returns sys_domain description          *                                     
    *                                                                         *                                                                
    * @author                         Gustavo Serrano                         *                                                          
    * @version                        1.0                                     *                                                                
    * @since                          2009/05/27                              *                                                                
    **************************************************************************/
    FUNCTION get_domain
    (
        i_lang          IN sys_domain.id_language%TYPE,
        i_prof          IN profissional,
        i_code_dom      IN sys_domain.code_domain%TYPE,
        i_val           IN sys_domain.val%TYPE,
        i_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_domain_owner  sys_domain.domain_owner%TYPE DEFAULT k_default_schema
    ) RETURN VARCHAR2;

    /**************************************************************************
    * Returns a domain_list_inst_soft description for a specific val          *
    * by marker/institution/software/dep_clin_serv                            *                                                                  
    *                                                                         *                                                                
    * @param i_lang                   Language ID                             *                                                                
    * @param i_prof                   Profissional ID                         *                                                                    
    * @param i_domain_list            Element domain                          *
    * @param i_val                    Element domain value                    *
    * @param i_dep_clin_serv          Dep_clin_serv ID                        *                                                              
    *                                                                         *                                                               
    * @return                         Returns sys_domain description          *                                     
    *                                                                         *                                                                
    * @author                         Gustavo Serrano                         *                                                          
    * @version                        1.0                                     *                                                                
    * @since                          2010/04/14                              *                                                                
    **************************************************************************/
    FUNCTION get_domain_list_desc
    (
        i_lang          IN LANGUAGE.id_language%TYPE,
        i_prof          IN profissional,
        i_domain_list   IN domain_list_inst_soft.domain_list%TYPE,
        i_val           IN domain_list_inst_soft.val%TYPE,
        i_dep_clin_serv IN domain_list_inst_soft.id_dep_clin_serv%TYPE,
        i_domain_owner  sys_domain.domain_owner%TYPE DEFAULT k_default_schema
    ) RETURN VARCHAR2;

    /**************************************************************************
    * Returns a cursor of domain_list_inst_soft elements valid for a          *
    * specific market/institution/software/dep_clin_serv                      *                                                                  
    *                                                                         *                                                                
    * @param i_lang                   Language ID                             *                                                                
    * @param i_prof                   Profissional ID                         *                                                                    
    * @param i_domain_list            Element domain                          *
    * @param i_dep_clin_serv          Dep_clin_serv ID                        *                                                              
    * @param o_data                   Output cursor                           *                                                           
    * @param o_error                  Error object                            *                                                          
    *                                                                         *
    *                                                                         *                                                               
    * @return                         Returns boolean value                   *                                     
    *                                                                         *                                                                
    * @author                         Gustavo Serrano                         *                                                          
    * @version                        1.0                                     *                                                                
    * @since                          2010/04/14                              *                                                                
    **************************************************************************/
    FUNCTION get_values_domain_list
    (
        i_lang          IN LANGUAGE.id_language%TYPE,
        i_prof          IN profissional,
        i_domain_list   IN domain_list_inst_soft.domain_list%TYPE,
        i_dep_clin_serv IN domain_list_inst_soft.id_dep_clin_serv%TYPE,
        o_data          OUT pk_types.cursor_type,
        o_error         OUT t_error_out,
        i_domain_owner  sys_domain.domain_owner%TYPE DEFAULT k_default_schema
    ) RETURN BOOLEAN;

    /*******************************************************************************
    * Merges a record into sys_domain table                                        *
    *                                                                              *     
    * @param i_lang              record language                                   *
    * @param i_code_domain       domain code                                       *
    * @param i_desc_val          description                                       *
    * @param i_val               flag value                                        *
    * @param i_rank              domain value rank                                 *
    * @param i_img_name          image name (optional)                             *
    * @param i_flg_available     flag that indicates availability (default = 'Y')  *
    *                                                                              * 
    ********************************************************************************/
    PROCEDURE insert_into_sys_domain
    (
        i_lang          LANGUAGE.id_language%TYPE,
        i_code_domain   sys_domain.code_domain%TYPE,
        i_desc_val      sys_domain.desc_val%TYPE,
        i_val           sys_domain.val%TYPE,
        i_rank          sys_domain.rank%TYPE DEFAULT NULL,
        i_img_name      sys_domain.img_name%TYPE DEFAULT NULL,
        i_flg_available sys_domain.flg_available%TYPE DEFAULT NULL,
        i_domain_owner  sys_domain.domain_owner%TYPE DEFAULT k_default_schema
    );

    FUNCTION get_domain_desc
    (
        i_lang         IN language.id_language%TYPE,
        i_code_domain  IN sys_domain.code_domain%TYPE,
        i_domain_owner IN sys_domain.domain_owner%TYPE DEFAULT k_default_schema
    ) RETURN table_varchar;

    FUNCTION get_domain_val
    (
        i_lang         IN language.id_language%TYPE,
        i_code_domain  IN sys_domain.code_domain%TYPE,
        i_domain_owner IN sys_domain.domain_owner%TYPE DEFAULT k_default_schema
    ) RETURN table_varchar;
	
--
    --************************************
    FUNCTION get_tbl_domain
    (
        i_lang          IN NUMBER,
        i_prof          IN profissional,
        i_code          IN VARCHAR2,
        i_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_domain_owner  IN sys_domain.domain_owner%TYPE DEFAULT k_default_schema
    ) RETURN t_tbl_core_domain;

    FUNCTION get_multichoice
    (
        i_lang          IN NUMBER,
        i_prof          IN profissional,
        i_flg_type      IN table_varchar,
        i_internal_name IN table_varchar
    ) RETURN t_tbl_core_domain;

    FUNCTION get_multichoice
    (
        i_lang          IN NUMBER,
        i_prof          IN profissional,
        i_flg_type      IN table_varchar,
        i_internal_name IN table_varchar,
        o_result        OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

END pk_sysdomain;
/
