BEGIN
PK_FRMW_OBJECTS.insert_into_frmw_objects('ALERT', 'A_PROFILE_TEMPL_ACCESS', 'TABLE', 'DPC', 'N', '', 'N');
END;
/

--CREATE--
create table A_PROFILE_TEMPL_ACCESS
(
  id_profile_templ_access VARCHAR2(100),
  id_profile_template     VARCHAR2(100),
  rank                    VARCHAR2(100),
  id_sys_button_prop      VARCHAR2(100),
  flg_create              VARCHAR2(100),
  flg_cancel              VARCHAR2(100),
  flg_search              VARCHAR2(100),
  flg_print               VARCHAR2(100),
  flg_ok                  VARCHAR2(100),
  flg_detail              VARCHAR2(100),
  flg_content             VARCHAR2(100),
  flg_help                VARCHAR2(100),
  id_sys_shortcut         VARCHAR2(100),
  id_software             VARCHAR2(100),
  id_shortcut_pk          VARCHAR2(100),
  id_software_context     VARCHAR2(100),
  flg_graph               VARCHAR2(100),
  flg_vision              VARCHAR2(100),
  flg_digital             VARCHAR2(240),
  flg_freq                VARCHAR2(100),
  flg_no                  VARCHAR2(240),
  position                VARCHAR2(100),
  toolbar_level           VARCHAR2(100),
  flg_action              VARCHAR2(100),
  flg_view                VARCHAR2(100),
  flg_add_remove          VARCHAR2(100),
  flg_global_shortcut     VARCHAR2(100) )
  organization external 
  (
    type oracle_loader
    default directory DATA_IMP_DIR
    access parameters
    (
      records delimited by '\r\n' CHARACTERSET WE8MSWIN1252
      fields terminated by ';'
      OPTIONALLY ENCLOSED BY '"'
    )
    location ('a_profile_templ_access.csv')
  )
REJECT LIMIT 0;