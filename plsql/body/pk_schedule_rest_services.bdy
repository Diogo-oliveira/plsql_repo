/*-- Last Change Revision: $Rev:  $*/
/*-- Last Change by: $Author: $*/
/*-- Date of last change: $Date:  $*/
CREATE OR REPLACE PACKAGE BODY pk_schedule_rest_services IS

  -- Private variable declarations
  g_error   VARCHAR2(1000 CHAR);
  g_owner   VARCHAR2(30 CHAR);
  g_package VARCHAR2(40 CHAR);
  
  k_http_get    CONSTANT VARCHAR2(4 CHAR) := 'GET';
  k_http_post   CONSTANT VARCHAR2(4 CHAR) := 'POST';
  k_http_put    CONSTANT VARCHAR2(4 CHAR) := 'PUT';
  k_http_delete CONSTANT VARCHAR2(6 CHAR) := 'DELETE';

  k_content_type_json CONSTANT VARCHAR2(16 CHAR) := 'application/json';

  FUNCTION cancel_reason_dto(i_reasonid    IN NUMBER,
                             i_reasonnotes IN VARCHAR2) RETURN JSON_OBJECT_T IS
    l_cancel_reason JSON_OBJECT_T;
  
  BEGIN
    l_cancel_reason := JSON_OBJECT_T();
    l_cancel_reason.put('idCancelReason', i_reasonid);
    l_cancel_reason.put('cancelNotes', i_reasonnotes);
  
    RETURN l_cancel_reason;
  END cancel_reason_dto;

  -- Function and procedure implementations
  FUNCTION change_schedule_status_dto(i_schids      IN table_number,
                                      i_reasonid    IN NUMBER,
                                      i_reasonnotes IN VARCHAR2)
    RETURN JSON_OBJECT_T IS
    l_change_schedule_status JSON_OBJECT_T;
    l_schids                 JSON_ARRAY_T;
    l_cancel_reason          JSON_OBJECT_T;
  
  BEGIN
    l_schids := new JSON_ARRAY_T;
    FOR i IN 1 .. i_schids.count LOOP
      l_schids.append(i_schids(i));
    END LOOP;
    l_cancel_reason := cancel_reason_dto(i_reasonid    => i_reasonid,
                                         i_reasonnotes => i_reasonnotes);
  
    l_change_schedule_status := JSON_OBJECT_T();
    l_change_schedule_status.put('idSchedules', l_schids);
    l_change_schedule_status.put('cancelReason', l_cancel_reason);
  
    RETURN l_change_schedule_status;
  END change_schedule_status_dto;

  FUNCTION cancel_schedule_dto(i_schid        IN NUMBER,
                               i_idperson     IN NUMBER,
                               i_cancelreason IN NUMBER,
                               i_cancelnotes  IN VARCHAR2,
                               i_canceldate   IN TIMESTAMP WITH LOCAL TIME ZONE)
    RETURN JSON_OBJECT_T IS
    l_cancel_schedule JSON_OBJECT_T;
    l_cancel_reason   JSON_OBJECT_T;
  
  BEGIN
    l_cancel_reason := cancel_reason_dto(i_reasonid    => i_cancelreason,
                                         i_reasonnotes => i_cancelnotes);
  
    l_cancel_schedule := JSON_OBJECT_T();
    l_cancel_schedule.put('idSchedule', i_schid);
    l_cancel_schedule.put('idPerson', i_idPerson);
    l_cancel_schedule.put('cancelReason', l_cancel_reason);
    l_cancel_schedule.put('dtCancel',
                          pk_rest_api.convert_timestamp(i_canceldate));
  
    return l_cancel_schedule;
  END cancel_schedule_dto;

  FUNCTION update_schedule_bed_dto(i_schid   IN NUMBER,
                                   i_bedid   IN NUMBER,
                                   i_olddate IN TIMESTAMP WITH LOCAL TIME ZONE,
                                   i_newdate IN TIMESTAMP WITH LOCAL TIME ZONE)
    RETURN JSON_OBJECT_T IS
    l_update_schedule_bed JSON_OBJECT_T;
  
  BEGIN
    l_update_schedule_bed := JSON_OBJECT_T();
    l_update_schedule_bed.put('idSchedule', i_schid);
    l_update_schedule_bed.put('idResource', i_bedid);
    l_update_schedule_bed.put('oldDtEnd',
                              pk_rest_api.convert_timestamp(i_olddate));
    l_update_schedule_bed.put('newDtEnd',
                              pk_rest_api.convert_timestamp(i_newdate));
  
    RETURN l_update_schedule_bed;
  
  END update_schedule_bed_dto;

  FUNCTION cancelschedule(i_lang         IN NUMBER,
                          i_prof         IN profissional,
                          i_schid        IN NUMBER,
                          i_idperson     IN NUMBER,
                          i_cancelreason IN NUMBER,
                          i_cancelnotes  IN VARCHAR2,
                          i_canceldate   IN TIMESTAMP WITH LOCAL TIME ZONE,
                          i_transaction  IN VARCHAR2) RETURN BOOLEAN IS
    l_cancel_schedule JSON_OBJECT_T;
    l_http_method     varchar2(4 CHAR) := k_http_put;
    l_content_type    varchar2(16 CHAR) := k_content_type_json;
    l_service         varchar2(250 CHAR) := '/internal/schedule/' ||
                                            i_schid || '/cancel';
  
    l_status varchar2(50 CHAR);
    l_data   JSON_ELEMENT_T;
    l_error  JSON_ARRAY_T;
  
  BEGIN
    l_cancel_schedule := cancel_schedule_dto(i_schid        => i_schid,
                                             i_idperson     => i_idperson,
                                             i_cancelReason => i_cancelreason,
                                             i_cancelNotes  => i_cancelnotes,
                                             i_canceldate   => i_canceldate);
  
    RETURN pk_rest_api.make_internal_rest_request(i_host_transaction => i_transaction,
                                                  i_service          => l_service,
                                                  i_http_method      => l_http_method,
                                                  i_content_type     => l_content_type,
                                                  i_lang             => i_lang,
                                                  i_prof             => i_prof,
                                                  i_body             => l_cancel_schedule.to_string,
                                                  o_status           => l_status,
                                                  o_data             => l_data,
                                                  o_error            => l_error);
  
  END cancelschedule;

  FUNCTION registerschedule(i_lang        IN NUMBER,
                            i_prof        IN profissional,
                            i_schid       IN NUMBER,
                            i_personid    IN NUMBER,
                            i_transaction IN VARCHAR2) RETURN BOOLEAN IS
  
    l_http_method varchar2(4 CHAR) := k_http_put;
    l_service     varchar2(250 CHAR) := '/internal/schedule/' || i_schid ||
                                        '/register?idPerson=' || i_personid;
  
    l_status varchar2(50 CHAR);
    l_data   JSON_ELEMENT_T;
    l_error  JSON_ARRAY_T;
  BEGIN
  
    RETURN pk_rest_api.make_internal_rest_request(i_host_transaction => i_transaction,
                                                  i_service          => l_service,
                                                  i_http_method      => l_http_method,
                                                  i_lang             => i_lang,
                                                  i_prof             => i_prof,
                                                  o_status           => l_status,
                                                  o_data             => l_data,
                                                  o_error            => l_error);
  
  END registerschedule;

  FUNCTION cancelscheduleregistration(i_lang        IN NUMBER,
                                      i_prof        IN profissional,
                                      i_schid       IN NUMBER,
                                      i_personid    IN NUMBER,
                                      i_transaction IN VARCHAR2)
    RETURN BOOLEAN IS
  
    l_http_method varchar2(4 CHAR) := k_http_put;
    l_service     varchar2(250 CHAR) := '/internal/schedule/' || i_schid ||
                                        '/cancelRegistration?idPerson=' ||
                                        i_personid;
  
    l_status varchar2(50 CHAR);
    l_data   JSON_ELEMENT_T;
    l_error  JSON_ARRAY_T;
  BEGIN
  
    RETURN pk_rest_api.make_internal_rest_request(i_host_transaction => i_transaction,
                                                  i_service          => l_service,
                                                  i_http_method      => l_http_method,
                                                  i_lang             => i_lang,
                                                  i_prof             => i_prof,
                                                  o_status           => l_status,
                                                  o_data             => l_data,
                                                  o_error            => l_error);
  
  END cancelscheduleregistration;

  FUNCTION updateschedulebed(i_lang        IN NUMBER,
                             i_prof        IN profissional,
                             i_schid       IN NUMBER,
                             i_bedid       IN NUMBER,
                             i_olddate     IN TIMESTAMP WITH LOCAL TIME ZONE,
                             i_newdate     IN TIMESTAMP WITH LOCAL TIME ZONE,
                             i_transaction IN VARCHAR2) RETURN BOOLEAN IS
    l_update_schedule_bed JSON_OBJECT_T;
    l_http_method         varchar2(4 CHAR) := k_http_put;
    l_content_type        varchar2(16 CHAR) := k_content_type_json;
    l_service             varchar2(250 CHAR) := '/internal/schedule/' ||
                                                i_schid || '/bed';
  
    l_status varchar2(50 CHAR);
    l_data   JSON_ELEMENT_T;
    l_error  JSON_ARRAY_T;
  BEGIN
  
    l_update_schedule_bed := update_schedule_bed_dto(i_schid   => i_schid,
                                                     i_bedid   => i_bedid,
                                                     i_olddate => i_olddate,
                                                     i_newdate => i_newdate);
  
    RETURN pk_rest_api.make_internal_rest_request(i_host_transaction => i_transaction,
                                                  i_service          => l_service,
                                                  i_http_method      => l_http_method,
                                                  i_content_type     => l_content_type,
                                                  i_lang             => i_lang,
                                                  i_prof             => i_prof,
                                                  i_body             => l_update_schedule_bed.to_string,
                                                  o_status           => l_status,
                                                  o_data             => l_data,
                                                  o_error            => l_error);
  
  END updateschedulebed;

  FUNCTION notify_person_dto(i_schid            IN NUMBER,
                             i_personid         IN NUMBER,
                             i_notificationvia  IN VARCHAR2,
                             i_professionalid   IN NUMBER,
                             i_notificationdate IN TIMESTAMP WITH LOCAL TIME ZONE)
    RETURN JSON_OBJECT_T IS
    l_notify_person JSON_OBJECT_T;
  BEGIN
    l_notify_person := JSON_OBJECT_T();
    l_notify_person.put('idSchedule', i_schid);
    l_notify_person.put('i_personid', i_personid);
    l_notify_person.put('flgNotificationVia', i_notificationvia);
    l_notify_person.put('idProfessional', i_professionalid);
    l_notify_person.put('dtNotification',
                        pk_rest_api.convert_timestamp(i_notificationdate));
  
    RETURN l_notify_person;
  END notify_person_dto;

  FUNCTION notifyperson(i_lang             IN NUMBER,
                        i_prof             IN profissional,
                        i_schid            IN NUMBER,
                        i_personid         IN NUMBER,
                        i_notificationvia  IN VARCHAR2,
                        i_professionalid   IN NUMBER,
                        i_notificationdate IN TIMESTAMP WITH LOCAL TIME ZONE,
                        i_transaction      IN VARCHAR2) RETURN BOOLEAN IS
    l_notify_person JSON_OBJECT_T;
  
    l_http_method  varchar2(4 CHAR) := k_http_post;
    l_content_type varchar2(16 CHAR) := k_content_type_json;
    l_service      varchar2(250 CHAR) := '/internal/schedule/' || i_schid ||
                                         '/notifyPerson';
  
    l_status varchar2(50 CHAR);
    l_data   JSON_ELEMENT_T;
    l_error  JSON_ARRAY_T;
  BEGIN
  
    l_notify_person := notify_person_dto(i_schid            => i_schid,
                                         i_personid         => i_personid,
                                         i_notificationvia  => i_notificationvia,
                                         i_professionalid   => i_professionalid,
                                         i_notificationdate => i_notificationdate);
  
    RETURN pk_rest_api.make_internal_rest_request(i_host_transaction => i_transaction,
                                                  i_service          => l_service,
                                                  i_http_method      => l_http_method,
                                                  i_content_type     => l_content_type,
                                                  i_lang             => i_lang,
                                                  i_prof             => i_prof,
                                                  i_body             => l_notify_person.to_string,
                                                  o_status           => l_status,
                                                  o_data             => l_data,
                                                  o_error            => l_error);
  
  END notifyperson;

  FUNCTION confirm_person_dto(i_scheduleid            IN NUMBER,
                              i_personid              IN NUMBER,
                              i_professionalidconfirm in NUMBER,
                              i_confirmationdate      IN TIMESTAMP WITH LOCAL TIME ZONE)
    RETURN JSON_OBJECT_T IS
    l_confirm_person JSON_OBJECT_T;
  BEGIN
    l_confirm_person := JSON_OBJECT_T();
    l_confirm_person.put('idSchedule', i_scheduleid);
    l_confirm_person.put('idPerson', i_personid);
    l_confirm_person.put('idProfessional', i_professionalidconfirm);
    l_confirm_person.put('dtConfirmation',
                         pk_rest_api.convert_timestamp(i_confirmationdate));
  
    RETURN l_confirm_person;
  END confirm_person_dto;

  FUNCTION confirmperson(i_lang                  IN NUMBER,
                         i_prof                  IN profissional,
                         i_scheduleid            IN NUMBER,
                         i_personid              IN NUMBER,
                         i_professionalidconfirm IN NUMBER,
                         i_confirmationdate      IN TIMESTAMP WITH LOCAL TIME ZONE,
                         i_transaction           IN VARCHAR2) RETURN BOOLEAN IS
    l_confirm_person JSON_OBJECT_T;
  
    l_http_method  varchar2(4 CHAR) := k_http_put;
    l_content_type varchar2(16 CHAR) := k_content_type_json;
    l_service      varchar2(250 CHAR) := '/internal/schedule/' ||
                                         i_scheduleid || '/confirmPerson';
  
    l_status varchar2(50 CHAR);
    l_data   JSON_ELEMENT_T;
    l_error  JSON_ARRAY_T;
  BEGIN
    l_confirm_person := confirm_person_dto(i_scheduleid            => i_scheduleid,
                                           i_personid              => i_personid,
                                           i_professionalidconfirm => i_professionalidconfirm,
                                           i_confirmationdate      => i_confirmationdate);
  
    RETURN pk_rest_api.make_internal_rest_request(i_host_transaction => i_transaction,
                                                  i_service          => l_service,
                                                  i_http_method      => l_http_method,
                                                  i_content_type     => l_content_type,
                                                  i_lang             => i_lang,
                                                  i_prof             => i_prof,
                                                  i_body             => l_confirm_person.to_string,
                                                  o_status           => l_status,
                                                  o_data             => l_data,
                                                  o_error            => l_error);
  
  END;

  FUNCTION confirmpendingschedule(i_lang        IN NUMBER,
                                  i_prof        IN profissional,
                                  i_schid       IN NUMBER,
                                  i_transaction IN VARCHAR2) RETURN BOOLEAN IS
  
    l_http_method varchar2(4 CHAR) := k_http_put;
    l_service     varchar2(250 CHAR) := '/internal/schedule/' || i_schid ||
                                        '/confirmPending';
  
    l_status varchar2(50 CHAR);
    l_data   JSON_ELEMENT_T;
    l_error  JSON_ARRAY_T;
  BEGIN
  
    RETURN pk_rest_api.make_internal_rest_request(i_host_transaction => i_transaction,
                                                  i_service          => l_service,
                                                  i_http_method      => l_http_method,
                                                  i_lang             => i_lang,
                                                  i_prof             => i_prof,
                                                  o_status           => l_status,
                                                  o_data             => l_data,
                                                  o_error            => l_error);
  
  END confirmpendingschedule;

  FUNCTION removependingschedule(i_lang        IN NUMBER,
                                 i_prof        IN profissional,
                                 i_schid       IN NUMBER,
                                 i_transaction IN VARCHAR2) RETURN BOOLEAN IS
  
    l_http_method varchar2(4 CHAR) := k_http_put;
    l_service     varchar2(250 CHAR) := '/internal/schedule/' || i_schid ||
                                        '/removePending';
  
    l_status varchar2(50 CHAR);
    l_data   JSON_ELEMENT_T;
    l_error  JSON_ARRAY_T;
  BEGIN
  
    RETURN pk_rest_api.make_internal_rest_request(i_host_transaction => i_transaction,
                                                  i_service          => l_service,
                                                  i_http_method      => l_http_method,
                                                  i_lang             => i_lang,
                                                  i_prof             => i_prof,
                                                  o_status           => l_status,
                                                  o_data             => l_data,
                                                  o_error            => l_error);
  
  END removependingschedule;

  FUNCTION reactivatecanceledschedule(i_lang        IN NUMBER,
                                      i_prof        IN profissional,
                                      i_schid       IN NUMBER,
                                      i_transaction IN VARCHAR2)
    RETURN BOOLEAN IS
  
    l_http_method varchar2(4 CHAR) := k_http_put;
    l_service     varchar2(250 CHAR) := '/internal/schedule/' || i_schid ||
                                        '/reactivate';
  
    l_status varchar2(50 CHAR);
    l_data   JSON_ELEMENT_T;
    l_error  JSON_ARRAY_T;
  BEGIN
  
    RETURN pk_rest_api.make_internal_rest_request(i_host_transaction => i_transaction,
                                                  i_service          => l_service,
                                                  i_http_method      => l_http_method,
                                                  i_lang             => i_lang,
                                                  i_prof             => i_prof,
                                                  o_status           => l_status,
                                                  o_data             => l_data,
                                                  o_error            => l_error);
  
  END reactivatecanceledschedule;

  FUNCTION schedule_dto(i_personid       IN NUMBER DEFAULT NULL,
                        i_depcleanservid IN NUMBER,
                        i_contentid      IN VARCHAR2,
                        i_professionalid IN NUMBER,
                        i_begindate      IN TIMESTAMP WITH LOCAL TIME ZONE,
                        i_enddate        IN TIMESTAMP WITH LOCAL TIME ZONE,
                        i_vacancy        IN VARCHAR2 DEFAULT NULL,
                        i_requesttypeid  IN NUMBER DEFAULT NULL,
                        i_schedulevia    IN VARCHAR2 DEFAULT NULL,
                        i_notes          IN VARCHAR2 DEFAULT NULL,
                        i_flgrequesttype IN VARCHAR2 DEFAULT NULL)
    RETURN JSON_OBJECT_T IS
    l_create_schedule JSON_OBJECT_T;
  BEGIN
    l_create_schedule := JSON_OBJECT_T();
  
    IF i_personid IS NOT NULL THEN
      l_create_schedule.put('idPerson', i_personid);
    END IF;
  
    l_create_schedule.put('idDepClinServ', i_depcleanservid);
    l_create_schedule.put('idContent', i_contentid);
    l_create_schedule.put('idProfessional', i_professionalid);
    l_create_schedule.put('dtBegin',
                          pk_rest_api.convert_timestamp(i_begindate));
    l_create_schedule.put('dtEnd',
                          pk_rest_api.convert_timestamp(i_enddate));
  
    IF i_vacancy IS NOT NULL THEN
      l_create_schedule.put('flgVacancy', i_vacancy);
    END IF;
  
    IF i_requesttypeid IS NOT NULL THEN
      l_create_schedule.put('idRequestType', i_requesttypeid);
    END IF;
  
    IF i_schedulevia IS NOT NULL THEN
      l_create_schedule.put('flgScheduleVia', i_schedulevia);
    END IF;
  
    IF i_notes IS NOT NULL THEN
      l_create_schedule.put('notes', i_notes);
    END IF;
  
    IF i_flgrequesttype IS NOT NULL THEN
      l_create_schedule.put('flgRequestType', i_flgrequesttype);
    END IF;
  
    RETURN l_create_schedule;
  END schedule_dto;

  FUNCTION createschedule(i_lang           IN NUMBER,
                          i_prof           IN profissional,
                          i_personid       IN NUMBER,
                          i_depcleanservid IN NUMBER,
                          i_contentid      IN VARCHAR2,
                          i_professionalid IN NUMBER,
                          i_begindate      IN TIMESTAMP WITH LOCAL TIME ZONE,
                          i_enddate        IN TIMESTAMP WITH LOCAL TIME ZONE,
                          i_vacancy        IN VARCHAR2,
                          i_requesttypeid  IN NUMBER,
                          i_schedulevia    IN VARCHAR2,
                          i_notes          IN VARCHAR2,
                          i_transaction    IN VARCHAR2,
                          o_schid          OUT NUMBER) RETURN BOOLEAN IS
    l_schedule JSON_OBJECT_T;
  
    l_http_method  varchar2(4 CHAR) := k_http_post;
    l_content_type varchar2(16 CHAR) := k_content_type_json;
    l_service      varchar2(250 CHAR) := '/internal/schedule';
  
    l_status varchar2(50 CHAR);
    l_data   JSON_ELEMENT_T;
    l_error  JSON_ARRAY_T;
  
  BEGIN
    l_schedule := schedule_dto(i_personid       => i_personid,
                               i_depcleanservid => i_depcleanservid,
                               i_contentid      => i_contentid,
                               i_professionalid => i_professionalid,
                               i_begindate      => i_begindate,
                               i_enddate        => i_enddate,
                               i_vacancy        => i_vacancy,
                               i_requesttypeid  => i_requesttypeid,
                               i_schedulevia    => i_schedulevia,
                               i_notes          => i_notes);
  
    IF pk_rest_api.make_internal_rest_request(i_host_transaction => i_transaction,
                                              i_service          => l_service,
                                              i_http_method      => l_http_method,
                                              i_content_type     => l_content_type,
                                              i_lang             => i_lang,
                                              i_prof             => i_prof,
                                              i_body             => l_schedule.to_string,
                                              o_status           => l_status,
                                              o_data             => l_data,
                                              o_error            => l_error) THEN
    
      o_schid := l_data.to_Number;
    
      RETURN TRUE;
    
    END IF;
  
    RETURN FALSE;
  
  END createschedule;

  FUNCTION schedule_procedure_dto(i_scheduleid             IN NUMBER,
                                  i_institutionrequestsid  IN NUMBER,
                                  i_institutionrequestedid IN NUMBER,
                                  i_dcsrequestsid          IN NUMBER,
                                  i_dcsrequestedid         IN NUMBER,
                                  i_contentid              IN VARCHAR2,
                                  i_professionalid         IN NUMBER,
                                  i_reasonnotes            IN VARCHAR2,
                                  i_urgency                IN VARCHAR2,
                                  i_begindate              IN TIMESTAMP WITH LOCAL TIME ZONE,
                                  i_creationdate           IN TIMESTAMP WITH LOCAL TIME ZONE,
                                  i_scehduletype           IN VARCHAR2)
    RETURN JSON_OBJECT_T IS
    l_schedule_procedure_dto JSON_OBJECT_T;
  BEGIN
    l_schedule_procedure_dto := JSON_OBJECT_T();
    l_schedule_procedure_dto.put('idSchedule', i_scheduleid);
    l_schedule_procedure_dto.put('idInstiRequests',
                                 i_institutionrequestsid);
    l_schedule_procedure_dto.put('idInstiRequested',
                                 i_institutionrequestedid);
    l_schedule_procedure_dto.put('idDcsRequests', i_dcsrequestsid);
    l_schedule_procedure_dto.put('idDcsRequested', i_dcsrequestedid);
    l_schedule_procedure_dto.put('idContent', i_contentid);
    l_schedule_procedure_dto.put('idProfessional', i_professionalid);
    l_schedule_procedure_dto.put('reasonNotes', i_reasonnotes);
    l_schedule_procedure_dto.put('flgUrgency', i_urgency);
    l_schedule_procedure_dto.put('dtBegin',
                                 pk_rest_api.convert_timestamp(i_begindate));
    l_schedule_procedure_dto.put('dtCreation',
                                 pk_rest_api.convert_timestamp(i_creationdate));
    l_schedule_procedure_dto.put('flgSchType', i_scehduletype);
  
    RETURN l_schedule_procedure_dto;
  END;

  FUNCTION createscheduleprocedure(i_lang                   IN NUMBER,
                                   i_prof                   IN profissional,
                                   i_scheduleid             IN NUMBER,
                                   i_institutionrequestsid  IN NUMBER,
                                   i_institutionrequestedid IN NUMBER,
                                   i_dcsrequestsid          IN NUMBER,
                                   i_dcsrequestedid         IN NUMBER,
                                   i_contentid              IN VARCHAR2,
                                   i_professionalid         IN NUMBER,
                                   i_reasonnotes            IN VARCHAR2,
                                   i_urgency                IN VARCHAR2,
                                   i_begindate              IN TIMESTAMP WITH LOCAL TIME ZONE,
                                   i_creationdate           IN TIMESTAMP WITH LOCAL TIME ZONE,
                                   i_scehduletype           IN VARCHAR2,
                                   i_transaction            IN VARCHAR2)
    RETURN BOOLEAN IS
    l_schedule_procedure JSON_OBJECT_T;
  
    l_http_method  varchar2(4 CHAR) := k_http_post;
    l_content_type varchar2(16 CHAR) := k_content_type_json;
    l_service      varchar2(250 CHAR) := '/internal/schedule/procedure';
  
    l_status varchar2(50 CHAR);
    l_data   JSON_ELEMENT_T;
    l_error  JSON_ARRAY_T;
  BEGIN
    l_schedule_procedure := schedule_procedure_dto(i_scheduleid             => i_scheduleid,
                                                   i_institutionrequestsid  => i_institutionrequestsid,
                                                   i_institutionrequestedid => i_institutionrequestedid,
                                                   i_dcsrequestsid          => i_dcsrequestsid,
                                                   i_dcsrequestedid         => i_dcsrequestedid,
                                                   i_contentid              => i_contentid,
                                                   i_professionalid         => i_professionalid,
                                                   i_reasonnotes            => i_reasonnotes,
                                                   i_urgency                => i_urgency,
                                                   i_begindate              => i_begindate,
                                                   i_creationdate           => i_creationdate,
                                                   i_scehduletype           => i_scehduletype);
  
    RETURN pk_rest_api.make_internal_rest_request(i_host_transaction => i_transaction,
                                                  i_service          => l_service,
                                                  i_http_method      => l_http_method,
                                                  i_content_type     => l_content_type,
                                                  i_lang             => i_lang,
                                                  i_prof             => i_prof,
                                                  i_body             => l_schedule_procedure.to_string,
                                                  o_status           => l_status,
                                                  o_data             => l_data,
                                                  o_error            => l_error);
  
  END createscheduleprocedure;

  FUNCTION updateschedulepatient(i_lang            NUMBER,
                                 i_prof            profissional,
                                 i_scheduleid      NUMBER,
                                 i_patienttoremove NUMBER,
                                 i_patienttoadd    NUMBER,
                                 i_transaction     IN VARCHAR2)
    RETURN BOOLEAN IS
  
    l_http_method varchar2(4 CHAR) := k_http_put;
    l_service     varchar2(250 CHAR) := '/internal/schedule/' ||
                                        i_scheduleid || '/patient/' ||
                                        i_patienttoadd || '?idPatientOld=' ||
                                        i_patienttoremove;
  
    l_status varchar2(50 CHAR);
    l_data   JSON_ELEMENT_T;
    l_error  JSON_ARRAY_T;
  BEGIN
  
    RETURN pk_rest_api.make_internal_rest_request(i_host_transaction => i_transaction,
                                                  i_service          => l_service,
                                                  i_http_method      => l_http_method,
                                                  i_lang             => i_lang,
                                                  i_prof             => i_prof,
                                                  o_status           => l_status,
                                                  o_data             => l_data,
                                                  o_error            => l_error);
  
  END updateschedulepatient;

  FUNCTION setschedulepersonnoshow(i_lang        IN NUMBER,
                                   i_prof        IN profissional,
                                   i_schid       IN NUMBER,
                                   i_personid    IN NUMBER,
                                   i_noshowid    IN NUMBER,
                                   i_noshownotes IN VARCHAR2,
                                   i_transaction IN VARCHAR2) RETURN BOOLEAN IS
    l_cancel_reason JSON_OBJECT_T;
    l_http_method   varchar2(4 CHAR) := k_http_put;
    l_content_type  varchar2(16 CHAR) := k_content_type_json;
    l_service       varchar2(250 CHAR) := '/internal/schedule/' || i_schid ||
                                          '/patient/' || i_personid ||
                                          '/noShow';
  
    l_status varchar2(50 CHAR);
    l_data   JSON_ELEMENT_T;
    l_error  JSON_ARRAY_T;
  BEGIN
    l_cancel_reason := cancel_reason_dto(i_reasonid    => i_noshowid,
                                         i_reasonnotes => i_noshownotes);
  
    RETURN pk_rest_api.make_internal_rest_request(i_host_transaction => i_transaction,
                                                  i_service          => l_service,
                                                  i_http_method      => l_http_method,
                                                  i_content_type     => l_content_type,
                                                  i_lang             => i_lang,
                                                  i_prof             => i_prof,
                                                  i_body             => l_cancel_reason.to_string,
                                                  o_status           => l_status,
                                                  o_data             => l_data,
                                                  o_error            => l_error);
  
  END setschedulepersonnoshow;

  FUNCTION cancelschedulepersonnoshow(i_lang             IN NUMBER,
                                      i_prof             IN profissional,
                                      i_schid            IN NUMBER,
                                      i_idpersonexternal IN NUMBER,
                                      i_transaction      IN VARCHAR2)
    RETURN BOOLEAN IS
  
    l_http_method varchar2(4 CHAR) := k_http_put;
    l_service     varchar2(250 CHAR) := '/internal/schedule/' || i_schid ||
                                        '/patient/' || i_idpersonexternal ||
                                        '/noShow/cancel';
  
    l_status varchar2(50 CHAR);
    l_data   JSON_ELEMENT_T;
    l_error  JSON_ARRAY_T;
  
  BEGIN
  
    RETURN pk_rest_api.make_internal_rest_request(i_host_transaction => i_transaction,
                                                  i_service          => l_service,
                                                  i_http_method      => l_http_method,
                                                  i_lang             => i_lang,
                                                  i_prof             => i_prof,
                                                  o_status           => l_status,
                                                  o_data             => l_data,
                                                  o_error            => l_error);
  
  END cancelschedulepersonnoshow;

  FUNCTION setcontacttype(i_lang             IN NUMBER,
                          i_prof             IN profissional,
                          i_schid            IN NUMBER,
                          i_idpersonexternal IN NUMBER,
                          i_contacttype      IN VARCHAR2,
                          i_transaction      IN VARCHAR2) RETURN BOOLEAN IS
  
    l_http_method varchar2(4 CHAR) := k_http_put;
    l_service     varchar2(250 CHAR) := '/internal/schedule/' || i_schid ||
                                        '/patient/' || i_idpersonexternal ||
                                        '/contactType/' || i_contacttype;
  
    l_status varchar2(50 CHAR);
    l_data   JSON_ELEMENT_T;
    l_error  JSON_ARRAY_T;
  BEGIN
  
    RETURN pk_rest_api.make_internal_rest_request(i_host_transaction => i_transaction,
                                                  i_service          => l_service,
                                                  i_http_method      => l_http_method,
                                                  i_lang             => i_lang,
                                                  i_prof             => i_prof,
                                                  o_status           => l_status,
                                                  o_data             => l_data,
                                                  o_error            => l_error);
  
  END setcontacttype;

  FUNCTION updateschprocedureanddates(i_lang          IN NUMBER,
                                      i_prof          IN profissional,
                                      i_scheduleid    IN NUMBER,
                                      i_contentid     IN VARCHAR2,
                                      i_depclinservid IN NUMBER,
                                      i_profid        IN NUMBER,
                                      i_begindate     IN TIMESTAMP WITH LOCAL TIME ZONE,
                                      i_enddate       IN TIMESTAMP WITH LOCAL TIME ZONE,
                                      i_requestedtype IN VARCHAR2,
                                      i_transaction   IN VARCHAR2)
    RETURN BOOLEAN IS
    l_update_schedule JSON_OBJECT_T;
  
    l_http_method  varchar2(4 CHAR) := k_http_put;
    l_content_type varchar2(16 CHAR) := k_content_type_json;
    l_service      varchar2(250 CHAR) := '/internal/schedule/' ||
                                         i_scheduleid;
  
    l_status varchar2(50 CHAR);
    l_data   JSON_ELEMENT_T;
    l_error  JSON_ARRAY_T;
  
  BEGIN
    l_update_schedule := schedule_dto(i_depcleanservid => i_depclinservid,
                                      i_contentid      => i_contentid,
                                      i_professionalid => i_profid,
                                      i_begindate      => i_begindate,
                                      i_enddate        => i_enddate,
                                      i_flgrequesttype => i_requestedtype);
  
    RETURN pk_rest_api.make_internal_rest_request(i_host_transaction => i_transaction,
                                                  i_service          => l_service,
                                                  i_http_method      => l_http_method,
                                                  i_content_type     => l_content_type,
                                                  i_lang             => i_lang,
                                                  i_prof             => i_prof,
                                                  i_body             => l_update_schedule.to_string,
                                                  o_status           => l_status,
                                                  o_data             => l_data,
                                                  o_error            => l_error);
  
  END updateschprocedureanddates;

  FUNCTION addrequisition(i_lang             IN NUMBER,
                          i_prof             IN profissional,
                          i_schid            IN NUMBER,
                          i_idpersonexternal IN NUMBER,
                          i_idreq            IN NUMBER,
                          i_transaction      IN VARCHAR2) RETURN BOOLEAN IS
  
    l_http_method varchar2(4 CHAR) := k_http_post;
    l_service     varchar2(250 CHAR) := '/internal/schedule/' || i_schid ||
                                        '/person/' || i_idpersonexternal ||
                                        '/requisition/' || i_idreq;
  
    l_status varchar2(50 CHAR);
    l_data   JSON_ELEMENT_T;
    l_error  JSON_ARRAY_T;
  BEGIN
  
    RETURN pk_rest_api.make_internal_rest_request(i_host_transaction => i_transaction,
                                                  i_service          => l_service,
                                                  i_http_method      => l_http_method,
                                                  i_lang             => i_lang,
                                                  i_prof             => i_prof,
                                                  o_status           => l_status,
                                                  o_data             => l_data,
                                                  o_error            => l_error);
  
  END addrequisition;

  FUNCTION block_unblock_bed_dto(i_bedid      IN NUMBER,
                                 i_resourceid IN NUMBER DEFAULT NULL,
                                 i_begindate  IN TIMESTAMP WITH LOCAL TIME ZONE,
                                 i_enddate    IN TIMESTAMP WITH LOCAL TIME ZONE)
    RETURN JSON_OBJECT_T IS
    l_block_unblock_bed JSON_OBJECT_T;
  
  BEGIN
    l_block_unblock_bed := JSON_OBJECT_T();
  
    l_block_unblock_bed.put('idBed', i_bedid);
    l_block_unblock_bed.put('idScheduleResource', i_resourceid);
    l_block_unblock_bed.put('dtBegin',
                            pk_rest_api.convert_timestamp(i_begindate));
    l_block_unblock_bed.put('dtEnd',
                            pk_rest_api.convert_timestamp(i_enddate));
  
    RETURN l_block_unblock_bed;
  END block_unblock_bed_dto;

  FUNCTION blockbed(i_lang        IN NUMBER,
                    i_prof        IN profissional,
                    i_bedid       IN NUMBER,
                    i_begindate   IN TIMESTAMP WITH LOCAL TIME ZONE,
                    i_enddate     IN TIMESTAMP WITH LOCAL TIME ZONE,
                    i_transaction IN VARCHAR2,
                    o_idresource  OUT NUMBER) RETURN BOOLEAN IS
    l_block_bed    JSON_OBJECT_T;
    l_http_method  varchar2(4 CHAR) := k_http_put;
    l_content_type varchar2(16 CHAR) := k_content_type_json;
    l_service      varchar2(250 CHAR) := '/internal/bed/' || i_bedid ||
                                         '/block';
  
    l_status varchar2(50 CHAR);
    l_data   JSON_ELEMENT_T;
    l_error  JSON_ARRAY_T;
  
  BEGIN
    l_block_bed := block_unblock_bed_dto(i_bedid     => i_bedid,
                                         i_begindate => i_begindate,
                                         i_enddate   => i_enddate);
  
    IF pk_rest_api.make_internal_rest_request(i_host_transaction => i_transaction,
                                              i_service          => l_service,
                                              i_http_method      => l_http_method,
                                              i_content_type     => l_content_type,
                                              i_lang             => i_lang,
                                              i_prof             => i_prof,
                                              i_body             => l_block_bed.to_string,
                                              o_status           => l_status,
                                              o_data             => l_data,
                                              o_error            => l_error) THEN
      o_idresource := l_data.to_Number;
      RETURN TRUE;
    
    END IF;
  
    RETURN FALSE;
  END blockbed;

  FUNCTION unblockbed(i_lang        IN NUMBER,
                      i_prof        IN profissional,
                      i_bedid       IN NUMBER,
                      i_resourceid  IN NUMBER,
                      i_begindate   IN TIMESTAMP WITH LOCAL TIME ZONE,
                      i_enddate     IN TIMESTAMP WITH LOCAL TIME ZONE,
                      i_transaction IN VARCHAR2) RETURN BOOLEAN IS
    l_unblock_bed  JSON_OBJECT_T;
    l_http_method  varchar2(4 CHAR) := k_http_put;
    l_content_type varchar2(16 CHAR) := k_content_type_json;
    l_service      varchar2(250 CHAR) := '/internal/bed/' || i_bedid ||
                                         '/unblock';
  
    l_status varchar2(50 CHAR);
    l_data   JSON_ELEMENT_T;
    l_error  JSON_ARRAY_T;
  
  BEGIN
    l_unblock_bed := block_unblock_bed_dto(i_bedid      => i_bedid,
                                           i_resourceid => i_resourceid,
                                           i_begindate  => i_begindate,
                                           i_enddate    => i_enddate);
  
    RETURN pk_rest_api.make_internal_rest_request(i_host_transaction => i_transaction,
                                                  i_service          => l_service,
                                                  i_http_method      => l_http_method,
                                                  i_content_type     => l_content_type,
                                                  i_lang             => i_lang,
                                                  i_prof             => i_prof,
                                                  i_body             => l_unblock_bed.to_string,
                                                  o_status           => l_status,
                                                  o_data             => l_data,
                                                  o_error            => l_error);
  END unblockbed;

  FUNCTION allocate_bed_dto(i_patientid   IN NUMBER,
                            i_specialtyid IN NUMBER DEFAULT NULL,
                            i_bedid       IN NUMBER,
                            i_begindate   IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
                            i_enddate     IN TIMESTAMP WITH LOCAL TIME ZONE,
                            i_resourceid  IN NUMBER DEFAULT NULL)
    RETURN JSON_OBJECT_T IS
    l_allocate_bed JSON_OBJECT_T;
  BEGIN
    l_allocate_bed := JSON_OBJECT_T();
    l_allocate_bed.put('idPatient', i_patientid);
    IF i_specialtyid IS NOT NULL THEN
      l_allocate_bed.put('idDepClinServ', i_specialtyid);
    END IF;
    l_allocate_bed.put('idBed', i_bedid);
    IF i_begindate IS NOT NULL THEN
      l_allocate_bed.put('dtBegin',
                         pk_rest_api.convert_timestamp(i_begindate));
    END IF;
    l_allocate_bed.put('dtEnd', pk_rest_api.convert_timestamp(i_enddate));
    IF i_resourceid IS NOT NULL THEN
      l_allocate_bed.put('idScheduleResource', i_resourceid);
    END IF;
  
    RETURN l_allocate_bed;
  END allocate_bed_dto;

  FUNCTION allocatebed(i_lang        IN NUMBER,
                       i_prof        IN profissional,
                       i_patientid   IN NUMBER,
                       i_specialtyid IN NUMBER,
                       i_bedid       IN NUMBER,
                       i_begindate   IN TIMESTAMP WITH LOCAL TIME ZONE,
                       i_enddate     IN TIMESTAMP WITH LOCAL TIME ZONE,
                       i_transaction IN VARCHAR2,
                       o_idresource  OUT NUMBER) RETURN BOOLEAN IS
    l_allocate_bed JSON_OBJECT_T;
    l_http_method  varchar2(4 CHAR) := k_http_post;
    l_content_type varchar2(16 CHAR) := k_content_type_json;
    l_service      varchar2(250 CHAR) := '/internal/bed/' || i_bedid ||
                                         '/allocate';
  
    l_status varchar2(50);
    l_data   JSON_ELEMENT_T;
    l_error  JSON_ARRAY_T;
  
  BEGIN
    l_allocate_bed := allocate_bed_dto(i_patientid   => i_patientid,
                                       i_specialtyid => i_specialtyid,
                                       i_bedid       => i_bedid,
                                       i_begindate   => i_begindate,
                                       i_enddate     => i_enddate);
  
    IF pk_rest_api.make_internal_rest_request(i_host_transaction => i_transaction,
                                              i_service          => l_service,
                                              i_http_method      => l_http_method,
                                              i_content_type     => l_content_type,
                                              i_lang             => i_lang,
                                              i_prof             => i_prof,
                                              i_body             => l_allocate_bed.to_string,
                                              o_status           => l_status,
                                              o_data             => l_data,
                                              o_error            => l_error) THEN
    
      o_idresource := l_data.to_Number;
      RETURN TRUE;
    
    END IF;
  
    RETURN FALSE;
  
  END allocatebed;

  FUNCTION deallocatebed(i_lang        IN NUMBER,
                         i_prof        IN profissional,
                         i_patientid   IN NUMBER,
                         i_bedid       IN NUMBER,
                         i_resourceid  IN NUMBER,
                         i_enddate     IN TIMESTAMP WITH LOCAL TIME ZONE,
                         i_transaction IN VARCHAR2) RETURN BOOLEAN IS
    l_allocate_bed JSON_OBJECT_T;
  
    l_http_method  varchar2(4 CHAR) := k_http_put;
    l_content_type varchar2(16 CHAR) := k_content_type_json;
    l_service      varchar2(250 CHAR) := '/internal/bed/' || i_bedid ||
                                         '/deallocate';
  
    l_status varchar2(50 CHAR);
    l_data   JSON_ELEMENT_T;
    l_error  JSON_ARRAY_T;
  
  BEGIN
  
    l_allocate_bed := allocate_bed_dto(i_patientid  => i_patientid,
                                       i_bedid      => i_bedid,
                                       i_enddate    => i_enddate,
                                       i_resourceid => i_resourceid);
  
    RETURN pk_rest_api.make_internal_rest_request(i_host_transaction => i_transaction,
                                                  i_service          => l_service,
                                                  i_http_method      => l_http_method,
                                                  i_content_type     => l_content_type,
                                                  i_lang             => i_lang,
                                                  i_prof             => i_prof,
                                                  i_body             => l_allocate_bed.to_string,
                                                  o_status           => l_status,
                                                  o_data             => l_data,
                                                  o_error            => l_error);
  
  END deallocatebed;

  FUNCTION update_allocate_bed_dto(i_patientid  IN NUMBER,
                                   i_bedid      IN NUMBER,
                                   i_resourceid IN NUMBER,
                                   i_enddate    IN TIMESTAMP WITH LOCAL TIME ZONE,
                                   i_newenddate IN TIMESTAMP WITH LOCAL TIME ZONE)
    RETURN JSON_OBJECT_T IS
    l_update_allocate_bed JSON_OBJECT_T;
  BEGIN
    l_update_allocate_bed := JSON_OBJECT_T();
    l_update_allocate_bed.put('idPatient', i_patientid);
    l_update_allocate_bed.put('idBed', i_bedid);
    l_update_allocate_bed.put('idScheduleResource', i_resourceid);
    l_update_allocate_bed.put('dtEnd',
                              pk_rest_api.convert_timestamp(i_enddate));
    l_update_allocate_bed.put('newDtEnd',
                              pk_rest_api.convert_timestamp(i_newenddate));
  
    RETURN l_update_allocate_bed;
  END update_allocate_bed_dto;

  FUNCTION updateallocatedbed(i_lang        IN NUMBER,
                              i_prof        IN profissional,
                              i_patientid   IN NUMBER,
                              i_bedid       IN NUMBER,
                              i_resourceid  IN NUMBER,
                              i_enddate     IN TIMESTAMP WITH LOCAL TIME ZONE,
                              i_newenddate  IN TIMESTAMP WITH LOCAL TIME ZONE,
                              i_transaction IN VARCHAR2) RETURN BOOLEAN IS
    l_update_allocate_bed JSON_OBJECT_T;
    l_http_method         varchar2(4 CHAR) := k_http_put;
    l_content_type        varchar2(16 CHAR) := k_content_type_json;
    l_service             varchar2(250 CHAR) := '/internal/bed/' || i_bedid ||
                                                '/allocate';
  
    l_status varchar2(50 CHAR);
    l_data   JSON_ELEMENT_T;
    l_error  JSON_ARRAY_T;
  BEGIN
    l_update_allocate_bed := update_allocate_bed_dto(i_patientid  => i_patientid,
                                                     i_bedid      => i_bedid,
                                                     i_resourceid => i_resourceid,
                                                     i_enddate    => i_enddate,
                                                     i_newenddate => i_newenddate);
  
    RETURN pk_rest_api.make_internal_rest_request(i_host_transaction => i_transaction,
                                                  i_service          => l_service,
                                                  i_http_method      => l_http_method,
                                                  i_content_type     => l_content_type,
                                                  i_lang             => i_lang,
                                                  i_prof             => i_prof,
                                                  i_body             => l_update_allocate_bed.to_string,
                                                  o_status           => l_status,
                                                  o_data             => l_data,
                                                  o_error            => l_error);
  
  END updateallocatedbed;

  FUNCTION approvehhcschedules(i_lang        IN NUMBER,
                               i_prof        IN profissional,
                               i_schids      IN table_number,
                               i_reasonid    IN NUMBER,
                               i_reasonnotes IN VARCHAR2,
                               i_transaction IN VARCHAR2) RETURN BOOLEAN IS
    l_jo           JSON_OBJECT_T;
    l_http_method  varchar2(4 CHAR) := k_http_put;
    l_content_type varchar2(16 CHAR) := k_content_type_json;
    l_service      varchar2(250 CHAR) := '/internal/schedule/hhc/approve';
  
    l_status varchar2(50 CHAR);
    l_data   JSON_ELEMENT_T;
    l_error  JSON_ARRAY_T;
  BEGIN
    l_jo := change_schedule_status_dto(i_schids      => i_schids,
                                       i_reasonid    => i_reasonid,
                                       i_reasonnotes => i_reasonnotes);
  
    RETURN pk_rest_api.make_internal_rest_request(i_host_transaction => i_transaction,
                                                  i_service          => l_service,
                                                  i_http_method      => l_http_method,
                                                  i_content_type     => l_content_type,
                                                  i_lang             => i_lang,
                                                  i_prof             => i_prof,
                                                  i_body             => l_jo.to_string,
                                                  o_status           => l_status,
                                                  o_data             => l_data,
                                                  o_error            => l_error);
  
  END approvehhcschedules;

  FUNCTION undoapprovedhhcschedules(i_lang        IN NUMBER,
                                    i_prof        IN profissional,
                                    i_schids      IN table_number,
                                    i_reasonid    IN NUMBER,
                                    i_reasonnotes IN VARCHAR2,
                                    i_transaction IN VARCHAR2) RETURN BOOLEAN IS
    l_jo           JSON_OBJECT_T;
    l_http_method  varchar2(4 CHAR) := k_http_put;
    l_content_type varchar2(16 CHAR) := k_content_type_json;
    l_service      varchar2(250 CHAR) := '/internal/schedule/hhc/undoApprove';
  
    l_status varchar2(50 CHAR);
    l_data   JSON_ELEMENT_T;
    l_error  JSON_ARRAY_T;
  BEGIN
    l_jo := change_schedule_status_dto(i_schids      => i_schids,
                                       i_reasonid    => i_reasonid,
                                       i_reasonnotes => i_reasonnotes);
  
    RETURN pk_rest_api.make_internal_rest_request(i_host_transaction => i_transaction,
                                                  i_service          => l_service,
                                                  i_http_method      => l_http_method,
                                                  i_content_type     => l_content_type,
                                                  i_lang             => i_lang,
                                                  i_prof             => i_prof,
                                                  i_body             => l_jo.to_string,
                                                  o_status           => l_status,
                                                  o_data             => l_data,
                                                  o_error            => l_error);
  
  END undoapprovedhhcschedules;

  FUNCTION cancelvideolinkconference(i_lang        IN NUMBER,
                                     i_prof        IN profissional,
                                     i_schid       IN NUMBER,
                                     i_transaction IN VARCHAR2)
    RETURN BOOLEAN IS
  
    l_http_method varchar2(6 CHAR) := k_http_delete;
    l_service     varchar2(250 CHAR) := '/internal/schedule/' || i_schid ||
                                        '/videoconference';
  
    l_status varchar2(50 CHAR);
    l_data   JSON_ELEMENT_T;
    l_error  JSON_ARRAY_T;
  BEGIN
  
    RETURN pk_rest_api.make_internal_rest_request(i_host_transaction => i_transaction,
                                                  i_service          => l_service,
                                                  i_http_method      => l_http_method,
                                                  i_lang             => i_lang,
                                                  i_prof             => i_prof,
                                                  o_status           => l_status,
                                                  o_data             => l_data,
                                                  o_error            => l_error);
  END cancelvideolinkconference;
  
    FUNCTION isitok RETURN BOOLEAN IS
    l_transaction_id VARCHAR2(4000);
    l_application_context sys_config.id_sys_config%TYPE := 'REST_APSSCH_CONTEXT';
    l_application_port    sys_config.id_sys_config%TYPE := 'REST_APSSCH_PORT';
    l_prof profissional := profissional(ID          => 0,
                            INSTITUTION => 0,
                            SOFTWARE    => 0);
  BEGIN
    
  RETURN pk_rest_api.gettransactionid(i_lang            => 0,
                                        i_prof                => l_prof,
                                        i_application_context => l_application_context,
                                        i_application_port    => l_application_port,
                                        o_transaction         => l_transaction_id);
    
  END isitok;

begin
  /* CAN'T TOUCH THIS */
  /* Who am I */
  pk_alertlog.who_am_i(owner => g_owner, name => g_package);
  /* Log init */
  pk_alertlog.log_init(object_name => g_package);
end PK_SCHEDULE_REST_SERVICES;
/