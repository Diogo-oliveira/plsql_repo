create or replace  TYPE t_rec_professional IS object(
        id_professional  NUMBER,
        nick_name        VARCHAR2(200 CHAR),
        username         VARCHAR2(200 CHAR),
        profile_template VARCHAR2(200 CHAR),
        title            VARCHAR2(200 CHAR),
        gender           VARCHAR2(200 CHAR),
        category_name    VARCHAR2(200 CHAR),
        institution      NUMBER,
        name             VARCHAR2(200 CHAR),
        birthdate        DATE);
