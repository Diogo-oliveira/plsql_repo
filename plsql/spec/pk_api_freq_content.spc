/*-- Last Change Revision: $Rev: 1682955 $*/
/*-- Last Change by: $Author: joao.melao $*/
/*-- Date of last change: $Date: 2015-02-03 17:29:42 +0000 (ter, 03 fev 2015) $*/

CREATE OR REPLACE PACKAGE pk_api_freq_content IS

  /********************************************************************************************
  * Get   structure available in the institution and  software
  *
  *
  * @author                        JM
  * @version                       2.6.4.4
  * @since                         2014/07/24
  ********************************************************************************************/
  FUNCTION get_inst_structure(i_lang        IN language.id_language%TYPE,
                                  i_institution institution.id_institution%TYPE,
                                  i_software    software.id_software%type )
    RETURN t_tbl_apex_manyfields;

   /********************************************************************************************
  * Get display of searchable content available in a specific institution
  * and software
  *
  * @author                        JM
  * @version                       2.6.4.4
  * @since                         2014/07/24
  ********************************************************************************************/
  FUNCTION get_searchable_content(i_lang        IN language.id_language%TYPE,
                                  i_institution institution.id_institution%TYPE,
                                  i_software    software.id_software%type,
                                  i_context varchar,
                                  i_flg_context varchar,
                                  i_flg_content varchar)
    RETURN t_tbl_apex_manyfields;
  /********************************************************************************************
  * Get display of most freq content available in a specific institution
  * , software and dep_clin_serv
  *
  * @author                        JM
  * @version                       2.6.4.4
  * @since                         2014/07/24
  ********************************************************************************************/
  FUNCTION get_most_freq_content(i_lang          IN language.id_language%TYPE,
                                 i_institution   institution.id_institution%TYPE,
                                 i_software      software.id_software%type,
                                 i_context varchar,
                                 i_flg_context   varchar,
                                 i_flg_content   varchar)
    RETURN t_tbl_apex_manyfields;

  /********************************************************************************************
  * Set frequent content
  * Directs to a most frequent by complaint or most frequent by dep_clin_serv
  * @author                        JM
  * @version                       2.6.4.2.5
  * @since                         2015/11/25
  ********************************************************************************************/
  procedure set_freq(i_lang           varchar,
                     i_id_institution varchar,
                     i_id_software    varchar,
                     i_operation      varchar default 'A',
                     i_flg_context    varchar,
                     i_flg_content    varchar,
                     i_id_context     table_varchar,
                     i_id_content     table_varchar);

  -- useful vars
  g_flg_available  VARCHAR2(1) := 'Y';
  g_no             VARCHAR2(1) := 'N';
  g_active         VARCHAR2(1);
  g_apex_separator VARCHAR(1) := '|';
  g_freq_var       VARCHAR(1) := 'M';
  g_default_rank   number := 0;

  -- vars to match flg_context
  g_dcs   VARCHAR2(1) := 'D';
  g_compl VARCHAR2(1) := 'C';
  g_error VARCHAR2(2000);

  -- vars to match flg_content
  g_flg_lab_test_condition      varchar(1) := 'A';
  g_flg_lab_group_condition     varchar(2) := 'AG';
  g_flg_img_exam_condition      varchar(1) := 'I';
  g_flg_other_exam_condition    varchar(1) := 'O';
  g_flg_diag_condition          varchar(1) := 'D';
  g_flg_procedures_condition    varchar(1) := 'P';
  g_flg_sr_procedures_condition varchar(2) := 'SP';
  g_flg_sample_text_condition   varchar(2) := 'ST';
  g_flg_rehab_condition         varchar(1) := 'R';
  g_flg_body_diagrams_condition varchar(2) := 'BD';
  g_flg_exam_cat_condition      varchar(2) := 'EC';
  g_flg_order_sets_condition    varchar(2) := 'OS';
  -- vars to match flg_operation
  g_operation_a  varchar(1) := 'A';
  g_operation_r  varchar(2) := 'R';
  g_operation_ar varchar(2) := 'AR';

  -- debug vars
  g_package_owner VARCHAR2(50);
  g_package_name  VARCHAR2(100);
  g_function_name VARCHAR2(100);
END pk_api_freq_content;
/
