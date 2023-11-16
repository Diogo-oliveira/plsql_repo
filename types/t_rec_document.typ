-- CHANGED BY: daniel.silva
-- CHANGE DATE: 2013.07.04
-- CHANGE REASON: [ALERT-260743] 
DECLARE
    e_already_dropped EXCEPTION;

    PRAGMA EXCEPTION_INIT(e_already_dropped, -4043);
BEGIN
  EXECUTE IMMEDIATE 'DROP TYPE t_tbl_rec_document force'; 
EXCEPTION 
  WHEN e_already_dropped THEN 
    NULL;
END;
/



CREATE OR REPLACE TYPE t_rec_document AS OBJECT
(
    id_doc_ori_type            NUMBER,
    oritypedesc                VARCHAR2(4000),
    typedesc                   VARCHAR2(4000),
    title                      VARCHAR2(200),
    iddoc                      NUMBER,
    numcomments                VARCHAR2(200),
    numimages                  NUMBER,
    dt_emited                  VARCHAR2(200),
    dt_expire                  VARCHAR2(200),
    lastupdateddate            VARCHAR2(200),
    lastupdatedby              VARCHAR2(200),
    todo_especialidade         VARCHAR2(200),
    url_thumb                  VARCHAR2(200),
    mime_type                  VARCHAR2(200),
    format_type                VARCHAR2(200),
    flg_status                 VARCHAR2(1),
    flg_comment_type           VARCHAR2(1),
    id_doc_external            NUMBER,
    id_folder                  NUMBER,
    id_xds_document_submission NUMBER,
    submission_set_unique_id   VARCHAR2(200),
    doc_oid                    VARCHAR2(200),
    submission_status          VARCHAR2(1),
    subm_dt_char               VARCHAR2(200),
    subm_dt_char_hour          VARCHAR2(200),
    id_epis_report             NUMBER,
    num_doc                    VARCHAR2(200),
    specialty                  VARCHAR2(4000),
    original                   VARCHAR2(4000),
    desc_language              VARCHAR2(4000),
    notes                      VARCHAR2(2000),
    note_count                 NUMBER,
    FLG_PUBLISHABLE            VARCHAR2(1),
    flg_download               VARCHAR2(1),
    id_doc_type                NUMBER,
    created_date               VARCHAR2(200),
    created_by                 VARCHAR2(200)
);
/


CREATE OR REPLACE TYPE t_tbl_rec_document IS TABLE OF t_rec_document;
/
-- CHANGE END:  daniel.silva



-- CHANGED BY: daniel.silva
-- CHANGE DATE: 2013.09.13
-- CHANGE REASON: [ALERT-] 
DECLARE
    e_already_dropped EXCEPTION;

    PRAGMA EXCEPTION_INIT(e_already_dropped, -4043);
BEGIN
  EXECUTE IMMEDIATE 'DROP TYPE t_tbl_rec_document force'; 
EXCEPTION 
  WHEN e_already_dropped THEN 
    NULL;
END;
/



CREATE OR REPLACE TYPE t_rec_document AS OBJECT
(
    id_doc_ori_type            NUMBER,
    oritypedesc                VARCHAR2(4000),
    typedesc                   VARCHAR2(4000),
    title                      VARCHAR2(200),
    iddoc                      NUMBER,
    numcomments                VARCHAR2(200),
    numimages                  NUMBER,
    dt_emited                  VARCHAR2(200),
    dt_expire                  VARCHAR2(200),
    lastupdateddate            VARCHAR2(200),
    lastupdatedby              VARCHAR2(200),
    todo_especialidade         VARCHAR2(200),
    url_thumb                  VARCHAR2(200),
    mime_type                  VARCHAR2(200),
    format_type                VARCHAR2(200),
    flg_status                 VARCHAR2(1),
    flg_comment_type           VARCHAR2(1),
    id_doc_external            NUMBER,
    id_folder                  NUMBER,
    id_xds_document_submission NUMBER,
    submission_set_unique_id   VARCHAR2(200),
    doc_oid                    VARCHAR2(200),
    submission_status          VARCHAR2(1),
    subm_dt_char               VARCHAR2(200),
    subm_dt_char_hour          VARCHAR2(200),
    id_epis_report             NUMBER,
    num_doc                    VARCHAR2(200),
    specialty                  VARCHAR2(4000),
    original                   VARCHAR2(4000),
    desc_language              VARCHAR2(4000),
    notes                      VARCHAR2(2000),
    note_count                 NUMBER,
    FLG_PUBLISHABLE            VARCHAR2(1),
    flg_download               VARCHAR2(1),
    id_doc_type                NUMBER,
    created_date               VARCHAR2(200),
    created_by                 VARCHAR2(200),
	id_patient                 NUMBER,
    id_external_request        NUMBER,
    id_institution             NUMBER
);
/


