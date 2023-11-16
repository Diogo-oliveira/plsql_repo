-- CHANGED BY: filipe.f.pereira
-- CHANGE DATE: 18/07/2013
-- CHANGE REASON: ALERT-217074

DECLARE
  ID_REPORTS     NUMBER(24);
  DESC_MESSAGE   varchar2(4000);
  ID_LANGUAGE    NUMBER(6);
  ID_SOFTWARE    NUMBER(24);
  ID_INSTITUTION NUMBER(24);

  l_code CLOB;

  cursor c_messages IS
    SELECT TO_NUMBER(REPLACE(sm.code_message,
                             'REP_GENERAL_CERTIFICATE.',
                             '')) AS ID_REPORTS,
           sm.desc_message,
           sm.id_language,
           sm.id_software,
           sm.id_institution
      FROM sys_message sm, REPORTS R
     WHERE sm.code_message LIKE 'REP_GENERAL_CERTIFICATE.%'
       AND R.ID_REPORTS = TO_NUMBER(REPLACE(sm.code_message,
                                            'REP_GENERAL_CERTIFICATE.',
                                            ''));
  CURSOR c_unique_institutions IS
    SELECT DISTINCT id_institution FROM rep_editable_text_inst_soft;

BEGIN

  <<LOOP_THRU_MESSAGES>>
  FOR message IN c_messages loop
  
    ID_REPORTS     := message.ID_REPORTS;
    DESC_MESSAGE   := message.DESC_MESSAGE;
    ID_LANGUAGE    := message.ID_LANGUAGE;
    ID_SOFTWARE    := message.ID_SOFTWARE;
    ID_INSTITUTION := message.ID_INSTITUTION;
  
    IF (ID_INSTITUTION != 0) THEN
      l_code := 'INSERT INTO REP_EDITABLE_TEXT_INST_SOFT(ID_REP_EDITABLE_TEXT_INST, ID_REPORTS, ID_LANGUAGE, ID_INSTITUTION, ID_SOFTWARE, TEXT)
                    VALUES
                    (SEC_REP_EDIT_TEXT_INST_SOFT.NEXTVAL, ' ||
                ID_REPORTS || ', ' || ID_LANGUAGE || ', ' || ID_INSTITUTION ||
                ',  ' || ID_SOFTWARE || ', q''[' || DESC_MESSAGE || ']'') ';
      execute immediate l_code;
    
    ELSE
      l_code := 'INSERT INTO REP_EDITABLE_TEXT_MKT(ID_REP_EDITABLE_TEXT_MKT, ID_REPORTS, ID_LANGUAGE, ID_MARKET, TEXT)
                    VALUES
                    (SEC_REP_EDITABLE_TEXT_MKT.NEXTVAL, ' ||
                ID_REPORTS || ', ' || ID_LANGUAGE || ', 0, q''[' ||
                DESC_MESSAGE || ']'') ';
      execute immediate l_code;
    END IF;
  
  end loop LOOP_THRU_MESSAGES;

  <<LOOP_THRU_INSTITUTIONS>>
  FOR institution IN c_unique_institutions loop
    ID_INSTITUTION := institution.id_institution;
  
    l_code := 'INSERT INTO REP_EDITABLE_TEXT_INST_SOFT(ID_REP_EDITABLE_TEXT_INST, ID_REPORTS, ID_LANGUAGE, ID_INSTITUTION, ID_SOFTWARE, TEXT)
                     select SEC_REP_EDIT_TEXT_INST_SOFT.NEXTVAL, retm.id_reports, retm.id_language, ' ||
              ID_INSTITUTION ||
              ' as id_institution, 0 as id_software, retm.text
                            from rep_editable_text_mkt retm
                                 where retm.id_reports not in (select reti.id_reports from rep_editable_text_inst_soft reti where reti.id_institution = ' ||
              ID_INSTITUTION || ')';
  
    execute immediate l_code;
  end loop LOOP_THRU_INSTITUTIONS;

  execute immediate 'delete from sys_message sm where sm.code_message like ''REP_GENERAL_CERTIFICATE%''';

  commit;

END;
/

-- CHANGE END: filipe.f.pereira