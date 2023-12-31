CREATE OR REPLACE TYPE t_wl_search_row FORCE AS OBJECT
(
    idrequisition            NUMBER(24),
    flgtype                  VARCHAR2(2 CHAR),
    qtl_flg_type             VARCHAR2(1 CHAR),
    flg_status               VARCHAR2(1 CHAR),
    idpatient                NUMBER(24),
    relative_urgency         NUMBER(24),
    dtcreation               TIMESTAMP WITH LOCAL TIME ZONE,
    idusercreation           NUMBER(24),
    idinstitution            NUMBER(24),
    idservice                NUMBER(24),
    idresource               NUMBER(24),
    resourcetype             VARCHAR2(1 CHAR),
    dtbeginmin               TIMESTAMP WITH LOCAL TIME ZONE,
    dtbeginmax               TIMESTAMP WITH LOCAL TIME ZONE,
    flgcontacttype           VARCHAR2(1 CHAR),
    priority                 VARCHAR2(1 CHAR),
    urgencylevel             VARCHAR2(4000), -- descricao
    idlanguage               NUMBER(24),
    idmotive                 NUMBER(24),
    motivetype               VARCHAR2(1 CHAR),
    motivedescription        VARCHAR2(200),
    sessionnumber            NUMBER(24),
    frequencyunit            VARCHAR2(1 CHAR),
    frequency                NUMBER(24),
    iddepclinserv            table_number,
    idspeciality             table_number,
    expectedduration         NUMBER(24, 2),
    hasrequisitiontoschedule VARCHAR2(1 CHAR),
    sk_relative_urgency      NUMBER,
    sk_absolute_urgency      NUMBER,
    sk_waiting_time          NUMBER,
    sk_urgency_level         NUMBER(6),
    sk_barthel               NUMBER,
    sk_gender                VARCHAR2(20 CHAR),
    idcontent                VARCHAR2(200 CHAR),
    dtsugested               TIMESTAMP WITH LOCAL TIME ZONE,
    admissionneeded          VARCHAR2(1 CHAR),
    ids_pref_surgeons        table_number,
    icuneeded                VARCHAR2(1 CHAR),
    pos                      VARCHAR2(1 CHAR),
    idroomtype               NUMBER(24),
    idbedtype                NUMBER(24),
    idpreferedroom           NUMBER(24),
    nurseintakeneed          VARCHAR2(1 CHAR),
    mixednursing             VARCHAR2(1 CHAR),
    admindic                 VARCHAR2(4000), -- descricao
    unavailabilitydatebegin  TIMESTAMP WITH LOCAL TIME ZONE,
    unavailabilitydateend    TIMESTAMP WITH LOCAL TIME ZONE,
    dangerofcontamination    VARCHAR2(1 CHAR),
    idadmward                NUMBER(24),
    idadmclinserv            NUMBER(24),
    procdiagnosis            VARCHAR2(4000),
    procsurgeon              VARCHAR2(4000),
    patient_origin           VARCHAR(1000 CHAR),
    dt_hhc_approval          TIMESTAMP WITH LOCAL TIME ZONE,
    professionals            table_number
);
/
