-- CHANGED BY: Ant�nio Neto
-- CHANGE DATE: 16/05/2011 
-- CHANGE REASON: [ALERT-179477] Convert varchar2 to clob - Descri��o: No perfil M�dico, no INP, no bot�o da Hist�ria da Doen�a (truncated)


BEGIN
    FOR item IN (SELECT ch.id_complete_history, ch.text
                   FROM complete_history ch
									 where ch.text is not null
									 and ch.long_text is null)
    LOOP
        UPDATE complete_history ch
           SET ch.long_text = item.text
         WHERE ch.id_complete_history = item.id_complete_history;
    END LOOP;

END;
/

-- CHANGE END: Ant�nio Neto