CREATE OR REPLACE TYPE t_tbl_rec_document IS TABLE OF t_rec_document;
/
-- CHANGE END:  daniel.silva

-- CHANGED BY: daniel.silva
-- CHANGE DATE: 2013.09.20
-- CHANGE REASON: [ALERT-265406] 
DECLARE
    e_already_dropped EXCEPTION;

    PRAGMA EXCEPTION_INIT(e_already_dropped, -4043);
BEGIN
  EXECUTE IMMEDIATE 'DROP TYPE t_tbl_rec_document force'; 
EXCEPTION 
  WHEN e_already_dropped THEN 
    NULL;
END;
/



CREATE OR REPLACE TYPE t_rec_document AS OBJECT
(
    id_doc_ori_type            NUMBER,
    oritypedesc                VARCHAR2(4000),
    typedesc                   VARCHAR2(4000),
    title                      VARCHAR2(200),
    iddoc                      NUMBER,
    numcomments                VARCHAR2(200),
    numimages                  NUMBER,
    dt_emited                  VARCHAR2(200),
    dt_expire                  VARCHAR2(200),
    lastupdateddate            VARCHAR2(200),
    lastupdatedby              VARCHAR2(200),
    todo_especialidade         VARCHAR2(200),
    url_thumb                  VARCHAR2(200),
    mime_type                  VARCHAR2(200),
    format_type                VARCHAR2(200),
    flg_status                 VARCHAR2(1),
    flg_comment_type           VARCHAR2(1),
    id_doc_external            NUMBER,
    id_folder                  NUMBER,
    id_xds_document_submission NUMBER,
    submission_set_unique_id   VARCHAR2(200),
    doc_oid                    VARCHAR2(200),
    submission_status          VARCHAR2(1),
    subm_dt_char               VARCHAR2(200),
    subm_dt_char_hour          VARCHAR2(200),
    id_epis_report             NUMBER,
    num_doc                    VARCHAR2(200),
    specialty                  VARCHAR2(4000),
    original                   VARCHAR2(4000),
    desc_language              VARCHAR2(4000),
    notes                      VARCHAR2(2000),
    note_count                 NUMBER,
    FLG_PUBLISHABLE            VARCHAR2(1),
    flg_download               VARCHAR2(1),
    id_doc_type                NUMBER,
    created_date               VARCHAR2(200),
    created_by                 VARCHAR2(200),
	  id_patient                 NUMBER,
    id_external_request        NUMBER,
    id_institution             NUMBER,
    id_episode                 NUMBER
);
/


CREATE OR REPLACE TYPE t_tbl_rec_document IS TABLE OF t_rec_document;
/
-- CHANGE END:  daniel.silva

-- CHANGED BY: daniel.silva
-- CHANGE DATE: 2014.03.21
-- CHANGE REASON: [ALERT-279028] Viewer counters
BEGIN
    EXECUTE IMMEDIATE 'CREATE OR REPLACE TYPE t_rec_document FORCE AS OBJECT
(
    id_doc_ori_type            NUMBER,
    oritypedesc                VARCHAR2(4000),
    typedesc                   VARCHAR2(4000),
    title                      VARCHAR2(200),
    iddoc                      NUMBER,
    numcomments                VARCHAR2(200),
    numimages                  NUMBER,
    dt_emited                  VARCHAR2(200),
    dt_expire                  VARCHAR2(200),
    lastupdateddate            VARCHAR2(200),
    lastupdatedby              VARCHAR2(200),
    todo_especialidade         VARCHAR2(200),
    url_thumb                  VARCHAR2(200),
    mime_type                  VARCHAR2(200),
    format_type                VARCHAR2(200),
    flg_status                 VARCHAR2(1),
    flg_comment_type           VARCHAR2(1),
    id_doc_external            NUMBER,
    id_folder                  NUMBER,
    id_xds_document_submission NUMBER,
    submission_set_unique_id   VARCHAR2(200),
    doc_oid                    VARCHAR2(200),
    submission_status          VARCHAR2(1),
    subm_dt_char               VARCHAR2(200),
    subm_dt_char_hour          VARCHAR2(200),
    id_epis_report             NUMBER,
    num_doc                    VARCHAR2(200),
    specialty                  VARCHAR2(4000),
    original                   VARCHAR2(4000),
    desc_language              VARCHAR2(4000),
    notes                      VARCHAR2(2000),
    note_count                 NUMBER,
    FLG_PUBLISHABLE            VARCHAR2(1),
    flg_download               VARCHAR2(1),
    id_doc_type                NUMBER,
    created_date               VARCHAR2(200),
    created_by                 VARCHAR2(200),
	  id_patient                 NUMBER,
    id_external_request        NUMBER,
    id_institution             NUMBER,
    id_episode                 NUMBER,
    lastupdateddatetstz        TIMESTAMP(6) WITH LOCAL TIME ZONE
)';
EXCEPTION
    WHEN OTHERS THEN
        NULL;
