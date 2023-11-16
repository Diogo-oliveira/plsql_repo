/*-- Last Change Revision: $Rev: 2029011 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:49:17 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_timeline_core IS

    -- Author  : LUIS.MAIA
    -- Created : 05-06-2009 15:57:09
    -- Purpose : This package should have CORE timeline code

    -- Local Variables
    g_package_owner VARCHAR2(50);
    g_package_name  VARCHAR2(50);
    --
    g_ret   BOOLEAN;
    g_error VARCHAR2(4000);
    g_general_error CONSTANT VARCHAR2(16) := 'COMMON_M001';
    --
    g_tl_timezone VARCHAR2(200);

    --
    g_format_mask_day         CONSTANT VARCHAR2(8) := 'yyyymmdd';
    g_format_mask_month       CONSTANT VARCHAR2(6) := 'yyyymm';
    g_format_mask_year        CONSTANT VARCHAR2(4) := 'yyyy';
    g_format_mask_short_hour  CONSTANT VARCHAR2(4) := 'hh24';
    g_format_mask_short_month CONSTANT VARCHAR2(2) := 'mm';
    g_format_mask_short_day   CONSTANT VARCHAR2(2) := 'dd';
    --
    g_one_second  CONSTANT NUMBER(24, 16) := 0.0000115740740740741;
    g_daily_hours CONSTANT NUMBER(24) := 24;

    --
    -- Structures
    --
    g_tab_reg_date tl_tab_reg_date := tl_tab_reg_date(tl_reg_date(NULL, NULL, NULL, NULL));

    FUNCTION get_date_string
    (
        i_lang     IN VARCHAR2,
        i_dt_param IN VARCHAR2,
        i_dt_begin IN DATE,
        i_dt_end   IN DATE DEFAULT NULL,
        i_format   IN VARCHAR2
    ) RETURN VARCHAR2;

    FUNCTION get_date_string_week
    (
        i_lang     IN VARCHAR2,
        i_dt_param IN table_varchar,
        i_dt_begin IN DATE,
        i_dt_end   IN DATE DEFAULT NULL,
        i_format   IN VARCHAR2
    ) RETURN VARCHAR2;

    FUNCTION get_date_string_month
    (
        i_lang     IN VARCHAR2,
        i_dt_param IN table_varchar,
        i_dt_begin IN DATE,
        i_dt_end   IN DATE DEFAULT NULL,
        i_format   IN VARCHAR2
    ) RETURN VARCHAR2;

    /*******************************************************************************************************************************************
    * Nome :                          initialize                                                                                               *
    * Descrição:  initialize all constants and global variables needed in the timeline                                                         *
    *                                                                                                                                          *
    *                                                                                                                                          *
    *                                                                                                                                          *
    * @raises                         Generic oracle error                                                                                     *
    *                                                                                                                                          *
    * @author                         Carlos Vieira                                                                                            *
    * @version                         1.0                                                                                                     *
    * @since                          2008/04/17                                                                                               *
    *******************************************************************************************************************************************/
    FUNCTION initialize
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /*******************************************************************************************************************************************
    * Nome :                          GET_TIMELINE_DATA                                                                                        *
    * Descrição:  Função que devolve as diferentes escalas horizontais para preenchimento da timeline e respectivos episodios                  *
    *                                                                                                                                          *
    * @param I_LANG                   ID da linguagem para traduções                                                                           *
    * @param I_PROF                   Vector com a informação relativa  ao profissional, instituição e software                                *
    * @param ID_TL_TIMELINE           ID da TIMELINE                                                                                           *
    * @param ID_TL_SCALE              ID da ESCALA                                                                                             *
    * @param I_BLOCK_REQ_NUMBER       Número de blocos de informação pedidos                                                                   *
    * @param I_REQUEST_DATE           Data a partir da qual é pedida a informação                                                              *
    * @param I_DIRECTION              Direcção para onde devem ser contados os blocos de tempo a devolver                                      *
    * @param I_PATIENT                ID do paciente                                                                                           *
    * @param O_X_data                 Cursor que devolve os titulos dos blocos expl: Década 1990                                               *
    * @param O_episode                Cursor que devolve os episodios                                               *
    * @param O_ERROR                  Devolução do erro                                                                                        *
    *                                                                                                                                          *
    * @value I_DIRECTION              R-RIGHT, L-LEFT, B-BOTH                                                                                  *
    *                                                                                                                                          *
    * @return                         Devolve false em caso de erro e true caso contrário                                                      *
    * @raises                         Erro genérico de oracle                                                                                  *
    *                                                                                                                                          *
    * @author                         Carlos Vieira                                                                                            *
    * @version                         1.0                                                                                                     *
    * @since                          2008/04/16                                                                                               *
    *******************************************************************************************************************************************/

    FUNCTION get_timeline_data
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        id_tl_timeline     IN tl_timeline.id_tl_timeline%TYPE,
        id_tl_scale        IN tl_scale.id_tl_scale%TYPE,
        i_block_req_number IN NUMBER,
        i_request_date     IN VARCHAR2,
        i_direction        IN VARCHAR2 DEFAULT 'B',
        i_patient          IN NUMBER,
        o_x_data           OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /*******************************************************************************************************************************************
    * Gets all the scales available for any given timeline                  
    *                                                                                                                                          
    * @param I_LANG                   Language ID                                                                           
    * @param I_PROF                   Professional information array                                
    * @param ID_TL_TIMELINE           Timeline ID                                                                                           
    * @param O_tl_timeline            Contains the scales available in the given timeline
    * @param O_ERROR                  Devolução do erro                                                                                        
    *                                                                                                                                          
    * @return                         False if an error occurs, true otherwise                                                      
    *                                                                                                                                          
    * @author                         Nelson Canastro                                                                                          
    * @version                         1.0                                                                                                     
    * @since                          15/02/2011                                                                                               
    *******************************************************************************************************************************************/
    FUNCTION get_timescale_by_tl
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_tl_timeline IN tl_scale_inst_soft_market.id_tl_timeline%TYPE,
        o_tl_scales      OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

END pk_timeline_core;
/
