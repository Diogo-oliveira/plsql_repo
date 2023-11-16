-- CHANGED BY: Gisela Couto 
-- CHANGE DATE: 10-04-2014
-- CHANGE REASON: ALERT-274030 - CDA Encounter information

DECLARE
    e_already_dropped EXCEPTION;

    PRAGMA EXCEPTION_INIT(e_already_dropped, -4043);
BEGIN
  EXECUTE IMMEDIATE 'DROP TYPE t_table_episode_cda'; 
  EXECUTE IMMEDIATE 'DROP TYPE t_rec_episode_cda'; 
EXCEPTION 
  WHEN e_already_dropped THEN 
    NULL;
END;
/

CREATE OR REPLACE TYPE t_rec_episode_cda IS OBJECT(
        dt_begin_tstz               timestamp(6),
        dt_begin_formatted          VARCHAR2(64),
        dt_begin_id_timezone        VARCHAR2(64),
        dt_end_tstz                 timestamp(6),
        dt_end_formatted            VARCHAR2(64),
        dt_end_id_timezone          VARCHAR2(64),
        id_institution              number(24),
        id_country                  number(24),
        institution_name            VARCHAR2(4000),
        address                     varchar2(512),
        zip_code                    varchar2(512),
        phone_number                varchar2(512),
  		district                    varchar2(512),
		country                     varchar2(512),
        location                    varchar2(512),
		email                       varchar2(100));
/


CREATE OR REPLACE TYPE t_table_episode_cda IS TABLE OF t_rec_episode_cda;
/
-- CHANGE END: Gisela Couto
