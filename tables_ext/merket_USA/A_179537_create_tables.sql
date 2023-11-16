--CREATE--
create table A_179537_mi_atc_int
(
  id_drug                    VARCHAR2(255),
  atcd                       VARCHAR2(255),
  atcdescd                   VARCHAR2(255),
  ddi                        VARCHAR2(255),
  interddi                   VARCHAR2(255),
  ddi_desd                   VARCHAR2(255),
  ddi_sld                    VARCHAR2(255),
  vers                       VARCHAR2(255)
)
  organization external 
  (
    default directory DATA_IMP_DIR
    access parameters
    (
      records delimited by newline
      fields terminated by ';'
      OPTIONALLY ENCLOSED BY '"'
    )
    location ('A_179537_mi_atc_int.csv')
  )
REJECT LIMIT 0;


--CREATE--
create table A_179537_me_atc_int
(
  emb_id                     VARCHAR2(255),
  atcd                       VARCHAR2(255),
  atcdescd                   VARCHAR2(255),
  ddi                        VARCHAR2(255),
  interddi                   VARCHAR2(255),
  ddi_desd                   VARCHAR2(255),
  ddi_sld                    VARCHAR2(255),
  vers                       VARCHAR2(255)
)
  organization external 
  (
    default directory DATA_IMP_DIR
    access parameters
    (
      records delimited by newline
      fields terminated by ';'
      OPTIONALLY ENCLOSED BY '"'
    )
    location ('A_179537_me_atc_int.csv')
  )
REJECT LIMIT 0;
