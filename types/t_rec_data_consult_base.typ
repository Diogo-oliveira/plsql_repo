create or replace type t_rec_data_consult_base force as object (
   ID_OPINION       number
  ,ID_EPISODE             number
  ,ID_EPIS_TYPE           number
  ,ID_INSTITUTION       number
  ,FLG_STATE              varchar2(0020 char)
  ,ID_PROF_QUESTIONS      number
  ,ID_PROF_QUESTIONED     number
  ,ID_SPECIALITY          number
  ,DT_PROBLEM_TSTZ        timestamp with local time zone
  ,DT_CANCEL_TSTZ         timestamp with local time zone
  ,STATUS_FLG             varchar2(0020 char)
  ,FLG_TYPE               varchar2(0020 char)
  ,ID_CANCEL_REASON       number
  ,ID_PATIENT             number
  ,ID_OPINION_TYPE        number
  ,ID_CLINICAL_SERVICE    number
  ,DT_APPROVED            timestamp with local time zone
  ,ID_PROF_APPROVED       number
  ,FLG_AUTO_FOLLOW_UP     varchar2(0020 char)
  ,ID_PROF_CANCEL         number
  ,FLG_PRIORITY           varchar2(0020 char)
  );
/
  