END;
/
--CHANGE END: daniel.silva


-- CHANGED BY: paulo.silva
-- CHANGE DATE: 2014.05.02
-- CHANGE REASON: [ALERT-284513] Direct Project - Import Documents into Documents Archive
BEGIN
CREATE OR REPLACE TYPE t_rec_document FORCE AS OBJECT
(
    id_doc_ori_type            NUMBER,
    oritypedesc                VARCHAR2(4000),
    typedesc                   VARCHAR2(4000),
    title                      VARCHAR2(200),
    iddoc                      NUMBER,
    numcomments                VARCHAR2(200),
    numimages                  NUMBER,
    dt_emited                  VARCHAR2(200),
    dt_expire                  VARCHAR2(200),
    lastupdateddate            VARCHAR2(200),
    lastupdatedby              VARCHAR2(200),
    lastupdatedby_inst         VARCHAR2(200),
    todo_especialidade         VARCHAR2(200),
    url_thumb                  VARCHAR2(200),
    mime_type                  VARCHAR2(200),
    format_type                VARCHAR2(200),
    flg_status                 VARCHAR2(1),
    flg_comment_type           VARCHAR2(1),
    id_doc_external            NUMBER,
    id_folder                  NUMBER,
    id_xds_document_submission NUMBER,
    submission_set_unique_id   VARCHAR2(200),
    doc_oid                    VARCHAR2(200),
    submission_status          VARCHAR2(1),
    subm_dt_char               VARCHAR2(200),
    subm_dt_char_hour          VARCHAR2(200),
    id_epis_report             NUMBER,
    num_doc                    VARCHAR2(200),
    specialty                  VARCHAR2(4000),
    original                   VARCHAR2(4000),
    desc_language              VARCHAR2(4000),
    notes                      VARCHAR2(2000),
    note_count                 NUMBER,
    FLG_PUBLISHABLE            VARCHAR2(1),
    flg_download               VARCHAR2(1),
    id_doc_type                NUMBER,
    created_date               VARCHAR2(200),
    created_by                 VARCHAR2(200),
    created_by_inst            VARCHAR2(200),     
	id_patient                 NUMBER,
    id_external_request        NUMBER,
    id_institution             NUMBER,
    id_episode                 NUMBER,
    lastupdateddatetstz        TIMESTAMP(6) WITH LOCAL TIME ZONE
)

EXCEPTION
    WHEN OTHERS THEN
        NULL;
END;
/
--CHANGE END: paulo.silva

-- CHANGED BY: Andre Silva
-- CHANGE DATE: 28/07/2022
-- CHANGE REASON: [EMR-54364] 
BEGIN
CREATE OR REPLACE TYPE t_rec_document FORCE AS OBJECT
(
    id_doc_ori_type            NUMBER,
    oritypedesc                VARCHAR2(4000),
    typedesc                   VARCHAR2(4000),
    title                      VARCHAR2(200),
    iddoc                      NUMBER,
    numcomments                VARCHAR2(200),
    numimages                  NUMBER,
    dt_emited                  VARCHAR2(200),
    dt_expire                  VARCHAR2(200),
    lastupdateddate            VARCHAR2(200),
    lastupdatedby              VARCHAR2(200),
    lastupdatedby_inst         VARCHAR2(200),
    todo_especialidade         VARCHAR2(200),
    url_thumb                  VARCHAR2(200),
    mime_type                  VARCHAR2(200),
    format_type                VARCHAR2(200),
    flg_status                 VARCHAR2(1),
    flg_comment_type           VARCHAR2(1),
    id_doc_external            NUMBER,
    id_folder                  NUMBER,
    id_xds_document_submission NUMBER,
    submission_set_unique_id   VARCHAR2(200),
    doc_oid                    VARCHAR2(200),
    submission_status          VARCHAR2(1),
    subm_dt_char               VARCHAR2(200),
    subm_dt_char_hour          VARCHAR2(200),
    id_epis_report             NUMBER,
    num_doc                    VARCHAR2(200),
    specialty                  VARCHAR2(4000),
    original                   VARCHAR2(4000),
    desc_language              VARCHAR2(4000),
    notes                      VARCHAR2(2000),
    note_count                 NUMBER,
    FLG_PUBLISHABLE            VARCHAR2(1),
    flg_download               VARCHAR2(1),
    id_doc_type                NUMBER,
    created_date               VARCHAR2(200),
    created_by                 VARCHAR2(200),
    created_by_inst            VARCHAR2(200),
	id_patient                 NUMBER,
    id_external_request        NUMBER,
    id_institution             NUMBER,
    id_episode                 NUMBER,
    lastupdateddatetstz        TIMESTAMP(6) WITH LOCAL TIME ZONE,
    flg_saved_outside              VARCHAR2(1)
)

EXCEPTION
    WHEN OTHERS THEN
        NULL;

END;
/
-- CHANGE END: Andre Silva