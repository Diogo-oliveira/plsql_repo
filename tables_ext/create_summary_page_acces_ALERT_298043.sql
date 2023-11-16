create table SPA_ALERT_298043
(
       id_summary_page_access number(24), 
       id_profile_template number(24), 
       id_summary_page_section number(24), 
       flg_write varchar2(1), 
       height number(4), 
       flg_search varchar2(1), 
       flg_no_changes varchar2(1)
)
  organization external 
  (
    default directory DATA_IMP_DIR
    access parameters
    (
      records delimited by '\r\n'
      fields terminated by ';'
      OPTIONALLY ENCLOSED BY '"'
    )
    location ('summary_page_acces_ALERT_298043.csv')
  )
reject limit UNLIMITED;
