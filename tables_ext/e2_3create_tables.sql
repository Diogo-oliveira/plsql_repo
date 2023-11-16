BEGIN
PK_FRMW_OBJECTS.insert_into_frmw_objects('ALERT', 'e2_3unavailable_cdr_instances', 'TABLE', 'DPC', 'N', '', 'N');
END;
/

--CREATE--
create table e2_3unavailable_cdr_instances
(
  ID_CDR_INSTANCE	NUMBER(24)
)
  organization external 
  (
    default directory DATA_IMP_DIR
    access parameters
    (
      records delimited by '\r\n' CHARACTERSET WE8MSWIN1252
    )
    location ('e2_3unavailable_cdr_instances.csv')
  )
REJECT LIMIT 0;