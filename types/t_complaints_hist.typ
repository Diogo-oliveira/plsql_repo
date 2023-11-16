-->t_complaints_hist|alert|dml
CREATE OR REPLACE TYPE t_complaints_hist force AS OBJECT
(
    id_epis_complaint            NUMBER(24),
    action                       VARCHAR2(50),
    reported_by                  VARCHAR2(1000),
    reported_by_new              VARCHAR2(1000),
    patient_complaint            VARCHAR2(4000),
    patient_complaint_new        VARCHAR2(4000),
    patient_complaint_arabic     VARCHAR2(4000),
    patient_complaint_arabic_new VARCHAR2(4000),
    complaint                    VARCHAR2(4000),
    complaint_new                VARCHAR2(4000),
    status                       VARCHAR2(2),
--   status_new                   VARCHAR2(200),
    cancel_reason_new VARCHAR2(1000),
    cancel_notes_new  VARCHAR2(4000),
    registry          VARCHAR2(1000),
    white_line        VARCHAR2(1)
);
/
