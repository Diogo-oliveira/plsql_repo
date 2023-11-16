/*-- Last Change Revision: $Rev:  $*/
/*-- Last Change by: $Author:  $*/
/*-- Date of last change: $Date:  $*/
create or replace package PK_SCHEDULE_REST_SERVICES is

  -- Author  : MIGUEL.MONTEIRO
  -- Created : 01/09/2020 16:35:07
  -- Purpose : Consume REST Services from Scheduler application

  -- Public type declarations
  FUNCTION cancelschedule(i_lang         IN NUMBER,
                          i_prof         IN profissional,
                          i_schid        IN NUMBER,
                          i_idperson     IN NUMBER,
                          i_cancelreason IN NUMBER,
                          i_cancelnotes  IN VARCHAR2,
                          i_canceldate   IN TIMESTAMP WITH LOCAL TIME ZONE,
                          i_transaction  IN VARCHAR2) RETURN BOOLEAN;

  FUNCTION registerschedule(i_lang        IN NUMBER,
                            i_prof        IN profissional,
                            i_schid       IN NUMBER,
                            i_personid    IN NUMBER,
                            i_transaction IN VARCHAR2) RETURN BOOLEAN;

  FUNCTION cancelscheduleregistration(i_lang        IN NUMBER,
                                      i_prof        IN profissional,
                                      i_schid       IN NUMBER,
                                      i_personid    IN NUMBER,
                                      i_transaction IN VARCHAR2)
    RETURN BOOLEAN;

  FUNCTION updateschedulebed(i_lang        IN NUMBER,
                             i_prof        IN profissional,
                             i_schid       IN NUMBER,
                             i_bedid       IN NUMBER,
                             i_olddate     IN TIMESTAMP WITH LOCAL TIME ZONE,
                             i_newdate     IN TIMESTAMP WITH LOCAL TIME ZONE,
                             i_transaction IN VARCHAR2) RETURN BOOLEAN;

  FUNCTION notifyperson(i_lang             IN NUMBER,
                        i_prof             IN profissional,
                        i_schid            IN NUMBER,
                        i_personid         IN NUMBER,
                        i_notificationvia  IN VARCHAR2,
                        i_professionalid   IN NUMBER,
                        i_notificationdate IN TIMESTAMP WITH LOCAL TIME ZONE,
                        i_transaction      IN VARCHAR2) RETURN BOOLEAN;

  FUNCTION confirmperson(i_lang                  IN NUMBER,
                         i_prof                  IN profissional,
                         i_scheduleid            IN NUMBER,
                         i_personid              IN NUMBER,
                         i_professionalidconfirm IN NUMBER,
                         i_confirmationdate      IN TIMESTAMP WITH LOCAL TIME ZONE,
                         i_transaction           IN VARCHAR2) RETURN BOOLEAN;

  FUNCTION confirmpendingschedule(i_lang        IN NUMBER,
                                  i_prof        IN profissional,
                                  i_schid       IN NUMBER,
                                  i_transaction IN VARCHAR2) RETURN BOOLEAN;

  FUNCTION removependingschedule(i_lang        IN NUMBER,
                                 i_prof        IN profissional,
                                 i_schid       IN NUMBER,
                                 i_transaction IN VARCHAR2) RETURN BOOLEAN;

  FUNCTION reactivatecanceledschedule(i_lang        IN NUMBER,
                                      i_prof        IN profissional,
                                      i_schid       IN NUMBER,
                                      i_transaction IN VARCHAR2)
    RETURN BOOLEAN;

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
                          o_schid          OUT NUMBER) RETURN BOOLEAN;

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
    RETURN BOOLEAN;

  FUNCTION updateschedulepatient(i_lang            NUMBER,
                                 i_prof            profissional,
                                 i_scheduleid      NUMBER,
                                 i_patienttoremove NUMBER,
                                 i_patienttoadd    NUMBER,
                                 i_transaction     IN VARCHAR2)
    RETURN BOOLEAN;

  FUNCTION setschedulepersonnoshow(i_lang        IN NUMBER,
                                   i_prof        IN profissional,
                                   i_schid       IN NUMBER,
                                   i_personid    IN NUMBER,
                                   i_noshowid    IN NUMBER,
                                   i_noshownotes IN VARCHAR2,
                                   i_transaction IN VARCHAR2) RETURN BOOLEAN;

  FUNCTION cancelschedulepersonnoshow(i_lang             IN NUMBER,
                                      i_prof             IN profissional,
                                      i_schid            IN NUMBER,
                                      i_idpersonexternal IN NUMBER,
                                      i_transaction      IN VARCHAR2)
    RETURN BOOLEAN;

  FUNCTION setcontacttype(i_lang             IN NUMBER,
                          i_prof             IN profissional,
                          i_schid            IN NUMBER,
                          i_idpersonexternal IN NUMBER,
                          i_contacttype      IN VARCHAR2,
                          i_transaction      IN VARCHAR2) RETURN BOOLEAN;

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
    RETURN BOOLEAN;

  FUNCTION addrequisition(i_lang             IN NUMBER,
                          i_prof             IN profissional,
                          i_schid            IN NUMBER,
                          i_idpersonexternal IN NUMBER,
                          i_idreq            IN NUMBER,
                          i_transaction      IN VARCHAR2) RETURN BOOLEAN;

  FUNCTION blockbed(i_lang        IN NUMBER,
                    i_prof        IN profissional,
                    i_bedid       IN NUMBER,
                    i_begindate   IN TIMESTAMP WITH LOCAL TIME ZONE,
                    i_enddate     IN TIMESTAMP WITH LOCAL TIME ZONE,
                    i_transaction IN VARCHAR2,
                    o_idresource  OUT NUMBER) RETURN BOOLEAN;

  FUNCTION unblockbed(i_lang        IN NUMBER,
                      i_prof        IN profissional,
                      i_bedid       IN NUMBER,
                      i_resourceid  IN NUMBER,
                      i_begindate   IN TIMESTAMP WITH LOCAL TIME ZONE,
                      i_enddate     IN TIMESTAMP WITH LOCAL TIME ZONE,
                      i_transaction IN VARCHAR2) RETURN BOOLEAN;

  FUNCTION allocatebed(i_lang        IN NUMBER,
                       i_prof        IN profissional,
                       i_patientid   IN NUMBER,
                       i_specialtyid IN NUMBER,
                       i_bedid       IN NUMBER,
                       i_begindate   IN TIMESTAMP WITH LOCAL TIME ZONE,
                       i_enddate     IN TIMESTAMP WITH LOCAL TIME ZONE,
                       i_transaction IN VARCHAR2,
                       o_idresource  OUT NUMBER) RETURN BOOLEAN;

  FUNCTION deallocatebed(i_lang        IN NUMBER,
                         i_prof        IN profissional,
                         i_patientid   IN NUMBER,
                         i_bedid       IN NUMBER,
                         i_resourceid  IN NUMBER,
                         i_enddate     IN TIMESTAMP WITH LOCAL TIME ZONE,
                         i_transaction IN VARCHAR2) RETURN BOOLEAN;

  FUNCTION updateallocatedbed(i_lang        IN NUMBER,
                              i_prof        IN profissional,
                              i_patientid   IN NUMBER,
                              i_bedid       IN NUMBER,
                              i_resourceid  IN NUMBER,
                              i_enddate     IN TIMESTAMP WITH LOCAL TIME ZONE,
                              i_newenddate  IN TIMESTAMP WITH LOCAL TIME ZONE,
                              i_transaction IN VARCHAR2) RETURN BOOLEAN;

  FUNCTION approvehhcschedules(i_lang        IN NUMBER,
                               i_prof        IN profissional,
                               i_schids      IN table_number,
                               i_reasonid    IN NUMBER,
                               i_reasonnotes IN VARCHAR2,
                               i_transaction IN VARCHAR2) RETURN BOOLEAN;

  FUNCTION undoapprovedhhcschedules(i_lang        IN NUMBER,
                                    i_prof        IN profissional,
                                    i_schids      IN table_number,
                                    i_reasonid    IN NUMBER,
                                    i_reasonnotes IN VARCHAR2,
                                    i_transaction IN VARCHAR2) RETURN BOOLEAN;

FUNCTION isitok RETURN BOOLEAN;

end PK_SCHEDULE_REST_SERVICES;
/