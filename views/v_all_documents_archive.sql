create or replace view v_all_documents_archive as
select ID_DOC_ORI_TYPE
,ORITYPEDESC
,TYPEDESC
,TITLE
,IDDOC
,NUMCOMMENTS
,NUMIMAGES
,DT_EMITED
,DT_EXPIRE
,LASTUPDATEDDATE
,LASTUPDATEDBY
,TODO_ESPECIALIDADE
,URL_THUMB
,MIME_TYPE
,FORMAT_TYPE
,FLG_STATUS
,FLG_COMMENT_TYPE
,ID_DOC_EXTERNAL
,ID_FOLDER
,ID_XDS_DOCUMENT_SUBMISSION
,SUBMISSION_SET_UNIQUE_ID
,DOC_OID
,SUBMISSION_STATUS
,SUBM_DT_CHAR
,SUBM_DT_CHAR_HOUR
,ID_EPIS_REPORT
,NUM_DOC
,SPECIALTY
,ORIGINAL
,DESC_LANGUAGE
,NOTES
,NOTE_COUNT
,FLG_PUBLISHABLE
,FLG_DOWNLOAD
,ID_DOC_TYPE
,CREATED_DATE
,CREATED_BY
,ID_PATIENT
,ID_EXTERNAL_REQUEST
,ID_INSTITUTION
,ID_EPISODE
, FLG_SAVED_OUTSIDE from 
TABLE(
    pk_doc.get_doc_list_by_type(
  i_lang => sys_context('ALERT_CONTEXT', 'i_lang')
, i_prof => profissional(sys_context('ALERT_CONTEXT', 'i_prof_id')
, sys_context('ALERT_CONTEXT', 'i_prof_institution')
, sys_context('ALERT_CONTEXT', 'i_prof_software'))
, i_patient => sys_context('ALERT_CONTEXT', 'i_patient')
, i_episode => sys_context('ALERT_CONTEXT', 'i_episode')
, i_ext_req => sys_context('ALERT_CONTEXT', 'i_ext_req')
, i_btn => sys_context('ALERT_CONTEXT', 'i_btn')
, i_doc_ori_type => sys_context('ALERT_CONTEXT', 'i_doc_ori_type'))
);