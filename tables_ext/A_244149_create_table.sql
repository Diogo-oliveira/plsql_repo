--CREATE--
create table A_244149_stf
(
ID_FREQ_SAMPLE_TEXT	NUMBER(24),
ID_SAMPLE_TEXT	NUMBER(12),
ID_CLINICAL_SERVICE	NUMBER(24),
ID_MARKET	NUMBER(24),
VERSION	VARCHAR2(100)
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
    location ('A_244149_stf.csv')
  )
REJECT LIMIT 0;
