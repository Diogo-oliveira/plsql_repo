create or replace type t_rec_data_emr_consult_plus force as object (
   ID_OPINION       number
  ,ID_EPISODE             number
  ,ID_EPIS_TYPE           number
  ,ID_INSTITUTION       number
  ,INSTITUTION_NAME   VARCHAR2(4000)
  ,FLG_STATE              varchar2(4000)
  ,FLG_STATE_DESC     varchar2(4000)
  ,ID_PROF_QUESTIONS      number
  ,PROF_NAME_QUESTIONS  varchar2(4000)
  ,ID_PROF_QUESTIONED     number
  ,PROF_NAME_QUESTIONED varchar2(4000)
  ,ID_SPECIALITY          number
  ,SPECIALITY_NAME    varchar2(4000)
  ,DT_PROBLEM_TSTZ        timestamp with local time zone
  ,DT_CANCEL_TSTZ         timestamp with local time zone
  ,STATUS_FLG             varchar2(0020 char)
  ,STATUS_FLG_DESC    varchar2(4000)
  ,FLG_TYPE               varchar2(0020 char)
  ,FLG_TYPE_DESC      varchar2(4000)
  ,ID_CANCEL_REASON       number
  ,CANCEL_REASON_DESC   varchar2(4000)
  ,ID_PATIENT             number
  ,ID_OPINION_TYPE        number
  ,OPINION_TYPE_DESC    varchar2(4000)
  ,ID_CLINICAL_SERVICE    number
  ,CLINICAL_SERVICE_DESC  varchar2(4000)
  ,DT_APPROVED            timestamp with local time zone
  ,ID_PROF_APPROVED       number
  ,PROF_APPROVED_NAME   varchar2(4000)
  ,FLG_AUTO_FOLLOW_UP     varchar2(0020 char)
  ,FLG_AUTO_FUP_DESC    varchar2(4000)
  ,ID_PROF_CANCEL         number
  ,PROF_CANCEL_NAME   varchar2(4000)
  ,FLG_PRIORITY           varchar2(0020 char)
  ,FLG_PRIORITY_DESC    varchar2(4000)
  );
/
  
  
