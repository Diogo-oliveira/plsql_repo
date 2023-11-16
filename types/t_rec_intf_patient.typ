-- CHANGED BY: Ana Monteiro
-- CHANGED DATE: 2010-JAN-12
-- CHANGED REASON: 
-- Utilizado para receber dados de interface (PK_P1_URL)
CREATE OR REPLACE TYPE t_rec_intf_patient AS OBJECT
(
    internal_number     VARCHAR2(200 CHAR),
    name                VARCHAR2(200 CHAR),
    sex                 VARCHAR2(1 CHAR),
    birth_date_year     NUMBER(4),
    birth_date_month    NUMBER(2),
    birth_date_day      NUMBER(2),
    exemption_type      NUMBER(4),
    recm                NUMBER(3),
    phone               VARCHAR2(30 CHAR),
    address             VARCHAR2(200 CHAR),
    postal_code         VARCHAR2(30 CHAR),
    locality            VARCHAR2(200 CHAR),
    district            VARCHAR2(200 CHAR),
    country             VARCHAR2(2 CHAR),
    marital_state       VARCHAR2(2 CHAR),
    qualifications      NUMBER(4),
    profession          NUMBER(4),
    profession_practice VARCHAR2(2 CHAR),
    father              VARCHAR2(200 CHAR),
    mother              VARCHAR2(200 CHAR),
    rnu_id              NUMBER(10)
)
/
-- CHANGE END: Ana Monteiro
