-- CHANGED BY: Joao Coutinho
-- CHANGE DATE: 04/05/2017
-- CHANGE REASON: ALERT-309059 

BEGIN

    -- 
    pk_frmw_objects.insert_into_frmw_objects(i_owner             => 'ALERT',
                                             i_obj_name          => 'ids_cds_duplicated040517',
                                             i_obj_type          => 'TABLE',
                                             i_flg_category      => 'DPC',
                                             i_flg_alert_default => 'N',
                                             i_delete_script     => NULL,
                                             i_flg_default_child => 'N',
                                             i_responsible_team  => 'CONTENT');
END;
/


-- 
CREATE TABLE ids_cds_duplicated040517
(
     --Nome das colunas da tabela    
     ID_CDR_INSTANCE NUMBER(24)
)
organization external
(
       DEFAULT directory DATA_IMP_DIR
       access parameters
       (
              records delimited by '\r\n' CHARACTERSET WE8MSWIN1252
              fields terminated by ';'
              optionally enclosed by '"'
       )
       location('.csv')   -- nome do ficheiro csv correspondente
)
reject limit 0;

-- END CHANGE BY: Joao Coutinho