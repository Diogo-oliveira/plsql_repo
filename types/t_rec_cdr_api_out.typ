CREATE OR REPLACE TYPE t_rec_cdr_api_out force AS OBJECT
(
-- represents an ehr validation service output (in bulk)
    id_record           NUMBER(24), -- ehr record identifier
    id_element          VARCHAR2(255 CHAR), -- element identifier
    dt_record           TIMESTAMP WITH LOCAL TIME ZONE, -- ehr record date
    flg_source          VARCHAR2(2 CHAR), -- problem origin flag
    id_allergy_severity NUMBER(24), -- allergy severity identifier
    id_task_request     VARCHAR2(255 CHAR), -- task request identifier
    code_icd            VARCHAR2(200 CHAR), -- icd code diagnosi
    CONSTRUCTOR FUNCTION t_rec_cdr_api_out RETURN SELF AS RESULT,
    CONSTRUCTOR FUNCTION t_rec_cdr_api_out
    (
        id_record  IN NUMBER,
        id_element IN VARCHAR2,
        dt_record  IN TIMESTAMP WITH LOCAL TIME ZONE,
        flg_source IN VARCHAR2
    ) RETURN SELF AS RESULT,
    CONSTRUCTOR FUNCTION t_rec_cdr_api_out
    (
        id_record           IN NUMBER,
        id_element          IN VARCHAR2,
        dt_record           IN TIMESTAMP WITH LOCAL TIME ZONE,
        id_allergy_severity IN NUMBER,
        id_task_request     IN VARCHAR2
    ) RETURN SELF AS RESULT,

    CONSTRUCTOR FUNCTION t_rec_cdr_api_out
    (
        id_record           IN NUMBER,
        id_element          IN VARCHAR2,
        dt_record           IN TIMESTAMP WITH LOCAL TIME ZONE,
        flg_source          IN VARCHAR2,
        id_allergy_severity IN NUMBER DEFAULT NULL,
        id_task_request     IN VARCHAR2 DEFAULT NULL,
        code_icd            IN VARCHAR2
    ) RETURN SELF AS RESULT
)
/
CREATE OR REPLACE TYPE BODY t_rec_cdr_api_out IS

    CONSTRUCTOR FUNCTION t_rec_cdr_api_out RETURN SELF AS RESULT IS
    BEGIN
        self.id_record           := NULL;
        self.id_element          := NULL;
        self.dt_record           := NULL;
        self.flg_source          := NULL;
        self.id_allergy_severity := NULL;
        self.id_task_request     := NULL;
        self.code_icd            := NULL;
    
        RETURN;
    END;

    CONSTRUCTOR FUNCTION t_rec_cdr_api_out
    (
        id_record  IN NUMBER,
        id_element IN VARCHAR2,
        dt_record  IN TIMESTAMP WITH LOCAL TIME ZONE,
        flg_source IN VARCHAR2
    ) RETURN SELF AS RESULT IS
    BEGIN
        self.id_record           := id_record;
        self.id_element          := id_element;
        self.dt_record           := dt_record;
        self.flg_source          := flg_source;
        self.id_allergy_severity := NULL;
        self.id_task_request     := NULL;
        self.code_icd            := NULL;
    
        RETURN;
    END;

    CONSTRUCTOR FUNCTION t_rec_cdr_api_out
    (
        id_record           IN NUMBER,
        id_element          IN VARCHAR2,
        dt_record           IN TIMESTAMP WITH LOCAL TIME ZONE,
        id_allergy_severity IN NUMBER,
        id_task_request     IN VARCHAR2
    ) RETURN SELF AS RESULT IS
    BEGIN
        self.id_record           := id_record;
        self.id_element          := id_element;
        self.dt_record           := dt_record;
        self.flg_source          := NULL;
        self.id_allergy_severity := id_allergy_severity;
        self.id_task_request     := id_task_request;
        self.code_icd            := NULL;
    
        RETURN;
    END;

    CONSTRUCTOR FUNCTION t_rec_cdr_api_out
    (
        id_record           IN NUMBER,
        id_element          IN VARCHAR2,
        dt_record           IN TIMESTAMP WITH LOCAL TIME ZONE,
        flg_source          IN VARCHAR2,
        id_allergy_severity IN NUMBER DEFAULT NULL,
        id_task_request     IN VARCHAR2 DEFAULT NULL,
        code_icd            IN VARCHAR2
    ) RETURN SELF AS RESULT IS
    BEGIN
        self.id_record           := id_record;
        self.id_element          := id_element;
        self.dt_record           := dt_record;
        self.flg_source          := flg_source;
        self.id_allergy_severity := NULL;
        self.id_task_request     := NULL;
        self.code_icd            := code_icd;
    
        RETURN;
    END;

END;
/
